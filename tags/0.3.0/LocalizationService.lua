local _, InternalInterface = ...

-- Localization Services
local localizationTable = localizationTable or {}
setmetatable(localizationTable,
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

local function RegisterLocale(locale, tab)
	if locale == "English" or locale == Inspect.System.Language() then
		for key, value in pairs(tab) do
			if value == true then
				localizationTable[key] = key
			elseif type(value) == "string" then
				localizationTable[key] = value
			else
				localizationTable[key] = key
			end
		end
	end
end

local function GetLocalizedDateString(format, value)
	local weekdayNames = localizationTable["Meta/weekdayNames"] .. ","
	weekdayNames = { weekdayNames:match((weekdayNames:gsub("[^,]*,", "([^,]*),"))) }
	local weekdayName = weekdayNames[tonumber(os.date("%w", value)) + 1]
	
	local weekdayAbbreviatedNames = localizationTable["Meta/weekdayAbbreviatedNames"] .. ","
	weekdayAbbreviatedNames = { weekdayAbbreviatedNames:match((weekdayAbbreviatedNames:gsub("[^,]*,", "([^,]*),"))) }
	local weekdayAbbreviatedName = weekdayAbbreviatedNames[tonumber(os.date("%w", value)) + 1]

	local m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12 = string.match(localizationTable["Meta/monthNames"], "(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)")
	local ma1, ma2, ma3, ma4, ma5, ma6, ma7, ma8, ma9, ma10, ma11, ma12 = string.match(localizationTable["Meta/monthAbbreviatedNames"], "(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)")
	
	local monthNames = { m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12 }
	local monthAbbreviatedNames = { ma1, ma2, ma3, ma4, ma5, ma6, ma7, ma8, ma9, ma10, ma11, ma12 }
	
	local monthName = monthNames[tonumber(os.date("%m", value))]
	local monthAbbreviatedName = monthAbbreviatedNames[tonumber(os.date("%m", value))]
	
	format = string.gsub(format, "%%a", weekdayAbbreviatedName)
	format = string.gsub(format, "%%A", weekdayName)
	format = string.gsub(format, "%%b", monthAbbreviatedName)
	format = string.gsub(format, "%%B", monthName)

	return os.date(format, value)
end

InternalInterface.Localization = {}
InternalInterface.Localization.L = localizationTable
InternalInterface.Localization.RegisterLocale = RegisterLocale
InternalInterface.Localization.GetLocalizedDateString = GetLocalizedDateString