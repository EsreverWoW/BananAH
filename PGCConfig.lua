-- ***************************************************************************************************************************************************
-- * PGCConfig.lua                                                                                                                                   *
-- ***************************************************************************************************************************************************
-- * Sets up BananAH's Price Models                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * 0.4.15 / 2012.10.23 / Baanano: Fallback to BASE_CATEGORY for unknown categories                                                                 *
-- * 0.4.4  / 2012.10.23 / Baanano: Per category price models                                                                                        *
-- * 0.4.1  / 2012.08.01 / Baanano: First version                                                                                                    *
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
local UnregisterPriceModel = LibPGCEx.UnregisterPriceModel
local pairs = pairs

local categoryModels = {}

local builtInModels =
{
	[BASE_CATEGORY] =
	{
		["BVendor"] =
		{
			name = L["PriceModels/Vendor"],
			modelType = "simple",
			usage =
			{
				id = "vendor",
				extra =
				{
					bidMultiplier = 3,
					buyMultiplier = 5,
				},			
			},
			matchers =
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
					id = "minprofit",
					extra = 
					{
						minProfit = 0,
					}
				},			
			},
		},
		["BMean"] =
		{
			name = L["PriceModels/Average"],
			modelType = "statistical",
			usage =
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
				},
			},
			matchers =
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
					id = "minprofit",
					extra = 
					{
						minProfit = 0,
					}
				},
			},
		},
		["BMedian"] =
		{
			name = L["PriceModels/Median"],
			modelType = "statistical",
			usage =
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
				},
			},
			matchers =
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
					id = "minprofit",
					extra = 
					{
						minProfit = 0,
					}
				},			
			},
		},
		["BStdev"] =
		{
			name = L["PriceModels/StandardDeviation"],
			modelType = "statistical",
			usage =
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
				},		
			},
			matchers =
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
					id = "minprofit",
					extra = 
					{
						minProfit = 0,
					}
				},			
			},
		},
		["BInterpercentilerange"] =
		{
			name = L["PriceModels/TrimmedMean"],
			modelType = "statistical",
			usage =
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
				},
			},
			matchers =
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
					id = "minprofit",
					extra = 
					{
						minProfit = 0,
					}
				},			
			},
		},
		["BMarket"] =
		{
			name = L["PriceModels/Market"],
			modelType = "composite",
			usage =
			{
				["BMean"] = 1,
				["BStdev"] = 3,
				["BInterpercentilerange"] = 5,			
			},
			matchers =
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
					id = "minprofit",
					extra = 
					{
						minProfit = 0,
					}
				},			
			},
		},
	},
}

InternalInterface.PGCConfig = InternalInterface.PGCConfig or {}

function InternalInterface.PGCConfig.LoadBuiltInModels()
	for category, models in pairs(builtInModels) do
		categoryModels[category] = categoryModels[category] or {}
		for modelID, modelInfo in pairs(models) do
			UnregisterPriceModel(modelID)
			RegisterPriceModel(modelID, modelInfo.name, modelInfo.modelType, modelInfo.usage, modelInfo.matchers)
			categoryModels[category][modelID] = true
		end
	end
end

function InternalInterface.PGCConfig.LoadSavedPrices()
	for category, models in pairs(InternalInterface.AccountSettings.Prices) do
		categoryModels[category] = categoryModels[category] or {}
		for modelID, modelInfo in pairs(models) do
			UnregisterPriceModel(modelID)
			RegisterPriceModel(modelID, modelInfo.name, modelInfo.modelType, modelInfo.usage, modelInfo.matchers)
			categoryModels[category][modelID] = true
		end
	end
end

function InternalInterface.PGCConfig.SaveCategoryModels(category, preserveModels, addModels)
	categoryModels[category] = categoryModels[category] or {}
	InternalInterface.AccountSettings.Prices[category] = InternalInterface.AccountSettings.Prices[category] or {}
	
	for modelID in pairs(categoryModels[category]) do
		if not preserveModels[modelID] then
			UnregisterPriceModel(modelID)
			categoryModels[category][modelID] = nil
			InternalInterface.AccountSettings.Prices[category][modelID] = nil
		end
	end
	
	for modelID, modelInfo in pairs(addModels) do
		RegisterPriceModel(modelID, modelInfo.name, modelInfo.modelType, modelInfo.usage, modelInfo.matchers)
		categoryModels[category][modelID] = true
		InternalInterface.AccountSettings.Prices[category][modelID] = { name = modelInfo.name, modelType = modelInfo.modelType, usage = modelInfo.usage, matchers = modelInfo.matchers, }
	end
end

function InternalInterface.PGCConfig.ClearCategoryModels(category)
	if categoryModels[category] then
		for modelID in pairs(categoryModels[category]) do
			UnregisterPriceModel(modelID)
		end
		categoryModels[category] = nil
		InternalInterface.AccountSettings.Prices[category] = nil
	end
end

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
		elseif own then
			print("Unknown item category '" .. category .. "', using default item category.")
			own = false
			category = BASE_CATEGORY
		else
			category = nil
		end
	end
	
	return models
end

InternalInterface.PGCConfig.LoadBuiltInModels()
