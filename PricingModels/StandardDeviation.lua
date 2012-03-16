local _, InternalInterface = ...

local L = InternalInterface.Localization.L

-- Constants
local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "stdev"
local PRICING_MODEL_NAME = L["PricingModel/stdevName"]

local NUMBER_OF_DAYS = 3 -- TODO Get from config
local MAX_DEVIATION = 1.5 -- TODO Get from config
local WEIGHTED = true -- TODO Get from config

local function PricingModel(item, matchPrice)
	local minTime = os.time() - DAY_LENGTH * NUMBER_OF_DAYS
	
	local bidW = 0
	local bidA = 0
	local bidT = 0
	local bidQ = 0

	local buyW = 0
	local buyA = 0
	local buyT = 0
	local buyQ = 0
	
	local auctions = BananAH.GetAllAuctionData(item)
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime then
			local weight = WEIGHTED and auctionData.stack or 1

			local pBidA = bidA
			bidW = bidW + weight
			bidA = bidA + weight * (auctionData.bidUnitPrice - bidA) / bidW
			bidT = bidT + weight * auctionData.bidUnitPrice
			bidQ = bidQ + weight * (auctionData.bidUnitPrice - pBidA) * (auctionData.bidUnitPrice - bidA)

			if auctionData.buyoutUnitPrice then
				local pBuyA = buyA
				buyW = buyW + weight
				buyA = buyA + weight * (auctionData.buyoutUnitPrice - buyA) / buyW
				buyT = buyT + weight * auctionData.buyoutUnitPrice
				buyQ = buyQ + weight * (auctionData.buyoutUnitPrice - pBuyA) * (auctionData.buyoutUnitPrice - buyA)
			end
		end
	end
	
	if bidW <= 0 or buyW <= 0 then
		print("[" .. PRICING_MODEL_NAME .. "]: " .. L["PricingModel/stdevError"])
		return nil, nil
	end
	
	bidW, bidA, bidT, bidQ = 0, bidT / bidW, 0, bidQ / bidW
	buyW, buyA, buyT, buyQ = 0, buyT / buyW, 0, buyQ / buyW
	
	local maxDevSquared = MAX_DEVIATION * MAX_DEVIATION
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime then
			local weight = WEIGHTED and auctionData.stack or 1

			local bidD = auctionData.bidUnitPrice - bidA
			if bidD * bidD <= bidQ * maxDevSquared then
				bidW = bidW + weight
				bidT = bidT + weight * auctionData.bidUnitPrice
			end

			if auctionData.buyoutUnitPrice then
				local buyD = auctionData.buyoutUnitPrice - buyA
				if buyD * buyD <= buyQ * maxDevSquared then
					buyW = buyW + weight
					buyT = buyT + weight * auctionData.buyoutUnitPrice
				end
			end
		end
	end
	
	if bidW <= 0 then bidT, bidW = bidA, 1 end
	if buyW <= 0 then buyT, buyW = buyA, 1 end

	return math.min(math.floor(bidT / bidW), math.floor(buyT / buyW)), math.floor(buyT / buyW), matchPrice
end
BananAH.RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel)
