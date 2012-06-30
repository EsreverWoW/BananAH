local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local PRICE_MATCHER_ID = "vendor"
local PRICE_MATCHER_NAME = L["PriceMatcher/vendorName"]
local AUCTION_FEE_REDUCTION = 0.95

local configFrame = nil

local function DefaultConfig()
	InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID] = InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID] or
	{
		enabled = true,
	}
end

local function PriceMatcher(callback, item, bid, buy)
	DefaultConfig()

	if not InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID].enabled then
		return bid, buy
	end

	local ok, itemDetail = pcall(Inspect.Item.Detail, item)
	
	local sellPrice = ok and itemDetail and itemDetail.sell
	
	if not sellPrice then 
		return callback(bid, buy)
	end
	
	sellPrice = math.ceil(sellPrice / AUCTION_FEE_REDUCTION)
	
	bid = math.max(bid, sellPrice)
	buy = math.max(buy, sellPrice)
	
	callback(math.min(bid, buy), buy)
end

local function ConfigFrame(parent)
	if configFrame then return configFrame end

	DefaultConfig()
	
	configFrame = UI.CreateFrame("Frame", parent:GetName() .. ".VendorPriceMatcherConfig", parent)
	local enabledCheck = UI.CreateFrame("RiftCheckbox", configFrame:GetName() .. ".EnabledCheck", configFrame)
	local enabledText = UI.CreateFrame("Text", configFrame:GetName() .. ".EnabledText", configFrame)

	configFrame:SetVisible(false)
	
	enabledCheck:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 10)
	enabledCheck:SetChecked(InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID].enabled or false)
	
	enabledText:SetPoint("CENTERLEFT", enabledCheck, "CENTERRIGHT", 5, 0)
	enabledText:SetFontSize(14)
	enabledText:SetText(L["PriceMatcher/vendorEnable"])
	
	function enabledCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.PriceMatchers[PRICE_MATCHER_ID].enabled = self:GetChecked()
	end
	
	return configFrame
end

_G[addonID].RegisterPriceMatcher(PRICE_MATCHER_ID, PRICE_MATCHER_NAME, PriceMatcher, ConfigFrame)
