local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "mean"
local PRICING_MODEL_NAME = L["PricingModel/meanName"]

local function PricingModel(item, auctions, autoMode)
	local weighted = true --InternalInterface.Settings.Config.PricingModels.meanWeight or true
	local days = 3 --InternalInterface.Settings.Config.PricingModels.meanDays or 3
	
	local minTime = os.time() - DAY_LENGTH * days
	
	local bidT = 0
	local bidW = 0
	local buyT = 0
	local buyW = 0
	
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime or (days <= 0 and auctionData.removedBeforeExpiration == nil) then
			local weight = weighted and auctionData.stack or 1
			
			bidT = bidT + auctionData.bidUnitPrice * weight
			bidW = bidW + weight
			
			if auctionData.buyoutUnitPrice then
				buyT = buyT + auctionData.buyoutUnitPrice * weight
				buyW = buyW + weight
			end
		end
	end
	
	if bidW <= 0 or buyW <= 0 then return nil end
	
	bidT = math.floor(bidT / bidW)
	buyT = math.floor(buyT / buyW)
	
	return math.min(bidT, buyT), buyT
end

_G[addonID].RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, nil)
