-- ***************************************************************************************************************************************************
-- * Misc/Utility.lua                                                                                                                                *
-- ***************************************************************************************************************************************************
-- * Defines helper functions                                                                                                                        *
-- ***************************************************************************************************************************************************
-- * 0.4.0  / 2012.05.30 / Baanano: First version, splitted out of the old Init.lua                                                                  *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local IUDetail = Inspect.Unit.Detail
local L = InternalInterface.Localization.L
local MFloor = math.floor
local OTime = Inspect.Time.Server
local ODate = os.date
local SFormat = string.format
local pairs = pairs
local tonumber = tonumber
local type = type

InternalInterface.Utility = InternalInterface.Utility or {}

-- ***************************************************************************************************************************************************
-- * GetRarityColor                                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * Returns r, g, b, a color values for a given rarity                                                                                              *
-- * Source: http://forums.riftgame.com/beta-addon-api-development/258724-post-your-small-addon-api-suggestions-here-13.html#post3382612             *
-- ***************************************************************************************************************************************************
function InternalInterface.Utility.GetRarityColor(rarity)
--	if     rarity == "sellable"     then return 0.34375, 0.34375, 0.34375, 1
	if     rarity == "sellable"     then return 0.5,     0.5,     0.5,     1
	elseif rarity == "uncommon"     then return 0,       0.797,   0,       1
	elseif rarity == "rare"         then return 0.148,   0.496,   0.977,   1
	elseif rarity == "epic"         then return 0.676,   0.281,   0.98,    1
	elseif rarity == "relic"        then return 1,       0.5,     0,       1
	elseif rarity == "quest"        then return 1,       1,       0,       1
	elseif rarity == "transcendent" then return 1,       0,       0,     1
	else                                 return 0.98,    0.98,    0.98,    1
	end
end

-- ***************************************************************************************************************************************************
-- * RemainingTimeFormatter                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * Formats an UNIX timestamp as a "time remaining" string                                                                                          *
-- ***************************************************************************************************************************************************
function InternalInterface.Utility.RemainingTimeFormatter(value)
	local timeDelta = value - OTime()
	if timeDelta <= 0 then return "" end
	
	local hours, minutes, seconds = MFloor(timeDelta / 3600), MFloor(MFloor(timeDelta % 3600) / 60), MFloor(timeDelta % 60)
	
	if hours > 0 then
		return SFormat(L["Misc/RemainingTimeHours"], hours, minutes)
	elseif minutes > 0 then
		return SFormat(L["Misc/RemainingTimeMinutes"], minutes, seconds)
	else
		return SFormat(L["Misc/RemainingTimeSeconds"], seconds)
	end
end	

-- ***************************************************************************************************************************************************
-- * GetLocalizedDateString                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * Formats a timestamp like os.date, but using localized weekday & month names                                                                     *
-- ***************************************************************************************************************************************************
function InternalInterface.Utility.GetLocalizedDateString(formatString, value)
	local weekdayNames = L["Misc/DateWeekdayNames"] .. ","
	weekdayNames = { weekdayNames:match((weekdayNames:gsub("[^,]*,", "([^,]*),"))) }
	local weekdayName = weekdayNames[tonumber(ODate("%w", value)) + 1]
	
	local weekdayAbbreviatedNames = L["Misc/DateWeekdayAbbreviatedNames"] .. ","
	weekdayAbbreviatedNames = { weekdayAbbreviatedNames:match((weekdayAbbreviatedNames:gsub("[^,]*,", "([^,]*),"))) }
	local weekdayAbbreviatedName = weekdayAbbreviatedNames[tonumber(ODate("%w", value)) + 1]

	local monthNames = L["Misc/DateMonthNames"] .. ","
	monthNames = { monthNames:match((monthNames:gsub("[^,]*,", "([^,]*),"))) }
	local monthName = monthNames[tonumber(ODate("%m", value))]
	
	local monthAbbreviatedNames = L["Misc/DateMonthAbbreviatedNames"] .. ","
	monthAbbreviatedNames = { monthAbbreviatedNames:match((monthAbbreviatedNames:gsub("[^,]*,", "([^,]*),"))) }
	local monthAbbreviatedName = monthAbbreviatedNames[tonumber(ODate("%m", value))]
	
	formatString = formatString:gsub("%%a", weekdayAbbreviatedName)
	formatString = formatString:gsub("%%A", weekdayName)
	formatString = formatString:gsub("%%b", monthAbbreviatedName)
	formatString = formatString:gsub("%%B", monthName)

	return ODate(formatString, value)
end

-- ***************************************************************************************************************************************************
-- * CopyTableSimple                                                                                                                                 *
-- ***************************************************************************************************************************************************
-- * Returns a shallow copy of a table, without its metatable                                                                                        *
-- ***************************************************************************************************************************************************
function InternalInterface.Utility.CopyTableSimple(sourceTable)
	local copy = {}
	for key, value in pairs(sourceTable) do 
		copy[key] = value 
	end
	return copy
end

-- ***************************************************************************************************************************************************
-- * CopyTableRecursive                                                                                                                              *
-- ***************************************************************************************************************************************************
-- * Returns a deep copy of a table, without its metatable                                                                                           *
-- ***************************************************************************************************************************************************
function InternalInterface.Utility.CopyTableRecursive(sourceTable)
	local copy = {}
	for key, value in pairs(sourceTable) do
		copy[key] = type(value) == "table" and InternalInterface.Utility.CopyTableRecursive(value) or value
	end
	return copy
end

local playerName = nil
function InternalInterface.Utility.GetPlayerName()
	if not playerName then
		playerName = IUDetail("player")
		playerName = playerName and playerName.name or nil
	end
	return playerName
end