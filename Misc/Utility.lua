-- ***************************************************************************************************************************************************
-- * Misc/Utility.lua                                                                                                                                *
-- ***************************************************************************************************************************************************
-- * Defines helper functions                                                                                                                        *
-- ***************************************************************************************************************************************************
-- * 0.4.0  / 2012.05.30 / Baanano: First version, splitted out of the old Init.lua                                                                  *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

InternalInterface.Utility = InternalInterface.Utility or {}

-- ***************************************************************************************************************************************************
-- * GetRarityColor                                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * Returns r, g, b, a color values for a given rarity                                                                                              *
-- * Source: http://forums.riftgame.com/beta-addon-api-development/258724-post-your-small-addon-api-suggestions-here-13.html#post3382612             *
-- * New: http://forums.riftgame.com/technical-discussions/addon-api-development/333518-official-addon-information-station.html#post4175070          *
-- ***************************************************************************************************************************************************
function InternalInterface.Utility.GetRarityColor(rarity)
--	if     rarity == "sellable"     then return 0.34375, 0.34375, 0.34375, 1
	if     rarity == "sellable"     then return 0.5,     0.5,     0.5,     1
	elseif rarity == "uncommon"     then return 0,       0.797,   0,       1
	elseif rarity == "rare"         then return 0.148,   0.496,   0.977,   1
	elseif rarity == "epic"         then return 0.676,   0.281,   0.98,    1
	elseif rarity == "relic"        then return 1,       0.5,     0,       1
	elseif rarity == "quest"        then return 1,       1,       0,       1
	elseif rarity == "transcendant" then return 1,       0,       0,       1
	else                                 return 0.98,    0.98,    0.98,    1
	end
end

-- ***************************************************************************************************************************************************
-- * RemainingTimeFormatter                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * Formats an UNIX timestamp as a "time remaining" string                                                                                          *
-- ***************************************************************************************************************************************************
function InternalInterface.Utility.RemainingTimeFormatter(value)
	local timeDelta = value - Inspect.Time.Server()
	if timeDelta <= 0 then return "" end
	
	local hours, minutes, seconds = math.floor(timeDelta / 3600), math.floor(math.floor(timeDelta % 3600) / 60), math.floor(timeDelta % 60)
	
	if hours > 0 then
		return string.format(L["Misc/RemainingTimeHours"], hours, minutes)
	elseif minutes > 0 then
		return string.format(L["Misc/RemainingTimeMinutes"], minutes, seconds)
	else
		return string.format(L["Misc/RemainingTimeSeconds"], seconds)
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
	local weekdayName = weekdayNames[tonumber(os.date("%w", value)) + 1]
	
	local weekdayAbbreviatedNames = L["Misc/DateWeekdayAbbreviatedNames"] .. ","
	weekdayAbbreviatedNames = { weekdayAbbreviatedNames:match((weekdayAbbreviatedNames:gsub("[^,]*,", "([^,]*),"))) }
	local weekdayAbbreviatedName = weekdayAbbreviatedNames[tonumber(os.date("%w", value)) + 1]

	local monthNames = L["Misc/DateMonthNames"] .. ","
	monthNames = { monthNames:match((monthNames:gsub("[^,]*,", "([^,]*),"))) }
	local monthName = monthNames[tonumber(os.date("%m", value))]
	
	local monthAbbreviatedNames = L["Misc/DateMonthAbbreviatedNames"] .. ","
	monthAbbreviatedNames = { monthAbbreviatedNames:match((monthAbbreviatedNames:gsub("[^,]*,", "([^,]*),"))) }
	local monthAbbreviatedName = monthAbbreviatedNames[tonumber(os.date("%m", value))]
	
	formatString = formatString:gsub("%%a", weekdayAbbreviatedName)
	formatString = formatString:gsub("%%A", weekdayName)
	formatString = formatString:gsub("%%b", monthAbbreviatedName)
	formatString = formatString:gsub("%%B", monthName)

	return os.date(formatString, value)
end
