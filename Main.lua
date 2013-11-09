-- ***************************************************************************************************************************************************
-- * Main.lua                                                                                                                                        *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.29 / Baanano: Updated for 0.4.1                                                                                                 *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local L = InternalInterface.Localization.L
local Write = InternalInterface.Output.Write

local MIN_WIDTH = 1370
local MIN_HEIGHT = 800
local DEFAULT_WIDTH = 1370
local DEFAULT_HEIGHT = 800

local function InitializeLayout()
	local mapContext = UI.CreateContext(addonID .. ".UI.MapContext")
	local mapIcon = UI.CreateFrame("Texture", addonID .. ".UI.MapIcon", mapContext)

	local mainContext = UI.CreateContext(addonID .. ".UI.MainContext")

	local mainWindow = Yague.Window(addonID .. ".UI.MainWindow", mainContext)
	local popupManager = Yague.PopupManager(mainWindow:GetName() .. ".PopupManager", mainWindow)
	local mainTab = Yague.TabControl(mainWindow:GetName() .. ".MainTab", mainWindow:GetContent())
	local searchFrame = InternalInterface.UI.SearchFrame(mainTab:GetName() .. ".SearchFrame", mainTab:GetContent())
	local postFrame = InternalInterface.UI.PostFrame(mainTab:GetName() .. ".PostFrame", mainTab:GetContent())
	local sellingFrame = InternalInterface.UI.SellingFrame(mainTab:GetName() .. ".SellingFrame", mainTab:GetContent())
--	local mapFrame = InternalInterface.UI.MapFrame(mainTab:GetName() .. ".MapFrame", mainTab:GetContent())
	local configFrame = InternalInterface.UI.ConfigFrame(mainTab:GetName() .. ".ConfigFrame", mainTab:GetContent())

	local queueManager = InternalInterface.UI.QueueManager(mainWindow:GetName() .. ".QueueManager", mainWindow:GetContent())
	
	local auctionsPanel = Yague.Panel(mainWindow:GetName() .. ".AuctionsPanel", mainWindow:GetContent())
	local auctionsIcon = UI.CreateFrame("Texture", auctionsPanel:GetName() .. ".AuctionsIcon", auctionsPanel:GetContent())
	local auctionsText = UI.CreateFrame("Text", auctionsPanel:GetName() .. ".AuctionsText", auctionsPanel:GetContent())
	
	local sellersPanel = Yague.Panel(mainWindow:GetName() .. ".SellersPanel", mainWindow:GetContent())
	local sellersAnchor = UI.CreateFrame("Frame", mainWindow:GetName() .. ".SellersAnchor", sellersPanel:GetContent())
	local sellerRows = {}
	
	local statusPanel = Yague.Panel(addonID .. ".UI.MainWindow.StatusBar", mainWindow:GetContent())
	local statusText = UI.CreateFrame("Text", addonID .. ".UI.MainWindow.StatusText", statusPanel:GetContent())

	local refreshPanel = Yague.Panel(mainWindow:GetName() .. ".RefreshPanel", mainWindow:GetContent())
	local refreshText = Yague.ShadowedText(mainWindow:GetName() .. ".RefreshText", refreshPanel:GetContent())
	
	local refreshEnabled = false
	local auctionNumbers = {}
	local updateTask = nil

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
				local sellerRow = UI.CreateFrame("Frame", sellersPanel:GetName() .. ".Row." .. i, sellersPanel:GetContent())
				local sellerRowName = UI.CreateFrame("Text", sellerRow:GetName() .. ".Name", sellerRow)
				local sellerRowNumber = UI.CreateFrame("Text", sellerRow:GetName() .. ".Number", sellerRow)
				
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
			local playerName = blUtil.Player.Name() or ""
			
			auctionNumbers = {}
			
			auctionsText:SetText("")
			sellersPanel:SetVisible(false)
			
			if updateTask and not updateTask:Finished() then
				updateTask:Stop()
			end
			
			updateTask = blTasks.Task.Create(
				function(taskHandle)
					local auctions = LibPGC.Search.Own():Result()
					auctionNumbers = {}
					
					for auctionID, auctionData in pairs(auctions) do
						auctionNumbers[auctionData.sellerName] = (auctionNumbers[auctionData.sellerName] or 0) + 1
					end
					
					auctionsText:SetText(tostring(auctionNumbers[playerName] or 0))
					UpdateSellerRows()
				end):Start():Abandon()
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
		mapIcon:SetPoint("CENTER", UI.Native.MapMini, "BOTTOMLEFT", 24, -25)
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

	UI.Native.MapMini:EventAttach(Event.UI.Layout.Layer,
		function()
			mapContext:SetLayer(UI.Native.MapMini:GetLayer() + 1)
		end, addonID .. ".MapMiniLayer")

	mapIcon:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			if not mainWindow:GetVisible() then
				ShowBananAH()
			else
				mainWindow:Close()
			end
		end, mapIcon:GetName() .. ".OnLeftClick")
	
	UI.Native.Auction:EventAttach(Event.UI.Native.Loaded,
		function()
			if UI.Native.Auction:GetLoaded() and InternalInterface.AccountSettings.General.AutoOpen then
				ShowBananAH()
			end
			if not UI.Native.Auction:GetLoaded() and InternalInterface.AccountSettings.General.AutoClose then
				mainWindow:Close()
			end
		end, addonID .. ".AuctionLoaded")

	function mainWindow.Event:Close()
		if updateTask and not updateTask:Finished() then
			updateTask:Stop()
		end	
		HideSelectedFrame(mainTab:GetSelectedFrame())
		mainWindow:SetKeyFocus(true)
		mainWindow:SetKeyFocus(false)
	end
	
	function mainTab.Event:TabSelected(id, frame, oldID, oldFrame)
		ShowSelectedFrame(frame)
		HideSelectedFrame(oldFrame)
	end
	
	refreshPanel:EventAttach(Event.UI.Input.Mouse.Cursor.In,
		function()
			refreshText:SetFontSize(refreshEnabled and 18 or 16)
		end, refreshPanel:GetName() .. ".OnCursorIn")
	
	refreshPanel:EventAttach(Event.UI.Input.Mouse.Cursor.Out,
		function()
			refreshText:SetFontSize(16)
		end, refreshPanel:GetName() .. ".OnCursorOut")
	
	refreshPanel:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			if not refreshEnabled then return end
			if not pcall(Command.Auction.Scan, { type = "search", sort = "time", sortOrder = "descending" }) then
				Write(L["Main/FullScanError"])
			else
				Write(L["Main/FullScanStarted"])
			end	
		end, refreshPanel:GetName() .. ".OnLeftClick")
	
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
	
	local function OnInteractionChanged(h, interaction, state)
		if interaction == "auction" then
			refreshEnabled = state
			refreshText:SetFontColor(0.5, refreshEnabled and 1 or 0.5, 0.5)
		end
	end
	Command.Event.Attach(Event.Interaction, OnInteractionChanged, addonID .. ".OnInteractionChanged")
	
	local function ScanStarted(h, criteria)
		if criteria.type == "search" then
			Write(L["Main/ScanInitMessage"])
		end
	end
	Command.Event.Attach(Event.LibPGC.Scan.Begin, ScanStarted, addonID .. ".OnScanStarted")
	
	local function ScanProgress(h, criteria, timeElapsed, progress)
		if criteria.type == "search" then
			Write(string.format(L["Main/ScanProgressMessage"], progress, timeElapsed))
		end
	end
	Command.Event.Attach(Event.LibPGC.Scan.Progress, ScanProgress, addonID .. ".OnScanProgress")
	
	local function ScanEnd(h, criteria, timeElapsed, results)
		UpdateAuctions()
		if criteria.type == "search" then
			local resurrected = results.auctions.count.resurrected > 0 and string.format(L["Main/ScanResurrectedCount"], results.auctions.count.resurrected) or ""
			local new = results.auctions.count.new > 0 and string.format(L["Main/ScanNewCount"], results.auctions.count.new) or ""
			local reposted = results.auctions.count.reposted > 0 and string.format(L["Main/ScanRepostedCount"], results.auctions.count.reposted) or ""
			local updated = results.auctions.count.updated > 0 and string.format(L["Main/ScanUpdatedCount"], results.auctions.count.updated) or ""
			local removed = results.auctions.count.removed > 0 and string.format(L["Main/ScanDeletedCount"], results.auctions.count.removed) or ""
			local beforeExpire = results.auctions.count.beforeExpire > 0 and string.format(L["Main/ScanBeforeExpireCount"], results.auctions.count.beforeExpire) or ""
			Write(string.format(L["Main/ScanFinishMessage"], results.auctions.count.all, resurrected, new, reposted, updated, removed, beforeExpire, timeElapsed))
		end
	end
	Command.Event.Attach(Event.LibPGC.Scan.End, ScanEnd, addonID .. ".OnScanEnd")

	local slashEvent1 = Command.Slash.Register("bananah")
	local slashEvent2 = Command.Slash.Register("bah")
	
	if slashEvent1 then
		Command.Event.Attach(slashEvent1, ShowBananAH, addonID .. ".SlashShow1")
	end
	if slashEvent2 then
		Command.Event.Attach(slashEvent2, ShowBananAH, addonID .. ".SlashShow2")
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
		table.insert(ImhoBags.Event.Item.Standard.Right, { OnImhoBagsRightClick, addonID, "PostingFrame.OnImhoBagsRightClick" })
	end

end

local loaded = false

local function OnLibPGCReady()
	if not loaded then
		InitializeLayout()
		loaded = true
	end
end
Command.Event.Attach(Event.LibPGC.Ready, OnLibPGCReady, addonID .. ".OnLibPGCReady")

local function OnAddonLoaded(h, addon)
	if not loaded and addon == addonID and LibPGC.Ready() then
		InitializeLayout()
		loaded = true
	end
end
Command.Event.Attach(Event.Addon.Load.End, OnAddonLoaded, addonID .. ".OnAddonLoaded")