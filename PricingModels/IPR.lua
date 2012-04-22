local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "interpercentilerange"
local PRICING_MODEL_NAME = L["PricingModel/interPercentileRangeName"]

local function PricingModel(item, auctions, autoMode)
	local weighted = true --InternalInterface.Settings.Config.PricingModels.iprWeight or true
	local days = 3 --InternalInterface.Settings.Config.PricingModels.iprDays or 3
	local range = 50 --InternalInterface.Settings.Config.PricingModels.iprDeviation or 50
	
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
	
	local bid = 0
	local bidLi = math.floor(#bids * (50 - range / 2) / 100) + 1
	local bidHi = math.ceil(#bids * (50 + range / 2) / 100)
	if bidHi < bidLi then
		bid = math.floor((bids[bidLi] + bids[bidHi]) / 2)
	else
		for bidI = bidLi, bidHi do bid = bid + bids[bidI] end
		bid = math.floor(bid / (bidHi - bidLi + 1))
	end
	
	local buy = 0
	local buyLi = math.floor(#buys * (50 - range / 2) / 100) + 1
	local buyHi = math.ceil(#buys * (50 + range / 2) / 100)
	if buyHi < buyLi then
		buy = math.floor((buys[buyLi] + buys[buyHi]) / 2)
	else
		for buyI = buyLi, buyHi do buy = buy + buys[buyI] end
		buy = math.floor(buy / (buyHi - buyLi + 1))
	end
	
	return math.min(bid, buy), buy
end

_G[addonID].RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, nil)
