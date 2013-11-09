-- ***************************************************************************************************************************************************
-- * QueueManager.lua                                                                                                                                *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.29 / Baanano: Updated for 0.4.1                                                                                                 *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local FIXED_MODEL_ID = "fixed"

local function QueueCellType(name, parent)
	local queueManagerCell = UI.CreateFrame("Mask", name, parent)
	
	local cellBackground = UI.CreateFrame("Texture", name .. ".CellBackground", queueManagerCell)
	local itemTextureBackground = UI.CreateFrame("Frame", name .. ".ItemTextureBackground", queueManagerCell)
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = Yague.ShadowedText(name .. ".ItemNameLabel", queueManagerCell)
	local itemStackLabel = UI.CreateFrame("Text", name .. ".ItemStackLabel", queueManagerCell)
	local bidMoneyDisplay = Yague.MoneyDisplay(name .. ".BidMoneyDisplay", queueManagerCell)
	local buyMoneyDisplay = Yague.MoneyDisplay(name .. ".BuyMoneyDisplay", queueManagerCell)

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
		local itemDetail = Inspect.Item.Detail(value.itemType)
		self:SetWidth(width)
		
		itemTextureBackground:SetBackgroundColor(InternalInterface.Utility.GetRarityColor(itemDetail.rarity))
		
		itemTexture:SetTexture("Rift", itemDetail.icon)
		itemType = value.itemType
		
		itemNameLabel:SetText(itemDetail.name)
		itemNameLabel:SetFontColor(InternalInterface.Utility.GetRarityColor(itemDetail.rarity))
		
		itemStackLabel:SetText("x" .. tostring(value.amount))
		
		bidMoneyDisplay:SetValue(value.amount * (value.unitBidPrice or 0))
		buyMoneyDisplay:SetValue(value.amount * (value.unitBuyoutPrice or 0))
	end
	
	function itemTexture.Event:MouseIn()
		pcall(Command.Tooltip, itemType)
	end
	
	function itemTexture.Event:MouseOut()
		Command.Tooltip(nil)
	end
	
	return queueManagerCell
end

function InternalInterface.UI.QueueManager(name, parent)
	local queueFrame = UI.CreateFrame("Frame", name, parent)

	local queuePanel = Yague.Panel(name .. ".QueueSizePanel", queueFrame)
	local queueSizeText = UI.CreateFrame("Text", queuePanel:GetName() .. ".QueueSizeText", queuePanel:GetContent())
	local clearButton = UI.CreateFrame("Texture", name .. ".ClearButton", queueFrame)
	local playButton = UI.CreateFrame("Texture", name .. ".PlayButton", queueFrame)
	local autoPostButton = UI.CreateFrame("Texture", name .. ".AutoPostButton", queueFrame)
	
	local queueGrid = Yague.DataGrid(name .. ".QueueGrid", parent)
		
	local function UpdateQueue()
		local queue = LibPGC.Queue.Detail()
		queueGrid:SetData(queue)

		local status, size = LibPGC.Queue.Status()

		playButton:SetTextureAsync(addonID, status == 2 and "Textures/Play.png" or "Textures/Pause.png")

		queueSizeText:SetText(tostring(size))
		
		if status == 2 then
			queueSizeText:SetFontColor(0, 0.75, 0.75, 1)
		elseif status == 3 then
			queueSizeText:SetFontColor(1, 0, 0, 1)
		elseif status == 4 then
			queueSizeText:SetFontColor(1, 0.5, 0, 1)
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

	playButton:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			LibPGC.Queue.Pause(LibPGC.Queue.Status() ~= 2)
		end, playButton:GetName() .. ".OnLeftClick")

	clearButton:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			if queueGrid:GetVisible() then
				local key = queueGrid:GetSelectedData()
				if key then
					LibPGC.Queue.CancelByIndex(key)
				end
			else
				LibPGC.Queue.CancelAll()
			end
		end, clearButton:GetName() .. ".OnLeftClick")
	
	queuePanel:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			queueGrid:SetVisible(not queueGrid:GetVisible())
		end, queuePanel:GetName() .. ".OnLeftClick")
	
	autoPostButton:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			blTasks.Task.Create(
				function(taskHandle)
					-- 1. Start fetching own auctions
					local auctionsTask = LibPGC.Search.Own()

					-- 2. Get inventory items
					local itemTypeTable = {}
					
					local slot = Utility.Item.Slot.Inventory()
					local items = Inspect.Item.List(slot)
					for _, itemID in pairs(items) do repeat
						if type(itemID) == "boolean" then break end 
						local ok, itemDetail = pcall(Inspect.Item.Detail, itemID)
						if not ok or not itemDetail or itemDetail.bound then break end
						
						local itemType = itemDetail.type
						if InternalInterface.CharacterSettings.Posting.AutoConfig[itemType] then
							itemTypeTable[itemType] = itemTypeTable[itemType] or
							{
								stack = 0,
								stackMax = itemDetail.stackMax or 1,
								category = itemDetail.category,
								stacksInAH = 0,
								stacksInQueue = 0,
							}
							itemTypeTable[itemType].stack = itemTypeTable[itemType].stack + (itemDetail.stack or 1)
						end
					until true end
					if not next(itemTypeTable) then return end
					
					-- 3. Substract queued stacks
					local queue = LibPGC.Queue.Detail()
					for i = 1, #queue do
						local post = queue[i]
						local itemType = post.itemType
						
						if itemType and itemTypeTable[itemType] then
							local newStack = itemTypeTable[itemType].stack - post.amount
							if newStack > 0 then
								itemTypeTable[itemType].stack = newStack
								itemTypeTable[itemType].stacksInQueue = itemTypeTable[itemType].stacksInQueue + 1
							else
								itemTypeTable[itemType] = nil
							end
						end
					end
					if not next(itemTypeTable) then return end
					
					taskHandle:Breath()
					
					-- 4. Get posting settings for each itemType
					for itemType, itemInfo in pairs(itemTypeTable) do
						itemInfo.settings = InternalInterface.Helper.GetPostingSettings(itemType, itemInfo.category)
					end					
					
					-- 5. Get own auctions
					local auctions = auctionsTask:Result()
					for _, auctionData in pairs(auctions) do
						local itemType = auctionData.itemType
						if itemTypeTable[itemType] then
							itemTypeTable[itemType].stacksInAH = itemTypeTable[itemType].stacksInAH + 1
						end
					end
					
					for itemType, itemInfo in pairs(itemTypeTable) do repeat
						-- 6. Convert stackSize to number
						itemInfo.settings.stackSize = itemInfo.settings.stackSize == "+" and itemInfo.stackMax or itemInfo.settings.stackSize
						if itemInfo.settings.stackSize <= 0 then
							itemTypeTable[itemType] = nil
							break
						end

						-- 7. Recalc limit
						local Round = itemInfo.settings.postIncomplete and math.ceil or math.floor
						
						if type(itemInfo.settings.auctionLimit) == "number" then
							itemInfo.settings.auctionLimit = math.max(math.min(itemInfo.settings.auctionLimit - itemInfo.stacksInAH - itemInfo.stacksInQueue, Round(itemInfo.stack / itemInfo.settings.stackSize)), 0)
						else
							itemInfo.settings.auctionLimit = Round(itemInfo.stack / itemInfo.settings.stackSize)
						end
						
						if itemInfo.settings.auctionLimit <= 0 then
							itemTypeTable[itemType] = nil
							break
						end				
					until true end
					if not next(itemTypeTable) then return end
					
					-- 8. Get item prices
					local priceTasks = {}
					for itemType, itemInfo in pairs(itemTypeTable) do
						local preferredPrice = itemInfo.settings.referencePrice
						if preferredPrice == FIXED_MODEL_ID then
							priceTasks[itemType] = blTasks.Task.Create(function() return { [FIXED_MODEL_ID] = { bid = itemInfo.settings.lastBid or 0, buy = itemInfo.settings.lastBuy or 0, } } end):Start():Suspend()
						else
							priceTasks[itemType] = LibPGCEx.Price.Calculate(itemType, preferredPrice, itemInfo.settings.bidPercentage, false):Suspend()
						end
					end
					
					-- 9. Apply posting settings
					for itemType, priceTask in pairs(priceTasks) do
						if not priceTask:Finished() then
							priceTask:Resume()
						end
						
						local ok, prices = pcall(priceTask.Result, priceTask)
						if ok then
							local itemInfo = itemTypeTable[itemType]
							
							prices = prices and prices[itemInfo.settings.referencePrice]
							if prices then
								itemInfo.bid = itemInfo.settings.matchPrices and prices.adjustedBid or prices.bid
								itemInfo.buy = itemInfo.settings.matchPrices and prices.adjustedBuy or prices.buy
								
								if itemInfo.settings.bindPrices then
									itemInfo.bid = math.max(itemInfo.bid or 0, itemInfo.buy or 0)
									itemInfo.buy = itemInfo.bid
								end
								
								if itemInfo.buy <= 0 then 
									itemInfo.buy = nil
								end
								
								if itemInfo.bid > 0 and (not itemInfo.buy or itemInfo.buy >= itemInfo.bid) then
									-- 10. Post the item
									if InternalInterface.AccountSettings.Posting.AutoPostPause then
										LibPGC.Queue.Pause(true)
									end
									
									if LibPGC.Queue.Post(itemType, itemInfo.settings.stackSize, math.min(itemInfo.stack, itemInfo.settings.stackSize * itemInfo.settings.auctionLimit), itemInfo.bid, itemInfo.buy, 6 * 2 ^ itemInfo.settings.duration) then
										InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] = InternalInterface.CharacterSettings.Posting.ItemConfig[itemType] or {}
										InternalInterface.CharacterSettings.Posting.ItemConfig[itemType].lastBid = itemInfo.bid or 0
										InternalInterface.CharacterSettings.Posting.ItemConfig[itemType].lastBuy = itemInfo.buy or 0
									end								
								end
							end
						end
					end
				end):Start():Abandon()
		end, autoPostButton:GetName() .. ".OnLeftClick")

	Command.Event.Attach(Event.LibPGC.Queue.Changed, UpdateQueue, addonID .. ".OnQueueChanged" )
	UpdateQueue()
	
	if InternalInterface.AccountSettings.General.QueuePausedOnStart then
		LibPGC.Queue.Pause(true)
	end
	
	return queueFrame
end
