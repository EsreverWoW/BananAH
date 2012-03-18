local _, InternalInterface = ...

local L = InternalInterface.Localization.L

-- Constants
local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "interpercentilerange"
local PRICING_MODEL_NAME = L["PricingModel/interPercentileRangeName"]

local NUMBER_OF_DAYS = 3 -- TODO Get from config
local RANGE_AMPLITUDE = 50 -- TODO Get from config
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
	weightedText:SetText(L["PricingModel/interPercentileRangeWeight"])
	
	daysText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 50)
	daysText:SetFontSize(14)
	daysText:SetText(L["PricingModel/interPercentileRangeDays"])

	deviationText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 90)
	deviationText:SetFontSize(14)
	deviationText:SetText(L["PricingModel/interPercentileRangeRange"])

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
	
	local bids = {}
	local buys = {}
	
	local auctions = BananAH.GetAllAuctionData(item)
	for auctionId, auctionData in pairs(auctions) do
		if auctionData.lastSeenTime >= minTime then
			local weight = WEIGHTED and auctionData.stack or 1
			local bid = auctionData.bidUnitPrice
			local buy = auctionData.buyoutUnitPrice
			for i = 1, weight do
				table.insert(bids, bid)
				if buy then table.insert(buys, buy) end
			end
		end
	end
	
	if #bids <= 0 or #buys <= 0 then
		print("[" .. PRICING_MODEL_NAME .. "]: " .. L["PricingModel/interPercentileRangeError"])
		return nil, nil
	end
	
	table.sort(bids)
	table.sort(buys)
	
	local bid = 0
	local bidLi = math.floor(#bids * (50 - RANGE_AMPLITUDE / 2) / 100) + 1
	local bidHi = math.ceil(#bids * (50 + RANGE_AMPLITUDE / 2) / 100)
	if bidHi < bidLi then
		bid = math.floor((bids[bidLi] + bids[bidHi]) / 2)
	else
		for bidI = bidLi, bidHi do bid = bid + bids[bidI] end
		bid = bid / (bidHi - bidLi + 1)
	end
	
	local buy = 0
	local buyLi = math.floor(#buys * (50 - RANGE_AMPLITUDE / 2) / 100) + 1
	local buyHi = math.ceil(#buys * (50 + RANGE_AMPLITUDE / 2) / 100)
	if buyHi < buyLi then
		buy = math.floor((buys[buyLi] + buys[buyHi]) / 2)
	else
		for buyI = buyLi, buyHi do buy = buy + buys[buyI] end
		buy = buy / (buyHi - buyLi + 1)
	end
	
	return math.min(bid, buy), buy, matchPrice
end
BananAH.RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, ConfigFrame)
