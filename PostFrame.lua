-- ***************************************************************************************************************************************************
-- * PostFrame.lua                                                                                                                                   *
-- ***************************************************************************************************************************************************
-- * 0.4.4 / 2013.02.07 / Baanano: Extracted model logic to PostController                                                                           *
-- * 0.4.1 / 2012.07.31 / Baanano: Rewritten for 0.4.1                                                                                               *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local AH_FEE_MULTIPLIER = 0.95
local FIXED_MODEL_ID = "fixed"

local function ItemCellType(name, parent)
	local itemCell = UI.CreateFrame("Mask", name, parent)
	
	local cellBackground = UI.CreateFrame("Texture", name .. ".CellBackground", itemCell)
	local itemTextureBackground = UI.CreateFrame("Frame", name .. ".ItemTextureBackground", itemCell)
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = Yague.ShadowedText(name .. ".ItemNameLabel", itemCell)
	local visibilityIcon = UI.CreateFrame("Texture", name .. ".VisibilityIcon", itemCell)
	local autoPostingIcon = UI.CreateFrame("Texture", name .. ".AutoPostingIcon", itemCell)
	local itemStackLabel = UI.CreateFrame("Text", name .. ".ItemStackLabel", itemCell)
	
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
		itemTextureBackground:SetBackgroundColor(InternalInterface.Utility.GetRarityColor(value.rarity))
		itemTexture:SetTextureAsync("Rift", value.icon)
		itemNameLabel:SetText(value.name or "")
		itemNameLabel:SetFontColor(InternalInterface.Utility.GetRarityColor(value.rarity))
		itemStackLabel:SetText("x" .. (value.adjustedStack or 0))
		
		itemType = value.itemType
		visibility = value.visibility
		auto = value.auto
		itemCategory = value.category
		
		visibilityIcon:SetTextureAsync(addonID, (visibility == "HideAll" and "Textures/HideIcon.png") or (visibility == "HideChar" and "Textures/CharacterHideIcon.png") or "Textures/ShowIcon.png")
		autoPostingIcon:SetTexture(addonID, auto and "Textures/AutoOn.png" or "Textures/AutoOff.png")
	end
	
	visibilityIcon:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			InternalInterface.Control.PostController.ToggleItemVisibility(itemType, "HideAll")
		end, visibilityIcon:GetName() .. ".OnLeftClick")
	
	visibilityIcon:EventAttach(Event.UI.Input.Mouse.Right.Click,
		function()
			InternalInterface.Control.PostController.ToggleItemVisibility(itemType, "HideChar")
		end, visibilityIcon:GetName() .. ".OnRightClick")
	
	autoPostingIcon:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			if itemType then
				if auto then
					InternalInterface.Control.PostController.ClearItemAuto(itemType)
				else
					local categoryConfig = InternalInterface.Helper.GetCategoryConfig(itemCategory)
					
					InternalInterface.Control.PostController.SetItemAuto(itemType,
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
		end, autoPostingIcon:GetName() .. ".OnLeftClick")
	
	itemTexture:EventAttach(Event.UI.Input.Mouse.Cursor.In,
		function()
			pcall(Command.Tooltip, itemType)
		end, itemTexture:GetName() .. ".OnCursorIn")
	
	itemTexture:EventAttach(Event.UI.Input.Mouse.Cursor.Out,
		function()
			Command.Tooltip(nil)
		end, itemTexture:GetName() .. ".OnCursorOut")
	
	return itemCell
end

function InternalInterface.UI.PostFrame(name, parent)
	local postFrame = UI.CreateFrame("Frame", name, parent)
	
	local itemGrid = Yague.DataGrid(name .. ".ItemGrid", postFrame)
	local categoryFilter = Yague.Dropdown(name .. ".CategoryFilter", itemGrid:GetContent())
	local filterFrame = UI.CreateFrame("Frame", name .. ".FilterFrame", itemGrid:GetContent())
	local filterTextPanel = Yague.Panel(filterFrame:GetName() .. ".FilterTextPanel", filterFrame)
	local visibilityIcon = UI.CreateFrame("Texture", filterFrame:GetName() .. ".VisibilityIcon", filterTextPanel:GetContent())
	local filterTextField = UI.CreateFrame("RiftTextfield", filterFrame:GetName() .. ".FilterTextField", filterTextPanel:GetContent())
	
	local itemTexturePanel = Yague.Panel(name .. ".ItemTexturePanel", postFrame)
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTexturePanel:GetContent())
	local itemNameLabel = Yague.ShadowedText(name .. ".ItemNameLabel", postFrame)
	local itemStackLabel = Yague.ShadowedText(name .. ".ItemStackLabel", postFrame)
	
	local stackSizeLabel = Yague.ShadowedText(name .. ".StackSizeLabel", postFrame)
	local stackSizeSelector = Yague.Slider(name .. ".StackSizeSelector", postFrame)
	local auctionLimitLabel = Yague.ShadowedText(name .. ".AuctionLimitLabel", postFrame)
	local auctionLimitSelector = Yague.Slider(name .. ".AuctionLimitSelector", postFrame)
	local auctionsLabel = Yague.ShadowedText(name .. ".AuctionsLabel", postFrame)
	local incompleteStackLabel = Yague.ShadowedText(name .. ".IncompleteStackLabel", postFrame)
	local incompleteStackCheck = UI.CreateFrame("RiftCheckbox", name .. ".IncompleteStackCheck", postFrame)
	local durationLabel = Yague.ShadowedText(name .. ".DurationLabel", postFrame)
	local durationSlider = UI.CreateFrame("RiftSlider", name .. ".DurationSlider", postFrame)
	local durationTimeLabel = Yague.ShadowedText(name .. ".DurationTimeLabel", postFrame)
	local pricingModelLabel = Yague.ShadowedText(name .. ".PricingModelLabel", postFrame)
	local pricingModelSelector = Yague.Dropdown(name .. ".PricingModelSelector", postFrame)
	local priceMatchingCheck = UI.CreateFrame("RiftCheckbox", name .. ".PriceMatchingCheck", postFrame)
	local priceMatchingLabel = Yague.ShadowedText(name .. ".PriceMatchingLabel", postFrame)
	local bidLabel = Yague.ShadowedText(name .. ".BidLabel", postFrame)
	local bidMoneySelector = Yague.MoneySelector(name .. ".BidMoneySelector", postFrame)
	local buyLabel = Yague.ShadowedText(name .. ".BuyLabel", postFrame)
	local buyMoneySelector = Yague.MoneySelector(name .. ".BuyMoneySelector", postFrame)
	local bindPricesCheck = UI.CreateFrame("RiftCheckbox", name .. ".BindPricesCheck", postFrame)
	local bindPricesLabel = Yague.ShadowedText(name .. ".BindPricesLabel", postFrame)
	
	local resetButton = UI.CreateFrame("RiftButton", name .. ".ResetButton", postFrame)
	local postButton = UI.CreateFrame("RiftButton", name .. ".PostButton", postFrame)
	local autoPostButton = UI.CreateFrame("Texture", name .. ".AutoPostButton", postFrame)
	
	local auctionsGrid = InternalInterface.UI.ItemAuctionsGrid(name .. ".ItemAuctionsGrid", postFrame)
	
	local noPropagateAuto = false
	local noPropagatePrices = false
	local waitUntil = 0

	local function ItemGridFilter(itemType, itemInfo)
		if itemInfo.adjustedStack <= 0 then return false end
		
		if not InternalInterface.Control.PostController.GetHiddenVisibility() and itemInfo.visibility ~= "Show" then
			return false
		end

		local rarity = itemInfo.rarity and itemInfo.rarity ~= "" and itemInfo.rarity or "common"
		rarity = ({ sellable = 1, common = 2, uncommon = 3, rare = 4, epic = 5, relic = 6, trascendant = 7, quest = 8 })[rarity] or 1
		local minRarity = InternalInterface.AccountSettings.Posting.RarityFilter or 1
		if rarity < minRarity then return false end
		
		local categoryID, filterCategory = categoryFilter:GetSelectedValue()
		if categoryID ~= InternalInterface.Category.BASE_CATEGORY and not filterCategory.filter[itemInfo.category or InternalInterface.Category.BASE_CATEGORY] then return false end

		local filterText = (filterTextField:GetText()):upper()
		local upperName = itemInfo.name:upper()
		if not upperName:find(filterText, 1, true) then return false end
		
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
		local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
		local auctions = auctionsGrid:GetAuctions()
		if auctions and itemInfo then
			local stack = itemInfo.adjustedStack
			local stackSize = stackSizeSelector:GetPosition()
			stackSize = stackSize == "+" and itemInfo.stackMax or stackSize
			local Round = incompleteStackCheck:GetChecked() and math.ceil or math.floor
			local numAuctions = Round(stack / stackSize)
			
			local ownAuctions = 0
			for _, auctionData in pairs(auctions) do
				if auctionData.own then
					ownAuctions = ownAuctions + 1
				end
			end
			
			local queuedAuctions = 0
			for _, postData in pairs(LibPGC.Queue.Detail()) do
				if postData.itemType == itemType then
					queuedAuctions = queuedAuctions + 1
				end
			end
			
			local postAuctions = numAuctions
			local limit = auctionLimitSelector:GetPosition()
			if type(limit) == "number" then
				postAuctions = math.max(math.min(limit - ownAuctions - queuedAuctions, numAuctions), 0)
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
		local _, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
		if itemInfo and itemInfo.sell and value > 0 and value < math.ceil(itemInfo.sell / AH_FEE_MULTIPLIER) then
			return { 1, 0, 0, }
		else
			return { 0, 0, 0, }
		end
	end
	
	local function BuildCategoryFilter()
		local categories = {}

		local baseCategory = InternalInterface.Category.Detail(InternalInterface.Category.BASE_CATEGORY)
		for order, subCategoryID in ipairs(baseCategory.children) do
			categories[subCategoryID] = { name = InternalInterface.Category.Detail(subCategoryID).name, order = order, filter = {}, }
		end

		for categoryID, categoryData in pairs(categories) do
			local pending = { categoryID }
			while #pending > 0 do
				local current = table.remove(pending)
				
				categoryData.filter[current] = true
				
				local children = InternalInterface.Category.Detail(current).children
				if children then
					for _, child in pairs(children) do
						pending[#pending + 1] = child
					end
				end
			end
		end

		categories[InternalInterface.Category.BASE_CATEGORY] = { name = baseCategory.name, order = 0, filter = {}, }
		
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
	maxLeftLabelWidth = math.max(maxLeftLabelWidth, stackSizeLabel:GetWidth())
	maxLeftLabelWidth = math.max(maxLeftLabelWidth, auctionLimitLabel:GetWidth())
	maxLeftLabelWidth = math.max(maxLeftLabelWidth, durationLabel:GetWidth())
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
	maxRightLabelWidth = math.max(maxRightLabelWidth, pricingModelLabel:GetWidth())
	maxRightLabelWidth = math.max(maxRightLabelWidth, bidLabel:GetWidth())
	maxRightLabelWidth = math.max(maxRightLabelWidth, buyLabel:GetWidth())
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
		InternalInterface.Control.PostController.SetSelectedItemType(itemType)
	end
	
	function categoryFilter.Event:SelectionChanged()
		RefreshFilter()
	end
	
	filterTextPanel:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			filterTextField:SetKeyFocus(true)
		end, filterTextPanel:GetName() .. ".OnLeftClick")

	filterTextField:EventAttach(Event.UI.Input.Key.Focus.Gain,
		function()
			local length = (filterTextField:GetText()):len()
			if length > 0 then
				filterTextField:SetSelection(0, length)
			end
		end, filterTextField:GetName() .. ".OnFocusGain")
	
	filterTextField:EventAttach(Event.UI.Textfield.Change,
		function()
			RefreshFilter()
		end, filterTextField:GetName() .. ".OnTextfieldChange")
	
	visibilityIcon:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			InternalInterface.Control.PostController.SetHiddenVisibility(not InternalInterface.Control.PostController.GetHiddenVisibility())
		end, visibilityIcon:GetName() .. ".OnLeftClick")
	
	itemTexture:EventAttach(Event.UI.Input.Mouse.Cursor.In,
		function()
			pcall(Command.Tooltip, (InternalInterface.Control.PostController.GetSelectedItemType()))
		end, itemTexture:GetName() .. ".OnCursorIn")
	
	itemTexture:EventAttach(Event.UI.Input.Mouse.Cursor.Out,
		function()
			Command.Tooltip(nil)
		end, itemTexture:GetName() .. ".OnCursorOut")
	
	function pricingModelSelector.Event:SelectionChanged()
		ApplyPricingModel()
		local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
		if not noPropagateAuto and itemInfo.auto then
			InternalInterface.Control.PostController.ClearItemAuto(itemType)
		end
	end

	priceMatchingCheck:EventAttach(Event.UI.Checkbox.Change,
		function()
			ApplyPricingModel()
			local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
			if not noPropagateAuto and itemInfo.auto then
				InternalInterface.Control.PostController.ClearItemAuto(itemType)
			end
		end, priceMatchingCheck:GetName() .. ".OnCheckboxChange")

	function stackSizeSelector.Event:PositionChanged(position)
		local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
		if not noPropagateAuto and itemInfo.auto then
			InternalInterface.Control.PostController.ClearItemAuto(itemType)
		end
		ResetAuctionLabel()
	end
	
	function auctionLimitSelector.Event:PositionChanged()
		local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
		if not noPropagateAuto and itemInfo.auto then
			InternalInterface.Control.PostController.ClearItemAuto(itemType)
		end
		ResetAuctionLabel()
	end
	
	incompleteStackCheck:EventAttach(Event.UI.Checkbox.Change,
		function()
			local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
			if not noPropagateAuto and itemInfo.auto then
				InternalInterface.Control.PostController.ClearItemAuto(itemType)
			end
			ResetAuctionLabel()
		end, incompleteStackCheck:GetName() .. ".OnCheckboxChange")
	
	function bidMoneySelector.Event:ValueChanged(newValue)
		if not bidMoneySelector:GetEnabled() then return end

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
			local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
			if not noPropagateAuto and itemInfo.auto then
				InternalInterface.Control.PostController.ClearItemAuto(itemType)
			end
		end
	end
	
	function buyMoneySelector.Event:ValueChanged(newValue)
		if not buyMoneySelector:GetEnabled() then return end
		
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
			local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
			if not noPropagateAuto and itemInfo.auto then
				InternalInterface.Control.PostController.ClearItemAuto(itemType)
			end
		end
	end	

	bindPricesCheck:EventAttach(Event.UI.Checkbox.Change,
		function()
			if bindPricesCheck:GetChecked() then
				noPropagatePrices = true
				local maxPrice = math.max(bidMoneySelector:GetValue(), buyMoneySelector:GetValue())
				bidMoneySelector:SetValue(maxPrice)
				buyMoneySelector:SetValue(maxPrice)
				noPropagatePrices = false
			else
				ApplyPricingModel()
			end
			local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
			if not noPropagateAuto and itemInfo.auto then
				InternalInterface.Control.PostController.ClearItemAuto(itemType)
			end
		end, bindPricesCheck:GetName() .. ".OnCheckboxChange")

	durationSlider:EventAttach(Event.UI.Input.Mouse.Wheel.Forward,
		function()
			if durationSlider:GetEnabled() then
				durationSlider:SetPosition(math.min(durationSlider:GetPosition() + 1, 3))
			end
		end, durationSlider:GetName() .. ".OnWheelForward")

	durationSlider:EventAttach(Event.UI.Input.Mouse.Wheel.Back,
		function()
			if durationSlider:GetEnabled() then
				durationSlider:SetPosition(math.max(durationSlider:GetPosition() - 1, 1))
			end
		end, durationSlider:GetName() .. ".OnWheelBack")
	
	durationSlider:EventAttach(Event.UI.Slider.Change,
		function()
			local position = durationSlider:GetPosition()
			durationTimeLabel:SetText(L["Misc/DurationFormat"]:format(6 * 2 ^ position))
			local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
			if not noPropagateAuto and itemInfo.auto then
				InternalInterface.Control.PostController.ClearItemAuto(itemType)
			end
		end, durationSlider:GetName() .. ".OnSliderChange")
	
	resetButton:EventAttach(Event.UI.Button.Left.Press,
		function()
			InternalInterface.Control.PostController.ResetPostingSettings()
			RefreshFilter()
		end, resetButton:GetName() .. ".OnLeftPress")
	
	postButton:EventAttach(Event.UI.Button.Left.Press,
		function()
			if Inspect.Time.Real() < waitUntil then return end
			
			local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
			if not itemType or not itemInfo then return end

			local result = InternalInterface.Control.PostController.PostItem(CollectPostingSettings())
			if type(result) == "string" then
				InternalInterface.Output.Write(L["PostFrame/ErrorPostBase"]:format(result))
			elseif result then
				waitUntil = Inspect.Time.Real() + 0.5
			end
		end, postButton:GetName() .. ".OnLeftPress")
	
	autoPostButton:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
			if not itemType or not itemInfo then return end
			
			if itemInfo.auto then
				InternalInterface.Control.PostController.ClearItemAuto(itemType)
			else
				if not auctionsLabel:GetVisible() then return end
				local result = InternalInterface.Control.PostController.SetItemAuto(itemType, CollectPostingSettings())
				if type(result) == "string" then
					InternalInterface.Output.Write(L["PostFrame/ErrorPostBase"]:format(result))
				end
			end
		end, autoPostButton:GetName() .. ".OnLeftClick")
	
	function auctionsGrid.Event:RowRightClick(auctionID, auctionData)
		if auctionData then
			if auctionData.own then
				bidMoneySelector:SetValue(auctionData.bidUnitPrice or 0)
				if auctionData.buyoutUnitPrice > 0 or not bindPricesCheck:GetChecked() then
					buyMoneySelector:SetValue(auctionData.buyoutUnitPrice)
				end
			else
				local absoluteUndercut = InternalInterface.AccountSettings.Posting.AbsoluteUndercut
				local relativeUndercut = 1 - InternalInterface.AccountSettings.Posting.RelativeUndercut / 100
				
				bidMoneySelector:SetValue(math.max(auctionData.bidUnitPrice * relativeUndercut - absoluteUndercut, 1))
				if auctionData.buyoutUnitPrice > 0 or not bindPricesCheck:GetChecked() then
					buyMoneySelector:SetValue(math.max(auctionData.buyoutUnitPrice * relativeUndercut - absoluteUndercut, auctionData.buyoutUnitPrice > 0 and 1 or 0))
				end
			end
		end
	end
	
	function postFrame:Show()
		InternalInterface.Control.PostController.SetActive(true)
	end
	
	function postFrame:Hide()
		InternalInterface.Control.PostController.SetActive(false)
	end
	
	function postFrame:ItemRightClick(params)
		if params and params.id then
			local ok, itemDetail = pcall(Inspect.Item.Detail, params.id)
			if not ok or not itemDetail or not itemDetail.type then return false end
			local filteredData = itemGrid:GetFilteredData()
			if filteredData[itemDetail.type] then
				itemGrid:SetSelectedKey(itemDetail.type)
			end
			return true
		end
		return false
	end
	
	table.insert(InternalInterface.Control.PostController.ItemListChanged, function(itemList) itemGrid:SetData(itemList, nil, nil, true) end)
	
	local function OnHiddenVisibilityChanged(visible)
		visibilityIcon:SetTextureAsync(addonID, visible and "Textures/ShowIcon.png" or "Textures/HideIcon.png")
		RefreshFilter()
	end
	table.insert(InternalInterface.Control.PostController.HiddenVisibilityChanged, OnHiddenVisibilityChanged)
	table.insert(InternalInterface.Control.PostController.ItemVisibilityChanged, RefreshFilter)
	
	local function OnItemAutoChanged(changedItemType)
		local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
		if itemType == changedItemType and itemInfo then
			autoPostButton:SetTexture(addonID, itemInfo.auto and "Textures/AutoOn.png" or "Textures/AutoOff.png")
		end
		RefreshFilter()
	end
	table.insert(InternalInterface.Control.PostController.ItemAutoChanged, OnItemAutoChanged)

	local function OnSelectedItemTypeChanged(itemType, itemInfo)
		noPropagateAuto = true
		
		stackSizeSelector:ResetPseudoValues()
		auctionLimitSelector:ResetPseudoValues()

		if itemType and itemInfo then
			local itemSettings = InternalInterface.Helper.GetPostingSettings(itemType, itemInfo.category)
		
			itemTexturePanel:GetContent():SetBackgroundColor(InternalInterface.Utility.GetRarityColor(itemInfo.rarity))
			itemTexture:SetTextureAsync("Rift", itemInfo.icon)
			itemTexture:SetVisible(true)
			itemNameLabel:SetText(itemInfo.name)
			itemNameLabel:SetFontColor(InternalInterface.Utility.GetRarityColor(itemInfo.rarity))
			itemNameLabel:SetVisible(true)
			itemStackLabel:SetText(L["PostFrame/LabelItemStack"]:format(itemInfo.adjustedStack))
			itemStackLabel:SetVisible(true)
			
			stackSizeSelector:SetRange(1, itemInfo.stackMax)
			stackSizeSelector:AddPostValue(L["Misc/StackSizeMaxKeyShortcut"], "+", L["Misc/StackSizeMax"])
			local preferredStackSize = itemSettings.stackSize
			if type(preferredStackSize) == "number" then
				preferredStackSize = math.min(preferredStackSize, itemInfo.stackMax)
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
	table.insert(InternalInterface.Control.PostController.SelectedItemTypeChanged, OnSelectedItemTypeChanged)

	local function OnPricesChanged(prices)
		noPropagateAuto = true
	
		local itemType, itemInfo = InternalInterface.Control.PostController.GetSelectedItemType()
		
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

			local itemSettings = InternalInterface.Helper.GetPostingSettings(itemType, itemInfo.category)
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
				InternalInterface.Output.Write(L["PostFrame/ErrorAutoPostModelMissing"])
				InternalInterface.Control.PostController.ClearItemAuto(itemType)
			end
			
			resetButton:SetEnabled(true)
		end
		
		noPropagateAuto = false
	end
	table.insert(InternalInterface.Control.PostController.PricesChanged, OnPricesChanged)
	
	local function OnAuctionsChanged(auctions)
		local itemType = InternalInterface.Control.PostController.GetSelectedItemType()
		if not auctions or not itemType then
			auctionsGrid:SetItemAuctions()
			postButton:SetEnabled(false)
		else
			auctionsGrid:SetItemAuctions(itemType, auctions)
			ResetAuctionLabel()
		end
	end
	table.insert(InternalInterface.Control.PostController.AuctionsChanged, OnAuctionsChanged)
	
	local function OnStackChanged(stack)
		itemStackLabel:SetText(L["PostFrame/LabelItemStack"]:format(stack))
		ResetAuctionLabel()
	end
	table.insert(InternalInterface.Control.PostController.ItemAdjustedStackChanged, OnStackChanged)

	return postFrame
end
