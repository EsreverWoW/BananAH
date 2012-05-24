local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local AUCTION_SEARCHER_ID = "vendor"
local AUCTION_SEARCHER_NAME = "Vendor" -- LOCALIZE
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
	return { name = text }
end

local memoizedPrices = {}
local function AuctionFilter(activeAuctions)
	if not searchFrame.bidCheck:GetChecked() and not searchFrame.buyCheck:GetChecked() then return {} end
	
	local maxTime = os.time() + searchFrame.durationSlider:GetPosition() * 3600
	for auctionID, auctionData in pairs(activeAuctions) do
		local preserve = false

		if not memoizedPrices[auctionData.itemType] then
			local ok, itemDetail = pcall(Inspect.Item.Detail, auctionData.itemType)
			memoizedPrices[auctionData.itemType] = ok and itemDetail and (itemDetail.sell or 0) or nil
		end
		
		if memoizedPrices[auctionData.itemType] then
			local totalSell = auctionData.stack * memoizedPrices[auctionData.itemType]
			local minProfit = math.max(searchFrame.profitPriceSelector:GetValue(), 1)
			
			activeAuctions[auctionID].bidProfit = totalSell - auctionData.bidPrice
			activeAuctions[auctionID].buyProfit = auctionData.buyoutPrice and totalSell - auctionData.buyoutPrice or 0
			
			if searchFrame.bidCheck:GetChecked() and auctionData.maxExpireTime <= maxTime and activeAuctions[auctionID].bidProfit >= minProfit then preserve = true end
			if searchFrame.buyCheck:GetChecked() and activeAuctions[auctionID].buyProfit >= minProfit then preserve = true end
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
	local profitText = UI.CreateFrame("Text", searchFrame:GetName() .. ".ProfitText", searchFrame) 
	local profitPriceSelector = UI.CreateFrame("BMoneySelector", searchFrame:GetName() .. ".ProfitPriceSelector", searchFrame)
	
	buyCheck:SetPoint("CENTERLEFT", searchFrame, 0, 0.5)
	buyCheck:SetChecked(true)
	searchFrame.buyCheck = buyCheck
	
	bidCheck:SetPoint("CENTERLEFT", searchFrame, 0.2, 0.5)
	bidCheck:SetChecked(true)
	searchFrame.bidCheck = bidCheck
	
	buyText:SetPoint("CENTERLEFT", buyCheck, "CENTERRIGHT", 5, 0)
	buyText:SetText("Search by buyout price") -- LOCALIZE
	
	bidText:SetPoint("CENTERLEFT", bidCheck, "CENTERRIGHT", 5, 0)
	bidText:SetText("Search by bid price, expiring before") -- LOCALIZE
	
	durationText:SetPoint("CENTERRIGHT", searchFrame, 0.7, 0.5)
	durationText:SetText("hours") -- LOCALIZE
	
	profitText:SetPoint("CENTERLEFT", searchFrame, 0.75, 0.5)
	profitText:SetText("Min. profit:") -- LOCALIZE
	
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

_G[addonID].RegisterAuctionSearcher(AUCTION_SEARCHER_ID, AUCTION_SEARCHER_NAME, ONLINE, AuctionSearcher, AuctionFilter, AuctionClear, AuctionSnipe, SearchFrame, ExtraFrame, ConfigFrame)
