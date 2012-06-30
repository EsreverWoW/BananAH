-- ***************************************************************************************************************************************************
-- * Services/PostQueue.lua                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * Posts auctions, splitting stacks if needed                                                                                                      *
-- ***************************************************************************************************************************************************
-- * 0.4.0  / 2012.06.17 / Baanano: Rewritten AHPostingService.lua                                                                                   *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local CAPost = Command.Auction.Post
local CIMove = Command.Item.Move
local CISplit = Command.Item.Split
local IInteraction = Inspect.Interaction
local ICDetail = Inspect.Currency.Detail
local IIDetail = Inspect.Item.Detail
local IIList = Inspect.Item.List
local IQStatus = Inspect.Queue.Status
local MFloor = math.floor
local MMax = math.max
local MMin = math.min
local OTime = os.time
local TInsert = table.insert
local TRemove = table.remove
local UECreate = Utility.Event.Create
local UACost = Utility.Auction.Cost
local UISInventory = Utility.Item.Slot.Inventory

local CronNew = Library.LibCron.new
local CronPause = Library.LibCron.pause
local CronResume = Library.LibCron.resume
local AuctionPostCallback = InternalInterface.Scanner.AuctionPostCallback
local CopyTableRecursive = InternalInterface.Utility.CopyTableRecursive

local postingQueue = {}
local paused = false
local waitingUpdate = false
local cronTask = nil
local cronRunning = false
local QueueChangedEvent = UECreate(addonID, "PostingQueueChanged")
local QueueStatusChangedEvent = UECreate(addonID, "PostingQueueStatusChanged")

local function PostingQueueCoroutine()
	repeat
		repeat
			if paused or waitingUpdate or #postingQueue <= 0 or not IInteraction("auction") or not IQStatus("global") then break end

			local postTable = postingQueue[1]
			local itemType = postTable.itemType

			if postTable.amount <= 0 then -- This post is finished
				TRemove(postingQueue, 1)
				QueueChangedEvent()
				QueueStatusChangedEvent()
				if #postingQueue <= 0 and cronRunning and cronTask then
					CronPause(cronTask)
					cronRunning = false
				end
				break
			end

			local searchStackSize = MMin(postTable.stackSize, postTable.amount)
			
			local lowerItems = {}
			local exactItems = {}
			local higherItems = {}

			local slot = UISInventory()
			local items = IIList(slot)
			for slotID, itemID in pairs(items) do repeat
				if type(itemID) == "boolean" then break end
				local itemDetail = IIDetail(itemID)
				if itemDetail.bound == true or itemDetail.type ~= itemType then break end
				
				local itemStack = itemDetail.stack or 1
				local itemInfo = { itemID = itemID, slotID = slotID }
				
				if itemStack < searchStackSize then
					TInsert(lowerItems, itemInfo)
				elseif itemStack == searchStackSize then
					TInsert(exactItems, itemInfo)
				else
					TInsert(higherItems, itemInfo)
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

				local cost = UACost(item, tim, bid, buyout)
				local coinDetail = ICDetail("coin")
				local money = coinDetail and coinDetail.stack or 0
				if money < cost then -- Not enough money to post, abort
					TRemove(postingQueue, 1)
					QueueChangedEvent()
					QueueStatusChangedEvent()
					if #postingQueue <= 0 and cronRunning and cronTask then
						CronPause(cronTask)
						cronRunning = false
					end
					break
				end

				local postTime = OTime()
				CAPost(item, tim, bid, buyout, function(...) AuctionPostCallback(itemType, tim, postTime, bid, buyout, ...) end)
				postingQueue[1].amount = postingQueue[1].amount - searchStackSize
				waitingUpdate = true
				QueueStatusChangedEvent()
				if cronRunning and cronTask then
					CronPause(cronTask)
					cronRunning = false
				end
				break
			end

			if #lowerItems > 1 then -- Need to join two items
				local firstItemSlot = lowerItems[1].slotID
				local secondItemSlot = lowerItems[2].slotID
				CIMove(firstItemSlot, secondItemSlot)
				waitingUpdate = true
				QueueStatusChangedEvent()
				if cronRunning and cronTask then
					CronPause(cronTask)
					cronRunning = false
				end
				break
			end

			if #higherItems > 0 then -- Need to split an item
				local item = higherItems[1].itemID
				CISplit(item, searchStackSize)
				waitingUpdate = true
				QueueStatusChangedEvent()
				if cronRunning and cronTask then
					CronPause(cronTask)
					cronRunning = false
				end
				break
			end

			-- If execution reach this point, there aren't enough stacks of the item to post, abort
			TRemove(postingQueue, 1)
			QueueChangedEvent()
			QueueStatusChangedEvent()
			if #postingQueue <= 0 and cronRunning and cronTask then
				CronPause(cronTask)
				cronRunning = false
			end
		until true
		coroutine.yield()
	until false
end
local postingCoroutine = coroutine.create(PostingQueueCoroutine)
cronTask = CronNew(addonID, 0, true, true, coroutine.resume, postingCoroutine)
if cronTask then CronPause(cronTask) end

local function OnWaitingUnlock()
	if waitingUpdate then
		waitingUpdate = false
		QueueStatusChangedEvent()
		
		if not cronRunning and not paused and #postingQueue > 0 and Inspect.Interaction("auction") and Inspect.Queue.Status("global") and cronTask then
			CronResume(cronTask)
			cronRunning = true
		end
	end
end
TInsert(Event.Item.Slot, { OnWaitingUnlock, addonID, "PostQueue.OnWaitingUnlockSlot" })
TInsert(Event.Item.Update, { OnWaitingUnlock, addonID, "PostQueue.OnWaitingUnlockUpdate" })

local function OnInteractionChanged(interaction, state)
	if interaction == "auction" then
		QueueStatusChangedEvent()
		if not state and cronRunning and cronTask then 
			CronPause(cronTask) 
			cronRunning = false 
		elseif state and not cronRunning and not paused and #postingQueue > 0 and not waitingUpdate and IQStatus("global") and cronTask then
			CronResume(cronTask)
			cronRunning = true
		end		
	end
end
TInsert(Event.Interaction, { OnInteractionChanged, addonID, "PostQueue.OnInteractionChanged" })

local function OnGlobalQueueChanged(queue)
	if queue == "global" then
		QueueStatusChangedEvent()
		if not IQStatus("global") and cronRunning and cronTask then 
			CronPause(cronTask) 
			cronRunning = false 
		elseif not cronRunning and not paused and #postingQueue > 0 and not waitingUpdate and IInteraction("auction") and IQStatus("global") and cronTask then
			CronResume(cronTask)
			cronRunning = true
		end		
	end
end
TInsert(Event.Queue.Status, { OnGlobalQueueChanged, addonID, "PostQueue.OnGlobalQueueChanged" })

local function OnAddonLoaded(addonId)
	if addonId == addonID then 
		PublicInterface.SetPostingQueuePaused(InternalInterface.AccountSettings.Posting.startPostingQueuePaused or false)
	end 
end
TInsert(Event.Addon.Load.End, { OnAddonLoaded, addonID, "PostQueue.OnAddonLoaded" })



function PublicInterface.PostItem(item, stackSize, amount, unitBidPrice, unitBuyoutPrice, duration)
	if not item or not amount or not stackSize or not unitBidPrice or not duration then return false end
	
	amount, stackSize, unitBidPrice, duration = MFloor(amount), MFloor(stackSize), MFloor(unitBidPrice), MFloor(duration)
	if unitBuyoutPrice then unitBuyoutPrice = MMax(MFloor(unitBuyoutPrice), unitBidPrice) end
	if amount <= 0 or stackSize <= 0 or unitBidPrice <= 0 or (duration ~= 12 and duration ~= 24 and duration ~= 48) then return false end

	local ok, itemDetail = pcall(IIDetail, item)
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
	TInsert(postingQueue, postTable)
	
	QueueChangedEvent()
	QueueStatusChangedEvent()
	if not cronRunning and not paused and #postingQueue > 0 and not waitingUpdate and IInteraction("auction") and IQStatus("global") and cronTask then
		CronResume(cronTask)
		cronRunning = true
	end	
	return true
end

function PublicInterface.CancelPostingByIndex(index)
	if index < 0 or index > #postingQueue then return end
	TRemove(postingQueue, index)
	QueueChangedEvent()
	QueueStatusChangedEvent()
	if #postingQueue <= 0 and cronRunning and cronTask then
		CronPause(cronTask)
		cronRunning = false
	end
end

function PublicInterface.GetPostingQueue()
	return CopyTableRecursive(postingQueue)
end

function PublicInterface.GetPostingQueueStatus()
	local status = 0 -- Busy
	if paused then status = 1 -- Paused
	elseif #postingQueue <= 0 then status = 2 -- Empty
	elseif not IInteraction("auction") then status = 3 -- Not at the AH
	elseif waitingUpdate or not IQStatus("global") then status = 4 -- Waiting
	end
	
	return status, #postingQueue
end

function PublicInterface.GetPostingQueuePaused()
	return paused
end

function PublicInterface.SetPostingQueuePaused(pause)
	if pause == paused then return end
	paused = pause

	if paused and cronRunning and cronTask then 
		CronPause(cronTask) 
		cronRunning = false 
	elseif not cronRunning and not paused and #postingQueue > 0 and not waitingUpdate and IInteraction("auction") and IQStatus("global") and cronTask then
		CronResume(cronTask)
		cronRunning = true
	end

	QueueStatusChangedEvent()
end
