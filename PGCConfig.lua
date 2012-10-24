-- ***************************************************************************************************************************************************
-- * PGCConfig.lua                                                                                                                                   *
-- ***************************************************************************************************************************************************
-- * Sets up BananAH's Price Models                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * 0.4.4 / 2012.10.23 / Baanano: Per category price models                                                                                         *
-- * 0.4.1 / 2012.08.01 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local BASE_CATEGORY = InternalInterface.Category.BASE_CATEGORY
local CDetail = InternalInterface.Category.Detail
local GetPriceModelMatchers = LibPGCEx.GetPriceModelMatchers
local GetPriceModelType = LibPGCEx.GetPriceModelType
local GetPriceModelUsage = LibPGCEx.GetPriceModelUsage
local GetPriceModels = LibPGCEx.GetPriceModels
local L = InternalInterface.Localization.L
local RegisterPriceModel = LibPGCEx.RegisterPriceModel
local pairs = pairs

local categoryModels = {}

RegisterPriceModel("BVendor", L["PriceModels/Vendor"], "simple",
{
	id = "vendor",
	extra =
	{
		bidMultiplier = 3,
		buyMultiplier = 5,
	},
},
{
	{
		id = "selfundercut",
		extra = 
		{
			selfRange = 25,
			undercutRange = 25,
			undercutRelative = 0,
			undercutAbsolute = 1,
			noCompetitionRelative = 25,
			noCompetitionAbsolute = 0,
		}
	},
	{
		id = "minProfit",
		extra = 
		{
			minProfit = 0,
		}
	},
})

RegisterPriceModel("BMean", L["PriceModels/Average"], "statistical",
{
	id = "avg",
	extra =
	{
		weighted = true,
	},
	filters =
	{
		{
			id = "time",
			extra =
			{
				days = 3,
			},
		},
	}
},
{
	{
		id = "selfundercut",
		extra = 
		{
			selfRange = 25,
			undercutRange = 25,
			undercutRelative = 0,
			undercutAbsolute = 1,
			noCompetitionRelative = 25,
			noCompetitionAbsolute = 0,
		}
	},
	{
		id = "minProfit",
		extra = 
		{
			minProfit = 0,
		}
	},
})

RegisterPriceModel("BMedian", L["PriceModels/Median"], "statistical",
{
	id = "rpos",
	extra =
	{
		weighted = true,
		position = 50,
	},
	filters =
	{
		{
			id = "time",
			extra =
			{
				days = 3,
			},
		},
	}
},
{
	{
		id = "selfundercut",
		extra = 
		{
			selfRange = 25,
			undercutRange = 25,
			undercutRelative = 0,
			undercutAbsolute = 1,
			noCompetitionRelative = 25,
			noCompetitionAbsolute = 0,
		}
	},
	{
		id = "minProfit",
		extra = 
		{
			minProfit = 0,
		}
	},
})

RegisterPriceModel("BStdev", L["PriceModels/StandardDeviation"], "statistical",
{
	id = "avg",
	extra =
	{
		weighted = true,
	},
	filters =
	{
		{
			id = "time",
			extra =
			{
				days = 3,
			},
		},
		{
			id = "stdev",
			extra =
			{
				weighted = true,
				lowDeviation = 15,
				highDeviation = 15,
			},
		},
	}
},
{
	{
		id = "selfundercut",
		extra = 
		{
			selfRange = 25,
			undercutRange = 25,
			undercutRelative = 0,
			undercutAbsolute = 1,
			noCompetitionRelative = 25,
			noCompetitionAbsolute = 0,
		}
	},
	{
		id = "minProfit",
		extra = 
		{
			minProfit = 0,
		}
	},
})

RegisterPriceModel("BInterpercentilerange", L["PriceModels/TrimmedMean"], "statistical",
{
	id = "avg",
	extra =
	{
		weighted = true,
	},
	filters =
	{
		{
			id = "time",
			extra =
			{
				days = 3,
			},
		},
		{
			id = "ptrim",
			extra =
			{
				weighted = true,
				lowTrim = 25,
				highTrim = 25,
			},
		},
	}
},
{
	{
		id = "selfundercut",
		extra = 
		{
			selfRange = 25,
			undercutRange = 25,
			undercutRelative = 0,
			undercutAbsolute = 1,
			noCompetitionRelative = 25,
			noCompetitionAbsolute = 0,
		}
	},
	{
		id = "minProfit",
		extra = 
		{
			minProfit = 0,
		}
	},
})

RegisterPriceModel("BMarket", L["PriceModels/Market"], "composite",
{
	BMean = 1,
	BStdev = 3,
	BInterpercentilerange = 5,
},
{
	{
		id = "selfundercut",
		extra = 
		{
			selfRange = 25,
			undercutRange = 25,
			undercutRelative = 0,
			undercutAbsolute = 1,
			noCompetitionRelative = 25,
			noCompetitionAbsolute = 0,
		}
	},
	{
		id = "minProfit",
		extra = 
		{
			minProfit = 0,
		}
	},
})

categoryModels[BASE_CATEGORY] =
{
	["BVendor"] = true,
	["BMean"] = true,
	["BMedian"] = true,
	["BStdev"] = true,
	["BInterpercentilerange"] = true,
	["BMarket"] = true,
}

InternalInterface.PGCConfig = InternalInterface.PGCConfig or {}

function InternalInterface.PGCConfig.GetCategoryModels(category)
	local allModels = GetPriceModels()
	local models = {}
	
	local own = true
	while category do
		local detail = CDetail(category)
		if detail then
			if categoryModels[category] then
				for model in pairs(categoryModels[category]) do
					if allModels[model] then
						models[model] = models[model] or 
						{
							name = allModels[model],
							own = own,
							modelType = GetPriceModelType(model),
							usage = GetPriceModelUsage(model),
							matchers = GetPriceModelMatchers(model),
						}
					end
				end
			end		
			own = false
			category = detail.parent
		else
			category = nil
		end
	end
	
	return models
end