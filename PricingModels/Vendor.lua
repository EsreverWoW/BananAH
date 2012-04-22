local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local PRICING_MODEL_ID = "vendor"
local PRICING_MODEL_NAME = L["PricingModel/fallbackName"]

local function PricingModel(item, auctions, autoMode)
	local ok, itemDetail = pcall(Inspect.Item.Detail, item)
	
	local sellPrice = ok and itemDetail.sell or 1
	local bid = math.floor(sellPrice * 3)
	local buyout = math.floor(sellPrice * 5)
	
	return math.min(bid, buyout), buyout
end

_G[addonID].RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, nil)
