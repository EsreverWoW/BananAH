-- ***************************************************************************************************************************************************
-- * Misc/Localization.lua                                                                                                                           *
-- ***************************************************************************************************************************************************
-- * Provides support for localization                                                                                                               *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.30 / Baanano: Minor upadates for 0.4.1                                                                                          *
-- * 0.4.0 / 2012.05.30 / Baanano: Old LocalizationService.lua file                                                                                  *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
InternalInterface.Localization = InternalInterface.Localization or {}

local ISLanguage = Inspect.System.Language
local pairs = pairs
local rawset = rawset
local setmetatable = setmetatable
local type = type

-- ***************************************************************************************************************************************************
-- * L (table)                                                                                                                                       *
-- ***************************************************************************************************************************************************
-- * Returns the translation of the key in the loaded locale                                                                                         *
-- * Source: http://wowprogramming.com/forums/development/596                                                                                        *
-- ***************************************************************************************************************************************************
InternalInterface.Localization.L = InternalInterface.Localization.L or {}
setmetatable(InternalInterface.Localization.L,
	{
		__index = 
			function(tab, key)
				rawset(tab, key, key)
				return key
			end,
		
		__newindex = 
			function(tab, key, value)
				if value == true then
					rawset(tab, key, key)
				else
					rawset(tab, key, value)
				end
			end,
	}
)

-- ***************************************************************************************************************************************************
-- * RegisterLocale                                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * Loads a localization table if it matches the current game language                                                                              *
-- * Source: http://wowprogramming.com/forums/development/596                                                                                        *
-- ***************************************************************************************************************************************************
function InternalInterface.Localization.RegisterLocale(locale, tab)
	local L = InternalInterface.Localization.L
	if locale == "English" or locale == ISLanguage() then
		for key, value in pairs(tab) do
			if value == true then
				L[key] = key
			elseif type(value) == "string" then
				L[key] = value
			else
				L[key] = key
			end
		end
	end
end
