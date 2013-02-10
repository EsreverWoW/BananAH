-- ***************************************************************************************************************************************************
-- * Main.lua                                                                                                                                        *
-- ***************************************************************************************************************************************************
-- * Creates the addon windows                                                                                                                       *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.29 / Baanano: Updated for 0.4.1                                                                                                 *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local FIXED_MODEL_ID = "fixed"

local CTooltip = Command.Tooltip
local CancelAll = LibPGC.CancelAll
local CancelPostingByIndex = LibPGC.CancelPostingByIndex
local DataGrid = Yague.DataGrid
local GetOwnAuctionData = LibPGC.GetOwnAuctionData
local GetPostingQueue = LibPGC.GetPostingQueue
local GetPostingQueuePaused = LibPGC.GetPostingQueuePaused
local GetPostingQueueStatus = LibPGC.GetPostingQueueStatus
local GetPostingSettings = InternalInterface.Helper.GetPostingSettings
local GetPrices = LibPGCEx.GetPrices
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local IIDetail = Inspect.Item.Detail
local IIList = Inspect.Item.List
local MCeil = math.ceil
local MFloor = math.floor
local MMax = math.max
local MMin = math.min
local MoneyDisplay = Yague.MoneyDisplay
local Panel = Yague.Panel
local PostItem = LibPGC.PostItem
local SFormat = string.format
local SetPostingQueuePaused = LibPGC.SetPostingQueuePaused
local ShadowedText = Yague.ShadowedText
local TInsert = table.insert
local UICreateFrame = UI.CreateFrame
local UISInventory = Utility.Item.Slot.Inventory
local next = next
local pairs = pairs
local pcall = pcall
local tostring = tostring
local type = type

local function QueueCellType(name, parent)
	local queueManagerCell = UICreateFrame("Mask", name, parent)
	
	local cellBackground = UICreateFrame("Texture", name .. ".CellBackground", queueManagerCell)
	local itemTextureBackground = UICreateFrame("Frame", name .. ".ItemTextureBackground", queueManagerCell)
	local itemTexture = UICreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = ShadowedText(name .. ".ItemNameLabel", queueManagerCell)
	local itemStackLabel = UICreateFrame("Text", name .. ".ItemStackLabel", queueManagerCell)
	local bidMoneyDisplay = MoneyDisplay(name .. ".BidMoneyDisplay", queueManagerCell)
	local buyMoneyDisplay = MoneyDisplay(name .. ".BuyMoneyDisplay", queueManagerCell)

	local itemType = nil
	
	cellBackground:SetAllPoints()
	cellBackground:SetTextureAsync(addonID, "Textures/ItemRowBackground.png")
	cellBackground:SetLayer(-9999)
	
	itemTextureBackground:SetPoint("CENTERLEFT", queueManagerCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	queueManagerCell.itemTexture = itemTexture
	
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("TOPLEFT", queueManagerCell, "TOPLEFT", 58, 0)
	
	itemStackLabel:SetPoint("BOTTOMLEFT", queueManagerCell, "BOTTOMLEFT", 58, 0)
	
	bidMoneyDisplay:SetPoint("TOPLEFT", queueManagerCell, "BOTTOMRIGHT", -120, -40)
	bidMoneyDisplay:SetPoint("BOTTOMRIGHT", queueManagerCell, "BOTTOMRIGHT", 0, -20)
	
	buyMoneyDisplay:SetPoint("TOPLEFT", queueManagerCell, "BOTTOMRIGHT", -120, -20)
	buyMoneyDisplay:SetPoint("BOTTOMRIGHT", queueManagerCell, "BOTTOMRIGHT", 0, 0)

	function queueManagerCell:SetValue(key, value, width, extra)
		local itemDetail = IIDetail(value.itemType)
		self:SetWidth(width)
		
		itemTextureBackground:SetBackgroundColor(GetRarityColor(itemDetail.rarity))
		
		itemTexture:SetTexture("Rift", itemDetail.icon)
		itemType = value.itemType
		
		itemNameLabel:SetText(itemDetail.name)
		itemNameLabel:SetFontColor(GetRarityColor(itemDetail.rarity))
		
		local fullStacks = MFloor(value.amount / value.stackSize)
		local oddStack = value.amount % value.stackSize
		local stack = ""
		if fullStacks > 0 and oddStack > 0 then
			stack = SFormat("%d x %d + %d", fullStacks, value.stackSize, oddStack)
		elseif fullStacks > 0 then
			stack = SFormat("%d x %d", fullStacks, value.stackSize)
		else
			stack = tostring(oddStack)
		end
		itemStackLabel:SetText(stack)
		
		bidMoneyDisplay:SetValue(value.amount * (value.unitBidPrice or 0))
		buyMoneyDisplay:SetValue(value.amount * (value.unitBuyoutPrice or 0))
	end
	
	function itemTexture.Event:MouseIn()
		pcall(CTooltip, itemType)
	end
	
	function itemTexture.Event:MouseOut()
		CTooltip(nil)
	end
	
	return queueManagerCell
end

function InternalInterface.UI.QueueManager(name, parent)
	local queueFrame = UICreateFrame("Frame", name, parent)

	local queuePanel = Panel(name .. ".QueueSizePanel", queueFrame)
	local queueSizeText = UICreateFrame("Text", queuePanel:GetName() .. ".QueueSizeText", queuePanel:GetContent())
	local clearButton = UICreateFrame("Texture", name .. ".ClearButton", queueFrame)
	local playButton = UICreateFrame("Texture", name .. ".PlayButton", queueFrame)
	local autoPostButton = UICreateFrame("Texture", name .. ".AutoPostButton", queueFrame)
	
	local queueGrid = DataGrid(name .. ".QueueGrid", parent)
		
	local function UpdateQueue()
		local queue = GetPostingQueue()
		queueGrid:SetData(queue)
	end
		
	local function UpdateQueueStatus()
		local status, size = GetPostingQueueStatus()

		playButton:SetTextureAsync(addonID, GetPostingQueuePaused() and "Textures/Play.png" or "Textures/Pause.png")

		queueSizeText:SetText(tostring(size))
		
		if status == 1 then
			queueSizeText:SetFontColor(0, 0.75, 0.75, 1)
		elseif status == 3 then
			queueSizeText:SetFontColor(1, 0.5, 0, 1)
		elseif status == 5 then
			queueSizeText:SetFontColor(1, 0, 0, 1)
		else
			queueSizeText:SetFontColor(1, 1, 1, 1)
		end
	end
	
	playButton:SetPoint("CENTERLEFT", queueFrame, "CENTERLEFT")
	playButton:SetTextureAsync(addonID, "Textures/Pause.png")

	clearButton:SetPoint("CENTERLEFT", queueFrame, "CENTERLEFT", 30, 0)
	clearButton:SetTextureAsync(addonID, "Textures/Stop.png")

	autoPostButton:SetPoint("CENTERRIGHT", queueFrame, "CENTERRIGHT", -5, 0)
	autoPostButton:SetTextureAsync(addonID, "Textures/AutoOn.png")
	autoPostButton:SetWidth(20)
	autoPostButton:SetHeight(20)
	
	queuePanel:SetPoint("CENTERLEFT", queueFrame, "CENTERLEFT", 60, 0)
	queuePanel:SetPoint("CENTERRIGHT", queueFrame, "CENTERRIGHT", -30, 0)
	queuePanel:SetHeight(30)
	queuePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
	
	queueSizeText:SetPoint("CENTER", queuePanel:GetContent(), "CENTER")
	
	queueGrid:SetPoint("BOTTOMLEFT", queueFrame, "TOPRIGHT", -290, 0)
	queueGrid:SetPoint("TOPRIGHT", queueFrame, "TOPRIGHT", 0, -400)
	queueGrid:SetLayer(9001)
	queueGrid:SetPadding(1, 1, 1, 1)
	queueGrid:SetHeadersVisible(false)
	queueGrid:SetRowHeight(62)
	queueGrid:SetRowMargin(2)
	queueGrid:SetUnselectedRowBackgroundColor({0.15, 0.2, 0.15, 1})
	queueGrid:SetSelectedRowBackgroundColor({0.45, 0.6, 0.45, 1})
	queueGrid:AddColumn("item", nil, QueueCellType, 248, 0, nil, "I DON'T CARE")
	queueGrid:SetVisible(false)
	queueGrid:GetInternalContent():SetBackgroundColor(0, 0, 0.05, 0.5)	

	function playButton.Event:LeftClick()
		SetPostingQueuePaused(not GetPostingQueuePaused())
	end	

	function clearButton.Event:LeftClick()
		if queueGrid:GetVisible() then
			local key = queueGrid:GetSelectedData()
			if key then
				CancelPostingByIndex(key)
			end
		else
			CancelAll()
		end
	end
	
	function queuePanel.Event:LeftClick()
		queueGrid:SetVisible(not queueGrid:GetVisible())
	end
	queuePanel.Event.RightClick = queuePanel.Event.LeftClick
	
	function autoPostButton.Event:LeftClick()
		-- 1.- Get Items
		local slot = UISInventory()
		local items = IIList(slot)
		local itemTypeTable = {}
		for _, itemID in pairs(items) do repeat
			if type(itemID) == "boolean" then break end 
			local ok, itemDetail = pcall(IIDetail, itemID)
			if not ok or not itemDetail or itemDetail.bound then break end
			
			local itemType = itemDetail.type
			if InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] then
				itemTypeTable[itemType] = itemTypeTable[itemType] or { stack = 0, stackMax = itemDetail.stackMax or 1, category = itemDetail.category, stacksInAH = 0, stacksInQueue = 0, }
				itemTypeTable[itemType].stack = itemTypeTable[itemType].stack + (itemDetail.stack or 1)
			end
		until true end
		
		-- 2.- Substract queued stacks
		local queue = GetPostingQueue()
		for _, post in ipairs(queue) do
			local itemType = post.itemType
			if itemType and itemTypeTable[itemType] then
				local newStack = itemTypeTable[itemType].stack - post.amount
				if newStack > 0 then
					itemTypeTable[itemType].stack = newStack
					itemTypeTable[itemType].stacksInQueue = itemTypeTable[itemType].stacksInQueue + MCeil(post.amount / post.stackSize)
				else
					itemTypeTable[itemType] = nil
				end
			end
		end
		if not next(itemTypeTable) then return end
		
		-- 3.- Get posting settings for each itemType
		for itemType, itemInfo in pairs(itemTypeTable) do
			itemInfo.settings = GetPostingSettings(itemType, itemInfo.category)
		end
		
		-- 4.- Get own auctions
		local function ProcessOwnAuctions(auctions)
			auctions = auctions or {}
			for _, auctionData in pairs(auctions) do
				local itemType = auctionData.itemType
				if itemTypeTable[itemType] then
					itemTypeTable[itemType].stacksInAH = itemTypeTable[itemType].stacksInAH + 1
				end
			end
			
			for itemType, itemInfo in pairs(itemTypeTable) do repeat
				-- 5.- Convert stackSize to number
				itemInfo.settings.stackSize = itemInfo.settings.stackSize == "+" and itemInfo.stackMax or itemInfo.settings.stackSize
				if itemInfo.settings.stackSize <= 0 then
					itemTypeTable[itemType] = nil
					break
				end

				-- 6.- Recalc limit
				local Round = itemInfo.settings.postIncomplete and MCeil or MFloor
				if type(itemInfo.settings.auctionLimit) == "number" then
					itemInfo.settings.auctionLimit = MMax(MMin(itemInfo.settings.auctionLimit - itemInfo.stacksInAH - itemInfo.stacksInQueue, Round(itemInfo.stack / itemInfo.settings.stackSize)), 0)
				else
					itemInfo.settings.auctionLimit = Round(itemInfo.stack / itemInfo.settings.stackSize)
				end
				if itemInfo.settings.auctionLimit <= 0 then
					itemTypeTable[itemType] = nil
					break
				end				
			until true end
			
			if not next(itemTypeTable) then return end
			
			-- 8.- Get item prices
			local function ProcessItemPrice(itemType, prices)
				local itemInfo = itemTypeTable[itemType]
				prices = prices and prices[itemInfo.settings.referencePrice]
				if not prices then return end
				
				itemInfo.bid = itemInfo.settings.matchPrices and prices.adjustedBid or prices.bid
				itemInfo.buy = itemInfo.settings.matchPrices and prices.adjustedBuy or prices.buy
				
				if itemInfo.settings.bindPrices then
					itemInfo.bid = MMax(itemInfo.bid or 0, itemInfo.buy or 0)
					itemInfo.buy = itemInfo.bid
				end

				if itemInfo.buy <= 0 then 
					itemInfo.buy = nil
				end
				
				if itemInfo.bid <= 0 then return end
				if itemInfo.buy and itemInfo.buy < itemInfo.bid then return end
				
				-- 9.- Post the item
				if InternalInterface.AccountSettings.Posting.AutoPostPause then
					SetPostingQueuePaused(true)
				end
				
				if PostItem(itemType, itemInfo.settings.stackSize, MMin(itemInfo.stack, itemInfo.settings.stackSize * itemInfo.settings.auctionLimit), itemInfo.bid, itemInfo.buy, 6 * 2 ^ itemInfo.settings.duration) then
					InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] = InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] or {}
					InternalInterface.CharacterSettings.Posting.ItemConfig[itemType].lastBid = itemInfo.bid or 0
					InternalInterface.CharacterSettings.Posting.ItemConfig[itemType].lastBuy = itemInfo.buy or 0
				end
			end
			
			for itemType, itemInfo in pairs(itemTypeTable) do
				local preferredPrice = itemInfo.settings.referencePrice
				if preferredPrice == FIXED_MODEL_ID then
					ProcessItemPrice(itemType, { [FIXED_MODEL_ID] = { bid = itemInfo.settings.lastBid or 0, buy = itemInfo.settings.lastBuy or 0, } })
				else
					GetPrices(function(prices) ProcessItemPrice(itemType, prices) end, itemType, itemInfo.settings.bidPercentage, preferredPrice, false)
				end
			end
		end
		GetOwnAuctionData(ProcessOwnAuctions)
	end

	TInsert(Event.LibPGC.PostingQueueStatusChanged, { UpdateQueueStatus, addonID, addonID .. ".OnQueueStatusChanged" })
	UpdateQueueStatus()
	
	TInsert(Event.LibPGC.PostingQueueChanged, { UpdateQueue, addonID, addonID .. ".OnQueueChanged" })
	UpdateQueue()
	
	if InternalInterface.AccountSettings.General.QueuePausedOnStart then
		SetPostingQueuePaused(true)
	end
	
	return queueFrame
end
