local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local PricingModelAddedEvent = Utility.Event.Create(addonID, "PricingModelAdded")
local PriceScorerAddedEvent = Utility.Event.Create(addonID, "PriceScorerAdded")
local PriceMatcherAddedEvent = Utility.Event.Create(addonID, "PriceMatcherAdded")

local pricingModels = {}
local priceScorers = {}
local priceMatchers = {}

function InternalInterface.PricingModelService.GetAllPricingModels()
	return pricingModels -- FIXME Return copy
end

function InternalInterface.PricingModelService.GetAllPriceScorers()
	return priceScorers -- FIXME Return copy
end

function InternalInterface.PricingModelService.GetAllPriceMatchers()
	return priceMatchers -- FIXME Return copy
end

local function GetPricingModel(id)
	return pricingModels[id] or priceScorers[id] or nil -- FIXME Return copy
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

local function RegisterPriceScorer(id, displayName, pricingFunction, callbackFunction, scoreFunction, configFrameConstructor)
	if not priceScorers[id] then
		priceScorers[id] =
		{
			priceScorerID = id,
			displayName = displayName,
			pricingFunction = pricingFunction,
			callbackFunction = callbackFunction,
			scoreFunction = scoreFunction,
			configFrameConstructor = configFrameConstructor,
		}
		PriceScorerAddedEvent(id)
		return true
	end
	return false
end

local function RegisterPriceMatcher(id, displayName, matchingFunction, configFrameConstructor)
	if not priceMatchers[id] then
		priceMatchers[id] =
		{
			priceMatcherID = id,
			displayName = displayName,
			matchingFunction = matchingFunction,
			configFrameConstructor = configFrameConstructor,
		}
		PriceMatcherAddedEvent(id)
	end
	return false
end

local function GetPricings(item, autoMode)
	local prices = {}
	local auctions = _G[addonID].GetAllAuctionData(item)
	
	for pricingModelID, pricingModelData in pairs(pricingModels) do
		local bid, buy = pricingModelData.pricingFunction(item, auctions, autoMode)

		if bid then
			prices[pricingModelID] = { displayName = pricingModelData.displayName, bid = bid, buy = buy, }
		end
	end
	
	for priceScorerID, priceScorerData in pairs(priceScorers) do
		if priceScorerData.pricingFunction then
			local bid, buy = priceScorerData.pricingFunction(item, auctions, autoMode, prices)
			if bid then
				prices[priceScorerID] = { displayName = priceScorerData.displayName, bid = bid, buy = buy, }
			end
		end
	end
	
	return prices
end

local function MatchPrice(item, unitBid, unitBuy)
	local auctions = _G[addonID].GetActiveAuctionData(item)
	
	local priceMatcherOrder = InternalInterface.AccountSettings.Posting.DefaultConfig.priceMatcherOrder or {}
	local priceMatcherUsed = {}
	
	for _, priceMatcherID in ipairs(priceMatcherOrder) do
		if priceMatchers[priceMatcherID] then
			local matchBid, matchBuy = priceMatchers[priceMatcherID].matchingFunction(item, auctions, unitBid, unitBuy)
			unitBid = matchBid or unitBid
			unitBuy = matchBuy or unitBuy
			priceMatcherUsed[priceMatcherID] = true
		end
	end
	
	for priceMatcherID, priceMatcherData in pairs(priceMatchers) do
		if not priceMatcherUsed[priceMatcherID] then
			local matchBid, matchBuy = priceMatcherData.matchingFunction(item, auctions, unitBid, unitBuy)
			unitBid = matchBid or unitBid
			unitBuy = matchBuy or unitBuy
		end
	end
	
	return unitBid, unitBuy
end

_G[addonID].GetPricingModel = GetPricingModel
_G[addonID].GetPriceMatcher = GetPriceMatcher
_G[addonID].RegisterPricingModel = RegisterPricingModel
_G[addonID].RegisterPriceScorer = RegisterPriceScorer
_G[addonID].RegisterPriceMatcher = RegisterPriceMatcher
_G[addonID].GetPricings = GetPricings
_G[addonID].MatchPrice = MatchPrice

