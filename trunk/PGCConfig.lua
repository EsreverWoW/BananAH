-- ***************************************************************************************************************************************************
-- * PGCConfig.lua                                                                                                                                   *
-- ***************************************************************************************************************************************************
-- * Sets up BananAH's Price Models                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.01 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L
local RegisterPriceModel = LibPGCEx.RegisterPriceModel

RegisterPriceModel("vendor", L["PriceModels/Vendor"], "simple",
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

RegisterPriceModel("mean", L["PriceModels/Average"], "statistical",
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

RegisterPriceModel("median", L["PriceModels/Median"], "statistical",
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

RegisterPriceModel("stdev", L["PriceModels/StandardDeviation"], "statistical",
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

RegisterPriceModel("interpercentilerange", L["PriceModels/TrimmedMean"], "statistical",
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

RegisterPriceModel("market", L["PriceModels/Market"], "composite",
{
	mean = 1,
	stdev = 3,
	interpercentilerange = 5,
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