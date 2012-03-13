local _, InternalInterface = ...

local FixItemType = InternalInterface.Utility.FixItemType
local L = InternalInterface.Localization.L

local savedPostParams = {}

local useMapIcon = true

local function InitializeLayout()
	local context = UI.CreateContext("BananAH.UI.Context")
	local mainWindow = UI.CreateFrame("BWindow", "BananAH.UI.MainWindow", context)
	local refreshButton = UI.CreateFrame("Texture", "BananAH.UI.MainWindow.RefreshButton", mainWindow:GetContent())
	local postPanel = UI.CreateFrame("BPanel", "BananAH.UI.MainWindow.PostPanel", mainWindow:GetContent())
	local itemSelector = InternalInterface.UI.ItemSelector("BananAH.UI.MainWindow.PostPanel.ItemSelector", postPanel:GetContent())
	local auctionSelector = InternalInterface.UI.AuctionSelector("BananAH.UI.MainWindow.PostPanel.AuctionSelector", postPanel:GetContent())
	local postSelector = InternalInterface.UI.PostSelector("BananAH.UI.MainWindow.PostPanel.PostSelector", postPanel:GetContent())
	local queuePanel = UI.CreateFrame("BDataGrid", "BananAH.UI.MainWindow.QueuePanel", postPanel:GetContent())

	local function ShowBananAH()
		if UI.Native.Auction:GetLoaded() then
			context:SetLayer(UI.Native.Auction:GetLayer() + 1)
		end
		itemSelector:ResetItems()
		mainWindow:SetVisible(true)
		if mainWindow:GetTop() < 0 then
			mainWindow:ClearAll()
			mainWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			mainWindow:SetWidth(1280)
			mainWindow:SetHeight(768)
		end
	end	
	
	-- Map Icon
	if useMapIcon then
		local mapContext = UI.CreateContext("BananAH.UI.MapContext")
		local mapIcon = UI.CreateFrame("Texture", "BananAH.UI.MapIcon", mapContext)
		mapIcon:SetTexture("BananAH", "Textures/MapIcon.png")
		mapIcon:SetPoint("CENTER", UI.Native.MapMini, "BOTTOMLEFT", 24, -25)
		function mapIcon.Event:LeftClick()
			-- mainWindow:SetVisible(not mainWindow:GetVisible())
			ShowBananAH()
		end
	end
	
	mainWindow:SetVisible(false)
	mainWindow:SetMinWidth(1280)
	mainWindow:SetMinHeight(768)
	mainWindow:SetWidth(1280)
	mainWindow:SetHeight(768)
	mainWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	mainWindow:SetTitle("BananAH")
	mainWindow:SetAlpha(1)
	mainWindow:SetCloseable(true)
	mainWindow:SetDraggable(true)
	mainWindow:SetResizable(false)
	
	postPanel:SetPoint("TOPLEFT", mainWindow:GetContent(), "TOPLEFT", 5, 60)
	postPanel:SetPoint("BOTTOMRIGHT", mainWindow:GetContent(), "BOTTOMRIGHT", -5, -5)
	
	itemSelector:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPLEFT", 5, 5)
	itemSelector:SetPoint("BOTTOMRIGHT", postPanel:GetContent(), "BOTTOMLEFT", 295, -5) -- 370
	function itemSelector.Event:ItemSelected(item, itemInfo)
		postSelector:SetItem(item, itemInfo)
		auctionSelector:SetItem(item)
	end	
	itemSelector:GetParent().itemSelector = itemSelector
	
	auctionSelector:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPLEFT", 300, 335)
	auctionSelector:SetPoint("BOTTOMRIGHT", postPanel:GetContent(), "BOTTOMRIGHT", -5, -5)
	
	postSelector:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPLEFT", 300, 5)
	postSelector:SetPoint("BOTTOMRIGHT", postPanel:GetContent(), "TOPRIGHT", -310, 330)
	
	queuePanel:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPRIGHT", -300, 70)
	queuePanel:SetPoint("BOTTOMRIGHT", postPanel:GetContent(), "TOPRIGHT", -5, 330)
	
	refreshButton:SetTexture("BananAH", "Textures/RefreshDisabled.png")
	refreshButton:SetPoint("TOPRIGHT", mainWindow:GetContent(), "TOPRIGHT", -10, 5)
	refreshButton.enabled = false
	function refreshButton.Event:MouseIn()
		if self.enabled then
			self:SetTexture("BananAH", "Textures/RefreshOn.png")
		else
			self:SetTexture("BananAH", "Textures/RefreshDisabled.png")
		end
	end
	function refreshButton.Event:MouseOut()
		if self.enabled then
			self:SetTexture("BananAH", "Textures/RefreshOff.png")
		else
			self:SetTexture("BananAH", "Textures/RefreshDisabled.png")
		end
	end
	function refreshButton.Event:LeftClick()
		if not self.enabled then return end
		if not pcall(Command.Auction.Scan, {type="search"}) then
			print(L["General/fullScanError"])
		else
			print(L["General/fullScanStarted"])
		end
	end	

	local function RelayInteractionChanged(interaction, state)
		if interaction == "auction" then
			refreshButton.enabled = state
			refreshButton:SetTexture("BananAH", state and "Textures/RefreshOff.png" or "Textures/RefreshDisabled.png")
		end
	end
	table.insert(Event.Interaction, { RelayInteractionChanged, "BananAH", "RelayInteractionChanged" })
	
	local function ReportAuctionData(full, total, new, updated, removed, before)
		local fullOrPartialMessage = full and L["General/scanTypeFull"] or L["General/scanTypePartial"]
		local newMessage = (new > 0) and string.format(L["General/scanNewCount"], new) or ""
		local updatedMessage = (updated > 0) and string.format(L["General/scanUpdatedCount"], updated) or ""
		local removedMessage = (removed > 0) and string.format(L["General/scanRemovedCount"], removed, before) or ""
		local message = string.format(L["General/scanMessage"], fullOrPartialMessage, total, newMessage, updatedMessage, removedMessage)
		print(message)
	end
	table.insert(Event.BananAH.AuctionData, { ReportAuctionData, "BananAH", "ReportAuctionData" })

	local slashEvent1 = Command.Slash.Register("bananah")
	local slashEvent2 = Command.Slash.Register("bah")
	if slashEvent1 then
		table.insert(slashEvent1, {ShowBananAH, "BananAH", "ShowBananAH1"})
	end
	if slashEvent2 then
		table.insert(slashEvent2, {ShowBananAH, "BananAH", "ShowBananAH2"})
	elseif not slashEvent1 then
		print(L["General/slashRegisterError"])
	end
end

local function LoadPostingParameters(addonId)
	if addonId == "BananAH" then
		savedPostParams = BananAHPostingParameters or {}
	end
end
table.insert(Event.Addon.SavedVariables.Load.End, {LoadPostingParameters, "BananAH", "LoadPostingParameters"})

local function SavePostingParameters(addonId)
	if addonId == "BananAH" then
		BananAHPostingParameters = savedPostParams
	end
end
table.insert(Event.Addon.SavedVariables.Save.Begin, {SavePostingParameters, "BananAH", "SavePostingParameters"})

local function OnAddonLoaded(addonId)
	if addonId == "BananAH" then 
		InitializeLayout()
	end 
end
table.insert(Event.Addon.Load.End, { OnAddonLoaded, "BananAH", "OnAddonLoaded" })

-- local function TestDataGrid()
	-- local context = UI.CreateContext("BananAH.UI.TestContext")
	-- local testWindow = UI.CreateFrame("BWindow", "BananAH.UI.TestWindow", context)
	-- testWindow:SetVisible(true)
	-- testWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	-- testWindow:SetTitle("Test Window")
	-- testWindow:SetAlpha(1)
	-- testWindow:SetCloseable(true)
	-- testWindow:SetDraggable(true)
	-- testWindow:SetResizable(true)
	-- local dataGrid = UI.CreateFrame("BDataGrid", "BananAH.UI.DataGrid", testWindow:GetContent())
	-- dataGrid:SetAllPoints()
-- end

--TestDataGrid()

