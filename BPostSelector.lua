local _, InternalInterface = ...

local FixItemType = InternalInterface.Utility.FixItemType
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local L = InternalInterface.Localization.L

-- Constants
local FALLBACK_PRICING_MODEL = "fallback"
local FIXED_PRICING_MODEL = "fixed"

-- Fallback price model
local function FallbackPricingModel(item, matchPrice)
	local ok, itemDetail = pcall(Inspect.Item.Detail, item)
	local sellPrice = ok and itemDetail.sell or 1
	local bid = math.floor(sellPrice * 3) -- TODO Get from config instead of 3
	local buyout = math.floor(sellPrice * 5) -- TODO Get from config instead of 3
	return bid, buyout
end
BananAH.UnregisterPricingModel(FALLBACK_PRICING_MODEL)
BananAH.RegisterPricingModel(FALLBACK_PRICING_MODEL, L["PricingModel/fallbackName"], FallbackPricingModel)

-- Fixed price model
local function FixedPricingModel(item, matchPrice)
	InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
	InternalInterface.Settings.Posting.FixedPrices = InternalInterface.Settings.Posting.FixedPrices or {}

	local bid = true
	local buyout = true
	
	local ok, itemDetail = pcall(Inspect.Item.Detail, item)
	if ok then
		local fixedType = FixItemType(itemDetail.type)
		local savedPrices = InternalInterface.Settings.Posting.FixedPrices[fixedType]
		if savedPrices then
			bid = savedPrices.bid
			buyout = savedPrices.buyout
		end
	end
	return bid, buyout
end
local function FixedSaveConfig(itemType, bid, buyout)
	InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
	InternalInterface.Settings.Posting.FixedPrices = InternalInterface.Settings.Posting.FixedPrices or {}
	InternalInterface.Settings.Posting.FixedPrices[itemType] =
	{
		bid = bid,
		buyout = buyout or 0,
	}
end
BananAH.UnregisterPricingModel(FIXED_PRICING_MODEL)
BananAH.RegisterPricingModel(FIXED_PRICING_MODEL, L["PricingModel/fixedName"], FixedPricingModel, FixedSaveConfig)

-- Private
local function FeedPricingModel(self)
	local selectedIndex = self.pricingModelSelector:GetSelectedIndex()
	local item = self:GetItem()
	local usePriceMatching = self.priceMatchingCheck:GetChecked()
	
	if selectedIndex <= 0 or not item then return end
	local pricingModel = self.pricingModelTable[selectedIndex]
	local pricingFunction = pricingModel and pricingModel.pricingFunction or nil
	
	local unitBid = nil
	local unitBuy = nil
	if pricingFunction then 
		unitBid, unitBuy = pricingFunction(item, usePriceMatching)
	end
	if not unitBid then
		print(L["PostingPanel/pricingModelError"])
		self.pricingModelSelector:SetSelectedIndex(self.pricingModelTable.fallbackPricingModel)
	else
		if type(unitBid) == "boolean" then unitBid = self.bidMoneySelector:GetValue() end
		if type(unitBuy) == "boolean" then unitBuy = self.buyMoneySelector:GetValue() end
		self.pricesSetByModel = true
		self.bidMoneySelector:SetValue(unitBid)
		self.buyMoneySelector:SetValue(unitBuy)
		self.pricesSetByModel = nil
	end
end

-- Public
local function GetItem(self)
	return self.item
end

local function SetItem(self, item, itemInfo)
	self.item = item
	
	local activatePostingControls = false
	local ok, itemDetail = pcall(Inspect.Item.Detail, item)
	if ok and item and itemInfo and itemDetail then
		self.itemTexturePanel:GetContent():SetBackgroundColor(GetRarityColor(itemInfo.rarity))
		self.itemTexture:SetVisible(true)
		self.itemTexture:SetTexture("Rift", itemDetail.icon)
		self.itemNameLabel:SetText(itemDetail.name)
		self.itemNameLabel:SetFontColor(GetRarityColor(itemDetail.rarity))
		self.itemNameLabel:SetVisible(true)
		self.itemStackLabel:SetText(string.format(L["PostingPanel/labelItemStack"], itemInfo.stack)) -- Remember: Stack from itemInfo for the filter to be applied!
		self.itemStackLabel:SetVisible(false) -- FIXME Stack label not properly updated :_
		activatePostingControls = #self.pricingModelSelector:GetValues() > 0
	else
		self.itemTexturePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
		self.itemTexture:SetVisible(false)
		self.itemNameLabel:SetVisible(false)
		self.itemStackLabel:SetVisible(false)
		activatePostingControls = false
	end
	
	if activatePostingControls then
		InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
		InternalInterface.Settings.Posting.ItemConfig = InternalInterface.Settings.Posting.ItemConfig or {}
		local itemConfig = InternalInterface.Settings.Posting.ItemConfig[itemInfo.fixedType]
		local pricingModelId = itemConfig and itemConfig.pricingModel
		local pricingModelIndex = nil
		for index, pricingModel in ipairs(self.pricingModelTable) do
			if pricingModelId == pricingModel.pricingModelId then
				pricingModelIndex = index
				break
			end
		end
		self.pricingModelSelector:SetEnabled(true)
		self.pricingModelSelector:SetSelectedIndex(pricingModelIndex or self.pricingModelTable.defaultPricingModel)
		self.priceMatchingCheck:SetEnabled(true)
		self.priceMatchingCheck:SetChecked(itemConfig and itemConfig.priceMatching or false) -- TODO Get from config instead of false
		self.stackSizeSelector:SetRange(1, itemDetail.stackMax or 1)
		self.stackSizeSelector:SetPosition(itemConfig and itemConfig.stackSize or itemDetail.stackMax or 1)
		self.bidMoneySelector:SetEnabled(true)
		self.buyMoneySelector:SetEnabled(true)
		self.durationSlider:SetPosition(itemConfig and itemConfig.duration or 3) -- TODO Get from config instead of 3
		self.durationSlider:SetEnabled(true)
		self.postButton:SetEnabled(true)
	else
		self.pricingModelSelector:SetEnabled(false)
		self.pricingModelSelector:SetSelectedIndex(0)
		self.priceMatchingCheck:SetEnabled(false)
		self.priceMatchingCheck:SetChecked(false)
		self.stackSizeSelector:SetRange(0, 0)
		self.bidMoneySelector:SetEnabled(false)
		self.buyMoneySelector:SetEnabled(false)
		self.bidMoneySelector:SetValue(0)
		self.buyMoneySelector:SetValue(0)
		self.durationSlider:SetPosition(3)
		self.durationSlider:SetEnabled(false)
		self.postButton:SetEnabled(false)
	end
	
	return self.item
end

local function SetPrices(self, bid, buy)
	self.bidMoneySelector:SetValue(bid)
	self.buyMoneySelector:SetValue(buy)
end

function InternalInterface.UI.PostSelector(name, parent)
	local bPostSelector = UI.CreateFrame("Frame", name, parent)

	local itemTexturePanel = UI.CreateFrame("BPanel", name .. ".ItemTexturePanel", bPostSelector)
	itemTexturePanel:SetPoint("TOPLEFT", bPostSelector, "TOPLEFT", 0, 0)
	itemTexturePanel:SetPoint("BOTTOMRIGHT", bPostSelector, "TOPLEFT", 70, 70)
	itemTexturePanel:SetInvertedBorder(true)
	itemTexturePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
	bPostSelector.itemTexturePanel = itemTexturePanel

	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTexturePanel:GetContent())
	itemTexture:SetPoint("TOPLEFT", itemTexturePanel:GetContent(), "TOPLEFT", 1, 1)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTexturePanel:GetContent(), "BOTTOMRIGHT", -1, -1)
	itemTexture:SetVisible(false)
	bPostSelector.itemTexture = itemTexture
	
	local itemNameLabel = UI.CreateFrame("BShadowedText", name .. ".ItemNameLabel", bPostSelector)
	itemNameLabel:SetPoint("BOTTOMLEFT", itemTexturePanel, "CENTERRIGHT", 5, 5)
	itemNameLabel:SetFontSize(20)
	itemNameLabel:SetText("")
	bPostSelector.itemNameLabel = itemNameLabel

	local itemStackLabel = UI.CreateFrame("BShadowedText", name .. ".ItemStackLabel", bPostSelector)
	itemStackLabel:SetPoint("BOTTOMLEFT", itemTexturePanel, "BOTTOMRIGHT", 5, -1)
	itemStackLabel:SetFontSize(15)
	itemStackLabel:SetText("")
	bPostSelector.itemStackLabel = itemStackLabel

	local pricingModelLabel = UI.CreateFrame("BShadowedText", name .. ".PricingModelLabel", bPostSelector)
	pricingModelLabel:SetPoint("TOPLEFT", bPostSelector, "TOPLEFT", 15, 100)
	pricingModelLabel:SetText(L["PostingPanel/labelPricingModel"])
	pricingModelLabel:SetFontSize(14)
	pricingModelLabel:SetFontColor(1, 1, 0.75, 1)
	pricingModelLabel:SetShadowOffset(2, 2)
	
	local stackSizeLabel = UI.CreateFrame("BShadowedText", name .. ".StackSizeLabel", bPostSelector)
	stackSizeLabel:SetPoint("TOPLEFT", bPostSelector, "TOPLEFT", 15, 140)
	stackSizeLabel:SetText(L["PostingPanel/labelStackSize"])
	stackSizeLabel:SetFontSize(14)
	stackSizeLabel:SetFontColor(1, 1, 0.75, 1)
	stackSizeLabel:SetShadowOffset(2, 2)
	
	local stackNumberLabel = UI.CreateFrame("BShadowedText", name .. ".StackNumberLabel", bPostSelector)
	stackNumberLabel:SetPoint("TOPLEFT", bPostSelector, "TOPLEFT", 15, 180)
	stackNumberLabel:SetText(L["PostingPanel/labelStackNumber"])
	stackNumberLabel:SetFontSize(14)
	stackNumberLabel:SetFontColor(1, 1, 0.75, 1)
	stackNumberLabel:SetShadowOffset(2, 2)
	
	local bidLabel = UI.CreateFrame("BShadowedText", name .. ".BidLabel", bPostSelector)
	bidLabel:SetPoint("TOPLEFT", bPostSelector, "TOPLEFT", 15, 220)
	bidLabel:SetText(L["PostingPanel/labelUnitBid"])
	bidLabel:SetFontSize(14)
	bidLabel:SetFontColor(1, 1, 0.75, 1)
	bidLabel:SetShadowOffset(2, 2)
	
	local buyLabel = UI.CreateFrame("BShadowedText", name .. ".BuyLabel", bPostSelector)
	buyLabel:SetPoint("TOPLEFT", bPostSelector, "TOPLEFT", 15, 260)
	buyLabel:SetText(L["PostingPanel/labelUnitBuy"])
	buyLabel:SetFontSize(14)
	buyLabel:SetFontColor(1, 1, 0.75, 1)
	buyLabel:SetShadowOffset(2, 2)

	local durationLabel = UI.CreateFrame("BShadowedText", name .. ".DurationLabel", bPostSelector)
	durationLabel:SetPoint("TOPLEFT", bPostSelector, "TOPLEFT", 15, 300)
	durationLabel:SetText(L["PostingPanel/labelDuration"])
	durationLabel:SetFontSize(14)
	durationLabel:SetFontColor(1, 1, 0.75, 1)
	durationLabel:SetShadowOffset(2, 2)
	
	local maxLabelWidth = 220
	maxLabelWidth = math.max(maxLabelWidth, pricingModelLabel:GetWidth())
	maxLabelWidth = math.max(maxLabelWidth, stackSizeLabel:GetWidth())
	maxLabelWidth = math.max(maxLabelWidth, stackNumberLabel:GetWidth())
	maxLabelWidth = math.max(maxLabelWidth, bidLabel:GetWidth())
	maxLabelWidth = math.max(maxLabelWidth, buyLabel:GetWidth())
	maxLabelWidth = math.max(maxLabelWidth, buyLabel:GetWidth())
	maxLabelWidth = maxLabelWidth + 15
	
	local pricingModelSelector = UI.CreateFrame("BDropdown", name .. ".PricingModelSelector", bPostSelector)
	pricingModelSelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -150, 95)
	pricingModelSelector:SetPoint("CENTERLEFT", pricingModelLabel, "CENTERRIGHT", maxLabelWidth - pricingModelLabel:GetWidth(), 1)
	function pricingModelSelector.Event:SelectionChanged(index)
		FeedPricingModel(bPostSelector)
	end
	bPostSelector.pricingModelSelector = pricingModelSelector
	
	local priceMatchingCheck = UI.CreateFrame("RiftCheckbox", name .. ".PriceMatchingCheck", bPostSelector)
	priceMatchingCheck:SetPoint("CENTERLEFT", pricingModelSelector, "CENTERRIGHT", 15, 0)
	priceMatchingCheck:SetChecked(false)
	priceMatchingCheck:SetEnabled(false)
	function priceMatchingCheck.Event:CheckboxChange()
		FeedPricingModel(bPostSelector)
	end
	bPostSelector.priceMatchingCheck = priceMatchingCheck
	
	local priceMatchingLabel = UI.CreateFrame("BShadowedText", name .. ".PriceMatchingLabel", bPostSelector)
	priceMatchingLabel:SetFontSize(13)
	priceMatchingLabel:SetText(L["PostingPanel/checkPriceMatching"])
	priceMatchingLabel:SetPoint("BOTTOMLEFT", priceMatchingCheck, "BOTTOMRIGHT", 2, 2)
	bPostSelector.priceMatchingLabel = priceMatchingLabel
	
	local stackSizeSelector = UI.CreateFrame("BSlider", name .. ".StackSizeSelector", bPostSelector)
	stackSizeSelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -5, 140)
	stackSizeSelector:SetPoint("CENTERLEFT", stackSizeLabel, "CENTERRIGHT", maxLabelWidth - stackSizeLabel:GetWidth(), 5)
	function stackSizeSelector.Event:PositionChanged(stackSize)
		local itemSelector = bPostSelector.itemSelector
		if not itemSelector then return end
		local selectedItem, selectedInfo = itemSelector:GetSelectedItem()
		if stackSize > 0 and selectedItem then
			local stacks = selectedInfo.stack
			local maxNumberOfStacks = math.ceil(stacks / stackSize)
			bPostSelector.stackNumberSelector:SetRange(1, maxNumberOfStacks)
			bPostSelector.stackNumberSelector:SetPosition(maxNumberOfStacks)
		else
			bPostSelector.stackNumberSelector:SetRange(0, 0)
		end
	end
	bPostSelector.stackSizeSelector = stackSizeSelector
	
	local stackNumberSelector = UI.CreateFrame("BSlider", name .. ".StackNumberSelector", bPostSelector)
	stackNumberSelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -5, 180)
	stackNumberSelector:SetPoint("CENTERLEFT", stackNumberLabel, "CENTERRIGHT", maxLabelWidth - stackNumberLabel:GetWidth(), 5)
	bPostSelector.stackNumberSelector = stackNumberSelector

	local bidMoneySelector = UI.CreateFrame("BMoneySelector", name .. ".BidMoneySelector", bPostSelector)
	bidMoneySelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -150, 216)
	bidMoneySelector:SetPoint("CENTERLEFT", bidLabel, "CENTERRIGHT", maxLabelWidth - bidLabel:GetWidth(), 0)
	function bidMoneySelector.Event:ValueChanged(newValue)
		if not self:GetEnabled() then return end
		if bPostSelector.bindPricesCheck:GetChecked() then
			local buy = bPostSelector.buyMoneySelector:GetValue()
			if buy ~= newValue then
				bPostSelector.buyMoneySelector:SetValue(newValue)
			end
		end
		if not bPostSelector.pricesSetByModel and bPostSelector.pricingModelSelector:GetSelectedIndex() ~= bPostSelector.pricingModelTable.fixedPricingModel then
			local bid = newValue
			local buy = bPostSelector.buyMoneySelector:GetValue()
			bPostSelector.pricingModelSelector:SetSelectedIndex(bPostSelector.pricingModelTable.fixedPricingModel)
			self:SetValue(bid)
			bPostSelector.buyMoneySelector:SetValue(buy)
		end
	end
	bPostSelector.bidMoneySelector = bidMoneySelector
	
	local bindPricesCheck = UI.CreateFrame("RiftCheckbox", name .. ".BindPricesCheck", bPostSelector)
	bindPricesCheck:SetPoint("CENTERLEFT", bidMoneySelector, "CENTERRIGHT", 15, 0)
	function bindPricesCheck.Event:CheckboxChange()
		if self:GetChecked() then
			bPostSelector.pricesSetByModel = true
			local maxPrice = math.max(bPostSelector.bidMoneySelector:GetValue(), bPostSelector.buyMoneySelector:GetValue())
			bPostSelector.bidMoneySelector:SetValue(maxPrice)
			bPostSelector.buyMoneySelector:SetValue(maxPrice)
			bPostSelector.pricesSetByModel = nil
		end
	end
	bPostSelector.bindPricesCheck = bindPricesCheck
	
	local bindPricesLabel = UI.CreateFrame("BShadowedText", name .. ".BindPricesLabel", bPostSelector)
	bindPricesLabel:SetFontSize(13)
	bindPricesLabel:SetText(L["PostingPanel/checkBindPrices"])
	bindPricesLabel:SetPoint("BOTTOMLEFT", bindPricesCheck, "BOTTOMRIGHT", 2, 2)
	bPostSelector.bindPricesLabel = bindPricesLabel

	local buyMoneySelector = UI.CreateFrame("BMoneySelector", name .. ".BuyMoneySelector", bPostSelector)
	buyMoneySelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -150, 256)
	buyMoneySelector:SetPoint("CENTERLEFT", buyLabel, "CENTERRIGHT", maxLabelWidth - buyLabel:GetWidth(), 0)
	function buyMoneySelector.Event:ValueChanged(newValue)
		if not self:GetEnabled() then return end
		if bindPricesCheck:GetChecked() then
			local bid = bidMoneySelector:GetValue()
			if bid ~= newValue then
				bidMoneySelector:SetValue(newValue)
			end
		end
		if not bPostSelector.pricesSetByModel and bPostSelector.pricingModelSelector:GetSelectedIndex() ~= bPostSelector.pricingModelTable.fixedPricingModel then
			local bid = bidMoneySelector:GetValue()
			local buy = newValue
			bPostSelector.pricingModelSelector:SetSelectedIndex(bPostSelector.pricingModelTable.fixedPricingModel)
			bidMoneySelector:SetValue(bid)
			self:SetValue(buy)
		end
		local item = bPostSelector:GetItem()
		local ok, itemDetail = pcall(Inspect.Item.Detail, item)
		bPostSelector.buyPriceWarning:SetVisible(ok and newValue > 0 and newValue < (itemDetail.sell or 0))
	end
	bPostSelector.buyMoneySelector = buyMoneySelector

	local postButton = UI.CreateFrame("RiftButton", name .. ".PostButton", bPostSelector)
	postButton:SetPoint("BOTTOMRIGHT", bPostSelector, "BOTTOMRIGHT", 0, 2)
	postButton:SetText(L["PostingPanel/buttonPost"])
	postButton:SetEnabled(false)
	function postButton.Event:LeftPress()
		local itemSelector = bPostSelector.itemSelector
		if not itemSelector then return end
		local selectedItem, selectedInfo = itemSelector:GetSelectedItem()
		if not selectedItem or not selectedInfo then return end
		
		local pricingModelIndex = bPostSelector.pricingModelSelector:GetSelectedIndex()
		local pricingModel = bPostSelector.pricingModelTable[pricingModelIndex or 0]
		local pricingModelId = pricingModel and pricingModel.pricingModelId or nil
		local stackSize = bPostSelector.stackSizeSelector:GetPosition()
		local stackNumber = bPostSelector.stackNumberSelector:GetPosition()
		local bidUnitPrice = bPostSelector.bidMoneySelector:GetValue()
		local buyUnitPrice = bPostSelector.buyMoneySelector:GetValue()
		local duration = 6 * 2 ^ bPostSelector.durationSlider:GetPosition()
		
		if not pricingModelId or stackSize <= 0 or stackNumber <= 0 or bidUnitPrice <= 0 then return end
		if buyUnitPrice <= 0 then 
			buyUnitPrice = nil
		elseif buyUnitPrice < bidUnitPrice then
			print(L["PostingPanel/postErrorBidHigherBuy"])
			return
		end
		
		local amount = math.min(stackSize * stackNumber, selectedInfo.stack)  -- Remember: Stack from selectedInfo for the filter to be applied!
		if amount <= 0 then return end
		
		local itemType = BananAH.PostItem(selectedItem, stackSize, amount, bidUnitPrice, buyUnitPrice, duration)
		if itemType then
			InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
			InternalInterface.Settings.Posting.ItemConfig = InternalInterface.Settings.Posting.ItemConfig or {}
			InternalInterface.Settings.Posting.ItemConfig[selectedInfo.fixedType] =
			{
				pricingModel = pricingModelId,
				priceMatching = bPostSelector.priceMatchingCheck:GetChecked(),
				stackSize = stackSize,
				duration = bPostSelector.durationSlider:GetPosition(),
			}
			if type(pricingModel.callbackOnPost) == "function" then
				pricingModel.callbackOnPost(selectedInfo.fixedType, bidUnitPrice, buyUnitPrice)
			end
		end
	end
	bPostSelector.postButton = postButton

	local buyPriceWarning = UI.CreateFrame("BShadowedText", name .. ".BuyPriceWarning", bPostSelector)
	buyPriceWarning:SetFontSize(14)
	buyPriceWarning:SetFontColor(1, 0.25, 0, 1)
	buyPriceWarning:SetShadowColor(0.05, 0, 0.1, 1)
	buyPriceWarning:SetText(L["PostingPanel/buyWarningLowerSeller"])
	buyPriceWarning:SetPoint("BOTTOMCENTER", postButton, "TOPCENTER", 0, -12)
	buyPriceWarning:SetVisible(false)
	bPostSelector.buyPriceWarning = buyPriceWarning
	
	local durationTimeLabel = UI.CreateFrame("BShadowedText", name .. ".DurationTimeLabel", bPostSelector)
	durationTimeLabel:SetPoint("BOTTOMLEFT", bPostSelector, "BOTTOMRIGHT", -250, -5)
	durationTimeLabel:SetText(string.format(L["PostingPanel/labelDurationFormat"], 48))
	bPostSelector.durationTimeLabel = durationTimeLabel

	local durationSlider = UI.CreateFrame("RiftSlider", name .. ".DurationSlider", bPostSelector)
	durationSlider:SetPoint("CENTERRIGHT", durationTimeLabel, "CENTERLEFT", -15, 5)
	durationSlider:SetPoint("CENTERLEFT", durationLabel, "CENTERRIGHT", maxLabelWidth - durationLabel:GetWidth() + 10, 5)
	durationSlider:SetRange(1, 3)
	durationSlider:SetPosition(3)
	function durationSlider.Event:SliderChange()
		local position = self:GetPosition()
		durationTimeLabel:SetText(string.format(L["PostingPanel/labelDurationFormat"], 6 * 2 ^ position))
	end
	bPostSelector.durationSlider = durationSlider
	
	-- Public
	bPostSelector.GetItem = GetItem
	bPostSelector.SetItem = SetItem
	bPostSelector.SetPrices = SetPrices
	
	-- Late initialization
	local function OnPricingModels()
		local pricingModels = BananAH.GetPricingModels()
		local pricingModelNames = {}
		bPostSelector.pricingModelTable = {}
		for id, pricingModelInfo in pairs(pricingModels) do
			table.insert(pricingModelNames, pricingModelInfo.displayName)
			table.insert(bPostSelector.pricingModelTable, pricingModelInfo)
			if id == FALLBACK_PRICING_MODEL then
				bPostSelector.pricingModelTable.fallbackPricingModel = #bPostSelector.pricingModelTable
			end
			if id == FIXED_PRICING_MODEL then
				bPostSelector.pricingModelTable.fixedPricingModel = #bPostSelector.pricingModelTable
			end
			if id == FALLBACK_PRICING_MODEL then -- TODO Get from config instead of fallback
				bPostSelector.pricingModelTable.defaultPricingModel = #bPostSelector.pricingModelTable
			end
		end
		if bPostSelector.pricingModelTable.fallbackPricingModel and bPostSelector.pricingModelTable.fixedPricingModel then
			bPostSelector.pricingModelSelector:SetValues(pricingModelNames)
		else
			bPostSelector.pricingModelSelector:SetValues(nil)
		end
		bPostSelector:SetItem(bPostSelector:GetItem())
	end
	table.insert(Event.BananAH.PricingModelAdded, { OnPricingModels, "BananAH", "PostSelector.PricingModelAdded" })
	table.insert(Event.BananAH.PricingModelRemoved, { OnPricingModels, "BananAH", "PostSelector.PricingModelRemoved" })
	OnPricingModels()
	
	return bPostSelector
end