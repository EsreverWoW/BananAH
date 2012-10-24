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

InternalInterface = InternalInterface or {}
InternalInterface.AccountSettings = InternalInterface.AccountSettings or {}
InternalInterface.ShardSettings = InternalInterface.ShardSettings or {}
InternalInterface.CharacterSettings = InternalInterface.CharacterSettings or {}

local function DefaultSettings()
	-- Account: General settings
	--  + ShowMapIcon: If active, the BananAH icon is shown next to the Minimap
	--  + AutoOpen: If active, BananAH is opened whenever the AH is opened
	--  + AutoClose: If active, BananAH is closed whenever the AH is closed
	--  + QueuePausedOnStart: If active, the posting queue will be paused on addon load. Note other addons may override this setting
	InternalInterface.AccountSettings.General = InternalInterface.AccountSettings.General or {}
	if InternalInterface.AccountSettings.General.ShowMapIcon == nil then InternalInterface.AccountSettings.General.ShowMapIcon = true end
	if InternalInterface.AccountSettings.General.AutoOpen == nil then InternalInterface.AccountSettings.General.AutoOpen = false end
	if InternalInterface.AccountSettings.General.AutoClose == nil then InternalInterface.AccountSettings.General.AutoClose = false end
	if InternalInterface.AccountSettings.General.QueuePausedOnStart == nil then InternalInterface.AccountSettings.General.QueuePausedOnStart = false end

	-- Account: Search frame settings
	--  + DefaultSearcher: Searcher to use when the BananAH window is opened the first time
	--  + DefaultOnline: If active, BananAH starts in online mode (if the searcher supports online mode)
	--  * SavedSearchs: Container for saved searchs (initialization only)
	InternalInterface.AccountSettings.Search = InternalInterface.AccountSettings.Search or {}
	InternalInterface.AccountSettings.Search.DefaultSearcher = InternalInterface.AccountSettings.Search.DefaultSearcher or "basic"
	if InternalInterface.AccountSettings.Search.DefaultOnline == nil then InternalInterface.AccountSettings.Search.DefaultOnline = false end
	InternalInterface.AccountSettings.Search.SavedSearchs = InternalInterface.AccountSettings.Search.SavedSearchs or {}
	
	-- Account: Post frame settings
	--  + RarityFilter: Minimum rarity for items to show in the item list
	--  * HiddenItems: Container for account-level hidden items (initialization only)
	--  * CategoryConfig: Container for default posting settings, by item category (initialization for global category only)
	--    + DefaultReferencePrice: Pricing model to use for items of this category that haven't their own reference price
	--    + FallbackReferencePrice: Pricing model to use for items of this category that haven't their own reference price when the default fails
	--    + ApplyMatching: If active and the item hasn't its own config for price matching rules, price matching rules of the pricing model will be applied
	--    + StackSize: Stack size to use if the item hasn't its own config for stack size
	--    + StackNumber: Stack number to use if the item hasn't its own config for stack number
	--    + StackLimit: If active and the item hasn't its own config for stack limit, this will prevent the number of active auctions to be higher than the stack number
	--    + BidPercentage: Percentage of the buyout price to use as bid price
	--    + BindPrices: If active and the item hasn't its own config for price binding, bid price will be matched to the buyout price
	--    + Duration: Duration to use if the item hasn't its own config for duration
	InternalInterface.AccountSettings.Posting = InternalInterface.AccountSettings.Posting or {}
	InternalInterface.AccountSettings.Posting.RarityFilter = InternalInterface.AccountSettings.Posting.RarityFilter or 1
	InternalInterface.AccountSettings.Posting.HiddenItems = InternalInterface.AccountSettings.Posting.HiddenItems or {}
	InternalInterface.AccountSettings.Posting.Config = InternalInterface.AccountSettings.Posting.Config or {}
	InternalInterface.AccountSettings.Posting.Config.BidPercentage = InternalInterface.AccountSettings.Posting.Config.BidPercentage or 75
	if InternalInterface.AccountSettings.Posting.Config.BindPrices == nil then InternalInterface.AccountSettings.Posting.Config.BindPrices = false end

	InternalInterface.AccountSettings.Posting.CategoryConfig = InternalInterface.AccountSettings.Posting.CategoryConfig or {}
	InternalInterface.AccountSettings.Posting.CategoryConfig[""] = InternalInterface.AccountSettings.Posting.CategoryConfig[""] or {}
	InternalInterface.AccountSettings.Posting.CategoryConfig[""].DefaultReferencePrice = InternalInterface.AccountSettings.Posting.CategoryConfig[""].DefaultReferencePrice or "BMarket"
	InternalInterface.AccountSettings.Posting.CategoryConfig[""].FallbackReferencePrice = InternalInterface.AccountSettings.Posting.CategoryConfig[""].FallbackReferencePrice or "BVendor"
	if InternalInterface.AccountSettings.Posting.CategoryConfig[""].ApplyMatching == nil then InternalInterface.AccountSettings.Posting.CategoryConfig[""].ApplyMatching = false end
	InternalInterface.AccountSettings.Posting.CategoryConfig[""].StackSize = InternalInterface.AccountSettings.Posting.CategoryConfig[""].StackSize or "+"
	InternalInterface.AccountSettings.Posting.CategoryConfig[""].StackNumber = InternalInterface.AccountSettings.Posting.CategoryConfig[""].StackNumber or "A"
	if InternalInterface.AccountSettings.Posting.CategoryConfig[""].StackLimit == nil then InternalInterface.AccountSettings.Posting.CategoryConfig[""].StackLimit = false end
	InternalInterface.AccountSettings.Posting.CategoryConfig[""].Duration = InternalInterface.AccountSettings.Posting.CategoryConfig[""].Duration or 3
	InternalInterface.AccountSettings.Posting.CategoryConfig[""].BlackList = InternalInterface.AccountSettings.Posting.CategoryConfig[""].BlackList or {}

	-- Account: Selling frame settings
	--  + BypassCancelPopup: If active, the auction cancel popup won't be shown when cancelling auctions
	--  + RestrictCharacterFilter: Default value for the Restrict Character filter
	--  + DefaultCompetitionFilter: Default value for the Competition filter
	--  + DefaultBelowFilter: Default value for the Below filter
	--  + DefaultScoreFilter: Default values for the Score filters
	InternalInterface.AccountSettings.Auctions = InternalInterface.AccountSettings.Auctions or {}
	if InternalInterface.AccountSettings.Auctions.BypassCancelPopup == nil then InternalInterface.AccountSettings.Auctions.BypassCancelPopup = false end
	if InternalInterface.AccountSettings.Auctions.RestrictCharacterFilter == nil then InternalInterface.AccountSettings.Auctions.RestrictCharacterFilter = false end
	InternalInterface.AccountSettings.Auctions.DefaultCompetitionFilter = InternalInterface.AccountSettings.Auctions.DefaultCompetitionFilter or 1
	InternalInterface.AccountSettings.Auctions.DefaultBelowFilter = InternalInterface.AccountSettings.Auctions.DefaultBelowFilter or 0
	InternalInterface.AccountSettings.Auctions.DefaultScoreFilter = InternalInterface.AccountSettings.Auctions.DefaultScoreFilter or { true, true, true, true, true, true }

	-- Account: Scoring settings
	--  + ReferencePrice: Pricing model to use as reference when scoring
	--  + ColorLimits: Percentage limits for the scores (Very low, Low, Medium, High, Very high)
	InternalInterface.AccountSettings.Scoring = InternalInterface.AccountSettings.Scoring or {}
	InternalInterface.AccountSettings.Scoring.ReferencePrice = InternalInterface.AccountSettings.Scoring.ReferencePrice or "BMarket"
	InternalInterface.AccountSettings.Scoring.ColorLimits = InternalInterface.AccountSettings.Scoring.ColorLimits or { 85, 85, 115, 115 }
	
	InternalInterface.AccountSettings.PricingModels = InternalInterface.AccountSettings.PricingModels or {}

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
TInsert(Event.Addon.SavedVariables.Load.End, {LoadSettings, addonID, addonID .. ".Settings.Load"})

local function SaveSettings(addonId)
	if addonId == addonID then
		_G[addonID .. "AccountSettings"] = InternalInterface.AccountSettings
		_G[addonID .. "ShardSettings"] = InternalInterface.ShardSettings
		_G[addonID .. "CharacterSettings"] = InternalInterface.CharacterSettings
	end
end
TInsert(Event.Addon.SavedVariables.Save.Begin, {SaveSettings, addonID, addonID .. ".Settings.Save"})
