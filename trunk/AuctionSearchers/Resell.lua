local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local AUCTION_FEE_REDUCTION = 0.95
local MEMOIZATION_REFRESH = 1800

local L = InternalInterface.Localization.L

local AUCTION_SEARCHER_ID = "resell"
local AUCTION_SEARCHER_NAME = "Resell" -- LOCALIZE
local ONLINE = false

local SEARCH_HEIGHT = 40

local searchFrame = nil
local extraFrame = nil
local configFrame = nil

local function DefaultConfig()
	InternalInterface.AccountSettings.AuctionSearchers[AUCTION_SEARCHER_ID] = InternalInterface.AccountSettings.PriceMatchers[AUCTION_SEARCHER_ID] or
	{
	}
end

local function AuctionSearcher(text)
	return 
	{ 
		useBid = searchFrame.bidCheck:GetChecked() or nil,
		useBuy = searchFrame.buyCheck:GetChecked() or nil,
		bidDuration = searchFrame.durationSlider:GetPosition(),
		maxScore = searchFrame.scoreSlider:GetPosition(),
		minProfit = math.max(searchFrame.profitPriceSelector:GetValue(), 1),
		name = text, 
	}
end

local nextMemoization = nil
local memoizedPrices = {}
local function AuctionFilter(activeAuctions, searchSettings)
	if not searchSettings.useBid and not searchSettings.useBuy then return {} end
	
	if not nextMemoization or nextMemoization < os.time() then
		memoizedPrices = {}
		nextMemoization = os.time() + MEMOIZATION_REFRESH
	end
	
	local maxTime = os.time() + (searchSettings.bidDuration or 48) * 3600
	for auctionID, auctionData in pairs(activeAuctions) do
		local preserve = false

		if not memoizedPrices[auctionData.itemType] then
			memoizedPrices[auctionData.itemType] = _G[addonID].GetPricings(auctionData.itemType)
		end
		
		if memoizedPrices[auctionData.itemType] then
			local minProfit = searchSettings.minProfit
			local maxScore = searchSettings.maxScore
			local bidScore = _G[addonID].ScorePrice(auctionData.itemType, auctionData.bidUnitPrice, memoizedPrices[auctionData.itemType])
			local buyScore = _G[addonID].ScorePrice(auctionData.itemType, auctionData.buyoutUnitPrice, memoizedPrices[auctionData.itemType])
			
			activeAuctions[auctionID].bidProfit = auctionData.bidPrice and bidScore and auctionData.bidPrice * 100 * AUCTION_FEE_REDUCTION / bidScore - auctionData.bidPrice or 0
			activeAuctions[auctionID].buyProfit = auctionData.buyoutPrice and buyScore and auctionData.buyoutPrice * 100 * AUCTION_FEE_REDUCTION / buyScore - auctionData.buyoutPrice or 0

			if searchSettings.useBid and bidScore and math.floor(bidScore) <= maxScore and auctionData.maxExpireTime <= maxTime and activeAuctions[auctionID].bidProfit >= minProfit then preserve = true end
			if searchSettings.useBuy and buyScore and math.floor(buyScore) <= maxScore and activeAuctions[auctionID].buyProfit >= minProfit then preserve = true end
		end
		
		if not preserve then
			activeAuctions[auctionID] = nil
		end
	end
	return activeAuctions
end

local function AuctionClear()
	if searchFrame then
		searchFrame.buyCheck:SetChecked(true)
		searchFrame.bidCheck:SetChecked(true)
		searchFrame.profitPriceSelector:SetValue(0)
		searchFrame.durationSlider:SetPosition(48)
	end
end

local function AuctionSnipe()
end

local function SearchFrame(parent)
	if searchFrame then return searchFrame, SEARCH_HEIGHT end

	searchFrame = UI.CreateFrame("Frame", parent:GetName() .. ".VendorSearcher", parent)
	local buyCheck = UI.CreateFrame("RiftCheckbox", searchFrame:GetName() .. ".BuyCheck", searchFrame)
	local bidCheck = UI.CreateFrame("RiftCheckbox", searchFrame:GetName() .. ".BidCheck", searchFrame)
	local buyText = UI.CreateFrame("Text", searchFrame:GetName() .. ".BuyText", searchFrame)
	local bidText = UI.CreateFrame("Text", searchFrame:GetName() .. ".BidText", searchFrame)
	local durationSlider = UI.CreateFrame("BSlider", searchFrame:GetName() .. ".MinLevelSlider", searchFrame)
	local durationText = UI.CreateFrame("Text", searchFrame:GetName() .. ".DurationText", searchFrame)
	local scoreText = UI.CreateFrame("Text", searchFrame:GetName() .. ".ScoreText", searchFrame) 
	local scoreSlider = UI.CreateFrame("BSlider", searchFrame:GetName() .. ".ScoreSlider", searchFrame)
	local profitText = UI.CreateFrame("Text", searchFrame:GetName() .. ".ProfitText", searchFrame) 
	local profitPriceSelector = UI.CreateFrame("BMoneySelector", searchFrame:GetName() .. ".ProfitPriceSelector", searchFrame)
	
	buyCheck:SetPoint("CENTERLEFT", searchFrame, 0, 0.5)
	buyCheck:SetChecked(true)
	searchFrame.buyCheck = buyCheck
	
	buyText:SetPoint("CENTERLEFT", buyCheck, "CENTERRIGHT", 5, 0)
	buyText:SetText("Search by buyout price") -- LOCALIZE
	
	bidCheck:SetPoint("CENTERLEFT", buyText, "CENTERRIGHT", 20, 0)
	bidCheck:SetChecked(true)
	searchFrame.bidCheck = bidCheck
	
	bidText:SetPoint("CENTERLEFT", bidCheck, "CENTERRIGHT", 5, 0)
	bidText:SetText("Search by bid price, expiring before") -- LOCALIZE
	
	scoreText:SetPoint("CENTERLEFT", searchFrame, 0.5, 0.5)
	scoreText:SetText("Max. score:") -- LOCALIZE
	
	durationText:SetPoint("CENTERRIGHT", scoreText, "CENTERLEFT", -20, 0)
	durationText:SetText("hours") -- LOCALIZE
	
	profitText:SetPoint("CENTERLEFT", searchFrame, 0.75, 0.5)
	profitText:SetText("Min. profit:") -- LOCALIZE
	
	scoreSlider:SetPoint("CENTERLEFT", scoreText, "CENTERRIGHT", 5, 8)
	scoreSlider:SetPoint("CENTERRIGHT", profitText, "CENTERLEFT", -5, 8)
	scoreSlider:SetRange(1, 100)
	scoreSlider:SetPosition(100)
	searchFrame.scoreSlider = scoreSlider	
	
	durationSlider:SetPoint("CENTERLEFT", bidText, "CENTERRIGHT", 5, 8)
	durationSlider:SetPoint("CENTERRIGHT", durationText, "CENTERLEFT", -5, 8)
	durationSlider:SetRange(1, 48)
	durationSlider:SetPosition(48)
	searchFrame.durationSlider = durationSlider	
	
	profitPriceSelector:SetPoint("CENTERLEFT", profitText, "CENTERRIGHT", 5, 0)
	profitPriceSelector:SetPoint("CENTERRIGHT", searchFrame, 1, 0.5)
	profitPriceSelector:SetHeight(34)
	searchFrame.profitPriceSelector = profitPriceSelector
	
	return searchFrame, SEARCH_HEIGHT
end

local function ExtraFrame()
end

local function ConfigFrame()
end


local function ResetMemoization(dataType, totalAuctions, newAuctions, updatedAuctions, removedAuctions, beforeExpireAuctions)
	local newTypes = _G[addonID].GetAuctionsItemTypes(newAuctions or {})
	for auctionID, itemType in pairs(newTypes) do memoizedPrices[itemType] = nil end
	local updatedTypes = _G[addonID].GetAuctionsItemTypes(updatedAuctions or {})
	for auctionID, itemType in pairs(updatedTypes) do memoizedPrices[itemType] = nil end
	local removedTypes = _G[addonID].GetAuctionsItemTypes(removedAuctions or {})
	for auctionID, itemType in pairs(removedTypes) do memoizedPrices[itemType] = nil end
end
table.insert(Event[addonID].AuctionData, { ResetMemoization, addonID, "AuctionSearcher" .. AUCTION_SEARCHER_ID .. ".OnAuctionData" })


_G[addonID].RegisterAuctionSearcher(AUCTION_SEARCHER_ID, AUCTION_SEARCHER_NAME, ONLINE, AuctionSearcher, AuctionFilter, AuctionClear, AuctionSnipe, SearchFrame, ExtraFrame, ConfigFrame)
