local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "interpercentilerange"
local PRICING_MODEL_NAME = L["PricingModel/interPercentileRangeName"]

local configFrame = nil

local function DefaultConfig()
	InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID] = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID] or
	{
		weight = true,
		days = 3,
		deviation = 50,
	}
end

local function PricingModel(item, auctions, autoMode)
	DefaultConfig()
	
	local weighted = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].weight or false
	local days = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].days or 3
	local range = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].deviation or 50
	
	local minTime = os.time() - DAY_LENGTH * days
	
	local bids = {}
	local buys = {}
	
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime or (days <= 0 and auctionData.removedBeforeExpiration == nil) then
			local weight = weighted and auctionData.stack or 1

			local bid = auctionData.bidUnitPrice
			local buy = auctionData.buyoutUnitPrice

			for i = 1, weight do
				table.insert(bids, bid)
				if buy then table.insert(buys, buy) end
			end
		end
	end
	
	if #bids <= 0 or #buys <= 0 then return nil end
	
	table.sort(bids)
	table.sort(buys)
	
	local bid = 0
	local bidLi = math.floor(#bids * (50 - range / 2) / 100) + 1
	local bidHi = math.ceil(#bids * (50 + range / 2) / 100)
	if bidHi < bidLi then
		bid = math.floor((bids[bidLi] + bids[bidHi]) / 2)
	else
		for bidI = bidLi, bidHi do bid = bid + bids[bidI] end
		bid = math.floor(bid / (bidHi - bidLi + 1))
	end
	
	local buy = 0
	local buyLi = math.floor(#buys * (50 - range / 2) / 100) + 1
	local buyHi = math.ceil(#buys * (50 + range / 2) / 100)
	if buyHi < buyLi then
		buy = math.floor((buys[buyLi] + buys[buyHi]) / 2)
	else
		for buyI = buyLi, buyHi do buy = buy + buys[buyI] end
		buy = math.floor(buy / (buyHi - buyLi + 1))
	end
	
	return math.min(bid, buy), buy
end

local function ConfigFrame(parent)
	if configFrame then return configFrame end

	DefaultConfig()
	
	configFrame = UI.CreateFrame("Frame", parent:GetName() .. ".StandardDeviationPricingModelConfig", parent)
	local weightedCheck = UI.CreateFrame("RiftCheckbox", configFrame:GetName() .. ".WeightedCheck", configFrame)
	local weightedText = UI.CreateFrame("Text", configFrame:GetName() .. ".WeightedText", configFrame)
	local daysText = UI.CreateFrame("Text", configFrame:GetName() .. ".DaysText", configFrame)
	local daysSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".DaysSlider", configFrame)
	local deviationText = UI.CreateFrame("Text", configFrame:GetName() .. ".DeviationText", configFrame)
	local deviationSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".DeviationSlider", configFrame)

	configFrame:SetVisible(false)
	
	weightedCheck:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 10)
	weightedCheck:SetChecked(InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].weight or false)
	
	weightedText:SetPoint("CENTERLEFT", weightedCheck, "CENTERRIGHT", 5, 0)
	weightedText:SetFontSize(14)
	weightedText:SetText(L["PricingModel/interPercentileRangeWeight"])
	
	daysText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 50)
	daysText:SetFontSize(14)
	daysText:SetText(L["PricingModel/interPercentileRangeDays"])

	deviationText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 90)
	deviationText:SetFontSize(14)
	deviationText:SetText(L["PricingModel/interPercentileRangeRange"])

	local maxWidth = math.max(daysText:GetWidth(), deviationText:GetWidth())
	
	daysSlider:SetPoint("CENTERLEFT", daysText, "CENTERRIGHT", 20 + maxWidth - daysText:GetWidth(), 8)	
	daysSlider:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -10, 50)
	daysSlider:SetRange(0, 30)
	daysSlider:SetPosition(InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].days or 3)

	deviationSlider:SetPoint("CENTERLEFT", deviationText, "CENTERRIGHT", 20 + maxWidth - deviationText:GetWidth(), 8)	
	deviationSlider:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -10, 90)
	deviationSlider:SetRange(0, 100)
	deviationSlider:SetPosition(InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].deviation or 50)

	function weightedCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].weight = self:GetChecked()
	end
	
	function daysSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].days = position
	end
	
	function deviationSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].deviation = position
	end
	
	return configFrame
end

_G[addonID].RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, ConfigFrame)
