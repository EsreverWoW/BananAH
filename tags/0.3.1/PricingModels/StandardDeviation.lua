local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local IIDetail = Inspect.Item.Detail
local OTime = os.time
local L = InternalInterface.Localization.L

local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "stdev"
local PRICING_MODEL_NAME = L["PricingModel/stdevName"]

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
		local deviation = 1 + (InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].deviation or 50) / 100

		local bidW = 0
		local bidA = 0
		local bidT = 0
		local bidQ = 0
		local buyW = 0
		local buyA = 0
		local buyT = 0
		local buyQ = 0
		local expire = math.huge
		
		for auctionId, auctionData in pairs(auctions) do
			local weight = weighted and auctionData.stack or 1
			expire = days > 0 and math.min(expire, auctionData.lastSeenTime) or expire
				
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
		
		if bidW <= 0 then return callback() end

		if buyW <= 0 then
			buyT, buyQ, buyW = 0, 0, 1
		end
		bidW, bidA, bidT, bidQ = 0, bidT / bidW, 0, bidQ / bidW
		buyW, buyA, buyT, buyQ = 0, buyT / buyW, 0, buyQ / buyW

		local maxDevSquared = deviation * deviation
		for auctionId, auctionData in pairs(auctions) do
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

		if bidW <= 0 then return callback() end
		
		buyT = buyW > 0 and math.floor(buyT / buyW) or nil
		bidT = math.floor(bidT / bidW)
		bidT = buyT and math.min(bidT, buyT) or bidT		
		
		memoizedPrices[itemType] = { expire + DAY_LENGTH * days, bidT, buyT }
		callback(bidT, buyT)
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
	weightedText:SetText(L["PricingModel/stdevWeight"])
	
	daysText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 50)
	daysText:SetFontSize(14)
	daysText:SetText(L["PricingModel/stdevDays"])

	deviationText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 90)
	deviationText:SetFontSize(14)
	deviationText:SetText(L["PricingModel/stdevDeviation"])

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
