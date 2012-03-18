local _, InternalInterface = ...

local L = InternalInterface.Localization.L

-- Constants
local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "stdev"
local PRICING_MODEL_NAME = L["PricingModel/stdevName"]

local NUMBER_OF_DAYS = 3 -- TODO Get from config
local MAX_DEVIATION = 1.5 -- TODO Get from config
local WEIGHTED = true -- TODO Get from config

local configFrame = nil
local function ConfigFrame(parent)
	if configFrame then return configFrame end

	configFrame = UI.CreateFrame("Frame", parent:GetName() .. ".StandardDeviationPricingModelConfig", parent)

	local weightedCheck = UI.CreateFrame("RiftCheckbox", configFrame:GetName() .. ".WeightedCheck", configFrame)
	local weightedText = UI.CreateFrame("Text", configFrame:GetName() .. ".WeightedText", configFrame)
	local daysText = UI.CreateFrame("Text", configFrame:GetName() .. ".DaysText", configFrame)
	local daysSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".DaysSlider", configFrame)
	local deviationText = UI.CreateFrame("Text", configFrame:GetName() .. ".DeviationText", configFrame)
	local deviationSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".DeviationSlider", configFrame)

	configFrame:SetVisible(false)
	
	weightedCheck:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 10)
	
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

	deviationSlider:SetPoint("CENTERLEFT", deviationText, "CENTERRIGHT", 20 + maxWidth - deviationText:GetWidth(), 8)	
	deviationSlider:SetWidth(300)
	deviationSlider:SetRange(0, 100)
	
	return configFrame
end

local function PricingModel(item, matchPrice)
	local minTime = os.time() - DAY_LENGTH * NUMBER_OF_DAYS
	
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
		if auctionData.lastSeenTime >= minTime then
			local weight = WEIGHTED and auctionData.stack or 1

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
	
	local maxDevSquared = MAX_DEVIATION * MAX_DEVIATION
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime then
			local weight = WEIGHTED and auctionData.stack or 1

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
