local _, InternalInterface = ...

local L = InternalInterface.Localization.L

-- Constants
local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "mean"
local PRICING_MODEL_NAME = L["PricingModel/meanName"]

local NUMBER_OF_DAYS = 3 -- TODO Get from config
local WEIGHTED = true -- TODO Get from config

local function PricingModel(item, matchPrice)
	local minTime = os.time() - DAY_LENGTH * NUMBER_OF_DAYS
	
	local bidT = 0
	local bidW = 0
	local buyT = 0
	local buyW = 0
	
	local auctions = BananAH.GetAllAuctionData(item)
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime then
			local weight = WEIGHTED and auctionData.stack or 1
			bidT = bidT + auctionData.bidUnitPrice * weight
			bidW = bidW + weight
			if auctionData.buyoutUnitPrice then
				buyT = buyT + auctionData.buyoutUnitPrice * weight
				buyW = buyW + weight
			end
		end
	end
	
	if bidW <= 0 or buyW <= 0 then
		print("[" .. PRICING_MODEL_NAME .. "]: " .. L["PricingModel/meanError"])
		return nil, nil
	end

	return math.min(math.floor(bidT / bidW), math.floor(buyT / buyW)), math.floor(buyT / buyW), matchPrice
end
BananAH.RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel)
