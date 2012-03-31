

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
	local w0, w1, w2, w3, w4, w5, w6 = string.match(localizationTable["Meta/weekdayNames"], "(.-),(.-),(.-),(.-),(.-),(.-),(.-)")
	local wa0, wa1, wa2, wa3, wa4, wa5, wa6 = string.match(localizationTable["Meta/weekdayAbbreviatedNames"], "(.-),(.-),(.-),(.-),(.-),(.-),(.-)")
	local m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12 = string.match(localizationTable["Meta/monthNames"], "(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)")
	local ma1, ma2, ma3, ma4, ma5, ma6, ma7, ma8, ma9, ma10, ma11, ma12 = string.match(localizationTable["Meta/monthAbbreviatedNames"], "(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-)")
	
	local weekdayNames = { w0, w1, w2, w3, w4, w5, w6 }
	local weekdayAbbreviatedNames = { wa0, wa1, wa2, wa3, wa4, wa5, wa6 }
	local monthNames = { m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12 }
	local monthAbbreviatedNames = { ma1, ma2, ma3, ma4, ma5, ma6, ma7, ma8, ma9, ma10, ma11, ma12 }
	
	local weekdayName = weekdayNames[tonumber(os.date("%w", value)) + 1]
	local weekdayAbbreviatedName = weekdayAbbreviatedNames[tonumber(os.date("%w", value)) + 1]
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

