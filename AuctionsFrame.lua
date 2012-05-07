local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L
local GetRarityColor = InternalInterface.Utility.GetRarityColor

local function MineItemRenderer(name, parent)
	local mineCell = UI.CreateFrame("Mask", name, parent)
	local itemTextureBackground = UI.CreateFrame("Frame", name .. ".ItemTextureBackground", mineCell)
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = UI.CreateFrame("BShadowedText", name .. ".ItemNameLabel", mineCell)
	local itemStackLabel = UI.CreateFrame("Text", name .. ".ItemStackLabel", mineCell)
	
	itemTextureBackground:SetPoint("CENTERLEFT", mineCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	mineCell.itemTextureBackground = itemTextureBackground
	
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	mineCell.itemTexture = itemTexture
	
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("CENTERLEFT", itemTextureBackground, "CENTERRIGHT", 4, 0)
	mineCell.itemNameLabel = itemNameLabel
	
	itemStackLabel:SetPoint("BOTTOMRIGHT", itemTexture, "BOTTOMRIGHT", 0, 1)
	itemStackLabel:SetLayer(50)
	mineCell.itemStackLabel = itemStackLabel
	
	function mineCell:SetValue(key, value, width, extra)
		self:SetWidth(290)
		self.itemTextureBackground:SetBackgroundColor(GetRarityColor(value.itemRarity))
		self.itemTexture:SetTexture("Rift", value.itemIcon)
		self.itemNameLabel:SetText(value.itemName)
		self.itemNameLabel:SetFontColor(GetRarityColor(value.itemRarity))
		self.itemStackLabel:SetText(value.stack > 1 and tostring(value.stack) or "")
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
		self:SetTexture(addonID, _G[addonID].GetAuctionCached(key) and value.sellerName == Inspect.Unit.Detail("player").name and "Textures/DeleteEnabled.png" or "Textures/DeleteDisabled.png")
	end
	
	return cell
end

function InternalInterface.UI.AuctionsFrame(name, parent)
	local auctionsFrame = UI.CreateFrame("Frame", name, parent)
	
	local mineGrid = UI.CreateFrame("BDataGrid", name .. ".MineGrid", auctionsFrame)
	local auctionGrid = UI.CreateFrame("BDataGrid", name .. ".AuctionGrid", auctionsFrame)

	local prices = {}
	local competitionCache = {}
	
	local function ResetMineGrid()
		local ownAuctions = _G[addonID].GetActiveAuctionData()
		prices = {}
		competitionCache = {}
		for auctionID, auctionData in pairs(ownAuctions) do
			if not auctionData.own then 
				ownAuctions[auctionID] = nil 
			else
				if not prices[auctionData.itemType] then
					prices[auctionData.itemType] = _G[addonID].GetPricings(auctionData.itemType)
				end
			end 
		end
		mineGrid:SetData(ownAuctions)
		auctionGrid:ForceUpdate()
	end
	
	local function ScoreValue(value)
		local score = _G[addonID].ScorePrice(value.itemType, value.buyoutUnitPrice, prices[value.itemType])
		if not score then return "" end
		return math.floor(score) .. " %"
	end
	
	local function ScoreColor(value)
		local r, g, b = unpack(InternalInterface.UI.ScoreColorByScore(_G[addonID].ScorePrice(value.itemType, value.buyoutUnitPrice, prices[value.itemType])))
		return { r, g, b, 0.1 }
	end
	
	local function ScoreOrder(a, b, direction)
		local auctions = mineGrid:GetData()
		local scoreA = _G[addonID].ScorePrice(auctions[a].itemType, auctions[a].buyoutUnitPrice, prices[auctions[a].itemType]) or 0
		local scoreB = _G[addonID].ScorePrice(auctions[b].itemType, auctions[b].buyoutUnitPrice, prices[auctions[b].itemType]) or 0
		return (scoreB - scoreA) * direction > 0
	end
	
	local function CompetitionCompare(key, value)
		if key and competitionCache[key] then return unpack(competitionCache[key]) end
		local auctions = _G[addonID].GetActiveAuctionData(value.itemType)
		local above, below = 0, 0
		for auctionID, auctionData in pairs(auctions) do
			if not auctionData.own and auctionData.buyoutUnitPrice then
				if auctionData.buyoutUnitPrice < value.buyoutUnitPrice then
					below = below + 1
				elseif auctionData.buyoutUnitPrice > value.buyoutUnitPrice then
					above = above + 1
				end
			end
		end
		if key then competitionCache[key] = { above, below } end
		return above, below
	end
	
	local function CompetitionString(value)
		local above, below = CompetitionCompare(nil, value)
		return string.format("%d below, %d above", below, above) -- LOCALIZE
	end
	
	local function CompetitionOrder(a, b, direction)
		local auctions = mineGrid:GetData()
		local aboveA, belowA = CompetitionCompare(a, auctions[a])
		local aboveB, belowB = CompetitionCompare(b, auctions[b])
		if direction > 0 then
			return belowA < belowB or (belowA == belowB and aboveA > aboveB)
		else
			return belowA > belowB or (belowA == belowB and aboveA < aboveB)
		end
	end
	
	mineGrid:SetPoint("TOPLEFT", auctionsFrame, "TOPLEFT", 5, 5)
	mineGrid:SetPoint("BOTTOMRIGHT", auctionsFrame, "TOPRIGHT", -5, 330)
	mineGrid:SetHeadersVisible(true)
	mineGrid:SetRowHeight(62)
	mineGrid:SetRowMargin(2)
	mineGrid:SetUnselectedRowBackgroundColor(0.2, 0.15, 0.2, 1)
	mineGrid:SetSelectedRowBackgroundColor(0.6, 0.45, 0.6, 1)
	mineGrid:AddColumn(L["PostingPanel/columnStack"], 60, MineItemRenderer, function(a, b, direction) local auctions = mineGrid:GetData() return (auctions[b].stack - auctions[a].stack) * direction > 0 end) -- RELOCALIZE?
	mineGrid:AddColumn("Item", 250, "Text", true, "itemName", { Alignment = "left", Formatter = function() return "" end }) -- LOCALIZE
	local mineOrderColumn = mineGrid:AddColumn(L["PostingPanel/columnMinExpire"], 100, "Text", true, "minExpireTime", { Alignment = "center", Formatter = InternalInterface.Utility.RemainingTimeFormatter }) -- RELOCALIZE?
	mineGrid:AddColumn(L["PostingPanel/columnMaxExpire"], 100, "Text", true, "maxExpireTime", { Alignment = "center", Formatter = InternalInterface.Utility.RemainingTimeFormatter }) -- RELOCALIZE?
	mineGrid:AddColumn(L["PostingPanel/columnBid"], 130, "MoneyRenderer", true, "bidPrice") -- RELOCALIZE?
	mineGrid:AddColumn(L["PostingPanel/columnBuy"], 130, "MoneyRenderer", true, "buyoutPrice") -- RELOCALIZE?
	mineGrid:AddColumn(L["PostingPanel/columnBidPerUnit"], 130, "MoneyRenderer", true, "bidUnitPrice") -- RELOCALIZE?
	mineGrid:AddColumn(L["PostingPanel/columnBuyPerUnit"], 130, "MoneyRenderer", true, "buyoutUnitPrice") -- RELOCALIZE?
	mineGrid:AddColumn("Score", 80, "Text", ScoreOrder, nil, { Alignment = "center", Formatter = ScoreValue, Color = ScoreColor }) -- LOCALIZE
	mineGrid:AddColumn("Competition", 130, "Text", CompetitionOrder, nil, { Alignment = "center", Formatter = CompetitionString }) -- LOCALIZE
	mineGrid:AddColumn("", 40, CancellableRenderer)
	mineOrderColumn.Event.LeftClick(mineOrderColumn)
	
	auctionGrid:SetPoint("TOPLEFT", auctionsFrame, "TOPLEFT", 300, 335)
	auctionGrid:SetPoint("BOTTOMRIGHT", auctionsFrame, "BOTTOMRIGHT", -5, -5)
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
	auctionGrid:AddColumn("Score", 60, "Text", ScoreOrder, nil, { Alignment = "right", Formatter = ScoreValue, Color = ScoreColor }) -- LOCALIZE
	auctionGrid:AddColumn("", 0, "AuctionRenderer", false, nil, { Color = ScoreColor })
	auctionOrderColumn.Event.LeftClick(auctionOrderColumn)
	
	function mineGrid.Event:SelectionChanged(mineID, mineData)
		local auctions = {}
		if mineData then
			auctions = _G[addonID].GetActiveAuctionData(mineData.itemType)
		end
		auctionGrid:SetData(auctions)
	end
	
	ResetMineGrid()
	table.insert(Event[addonID].AuctionData, { ResetMineGrid, addonID, "AuctionsFrame.OnAuctionData" })
	
	function auctionsFrame:Show(hEvent)
		pcall(Command.Auction.Scan, { type = "mine" })
	end	
	
	return auctionsFrame
end