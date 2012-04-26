local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local MAX_DATA_AGE = 30 * 24 * 60 * 60

local auctionTable = {}
local auctionTableLoaded = false
local cachedItemTypes = {}
local cachedAuctions = {}
local auctionSearcher = InternalInterface.Utility.BuildAuctionTree()
local AuctionDataEvent = Utility.Event.Create(addonID, "AuctionData")
local backgroundScannerDisabled = false
local scanNext = false

local function UnpackAuctionTable(packedDB)
	if type(packedDB) ~= "table" or not packedDB.DICT then return packedDB end
	
	local unpackedDB = {}

	local dictionary = {}
	local sDictionary = (packedDB.DICT or "") .. "#"
	sDictionary:gsub("([^#]*)#", function(c) dictionary[#dictionary + 1] = c end)
	setmetatable(dictionary, { __index = function(tab, key) return rawget(tab, tonumber(key, 16)) or key end, })
	
	for _, itemPackedData in ipairs(packedDB) do
		local itemData = {}
		local sItemData = itemPackedData .. "#"
		sItemData:gsub("([^#]*)#", function(c) itemData[#itemData + 1] = c end)
		
		local itemType = itemData[1] .. ","
		itemType = { itemType:match((itemType:gsub("[^,]*,", "([^,]*),"))) }
		itemType = table.concat({ dictionary[itemType[1]], itemType[2], dictionary[itemType[3]], dictionary[itemType[4]], dictionary[itemType[5]], dictionary[itemType[6]], dictionary[itemType[7]], itemType[8], }, ",")

		local name = dictionary[itemData[2]]
		local rarity = dictionary[itemData[3]]
		local level = tonumber(dictionary[itemData[4]], 16)
		local category = dictionary[itemData[5]]
		local callings = tonumber(dictionary[itemData[6]], 16)
		callings = { warrior = bit.band(callings, 8) > 0 and true or nil, cleric = bit.band(callings, 4) > 0 and true or nil, rogue = bit.band(callings, 2) > 0 and true or nil, mage = bit.band(callings, 1) > 0 and true or nil, }
		
		local auctions = {}
		for index = 7, #itemData do
			local auctionData = itemData[index] .. ","
			auctionData = { auctionData:match((auctionData:gsub("[^,]+,", "([^,]*),"))) }
			
			local auctionID = string.format("o%08s%08s", dictionary[auctionData[1]], auctionData[2])
			local buy = tonumber(dictionary[auctionData[5]], 16)
			local rbe = tonumber(auctionData[12])
			auctions[auctionID] = 
			{ 
				buy = buy, rbe = rbe, sln = dictionary[auctionData[6]], bdd = tonumber(auctionData[11]),
				stk = tonumber(auctionData[3], 16), bid = tonumber(dictionary[auctionData[4]], 16), 	
				fst = tonumber(dictionary[auctionData[7]], 16), lst = tonumber(dictionary[auctionData[8]], 16),
				met = tonumber(dictionary[auctionData[9]], 16), xet = tonumber(dictionary[auctionData[10]], 16),
			}
		end

		unpackedDB[itemType] =
		{
			name = name,
			rarity = rarity,
			level = level,
			category = category,
			callings = callings,
			auctions = auctions,
		}
	end
	
	return unpackedDB
end


local function PackAuctionTable()
	local packedDB = {}
	
	local encodeAlways = {}
	local function EncodeAlways(key)
		if key ~= "" then
			if type(key) == "number" then
				key = string.format("%X", key)
			end
			encodeAlways[key] = (encodeAlways[key] or 0) + 1 
		end 
		return key 
	end
	
	local encodeWhenRepeated = {}
	local function EncodeWhenRepeated(key)
		encodeWhenRepeated[key] = (encodeWhenRepeated[key] or 0) + 1
		return key
	end		
	
	for itemType, itemData in pairs(auctionTable) do
		local packedAuctions = {}
		
		for auctionID, auctionData in pairs(itemData.auctions) do
			local packedAuctionData = 
			{
				EncodeAlways(tonumber(auctionID:sub(2, 9), 16)),
				string.format("%X", tonumber(auctionID:sub(10), 16)),
				string.format("%X", auctionData.stk),
				EncodeAlways(auctionData.bid),
				EncodeAlways(auctionData.buy),
				EncodeWhenRepeated(auctionData.sln),
				EncodeAlways(auctionData.fst),
				EncodeAlways(auctionData.lst),
				EncodeAlways(auctionData.met),
				EncodeAlways(auctionData.xet),
				auctionData.bdd,
				auctionData.rbe,
			}
			table.insert(packedAuctions, packedAuctionData)					
		end

		if #packedAuctions > 0 then
			local packedItemType = itemType .. ","
			packedItemType = { packedItemType:match((packedItemType:gsub("[^,]*,", "([^,]*),"))) }
			packedItemType =
			{
				EncodeWhenRepeated(packedItemType[1]), 
				packedItemType[2], 
				EncodeAlways(packedItemType[3]), 
				EncodeAlways(packedItemType[4]), 
				EncodeAlways(packedItemType[5]), 
				EncodeAlways(packedItemType[6]), 
				EncodeWhenRepeated(packedItemType[7]), 
				packedItemType[8],
			}
			local packedItemData =
			{
				packedItemType,
				EncodeWhenRepeated(itemData.name),
				EncodeWhenRepeated(itemData.rarity),
				EncodeAlways(itemData.level),
				EncodeWhenRepeated(itemData.category),
				EncodeAlways((itemData.callings.warrior and 8 or 0) + (itemData.callings.cleric and 4 or 0) + (itemData.callings.rogue and 2 or 0) + (itemData.callings.mage and 1 or 0)),
				packedAuctions,
			}
			table.insert(packedDB, packedItemData)
		end
	end
	
	for key, frequency in pairs(encodeWhenRepeated) do if frequency > 1 then EncodeAlways(key) end end
	encodeWhenRepeated = {}
	for key, frequency in pairs(encodeAlways) do table.insert(encodeWhenRepeated, key) end
	table.sort(encodeWhenRepeated, function(a, b) return encodeAlways[b] < encodeAlways[a] end)
	for index, key in ipairs(encodeWhenRepeated) do encodeAlways[key] = string.format("%X", index) end
	setmetatable(encodeAlways, { __index = function(tab, key) return rawget(tab, key) or key end })
	
	for index, packedItemData in ipairs(packedDB) do
		packedDB[index][1] = table.concat({ encodeAlways[packedItemData[1][1]], packedItemData[1][2], encodeAlways[packedItemData[1][3]], encodeAlways[packedItemData[1][4]], encodeAlways[packedItemData[1][5]], encodeAlways[packedItemData[1][6]], encodeAlways[packedItemData[1][7]], packedItemData[1][8], }, ",")
		packedDB[index][2] = encodeAlways[packedItemData[2]]
		packedDB[index][3] = encodeAlways[packedItemData[3]]
		packedDB[index][4] = encodeAlways[packedItemData[4]]
		packedDB[index][5] = encodeAlways[packedItemData[5]]
		packedDB[index][6] = encodeAlways[packedItemData[6]]
		for aIndex, packedAuctionData in ipairs(packedItemData[7]) do
			packedDB[index][7][aIndex] = table.concat({ encodeAlways[packedAuctionData[1]], packedAuctionData[2], packedAuctionData[3], encodeAlways[packedAuctionData[4]], encodeAlways[packedAuctionData[5]], encodeAlways[packedAuctionData[6]], encodeAlways[packedAuctionData[7]], encodeAlways[packedAuctionData[8]], encodeAlways[packedAuctionData[9]], encodeAlways[packedAuctionData[10]], encodeAlways[packedAuctionData[11]], encodeAlways[packedAuctionData[12]], }, ",")
		end
		packedDB[index][7] = table.concat(packedDB[index][7], "#")
		packedDB[index] = table.concat(packedDB[index], "#")
	end
	packedDB.DICT = table.concat(encodeWhenRepeated, "#")
		
	return packedDB
end

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
	if (backgroundScannerDisabled and not scanNext) or not Inspect.Interaction("auction") then return end

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
	
	scanNext = false
	AuctionDataEvent(criteria.type, totalAuctions, newAuctions, updatedAuctions, removedAuctions, beforeExpireAuctions)
end
table.insert(Event.Auction.Scan, { OnAuctionData, addonID, "AHMonitoringService.OnAuctionData" })

local function LoadAuctionTable(addonId)
	if addonId == addonID then
		if type(_G[addonID .. "AuctionTable"]) == "string" then
			auctionTable = loadstring("return " .. zlib.inflate()(_G[addonID .. "AuctionTable"]))
			auctionTable = auctionTable and auctionTable() or {}
			auctionTable = UnpackAuctionTable(auctionTable)
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
		
		_G[addonID .. "AuctionTable"] = zlib.deflate(zlib.BEST_COMPRESSION)(Utility.Serialize.Inline(PackAuctionTable()), "finish")
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

local function GetBackgroundScannerEnabled()
	return not backgroundScannerDisabled
end

local function SetBackgroundScannerEnabled(enabled)
	backgroundScannerDisabled = not enabled
end

function InternalInterface.ScanNext()
	scanNext = true
end

_G[addonID].SearchAuctions = SearchAuctions
_G[addonID].GetAllAuctionData = GetAllAuctionData
_G[addonID].GetActiveAuctionData = GetActiveAuctionData
_G[addonID].GetAuctionCached = GetAuctionCached
_G[addonID].GetBackgroundScannerEnabled = GetBackgroundScannerEnabled
_G[addonID].SetBackgroundScannerEnabled = SetBackgroundScannerEnabled
