local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "median"
local PRICING_MODEL_NAME = L["PricingModel/medianName"]

local configFrame = nil

local function DefaultConfig()
	InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID] = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID] or
	{
		weight = true,
		days = 3,
	}
end

local function PricingModel(item, auctions, autoMode)
	DefaultConfig()
	
	local weighted = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].weight or false
	local days = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].days or 3
	
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
	
	local bid = math.floor((bids[math.floor(#bids / 2) + (#bids % 2)] + bids[math.floor(#bids / 2) + 1]) / 2)
	local buy = math.floor((buys[math.floor(#buys / 2) + (#buys % 2)] + buys[math.floor(#buys / 2) + 1]) / 2)

	return math.min(bid, buy), buy
end

local function ConfigFrame(parent)
	if configFrame then return configFrame end

	DefaultConfig()
	
	configFrame = UI.CreateFrame("Frame", parent:GetName() .. ".MedianPricingModelConfig", parent)
	local weightedCheck = UI.CreateFrame("RiftCheckbox", configFrame:GetName() .. ".WeightedCheck", configFrame)
	local weightedText = UI.CreateFrame("Text", configFrame:GetName() .. ".WeightedText", configFrame)
	local daysText = UI.CreateFrame("Text", configFrame:GetName() .. ".DaysText", configFrame)
	local daysSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".DaysSlider", configFrame)

	configFrame:SetVisible(false)
	
	weightedCheck:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 10)
	weightedCheck:SetChecked(InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].weight or false)
	
	weightedText:SetPoint("CENTERLEFT", weightedCheck, "CENTERRIGHT", 5, 0)
	weightedText:SetFontSize(14)
	weightedText:SetText(L["PricingModel/medianWeight"])
	
	daysText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 50)
	daysText:SetFontSize(14)
	daysText:SetText(L["PricingModel/medianDays"])

	daysSlider:SetPoint("CENTERLEFT", daysText, "CENTERRIGHT", 20, 8)	
	daysSlider:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -10, 50)
	daysSlider:SetRange(0, 30)
	daysSlider:SetPosition(InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].days or 3)
	
	function weightedCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].weight = self:GetChecked()
	end
	
	function daysSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].days = position
	end
	
	return configFrame
end

_G[addonID].RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, ConfigFrame)
