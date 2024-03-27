-- ***************************************************************************************************************************************************
-- * PGCExtensions.lua                                                                                                                               *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.01 / Baanano: Updated for 0.4.1                                                                                                 *
-- * 0.4.0 / 2012.05.31 / Baanano: Rewritten AHMonitoringService.lua                                                                                 *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local GetActiveAuctionData = LibPGC.GetActiveAuctionData
local GetOwnAuctionData = LibPGC.GetOwnAuctionData
local GetPrices = LibPGCEx.GetPrices

InternalInterface.PGCExtensions = InternalInterface.PGCExtensions or {}

function InternalInterface.PGCExtensions.GetActiveAuctionsScored(item)
	return blTasks.Task.Create(
		function(taskHandle)
			local referencePrice = InternalInterface.AccountSettings.Scoring.ReferencePrice
			local activeAuctions = LibPGC.Search.Active(item):Result()
			
			local itemTypes = {}
			
			for auctionID, auctionData in pairs(activeAuctions) do
				local auctionItemType = auctionData.itemType
				itemTypes[auctionItemType] = itemTypes[auctionItemType] or {}
				itemTypes[auctionItemType][#itemTypes[auctionItemType] + 1] = auctionID
			end

			local priceTasks = {}
			for itemType in pairs(itemTypes) do
				priceTasks[itemType] = LibPGCEx.Price.Calculate(itemType, referencePrice, 1, true)
			end

			taskHandle:Wait(blTasks.Wait.Children())
			
			local prices = {}
			for itemType, priceTask in pairs(priceTasks) do
				local ok, price = pcall(priceTask.Result, priceTask)
				if ok then
					prices[itemType] = price and price[referencePrice] and price[referencePrice].buy and price[referencePrice].buy > 0 and price[referencePrice].buy or nil
				end
			end
			
			for auctionID, auctionData in pairs(activeAuctions) do
				if auctionData.buyoutUnitPrice > 0 and prices[auctionData.itemType] then
					auctionData.score = math.floor(auctionData.buyoutUnitPrice * 100 / prices[auctionData.itemType])
				end
			end
			
			return activeAuctions			
		end):Start()
end

function InternalInterface.PGCExtensions.GetOwnAuctionsScoredCompetition()
	return blTasks.Task.Create(
		function(taskHandle)
			local referencePrice = InternalInterface.AccountSettings.Scoring.ReferencePrice
			local activeAuctions = LibPGC.Search.Active():Result()
			
			local itemTypes = {}
			local ownItemTypes = {}
			local ownAuctions = {}
			
			for auctionID, auctionData in pairs(activeAuctions) do
				local auctionItemType = auctionData.itemType
				
				itemTypes[auctionItemType] = itemTypes[auctionItemType] or {}
				itemTypes[auctionItemType][#itemTypes[auctionItemType] + 1] = auctionID
				
				if auctionData.own then
					ownAuctions[auctionID] = auctionData
					ownItemTypes[auctionItemType] = true
				end
				
				taskHandle:BreathShort()
			end
			
			local priceTasks = {}
			for itemType in pairs(ownItemTypes) do
				priceTasks[itemType] = LibPGCEx.Price.Calculate(itemType, referencePrice, 1, true)
			end
			
			for auctionID, auctionData in pairs(ownAuctions) do
				local auctionItemType = auctionData.itemType
				local buy = auctionData.buyoutUnitPrice and auctionData.buyoutUnitPrice > 0 and auctionData.buyoutUnitPrice or nil
				
				local ok, price = pcall(priceTasks[auctionItemType].Result, priceTasks[auctionItemType])
				local scorePrice = ok and price and price[referencePrice] and price[referencePrice].buy > 0 and price[referencePrice].buy or nil
				
				local below, above, total = 0, 0, 1
				
				auctionData.competition = {}
				
				for index = 1, #itemTypes[auctionItemType] do
					local competitionID = itemTypes[auctionItemType][index]
					local competitionData = activeAuctions[competitionID]
					local competitionBuy = competitionData.buyoutUnitPrice
					
					competitionData.score = competitionBuy and scorePrice and math.floor(competitionBuy * 100 / scorePrice)
					auctionData.competition[competitionID] = competitionData

					if buy and competitionBuy and competitionBuy > 0 and not competitionData.own then
						total = total + 1
						
						if buy < competitionBuy then
							above = above + 1
						elseif buy > competitionBuy then
							below = below + 1
						end
					end
				end
				
				auctionData.competitionBelow = below
				auctionData.competitionAbove = above
				auctionData.competitionQuintile = math.floor(below * 5 / total) + 1
				auctionData.competitionOrder = auctionData.competitionQuintile * 10000 + below
				
				taskHandle:BreathShort()
			end
			
			return ownAuctions
		end):Start()
end

--[[
function InternalInterface.PGCExtensions.ScoreAuctions(callback, auctions)
	if type(callback) ~= "function" then return end
	
	local referencePrice = InternalInterface.AccountSettings.Scoring.ReferencePrice
	
	local remainingItemTypes = 1
	local itemTypes = {}
	
	for auctionID, auctionData in pairs(auctions) do
		local auctionItemType = auctionData.itemType
		itemTypes[auctionItemType] = itemTypes[auctionItemType] or {}
		table.insert(itemTypes[auctionItemType], auctionID)
	end
		
	local function AssignScore(itemType, prices)
		local price = prices and prices[referencePrice] or nil
		if itemType and price and price.buy and price.buy > 0 then
			for _, auctionID in ipairs(itemTypes[itemType]) do
				local auctionData = auctions[auctionID]
				if auctionData.buyoutUnitPrice then
					auctionData.score = math.floor(auctionData.buyoutUnitPrice * 100 / price.buy)
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
]]
