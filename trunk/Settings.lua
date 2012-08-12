-- ***************************************************************************************************************************************************
-- * Settings.lua                                                                                                                                    *
-- ***************************************************************************************************************************************************
-- * Initializes default addon settings                                                                                                              *
-- * Loads / Saves player settings                                                                                                                   *
-- ***************************************************************************************************************************************************
-- * 0.4.0  / 2012.05.30 / Baanano: First version, splitted out of the old Init.lua                                                                  *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

InternalInterface = InternalInterface or {}
InternalInterface.AccountSettings = InternalInterface.AccountSettings or {}
InternalInterface.ShardSettings = InternalInterface.ShardSettings or {}
InternalInterface.CharacterSettings = InternalInterface.CharacterSettings or {}

local function DefaultSettings()
	InternalInterface.AccountSettings.General = InternalInterface.AccountSettings.General or
	{
		showMapIcon = true,
		autoOpen = false,
		autoClose = false,
	}
	InternalInterface.AccountSettings.Posting = InternalInterface.AccountSettings.Posting or 
	{
		startPostingQueuePaused = false,
		rarityFilter = 1,
	}
	InternalInterface.AccountSettings.Posting.DefaultConfig = InternalInterface.AccountSettings.Posting.DefaultConfig or
	{
		usePriceMatching = false,
		bindPrices = false,
		stackSize = 100,
		duration = 3,
	}
	InternalInterface.AccountSettings.Posting.HiddenItems = InternalInterface.AccountSettings.Posting.HiddenItems or {}
	InternalInterface.AccountSettings.Auctions = InternalInterface.AccountSettings.Auctions or 
	{
		allowLeftCancel = false,
		restrictCharacterFilter = false,
		defaultCompetitionFilter = 1,
		defaultBelowFilter = 0,
		defaultScoreFilter = { true, true, true, true, true, true },
	}
	InternalInterface.AccountSettings.PricingModels = InternalInterface.AccountSettings.PricingModels or {}
	InternalInterface.AccountSettings.PriceScorers = InternalInterface.AccountSettings.PriceScorers or {}
	InternalInterface.AccountSettings.PriceScorers.Settings = InternalInterface.AccountSettings.PriceScorers.Settings or
	{
		default = "market",
		colorLimits = { 85, 85, 115, 115 },
	}
	InternalInterface.AccountSettings.PriceMatchers = InternalInterface.AccountSettings.PriceMatchers or {}
	InternalInterface.AccountSettings.AuctionSearchers = InternalInterface.AccountSettings.AuctionSearchers or {}
	
	InternalInterface.CharacterSettings.Posting = InternalInterface.CharacterSettings.Posting or {}
	InternalInterface.CharacterSettings.Posting.HiddenItems = InternalInterface.CharacterSettings.Posting.HiddenItems or {}
	InternalInterface.CharacterSettings.Posting.ItemConfig = InternalInterface.CharacterSettings.Posting.ItemConfig or {}
	InternalInterface.CharacterSettings.Posting.AutoConfig = InternalInterface.CharacterSettings.Posting.AutoConfig or {}
end

local function LoadSettings(addonId)
	if addonId == addonID then
		InternalInterface.AccountSettings = _G[addonID .. "AccountSettings"] or {}
		InternalInterface.ShardSettings = _G[addonID .. "ShardSettings"] or {}
		InternalInterface.CharacterSettings = _G[addonID .. "CharacterSettings"] or {}
		DefaultSettings()
	end
end
table.insert(Event.Addon.SavedVariables.Load.End, {LoadSettings, addonID, "Settings.Load"})

local function SaveSettings(addonId)
	if addonId == addonID then
		_G[addonID .. "AccountSettings"] = InternalInterface.AccountSettings
		_G[addonID .. "ShardSettings"] = InternalInterface.ShardSettings
		_G[addonID .. "CharacterSettings"] = InternalInterface.CharacterSettings
	end
end
table.insert(Event.Addon.SavedVariables.Save.Begin, {SaveSettings, addonID, "Settings.Save"})