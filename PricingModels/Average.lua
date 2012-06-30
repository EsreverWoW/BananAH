-- ***************************************************************************************************************************************************
-- * PricingModels/Average.lua                                                                                                                       *
-- ***************************************************************************************************************************************************
-- * Average pricing model                                                                                                                           *
-- ***************************************************************************************************************************************************
-- * 0.4.0  / 2012.06.17 / Baanano: Rewritten for 1.9                                                                                                *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local IIDetail = Inspect.Item.Detail
local OTime = os.time
local L = InternalInterface.Localization.L

local DAY_LENGTH = 86400
local PRICING_MODEL_ID = "mean"
local PRICING_MODEL_NAME = L["PricingModel/meanName"]

local configFrame = nil
local memoizedPrices = {}

local function DefaultConfig()
	InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID] = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID] or
	{
		weight = true,
		days = 3,
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
	
	local function CalcAverage(auctions)
		local weighted = InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].weight or false

		local bidT = 0
		local bidW = 0
		local buyT = 0
		local buyW = 0
		local expire = math.huge
		
		for auctionId, auctionData in pairs(auctions) do
			local weight = weighted and auctionData.stack or 1
			expire = days > 0 and math.min(expire, auctionData.lastSeenTime) or expire
				
			bidT = bidT + auctionData.bidUnitPrice * weight
			bidW = bidW + weight
				
			if auctionData.buyoutUnitPrice then
				buyT = buyT + auctionData.buyoutUnitPrice * weight
				buyW = buyW + weight
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
		_G[addonID].GetAllAuctionData(CalcAverage, itemType, currentTime - DAY_LENGTH * days)
	else
		_G[addonID].GetActiveAuctionData(CalcAverage, itemType)
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
	
	configFrame = UI.CreateFrame("Frame", parent:GetName() .. ".MeanPricingModelConfig", parent)
	local weightedCheck = UI.CreateFrame("RiftCheckbox", configFrame:GetName() .. ".WeightedCheck", configFrame)
	local weightedText = UI.CreateFrame("Text", configFrame:GetName() .. ".WeightedText", configFrame)
	local daysText = UI.CreateFrame("Text", configFrame:GetName() .. ".DaysText", configFrame)
	local daysSlider = UI.CreateFrame("BSlider", configFrame:GetName() .. ".DaysSlider", configFrame)

	configFrame:SetVisible(false)
	
	weightedCheck:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 10)
	weightedCheck:SetChecked(InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].weight or false)
	
	weightedText:SetPoint("CENTERLEFT", weightedCheck, "CENTERRIGHT", 5, 0)
	weightedText:SetFontSize(14)
	weightedText:SetText(L["PricingModel/meanWeight"])
	
	daysText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, 50)
	daysText:SetFontSize(14)
	daysText:SetText(L["PricingModel/meanDays"])

	daysSlider:SetPoint("CENTERLEFT", daysText, "CENTERRIGHT", 20, 8)	
	daysSlider:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -10, 50)
	daysSlider:SetRange(0, 30)
	daysSlider:SetPosition(InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].days or 3)
	
	function weightedCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].weight = self:GetChecked()
		memoizedPrices = {}
	end
	
	function daysSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.PricingModels[PRICING_MODEL_ID].days = position
		memoizedPrices = {}
	end
	
	return configFrame
end

_G[addonID].RegisterPricingModel(PRICING_MODEL_ID, PRICING_MODEL_NAME, PricingModel, nil, ConfigFrame)
