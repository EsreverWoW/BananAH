
local _, InternalInterface = ...

-- Utility Functions
local function FixItemType(itemType)
	itemType = string.gsub(itemType, "FFFFFFFFFFFFFFFF0", "FFFFFFFF0")
	return itemType
end

local function NormalizeItemType(itemType, rarity, includePowerLevels, includeRunes)
	itemType = FixItemType(itemType)
	local baseType, _, augmentID, randomID, randomPower, augmentPower, runeID, _ = string.match(itemType, "(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)")
	local normalizedType = baseType .. ","
	if rarity then normalizedType = normalizedType .. rarity .. "," end
	normalizedType = normalizedType .. augmentID .. "," .. randomID
	if includePowerLevels then normalizedType = normalizedType .. "," .. augmentPower .. "," .. randomPower end
	if includeRunes then normalizedType = normalizedType .. "," .. runeID end
	return normalizedType
end

local function GetRarityColor(rarity)
	if     rarity == "sellable"     then return 0.34375, 0.34375, 0.34375, 1
	elseif rarity == "uncommon"     then return 0,       0.797,   0,       1
	elseif rarity == "rare"         then return 0.148,   0.496,   0.977,   1
	elseif rarity == "epic"         then return 0.676,   0.281,   0.98,    1
	elseif rarity == "relic"        then return 1,       0.5,     0,       1
	elseif rarity == "quest"        then return 1,       1,       0,       1
	elseif rarity == "transcendant" then return 1,       0.7,     0.9,     1
	else                                 return 0.98,    0.98,    0.98,    1
	end
end

local function CopyTableSimple(tab)
	local copy = { }
	for k, v in pairs(tab) do copy[k] = v end
	return copy
end

-- Interfaces
_G.BananAH = _G.BananAH or {}
InternalInterface = InternalInterface or {}

InternalInterface.Utility = InternalInterface.Utility or {}
InternalInterface.Utility.FixItemType = FixItemType
InternalInterface.Utility.NormalizeItemType = NormalizeItemType
InternalInterface.Utility.GetRarityColor = GetRarityColor
InternalInterface.Utility.CopyTableSimple = CopyTableSimple

InternalInterface.UI = InternalInterface.UI or {}

InternalInterface.Settings = InternalInterface.Settings or {}

-- Settings
local function LoadSettings(addonId)
	if addonId == "BananAH" then
		InternalInterface.Settings = BananAHSettings or {}
	end
end
table.insert(Event.Addon.SavedVariables.Load.End, {LoadSettings, "BananAH", "LoadSettings"})

local function SaveSettings(addonId)
	if addonId == "BananAH" and _G.BananAH.isLoaded then
		BananAHSettings = InternalInterface.Settings
	end
end
table.insert(Event.Addon.SavedVariables.Save.Begin, {SaveSettings, "BananAH", "SaveSettings"})

-- Loading
local function OnAddonLoadEnd(addonId)
	if addonId == "BananAH" then 
		_G.BananAH.isLoaded = true 
	end 
end
table.insert(Event.Addon.Load.End, { OnAddonLoadEnd, "BananAH", "OnAddonLoadEnd" })