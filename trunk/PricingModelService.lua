local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local PricingModelAddedEvent = Utility.Event.Create(addonID, "PricingModelAdded")
local PriceMatcherAddedEvent = Utility.Event.Create(addonID, "PriceMatcherAdded")

local pricingModels = {}
local priceMatchers = {}

local function GetPricingModel(id)
	if not pricingModels[id] then return nil end
	return pricingModels[id] -- FIXME Return copy
end

local function GetPriceMatcher(id)
	if not priceMatchers[id] then return nil end
	return priceMatchers[id] -- FIXME Return copy
end

local function RegisterPricingModel(id, displayName, pricingFunction, callbackFunction, configFrameConstructor)
	if not pricingModels[id] then
		pricingModels[id] = 
		{ 
			pricingModelID = id, 
			displayName = displayName, 
			pricingFunction = pricingFunction, 
			callbackFunction = callbackFunction, 
			configFrameConstructor = configFrameConstructor,
		}
		PricingModelAddedEvent(id)
		return true
	end
	return false
end

local function RegisterPriceMatcher(id, displayName, matchingFunction)
	if not priceMatchers[id] then
		priceMatcher[id] =
		{
			priceMatcherID = id,
			displayName = displayName,
			matchingFunction = matchingFunction,
		}
		PriceMatcherAddedEvent(id)
	end
	return false
end

local function GetPricings(item, autoMode)
	local prices = {}
	local auctions = _G[addonID].GetAllAuctionData(item)
	
	local marketPricePricingModels = { vendor = 0, mean = 0, stdev = 2, median = 2, interpercentilerange = 0, } -- TODO Config
	local marketPriceBidT = 0
	local marketPriceBidW = 0
	local marketPriceBuyT = 0
	local marketPriceBuyW = 0
	
	for pricingModelID, pricingModelData in pairs(pricingModels) do
		local bid, buy = pricingModelData.pricingFunction(item, auctions, autoMode)

		if bid then
			prices[pricingModelID] = { displayName = pricingModelData.displayName, bid = bid, buy = buy, }
			
			local weight = marketPricePricingModels[pricingModelID] or 0
			marketPriceBidT = marketPriceBidT + bid * weight
			marketPriceBidW = marketPriceBidW + weight
			marketPriceBuyT = marketPriceBuyT + (buy or 0) * weight
			marketPriceBuyW = marketPriceBuyW + (buy and weight or 0)
		end
	end
	
	if marketPriceBidW > 0 then
		prices["market"] = { displayName = "Market Price", bid = math.floor(marketPriceBidT / marketPriceBidW), buy = marketPriceBuyW > 0 and math.floor(marketPriceBuyT / marketPriceBuyW) or nil, } -- TODO LOCALIZATION
	end
	
	return prices
end

local function MatchPrice(item, unitBid, unitBuy)
	-- TODO Use registered price matchers instead of this!
	local userName = Inspect.Unit.Detail("player").name -- TODO Use all player characters
	local matchingRange = (InternalInterface.AccountSettings.Posting.selfMatcherRange or 25) / 100
	local undercutRange = (InternalInterface.AccountSettings.Posting.competitionUndercutterRange or 25) / 100

	local auctions = _G[addonID].GetActiveAuctionData(item)
	local bidsMatchRange = {}
	local bidsUndercutRange = {}
	local buysMatchRange = {}
	local buysUndercutRange = {}

	for auctionId, auctionData in pairs(auctions) do
		local bidRelDev = math.abs(1 - auctionData.bidUnitPrice / unitBid)
		if userName == auctionData.sellerName and bidRelDev <= matchingRange and matchingRange > 0 then table.insert(bidsMatchRange, auctionData.bidUnitPrice) end
		if userName ~= auctionData.sellerName and bidRelDev <= undercutRange and undercutRange > 0 then table.insert(bidsUndercutRange, auctionData.bidUnitPrice) end

		local buyRelDev = auctionData.buyoutUnitPrice and math.abs(1 - auctionData.buyoutUnitPrice / unitBuy) or (math.max(matchingRange, undercutRange) + 1)
		if userName == auctionData.sellerName and buyRelDev <= matchingRange and matchingRange > 0 then table.insert(buysMatchRange, auctionData.buyoutUnitPrice) end
		if userName ~= auctionData.sellerName and buyRelDev <= undercutRange and undercutRange > 0 then table.insert(buysUndercutRange, auctionData.buyoutUnitPrice) end
	end

	table.sort(bidsMatchRange)
	table.sort(bidsUndercutRange)
	if #bidsMatchRange > 0 then 
		unitBid = bidsMatchRange[1]
	elseif #bidsUndercutRange > 0 then
		unitBid = math.max(bidsUndercutRange[1] - 1, 1)
	else
		unitBid = math.floor(unitBid * (1 + undercutRange))
	end

	table.sort(buysMatchRange)
	table.sort(buysUndercutRange)
	if #buysMatchRange > 0 then 
		unitBuy = buysMatchRange[1]
	elseif #buysUndercutRange > 0 then
		unitBuy = math.max(buysUndercutRange[1] - 1, 1)
	else
		unitBuy = math.floor(unitBuy * (1 + undercutRange))
	end
	unitBid = math.min(unitBid, unitBuy)	
	
	return unitBid, unitBuy
end

_G[addonID].GetPricingModel = GetPricingModel
_G[addonID].GetPriceMatcher = GetPriceMatcher
_G[addonID].RegisterPricingModel = RegisterPricingModel
_G[addonID].RegisterPriceMatcher = RegisterPriceMatcher
_G[addonID].GetPricings = GetPricings
_G[addonID].MatchPrice = MatchPrice

