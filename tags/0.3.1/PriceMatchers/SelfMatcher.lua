local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local PRICE_MATCHER_ID = "self"
local PRICE_MATCHER_NAME = L["PriceMatcher/selfName"]

local configFrame = nil

local function DefaultConfig()
	InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID] = InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID] or
	{
		range = 25,
	}
end

local function PriceMatcher(callback, item, bid, buy)
	local itemType
	if item:sub(1, 1) == "I" then
			itemType = item
	else
		local ok, itemDetail = pcall(IIDetail, item)
		itemType = ok and itemDetail and itemDetail.type or nil
	end
	if not itemType then return callback() end
	
	local function CalcPrice(activeAuctions)
		local bidsRange = {}
		local buysRange = {}
		
		DefaultConfig()
		local matchingRange = (InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID].range or 25) / 100

		for auctionId, auctionData in pairs(activeAuctions) do
			local bidRelDev = math.abs(1 - auctionData.bidUnitPrice / bid)
			if auctionData.own and bidRelDev <= matchingRange and matchingRange > 0 then table.insert(bidsRange, auctionData.bidUnitPrice) end
			local buyRelDev = auctionData.buyoutUnitPrice and math.abs(1 - auctionData.buyoutUnitPrice / buy) or (matchingRange + 1)
			if auctionData.own and buyRelDev <= matchingRange and matchingRange > 0 then table.insert(buysRange, auctionData.buyoutUnitPrice) end
		end

		table.sort(bidsRange)
		if #bidsRange > 0 then
			bid = bidsRange[1]
		end

		table.sort(buysRange)
		if #buysRange > 0 then
			buy = buysRange[1]
		end
		
		bid = math.min(bid, buy)	
		
		callback(bid, buy)
	end

	_G[addonID].GetActiveAuctionData(CalcPrice, itemType)		
end

local function ConfigFrame(parent)
	if configFrame then return configFrame end

	DefaultConfig()
	
	configFrame = UI.CreateFrame("Frame", parent:GetName() .. ".SelfPriceMatcherConfig", parent)
	local rangeText = UI.CreateFrame("Text", configFrame:GetName() .. ".RangeText", configFrame)
	local rangeSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".RangeSlider", configFrame)

	configFrame:SetVisible(false)
	
	rangeText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 10)
	rangeText:SetFontSize(14)
	rangeText:SetText(L["PriceMatcher/selfRange"])

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
