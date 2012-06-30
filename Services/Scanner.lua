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

local MAX_DATA_AGE = 30 * 24 * 60 * 60

local OTime = os.time
local QueueTask = InternalInterface.Scheduler.QueueTask
local Priorities = InternalInterface.Scheduler.Priorities
local CYield = coroutine.yield
local IInteraction = Inspect.Interaction
local TInsert = table.insert
local IAuctionDetail = Inspect.Auction.Detail
local IUnitDetail = Inspect.Unit.Detail
local IIDetail = Inspect.Item.Detail
local MMax = math.max
local MMin = math.min
local TSort = table.sort

local auctionTable = {}
local auctionTableLoaded = false
local cachedAuctions = {}
local cachedItemTypes = {}
local alreadyMatched = {}
local backgroundScannerDisabled = false
local scanNext = false
local pendingPosts = {}
local nativeIndexer = InternalInterface.Utility.BuildNativeIndexer()
local ownIndex = {}
local AuctionDataEvent = Utility.Event.Create(addonID, "AuctionData")

InternalInterface.Scanner = InternalInterface.Scanner or {}

local function TryMatchAuction(auctionID)
	if alreadyMatched[auctionID] then return end
	
	local itemType = cachedAuctions[auctionID]
	local pending = itemType and pendingPosts[itemType] or nil
	local itemInfo = auctionTable[itemType]
	local auctionInfo = itemInfo and itemInfo.activeAuctions[auctionID] or nil
	
	if not pending or not auctionInfo then return end
	
	for index, pendingData in ipairs(pending) do
		if not pendingData.matched and pendingData.bid == auctionInfo.bid and pendingData.buy == auctionInfo.buy then
			auctionTable[itemType].activeAuctions[auctionID].minExpire = pendingData.timestamp + pendingData.tim * 3600 
			auctionTable[itemType].activeAuctions[auctionID].maxExpire = auctionInfo.firstSeen + pendingData.tim * 3600 
			pendingPosts[itemType][index].matched = true
			alreadyMatched[auctionID] = true
			return
		end
	end
	if not backgroundScannerDisabled then
		auctionTable[itemType].activeAuctions[auctionID].postPending = true
	end
end

local function TryMatchPost(itemType, tim, timestamp, bid, buyout)
	local itemInfo = auctionTable[itemType]
	local auctions = itemInfo and itemInfo.activeAuctions or {}
	for auctionID, auctionInfo in pairs(auctions) do
		if auctionInfo.postPending and bid == auctionInfo.bid and buyout == auctionInfo.buy then
			auctionTable[itemType].activeAuctions[auctionID].minExpire = timestamp + tim * 3600 
			auctionTable[itemType].activeAuctions[auctionID].maxExpire = auctionInfo.firstSeen + tim * 3600 
			auctionTable[itemType].activeAuctions[auctionID].postPending = nil
			alreadyMatched[auctionID] = true
			return
		end
	end
	if not backgroundScannerDisabled then
		pendingPosts[itemType] = pendingPosts[itemType] or {}
		TInsert(pendingPosts[itemType], { tim = tim, timestamp = timestamp, bid = bid, buy = buyout or 0 })
	end
end


local function OnAuctionData(criteria, auctions)
	if backgroundScannerDisabled and not scanNext then return end
	scanNext = false
	
	local auctionScanTime = OTime()
	local expireTimes = 
	{ 
		short =		{ auctionScanTime, 			auctionScanTime + 7200 }, 
		medium =	{ auctionScanTime + 7200, 	auctionScanTime + 43200 }, 
		long =		{ auctionScanTime + 43200, 	auctionScanTime + 172800 },
	}

	local totalAuctions, newAuctions, updatedAuctions, removedAuctions, beforeExpireAuctions = {}, {}, {}, {}, {}
	local totalItemTypes, newItemTypes, updatedItemTypes, removedItemTypes, modifiedItemTypes = {}, {}, {}, {}, {}
	
	local playerName = IUnitDetail("player").name
	
	local function ProcessItemType(itemType)
		if cachedItemTypes[itemType] then return end
		
		local itemDetail = IIDetail(itemType)

		local name, icon, rarity, level = itemDetail.name, itemDetail.icon, itemDetail.rarity or "", itemDetail.requiredLevel or 1
		local category, callings = itemDetail.category or "", itemDetail.requiredCalling
		callings =
		{
			warrior = (not callings or callings:find("warrior")) and true or nil,
			cleric = (not callings or callings:find("cleric")) and true or nil,
			rogue = (not callings or callings:find("rogue")) and true or nil,
			mage = (not callings or callings:find("mage")) and true or nil,
		}
		
		if not auctionTable[itemType] then
			auctionTable[itemType] =
			{
				name = name,
				icon = icon,
				rarity = rarity,
				level = level,
				category = category,
				callings = callings,
				activeAuctions = {},
				expiredAuctions = {},
			}
		else
			local oldData = auctionTable[itemType]
			
			local oldName = oldData.name
			local oldIcon = oldData.icon
			local oldRarity = oldData.rarity
			local oldLevel = oldData.level
			local oldCategory = oldData.category
			local oldCallings = oldData.callings
			
			if name ~= oldName or icon ~= oldIcon or rarity ~= oldRarity  or level ~= oldLevel or category ~= oldCategory or callings.warrior ~= oldCallings.warrior or callings.cleric ~= oldCallings.cleric or callings.rogue ~= oldCallings.rogue or callings.mage ~= oldCallings.mage then
				auctionTable[itemType].name = name
				auctionTable[itemType].icon = icon
				auctionTable[itemType].rarity = rarity
				auctionTable[itemType].level = level
				auctionTable[itemType].category = category
				auctionTable[itemType].callings = callings

				for auctionID, auctionData in pairs(oldData.activeAuctions) do
					nativeIndexer:RemoveAuction(auctionID, oldCallings, oldRarity, oldLevel, oldCategory, oldName, auctionData.buy)
					nativeIndexer:AddAuction(itemType, auctionID, callings, rarity, level, category, name, auctionData.buy)
				end
				
				modifiedItemTypes[itemType] = true
			end
		end		
		
		cachedItemTypes[itemType] = true
	end
	
	local function ProcessAuction(auctionID, auctionDetail)
		local itemType = auctionDetail.itemType
		
		ProcessItemType(itemType)
		cachedAuctions[auctionID] = itemType
		
		TInsert(totalAuctions, auctionID)
		totalItemTypes[itemType] = true
		
		local auctionData = auctionTable[itemType].activeAuctions[auctionID]
		if not auctionData then
			local itemTypeData = auctionTable[itemType]
			itemTypeData.activeAuctions[auctionID] = 
			{
				stack = auctionDetail.itemStack or 1,
				bid = auctionDetail.bid,
				buy = auctionDetail.buyout or 0,
				seller = auctionDetail.seller,
				firstSeen = auctionScanTime,
				lastSeen = auctionScanTime,
				minExpire = expireTimes[auctionDetail.time][1],
				maxExpire = expireTimes[auctionDetail.time][2],
				own = auctionDetail.seller == playerName and true or nil,
				bidded = auctionDetail.bidder and auctionDetail.bidder ~= "0" and true or nil,
				ownBidded = auctionDetail.bidder and auctionDetail.bidder == playerName and auctionDetail.bid or 0,
			}
			auctionData = itemTypeData.activeAuctions[auctionID]
			
			TInsert(newAuctions, auctionID)
			newItemTypes[itemType] = true
			
			nativeIndexer:AddAuction(itemType, auctionID, itemTypeData.callings, itemTypeData.rarity, itemTypeData.level, itemTypeData.category, itemTypeData.name, auctionDetail.buyout or 0)
			
			if auctionDetail.seller == playerName then
				TryMatchAuction(auctionID)
			end
		else
			auctionData.lastSeen = auctionScanTime
			auctionData.minExpire = MMax(auctionData.minExpire, expireTimes[auctionDetail.time][1])
			auctionData.maxExpire = MMin(auctionData.maxExpire, expireTimes[auctionDetail.time][2])
			auctionData.own = auctionData.own or auctionDetail.seller == playerName or nil
			auctionData.bidded = auctionData.bidded or (auctionDetail.bidder and auctionDetail.bidder ~= "0") or nil
			
			if auctionDetail.bidder and auctionDetail.bidder == playerName then auctionData.ownBidded = auctionDetail.bid end
			
			if auctionDetail.bid > auctionData.bid then
				auctionData.bid = auctionDetail.bid
				auctionData.bidded = true
				TInsert(updatedAuctions, auctionID)
				updatedItemTypes[itemType] = true
			end			
		end
		
		if auctionData.own then ownIndex[auctionID] = itemType end
	end
	
	local function ProcessAuctions()
		local preprocessingSuccessful = true
		
		for auctionID in pairs(auctions) do
			local ok, auctionDetail = pcall(IAuctionDetail, auctionID)
			if not ok or not auctionDetail then
				preprocessingSuccessful = false 
				break 
			end
			ProcessAuction(auctionID, auctionDetail)
			CYield()
		end

		if criteria.type == "search" then
			local auctionCount = 0
			if not preprocessingSuccessful then
				for auctionID in pairs(auctions) do auctionCount = auctionCount + 1  end
			else
				auctionCount = #totalAuctions
			end
			if not criteria.index or (criteria.index == 0 and auctionCount < 50) then
				local matchingAuctions = nativeIndexer:Search(criteria.role, criteria.rarity, criteria.levelMin, criteria.levelMax, criteria.category, criteria.priceMin, criteria.priceMax, criteria.text)
				for auctionID, itemType in pairs(matchingAuctions) do
					if not auctions[auctionID] then
						local itemData = auctionTable[itemType]
						local auctionData = itemData.activeAuctions[auctionID]

						TInsert(removedAuctions, auctionID)
						removedItemTypes[itemType] = true
						if auctionScanTime < auctionData.minExpire then
							auctionData.beforeExpiration = true
							TInsert(beforeExpireAuctions, auctionID)
						end
						
						nativeIndexer:RemoveAuction(auctionID, itemData.callings, itemData.rarity, itemData.level, itemData.category, itemData.name, auctionData.buy)
						ownIndex[auctionID] = nil
						
						itemData.expiredAuctions[auctionID] = auctionData
						itemData.activeAuctions[auctionID] = nil
					end
					CYield()
				end
			end
		elseif criteria.type == "mine" then
			for auctionID, itemType in pairs(ownIndex) do
				local itemData = auctionTable[itemType]
				local auctionData = itemData.activeAuctions[auctionID]
				if not auctions[auctionID] and auctionData.seller == playerName then
					TInsert(removedAuctions, auctionID)
					removedItemTypes[itemType] = true
					if auctionScanTime < auctionData.minExpire then
						auctionData.beforeExpiration = true
						TInsert(beforeExpireAuctions, auctionID)
					end
					
					nativeIndexer:RemoveAuction(auctionID, itemData.callings, itemData.rarity, itemData.level, itemData.category, itemData.name, auctionData.buy)
					ownIndex[auctionID] = nil
					
					itemData.expiredAuctions[auctionID] = auctionData
					itemData.activeAuctions[auctionID] = nil
				end
				CYield()
			end
		end

		if criteria.sort and criteria.sort == "time" and criteria.sortOrder then
			local knownAuctions = {}
			if preprocessingSuccessful then
				knownAuctions = totalAuctions
			else
				for auctionID in pairs(auctions) do
					if cachedAuctions[auctionID] then
						TInsert(knownAuctions, auctionID)
					end
				end
			end
			
			if criteria.sortOrder == "descending" then
				TSort(knownAuctions, function(a,b) return auctions[a] < auctions[b] end)
			else
				TSort(knownAuctions, function(a,b) return auctions[b] < auctions[a] end)
			end
			for index = 2, #knownAuctions, 1 do
				local auctionID = knownAuctions[index]
				local prevAuctionID = knownAuctions[index - 1]
				
				local auctionMET = auctionTable[cachedAuctions[auctionID]].activeAuctions[auctionID].minExpire
				local prevAuctionMET = auctionTable[cachedAuctions[prevAuctionID]].activeAuctions[prevAuctionID].minExpire
				
				if auctionMET < prevAuctionMET then
					auctionTable[cachedAuctions[auctionID]].activeAuctions[auctionID].minExpire = prevAuctionMET
				end
				CYield()
			end
			for index = #knownAuctions - 1, 1, -1 do
				local auctionID = knownAuctions[index]
				local nextAuctionID = knownAuctions[index + 1]
				
				local auctionXET = auctionTable[cachedAuctions[auctionID]].activeAuctions[auctionID].maxExpire
				local nextAuctionXET = auctionTable[cachedAuctions[nextAuctionID]].activeAuctions[nextAuctionID].maxExpire
				
				if auctionXET > nextAuctionXET then
					auctionTable[cachedAuctions[auctionID]].activeAuctions[auctionID].maxExpire = nextAuctionXET
				end
				CYield()
			end
		end		
	end
	
	local function ProcessCompleted()
		AuctionDataEvent(criteria.type, totalAuctions, newAuctions, updatedAuctions, removedAuctions, beforeExpireAuctions, totalItemTypes, newItemTypes, updatedItemTypes, removedItemTypes, modifiedItemTypes)
	end
	
	QueueTask(Priorities.CRITICAL, ProcessAuctions, ProcessCompleted)
end
TInsert(Event.Auction.Scan, { OnAuctionData, addonID, "Scanner.OnAuctionData" })

local function UnpackAuctionTable(packedDB)
	if type(packedDB) ~= "table" or not packedDB.DICT2 then return packedDB end
	print("Upgrading 0.3.0 Auction DB...")
	
	local unpackedDB = {}

	local dictionary = {}
	local sDictionary = (packedDB.DICT2 or "") .. "►"
	sDictionary:gsub("([^►]*)►", function(c) dictionary[#dictionary + 1] = c end)
	setmetatable(dictionary, { __index = function(tab, key) return rawget(tab, tonumber(key, 16)) or key end, })
	
	for _, itemPackedData in ipairs(packedDB) do
		local itemData = {}
		local sItemData = itemPackedData
		sItemData:gsub("([^◄]*)◄", function(c) itemData[#itemData + 1] = c end)
		
		local itemType = itemData[1] .. ","
		itemType = { itemType:match((itemType:gsub("[^,]*,", "([^,]*),"))) }
		itemType = table.concat({ dictionary[itemType[1]], itemType[2], dictionary[itemType[3]], dictionary[itemType[4]], dictionary[itemType[5]], dictionary[itemType[6]], dictionary[itemType[7]], itemType[8], }, ",")

		local name = dictionary[itemData[2]]
		local rarity = dictionary[itemData[3]]
		local level = tonumber(dictionary[itemData[4]], 16)
		local category = dictionary[itemData[5]]
		local icon = dictionary[itemData[6]]
		local callings = tonumber(dictionary[itemData[7]], 16)
		callings = { warrior = bit.band(callings, 8) > 0 and true or nil, cleric = bit.band(callings, 4) > 0 and true or nil, rogue = bit.band(callings, 2) > 0 and true or nil, mage = bit.band(callings, 1) > 0 and true or nil, }

		local auctionData = {}
		local sAuctionData = itemPackedData .. "►"
		sAuctionData:gsub("([^►]*)►", function(c) auctionData[#auctionData + 1] = c end)
		
		local activeAuctions = {}
		local expiredAuctions = {}
		for index = 2, #auctionData do
			local auctionData = auctionData[index] .. ","
			auctionData = { auctionData:match((auctionData:gsub("[^,]+,", "([^,]*),"))) }
			
			local auctionID = string.format("o%08s%08s", dictionary[auctionData[1]], auctionData[2])
			local buy = tonumber(dictionary[auctionData[5]], 16)
			local rbe = tonumber(auctionData[12])
			if rbe == 0 then
				activeAuctions[auctionID] = 
				{ 
					stack = tonumber(auctionData[3], 16),
					bid = tonumber(dictionary[auctionData[4]], 16),
					buy = buy, 
					seller = dictionary[auctionData[6]],
					firstSeen = tonumber(dictionary[auctionData[7]], 16),
					lastSeen = tonumber(dictionary[auctionData[8]], 16),
					minExpire = tonumber(dictionary[auctionData[9]], 16),
					maxExpire = tonumber(dictionary[auctionData[10]], 16),
					own = tonumber(auctionData[13]) > 0 and true or nil,
					bidded = tonumber(auctionData[11]) > 0 and true or nil,
					beforeExpiration = rbe == 2 and true or nil,  
					ownBidded = tonumber(auctionData[14]), 
					ownBought = tonumber(auctionData[15]) > 0 and true or nil,
					cancelled = tonumber(auctionData[16]) > 0 and true or nil,
				}
			else
				expiredAuctions[auctionID] = 
				{ 
					stack = tonumber(auctionData[3], 16),
					bid = tonumber(dictionary[auctionData[4]], 16),
					buy = buy, 
					seller = dictionary[auctionData[6]],
					firstSeen = tonumber(dictionary[auctionData[7]], 16),
					lastSeen = tonumber(dictionary[auctionData[8]], 16),
					minExpire = tonumber(dictionary[auctionData[9]], 16),
					maxExpire = tonumber(dictionary[auctionData[10]], 16),
					own = tonumber(auctionData[13]) > 0 and true or nil,
					bidded = tonumber(auctionData[11]) > 0 and true or nil,
					beforeExpiration = rbe == 2 and true or nil,  
					ownBidded = tonumber(auctionData[14]), 
					ownBought = tonumber(auctionData[15]) > 0 and true or nil,
					cancelled = tonumber(auctionData[16]) > 0 and true or nil,
				}
			end
		end

		unpackedDB[itemType] =
		{
			name = name,
			icon = icon,
			rarity = rarity,
			level = level,
			category = category,
			callings = callings,
			activeAuctions = activeAuctions,
			expiredAuctions = expiredAuctions,
		}
	end
	
	return unpackedDB
end

local function LoadAuctionTable(addonId)
	if addonId == addonID then
		if type(_G[addonID .. "AuctionTable"]) == "string" then
			auctionTable = loadstring("return " .. zlib.inflate()(_G[addonID .. "AuctionTable"]))
			auctionTable = auctionTable and auctionTable() or {}
			auctionTable = UnpackAuctionTable(auctionTable)
		elseif type(_G[addonID .. "AuctionTable"]) == "table" then
			auctionTable = _G[addonID .. "AuctionTable"]
		else
			auctionTable = {}
		end

		for itemType, itemData in pairs(auctionTable) do
			if itemData.activeAuctions then
				for auctionID, auctionData in pairs(itemData.activeAuctions) do
					nativeIndexer:AddAuction(itemType, auctionID, itemData.callings, itemData.rarity, itemData.level, itemData.category, itemData.name, auctionData.buy)
					if auctionData.own then ownIndex[auctionID] = itemType end
				end
			else
				auctionTable = {}
				break
			end
		end

		auctionTableLoaded = true
	end
end
TInsert(Event.Addon.SavedVariables.Load.End, {LoadAuctionTable, addonID, "Scanner.LoadAuctionData"})

local function SaveAuctionTable(addonId)
	if addonId == addonID and auctionTableLoaded then
		local purgeTime = OTime() - MAX_DATA_AGE
		
		for itemType, itemData in pairs(auctionTable) do
			local hasAuctions = false
			for auctionID, auctionData in pairs(itemData.activeAuctions) do
				auctionData.postPending = nil
				hasAuctions = true
				break
			end
			for auctionID, auctionData in pairs(itemData.expiredAuctions) do
				if auctionData.lastSeen < purgeTime then
					auctionTable[itemType].expiredAuctions[auctionID] = nil
				else
					hasAuctions = true
				end
			end
			if not hasAuctions then
				auctionTable[itemType] = nil
			end
		end
		
		_G[addonID .. "AuctionTable"] = auctionTable
	end
end
TInsert(Event.Addon.SavedVariables.Save.Begin, {SaveAuctionTable, addonID, "Scanner.SaveAuctionData"})

local function ProcessAuctionBuy(auctionID)
	local itemType = cachedAuctions[auctionID]
	local itemInfo = itemType and auctionTable[itemType] or nil
	local auctionInfo = itemInfo and itemInfo.activeAuctions[auctionID] or nil
	
	if auctionInfo then
		nativeIndexer:RemoveAuction(auctionID, itemInfo.callings, itemInfo.rarity, itemInfo.level, itemInfo.category, itemInfo.name, auctionInfo.buy)
		ownIndex[auctionID] = nil
		
		auctionInfo.ownBought = true
		auctionInfo.beforeExpiration = true
		
		itemInfo.expiredAuctions[auctionID] = auctionInfo
		itemInfo.activeAuctions[auctionID] = nil
		
		AuctionDataEvent("playerbuy", {auctionID}, {}, {}, {auctionID}, {auctionID}, {itemType = true}, {}, {}, {itemType = true}, {})
	end
end
function InternalInterface.Scanner.AuctionBuyCallback(auctionID, failed)
	if failed then return end
	QueueTask(Priorities.CRITICAL, function() ProcessAuctionBuy(auctionID) end)
end

local function  ProcessAuctionBid(auctionID, amount)
	local itemType = cachedAuctions[auctionID]
	local itemInfo = itemType and auctionTable[itemType] or nil
	local auctionInfo = itemInfo and itemInfo.activeAuctions[auctionID] or nil
	
	if auctionInfo then
		if auctionInfo.buy and auctionInfo.buy > 0 and amount >= auctionInfo.buy then
			ProcessAuctionBuy(auctionID)
		else
			auctionInfo.bidded = true
			auctionInfo.bid = amount
			auctionInfo.ownBidded = amount
			AuctionDataEvent("playerbid", {auctionID}, {}, {auctionID}, {}, {}, {itemType = true}, {}, {itemType = true}, {}, {})
		end
	end
end
function InternalInterface.Scanner.AuctionBidCallback(auctionID, amount, failed)
	if failed then return end
	QueueTask(Priorities.CRITICAL, function() ProcessAuctionBid(auctionID, amount) end)
end

function InternalInterface.Scanner.AuctionPostCallback(itemType, tim, timestamp, bid, buyout, failed)
	if not failed then
		QueueTask(Priorities.CRITICAL, function() TryMatchPost(itemType, tim, timestamp, bid, buyout or 0) end)
	end
end

local function ProcessAuctionCancel(auctionID)
	local itemType = cachedAuctions[auctionID]
	local itemInfo = itemType and auctionTable[itemType] or nil
	local auctionInfo = itemInfo and itemInfo.activeAuctions[auctionID] or nil

	if auctionInfo then
		nativeIndexer:RemoveAuction(auctionID, itemInfo.callings, itemInfo.rarity, itemInfo.level, itemInfo.category, itemInfo.name, auctionInfo.buy)
		ownIndex[auctionID] = nil
		
		auctionInfo.cancelled = true
		auctionInfo.beforeExpiration = true
		
		itemInfo.expiredAuctions[auctionID] = auctionInfo
		itemInfo.activeAuctions[auctionID] = nil
		
		AuctionDataEvent("playercancel", {auctionID}, {}, {}, {auctionID}, {auctionID}, {itemType = true}, {}, {}, {itemType = true}, {})
	end
end
function InternalInterface.Scanner.AuctionCancelCallback(auctionID, failed)
	if failed then return end
	QueueTask(Priorities.CRITICAL, function() ProcessAuctionCancel(auctionID) end)
end

function InternalInterface.ScanNext()
	scanNext = true
end



local function GetAuctionData(itemType, auctionID)
	itemType = itemType or (auctionID and cachedAuctions[auctionID])
	if not itemType or not auctionTable[itemType] then return nil end
	
	local auctionData = auctionTable[itemType].activeAuctions[auctionID] or auctionTable[itemType].expiredAuctions[auctionID]
	if not auctionData then return nil end
	
	return
	{
		active = auctionTable[itemType].activeAuctions[auctionID] and true or false,
		itemType = itemType,
		itemName = auctionTable[itemType].name,
		itemIcon = auctionTable[itemType].icon,
		itemRarity = auctionTable[itemType].rarity,
		stack = auctionData.stack,
		bidPrice = auctionData.bid,
		buyoutPrice = auctionData.buy ~= 0 and auctionData.buy or nil,
		bidUnitPrice = auctionData.bid / auctionData.stack,
		buyoutUnitPrice = auctionData.buy ~= 0 and (auctionData.buy / auctionData.stack) or nil,
		sellerName = auctionData.seller,
		firstSeenTime = auctionData.firstSeen,
		lastSeenTime = auctionData.lastSeen,
		minExpireTime = auctionData.minExpire,
		maxExpireTime = auctionData.maxExpire,
		own = auctionData.own or false,
		bidded = auctionData.bidded or false,
		removedBeforeExpiration = auctionData.beforeExpiration or false,
		ownBidded = auctionData.ownBidded,
		ownBought = auctionData.ownBought or false,
		cancelled = auctionData.cancelled or false,
	}
end
PublicInterface.GetAuctionData = GetAuctionData

local function SearchAuctionsAsync(calling, rarity, levelMin, levelMax, category, priceMin, priceMax, name)
	local auctions = nativeIndexer:Search(calling, rarity, levelMin, levelMax, category, priceMin, priceMax, name)
	for auctionID, itemType in pairs(auctions) do
		auctions[auctionID] = GetAuctionData(itemType, auctionID)
		CYield()
	end
	return auctions
end
function PublicInterface.SearchAuctions(callback, calling, rarity, levelMin, levelMax, category, priceMin, priceMax, name)
	if type(callback) ~= "function" then return end
	QueueTask(Priorities.HIGH, function() return SearchAuctionsAsync(calling, rarity, levelMin, levelMax, category, priceMin, priceMax, name) end, callback)
end

local function GetAuctionDataAsync(item, startTime, endTime, excludeExpired)
	local auctions = {}
	local lastSeen = 0
	
	startTime = startTime or 0
	endTime = endTime or OTime()
	
	if not item then
		for itemType, itemInfo in pairs(auctionTable) do
			for auctionID in pairs(itemInfo.activeAuctions) do
				local auctionData = GetAuctionData(itemType, auctionID)
				if auctionData then
					if auctionData.lastSeenTime >= startTime and auctionData.firstSeenTime <= endTime then
						auctions[auctionID] = auctionData
					end
					lastSeen = MMax(lastSeen, auctionData.lastSeenTime)
				end
				CYield()
			end
			
			for auctionID in pairs(itemInfo.expiredAuctions) do
				local auctionData = GetAuctionData(itemType, auctionID)
				if auctionData then
					if not excludeExpired and auctionData.lastSeenTime >= startTime and auctionData.firstSeenTime <= endTime then
						auctions[auctionID] = auctionData
					end
					lastSeen = MMax(lastSeen, auctionData.lastSeenTime)
				end
				CYield()
			end
		end
	else
		local itemType = nil
		if item:sub(1, 1) == "I" then
			itemType = item
		else
			local ok, itemDetail = pcall(IIDetail, item)
			itemType = ok and itemDetail and itemDetail.type or nil
		end
		
		local itemInfo = itemType and auctionTable[itemType] or nil
		if not itemInfo then return {}, lastSeen end
		
		for auctionID in pairs(itemInfo.activeAuctions) do
			local auctionData = GetAuctionData(itemType, auctionID)
			if auctionData then
				if auctionData.lastSeenTime >= startTime and auctionData.firstSeenTime <= endTime then
					auctions[auctionID] = auctionData
				end
				lastSeen = MMax(lastSeen, auctionData.lastSeenTime)
			end
			CYield()
		end
		
		for auctionID in pairs(itemInfo.expiredAuctions) do
			local auctionData = GetAuctionData(itemType, auctionID)
			if auctionData then
				if not excludeExpired and auctionData.lastSeenTime >= startTime and auctionData.firstSeenTime <= endTime then
					auctions[auctionID] = auctionData
				end
				lastSeen = MMax(lastSeen, auctionData.lastSeenTime)
			end
			CYield()
		end
	end
	
	return auctions, lastSeen
end

function PublicInterface.GetAllAuctionData(callback, item, startTime, endTime)
	if type(callback) ~= "function" then return end
	QueueTask(Priorities.HIGH, function() return { GetAuctionDataAsync(item, startTime, endTime, false) } end, function(result) callback(unpack(result)) end)
end

function PublicInterface.GetActiveAuctionData(callback, item)
	if type(callback) ~= "function" then return end
	QueueTask(Priorities.HIGH, function() return { GetAuctionDataAsync(item, nil, nil, true) } end, function(result) callback(unpack(result)) end)
end

local function GetOwnAuctionDataAsync()
	local auctions = {}
	for auctionID, itemType in pairs(ownIndex) do
		auctions[auctionID] = GetAuctionData(itemType, auctionID)
		CYield()
	end
	return auctions
end

function PublicInterface.GetOwnAuctionData(callback)
	if type(callback) ~= "function" then return end
	QueueTask(Priorities.HIGH, GetOwnAuctionDataAsync, callback)
end	


function PublicInterface.GetAuctionCached(auctionID)
	return cachedAuctions[auctionID] and true or false
end

function PublicInterface.GetBackgroundScannerEnabled()
	return not backgroundScannerDisabled
end

function PublicInterface.SetBackgroundScannerEnabled(enabled)
	backgroundScannerDisabled = not enabled
end
