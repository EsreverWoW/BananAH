local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local REFRESH_MINE = 4
local REFRESH_MINEFILTER = 3
local REFRESH_AUCTIONS = 2
local REFRESH_AUCTION = 1
local REFRESH_NONE = 0

local L = InternalInterface.Localization.L
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local GetOutput = InternalInterface.Utility.GetOutput
local function out(value) GetOutput()(value) end

local function MineItemRenderer(name, parent)
	local mineCell = UI.CreateFrame("Mask", name, parent)
	local itemTextureBackground = UI.CreateFrame("Frame", name .. ".ItemTextureBackground", mineCell)
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = UI.CreateFrame("BShadowedText", name .. ".ItemNameLabel", mineCell)
	
	itemTextureBackground:SetPoint("CENTERLEFT", mineCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	mineCell.itemTextureBackground = itemTextureBackground
	
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	mineCell.itemTexture = itemTexture
	
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("TOPLEFT", itemTextureBackground, "TOPRIGHT", 4, 0)
	mineCell.itemNameLabel = itemNameLabel
	
	function mineCell:SetValue(key, value, width, extra)
		self:SetWidth(width)
		self.itemTextureBackground:SetBackgroundColor(GetRarityColor(value.itemRarity))
		self.itemTexture:SetTexture("Rift", value.itemIcon)
		local name = value.itemName .. (value.stack > 1 and " (" .. value.stack .. ")" or "")
		self.itemNameLabel:SetText(name)
		self.itemNameLabel:SetFontColor(GetRarityColor(value.itemRarity))
	end
	
	return mineCell
end

local function CancellableRenderer(name, parent)
	local cell = UI.CreateFrame("Frame", name, parent)
	local cancellableCell = UI.CreateFrame("Texture", name .. ".Texture", cell)
	
	cancellableCell:SetPoint("CENTER", cell, "CENTER")
	cancellableCell:SetWidth(24)
	cancellableCell:SetHeight(24)
	cancellableCell:SetTexture(addonID, "Textures/DeleteDisabled.png")

	function cell:SetValue(key, value, width, extra)
		cancellableCell:SetValue(key, value, width, extra)
	end
	
	function cancellableCell:SetValue(key, value, width, extra)
		self.auctionID = key
		self.usable = _G[addonID].GetAuctionCached(key) and value.sellerName == Inspect.Unit.Detail("player").name and Inspect.Interaction("auction")
		self:SetTexture(addonID, self.usable and "Textures/DeleteEnabled.png" or "Textures/DeleteDisabled.png")
	end
	
	function cancellableCell.Event:LeftClick()
		if not self.usable then return end
		out("To avoid cancelling auctions by accident, you need to right click on the button to cancel the auction. You can change this behavior in the Config tab.") -- LOCALIZE
		cell:GetParent().Event.LeftClick(cell:GetParent())
	end
	
	function cancellableCell.Event:RightClick()
		if not self.usable or not self.auctionID then return end
		Command.Auction.Cancel(self.auctionID, function(...) InternalInterface.AHMonitoringService.AuctionCancelCallback(self.auctionID, ...) end)
		cell:GetParent().Event.LeftClick(cell:GetParent())
	end
	
	return cell
end

local function MineBackgroundRenderer(name, parent)
	local backgroundCell = UI.CreateFrame("Texture", name, parent)
	
	backgroundCell:SetTexture(addonID, "Textures/AuctionRowBackground.png")
	
	function backgroundCell:SetValue(key, value, width, extra)
		self:ClearAll()
		self:SetAllPoints()
		self:SetLayer(self:GetParent():GetLayer() - 1)
	end
	
	return backgroundCell
end

function InternalInterface.UI.AuctionsFrame(name, parent)
	local auctionsFrame = UI.CreateFrame("Frame", name, parent)
	
	local mineGrid = UI.CreateFrame("BDataGrid", name .. ".MineGrid", auctionsFrame)
	
	local collapseButton = UI.CreateFrame("Texture", name .. ".CollapseButton", auctionsFrame)
	local filterTextPanel = UI.CreateFrame("BPanel", name .. ".FilterTextPanel", auctionsFrame)
	local filterTextField = UI.CreateFrame("RiftTextfield", name .. ".FilterTextField", filterTextPanel:GetContent())

	local filterFrame = UI.CreateFrame("Frame", name .. ".FilterFrame", auctionsFrame)
	local filterCharacterCheck = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterTextField", filterFrame)
	local filterCharacterText = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterTextField", filterFrame)
	local filterCompetitionText = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterTextField", filterFrame)
	local filterCompetitionSelector = UI.CreateFrame("BDropdown", filterFrame:GetName() .. ".FilterTextField", filterFrame)
	local filterBelowText = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterTextField", filterFrame)
	local filterBelowSlider = UI.CreateFrame("BSlider", filterFrame:GetName() .. ".FilterTextField", filterFrame)
	local filterScorePanel = UI.CreateFrame("BPanel", filterFrame:GetName() .. ".FilterTextField", filterFrame)
	local filterScoreTitle = UI.CreateFrame("BShadowedText", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	local filterScoreNilCheck = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	local filterScoreNilText = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	local filterScore1Check = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	local filterScore1Text = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	local filterScore2Check = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	local filterScore2Text = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	local filterScore3Check = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	local filterScore3Text = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	local filterScore4Check = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	local filterScore4Text = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	local filterScore5Check = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	local filterScore5Text = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterTextField", filterScorePanel:GetContent())
	
	local auctionGrid = UI.CreateFrame("BDataGrid", name .. ".AuctionGrid", auctionsFrame)
	local controlFrame = UI.CreateFrame("Frame", name .. ".ControlFrame", auctionGrid.externalPanel:GetContent())
	local buyButton = UI.CreateFrame("RiftButton", name .. ".BuyButton", controlFrame)
	local bidButton = UI.CreateFrame("RiftButton", name .. ".BidButton", controlFrame)
	local auctionMoneySelector = UI.CreateFrame("BMoneySelector", name .. ".AuctionMoneySelector", controlFrame)
	local noBidLabel = UI.CreateFrame("BShadowedText", name .. ".NoBidLabel", controlFrame)
	local refreshPanel = UI.CreateFrame("BPanel", name .. ".RefreshPanel", controlFrame)
	local refreshButton = UI.CreateFrame("Texture", name .. ".RefreshButton", refreshPanel:GetContent())
	local refreshText = UI.CreateFrame("Text", name .. ".RefreshLabel", refreshPanel:GetContent())
	

	local prices = {}
	local collapsed = true
	local refreshMode = REFRESH_NONE
	local refreshTask
	local itemPrices = {}
	
	local function ResetMineGrid()
		local ownAuctions = _G[addonID].GetActiveAuctionData()
		local auctionsByItem = {}
		prices = {}
		for auctionID, auctionData in pairs(ownAuctions) do
			if not auctionData.own then 
				ownAuctions[auctionID] = nil 
			else
				if not prices[auctionData.itemType] then
					prices[auctionData.itemType] = _G[addonID].GetPricings(auctionData.itemType)
				end
				if auctionData.buyoutUnitPrice then
					ownAuctions[auctionID].score =  _G[addonID].ScorePrice(auctionData.itemType, auctionData.buyoutUnitPrice, prices[auctionData.itemType])
					auctionsByItem[auctionData.itemType] = auctionsByItem[auctionData.itemType] or {}
					table.insert(auctionsByItem[auctionData.itemType], auctionID)
				end
			end 
		end
		
		for itemType, auctions in pairs(auctionsByItem) do
			local itemAuctions = _G[addonID].GetActiveAuctionData(itemType)
			for _, auctionID in ipairs(auctions) do
				local buy = ownAuctions[auctionID].buyoutUnitPrice
				local below, above, total = 0, 0, 1
				for itemAuctionID, itemAuctionData in pairs(itemAuctions) do
					if itemAuctionData.buyoutUnitPrice and not itemAuctionData.own then
						local itemBuy = itemAuctionData.buyoutUnitPrice
						if buy < itemBuy then 
							above = above + 1
						elseif buy > itemBuy then 
							below = below + 1
						end
						total = total + 1
					end
				end
				ownAuctions[auctionID].below = below
				ownAuctions[auctionID].above = above
				ownAuctions[auctionID].quintile = math.floor(below * 5 / total) + 1
			end
		end
		mineGrid:SetData(ownAuctions)
	end

	local function ResetAuctionGrid()
		local auctions = {}
		local mineID, mineData = mineGrid:GetSelectedData()
		if mineData then
			auctions = _G[addonID].GetActiveAuctionData(mineData.itemType)
			for auctionID, auctionData in pairs(auctions) do
				auctions[auctionID].score = _G[addonID].ScorePrice(auctionData.itemType, auctionData.buyoutUnitPrice, prices[auctionData.itemType])
			end
		end
		auctionGrid:SetData(auctions)	
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
			noBidLabel:SetText(L["PostingPanel/bidErrorNoAuction"]) -- RELOCALIZE?
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not selectedAuctionCached then
			noBidLabel:SetText(L["PostingPanel/bidErrorNotCached"]) -- RELOCALIZE?
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not selectedAuctionBid then
			noBidLabel:SetText(L["PostingPanel/bidErrorBidEqualBuy"]) -- RELOCALIZE?
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif seller then
			noBidLabel:SetText(L["PostingPanel/bidErrorSeller"]) -- RELOCALIZE?
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif highestBidder then
			noBidLabel:SetText(L["PostingPanel/bidErrorHighestBidder"]) -- RELOCALIZE?
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not auctionInteraction then
			noBidLabel:SetText(L["PostingPanel/bidErrorNoAuctionHouse"]) -- RELOCALIZE?
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
		if not auctionsFrame:GetVisible() then return end
	
		if refreshMode >= REFRESH_MINE then
			ResetMineGrid()
		end
		
		if refreshMode == REFRESH_MINEFILTER then -- If ResetMineGrid was called, it isn't necessary to force update
			mineGrid:ForceUpdate()
		end
		
		if refreshMode >= REFRESH_AUCTIONS then
			ResetAuctionGrid(item)
		end

		if refreshMode >= REFRESH_AUCTION then
			RefreshAuctionButtons()
		end

		refreshMode = REFRESH_NONE
		if refreshTask then Library.LibCron.pause(refreshTask) end
	end
	refreshTask = Library.LibCron.new(addonID, 0, true, true, DoRefresh)
	Library.LibCron.pause(refreshTask)
	
	local function MineGridFilter(key, value)
		if (value.below or 0) < filterBelowSlider:GetPosition() then return false end
	
		if (value.quintile or 1) < filterCompetitionSelector:GetSelectedValue() then return false end

		if filterCharacterCheck:GetChecked() and value.sellerName ~= Inspect.Unit.Detail("player").name then return false end

		local scoreIndex = InternalInterface.UI.ScoreIndexByScore(value.score) or 0
		if scoreIndex == 0 and not filterScoreNilCheck:GetChecked() then return false
		elseif scoreIndex == 1 and not filterScore1Check:GetChecked() then return false
		elseif scoreIndex == 2 and not filterScore2Check:GetChecked() then return false
		elseif scoreIndex == 3 and not filterScore3Check:GetChecked() then return false
		elseif scoreIndex == 4 and not filterScore4Check:GetChecked() then return false
		elseif scoreIndex == 5 and not filterScore5Check:GetChecked() then return false
		end

		local filterText = string.upper(filterTextField:GetText())
		local upperName = string.upper(value.itemName)
		if not string.find(upperName, filterText) then return false end

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
	
	local function CompetitionString(value)
		if not value.below or not value.quintile then return "" end
		local quintileNames = { "Weak", "Moderate", "Intense", "Strong", "Fierce" } -- LOCALIZE
		return string.format("%s (%d)", quintileNames[value.quintile], value.below)
	end
	
	local function CompetitionOrder(a, b, direction)
		local auctions = mineGrid:GetData()
		local ret = ((auctions[a].quintile or 0) - (auctions[b].quintile or 0)) * direction
		if ret == 0 then ret = ((auctions[a].below or 0) - (auctions[b].below or 0)) * direction end
		return ret < 0 or (ret == 0 and a < b)
	end
	
	mineGrid:SetRowHeight(62)
	mineGrid:SetRowMargin(2)
	mineGrid:SetPoint("TOPLEFT", auctionsFrame, "TOPLEFT", 5, 5)
	mineGrid:SetPoint("TOPRIGHT", auctionsFrame, "TOPRIGHT", -5, 5)
	mineGrid:SetHeight(589)
	mineGrid:SetHeadersVisible(true)
	mineGrid:SetUnselectedRowBackgroundColor(0.15, 0.1, 0.1, 1)
	mineGrid:SetSelectedRowBackgroundColor(0.45, 0.3, 0.3, 1)
	mineGrid:AddColumn("Item", 310, MineItemRenderer, function(a, b, direction) local auctions = mineGrid:GetData() return (auctions[a].itemName < auctions[b].itemName and -1 or 1) * direction <= 0 end) -- LOCALIZE
	local mineOrderColumn = mineGrid:AddColumn(L["PostingPanel/columnMinExpire"], 100, "Text", true, "minExpireTime", { Alignment = "center", Formatter = InternalInterface.Utility.RemainingTimeFormatter }) -- RELOCALIZE?
	mineGrid:AddColumn(L["PostingPanel/columnMaxExpire"], 100, "Text", true, "maxExpireTime", { Alignment = "center", Formatter = InternalInterface.Utility.RemainingTimeFormatter }) -- RELOCALIZE?
	mineGrid:AddColumn(L["PostingPanel/columnBid"], 130, "MoneyRenderer", true, "bidPrice") -- RELOCALIZE?
	mineGrid:AddColumn(L["PostingPanel/columnBuy"], 130, "MoneyRenderer", true, "buyoutPrice") -- RELOCALIZE?
	mineGrid:AddColumn(L["PostingPanel/columnBidPerUnit"], 130, "MoneyRenderer", true, "bidUnitPrice") -- RELOCALIZE?
	mineGrid:AddColumn(L["PostingPanel/columnBuyPerUnit"], 130, "MoneyRenderer", true, "buyoutUnitPrice") -- RELOCALIZE?
	mineGrid:AddColumn("Score", 80, "Text", true, "score", { Alignment = "center", Formatter = ScoreValue, Color = ScoreColor }) -- LOCALIZE
	mineGrid:AddColumn("Competition", 120, "Text", CompetitionOrder, nil, { Alignment = "center", Formatter = CompetitionString }) -- LOCALIZE
	mineGrid:AddColumn("", 48, CancellableRenderer)
	mineGrid:AddColumn("", 0, MineBackgroundRenderer)
	mineGrid:SetFilteringFunction(MineGridFilter)		
	mineOrderColumn.Event.LeftClick(mineOrderColumn)

	collapseButton:SetPoint("BOTTOMLEFT", auctionsFrame, "BOTTOMLEFT", 5, -5)
	collapseButton:SetTexture(addonID, "Textures/FilterShow.png")

	filterTextPanel:SetPoint("CENTERLEFT", collapseButton, "CENTERRIGHT", 5, 0)
	filterTextPanel:SetPoint("BOTTOMRIGHT", auctionsFrame, "BOTTOMRIGHT", -5, -3)
	filterTextPanel:SetInvertedBorder(true)
	filterTextPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	filterTextField:SetPoint("CENTERLEFT", filterTextPanel:GetContent(), "CENTERLEFT", 2, 1)
	filterTextField:SetPoint("CENTERRIGHT", filterTextPanel:GetContent(), "CENTERRIGHT", -2, 1)
	filterTextField:SetText("")
	
	auctionGrid:SetPoint("TOPLEFT", auctionsFrame, "TOPLEFT", 300, 335)
	auctionGrid:SetPoint("BOTTOMRIGHT", auctionsFrame, "BOTTOMRIGHT", -5, -40)
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
	local auctionOrderColumn = auctionGrid:AddColumn(L["PostingPanel/columnBuyPerUnit"], 130, "MoneyRenderer", true, "buyoutUnitPrice")
	auctionGrid:AddColumn(L["PostingPanel/columnMinExpire"], 90, "Text", true, "minExpireTime", { Alignment = "right", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	auctionGrid:AddColumn(L["PostingPanel/columnMaxExpire"], 90, "Text", true, "maxExpireTime", { Alignment = "right", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	auctionGrid:AddColumn("Score", 60, "Text", true, "score", { Alignment = "right", Formatter = ScoreValue, Color = ScoreColor }) -- LOCALIZE
	auctionGrid:AddColumn("", 0, "AuctionRenderer", false, "score", { Color = ScoreColor })
	auctionOrderColumn.Event.LeftClick(auctionOrderColumn)
	auctionGrid:SetVisible(false)
	
	local paddingLeft, _, paddingRight, paddingBottom = auctionGrid:GetPadding()
	controlFrame:SetPoint("TOPLEFT", auctionGrid.externalPanel:GetContent(), "BOTTOMLEFT", paddingLeft + 2, 2 - paddingBottom)
	controlFrame:SetPoint("BOTTOMRIGHT", auctionGrid.externalPanel:GetContent(), "BOTTOMRIGHT", -paddingRight - 2, -2)

	buyButton:SetPoint("CENTERRIGHT", controlFrame, "CENTERRIGHT", 0, 0)
	buyButton:SetText(L["PostingPanel/buttonBuy"]) -- RELOCALIZE?
	buyButton:SetEnabled(false)

	bidButton:SetPoint("CENTERRIGHT", buyButton, "CENTERLEFT", 10, 0)
	bidButton:SetText(L["PostingPanel/buttonBid"]) -- RELOCALIZE?
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

	refreshText:SetText(L["PostingPanel/lastUpdateMessage"] .. L["PostingPanel/lastUpdateDateFallback"]) -- RELOCALIZE?
	refreshText:SetPoint("CENTERLEFT", refreshButton, "CENTERRIGHT", 6, 0)	
	
	filterFrame:SetPoint("TOPLEFT", auctionsFrame, "TOPLEFT", 5, 335)
	filterFrame:SetPoint("BOTTOMRIGHT", auctionsFrame, "BOTTOMLEFT", 295, -40)
	filterFrame:SetVisible(false)

	filterCharacterCheck:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 5, 15)
	
	filterCharacterText:SetPoint("CENTERLEFT", filterCharacterCheck, "CENTERRIGHT", 5, 0)
	filterCharacterText:SetText("Show only auctions posted by this character") -- LOCALIZE
	
	filterCompetitionText:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 5, 60)
	filterCompetitionText:SetText("Min. Competition:") -- LOCALIZE
	
	filterCompetitionSelector:SetPoint("CENTERLEFT", filterCompetitionText, "CENTERRIGHT", 5, 0)
	filterCompetitionSelector:SetPoint("TOPRIGHT", filterFrame, "TOPRIGHT", 0, 53)
	filterCompetitionSelector:SetValues({
		{ displayName = "Weak", }, -- LOCALIZE
		{ displayName = "Moderate", }, -- LOCALIZE
		{ displayName = "Intense", }, -- LOCALIZE
		{ displayName = "Strong", }, -- LOCALIZE
		{ displayName = "Fierce", }, -- LOCALIZE
	})
	filterCompetitionSelector:SetSelectedIndex(1)
	
	filterBelowText:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 5, 110)
	filterBelowText:SetText("Min. Below:") -- LOCALIZE
	
	filterBelowSlider:SetPoint("CENTERLEFT", filterBelowText, "CENTERRIGHT", 5, 0)
	filterBelowSlider:SetPoint("CENTERRIGHT", filterFrame, "TOPRIGHT", 0, 125)
	filterBelowSlider:SetRange(0, 20)
	
	filterScorePanel:SetPoint("TOPLEFT", filterFrame, "BOTTOMLEFT", 0, -100)
	filterScorePanel:SetPoint("BOTTOMRIGHT", filterFrame, "BOTTOMRIGHT", 0, 0)
	
	filterScoreTitle:SetPoint("TOPCENTER", filterScorePanel:GetContent(), "TOPCENTER", 0, 5)
	filterScoreTitle:SetText("SCORE FILTER")
	filterScoreTitle:SetFontSize(14)
	filterScoreTitle:SetFontSize(14)
	filterScoreTitle:SetFontColor(1, 1, 0.75, 1)
	filterScoreTitle:SetShadowOffset(2, 2)	
	
	filterScoreNilCheck:SetPoint("TOPLEFT", filterScorePanel:GetContent(), "TOPLEFT", 5, 30)
	filterScoreNilCheck:SetChecked(true)
	filterScore2Check:SetPoint("TOPLEFT", filterScorePanel:GetContent(), "TOPLEFT", 5, 50)
	filterScore2Check:SetChecked(true)
	filterScore1Check:SetPoint("TOPLEFT", filterScorePanel:GetContent(), "TOPLEFT", 5, 70)
	filterScore1Check:SetChecked(true)
	filterScore3Check:SetPoint("TOPLEFT", filterScorePanel:GetContent(), "TOPCENTER", 5, 30)
	filterScore3Check:SetChecked(true)
	filterScore4Check:SetPoint("TOPLEFT", filterScorePanel:GetContent(), "TOPCENTER", 5, 50)
	filterScore4Check:SetChecked(true)
	filterScore5Check:SetPoint("TOPLEFT", filterScorePanel:GetContent(), "TOPCENTER", 5, 70)
	filterScore5Check:SetChecked(true)
	
	filterScoreNilText:SetPoint("CENTERLEFT", filterScoreNilCheck, "CENTERRIGHT", 5, 0)
	filterScoreNilText:SetText("No score") -- LOCALIZE
	filterScore1Text:SetPoint("CENTERLEFT", filterScore1Check, "CENTERRIGHT", 5, 0)
	filterScore1Text:SetText("Very low") -- LOCALIZE
	filterScore2Text:SetPoint("CENTERLEFT", filterScore2Check, "CENTERRIGHT", 5, 0)
	filterScore2Text:SetText("Low") -- LOCALIZE
	filterScore3Text:SetPoint("CENTERLEFT", filterScore3Check, "CENTERRIGHT", 5, 0)
	filterScore3Text:SetText("Medium") -- LOCALIZE
	filterScore4Text:SetPoint("CENTERLEFT", filterScore4Check, "CENTERRIGHT", 5, 0)
	filterScore4Text:SetText("High") -- LOCALIZE
	filterScore5Text:SetPoint("CENTERLEFT", filterScore5Check, "CENTERRIGHT", 5, 0)
	filterScore5Text:SetText("Very high") -- LOCALIZE

	function mineGrid.Event:SelectionChanged()
		SetRefreshMode(REFRESH_AUCTIONS)
	end
	
	function collapseButton.Event:LeftClick()
		auctionGrid:SetVisible(collapsed)
		filterFrame:SetVisible(collapsed)
		collapsed = not collapsed
		mineGrid:SetHeight(collapsed and 589 or 320)
		mineGrid:SetRowHeight(mineGrid:GetRowHeight())
		self:SetTexture(addonID, collapsed and "Textures/FilterShow.png" or "Textures/FilterHide.png") -- LOCALIZE
	end
	
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
		
		local mineID, mineInfo = mineGrid:GetSelectedData()
		if not mineID then return end
		
		if not pcall(Command.Auction.Scan, { type = "search", index = 0, text = mineInfo.itemName, sort = "time", sortOrder = "descending" }) then
			out(L["PostingPanel/itemScanError"]) -- RELOCALIZE?
		else
			InternalInterface.ScanNext()
			out(L["PostingPanel/itemScanStarted"]) -- RELOCALIZE?
		end				
	end

	function auctionGrid.Event:SelectionChanged(auctionID, auctionData)
		SetRefreshMode(REFRESH_AUCTION)
	end
	
	local function UpdateMineGrid() SetRefreshMode(REFRESH_MINEFILTER) end
	
	filterTextField.Event.TextfieldChange = UpdateMineGrid
	filterCharacterCheck.Event.CheckboxChange = UpdateMineGrid
	filterCompetitionSelector.Event.SelectionChanged = UpdateMineGrid
	filterBelowSlider.Event.PositionChanged = UpdateMineGrid
	filterScoreNilCheck.Event.CheckboxChange = UpdateMineGrid
	filterScore1Check.Event.CheckboxChange = UpdateMineGrid
	filterScore2Check.Event.CheckboxChange = UpdateMineGrid
	filterScore3Check.Event.CheckboxChange = UpdateMineGrid
	filterScore4Check.Event.CheckboxChange = UpdateMineGrid
	filterScore5Check.Event.CheckboxChange = UpdateMineGrid
	table.insert(Event.Interaction, { function(interaction) if interaction == "auction" then UpdateMineGrid() end end, addonID, "AuctionsFrame.OnInteraction" })
	
	table.insert(Event[addonID].AuctionData, { function() SetRefreshMode(REFRESH_MINE) end, addonID, "AuctionsFrame.OnAuctionData" })
	
	function auctionsFrame:Show(hEvent)
		pcall(Command.Auction.Scan, { type = "mine" })
		SetRefreshMode(REFRESH_MINE)
	end	

	return auctionsFrame
end