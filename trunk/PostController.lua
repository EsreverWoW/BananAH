-- ***************************************************************************************************************************************************
-- * PostController.lua                                                                                                                              *
-- ***************************************************************************************************************************************************
-- * Post tab controller                                                                                                                             *
-- ***************************************************************************************************************************************************
-- * 0.4.4 / 2013.02.07 / Baanano: Extracted model logic from PostFrame                                                                              *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local GetActiveAuctionsScored = InternalInterface.PGCExtensions.GetActiveAuctionsScored
local GetCategoryModels = InternalInterface.PGCConfig.GetCategoryModels
local GetPostingQueue = LibPGC.GetPostingQueue
local GetPostingSettings = InternalInterface.Helper.GetPostingSettings
local GetPriceModels = LibPGCEx.GetPriceModels
local GetPrices = LibPGCEx.GetPrices
local IIDetail = Inspect.Item.Detail
local IIList = Inspect.Item.List
local L = InternalInterface.Localization.L
local MCeil = math.ceil
local MFloor = math.floor
local MMax = math.max
local MMin = math.min
local PostItem = LibPGC.PostItem
local TInsert = table.insert
local UISInventory = Utility.Item.Slot.Inventory
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local type = type

local FIXED_MODEL_ID = "fixed"
local FIXED_MODEL_NAME = L["PriceModels/Fixed"]

local active = false
local itemList = {}
local showHiddenItems = false
local selectedItemType = nil
local lastLoadSeq = 0
local lastAuctions = {}

InternalInterface.Control = InternalInterface.Control or {}
InternalInterface.Control.PostController = InternalInterface.Control.PostController or {}

local function FireEvent(event, ...)
	if type(event) == "table" then
		for _, eventHandler in ipairs(event) do
			if type(eventHandler) == "function" then
				pcall(eventHandler, ...)
			end
		end
	end
end

local function RefreshItemList()
	local changed = false
	local newItemList = {}
	
	local items = IIList(UISInventory())
	for _, itemID in pairs(items) do repeat
		if type(itemID) ~= "string" then break end
		local ok, itemDetail = pcall(IIDetail, itemID)
		if not ok or not itemDetail or itemDetail.bound then break end
		
		local itemType = itemDetail.type
		newItemList[itemType] = newItemList[itemType] or
		{
			itemType = itemType,
			name = itemDetail.name,
			icon = itemDetail.icon,
			rarity = itemDetail.rarity or "common",
			stack = 0,
			adjustedStack = 0,
			stackMax = itemDetail.stackMax or 1,
			sell = itemDetail.sell,
			category = itemDetail.category,
			visibility = (InternalInterface.AccountSettings.Posting.HiddenItems[itemType] and "HideAll") or
			             (InternalInterface.CharacterSettings.Posting.HiddenItems[itemType] and "HideChar") or
						 "Show",
			auto = InternalInterface.CharacterSettings.Posting.AutoConfig[itemType],					 
		}
		newItemList[itemType].stack = newItemList[itemType].stack + (itemDetail.stack or 1)
		newItemList[itemType].adjustedStack = newItemList[itemType].stack
		
		changed = changed or not itemList[itemType]
	until true end
	
	local postingQueue = GetPostingQueue()
	for _, postOrder in ipairs(postingQueue) do
		local itemData = newItemList[postOrder.itemType] or nil
		if itemData then
			itemData.adjustedStack = itemData.adjustedStack - postOrder.amount
		end
	end
	
	if not changed then
		for itemType, itemData in pairs(newItemList) do
			if itemData.adjustedStack ~= itemList[itemType].adjustedStack then
				changed = true
				break
			end
		end
	end

	if not changed then
		for itemType in pairs(itemList) do
			if not newItemList[itemType] then
				changed = true
				break
			end
		end
	end
	
	if changed then
		local adjustedStackChanged = selectedItemType and itemList[selectedItemType] and newItemList[selectedItemType]
			                         and itemList[selectedItemType].adjustedStack ~= newItemList[selectedItemType].adjustedStack
		itemList = newItemList
		FireEvent(InternalInterface.Control.PostController.ItemListChanged, itemList)
		if adjustedStackChanged and selectedItemType then
			FireEvent(InternalInterface.Control.PostController.ItemAdjustedStackChanged, newItemList[selectedItemType].adjustedStack)
		end
	end
end

local function OnInventoryChange()
	if active then
		RefreshItemList()
	end
end
TInsert(Event.Item.Slot, { OnInventoryChange, addonID, addonID .. ".PostController.OnItemSlot" })
TInsert(Event.Item.Update, { OnInventoryChange, addonID, addonID .. ".PostController.OnItemUpdate" })
TInsert(Event.LibPGC.PostingQueueChanged, { OnInventoryChange, addonID, addonID .. ".PostController.OnPostingQueueChanged" })	

local function SetActive(value)
	value = value and true or false
	if active ~= value then
		active = value
		if active then
			RefreshItemList()
		end
	end
end

local function ReloadAuctions(itemType, itemInfo)
	local category = itemInfo.category
	local itemSettings = GetPostingSettings(itemType, category)

	local models = GetCategoryModels(category)
	local blackList = itemSettings.blackList or {}
	for modelID in pairs(blackList) do
		models[modelID] = nil
	end

	lastLoadSeq = lastLoadSeq + 1
	local loadSeq = lastLoadSeq
	
	GetPrices(function(prices)
		if lastLoadSeq == loadSeq then
			local priceModels = GetPriceModels()
			for priceID, priceData in pairs(prices) do
				local priceModelName = priceModels[priceID]
				if priceModelName then
					priceData.displayName = priceModelName
				else
					prices[priceID] = nil
				end
			end
	
			prices[FIXED_MODEL_ID] = { displayName = FIXED_MODEL_NAME, bid = itemSettings.lastBid or 0, buy = itemSettings.lastBuy or 0 }
		
			FireEvent(InternalInterface.Control.PostController.PricesChanged, prices)
		end
	end, itemType, itemSettings.bidPercentage, models, false)		

	lastAuctions = {}
	
	GetActiveAuctionsScored(function(auctions)
		if lastLoadSeq == loadSeq then
			lastAuctions = auctions
			FireEvent(InternalInterface.Control.PostController.AuctionsChanged, auctions)
		end
	end, itemType)
end

local function OnAuctionData(scanType, totalAuctions, newAuctions, updatedAuctions, removedAuctions, beforeExpireAuctions, totalItemTypes, newItemTypes, updatedItemTypes, removedItemTypes, modifiedItemTypes)
	if selectedItemType and totalItemTypes[selectedItemType] and itemList[selectedItemType] then
		ReloadAuctions(selectedItemType, itemList[selectedItemType])
	end
end
TInsert(Event.LibPGC.AuctionData, { OnAuctionData, addonID, addonID .. ".PostController.OnAuctionData" })

InternalInterface.Control.PostController.ItemListChanged = {}
InternalInterface.Control.PostController.ItemAdjustedStackChanged = {}
InternalInterface.Control.PostController.HiddenVisibilityChanged = {}
InternalInterface.Control.PostController.ItemVisibilityChanged = {}
InternalInterface.Control.PostController.ItemAutoChanged = {}
InternalInterface.Control.PostController.SelectedItemTypeChanged = {}
InternalInterface.Control.PostController.PricesChanged = {}
InternalInterface.Control.PostController.AuctionsChanged = {}

InternalInterface.Control.PostController.SetActive = SetActive

function InternalInterface.Control.PostController.GetItemList() return itemList end
InternalInterface.Control.PostController.RefreshItemList = RefreshItemList

function InternalInterface.Control.PostController.GetHiddenVisibility()
	return showHiddenItems
end

function InternalInterface.Control.PostController.SetHiddenVisibility(value)
	value = value and true or false
	if showHiddenItems ~= value then
		showHiddenItems = value
		FireEvent(InternalInterface.Control.PostController.HiddenVisibilityChanged, showHiddenItems)
	end
end

function InternalInterface.Control.PostController.ToggleItemVisibility(itemType, value)
	if itemType and itemList[itemType] and (value == "HideAll" or value == "HideChar") then
		itemList[itemType].visibility = itemList[itemType].visibility == "Show" and value or "Show"
		InternalInterface.AccountSettings.Posting.HiddenItems[itemType] = itemList[itemType].visibility == "HideAll" and true or nil
		InternalInterface.CharacterSettings.Posting.HiddenItems[itemType] = itemList[itemType].visibility == "HideChar" and true or nil
		FireEvent(InternalInterface.Control.PostController.ItemVisibilityChanged, itemType, itemList[itemType].visibility)
	end
end

function InternalInterface.Control.PostController.SetItemAuto(itemType, settings)
	if itemType and itemList[itemType] and settings then
		if type(settings.stackSize) == "number" and settings.stackSize <= 0 then
			return L["PostFrame/ErrorPostStackSize"]
		elseif type(settings.auctionLimit) == "number" and settings.auctionLimit <= 0 then
			return L["PostFrame/ErrorPostStackNumber"]
		elseif (settings.pricingModelOrder == FIXED_MODEL_ID and settings.lastBid <= 0) then
			return L["PostFrame/ErrorPostBidPrice"]
		elseif settings.lastBuy and settings.lastBuy ~= 0 and settings.lastBuy < settings.lastBid then
			return L["PostFrame/ErrorPostBuyPrice"]
		end
		InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] = settings
		InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] = true
		itemList[itemType].auto = true
		if itemType == selectedItemType then
			selectedItemType = nil
			InternalInterface.Control.PostController.SetSelectedItemType(itemType)
		end
		FireEvent(InternalInterface.Control.PostController.ItemAutoChanged, itemType, itemList[itemType].auto)		
	end
end

function InternalInterface.Control.PostController.ClearItemAuto(itemType)
	if itemType and itemList[itemType] then
		InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] = nil
		itemList[itemType].auto = nil
		FireEvent(InternalInterface.Control.PostController.ItemAutoChanged, itemType, itemList[itemType].auto)
	end
end

function InternalInterface.Control.PostController.GetSelectedItemType()
	return selectedItemType, selectedItemType and itemList[selectedItemType] or nil
end

function InternalInterface.Control.PostController.SetSelectedItemType(itemType)
	if selectedItemType ~= itemType and (itemType == nil or type(itemType) == "string") then
		selectedItemType = itemType and itemList[itemType] and itemType or nil
		local selectedItemInfo = selectedItemType and itemList[selectedItemType] or nil
		FireEvent(InternalInterface.Control.PostController.SelectedItemTypeChanged, selectedItemType, selectedItemInfo)

		if selectedItemType and selectedItemInfo then
			ReloadAuctions(selectedItemType, selectedItemInfo)
		else
			FireEvent(InternalInterface.Control.PostController.PricesChanged, nil)
			FireEvent(InternalInterface.Control.PostController.AuctionsChanged, nil)
		end
	end
end

function InternalInterface.Control.PostController.PostItem(settings)
	if selectedItemType and settings then
		local itemInfo = itemList[selectedItemType]
		
		local stackSize = settings.stackSize
		local auctionLimit = settings.auctionLimit
		local bidUnitPrice = settings.lastBid
		local buyUnitPrice = settings.lastBuy
		local duration = 6 * 2 ^ settings.duration
		
		stackSize = stackSize == "+" and itemInfo.stackMax or stackSize
		if type(stackSize) ~= "number" then stackSize = 0 end

		if stackSize > 0 and itemInfo.adjustedStack then
			local stacks = itemInfo.adjustedStack
			local Round = settings.postIncomplete and MCeil or MFloor
			
			if type(auctionLimit) == "number" then
				for _, auctionData in pairs(lastAuctions) do
					if auctionData.own then
						auctionLimit = auctionLimit - 1
					end
				end
				
				for _, postData in pairs(GetPostingQueue()) do
					if postData.itemType == selectedItemType then
						auctionLimit = auctionLimit - MCeil(postData.amount / postData.stackSize)
					end
				end
			
				auctionLimit = MMax(MMin(auctionLimit, Round(stacks / stackSize)), 0)
			else
				auctionLimit = stackSize > 0 and Round(stacks / stackSize) or 0
			end
		end

		buyUnitPrice = buyUnitPrice > 0 and buyUnitPrice or nil
		local amount = MMin(stackSize * auctionLimit, itemInfo.adjustedStack)

		if stackSize <= 0 then
			return L["PostFrame/ErrorPostStackSize"]
		elseif auctionLimit <= 0 or amount <= 0 then
			return L["PostFrame/ErrorPostStackNumber"]
		elseif bidUnitPrice <= 0 then
			return L["PostFrame/ErrorPostBidPrice"]
		elseif buyUnitPrice and buyUnitPrice < bidUnitPrice then
			return L["PostFrame/ErrorPostBuyPrice"]
		end
		
		local itemType = selectedItemType
		if PostItem(itemType, stackSize, amount, bidUnitPrice, buyUnitPrice, duration) then
			InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] = settings
			return true
		end
		
		return false
	end
end

function InternalInterface.Control.PostController.ResetPostingSettings()
	if selectedItemType then
		local itemType = selectedItemType
		InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] = nil
		InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] = nil
		itemList[itemType].auto = nil
		selectedItemType = nil
		InternalInterface.Control.PostController.SetSelectedItemType(itemType)
		FireEvent(InternalInterface.Control.PostController.ItemAutoChanged, itemType, itemList[itemType].auto)
	end
end
