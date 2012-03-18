local _, InternalInterface = ...

local L = InternalInterface.Localization.L

-- Constants
local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "stdev"
local PRICING_MODEL_NAME = L["PricingModel/stdevName"]

local configFrame = nil
local function ConfigFrame(parent)
	if configFrame then return configFrame end

	InternalInterface.Settings.Config = InternalInterface.Settings.Config or {}
	InternalInterface.Settings.Config.PricingModels = InternalInterface.Settings.Config.PricingModels or {}
	
	configFrame = UI.CreateFrame("Frame", parent:GetName() .. ".StandardDeviationPricingModelConfig", parent)

	local weightedCheck = UI.CreateFrame("RiftCheckbox", configFrame:GetName() .. ".WeightedCheck", configFrame)
	local weightedText = UI.CreateFrame("Text", configFrame:GetName() .. ".WeightedText", configFrame)
	local daysText = UI.CreateFrame("Text", configFrame:GetName() .. ".DaysText", configFrame)
	local daysSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".DaysSlider", configFrame)
	local deviationText = UI.CreateFrame("Text", configFrame:GetName() .. ".DeviationText", configFrame)
	local deviationSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".DeviationSlider", configFrame)

	configFrame:SetVisible(false)
	
	weightedCheck:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 10)
	weightedCheck:SetChecked(InternalInterface.Settings.Config.PricingModels.stdevWeight or false)
	
	weightedText:SetPoint("CENTERLEFT", weightedCheck, "CENTERRIGHT", 5, 0)
	weightedText:SetFontSize(14)
	weightedText:SetText(L["PricingModel/stdevWeight"])
	
	daysText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 50)
	daysText:SetFontSize(14)
	daysText:SetText(L["PricingModel/stdevDays"])

	deviationText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 90)
	deviationText:SetFontSize(14)
	deviationText:SetText(L["PricingModel/stdevDeviation"])

	local maxWidth = math.max(daysText:GetWidth(), deviationText:GetWidth())
	
	daysSlider:SetPoint("CENTERLEFT", daysText, "CENTERRIGHT", 20 + maxWidth - daysText:GetWidth(), 8)	
	daysSlider:SetWidth(300)
	daysSlider:SetRange(0, 30)
	daysSlider:SetPosition(InternalInterface.Settings.Config.PricingModels.stdevDays or 3)

	deviationSlider:SetPoint("CENTERLEFT", deviationText, "CENTERRIGHT", 20 + maxWidth - deviationText:GetWidth(), 8)	
	deviationSlider:SetWidth(300)
	deviationSlider:SetRange(0, 100)
	deviationSlider:SetPosition(InternalInterface.Settings.Config.PricingModels.stdevDeviation or 50)

	function weightedCheck.Event:CheckboxChange()
		InternalInterface.Settings.Config.PricingModels.stdevWeight = self:GetChecked()
	end
	
	function daysSlider.Event:PositionChanged(position)
		InternalInterface.Settings.Config.PricingModels.stdevDays = position
	end
	
	function deviationSlider.Event:PositionChanged(position)
		InternalInterface.Settings.Config.PricingModels.stdevDeviation = position
	end
	
	
	return configFrame
end

local function PricingModel(item, matchPrice)
	local weighted = InternalInterface.Settings.Config.PricingModels.stdevWeight or false
	local days = InternalInterface.Settings.Config.PricingModels.stdevDays or 3
	local deviation = 1 + (InternalInterface.Settings.Config.PricingModels.stdevDeviation or 50) / 100
	local minTime = os.time() - DAY_LENGTH * days
	
	local bidW = 0
	local bidA = 0
	local bidT = 0
	local bidQ = 0

	local buyW = 0
	local buyA = 0
	local buyT = 0
	local buyQ = 0
	
	local auctions = BananAH.GetAllAuctionData(item)
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime or (days <= 0 and auctionData.removedBeforeExpiration == nil) then
			local weight = weighted and auctionData.stack or 1

			local pBidA = bidA
			bidW = bidW + weight
			bidA = bidA + weight * (auctionData.bidUnitPrice - bidA) / bidW
			bidT = bidT + weight * auctionData.bidUnitPrice
			bidQ = bidQ + weight * (auctionData.bidUnitPrice - pBidA) * (auctionData.bidUnitPrice - bidA)

			if auctionData.buyoutUnitPrice then
				local pBuyA = buyA
				buyW = buyW + weight
				buyA = buyA + weight * (auctionData.buyoutUnitPrice - buyA) / buyW
				buyT = buyT + weight * auctionData.buyoutUnitPrice
				buyQ = buyQ + weight * (auctionData.buyoutUnitPrice - pBuyA) * (auctionData.buyoutUnitPrice - buyA)
			end
		end
	end
	
	if bidW <= 0 or buyW <= 0 then
		print("[" .. PRICING_MODEL_NAME .. "]: " .. L["PricingModel/stdevError"])
		return nil, nil
	end
	
	bidW, bidA, bidT, bidQ = 0, bidT / bidW, 0, bidQ / bidW
	buyW, buyA, buyT, buyQ = 0, buyT / buyW, 0, buyQ / buyW
	
	local maxDevSquared = deviation * deviation
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime or (days <= 0 and auctionData.removedBeforeExpiration == nil) then
			local weight = weighted and auctionData.stack or 1

			local bidD = auctionData.bidUnitPrice - bidA
			if bidD * bidD <= bidQ * maxDevSquared then
				bidW = bidW + weight
				bidT = bidT + weight * auctionData.bidUnitPrice
			end

			if auctionData.buyoutUnitPrice then
				local buyD = auctionData.buyoutUnitPrice - buyA
				if buyD * buyD <= buyQ * maxDevSquared then
					buyW = buyW + weight
					buyT = buyT + weight * auctionData.buyoutUnitPrice
				end
			end
		end
	end
	
	if bidW <= 0 then bidT, bidW = bidA, 1 end
	if buyW <= 0 then buyT, buyW = buyA, 1 end

	return math.min(math.floor(bidT / bidW), math.floor(buyT / buyW)), math.floor(buyT / buyW), matchPrice
end
BananAH.RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, ConfigFrame)
