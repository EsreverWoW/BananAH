local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local PRICE_SCORER_ID = "market"
local PRICE_SCORER_NAME = L["PriceScorer/marketName"]

local configFrame = nil

local function DefaultConfig()
	InternalInterface.AccountSettings.PriceScorers[PRICE_SCORER_ID] = InternalInterface.AccountSettings.PriceScorers[PRICE_SCORER_ID] or
	{
		pricingWeights = { mean = 1, stdev = 3, interpercentilerange = 5 }
	}
end

local function PricingModel(callback, item, autoMode, prices)
	DefaultConfig()
	
	local marketPricePricingModels = InternalInterface.AccountSettings.PriceScorers[PRICE_SCORER_ID].pricingWeights
	
	local marketPriceBidT = 0
	local marketPriceBidW = 0
	
	local marketPriceBuyT = 0
	local marketPriceBuyW = 0

	for key, priceData in pairs(prices) do
		local weight = marketPricePricingModels[key] or 0
		marketPriceBidT = marketPriceBidT + priceData.bid * weight
		marketPriceBidW = marketPriceBidW + weight
		marketPriceBuyT = marketPriceBuyT + (priceData.buy or 0) * weight
		marketPriceBuyW = marketPriceBuyW + (priceData.buy and weight or 0)
	end
	
	if marketPriceBidW <= 0 then return callback() end
	
	local buyout = marketPriceBuyW > 0 and math.floor(marketPriceBuyT / marketPriceBuyW) or nil
	local bid = math.min(math.floor(marketPriceBidT / marketPriceBidW), buyout or math.huge)
	callback(bid, buyout)
end

local function PriceScorer(callback, item, value, prices)
	if not prices[PRICE_SCORER_ID] then return callback() end
	local buy = prices[PRICE_SCORER_ID].buy or 1
	callback(math.min(999, value * 100 / buy))
end

local function ConfigFrame(parent)
	if configFrame then return configFrame end

	DefaultConfig()
	
	configFrame = UI.CreateFrame("Frame", parent:GetName() .. ".MarketPricePriceScorerConfig", parent)
	local title = UI.CreateFrame("Text", configFrame:GetName() .. ".Title", configFrame)
	
	configFrame:SetVisible(false)
	
	local modelFrames = {}
	local function ResetModelFrames()
		local pricingModels = InternalInterface.Modules.GetAllPricingModels()
		
		for pricingModelID, pricingModelData in pairs(pricingModels) do
			if pricingModelID ~= "fixed" then
				if not modelFrames[pricingModelID] then
					local name = UI.CreateFrame("Text", configFrame:GetName() .. "." .. pricingModelID .. ".Name", configFrame)
					name:SetFontSize(14)
					local weight = UI.CreateFrame("BSlider", configFrame:GetName() .. "." .. pricingModelID .. ".Weight", configFrame)
					weight:SetRange(0, 10)
					function weight.Event:PositionChanged(position)
						InternalInterface.AccountSettings.PriceScorers[PRICE_SCORER_ID].pricingWeights[pricingModelID] = position
					end
					modelFrames[pricingModelID] = { name = name, weight = weight }
				end
				modelFrames[pricingModelID].name:SetText(pricingModelData.displayName)
				modelFrames[pricingModelID].weight:SetPosition(InternalInterface.AccountSettings.PriceScorers[PRICE_SCORER_ID].pricingWeights[pricingModelID] or 0)
			end
		end
		
		local modelIDs = {}
		for pricingModelID in pairs(modelFrames) do table.insert(modelIDs, pricingModelID) end
		table.sort(modelIDs, function(a,b) return string.upper(modelFrames[a].name:GetText()) < string.upper(modelFrames[b].name:GetText()) end)
		
		local count = 0
		for _, pricingModelID in ipairs(modelIDs) do
			local frames = modelFrames[pricingModelID]
			if not pricingModels[pricingModelID] then
				frames.name:SetVisible(false)
				frames.weight:SetVisible(false)
			else
				frames.name:SetVisible(true)
				frames.weight:SetVisible(true)
				
				frames.name:ClearAll()
				frames.name:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, count * 40 + 50)
				frames.weight:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 200, count * 40 + 50)
				
				count = count + 1
				
				frames.weight:SetPoint("BOTTOMRIGHT", configFrame, "TOPRIGHT", -10, count * 40 + 50)
			end
		end
	end
	
	title:SetPoint("TOPCENTER", configFrame, "TOPCENTER", 0, 10)
	title:SetFontSize(14)
	title:SetText(L["PriceScorer/marketWeights"])
	
	ResetModelFrames()
	table.insert(Event[addonID].PricingModelAdded, { ResetModelFrames, addonID, "MarketPrice.PricingModelAdded" })
	
	return configFrame
end

_G[addonID].RegisterPriceScorer(PRICE_SCORER_ID, PRICE_SCORER_NAME, PricingModel, nil, PriceScorer, ConfigFrame)

