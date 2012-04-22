local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

-- AH Posting Service
local postingQueue = {}
local paused = false
local waitingUpdate = false
local cronTask = nil
local cronRunning = false
local QueueChangedEvent = Utility.Event.Create(addonID, "PostingQueueChanged")
local QueueStatusChangedEvent = Utility.Event.Create(addonID, "PostingQueueStatusChanged")

local function PostingQueueCoroutine()
	repeat
		repeat
			if paused or waitingUpdate or #postingQueue <= 0 or not Inspect.Interaction("auction") or not Inspect.Queue.Status("global") then break end
			local postTable = postingQueue[1]
			local itemType = postTable.itemType

			if postTable.amount <= 0 then -- This post is finished
				table.remove(postingQueue, 1)
				QueueChangedEvent()
				QueueStatusChangedEvent()
				if #postingQueue <= 0 and cronRunning and cronTask then
					Library.LibCron.pause(cronTask)
					cronRunning = false
				end
				break
			end

			local searchStackSize = math.min(postTable.stackSize, postTable.amount)
			local lowerItems = {}
			local exactItems = {}
			local higherItems = {}

			local slot = Utility.Item.Slot.Inventory()
			local items = Inspect.Item.List(slot)
			for slotID, itemID in pairs(items) do repeat
				if type(itemID) == "boolean" then break end
				local itemDetail = Inspect.Item.Detail(itemID)
				if itemDetail.bound == true or itemDetail.type ~= itemType then break end
				
				local itemStack = itemDetail.stack or 1
				local itemInfo = { itemID = itemID, slotID = slotID }
				
				if itemStack < searchStackSize then
					table.insert(lowerItems, itemInfo)
				elseif itemStack == searchStackSize then
					table.insert(exactItems, itemInfo)
					-- It would be nice to break here but I don't like goto
				else
					table.insert(higherItems, itemInfo)
				end
			until true end

			if #exactItems > 0 then -- Found an exact match!
				local item = exactItems[1].itemID
				local tim = postTable.duration
				local bid = postTable.unitBidPrice * searchStackSize
				local buyout = nil
				if postTable.unitBuyoutPrice then 
					buyout = postTable.unitBuyoutPrice * searchStackSize 
				end

				local cost = Utility.Auction.Cost(item, tim, bid, buyout)
				local coinDetail = Inspect.Currency.Detail("coin")
				local money = coinDetail and coinDetail.stack or 0
				if money < cost then -- Not enough money to post, abort
					table.remove(postingQueue, 1)
					QueueChangedEvent()
					QueueStatusChangedEvent()
					if #postingQueue <= 0 and cronRunning and cronTask then
						Library.LibCron.pause(cronTask)
						cronRunning = false
					end
					break
				end

				Command.Auction.Post(item, tim, bid, buyout)
				postingQueue[1].amount = postingQueue[1].amount - searchStackSize
				waitingUpdate = true
				QueueStatusChangedEvent()
				if cronRunning and cronTask then
					Library.LibCron.pause(cronTask)
					cronRunning = false
				end
				break
			end

			if #lowerItems > 1 then -- Need to join two items
				local firstItemSlot = lowerItems[1].slotID
				local secondItemSlot = lowerItems[2].slotID
				Command.Item.Move(firstItemSlot, secondItemSlot)
				waitingUpdate = true
				QueueStatusChangedEvent()
				if cronRunning and cronTask then
					Library.LibCron.pause(cronTask)
					cronRunning = false
				end
				break
			end

			if #higherItems > 0 then -- Need to split an item
				local item = higherItems[1].itemID
				Command.Item.Split(item, searchStackSize)
				waitingUpdate = true
				QueueStatusChangedEvent()
				if cronRunning and cronTask then
					Library.LibCron.pause(cronTask)
					cronRunning = false
				end
				break
			end

			-- If execution reach this point, there aren't enough stacks of the item to post, abort
			table.remove(postingQueue, 1)
			QueueChangedEvent()
			QueueStatusChangedEvent()
			if #postingQueue <= 0 and cronRunning and cronTask then
				Library.LibCron.pause(cronTask)
				cronRunning = false
			end
		until true
		coroutine.yield()
	until false
end
local postingCoroutine = coroutine.create(PostingQueueCoroutine)
cronTask = Library.LibCron.new(addonID, 0, true, true, coroutine.resume, postingCoroutine)
if cronTask then Library.LibCron.pause(cronTask) end


local function PostItem(item, stackSize, amount, unitBidPrice, unitBuyoutPrice, duration)
	if not item or not amount or not stackSize or not unitBidPrice or not duration then return false end
	
	amount = math.floor(amount)
	stackSize = math.floor(stackSize)
	unitBidPrice = math.floor(unitBidPrice)
	if unitBuyoutPrice then unitBuyoutPrice = math.max(math.floor(unitBuyoutPrice), unitBidPrice) end
	duration = math.floor(duration)
	
	if amount <= 0 or stackSize <= 0 or unitBidPrice <= 0 or (duration ~= 12 and duration ~= 24 and duration ~= 48) then return false end
	local ok, itemDetail = pcall(Inspect.Item.Detail, item)
	if not ok or not itemDetail then return false end
	
	local postTable = 
	{ 
		itemType = itemDetail.type, 
		stackSize = stackSize, 
		amount = amount, 
		unitBidPrice = unitBidPrice, 
		unitBuyoutPrice = unitBuyoutPrice, 
		duration = duration,
	}
	table.insert(postingQueue, postTable)
	QueueChangedEvent()
	QueueStatusChangedEvent()
	if not cronRunning and not paused and #postingQueue > 0 and not waitingUpdate and Inspect.Interaction("auction") and Inspect.Queue.Status("global") and cronTask then
		Library.LibCron.resume(cronTask)
		cronRunning = true
	end	
	return true
end

local function CancelPostingByIndex(index)
	if index < 0 or index > #postingQueue then return end
	table.remove(postingQueue, index)
	QueueChangedEvent()
	QueueStatusChangedEvent()
	if #postingQueue <= 0 and cronRunning and cronTask then
		Library.LibCron.pause(cronTask)
		cronRunning = false
	end
end

local function GetPostingQueue()
	return postingQueue -- FIXME Return copy!
end

local function GetPostingQueueStatus()
	local status = 0 -- Busy
	if paused then status = 1 -- Paused
	elseif #postingQueue <= 0 then status = 2 -- Empty
	elseif not Inspect.Interaction("auction") then status = 3 -- Not at the AH
	elseif waitingUpdate or not Inspect.Queue.Status("global") then status = 4 -- Waiting
	end
	
	return status, #postingQueue
end

local function GetPostingQueuePaused()
	return paused
end

local function SetPostingQueuePaused(pause)
	if pause == paused then return end
	paused = pause

	if paused and cronRunning and cronTask then 
		Library.LibCron.pause(cronTask) 
		cronRunning = false 
	elseif not cronRunning and not paused and #postingQueue > 0 and not waitingUpdate and Inspect.Interaction("auction") and Inspect.Queue.Status("global") and cronTask then
		Library.LibCron.resume(cronTask)
		cronRunning = true
	end

	QueueStatusChangedEvent()
end

--
local function OnWaitingUnlock()
	if waitingUpdate then
		waitingUpdate = false
		QueueStatusChangedEvent()
		
		if not cronRunning and not paused and #postingQueue > 0 and Inspect.Interaction("auction") and Inspect.Queue.Status("global") and cronTask then
			Library.LibCron.resume(cronTask)
			cronRunning = true
		end
	end
end
table.insert(Event.Item.Slot, { OnWaitingUnlock, addonID, "AHPostingService.OnWaitingUnlockSlot" })
table.insert(Event.Item.Update, { OnWaitingUnlock, addonID, "AHPostingService.OnWaitingUnlockUpdate" })

local function OnInteractionChanged(interaction, state)
	if interaction == "auction" then
		QueueStatusChangedEvent() -- FIXME Check if it has really changed
		if not state and cronRunning and cronTask then 
			Library.LibCron.pause(cronTask) 
			cronRunning = false 
		elseif state and not cronRunning and not paused and #postingQueue > 0 and not waitingUpdate and Inspect.Queue.Status("global") and cronTask then
			Library.LibCron.resume(cronTask)
			cronRunning = true
		end		
	end
end
table.insert(Event.Interaction, { OnInteractionChanged, addonID, "AHPostingService.OnInteractionChanged" })

local function OnGlobalQueueChanged(queue)
	if queue == "global" then
		QueueStatusChangedEvent() -- FIXME Check if it has really changed
		if not Inspect.Queue.Status("global") and cronRunning and cronTask then 
			Library.LibCron.pause(cronTask) 
			cronRunning = false 
		elseif not cronRunning and not paused and #postingQueue > 0 and not waitingUpdate and Inspect.Interaction("auction") and Inspect.Queue.Status("global") and cronTask then
			Library.LibCron.resume(cronTask)
			cronRunning = true
		end		
	end
end
table.insert(Event.Queue.Status, { OnGlobalQueueChanged, addonID, "AHPostingService.OnGlobalQueueChanged" })

local function OnAddonLoaded(addonId)
	if addonId == addonID then 
		SetPostingQueuePaused(InternalInterface.AccountSettings.Posting.startPostingQueuePaused or false)
	end 
end
table.insert(Event.Addon.Load.End, { OnAddonLoaded, addonID, "AHPostingService.OnAddonLoaded" })

--
_G[addonID].PostItem = PostItem
_G[addonID].CancelPostingByIndex = CancelPostingByIndex
_G[addonID].GetPostingQueue = GetPostingQueue
_G[addonID].GetPostingQueueStatus = GetPostingQueueStatus
_G[addonID].GetPostingQueuePaused = GetPostingQueuePaused
_G[addonID].SetPostingQueuePaused = SetPostingQueuePaused
