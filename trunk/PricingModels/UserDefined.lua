local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local PRICING_MODEL_ID = "fixed"
local PRICING_MODEL_NAME = L["PricingModel/fixedName"]

local function PricingModel(item, auctions, autoMode)
	local ok, itemDetail = pcall(Inspect.Item.Detail, item)

	if not ok or not itemDetail then
		return 0, 0
	end
	
	local itemType = itemDetail.type
	
	InternalInterface.CharacterSettings.Posting.FixedPrices = InternalInterface.CharacterSettings.Posting.FixedPrices or {}
	InternalInterface.CharacterSettings.Posting.AutoPrices = InternalInterface.CharacterSettings.Posting.AutoPrices or {}
	
	local savedPrices = InternalInterface.CharacterSettings.Posting.FixedPrices[itemType]
	local autoPrices = InternalInterface.CharacterSettings.Posting.AutoPrices[itemType]
	local prices = autoMode and autoPrices or savedPrices or { bid = 0, buy = 0, }
	
	return prices.bid, prices.buy
end

local function SaveConfig(itemType, bid, buyout, auto)
	InternalInterface.CharacterSettings.Posting.FixedPrices = InternalInterface.CharacterSettings.Posting.FixedPrices or {}
	InternalInterface.CharacterSettings.Posting.AutoPrices = InternalInterface.CharacterSettings.Posting.AutoPrices or {}
	
	if auto then
		if bid then
			InternalInterface.CharacterSettings.Posting.AutoPrices[itemType] = { bid = bid, buy = buyout or 0 }
		else
			InternalInterface.CharacterSettings.Posting.AutoPrices[itemType] = nil
		end
	else
		if bid then
			InternalInterface.CharacterSettings.Posting.FixedPrices[itemType] = { bid = bid, buy = buyout or 0 }
		else
			InternalInterface.CharacterSettings.Posting.FixedPrices[itemType] = nil
		end
	end
end

_G[addonID].RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, SaveConfig)
