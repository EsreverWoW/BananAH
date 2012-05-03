local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local PRICE_SCORER_ID = "market"
local PRICE_SCORER_NAME = "Market Price" -- LOCALIZE

local function PricingModel(item, auctions, autoMode, prices)
	local marketPricePricingModels = { vendor = 0, mean = 0, stdev = 2, median = 2, interpercentilerange = 0, } -- TODO Config
	
	local marketPriceBidT = 0
	local marketPriceBidW = 0
	
	local marketPriceBuyT = 0
	local marketPriceBuyW = 0

	for key, priceData in pairs(prices) do
		local weight = marketPricePricingModels[key] or 0
		marketPriceBidT = marketPriceBidT + priceData.bid * weight
		marketPriceBidW = marketPriceBidW + weight
		marketPriceBuyT = marketPriceBuyT + (priceData.buy or 0) * weight
		marketPriceBuyW = marketPriceBuyW + (priceData.buy and weight or 0)
	end
	
	if marketPriceBidW <= 0 or marketPriceBuyW <= 0 then
		return nil, nil
	end
	
	local bid = math.floor(marketPriceBidT / marketPriceBidW)
	local buyout = marketPriceBuyW > 0 and math.floor(marketPriceBuyT / marketPriceBuyW) or 0
	
	return math.min(bid, buyout), buyout
end

local function PriceScorer()
end

_G[addonID].RegisterPriceScorer(PRICE_SCORER_ID, PRICE_SCORER_NAME, PricingModel, nil, PriceScorer, nil)

