-- ***************************************************************************************************************************************************
-- * PostFrame.lua                                                                                                                                   *
-- ***************************************************************************************************************************************************
-- * Post tab frame                                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * 0.4.4 / 2013.02.07 / Baanano: Extracted model logic to PostController                                                                           *
-- * 0.4.1 / 2012.07.31 / Baanano: Rewritten for 0.4.1                                                                                               *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local BASE_CATEGORY = InternalInterface.Category.BASE_CATEGORY
local CDetail = InternalInterface.Category.Detail
local CTooltip = Command.Tooltip
local ClearItemAuto = InternalInterface.Control.PostController.ClearItemAuto
local DataGrid = Yague.DataGrid
local Dropdown = Yague.Dropdown
local GetCategoryConfig = InternalInterface.Helper.GetCategoryConfig
local GetHiddenVisibility = InternalInterface.Control.PostController.GetHiddenVisibility
local GetPostingQueue = LibPGC.GetPostingQueue
local GetPostingSettings = InternalInterface.Helper.GetPostingSettings
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local GetSelectedItemType = InternalInterface.Control.PostController.GetSelectedItemType
local IIDetail = Inspect.Item.Detail
local ITReal = Inspect.Time.Real
local L = InternalInterface.Localization.L
local MCeil = math.ceil
local MFloor = math.floor
local MMax = math.max
local MMin = math.min
local MoneySelector = Yague.MoneySelector
local Panel = Yague.Panel
local PostItem = InternalInterface.Control.PostController.PostItem
local ResetPostingSettings = InternalInterface.Control.PostController.ResetPostingSettings
local SetControllerActive = InternalInterface.Control.PostController.SetActive
local SetHiddenVisibility = InternalInterface.Control.PostController.SetHiddenVisibility
local SetItemAuto = InternalInterface.Control.PostController.SetItemAuto
local SetSelectedItemType = InternalInterface.Control.PostController.SetSelectedItemType
local ShadowedText = Yague.ShadowedText
local Slider = Yague.Slider
local TInsert = table.insert
local TRemove = table.remove
local ToggleItemVisibility = InternalInterface.Control.PostController.ToggleItemVisibility
local UICreateFrame = UI.CreateFrame
local Write = InternalInterface.Output.Write
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local type = type

local AH_FEE_MULTIPLIER = 0.95
local FIXED_MODEL_ID = "fixed"

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
	local visibility = "Show"
	local auto = nil
	local itemCategory = nil

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
		visibility = value.visibility
		auto = value.auto
		itemCategory = value.category
		
		visibilityIcon:SetTextureAsync(addonID, (visibility == "HideAll" and "Textures/HideIcon.png") or (visibility == "HideChar" and "Textures/CharacterHideIcon.png") or "Textures/ShowIcon.png")
		autoPostingIcon:SetTexture(addonID, auto and "Textures/AutoOn.png" or "Textures/AutoOff.png")
	end
	
	function visibilityIcon.Event:LeftClick()
		ToggleItemVisibility(itemType, "HideAll")
	end
	
	function visibilityIcon.Event:RightClick()
		ToggleItemVisibility(itemType, "HideChar")
	end
	
	function autoPostingIcon.Event:LeftClick()
		if itemType then
			if auto then
				ClearItemAuto(itemType)
			else
				local categoryConfig = GetCategoryConfig(itemCategory)
				
				SetItemAuto(itemType,
				{
					pricingModelOrder = categoryConfig.DefaultReferencePrice,
					usePriceMatching = categoryConfig.ApplyMatching,
					lastBid = 0,
					lastBuy = 0,
					bindPrices = InternalInterface.AccountSettings.Posting.Config.BindPrices,
					stackSize = categoryConfig.StackSize,
					auctionLimit = categoryConfig.AuctionLimit,
					postIncomplete = categoryConfig.PostIncomplete,
					duration = categoryConfig.Duration,
				})
			end
		end
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
	local categoryFilter = Dropdown(name .. ".CategoryFilter", itemGrid:GetContent())
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
	local auctionLimitLabel = ShadowedText(name .. ".AuctionLimitLabel", postFrame)
	local auctionLimitSelector = Slider(name .. ".AuctionLimitSelector", postFrame)
	local auctionsLabel = ShadowedText(name .. ".AuctionsLabel", postFrame)
	local incompleteStackLabel = ShadowedText(name .. ".IncompleteStackLabel", postFrame)
	local incompleteStackCheck = UICreateFrame("RiftCheckbox", name .. ".IncompleteStackCheck", postFrame)
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
	
	local noPropagateAuto = false
	local noPropagatePrices = false
	local waitUntil = 0

	local function ItemGridFilter(itemType, itemInfo)
		if itemInfo.adjustedStack <= 0 then return false end
		
		if not GetHiddenVisibility() and itemInfo.visibility ~= "Show" then
			return false
		end

		local rarity = itemInfo.rarity and itemInfo.rarity ~= "" and itemInfo.rarity or "common"
		rarity = ({ sellable = 1, common = 2, uncommon = 3, rare = 4, epic = 5, relic = 6, trascendant = 7, ascended = 8, eternal = 9 })[rarity] or 1
		local minRarity = InternalInterface.AccountSettings.Posting.RarityFilter or 1
		if rarity < minRarity then return false end
		
		local categoryID, filterCategory = categoryFilter:GetSelectedValue()
		if categoryID ~= BASE_CATEGORY and not filterCategory.filter[itemInfo.category or BASE_CATEGORY] then return false end

		local filterText = (filterTextField:GetText()):upper()
		local upperName = itemInfo.name:upper()
		if not upperName:find(filterText) then return false end
		
		return true
	end
	
	local function RefreshFilter()
		itemGrid:RefreshFilter()
	end
	
	local function ApplyPricingModel()
		local priceID, priceData = pricingModelSelector:GetSelectedValue()
		local match = priceMatchingCheck:GetChecked()
		
		noPropagatePrices = true
		if priceID and priceData then
			local bid = match and priceData.adjustedBid or priceData.bid
			local buy = match and priceData.adjustedBuy or priceData.buy
			bidMoneySelector:SetValue(bid)
			buyMoneySelector:SetValue(buy)
		else
			bidMoneySelector:SetValue(0)
			buyMoneySelector:SetValue(0)
		end
		noPropagatePrices = false
	end
	
	local function ResetAuctionLabel()
		local itemType, itemInfo = GetSelectedItemType()
		local auctions = auctionsGrid:GetAuctions()
		if auctions and itemInfo then
			local stack = itemInfo.adjustedStack
			local stackSize = stackSizeSelector:GetPosition()
			stackSize = stackSize == "+" and itemInfo.stackMax or stackSize
			local Round = incompleteStackCheck:GetChecked() and MCeil or MFloor
			local numAuctions = Round(stack / stackSize)
			
			local ownAuctions = 0
			for _, auctionData in pairs(auctions) do
				if auctionData.own then
					ownAuctions = ownAuctions + 1
				end
			end
			
			local queuedAuctions = 0
			for _, postData in pairs(GetPostingQueue()) do
				if postData.itemType == itemType then
					queuedAuctions = queuedAuctions + MCeil(postData.amount / postData.stackSize)
				end
			end
			
			local postAuctions = numAuctions
			local limit = auctionLimitSelector:GetPosition()
			if type(limit) == "number" then
				postAuctions = MMax(MMin(limit - ownAuctions - queuedAuctions, numAuctions), 0)
			end
			
			auctionsLabel:SetText(L["PostFrame/LabelAuctions"]:format(postAuctions, postAuctions == 1 and L["PostFrame/LabelAuctionsSingular"] or L["PostFrame/LabelAuctionsPlural"], ownAuctions, queuedAuctions))
			auctionsLabel:SetVisible(true)
			
			postButton:SetEnabled(postAuctions > 0)
		else
			auctionsLabel:SetVisible(false)
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
			auctionLimit = auctionLimitSelector:GetPosition(),
			postIncomplete = incompleteStackCheck:GetChecked(),
			duration = durationSlider:GetPosition(),
		}
		return settings
	end

	local function ColorSelector(value)
		local _, itemInfo = GetSelectedItemType()
		if itemInfo and itemInfo.sell and value > 0 and value < MCeil(itemInfo.sell / AH_FEE_MULTIPLIER) then
			return { 1, 0, 0, }
		else
			return { 0, 0, 0, }
		end
	end
	
	local function BuildCategoryFilter()
		local categories = {}

		local baseCategory = CDetail(BASE_CATEGORY)
		for order, subCategoryID in ipairs(baseCategory.children) do
			categories[subCategoryID] = { name = CDetail(subCategoryID).name, order = order, filter = {}, }
		end

		for categoryID, categoryData in pairs(categories) do
			local pending = { categoryID }
			while #pending > 0 do
				local current = TRemove(pending)
				
				categoryData.filter[current] = true
				
				local children = CDetail(current).children
				if children then
					for _, child in pairs(children) do
						TInsert(pending, child)
					end
				end
			end
		end

		categories[BASE_CATEGORY] = { name = baseCategory.name, order = 0, filter = {}, }
		
		return categories
	end
	
	
	itemGrid:SetPoint("TOPLEFT", postFrame, "TOPLEFT", 5, 5)
	itemGrid:SetPoint("BOTTOMRIGHT", postFrame, "BOTTOMLEFT", 295, -5)
	itemGrid:SetPadding(1, 38, 1, 38)
	itemGrid:SetHeadersVisible(false)
	itemGrid:SetRowHeight(62)
	itemGrid:SetRowMargin(2)
	itemGrid:SetUnselectedRowBackgroundColor({0.2, 0.15, 0.2, 1})
	itemGrid:SetSelectedRowBackgroundColor({0.6, 0.45, 0.6, 1})
	itemGrid:AddColumn("item", nil, ItemCellType, 248, 0, nil, "name")
	itemGrid:SetFilter(ItemGridFilter)
	itemGrid:GetInternalContent():SetBackgroundColor(0, 0.05, 0, 0.5)	

	categoryFilter:SetPoint("TOPLEFT", itemGrid:GetContent(), "TOPLEFT", 3, 3)
	categoryFilter:SetPoint("BOTTOMRIGHT", itemGrid:GetContent(), "TOPRIGHT", -3, 35)
	categoryFilter:SetTextSelector("name")
	categoryFilter:SetOrderSelector("order")
	categoryFilter:SetValues(BuildCategoryFilter())
	
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
	itemNameLabel:SetVisible(false)

	itemStackLabel:SetPoint("BOTTOMLEFT", itemTexturePanel, "BOTTOMRIGHT", 5, -1)
	itemStackLabel:SetFontSize(15)
	itemStackLabel:SetVisible(false)	
	
	stackSizeLabel:SetPoint("TOPLEFT", postFrame, "TOPLEFT", 315, 105)
	stackSizeLabel:SetText(L["PostFrame/LabelStackSize"])
	stackSizeLabel:SetFontSize(14)
	stackSizeLabel:SetFontColor(1, 1, 0.75, 1)
	stackSizeLabel:SetShadowOffset(2, 2)
	
	auctionLimitLabel:SetPoint("TOPLEFT", postFrame, "TOPLEFT", 315, 145)
	auctionLimitLabel:SetText(L["PostFrame/LabelAuctionLimit"])
	auctionLimitLabel:SetFontSize(14)
	auctionLimitLabel:SetFontColor(1, 1, 0.75, 1)
	auctionLimitLabel:SetShadowOffset(2, 2)

	auctionsLabel:SetPoint("TOPLEFT", auctionLimitLabel, "BOTTOMLEFT", 0, 10)
	auctionsLabel:SetFontColor(1, 0.5, 0, 1)
	auctionsLabel:SetFontSize(13)
	
	durationLabel:SetPoint("TOPLEFT", postFrame, "TOPLEFT", 315, 225)
	durationLabel:SetText(L["PostFrame/LabelDuration"])
	durationLabel:SetFontSize(14)
	durationLabel:SetFontColor(1, 1, 0.75, 1)
	durationLabel:SetShadowOffset(2, 2)

	local maxLeftLabelWidth = 100
	maxLeftLabelWidth = MMax(maxLeftLabelWidth, stackSizeLabel:GetWidth())
	maxLeftLabelWidth = MMax(maxLeftLabelWidth, auctionLimitLabel:GetWidth())
	maxLeftLabelWidth = MMax(maxLeftLabelWidth, durationLabel:GetWidth())
	maxLeftLabelWidth = maxLeftLabelWidth + 20

	stackSizeSelector:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT", -490, 106)
	stackSizeSelector:SetPoint("CENTERLEFT", stackSizeLabel, "CENTERLEFT", maxLeftLabelWidth, 4)
	
	auctionLimitSelector:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT", -490, 146)
	auctionLimitSelector:SetPoint("CENTERLEFT", auctionLimitLabel, "CENTERLEFT", maxLeftLabelWidth, 4)

	incompleteStackLabel:SetPoint("RIGHT", auctionLimitSelector, "RIGHT")
	incompleteStackLabel:SetPoint("CENTERY", auctionsLabel, "CENTERY")
	incompleteStackLabel:SetFontSize(13)
	incompleteStackLabel:SetText(L["PostFrame/LabelIncompleteStack"])	
	
	incompleteStackCheck:SetPoint("CENTERRIGHT", incompleteStackLabel, "CENTERLEFT", -5, 0)
	incompleteStackCheck:SetChecked(false)
	incompleteStackCheck:SetEnabled(false)

	durationTimeLabel:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT", -490, 225)
	durationTimeLabel:SetText(L["Misc/DurationFormat"]:format(48))

	durationSlider:SetPoint("CENTERLEFT", durationLabel, "CENTERLEFT", maxLeftLabelWidth + 10, 5)
	durationSlider:SetPoint("CENTERRIGHT", durationTimeLabel, "CENTERLEFT", -15, 5)
	durationSlider:SetRange(1, 3)
	durationSlider:SetPosition(3)
	durationSlider:SetEnabled(false)
	
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

	local maxRightLabelWidth = 100
	maxRightLabelWidth = MMax(maxRightLabelWidth, pricingModelLabel:GetWidth())
	maxRightLabelWidth = MMax(maxRightLabelWidth, bidLabel:GetWidth())
	maxRightLabelWidth = MMax(maxRightLabelWidth, buyLabel:GetWidth())
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


	
	function itemGrid.Event:SelectionChanged(itemType)
		SetSelectedItemType(itemType)
	end
	
	function categoryFilter.Event:SelectionChanged()
		RefreshFilter()
	end
	
	function filterTextPanel.Event:LeftClick()
		filterTextField:SetKeyFocus(true)
	end

	function filterTextField.Event:KeyFocusGain()
		local length = (self:GetText()):len()
		if length > 0 then
			self:SetSelection(0, length)
		end
	end
	
	function filterTextField.Event:TextfieldChange()
		RefreshFilter()
	end	
	
	function visibilityIcon.Event:LeftClick()
		SetHiddenVisibility(not GetHiddenVisibility())
	end
	
	function itemTexture.Event:MouseIn()
		pcall(CTooltip, (GetSelectedItemType()))
	end
	
	function itemTexture.Event:MouseOut()
		CTooltip(nil)
	end
	
	function pricingModelSelector.Event:SelectionChanged()
		ApplyPricingModel()
		local itemType, itemInfo = GetSelectedItemType()
		if not noPropagateAuto and itemInfo.auto then
			ClearItemAuto(itemType)
		end
	end

	function priceMatchingCheck.Event:CheckboxChange()
		ApplyPricingModel()
		local itemType, itemInfo = GetSelectedItemType()
		if not noPropagateAuto and itemInfo.auto then
			ClearItemAuto(itemType)
		end
	end

	function stackSizeSelector.Event:PositionChanged(position)
		local itemType, itemInfo = GetSelectedItemType()
		if not noPropagateAuto and itemInfo.auto then
			ClearItemAuto(itemType)
		end
		ResetAuctionLabel()
	end
	
	function auctionLimitSelector.Event:PositionChanged()
		local itemType, itemInfo = GetSelectedItemType()
		if not noPropagateAuto and itemInfo.auto then
			ClearItemAuto(itemType)
		end
		ResetAuctionLabel()
	end
	
	function incompleteStackCheck.Event:CheckboxChange()
		local itemType, itemInfo = GetSelectedItemType()
		if not noPropagateAuto and itemInfo.auto then
			ClearItemAuto(itemType)
		end
		ResetAuctionLabel()
	end
	
	function bidMoneySelector.Event:ValueChanged(newValue)
		if not self:GetEnabled() then return end

		local bid, buy = newValue, buyMoneySelector:GetValue()

		if (bindPricesCheck:GetChecked() or bid > buy) and bid ~= buy then
			buyMoneySelector:SetValue(bid)
			buy = bid
		end

		if not noPropagatePrices then
			local prices = pricingModelSelector:GetValues()
			prices[FIXED_MODEL_ID].bid = bid
			prices[FIXED_MODEL_ID].buy = buy
			pricingModelSelector:SetSelectedKey(FIXED_MODEL_ID)
			local itemType, itemInfo = GetSelectedItemType()
			if not noPropagateAuto and itemInfo.auto then
				ClearItemAuto(itemType)
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
		
		if not noPropagatePrices then
			local prices = pricingModelSelector:GetValues()
			prices[FIXED_MODEL_ID].bid = bid
			prices[FIXED_MODEL_ID].buy = buy
			pricingModelSelector:SetSelectedKey(FIXED_MODEL_ID)
			local itemType, itemInfo = GetSelectedItemType()
			if not noPropagateAuto and itemInfo.auto then
				ClearItemAuto(itemType)
			end
		end
	end	

	function bindPricesCheck.Event:CheckboxChange()
		if self:GetChecked() then
			noPropagatePrices = true
			local maxPrice = MMax(bidMoneySelector:GetValue(), buyMoneySelector:GetValue())
			bidMoneySelector:SetValue(maxPrice)
			buyMoneySelector:SetValue(maxPrice)
			noPropagatePrices = false
		else
			ApplyPricingModel()
		end
		local itemType, itemInfo = GetSelectedItemType()
		if not noPropagateAuto and itemInfo.auto then
			ClearItemAuto(itemType)
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
		durationTimeLabel:SetText(L["Misc/DurationFormat"]:format(6 * 2 ^ position))
		local itemType, itemInfo = GetSelectedItemType()
		if not noPropagateAuto and itemInfo.auto then
			ClearItemAuto(itemType)
		end
	end
	
	function resetButton.Event:LeftPress()
		ResetPostingSettings()
		RefreshFilter()
	end
	
	function postButton.Event:LeftPress()
		if ITReal() < waitUntil then return end
		
		local itemType, itemInfo = GetSelectedItemType()
		if not itemType or not itemInfo then return end

		local result = PostItem(CollectPostingSettings())
		if type(result) == "string" then
			Write(L["PostFrame/ErrorPostBase"]:format(result))
		elseif result then
			waitUntil = ITReal() + 0.5
		end
	end
	
	function autoPostButton.Event.LeftClick()
		local itemType, itemInfo = GetSelectedItemType()
		if not itemType or not itemInfo then return end
		
		if itemInfo.auto then
			ClearItemAuto(itemType)
		else
			if not auctionsLabel:GetVisible() then return end
			local result = SetItemAuto(itemType, CollectPostingSettings())
			if type(result) == "string" then
				Write(L["PostFrame/ErrorPostBase"]:format(result))
			end
		end
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
		SetControllerActive(true)
	end
	
	function postFrame:Hide()
		SetControllerActive(false)
	end
	
	function postFrame:ItemRightClick(params)
		if params and params.id then
			local ok, itemDetail = pcall(IIDetail, params.id)
			if not ok or not itemDetail or not itemDetail.type then return false end
			local filteredData = itemGrid:GetFilteredData()
			if filteredData[itemDetail.type] then
				itemGrid:SetSelectedKey(itemDetail.type)
			end
			return true
		end
		return false
	end
	
	TInsert(InternalInterface.Control.PostController.ItemListChanged, function(itemList) itemGrid:SetData(itemList, nil, nil, true) end)
	
	local function OnHiddenVisibilityChanged(visible)
		visibilityIcon:SetTextureAsync(addonID, visible and "Textures/ShowIcon.png" or "Textures/HideIcon.png")
		RefreshFilter()
	end
	TInsert(InternalInterface.Control.PostController.HiddenVisibilityChanged, OnHiddenVisibilityChanged)
	TInsert(InternalInterface.Control.PostController.ItemVisibilityChanged, RefreshFilter)
	local function OnItemAutoChanged(changedItemType)
		local itemType, itemInfo = GetSelectedItemType()
		if itemType == changedItemType and itemInfo then
			autoPostButton:SetTexture(addonID, itemInfo.auto and "Textures/AutoOn.png" or "Textures/AutoOff.png")
		end
		RefreshFilter()
	end
	TInsert(InternalInterface.Control.PostController.ItemAutoChanged, OnItemAutoChanged)

	local function OnSelectedItemTypeChanged(itemType, itemInfo)
		noPropagateAuto = true
		
		stackSizeSelector:ResetPseudoValues()
		auctionLimitSelector:ResetPseudoValues()

		if itemType and itemInfo then
			local itemSettings = GetPostingSettings(itemType, itemInfo.category)
		
			itemTexturePanel:GetContent():SetBackgroundColor(GetRarityColor(itemInfo.rarity))
			itemTexture:SetTextureAsync("Rift", itemInfo.icon)
			itemTexture:SetVisible(true)
			itemNameLabel:SetText(itemInfo.name)
			itemNameLabel:SetFontColor(GetRarityColor(itemInfo.rarity))
			itemNameLabel:SetVisible(true)
			itemStackLabel:SetText(L["PostFrame/LabelItemStack"]:format(itemInfo.adjustedStack))
			itemStackLabel:SetVisible(true)
			
			stackSizeSelector:SetRange(1, itemInfo.stackMax)
			stackSizeSelector:AddPostValue(L["Misc/StackSizeMaxKeyShortcut"], "+", L["Misc/StackSizeMax"])
			local preferredStackSize = itemSettings.stackSize
			if type(preferredStackSize) == "number" then
				preferredStackSize = MMin(preferredStackSize, itemInfo.stackMax)
			end
			stackSizeSelector:SetPosition(preferredStackSize)

			auctionLimitSelector:SetRange(1, 999)
			auctionLimitSelector:AddPostValue(L["Misc/AuctionLimitMaxKeyShortcut"], "+", L["Misc/AuctionLimitMax"])
			auctionLimitSelector:SetPosition(itemSettings.auctionLimit)

			incompleteStackCheck:SetEnabled(true)
			incompleteStackCheck:SetChecked(itemSettings.postIncomplete)

			durationSlider:SetEnabled(true)
			durationSlider:SetPosition(itemSettings.duration)

			priceMatchingCheck:SetEnabled(true)
			priceMatchingCheck:SetChecked(itemSettings.matchPrices)
			
			bindPricesCheck:SetEnabled(true)
			bindPricesCheck:SetChecked(itemSettings.bindPrices)
			
			autoPostButton:SetTexture(addonID, itemInfo.auto and "Textures/AutoOn.png" or "Textures/AutoOff.png")
		else
			itemTexturePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
			itemTexture:SetVisible(false)
			itemNameLabel:SetVisible(false)
			itemStackLabel:SetVisible(false)
			stackSizeSelector:SetRange(0, 0)
			auctionLimitSelector:SetRange(0, 0)
			incompleteStackCheck:SetEnabled(false)
			incompleteStackCheck:SetChecked(false)
			durationSlider:SetEnabled(false)
			priceMatchingCheck:SetEnabled(false)
			priceMatchingCheck:SetChecked(false)
			bindPricesCheck:SetEnabled(false)
			bindPricesCheck:SetChecked(false)
			autoPostButton:SetTexture(addonID, "Textures/AutoOff.png")
		end
		
		bidMoneySelector:SetEnabled(false)
		bidMoneySelector:SetValue(0)
		buyMoneySelector:SetEnabled(false)
		buyMoneySelector:SetValue(0)
		pricingModelSelector:SetValues({})
		pricingModelSelector:SetEnabled(false)
		resetButton:SetEnabled(false)
		postButton:SetEnabled(false)

		auctionsGrid:SetItemAuctions()
		
		ResetAuctionLabel()
		
		noPropagateAuto = false
	end
	TInsert(InternalInterface.Control.PostController.SelectedItemTypeChanged, OnSelectedItemTypeChanged)

	local function OnPricesChanged(prices)
		noPropagateAuto = true
	
		local itemType, itemInfo = GetSelectedItemType()
		
		if not prices or not itemType or not itemInfo then
			bidMoneySelector:SetEnabled(false)
			bidMoneySelector:SetValue(0)
			buyMoneySelector:SetEnabled(false)
			buyMoneySelector:SetValue(0)
			pricingModelSelector:SetValues({})
			pricingModelSelector:SetEnabled(false)
			resetButton:SetEnabled(false)			
		else
			bidMoneySelector:SetEnabled(true)
			buyMoneySelector:SetEnabled(true)

			local itemSettings = GetPostingSettings(itemType, itemInfo.category)
			local preferredPrice = pricingModelSelector:GetSelectedValue()
			if not preferredPrice or not prices[preferredPrice] then
				preferredPrice = itemSettings.referencePrice
				if not preferredPrice or not prices[preferredPrice] then
					preferredPrice = prices[itemSettings.fallbackPrice] and itemSettings.fallbackPrice or nil
				end
			elseif preferredPrice == FIXED_MODEL_ID then
				prices[preferredPrice].bid = bidMoneySelector:GetValue()
				prices[preferredPrice].buy = buyMoneySelector:GetValue()
			end
			pricingModelSelector:SetValues(prices)
			pricingModelSelector:SetEnabled(true)
			if preferredPrice then
				pricingModelSelector:SetSelectedKey(preferredPrice)
			end
			
			if itemInfo.auto and not prices[itemSettings.referencePrice] then
				Write(L["PostFrame/ErrorAutoPostModelMissing"])
				ClearItemAuto(itemType)
			end
			
			resetButton:SetEnabled(true)
		end
		
		noPropagateAuto = false
	end
	TInsert(InternalInterface.Control.PostController.PricesChanged, OnPricesChanged)
	
	local function OnAuctionsChanged(auctions)
		local itemType = GetSelectedItemType()
		if not auctions or not itemType then
			auctionsGrid:SetItemAuctions()
			postButton:SetEnabled(false)
		else
			auctionsGrid:SetItemAuctions(itemType, auctions)
			ResetAuctionLabel()
		end
	end
	TInsert(InternalInterface.Control.PostController.AuctionsChanged, OnAuctionsChanged)
	
	local function OnStackChanged(stack)
		itemStackLabel:SetText(L["PostFrame/LabelItemStack"]:format(stack))
		ResetAuctionLabel()
	end
	TInsert(InternalInterface.Control.PostController.ItemAdjustedStackChanged, OnStackChanged)

	return postFrame
end
