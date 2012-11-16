-- ***************************************************************************************************************************************************
-- * PostFrame.lua                                                                                                                                   *
-- ***************************************************************************************************************************************************
-- * Post tab frame                                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.31 / Baanano: Rewritten for 0.4.1                                                                                               *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local AH_FEE_MULTIPLIER = 0.95
local BASE_CATEGORY = InternalInterface.Category.BASE_CATEGORY
local DataGrid = Yague.DataGrid
local Dropdown = Yague.Dropdown
local MoneySelector = Yague.MoneySelector
local Panel = Yague.Panel
local ShadowedText = Yague.ShadowedText
local Slider = Yague.Slider
local CDetail = InternalInterface.Category.Detail
local CTooltip = Command.Tooltip
local GetCategoryConfig = InternalInterface.Helper.GetCategoryConfig
local GetCategoryModels = InternalInterface.PGCConfig.GetCategoryModels
local GetOwnAuctionData = LibPGC.GetOwnAuctionData
local GetPostingQueue = LibPGC.GetPostingQueue
local GetPostingSettings = InternalInterface.Helper.GetPostingSettings
local GetPriceModels = LibPGCEx.GetPriceModels
local GetPrices = LibPGCEx.GetPrices
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local IIDetail = Inspect.Item.Detail
local IIList = Inspect.Item.List
local ITReal = Inspect.Time.Real
local L = InternalInterface.Localization.L
local MCeil = math.ceil
local MFloor = math.floor
local MMax = math.max
local MMin = math.min
local PostItem = LibPGC.PostItem
local SFind = string.find
local SFormat = string.format
local SLen = string.len
local SUpper = string.upper
local TInsert = table.insert
local UICreateFrame = UI.CreateFrame
local UISInventory = Utility.Item.Slot.Inventory
local Write = InternalInterface.Output.Write
local ipairs = ipairs
local next = next
local pairs = pairs
local pcall = pcall
local type = type

local FIXED_MODEL_ID = "fixed"
local FIXED_MODEL_NAME = L["PriceModels/Fixed"]

local function ItemCellType(name, parent)
	local itemCell = UICreateFrame("Mask", name, parent)
	
	local cellBackground = UICreateFrame("Texture", name .. ".CellBackground", itemCell)
	local itemTextureBackground = UICreateFrame("Frame", name .. ".ItemTextureBackground", itemCell)
	local itemTexture = UICreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = ShadowedText(name .. ".ItemNameLabel", itemCell)
	local visibilityIcon = UICreateFrame("Texture", name .. ".VisibilityIcon", itemCell)
	local autoPostingIcon = UICreateFrame("Texture", name .. ".AutoPostingIcon", itemCell)
	local itemStackLabel = UICreateFrame("Text", name .. ".ItemStackLabel", itemCell)
	
	local itemType = nil
	local itemCategory = nil
	local resetGridFunction = nil

	cellBackground:SetAllPoints()
	cellBackground:SetTextureAsync(addonID, "Textures/ItemRowBackground.png")
	cellBackground:SetLayer(-9999)
	
	itemTextureBackground:SetPoint("CENTERLEFT", itemCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	
	itemNameLabel:SetPoint("TOPLEFT", itemCell, "TOPLEFT", 58, 8)
	itemNameLabel:SetFontSize(13)
	
	visibilityIcon:SetPoint("BOTTOMLEFT", itemTextureBackground, "BOTTOMRIGHT", 5, -5)
	visibilityIcon:SetTextureAsync(addonID, "Textures/ShowIcon.png")
	
	autoPostingIcon:SetPoint("BOTTOMLEFT", itemTextureBackground, "BOTTOMRIGHT", 26, -5)
	autoPostingIcon:SetTextureAsync(addonID, "Textures/AutoOff.png")
	
	itemStackLabel:SetPoint("BOTTOMRIGHT", itemCell, "BOTTOMRIGHT", -4, -4)
	
	function itemCell:SetValue(key, value, width, extra)
		itemTextureBackground:SetBackgroundColor(GetRarityColor(value.rarity))
		itemTexture:SetTextureAsync("Rift", value.icon)
		itemNameLabel:SetText(value.name or "")
		itemNameLabel:SetFontColor(GetRarityColor(value.rarity))
		itemStackLabel:SetText("x" .. (value.adjustedStack or 0))
		
		itemType = value.itemType
		itemCategory = value.category
		
		if itemType then
			if InternalInterface.AccountSettings.Posting.HiddenItems[itemType] then
				visibilityIcon:SetTextureAsync(addonID, "Textures/HideIcon.png")
			elseif InternalInterface.CharacterSettings.Posting.HiddenItems[itemType] then
				visibilityIcon:SetTextureAsync(addonID, "Textures/CharacterHideIcon.png")
			else
				visibilityIcon:SetTextureAsync(addonID, "Textures/ShowIcon.png")
			end
			autoPostingIcon:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
		end

		resetGridFunction = extra and extra.ResetGridFunction or nil
	end
	
	function visibilityIcon.Event:LeftClick()
		if itemType then
			if InternalInterface.AccountSettings.Posting.HiddenItems[itemType] then
				InternalInterface.AccountSettings.Posting.HiddenItems[itemType] = nil
			elseif InternalInterface.CharacterSettings.Posting.HiddenItems[itemType] then
				InternalInterface.CharacterSettings.Posting.HiddenItems[itemType] = nil
			else
				InternalInterface.AccountSettings.Posting.HiddenItems[itemType] = true
			end
		end
		itemCell:GetParent().Event.LeftClick(itemCell:GetParent())
		if resetGridFunction then resetGridFunction(itemType) end
	end
	
	function visibilityIcon.Event:RightClick()
		if itemType then
			if InternalInterface.AccountSettings.Posting.HiddenItems[itemType] then
				InternalInterface.AccountSettings.Posting.HiddenItems[itemType] = nil
			elseif InternalInterface.CharacterSettings.Posting.HiddenItems[itemType] then
				InternalInterface.CharacterSettings.Posting.HiddenItems[itemType] = nil
			else
				InternalInterface.CharacterSettings.Posting.HiddenItems[itemType] = true
			end
		end
		itemCell:GetParent().Event.LeftClick(itemCell:GetParent())
		if resetGridFunction then resetGridFunction(itemType) end
	end
	
	function autoPostingIcon.Event:LeftClick()
		if itemType then
			if InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] then
				InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] = nil
			else
				InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] = nil
				local itemSettings = GetPostingSettings(itemType, itemCategory)
				
				InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] =
				{
					pricingModelOrder = itemSettings.referencePrice,
					usePriceMatching = itemSettings.matchPrices,
					bindPrices = itemSettings.bindPrices,
					stackSize = itemSettings.stackSize,
					stackNumber = itemSettings.stackNumber,
					limitActive = itemSettings.stackLimit,
					duration = itemSettings.duration,
				}
				
				InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] = true
			end
		end
		itemCell:GetParent().Event.LeftClick(itemCell:GetParent())
		if resetGridFunction then resetGridFunction(itemType) end
	end
	
	function itemTexture.Event:MouseIn()
		pcall(CTooltip, itemType)
	end
	
	function itemTexture.Event:MouseOut()
		CTooltip(nil)
	end	
	
	return itemCell
end

function InternalInterface.UI.PostFrame(name, parent)
	local postFrame = UICreateFrame("Frame", name, parent)
	
	local itemGrid = DataGrid(name .. ".ItemGrid", postFrame)
	local filterFrame = UICreateFrame("Frame", name .. ".FilterFrame", itemGrid:GetContent())
	local filterTextPanel = Panel(filterFrame:GetName() .. ".FilterTextPanel", filterFrame)
	local visibilityIcon = UICreateFrame("Texture", filterFrame:GetName() .. ".VisibilityIcon", filterTextPanel:GetContent())
	local filterTextField = UICreateFrame("RiftTextfield", filterFrame:GetName() .. ".FilterTextField", filterTextPanel:GetContent())
	
	local itemTexturePanel = Panel(name .. ".ItemTexturePanel", postFrame)
	local itemTexture = UICreateFrame("Texture", name .. ".ItemTexture", itemTexturePanel:GetContent())
	local itemNameLabel = ShadowedText(name .. ".ItemNameLabel", postFrame)
	local itemStackLabel = ShadowedText(name .. ".ItemStackLabel", postFrame)
	
	local stackSizeLabel = ShadowedText(name .. ".StackSizeLabel", postFrame)
	local stackSizeSelector = Slider(name .. ".StackSizeSelector", postFrame)
	local stackNumberLabel = ShadowedText(name .. ".StackNumberLabel", postFrame)
	local stackNumberSelector = Slider(name .. ".StackNumberSelector", postFrame)
	local stackLimitCheck = UICreateFrame("RiftCheckbox", name .. ".StackLimitCheck", postFrame)
	local stackLimitLabel = ShadowedText(name .. ".StackLimitLabel", postFrame)
	local durationLabel = ShadowedText(name .. ".DurationLabel", postFrame)
	local durationSlider = UICreateFrame("RiftSlider", name .. ".DurationSlider", postFrame)
	local durationTimeLabel = ShadowedText(name .. ".DurationTimeLabel", postFrame)
	local pricingModelLabel = ShadowedText(name .. ".PricingModelLabel", postFrame)
	local pricingModelSelector = Dropdown(name .. ".PricingModelSelector", postFrame)
	local priceMatchingCheck = UICreateFrame("RiftCheckbox", name .. ".PriceMatchingCheck", postFrame)
	local priceMatchingLabel = ShadowedText(name .. ".PriceMatchingLabel", postFrame)
	local bidLabel = ShadowedText(name .. ".BidLabel", postFrame)
	local bidMoneySelector = MoneySelector(name .. ".BidMoneySelector", postFrame)
	local buyLabel = ShadowedText(name .. ".BuyLabel", postFrame)
	local buyMoneySelector = MoneySelector(name .. ".BuyMoneySelector", postFrame)
	local bindPricesCheck = UICreateFrame("RiftCheckbox", name .. ".BindPricesCheck", postFrame)
	local bindPricesLabel = ShadowedText(name .. ".BindPricesLabel", postFrame)
	
	local resetButton = UICreateFrame("RiftButton", name .. ".ResetButton", postFrame)
	local postButton = UICreateFrame("RiftButton", name .. ".PostButton", postFrame)
	local autoPostButton = UICreateFrame("Texture", name .. ".AutoPostButton", postFrame)
	
	local auctionsGrid = InternalInterface.UI.ItemAuctionsGrid(name .. ".ItemAuctionsGrid", postFrame)
	
	local frameActive = false
	local resetNeeded = false
	local visibilityMode = false
	local currentItemType = nil
	local currentAdjustedStack = nil
	local pricesSetByModel = false

	local function ItemGridFilter(itemType, itemInfo)
		local rarity = itemInfo.rarity and itemInfo.rarity ~= "" and itemInfo.rarity or "common"
		rarity = ({ sellable = 1, common = 2, uncommon = 3, rare = 4, epic = 5, relic = 6, trascendant = 7, quest = 8 })[rarity] or 1
		local minRarity = InternalInterface.AccountSettings.Posting.RarityFilter or 1
		if rarity < minRarity then return false end

		local filterText = SUpper(filterTextField:GetText())
		local upperName = SUpper(itemInfo.name)
		if not SFind(upperName, filterText) then return false end
		
		if not visibilityMode then
			if InternalInterface.AccountSettings.Posting.HiddenItems[itemType] or InternalInterface.CharacterSettings.Posting.HiddenItems[itemType] then
				return false
			end
		end

		local auctionAmount = 0
		local postingQueue = GetPostingQueue()
		for index, post in ipairs(postingQueue) do
			if post.itemType == itemType then
				auctionAmount = auctionAmount + post.amount
			end
		end
		itemInfo.adjustedStack = itemInfo.stack - auctionAmount
		if itemInfo.adjustedStack <= 0 then return false end
		
		return true
	end
	
	local function RefreshFilter()
		if not frameActive then return end
		itemGrid:RefreshFilter()
	end

	local function ResetItems()
		if not frameActive then return end
		
		local slot = UISInventory()
		local items = IIList(slot)
		
		local itemTypeTable = {}
		for _, itemID in pairs(items) do repeat
			if type(itemID) == "boolean" then break end 
			local ok, itemDetail = pcall(IIDetail, itemID)
			if not ok or not itemDetail or itemDetail.bound then break end
			
			local itemType = itemDetail.type
			itemTypeTable[itemType] = itemTypeTable[itemType] or { name = itemDetail.name, icon = itemDetail.icon, rarity = itemDetail.rarity, stack = 0, stackMax = itemDetail.stackMax or 1, sell = itemDetail.sell, itemType = itemType, category = itemDetail.category, }
			itemTypeTable[itemType].stack = itemTypeTable[itemType].stack + (itemDetail.stack or 1)
		until true end
		
		itemGrid:SetData(itemTypeTable, nil, RefreshFilter, true)
	end
	
	local function RefreshPostArea(itemType, itemInfo)
		currentItemType = nil
		currentAdjustedStack = nil
	
		itemTexturePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
		itemTexture:SetVisible(false)
		itemNameLabel:SetVisible(false)
		itemStackLabel:SetVisible(false)
		
		pricingModelSelector:SetValues({})
		pricingModelSelector:SetEnabled(false)
		priceMatchingCheck:SetEnabled(false)
		priceMatchingCheck:SetChecked(false)
		stackSizeSelector:SetRange(0, 0)
		stackSizeSelector:ResetPseudoValues()
		stackNumberSelector:SetRange(0, 0)
		stackNumberSelector:ResetPseudoValues()
		stackLimitCheck:SetEnabled(false)
		stackLimitCheck:SetChecked(false)
		bidMoneySelector:SetEnabled(false)
		buyMoneySelector:SetEnabled(false)
		bindPricesCheck:SetEnabled(false)
		bindPricesCheck:SetChecked(false)
		durationSlider:SetEnabled(false)

		resetButton:SetEnabled(false)
		postButton:SetEnabled(false)
		
		local function PopulatePostArea(itemType, itemInfo, itemSettings, prices)
			itemTexturePanel:GetContent():SetBackgroundColor(GetRarityColor(itemInfo.rarity))
			itemTexture:SetVisible(true)
			itemTexture:SetTextureAsync("Rift", itemInfo.icon)
			itemNameLabel:SetText(itemInfo.name)
			itemNameLabel:SetFontColor(GetRarityColor(itemInfo.rarity))
			itemNameLabel:SetVisible(true)
			itemStackLabel:SetText(SFormat(L["PostFrame/LabelItemStack"], itemInfo.adjustedStack))
			itemStackLabel:SetVisible(true)
			
			local priceModels = GetPriceModels()
			for priceID, priceData in pairs(prices) do
				local priceModelName = priceModels[priceID]
				if priceModelName then
					prices[priceID].displayName = priceModelName
				else
					prices[priceID] = nil
				end
			end
			prices[FIXED_MODEL_ID] = { displayName = FIXED_MODEL_NAME, bid = itemSettings.lastBid or 0, buy = itemSettings.lastBuy or 0 }

			local preferredPrice = itemSettings.referencePrice
			if not preferredPrice or not prices[preferredPrice] then
				if InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] then
					Write(L["PostFrame/ErrorAutoPostModelMissing"])
					InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] = nil
					RefreshFilter()
				end
				preferredPrice = prices[itemSettings.fallbackPrice] and itemSettings.fallbackPrice or nil
			end
			
			pricingModelSelector:SetValues(prices)
			pricingModelSelector:SetEnabled(true)
			if preferredPrice then
				pricingModelSelector:SetSelectedKey(preferredPrice)
			end
			
			priceMatchingCheck:SetEnabled(true)
			priceMatchingCheck:SetChecked(itemSettings.matchPrices)
			
			local preferredStackSize = itemSettings.stackSize
			stackSizeSelector:SetRange(1, itemInfo.stackMax)
			stackSizeSelector:AddPostValue(L["Misc/StackSizeMaxKeyShortcut"], "+", L["Misc/StackSizeMax"])
			if type(preferredStackSize) == "number" then
				preferredStackSize = MMin(preferredStackSize, itemInfo.stackMax)
			end
			stackSizeSelector:SetPosition(preferredStackSize)
			
			local preferredStackNumber = itemSettings.stackNumber
			if type(preferredStackNumber) == "number" then
				local _, maxRange = stackNumberSelector:GetRange()
				preferredStackNumber = MMin(preferredStackNumber, maxRange)
			end
			stackNumberSelector:SetPosition(preferredStackNumber)
			
			stackLimitCheck:SetEnabled(true)
			stackLimitCheck:SetChecked(itemSettings.stackLimit)

			bidMoneySelector:SetEnabled(true)
			buyMoneySelector:SetEnabled(true)
			
			bindPricesCheck:SetEnabled(true)
			bindPricesCheck:SetChecked(itemSettings.bindPrices)
			
			durationSlider:SetEnabled(true)
			durationSlider:SetPosition(itemSettings.duration)
			
			resetButton:SetEnabled(true)
			postButton:SetEnabled(true)
			autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
			
			currentItemType = itemType
			currentAdjustedStack = itemInfo.adjustedStack
		end
		
		if itemType and itemInfo then
			local category = itemInfo.category
			local itemSettings = GetPostingSettings(itemType, category)
		
			local models = GetCategoryModels(category)
			local blackList = itemSettings.blackList or {}
			for modelID in pairs(blackList) do
				models[modelID] = nil
			end
			
			GetPrices(function(prices) PopulatePostArea(itemType, itemInfo, itemSettings, prices) end, itemType, itemSettings.bidPercentage, models, false)
		else
			autoPostButton:SetTextureAsync(addonID, "Textures/AutoOff.png")
		end
	end
	
	local function ApplyPricingModel()
		local priceID, priceData = pricingModelSelector:GetSelectedValue()
		local match = priceMatchingCheck:GetChecked()
		
		pricesSetByModel = true
		if priceID and priceData then
			local bid = match and priceData.adjustedBid or priceData.bid
			local buy = match and priceData.adjustedBuy or priceData.buy
			bidMoneySelector:SetValue(bid)
			buyMoneySelector:SetValue(buy)
		else
			bidMoneySelector:SetValue(0)
			buyMoneySelector:SetValue(0)
		end
		pricesSetByModel = false
	end
	
	local function ResetItemGridFunction(itemType)
		RefreshFilter()
		if InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] then
			RefreshPostArea(itemGrid:GetSelectedData())
		else
			autoPostButton:SetTextureAsync(addonID, "Textures/AutoOff.png")
		end
	end
	
	local function CollectPostingSettings()
		local settings =
		{
			pricingModelOrder = (pricingModelSelector:GetSelectedValue()),
			usePriceMatching = priceMatchingCheck:GetChecked(),
			lastBid = bidMoneySelector:GetValue(),
			lastBuy = buyMoneySelector:GetValue(),
			bindPrices = bindPricesCheck:GetChecked(),
			stackSize = stackSizeSelector:GetPosition(),
			stackNumber = stackNumberSelector:GetPosition(),
			limitActive = stackLimitCheck:GetChecked(),
			duration = durationSlider:GetPosition(),
		}
		return settings
	end

	local function ColorSelector(value)
		local _, selectedInfo = itemGrid:GetSelectedData()
		if selectedInfo and selectedInfo.sell and value > 0 and value < MCeil(selectedInfo.sell / AH_FEE_MULTIPLIER) then
			return { 1, 0, 0, }
		else
			return { 0, 0, 0, }
		end
	end
	
	do -- LAYOUT --
	itemGrid:SetPoint("TOPLEFT", postFrame, "TOPLEFT", 5, 5)
	itemGrid:SetPoint("BOTTOMRIGHT", postFrame, "BOTTOMLEFT", 295, -5)
	itemGrid:SetPadding(1, 1, 1, 38)
	itemGrid:SetHeadersVisible(false)
	itemGrid:SetRowHeight(62)
	itemGrid:SetRowMargin(2)
	itemGrid:SetUnselectedRowBackgroundColor({0.2, 0.15, 0.2, 1})
	itemGrid:SetSelectedRowBackgroundColor({0.6, 0.45, 0.6, 1})
	itemGrid:AddColumn("item", nil, ItemCellType, 248, 0, nil, "name", { ResetGridFunction = ResetItemGridFunction })
	itemGrid:SetFilter(ItemGridFilter)
	itemGrid:GetInternalContent():SetBackgroundColor(0, 0.05, 0, 0.5)	

	filterFrame:SetPoint("TOPLEFT", itemGrid:GetContent(), "BOTTOMLEFT", 3, -36)
	filterFrame:SetPoint("BOTTOMRIGHT", itemGrid:GetContent(), "BOTTOMRIGHT", -3, -2)
	
	filterTextPanel:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 0, 2)
	filterTextPanel:SetPoint("BOTTOMRIGHT", filterFrame, "BOTTOMRIGHT", 0, -2)
	filterTextPanel:SetInvertedBorder(true)
	filterTextPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	visibilityIcon:SetPoint("CENTERRIGHT", filterTextPanel:GetContent(), "CENTERRIGHT", -5, 0)
	visibilityIcon:SetTextureAsync(addonID, "Textures/HideIcon.png")
	
	filterTextField:SetPoint("CENTERLEFT", filterTextPanel:GetContent(), "CENTERLEFT", 2, 1)
	filterTextField:SetPoint("CENTERRIGHT", filterTextPanel:GetContent(), "CENTERRIGHT", -23, 1)
	filterTextField:SetText("")
	
	itemTexturePanel:SetPoint("TOPLEFT", postFrame, "TOPLEFT", 300, 5)
	itemTexturePanel:SetPoint("BOTTOMRIGHT", postFrame, "TOPLEFT", 370, 75)
	itemTexturePanel:SetInvertedBorder(true)
	itemTexturePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)

	itemTexture:SetPoint("TOPLEFT", itemTexturePanel:GetContent(), "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTexturePanel:GetContent(), "BOTTOMRIGHT", -1.5, -1.5)
	itemTexture:SetVisible(false)
	
	itemNameLabel:SetPoint("BOTTOMLEFT", itemTexturePanel, "CENTERRIGHT", 5, 5)
	itemNameLabel:SetFontSize(20)

	itemStackLabel:SetPoint("BOTTOMLEFT", itemTexturePanel, "BOTTOMRIGHT", 5, -1)
	itemStackLabel:SetFontSize(15)
	
	stackSizeLabel:SetPoint("TOPLEFT", postFrame, "TOPLEFT", 315, 105)
	stackSizeLabel:SetText(L["PostFrame/LabelStackSize"])
	stackSizeLabel:SetFontSize(14)
	stackSizeLabel:SetFontColor(1, 1, 0.75, 1)
	stackSizeLabel:SetShadowOffset(2, 2)
	
	stackNumberLabel:SetPoint("TOPLEFT", postFrame, "TOPLEFT", 315, 145)
	stackNumberLabel:SetText(L["PostFrame/LabelStackNumber"])
	stackNumberLabel:SetFontSize(14)
	stackNumberLabel:SetFontColor(1, 1, 0.75, 1)
	stackNumberLabel:SetShadowOffset(2, 2)

	durationLabel:SetPoint("TOPLEFT", postFrame, "TOPLEFT", 315, 225)
	durationLabel:SetText(L["PostFrame/LabelDuration"])
	durationLabel:SetFontSize(14)
	durationLabel:SetFontColor(1, 1, 0.75, 1)
	durationLabel:SetShadowOffset(2, 2)
	
	pricingModelLabel:SetPoint("TOPLEFT", postFrame, "TOPRIGHT", -450, 20)
	pricingModelLabel:SetText(L["PostFrame/LabelPricingModel"])
	pricingModelLabel:SetFontSize(14)
	pricingModelLabel:SetFontColor(1, 1, 0.75, 1)
	pricingModelLabel:SetShadowOffset(2, 2)
	
	bidLabel:SetPoint("TOPLEFT", postFrame, "TOPRIGHT", -450, 105)
	bidLabel:SetText(L["PostFrame/LabelUnitBid"])
	bidLabel:SetFontSize(14)
	bidLabel:SetFontColor(1, 1, 0.75, 1)
	bidLabel:SetShadowOffset(2, 2)
	
	buyLabel:SetPoint("TOPLEFT", postFrame, "TOPRIGHT", -450, 145)
	buyLabel:SetText(L["PostFrame/LabelUnitBuy"])
	buyLabel:SetFontSize(14)
	buyLabel:SetFontColor(1, 1, 0.75, 1)
	buyLabel:SetShadowOffset(2, 2)

	local maxLeftLabelWidth = 100
	maxLeftLabelWidth = MMax(maxLeftLabelWidth, stackSizeLabel:GetWidth())
	maxLeftLabelWidth = MMax(maxLeftLabelWidth, bidLabel:GetWidth())
	maxLeftLabelWidth = MMax(maxLeftLabelWidth, buyLabel:GetWidth())
	maxLeftLabelWidth = maxLeftLabelWidth + 20
	
	stackSizeSelector:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT", -490, 106)
	stackSizeSelector:SetPoint("CENTERLEFT", stackSizeLabel, "CENTERLEFT", maxLeftLabelWidth, 4)
	
	stackNumberSelector:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT", -490, 146)
	stackNumberSelector:SetPoint("CENTERLEFT", stackNumberLabel, "CENTERLEFT", maxLeftLabelWidth, 4)
		
	stackLimitCheck:SetPoint("TOPRIGHT", stackNumberSelector, "BOTTOMRIGHT", 0, 5)
	stackLimitCheck:SetChecked(false)
	stackLimitCheck:SetEnabled(false)
	
	stackLimitLabel:SetPoint("CENTERRIGHT", stackLimitCheck, "CENTERLEFT", -5, 0)	
	stackLimitLabel:SetFontSize(13)
	stackLimitLabel:SetText(L["PostFrame/CheckStackLimit"])

	durationTimeLabel:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT", -490, 225)
	durationTimeLabel:SetText(SFormat(L["Misc/DurationFormat"], 48))

	durationSlider:SetPoint("CENTERRIGHT", durationTimeLabel, "CENTERLEFT", -15, 5)
	durationSlider:SetPoint("CENTERLEFT", durationLabel, "CENTERLEFT", maxLeftLabelWidth + 10, 5)
	durationSlider:SetRange(1, 3)
	durationSlider:SetPosition(3)
	durationSlider:SetEnabled(false)

	local maxRightLabelWidth = 100
	maxRightLabelWidth = MMax(maxRightLabelWidth, pricingModelLabel:GetWidth())
	maxRightLabelWidth = MMax(maxRightLabelWidth, stackNumberLabel:GetWidth())
	maxRightLabelWidth = MMax(maxRightLabelWidth, durationLabel:GetWidth())
	maxRightLabelWidth = maxRightLabelWidth + 20

	pricingModelSelector:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT", -5, 15)
	pricingModelSelector:SetPoint("CENTERLEFT", pricingModelLabel, "CENTERLEFT", maxRightLabelWidth, 0)
	pricingModelSelector:SetOrderSelector("displayName")
	pricingModelSelector:SetTextSelector("displayName")
	
	priceMatchingCheck:SetPoint("TOPRIGHT", pricingModelSelector, "BOTTOMRIGHT", 0, 10)
	priceMatchingCheck:SetChecked(false)
	priceMatchingCheck:SetEnabled(false)
	
	priceMatchingLabel:SetPoint("CENTERRIGHT", priceMatchingCheck, "CENTERLEFT", -5, 0)	
	priceMatchingLabel:SetFontSize(13)
	priceMatchingLabel:SetText(L["PostFrame/CheckPriceMatching"])

	bidMoneySelector:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT", -5, 101)
	bidMoneySelector:SetPoint("CENTERLEFT", bidLabel, "CENTERLEFT", maxRightLabelWidth, 0)
	bidMoneySelector:SetEnabled(false)
	bidMoneySelector:SetColorSelector(ColorSelector)
	
	buyMoneySelector:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT", -5, 141)
	buyMoneySelector:SetPoint("CENTERLEFT", buyLabel, "CENTERLEFT", maxRightLabelWidth, 0)
	buyMoneySelector:SetEnabled(false)
	buyMoneySelector:SetColorSelector(ColorSelector)

	bindPricesCheck:SetPoint("TOPRIGHT", buyMoneySelector, "BOTTOMRIGHT", 0, 10)
	bindPricesCheck:SetChecked(false)
	bindPricesCheck:SetEnabled(false)
	
	bindPricesLabel:SetPoint("CENTERRIGHT", bindPricesCheck, "CENTERLEFT", -5, 0)
	bindPricesLabel:SetFontSize(13)
	bindPricesLabel:SetText(L["PostFrame/CheckBindPrices"])
	
	resetButton:SetPoint("CENTERRIGHT", postButton, "CENTERLEFT", 0, 0)
	resetButton:SetText(L["PostFrame/ButtonReset"])
	resetButton:SetEnabled(false)
	
	postButton:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT", -31, 225)
	postButton:SetText(L["PostFrame/ButtonPost"])
	postButton:SetEnabled(false)
	
	autoPostButton:SetPoint("CENTERLEFT", postButton, "CENTERRIGHT", 5, 0)
	autoPostButton:SetTextureAsync(addonID, "Textures/AutoOff.png")
	
	auctionsGrid:SetPoint("TOPLEFT", postFrame, "TOPLEFT", 300, 260)
	auctionsGrid:SetPoint("BOTTOMRIGHT", postFrame, "BOTTOMRIGHT", -5, -5)
	end
	
	function itemGrid.Event:SelectionChanged(itemType, itemData)
		if itemType ~= currentItemType then
			auctionsGrid:SetItemType(itemType)
		end
		if itemType ~= currentItemType or (itemData and itemData.adjustedStack or nil) ~= currentAdjustedStack then
			RefreshPostArea(itemType, itemData)
		end
	end
	
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
		RefreshFilter()
	end	
	
	function visibilityIcon.Event:LeftClick()
		visibilityMode = not visibilityMode
		visibilityIcon:SetTextureAsync(addonID, visibilityMode and "Textures/ShowIcon.png" or "Textures/HideIcon.png")
		RefreshFilter()
	end
	
	function itemTexture.Event:MouseIn()
		pcall(CTooltip, currentItemType)
	end
	
	function itemTexture.Event:MouseOut()
		CTooltip(nil)
	end
	
	function pricingModelSelector.Event:SelectionChanged()
		ApplyPricingModel()
		if currentItemType and InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] then
			InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] = nil
			autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
			RefreshFilter()
		end
	end

	function priceMatchingCheck.Event:CheckboxChange()
		ApplyPricingModel()
		if currentItemType and InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] then
			InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] = nil
			autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
			RefreshFilter()
		end
	end

	function stackSizeSelector.Event:PositionChanged(position)
		local selectedItem, selectedInfo = itemGrid:GetSelectedData()
		
		if selectedItem then
			local _, maxValue = self:GetRange()
			local stackSize = position == "+" and maxValue or position
			if type(stackSize) ~= "number" then stackSize = 0 end

			local stackNumber = stackNumberSelector:GetPosition()
			local amount = self.lastStackSize and type(stackNumber) == "number" and self.lastStackSize * stackNumber or stackNumber
			
			if stackSize > 0 then
				self.lastStackSize = stackSize

				local stacks = selectedInfo.adjustedStack
				local fullStacks = MFloor(stacks / stackSize)
				local allStacks = MCeil(stacks / stackSize)
				if amount == "F" and fullStacks <= 0 then amount = 1 end
				
				stackNumberSelector:SetRange(1, MMax(fullStacks, 1))
				stackNumberSelector:ResetPseudoValues()
				
				if fullStacks > 0 then
					stackNumberSelector:AddPostValue(L["Misc/StacksFullKeyShortcut"], "F", L["Misc/StacksFull"])
				end
				stackNumberSelector:AddPostValue(L["Misc/StacksAllKeyShortcut"], "A", L["Misc/StacksAll"])
				
				if type(amount) == "number" then
					amount = MMin(MFloor(amount / stackSize), MMax(fullStacks, 1))
				end
				stackNumberSelector:SetPosition(amount)
			else
				stackNumberSelector:SetRange(0, 0)
				stackNumberSelector:ResetPseudoValues()			
			end
			
			if currentItemType and InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] then
				InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] = nil
				autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
				RefreshFilter()
			end			
		end
	end
	
	function stackNumberSelector.Event:PositionChanged(stackNumber)
		if currentItemType and InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] then
			InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] = nil
			autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
			RefreshFilter()
		end	
	end
	
	function stackLimitCheck.Event:CheckboxChange()
		if currentItemType and InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] then
			InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] = nil
			autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
			RefreshFilter()
		end
	end
	
	function bidMoneySelector.Event:ValueChanged(newValue)
		if not self:GetEnabled() then return end

		local bid, buy = newValue, buyMoneySelector:GetValue()

		if (bindPricesCheck:GetChecked() or bid > buy) and bid ~= buy then
			buyMoneySelector:SetValue(bid)
			buy = bid
		end

		if not pricesSetByModel then
			local prices = pricingModelSelector:GetValues()
			prices[FIXED_MODEL_ID].bid = bid
			prices[FIXED_MODEL_ID].buy = buy
			pricingModelSelector:SetSelectedKey(FIXED_MODEL_ID)
			if currentItemType and InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] then
				InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] = nil
				autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
				RefreshFilter()
			end
		end
	end
	
	function buyMoneySelector.Event:ValueChanged(newValue)
		if not self:GetEnabled() then return end
		
		local bid, buy = bidMoneySelector:GetValue(), newValue
		
		if bindPricesCheck:GetChecked() and bid ~= buy then
			bidMoneySelector:SetValue(buy)
			bid = buy
		end
		
		if not pricesSetByModel then
			local prices = pricingModelSelector:GetValues()
			prices[FIXED_MODEL_ID].bid = bid
			prices[FIXED_MODEL_ID].buy = buy
			pricingModelSelector:SetSelectedKey(FIXED_MODEL_ID)
			if currentItemType and InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] then
				InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] = nil
				autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
				RefreshFilter()
			end
		end
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
		if currentItemType and InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] then
			InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] = nil
			autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
			RefreshFilter()
		end	
	end	

	function durationSlider.Event:WheelForward()
		if self:GetEnabled() then
			self:SetPosition(MMin(self:GetPosition() + 1, 3))
		end
	end

	function durationSlider.Event:WheelBack()
		if self:GetEnabled() then
			self:SetPosition(MMax(self:GetPosition() - 1, 1))
		end
	end
	
	function durationSlider.Event:SliderChange()
		local position = self:GetPosition()
		durationTimeLabel:SetText(SFormat(L["Misc/DurationFormat"], 6 * 2 ^ position))
		if currentItemType and InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] then
			InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] = nil
			autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
			RefreshFilter()
		end	
	end
	
	function resetButton.Event:LeftPress()
		InternalInterface.CharacterSettings.Posting.AutoConfig[currentItemType] = nil
		InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] = nil
		RefreshFilter()
		RefreshPostArea(itemGrid:GetSelectedData())
	end
	
	function postButton.Event:LeftPress()
		if self.waitUntil and ITReal() < self.waitUntil then return end
		
		local selectedItem, selectedInfo = itemGrid:GetSelectedData()
		if not selectedItem or not selectedInfo then return end

		local settings = CollectPostingSettings()
		
		local stackSize = settings.stackSize
		local stackNumber = settings.stackNumber
		local bidUnitPrice = settings.lastBid
		local buyUnitPrice = settings.lastBuy
		local duration = 6 * 2 ^ settings.duration

		stackSize = stackSize == "+" and selectedInfo.stackMax or stackSize
		if type(stackSize) ~= "number" then stackSize = 0 end
		
		if stackSize > 0 and selectedInfo.adjustedStack then
			local stacks = selectedInfo.adjustedStack
			local fullStacks = MFloor(stacks / stackSize)
			local allStacks = MCeil(stacks / stackSize)
			
			if stackNumber == "F" then
				stackNumber = fullStacks
			elseif stackNumber == "A" then
				stackNumber = allStacks
			elseif type(stackNumber) ~= "number" then
				stackNumber = 0
			elseif settings.limitActive then
				local auctions = auctionsGrid:GetData() or {}
				for auctionID, auctionData in pairs(auctions) do
					if auctionData.own then
						stackNumber = stackNumber - 1
					end
				end
				
				local queue = GetPostingQueue()
				for _, queueInfo in ipairs(queue) do
					if queueInfo.itemType == selectedItem then
						stackNumber = stackNumber - MCeil(queueInfo.amount / queueInfo.stackSize)
					end
				end
			end
			
			stackNumber = MMax(MMin(stackNumber, allStacks), 0)
		else
			stackNumber = 0
		end

		buyUnitPrice = buyUnitPrice > 0 and buyUnitPrice or nil
		local amount = MMin(stackSize * stackNumber, selectedInfo.adjustedStack)
		
		if stackSize <= 0 then
			Write(SFormat(L["PostFrame/ErrorPostBase"], L["PostFrame/ErrorPostStackSize"]))
			return
		elseif stackNumber <= 0 or amount <= 0 then
			Write(SFormat(L["PostFrame/ErrorPostBase"], L["PostFrame/ErrorPostStackNumber"]))
			return
		elseif bidUnitPrice <= 0 then
			Write(SFormat(L["PostFrame/ErrorPostBase"], L["PostFrame/ErrorPostBidPrice"]))
			return
		elseif buyUnitPrice and buyUnitPrice < bidUnitPrice then
			Write(SFormat(L["PostFrame/ErrorPostBase"], L["PostFrame/ErrorPostBuyPrice"]))
			return
		end
		
		if PostItem(selectedItem, stackSize, amount, bidUnitPrice, buyUnitPrice, duration) then
			InternalInterface.CharacterSettings.Posting.ItemConfig[selectedItem] = settings
			self.waitUntil = ITReal() + 0.5
		end
	end
	
	function autoPostButton.Event.LeftClick()
		local itemType = itemGrid:GetSelectedData()
		if not itemType then return end
		local settings = CollectPostingSettings()
		
		if settings.lastBuy and settings.lastBuy < settings.lastBid then
			Write(SFormat(L["PostFrame/ErrorPostBase"], L["PostFrame/ErrorPostBuyPrice"]))
			return
		end
		
		InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] = settings
		InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] = not InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] or nil
		RefreshFilter()
		autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
	end
	
	function auctionsGrid.Event:RowRightClick(auctionID, auctionData)
		if auctionData then
			if auctionData.own then
				bidMoneySelector:SetValue(auctionData.bidUnitPrice or 0)
				if auctionData.buyoutUnitPrice or not bindPricesCheck:GetChecked() then
					buyMoneySelector:SetValue(auctionData.buyoutUnitPrice or 0)
				end
			else
				local absoluteUndercut = InternalInterface.AccountSettings.Posting.AbsoluteUndercut
				local relativeUndercut = 1 - InternalInterface.AccountSettings.Posting.RelativeUndercut / 100
				
				bidMoneySelector:SetValue(MMax((auctionData.bidUnitPrice or 0) * relativeUndercut - absoluteUndercut, 1))
				if auctionData.buyoutUnitPrice or not bindPricesCheck:GetChecked() then
					buyMoneySelector:SetValue(MMax((auctionData.buyoutUnitPrice or 0) * relativeUndercut - absoluteUndercut, auctionData.buyoutUnitPrice and 1 or 0))
				end
			end
		end
	end
	
	function postFrame:Show()
		frameActive = true
		auctionsGrid:SetEnabled(true)
		resetNeeded = true
	end
	
	function postFrame:Hide()
		frameActive = false
		auctionsGrid:SetEnabled(false)
	end
	
	function postFrame:ItemRightClick(params)
		if params and params.id then
			local ok, itemDetail = pcall(IIDetail, params.id)
			if not ok or not itemDetail or not itemDetail.type then return false end
			local filteredData = itemGrid:GetFilteredData()
			if filteredData[itemDetail.type] then
				itemGrid:SetSelectedKey(itemDetail.type)
				return true
			end
		end
		return false
	end	
	
	TInsert(Event.Item.Slot, { function() resetNeeded = true end, addonID, addonID .. ".PostFrame.OnItemSlot" })
	TInsert(Event.Item.Update, { function() resetNeeded = true end, addonID, addonID .. ".PostFrame.OnItemUpdate" })

	local function OnPostingQueueChanged()
		RefreshFilter()
		local selectedItem, selectedInfo = itemGrid:GetSelectedData()
		if selectedItem and selectedInfo then
			if currentItemType ~= selectedItem or currentAdjustedStack ~= selectedInfo.adjustedStack then
				RefreshPostArea(selectedItem, selectedInfo)
			end
		else
			RefreshPostArea(nil, nil)
		end
	end
	TInsert(Event.LibPGC.PostingQueueChanged, { OnPostingQueueChanged, addonID, addonID .. ".PostFrame.OnPostingQueueChanged" })	
	
	local function OnFrame()
		if resetNeeded then
			ResetItems()
			resetNeeded = false
		end
	end
	TInsert(Event.System.Update.Begin, { OnFrame, addonID, addonID .. ".PostFrame.OnFrame" })
	
	return postFrame
end
