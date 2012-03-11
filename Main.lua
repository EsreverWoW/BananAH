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
	local selectedItemTexturePanelExt = UI.CreateFrame("BPanel", "BananAH.UI.MainWindow.SelectedItemTexturePanelExt", postPanel:GetContent())
	local selectedItemTexturePanelInt = UI.CreateFrame("BPanel", "BananAH.UI.MainWindow.SelectedItemTexturePanelInt", selectedItemTexturePanelExt:GetContent())
	local selectedItemTexture = UI.CreateFrame("Texture", "BananAH.UI.MainWindow.SelectedItemTexture", selectedItemTexturePanelInt:GetContent())
	local selectedItemNameLabel = UI.CreateFrame("Text", "BananAH.UI.MainWindow.SelectedItemNameLabel", postPanel:GetContent())
	local stackSizeLabel = UI.CreateFrame("Text", "BananAH.UI.MainWindow.PostPanel.StackSizeLabel", postPanel:GetContent())
	local stackSizeLabelShadow = UI.CreateFrame("Text", "BananAH.UI.MainWindow.PostPanel.StackSizeShadow", postPanel:GetContent())
	local stackSizeSelector = UI.CreateFrame("BSlider", "BananAH.UI.MainWindow.PostPanel.StackSizeSelector", postPanel:GetContent())
	local stackNumberLabel = UI.CreateFrame("Text", "BananAH.UI.MainWindow.PostPanel.StackNumberLabel", postPanel:GetContent())
	local stackNumberLabelShadow = UI.CreateFrame("Text", "BananAH.UI.MainWindow.PostPanel.StackNumberLabelShadow", postPanel:GetContent())
	local stackNumberSelector = UI.CreateFrame("BSlider", "BananAH.UI.MainWindow.PostPanel.StackNumberSelector", postPanel:GetContent())
	local bidLabel = UI.CreateFrame("Text", "BananAH.UI.MainWindow.PostPanel.BidLabel", postPanel:GetContent())
	local bidLabelShadow = UI.CreateFrame("Text", "BananAH.UI.MainWindow.PostPanel.BidShadow", postPanel:GetContent())
	local bidMoneySelector = UI.CreateFrame("BMoneySelector", "BananAH.UI.MainWindow.PostPanel.BidMoneySelector", postPanel:GetContent())
	local buyLabel = UI.CreateFrame("Text", "BananAH.UI.MainWindow.PostPanel.BuyLabel", postPanel:GetContent())
	local buyLabelShadow = UI.CreateFrame("Text", "BananAH.UI.MainWindow.PostPanel.BuyShadow", postPanel:GetContent())
	local buyMoneySelector = UI.CreateFrame("BMoneySelector", "BananAH.UI.MainWindow.PostPanel.BuyMoneySelector", postPanel:GetContent())
	local durationLabel = UI.CreateFrame("Text", "BananAH.UI.MainWindow.PostPanel.DurationLabel", postPanel:GetContent())
	local durationLabelShadow = UI.CreateFrame("Text", "BananAH.UI.MainWindow.PostPanel.DurationShadow", postPanel:GetContent())
	local durationSlider = UI.CreateFrame("RiftSlider", "BananAH.UI.MainWindow.PostPanel.DurationSlider", postPanel:GetContent())
	local durationTimeLabel = UI.CreateFrame("Text", "BananAH.UI.MainWindow.PostPanel.DurationTimeLabel", postPanel:GetContent())
	local undercutButton = UI.CreateFrame("RiftButton", "BananAH.UI.MainWindow.PostPanel.UndercutButton", postPanel:GetContent())
	local postButton = UI.CreateFrame("RiftButton", "BananAH.UI.MainWindow.PostPanel.PostButton", postPanel:GetContent())

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
	function itemSelector.Event:ItemSelected(item)
		auctionSelector:SetItem(item)
		if item then
			local auctions, lastUpdate = BananAH.GetActiveAuctionData(item)
			local itemDetail = Inspect.Item.Detail(item)
			local stackSize = itemDetail.stackMax or 1
			local bidPrice = itemDetail.sell or 1
			local buyPrice = itemDetail.sell or 1
			local duration = 3
			local postParams = savedPostParams[FixItemType(itemDetail.type)]
			if postParams then
				stackSize = postParams.stackSize or stackSize
				bidPrice = postParams.bidPrice or bidPrice
				buyPrice = postParams.buyPrice or buyPrice
				duration = postParams.duration or duration
			end
			
			stackSizeSelector:SetRange(1, itemDetail.stackMax or 1)
			stackSizeSelector:SetPosition(stackSize)
			selectedItemTexture:SetVisible(true)
			selectedItemTexture:SetTexture("Rift", itemDetail.icon)
			selectedItemNameLabel:SetText(itemDetail.name)
			selectedItemNameLabel:SetVisible(true)
			bidMoneySelector:SetValue(bidPrice)
			buyMoneySelector:SetValue(buyPrice)
			durationSlider:SetPosition(duration)
			local minBid = nil
			local minBuy = nil
			local minBidSelf = false
			local minBuySelf = false
			local userName = Inspect.Unit.Detail("player").name
			for _, auctionData in pairs(auctions) do
				local bidUnit = math.ceil((auctionData.bidPrice or 0) / (auctionData.stack or 1))
				local buyUnit = math.ceil((auctionData.buyoutPrice or 0) / (auctionData.stack or 1))
				if bidUnit > 0 and (not minBid or (bidUnit <= minBid)) then
					minBid = bidUnit
					minBidSelf = minBidSelf or (userName == auctionData.sellerName)
				end
				if buyUnit > 0 and (not minBuy or (buyUnit <= minBuy)) then
					minBuy = buyUnit
					minBuySelf = minBuySelf or (userName == auctionData.sellerName)
				end
			end
			if minBid and not minBidSelf then minBid = minBid - 1 end
			if minBuy and not minBuySelf then minBuy = minBuy - 1 end
			undercutButton:SetEnabled(minBid ~= nil or minBuy ~= nil)
			undercutButton.minBid = minBid
			undercutButton.minBuy = minBuy
			postButton:SetEnabled(Inspect.Interaction("auction"))
		else
			stackSizeSelector:SetRange(0, 0)
			selectedItemTexture:SetVisible(false)
			selectedItemNameLabel:SetVisible(false)
			bidMoneySelector:SetValue(0)
			buyMoneySelector:SetValue(0)
			undercutButton:SetEnabled(false)
			postButton:SetEnabled(false)
		end
	end	
	itemSelector:GetParent().itemSelector = itemSelector
	
	auctionSelector:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPLEFT", 300, 240)
	auctionSelector:SetPoint("BOTTOMRIGHT", postPanel:GetContent(), "BOTTOMRIGHT", -5, -5)

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
			postButton:SetEnabled(state)
		end
	end
	table.insert(Event.Interaction, { RelayInteractionChanged, "BananAH", "RelayInteractionChanged" })
	

	selectedItemTexturePanelExt:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPLEFT", 300, 5)
	selectedItemTexturePanelExt:SetPoint("BOTTOMRIGHT", postPanel:GetContent(), "TOPLEFT", 370, 75)
	selectedItemTexturePanelInt:SetAllPoints()
	selectedItemTexturePanelInt:SetInvertedBorder(true)
	selectedItemTexturePanelInt:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
	selectedItemTexture:SetAllPoints()
	selectedItemTexture:SetVisible(false)
	selectedItemNameLabel:SetPoint("BOTTOMLEFT", selectedItemTexturePanelExt, "CENTERRIGHT", 5, 5)
	selectedItemNameLabel:SetFontSize(20)
	selectedItemNameLabel:SetText("")
	selectedItemNameLabel:SetVisible(false)
	
	stackSizeLabel:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPLEFT", 340, 100)
	stackSizeLabel:SetFontColor(1, 1, 0.75, 1)
	stackSizeLabel:SetFontSize(14)
	stackSizeLabel:SetText(L["PostingPanel/labelStackSize"])
	stackSizeLabelShadow:SetPoint("CENTER", stackSizeLabel, "CENTER", 2, 2)
	stackSizeLabelShadow:SetFontColor(0, 0, 0, 0.25)
	stackSizeLabelShadow:SetFontSize(stackSizeLabel:GetFontSize())
	stackSizeLabelShadow:SetLayer(stackSizeLabel:GetLayer() - 1)
	stackSizeLabelShadow:SetText(stackSizeLabel:GetText())
	stackSizeSelector:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPLEFT", 300, 115)
	stackSizeSelector:SetPoint("BOTTOMRIGHT", postPanel:GetContent(), "TOPLEFT", 800, 165)
	function stackSizeSelector.Event:PositionChanged(stackSize)
		local selectedItem, selectedInfo = itemSelector:GetSelectedItem()
		if stackSize > 0 and selectedItem then
			local stacks = selectedInfo.stack
			local maxNumberOfStacks = math.ceil(stacks / stackSize)
			stackNumberSelector:SetRange(1, maxNumberOfStacks)
			stackNumberSelector:SetPosition(maxNumberOfStacks)
		else
			stackNumberSelector:SetRange(0, 0)
		end
	end

	stackNumberLabel:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPLEFT", 340, 170)
	stackNumberLabel:SetFontColor(1, 1, 0.75, 1)
	stackNumberLabel:SetFontSize(14)
	stackNumberLabel:SetText(L["PostingPanel/labelStackNumber"])
	stackNumberLabelShadow:SetPoint("CENTER", stackNumberLabel, "CENTER", 2, 2)
	stackNumberLabelShadow:SetFontColor(0, 0, 0, 0.25)
	stackNumberLabelShadow:SetFontSize(stackNumberLabel:GetFontSize())
	stackNumberLabelShadow:SetLayer(stackNumberLabel:GetLayer() - 1)
	stackNumberLabelShadow:SetText(stackNumberLabel:GetText())
	stackNumberSelector:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPLEFT", 300, 185)
	stackNumberSelector:SetPoint("BOTTOMRIGHT", postPanel:GetContent(), "TOPLEFT", 800, 235)
	
	undercutButton:SetPoint("BOTTOMCENTER", postPanel:GetContent(), "TOPRIGHT", -105, 50)
	undercutButton:SetText(L["PostingPanel/buttonUndercut"])
	undercutButton:SetEnabled(false)
	function undercutButton.Event:LeftPress()
		if self.minBid then
			bidMoneySelector:SetValue(self.minBid)
		end
		if self.minBuy then
			buyMoneySelector:SetValue(self.minBuy)
		end
	end
	
	bidLabel:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPRIGHT", -400, 70)
	bidLabel:SetFontColor(1, 1, 0.75, 1)
	bidLabel:SetFontSize(14)
	bidLabel:SetText(L["PostingPanel/labelUnitBid"])
	bidLabelShadow:SetPoint("CENTER", bidLabel, "CENTER", 2, 2)
	bidLabelShadow:SetFontColor(0, 0, 0, 0.25)
	bidLabelShadow:SetFontSize(bidLabel:GetFontSize())
	bidLabelShadow:SetLayer(bidLabel:GetLayer() - 1)
	bidLabelShadow:SetText(bidLabel:GetText())
	bidMoneySelector:SetPoint("TOPRIGHT", postPanel:GetContent(), "TOPRIGHT", -5, 65)
	bidMoneySelector:SetPoint("BOTTOMLEFT", postPanel:GetContent(), "TOPRIGHT", -220, 95)
	-- function bidMoneySelector.Event:ValueChanged(newValue)
		-- local buy = buyMoneySelector:GetValue()
		-- if buy and buy > 0 and buy < newValue then
			-- buyMoneySelector:SetValue(newValue)
		-- end
	-- end
	
	buyLabel:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPRIGHT", -400, 110)
	buyLabel:SetFontColor(1, 1, 0.75, 1)
	buyLabel:SetFontSize(14)
	buyLabel:SetText(L["PostingPanel/labelUnitBuy"])
	buyLabelShadow:SetPoint("CENTER", buyLabel, "CENTER", 2, 2)
	buyLabelShadow:SetFontColor(0, 0, 0, 0.25)
	buyLabelShadow:SetFontSize(buyLabel:GetFontSize())
	buyLabelShadow:SetLayer(buyLabel:GetLayer() - 1)
	buyLabelShadow:SetText(buyLabel:GetText())
	buyMoneySelector:SetPoint("TOPRIGHT", postPanel:GetContent(), "TOPRIGHT", -5, 105)
	buyMoneySelector:SetPoint("BOTTOMLEFT", postPanel:GetContent(), "TOPRIGHT", -220, 135)
	-- function buyMoneySelector.Event:ValueChanged(newValue)
		-- local bid = bidMoneySelector:GetValue()
		-- if bid and bid > newValue then
			-- bidMoneySelector:SetValue(newValue)
		-- end
	-- end

	durationLabel:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPRIGHT", -400, 150)
	durationLabel:SetFontColor(1, 1, 0.75, 1)
	durationLabel:SetFontSize(14)
	durationLabel:SetText(L["PostingPanel/labelDuration"])
	durationLabelShadow:SetPoint("CENTER", durationLabel, "CENTER", 2, 2)
	durationLabelShadow:SetFontColor(0, 0, 0, 0.25)
	durationLabelShadow:SetFontSize(durationLabel:GetFontSize())
	durationLabelShadow:SetLayer(durationLabel:GetLayer() - 1)
	durationLabelShadow:SetText(durationLabel:GetText())
	durationSlider:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPRIGHT", -220, 157)
	durationSlider:SetWidth(100)
	durationSlider:SetRange(1, 3)
	durationSlider:SetPosition(3)
	function durationSlider.Event:SliderChange()
		local position = self:GetPosition()
		durationTimeLabel:SetText(string.format(L["PostingPanel/labelDurationFormat"], 6 * 2 ^ position))
	end
	durationTimeLabel:SetPoint("TOPRIGHT", postPanel:GetContent(), "TOPRIGHT", -10, 150)
	durationTimeLabel:SetText(string.format(L["PostingPanel/labelDurationFormat"], 48))
	
	postButton:SetPoint("TOPCENTER", postPanel:GetContent(), "TOPRIGHT", -105, 185)
	postButton:SetText(L["PostingPanel/buttonPost"])
	postButton:SetEnabled(false)
	function postButton.Event:LeftPress()
		local selectedItems = itemSelector:GetSelectedItems()
		if not selectedItems or #selectedItems < 0 then return end
		
		local item = selectedItems[1]
		local stackSize = stackSizeSelector:GetPosition()
		local stackNumber = stackNumberSelector:GetPosition()
		local bidUnitPrice = bidMoneySelector:GetValue()
		local buyUnitPrice = buyMoneySelector:GetValue()
		local duration = 6 * 2 ^ durationSlider:GetPosition()
		
		if stackSize <= 0 or stackNumber <= 0 or bidUnitPrice <= 0 then return end
		if buyUnitPrice <= 0 then buyUnitPrice = nil end
		
		local amount = 0
		local itemType = nil
		for _, itemID in ipairs(selectedItems) do
			local itemDetail = Inspect.Item.Detail(itemID)
			amount = amount + (itemDetail.stack or 1)
			itemType = itemType or FixItemType(itemDetail.type)
		end
		amount = math.min(stackSize * stackNumber, amount)
		if amount <= 0 then return end

		if BananAH.PostItem(item, stackSize, amount, bidUnitPrice, buyUnitPrice, duration) then
			savedPostParams[itemType] = { stackSize = stackSize, bidPrice = bidUnitPrice, buyPrice = buyUnitPrice or 0, duration = durationSlider:GetPosition() }
		end
	end
	
	local function ReportAuctionData(full, total, new, updated, removed, before)
		local fullOrPartialMessage = full and L["General/scanTypeFull"] or L["General/scanTypePartial"]
		local newMessage = (new > 0) and string.format(L["General/scanNewCount"], new) or ""
		local updatedMessage = (updated > 0) and string.format(L["General/scanUpdatedCount"], updated) or ""
		local removedMessage = (removed > 0) and string.format(L["General/scanRemovedCount"], removed, before) or ""
		local message = string.format(L["General/scanMessage"], fullOrPartialMessage, total, newMessage, updatedMessage, removedMessage)
		print(message)
		
		local selectedItem = itemSelector:GetSelectedItem()
		if selectedItem then
			local auctions, lastUpdate = BananAH.GetActiveAuctionData(selectedItem)
			auctionSelector:SetItem(selectedItem)
			local minBid = nil
			local minBuy = nil
			local minBidSelf = false
			local minBuySelf = false
			local userName = Inspect.Unit.Detail("player").name
			for _, auctionData in pairs(auctions) do
				local bidUnit = math.floor((auctionData.bidPrice or 0) / (auctionData.stack or 1))
				local buyUnit = math.floor((auctionData.buyoutPrice or 0) / (auctionData.stack or 1))
				if bidUnit > 0 and (not minBid or (bidUnit <= minBid)) then
					minBid = bidUnit
					minBidSelf = minBidSelf or (userName == auctionData.sellerName)
				end
				if buyUnit > 0 and (not minBuy or (buyUnit <= minBuy)) then
					minBuy = buyUnit
					minBuySelf = minBuySelf or (userName == auctionData.sellerName)
				end
			end
			if minBid and not minBidSelf then minBid = minBid - 1 end
			if minBuy and not minBuySelf then minBuy = minBuy - 1 end
			undercutButton:SetEnabled(minBid ~= nil or minBuy ~= nil)
			undercutButton.minBid = minBid
			undercutButton.minBuy = minBuy
		end
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

