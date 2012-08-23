-- ***************************************************************************************************************************************************
-- * ItemAuctionsGrid.lua                                                                                                                            *
-- ***************************************************************************************************************************************************
-- * Shows auctions corresponding to a given item and allows purchasing them                                                                         *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.31 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local DataGrid = Yague.DataGrid
local MoneySelector = Yague.MoneySelector
local Panel = Yague.Panel
local ShadowedText = Yague.ShadowedText
local CABid = Command.Auction.Bid
local CAScan = Command.Auction.Scan
local GetActiveAuctionsScored = InternalInterface.PGCExtensions.GetActiveAuctionsScored
local GetAuctionBidCallback = LibPGC.GetAuctionBidCallback
local GetAuctionBuyCallback = LibPGC.GetAuctionBuyCallback
local GetAuctionCached = LibPGC.GetAuctionCached
local GetLastTimeSeen = LibPGC.GetLastTimeSeen
local GetLocalizedDateString = InternalInterface.Utility.GetLocalizedDateString
local IInteraction = Inspect.Interaction
local IIDetail = Inspect.Item.Detail
local L = InternalInterface.Localization.L
local MFloor = math.floor
local MMin = math.min
local RemainingTimeFormatter = InternalInterface.Utility.RemainingTimeFormatter
local SFormat = string.format
local ScoreColorByScore = InternalInterface.UI.ScoreColorByScore
local TInsert = table.insert
local UICreateFrame = UI.CreateFrame
local Write = InternalInterface.Output.Write
local pcall = pcall

function InternalInterface.UI.ItemAuctionsGrid(name, parent)
	local itemAuctionsGrid = DataGrid(name, parent)
	
	local controlFrame = UICreateFrame("Frame", name .. ".ControlFrame", itemAuctionsGrid:GetContent())
	local buyButton = UICreateFrame("RiftButton", name .. ".BuyButton", controlFrame)
	local bidButton = UICreateFrame("RiftButton", name .. ".BidButton", controlFrame)
	local auctionMoneySelector = MoneySelector(name .. ".AuctionMoneySelector", controlFrame)
	local noBidLabel = ShadowedText(name .. ".NoBidLabel", controlFrame)
	local refreshPanel = Panel(name .. ".RefreshPanel", controlFrame)
	local refreshButton = UICreateFrame("Texture", name .. ".RefreshButton", refreshPanel:GetContent())
	local refreshText = UICreateFrame("Text", name .. ".RefreshLabel", refreshPanel:GetContent())	
	
	local itemType = nil
	local controlEnabled = false
	local refreshEnabled = false
	
	local function RefreshAuctionButtons()
		local auctionSelected = false
		local auctionInteraction = IInteraction("auction")
		local selectedAuctionCached = false
		local selectedAuctionBid = false
		local selectedAuctionBuy = false
		local highestBidder = false
		local seller = false
		local bidPrice = 1
		
		local selectedAuctionID, selectedAuctionData = itemAuctionsGrid:GetSelectedData()
		if selectedAuctionID and selectedAuctionData then
			auctionSelected = true
			selectedAuctionCached = GetAuctionCached(selectedAuctionID) or false
			selectedAuctionBid = not selectedAuctionData.buyoutPrice or selectedAuctionData.bidPrice < selectedAuctionData.buyoutPrice
			selectedAuctionBuyout = selectedAuctionData.buyoutPrice and true or false
			highestBidder = (selectedAuctionData.ownBidded or 0) == selectedAuctionData.bidPrice
			seller = selectedAuctionData.own
			bidPrice = selectedAuctionData.bidPrice
		end
		
		refreshEnabled = auctionInteraction
		refreshButton:SetTextureAsync(addonID, refreshEnabled and "Textures/RefreshMiniOff.png" or "Textures/RefreshMiniDisabled.png")
		bidButton:SetEnabled(auctionSelected and auctionInteraction and selectedAuctionCached and selectedAuctionBid and not highestBidder and not seller)
		buyButton:SetEnabled(auctionSelected and auctionInteraction and selectedAuctionCached and selectedAuctionBuyout and not seller)

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
		if itemType then
			local function GetAuctionsCallback(auctions)
				itemAuctionsGrid:SetData(auctions, firstKey)
				local lastTimeSeen = GetLastTimeSeen(itemType)
				if lastTimeSeen then
					refreshText:SetText(SFormat(L["ItemAuctionsGrid/LastUpdateMessage"], GetLocalizedDateString(L["ItemAuctionsGrid/LastUpdateDateFormat"], lastTimeSeen)))
				else
					refreshText:SetText(SFormat(L["ItemAuctionsGrid/LastUpdateMessage"], L["ItemAuctionsGrid/LastUpdateDateFallback"]))
				end				
				RefreshAuctionButtons()
			end
			GetActiveAuctionsScored(GetAuctionsCallback, itemType)
		else
			itemAuctionsGrid:SetData({})
			refreshText:SetText(SFormat(L["ItemAuctionsGrid/LastUpdateMessage"], L["ItemAuctionsGrid/LastUpdateDateFallback"]))
			RefreshAuctionButtons()
		end
	end
	
	local function ScoreValue(value)
		if not value then return "" end
		return MFloor(MMin(value, 999)) .. " %"
	end

	local function ScoreColor(value)
		local r, g, b = unpack(ScoreColorByScore(value))
		return { r, g, b, 0.1 }
	end		
	
	itemAuctionsGrid:SetPadding(1, 1, 1, 38)
	itemAuctionsGrid:SetHeadersVisible(true)
	itemAuctionsGrid:SetRowHeight(20)
	itemAuctionsGrid:SetRowMargin(0)
	itemAuctionsGrid:SetUnselectedRowBackgroundColor({0.2, 0.2, 0.2, 0.25}) -- TODO Change to use function
	itemAuctionsGrid:SetSelectedRowBackgroundColor({0.6, 0.6, 0.6, 0.25}) -- TODO Change to use function
	itemAuctionsGrid:AddColumn("cached", nil, "AuctionCachedCellType", 20, 0)
	itemAuctionsGrid:AddColumn("seller", L["ItemAuctionsGrid/ColumnSeller"], "Text", 140, 2, "sellerName", true, { Alignment = "left", Formatter = "none" })
	itemAuctionsGrid:AddColumn("stack", L["ItemAuctionsGrid/ColumnStack"], "Text", 60, 1, "stack", true, { Alignment = "center", Formatter = "none" })
	itemAuctionsGrid:AddColumn("bid", L["ItemAuctionsGrid/ColumnBid"], "MoneyCellType", 130, 1, "bidPrice", true)
	itemAuctionsGrid:AddColumn("buy", L["ItemAuctionsGrid/ColumnBuy"], "MoneyCellType", 130, 1, "buyoutPrice", true)
	itemAuctionsGrid:AddColumn("unitbid", L["ItemAuctionsGrid/ColumnBidPerUnit"], "MoneyCellType", 130, 1, "bidUnitPrice", true)
	itemAuctionsGrid:AddColumn("unitbuy", L["ItemAuctionsGrid/ColumnBuyPerUnit"], "MoneyCellType", 130, 1, "buyoutUnitPrice", true)
	itemAuctionsGrid:AddColumn("minexpire", L["ItemAuctionsGrid/ColumnMinExpire"], "Text", 90, 1, "minExpireTime", true, { Alignment = "right", Formatter = RemainingTimeFormatter })
	itemAuctionsGrid:AddColumn("maxexpire", L["ItemAuctionsGrid/ColumnMaxExpire"], "Text", 90, 1, "maxExpireTime", true, { Alignment = "right", Formatter = RemainingTimeFormatter })
	itemAuctionsGrid:AddColumn("score", L["ItemAuctionsGrid/ColumnScore"], "Text", 60, 0, "score", true, { Alignment = "right", Formatter = ScoreValue, Color = ScoreColor })
	itemAuctionsGrid:AddColumn("background", nil, "ItemAuctionBackgroundCellType", 0, 0, "score", false, { Color = ScoreColor }) -- TODO Remove
	itemAuctionsGrid:SetOrder("unitbuy", false)
	
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
	refreshText:SetText(SFormat(L["ItemAuctionsGrid/LastUpdateMessage"], L["ItemAuctionsGrid/LastUpdateDateFallback"]))

	
	
	function itemAuctionsGrid.Event:SelectionChanged(auctionID, auctionData)
		RefreshAuctionButtons()
	end	
	
	function buyButton.Event:LeftPress()
		local auctionID, auctionData = itemAuctionsGrid:GetSelectedData()
		if auctionID then
			CABid(auctionID, auctionData.buyoutPrice, GetAuctionBuyCallback(auctionID))
		end
	end
	
	function bidButton.Event:LeftPress()
		local auctionID = itemAuctionsGrid:GetSelectedData()
		if auctionID then
			local bidAmount = auctionMoneySelector:GetValue()
			CABid(auctionID, bidAmount, GetAuctionBidCallback(auctionID, bidAmount))
		end
	end
	
	function refreshButton.Event:MouseIn()
		self:SetTextureAsync(addonID, refreshEnabled and "Textures/RefreshMiniOn.png" or "Textures/RefreshMiniDisabled.png")
	end
	
	function refreshButton.Event:MouseOut()
		self:SetTextureAsync(addonID, refreshEnabled and "Textures/RefreshMiniOff.png" or "Textures/RefreshMiniDisabled.png")
	end

	function refreshButton.Event:LeftClick()
		if not refreshEnabled or not itemType then return end
		
		local ok, itemInfo = pcall(IIDetail, itemType)
		if not ok or not itemInfo then return end
		
		if not pcall(CAScan, { type = "search", index = 0, text = itemInfo.name, rarity = itemInfo.rarity or "common", category = itemInfo.category, sort = "time", sortOrder = "descending" }) then
			Write(L["ItemAuctionsGrid/ItemScanError"])
		else
			Write(L["ItemAuctionsGrid/ItemScanStarted"])
		end				
	end

	local function OnAuctionData(scanType, totalAuctions, newAuctions, updatedAuctions, removedAuctions, beforeExpireAuctions, totalItemTypes, newItemTypes, updatedItemTypes, removedItemTypes, modifiedItemTypes)
		if totalItemTypes[itemType] then
			ResetAuctions()
		end
	end
	TInsert(Event.LibPGC.AuctionData, { OnAuctionData, addonID, addonID .. ".ItemAuctionsGrid.OnAuctionData" })
	
	local function OnInteraction(interaction)
		if controlEnabled and interaction == "auction" then
			RefreshAuctionButtons()
		end
	end
	TInsert(Event.Interaction, { OnInteraction, addonID, addonID .. ".ItemAuctionsGrid.OnInteraction" })
	
	
	
	function itemAuctionsGrid:SetEnabled(enabled)
		local mustReset = not controlEnabled and enabled and true or false
		controlEnabled = enabled
		if mustReset then
			ResetAuctions()
		end
	end
	
	function itemAuctionsGrid:SetItemType(newItemType, firstKey)
		if itemType ~= newItemType then
			itemType = newItemType
			if controlEnabled then
				ResetAuctions(firstKey)
			end
		end
	end
	
	return itemAuctionsGrid
end
