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

function InternalInterface.PGCExtensions.ScoreAuctions(auctions)
	return blTasks.Task.Create(
		function(taskHandle)
			local referencePrice = InternalInterface.AccountSettings.Scoring.ReferencePrice
			
			local prices = {}
			local numItemTypes = 0

			for auctionID, auctionData in pairs(auctions) do
				local itemType = auctionData.itemType
				
				if auctionData.buyoutUnitPrice > 0 then
					if prices[itemType] == nil then
						local priceTask = LibPGCEx.Price.Calculate(itemType, referencePrice, 1, true)
						local ok, price = pcall(priceTask.Result, priceTask)
						prices[itemType] = ok and price and price[referencePrice] and price[referencePrice].buy and price[referencePrice].buy > 0 and price[referencePrice].buy or false
					end
					
					if prices[itemType] then
						auctionData.score = math.floor(auctionData.buyoutUnitPrice * 100 / prices[itemType])
					end
				end
			end
			
			return auctions
		end):Start()
end

function InternalInterface.PGCExtensions.GetOwnAuctionsScoredCompetition()
	return blTasks.Task.Create(
		function(taskHandle)
			local referencePrice = InternalInterface.AccountSettings.Scoring.ReferencePrice
			
			local ownAuctions = LibPGC.Search.Own():Result()
			
			local prices = {}
			local auctions = {}

			for auctionID, auctionData in pairs(ownAuctions) do
				local itemType = auctionData.itemType
				
				if prices[itemType] == nil then
					local priceTask = LibPGCEx.Price.Calculate(itemType, referencePrice, 1, true)
					local ok, price = pcall(priceTask.Result, priceTask)
					prices[itemType] = ok and price and price[referencePrice] and price[referencePrice].buy and price[referencePrice].buy > 0 and price[referencePrice].buy or false
				end
				
				auctions[itemType] = auctions[itemType] or LibPGC.Search.Active(itemType):Result()
				
				local buy = auctionData.buyoutUnitPrice and auctionData.buyoutUnitPrice > 0 and auctionData.buyoutUnitPrice or nil
				local scorePrice = prices[itemType]
				
				local below, above, total = 0, 0, 1
				
				auctionData.competition = {}
				
				for competitionID, competitionData in pairs(auctions[itemType]) do
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
				
				auctionData.score = auctionData.competition[auctionID].score
				auctionData.competitionBelow = below
				auctionData.competitionAbove = above
				auctionData.competitionQuintile = math.floor(below * 5 / total) + 1
				auctionData.competitionOrder = auctionData.competitionQuintile * 10000 + below
				
				taskHandle:BreathShort()
			end
			
			return ownAuctions
		end):Start()
end

function InternalInterface.PGCExtensions.GetActiveAuctionsScored(item)
	return blTasks.Task.Create(
		function(taskHandle)
			return InternalInterface.PGCExtensions.ScoreAuctions(LibPGC.Search.Active(item):Result()):Result()
		end):Start()
end

