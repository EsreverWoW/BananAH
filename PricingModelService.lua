local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local PricingModelAddedEvent = Utility.Event.Create(addonID, "PricingModelAdded")
local PriceScorerAddedEvent = Utility.Event.Create(addonID, "PriceScorerAdded")
local PriceMatcherAddedEvent = Utility.Event.Create(addonID, "PriceMatcherAdded")
local AuctionSearcherAddedEvent = Utility.Event.Create(addonID, "AuctionSearcherAdded")

local pricingModels = {}
local priceScorers = {}
local priceMatchers = {}
local auctionSearchers = {}

function InternalInterface.PricingModelService.GetAllPricingModels()
	return InternalInterface.Utility.CopyTableRecursive(pricingModels)
end

function InternalInterface.PricingModelService.GetAllPriceScorers()
	return InternalInterface.Utility.CopyTableRecursive(priceScorers)
end

function InternalInterface.PricingModelService.GetAllPriceMatchers()
	return InternalInterface.Utility.CopyTableRecursive(priceMatchers)
end

function InternalInterface.PricingModelService.GetAllAuctionSearchers()
	return InternalInterface.Utility.CopyTableRecursive(auctionSearchers)
end

local function GetPricingModel(id)
	if pricingModels[id] then return InternalInterface.Utility.CopyTableRecursive(pricingModels[id]) end
	if priceScorers[id] then return InternalInterface.Utility.CopyTableRecursive(priceScorers[id]) end
	return nil
end

local function GetPriceMatcher(id)
	if not priceMatchers[id] then return nil end
	return InternalInterface.Utility.CopyTableRecursive(priceMatchers[id])
end

local function GetAuctionSearcher(id)
	if not auctionSearchers[id] then return nil end
	return InternalInterface.Utility.CopyTableRecursive(auctionSearchers[id])
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
		return true
	end
	return false
end

local function RegisterAuctionSearcher(id, displayName, online, searchFunction, filterFunction, clearFunction, snipeFunction, searchFrameConstructor, extraButtonsConstructor, configFrameConstructor)
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

local function ScorePrice(item, value, prices)
	if not value then return nil end

	if not prices then 
		if item then
			prices = GetPricings(item) 
		else
			return nil
		end
	end

	local priceScorer = InternalInterface.AccountSettings.PriceScorers.Settings.default or "market"
	if not priceScorers[priceScorer] or not priceScorers[priceScorer].scoreFunction then return nil end

	return priceScorers[priceScorer].scoreFunction(item, value, prices)
end

function InternalInterface.UI.ScoreColorByIndex(index)
	if not index or type(index) ~= "number" then return { 0.75, 0.5, 0.75 } end
	if index <= 1 then return { 0, 0.75, 0.75 }
	elseif index <= 2 then return { 0, 0.75, 0 }
	elseif index <= 3 then return { 0.75, 0.75, 0 }
	elseif index <= 4 then return { 0.75, 0.5, 0 }
	else return { 0.75, 0, 0 }
	end
	return { 0.75, 0.5, 0.75 }
end

function InternalInterface.UI.ScoreIndexByScore(score)
	local index = nil
	local limits = InternalInterface.AccountSettings.PriceScorers.Settings.colorLimits or { 85, 85, 115, 115 }
	if score then
		if score <= limits[1] then index = 1
		elseif score <= limits[2] then index = 2
		elseif score <= limits[3] then index = 3
		elseif score <= limits[4] then index = 4
		else index = 5
		end
	end
	return index
end

function InternalInterface.UI.ScoreColorByScore(score)
	return InternalInterface.UI.ScoreColorByIndex(InternalInterface.UI.ScoreIndexByScore(score))
end

_G[addonID].GetPricingModel = GetPricingModel
_G[addonID].GetPriceMatcher = GetPriceMatcher
_G[addonID].RegisterPricingModel = RegisterPricingModel
_G[addonID].RegisterPriceScorer = RegisterPriceScorer
_G[addonID].RegisterPriceMatcher = RegisterPriceMatcher
_G[addonID].RegisterAuctionSearcher = RegisterAuctionSearcher
_G[addonID].GetPricings = GetPricings
_G[addonID].MatchPrice = MatchPrice
_G[addonID].ScorePrice = ScorePrice

