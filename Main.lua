-- ***************************************************************************************************************************************************
-- * Main.lua                                                                                                                                        *
-- ***************************************************************************************************************************************************
-- * Creates the addon windows                                                                                                                       *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.29 / Baanano: Updated for 0.4.1                                                                                                 *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local CAScan = Command.Auction.Scan
local CSRegister = Command.Slash.Register
local GetPlayerName = InternalInterface.Utility.GetPlayerName
local L = InternalInterface.Localization.L
local Panel = Yague.Panel
local PopupManager = Yague.PopupManager
local SFormat = string.format
local TInsert = table.insert
local UICreateContext = UI.CreateContext
local UICreateFrame = UI.CreateFrame
local UNMapMini = UI.Native.MapMini
local UNAuction = UI.Native.Auction
local Write = InternalInterface.Output.Write
local pcall = pcall
local tostring = tostring

local MIN_WIDTH = 1422
local MIN_HEIGHT = 800
local DEFAULT_WIDTH = 1422
local DEFAULT_HEIGHT = 800

local function InitializeLayout()
	local mapContext = UICreateContext(addonID .. ".UI.MapContext")
	local mapIcon = UICreateFrame("Texture", addonID .. ".UI.MapIcon", mapContext)

	local mainContext = UICreateContext(addonID .. ".UI.MainContext")

	local mainWindow = Yague.Window(addonID .. ".UI.MainWindow", mainContext)
	local popupManager = PopupManager(mainWindow:GetName() .. ".PopupManager", mainWindow)
	local mainTab = Yague.TabControl(mainWindow:GetName() .. ".MainTab", mainWindow:GetContent())
	local searchFrame = InternalInterface.UI.SearchFrame(mainTab:GetName() .. ".SearchFrame", mainTab:GetContent())
	local postFrame = InternalInterface.UI.PostFrame(mainTab:GetName() .. ".PostFrame", mainTab:GetContent())
	local sellingFrame = InternalInterface.UI.SellingFrame(mainTab:GetName() .. ".SellingFrame", mainTab:GetContent())
	local mapFrame = InternalInterface.UI.MapFrame(mainTab:GetName() .. ".MapFrame", mainTab:GetContent())
	local configFrame = InternalInterface.UI.ConfigFrame(mainTab:GetName() .. ".ConfigFrame", mainTab:GetContent())

	local queueManager = InternalInterface.UI.QueueManager(mainWindow:GetName() .. ".QueueManager", mainWindow:GetContent())
	
	local auctionsPanel = Panel(mainWindow:GetName() .. ".AuctionsPanel", mainWindow:GetContent())
	local auctionsIcon = UICreateFrame("Texture", auctionsPanel:GetName() .. ".AuctionsIcon", auctionsPanel:GetContent())
	local auctionsText = UICreateFrame("Text", auctionsPanel:GetName() .. ".AuctionsText", auctionsPanel:GetContent())
	
	local sellersPanel = Panel(mainWindow:GetName() .. ".SellersPanel", mainWindow:GetContent())
	local sellersAnchor = UICreateFrame("Frame", mainWindow:GetName() .. ".SellersAnchor", sellersPanel:GetContent())
	local sellerRows = {}
	
	local statusPanel = Panel(addonID .. ".UI.MainWindow.StatusBar", mainWindow:GetContent())
	local statusText = UICreateFrame("Text", addonID .. ".UI.MainWindow.StatusText", statusPanel:GetContent())

	local refreshPanel = Panel(mainWindow:GetName() .. ".RefreshPanel", mainWindow:GetContent())
	local refreshText = Yague.ShadowedText(mainWindow:GetName() .. ".RefreshText", refreshPanel:GetContent())
	
	local refreshEnabled = false
	local auctionNumbers = {}

	local function ShowSelectedFrame(frame)
		if frame and frame.Show then
			frame:Show()
		end
	end
	
	local function HideSelectedFrame(frame)
		if frame and frame.Hide then
			frame:Hide()
		end
	end

	local function UpdateSellerRows()
		local names = {}
		for seller, number in pairs(auctionNumbers) do
			names[#names + 1] = seller
		end
		table.sort(names, function(a,b) return b < a end)
		
		for i = 1, #names do
			if not sellerRows[i] then
				local sellerRow = UICreateFrame("Frame", sellersPanel:GetName() .. ".Row." .. i, sellersPanel:GetContent())
				local sellerRowName = UICreateFrame("Text", sellerRow:GetName() .. ".Name", sellerRow)
				local sellerRowNumber = UICreateFrame("Text", sellerRow:GetName() .. ".Number", sellerRow)
				
				sellerRow:SetPoint("BOTTOMLEFT", sellersPanel:GetContent(), "BOTTOMLEFT", 2, 20 - 20 * i)
				sellerRow:SetPoint("TOPRIGHT", sellersPanel:GetContent(), "BOTTOMRIGHT", -2, 0 - 20 * i)
				
				sellerRowName:SetPoint("CENTERLEFT", sellerRow, "CENTERLEFT", 2, 0)

				sellerRowNumber:SetPoint("CENTERRIGHT", sellerRow, "CENTERRIGHT", -2, 0)
				
				sellerRows[i] = { sellerRow, sellerRowName, sellerRowNumber }
			end
			
			sellerRows[i][1]:SetVisible(true)
			sellerRows[i][2]:SetText(names[i])
			sellerRows[i][3]:SetText(tostring(auctionNumbers[names[i]]))
		end
		
		if #names > 0 then
			sellersAnchor:SetPoint("BOTTOMCENTER", sellerRows[#names][1], "TOPCENTER", 0, -6)
		end
		
		for i = #names + 1, #sellerRows do
			sellerRows[i][1]:SetVisible(false)
		end
	end
	
	local function UpdateAuctions()
		if mainWindow:GetVisible() then
			local playerName = GetPlayerName() or true
			
			auctionNumbers = {}
			
			auctionsText:SetText("")
			sellersPanel:SetVisible(false)
			
			LibPGC.GetOwnAuctionData(
				function(auctions)
					for auctionID, auctionData in pairs(auctions) do
						auctionNumbers[auctionData.sellerName] = (auctionNumbers[auctionData.sellerName] or 0) + 1
					end
					
					auctionsText:SetText(tostring(auctionNumbers[playerName] or 0))
					UpdateSellerRows()
				end)
		end
	end
	
	local function ShowBananAH()
		mainContext:SetLayer(UI.Native.Auction:GetLayer() + 1)
		mainWindow:SetVisible(true)
		if mainWindow:GetTop() < 0 then
			mainWindow:ClearAll()
			mainWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			mainWindow:SetWidth(DEFAULT_WIDTH)
			mainWindow:SetHeight(DEFAULT_HEIGHT)
		end
		UpdateAuctions()
		ShowSelectedFrame(mainTab:GetSelectedFrame())
	end
	
	mapContext:SetStrata("hud")

	mapIcon:SetTextureAsync(addonID, "Textures/MapIcon.png")
	InternalInterface.UI.MapIcon = mapIcon
	if MINIMAPDOCKER then
		MINIMAPDOCKER.Register(addonID, mapIcon)
	else
		mapIcon:SetVisible(InternalInterface.AccountSettings.General.ShowMapIcon or false)
		mapIcon:SetPoint("CENTER", UNMapMini, "BOTTOMLEFT", 24, -25)
	end
	
	mainWindow:SetVisible(false)
	mainWindow:SetMinWidth(MIN_WIDTH)
	mainWindow:SetMinHeight(MIN_HEIGHT)
	mainWindow:SetWidth(DEFAULT_WIDTH)
	mainWindow:SetHeight(DEFAULT_HEIGHT)
	mainWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	mainWindow:SetTitle(addonID)
	mainWindow:SetAlpha(1)
	mainWindow:SetCloseable(true)
	mainWindow:SetDraggable(true)
	mainWindow:SetResizable(false)
	
	popupManager:SetAllPoints(mainWindow:GetContent())
	
	mainTab:SetPoint("TOPLEFT", mainWindow:GetContent(), "TOPLEFT", 5, 5)
	mainTab:SetPoint("BOTTOMRIGHT", mainWindow:GetContent(), "BOTTOMRIGHT", -5, -40)
	mainTab:AddTab("search", L["Main/MenuSearch"], searchFrame)
	mainTab:AddTab("post", L["Main/MenuPost"], postFrame)
	mainTab:AddTab("auctions", L["Main/MenuAuctions"], sellingFrame)
	--mainTab:AddTab("bids", L["Main/MenuBids"], nil)
	--mainTab:AddTab("map", L["Main/MenuMap"], mapFrame)
	--mainTab:AddTab("history", L["Main/MenuHistory"], nil)
	mainTab:AddTab("config", L["Main/MenuConfig"], configFrame)
	
	queueManager:SetPoint("BOTTOMRIGHT", mainWindow:GetContent(), "BOTTOMRIGHT", -5, -5)
	queueManager:SetPoint("TOPLEFT", mainWindow:GetContent(), "BOTTOMRIGHT", -155, -35)

	auctionsPanel:SetPoint("TOPLEFT", mainWindow:GetContent(), "BOTTOMLEFT", 5, -35)
	auctionsPanel:SetPoint("BOTTOMRIGHT", mainWindow:GetContent(), "BOTTOMLEFT", 80, -5)
	auctionsPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	auctionsIcon:SetPoint("CENTERLEFT", auctionsPanel:GetContent(), "CENTERLEFT", 2, 0)
	auctionsIcon:SetTextureAsync("Rift", "indicator_auctioneer.png.dds")
	auctionsIcon:SetWidth(24)
	auctionsIcon:SetHeight(24)
	
	auctionsText:SetPoint("CENTERRIGHT", auctionsPanel:GetContent(), "CENTERRIGHT", -2, 0)
	
	sellersPanel:SetLayer(mainTab:GetLayer() + 10)
	sellersPanel:SetPoint("BOTTOMLEFT", auctionsPanel, "TOPLEFT")
	sellersPanel:SetPoint("BOTTOMRIGHT", auctionsPanel, "TOPLEFT", 220, 0)
	sellersPanel:SetPoint("TOP", sellersAnchor, "BOTTOM")
	sellersPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	sellersPanel:SetVisible(false)
	
	sellersAnchor:SetVisible(false)
	sellersAnchor:SetPoint("BOTTOMCENTER", auctionsPanel, "TOPCENTER", 0, -100)
	
	statusPanel:SetPoint("TOPLEFT", auctionsPanel, "TOPRIGHT", 5, 0)
	statusPanel:SetPoint("BOTTOMRIGHT", queueManager, "BOTTOMLEFT", -5, 0)
	statusPanel:GetContent():SetBackgroundColor(0.2, 0.2, 0.2, 0.5)
	
	statusText:SetPoint("CENTERLEFT", statusPanel:GetContent(), "CENTERLEFT", 5, 0)
	statusText:SetPoint("CENTERRIGHT", statusPanel:GetContent(), "CENTERRIGHT", -5, 0)
	
	refreshPanel:SetPoint("TOPRIGHT", mainTab, "TOPRIGHT", -20, 0)
	refreshPanel:SetBottomBorderVisible(false)
	refreshPanel:SetHeight(44)

	refreshText:SetPoint("CENTER", refreshPanel:GetContent(), "CENTER")
	refreshText:SetFontSize(16)
	refreshText:SetFontColor(0.5, 0.5, 0.5)
	refreshText:SetShadowOffset(2, 2)
	refreshText:SetText(L["Main/MenuFullScan"])
	
	refreshPanel:SetWidth(refreshText:GetWidth() + 60)

	function UNMapMini.Event:Layer()
		mapContext:SetLayer(UNMapMini:GetLayer() + 1)
	end

	function mapIcon.Event:LeftClick()
		if not mainWindow:GetVisible() then
			ShowBananAH()
		else
			mainWindow:Close()
		end
	end
	
	function UNAuction.Event:Loaded()
		if UNAuction:GetLoaded() and InternalInterface.AccountSettings.General.AutoOpen then
			ShowBananAH()
		end
		if not UNAuction:GetLoaded() and InternalInterface.AccountSettings.General.AutoClose then
			mainWindow:Close()
		end
	end

	function mainWindow.Event:Close()
		HideSelectedFrame(mainTab:GetSelectedFrame())
		mainWindow:SetKeyFocus(true)
		mainWindow:SetKeyFocus(false)
	end
	
	function mainTab.Event:TabSelected(id, frame, oldID, oldFrame)
		ShowSelectedFrame(frame)
		HideSelectedFrame(oldFrame)
	end
	
	function refreshPanel.Event:MouseIn()
		refreshText:SetFontSize(refreshEnabled and 18 or 16)
	end
	
	function refreshPanel.Event:MouseOut()
		refreshText:SetFontSize(16)
	end
	
	function refreshPanel.Event:LeftClick()
		if not refreshEnabled then return end
		if not pcall(CAScan, { type = "search", sort = "time", sortOrder = "descending" }) then
			Write(L["Main/FullScanError"])
		else
			Write(L["Main/FullScanStarted"])
		end	
	end
	
	auctionsPanel:EventAttach(Event.UI.Input.Mouse.Cursor.In,
		function()
			if next(auctionNumbers) then
				sellersPanel:SetVisible(true)
			end
		end, auctionsPanel:GetName() .. ".OnCursorIn")
	
	auctionsPanel:EventAttach(Event.UI.Input.Mouse.Cursor.Out,
		function()
			sellersPanel:SetVisible(false)
		end, auctionsPanel:GetName() .. ".OnCursorOut")
	
	local function OnInteractionChanged(interaction, state)
		if interaction == "auction" then
			refreshEnabled = state
			refreshText:SetFontColor(0.5, refreshEnabled and 1 or 0.5, 0.5)
		end
	end
	TInsert(Event.Interaction, { OnInteractionChanged, addonID, addonID .. ".OnInteractionChanged" })
	
	local function ReportAuctionData(scanType, total, new, updated, removed, before)
		UpdateAuctions()
		if scanType ~= "search" then return end
		local newMessage = (#new > 0) and SFormat(L["Main/ScanNewCount"], #new) or ""
		local updatedMessage = (#updated > 0) and SFormat(L["Main/ScanUpdatedCount"], #updated) or ""
		local removedMessage = (#removed > 0) and SFormat(L["Main/ScanRemovedCount"], #removed, #before) or ""
		local message = SFormat(L["Main/ScanMessage"], #total, newMessage, updatedMessage, removedMessage)
		Write(message)
	end
	TInsert(Event.LibPGC.AuctionData, { ReportAuctionData, addonID, addonID .. ".ReportAuctionData" })

	local slashEvent1 = CSRegister("bananah")
	local slashEvent2 = CSRegister("bah")
	
	if slashEvent1 then
		TInsert(slashEvent1, {ShowBananAH, addonID, addonID .. ".SlashShow1"})
	end
	if slashEvent2 then
		TInsert(slashEvent2, {ShowBananAH, addonID, addonID .. ".SlashShow2"})
	elseif not slashEvent1 then
		print(L["Main/SlashRegisterError"])
	end
	
	local function StatusBarOutput(value)
		statusText:SetText(value and tostring(value) or "")
	end
	InternalInterface.Output.SetOutputFunction(StatusBarOutput)
	InternalInterface.Output.SetPopupManager(popupManager)
	
	local IMHOBAGS = Inspect.Addon.Detail("ImhoBags")
	if IMHOBAGS and IMHOBAGS.toc and IMHOBAGS.toc.publicAPI == 1 then
		local function OnImhoBagsRightClick(params)
			if not params.cancel and mainWindow:GetVisible() then
				local tabFrame = mainTab:GetSelectedFrame()
				if tabFrame and tabFrame.ItemRightClick then
					params.cancel = tabFrame:ItemRightClick(params) and true or false
				end
			end			
		end	
		TInsert(ImhoBags.Event.Item.Standard.Right, { OnImhoBagsRightClick, addonID, "PostingFrame.OnImhoBagsRightClick" })
	end

end

local function OnAddonLoaded(addonId)
	if addonId == addonID then 
		InitializeLayout()
	end 
end
TInsert(Event.Addon.Load.End, { OnAddonLoaded, addonID, addonID .. ".OnAddonLoaded" })
