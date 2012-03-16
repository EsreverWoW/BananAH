local _, InternalInterface = ...

local L = InternalInterface.Localization.L

-- Constants
local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "median"
local PRICING_MODEL_NAME = L["PricingModel/medianName"]

local NUMBER_OF_DAYS = 3 -- TODO Get from config
local WEIGHTED = true -- TODO Get from config

local function PricingModel(item, matchPrice)
	local minTime = os.time() - DAY_LENGTH * NUMBER_OF_DAYS
	
	local bids = {}
	local buys = {}
	
	local auctions = BananAH.GetAllAuctionData(item)
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime then
			local weight = WEIGHTED and auctionData.stack or 1
			local bid = auctionData.bidUnitPrice
			local buy = auctionData.buyoutUnitPrice
			for i = 1, weight do
				table.insert(bids, bid)
				if buy then table.insert(buys, buy) end
			end
		end
	end
	
	if #bids <= 0 or #buys <= 0 then
		print("[" .. PRICING_MODEL_NAME .. "]: " .. L["PricingModel/medianError"])
		return nil, nil
	end
	
	table.sort(bids)
	table.sort(buys)
	
	local bid = math.floor((bids[math.floor(#bids / 2) + (#bids % 2)] + bids[math.floor(#bids / 2) + 1]) / 2)
	local buy = math.floor((buys[math.floor(#buys / 2) + (#buys % 2)] + buys[math.floor(#buys / 2) + 1]) / 2)

	return math.min(bid, buy), buy, matchPrice
end
BananAH.RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel)
