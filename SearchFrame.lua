local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local REFRESH_AUCTIONS = 2
local REFRESH_AUCTION = 1
local REFRESH_NONE = 0

local L = InternalInterface.Localization.L
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local GetOutput = InternalInterface.Utility.GetOutput
local function out(value) GetOutput()(value) end

local function SearchRenderer(name, parent)
	local searchCell = UI.CreateFrame("Mask", name, parent)
	local itemTextureBackground = UI.CreateFrame("Frame", name .. ".ItemTextureBackground", searchCell)
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = UI.CreateFrame("BShadowedText", name .. ".ItemNameLabel", searchCell)
	
	itemTextureBackground:SetPoint("CENTERLEFT", searchCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	searchCell.itemTextureBackground = itemTextureBackground
	
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	searchCell.itemTexture = itemTexture
	
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("TOPLEFT", itemTextureBackground, "TOPRIGHT", 4, 0)
	searchCell.itemNameLabel = itemNameLabel
	
	function searchCell:SetValue(key, value, width, extra)
		self:SetWidth(width)
		self.itemTextureBackground:SetBackgroundColor(GetRarityColor(value.itemRarity))
		self.itemTexture:SetTexture("Rift", value.itemIcon)
		local name = value.itemName .. (value.stack > 1 and " (" .. value.stack .. ")" or "")
		self.itemNameLabel:SetText(name)
		self.itemNameLabel:SetFontColor(GetRarityColor(value.itemRarity))
	end
	
	return searchCell
end

local function SearchBackgroundRenderer(name, parent)
	local backgroundCell = UI.CreateFrame("Texture", name, parent)
	
	backgroundCell:SetTexture(addonID, "Textures/AuctionRowBackground.png")
	
	function backgroundCell:SetValue(key, value, width, extra)
		self:ClearAll()
		self:SetAllPoints()
		self:SetLayer(self:GetParent():GetLayer() - 1)
	end
	
	return backgroundCell
end

function InternalInterface.UI.SearchFrame(name, parent)
	local searchFrame = UI.CreateFrame("Frame", name, parent)
	
	local collapseButton = UI.CreateFrame("Texture", name .. ".CollapseButton", searchFrame)
	local itemNamePanel = UI.CreateFrame("BPanel", name .. ".ItemNamePanel", searchFrame)
	local itemNameField = UI.CreateFrame("RiftTextfield", name .. ".ItemNameField", itemNamePanel:GetContent())
	local searchButton = UI.CreateFrame("RiftButton", name .. ".SearchButton", searchFrame)
	local clearButton = UI.CreateFrame("RiftButton", name .. ".ClearButton", searchFrame)
	
	local filterFrame = UI.CreateFrame("Frame", name .. ".FilterFrame", searchFrame)
	local callingsText = UI.CreateFrame("Text", filterFrame:GetName() .. ".CallingsText", filterFrame)
	local rarityText = UI.CreateFrame("Text", filterFrame:GetName() .. ".RarityText", filterFrame)
	local categoryText = UI.CreateFrame("Text", filterFrame:GetName() .. ".CategoryText", filterFrame)
	local usableText = UI.CreateFrame("Text", filterFrame:GetName() .. ".UsableText", filterFrame)
	local minLevelText = UI.CreateFrame("Text", filterFrame:GetName() .. ".MinLevelText", filterFrame)
	local maxLevelText = UI.CreateFrame("Text", filterFrame:GetName() .. ".MaxLevelText", filterFrame)
	local minPriceText = UI.CreateFrame("Text", filterFrame:GetName() .. ".MinPriceText", filterFrame)
	local maxPriceText = UI.CreateFrame("Text", filterFrame:GetName() .. ".MaxPriceText", filterFrame)
	local searcherText = UI.CreateFrame("Text", filterFrame:GetName() .. ".SearcherText", filterFrame)
	local callingsDropdown = UI.CreateFrame("BDropdown", filterFrame:GetName() .. ".CallingsDropdown", filterFrame)
	local rarityDropdown = UI.CreateFrame("BDropdown", filterFrame:GetName() .. ".RarityDropdown", filterFrame)
	local categoryDropdown = UI.CreateFrame("BDropdown", filterFrame:GetName() .. ".CategoryDropdown", filterFrame)
	local searcherDropdown = UI.CreateFrame("BDropdown", filterFrame:GetName() .. ".SearcherDropdown", filterFrame)
	local minPriceSelector = UI.CreateFrame("BMoneySelector", filterFrame:GetName() .. ".MinPriceSelector", filterFrame)
	local maxPriceSelector = UI.CreateFrame("BMoneySelector", filterFrame:GetName() .. ".MaxPriceSelector", filterFrame)
	local usableCheck = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".UsableCheck", filterFrame)

	local searchAnchor = UI.CreateFrame("Frame", name .. ".SearchAnchor", searchFrame)
	local searchGrid = UI.CreateFrame("BDataGrid", name .. ".SearchGrid", searchFrame)
	local controlFrame = UI.CreateFrame("Frame", name .. ".ControlFrame", searchGrid.externalPanel:GetContent())
	local trackButton = UI.CreateFrame("RiftButton", name .. ".TrackButton", controlFrame)
	local favoriteButton = UI.CreateFrame("RiftButton", name .. ".FavoriteButton", controlFrame)
	local buyButton = UI.CreateFrame("RiftButton", name .. ".BuyButton", controlFrame)
	local bidButton = UI.CreateFrame("RiftButton", name .. ".BidButton", controlFrame)
	local auctionMoneySelector = UI.CreateFrame("BMoneySelector", name .. ".AuctionMoneySelector", controlFrame)
	local noBidLabel = UI.CreateFrame("BShadowedText", name .. ".NoBidLabel", controlFrame)
	
	local prices = {}
	local collapsed = true
	local lastSearch = nil
	local refreshMode = REFRESH_NONE
	local refreshTask
	
	local function ResetSearchGrid()
		if lastSearch then
			local activeAuctions = _G[addonID].SearchAuctions(true, lastSearch.calling, lastSearch.rarity, lastSearch.levelMin, lastSearch.levelMax, lastSearch.category, lastSearch.priceMin, lastSearch.priceMax, lastSearch.name)
			prices = {}
			for auctionID, auctionData in pairs(activeAuctions) do
				if not prices[auctionData.itemType] then
					prices[auctionData.itemType] = _G[addonID].GetPricings(auctionData.itemType)
				end
				if auctionData.buyoutUnitPrice then
					activeAuctions[auctionID].score =  _G[addonID].ScorePrice(auctionData.itemType, auctionData.buyoutUnitPrice, prices[auctionData.itemType])
				end
			end
			searchGrid:SetData(activeAuctions)
		else
			searchGrid:SetData(nil)
		end
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
		
		local selectedAuctionID, selectedAuctionData = searchGrid:GetSelectedData()
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
	
	local function SetRefreshMode(mode)
		if mode > REFRESH_NONE and refreshMode <= REFRESH_NONE and refreshTask then
			Library.LibCron.resume(refreshTask)
		end
		refreshMode = math.max(mode, refreshMode)
	end

	local function DoRefresh()
		if not searchFrame:GetVisible() then return end
	
		if refreshMode >= REFRESH_AUCTIONS then
			ResetSearchGrid()
		end
		
		if refreshMode >= REFRESH_AUCTION then
			RefreshAuctionButtons()
		end

		refreshMode = REFRESH_NONE
		if refreshTask then Library.LibCron.pause(refreshTask) end
	end
	refreshTask = Library.LibCron.new(addonID, 0, true, true, DoRefresh)
	Library.LibCron.pause(refreshTask)	
	
	local function SearchGridFilter(key, value)
		-- local filterText = string.upper(itemNameField:GetText())
		-- local upperName = string.upper(value.itemName)
		-- if not string.find(upperName, filterText) then return false end

		return true
	end
	
	local function ScoreValue(value)
		if not value then return "" end
		return math.floor(value) .. " %"
	end
	
	local function ScoreColor(value)
		local r, g, b = unpack(InternalInterface.UI.ScoreColorByScore(value))
		return { r, g, b, 0.1 }
	end

	collapseButton:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 5, 5)
	collapseButton:SetTexture(addonID, "Textures/FilterHide.png")

	clearButton:SetPoint("TOPRIGHT", searchFrame, "TOPRIGHT", -5, 0)
	clearButton:SetText("Clear") -- LOCALIZE
	
	searchButton:SetPoint("TOPRIGHT", clearButton, "TOPLEFT", 10, 0)
	searchButton:SetText("Search") -- LOCALIZE
	
	itemNamePanel:SetPoint("CENTERLEFT", collapseButton, "CENTERRIGHT", 5, 0)
	itemNamePanel:SetPoint("TOPRIGHT", searchButton, "TOPLEFT", -5, 3)
	itemNamePanel:SetInvertedBorder(true)
	itemNamePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	itemNameField:SetPoint("CENTERLEFT", itemNamePanel:GetContent(), "CENTERLEFT", 2, 1)
	itemNameField:SetPoint("CENTERRIGHT", itemNamePanel:GetContent(), "CENTERRIGHT", -2, 1)
	itemNameField:SetText("")
	
	filterFrame:SetPoint("TOPRIGHT", searchFrame, "TOPRIGHT", -5, 35)
	filterFrame:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 5, 35)
	filterFrame:SetHeight(80)
	filterFrame:SetVisible(false)
	
	callingsText:SetPoint("CENTERLEFT", filterFrame, 0, 0.25)
	callingsText:SetText("Calling:") -- LOCALIZE
	
	rarityText:SetPoint("CENTERLEFT", filterFrame, 0.25, 0.25)
	rarityText:SetText("Min. rarity:") -- LOCALIZE
	
	categoryText:SetPoint("CENTERLEFT", filterFrame, 0.5, 0.25)
	categoryText:SetText("Category:") -- LOCALIZE

	usableCheck:SetPoint("CENTERRIGHT", filterFrame, 1, 0.25)
	usableCheck:SetEnabled(false)
	
	usableText:SetPoint("CENTERRIGHT", usableCheck, "CENTERLEFT", -5, 0)
	usableText:SetText("Usable only") -- LOCALIZE
	
	minLevelText:SetPoint("CENTERLEFT", filterFrame, 0, 0.75)
	minLevelText:SetText("Min. level:") -- LOCALIZE
	
	maxLevelText:SetPoint("CENTERLEFT", filterFrame, 0.125, 0.75)
	maxLevelText:SetText("Max. level:") -- LOCALIZE
	
	minPriceText:SetPoint("CENTERLEFT", filterFrame, 0.25, 0.75)
	minPriceText:SetText("Min. price:") -- LOCALIZE
	
	maxPriceText:SetPoint("CENTERLEFT", filterFrame, 0.5, 0.75)
	maxPriceText:SetText("Max. price:") -- LOCALIZE
	
	searcherText:SetPoint("CENTERLEFT", filterFrame, 0.75, 0.75)
	searcherText:SetText("Searcher:") -- LOCALIZE
	
	local align2Offset = math.max(rarityText:GetWidth(), minPriceText:GetWidth())
	local align3Offset = math.max(categoryText:GetWidth(), maxPriceText:GetWidth())
	
	callingsDropdown:SetPoint("CENTERLEFT", callingsText, "CENTERRIGHT", 5, 0)
	callingsDropdown:SetPoint("CENTERRIGHT", rarityText, "CENTERLEFT", -5, 0)
	callingsDropdown:SetHeight(34)
	callingsDropdown:SetValues({
		{ displayName = "All", calling = nil }, -- LOCALIZE
		{ displayName = "Warrior", calling = "warrior" }, -- LOCALIZE
		{ displayName = "Cleric", calling = "cleric" }, -- LOCALIZE
		{ displayName = "Rogue", calling = "rogue" }, -- LOCALIZE
		{ displayName = "Mage", calling = "mage" }, -- LOCALIZE
	})

	rarityDropdown:SetPoint("CENTERLEFT", rarityText, "CENTERLEFT", align2Offset + 5, 0)
	rarityDropdown:SetPoint("CENTERRIGHT", categoryText, "CENTERLEFT", -5, 0)
	rarityDropdown:SetHeight(34)
	rarityDropdown:SetValues({
		{ displayName = L["General/Rarity1"], rarity = "sellable", },
		{ displayName = L["General/Rarity2"], rarity = "", },
		{ displayName = L["General/Rarity3"], rarity = "uncommon", },
		{ displayName = L["General/Rarity4"], rarity = "rare", },
		{ displayName = L["General/Rarity5"], rarity = "epic", },
		{ displayName = L["General/Rarity6"], rarity = "relic", },
		{ displayName = L["General/Rarity7"], rarity = "transcendant", },
		{ displayName = L["General/Rarity0"], rarity = "quest", },
	})
	

	categoryDropdown:SetPoint("CENTERLEFT", categoryText, "CENTERLEFT", align3Offset + 5, 0)
	categoryDropdown:SetPoint("CENTERRIGHT", filterFrame, 0.875, 0.25)
	categoryDropdown:SetHeight(34)

	searcherDropdown:SetPoint("CENTERLEFT", searcherText, "CENTERRIGHT", 5, 0)
	searcherDropdown:SetPoint("CENTERRIGHT", filterFrame, 1, 0.75)
	searcherDropdown:SetHeight(34)
	searcherDropdown:SetValues({
		{ displayName = "Basic", searcher = nil }, -- TODO Take name & id from searchers
	})

	minPriceSelector:SetPoint("CENTERLEFT", minPriceText, "CENTERLEFT", align2Offset + 5, 0)
	minPriceSelector:SetPoint("CENTERRIGHT", maxPriceText, "CENTERLEFT", -5, 0)
	minPriceSelector:SetHeight(34)
	
	maxPriceSelector:SetPoint("CENTERLEFT", maxPriceText, "CENTERLEFT", align3Offset + 5, 0)
	maxPriceSelector:SetPoint("CENTERRIGHT", searcherText, "CENTERLEFT", -5, 0)
	maxPriceSelector:SetHeight(34)

	searchAnchor:SetPoint("BOTTOMLEFT", collapseButton, "BOTTOMLEFT")
	
	searchGrid:SetRowHeight(62)
	searchGrid:SetRowMargin(2)
	searchGrid:SetPadding(1, 1, 1, 38)
	searchGrid:SetPoint("TOPLEFT", searchAnchor, "BOTTOMLEFT", 0, 5)
	searchGrid:SetPoint("BOTTOMRIGHT", searchFrame, "BOTTOMRIGHT", -5, -5)
	searchGrid:SetHeadersVisible(true)
	searchGrid:SetUnselectedRowBackgroundColor(0.15, 0.1, 0.1, 1)
	searchGrid:SetSelectedRowBackgroundColor(0.45, 0.3, 0.3, 1)
	searchGrid:AddColumn(L["AuctionsPanel/columnItem"], 310, SearchRenderer, function(a, b, direction) local auctions = searchGrid:GetData() return ((auctions[a].itemName < auctions[b].itemName or (auctions[a].itemName == auctions[b].itemName and a < b)) and -1 or 1) * direction <= 0 end)
	searchGrid:AddColumn(L["PostingPanel/columnSeller"], 168, "Text", true, "sellerName")
	local searchOrderColumn = searchGrid:AddColumn(L["PostingPanel/columnMinExpire"], 100, "Text", true, "minExpireTime", { Alignment = "center", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	searchGrid:AddColumn(L["PostingPanel/columnMaxExpire"], 100, "Text", true, "maxExpireTime", { Alignment = "center", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	searchGrid:AddColumn(L["PostingPanel/columnBid"], 130, "MoneyRenderer", true, "bidPrice")
	searchGrid:AddColumn(L["PostingPanel/columnBuy"], 130, "MoneyRenderer", true, "buyoutPrice")
	searchGrid:AddColumn(L["PostingPanel/columnBidPerUnit"], 130, "MoneyRenderer", true, "bidUnitPrice")
	searchGrid:AddColumn(L["PostingPanel/columnBuyPerUnit"], 130, "MoneyRenderer", true, "buyoutUnitPrice")
	searchGrid:AddColumn(L["AuctionsPanel/columnScore"], 80, "Text", true, "score", { Alignment = "center", Formatter = ScoreValue, Color = ScoreColor })
	searchGrid:AddColumn("", 0, SearchBackgroundRenderer)
	searchGrid:SetFilteringFunction(SearchGridFilter)		
	searchOrderColumn.Event.LeftClick(searchOrderColumn)
	
	paddingLeft, _, paddingRight, paddingBottom = searchGrid:GetPadding()
	controlFrame:SetPoint("TOPLEFT", searchGrid.externalPanel:GetContent(), "BOTTOMLEFT", paddingLeft + 2, 2 - paddingBottom)
	controlFrame:SetPoint("BOTTOMRIGHT", searchGrid.externalPanel:GetContent(), "BOTTOMRIGHT", -paddingRight - 2, -2)

	trackButton:SetPoint("CENTERLEFT", controlFrame, "CENTERLEFT", 0, 0)
	trackButton:SetText("Track auction") -- LOCALIZE
	trackButton:SetEnabled(false)

	favoriteButton:SetPoint("CENTERLEFT", trackButton, "CENTERRIGHT", -10, 0)
	favoriteButton:SetText("Favorite price")
	favoriteButton:SetEnabled(false)

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
	
	function collapseButton.Event:LeftClick()
		filterFrame:SetVisible(collapsed)
		collapsed = not collapsed
		searchAnchor:ClearAll()
		searchAnchor:SetPoint("BOTTOMLEFT", collapsed and collapseButton or filterFrame, "BOTTOMLEFT")
		searchGrid:SetRowHeight(searchGrid:GetRowHeight())
		self:SetTexture(addonID, collapsed and "Textures/FilterHide.png" or "Textures/FilterShow.png")
	end
	
	function itemNamePanel.Event:LeftClick()
		itemNameField:SetKeyFocus(true)
	end

	function itemNameField.Event:KeyFocusGain()
		local length = string.len(self:GetText())
		if length > 0 then
			self:SetSelection(0, length)
		end
	end
	
	function itemNameField.Event:KeyUp(key)
		if key == "\13" and searchButton:GetEnabled() then
			searchButton.Event.LeftPress(searchButton)
		end
	end
	
	function searchButton.Event:LeftPress()
		local _, calling = callingsDropdown:GetSelectedValue()
		local _, rarity = rarityDropdown:GetSelectedValue()
		local priceMin = minPriceSelector:GetValue()
		local priceMax = maxPriceSelector:GetValue()
		priceMin = priceMin > 0 and priceMin or nil
		priceMax = priceMax > 0 and priceMax or nil
		if priceMin and priceMax and priceMin > priceMax then
			priceMin = nil
			minPriceSelector:SetValue(0)
		end
		
		lastSearch = 
		{
			calling = calling.calling,
			rarity = rarity.rarity,
			levelMin = nil,
			levelMax = nil,
			category = nil,
			priceMin = priceMin,
			priceMax = priceMax,
			name = itemNameField:GetText()
		}
		SetRefreshMode(REFRESH_AUCTIONS)
	end
	
	function clearButton.Event:LeftPress()
		itemNameField:SetText("")
		callingsDropdown:SetSelectedIndex(1)
		rarityDropdown:SetSelectedIndex(1)
		--categoryDropdown:SetSelectedIndex(1)
		minPriceSelector:SetValue(0)
		maxPriceSelector:SetValue(0)
	end
	
	function searchGrid.Event:SelectionChanged()
		SetRefreshMode(REFRESH_AUCTION)
	end
	
	function buyButton.Event:LeftPress()
		local auctionID, auctionData = searchGrid:GetSelectedData()
		if auctionID then
			Command.Auction.Bid(auctionID, auctionData.buyoutPrice, function(...) InternalInterface.AHMonitoringService.AuctionBuyCallback(auctionID, ...) end)
		end
	end
	
	function bidButton.Event:LeftPress()
		local auctionID = searchGrid:GetSelectedData()
		if auctionID then
			local bidAmount = auctionMoneySelector:GetValue()
			Command.Auction.Bid(auctionID, bidAmount, function(...) InternalInterface.AHMonitoringService.AuctionBidCallback(auctionID, bidAmount, ...) end)
		end
	end
	
	table.insert(Event[addonID].AuctionData, { function() SetRefreshMode(REFRESH_AUCTIONS) end, addonID, "SearchFrame.OnAuctionData" })
	table.insert(Event.Interaction, { function(interaction) if interaction == "auction" then SetRefreshMode(REFRESH_AUCTION) end end, addonID, "SearchFrame.OnInteraction" })
	
	function searchFrame:Show(hEvent)
		SetRefreshMode(REFRESH_AUCTIONS)
	end	
	

	return searchFrame
end