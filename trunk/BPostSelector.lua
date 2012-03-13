local _, InternalInterface = ...

local FixItemType = InternalInterface.Utility.FixItemType
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local L = InternalInterface.Localization.L

-- Private

-- Public
local function GetItem(self)
	return self.item
end

local function SetItem(self, item, itemInfo)
	self.item = item
	
	if item and itemInfo then
		self.itemTexturePanel:GetContent():SetBackgroundColor(GetRarityColor(itemInfo.rarity))
		self.itemTexture:SetVisible(true)
		self.itemTexture:SetTexture("Rift", itemInfo.icon)
		self.itemNameLabel:SetText(itemInfo.name)
		self.itemNameLabel:SetFontColor(GetRarityColor(itemInfo.rarity))
		self.itemNameLabel:SetVisible(true)
		self.itemStackLabel:SetText(string.format(L["PostingPanel/labelItemStack"], itemInfo.stack))
		self.itemStackLabel:SetVisible(true)
		-- stackSizeSelector:SetRange(1, itemDetail.stackMax or 1)
		-- stackSizeSelector:SetPosition(stackSize)
		-- bidMoneySelector:SetValue(bidPrice)
		-- buyMoneySelector:SetValue(buyPrice)
		-- postButton:SetEnabled(Inspect.Interaction("auction"))
		-- durationSlider:SetPosition(duration)
	else
		self.itemTexturePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
		self.itemTexture:SetVisible(false)
		self.itemNameLabel:SetVisible(false)
		self.itemStackLabel:SetVisible(false)
		-- stackSizeSelector:SetRange(0, 0)
		-- bidMoneySelector:SetValue(0)
		-- buyMoneySelector:SetValue(0)
		-- postButton:SetEnabled(false)
	end
	
	return self.item
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
	pricingModelSelector:SetValues({ "Vendor", "User defined" })
	bPostSelector.pricingModelSelector = pricingModelSelector
	
	local priceMatchingCheck = UI.CreateFrame("RiftCheckbox", name .. ".PriceMatchingCheck", bPostSelector)
	priceMatchingCheck:SetPoint("CENTERLEFT", pricingModelSelector, "CENTERRIGHT", 15, 0)
	bPostSelector.priceMatchingCheck = priceMatchingCheck
	
	local priceMatchingLabel = UI.CreateFrame("BShadowedText", name .. ".PriceMatchingLabel", bPostSelector)
	priceMatchingLabel:SetFontSize(13)
	priceMatchingLabel:SetText(L["PostingPanel/checkPriceMatching"])
	priceMatchingLabel:SetPoint("BOTTOMLEFT", priceMatchingCheck, "BOTTOMRIGHT", 2, 2)
	bPostSelector.priceMatchingLabel = priceMatchingLabel
	
	
	local stackSizeSelector = UI.CreateFrame("BSlider", name .. ".StackSizeSelector", bPostSelector)
	stackSizeSelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -5, 140)
	stackSizeSelector:SetPoint("CENTERLEFT", stackSizeLabel, "CENTERRIGHT", maxLabelWidth - stackSizeLabel:GetWidth(), 5)
	-- function stackSizeSelector.Event:PositionChanged(stackSize)
		-- local selectedItem, selectedInfo = itemSelector:GetSelectedItem()
		-- if stackSize > 0 and selectedItem then
			-- local stacks = selectedInfo.stack
			-- local maxNumberOfStacks = math.ceil(stacks / stackSize)
			-- stackNumberSelector:SetRange(1, maxNumberOfStacks)
			-- stackNumberSelector:SetPosition(maxNumberOfStacks)
		-- else
			-- stackNumberSelector:SetRange(0, 0)
		-- end
	-- end
	bPostSelector.stackSizeSelector = stackSizeSelector
	
	local stackNumberSelector = UI.CreateFrame("BSlider", name .. ".StackNumberSelector", bPostSelector)
	stackNumberSelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -5, 180)
	stackNumberSelector:SetPoint("CENTERLEFT", stackNumberLabel, "CENTERRIGHT", maxLabelWidth - stackNumberLabel:GetWidth(), 5)
	bPostSelector.stackNumberSelector = stackNumberSelector

	local bidMoneySelector = UI.CreateFrame("BMoneySelector", name .. ".BidMoneySelector", bPostSelector)
	bidMoneySelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -150, 216)
	bidMoneySelector:SetPoint("CENTERLEFT", bidLabel, "CENTERRIGHT", maxLabelWidth - bidLabel:GetWidth(), 0)
	-- function bidMoneySelector.Event:ValueChanged(newValue)
		-- local buy = buyMoneySelector:GetValue()
		-- if buy and buy > 0 and buy < newValue then
			-- buyMoneySelector:SetValue(newValue)
		-- end
	-- end
	bPostSelector.bidMoneySelector = bidMoneySelector
	
	local bindPricesCheck = UI.CreateFrame("RiftCheckbox", name .. ".BindPricesCheck", bPostSelector)
	bindPricesCheck:SetPoint("CENTERLEFT", bidMoneySelector, "CENTERRIGHT", 15, 0)
	bPostSelector.bindPricesCheck = bindPricesCheck
	
	local bindPricesLabel = UI.CreateFrame("BShadowedText", name .. ".BindPricesLabel", bPostSelector)
	bindPricesLabel:SetFontSize(13)
	bindPricesLabel:SetText(L["PostingPanel/checkBindPrices"])
	bindPricesLabel:SetPoint("BOTTOMLEFT", bindPricesCheck, "BOTTOMRIGHT", 2, 2)
	bPostSelector.bindPricesLabel = bindPricesLabel

	local buyMoneySelector = UI.CreateFrame("BMoneySelector", name .. ".BuyMoneySelector", bPostSelector)
	buyMoneySelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -150, 256)
	buyMoneySelector:SetPoint("CENTERLEFT", buyLabel, "CENTERRIGHT", maxLabelWidth - buyLabel:GetWidth(), 0)
	-- function buyMoneySelector.Event:ValueChanged(newValue)
		-- local bid = bidMoneySelector:GetValue()
		-- if bid and bid > newValue then
			-- bidMoneySelector:SetValue(newValue)
		-- end
	-- end
	bPostSelector.buyMoneySelector = buyMoneySelector

	local postButton = UI.CreateFrame("RiftButton", name .. ".PostButton", bPostSelector)
	postButton:SetPoint("BOTTOMRIGHT", bPostSelector, "BOTTOMRIGHT", 0, 2)
	postButton:SetText(L["PostingPanel/buttonPost"])
	postButton:SetEnabled(false)
	-- function postButton.Event:LeftPress()
		-- local selectedItems = itemSelector:GetSelectedItems()
		-- if not selectedItems or #selectedItems < 0 then return end
		
		-- local item = selectedItems[1]
		-- local stackSize = 1 -- stackSizeSelector:GetPosition()
		-- local stackNumber = 1 -- stackNumberSelector:GetPosition()
		-- local bidUnitPrice = 0 -- bidMoneySelector:GetValue()
		-- local buyUnitPrice = 0 -- buyMoneySelector:GetValue()
		-- local duration = 6 * 2 ^ durationSlider:GetPosition()
		
		-- if stackSize <= 0 or stackNumber <= 0 or bidUnitPrice <= 0 then return end
		-- if buyUnitPrice <= 0 then buyUnitPrice = nil end
		
		-- local amount = 0
		-- local itemType = nil
		-- for _, itemID in ipairs(selectedItems) do
			-- local itemDetail = Inspect.Item.Detail(itemID)
			-- amount = amount + (itemDetail.stack or 1)
			-- itemType = itemType or FixItemType(itemDetail.type)
		-- end
		-- amount = math.min(stackSize * stackNumber, amount)
		-- if amount <= 0 then return end

		-- if BananAH.PostItem(item, stackSize, amount, bidUnitPrice, buyUnitPrice, duration) then
			-- savedPostParams[itemType] = { stackSize = stackSize, bidPrice = bidUnitPrice, buyPrice = buyUnitPrice or 0, duration = durationSlider:GetPosition() }
		-- end
	-- end
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
--	durationSlider:SetPoint("TOPLEFT", postPanel:GetContent(), "TOPRIGHT", -220, 157)
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
	
	return bPostSelector
end