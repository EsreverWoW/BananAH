local _, InternalInterface = ...

local L = InternalInterface.Localization.L

-- Constants
local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "median"
local PRICING_MODEL_NAME = L["PricingModel/medianName"]

local configFrame = nil
local function ConfigFrame(parent)
	if configFrame then return configFrame end

	InternalInterface.Settings.Config = InternalInterface.Settings.Config or {}
	InternalInterface.Settings.Config.PricingModels = InternalInterface.Settings.Config.PricingModels or {}
	
	configFrame = UI.CreateFrame("Frame", parent:GetName() .. ".MedianPricingModelConfig", parent)

	local weightedCheck = UI.CreateFrame("RiftCheckbox", configFrame:GetName() .. ".WeightedCheck", configFrame)
	local weightedText = UI.CreateFrame("Text", configFrame:GetName() .. ".WeightedText", configFrame)
	local daysText = UI.CreateFrame("Text", configFrame:GetName() .. ".DaysText", configFrame)
	local daysSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".DaysSlider", configFrame)

	configFrame:SetVisible(false)
	
	weightedCheck:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 10)
	weightedCheck:SetChecked(InternalInterface.Settings.Config.PricingModels.medianWeight or false)
	
	weightedText:SetPoint("CENTERLEFT", weightedCheck, "CENTERRIGHT", 5, 0)
	weightedText:SetFontSize(14)
	weightedText:SetText(L["PricingModel/medianWeight"])
	
	daysText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 50)
	daysText:SetFontSize(14)
	daysText:SetText(L["PricingModel/medianDays"])

	daysSlider:SetPoint("CENTERLEFT", daysText, "CENTERRIGHT", 20, 8)	
	daysSlider:SetWidth(300)
	daysSlider:SetRange(0, 30)
	daysSlider:SetPosition(InternalInterface.Settings.Config.PricingModels.medianDays or 3)
	
	function weightedCheck.Event:CheckboxChange()
		InternalInterface.Settings.Config.PricingModels.medianWeight = self:GetChecked()
	end
	
	function daysSlider.Event:PositionChanged(position)
		InternalInterface.Settings.Config.PricingModels.medianDays = position
	end
	
	return configFrame
end

local function PricingModel(item, matchPrice)
	local weighted = InternalInterface.Settings.Config.PricingModels.medianWeight or false
	local days = InternalInterface.Settings.Config.PricingModels.medianDays or 3
	local minTime = os.time() - DAY_LENGTH * days
	
	local bids = {}
	local buys = {}
	
	local auctions = BananAH.GetAllAuctionData(item)
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
	
	if #bids <= 0 or #buys <= 0 then
		print("[" .. PRICING_MODEL_NAME .. "]: " .. L["PricingModel/medianError"])
		return nil, nil
	end
	
	table.sort(bids)
	table.sort(buys)
	
	local bid = math.floor((bids[math.floor(#bids / 2) + (#bids % 2)] + bids[math.floor(#bids / 2) + 1]) / 2)
	local buy = math.floor((buys[math.floor(#buys / 2) + (#buys % 2)] + buys[math.floor(#buys / 2) + 1]) / 2)

	return math.min(bid, buy), buy, matchPrice
end
BananAH.RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, ConfigFrame)
