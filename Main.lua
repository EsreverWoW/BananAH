local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L
local GetOutput = InternalInterface.Utility.GetOutput
local function out(value) GetOutput()(value) end

local function InitializeLayout()
	local mapContext = UI.CreateContext(addonID .. ".UI.MapContext")
	local mapIcon = UI.CreateFrame("Texture", addonID .. ".UI.MapIcon", mapContext)

	local mainContext = UI.CreateContext(addonID .. ".UI.MainContext")
	local mainWindow = UI.CreateFrame("BWindow", addonID .. ".UI.MainWindow", mainContext)
	local searchTab = UI.CreateFrame("BPanel", addonID .. ".UI.MainWindow.SearchTab", mainWindow:GetContent())
	local postTab = UI.CreateFrame("BPanel", addonID .. ".UI.MainWindow.PostTab", mainWindow:GetContent())
	local auctionsTab = UI.CreateFrame("BPanel", addonID .. ".UI.MainWindow.AuctionsTab", mainWindow:GetContent())
	local bidsTab = UI.CreateFrame("BPanel", addonID .. ".UI.MainWindow.BidsTab", mainWindow:GetContent())
	local historyTab = UI.CreateFrame("BPanel", addonID .. ".UI.MainWindow.HistoryTab", mainWindow:GetContent())
	local configTab = UI.CreateFrame("BPanel", addonID .. ".UI.MainWindow.ConfigTab", mainWindow:GetContent())
	local mainPanel = UI.CreateFrame("BPanel", addonID .. ".UI.MainWindow.Panel", mainWindow:GetContent())
	local statusPanel = UI.CreateFrame("BPanel", addonID .. ".UI.MainWindow.StatusBar", mainWindow:GetContent())
	local statusText = UI.CreateFrame("Text", addonID .. ".UI.MainWindow.StatusText", statusPanel:GetContent())
	local scannerButton = UI.CreateFrame("Texture", addonID .. ".UI.MainWindow.ScannerButton", statusPanel:GetContent())
	local refreshButton = UI.CreateFrame("Texture", addonID .. ".UI.MainWindow.RefreshButton", mainWindow:GetContent())
	local searchText = UI.CreateFrame("BShadowedText", addonID .. ".UI.MainWindow.SearchTab.Text", searchTab:GetContent())
	local postText = UI.CreateFrame("BShadowedText", addonID .. ".UI.MainWindow.PostTab.Text", postTab:GetContent())
	local postFrame = InternalInterface.UI.PostingFrame(addonID .. ".UI.MainWindow.PostFrame", mainPanel:GetContent())
	local auctionsText = UI.CreateFrame("BShadowedText", addonID .. ".UI.MainWindow.AuctionsTab.Text", auctionsTab:GetContent())
	local bidsText = UI.CreateFrame("BShadowedText", addonID .. ".UI.MainWindow.BidsTab.Text", bidsTab:GetContent())
	local historyText = UI.CreateFrame("BShadowedText", addonID .. ".UI.MainWindow.HistoryTab.Text", historyTab:GetContent())
	local configText = UI.CreateFrame("BShadowedText", addonID .. ".UI.MainWindow.ConfigTab.Text", configTab:GetContent())
	local configFrame = InternalInterface.UI.ConfigFrame(addonID .. ".UI.MainWindow.ConfigFrame", mainPanel:GetContent())

	mapContext:SetStrata("hud")

	mapIcon:SetPoint("CENTER", UI.Native.MapMini, "BOTTOMLEFT", 24, -25)
	mapIcon:SetTexture(addonID, "Textures/MapIcon.png")
	mapIcon:SetVisible(InternalInterface.AccountSettings.General.showMapIcon or false)
	InternalInterface.UI.MapIcon = mapIcon
	
	mainWindow:SetVisible(false)
	mainWindow:SetMinWidth(1280)
	mainWindow:SetMinHeight(768)
	mainWindow:SetWidth(1280)
	mainWindow:SetHeight(798)
	mainWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- TODO Get from config
	mainWindow:SetTitle(addonID)
	mainWindow:SetAlpha(1)
	mainWindow:SetCloseable(true)
	mainWindow:SetDraggable(true)
	mainWindow:SetResizable(false)
	
	searchTab:SetPoint("TOPLEFT", mainWindow:GetContent(), "TOPLEFT", 20, 20)
	searchTab:SetPoint("BOTTOMLEFT", mainWindow:GetContent(), "TOPLEFT", 20, 64)
	searchTab.borderFrame.cornerBottomLeft:SetVisible(false)
	searchTab.borderFrame.borderBottom:SetVisible(false)
	searchTab.borderFrame.cornerBottomRight:SetVisible(false)
	searchTab:SetLayer(1)

	postTab:SetPoint("TOPLEFT", searchTab, "TOPRIGHT", 10, 0)
	postTab:SetPoint("BOTTOMLEFT", searchTab, "BOTTOMRIGHT", 10, 0) 
	postTab.borderFrame.cornerBottomLeft:SetVisible(false)
	postTab.borderFrame.borderBottom:SetVisible(false)
	postTab.borderFrame.cornerBottomRight:SetVisible(false)
	postTab:SetLayer(1)

	auctionsTab:SetPoint("TOPLEFT", postTab, "TOPRIGHT", 10, 0)
	auctionsTab:SetPoint("BOTTOMLEFT", postTab, "BOTTOMRIGHT", 10, 0) 
	auctionsTab.borderFrame.cornerBottomLeft:SetVisible(false)
	auctionsTab.borderFrame.borderBottom:SetVisible(false)
	auctionsTab.borderFrame.cornerBottomRight:SetVisible(false)
	auctionsTab:SetLayer(1)

	bidsTab:SetPoint("TOPLEFT", auctionsTab, "TOPRIGHT", 10, 0)
	bidsTab:SetPoint("BOTTOMLEFT", auctionsTab, "BOTTOMRIGHT", 10, 0) 
	bidsTab.borderFrame.cornerBottomLeft:SetVisible(false)
	bidsTab.borderFrame.borderBottom:SetVisible(false)
	bidsTab.borderFrame.cornerBottomRight:SetVisible(false)
	bidsTab:SetLayer(1)

	historyTab:SetPoint("TOPLEFT", bidsTab, "TOPRIGHT", 10, 0)
	historyTab:SetPoint("BOTTOMLEFT", bidsTab, "BOTTOMRIGHT", 10, 0) 
	historyTab.borderFrame.cornerBottomLeft:SetVisible(false)
	historyTab.borderFrame.borderBottom:SetVisible(false)
	historyTab.borderFrame.cornerBottomRight:SetVisible(false)
	historyTab:SetLayer(1)

	configTab:SetPoint("TOPLEFT", historyTab, "TOPRIGHT", 10, 0)
	configTab:SetPoint("BOTTOMLEFT", historyTab, "BOTTOMRIGHT", 10, 0) 
	configTab.borderFrame.cornerBottomLeft:SetVisible(false)
	configTab.borderFrame.borderBottom:SetVisible(false)
	configTab.borderFrame.cornerBottomRight:SetVisible(false)
	configTab:SetLayer(1)

	mainPanel:SetPoint("TOPLEFT", mainWindow:GetContent(), "TOPLEFT", 5, 60)
	mainPanel:SetPoint("BOTTOMRIGHT", mainWindow:GetContent(), "BOTTOMRIGHT", -5, -35)
	mainPanel:SetLayer(2)
	
	statusPanel:SetPoint("TOPLEFT", mainWindow:GetContent(), "BOTTOMLEFT", 3, -33)
	statusPanel:SetPoint("BOTTOMRIGHT", mainWindow:GetContent(), "BOTTOMRIGHT", -3, -3)
	statusPanel:SetInvertedBorder(true)
	statusPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	scannerButton:SetTexture(addonID, _G[addonID].GetBackgroundScannerEnabled() and "Textures/SearchIcon.png" or "Textures/DontSearchIcon.png")
	scannerButton:SetPoint("CENTERRIGHT", statusPanel:GetContent(), "CENTERRIGHT", -2, 0)
	scannerButton:SetWidth(16)
	scannerButton:SetHeight(16)
	
	statusText:SetPoint("CENTERLEFT", statusPanel:GetContent(), "CENTERLEFT", 5, 0)
	statusText:SetPoint("CENTERRIGHT", scannerButton, "CENTERLEFT", -2, 0)
	
	refreshButton:SetTexture(addonID, "Textures/RefreshDisabled.png")
	refreshButton:SetPoint("TOPRIGHT", mainWindow:GetContent(), "TOPRIGHT", -20, 5)
	refreshButton.enabled = false

	searchText:SetPoint("CENTER", searchTab, "CENTER", 0, 2)
	searchText:SetText(L["General/menuSearch"])
	searchText:SetFontSize(16)
	searchText:SetShadowOffset(2, 2)
	searchText:SetFontColor(0.5, 0.5, 0.5, 1)
	searchTab:SetWidth(searchText:GetWidth() + 60)
	
	postText:SetPoint("CENTER", postTab, "CENTER", 0, 2)
	postText:SetText(L["General/menuPost"])
	postText:SetFontSize(16)
	postText:SetShadowOffset(2, 2)
	postText:SetFontColor(0.75, 0.75, 0.5, 1)
	postTab:SetWidth(postText:GetWidth() + 60)
	postTab.text = postText
	
	postFrame:SetAllPoints()
	postFrame:SetVisible(false)
	postTab.frame = postFrame
	
	auctionsText:SetPoint("CENTER", auctionsTab, "CENTER", 0, 2)
	auctionsText:SetText(L["General/menuAuctions"])
	auctionsText:SetFontSize(16)
	auctionsText:SetShadowOffset(2, 2)
	auctionsText:SetFontColor(0.5, 0.5, 0.5, 1)
	auctionsTab:SetWidth(auctionsText:GetWidth() + 60)
	
	bidsText:SetPoint("CENTER", bidsTab, "CENTER", 0, 2)
	bidsText:SetText(L["General/menuBids"])
	bidsText:SetFontSize(16)
	bidsText:SetShadowOffset(2, 2)
	bidsText:SetFontColor(0.5, 0.5, 0.5, 1)
	bidsTab:SetWidth(bidsText:GetWidth() + 60)
	
	historyText:SetPoint("CENTER", historyTab, "CENTER", 0, 2)
	historyText:SetText(L["General/menuHistory"])
	historyText:SetFontSize(16)
	historyText:SetShadowOffset(2, 2)
	historyText:SetFontColor(0.5, 0.5, 0.5, 1)
	historyTab:SetWidth(historyText:GetWidth() + 60)
	
	configText:SetPoint("CENTER", configTab, "CENTER", 0, 2)
	configText:SetText(L["General/menuConfig"])
	configText:SetFontSize(16)
	configText:SetShadowOffset(2, 2)
	configText:SetFontColor(0.75, 0.75, 0.5, 1)
	configTab:SetWidth(configText:GetWidth() + 60)
	configTab.text = configText
	
	configFrame:SetAllPoints()
	configFrame:SetVisible(false)
	configTab.frame = configFrame
	
	local function ShowBananAH(hEvent)
		mainContext:SetLayer(UI.Native.Auction:GetLayer() + 1)
		mainWindow:SetVisible(true)
		if mainWindow:GetTop() < 0 then
			mainWindow:ClearAll()
			mainWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			mainWindow:SetWidth(1280)
			mainWindow:SetHeight(768)
		end
		mainWindow.selectedTab.frame:SetVisible(true)
		pcall(mainWindow.selectedTab.frame.Show, mainWindow.selectedTab.frame, hEvent)
	end
	
	function mainWindow.Event:Close()
		mainWindow.selectedTab.frame:SetVisible(false)
	end
	
	function UI.Native.MapMini.Event:Layer()
		mapContext:SetLayer(UI.Native.MapMini:GetLayer() + 1)
	end

	function mapIcon.Event:LeftClick()
		local wasVisible = mainWindow:GetVisible()
		if not wasVisible then
			ShowBananAH(true)
		else
			mainWindow:Close()
		end
	end
	
	function UI.Native.Auction.Event:Loaded()
		if UI.Native.Auction:GetLoaded() and InternalInterface.AccountSettings.General.autoOpen then
			ShowBananAH(false)
		end
		if not UI.Native.Auction:GetLoaded() and InternalInterface.AccountSettings.General.autoClose then
			mainWindow:Close()
		end
	end
	
	function refreshButton.Event:MouseIn()
		if self.enabled then
			self:SetTexture(addonID, "Textures/RefreshOn.png")
		else
			self:SetTexture(addonID, "Textures/RefreshDisabled.png")
		end
	end
	function refreshButton.Event:MouseOut()
		if self.enabled then
			self:SetTexture(addonID, "Textures/RefreshOff.png")
		else
			self:SetTexture(addonID, "Textures/RefreshDisabled.png")
		end
	end
	function refreshButton.Event:LeftClick()
		if not self.enabled then return end
		if not pcall(Command.Auction.Scan, { type="search", sort = "time", sortOrder = "descending" }) then
			out(L["General/fullScanError"])
		else
			InternalInterface.ScanNext()
			out(L["General/fullScanStarted"])
		end
	end	
	
	function scannerButton.Event:LeftClick()
		local newState = not _G[addonID].GetBackgroundScannerEnabled()
		_G[addonID].SetBackgroundScannerEnabled(newState)
		self:SetTexture(addonID, newState and "Textures/SearchIcon.png" or "Textures/DontSearchIcon.png")
	end

	local function TabMouseIn(self)
		self.text:SetFontSize(18)
	end
	local function TabMouseOut(self)
		self.text:SetFontSize(16)
	end
	local function TabLeftClick(self)
		if mainWindow.selectedTab then
			mainWindow.selectedTab.text:SetFontColor(0.75, 0.75, 0.5, 1)
			mainWindow.selectedTab.frame:SetVisible(false)
		end
		mainWindow.selectedTab = self
		mainWindow.selectedTab.text:SetFontColor(1, 1, 1, 1)
		mainWindow.selectedTab.frame:SetVisible(true)
		pcall(mainWindow.selectedTab.frame.Show, mainWindow.selectedTab.frame)
	end
	
	postTab.Event.MouseIn = TabMouseIn
	postTab.Event.MouseOut = TabMouseOut
	postTab.Event.LeftClick = TabLeftClick
	configTab.Event.MouseIn = TabMouseIn
	configTab.Event.MouseOut = TabMouseOut
	configTab.Event.LeftClick = TabLeftClick
	mainWindow.selectedTab = postTab
	mainWindow.selectedTab.text:SetFontColor(1, 1, 1, 1)
	
	local function OnInteractionChanged(interaction, state)
		if interaction == "auction" then
			refreshButton.enabled = state
			refreshButton:SetTexture(addonID, state and "Textures/RefreshOff.png" or "Textures/RefreshDisabled.png")
		end
	end
	table.insert(Event.Interaction, { OnInteractionChanged, addonID, "OnInteractionChanged" })
	
	local function ReportAuctionData(full, total, new, updated, removed, before)
		local fullOrPartialMessage = full and L["General/scanTypeFull"] or L["General/scanTypePartial"]
		local newMessage = (#new > 0) and string.format(L["General/scanNewCount"], #new) or ""
		local updatedMessage = (#updated > 0) and string.format(L["General/scanUpdatedCount"], #updated) or ""
		local removedMessage = (#removed > 0) and string.format(L["General/scanRemovedCount"], #removed, #before) or ""
		local message = string.format(L["General/scanMessage"], fullOrPartialMessage, #total, newMessage, updatedMessage, removedMessage)
		out(message)
	end
	table.insert(Event[addonID].AuctionData, { ReportAuctionData, addonID, "ReportAuctionData" })

	local slashEvent1 = Command.Slash.Register("bananah")
	local slashEvent2 = Command.Slash.Register("bah")
	if slashEvent1 then
		table.insert(slashEvent1, {function() ShowBananAH(true) end, addonID, "ShowBananAH1"})
	end
	if slashEvent2 then
		table.insert(slashEvent2, {function() ShowBananAH(true) end, addonID, "ShowBananAH2"})
	elseif not slashEvent1 then
		out(L["General/slashRegisterError"])
	end
	
	local function StatusBarOutput(value)
		statusText:SetText(value and tostring(value) or "")
	end
	InternalInterface.Utility.SetOutput(StatusBarOutput)
end

local function OnAddonLoaded(addonId)
	if addonId == addonID then 
		InitializeLayout()
	end 
end
table.insert(Event.Addon.Load.End, { OnAddonLoaded, addonID, "OnAddonLoaded" })
