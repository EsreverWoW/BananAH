

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

InternalInterface.Localization = {}
InternalInterface.Localization.L = localizationTable
InternalInterface.Localization.RegisterLocale = RegisterLocale

