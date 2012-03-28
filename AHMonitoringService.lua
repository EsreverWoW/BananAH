local _, InternalInterface = ...

local FixItemType = InternalInterface.Utility.FixItemType
local NormalizeItemType = InternalInterface.Utility.NormalizeItemType
local CopyTableSimple = InternalInterface.Utility.CopyTableSimple

-- AH Monitoring Service
auctionTable = {}
local cachedAuctions = {}
local AuctionDataEvent = Utility.Event.Create("BananAH", "AuctionData")

local function PackAuctionDB()
	-- 1. Convert the table
	local auctionDB = {}

	for _, factionData in pairs(auctionTable) do
		for normID, normData in pairs(factionData) do
			local rarity = string.match(normID, ".-,(.-),.+") or ""
			local lastFullScanTime = normData.lastFullScanTime
			local activeAuctions = normData.activeAuctions
			
			for auctionID, auctionData in pairs(normData.auctions) do
				local itemType = auctionData.itemType
				local stack = auctionData.stack
				local bidPrice = auctionData.bidPrice
				local buyoutPrice = auctionData.buyoutPrice
				local sellerName = auctionData.sellerName
				local firstSeenTime = auctionData.firstSeenTime
				local lastSeenTime = auctionData.lastSeenTime
				local minExpireTime = auctionData.minExpireTime
				local maxExpireTime = auctionData.maxExpireTime
				local bidded = auctionData.bidded
				local removedBeforeExpiration = auctionData.removedBeforeExpiration
				
				auctionDB[itemType] = auctionDB[itemType] or { aucts = {} }
				auctionDB[itemType].rarity = auctionDB[itemType].rarity or rarity
				auctionDB[itemType].fullScan = math.max(lastFullScanTime or 0, auctionDB[itemType].fullScan or 0)
				auctionDB[itemType].activeAuctions = auctionDB[itemType].activeAuctions or activeAuctions or false
				
				auctionDB[itemType].aucts[auctionID] = auctionDB[itemType].aucts[auctionID] or {}
				auctionDB[itemType].aucts[auctionID].stk = auctionDB[itemType].aucts[auctionID].stk or stack
				auctionDB[itemType].aucts[auctionID].bid = auctionDB[itemType].aucts[auctionID].bid or bidPrice
				auctionDB[itemType].aucts[auctionID].buy = auctionDB[itemType].aucts[auctionID].buy or buyoutPrice
				auctionDB[itemType].aucts[auctionID].sln = auctionDB[itemType].aucts[auctionID].sln or sellerName
				auctionDB[itemType].aucts[auctionID].fst = math.min(auctionDB[itemType].aucts[auctionID].fst or math.huge, firstSeenTime)
				auctionDB[itemType].aucts[auctionID].lst = math.max(auctionDB[itemType].aucts[auctionID].lst or 0, lastSeenTime)
				auctionDB[itemType].aucts[auctionID].met = math.max(auctionDB[itemType].aucts[auctionID].met or 0, minExpireTime)
				auctionDB[itemType].aucts[auctionID].xet = math.min(auctionDB[itemType].aucts[auctionID].xet or math.huge, maxExpireTime)
				auctionDB[itemType].aucts[auctionID].bdd = auctionDB[itemType].aucts[auctionID].bdd or bidded
				if auctionDB[itemType].aucts[auctionID].rbe == nil or (not auctionDB[itemType].aucts[auctionID].rbe and removedBeforeExpiration) then
					auctionDB[itemType].aucts[auctionID].rbe = removedBeforeExpiration
				end
			end
		end
	end
	
	-- 2. Pack the data
	local lookup = {}
	local reverseLookup = {}
	setmetatable(lookup,
	{
		__index = 
			function(tab, key)
	 	 	 	if not reverseLookup[key] then
	 	 	 	 	rawset(tab, #tab + 1, key)
	 	 	 	 	reverseLookup[key] = #tab
	 	 	 	end
	 	 	 	return reverseLookup[key]
			end,
	})

	local packedDB = {}

	for itemType, itemData in pairs(auctionDB) do
		local itBaseType, itUnknown, itAugmentID, itRandomID, itRandomPower, itAugmentPower, itRuneID, itUnknown2 = string.match(itemType, "(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)")
		local itTable = 
		{ 
			string.format("%X", lookup[itBaseType]), 
			itUnknown, 
			string.format("%X", lookup[itAugmentID]), 
			string.format("%X", lookup[itRandomID]), 
			string.format("%X", lookup[itRandomPower]), 
			string.format("%X", lookup[itAugmentPower]), 
			string.format("%X", lookup[itRuneID]), 
			itUnknown2
		}
		local packedType = { table.concat(itTable, ","), string.format("%X", lookup[itemData.rarity]), string.format("%X", lookup[string.format("%X", itemData.fullScan or 0)]), tostring(itemData.activeAuctions and 1 or 0) }
		for auctionID, auctionData in pairs(itemData.aucts) do
			local packedData = 
			{
				string.format("%X", lookup[string.format("%X", tonumber(auctionID:sub(2, 9), 16))]),
				string.format("%X", tonumber(auctionID:sub(10), 16)),
				string.format("%X", auctionData.stk),
				string.format("%X", lookup[string.format("%X", auctionData.bid)]),
				string.format("%X", lookup[string.format("%X", auctionData.buy or 0)]),
				string.format("%X", lookup[auctionData.sln]),
				string.format("%X", lookup[string.format("%X", auctionData.fst)]),
				string.format("%X", lookup[string.format("%X", auctionData.lst)]),
				string.format("%X", lookup[string.format("%X", auctionData.met)]),
				string.format("%X", lookup[string.format("%X", auctionData.xet)]),
				tostring(auctionData.bdd and 1 or 0),
				tostring(auctionData.rbe and 2 or (auctionData.rbe == nil and 0 or 1)),
			}
			table.insert(packedType, table.concat(packedData, ","))
		end
		table.insert(packedDB, table.concat(packedType, ";"))
	end
	packedDB.dict = lookup
	
	return packedDB
end

local function UnpackAuctionDB(packedDB)
	local dict = packedDB.dict
	if not dict then return packedDB end

	setmetatable(dict,
	{
		__index = 
			function(tab, key)
 	 	 	 	return rawget(tab, tonumber(key, 16))
			end,
	})
	
	local unpackTime = os.time()
	local unpackedDB = {}
	for _, packedType in ipairs(packedDB) do
		local itemType, rarity, fullScan, activeAuctions, auctions = string.match(packedType, "(.-);(.-);(.-);(.-);(.+)")
		local itBaseType, itUnknown, itAugmentID, itRandomID, itRandomPower, itAugmentPower, itRuneID, itUnknown2 = string.match(itemType, "(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)")

		itemType = table.concat({ dict[itBaseType], itUnknown, dict[itAugmentID], dict[itRandomID], dict[itRandomPower], dict[itAugmentPower], dict[itRuneID], itUnknown2 }, ",")
		rarity = dict[rarity]
		fullScan = tonumber(dict[fullScan], 16)
		activeAuctions = activeAuctions == "1" and true or nil
		
		
		local normType = NormalizeItemType(itemType, rarity)
		unpackedDB[normType] = unpackedDB[normType] or { auctions = {} }
		unpackedDB[normType].lastFullScanTime = math.max(unpackedDB[normType].lastFullScanTime or 0, fullScan)
		unpackedDB[normType].activeAuctions = unpackedDB[normType].activeAuctions or activeAuctions
		
		auctionTable = {}
		auctions:gsub("([^;]+)", function(c) auctionTable[#auctionTable+1] = c end)
		auctions = auctionTable
--		auctions = { auctions:match((auctions:gsub("[^;]*;", "([^;]*);"))) } -- Error: Too many captures
		for _, packedAuction in ipairs(auctions) do
			local auctionHID, auctionLID, stk, bid, buy, sln, fst, lst, met, xet, bdd, rbe = packedAuction:match("(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.+)")
			auctionHID = string.format("%08s", dict[auctionHID])
			auctionLID = string.format("%08s", auctionLID)
			stk = tonumber(stk, 16)
			bid = tonumber(dict[bid], 16)
			buy = tonumber(dict[buy], 16)
			buy = buy > 0 and buy or nil
			sln = dict[sln]
			fst = tonumber(dict[fst], 16)
			lst = tonumber(dict[lst], 16)
			met = tonumber(dict[met], 16)
			xet = tonumber(dict[xet], 16)
			bdd = bdd == "1" and true or nil
			if rbe == "2" then rbe = true elseif rbe == "1" then rbe = false else rbe = nil end
			
			if unpackTime - lst <= 604800 then
				unpackedDB[normType].auctions["o" .. auctionHID .. auctionLID] =
				{
					itemType = itemType,
					stack = stk,
					bidPrice = bid,
					buyoutPrice = buy,
					sellerName = sln,
					firstSeenTime = fst,
					lastSeenTime = lst,
					minExpireTime = met,
					maxExpireTime = xet,
					bidded = bdd,
					removedBeforeExpiration = rbe,
				}
			end
		end
	end
	
	for normType, normData in pairs(unpackedDB) do
		local hasAuctions = false
		for _,_ in pairs(normData.auctions) do hasAuctions = true break end
		if not hasAuctions then unpackedDB[normType] = nil end
	end
	
	return unpackedDB
end

local function OnAuctionData(type, auctions)
	if not Inspect.Interaction("auction") then return end
	if type.type ~= "search" then return end

	local auctionScanTime = os.time()

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
		local normalizedItemType = NormalizeItemType(itemDetail.type, itemDetail.rarity or "")
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
		auctionTable.common[normalizedItemType] = auctionTable.common[normalizedItemType] or { auctions = {} }
		auctionTable.common[normalizedItemType].activeAuctions = true
	
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
		
			if not auctionTable.common[normalizedItemType].auctions[auctionID] then
				auctionTable.common[normalizedItemType].auctions[auctionID] = 
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
				auctionTable.common[normalizedItemType].auctions[auctionID].lastSeenTime = auctionScanTime
				auctionTable.common[normalizedItemType].auctions[auctionID].minExpireTime = math.max(auctionTable.common[normalizedItemType].auctions[auctionID].minExpireTime, minExpirationTime)
				auctionTable.common[normalizedItemType].auctions[auctionID].maxExpireTime = math.min(auctionTable.common[normalizedItemType].auctions[auctionID].maxExpireTime, maxExpirationTime)
				if auctionTable.common[normalizedItemType].auctions[auctionID].bidPrice ~= auctionDetail.bidPrice then
					auctionTable.common[normalizedItemType].auctions[auctionID].bidPrice = auctionDetail.bidPrice
					auctionTable.common[normalizedItemType].auctions[auctionID].bidded = true
					updatedAuctionCount = updatedAuctionCount + 1
				end
			end			
		end

		if fullScan then 
			for oldAuctionID, oldAuctionDetail in pairs(auctionTable.common[normalizedItemType].auctions) do repeat
				if scanDetail.auctions[oldAuctionID] then break end
				if oldAuctionDetail.removedBeforeExpiration == nil then
					removedAuctionCount = removedAuctionCount + 1
					if auctionScanTime < oldAuctionDetail.minExpireTime then 
						auctionTable.common[normalizedItemType].auctions[oldAuctionID].removedBeforeExpiration = true
						beforeExpireAuctionCount = beforeExpireAuctionCount + 1
					else
						auctionTable.common[normalizedItemType].auctions[oldAuctionID].removedBeforeExpiration = false
					end
				end
			until true end
			auctionTable.common[normalizedItemType].lastFullScanTime = auctionScanTime
		end
	end
	if trueFullScan then
		for normalizedItemType, scanDetail in pairs(auctionTable.common) do repeat
			if scanDetail.activeAuctions and (scanDetail.lastFullScanTime or 0) >= auctionScanTime then break end
			for oldAuctionID, oldAuctionDetail in pairs(scanDetail.auctions) do
				if oldAuctionDetail.removedBeforeExpiration == nil then
					removedAuctionCount = removedAuctionCount + 1
					if auctionScanTime < oldAuctionDetail.minExpireTime then 
						auctionTable.common[normalizedItemType].auctions[oldAuctionID].removedBeforeExpiration = true
						beforeExpireAuctionCount = beforeExpireAuctionCount + 1
					else
						auctionTable.common[normalizedItemType].auctions[oldAuctionID].removedBeforeExpiration = false
					end
				end
			end
			auctionTable.common[normalizedItemType].activeAuctions = nil
			auctionTable.common[normalizedItemType].lastFullScanTime = auctionScanTime
		until true end
	end
	AuctionDataEvent(fullScan, totalAuctionCount, newAuctionCount, updatedAuctionCount, removedAuctionCount, beforeExpireAuctionCount)
end
table.insert(Event.Auction.Scan, { OnAuctionData, "BananAH", "OnAuctionData" })

local function LoadAuctionTable(addonId)
	if addonId == "BananAH" then
		if type(BananAHAuctionTable) ~= "table" then -- New saved variables file
			auctionTable = { common = {} }
		elseif BananAHAuctionTable.guardian then -- Pre 0.2.2 saved variables file
			auctionTable = BananAHAuctionTable
			auctionTable = { common = UnpackAuctionDB(PackAuctionDB()) }
		else
			auctionTable = { common = UnpackAuctionDB(BananAHAuctionTable) }
		end
	end
end
table.insert(Event.Addon.SavedVariables.Load.End, {LoadAuctionTable, "BananAH", "LoadAuctionData"})

local function SaveAuctionTable(addonId)
	if addonId == "BananAH" and _G.BananAH.isLoaded then
		BananAHAuctionTable = PackAuctionDB()
	end
end
table.insert(Event.Addon.SavedVariables.Save.Begin, {SaveAuctionTable, "BananAH", "SaveAuctionData"})

local function GetAllAuctionData(item)
	local auctions = {}
	local lastFullScanTime = 0
	if item then
		local ok, itemDetail = pcall(Inspect.Item.Detail, item)
		if ok then
			local normalizedItemType = NormalizeItemType(itemDetail.type, itemDetail.rarity or "")
			if auctionTable.common[normalizedItemType] then
				for auctionID, auctionData in pairs(auctionTable.common[normalizedItemType].auctions) do
					auctions[auctionID] = CopyTableSimple(auctionData)
					auctions[auctionID].bidUnitPrice = math.ceil((auctions[auctionID].bidPrice or 0) / (auctions[auctionID].stack or 1))
					if auctions[auctionID].buyoutPrice then
						auctions[auctionID].buyoutUnitPrice = math.ceil((auctions[auctionID].buyoutPrice or 0) / (auctions[auctionID].stack or 1))
					end
				end
				lastFullScanTime = auctionTable.common[normalizedItemType].lastFullScanTime
			end
		end
	else
		for normalizedItemType, itemData in pairs(auctionTable.common) do
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
