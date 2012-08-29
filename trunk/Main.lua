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

local MIN_WIDTH = 1370
local MIN_HEIGHT = 800
local DEFAULT_WIDTH = 1370
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
	local configFrame = InternalInterface.UI.ConfigFrame(mainTab:GetName() .. ".ConfigFrame", mainTab:GetContent())

	local queueManager = InternalInterface.UI.QueueManager(mainWindow:GetName() .. ".QueueManager", mainWindow:GetContent())
	
	local statusPanel = Panel(addonID .. ".UI.MainWindow.StatusBar", mainWindow:GetContent())
	local statusText = UICreateFrame("Text", addonID .. ".UI.MainWindow.StatusText", statusPanel:GetContent())

	local refreshButton = UICreateFrame("Texture", addonID .. ".UI.MainWindow.RefreshButton", mainWindow:GetContent())
	
	local refreshEnabled = false

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
	
	local function ShowBananAH()
		mainContext:SetLayer(UI.Native.Auction:GetLayer() + 1)
		mainWindow:SetVisible(true)
		if mainWindow:GetTop() < 0 then
			mainWindow:ClearAll()
			mainWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			mainWindow:SetWidth(DEFAULT_WIDTH)
			mainWindow:SetHeight(DEFAULT_HEIGHT)
		end
		ShowSelectedFrame(mainTab:GetSelectedFrame())
	end	
	
	mapContext:SetStrata("hud")

	mapIcon:SetPoint("CENTER", UNMapMini, "BOTTOMLEFT", 24, -25)
	mapIcon:SetTextureAsync(addonID, "Textures/MapIcon.png")
	mapIcon:SetVisible(InternalInterface.AccountSettings.General.ShowMapIcon or false)
	InternalInterface.UI.MapIcon = mapIcon
	
	mainWindow:SetVisible(false)
	mainWindow:SetMinWidth(MIN_WIDTH)
	mainWindow:SetMinHeight(MIN_HEIGHT)
	mainWindow:SetWidth(DEFAULT_WIDTH)
	mainWindow:SetHeight(DEFAULT_HEIGHT)
	mainWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- TODO Get from config
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
	mainTab:AddTab("bids", L["Main/MenuBids"], nil)
	mainTab:AddTab("history", L["Main/MenuHistory"], nil)
	mainTab:AddTab("config", L["Main/MenuConfig"], configFrame)
	
	queueManager:SetPoint("BOTTOMRIGHT", mainWindow:GetContent(), "BOTTOMRIGHT", -5, -5)
	queueManager:SetPoint("TOPLEFT", mainWindow:GetContent(), "BOTTOMRIGHT", -125, -35)

	statusPanel:SetPoint("TOPLEFT", mainWindow:GetContent(), "BOTTOMLEFT", 5, -35)
	statusPanel:SetPoint("BOTTOMRIGHT", queueManager, "BOTTOMLEFT", -5, 0)
	statusPanel:GetContent():SetBackgroundColor(0.2, 0.2, 0.2, 0.5)
	
	statusText:SetPoint("CENTERLEFT", statusPanel:GetContent(), "CENTERLEFT", 5, 0)
	statusText:SetPoint("CENTERRIGHT", statusPanel:GetContent(), "CENTERRIGHT", -5, 0)
	
	refreshButton:SetTextureAsync(addonID, "Textures/RefreshDisabled.png")
	refreshButton:SetPoint("TOPRIGHT", mainWindow:GetContent(), "TOPRIGHT", -20, 5)
	refreshButton:SetPoint("BOTTOMLEFT", mainWindow:GetContent(), "TOPRIGHT", -56, 41)

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
	
	function refreshButton.Event:MouseIn()
		self:SetTextureAsync(addonID, refreshEnabled and "Textures/RefreshOn.png" or "Textures/RefreshDisabled.png")
	end
	
	function refreshButton.Event:MouseOut()
		self:SetTextureAsync(addonID, refreshEnabled and "Textures/RefreshOff.png" or "Textures/RefreshDisabled.png")
	end
	
	function refreshButton.Event:LeftClick()
		if not refreshEnabled then return end
		if not pcall(CAScan, { type = "search", sort = "time", sortOrder = "descending" }) then
			Write(L["Main/FullScanError"])
		else
			Write(L["Main/FullScanStarted"])
		end
	end	
	
	local function OnInteractionChanged(interaction, state)
		if interaction == "auction" then
			refreshEnabled = state
			refreshButton:SetTextureAsync(addonID, state and "Textures/RefreshOff.png" or "Textures/RefreshDisabled.png")
		end
	end
	TInsert(Event.Interaction, { OnInteractionChanged, addonID, addonID .. ".OnInteractionChanged" })
	
	local function ReportAuctionData(scanType, total, new, updated, removed, before)
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
end

local function OnAddonLoaded(addonId)
	if addonId == addonID then 
		InitializeLayout()
	end 
end
TInsert(Event.Addon.Load.End, { OnAddonLoaded, addonID, addonID .. ".OnAddonLoaded" })
