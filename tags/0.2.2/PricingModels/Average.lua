local _, InternalInterface = ...

local L = InternalInterface.Localization.L

-- Constants
local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "mean"
local PRICING_MODEL_NAME = L["PricingModel/meanName"]

local configFrame = nil
local function ConfigFrame(parent)
	if configFrame then return configFrame end

	InternalInterface.Settings.Config = InternalInterface.Settings.Config or {}
	InternalInterface.Settings.Config.PricingModels = InternalInterface.Settings.Config.PricingModels or {}
	
	configFrame = UI.CreateFrame("Frame", parent:GetName() .. ".MeanPricingModelConfig", parent)

	local weightedCheck = UI.CreateFrame("RiftCheckbox", configFrame:GetName() .. ".WeightedCheck", configFrame)
	local weightedText = UI.CreateFrame("Text", configFrame:GetName() .. ".WeightedText", configFrame)
	local daysText = UI.CreateFrame("Text", configFrame:GetName() .. ".DaysText", configFrame)
	local daysSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".DaysSlider", configFrame)

	configFrame:SetVisible(false)
	
	weightedCheck:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 10)
	weightedCheck:SetChecked(InternalInterface.Settings.Config.PricingModels.meanWeight or false)
	
	weightedText:SetPoint("CENTERLEFT", weightedCheck, "CENTERRIGHT", 5, 0)
	weightedText:SetFontSize(14)
	weightedText:SetText(L["PricingModel/meanWeight"])
	
	daysText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 50)
	daysText:SetFontSize(14)
	daysText:SetText(L["PricingModel/meanDays"])

	daysSlider:SetPoint("CENTERLEFT", daysText, "CENTERRIGHT", 20, 8)	
	daysSlider:SetWidth(300)
	daysSlider:SetRange(0, 30)
	daysSlider:SetPosition(InternalInterface.Settings.Config.PricingModels.meanDays or 3)
	
	function weightedCheck.Event:CheckboxChange()
		InternalInterface.Settings.Config.PricingModels.meanWeight = self:GetChecked()
	end
	
	function daysSlider.Event:PositionChanged(position)
		InternalInterface.Settings.Config.PricingModels.meanDays = position
	end
	
	return configFrame
end

local function PricingModel(item, matchPrice)
	local weighted = InternalInterface.Settings.Config.PricingModels.meanWeight or false
	local days = InternalInterface.Settings.Config.PricingModels.meanDays or 3
	local minTime = os.time() - DAY_LENGTH * days
	
	local bidT = 0
	local bidW = 0
	local buyT = 0
	local buyW = 0
	
	local auctions = BananAH.GetAllAuctionData(item)
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime or (days <= 0 and auctionData.removedBeforeExpiration == nil) then
			local weight = weighted and auctionData.stack or 1
			bidT = bidT + auctionData.bidUnitPrice * weight
			bidW = bidW + weight
			if auctionData.buyoutUnitPrice then
				buyT = buyT + auctionData.buyoutUnitPrice * weight
				buyW = buyW + weight
			end
		end
	end
	
	if bidW <= 0 or buyW <= 0 then
		print("[" .. PRICING_MODEL_NAME .. "]: " .. L["PricingModel/meanError"])
		return nil, nil
	end

	return math.min(math.floor(bidT / bidW), math.floor(buyT / buyW)), math.floor(buyT / buyW), matchPrice
end
BananAH.RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, ConfigFrame)
