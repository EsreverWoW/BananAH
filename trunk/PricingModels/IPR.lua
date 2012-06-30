local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local IIDetail = Inspect.Item.Detail
local OTime = os.time
local L = InternalInterface.Localization.L

local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "interpercentilerange"
local PRICING_MODEL_NAME = L["PricingModel/interPercentileRangeName"]

local configFrame = nil
local memoizedPrices = {}

local function DefaultConfig()
	InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID] = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID] or
	{
		weight = true,
		days = 3,
		deviation = 50,
	}
end

local function PricingModel(callback, item)
	DefaultConfig()
	
	local days = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].days or 3
	
	local currentTime = OTime()
	local itemType
	if item:sub(1, 1) == "I" then
			itemType = item
	else
		local ok, itemDetail = pcall(IIDetail, item)
		itemType = ok and itemDetail and itemDetail.type or nil
	end
	if not itemType then return callback() end
	
	local memoizedPrice = memoizedPrices[itemType]
	if memoizedPrice and memoizedPrice[1] >= currentTime then
		return callback(memoizedPrice[2], memoizedPrice[3])
	end
	
	local function CalcPrice(auctions)
		local weighted = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].weight or false
		local range = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].deviation or 50

		local bids = {}
		local buys = {}
		local expire = math.huge
		
		for auctionId, auctionData in pairs(auctions) do
			local weight = weighted and auctionData.stack or 1
			expire = days > 0 and math.min(expire, auctionData.lastSeenTime) or expire
				
			local bid = auctionData.bidUnitPrice
			local buy = auctionData.buyoutUnitPrice

			for i = 1, weight do
				table.insert(bids, bid)
				if buy then table.insert(buys, buy) end
			end
		end
		
		if #bids <= 0 then return callback() end
		
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
	
		local buy = nil
		if #buys > 0 then
			buy = 0
			local buyLi = math.floor(#buys * (50 - range / 2) / 100) + 1
			local buyHi = math.ceil(#buys * (50 + range / 2) / 100)
			if buyHi < buyLi then
				buy = math.floor((buys[buyLi] + buys[buyHi]) / 2)
			else
			for buyI = buyLi, buyHi do buy = buy + buys[buyI] end
				buy = math.floor(buy / (buyHi - buyLi + 1))
			end
		end

		bid = buy and math.min(bid, buy) or bid
		
		memoizedPrices[itemType] = { expire + DAY_LENGTH * days, bid, buy }
		callback(bid, buy)
	end

	if days > 0 then
		_G[addonID].GetAllAuctionData(CalcPrice, itemType, currentTime - DAY_LENGTH * days)
	else
		_G[addonID].GetActiveAuctionData(CalcPrice, itemType)
	end
end

local function PurgeMemoizedPrices(scanType, totalAuctions, newAuctions, updatedAuctions, removedAuctions, beforeExpireAuctions, totalItemTypes, newItemTypes, updatedItemTypes, removedItemTypes, modifiedItemTypes)
	DefaultConfig()
	local days = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].days or 3

	local itemTypes = {}
	for itemType in pairs(newItemTypes) do itemTypes[itemType] = true end
	for itemType in pairs(updatedItemTypes) do itemTypes[itemType] = true end
	if days <= 0 then for itemType in pairs(removedItemTypes) do itemTypes[itemType] = true end end
	
	for itemType in pairs(itemTypes) do memoizedPrices[itemType] = nil end
end
table.insert(Event[addonID].AuctionData, { PurgeMemoizedPrices, addonID, "PricingModels." .. PRICING_MODEL_ID .. ".PurgeMemoizedPrices" })

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
		memoizedPrices = {}		
	end
	
	function daysSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].days = position
		memoizedPrices = {}		
	end
	
	function deviationSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].deviation = position
		memoizedPrices = {}		
	end
	
	return configFrame
end

_G[addonID].RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, ConfigFrame)
