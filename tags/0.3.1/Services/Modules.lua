-- ***************************************************************************************************************************************************
-- * Services/Modules.lua                                                                                                                            *
-- ***************************************************************************************************************************************************
-- * Manages the pluggable modules                                                                                                                   *
-- ***************************************************************************************************************************************************
-- * 0.4.0  / 2012.06.17 / Baanano: Rewritten PricingModelService.lua                                                                                *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local CYield = coroutine.yield
local TInsert = table.insert
local TRemove = table.remove
local UECreate = Utility.Event.Create

local CopyTableRecursive = InternalInterface.Utility.CopyTableRecursive

local auctionSearchers = {}
local pricingModels = {}
local priceScorers = {}
local priceMatchers = {}
local AuctionSearcherAddedEvent = UECreate(addonID, "AuctionSearcherAdded")
local PricingModelAddedEvent = UECreate(addonID, "PricingModelAdded")
local PriceScorerAddedEvent = UECreate(addonID, "PriceScorerAdded")
local PriceMatcherAddedEvent = UECreate(addonID, "PriceMatcherAdded")

InternalInterface.Modules = InternalInterface.Modules or {}

function InternalInterface.Modules.GetAllAuctionSearchers()
	return CopyTableRecursive(auctionSearchers)
end

function InternalInterface.Modules.GetAllPricingModels()
	return CopyTableRecursive(pricingModels)
end

function InternalInterface.Modules.GetAllPriceScorers()
	return CopyTableRecursive(priceScorers)
end

function InternalInterface.Modules.GetAllPriceMatchers()
	return CopyTableRecursive(priceMatchers)
end

function InternalInterface.Modules.GetPricingModelCallback(id)
	if pricingModels[id] then return pricingModels[id].callbackFunction end
	if priceScorers[id] then return priceScorers[id].callbackFunction end
	return nil
end



function PublicInterface.RegisterPricingModel(id, displayName, pricingFunction, callbackFunction, configFrameConstructor)
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

function PublicInterface.RegisterPriceScorer(id, displayName, pricingFunction, callbackFunction, scoreFunction, configFrameConstructor)
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

function PublicInterface.RegisterPriceMatcher(id, displayName, matchingFunction, configFrameConstructor)
	if not priceMatchers[id] then
		priceMatchers[id] =
		{
			priceMatcherID = id,
			displayName = displayName,
			matchingFunction = matchingFunction,
			configFrameConstructor = configFrameConstructor,
		}
		PriceMatcherAddedEvent(id)
		return true
	end
	return false
end

function PublicInterface.RegisterAuctionSearcher(id, displayName, online, searchFunction, filterFunction, clearFunction, snipeFunction, searchFrameConstructor, extraButtonsConstructor, configFrameConstructor)
	if not auctionSearchers[id] then
		auctionSearchers[id] =
		{
			auctionSearcherID = id,
			displayName = displayName,
			online = online,
			searchFunction = searchFunction,
			filterFunction = filterFunction,
			clearFunction = clearFunction,
			snipeFunction = snipeFunction,
			searchFrameConstructor = searchFrameConstructor,
			extraButtonsConstructor = extraButtonsConstructor,
			configFrameConstructor = configFrameConstructor,
		}
		AuctionSearcherAddedEvent(id)
		return true
	end
	return false
end

function PublicInterface.GetPricings(callback, item, autoMode)
	if type(callback) ~= "function" or not item then return end
	
	local prices = {}
	
	local queue = {}
	for pricingModelID, pricingModelData in pairs(pricingModels) do
		if pricingModelData.pricingFunction then
			TInsert(queue, { pricingModelID, pricingModelData.pricingFunction, pricingModelData.displayName })
		end
	end
	for priceScorerID, priceScorerData in pairs(priceScorers) do
		if priceScorerData.pricingFunction then
			TInsert(queue, { priceScorerID, priceScorerData.pricingFunction, priceScorerData.displayName })
		end
	end
	
	local function CollectPrice(id, name, bid, buy)
		if bid then
			prices[id] = { displayName = name, bid = bid, buy = buy, }
		end
		if #queue <= 0 then
			callback(prices)
		else
			local nextStep = queue[1]
			TRemove(queue, 1)
			nextStep[2](function(bid, buy) CollectPrice(nextStep[1], nextStep[3], bid, buy) end, item, autoMode, prices)
		end
	end
	CollectPrice()
end

function PublicInterface.MatchPrice(callback, item, unitBid, unitBuy)
	if type(callback) ~= "function" or not item then return end

	local queue = {}
	local priceMatcherUsed = {}
	local priceMatcherOrder = InternalInterface.AccountSettings.Posting.DefaultConfig.priceMatcherOrder or {}
	
	for _, priceMatcherID in ipairs(priceMatcherOrder) do
		if priceMatchers[priceMatcherID] then
			TInsert(queue, priceMatchers[priceMatcherID].matchingFunction)
			priceMatcherUsed[priceMatcherID] = true
		end
	end
	for priceMatcherID, priceMatcherData in pairs(priceMatchers) do
		if not priceMatcherUsed[priceMatcherID] then
			TInsert(queue, priceMatchers[priceMatcherID].matchingFunction)
		end
	end

	local function CollectPrice(bid, buy)
		unitBid = bid or unitBid
		unitBuy = buy or unitBuy
		
		if #queue <= 0 then
			callback(unitBid, unitBuy)
		else
			local nextStep = queue[1]
			TRemove(queue, 1)
			nextStep(CollectPrice, item, unitBid, unitBuy)
		end
	end
	CollectPrice()	
end

function PublicInterface.ScorePrice(callback, item, value, prices)
	if type(callback) ~= "function" or not value or (not prices and not item) then return end

	local function ScoreAsync(realPrices)
		local priceScorer = InternalInterface.AccountSettings.PriceScorers.Settings.default or "market"
		if not priceScorers[priceScorer] or not priceScorers[priceScorer].scoreFunction then return end
		priceScorers[priceScorer].scoreFunction(callback, item, value, realPrices)
	end
	
	if not prices then
		PublicInterface.GetPricings(ScoreAsync, item)
	else
		ScoreAsync(prices)
	end
end

