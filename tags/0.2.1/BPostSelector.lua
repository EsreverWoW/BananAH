local _, InternalInterface = ...

local FixItemType = InternalInterface.Utility.FixItemType
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local L = InternalInterface.Localization.L

-- Constants
local FALLBACK_PRICING_MODEL = "fallback"
local FIXED_PRICING_MODEL = "fixed"

-- Fallback price model
local fallbackConfigFrame = nil
local function FallbackConfig(parent)
	if fallbackConfigFrame then return fallbackConfigFrame end

	InternalInterface.Settings.Config = InternalInterface.Settings.Config or {}
	InternalInterface.Settings.Config.PricingModels = InternalInterface.Settings.Config.PricingModels or {}
	
	fallbackConfigFrame = UI.CreateFrame("Frame", parent:GetName() .. ".FallbackPricingModelConfig", parent)

	local bidMultiplierText = UI.CreateFrame("Text", fallbackConfigFrame:GetName() .. ".BidMultiplierText", fallbackConfigFrame)
	local bidMultiplierSlider = UI.CreateFrame("BSlider", fallbackConfigFrame:GetName() .. ".BidMultiplierSlider", fallbackConfigFrame)
	local buyMultiplierText = UI.CreateFrame("Text", fallbackConfigFrame:GetName() .. ".BuyMultiplierText", fallbackConfigFrame)
	local buyMultiplierSlider = UI.CreateFrame("BSlider", fallbackConfigFrame:GetName() .. ".BuyMultiplierSlider", fallbackConfigFrame)

	fallbackConfigFrame:SetVisible(false)

	bidMultiplierText:SetPoint("TOPLEFT", fallbackConfigFrame, "TOPLEFT", 10, 10)
	bidMultiplierText:SetFontSize(14)
	bidMultiplierText:SetText(L["PricingModel/fallbackBidMultiplier"])
	
	buyMultiplierText:SetPoint("TOPLEFT", fallbackConfigFrame, "TOPLEFT", 10, 50)
	buyMultiplierText:SetFontSize(14)
	buyMultiplierText:SetText(L["PricingModel/fallbackBuyMultiplier"])

	local maxWidth = math.max(bidMultiplierText:GetWidth(), buyMultiplierText:GetWidth())
	
	bidMultiplierSlider:SetPoint("CENTERLEFT", bidMultiplierText, "CENTERRIGHT", 20 + maxWidth - bidMultiplierText:GetWidth(), 8)	
	bidMultiplierSlider:SetWidth(300)
	bidMultiplierSlider:SetRange(1, 25)
	bidMultiplierSlider:SetPosition(InternalInterface.Settings.Config.PricingModels.fallbackBidMultiplier or 3)

	buyMultiplierSlider:SetPoint("CENTERLEFT", buyMultiplierText, "CENTERRIGHT", 20 + maxWidth - buyMultiplierText:GetWidth(), 8)	
	buyMultiplierSlider:SetWidth(300)
	buyMultiplierSlider:SetRange(1, 25)
	buyMultiplierSlider:SetPosition(InternalInterface.Settings.Config.PricingModels.fallbackBuyMultiplier or 5)
	
	function bidMultiplierSlider.Event:PositionChanged(position)
		InternalInterface.Settings.Config.PricingModels.fallbackBidMultiplier = position
	end
	
	function buyMultiplierSlider.Event:PositionChanged(position)
		InternalInterface.Settings.Config.PricingModels.fallbackBuyMultiplier = position
	end
	
	return fallbackConfigFrame
end

local function FallbackPricingModel(item, matchPrice, auto)
	local ok, itemDetail = pcall(Inspect.Item.Detail, item)
	local sellPrice = ok and itemDetail.sell or 1
	local bid = math.floor(sellPrice * (InternalInterface.Settings.Config.PricingModels.fallbackBidMultiplier or 3))
	local buyout = math.floor(sellPrice * (InternalInterface.Settings.Config.PricingModels.fallbackBuyMultiplier or 5))
	return math.min(bid, buyout), buyout, false
end
BananAH.UnregisterPricingModel(FALLBACK_PRICING_MODEL)
BananAH.RegisterPricingModel(FALLBACK_PRICING_MODEL, L["PricingModel/fallbackName"], FallbackPricingModel, nil, FallbackConfig)

-- Fixed price model
local function FixedPricingModel(item, matchPrice, auto)
	InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
	InternalInterface.Settings.Posting.FixedPrices = InternalInterface.Settings.Posting.FixedPrices or {}

	local bid = true
	local buyout = true
	
	local ok, itemDetail = pcall(Inspect.Item.Detail, item)
	if ok then
		local fixedType = FixItemType(itemDetail.type)
		local savedPrices = InternalInterface.Settings.Posting.FixedPrices[fixedType]
		if auto and savedPrices and savedPrices.autoPosting then
			savedPrices = savedPrices.autoPosting
		end
		if savedPrices then
			bid = savedPrices.bid
			buyout = savedPrices.buyout
		end
	end
	return bid, buyout, false
end
local function FixedSaveConfig(itemType, bid, buyout, auto)
	InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
	InternalInterface.Settings.Posting.FixedPrices = InternalInterface.Settings.Posting.FixedPrices or {}
	if auto then
		if bid then
			if not InternalInterface.Settings.Posting.FixedPrices[itemType] then
				InternalInterface.Settings.Posting.FixedPrices[itemType] =
				{
					bid = bid,
					buyout = buyout or 0,
				}
			end
			InternalInterface.Settings.Posting.FixedPrices[itemType].autoPosting =
			{
				bid = bid,
				buyout = buyout or 0,
			}
		elseif InternalInterface.Settings.Posting.FixedPrices[itemType] then
			InternalInterface.Settings.Posting.FixedPrices[itemType].autoPosting = nil
		end
	else
		InternalInterface.Settings.Posting.FixedPrices[itemType] =
		{
			bid = bid,
			buyout = buyout or 0,
		}
	end
end
BananAH.UnregisterPricingModel(FIXED_PRICING_MODEL)
BananAH.RegisterPricingModel(FIXED_PRICING_MODEL, L["PricingModel/fixedName"], FixedPricingModel, FixedSaveConfig)

-- Private
local function ApplyPriceMatching(item, unitBid, unitBuy)
	local userName = Inspect.Unit.Detail("player").name -- TODO Use all player characters
	local matchingRange = (InternalInterface.Settings.Config.selfMatcherRange or 25) / 100
	local undercutRange = (InternalInterface.Settings.Config.competitionUndercutterRange or 25) / 100

	local auctions = BananAH.GetActiveAuctionData(item)
	local bidsMatchRange = {}
	local bidsUndercutRange = {}
	local buysMatchRange = {}
	local buysUndercutRange = {}

	for auctionId, auctionData in pairs(auctions) do
		local bidRelDev = math.abs(1 - auctionData.bidUnitPrice / unitBid)
		if userName == auctionData.sellerName and bidRelDev <= matchingRange and matchingRange > 0 then table.insert(bidsMatchRange, auctionData.bidUnitPrice) end
		if userName ~= auctionData.sellerName and bidRelDev <= undercutRange and undercutRange > 0 then table.insert(bidsUndercutRange, auctionData.bidUnitPrice) end

		local buyRelDev = auctionData.buyoutUnitPrice and math.abs(1 - auctionData.buyoutUnitPrice / unitBuy) or (math.max(matchingRange, undercutRange) + 1)
		if userName == auctionData.sellerName and buyRelDev <= matchingRange and matchingRange > 0 then table.insert(buysMatchRange, auctionData.buyoutUnitPrice) end
		if userName ~= auctionData.sellerName and buyRelDev <= undercutRange and undercutRange > 0 then table.insert(buysUndercutRange, auctionData.buyoutUnitPrice) end
	end

	table.sort(bidsMatchRange)
	table.sort(bidsUndercutRange)
	if #bidsMatchRange > 0 then 
		unitBid = bidsMatchRange[1]
	elseif #bidsUndercutRange > 0 then
		unitBid = math.max(bidsUndercutRange[1] - 1, 1)
	else
		unitBid = math.floor(unitBid * (1 + undercutRange))
	end

	table.sort(buysMatchRange)
	table.sort(buysUndercutRange)
	if #buysMatchRange > 0 then 
		unitBuy = buysMatchRange[1]
	elseif #buysUndercutRange > 0 then
		unitBuy = math.max(buysUndercutRange[1] - 1, 1)
	else
		unitBuy = math.floor(unitBuy * (1 + undercutRange))
	end
	unitBid = math.min(unitBid, unitBuy)	
	
	return unitBid, unitBuy
end

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
		unitBid, unitBuy, usePriceMatching = pricingFunction(item, usePriceMatching, self.clearButton:GetVisible())
	end
	if not unitBid then
		print(L["PostingPanel/pricingModelError"])
		self.pricingModelSelector:SetSelectedIndex(self.pricingModelTable.fallbackPricingModel)
	else
		if type(unitBid) == "boolean" then unitBid = self.bidMoneySelector:GetValue() end
		if type(unitBuy) == "boolean" then unitBuy = self.buyMoneySelector:GetValue() end
		
		if usePriceMatching then
			unitBid, unitBuy = ApplyPriceMatching(item, unitBid, unitBuy)			
		end
		
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
		self.itemStackLabel:SetText(string.format(L["PostingPanel/labelItemStack"], itemInfo.adjustedStack)) -- Remember: Stack from itemInfo for the filter to be applied!
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
		if itemConfig and itemConfig.autoPosting and self.clearButton:GetVisible() then itemConfig = itemConfig.autoPosting end
		
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
		local usePriceMatching = itemConfig and itemConfig.priceMatching
		if usePriceMatching == nil then usePriceMatching = InternalInterface.Settings.Config.defaultPriceMatching end
		self.priceMatchingCheck:SetChecked(usePriceMatching or false)
		self.stackSizeSelector:SetRange(1, itemDetail.stackMax or 1)
		self.stackSizeSelector:SetPosition(itemConfig and itemConfig.stackSize or itemDetail.stackMax or 1)
		self.bidMoneySelector:SetEnabled(true)
		local bindPrices = itemConfig and itemConfig.bindPrices
		if bindPrices == nil then bindPrices = InternalInterface.Settings.Config.defaultBindPrices end
		self.bindPricesCheck:SetChecked(bindPrices or false)
		self.buyMoneySelector:SetEnabled(true)
		self.durationSlider:SetPosition(itemConfig and itemConfig.duration or InternalInterface.Settings.Config.defaultDuration or 3)
		self.durationSlider:SetEnabled(true)
		self.postButton:SetEnabled(true)
		self.clearButton:SetEnabled(itemConfig and InternalInterface.Settings.Posting.ItemConfig[itemInfo.fixedType].autoPosting and true or false)
	else
		self.pricingModelSelector:SetEnabled(false)
		self.pricingModelSelector:SetSelectedIndex(0)
		self.priceMatchingCheck:SetEnabled(false)
		self.priceMatchingCheck:SetChecked(false)
		self.stackSizeSelector:SetRange(0, 0)
		self.bidMoneySelector:SetEnabled(false)
		self.bindPricesCheck:SetChecked(false)
		self.buyMoneySelector:SetEnabled(false)
		self.bidMoneySelector:SetValue(0)
		self.buyMoneySelector:SetValue(0)
		self.durationSlider:SetPosition(3)
		self.durationSlider:SetEnabled(false)
		self.postButton:SetEnabled(false)
		self.clearButton:SetEnabled(false)
	end
	
	return self.item
end

local function SetPrices(self, bid, buy)
	self.bidMoneySelector:SetValue(bid)
	self.buyMoneySelector:SetValue(buy)
end

function InternalInterface.UI.PostSelector(name, parent)
	local bPostSelector = UI.CreateFrame("Frame", name, parent)

	InternalInterface.Settings.Config = InternalInterface.Settings.Config or {}

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
	pricingModelSelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -425, 95)
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
	stackSizeSelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -280, 140)
	stackSizeSelector:SetPoint("CENTERLEFT", stackSizeLabel, "CENTERRIGHT", maxLabelWidth - stackSizeLabel:GetWidth(), 5)
	function stackSizeSelector.Event:PositionChanged(stackSize)
		local itemSelector = bPostSelector.itemSelector
		if not itemSelector then return end
		local selectedItem, selectedInfo = itemSelector:GetSelectedItem()
		if stackSize > 0 and selectedItem then
			local stacks = selectedInfo.adjustedStack -- Remember to use adjustedStack from itemSelector!
			local maxNumberOfStacks = math.ceil(stacks / stackSize)
			bPostSelector.stackNumberSelector:SetRange(1, maxNumberOfStacks)
			bPostSelector.stackNumberSelector:SetPosition(maxNumberOfStacks)
		else
			bPostSelector.stackNumberSelector:SetRange(0, 0)
		end
	end
	bPostSelector.stackSizeSelector = stackSizeSelector
	
	local stackNumberSelector = UI.CreateFrame("BSlider", name .. ".StackNumberSelector", bPostSelector)
	stackNumberSelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -280, 180)
	stackNumberSelector:SetPoint("CENTERLEFT", stackNumberLabel, "CENTERRIGHT", maxLabelWidth - stackNumberLabel:GetWidth(), 5)
	bPostSelector.stackNumberSelector = stackNumberSelector

	local bidMoneySelector = UI.CreateFrame("BMoneySelector", name .. ".BidMoneySelector", bPostSelector)
	bidMoneySelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -425, 216)
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
		elseif bPostSelector.pricingModelSelector:GetSelectedIndex() ~= bPostSelector.pricingModelTable.fixedPricingModel then
			FeedPricingModel(bPostSelector)
		end
	end
	bPostSelector.bindPricesCheck = bindPricesCheck
	
	local bindPricesLabel = UI.CreateFrame("BShadowedText", name .. ".BindPricesLabel", bPostSelector)
	bindPricesLabel:SetFontSize(13)
	bindPricesLabel:SetText(L["PostingPanel/checkBindPrices"])
	bindPricesLabel:SetPoint("BOTTOMLEFT", bindPricesCheck, "BOTTOMRIGHT", 2, 2)
	bPostSelector.bindPricesLabel = bindPricesLabel

	local buyMoneySelector = UI.CreateFrame("BMoneySelector", name .. ".BuyMoneySelector", bPostSelector)
	buyMoneySelector:SetPoint("TOPRIGHT", bPostSelector, "TOPRIGHT", -425, 256)
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

	local buyPriceWarning = UI.CreateFrame("BShadowedText", name .. ".BuyPriceWarning", bPostSelector)
	buyPriceWarning:SetFontSize(14)
	buyPriceWarning:SetFontColor(1, 0.25, 0, 1)
	buyPriceWarning:SetShadowColor(0.05, 0, 0.1, 1)
	buyPriceWarning:SetText(L["PostingPanel/buyWarningLowerSeller"])
	buyPriceWarning:SetPoint("CENTERLEFT", buyMoneySelector, "CENTERRIGHT", 15, 0)
	buyPriceWarning:SetVisible(false)
	bPostSelector.buyPriceWarning = buyPriceWarning	
	
	local postButton = UI.CreateFrame("RiftButton", name .. ".PostButton", bPostSelector)
	postButton:SetPoint("BOTTOMRIGHT", bPostSelector, "BOTTOMRIGHT", -275, 2)
	postButton:SetText(L["PostingPanel/buttonPost"])
	postButton:SetEnabled(false)
	function postButton.Event:LeftPress()
		local itemSelector = bPostSelector.itemSelector
		if not itemSelector then return end
		local selectedItem, selectedInfo = itemSelector:GetSelectedItem()
		if not selectedItem or not selectedInfo then return end
		
		local autoPosting = bPostSelector.clearButton:GetVisible()
		
		local pricingModelIndex = bPostSelector.pricingModelSelector:GetSelectedIndex()
		local pricingModel = bPostSelector.pricingModelTable[pricingModelIndex or 0]
		local pricingModelId = pricingModel and pricingModel.pricingModelId or nil
		local savePriceMatching = bPostSelector.priceMatchingCheck:GetChecked()
		local stackSize = bPostSelector.stackSizeSelector:GetPosition()
		local stackNumber = bPostSelector.stackNumberSelector:GetPosition()
		local bidUnitPrice = bPostSelector.bidMoneySelector:GetValue()
		local saveBindPrices = bPostSelector.bindPricesCheck:GetChecked()
		local buyUnitPrice = bPostSelector.buyMoneySelector:GetValue()
		local saveDuration = bPostSelector.durationSlider:GetPosition()
		local duration = 6 * 2 ^ saveDuration
		
		if not pricingModelId or stackSize <= 0 or stackNumber <= 0 or bidUnitPrice <= 0 then return end
		if buyUnitPrice <= 0 then 
			buyUnitPrice = nil
		elseif buyUnitPrice < bidUnitPrice then
			print(L["PostingPanel/postErrorBidHigherBuy"])
			return
		end
		
		local amount = math.min(stackSize * stackNumber, selectedInfo.adjustedStack)  -- Remember: Stack from selectedInfo for the filter to be applied!
		if amount <= 0 then return end

		InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
		InternalInterface.Settings.Posting.ItemConfig = InternalInterface.Settings.Posting.ItemConfig or {}
		InternalInterface.Settings.Posting.ItemConfig[selectedInfo.fixedType] = InternalInterface.Settings.Posting.ItemConfig[selectedInfo.fixedType] or {}
		if not autoPosting or not InternalInterface.Settings.Posting.ItemConfig[selectedInfo.fixedType].pricingModel then
			InternalInterface.Settings.Posting.ItemConfig[selectedInfo.fixedType].pricingModel = pricingModelId
			InternalInterface.Settings.Posting.ItemConfig[selectedInfo.fixedType].priceMatching = savePriceMatching
			InternalInterface.Settings.Posting.ItemConfig[selectedInfo.fixedType].stackSize = stackSize
			InternalInterface.Settings.Posting.ItemConfig[selectedInfo.fixedType].bindPrices = saveBindPrices
			InternalInterface.Settings.Posting.ItemConfig[selectedInfo.fixedType].duration = saveDuration
		end
		if autoPosting then
			InternalInterface.Settings.Posting.ItemConfig[selectedInfo.fixedType].autoPosting =
			{
				pricingModel = pricingModelId,
				priceMatching = savePriceMatching,
				stackSize = stackSize,
				bindPrices = saveBindPrices,
				duration = saveDuration,
			}
		end
		if type(pricingModel.callbackOnPost) == "function" then
			pricingModel.callbackOnPost(selectedInfo.fixedType, bidUnitPrice, buyUnitPrice, autoPosting)
		end
		if autoPosting then
			itemSelector:ResetItems()
			bPostSelector:SetItem(selectedItem, selectedInfo)
		else
			BananAH.PostItem(selectedItem, stackSize, amount, bidUnitPrice, buyUnitPrice, duration)
		end
	end
	bPostSelector.postButton = postButton
	
	local durationTimeLabel = UI.CreateFrame("BShadowedText", name .. ".DurationTimeLabel", bPostSelector)
	durationTimeLabel:SetPoint("BOTTOMLEFT", bPostSelector, "BOTTOMRIGHT", -550, -5)
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

	local autoPostButton = UI.CreateFrame("RiftButton", name .. ".AutoPostButton", bPostSelector)
	autoPostButton:SetPoint("BOTTOMRIGHT", bPostSelector, "BOTTOMRIGHT", -5, 2)
	autoPostButton:SetText(L["PostingPanel/buttonAutoPostingMode"])
	function autoPostButton.Event:RightClick()
		local autoPostEditingMode = not bPostSelector.clearButton:GetVisible()
		bPostSelector.clearButton:SetVisible(autoPostEditingMode)
		postButton:SetText(autoPostEditingMode and L["PostingPanel/buttonAutoPostingSave"] or L["PostingPanel/buttonPost"])

		local itemSelector = bPostSelector.itemSelector
		if not itemSelector then return end
		local selectedItem, selectedInfo = itemSelector:GetSelectedItem()
		if not selectedItem or not selectedInfo then return end
		bPostSelector:SetItem(selectedItem, selectedInfo)
	end
	function autoPostButton.Event:LeftClick()
		local slot = Utility.Item.Slot.Inventory()
		local items = Inspect.Item.List(slot)
		
		local itemTypeTable = {}
		for _, itemID in pairs(items) do repeat
			if type(itemID) == "boolean" then break end 
			local ok, itemDetail = pcall(Inspect.Item.Detail, itemID)
			if not ok or not itemDetail or itemDetail.bound then break end
			
			local fixedItemType = FixItemType(itemDetail.type)
			itemTypeTable[fixedItemType] = itemTypeTable[fixedItemType] or { name = itemDetail.name, stack = 0, referenceItem = itemID, }
			itemTypeTable[fixedItemType].stack = itemTypeTable[fixedItemType].stack + (itemDetail.stack or 1)
		until true end

		local remainingItems = false
		local postingAmounts = {}
		local postingQueue = BananAH.GetPostingQueue()
		for index, post in ipairs(postingQueue) do
			postingAmounts[post.itemType] = (postingAmounts[post.itemType] or 0) + post.amount
		end
		InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
		InternalInterface.Settings.Posting.ItemConfig = InternalInterface.Settings.Posting.ItemConfig or {}
		for itemType, itemData in pairs(itemTypeTable) do
			if not InternalInterface.Settings.Posting.ItemConfig[itemType] or not InternalInterface.Settings.Posting.ItemConfig[itemType].autoPosting then
				itemTypeTable[itemType] = nil
			else
				itemTypeTable[itemType].autoPosting = InternalInterface.Settings.Posting.ItemConfig[itemType].autoPosting
				itemTypeTable[itemType].stack = itemTypeTable[itemType].stack - (postingAmounts[itemType] or 0)
				if itemTypeTable[itemType].stack <= 0 then
					itemTypeTable[itemType] = nil
				else
					remainingItems = true 
				end
			end
		end
		if not remainingItems then
			print(L["PostingPanel/autoPostingErrorNoItems"])
			return
		end
		
		for itemType, itemData in pairs(itemTypeTable) do repeat
			local pricingModelId = itemData.autoPosting.pricingModel
			local pricingModelIndex = nil
			for index, pricingModel in ipairs(bPostSelector.pricingModelTable) do
				if pricingModelId == pricingModel.pricingModelId then
					pricingModelIndex = index
					break
				end
			end
			if not pricingModelIndex then
				itemTypeTable[itemType] = nil
				print(string.format(L["PostingPanel/autoPostingErrorPricingModelNotFound"], itemData.name))
				break
			end

			local pricingFunction = bPostSelector.pricingModelTable[pricingModelIndex].pricingFunction
			local unitBid, unitBuy, usePriceMatching = pricingFunction(itemData.referenceItem, itemData.autoPosting.priceMatching, true)
			if not unitBid then
				itemTypeTable[itemType] = nil
				print(string.format(L["PostingPanel/autoPostingErrorPricingModelFailed"], itemData.name))
				break
			end
			
			if usePriceMatching then
				unitBid, unitBuy = ApplyPriceMatching(itemData.referenceItem, unitBid, unitBuy)
			end
			
			if itemData.autoPosting.bindPrices then unitBid = unitBuy end
			itemTypeTable[itemType].unitBid = unitBid
			itemTypeTable[itemType].unitBuy = unitBuy
		until true end
		
		for _, itemData in pairs(itemTypeTable) do
			BananAH.PostItem(itemData.referenceItem, itemData.autoPosting.stackSize, itemData.stack, itemData.unitBid, itemData.unitBuy, 6 * 2 ^ itemData.autoPosting.duration)	
		end
	end
	bPostSelector.autoPostButton = autoPostButton

	local clearButton = UI.CreateFrame("RiftButton", name .. ".ClearButton", bPostSelector)
	clearButton:SetPoint("CENTERRIGHT", autoPostButton, "CENTERLEFT", 0, 0)
	clearButton:SetText(L["PostingPanel/buttonAutoPostingClear"])
	clearButton:SetVisible(false)
	clearButton:SetEnabled(false)
	function clearButton.Event:LeftPress()
		local itemSelector = bPostSelector.itemSelector
		if not itemSelector then return end
		local selectedItem, selectedInfo = itemSelector:GetSelectedItem()
		if not selectedItem or not selectedInfo then return end

		local pricingModelId = InternalInterface.Settings.Posting.ItemConfig[selectedInfo.fixedType].autoPosting.pricingModel
		local pricingModelCallback = nil
		for index, pricingModel in ipairs(bPostSelector.pricingModelTable) do
			if pricingModelId == pricingModel.pricingModelId then
				pricingModelCallback = pricingModel.callbackOnPost
				break
			end
		end
		if type(pricingModelCallback) == "function" then
			pricingModelCallback(selectedInfo.fixedType, nil, nil, true)
		end		
		
		InternalInterface.Settings.Posting.ItemConfig[selectedInfo.fixedType].autoPosting = nil
		itemSelector:ResetItems()
		bPostSelector:SetItem(selectedItem, selectedInfo)
	end
	bPostSelector.clearButton = clearButton
	
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
			if id == (InternalInterface.Settings.Config.defaultPricingModel or FALLBACK_PRICING_MODEL) then
				bPostSelector.pricingModelTable.defaultPricingModel = #bPostSelector.pricingModelTable
			end
		end
		if bPostSelector.pricingModelTable.fallbackPricingModel and bPostSelector.pricingModelTable.fixedPricingModel then
			if not bPostSelector.pricingModelTable.defaultPricingModel then
				bPostSelector.pricingModelTable.defaultPricingModel = bPostSelector.pricingModelTable.fallbackPricingModel
			end
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