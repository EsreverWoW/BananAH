local _, InternalInterface = ...

local L = InternalInterface.Localization.L

-- Constants
local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "interpercentilerange"
local PRICING_MODEL_NAME = L["PricingModel/interPercentileRangeName"]

local NUMBER_OF_DAYS = 3 -- TODO Get from config
local RANGE_AMPLITUDE = 50 -- TODO Get from config
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
		print("[" .. PRICING_MODEL_NAME .. "]: " .. L["PricingModel/interPercentileRangeError"])
		return nil, nil
	end
	
	table.sort(bids)
	table.sort(buys)
	
	local bid = 0
	local bidLi = math.floor(#bids * (50 - RANGE_AMPLITUDE / 2) / 100) + 1
	local bidHi = math.ceil(#bids * (50 + RANGE_AMPLITUDE / 2) / 100)
	if bidHi < bidLi then
		bid = math.floor((bids[bidLi] + bids[bidHi]) / 2)
	else
		for bidI = bidLi, bidHi do bid = bid + bids[bidI] end
		bid = bid / (bidHi - bidLi + 1)
	end
	
	local buy = 0
	local buyLi = math.floor(#buys * (50 - RANGE_AMPLITUDE / 2) / 100) + 1
	local buyHi = math.ceil(#buys * (50 + RANGE_AMPLITUDE / 2) / 100)
	if buyHi < buyLi then
		buy = math.floor((buys[buyLi] + buys[buyHi]) / 2)
	else
		for buyI = buyLi, buyHi do buy = buy + buys[buyI] end
		buy = buy / (buyHi - buyLi + 1)
	end
	
	return math.min(bid, buy), buy, matchPrice
end
BananAH.RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel)
