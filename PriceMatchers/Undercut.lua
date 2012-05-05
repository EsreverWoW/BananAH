local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local PRICE_MATCHER_ID = "undercut"
local PRICE_MATCHER_NAME = "Competition undercut" -- LOCALIZE

local configFrame = nil

local function DefaultConfig()
	InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID] = InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID] or
	{
		range = 25,
	}
end

local function PriceMatcher(item, activeAuctions, bid, buy)
	local bidsRange = {}
	local buysRange = {}
	
	DefaultConfig()
	local undercutRange = (InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID].range or 25) / 100

	for auctionId, auctionData in pairs(activeAuctions) do
		local bidRelDev = math.abs(1 - auctionData.bidUnitPrice / bid)
		if not auctionData.own and bidRelDev <= undercutRange and undercutRange > 0 then table.insert(bidsRange, auctionData.bidUnitPrice) end -- FIXME
		local buyRelDev = auctionData.buyoutUnitPrice and math.abs(1 - auctionData.buyoutUnitPrice / buy) or (undercutRange + 1)
		if not auctionData.own and buyRelDev <= undercutRange and undercutRange > 0 then table.insert(buysRange, auctionData.buyoutUnitPrice) end -- FIXME
	end

	table.sort(bidsRange)
	if #bidsRange > 0 then
		bid = math.max(bidsRange[1] - 1, 1)
	else
		bid = math.floor(bid * (1 + undercutRange))
	end

	table.sort(buysRange)
	if #buysRange > 0 then
		buy = math.max(buysRange[1] - 1, 1)
	else
		buy = math.floor(buy * (1 + undercutRange))
	end
	
	bid = math.min(bid, buy)	
	
	return bid, buy
end

local function ConfigFrame(parent)
	if configFrame then return configFrame end

	DefaultConfig()
	
	configFrame = UI.CreateFrame("Frame", parent:GetName() .. ".UndercutPriceMatcherConfig", parent)
	local rangeText = UI.CreateFrame("Text", configFrame:GetName() .. ".RangeText", configFrame)
	local rangeSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".RangeSlider", configFrame)

	configFrame:SetVisible(false)
	
	rangeText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 10)
	rangeText:SetFontSize(14)
	rangeText:SetText(L["ConfigPanel/priceMatcherUndercutRange"]) -- RELOCALIZE

	rangeSlider:SetPoint("CENTERLEFT", rangeText, "CENTERRIGHT", 20, 8)	
	rangeSlider:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -10, 10)
	rangeSlider:SetRange(0, 100)
	rangeSlider:SetPosition(InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID].range or 25)
	
	function rangeSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID].range = position
	end
	
	return configFrame
end

_G[addonID].RegisterPriceMatcher(PRICE_MATCHER_ID, PRICE_MATCHER_NAME, PriceMatcher, ConfigFrame)
