local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local AUCTION_FEE_REDUCTION = 0.95

local CABid = Command.Auction.Bid
local CAScan = Command.Auction.Scan
local CTooltip = Command.Tooltip
local IInteraction = Inspect.Interaction
local IIDetail = Inspect.Item.Detail
local IIList = Inspect.Item.List
local ITReal = Inspect.Time.Real
local MCeil = math.ceil
local MFloor = math.floor
local MMax = math.max
local MMin = math.min
local SFind = string.find
local SFormat = string.format
local SLen = string.len
local SUpper = string.upper
local TInsert = table.insert
local UICreateFrame = UI.CreateFrame
local UISInventory = Utility.Item.Slot.Inventory

local L = InternalInterface.Localization.L
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local RemainingTimeFormatter = InternalInterface.Utility.RemainingTimeFormatter
local ScoreColorByScore = InternalInterface.UI.ScoreColorByScore
local GetLocalizedDateString = InternalInterface.Utility.GetLocalizedDateString
local out = InternalInterface.Output.Write

-- ItemRenderer
local function ItemRenderer(name, parent)
	local itemCell = UICreateFrame("Texture", name, parent)
	itemCell:SetTexture(addonID, "Textures/ItemRowBackground.png")

	local itemTextureBackground = UICreateFrame("Frame", name .. ".ItemTextureBackground", itemCell)
	local itemTexture = UICreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = UICreateFrame("BShadowedText", name .. ".ItemNameLabel", itemCell)
	local visibilityIcon = UICreateFrame("Texture", name .. ".VisibilityIcon", itemCell)
	local itemStackLabel = UICreateFrame("Text", name .. ".ItemStackLabel", itemCell)
	local autoPostingLabel = UICreateFrame("Text", name .. ".AutoPostingLabel", itemCell)
	
	local resetGridFunction = nil

	
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
		resetGridFunction = extra and extra.ResetGridFunction or nil

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
		if resetGridFunction then resetGridFunction() end
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
		if resetGridFunction then resetGridFunction() end
	end
	
	function itemTexture.Event:MouseIn()
		CTooltip(visibilityIcon.itemType)
	end
	
	function itemTexture.Event:MouseOut()
		CTooltip(nil)
	end	
	
	return itemCell
end

-- QueueManagerRenderer
local function QueueManagerRenderer(name, parent)
	local queueManagerCell = UICreateFrame("Texture", name, parent)
	queueManagerCell:SetTexture(addonID, "Textures/ItemRowBackground.png")
	
	local itemTextureBackground = UICreateFrame("Frame", name .. ".ItemTextureBackground", queueManagerCell)
	local itemTexture = UICreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = UICreateFrame("BShadowedText", name .. ".ItemNameLabel", queueManagerCell)
	local itemStackLabel = UICreateFrame("Text", name .. ".ItemStackLabel", queueManagerCell)
	local bidMoneyDisplay = UICreateFrame("BMoneyDisplay", name .. ".BidMoneyDisplay", queueManagerCell)
	local buyMoneyDisplay = UICreateFrame("BMoneyDisplay", name .. ".BuyMoneyDisplay", queueManagerCell)

	itemTextureBackground:SetPoint("CENTERLEFT", queueManagerCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	queueManagerCell.itemTextureBackground = itemTextureBackground
	
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	queueManagerCell.itemTexture = itemTexture
	
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("TOPLEFT", queueManagerCell, "TOPLEFT", 58, 0)
	queueManagerCell.itemNameLabel = itemNameLabel	
	
	itemStackLabel:SetPoint("BOTTOMLEFT", queueManagerCell, "BOTTOMLEFT", 58, 0)
	queueManagerCell.itemStackLabel = itemStackLabel
	
	bidMoneyDisplay:SetPoint("TOPLEFT", queueManagerCell, "BOTTOMRIGHT", -120, -40)
	bidMoneyDisplay:SetPoint("BOTTOMRIGHT", queueManagerCell, "BOTTOMRIGHT", 0, -20)
	queueManagerCell.bidMoneyDisplay = bidMoneyDisplay
	
	buyMoneyDisplay:SetPoint("TOPLEFT", queueManagerCell, "BOTTOMRIGHT", -120, -20)
	buyMoneyDisplay:SetPoint("BOTTOMRIGHT", queueManagerCell, "BOTTOMRIGHT", 0, 0)
	queueManagerCell.buyMoneyDisplay = buyMoneyDisplay

	function queueManagerCell:SetValue(key, value, width, extra)
		local itemDetail = IIDetail(value.itemType)
		self:SetWidth(width)
		self.itemTextureBackground:SetBackgroundColor(GetRarityColor(itemDetail.rarity))
		self.itemTexture:SetTexture("Rift", itemDetail.icon)
		self.itemTexture.itemType = value.itemType
		self.itemNameLabel:SetText(itemDetail.name)
		self.itemNameLabel:SetFontColor(GetRarityColor(itemDetail.rarity))
		
		local fullStacks = MFloor(value.amount / value.stackSize)
		local oddStack = value.amount % value.stackSize
		local stack = ""
		if fullStacks > 0 and oddStack > 0 then
			stack = SFormat("%d x %d + %d", fullStacks, value.stackSize, oddStack)
		elseif fullStacks > 0 then
			stack = SFormat("%d x %d", fullStacks, value.stackSize)
		else
			stack = tostring(oddStack)
		end
		self.itemStackLabel:SetText(stack)
		
		self.bidMoneyDisplay:SetValue(value.amount * (value.unitBidPrice or 0))
		self.buyMoneyDisplay:SetValue(value.amount * (value.unitBuyoutPrice or 0))
	end
	
	function itemTexture.Event:MouseIn()
		CTooltip(self.itemType)
	end
	
	function itemTexture.Event:MouseOut()
		CTooltip(nil)
	end
	
	return queueManagerCell
end

-- PostingFrame
function InternalInterface.UI.PostingFrame(name, parent)
	local postingFrame = UICreateFrame("Frame", name, parent)
	
	local itemGrid = UICreateFrame("BDataGrid", name .. ".ItemGrid", postingFrame)
	local filterFrame = UICreateFrame("Frame", name .. ".FilterFrame", itemGrid.externalPanel:GetContent())
	local filterTextPanel = UICreateFrame("BPanel", filterFrame:GetName() .. ".FilterTextPanel", filterFrame)
	local visibilityIcon = UICreateFrame("Texture", filterFrame:GetName() .. ".VisibilityIcon", filterTextPanel:GetContent())
	local filterTextField = UICreateFrame("RiftTextfield", filterFrame:GetName() .. ".FilterTextField", filterTextPanel:GetContent())
	
	local auctionGrid = UICreateFrame("BDataGrid", name .. ".AuctionGrid", postingFrame)
	local controlFrame = UICreateFrame("Frame", name .. ".ControlFrame", auctionGrid.externalPanel:GetContent())
	local buyButton = UICreateFrame("RiftButton", name .. ".BuyButton", controlFrame)
	local bidButton = UICreateFrame("RiftButton", name .. ".BidButton", controlFrame)
	local auctionMoneySelector = UICreateFrame("BMoneySelector", name .. ".AuctionMoneySelector", controlFrame)
	local noBidLabel = UICreateFrame("BShadowedText", name .. ".NoBidLabel", controlFrame)
	local refreshPanel = UICreateFrame("BPanel", name .. ".RefreshPanel", controlFrame)
	local refreshButton = UICreateFrame("Texture", name .. ".RefreshButton", refreshPanel:GetContent())
	local refreshText = UICreateFrame("Text", name .. ".RefreshLabel", refreshPanel:GetContent())
	
	local itemTexturePanel = UICreateFrame("BPanel", name .. ".ItemTexturePanel", postingFrame)
	local itemTexture = UICreateFrame("Texture", name .. ".ItemTexture", itemTexturePanel:GetContent())
	local itemNameLabel = UICreateFrame("BShadowedText", name .. ".ItemNameLabel", postingFrame)
	local itemStackLabel = UICreateFrame("BShadowedText", name .. ".ItemStackLabel", postingFrame)
	local pricingModelLabel = UICreateFrame("BShadowedText", name .. ".PricingModelLabel", postingFrame)
	local stackSizeLabel = UICreateFrame("BShadowedText", name .. ".StackSizeLabel", postingFrame)
	local stackNumberLabel = UICreateFrame("BShadowedText", name .. ".StackNumberLabel", postingFrame)
	local bidLabel = UICreateFrame("BShadowedText", name .. ".BidLabel", postingFrame)
	local buyLabel = UICreateFrame("BShadowedText", name .. ".BuyLabel", postingFrame)
	local durationLabel = UICreateFrame("BShadowedText", name .. ".DurationLabel", postingFrame)
	local pricingModelSelector = UICreateFrame("BDropdown", name .. ".PricingModelSelector", postingFrame)
	local priceMatchingCheck = UICreateFrame("RiftCheckbox", name .. ".PriceMatchingCheck", postingFrame)
	local priceMatchingLabel = UICreateFrame("BShadowedText", name .. ".PriceMatchingLabel", postingFrame)
	local stackSizeSelector = UICreateFrame("BSlider", name .. ".StackSizeSelector", postingFrame)
	local stackNumberSelector = UICreateFrame("BSlider", name .. ".StackNumberSelector", postingFrame)
	local bidMoneySelector = UICreateFrame("BMoneySelector", name .. ".BidMoneySelector", postingFrame)
	local bindPricesCheck = UICreateFrame("RiftCheckbox", name .. ".BindPricesCheck", postingFrame)
	local bindPricesLabel = UICreateFrame("BShadowedText", name .. ".BindPricesLabel", postingFrame)
	local buyMoneySelector = UICreateFrame("BMoneySelector", name .. ".BuyMoneySelector", postingFrame)
	local buyPriceWarning = UICreateFrame("BShadowedText", name .. ".BuyPriceWarning", postingFrame)
	local postButton = UICreateFrame("RiftButton", name .. ".PostButton", postingFrame)
	local durationTimeLabel = UICreateFrame("BShadowedText", name .. ".DurationTimeLabel", postingFrame)
	local durationSlider = UICreateFrame("RiftSlider", name .. ".DurationSlider", postingFrame)
	local autoPostButton = UICreateFrame("RiftButton", name .. ".AutoPostButton", postingFrame)
	local clearButton = UICreateFrame("RiftButton", name .. ".ClearButton", postingFrame)
	
	local queuePanel = UICreateFrame("BPanel", name .. ".QueuePanel", postingFrame)
	local pauseResumeButton = UICreateFrame("RiftButton", name .. ".PauseResumeButton", queuePanel:GetContent())
	local queueStatusLabel = UICreateFrame("BShadowedText", name .. ".QueueStatusLabel", queuePanel:GetContent())
	local queueStatus = UICreateFrame("BShadowedText", name .. ".QueueStatus", queuePanel:GetContent())
	local showHideButton = UICreateFrame("RiftButton", name .. ".ShowHideButton", queuePanel:GetContent())
	local queueGrid = UICreateFrame("BDataGrid", name .. ".QueueGrid", postingFrame)
	local queueClearButton = UICreateFrame("RiftButton", name .. ".QueueClearButton", queueGrid.externalPanel:GetContent())
	local queueCancelButton = UICreateFrame("RiftButton", name .. ".QueueCancelButton", queueGrid.externalPanel:GetContent())
	
	local infoStacksLabel = UICreateFrame("BShadowedText", name .. ".InfoStacksLabel", postingFrame)
	local totalBidLabel = UICreateFrame("BShadowedText", name .. ".TotalBidLabel", postingFrame)
	local totalBuyLabel = UICreateFrame("BShadowedText", name .. ".TotalBuyLabel", postingFrame)
	local depositLabel = UICreateFrame("BShadowedText", name .. ".DepositLabel", postingFrame)
	local discountBidLabel = UICreateFrame("BShadowedText", name .. ".DiscountBidLabel", postingFrame)
	local discountBuyLabel = UICreateFrame("BShadowedText", name .. ".DiscountBuyLabel", postingFrame)
	local infoStacks = UICreateFrame("Text", name .. ".InfoStacks", postingFrame)
	local infoTotalBid = UICreateFrame("BMoneyDisplay", name .. ".InfoTotalBid", postingFrame)
	local infoTotalBuy = UICreateFrame("BMoneyDisplay", name .. ".InfoTotalBuy", postingFrame)
	local infoDeposit = UICreateFrame("Text", name .. ".InfoDeposit", postingFrame)
	local infoDiscountBid = UICreateFrame("BMoneyDisplay", name .. "IinfoDiscountBid", postingFrame)
	local infoDiscountBuy = UICreateFrame("BMoneyDisplay", name .. "IinfoDiscountBuy", postingFrame)
	
	local visibilityMode = false
	local itemPrices = {}
	local autoPostingMode = false
	local pricesSetByModel = false

	local function AuctionRightClick(self)
		local data = self.dataValue
		local bid = data and data.bidUnitPrice or nil
		local buy = data and data.buyoutUnitPrice or 0
		if bid then
			if not data.own then
				bid = MMax(bid - 1, 1)
				buy = buy == 0 and buy or MMax(buy - 1, 1)
			end	
			bidMoneySelector:SetValue(bid)
			buyMoneySelector:SetValue(buy)
		end
		self.Event.LeftClick(self)
	end

	local function UpdatePostingConfig(item, itemInfo, newIndex)
		if item and itemInfo then
			local defaultConfig = InternalInterface.AccountSettings.Posting.DefaultConfig
			local itemConfig = InternalInterface.CharacterSettings.Posting.ItemConfig[itemInfo.itemType]
			local autoConfig = InternalInterface.CharacterSettings.Posting.AutoConfig[itemInfo.itemType]
			local config = autoPostingMode and autoConfig or itemConfig or defaultConfig
			
			local pricingModelOrder = config.pricingModelOrder

			local pricingModelIndex = newIndex
			
			if not pricingModelIndex then
				if type(pricingModelOrder) == "string" then
					pricingModelOrder = { pricingModelOrder }
					for _, pricingModelId in ipairs(defaultConfig.pricingModelOrder) do
						if pricingModelId ~= pricingModelOrder[1] then
							TInsert(pricingModelOrder, pricingModelId)
						end
					end
				end
				
				for _, pricingModelId in ipairs(pricingModelOrder) do
					for index, price in ipairs(itemPrices) do
						if price.key == pricingModelId then
							pricingModelIndex = index
							break
						end
					end
					if pricingModelIndex then break end
				end
			end

			itemTexturePanel:GetContent():SetBackgroundColor(GetRarityColor(itemInfo.rarity))
			itemTexture:SetVisible(true)
			itemTexture:SetTexture("Rift", itemInfo.icon)
			itemTexture.itemType = itemInfo.itemType
			itemNameLabel:SetText(itemInfo.name)
			itemNameLabel:SetFontColor(GetRarityColor(itemInfo.rarity))
			itemNameLabel:SetVisible(true)
			itemStackLabel:SetText(SFormat(L["PostingPanel/labelItemStack"], itemInfo.adjustedStack))
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
	
	local function UpdatePrices(item, itemInfo)
		local _, prevKey = pricingModelSelector:GetSelectedValue()
		prevKey = prevKey and prevKey.key or nil
		itemPrices = {}
		
		local function ProcessPricings(pricings)
			local newIndex = nil
			
			for key, value in pairs(pricings) do
				value.key = key
				TInsert(itemPrices, value)
				if key == prevKey then newIndex = #itemPrices end
			end
			
			-- pricesSetByModel = true
			-- bidMoneySelector:SetCompareFunction(function(value) return ScoreColorByScore(_G[addonID].ScorePrice(item, value, pricings)) end)
			-- buyMoneySelector:SetCompareFunction(function(value) return ScoreColorByScore(_G[addonID].ScorePrice(item, value, pricings)) end)
			-- pricesSetByModel = false
			
			pricingModelSelector:SetValues(itemPrices)
			UpdatePostingConfig(item, itemInfo, newIndex)
		end

		if item and itemInfo then
			_G[addonID].GetPricings(ProcessPricings, itemInfo.itemType, autoPostingMode)
		else
			ProcessPricings({})
		end
	end

	local function ResetAuctionGrid(auctions, lastUpdate)
		auctionGrid:SetData(auctions)
		for index, row in ipairs(auctionGrid.rows) do
			row.Event.RightClick = AuctionRightClick
		end
		if (lastUpdate or 0) <= 0 then
			refreshText:SetText(L["PostingPanel/lastUpdateMessage"] .. L["PostingPanel/lastUpdateDateFallback"])
		else
			refreshText:SetText(L["PostingPanel/lastUpdateMessage"] .. GetLocalizedDateString(L["PostingPanel/lastUpdateDateFormat"], lastUpdate))
		end		
	end
	
	local function ResetAuctions()
		auctionGrid:SetData({})
		UpdatePrices()

		local itemID, itemData = itemGrid:GetSelectedData()
		if itemData then
			_G[addonID].GetActiveAuctionsScored(ResetAuctionGrid, itemData.itemType)
			UpdatePrices(itemID, itemData)
		end
	end	
	
	local function ResetItems()
		if not postingFrame:GetVisible() then return end
		local slot = UISInventory()
		local items = IIList(slot)
		
		local itemTypeTable = {}
		for _, itemID in pairs(items) do repeat
			if type(itemID) == "boolean" then break end 
			local ok, itemDetail = pcall(IIDetail, itemID)
			if not ok or not itemDetail or itemDetail.bound then break end
			
			local itemType = itemDetail.type
			itemTypeTable[itemType] = itemTypeTable[itemType] or { name = itemDetail.name, icon = itemDetail.icon, rarity = itemDetail.rarity, stack = 0, stackMax = itemDetail.stackMax, sell = itemDetail.sell, items = {} }
			itemTypeTable[itemType].stack = itemTypeTable[itemType].stack + (itemDetail.stack or 1)
			TInsert(itemTypeTable[itemType].items, itemID)
		until true end
		
		local itemTable = {}
		for itemType, itemData in pairs(itemTypeTable) do
			if itemData.stack > 0 and #itemData.items > 0 then
				itemTable[itemData.items[1]] = itemData
				itemTable[itemData.items[1]].itemType = itemType
				itemData.items = nil
			end
		end

		local key = itemGrid:GetSelectedData()
		itemGrid:SetData(nil)
		itemGrid:SetData(itemTable)
		if key then
			itemGrid.lastSelectedKey = key
			itemGrid:ForceUpdate()
			ResetAuctions()
		end
	end		

	local function RefreshAuctionButtons()
		local auctionSelected = false
		local auctionInteraction = IInteraction("auction")
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
			highestBidder = (selectedAuctionData.ownBidded or 0) == selectedAuctionData.bidPrice
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
	
	local function ApplyPricingModel()
		local item, itemInfo = itemGrid:GetSelectedData()
		local _, value = pricingModelSelector:GetSelectedValue()

		local function PriceMatched(bid, buy)
			pricesSetByModel = true
			bidMoneySelector:SetValue(bid)
			buyMoneySelector:SetValue(buy)
			pricesSetByModel = false
		end
		
		if item and itemInfo and value then
			local bid, buy = value.bid, value.buy
			if priceMatchingCheck:GetChecked() and itemPrices[pricingModelSelector:GetSelectedValue()].key ~= "fixed" then
				_G[addonID].MatchPrice(PriceMatched, itemInfo.itemType, bid, buy)
			else
				PriceMatched(bid, buy)
			end
		else
			PriceMatched(0, 0)
		end	
	end
	
	local function UpdateInfo()
		local item, itemInfo = itemGrid:GetSelectedData()
		if itemInfo and itemInfo.adjustedStack then
			local amount = itemInfo.adjustedStack
			local stackSize = stackSizeSelector:GetPosition()
			local stacks = stackNumberSelector:GetPosition()
			amount = MMin(amount, stackSize * stacks)
			local fullStacks = MFloor(amount / stackSize)
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

	

	itemGrid:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 5, 5)
	itemGrid:SetPoint("BOTTOMRIGHT", postingFrame, "BOTTOMLEFT", 295, -5)
	itemGrid:SetPadding(1, 1, 1, 38)
	itemGrid:SetHeadersVisible(false)
	itemGrid:SetRowHeight(62)
	itemGrid:SetRowMargin(2)
	itemGrid:SetUnselectedRowBackgroundColor(0.2, 0.15, 0.2, 1)
	itemGrid:SetSelectedRowBackgroundColor(0.6, 0.45, 0.6, 1)
	itemGrid:AddColumn("Item", 248, ItemRenderer, "name", nil, { ResetGridFunction = function() itemGrid:ForceUpdate() end })
	local function ItemGridFilter(key, value)
		local rarity = value.rarity or "common"
		rarity = ({ sellable = 1, common = 2, uncommon = 3, rare = 4, epic = 5, relic = 6, trascendant = 7, quest = 8 })[rarity] or 1
		local minRarity = InternalInterface.AccountSettings.Posting.rarityFilter or 1
		if rarity < minRarity then return false end

		local filterText = SUpper(filterTextField:GetText())
		local upperName = SUpper(value.name)
		if not SFind(upperName, filterText) then return false end
		
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
	visibilityIcon:SetTexture(addonID, "Textures/HideIcon.png")
	
	filterTextField:SetPoint("CENTERLEFT", filterTextPanel:GetContent(), "CENTERLEFT", 2, 1)
	filterTextField:SetPoint("CENTERRIGHT", visibilityIcon, "CENTERLEFT", -2, 1)
	filterTextField:SetText("")

	local function ScoreValue(value)
		if not value then return "" end
		return MFloor(value) .. " %"
	end
	
	local function ScoreColor(value)
		local r, g, b = unpack(ScoreColorByScore(value))
		return { r, g, b, 0.1 }
	end	
	
	auctionGrid:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 300, 335)
	auctionGrid:SetPoint("BOTTOMRIGHT", postingFrame, "BOTTOMRIGHT", -5, -5)	
	auctionGrid:SetPadding(1, 1, 1, 38)
	auctionGrid:SetHeadersVisible(true)
	auctionGrid:SetRowHeight(20)
	auctionGrid:SetRowMargin(0)
	auctionGrid:SetUnselectedRowBackgroundColor(0.2, 0.2, 0.2, 0.25)
	auctionGrid:SetSelectedRowBackgroundColor(0.6, 0.6, 0.6, 0.25)
	auctionGrid:AddColumn("", 20, "AuctionCachedRenderer")
	auctionGrid:AddColumn(L["PostingPanel/columnSeller"], 140, "Text", true, "sellerName", { Alignment = "left", Formatter = "none" })
	auctionGrid:AddColumn(L["PostingPanel/columnStack"], 60, "Text", true, "stack", { Alignment = "center", Formatter = "none" })
	auctionGrid:AddColumn(L["PostingPanel/columnBid"], 130, "MoneyRenderer", true, "bidPrice")
	auctionGrid:AddColumn(L["PostingPanel/columnBuy"], 130, "MoneyRenderer", true, "buyoutPrice")
	auctionGrid:AddColumn(L["PostingPanel/columnBidPerUnit"], 130, "MoneyRenderer", true, "bidUnitPrice")
	local defaultOrderColumn = auctionGrid:AddColumn(L["PostingPanel/columnBuyPerUnit"], 130, "MoneyRenderer", true, "buyoutUnitPrice")
	auctionGrid:AddColumn(L["PostingPanel/columnMinExpire"], 90, "Text", true, "minExpireTime", { Alignment = "right", Formatter = RemainingTimeFormatter })
	auctionGrid:AddColumn(L["PostingPanel/columnMaxExpire"], 90, "Text", true, "maxExpireTime", { Alignment = "right", Formatter = RemainingTimeFormatter })
	auctionGrid:AddColumn(L["AuctionsPanel/columnScore"], 60, "Text", true, "score", { Alignment = "right", Formatter = ScoreValue, Color = ScoreColor })
	auctionGrid:AddColumn("", 0, "AuctionRenderer", false, "score", { Color = ScoreColor })
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
	maxLabelWidth = MMax(maxLabelWidth, pricingModelLabel:GetWidth())
	maxLabelWidth = MMax(maxLabelWidth, stackSizeLabel:GetWidth())
	maxLabelWidth = MMax(maxLabelWidth, stackNumberLabel:GetWidth())
	maxLabelWidth = MMax(maxLabelWidth, bidLabel:GetWidth())
	maxLabelWidth = MMax(maxLabelWidth, buyLabel:GetWidth())
	maxLabelWidth = MMax(maxLabelWidth, buyLabel:GetWidth())
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
	durationTimeLabel:SetText(SFormat(L["PostingPanel/labelDurationFormat"], 48))

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
	infoStacksLabel:SetText(L["PostingPanel/InfoStacks"])
	infoStacksLabel:SetFontSize(14)
	infoStacksLabel:SetFontColor(1, 1, 0.75, 1)
	infoStacksLabel:SetShadowOffset(2, 2)	

	totalBidLabel:SetPoint("CENTERLEFT", postingFrame, "TOPRIGHT", -275, 125)
	totalBidLabel:SetText(L["PostingPanel/InfoTotalBid"])
	totalBidLabel:SetFontSize(14)
	totalBidLabel:SetFontColor(1, 1, 0.75, 1)
	totalBidLabel:SetShadowOffset(2, 2)	

	totalBuyLabel:SetPoint("CENTERLEFT", postingFrame, "TOPRIGHT", -275, 155)
	totalBuyLabel:SetText(L["PostingPanel/InfoTotalBuy"])
	totalBuyLabel:SetFontSize(14)
	totalBuyLabel:SetFontColor(1, 1, 0.75, 1)
	totalBuyLabel:SetShadowOffset(2, 2)	
	
	depositLabel:SetPoint("CENTERLEFT", postingFrame, "TOPRIGHT", -275, 185)
	depositLabel:SetText(L["PostingPanel/InfoDeposit"])
	depositLabel:SetFontSize(14)
	depositLabel:SetFontColor(1, 1, 0.75, 1)
	depositLabel:SetShadowOffset(2, 2)	

	discountBidLabel:SetPoint("CENTERLEFT", postingFrame, "TOPRIGHT", -275, 215)
	discountBidLabel:SetText(L["PostingPanel/InfoDiscountBid"])
	discountBidLabel:SetFontSize(14)
	discountBidLabel:SetFontColor(1, 1, 0.75, 1)
	discountBidLabel:SetShadowOffset(2, 2)	

	discountBuyLabel:SetPoint("CENTERLEFT", postingFrame, "TOPRIGHT", -275, 245)
	discountBuyLabel:SetText(L["PostingPanel/InfoDiscountBuy"])
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
		local length = SLen(self:GetText())
		if length > 0 then
			self:SetSelection(0, length)
		end
	end
	
	function filterTextField.Event:TextfieldChange()
		itemGrid:ForceUpdate()
	end
	
	function visibilityIcon.Event:LeftClick()
		visibilityMode = not visibilityMode
		visibilityIcon:SetTexture(addonID, visibilityMode and "Textures/ShowIcon.png" or "Textures/HideIcon.png")
		itemGrid:ForceUpdate()
	end

	function itemGrid.Event:SelectionChanged(item, itemInfo)
		ResetAuctions()
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
	
	function buyButton.Event:LeftPress()
		local auctionID, auctionData = auctionGrid:GetSelectedData()
		if auctionID then
			CABid(auctionID, auctionData.buyoutPrice, function(...) InternalInterface.Scanner.AuctionBuyCallback(auctionID, ...) end)
		end
	end
	
	function bidButton.Event:LeftPress()
		local auctionID = auctionGrid:GetSelectedData()
		if auctionID then
			local bidAmount = auctionMoneySelector:GetValue()
			CABid(auctionID, bidAmount, function(...) InternalInterface.Scanner.AuctionBidCallback(auctionID, bidAmount, ...) end)
		end
	end
	
	function refreshButton.Event:LeftClick()
		if not self.enabled then return end
		
		local item, itemInfo = itemGrid:GetSelectedData()
		if not item then return end
		
		if not pcall(CAScan, { type = "search", index = 0, text = itemInfo.name, rarity = itemInfo.rarity or "common", sort = "time", sortOrder = "descending" }) then
			out(L["PostingPanel/itemScanError"])
		else
			InternalInterface.ScanNext()
			out(L["PostingPanel/itemScanStarted"])
		end				
	end

	function auctionGrid.Event:SelectionChanged(auctionID, auctionData)
		RefreshAuctionButtons()
	end
	
	function itemTexture.Event:MouseIn()
		CTooltip(self.itemType)
	end
	
	function itemTexture.Event:MouseOut()
		CTooltip(nil)
	end

	function pricingModelSelector.Event:SelectionChanged()
		ApplyPricingModel()
	end

	function priceMatchingCheck.Event:CheckboxChange()
		ApplyPricingModel()
	end

	function stackSizeSelector.Event:PositionChanged(stackSize)
		local selectedItem, selectedInfo = itemGrid:GetSelectedData()
		if stackSize > 0 and selectedItem then
			local stacks = selectedInfo.adjustedStack
			local maxNumberOfStacks = MCeil(stacks / stackSize)
			stackNumberSelector:SetRange(1, maxNumberOfStacks)
			stackNumberSelector:SetPosition(maxNumberOfStacks)
		else
			stackNumberSelector:SetRange(0, 0)
		end
		UpdateInfo()
	end

	function stackNumberSelector.Event:PositionChanged(stackNumber)
		UpdateInfo()
	end

	function bindPricesCheck.Event:CheckboxChange()
		if self:GetChecked() then
			pricesSetByModel = true
			local maxPrice = MMax(bidMoneySelector:GetValue(), buyMoneySelector:GetValue())
			bidMoneySelector:SetValue(maxPrice)
			buyMoneySelector:SetValue(maxPrice)
			pricesSetByModel = false
		else
			ApplyPricingModel()
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
					break
				end
			end
		end
		UpdateInfo()
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
					break
				end
			end
		end
		local _, selectedInfo = itemGrid:GetSelectedData()
		buyPriceWarning:SetVisible((selectedInfo and newValue > 0 and newValue < MCeil((selectedInfo.sell or 0) / AUCTION_FEE_REDUCTION)) or false)
		UpdateInfo()
	end

	function durationSlider.Event:SliderChange()
		local position = self:GetPosition()
		durationTimeLabel:SetText(SFormat(L["PostingPanel/labelDurationFormat"], 6 * 2 ^ position))
		UpdateInfo()
	end

	function postButton.Event:LeftPress()
		if self.cooldown and ITReal() < self.cooldown then return end
		
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
		
		local amount = MMin(stackSize * stackNumber, selectedInfo.adjustedStack)
		if amount <= 0 then return end
		
		if autoPostingMode or _G[addonID].PostItem(selectedItem, stackSize, amount, bidUnitPrice, buyUnitPrice, duration) then
			local config = { pricingModelOrder = pricingModelId, usePriceMatching = savePriceMatching, stackSize = stackSize, bindPrices = saveBindPrices, duration = saveDuration, }
			
			if autoPostingMode then
				InternalInterface.CharacterSettings.Posting.AutoConfig[selectedInfo.itemType] = config
			else
				InternalInterface.CharacterSettings.Posting.ItemConfig[selectedInfo.itemType] = config
				self.cooldown = ITReal() + 0.5
			end

			local pricingModelCallback = InternalInterface.Modules.GetPricingModelCallback(pricingModelId)
			if type(pricingModelCallback) == "function" then
				pricingModelCallback(selectedInfo.itemType, bidUnitPrice, buyUnitPrice, autoPostingMode)
			end
		
			itemGrid:ForceUpdate()
		end
	end

	function clearButton.Event:LeftPress()
		local selectedItem, selectedInfo = itemGrid:GetSelectedData()
		if not selectedItem or not selectedInfo then return end

		local pricingModelCallback = InternalInterface.Modules.GetPricingModelCallback(InternalInterface.CharacterSettings.Posting.AutoConfig[selectedInfo.itemType].pricingModelOrder)
		if type(pricingModelCallback) == "function" then
			pricingModelCallback(selectedInfo.itemType, bidUnitPrice, buyUnitPrice, autoPostingMode)
		end
		
		InternalInterface.CharacterSettings.Posting.AutoConfig[selectedInfo.itemType] = nil
		itemGrid:ForceUpdate()
	end

	function autoPostButton.Event:RightClick()
		autoPostingMode = not autoPostingMode
		postButton:SetText(autoPostingMode and L["PostingPanel/buttonAutoPostingSave"] or L["PostingPanel/buttonPost"])
		clearButton:SetVisible(autoPostingMode)
		UpdatePrices()
		local itemID, itemData = itemGrid:GetSelectedData()
		if itemData then
			UpdatePrices(itemID, itemData)
		end
	end

	function autoPostButton.Event:LeftClick()
		local slot = UISInventory()
		local items = IIList(slot)
		
		local itemTypeTable = {}
		for _, itemID in pairs(items) do repeat
			if type(itemID) == "boolean" then break end 
			local ok, itemDetail = pcall(IIDetail, itemID)
			if not ok or not itemDetail or itemDetail.bound then break end
			
			local itemType = itemDetail.type
			itemTypeTable[itemType] = itemTypeTable[itemType] or { name = itemDetail.name, stack = 0 }
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
		
		for itemType, itemData in pairs(itemTypeTable) do
			local pricingModelOrder = itemData.autoPosting.pricingModelOrder
			local usePriceMatching = itemData.autoPosting.usePriceMatching
			
			local function AutoPostingMatchingCallback(bid, buy)
				if bid then
					_G[addonID].PostItem(itemType, itemData.autoPosting.stackSize, itemData.stack, bid, buy > 0 and buy or nil, 6 * 2 ^ itemData.autoPosting.duration)	
				end
			end
			
			local function AutoPostingPricingCallback(prices)
				if not prices or not prices[pricingModelOrder] then
					itemTypeTable[itemType] = nil
					out(SFormat(L["PostingPanel/autoPostingErrorPricingModelNotFound"], itemData.name))
					return
				end

				local unitBid = prices[pricingModelOrder].bid
				local unitBuy = prices[pricingModelOrder].buy or 0
			
				if usePriceMatching then
					_G[addonID].MatchPrice(AutoPostingMatchingCallback, itemType, unitBid, unitBuy)
				else
					AutoPostingMatchingCallback(unitBid, unitBuy)
				end
			end
		
			_G[addonID].GetPricings(AutoPostingPricingCallback, itemType, true)
		end
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



	TInsert(Event.Item.Slot, { ResetItems, addonID, "PostingFrame.OnItemSlot" })
	TInsert(Event.Item.Update, { ResetItems, addonID, "PostingFrame.OnItemUpdate" })
	TInsert(Event[addonID].PostingQueueChanged, { function() if postingFrame:GetVisible() then ResetItems() end end, addonID, "PostingFrame.OnPostingQueueChanged" })	
	TInsert(Event[addonID].AuctionData, { function() if postingFrame:GetVisible() then ResetAuctions() end end, addonID, "PostingFrame.OnAuctionData" })
	TInsert(Event.Interaction, { function(interaction) if postingFrame:GetVisible() and interaction == "auction" then RefreshAuctionButtons() end end, addonID, "PostingFrame.OnInteraction" })

	local function OnQueueStatusChanged()
		local status, size = _G[addonID].GetPostingQueueStatus()
		local paused = _G[addonID].GetPostingQueuePaused()
		
		queueStatus:SetText(SFormat("%s (%d)", L["PostingPanel/labelPostingQueueStatus" .. status], size or 0))
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
	TInsert(Event[addonID].PostingQueueStatusChanged, { OnQueueStatusChanged, addonID, "PostingFrame.OnQueueStatusChanged" })
	
	OnQueueStatusChanged()	
	
	function postingFrame:Show(hEvent)
		ResetItems()
	end
	
	local info = Inspect.Addon.Detail("ImhoBags")
	if(info and info.toc.publicAPI) then
		local function OnImhoBagsRightClick(params)
			if not postingFrame:GetVisible() then return end
			local ok, itemInfo = pcall(IIDetail, params.id)
			if not ok or not itemInfo or itemInfo.bound then return end
			
			local adjustedStack = 0
			local itemGridData = itemGrid:GetData()
			for item, itemData in pairs(itemGridData) do
				if itemData.itemType == itemInfo.type then
					itemGrid.lastSelectedKey = item
					itemGrid:ForceUpdate()
					ResetAuctions()
					params.cancel = true
					break
				end
			end
		end
	
		TInsert(ImhoBags.Event.Item.Standard.Right, { OnImhoBagsRightClick, addonID, "PostingFrame.OnImhoBagsRightClick" })
	end
	
	return postingFrame
end
