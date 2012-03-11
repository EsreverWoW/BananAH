local _, InternalInterface = ...

local FixItemType = InternalInterface.Utility.FixItemType

-- AH Posting Service
local postingQueue = {}
local waitingUpdate = false

local function PostingQueueCoroutine()
	repeat
		repeat
			if waitingUpdate or #postingQueue <= 0 or not Inspect.Interaction("auction") or not Inspect.Queue.Status("global") then break end
			local postTable = postingQueue[1]
			local itemType = postTable.itemType

			if postTable.amount <= 0 then -- This post is finished
				table.remove(postingQueue, 1)
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
				if itemDetail.bound == true or FixItemType(itemDetail.type) ~= itemType then break end
				
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
					break
				end

				Command.Auction.Post(item, tim, bid, buyout)
				postingQueue[1].amount = postingQueue[1].amount - searchStackSize
				waitingUpdate = true
				break
			end

			if #higherItems > 0 then -- Need to split an item
				local item = higherItems[1].itemID
				Command.Item.Split(item, searchStackSize)
				waitingUpdate = true
				break
			end

			if #lowerItems > 1 then -- Need to join two items
				local firstItemSlot = lowerItems[1].slotID
				local secondItemSlot = lowerItems[2].slotID
				Command.Item.Move(firstItemSlot, secondItemSlot)
				waitingUpdate = true
				break
			end

			-- If execution reach this point, there aren't enough stacks of the item to post, abort
			table.remove(postingQueue, 1)
		until true
		coroutine.yield()
	until false
end

local function PostItem(item, stackSize, amount, unitBidPrice, unitBuyoutPrice, duration)
	if not item or not amount or not stackSize or not unitBidPrice or not duration then return false end
	
	amount = math.floor(amount)
	stackSize = math.floor(stackSize)
	unitBidPrice = math.floor(unitBidPrice)
	if unitBuyoutPrice then unitBuyoutPrice = math.max(math.floor(unitBuyoutPrice), unitBidPrice) end
	duration = math.floor(duration)
	
	if amount <= 0 or stackSize <= 0 or unitBidPrice <= 0 or (duration ~= 12 and duration ~= 24 and duration ~= 48) then return false end
	local ok, itemDetail = pcall(Inspect.Item.Detail, item)
	if not ok then return false end
	
	local itemType = FixItemType(itemDetail.type)
	local postTable = { itemType = itemType, stackSize = stackSize, amount = amount, unitBidPrice = unitBidPrice, unitBuyoutPrice = unitBuyoutPrice, duration = duration }
	table.insert(postingQueue, postTable)
	return true
end

local postingCoroutine = coroutine.create(PostingQueueCoroutine)

local function OnUpdateBegin()
	coroutine.resume(postingCoroutine)
end
table.insert(Event.System.Update.Begin, { OnUpdateBegin, "BananAH", "OnUpdateBegin" })

local function OnWaitingUnlock()
	waitingUpdate = false
end
table.insert(Event.Item.Slot, { OnWaitingUnlock, "BananAH", "OnWaitingUnlockSlot" })
table.insert(Event.Item.Update, { OnWaitingUnlock, "BananAH", "OnWaitingUnlockUpdate" })

_G.BananAH.PostItem = PostItem
