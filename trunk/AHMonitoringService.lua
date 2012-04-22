local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local MAX_DATA_AGE = 1 * 24 * 60 * 60

local auctionTable = {}
local auctionTableLoaded = false
local cachedItemTypes = {}
local cachedAuctions = {}
local auctionSearcher = InternalInterface.Utility.BuildAuctionTree()
local AuctionDataEvent = Utility.Event.Create(addonID, "AuctionData")

local function UpsertAuction(auctionID, auctionDetail, auctionScanTime, expireTimes)
	local itemType = auctionDetail.itemType
	if not cachedItemTypes[itemType] then
		local itemDetail = Inspect.Item.Detail(auctionDetail.item)
		cachedItemTypes[itemType] = true

		local name = itemDetail.name
		local rarity = itemDetail.rarity or ""
		local level = itemDetail.requiredLevel or 1
		local category = itemDetail.category or ""
		local callings = itemDetail.requiredCalling
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
				rarity = rarity,
				level = level,
				category = category,
				callings = callings,
				auctions = {},
			}
		else
			local oldData = auctionTable[itemType]
			
			local oldName = oldData.name
			local oldRarity = oldData.rarity
			local oldLevel = oldData.level
			local oldCategory = oldData.category
			local oldCallings = oldData.callings
			
			if name ~= oldName or rarity ~= oldRarity  or level ~= oldLevel or category ~= oldCategory or callings.warrior ~= oldCallings.warrior or callings.cleric ~= oldCallings.cleric or callings.rogue ~= oldCallings.rogue or callings.mage ~= oldCallings.mage then
				auctionTable[itemType].name = name
				auctionTable[itemType].rarity = rarity
				auctionTable[itemType].level = level
				auctionTable[itemType].category = category
				auctionTable[itemType].callings = callings
				for auctionID, auctionData in pairs(oldData.auctions) do
					auctionSearcher:RemoveAuction(auctionID, auctionData.rbe, oldCallings, oldRarity, oldLevel, oldCategory, oldName, auctionData.buy)
				end
			end
		end
	end

	auctionTable[itemType].auctions[auctionID] = auctionTable[itemType].auctions[auctionID] or
	{
		stk = auctionDetail.itemStack or 1,
		bid = auctionDetail.bid,
		buy = auctionDetail.buyout or 0,
		sln = auctionDetail.seller,
		fst = auctionScanTime,
		lst = auctionScanTime,
		met = expireTimes[1],
		xet = expireTimes[2],
		bdd = 0,
		rbe = 0,
	}
		
	cachedAuctions[auctionID] = itemType

	if auctionTable[itemType].auctions[auctionID].fst == auctionScanTime then
		auctionSearcher:AddAuction(itemType, auctionID, 0, auctionTable[itemType].callings, auctionTable[itemType].rarity, auctionTable[itemType].level, auctionTable[itemType].category, auctionTable[itemType].name, auctionDetail.buyout or 0)
		return itemType, nil
	else
		auctionTable[itemType].auctions[auctionID].lst = auctionScanTime
		auctionTable[itemType].auctions[auctionID].met = math.max(auctionTable[itemType].auctions[auctionID].met, expireTimes[1])
		auctionTable[itemType].auctions[auctionID].xet = math.min(auctionTable[itemType].auctions[auctionID].xet, expireTimes[2])
		
		if auctionTable[itemType].auctions[auctionID].bid == auctionDetail.bid then
			return itemType, false
		else
			auctionTable[itemType].auctions[auctionID].bid = auctionDetail.bid
			auctionTable[itemType].auctions[auctionID].bdd = 1
			return itemType, true
		end
	end
end

local function OnAuctionData(criteria, auctions)
	if not Inspect.Interaction("auction") then return end

	local auctionScanTime = os.time()
	local expireTimes = 
	{ 
		short =		{ auctionScanTime, 			auctionScanTime + 7200 }, 
		medium =	{ auctionScanTime + 7200, 	auctionScanTime + 43200 }, 
		long =		{ auctionScanTime + 43200, 	auctionScanTime + 172800 },
	}

	local totalAuctions = {}
	local newAuctions = {}
	local updatedAuctions = {}
	local removedAuctions = {}
	local beforeExpireAuctions = {}

	local auctionsDetail = Inspect.Auction.Detail(auctions)
	for auctionID, auctionDetail in pairs(auctionsDetail) do
		table.insert(totalAuctions, auctionID)
		local itemType, updated = UpsertAuction(auctionID, auctionDetail, auctionScanTime, expireTimes[auctionDetail.time])
		if updated == nil then
			table.insert(newAuctions, auctionID)
		elseif updated then
			table.insert(updatedAuctions, auctionID)
		end
	end

	if criteria.type == "search" then
		if not criteria.index or (criteria.index == 0 and #totalAuctions < 50) then
			local matchingAuctions = auctionSearcher:Search(0, criteria.role, criteria.rarity == "common" and "" or criteria.rarity, criteria.levelMin, criteria.levelMax, criteria.category, criteria.priceMin, criteria.priceMax, criteria.text)
			for auctionID, itemType in pairs(matchingAuctions) do
				if not auctions[auctionID] then
					table.insert(removedAuctions, auctionID)

					local itemData = auctionTable[itemType]
					local auctionData = itemData.auctions[auctionID]
					auctionSearcher:RemoveAuction(auctionID, 0, itemData.callings, itemData.rarity, itemData.level, itemData.category, itemData.name, auctionData.buy)
					
					if auctionScanTime < auctionData.met then
						auctionTable[itemType].auctions[auctionID].rbe = 2
						table.insert(beforeExpireAuctions, auctionID)
						else
						auctionTable[itemType].auctions[auctionID].rbe = 1
					end
					
					auctionSearcher:AddAuction(itemType, auctionID, auctionTable[itemType].auctions[auctionID].rbe, itemData.callings, itemData.rarity, itemData.level, itemData.category, itemData.name, auctionData.buy)
				end
			end
		end
	end

	AuctionDataEvent(criteria.type, totalAuctions, newAuctions, updatedAuctions, removedAuctions, beforeExpireAuctions)
end
table.insert(Event.Auction.Scan, { OnAuctionData, addonID, "AHMonitoringService.OnAuctionData" })

local function LoadAuctionTable(addonId)
	if addonId == addonID then
		if type(_G[addonID .. "AuctionTable"]) == "string" then
			auctionTable = loadstring("return " .. zlib.inflate()(_G[addonID .. "AuctionTable"]))()
		else
			auctionTable = {}
		end

		for itemType, itemData in pairs(auctionTable) do
			for auctionID, auctionData in pairs(itemData.auctions) do
				auctionSearcher:AddAuction(itemType, auctionID, auctionData.rbe, itemData.callings, itemData.rarity, itemData.level, itemData.category, itemData.name, auctionData.buy)
			end
		end

		auctionTableLoaded = true
	end
end
table.insert(Event.Addon.SavedVariables.Load.End, {LoadAuctionTable, addonID, "AHMonitoringService.LoadAuctionData"})

local function SaveAuctionTable(addonId)
	if addonId == addonID and auctionTableLoaded then
		local purgeTime = os.time() - MAX_DATA_AGE
		
		for itemType, itemData in pairs(auctionTable) do
			local hasAuctions = false
			for auctionID, auctionData in pairs(itemData.auctions) do
				if auctionData.lst < purgeTime then
					auctionTable[itemType].auctions[auctionID] = nil
				else
					hasAuctions = true
				end
			end
			if not hasAuctions then
				auctionTable[itemType] = nil
			end
		end
		
		_G[addonID .. "AuctionTable"] = zlib.deflate(zlib.BEST_COMPRESSION)(Utility.Serialize.Inline(auctionTable), "finish")
	end
end
table.insert(Event.Addon.SavedVariables.Save.Begin, {SaveAuctionTable, addonID, "AHMonitoringService.SaveAuctionData"})

local function SearchAuctions(activeOnly, calling, rarity, levelMin, levelMax, category, priceMin, priceMax, name)
	local auctions = auctionSearcher:Search(activeOnly and 0 or nil, calling, rarity, levelMin, levelMax, category, priceMin, priceMax, name)
	for auctionID, itemType in pairs(auctions) do
		local auctionData = auctionTable[itemType].auctions[auctionID]
		auctions[auctionID] =
		{
			itemType = itemType,
			stack = auctionData.stk,
			bidPrice = auctionData.bid,
			buyoutPrice = auctionData.buy ~= 0 and auctionData.buy or nil,
			bidUnitPrice = auctionData.bid / auctionData.stk,
			buyoutUnitPrice = auctionData.buy ~= 0 and (auctionData.buy / auctionData.stk) or nil,
			sellerName = auctionData.sln,
			firstSeenTime = auctionData.fst,
			lastSeenTime = auctionData.lst,
			minExpireTime = auctionData.met,
			maxExpireTime = auctionData.xet,
			bidded = auctionData.bdd == 1 and true or nil,
			removedBeforeExpiration = auctionData.rbe == 2 and true or nil,
		}
		if auctionData.rbe == 1 then auctions[auctionID].removedBeforeExpiration = false end
	end
	return auctions
end

local function GetAllAuctionData(item)
	if not item then return SearchAuctions() end
	
	local ok, itemDetail = pcall(Inspect.Item.Detail, item)
	if not ok or not itemDetail then return {} end
	
	local itemType = itemDetail.type
	local auctions = {}
	local lastSeenTime = 0
	if not auctionTable[itemType] then return auctions, lastSeenTime end
	for auctionID, auctionData in pairs(auctionTable[itemType].auctions) do
		lastSeenTime = math.max(lastSeenTime, auctionData.lst)
		
		auctions[auctionID] =
		{
			itemType = itemType,
			stack = auctionData.stk,
			bidPrice = auctionData.bid,
			buyoutPrice = auctionData.buy ~= 0 and auctionData.buy or nil,
			bidUnitPrice = auctionData.bid / auctionData.stk,
			buyoutUnitPrice = auctionData.buy ~= 0 and (auctionData.buy / auctionData.stk) or nil,
			sellerName = auctionData.sln,
			firstSeenTime = auctionData.fst,
			lastSeenTime = auctionData.lst,
			minExpireTime = auctionData.met,
			maxExpireTime = auctionData.xet,
			bidded = auctionData.bdd == 1 and true or nil,
			removedBeforeExpiration = auctionData.rbe == 2 and true or nil,
		}
		if auctionData.rbe == 1 then auctions[auctionID].removedBeforeExpiration = false end
	end
	
	return auctions, lastSeenTime
end

local function GetActiveAuctionData(item)
	if not item then return SearchAuctions(true) end
	
	local ok, itemDetail = pcall(Inspect.Item.Detail, item)
	if not ok or not itemDetail then return {} end
	
	local itemType = itemDetail.type
	local auctions = {}
	local lastSeenTime = 0
	if not auctionTable[itemType] then return auctions, lastSeenTime end
	for auctionID, auctionData in pairs(auctionTable[itemType].auctions) do
		lastSeenTime = math.max(lastSeenTime, auctionData.lst)
		
		if auctionData.rbe == 0 then
			auctions[auctionID] =
			{
				itemType = itemType,
				stack = auctionData.stk,
				bidPrice = auctionData.bid,
				buyoutPrice = auctionData.buy ~= 0 and auctionData.buy or nil,
				bidUnitPrice = auctionData.bid / auctionData.stk,
				buyoutUnitPrice = auctionData.buy ~= 0 and (auctionData.buy / auctionData.stk) or nil,
				sellerName = auctionData.sln,
				firstSeenTime = auctionData.fst,
				lastSeenTime = auctionData.lst,
				minExpireTime = auctionData.met,
				maxExpireTime = auctionData.xet,
				bidded = auctionData.bdd == 1 and true or nil,
				removedBeforeExpiration = auctionData.rbe == 2 and true or nil,
			}
			if auctionData.rbe == 1 then auctions[auctionID].removedBeforeExpiration = false end
		end
	end
	
	return auctions, lastSeenTime
end

local function GetAuctionCached(auctionID)
	return cachedAuctions[auctionID] and true or false
end

_G[addonID].SearchAuctions = SearchAuctions
_G[addonID].GetAllAuctionData = GetAllAuctionData
_G[addonID].GetActiveAuctionData = GetActiveAuctionData
_G[addonID].GetAuctionCached = GetAuctionCached
