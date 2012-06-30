-- ***************************************************************************************************************************************************
-- * PricingModels/Vendor.lua                                                                                                                        *
-- ***************************************************************************************************************************************************
-- * Vendor pricing model                                                                                                                            *
-- ***************************************************************************************************************************************************
-- * 0.4.0  / 2012.06.17 / Baanano: Rewritten for 1.9                                                                                                *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local MFloor = math.floor
local MMin = math.min
local L = InternalInterface.Localization.L

local PRICING_MODEL_ID = "vendor"
local PRICING_MODEL_NAME = L["PricingModel/fallbackName"]

local configFrame = nil

local function DefaultConfig()
	InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID] = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID] or
	{
		bidMultiplier = 3,
		buyMultiplier = 5,
	}
end

local function PricingModel(callback, item, autoMode)
	local ok, itemDetail = pcall(Inspect.Item.Detail, item)
	
	DefaultConfig()
	
	local sellPrice = ok and itemDetail and itemDetail.sell or 1
	local bid = MFloor(sellPrice * InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].bidMultiplier)
	local buyout = MFloor(sellPrice * InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].buyMultiplier)
	
	callback(MMin(bid, buyout), buyout)
end

local function ConfigFrame(parent)
	if configFrame then return configFrame end
	
	DefaultConfig()
	
	configFrame = UI.CreateFrame("Frame", parent:GetName() .. ".FallbackPricingModelConfig", parent)
	local bidMultiplierText = UI.CreateFrame("Text", configFrame:GetName() .. ".BidMultiplierText", configFrame)
	local bidMultiplierSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".BidMultiplierSlider", configFrame)
	local buyMultiplierText = UI.CreateFrame("Text", configFrame:GetName() .. ".BuyMultiplierText", configFrame)
	local buyMultiplierSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".BuyMultiplierSlider", configFrame)

	configFrame:SetVisible(false)

	bidMultiplierText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 10)
	bidMultiplierText:SetFontSize(14)
	bidMultiplierText:SetText(L["PricingModel/fallbackBidMultiplier"])
	
	buyMultiplierText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 50)
	buyMultiplierText:SetFontSize(14)
	buyMultiplierText:SetText(L["PricingModel/fallbackBuyMultiplier"])

	local maxWidth = math.max(bidMultiplierText:GetWidth(), buyMultiplierText:GetWidth())
	
	bidMultiplierSlider:SetPoint("CENTERLEFT", bidMultiplierText, "CENTERRIGHT", 20 + maxWidth - bidMultiplierText:GetWidth(), 8)	
	bidMultiplierSlider:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -10, 10)
	bidMultiplierSlider:SetRange(1, 25)
	bidMultiplierSlider:SetPosition(InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].bidMultiplier)

	buyMultiplierSlider:SetPoint("CENTERLEFT", buyMultiplierText, "CENTERRIGHT", 20 + maxWidth - buyMultiplierText:GetWidth(), 8)	
	buyMultiplierSlider:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -10, 50)
	buyMultiplierSlider:SetRange(1, 25)
	buyMultiplierSlider:SetPosition(InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].buyMultiplier)
	
	function bidMultiplierSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].bidMultiplier = position
	end
	
	function buyMultiplierSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].buyMultiplier = position
	end
	
	return configFrame
end

_G[addonID].RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, ConfigFrame)
