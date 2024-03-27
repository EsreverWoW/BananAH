-- ***************************************************************************************************************************************************
-- * Settings.lua                                                                                                                                    *
-- ***************************************************************************************************************************************************
-- * Initializes default addon settings                                                                                                              *
-- * Loads / Saves player settings                                                                                                                   *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.28 / Baanano: Added new settings                                                                                                *
-- * 0.4.0 / 2012.05.30 / Baanano: First version, splitted out of the old Init.lua                                                                   *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local TInsert = table.insert
local pairs = pairs

InternalInterface = InternalInterface or {}
InternalInterface.AccountSettings = InternalInterface.AccountSettings or {}
InternalInterface.ShardSettings = InternalInterface.ShardSettings or {}
InternalInterface.CharacterSettings = InternalInterface.CharacterSettings or {}

local function DefaultSettings()
	InternalInterface.AccountSettings.General = InternalInterface.AccountSettings.General or {}
	if InternalInterface.AccountSettings.General.ShowMapIcon == nil then InternalInterface.AccountSettings.General.ShowMapIcon = true end
	if InternalInterface.AccountSettings.General.AutoOpen == nil then InternalInterface.AccountSettings.General.AutoOpen = false end
	if InternalInterface.AccountSettings.General.AutoClose == nil then InternalInterface.AccountSettings.General.AutoClose = false end
	if InternalInterface.AccountSettings.General.QueuePausedOnStart == nil then InternalInterface.AccountSettings.General.QueuePausedOnStart = false end

	InternalInterface.AccountSettings.Search = InternalInterface.AccountSettings.Search or {}
	InternalInterface.AccountSettings.Search.DefaultSearcher = InternalInterface.AccountSettings.Search.DefaultSearcher or "basic"
	if InternalInterface.AccountSettings.Search.DefaultOnline == nil then InternalInterface.AccountSettings.Search.DefaultOnline = false end
	InternalInterface.AccountSettings.Search.SavedSearchs = InternalInterface.AccountSettings.Search.SavedSearchs or {}
	
	InternalInterface.AccountSettings.Posting = InternalInterface.AccountSettings.Posting or {}
	InternalInterface.AccountSettings.Posting.RarityFilter = InternalInterface.AccountSettings.Posting.RarityFilter or 1
	if InternalInterface.AccountSettings.Posting.AutoPostPause == nil then InternalInterface.AccountSettings.Posting.AutoPostPause = true end
	InternalInterface.AccountSettings.Posting.AbsoluteUndercut = InternalInterface.AccountSettings.Posting.AbsoluteUndercut or 1
	InternalInterface.AccountSettings.Posting.RelativeUndercut = InternalInterface.AccountSettings.Posting.RelativeUndercut or 0
	InternalInterface.AccountSettings.Posting.HiddenItems = InternalInterface.AccountSettings.Posting.HiddenItems or {}
	InternalInterface.AccountSettings.Posting.Config = InternalInterface.AccountSettings.Posting.Config or {}
	InternalInterface.AccountSettings.Posting.Config.BidPercentage = InternalInterface.AccountSettings.Posting.Config.BidPercentage or 75
	if InternalInterface.AccountSettings.Posting.Config.BindPrices == nil then InternalInterface.AccountSettings.Posting.Config.BindPrices = false end

	InternalInterface.AccountSettings.Posting.CategoryConfig = InternalInterface.AccountSettings.Posting.CategoryConfig or {}
	InternalInterface.AccountSettings.Posting.CategoryConfig[""] = InternalInterface.AccountSettings.Posting.CategoryConfig[""] or {}
	for categoryID, categoryConfig in pairs(InternalInterface.AccountSettings.Posting.CategoryConfig) do
		categoryConfig.DefaultReferencePrice = categoryConfig.DefaultReferencePrice or "BMarket"
		categoryConfig.FallbackReferencePrice = categoryConfig.FallbackReferencePrice or "BVendor"
		if categoryConfig.ApplyMatching == nil then categoryConfig.ApplyMatching = false end
		categoryConfig.StackSize = categoryConfig.StackSize or "+"
		categoryConfig.AuctionLimit = categoryConfig.AuctionLimit or "+"
		if categoryConfig.PostIncomplete == nil then categoryConfig.PostIncomplete = true end
		categoryConfig.Duration = categoryConfig.Duration or 3
		categoryConfig.BlackList = categoryConfig.BlackList or {}
	end

	InternalInterface.AccountSettings.Auctions = InternalInterface.AccountSettings.Auctions or {}
	if InternalInterface.AccountSettings.Auctions.BypassCancelPopup == nil then InternalInterface.AccountSettings.Auctions.BypassCancelPopup = false end
	if InternalInterface.AccountSettings.Auctions.RestrictCharacterFilter == nil then InternalInterface.AccountSettings.Auctions.RestrictCharacterFilter = false end
	InternalInterface.AccountSettings.Auctions.DefaultCompetitionFilter = InternalInterface.AccountSettings.Auctions.DefaultCompetitionFilter or 1
	InternalInterface.AccountSettings.Auctions.DefaultBelowFilter = InternalInterface.AccountSettings.Auctions.DefaultBelowFilter or 0
	InternalInterface.AccountSettings.Auctions.DefaultScoreFilter = InternalInterface.AccountSettings.Auctions.DefaultScoreFilter or { true, true, true, true, true, true }

	InternalInterface.AccountSettings.Scoring = InternalInterface.AccountSettings.Scoring or {}
	InternalInterface.AccountSettings.Scoring.ReferencePrice = InternalInterface.AccountSettings.Scoring.ReferencePrice or "BMarket"
	InternalInterface.AccountSettings.Scoring.ColorLimits = InternalInterface.AccountSettings.Scoring.ColorLimits or { 85, 85, 115, 115 }
	
	InternalInterface.AccountSettings.Prices = InternalInterface.AccountSettings.Prices or {}
	InternalInterface.PGCConfig.LoadSavedPrices()
	
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
TInsert(Event.Addon.SavedVariables.Load.End, {LoadSettings, addonID, addonID .. ".Settings.Load"})

local function SaveSettings(addonId)
	if addonId == addonID then
		_G[addonID .. "AccountSettings"] = InternalInterface.AccountSettings
		_G[addonID .. "ShardSettings"] = InternalInterface.ShardSettings
		_G[addonID .. "CharacterSettings"] = InternalInterface.CharacterSettings
	end
end
TInsert(Event.Addon.SavedVariables.Save.Begin, {SaveSettings, addonID, addonID .. ".Settings.Save"})
