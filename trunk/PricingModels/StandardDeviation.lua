local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "stdev"
local PRICING_MODEL_NAME = L["PricingModel/stdevName"]

local function PricingModel(item, auctions, autoMode)
	local weighted = true --InternalInterface.Settings.Config.PricingModels.stdevWeight or true
	local days = 3 --InternalInterface.Settings.Config.PricingModels.stdevDays or 3
	local deviation = 1.5  --1 + (InternalInterface.Settings.Config.PricingModels.stdevDeviation or 50) / 100
	
	local minTime = os.time() - DAY_LENGTH * days
	
	local bidW = 0
	local bidA = 0
	local bidT = 0
	local bidQ = 0

	local buyW = 0
	local buyA = 0
	local buyT = 0
	local buyQ = 0
	
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime or (days <= 0 and auctionData.removedBeforeExpiration == nil) then
			local weight = weighted and auctionData.stack or 1

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
	
	if bidW <= 0 or buyW <= 0 then return nil end
	
	bidW, bidA, bidT, bidQ = 0, bidT / bidW, 0, bidQ / bidW
	buyW, buyA, buyT, buyQ = 0, buyT / buyW, 0, buyQ / buyW
	
	local maxDevSquared = deviation * deviation
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime or (days <= 0 and auctionData.removedBeforeExpiration == nil) then
			local weight = weighted and auctionData.stack or 1

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
	
	if bidW <= 0 or buyW <= 0 then return nil end
	
	bidT = math.floor(bidT / bidW)
	buyT = math.floor(buyT / buyW)

	return math.min(bidT, buyT), buyT
end

_G[addonID].RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, nil)
