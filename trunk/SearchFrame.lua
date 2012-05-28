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
		itemTexture.itemType = value.itemType
	end
	
	function itemTexture.Event:MouseIn()
		Command.Tooltip(self.itemType)
	end
	
	function itemTexture.Event:MouseOut()
		Command.Tooltip(nil)
	end
	
	return searchCell
end

local function ProfitRenderer(name, parent)
	local renderCell = UI.CreateFrame("Frame", name, parent)
	local bidCell = UI.CreateFrame("BMoneyDisplay", name .. ".BidDisplay", renderCell)
	local buyCell = UI.CreateFrame("BMoneyDisplay", name .. ".BuyDisplay", renderCell)

	bidCell:SetPoint("CENTERLEFT", renderCell, 0, 0.25)
	bidCell:SetPoint("CENTERRIGHT", renderCell, 1, 0.25)
	bidCell:SetHeight(20)
	renderCell.bidCell = bidCell
	
	buyCell:SetPoint("CENTERLEFT", renderCell, 0, 0.75)
	buyCell:SetPoint("CENTERRIGHT", renderCell, 1, 0.75)
	buyCell:SetHeight(20)
	renderCell.buyCell = buyCell
	
	function renderCell:SetValue(key, value, width, extra)
		self:SetWidth(width)
		self.bidCell:SetValue(value.bidProfit or 0)
		self.buyCell:SetValue(value.buyProfit or 0)
	end
	
	return renderCell
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
	local searcherDropdown = UI.CreateFrame("BDropdown", name .. ".SearcherDropdown", searchFrame)
	
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
	local activeSearcherFrame = nil
	
	local function ResetSearchGrid()
		local _, value = searcherDropdown:GetSelectedValue()
		-- TODO Change behavior when online
		if lastSearch then
			local activeAuctions = _G[addonID].SearchAuctions(true, lastSearch.calling, lastSearch.rarity, lastSearch.levelMin, lastSearch.levelMax, lastSearch.category, lastSearch.priceMin, lastSearch.priceMax, lastSearch.name)
			if value and value.filterFunction then activeAuctions = value.filterFunction(activeAuctions, lastSearch) or {} end
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
	
	local function ResetGridAnchor()
		searchAnchor:ClearAll()
		searchAnchor:SetPoint("BOTTOMLEFT", (collapsed or not activeSearcherFrame) and collapseButton or activeSearcherFrame, "BOTTOMLEFT")
		searchGrid:SetRowHeight(searchGrid:GetRowHeight())
		if activeSearcherFrame then activeSearcherFrame:SetVisible(not collapsed) end
	end
	
	local function ResetActiveSearcher()
		if activeSearcherFrame then activeSearcherFrame:SetVisible(false) end
		local _, value = searcherDropdown:GetSelectedValue()
		activeSearcherFrame = value and value.searcherFrame or nil
		-- TODO Show/hide online controls & activate/deactivate the search button
		ResetGridAnchor()
	end
	
	local function ResetSearcherSelector()
		local _, value = searcherDropdown:GetSelectedValue()
		value = value and value.auctionSearcherID or nil

		local lastIndex = nil
		local searchersTable = {}
		local searchers = InternalInterface.PricingModelService.GetAllAuctionSearchers()
		for _, searcher in pairs(searchers) do 
			if searcher.searchFrameConstructor then
				local searcherFrame, prefHeight = searcher.searchFrameConstructor(searchFrame)
				if searcherFrame then
					searcherFrame:SetVisible(false)
					searcherFrame:ClearAll()
					searcherFrame:SetPoint("TOPRIGHT", searchFrame, "TOPRIGHT", -5, 35)
					searcherFrame:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 5, 35)
					searcherFrame:SetHeight(prefHeight or 0)
					searcher.searcherFrame = searcherFrame
				end
			end
			table.insert(searchersTable, searcher)
			if value and searcher.auctionSearcherID == value then lastIndex = #searchersTable end
		end
		
		searcherDropdown:SetValues(searchersTable)
		searcherDropdown:SetSelectedIndex(lastIndex or 1)
		ResetActiveSearcher()
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

	searcherDropdown:SetPoint("TOPRIGHT", searchFrame, "TOPRIGHT", -5, 1)
	searcherDropdown:SetPoint("BOTTOMLEFT", searchFrame, "TOPRIGHT", -255, 34)
	ResetSearcherSelector()
	
	clearButton:SetPoint("CENTERRIGHT", searcherDropdown, "CENTERLEFT", -5, 0)
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
	

	searchAnchor:SetPoint("BOTTOMLEFT", collapseButton, "BOTTOMLEFT")
	
	searchGrid:SetRowHeight(62)
	searchGrid:SetRowMargin(2)
	searchGrid:SetPadding(1, 1, 1, 38)
	searchGrid:SetPoint("TOPLEFT", searchAnchor, "BOTTOMLEFT", 0, 5)
	searchGrid:SetPoint("BOTTOMRIGHT", searchFrame, "BOTTOMRIGHT", -5, -5)
	searchGrid:SetHeadersVisible(true)
	searchGrid:SetUnselectedRowBackgroundColor(0.15, 0.1, 0.1, 1)
	searchGrid:SetSelectedRowBackgroundColor(0.45, 0.3, 0.3, 1)
	-- searchGrid:AddColumn(L["AuctionsPanel/columnItem"], 310, SearchRenderer, function(a, b, direction) local auctions = searchGrid:GetData() return ((auctions[a].itemName < auctions[b].itemName or (auctions[a].itemName == auctions[b].itemName and a < b)) and -1 or 1) * direction <= 0 end)
	-- searchGrid:AddColumn(L["PostingPanel/columnSeller"], 168, "Text", true, "sellerName")
	-- local searchOrderColumn = searchGrid:AddColumn(L["PostingPanel/columnMinExpire"], 100, "Text", true, "minExpireTime", { Alignment = "center", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	-- searchGrid:AddColumn(L["PostingPanel/columnMaxExpire"], 100, "Text", true, "maxExpireTime", { Alignment = "center", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	-- searchGrid:AddColumn(L["PostingPanel/columnBid"], 130, "MoneyRenderer", true, "bidPrice")
	-- searchGrid:AddColumn(L["PostingPanel/columnBuy"], 130, "MoneyRenderer", true, "buyoutPrice")
	-- searchGrid:AddColumn(L["PostingPanel/columnBidPerUnit"], 130, "MoneyRenderer", true, "bidUnitPrice")
	-- searchGrid:AddColumn(L["PostingPanel/columnBuyPerUnit"], 130, "MoneyRenderer", true, "buyoutUnitPrice")
	-- searchGrid:AddColumn(L["AuctionsPanel/columnScore"], 80, "Text", true, "score", { Alignment = "center", Formatter = ScoreValue, Color = ScoreColor })
	searchGrid:AddColumn("", 0, SearchBackgroundRenderer)
	searchGrid:AddColumn(L["AuctionsPanel/columnItem"], 270, SearchRenderer, function(a, b, direction) local auctions = searchGrid:GetData() return ((auctions[a].itemName < auctions[b].itemName or (auctions[a].itemName == auctions[b].itemName and a < b)) and -1 or 1) * direction <= 0 end)
	searchGrid:AddColumn(L["PostingPanel/columnSeller"], 120, "Text", true, "sellerName")
	local searchOrderColumn = searchGrid:AddColumn(L["PostingPanel/columnMinExpire"], 100, "Text", true, "minExpireTime", { Alignment = "center", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	searchGrid:AddColumn(L["PostingPanel/columnMaxExpire"], 100, "Text", true, "maxExpireTime", { Alignment = "center", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	searchGrid:AddColumn(L["PostingPanel/columnBid"], 120, "MoneyRenderer", true, "bidPrice")
	searchGrid:AddColumn(L["PostingPanel/columnBuy"], 120, "MoneyRenderer", true, "buyoutPrice")
	searchGrid:AddColumn(L["PostingPanel/columnBidPerUnit"], 120, "MoneyRenderer", true, "bidUnitPrice")
	searchGrid:AddColumn(L["PostingPanel/columnBuyPerUnit"], 120, "MoneyRenderer", true, "buyoutUnitPrice")
	searchGrid:AddColumn(L["AuctionsPanel/columnScore"], 80, "Text", true, "score", { Alignment = "center", Formatter = ScoreValue, Color = ScoreColor })
	searchGrid:AddColumn("Profit", 120, ProfitRenderer, function(a, b, direction) local auctions = searchGrid:GetData() return (((auctions[a].buyProfit or 0) < (auctions[b].buyProfit or 0) or ((auctions[a].buyProfit or 0) == (auctions[b].buyProfit or 0) and a < b)) and -1 or 1) * direction <= 0 end) -- LOCALIZE
	searchGrid:AddColumn("", 0, SearchBackgroundRenderer)
	searchOrderColumn.Event.LeftClick(searchOrderColumn)
	-- 38 + 40
	
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
		collapsed = not collapsed
		ResetGridAnchor()
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
		local _, value = searcherDropdown:GetSelectedValue()
		if value and value.searchFunction then
			local itemText = itemNameField:GetText()
			lastSearch = value.searchFunction(itemText)
			-- TODO If online, call Command.Auction.Scan
			SetRefreshMode(REFRESH_AUCTIONS)
		end
	end
	
	function clearButton.Event:LeftPress()
		itemNameField:SetText("")
		local _, value = searcherDropdown:GetSelectedValue()
		if value and value.clearFunction then value.clearFunction() end
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
	-- TODO Subscribe to searcheradded event
	
	function searchFrame:Show(hEvent)
		SetRefreshMode(REFRESH_AUCTIONS)
	end
	
	function searcherDropdown.Event:SelectionChanged()
		ResetActiveSearcher()
	end
	

	return searchFrame
end