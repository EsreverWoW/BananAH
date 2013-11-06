-- ***************************************************************************************************************************************************
-- * ItemAuctionsGrid.lua                                                                                                                            *
-- ***************************************************************************************************************************************************
-- * 0.4.4 / 2013.02.09 / Baanano: Reworked                                                                                                          *
-- * 0.4.1 / 2012.07.31 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

function InternalInterface.UI.ItemAuctionsGrid(name, parent)
	local itemAuctionsGrid = Yague.DataGrid(name, parent)
	
	local controlFrame = UI.CreateFrame("Frame", name .. ".ControlFrame", itemAuctionsGrid:GetContent())
	local buyButton = UI.CreateFrame("RiftButton", name .. ".BuyButton", controlFrame)
	local bidButton = UI.CreateFrame("RiftButton", name .. ".BidButton", controlFrame)
	local auctionMoneySelector = Yague.MoneySelector(name .. ".AuctionMoneySelector", controlFrame)
	local noBidLabel = Yague.ShadowedText(name .. ".NoBidLabel", controlFrame)
	local refreshPanel = Yague.Panel(name .. ".RefreshPanel", controlFrame)
	local refreshButton = UI.CreateFrame("Texture", name .. ".RefreshButton", refreshPanel:GetContent())
	local refreshText = UI.CreateFrame("Text", name .. ".RefreshLabel", refreshPanel:GetContent())
	
	local itemType = nil
	local auctions = nil
	local refreshEnabled = false
	
	local function RefreshAuctionButtons()
		local auctionSelected = false
		local auctionInteraction = Inspect.Interaction("auction")
		local selectedAuctionCached = false
		local selectedAuctionBid = false
		local selectedAuctionBuy = false
		local highestBidder = false
		local seller = false
		local bidPrice = 1
		
		local selectedAuctionID, selectedAuctionData = itemAuctionsGrid:GetSelectedData()
		if selectedAuctionID and selectedAuctionData then
			auctionSelected = true
			selectedAuctionCached = selectedAuctionData.cached
			selectedAuctionBid = selectedAuctionData.buyoutPrice == 0 or selectedAuctionData.bidPrice < selectedAuctionData.buyoutPrice
			selectedAuctionBuy = selectedAuctionData.buyoutPrice > 0 and true or false
			highestBidder = (selectedAuctionData.ownBidded or 0) == selectedAuctionData.bidPrice
			seller = selectedAuctionData.own
			bidPrice = selectedAuctionData.bidPrice
		end
		
		refreshEnabled = auctionInteraction and itemType and true or false
		refreshButton:SetTextureAsync(addonID, refreshEnabled and "Textures/RefreshMiniOff.png" or "Textures/RefreshMiniDisabled.png")
		bidButton:SetEnabled(auctionSelected and auctionInteraction and selectedAuctionCached and selectedAuctionBid and not highestBidder and not seller)
		buyButton:SetEnabled(auctionSelected and auctionInteraction and selectedAuctionCached and selectedAuctionBuy and not seller)

		if not auctionSelected then
			noBidLabel:SetText(L["ItemAuctionsGrid/ErrorNoAuction"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not selectedAuctionCached then
			noBidLabel:SetText(L["ItemAuctionsGrid/ErrorNotCached"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif seller then
			noBidLabel:SetText(L["ItemAuctionsGrid/ErrorSeller"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif highestBidder then
			noBidLabel:SetText(L["ItemAuctionsGrid/ErrorHighestBidder"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not auctionInteraction then
			noBidLabel:SetText(L["ItemAuctionsGrid/ErrorNoAuctionHouse"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not selectedAuctionBid then
			noBidLabel:SetText(L["ItemAuctionsGrid/ErrorBidEqualBuy"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		else
			auctionMoneySelector:SetValue(bidPrice + 1)
			auctionMoneySelector:SetVisible(true)
			noBidLabel:SetVisible(false)
		end	
	end
	
	local function ResetAuctions(firstKey)
		itemAuctionsGrid:SetData(nil, nil, nil, true)
		RefreshAuctionButtons()
		
		if itemType then
			local lastTimeSeen = LibPGC.Item.LastTimeSeen(itemType)
			if lastTimeSeen then
				refreshText:SetText(L["ItemAuctionsGrid/LastUpdateMessage"]:format(InternalInterface.Utility.GetLocalizedDateString(L["ItemAuctionsGrid/LastUpdateDateFormat"], lastTimeSeen)))
			else
				refreshText:SetText(L["ItemAuctionsGrid/LastUpdateMessage"]:format(L["ItemAuctionsGrid/LastUpdateDateFallback"]))
			end				
			
			itemAuctionsGrid:SetData(auctions, firstKey, RefreshAuctionButtons)
		else
			refreshText:SetText(L["ItemAuctionsGrid/LastUpdateMessage"]:format(L["ItemAuctionsGrid/LastUpdateDateFallback"]))
		end
	end
	
	local function ScoreValue(value)
		if not value then return "" end
		return math.floor(math.min(value, 999)) .. " %"
	end

	local function ScoreColor(value)
		local r, g, b = unpack(InternalInterface.UI.ScoreColorByScore(value))
		return { r, g, b, 0.1 }
	end		
	
	itemAuctionsGrid:SetPadding(1, 1, 1, 38)
	itemAuctionsGrid:SetHeadersVisible(true)
	itemAuctionsGrid:SetRowHeight(20)
	itemAuctionsGrid:SetRowMargin(0)
	itemAuctionsGrid:SetUnselectedRowBackgroundColor({0.2, 0.2, 0.2, 0.25})
	itemAuctionsGrid:SetSelectedRowBackgroundColor({0.6, 0.6, 0.6, 0.25})
	itemAuctionsGrid:AddColumn("cached", nil, "AuctionCachedCellType", 20, 0)
	itemAuctionsGrid:AddColumn("seller", L["ItemAuctionsGrid/ColumnSeller"], "Text", 140, 2, "sellerName", true, { Alignment = "left", Formatter = "none" })
	itemAuctionsGrid:AddColumn("stack", L["ItemAuctionsGrid/ColumnStack"], "Text", 60, 1, "stack", true, { Alignment = "center", Formatter = "none" })
	itemAuctionsGrid:AddColumn("bid", L["ItemAuctionsGrid/ColumnBid"], "MoneyCellType", 130, 1, "bidPrice", true)
	itemAuctionsGrid:AddColumn("buy", L["ItemAuctionsGrid/ColumnBuy"], "MoneyCellType", 130, 1, "buyoutPrice", true)
	itemAuctionsGrid:AddColumn("unitbid", L["ItemAuctionsGrid/ColumnBidPerUnit"], "MoneyCellType", 130, 1, "bidUnitPrice", true)
	itemAuctionsGrid:AddColumn("unitbuy", L["ItemAuctionsGrid/ColumnBuyPerUnit"], "MoneyCellType", 130, 1, "buyoutUnitPrice", true)
	itemAuctionsGrid:AddColumn("minexpire", L["ItemAuctionsGrid/ColumnMinExpire"], "Text", 90, 1, "minExpireTime", true, { Alignment = "right", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	itemAuctionsGrid:AddColumn("maxexpire", L["ItemAuctionsGrid/ColumnMaxExpire"], "Text", 90, 1, "maxExpireTime", true, { Alignment = "right", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	itemAuctionsGrid:AddColumn("score", L["ItemAuctionsGrid/ColumnScore"], "Text", 60, 0, "score", true, { Alignment = "right", Formatter = ScoreValue, Color = ScoreColor })
	itemAuctionsGrid:AddColumn("background", nil, "ItemAuctionBackgroundCellType", 0, 0, "score", false, { Color = ScoreColor })
	itemAuctionsGrid:SetOrder("unitbuy", false)
	itemAuctionsGrid:GetInternalContent():SetBackgroundColor(0.05, 0, 0.05, 0.25)
	
	controlFrame:SetPoint("TOPLEFT", itemAuctionsGrid:GetContent(), "BOTTOMLEFT", 3, -36)
	controlFrame:SetPoint("BOTTOMRIGHT", itemAuctionsGrid:GetContent(), "BOTTOMRIGHT", -3, -2)
	
	buyButton:SetPoint("CENTERRIGHT", controlFrame, "CENTERRIGHT", 0, 0)
	buyButton:SetText(L["ItemAuctionsGrid/ButtonBuy"])
	buyButton:SetEnabled(false)

	bidButton:SetPoint("CENTERRIGHT", buyButton, "CENTERLEFT", 10, 0)
	bidButton:SetText(L["ItemAuctionsGrid/ButtonBid"])
	bidButton:SetEnabled(false)
	
	auctionMoneySelector:SetPoint("TOPRIGHT", bidButton, "TOPLEFT", -5, 2)
	auctionMoneySelector:SetPoint("BOTTOMLEFT", bidButton, "BOTTOMLEFT", -230, -2)
	auctionMoneySelector:SetVisible(false)
	
	noBidLabel:SetPoint("CENTER", bidButton, "CENTERLEFT", -115, 0)
	noBidLabel:SetFontSize(14)
	noBidLabel:SetFontColor(1, 0.5, 0, 1)
	noBidLabel:SetShadowColor(0.05, 0, 0.1, 1)
	noBidLabel:SetShadowOffset(2, 2)

	refreshPanel:SetPoint("BOTTOMLEFT", controlFrame, "BOTTOMLEFT", 0, -2)
	refreshPanel:SetPoint("TOPRIGHT", bidButton, "TOPLEFT", -235, 2)
	refreshPanel:SetInvertedBorder(true)
	refreshPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)

	refreshButton:SetTextureAsync(addonID, "Textures/RefreshMiniDisabled.png")
	refreshButton:SetPoint("TOPLEFT", refreshPanel:GetContent(), "TOPLEFT", 2, 1)
	refreshButton:SetPoint("BOTTOMRIGHT", refreshPanel:GetContent(), "BOTTOMLEFT", 22, -1)

	refreshText:SetPoint("CENTERLEFT", refreshPanel:GetContent(), "CENTERLEFT", 28, 0)	
	refreshText:SetText(L["ItemAuctionsGrid/LastUpdateMessage"]:format(L["ItemAuctionsGrid/LastUpdateDateFallback"]))
	
	function itemAuctionsGrid.Event:SelectionChanged(auctionID, auctionData)
		RefreshAuctionButtons()
	end	
	
	buyButton:EventAttach(Event.UI.Button.Left.Press,
		function()
			local auctionID, auctionData = itemAuctionsGrid:GetSelectedData()
			if auctionID then
				Command.Auction.Bid(auctionID, auctionData.buyoutPrice, LibPGC.Callback.Buy(auctionID))
			end
		end, buyButton:GetName() .. ".OnLeftPress")
	
	bidButton:EventAttach(Event.UI.Button.Left.Press,
		function()
			local auctionID = itemAuctionsGrid:GetSelectedData()
			if auctionID then
				local bidAmount = auctionMoneySelector:GetValue()
				Command.Auction.Bid(auctionID, bidAmount, LibPGC.Callback.Bid(auctionID, bidAmount))
			end
		end, bidButton:GetName() .. ".OnLeftPress")
	
	refreshButton:EventAttach(Event.UI.Input.Mouse.Cursor.In,
		function()
			refreshButton:SetTextureAsync(addonID, refreshEnabled and "Textures/RefreshMiniOn.png" or "Textures/RefreshMiniDisabled.png")
		end, refreshButton:GetName() .. ".OnCursorIn")
	
	refreshButton:EventAttach(Event.UI.Input.Mouse.Cursor.Out,
		function()
			refreshButton:SetTextureAsync(addonID, refreshEnabled and "Textures/RefreshMiniOff.png" or "Textures/RefreshMiniDisabled.png")
		end, refreshButton:GetName() .. ".OnCursorOut")

	refreshButton:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			if not refreshEnabled or not itemType then return end
			
			local ok, itemInfo = pcall(Inspect.Item.Detail, itemType)
			if not ok or not itemInfo then return end
			
			if not pcall(Command.Auction.Scan, { type = "search", index = 0, text = itemInfo.name, rarity = itemInfo.rarity or "common", category = itemInfo.category, sort = "time", sortOrder = "descending" }) then
				InternalInterface.Output.Write(L["ItemAuctionsGrid/ItemScanError"])
			else
				InternalInterface.Output.Write(L["ItemAuctionsGrid/ItemScanStarted"])
			end				
		end, refreshButton:GetName() .. ".OnLeftClick")
	
	local function OnInteraction(h, interaction)
		if interaction == "auction" then
			RefreshAuctionButtons()
		end
	end
	Command.Event.Attach(Event.Interaction, OnInteraction, addonID .. ".ItemAuctionsGrid.OnInteraction")
	
	function itemAuctionsGrid:GetItemType()
		return itemType
	end
	
	function itemAuctionsGrid:GetAuctions()
		return auctions
	end
	
	function itemAuctionsGrid:SetItemAuctions(newItemType, newAuctions, firstKey)
		itemType = newItemType
		auctions = newAuctions
		ResetAuctions(firstKey)
	end
	
	return itemAuctionsGrid
end
