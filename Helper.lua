-- ***************************************************************************************************************************************************
-- * Helper.lua                                                                                                                                      *
-- ***************************************************************************************************************************************************
-- * Helper methods                                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.11.01 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

InternalInterface.Helper = InternalInterface.Helper or {}

function InternalInterface.Helper.GetCategoryConfig(category)
	category = category or InternalInterface.Category.BASE_CATEGORY
	local defaultConfig = InternalInterface.AccountSettings.Posting.CategoryConfig[category]
	while not defaultConfig do
		local detail = InternalInterface.Category.Detail(category)
		category = detail and detail.parent or InternalInterface.Category.BASE_CATEGORY
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
	postingSettings.auctionLimit = itemSettings.auctionLimit or categorySettings.AuctionLimit
	postingSettings.postIncomplete = itemSettings.postIncomplete
	if postingSettings.postIncomplete == nil then postingSettings.postIncomplete = categorySettings.PostIncomplete end
	
	postingSettings.duration = itemSettings.duration or categorySettings.Duration
	
	postingSettings.blackList = categorySettings.BlackList

	return postingSettings
end
