-- ***************************************************************************************************************************************************
-- * Helper.lua                                                                                                                                      *
-- ***************************************************************************************************************************************************
-- * Helper methods                                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.11.01 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local BASE_CATEGORY = InternalInterface.Category.BASE_CATEGORY
local CDetail = InternalInterface.Category.Detail

InternalInterface.Helper = InternalInterface.Helper or {}

function InternalInterface.Helper.GetCategoryConfig(category)
	category = category or BASE_CATEGORY
	local defaultConfig = InternalInterface.AccountSettings.Posting.CategoryConfig[category]
	while not defaultConfig do
		local detail = CDetail(category)
		category = detail and detail.parent or BASE_CATEGORY
		defaultConfig = InternalInterface.AccountSettings.Posting.CategoryConfig[category]
	end
	return defaultConfig
end

function InternalInterface.Helper.GetPostingSettings(itemType, category)
	local itemSettings = InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] or {}
	local categorySettings = InternalInterface.Helper.GetCategoryConfig(category) or {}
	local generalSettings = InternalInterface.AccountSettings.Posting.Config or {}
	
	local postingSettings = {}
	
	postingSettings.referencePrice = itemSettings.pricingModelOrder or categorySettings.DefaultReferencePrice
	postingSettings.fallbackPrice = categorySettings.FallbackReferencePrice
	postingSettings.matchPrices = itemSettings.usePriceMatching
	if postingSettings.matchPrices == nil then postingSettings.matchPrices = categorySettings.ApplyMatching end
	
	postingSettings.lastBid = itemSettings.lastBid
	postingSettings.lastBuy = itemSettings.lastBuy
	postingSettings.bidPercentage = generalSettings.BidPercentage / 100
	postingSettings.bindPrices = itemSettings.bindPrices
	if postingSettings.bindPrices == nil then postingSettings.bindPrices = generalSettings.BindPrices end
	
	postingSettings.stackSize = itemSettings.stackSize or categorySettings.StackSize
	postingSettings.stackNumber = itemSettings.stackNumber or categorySettings.StackNumber
	postingSettings.stackLimit = itemSettings.limitActive
	if postingSettings.stackLimit == nil then postingSettings.stackLimit = categorySettings.StackLimit end
	
	postingSettings.duration = itemSettings.duration or categorySettings.Duration
	
	postingSettings.blackList = categorySettings.BlackList

	return postingSettings
end
