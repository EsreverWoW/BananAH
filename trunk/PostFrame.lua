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

local DataGrid = Yague.DataGrid
local Dropdown = Yague.Dropdown
local MoneySelector = Yague.MoneySelector
local Panel = Yague.Panel
local ShadowedText = Yague.ShadowedText
local Slider = Yague.Slider
local CTooltip = Command.Tooltip
local GetOwnAuctionData = LibPGC.GetOwnAuctionData
local GetPostingQueue = LibPGC.GetPostingQueue
local GetPriceModels = LibPGCEx.GetPriceModels
local GetPrices = LibPGCEx.GetPrices
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local IIDetail = Inspect.Item.Detail
local IIList = Inspect.Item.List
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
	local resetGridFunction = nil

	cellBackground:SetAllPoints()
	cellBackground:SetTextureAsync(addonID, "Textures/ItemRowBackground.png") -- TODO Move to BDataGrid
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
				InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] = true
			end
		end
		itemCell:GetParent().Event.LeftClick(itemCell:GetParent())
		if resetGridFunction then resetGridFunction(itemType) end
	end
	
	function itemTexture.Event:MouseIn()
		CTooltip(itemType)
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
	local pricesSetByModel = false

	local function ItemGridFilter(itemType, itemInfo)
		local rarity = itemInfo.rarity or "common"
		rarity = ({ sellable = 1, common = 2, uncommon = 3, rare = 4, epic = 5, relic = 6, trascendant = 7, quest = 8 })[rarity] or 1
		local minRarity = InternalInterface.AccountSettings.Posting.rarityFilter or 1 -- FIXME
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
		local postingQueue = LibPGC.GetPostingQueue()
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
			itemTypeTable[itemType] = itemTypeTable[itemType] or { name = itemDetail.name, icon = itemDetail.icon, rarity = itemDetail.rarity, stack = 0, stackMax = itemDetail.stackMax, sell = itemDetail.sell, itemType = itemType }
			itemTypeTable[itemType].stack = itemTypeTable[itemType].stack + (itemDetail.stack or 1)
		until true end
		
		itemGrid:SetData(itemTypeTable, nil, RefreshFilter)
	end
	
	local function RefreshPostArea(itemType, itemInfo)
		currentItemType = nil
	
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
		
		local function PopulatePostArea(itemType, itemInfo, prices)
			currentItemType = itemType
			
			itemTexturePanel:GetContent():SetBackgroundColor(GetRarityColor(itemInfo.rarity))
			itemTexture:SetVisible(true)
			itemTexture:SetTextureAsync("Rift", itemInfo.icon)
			itemNameLabel:SetText(itemInfo.name)
			itemNameLabel:SetFontColor(GetRarityColor(itemInfo.rarity))
			itemNameLabel:SetVisible(true)
			itemStackLabel:SetText(SFormat(L["PostFrame/LabelItemStack"], itemInfo.adjustedStack))
			itemStackLabel:SetVisible(true)
			
			local itemConfig = currentItemType and InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] or {}
			
			local priceModels = GetPriceModels()
			for priceID, priceData in pairs(prices) do
				local priceModelName = priceModels[priceID]
				if priceModelName then
					prices[priceID].displayName = priceModelName
				else
					prices[priceID] = nil
				end
			end
			
			prices[FIXED_MODEL_ID] = { displayName = FIXED_MODEL_NAME, bid = itemConfig.lastBid or 0, buy = itemConfig.lastBuy or 0 }

			local preferredPrice = itemConfig.pricingModelOrder
			if not preferredPrice or not prices[preferredPrice] then preferredPrice = "market" end -- TODO Use default price
			if not preferredPrice or not prices[preferredPrice] then preferredPrice = "vendor" end -- TODO Use fallback price
			if not preferredPrice or not prices[preferredPrice] then preferredPrice = nil end
			pricingModelSelector:SetValues(prices)
			pricingModelSelector:SetEnabled(true)
			if preferredPrice then
				pricingModelSelector:SetSelectedKey(preferredPrice)
			end
			
			local preferredMatch = itemConfig.usePriceMatching
			if preferredMatch == nil then preferredMatch = false end -- TODO Get default value
			priceMatchingCheck:SetEnabled(true)
			priceMatchingCheck:SetChecked(preferredMatch)
			
			local preferredStackSize = itemConfig.stackSize or "+" -- TODO Get default value
			stackSizeSelector:SetRange(1, itemInfo.stackMax or 1)
			stackSizeSelector:AddPostValue("+", "+", L["Misc/StackSizeMax"]) -- LOCALIZE first +, and all shortcuts in the file
			if type(preferredStackSize) == "number" then
				preferredStackSize = MMin(preferredStackSize, itemInfo.stackMax or 1)
			end
			stackSizeSelector:SetPosition(preferredStackSize)
			
			local preferredLimitActive = itemConfig.limitActive
			if preferredLimitActive == nil then preferredLimitActive = false end -- TODO Get default value
			stackLimitCheck:SetEnabled(true)
			stackLimitCheck:SetChecked(preferredLimitActive)

			bidMoneySelector:SetEnabled(true)
			buyMoneySelector:SetEnabled(true)
			
			local preferredBindPrices = itemConfig.bindPrices
			if preferredBindPrices == nil then preferredBindPrices = false end -- TODO Get default value
			bindPricesCheck:SetEnabled(true)
			bindPricesCheck:SetChecked(preferredBindPrices)
			
			local preferredDuration = itemConfig.duration or 3 -- TODO Get default value
			durationSlider:SetEnabled(true)
			durationSlider:SetPosition(preferredDuration)
			
			resetButton:SetEnabled(true)
			postButton:SetEnabled(true)
			autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
		end
		
		if itemType and itemInfo then
			GetPrices(function(prices) PopulatePostArea(itemType, itemInfo, prices) end, itemType, 0.75, nil, false) -- TODO BidPercentage, Get own models
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
		autoPostButton:SetTextureAsync(addonID, itemType and InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
		RefreshFilter()
	end
	
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
	durationTimeLabel:SetText(SFormat(L["PostFrame/LabelDurationFormat"], 48))

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
	
	buyMoneySelector:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT", -5, 141)
	buyMoneySelector:SetPoint("CENTERLEFT", buyLabel, "CENTERLEFT", maxRightLabelWidth, 0)
	buyMoneySelector:SetEnabled(false)

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
	
	function itemGrid.Event:SelectionChanged(itemType, itemData)
		auctionsGrid:SetItemType(itemType)
		RefreshPostArea(itemType, itemData)
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
		CTooltip(currentItemType)
	end
	
	function itemTexture.Event:MouseOut()
		CTooltip(nil)
	end
	
	function pricingModelSelector.Event:SelectionChanged()
		ApplyPricingModel()
		if currentItemType then
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] = InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] or {}
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].pricingModelOrder = (self:GetSelectedValue())
		end
	end

	function priceMatchingCheck.Event:CheckboxChange()
		ApplyPricingModel()
		if currentItemType then
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] = InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] or {}
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].usePriceMatching = self:GetChecked()
		end		
	end

	function stackSizeSelector.Event:PositionChanged(position)
		if currentItemType then
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] = InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] or {}
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].stackSize = position
			
			local stackSize = position
			if stackSize == "+" then
				local _, maxValue = self:GetRange()
				stackSize = maxValue
			end
			if type(stackSize) ~= "number" then stackSize = 0 end

			local selectedItem, selectedInfo = itemGrid:GetSelectedData()
			local stackNumber = InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].stackNumber or "A" -- TODO Get default
			
			if stackSize > 0 and selectedItem then
				local stacks = selectedInfo.adjustedStack
				local fullStacks = MFloor(stacks / stackSize)
				local maxNumberOfStacks = MCeil(stacks / stackSize)
				
				stackNumberSelector:SetRange(1, MMax(fullStacks, 1))
				stackNumberSelector:ResetPseudoValues()
				
				if fullStacks > 0 then
					stackNumberSelector:AddPostValue("F", "F", L["Misc/StacksFull"])
				end
				stackNumberSelector:AddPostValue("A", "A", L["Misc/StacksAll"])
				
				if stackNumber == "F" and fullStacks <= 0 then stackNumber = 1 end
				if type(stackNumber) == "number" then stackNumber = MMin(stackNumber, fullStacks) end
				stackNumberSelector:SetPosition(stackNumber)
			else
				stackNumberSelector:SetRange(0, 0)
				stackNumberSelector:ResetPseudoValues()
			end
		end	
	end
	
	function stackNumberSelector.Event:PositionChanged(stackNumber)
		if currentItemType then
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] = InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] or {}
			if type(stackNumber) == "number" or stackNumber == "F" or stackNumber == "A" then
				InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].stackNumber = stackNumber
			else
				InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].stackNumber = nil
			end
		end
	end
	
	function stackLimitCheck.Event:CheckboxChange()
		if currentItemType then
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] = InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] or {}
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].limitActive = self:GetChecked()
		end	
	end
	
	function bidMoneySelector.Event:ValueChanged(newValue)
		if not self:GetEnabled() then return end

		local bid, buy = newValue, buyMoneySelector:GetValue()

		if bindPricesCheck:GetChecked() and bid ~= buy then
			buyMoneySelector:SetValue(bid)
			buy = bid
		end

		if not pricesSetByModel then
			local prices = pricingModelSelector:GetValues()
			prices[FIXED_MODEL_ID].bid = bid
			prices[FIXED_MODEL_ID].buy = buy
			pricingModelSelector:SetSelectedKey(FIXED_MODEL_ID)
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] = InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] or {}
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].lastBid = bid
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].lastBuy = buy
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
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] = InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] or {}
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].lastBid = bid
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].lastBuy = buy
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
		if currentItemType then
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] = InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] or {}
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].bindPrices = self:GetChecked()
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
		durationTimeLabel:SetText(SFormat(L["PostFrame/LabelDurationFormat"], 6 * 2 ^ position))
		if currentItemType then
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] = InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] or {}
			InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType].duration = position
		end
	end
	
	function resetButton.Event:LeftPress()
		InternalInterface.CharacterSettings.Posting.ItemConfig[currentItemType] = nil
		RefreshPostArea(itemGrid:GetSelectedData())
	end
	
	function postButton.Event:LeftPress()
		-- TODO Cooldown
		
		local selectedItem, selectedInfo = itemGrid:GetSelectedData()
		if not selectedItem or not selectedInfo then return end
		
		local stackSize = stackSizeSelector:GetPosition()
		local stackNumber = stackNumberSelector:GetPosition()
		local bidUnitPrice = bidMoneySelector:GetValue()
		local buyUnitPrice = buyMoneySelector:GetValue()
		local duration = 6 * 2 ^ durationSlider:GetPosition()
		
		if stackSize == "+" then
			local _, maxValue = stackSizeSelector:GetRange()
			stackSize = maxValue
		elseif type(stackSize) ~= "number" then
			stackSize = 0			
		end
		
		if stackSize > 0 and selectedItem and selectedInfo and selectedInfo.adjustedStack then
			local stacks = selectedInfo.adjustedStack
			local fullStacks = MFloor(stacks / stackSize)
			local maxNumberOfStacks = MCeil(stacks / stackSize)
			
			if stackNumber == "F" then
				stackNumber = fullStacks
			elseif stackNumber == "A" then
				stackNumber = maxNumberOfStacks
			elseif type(stackNumber) ~= "number" then
				stackNumber = 0
			elseif stackLimitCheck:GetChecked() then
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
				-- TODO Error message if < 0
			end
			
			stackNumber = MMax(MMin(stackNumber, maxNumberOfStacks), 0)
		else
			stackNumber = 0
		end
		
		if stackSize <= 0 or stackNumber <= 0 or bidUnitPrice <= 0 then return end
		if buyUnitPrice <= 0 then 
			buyUnitPrice = nil
		elseif buyUnitPrice < bidUnitPrice then
			Write(L["PostingPanel/ErrorBidHigherBuy"]) -- LOCALIZE
			return
		end
		
		local amount = MMin(stackSize * stackNumber, selectedInfo.adjustedStack)
		if amount <= 0 then return end
		
		if PostItem(selectedItem, stackSize, amount, bidUnitPrice, buyUnitPrice, duration) then
			InternalInterface.CharacterSettings.Posting.ItemConfig[selectedItem] = InternalInterface.CharacterSettings.Posting.ItemConfig[selectedItem] or {}
			InternalInterface.CharacterSettings.Posting.ItemConfig[selectedItem].lastBid = bidUnitPrice or 0
			InternalInterface.CharacterSettings.Posting.ItemConfig[selectedItem].lastBuy = buyUnitPrice or 0
			-- self.cooldown = ITReal() + 0.5
		end
	end
	
	function autoPostButton.Event.LeftClick()
		local itemType = itemGrid:GetSelectedData()
		if not itemType then return end
		InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] = not InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] or nil -- FIXME
		RefreshFilter()
		autoPostButton:SetTextureAsync(addonID, InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] and "Textures/AutoOn.png" or "Textures/AutoOff.png")
	end
	
	function autoPostButton.Event.RightClick()
		local filteredData = itemGrid:GetFilteredData()
		for itemType in pairs(filteredData) do
			if not InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] then -- FIXME
				filteredData[itemType] = nil
			end
		end
	
		if not next(filteredData) then return end
		
		local function DoAutoPost(ownAuctions)
			local pricingModels = GetPriceModels()
			local queue = GetPostingQueue()
			ownAuctions = ownAuctions or {}

			for itemType, itemInfo in pairs(filteredData) do repeat
				local itemConfig = itemType and InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] or {}
				
				local preferredPrice = itemConfig.pricingModelOrder or "market" -- TODO Use default price
				if not preferredPrice or (not pricingModels[preferredPrice] and preferredPrice ~= FIXED_MODEL_ID) then
					InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] = nil
					-- TODO Message warning deactivation?
					break
				end

				local preferredMatch = itemConfig.usePriceMatching
				if preferredMatch == nil then preferredMatch = false end -- TODO Get default value
				
				local preferredStackSize = itemConfig.stackSize or "+" -- TODO Get default value
				if preferredStackSize == "+" then preferredStackSize = itemInfo.stackMax end
				if type(preferredStackSize) ~= "number" or preferredStackSize <= 0 then break end

				local stacks = itemInfo.adjustedStack
				if not stacks or stacks < 0 then break end
				local fullStacks = MFloor(stacks / preferredStackSize)
				local maxNumberOfStacks = MCeil(stacks / preferredStackSize)
				
				local preferredLimitActive = itemConfig.limitActive
				if preferredLimitActive == nil then preferredLimitActive = false end -- TODO Get default value
				
				local preferredStackNumber = itemConfig.stackNumber or "A" -- TODO Get default value
				if preferredStackNumber == "F" then
					preferredStackNumber = fullStacks
				elseif preferredStackNumber == "A" then
					preferredStackNumber = maxNumberOfStacks
				elseif type(preferredStackNumber) ~= "number" then
					break
				elseif preferredLimitActive then
					for auctionID, auctionData in pairs(ownAuctions) do
						if auctionData.itemType == itemType then
							preferredStackNumber = preferredStackNumber - 1
						end
					end
				
					for _, queueInfo in ipairs(queue) do
						if queueInfo.itemType == itemType then
							preferredStackNumber = preferredStackNumber - MCeil(queueInfo.amount / queueInfo.stackSize)
						end
					end

					if preferredStackNumber <= 0 then break end
				end
				preferredStackNumber = MMin(preferredStackNumber, maxNumberOfStacks)
				
				local preferredAmount = MMin(preferredStackSize * preferredStackNumber, stacks)
				
				local preferredBindPrices = itemConfig.bindPrices
				if preferredBindPrices == nil then preferredBindPrices = false end  -- TODO Get default value
				
				local preferredDuration = 6 * 2 ^ (itemConfig.duration or 3) -- TODO Get default value
				
				local function GetPricesCallback(prices)
					if not prices or not prices[preferredPrice] then return end
					local bid = preferredMatch and prices[preferredPrice].adjustedBid or prices[preferredPrice].bid
					local buy = preferredMatch and prices[preferredPrice].adjustedBuy or prices[preferredPrice].buy
					
					if preferredBindPrices then
						bid = MMax(bid or 0, buy or 0)
						buy = bid
					end
					
					if buy <= 0 then 
						buy = nil
					elseif bid <= 0 or buy < bid then
						return
					end
					
					if PostItem(itemType, preferredStackSize, preferredAmount, bid, buy, preferredDuration) then
						InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] = InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] or {}
						InternalInterface.CharacterSettings.Posting.ItemConfig[itemType].lastBid = bid or 0
						InternalInterface.CharacterSettings.Posting.ItemConfig[itemType].lastBuy = buy or 0
					end
				end

				if preferredPrice == FIXED_MODEL_ID then
					GetPricesCallback({ [FIXED_MODEL_ID] = { bid = itemConfig.lastBid or 0, buy = itemConfig.lastBuy or 0, } })
				else
					GetPrices(GetPricesCallback, itemType, 0.75, preferredPrice, false) -- TODO BidPercentage
				end
			until true end
		end
		
		GetOwnAuctionData(DoAutoPost)
	end
	
	function auctionsGrid.Event:RowRightClick(auctionID, auctionData)
		if auctionData then
			if auctionData.own then
				bidMoneySelector:SetValue(auctionData.bidUnitPrice or 0)
				if auctionData.buyoutUnitPrice or not bindPricesCheck:GetChecked() then
					buyMoneySelector:SetValue(auctionData.buyoutUnitPrice or 0)
				end
			else
				bidMoneySelector:SetValue(MMax((auctionData.bidUnitPrice or 0) - 1, 1))
				if auctionData.buyoutUnitPrice or not bindPricesCheck:GetChecked() then
					buyMoneySelector:SetValue(MMax((auctionData.buyoutUnitPrice or 0) - 1, auctionData.buyoutUnitPrice and 1 or 0))
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
	
	
	TInsert(Event.Item.Slot, { function() resetNeeded = true end, addonID, addonID .. ".PostFrame.OnItemSlot" })
	TInsert(Event.Item.Update, { function() resetNeeded = true end, addonID, addonID .. ".PostFrame.OnItemUpdate" })

	local function OnPostingQueueChanged()
		RefreshFilter()
		RefreshPostArea(itemGrid:GetSelectedData())
	end
	TInsert(Event.LibPGC.PostingQueueChanged, { OnPostingQueueChanged, addonID, addonID .. ".PostFrame.OnPostingQueueChanged" })	
	
	local function OnFrame()
		if resetNeeded then
			ResetItems()
			resetNeeded = false
		end
	end
	TInsert(Event.System.Update.Begin, { OnFrame, addonID, addonID .. ".PostFrame.OnFrame" })
	
	-- TODO auto post
	
	return postFrame
end
