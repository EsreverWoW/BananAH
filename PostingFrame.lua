local _, InternalInterface = ...

function InternalInterface.UI.PostingFrame(name, parent)
	local postingFrame = UI.CreateFrame("Frame", name, parent)
	local itemSelector = InternalInterface.UI.ItemSelector(name .. ".ItemSelector", postingFrame)
	local auctionSelector = InternalInterface.UI.AuctionSelector(name .. ".AuctionSelector", postingFrame)
	local postSelector = InternalInterface.UI.PostSelector(name .. ".PostSelector", postingFrame)
	local queueManager = InternalInterface.UI.QueueManager(name .. ".QueueManager", postingFrame)
	
	itemSelector:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 5, 5)
	itemSelector:SetPoint("BOTTOMRIGHT", postingFrame, "BOTTOMLEFT", 295, -5)
	postingFrame.itemSelector = itemSelector
	
	postSelector:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 300, 5)
	postSelector:SetPoint("BOTTOMRIGHT", postingFrame, "TOPRIGHT", -5, 330)
	postSelector.itemSelector = itemSelector
	postingFrame.postSelector = postSelector

	auctionSelector:SetPoint("TOPLEFT", postingFrame, "TOPLEFT", 300, 335)
	auctionSelector:SetPoint("BOTTOMRIGHT", postingFrame, "BOTTOMRIGHT", -5, -5)
	auctionSelector.postSelector = postSelector
	postingFrame.auctionSelector = auctionSelector
	
	queueManager:SetPoint("TOPLEFT", postingFrame, "TOPRIGHT", -293, 5)
	queueManager:SetPoint("BOTTOMRIGHT", postingFrame, "TOPRIGHT", -5, 74)
	queueManager:SetLayer(postSelector:GetLayer() + 1)
	postingFrame.queueManager = queueManager

	function itemSelector.Event:ItemSelected(item, itemInfo)
		postSelector:SetItem(item, itemInfo)
		auctionSelector:SetItem(item)
	end
	
	function postingFrame:Show()
		itemSelector:ResetItems()
	end
	
	return postingFrame
end