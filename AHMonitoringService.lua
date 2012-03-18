local _, InternalInterface = ...

local FixItemType = InternalInterface.Utility.FixItemType
local NormalizeItemType = InternalInterface.Utility.NormalizeItemType
local CopyTableSimple = InternalInterface.Utility.CopyTableSimple

-- AH Monitoring Service
local auctionTable = {}
local cachedAuctions = {}
local AuctionDataEvent = Utility.Event.Create("BananAH", "AuctionData")

local function OnAuctionData(type, auctions)
	if not Inspect.Interaction("auction") then return end
	if type.type ~= "search" then return end

	local auctionScanTime = os.time()
	local playerFaction = Inspect.Unit.Detail("player").faction
	if playerFaction ~= "guardian" and playerFaction ~= "defiant" then return end

	local totalAuctionCount = 0
	local newAuctionCount = 0
	local updatedAuctionCount = 0
	local removedAuctionCount = 0
	local beforeExpireAuctionCount = 0
	
	local scanData = {}
	local auctionsDetail = Inspect.Auction.Detail(auctions)
	for auctionID, auctionDetail in pairs(auctionsDetail) do
		cachedAuctions[auctionID] = true
		local itemDetail = Inspect.Item.Detail(auctionDetail.item)
		local normalizedItemType = NormalizeItemType(itemDetail.type, itemDetail.rarity)
		scanData[normalizedItemType] = scanData[normalizedItemType] or { auctions = {} }
		scanData[normalizedItemType].auctions[auctionID] = 
		{
			itemType = FixItemType(itemDetail.type),
			stack = (itemDetail.stack or 1),
			bidPrice = auctionDetail.bid, 
			buyoutPrice = auctionDetail.buyout, 
			remainingTime = auctionDetail.time, 
			sellerName = auctionDetail.seller,  
		}
		totalAuctionCount = totalAuctionCount + 1
	end
	
	local fullScan = (not type.index or (type.index == 0 and totalAuctionCount < 50)) 
	                 and not type.category 
	                 and (not type.levelMin or type.levelMin <= 0) 
					 and (not type.levelMax or type.levelMax >= 50)
					 and (not type.priceMin or type.priceMin <= 0)
					 and not type.priceMax
					 and not type.rarity 
					 and not type.role
	local trueFullScan = fullScan and not type.text
	
	for normalizedItemType, scanDetail in pairs(scanData) do
		auctionTable[playerFaction][normalizedItemType] = auctionTable[playerFaction][normalizedItemType] or { auctions = {} }
		auctionTable[playerFaction][normalizedItemType].activeAuctions = true
	
		for auctionID, auctionDetail in pairs(scanDetail.auctions) do
			local minExpirationTime = 0
			local maxExpirationTime = 0
			if auctionDetail.remainingTime == "short" then
				minExpirationTime = auctionScanTime
				maxExpirationTime = auctionScanTime + 7200
			elseif auctionDetail.remainingTime == "medium" then
				minExpirationTime = auctionScanTime + 7200
				maxExpirationTime = auctionScanTime + 43200
			else
				minExpirationTime = auctionScanTime + 43200
				maxExpirationTime = auctionScanTime + 172800
			end
		
			if not auctionTable[playerFaction][normalizedItemType].auctions[auctionID] then
				auctionTable[playerFaction][normalizedItemType].auctions[auctionID] = 
				{
					itemType = auctionDetail.itemType,
					stack = auctionDetail.stack,
					bidPrice = auctionDetail.bidPrice,
					buyoutPrice = auctionDetail.buyoutPrice,
					sellerName = auctionDetail.sellerName,
					firstSeenTime = auctionScanTime,
					lastSeenTime = auctionScanTime,
					minExpireTime = minExpirationTime,
					maxExpireTime = maxExpirationTime,
				}
				newAuctionCount = newAuctionCount + 1
			else
				auctionTable[playerFaction][normalizedItemType].auctions[auctionID].lastSeenTime = auctionScanTime
				auctionTable[playerFaction][normalizedItemType].auctions[auctionID].minExpireTime = math.max(auctionTable[playerFaction][normalizedItemType].auctions[auctionID].minExpireTime, minExpirationTime)
				auctionTable[playerFaction][normalizedItemType].auctions[auctionID].maxExpireTime = math.min(auctionTable[playerFaction][normalizedItemType].auctions[auctionID].maxExpireTime, maxExpirationTime)
				if auctionTable[playerFaction][normalizedItemType].auctions[auctionID].bidPrice ~= auctionDetail.bidPrice then
					auctionTable[playerFaction][normalizedItemType].auctions[auctionID].bidPrice = auctionDetail.bidPrice
					auctionTable[playerFaction][normalizedItemType].auctions[auctionID].bidded = true
					updatedAuctionCount = updatedAuctionCount + 1
				end
			end			
		end

		if fullScan then 
			for oldAuctionID, oldAuctionDetail in pairs(auctionTable[playerFaction][normalizedItemType].auctions) do repeat
				if scanDetail.auctions[oldAuctionID] then break end
				if oldAuctionDetail.removedBeforeExpiration == nil then
					removedAuctionCount = removedAuctionCount + 1
					if auctionScanTime < oldAuctionDetail.minExpireTime then 
						auctionTable[playerFaction][normalizedItemType].auctions[oldAuctionID].removedBeforeExpiration = true
						beforeExpireAuctionCount = beforeExpireAuctionCount + 1
					else
						auctionTable[playerFaction][normalizedItemType].auctions[oldAuctionID].removedBeforeExpiration = false
					end
				end
			until true end
			auctionTable[playerFaction][normalizedItemType].lastFullScanTime = auctionScanTime
		end
	end
	if trueFullScan then
		for normalizedItemType, scanDetail in pairs(auctionTable[playerFaction]) do repeat
			if scanDetail.activeAuctions and (scanDetail.lastFullScanTime or 0) >= auctionScanTime then break end
			for oldAuctionID, oldAuctionDetail in pairs(scanDetail.auctions) do
				if oldAuctionDetail.removedBeforeExpiration == nil then
					removedAuctionCount = removedAuctionCount + 1
					if auctionScanTime < oldAuctionDetail.minExpireTime then 
						auctionTable[playerFaction][normalizedItemType].auctions[oldAuctionID].removedBeforeExpiration = true
						beforeExpireAuctionCount = beforeExpireAuctionCount + 1
					else
						auctionTable[playerFaction][normalizedItemType].auctions[oldAuctionID].removedBeforeExpiration = false
					end
				end
			end
			auctionTable[playerFaction][normalizedItemType].activeAuctions = nil
			auctionTable[playerFaction][normalizedItemType].lastFullScanTime = auctionScanTime
		until true end
	end
	AuctionDataEvent(fullScan, totalAuctionCount, newAuctionCount, updatedAuctionCount, removedAuctionCount, beforeExpireAuctionCount)
end
table.insert(Event.Auction.Scan, { OnAuctionData, "BananAH", "OnAuctionData" })

local function LoadAuctionTable(addonId)
	if addonId == "BananAH" then
		auctionTable = BananAHAuctionTable or {}
		auctionTable.guardian = auctionTable.guardian or {}
		auctionTable.defiant = auctionTable.defiant or {}
	end
end
table.insert(Event.Addon.SavedVariables.Load.End, {LoadAuctionTable, "BananAH", "LoadAuctionData"})

local function SaveAuctionTable(addonId)
	if addonId == "BananAH" and _G.BananAH.isLoaded then
		BananAHAuctionTable = auctionTable
	end
end
table.insert(Event.Addon.SavedVariables.Save.Begin, {SaveAuctionTable, "BananAH", "SaveAuctionData"})

local function GetAllAuctionData(item)
	local playerFaction = Inspect.Unit.Detail("player").faction
	local auctions = {}
	local lastFullScanTime = 0
	if item then
		local ok, itemDetail = pcall(Inspect.Item.Detail, item)
		if ok then
			local normalizedItemType = NormalizeItemType(itemDetail.type, itemDetail.rarity)
			if auctionTable[playerFaction][normalizedItemType] then
				for auctionID, auctionData in pairs(auctionTable[playerFaction][normalizedItemType].auctions) do
					auctions[auctionID] = CopyTableSimple(auctionData)
					auctions[auctionID].bidUnitPrice = math.ceil((auctions[auctionID].bidPrice or 0) / (auctions[auctionID].stack or 1))
					if auctions[auctionID].buyoutPrice then
						auctions[auctionID].buyoutUnitPrice = math.ceil((auctions[auctionID].buyoutPrice or 0) / (auctions[auctionID].stack or 1))
					end
				end
				lastFullScanTime = auctionTable[playerFaction][normalizedItemType].lastFullScanTime
			end
		end
	else
		for normalizedItemType, itemData in pairs(auctionTable[playerFaction]) do
			for auctionID, auctionData in pairs(itemData.auctions) do
				auctions[auctionID] = CopyTableSimple(auctionData)
				auctions[auctionID].bidUnitPrice = math.ceil((auctions[auctionID].bidPrice or 0) / (auctions[auctionID].stack or 1))
				if auctions[auctionID].buyoutPrice then
					auctions[auctionID].buyoutUnitPrice = math.ceil((auctions[auctionID].buyoutPrice or 0) / (auctions[auctionID].stack or 1))
				end
			end
			lastFullScanTime = math.max(lastFullScanTime, itemData.lastFullScanTime)
		end
	end
	return auctions, lastFullScanTime
end

local function GetActiveAuctionData(item)
	local auctions, lastFullScanTime = GetAllAuctionData(item)
	for auctionID, auctionData in pairs(auctions) do
		if auctionData.removedBeforeExpiration ~= nil then
			auctions[auctionID] = nil
		end
	end
	return auctions, lastFullScanTime
end

local function GetAuctionCached(auctionID)
	return cachedAuctions[auctionID]
end

_G.BananAH.GetAllAuctionData = GetAllAuctionData
_G.BananAH.GetActiveAuctionData = GetActiveAuctionData
_G.BananAH.GetAuctionCached = GetAuctionCached
