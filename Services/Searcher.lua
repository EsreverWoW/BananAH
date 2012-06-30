-- ***************************************************************************************************************************************************
-- * Services/Scanner.lua                                                                                                                            *
-- ***************************************************************************************************************************************************
-- * Processes auction scans and stores them in the auction DB                                                                                       *
-- ***************************************************************************************************************************************************
-- * 0.4.0  / 2012.05.31 / Baanano: Rewritten AHMonitoringService.lua                                                                                *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local MFloor = math.floor
local TInsert = table.insert

function PublicInterface.GetOwnAuctionsScored(callback)
	if type(callback) ~= "function" then return end
	
	local function ProcessAuctions(auctions)
		local remaining = 1
		
		local function AssignScore(auctionID, score)
			if auctionID then
				auctions[auctionID].score = score
			end
			remaining = remaining - 1
			if remaining <= 0 then
				callback(auctions)
			end
		end
		
		for auctionID, auctionData in pairs(auctions) do
			if auctionData.buyoutUnitPrice then
				remaining = remaining + 1
				PublicInterface.ScorePrice(function(score) AssignScore(auctionID, score) end, auctionData.itemType, auctionData.buyoutUnitPrice)
			end
		end
		AssignScore()
	end
	
	PublicInterface.GetOwnAuctionData(ProcessAuctions)
end

function PublicInterface.GetOwnAuctionsScoredCompetition(callback)
	if type(callback) ~= "function" then return end
	
	local function ProcessAuctions(auctions)
		local detailRemaining = 0
		local competitionRemaining = 0
		local auctionsByItemType = {}
		
		local function CheckEnd()
			if detailRemaining <= 0 and competitionRemaining <= 0 then
				callback(auctions)
			end
		end
		
		local function AssignScore(auctionID, score)
			if auctionID then
				auctions[auctionID].score = score
			end
			detailRemaining = detailRemaining - 1
			CheckEnd()
		end
		
		local function AssignCompetition(itemType, competition)
			if itemType then
				for auctionID, auctionData in pairs(auctionsByItemType[itemType]) do
					local buy = auctionData.buyoutUnitPrice
					local below, above, total = 0, 0, 1
					for competitionID, competitionData in pairs(competition) do
						if competitionData.buyoutUnitPrice and not competitionData.own then
							local competitionBuy = competitionData.buyoutUnitPrice
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
				end
			end
			competitionRemaining = competitionRemaining - 1
			CheckEnd()
		end
		
		for auctionID, auctionData in pairs(auctions) do
			if auctionData.buyoutUnitPrice then
				detailRemaining = detailRemaining + 1
				PublicInterface.ScorePrice(function(score) AssignScore(auctionID, score) end, auctionData.itemType, auctionData.buyoutUnitPrice)
				
				auctionsByItemType[auctionData.itemType] = auctionsByItemType[auctionData.itemType] or {}
				auctionsByItemType[auctionData.itemType][auctionID] = auctionData
			end
		end
		
		for itemType, auctions in pairs(auctionsByItemType) do
			competitionRemaining = competitionRemaining + 1
			PublicInterface.GetActiveAuctionData(function(competition) AssignCompetition(itemType, competition) end, itemType)
		end
		CheckEnd()	
	
	end
	
	PublicInterface.GetOwnAuctionData(ProcessAuctions)
end

function PublicInterface.GetActiveAuctionsScored(callback, item)
	if type(callback) ~= "function" then return end
	
	local function ProcessAuctions(auctions, lastSeen)
		local remaining = 1
		
		local function AssignScore(auctionID, score)
			if auctionID then
				auctions[auctionID].score = score
			end
			remaining = remaining - 1
			if remaining <= 0 then
				callback(auctions, lastSeen)
			end
		end
		
		for auctionID, auctionData in pairs(auctions) do
			if auctionData.buyoutUnitPrice then
				remaining = remaining + 1
				PublicInterface.ScorePrice(function(score) AssignScore(auctionID, score) end, auctionData.itemType, auctionData.buyoutUnitPrice)
			end
		end
		AssignScore()
	end
	
	PublicInterface.GetActiveAuctionData(ProcessAuctions, item)
end