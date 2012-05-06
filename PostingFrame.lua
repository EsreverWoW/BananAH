local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local AUCTION_FEE_REDUCTION = 0.95

local REFRESH_ITEMS = 8
local REFRESH_ITEMFILTER = 7
local REFRESH_ITEM = 6
local REFRESH_POSTING = 5
local REFRESH_AUCTIONS = 4
local REFRESH_AUCTION = 3
local REFRESH_PRICES = 2
local REFRESH_INFO = 1
local REFRESH_NONE = 0

local L = InternalInterface.Localization.L
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local GetOutput = InternalInterface.Utility.GetOutput
local function out(value) GetOutput()(value) end
local GetLocalizedDateString = InternalInterface.Localization.GetLocalizedDateString

local visibilityMode = false

-- ItemRenderer
local function ItemRenderer(name, parent)
	local itemCell = UI.CreateFrame("Texture", name, parent)
	itemCell:SetTexture(addonID, "Textures/ItemRowBackground.png")
	local itemTextureBackground = UI.CreateFrame("Frame", name .. ".ItemTextureBackground", itemCell)
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = UI.CreateFrame("BShadowedText", name .. ".ItemNameLabel", itemCell)
	local visibilityIcon = UI.CreateFrame("Texture", name .. ".VisibilityIcon", itemCell)
	local itemStackLabel = UI.CreateFrame("Text", name .. ".ItemStackLabel", itemCell)
	local autoPostingLabel = UI.CreateFrame("Text", name .. ".AutoPostingLabel", itemCell)
	
	itemTextureBackground:SetPoint("CENTERLEFT", itemCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	itemCell.itemTextureBackground = itemTextureBackground
	
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	itemCell.itemTexture = itemTexture
	
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("TOPLEFT", itemCell, "TOPLEFT", 58, 8)
	itemCell.itemNameLabel = itemNameLabel	
	
	visibilityIcon:SetTexture(addonID, "Textures/ShowIcon.png")
	visibilityIcon:SetPoint("BOTTOMLEFT", itemTextureBackground, "BOTTOMRIGHT", 5, -5)
	visibilityIcon:SetVisible(visibilityMode)
	itemCell.visibilityIcon = visibilityIcon
	
	itemStackLabel:SetPoint("BOTTOMRIGHT", itemCell, "BOTTOMRIGHT", -4, -4)
	itemCell.itemStackLabel = itemStackLabel
	
	autoPostingLabel:SetPoint("BOTTOMLEFT", visibilityIcon, "BOTTOMRIGHT", 5, 5)
	autoPostingLabel:SetFontColor(1, 0.75, 0.75, 1)
	autoPostingLabel:SetText(L["PostingPanel/autoPostingOnLabel"])
	itemCell.autoPostingLabel = autoPostingLabel
	
	function itemCell:SetValue(key, value, width, extra)
		self:SetWidth(width)
		self.itemTextureBackground:SetBackgroundColor(GetRarityColor(value.rarity))
		self.itemTexture:SetTexture("Rift", value.icon)
		self.itemNameLabel:SetText(value.name)
		self.itemNameLabel:SetFontColor(GetRarityColor(value.rarity))
		self.itemStackLabel:SetText("x" .. value.adjustedStack)
		
		if InternalInterface.AccountSettings.Posting.HiddenItems[value.itemType] then
			visibilityIcon:SetTexture(addonID, "Textures/HideIcon.png")
		elseif InternalInterface.CharacterSettings.Posting.HiddenItems[value.itemType] then
			visibilityIcon:SetTexture(addonID, "Textures/CharacterHideIcon.png")
		else
			visibilityIcon:SetTexture(addonID, "Textures/ShowIcon.png")
		end
		self.visibilityIcon.itemType = value.itemType
		self.visibilityIcon:SetVisible(visibilityMode)

		self.autoPostingLabel:SetVisible(InternalInterface.CharacterSettings.Posting.AutoConfig[value.itemType] and true or false)
	end
	
	function visibilityIcon.Event:LeftClick()
		if InternalInterface.AccountSettings.Posting.HiddenItems[self.itemType] then
			visibilityIcon:SetTexture(addonID, "Textures/ShowIcon.png")
			InternalInterface.AccountSettings.Posting.HiddenItems[self.itemType] = nil
		elseif InternalInterface.CharacterSettings.Posting.HiddenItems[self.itemType] then
			visibilityIcon:SetTexture(addonID, "Textures/ShowIcon.png")
			InternalInterface.CharacterSettings.Posting.HiddenItems[self.itemType] = nil
		else
			visibilityIcon:SetTexture(addonID, "Textures/HideIcon.png")
			InternalInterface.AccountSettings.Posting.HiddenItems[self.itemType] = true
		end
		itemCell:GetParent().Event.LeftClick(itemCell:GetParent())
	end
	
	function visibilityIcon.Event:RightClick()
		if InternalInterface.AccountSettings.Posting.HiddenItems[self.itemType] then
			visibilityIcon:SetTexture(addonID, "Textures/ShowIcon.png")
			InternalInterface.AccountSettings.Posting.HiddenItems[self.itemType] = nil
		elseif InternalInterface.CharacterSettings.Posting.HiddenItems[self.itemType] then
			visibilityIcon:SetTexture(addonID, "Textures/ShowIcon.png")
			InternalInterface.CharacterSettings.Posting.HiddenItems[self.itemType] = nil
		else
			visibilityIcon:SetTexture(addonID, "Textures/CharacterHideIcon.png")
			InternalInterface.CharacterSettings.Posting.HiddenItems[self.itemType] = true
		end
	end
	
	return itemCell
end

-- AuctionRenderer
local function AuctionCachedRenderer(name, parent)
	local cachedCell = UI.CreateFrame("Texture", name, parent)
	
	cachedCell:SetTexture(addonID, "Textures/AuctionUnavailable.png")
	cachedCell:SetVisible(false)
	
	function cachedCell:SetValue(key, value, width, extra)
		self:SetVisible(not _G[addonID].GetAuctionCached(key))
	end
	
	return cachedCell
end
local function AuctionRenderer(name, parent)
	local auctionCell = UI.CreateFrame("Frame", name, parent)
	
	function auctionCell:SetValue(key, value, width, extra)
		self:ClearAll()
		self:SetAllPoints()
		self:SetLayer(self:GetParent():GetLayer() - 1)
		self:SetBackgroundColor(unpack(extra.Color(value)))
		-- if _G[addonID].GetAuctionCached(key) then
			-- self:SetBackgroundColor(0, 0.75, 0.75, 0.1)
		-- else
			-- self:SetBackgroundColor(0.75, 0, 0, 0.1)
		-- end
	end
	
	return auctionCell
end

-- MoneyRenderer
local function MoneyRenderer(name, parent)
	local moneyCell = UI.CreateFrame("BMoneyDisplay", name, parent)
	
	local oldSetValue = moneyCell.SetValue
	function moneyCell:SetValue(key, value, width, extra)
		oldSetValue(self, value)
		self:SetWidth(width)
		if extra and extra.Compare then
			self:SetCompareValue(extra.Compare())
		else
			self:SetCompareValue(nil)
		end
	end
	
	return moneyCell
end

-- QueueManagerRenderer
local function QueueManagerRenderer(name, parent)
	local queueManagerCell = UI.CreateFrame("Texture", name, parent)
	queueManagerCell:SetTexture(addonID, "Textures/ItemRowBackground.png")
	
	local itemTextureBackground = UI.CreateFrame("Frame", name .. ".ItemTextureBackground", queueManagerCell)
	itemTextureBackground:SetPoint("CENTERLEFT", queueManagerCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	queueManagerCell.itemTextureBackground = itemTextureBackground
	
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	queueManagerCell.itemTexture = itemTexture
	
	local itemNameLabel = UI.CreateFrame("BShadowedText", name .. ".ItemNameLabel", queueManagerCell)
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("TOPLEFT", queueManagerCell, "TOPLEFT", 58, 0)
	queueManagerCell.itemNameLabel = itemNameLabel	
	
	local itemStackLabel = UI.CreateFrame("Text", name .. ".ItemStackLabel", queueManagerCell)
	itemStackLabel:SetPoint("BOTTOMLEFT", queueManagerCell, "BOTTOMLEFT", 58, 0)
	queueManagerCell.itemStackLabel = itemStackLabel
	
	local bidMoneyDisplay = UI.CreateFrame("BMoneyDisplay", name .. ".BidMoneyDisplay", queueManagerCell)
	bidMoneyDisplay:SetPoint("TOPLEFT", queueManagerCell, "BOTTOMRIGHT", -120, -40)
	bidMoneyDisplay:SetPoint("BOTTOMRIGHT", queueManagerCell, "BOTTOMRIGHT", 0, -20)
	queueManagerCell.bidMoneyDisplay = bidMoneyDisplay
	
	local buyMoneyDisplay = UI.CreateFrame("BMoneyDisplay", name .. ".BuyMoneyDisplay", queueManagerCell)
	buyMoneyDisplay:SetPoint("TOPLEFT", queueManagerCell, "BOTTOMRIGHT", -120, -20)
	buyMoneyDisplay:SetPoint("BOTTOMRIGHT", queueManagerCell, "BOTTOMRIGHT", 0, 0)
	queueManagerCell.buyMoneyDisplay = buyMoneyDisplay
	
	
	function queueManagerCell:SetValue(key, value, width, extra)
		local itemDetail = Inspect.Item.Detail(value.itemType)
		self:SetWidth(width)
		self.itemTextureBackground:SetBackgroundColor(GetRarityColor(itemDetail.rarity))
		self.itemTexture:SetTexture("Rift", itemDetail.icon)
		self.itemNameLabel:SetText(itemDetail.name)
		self.itemNameLabel:SetFontColor(GetRarityColor(itemDetail.rarity))
		
		local fullStacks = math.floor(value.amount / value.stackSize)
		local oddStack = value.amount % value.stackSize
		local stack = ""
		if fullStacks > 0 and oddStack > 0 then
			stack = string.format("%d x %d + %d", fullStacks, value.stackSize, oddStack)
		elseif fullStacks > 0 then
			stack = string.format("%d x %d", fullStacks, value.stackSize)
		else
			stack = tostring(oddStack)
		end
		self.itemStackLabel:SetText(stack)
		
		self.bidMoneyDisplay:SetValue(value.amount * (value.unitBidPrice or 0))
		self.buyMoneyDisplay:SetValue(value.amount * (value.unitBuyoutPrice or 0))
	end
	
	return queueManagerCell
end

-- PostingFrame
function InternalInterface.UI.PostingFrame(name, parent)
	local postingFrame = UI.CreateFrame("Frame", name, parent)
	
	local itemGrid = UI.CreateFrame("BDataGrid", name .. ".ItemGrid", postingFrame)
	local filterFrame = UI.CreateFrame("Frame", name .. ".FilterFrame", itemGrid.externalPanel:GetContent())
	local filterTextPanel = UI.CreateFrame("BPanel", filterFrame:GetName() .. ".FilterTextPanel", filterFrame)
	local visibilityIcon = UI.CreateFrame("Texture", filterFrame:GetName() .. ".VisibilityIcon", filterTextPanel:GetContent())
	local filterTextField = UI.CreateFrame("RiftTextfield", filterFrame:GetName() .. ".FilterTextField", filterTextPanel:GetContent())
	
	local auctionGrid = UI.CreateFrame("BDataGrid", name .. ".AuctionGrid", postingFrame)
	local controlFrame = UI.CreateFrame("Frame", name .. ".ControlFrame", auctionGrid.externalPanel:GetContent())
	local buyButton = UI.CreateFrame("RiftButton", name .. ".BuyButton", controlFrame)
	local bidButton = UI.CreateFrame("RiftButton", name .. ".BidButton", controlFrame)
	local auctionMoneySelector = UI.CreateFrame("BMoneySelector", name .. ".AuctionMoneySelector", controlFrame)
	local noBidLabel = UI.CreateFrame("BShadowedText", name .. ".NoBidLabel", controlFrame)
	local refreshPanel = UI.CreateFrame("BPanel", name .. ".RefreshPanel", controlFrame)
	local refreshButton = UI.CreateFrame("Texture", name .. ".RefreshButton", refreshPanel:GetContent())
	local refreshText = UI.CreateFrame("Text", name .. ".RefreshLabel", refreshPanel:GetContent())
	
	local itemTexturePanel = UI.CreateFrame("BPanel", name .. ".ItemTexturePanel", postingFrame)
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTexturePanel:GetContent())
	local itemNameLabel = UI.CreateFrame("BShadowedText", name .. ".ItemNameLabel", postingFrame)
	local itemStackLabel = UI.CreateFrame("BShadowedText", name .. ".ItemStackLabel", postingFrame)
	local pricingModelLabel = UI.CreateFrame("BShadowedText", name .. ".PricingModelLabel", postingFrame)
	local stackSizeLabel = UI.CreateFrame("BShadowedText", name .. ".StackSizeLabel", postingFrame)
	local stackNumberLabel = UI.CreateFrame("BShadowedText", name .. ".StackNumberLabel", postingFrame)
	local bidLabel = UI.CreateFrame("BShadowedText", name .. ".BidLabel", postingFrame)
	local buyLabel = UI.CreateFrame("BShadowedText", name .. ".BuyLabel", postingFrame)
	local durationLabel = UI.CreateFrame("BShadowedText", name .. ".DurationLabel", postingFrame)
	local pricingModelSelector = UI.CreateFrame("BDropdown", name .. ".PricingModelSelector", postingFrame)
	local priceMatchingCheck = UI.CreateFrame("RiftCheckbox", name .. ".PriceMatchingCheck", postingFrame)
	local priceMatchingLabel = UI.CreateFrame("BShadowedText", name .. ".PriceMatchingLabel", postingFrame)
	local stackSizeSelector = UI.CreateFrame("BSlider", name .. ".StackSizeSelector", postingFrame)
	local stackNumberSelector = UI.CreateFrame("BSlider", name .. ".StackNumberSelector", postingFrame)
	local bidMoneySelector = UI.CreateFrame("BMoneySelector", name .. ".BidMoneySelector", postingFrame)
	local bindPricesCheck = UI.CreateFrame("RiftCheckbox", name .. ".BindPricesCheck", postingFrame)
	local bindPricesLabel = UI.CreateFrame("BShadowedText", name .. ".BindPricesLabel", postingFrame)
	local buyMoneySelector = UI.CreateFrame("BMoneySelector", name .. ".BuyMoneySelector", postingFrame)
	local buyPriceWarning = UI.CreateFrame("BShadowedText", name .. ".BuyPriceWarning", postingFrame)
	local postButton = UI.CreateFrame("RiftButton", name .. ".PostButton", postingFrame)
	local durationTimeLabel = UI.CreateFrame("BShadowedText", name .. ".DurationTimeLabel", postingFrame)
	local durationSlider = UI.CreateFrame("RiftSlider", name .. ".DurationSlider", postingFrame)
	local autoPostButton = UI.CreateFrame("RiftButton", name .. ".AutoPostButton", postingFrame)
	local clearButton = UI.CreateFrame("RiftButton", name .. ".ClearButton", postingFrame)
	
	local queuePanel = UI.CreateFrame("BPanel", name .. ".QueuePanel", postingFrame)
	local pauseResumeButton = UI.CreateFrame("RiftButton", name .. ".PauseResumeButton", queuePanel:GetContent())
	local queueStatusLabel = UI.CreateFrame("BShadowedText", name .. ".QueueStatusLabel", queuePanel:GetContent())
	local queueStatus = UI.CreateFrame("BShadowedText", name .. ".QueueStatus", queuePanel:GetContent())
	local showHideButton = UI.CreateFrame("RiftButton", name .. ".ShowHideButton", queuePanel:GetContent())
	local queueGrid = UI.CreateFrame("BDataGrid", name .. ".QueueGrid", postingFrame)
	local queueClearButton = UI.CreateFrame("RiftButton", name .. ".QueueClearButton", queueGrid.externalPanel:GetContent())
	local queueCancelButton = UI.CreateFrame("RiftButton", name .. ".QueueCancelButton", queueGrid.externalPanel:GetContent())
	
	local infoStacksLabel = UI.CreateFrame("BShadowedText", name .. ".InfoStacksLabel", postingFrame)
	local totalBidLabel = UI.CreateFrame("BShadowedText", name .. ".TotalBidLabel", postingFrame)
	local totalBuyLabel = UI.CreateFrame("BShadowedText", name .. ".TotalBuyLabel", postingFrame)
	local depositLabel = UI.CreateFrame("BShadowedText", name .. ".DepositLabel", postingFrame)
	local discountBidLabel = UI.CreateFrame("BShadowedText", name .. ".DiscountBidLabel", postingFrame)
	local discountBuyLabel = UI.CreateFrame("BShadowedText", name .. ".DiscountBuyLabel", postingFrame)
	local infoStacks = UI.CreateFrame("Text", name .. ".InfoStacks", postingFrame)
	local infoTotalBid = UI.CreateFrame("BMoneyDisplay", name .. ".InfoTotalBid", postingFrame)
	local infoTotalBuy = UI.CreateFrame("BMoneyDisplay", name .. ".InfoTotalBuy", postingFrame)
	local infoDeposit = UI.CreateFrame("Text", name .. ".InfoDeposit", postingFrame)
	local infoDiscountBid = UI.CreateFrame("BMoneyDisplay", name .. "IinfoDiscountBid", postingFrame)
	local infoDiscountBuy = UI.CreateFrame("BMoneyDisplay", name .. "IinfoDiscountBuy", postingFrame)
	
	local autoPostingMode = false
	local pricesSetByModel = false
	local refreshMode = REFRESH_NONE
	local refreshTask
	local itemPrices = {}

	local function AuctionRightClick(self)
		local data = self.dataValue
		local bid = data and data.bidUnitPrice or nil
		local buy = data and data.buyoutUnitPrice or 0
		if bid then
			if not data.own then
				bid = math.max(bid - 1, 1)
				buy = buy == 0 and buy or math.max(buy - 1, 1)
			end	
			bidMoneySelector:SetValue(bid)
			buyMoneySelector:SetValue(buy)
		end
		self.Event.LeftClick(self)
	end

	local function ResetItems()
		local slot = Utility.Item.Slot.Inventory()
		local items = Inspect.Item.List(slot)
		
		local itemTypeTable = {}
		for _, itemID in pairs(items) do repeat
			if type(itemID) == "boolean" then break end 
			local ok, itemDetail = pcall(Inspect.Item.Detail, itemID)
			if not ok or not itemDetail or itemDetail.bound then break end
			
			local itemType = itemDetail.type
			itemTypeTable[itemType] = itemTypeTable[itemType] or { name = itemDetail.name, icon = itemDetail.icon, rarity = itemDetail.rarity, stack = 0, stackMax = itemDetail.stackMax, sell = itemDetail.sell, items = {} }
			itemTypeTable[itemType].stack = itemTypeTable[itemType].stack + (itemDetail.stack or 1)
			table.insert(itemTypeTable[itemType].items, itemID)
		until true end
		
		local itemTable = {}
		for itemType, itemData in pairs(itemTypeTable) do
			if itemData.stack > 0 and #itemData.items > 0 then
				itemTable[itemData.items[1]] = itemData
				itemTable[itemData.items[1]].itemType = itemType
				itemData.items = nil
			end
		end
		
		itemGrid:SetData(itemTable)
	end		

	local function UpdateAuctions(item, itemInfo)
		local lastUpdate = nil
		if item then
			local auctions = nil
			auctions, lastUpdate = _G[addonID].GetActiveAuctionData(item)
			auctionGrid:SetData(auctions)
			for index, row in ipairs(auctionGrid.rows) do
				row.Event.RightClick = AuctionRightClick
			end
		else
			auctionGrid:SetData(nil)
		end
		
		if (lastUpdate or 0) <= 0 then
			refreshText:SetText(L["PostingPanel/lastUpdateMessage"] .. L["PostingPanel/lastUpdateDateFallback"])
		else
			refreshText:SetText(L["PostingPanel/lastUpdateMessage"] .. GetLocalizedDateString(L["PostingPanel/lastUpdateDateFormat"], lastUpdate))
		end
	end

	local function UpdatePrices(item)
		local _, prevKey = pricingModelSelector:GetSelectedValue()
		prevKey = prevKey and prevKey.key or nil

		local pricings = item and _G[addonID].GetPricings(item, autoPostingMode) or {}

		itemPrices = {}
		local newIndex = nil
		for key, value in pairs(pricings) do
			value.key = key
			table.insert(itemPrices, value)
			if key == prevKey then newIndex = #itemPrices end
		end
		
		bidMoneySelector:SetCompareFunction(function(value) return InternalInterface.UI.ScoreColorByScore(_G[addonID].ScorePrice(item, value, pricings)) end)
		buyMoneySelector:SetCompareFunction(function(value) return InternalInterface.UI.ScoreColorByScore(_G[addonID].ScorePrice(item, value, pricings)) end)
		
		pricingModelSelector:SetValues(itemPrices)
		if newIndex then pricingModelSelector:SetSelectedIndex(newIndex) end
	end

	local function RefreshAuctionButtons()
		local auctionSelected = false
		local auctionInteraction = Inspect.Interaction("auction")
		local selectedAuctionCached = false
		local selectedAuctionBid = false
		local selectedAuctionBuy = false
		local highestBidder = false
		local seller = false
		local bidPrice = 1
		
		local selectedAuctionID, selectedAuctionData = auctionGrid:GetSelectedData()
		if selectedAuctionID and selectedAuctionData then
			auctionSelected = true
			selectedAuctionCached = _G[addonID].GetAuctionCached(selectedAuctionID) or false
			selectedAuctionBid = not selectedAuctionData.buyoutPrice or selectedAuctionData.bidPrice < selectedAuctionData.buyoutPrice
			selectedAuctionBuyout = selectedAuctionData.buyoutPrice and true or false
			local ok, auctionData = pcall(Inspect.Auction.Detail, selectedAuctionID)
			if ok and auctionData and auctionData.bidder then highestBidder = true end
			seller = selectedAuctionData.own
			bidPrice = selectedAuctionData.bidPrice
		end
		
		refreshButton.enabled = auctionInteraction
		refreshButton:SetTexture(addonID, auctionInteraction and "Textures/RefreshMiniOff.png" or "Textures/RefreshMiniDisabled.png")
		bidButton:SetEnabled(auctionSelected and auctionInteraction and selectedAuctionCached and selectedAuctionBid and not highestBidder and not seller)
		buyButton:SetEnabled(auctionSelected and auctionInteraction and selectedAuctionCached and selectedAuctionBuyout and not seller)

		if not auctionSelected then
			noBidLabel:SetText(L["PostingPanel/bidErrorNoAuction"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not selectedAuctionCached then
			noBidLabel:SetText(L["PostingPanel/bidErrorNotCached"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not selectedAuctionBid then
			noBidLabel:SetText(L["PostingPanel/bidErrorBidEqualBuy"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif seller then
			noBidLabel:SetText(L["PostingPanel/bidErrorSeller"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif highestBidder then
			noBidLabel:SetText(L["PostingPanel/bidErrorHighestBidder"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not auctionInteraction then
			noBidLabel:SetText(L["PostingPanel/bidErrorNoAuctionHouse"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		else
			auctionMoneySelector:SetValue(bidPrice + 1)
			auctionMoneySelector:SetVisible(true)
			noBidLabel:SetVisible(false)
		end
	end

	local function UpdatePostingConfig(item, itemInfo)
		local activatePostingControls = false

		if item and itemInfo then
			local defaultConfig = InternalInterface.AccountSettings.Posting.DefaultConfig
			local itemConfig = InternalInterface.CharacterSettings.Posting.ItemConfig[itemInfo.itemType]
			local autoConfig = InternalInterface.CharacterSettings.Posting.AutoConfig[itemInfo.itemType]
			local config = autoPostingMode and autoConfig or itemConfig or defaultConfig
			
			local pricingModelOrder = config.pricingModelOrder
			
			if type(pricingModelOrder) == "string" then
				pricingModelOrder = { pricingModelOrder }
				for _, pricingModelId in ipairs(defaultConfig.pricingModelOrder) do
					if pricingModelId ~= pricingModelOrder[1] then
						table.insert(pricingModelOrder, pricingModelId)
					end
				end
			end
			
			local pricingModelIndex = nil
			for _, pricingModelId in ipairs(pricingModelOrder) do
				for index, price in ipairs(itemPrices) do
					if price.key == pricingModelId then
						pricingModelIndex = index
						break
					end
				end
				if pricingModelIndex then break end
			end

			itemTexturePanel:GetContent():SetBackgroundColor(GetRarityColor(itemInfo.rarity))
			itemTexture:SetVisible(true)
			itemTexture:SetTexture("Rift", itemInfo.icon)
			itemNameLabel:SetText(itemInfo.name)
			itemNameLabel:SetFontColor(GetRarityColor(itemInfo.rarity))
			itemNameLabel:SetVisible(true)
			itemStackLabel:SetText(string.format(L["PostingPanel/labelItemStack"], itemInfo.adjustedStack))
			itemStackLabel:SetVisible(true)
			pricingModelSelector:SetEnabled(true)
			pricingModelSelector:SetSelectedIndex(pricingModelIndex or 0)
			priceMatchingCheck:SetEnabled(true)
			priceMatchingCheck:SetChecked(config.usePriceMatching)
			stackSizeSelector:SetRange(1, itemInfo.stackMax or 1)
			stackSizeSelector:SetPosition(config.stackSize)
			bidMoneySelector:SetEnabled(true)
			bindPricesCheck:SetChecked(config.bindPrices)
			bindPricesCheck:SetEnabled(true)
			buyMoneySelector:SetEnabled(true)
			durationSlider:SetPosition(config.duration)
			durationSlider:SetEnabled(true)
			postButton:SetEnabled(true)
			clearButton:SetEnabled(autoConfig and true or false)
		else
			itemTexturePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
			itemTexture:SetVisible(false)
			itemNameLabel:SetVisible(false)
			itemStackLabel:SetVisible(false)
			pricingModelSelector:SetEnabled(false)
			pricingModelSelector:SetSelectedIndex(0)
			priceMatchingCheck:SetEnabled(false)
			priceMatchingCheck:SetChecked(false)
			stackSizeSelector:SetRange(0, 0)
			bidMoneySelector:SetEnabled(false)
			bindPricesCheck:SetChecked(false)
			bindPricesCheck:SetEnabled(false)
			buyMoneySelector:SetEnabled(false)
			bidMoneySelector:SetValue(0)
			buyMoneySelector:SetValue(0)
			durationSlider:SetPosition(3)
			durationSlider:SetEnabled(false)
			postButton:SetEnabled(false)
			clearButton:SetEnabled(false)
		end
	end	
	
	local function ApplyPricingModel(item)
		local _, value = pricingModelSelector:GetSelectedValue()

		pricesSetByModel = true
		if item and value then
			local bid, buy = value.bid, value.buy
			if priceMatchingCheck:GetChecked() and itemPrices[pricingModelSelector:GetSelectedValue()].key ~= "fixed" then
				bid, buy = _G[addonID].MatchPrice(item, bid, buy)
			end
			
			bidMoneySelector:SetValue(bid)
			buyMoneySelector:SetValue(buy)
		else
			bidMoneySelector:SetValue(0)
			buyMoneySelector:SetValue(0)
		end	
		pricesSetByModel = false
	end
	
	local function UpdateInfo()
		local item, itemInfo = itemGrid:GetSelectedData()
		if itemInfo and itemInfo.adjustedStack then
			local amount = itemInfo.adjustedStack
			local stackSize = stackSizeSelector:GetPosition()
			local stacks = stackNumberSelector:GetPosition()
			amount = math.min(amount, stackSize * stacks)
			local fullStacks = math.floor(amount / stackSize)
			local oddStackSize = amount % stackSize
			local stackText = nil
			if fullStacks > 0 then stackText = fullStacks .. " x " .. stackSize end
			if oddStackSize > 0 then 
				stackText = stackText and (stackText .. " + ") or ""
				stackText = stackText .. oddStackSize
			end
			infoStacks:SetText(stackText or "0")
			
			local bid = amount * (bidMoneySelector:GetValue() or 0)
			local buy = amount * (buyMoneySelector:GetValue() or 0)
			
			infoTotalBid:SetValue(bid)
			infoTotalBuy:SetValue(buy)
			infoDiscountBid:SetValue(bid * AUCTION_FEE_REDUCTION)
			infoDiscountBuy:SetValue(buy * AUCTION_FEE_REDUCTION)
		else
			infoStacks:SetText("0")
			infoTotalBid:SetValue(0)
			infoTotalBuy:SetValue(0)
			infoDiscountBid:SetValue(0)
			infoDiscountBuy:SetValue(0)
		end
	end
	
	local function SetRefreshMode(mode)
		if mode > REFRESH_NONE and refreshMode <= REFRESH_NONE and refreshTask then
			Library.LibCron.resume(refreshTask)
		end
		refreshMode = math.max(mode, refreshMode)
	end

	local function DoRefresh()
		if not postingFrame:GetVisible() then return end
	
		if refreshMode >= REFRESH_ITEMS then
			ResetItems()
		end
		
		if refreshMode == REFRESH_ITEMFILTER then -- If ResetItems was called, it isn't necessary to force update
			itemGrid:ForceUpdate()
		end
		
		local item, itemData = itemGrid:GetSelectedData()
		
		if refreshMode >= REFRESH_ITEM then
			UpdatePrices(item)
		end
		
		if refreshMode >= REFRESH_POSTING then
			UpdatePostingConfig(item, itemData)
		end

		if refreshMode >= REFRESH_AUCTIONS then
			UpdateAuctions(item, itemData)
			UpdatePrices(item)
		end
		
		if refreshMode >= REFRESH_AUCTION then
			RefreshAuctionButtons()
		end
		
		if refreshMode >= REFRESH_PRICES then
			ApplyPricingModel(item)
		end
		
		if refreshMode >= REFRESH_INFO then
			UpdateInfo()
		end

		refreshMode = REFRESH_NONE
		if refreshTask then Library.LibCron.pause(refreshTask) end
	end
	refreshTask = Library.LibCron.new(addonID, 0, true, true, DoRefresh)
	Library.LibCron.pause(refreshTask)

	itemGrid:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 5, 5)
	itemGrid:SetPoint("BOTTOMRIGHT", postingFrame, "BOTTOMLEFT", 295, -5)
	itemGrid:SetPadding(1, 1, 1, 38)
	itemGrid:SetHeadersVisible(false)
	itemGrid:SetRowHeight(62)
	itemGrid:SetRowMargin(2)
	itemGrid:SetUnselectedRowBackgroundColor(0.2, 0.15, 0.2, 1)
	itemGrid:SetSelectedRowBackgroundColor(0.6, 0.45, 0.6, 1)
	itemGrid:AddColumn("Item", 248, ItemRenderer, function(a, b) local items = itemGrid:GetData() return string.upper(items[a].name) < string.upper(items[b].name) end)
	local function ItemGridFilter(key, value)
		local rarity = value.rarity or "common"
		rarity = ({ sellable = 1, common = 2, uncommon = 3, rare = 4, epic = 5, relic = 6, trascendant = 7, quest = 8 })[rarity] or 1
		local minRarity = InternalInterface.AccountSettings.Posting.rarityFilter or 1
		if rarity < minRarity then return false end

		local filterText = string.upper(filterTextField:GetText())
		local upperName = string.upper(value.name)
		if not string.find(upperName, filterText) then return false end
		
		if not visibilityMode then
			if InternalInterface.AccountSettings.Posting.HiddenItems[value.itemType] or InternalInterface.CharacterSettings.Posting.HiddenItems[value.itemType] then
				return false
			end
		end

		local auctionAmount = 0
		local postingQueue = _G[addonID].GetPostingQueue()
		for index, post in ipairs(postingQueue) do
			if post.itemType == value.itemType then
				auctionAmount = auctionAmount + post.amount
			end
		end
		value.adjustedStack = value.stack - auctionAmount
		if value.adjustedStack <= 0 then return false end
		
		return true
	end
	itemGrid:SetFilteringFunction(ItemGridFilter)	

	local paddingLeft, _, paddingRight, paddingBottom = itemGrid:GetPadding()
	filterFrame:SetPoint("TOPLEFT", itemGrid.externalPanel:GetContent(), "BOTTOMLEFT", paddingLeft + 2, 2 - paddingBottom)
	filterFrame:SetPoint("BOTTOMRIGHT", itemGrid.externalPanel:GetContent(), "BOTTOMRIGHT", -paddingRight - 2, -2)

	filterTextPanel:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 0, 2)
	filterTextPanel:SetPoint("BOTTOMRIGHT", filterFrame, "BOTTOMRIGHT", 0, -2)
	filterTextPanel:SetInvertedBorder(true)
	filterTextPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)

	visibilityIcon:SetPoint("CENTERRIGHT", filterTextPanel:GetContent(), "CENTERRIGHT", -5, 0)
	visibilityIcon:SetTexture(addonID, "Textures/ShowIcon.png")
	
	filterTextField:SetPoint("CENTERLEFT", filterTextPanel:GetContent(), "CENTERLEFT", 2, 1)
	filterTextField:SetPoint("CENTERRIGHT", visibilityIcon, "CENTERLEFT", -2, 1)
	filterTextField:SetText("")

	auctionGrid:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 300, 335)
	auctionGrid:SetPoint("BOTTOMRIGHT", postingFrame, "BOTTOMRIGHT", -5, -5)	
	auctionGrid:SetPadding(1, 1, 1, 38)
	auctionGrid:SetHeadersVisible(true)
	auctionGrid:SetRowHeight(20)
	auctionGrid:SetRowMargin(0)
	auctionGrid:SetUnselectedRowBackgroundColor(0.2, 0.2, 0.2, 0.25)
	auctionGrid:SetSelectedRowBackgroundColor(0.6, 0.6, 0.6, 0.25)
	auctionGrid:AddColumn("", 20, AuctionCachedRenderer)
	auctionGrid:AddColumn(L["PostingPanel/columnSeller"], 140, "Text", true, "sellerName", { Alignment = "left", Formatter = "none" })
	auctionGrid:AddColumn(L["PostingPanel/columnStack"], 60, "Text", true, "stack", { Alignment = "center", Formatter = "none" })
	auctionGrid:AddColumn(L["PostingPanel/columnBid"], 130, MoneyRenderer, true, "bidPrice")
	auctionGrid:AddColumn(L["PostingPanel/columnBuy"], 130, MoneyRenderer, true, "buyoutPrice")
	auctionGrid:AddColumn(L["PostingPanel/columnBidPerUnit"], 130, MoneyRenderer, true, "bidUnitPrice")--, { Compare = function() return CompareFunction()[1] end })
	local defaultOrderColumn = auctionGrid:AddColumn(L["PostingPanel/columnBuyPerUnit"], 130, MoneyRenderer, true, "buyoutUnitPrice")--, { Compare = function() return CompareFunction()[2] end })
	local function LocalizedDateFormatter(value)
		--return GetLocalizedDateString("%a %X", value)
		local diff = value - os.time()
		if diff <= 0 then return "" end
		local hours = math.floor(diff / 3600)
		local minutes = math.floor(math.floor(diff % 3600) / 60)
		local seconds = math.floor(diff % 60)
		if hours > 0 then
			return hours .. " h " .. minutes .. " m"
		elseif minutes > 0 then
			return minutes .. " m " .. seconds .. " s"
		else
			return seconds .. " s"
		end
		--return diff <= 0 and "" or math.floor(diff / 3600) .. " h " .. math.floor(math.floor(diff % 3600) / 60) .. " m " .. math.floor(diff % 60) .. " s"
		-- if diff <= 0 then return ""
		-- elseif diff <= 60 then return diff .. " s"
		-- elseif diff <= 3600 then return math.floor(diff / 60) .. " m"
		-- else return math.floor(diff / 3600) .. " h"
		-- end
	end	
	auctionGrid:AddColumn(L["PostingPanel/columnMinExpire"], 90, "Text", true, "minExpireTime", { Alignment = "right", Formatter = LocalizedDateFormatter })
	auctionGrid:AddColumn(L["PostingPanel/columnMaxExpire"], 90, "Text", true, "maxExpireTime", { Alignment = "right", Formatter = LocalizedDateFormatter })
	local function ScoreValue(value)
		local prices = {}
		for _, itemPrice in ipairs(itemPrices) do
			prices[itemPrice.key] = itemPrice
		end
		
		local score = _G[addonID].ScorePrice(nil, value, prices)
		
		if not score then return "" end

		return math.floor(score) .. " %"
	end
	local function ScoreColor(value)
		local prices = {}
		for _, itemPrice in ipairs(itemPrices) do
			prices[itemPrice.key] = itemPrice
		end
		local r, g, b = unpack(InternalInterface.UI.ScoreColorByScore(_G[addonID].ScorePrice(nil, value, prices)))
		return { r, g, b, 0.1 }
	end
	auctionGrid:AddColumn("Score", 60, "Text", true, "buyoutUnitPrice", { Alignment = "right", Formatter = ScoreValue, Color = ScoreColor }) -- LOCALIZE
	auctionGrid:AddColumn("", 0, AuctionRenderer, false, "buyoutUnitPrice", { Color = ScoreColor })
	defaultOrderColumn.Event.LeftClick(defaultOrderColumn)

	paddingLeft, _, paddingRight, paddingBottom = auctionGrid:GetPadding()
	controlFrame:SetPoint("TOPLEFT", auctionGrid.externalPanel:GetContent(), "BOTTOMLEFT", paddingLeft + 2, 2 - paddingBottom)
	controlFrame:SetPoint("BOTTOMRIGHT", auctionGrid.externalPanel:GetContent(), "BOTTOMRIGHT", -paddingRight - 2, -2)

	buyButton:SetPoint("CENTERRIGHT", controlFrame, "CENTERRIGHT", 0, 0)
	buyButton:SetText(L["PostingPanel/buttonBuy"])
	buyButton:SetEnabled(false)

	bidButton:SetPoint("CENTERRIGHT", buyButton, "CENTERLEFT", 10, 0)
	bidButton:SetText(L["PostingPanel/buttonBid"])
	bidButton:SetEnabled(false)

	auctionMoneySelector:SetPoint("TOPRIGHT", bidButton, "TOPLEFT", -5, 2)
	auctionMoneySelector:SetPoint("BOTTOMLEFT", bidButton, "BOTTOMLEFT", -230, -2)
	auctionMoneySelector:SetVisible(false)
	
	noBidLabel:SetFontColor(1, 0.5, 0, 1)
	noBidLabel:SetShadowColor(0.05, 0, 0.1, 1)
	noBidLabel:SetShadowOffset(2, 2)
	noBidLabel:SetFontSize(14)
	noBidLabel:SetText("")
	noBidLabel:SetPoint("CENTER", bidButton, "CENTERLEFT", -115, 0)

	refreshPanel:SetPoint("BOTTOMLEFT", controlFrame, "BOTTOMLEFT", 0, -2)
	refreshPanel:SetPoint("TOPRIGHT", bidButton, "TOPLEFT", -235, 2)
	refreshPanel:SetInvertedBorder(true)
	refreshPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)

	refreshButton:SetTexture(addonID, "Textures/RefreshMiniDisabled.png")
	refreshButton:SetPoint("TOPLEFT", refreshPanel:GetContent(), "TOPLEFT", 2, 1)
	refreshButton:SetPoint("BOTTOMRIGHT", refreshPanel:GetContent(), "BOTTOMLEFT", 22, -1)
	refreshButton.enabled = false

	refreshText:SetText(L["PostingPanel/lastUpdateMessage"] .. L["PostingPanel/lastUpdateDateFallback"])
	refreshText:SetPoint("CENTERLEFT", refreshButton, "CENTERRIGHT", 6, 0)

	itemTexturePanel:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 300, 5)
	itemTexturePanel:SetPoint("BOTTOMRIGHT", postingFrame, "TOPLEFT", 370, 75)
	itemTexturePanel:SetInvertedBorder(true)
	itemTexturePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)

	itemTexture:SetPoint("TOPLEFT", itemTexturePanel:GetContent(), "TOPLEFT", 1, 1)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTexturePanel:GetContent(), "BOTTOMRIGHT", -1, -1)
	itemTexture:SetVisible(false)
	
	itemNameLabel:SetPoint("BOTTOMLEFT", itemTexturePanel, "CENTERRIGHT", 5, 5)
	itemNameLabel:SetFontSize(20)
	itemNameLabel:SetText("")

	itemStackLabel:SetPoint("BOTTOMLEFT", itemTexturePanel, "BOTTOMRIGHT", 5, -1)
	itemStackLabel:SetFontSize(15)
	itemStackLabel:SetText("")

	pricingModelLabel:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 315, 105)
	pricingModelLabel:SetText(L["PostingPanel/labelPricingModel"])
	pricingModelLabel:SetFontSize(14)
	pricingModelLabel:SetFontColor(1, 1, 0.75, 1)
	pricingModelLabel:SetShadowOffset(2, 2)
	
	stackSizeLabel:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 315, 145)
	stackSizeLabel:SetText(L["PostingPanel/labelStackSize"])
	stackSizeLabel:SetFontSize(14)
	stackSizeLabel:SetFontColor(1, 1, 0.75, 1)
	stackSizeLabel:SetShadowOffset(2, 2)
	
	stackNumberLabel:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 315, 185)
	stackNumberLabel:SetText(L["PostingPanel/labelStackNumber"])
	stackNumberLabel:SetFontSize(14)
	stackNumberLabel:SetFontColor(1, 1, 0.75, 1)
	stackNumberLabel:SetShadowOffset(2, 2)
	
	bidLabel:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 315, 225)
	bidLabel:SetText(L["PostingPanel/labelUnitBid"])
	bidLabel:SetFontSize(14)
	bidLabel:SetFontColor(1, 1, 0.75, 1)
	bidLabel:SetShadowOffset(2, 2)
	
	buyLabel:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 315, 265)
	buyLabel:SetText(L["PostingPanel/labelUnitBuy"])
	buyLabel:SetFontSize(14)
	buyLabel:SetFontColor(1, 1, 0.75, 1)
	buyLabel:SetShadowOffset(2, 2)

	durationLabel:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 315, 305)
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
	
	pricingModelSelector:SetPoint("TOPRIGHT", postingFrame, "TOPRIGHT", -430, 100)
	pricingModelSelector:SetPoint("CENTERLEFT", pricingModelLabel, "CENTERRIGHT", maxLabelWidth - pricingModelLabel:GetWidth(), 1)
	
	priceMatchingCheck:SetPoint("CENTERLEFT", pricingModelSelector, "CENTERRIGHT", 15, 0)
	priceMatchingCheck:SetChecked(false)
	priceMatchingCheck:SetEnabled(false)
	
	priceMatchingLabel:SetFontSize(13)
	priceMatchingLabel:SetText(L["PostingPanel/checkPriceMatching"])
	priceMatchingLabel:SetPoint("BOTTOMLEFT", priceMatchingCheck, "BOTTOMRIGHT", 2, 2)

	stackSizeSelector:SetPoint("TOPRIGHT", postingFrame, "TOPRIGHT", -285, 145)
	stackSizeSelector:SetPoint("CENTERLEFT", stackSizeLabel, "CENTERRIGHT", maxLabelWidth - stackSizeLabel:GetWidth(), 5)
	
	stackNumberSelector:SetPoint("TOPRIGHT", postingFrame, "TOPRIGHT", -285, 185)
	stackNumberSelector:SetPoint("CENTERLEFT", stackNumberLabel, "CENTERRIGHT", maxLabelWidth - stackNumberLabel:GetWidth(), 5)

	bidMoneySelector:SetPoint("TOPRIGHT", postingFrame, "TOPRIGHT", -430, 221)
	bidMoneySelector:SetPoint("CENTERLEFT", bidLabel, "CENTERRIGHT", maxLabelWidth - bidLabel:GetWidth(), 0)
	
	bindPricesCheck:SetPoint("CENTERLEFT", bidMoneySelector, "CENTERRIGHT", 15, 0)
	bindPricesCheck:SetEnabled(false)
	
	bindPricesLabel:SetFontSize(13)
	bindPricesLabel:SetText(L["PostingPanel/checkBindPrices"])
	bindPricesLabel:SetPoint("BOTTOMLEFT", bindPricesCheck, "BOTTOMRIGHT", 2, 2)

	buyMoneySelector:SetPoint("TOPRIGHT", postingFrame, "TOPRIGHT", -430, 261)
	buyMoneySelector:SetPoint("CENTERLEFT", buyLabel, "CENTERRIGHT", maxLabelWidth - buyLabel:GetWidth(), 0)

	buyPriceWarning:SetFontSize(14)
	buyPriceWarning:SetFontColor(1, 0.25, 0, 1)
	buyPriceWarning:SetShadowColor(0.05, 0, 0.1, 1)
	buyPriceWarning:SetText(L["PostingPanel/buyWarningLowerSeller"])
	buyPriceWarning:SetPoint("CENTERLEFT", buyMoneySelector, "CENTERRIGHT", 15, 0)
	buyPriceWarning:SetVisible(false)

	postButton:SetPoint("BOTTOMRIGHT", postingFrame, "TOPRIGHT", -280, 332)
	postButton:SetText(L["PostingPanel/buttonPost"])
	postButton:SetEnabled(false)
	
	durationTimeLabel:SetPoint("BOTTOMLEFT", postingFrame, "TOPRIGHT", -555, 325)
	durationTimeLabel:SetText(string.format(L["PostingPanel/labelDurationFormat"], 48))

	durationSlider:SetPoint("CENTERRIGHT", durationTimeLabel, "CENTERLEFT", -15, 5)
	durationSlider:SetPoint("CENTERLEFT", durationLabel, "CENTERRIGHT", maxLabelWidth - durationLabel:GetWidth() + 10, 5)
	durationSlider:SetRange(1, 3)
	durationSlider:SetPosition(3)
	durationSlider:SetEnabled(false)

	autoPostButton:SetPoint("BOTTOMRIGHT", postingFrame, "TOPRIGHT", -10, 332)
	autoPostButton:SetText(L["PostingPanel/buttonAutoPostingMode"])

	clearButton:SetPoint("CENTERRIGHT", autoPostButton, "CENTERLEFT", 0, 0)
	clearButton:SetText(L["PostingPanel/buttonAutoPostingClear"])
	clearButton:SetVisible(false)
	clearButton:SetEnabled(false)
	
	queuePanel:SetPoint("TOPLEFT", postingFrame, "TOPRIGHT", -293, 5)
	queuePanel:SetPoint("BOTTOMRIGHT", postingFrame, "TOPRIGHT", -5, 74)
	queuePanel:SetInvertedBorder(true)
	queuePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)

	queueStatusLabel:SetPoint("TOPLEFT", queuePanel:GetContent(), "TOPLEFT", 5, 5)
	queueStatusLabel:SetText(L["PostingPanel/labelPostingQueueStatus"])
	queueStatusLabel:SetFontSize(14)
	queueStatusLabel:SetFontColor(1, 1, 0.75, 1)
	queueStatusLabel:SetShadowOffset(2, 2)	

	queueStatus:SetPoint("TOPRIGHT", queuePanel:GetContent(), "TOPRIGHT", -5, 6)
	queueStatus:SetText(L["PostingPanel/labelPostingQueueStatus2"])
	queueStatus:SetFontSize(13)

	showHideButton:SetPoint("BOTTOMRIGHT", queuePanel:GetContent(), "BOTTOMCENTER")
	showHideButton:SetText(L["PostingPanel/buttonShowQueue"])
	
	pauseResumeButton:SetPoint("BOTTOMLEFT", queuePanel:GetContent(), "BOTTOMCENTER")
	pauseResumeButton:SetText(L["PostingPanel/buttonPauseQueue"])
	
	queueGrid:SetPoint("TOPLEFT", queuePanel, "BOTTOMLEFT", 0, 0)
	queueGrid:SetPoint("BOTTOMRIGHT", queuePanel, "BOTTOMRIGHT", 0, 485)
	queueGrid:SetLayer(1000)
	queueGrid:SetPadding(0, 0, 0, 32)
	queueGrid:SetHeadersVisible(false)
	queueGrid:SetRowHeight(62)
	queueGrid:SetRowMargin(2)
	queueGrid:SetUnselectedRowBackgroundColor(0.15, 0.2, 0.15, 1)
	queueGrid:SetSelectedRowBackgroundColor(0.45, 0.6, 0.45, 1)
	queueGrid:AddColumn("", 248, QueueManagerRenderer, false)
	queueGrid.externalPanel.borderFrame:SetAlpha(1)
	queueGrid:SetVisible(false)
	
	queueClearButton:SetPoint("BOTTOMRIGHT", queueGrid.externalPanel:GetContent(), "BOTTOMCENTER")
	queueClearButton:SetText(L["PostingPanel/buttonCancelQueueAll"])
	queueClearButton:SetEnabled(false)
	
	queueCancelButton:SetPoint("BOTTOMLEFT", queueGrid.externalPanel:GetContent(), "BOTTOMCENTER")
	queueCancelButton:SetText(L["PostingPanel/buttonCancelQueueSelected"])
	queueCancelButton:SetEnabled(false)
	
	infoStacksLabel:SetPoint("CENTERLEFT", postingFrame, "TOPRIGHT", -275, 95)
	infoStacksLabel:SetText("Stacks:") -- LOCALIZE
	infoStacksLabel:SetFontSize(14)
	infoStacksLabel:SetFontColor(1, 1, 0.75, 1)
	infoStacksLabel:SetShadowOffset(2, 2)	

	totalBidLabel:SetPoint("CENTERLEFT", postingFrame, "TOPRIGHT", -275, 125)
	totalBidLabel:SetText("Total bid:") -- LOCALIZE
	totalBidLabel:SetFontSize(14)
	totalBidLabel:SetFontColor(1, 1, 0.75, 1)
	totalBidLabel:SetShadowOffset(2, 2)	

	totalBuyLabel:SetPoint("CENTERLEFT", postingFrame, "TOPRIGHT", -275, 155)
	totalBuyLabel:SetText("Total buyout:") -- LOCALIZE
	totalBuyLabel:SetFontSize(14)
	totalBuyLabel:SetFontColor(1, 1, 0.75, 1)
	totalBuyLabel:SetShadowOffset(2, 2)	
	
	depositLabel:SetPoint("CENTERLEFT", postingFrame, "TOPRIGHT", -275, 185)
	depositLabel:SetText("Deposit:") -- LOCALIZE
	depositLabel:SetFontSize(14)
	depositLabel:SetFontColor(1, 1, 0.75, 1)
	depositLabel:SetShadowOffset(2, 2)	

	discountBidLabel:SetPoint("CENTERLEFT", postingFrame, "TOPRIGHT", -275, 215)
	discountBidLabel:SetText("Adjusted bid:") -- LOCALIZE
	discountBidLabel:SetFontSize(14)
	discountBidLabel:SetFontColor(1, 1, 0.75, 1)
	discountBidLabel:SetShadowOffset(2, 2)	

	discountBuyLabel:SetPoint("CENTERLEFT", postingFrame, "TOPRIGHT", -275, 245)
	discountBuyLabel:SetText("Adjusted buyout:") -- LOCALIZE
	discountBuyLabel:SetFontSize(14)
	discountBuyLabel:SetFontColor(1, 1, 0.75, 1)
	discountBuyLabel:SetShadowOffset(2, 2)	

	infoStacks:SetPoint("CENTERRIGHT", postingFrame, "TOPRIGHT", -15, 95)
	infoStacks:SetText("0")

	infoTotalBid:SetPoint("CENTERRIGHT", postingFrame, "TOPRIGHT", -15, 125)
	infoTotalBid:SetHeight(20)

	infoTotalBuy:SetPoint("CENTERRIGHT", postingFrame, "TOPRIGHT", -15, 155)
	infoTotalBuy:SetHeight(20)

	infoDeposit:SetPoint("CENTERRIGHT", postingFrame, "TOPRIGHT", -15, 185)
	infoDeposit:SetText("?")

	infoDiscountBid:SetPoint("CENTERRIGHT", postingFrame, "TOPRIGHT", -15, 215)
	infoDiscountBid:SetHeight(20)

	infoDiscountBuy:SetPoint("CENTERRIGHT", postingFrame, "TOPRIGHT", -15, 245)
	infoDiscountBuy:SetHeight(20)


	

	function filterTextPanel.Event:LeftClick()
		filterTextField:SetKeyFocus(true)
	end

	function filterTextField.Event:KeyFocusGain()
		local length = string.len(self:GetText())
		if length > 0 then
			self:SetSelection(0, length)
		end
	end
	
	function refreshButton.Event:MouseIn()
		if self.enabled then
			self:SetTexture(addonID, "Textures/RefreshMiniOn.png")
		else
			self:SetTexture(addonID, "Textures/RefreshMiniDisabled.png")
		end
	end
	
	function refreshButton.Event:MouseOut()
		if self.enabled then
			self:SetTexture(addonID, "Textures/RefreshMiniOff.png")
		else
			self:SetTexture(addonID, "Textures/RefreshMiniDisabled.png")
		end
	end
	
	function filterTextField.Event:TextfieldChange()
		SetRefreshMode(REFRESH_ITEMFILTER)
	end
	
	function visibilityIcon.Event:LeftClick()
		visibilityMode = not visibilityMode
		SetRefreshMode(REFRESH_ITEMFILTER)
	end
	
	function showHideButton.Event:LeftPress()
		local visible = not queueGrid:GetVisible()
		queueGrid:SetVisible(visible)
		self:SetText(visible and L["PostingPanel/buttonHideQueue"] or L["PostingPanel/buttonShowQueue"])
	end
	
	function pauseResumeButton.Event:LeftPress()
		_G[addonID].SetPostingQueuePaused(not _G[addonID].GetPostingQueuePaused())
	end	

	function queueClearButton.Event:LeftPress()
		while #_G[addonID].GetPostingQueue() > 0 do
			_G[addonID].CancelPostingByIndex(1)
		end
	end
	
	function queueCancelButton.Event:LeftPress()
		local key = queueGrid:GetSelectedData()
		if key then
			_G[addonID].CancelPostingByIndex(key)
		end
	end
	
	function queueGrid.Event:SelectionChanged(key, value)
		queueCancelButton:SetEnabled(key and true or false)
	end
	
	function buyButton.Event:LeftPress()
		local auctionID, auctionData = auctionGrid:GetSelectedData()
		if auctionID then
			Command.Auction.Bid(auctionID, auctionData.buyoutPrice, function(...) InternalInterface.AHMonitoringService.AuctionBuyCallback(auctionID, ...) end)
		end
	end
	
	function bidButton.Event:LeftPress()
		local auctionID = auctionGrid:GetSelectedData()
		if auctionID then
			local bidAmount = auctionMoneySelector:GetValue()
			Command.Auction.Bid(auctionID, bidAmount, function(...) InternalInterface.AHMonitoringService.AuctionBidCallback(auctionID, bidAmount, ...) end)
		end
	end
	
	function refreshButton.Event:LeftClick()
		if not self.enabled then return end
		
		local item, itemInfo = itemGrid:GetSelectedData()
		if not item then return end
		
		if not pcall(Command.Auction.Scan, { type = "search", index = 0, text = itemInfo.name, rarity = itemInfo.rarity or "common", sort = "time", sortOrder = "descending" }) then
			out(L["PostingPanel/itemScanError"])
		else
			InternalInterface.ScanNext()
			out(L["PostingPanel/itemScanStarted"])
		end				
	end

	function itemGrid.Event:SelectionChanged(item, itemInfo)
		SetRefreshMode(REFRESH_ITEM)
	end	

	function auctionGrid.Event:SelectionChanged(auctionID, auctionData)
		SetRefreshMode(REFRESH_AUCTION)
	end

	function autoPostButton.Event:RightClick()
		autoPostingMode = not autoPostingMode
		postButton:SetText(autoPostingMode and L["PostingPanel/buttonAutoPostingSave"] or L["PostingPanel/buttonPost"])
		clearButton:SetVisible(autoPostingMode)
		SetRefreshMode(REFRESH_POSTING)
	end
	
	function clearButton.Event:LeftPress()
		local selectedItem, selectedInfo = itemGrid:GetSelectedData()
		if not selectedItem or not selectedInfo then return end

		local pricingModelCallback = _G[addonID].GetPricingModel(InternalInterface.CharacterSettings.Posting.AutoConfig[selectedInfo.itemType].pricingModelOrder)
		pricingModelCallback = pricingModelCallback and pricingModelCallback.callbackFunction or nil
		if type(pricingModelCallback) == "function" then
			pricingModelCallback(selectedInfo.itemType, nil, nil, true)
		end		
		
		InternalInterface.CharacterSettings.Posting.AutoConfig[selectedInfo.itemType] = nil
		SetRefreshMode(REFRESH_ITEMFILTER)
	end
	
	function stackSizeSelector.Event:PositionChanged(stackSize)
		local selectedItem, selectedInfo = itemGrid:GetSelectedData()
		if stackSize > 0 and selectedItem then
			local stacks = selectedInfo.adjustedStack
			local maxNumberOfStacks = math.ceil(stacks / stackSize)
			stackNumberSelector:SetRange(1, maxNumberOfStacks)
			stackNumberSelector:SetPosition(maxNumberOfStacks)
		else
			stackNumberSelector:SetRange(0, 0)
		end
		SetRefreshMode(REFRESH_INFO)
	end
	
	function stackNumberSelector.Event:PositionChanged(stackNumber)
		SetRefreshMode(REFRESH_INFO)
	end

	function postButton.Event:LeftPress()
		if self.cooldown and Inspect.Time.Real() < self.cooldown then return end
		local selectedItem, selectedInfo = itemGrid:GetSelectedData()
		if not selectedItem or not selectedInfo then return end
		
		local priceIndex, price = pricingModelSelector:GetSelectedValue()
		local pricingModelId = price and price.key or nil
		local savePriceMatching = priceMatchingCheck:GetChecked()
		local stackSize = stackSizeSelector:GetPosition()
		local stackNumber = stackNumberSelector:GetPosition()
		local bidUnitPrice = bidMoneySelector:GetValue()
		local saveBindPrices = bindPricesCheck:GetChecked()
		local buyUnitPrice = buyMoneySelector:GetValue()
		local saveDuration = durationSlider:GetPosition()
		local duration = 6 * 2 ^ saveDuration
		
		if not pricingModelId or stackSize <= 0 or stackNumber <= 0 or bidUnitPrice <= 0 then return end
		if buyUnitPrice <= 0 then 
			buyUnitPrice = nil
		elseif buyUnitPrice < bidUnitPrice then
			out(L["PostingPanel/postErrorBidHigherBuy"])
			return
		end
		
		local amount = math.min(stackSize * stackNumber, selectedInfo.adjustedStack)
		if amount <= 0 then return end
		
		if autoPostingMode or _G[addonID].PostItem(selectedItem, stackSize, amount, bidUnitPrice, buyUnitPrice, duration) then
			local config = { pricingModelOrder = pricingModelId, usePriceMatching = savePriceMatching, stackSize = stackSize, bindPrices = saveBindPrices, duration = saveDuration, }
			
			if autoPostingMode then
				InternalInterface.CharacterSettings.Posting.AutoConfig[selectedInfo.itemType] = config
			else
				InternalInterface.CharacterSettings.Posting.ItemConfig[selectedInfo.itemType] = config
				self.cooldown = Inspect.Time.Real() + 0.5
			end

			local pricingModelCallback = _G[addonID].GetPricingModel(pricingModelId)
			pricingModelCallback = pricingModelCallback and pricingModelCallback.callbackFunction or nil
			if pricingModelCallback then
				pricingModelCallback(selectedInfo.itemType, bidUnitPrice, buyUnitPrice, autoPostingMode)
			end
		
			SetRefreshMode(REFRESH_ITEMFILTER)
		end
	end
	
	function durationSlider.Event:SliderChange()
		local position = self:GetPosition()
		durationTimeLabel:SetText(string.format(L["PostingPanel/labelDurationFormat"], 6 * 2 ^ position))
		SetRefreshMode(REFRESH_INFO)
	end
	
	function autoPostButton.Event:LeftClick()
		local slot = Utility.Item.Slot.Inventory()
		local items = Inspect.Item.List(slot)
		
		local itemTypeTable = {}
		for _, itemID in pairs(items) do repeat
			if type(itemID) == "boolean" then break end 
			local ok, itemDetail = pcall(Inspect.Item.Detail, itemID)
			if not ok or not itemDetail or itemDetail.bound then break end
			
			local itemType = itemDetail.type
			itemTypeTable[itemType] = itemTypeTable[itemType] or { name = itemDetail.name, stack = 0, referenceItem = itemID, }
			itemTypeTable[itemType].stack = itemTypeTable[itemType].stack + (itemDetail.stack or 1)
		until true end

		local postingAmounts = {}
		local postingQueue = _G[addonID].GetPostingQueue()
		for index, post in ipairs(postingQueue) do
			postingAmounts[post.itemType] = (postingAmounts[post.itemType] or 0) + post.amount
		end
		
		local remainingItems = false
		for itemType, itemData in pairs(itemTypeTable) do
			if not InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] then
				itemTypeTable[itemType] = nil
			else
				itemTypeTable[itemType].autoPosting = InternalInterface.CharacterSettings.Posting.AutoConfig[itemType]
				itemTypeTable[itemType].stack = itemTypeTable[itemType].stack - (postingAmounts[itemType] or 0)
				if itemTypeTable[itemType].stack <= 0 then
					itemTypeTable[itemType] = nil
				else
					remainingItems = true 
				end
			end
		end
		if not remainingItems then
			out(L["PostingPanel/autoPostingErrorNoItems"])
			return
		end
		
		for itemType, itemData in pairs(itemTypeTable) do repeat
			local pricingModelOrder = itemData.autoPosting.pricingModelOrder
			local prices = _G[addonID].GetPricings(itemData.referenceItem, true)
			
			if not prices[pricingModelOrder] then
				itemTypeTable[itemType] = nil
				out(string.format(L["PostingPanel/autoPostingErrorPricingModelNotFound"], itemData.name))
				break
			end

			local unitBid = prices[pricingModelOrder].bid
			local unitBuy = prices[pricingModelOrder].buy or 0
			local usePriceMatching = itemData.autoPosting.usePriceMatching
			
			if usePriceMatching then
				unitBid, unitBuy = _G[addonID].MatchPrice(itemData.referenceItem, unitBid, unitBuy)
			end
			
			if itemData.autoPosting.bindPrices then unitBid = unitBuy end
			itemTypeTable[itemType].unitBid = unitBid
			itemTypeTable[itemType].unitBuy = unitBuy
		until true end
		
		for _, itemData in pairs(itemTypeTable) do
			_G[addonID].PostItem(itemData.referenceItem, itemData.autoPosting.stackSize, itemData.stack, itemData.unitBid, itemData.unitBuy, 6 * 2 ^ itemData.autoPosting.duration)	
		end
	end
	
	function pricingModelSelector.Event:SelectionChanged()
		SetRefreshMode(REFRESH_PRICES)
	end

	function priceMatchingCheck.Event:CheckboxChange()
		SetRefreshMode(REFRESH_PRICES)
	end

	function bindPricesCheck.Event:CheckboxChange()
		if self:GetChecked() then
			pricesSetByModel = true
			local maxPrice = math.max(bidMoneySelector:GetValue(), buyMoneySelector:GetValue())
			bidMoneySelector:SetValue(maxPrice)
			buyMoneySelector:SetValue(maxPrice)
			pricesSetByModel = false
		else
			SetRefreshMode(REFRESH_PRICES)
		end
	end
	
	function bidMoneySelector.Event:ValueChanged(newValue)
		if not self:GetEnabled() then return end
		if bindPricesCheck:GetChecked() then
			local buy = buyMoneySelector:GetValue()
			if buy ~= newValue then
				buyMoneySelector:SetValue(newValue)
			end
		end
		if not pricesSetByModel then
			for index, price in ipairs(itemPrices) do
				if price.key == "fixed" then
					itemPrices[index].bid = newValue
					itemPrices[index].buy = buyMoneySelector:GetValue()
					pricingModelSelector:SetValues(itemPrices)
					pricingModelSelector:SetSelectedIndex(index)
				end
			end
		end
		SetRefreshMode(REFRESH_INFO)
	end
	
	function buyMoneySelector.Event:ValueChanged(newValue)
		if not self:GetEnabled() then return end
		if bindPricesCheck:GetChecked() then
			local bid = bidMoneySelector:GetValue()
			if bid ~= newValue then
				bidMoneySelector:SetValue(newValue)
			end
		end
		if not pricesSetByModel then
			for index, price in ipairs(itemPrices) do
				if price.key == "fixed" then
					itemPrices[index].bid = bidMoneySelector:GetValue()
					itemPrices[index].buy = newValue
					pricingModelSelector:SetValues(itemPrices)
					pricingModelSelector:SetSelectedIndex(index)
				end
			end
		end
		local _, selectedInfo = itemGrid:GetSelectedData()
		buyPriceWarning:SetVisible((selectedInfo and newValue > 0 and newValue < math.ceil((selectedInfo.sell or 0) / AUCTION_FEE_REDUCTION)) or false)
		SetRefreshMode(REFRESH_INFO)
	end


	table.insert(Event.Item.Slot, { function() SetRefreshMode(REFRESH_ITEMS) end, addonID, "PostingFrame.OnItemSlot" })
	table.insert(Event.Item.Update, { function() SetRefreshMode(REFRESH_ITEMS) end, addonID, "PostingFrame.OnItemUpdate" })
	table.insert(Event[addonID].PostingQueueChanged, { function() SetRefreshMode(REFRESH_ITEMFILTER) end, addonID, "PostingFrame.OnPostingQueueChanged" })	
	table.insert(Event[addonID].AuctionData, { function() SetRefreshMode(REFRESH_AUCTIONS) end, addonID, "PostingFrame.OnAuctionData" })
	table.insert(Event.Interaction, { function(interaction) if interaction == "auction" then SetRefreshMode(REFRESH_AUCTION) end end, addonID, "PostingFrame.OnInteraction" })

	local function OnQueueStatusChanged()
		local status, size = _G[addonID].GetPostingQueueStatus()
		local paused = _G[addonID].GetPostingQueuePaused()
		
		queueStatus:SetText(string.format("%s (%d)", L["PostingPanel/labelPostingQueueStatus" .. status], size or 0))
		pauseResumeButton:SetText(paused and L["PostingPanel/buttonResumeQueue"] or L["PostingPanel/buttonPauseQueue"])
		if status == 1 or status == 3 then
			queueStatus:SetFontColor(1, 0.5, 0, 1)
		else
			queueStatus:SetFontColor(1, 1, 1, 1)
		end
		
		local queue = _G[addonID].GetPostingQueue()
		local auctions = {}
		local clearable = false
		for index, data in ipairs(queue) do
			auctions[index] = data
			clearable = true
		end
		queueGrid:SetData(auctions)
		queueClearButton:SetEnabled(clearable)
	end
	table.insert(Event[addonID].PostingQueueStatusChanged, { OnQueueStatusChanged, addonID, "QueueManager.OnQueueStatusChanged" })
	
	OnQueueStatusChanged()	
	
	function postingFrame:Show(hEvent)
		SetRefreshMode(REFRESH_ITEMS)
	end
	
	return postingFrame
end
