-- ***************************************************************************************************************************************************
-- * PGCExtensions.lua                                                                                                                               *
-- ***************************************************************************************************************************************************
-- * Extends LibPGC and LibPGCEx with functionality needed by BananAH                                                                                *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.01 / Baanano: Updated for 0.4.1                                                                                                 *
-- * 0.4.0 / 2012.05.31 / Baanano: Rewritten AHMonitoringService.lua                                                                                 *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local GetActiveAuctionData = LibPGC.GetActiveAuctionData
local GetOwnAuctionData = LibPGC.GetOwnAuctionData
local GetPrices = LibPGCEx.GetPrices
local MFloor = math.floor
local TInsert = table.insert
local ipairs = ipairs
local pairs = pairs
local type = type

InternalInterface.PGCExtensions = InternalInterface.PGCExtensions or {}

function InternalInterface.PGCExtensions.GetActiveAuctionsScored(callback, item)
	if type(callback) ~= "function" then return end
	
	local referencePrice = InternalInterface.AccountSettings.Scoring.ReferencePrice
	
	local function ProcessAuctions(auctions)
		local remainingItemTypes = 1
		local itemTypes = {}
		
		for auctionID, auctionData in pairs(auctions) do
			local auctionItemType = auctionData.itemType
			itemTypes[auctionItemType] = itemTypes[auctionItemType] or {}
			TInsert(itemTypes[auctionItemType], auctionID)
		end
		
		local function AssignScore(itemType, prices)
			local price = prices and prices[referencePrice] or nil
			if itemType and price and price.buy and price.buy > 0 then
				for _, auctionID in ipairs(itemTypes[itemType]) do
					local auctionData = auctions[auctionID]
					if auctionData.buyoutUnitPrice then
						auctionData.score = MFloor(auctionData.buyoutUnitPrice * 100 / price.buy)
					end
				end
			end
			remainingItemTypes = remainingItemTypes - 1
			if remainingItemTypes <= 0 then
				callback(auctions)
			end
		end
		
		for itemType in pairs(itemTypes) do
			if GetPrices(function(prices) AssignScore(itemType, prices) end, itemType, 1, referencePrice, true) then
				remainingItemTypes = remainingItemTypes + 1
			end
		end
		AssignScore()
	end
	
	GetActiveAuctionData(ProcessAuctions, item)
end

function InternalInterface.PGCExtensions.GetOwnAuctionsScoredCompetition(callback)
	if type(callback) ~= "function" then return end
	
	local referencePrice = InternalInterface.AccountSettings.Scoring.ReferencePrice
	
	local function ProcessAuctions(auctions)
		local scoreRemaining = 0
		local competitionRemaining = 0
		local auctionsByItemType = {}
		
		local function CheckEnd()
			if scoreRemaining <= 0 and competitionRemaining <= 0 then
				callback(auctions)
			end
		end
		
		local function AssignScore(itemType, prices)
			local price = prices and prices[referencePrice] or nil
			if itemType and price and price.buy and price.buy > 0 then
				for _, auctionID in ipairs(auctionsByItemType[itemType]) do
					local auctionData = auctions[auctionID]
					if auctionData.buyoutUnitPrice then
						auctionData.score = MFloor(auctionData.buyoutUnitPrice * 100 / price.buy)
					end
				end
			end
			scoreRemaining = scoreRemaining - 1
			CheckEnd()
		end
		
		local function AssignCompetition(itemType, competition)
			if itemType then
				for _, auctionID in ipairs(auctionsByItemType[itemType]) do
					local auctionData = auctions[auctionID]
					
					local buy = auctionData.buyoutUnitPrice
					local below, above, total = 0, 0, 1
					
					for competitionID, competitionData in pairs(competition) do
						local competitionBuy = competitionData.buyoutUnitPrice
						if competitionBuy and not competitionData.own then
							if buy < competitionBuy then 
								above = above + 1
							elseif buy > competitionBuy then 
								below = below + 1
							end
							total = total + 1
						end
					end
					
					auctionData.competitionBelow = below
					auctionData.competitionAbove = above
					auctionData.competitionQuintile = MFloor(below * 5 / total) + 1
					auctionData.competitionOrder = auctionData.competitionQuintile * 10000 + below
				end
			end
			competitionRemaining = competitionRemaining - 1
			CheckEnd()
		end
		
		for auctionID, auctionData in pairs(auctions) do
			if auctionData.buyoutUnitPrice then
				auctionsByItemType[auctionData.itemType] = auctionsByItemType[auctionData.itemType] or {}
				TInsert(auctionsByItemType[auctionData.itemType], auctionID)
			end
		end
		
		for itemType, auctions in pairs(auctionsByItemType) do
			competitionRemaining = competitionRemaining + 1
			GetActiveAuctionData(function(competition) AssignCompetition(itemType, competition) end, itemType)
			if GetPrices(function(prices) AssignScore(itemType, prices) end, itemType, 1, referencePrice, true) then
				scoreRemaining = scoreRemaining + 1
			end			
		end
		CheckEnd()	
	end
	
	GetOwnAuctionData(ProcessAuctions)
end

function InternalInterface.PGCExtensions.ScoreAuctions(callback, auctions)
	if type(callback) ~= "function" then return end
	
	local referencePrice = InternalInterface.AccountSettings.Scoring.ReferencePrice
	
	local remainingItemTypes = 1
	local itemTypes = {}
	
	for auctionID, auctionData in pairs(auctions) do
		local auctionItemType = auctionData.itemType
		itemTypes[auctionItemType] = itemTypes[auctionItemType] or {}
		TInsert(itemTypes[auctionItemType], auctionID)
	end
		
	local function AssignScore(itemType, prices)
		local price = prices and prices[referencePrice] or nil
		if itemType and price and price.buy and price.buy > 0 then
			for _, auctionID in ipairs(itemTypes[itemType]) do
				local auctionData = auctions[auctionID]
				if auctionData.buyoutUnitPrice then
					auctionData.score = MFloor(auctionData.buyoutUnitPrice * 100 / price.buy)
				end
			end
		end
		remainingItemTypes = remainingItemTypes - 1
		if remainingItemTypes <= 0 then
			callback(auctions)
		end
	end
	
	for itemType in pairs(itemTypes) do
		if GetPrices(function(prices) AssignScore(itemType, prices) end, itemType, 1, referencePrice, true) then
			remainingItemTypes = remainingItemTypes + 1
		end
	end
	AssignScore()	
end
