local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "median"
local PRICING_MODEL_NAME = L["PricingModel/medianName"]

local function PricingModel(item, auctions, autoMode)
	local weighted = true --InternalInterface.Settings.Config.PricingModels.medianWeight or true
	local days = 3 -- InternalInterface.Settings.Config.PricingModels.medianDays or 3
	
	local minTime = os.time() - DAY_LENGTH * days
	
	local bids = {}
	local buys = {}
	
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime or (days <= 0 and auctionData.removedBeforeExpiration == nil) then
			local weight = weighted and auctionData.stack or 1

			local bid = auctionData.bidUnitPrice
			local buy = auctionData.buyoutUnitPrice

			for i = 1, weight do
				table.insert(bids, bid)
				if buy then table.insert(buys, buy) end
			end
		end
	end
	
	if #bids <= 0 or #buys <= 0 then return nil end
	
	table.sort(bids)
	table.sort(buys)
	
	local bid = math.floor((bids[math.floor(#bids / 2) + (#bids % 2)] + bids[math.floor(#bids / 2) + 1]) / 2)
	local buy = math.floor((buys[math.floor(#buys / 2) + (#buys % 2)] + buys[math.floor(#buys / 2) + 1]) / 2)

	return math.min(bid, buy), buy
end

_G[addonID].RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, nil)
