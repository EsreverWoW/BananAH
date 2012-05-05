local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local outputFunction = print

-- Utility Functions
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

local function GetOutput()
	return outputFunction
end

local function SetOutput(func)
	outputFunction = func
end

-- Interfaces
_G[addonID] = _G[addonID] or {}

InternalInterface = InternalInterface or {}
InternalInterface.UI = InternalInterface.UI or {}
InternalInterface.PricingModelService = InternalInterface.PricingModelService or {}
InternalInterface.Utility = InternalInterface.Utility or {}
InternalInterface.Utility.GetRarityColor = GetRarityColor
InternalInterface.Utility.GetOutput = GetOutput
InternalInterface.Utility.SetOutput = SetOutput
InternalInterface.AccountSettings = InternalInterface.AccountSettings or {}
InternalInterface.ShardSettings = InternalInterface.ShardSettings or {}
InternalInterface.CharacterSettings = InternalInterface.CharacterSettings or {}

-- Settings
local function BuildSettings()
	InternalInterface.AccountSettings.General = InternalInterface.AccountSettings.General or
	{
		showMapIcon = false,
		autoOpen = false,
		autoClose = false,
		disableBackgroundScanner = false,
	}
	InternalInterface.AccountSettings.Posting = InternalInterface.AccountSettings.Posting or 
	{
		startPostingQueuePaused = false,
		rarityFilter = 1,
	}
	InternalInterface.AccountSettings.Posting.DefaultConfig = InternalInterface.AccountSettings.Posting.DefaultConfig or
	{
		pricingModelOrder = { "market", "vendor", "fixed", },
		priceMatcherOrder = { "undercut", "self", "vendor", },
		usePriceMatching = false,
		bindPrices = false,
		stackSize = 1,
		duration = 3,
	}
	InternalInterface.AccountSettings.Posting.HiddenItems = InternalInterface.AccountSettings.Posting.HiddenItems or {}
	InternalInterface.AccountSettings.PricingModels = InternalInterface.AccountSettings.PricingModels or {}
	InternalInterface.AccountSettings.PriceScorers = InternalInterface.AccountSettings.PriceScorers or {}
	InternalInterface.AccountSettings.PriceScorers.Settings = InternalInterface.AccountSettings.PriceScorers.Settings or
	{
		default = "market",
		colorRanges = { -1, -1, -1, 85, 115, -1, -1, -1, -1 },
	}
	InternalInterface.AccountSettings.PriceMatchers = InternalInterface.AccountSettings.PriceMatchers or {}

	InternalInterface.ShardSettings.Posting = InternalInterface.ShardSettings.Posting or {}
	
	InternalInterface.CharacterSettings.Posting = InternalInterface.CharacterSettings.Posting or {}
	InternalInterface.CharacterSettings.Posting.HiddenItems = InternalInterface.CharacterSettings.Posting.HiddenItems or {}
	InternalInterface.CharacterSettings.Posting.ItemConfig = InternalInterface.CharacterSettings.Posting.ItemConfig or {}
	InternalInterface.CharacterSettings.Posting.AutoConfig = InternalInterface.CharacterSettings.Posting.AutoConfig or {}
end

local function LoadSettings(addonId)
	if addonId == addonID then
		InternalInterface.AccountSettings = BananAHAccountSettings or {}
		InternalInterface.ShardSettings = BananAHShardSettings or {}
		InternalInterface.CharacterSettings = BananAHCharacterSettings or {}
		BuildSettings()
	end
end
table.insert(Event.Addon.SavedVariables.Load.End, {LoadSettings, addonID, "LoadSettings"})

local function SaveSettings(addonId)
	if addonId == addonID then
		BananAHAccountSettings = InternalInterface.AccountSettings
		BananAHShardSettings = InternalInterface.ShardSettings
		BananAHCharacterSettings = InternalInterface.CharacterSettings
	end
end
table.insert(Event.Addon.SavedVariables.Save.Begin, {SaveSettings, addonID, "SaveSettings"})