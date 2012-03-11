local _, InternalInterface = ...

local FixItemType = InternalInterface.Utility.FixItemType

-- Private
local function RepositionItemList(bItemSelector)
	bItemSelector.itemListFrame:SetPoint("TOPLEFT", bItemSelector.maskFrame, "TOPLEFT", 0, -bItemSelector.offset)
	bItemSelector.itemListFrame:SetPoint("TOPRIGHT", bItemSelector.maskFrame, "TOPRIGHT", 0, -bItemSelector.offset)
end

local function RepositionScrollbar(bItemSelector)
	if bItemSelector.maskFrame:GetHeight() < 0 then return end
	local maxOffset = math.max(0, bItemSelector.itemListFrame:GetHeight() - bItemSelector.maskFrame:GetHeight())
	if maxOffset <= 0 then
		bItemSelector.offset = 0
		bItemSelector.scrollBar:SetEnabled(false)
	else
		if bItemSelector.offset > maxOffset then
			bItemSelector.offset = maxOffset
		end
		bItemSelector.scrollBar:SetEnabled(true)
		bItemSelector.scrollBar:SetRange(0, maxOffset)
		bItemSelector.scrollBar:SetPosition(bItemSelector.offset)
		bItemSelector.scrollBar:SetThickness(bItemSelector.maskFrame:GetHeight() / bItemSelector.itemListFrame:GetHeight() * maxOffset)
	end
	RepositionItemList(bItemSelector)
end



local function SetSelectedDesign(itemFrame, selected)
	if selected then
		itemFrame:SetBackgroundColor(0.2, 0, 0.2, 1) 
	else
		itemFrame:SetBackgroundColor(0.1, 0, 0.1, 1) 
	end			
end

local function RepaintSelected(bItemSelector)
	bItemSelector.itemFrameList = bItemSelector.itemFrameList or {}
	for index, itemFrame in ipairs(bItemSelector.itemFrameList) do
		SetSelectedDesign(itemFrame, index == bItemSelector.selectedIndex)
	end
end

local function SelectItemFrameByIndex(bItemSelector, index)
	if index > 0 and index <= #bItemSelector.itemFrameList and bItemSelector.itemFrameList[index]:GetVisible() then
		bItemSelector.selectedIndex = index
	else
		bItemSelector.selectedIndex = 0
	end
	
	RepaintSelected(bItemSelector)
	
	if bItemSelector.Event.ItemSelected then
		if bItemSelector.selectedIndex > 0 then
			bItemSelector.Event.ItemSelected(bItemSelector, bItemSelector.itemFrameList[index].itemTable)
		else
			bItemSelector.Event.ItemSelected(bItemSelector, nil)
		end
	end			
end

local function SetItemFrame(bItemSelector, index, itemTable)
	bItemSelector.itemFrameList = bItemSelector.itemFrameList or {}
	local itemFrame = bItemSelector.itemFrameList[index]
	
	if not itemFrame then
		itemFrame = UI.CreateFrame("Frame", bItemSelector:GetName() .. ".ItemFrame." .. index, bItemSelector.itemListFrame)
		itemFrame:SetPoint("TOPLEFT", bItemSelector.itemListFrame, "TOPLEFT", 0, (index - 1) * 60)
		itemFrame:SetPoint("BOTTOMRIGHT", bItemSelector.itemListFrame, "TOPRIGHT", 0, index * 60)
		
		local itemFrameTexture = UI.CreateFrame("Texture", itemFrame:GetName() .. ".Texture", itemFrame)
		itemFrameTexture:SetPoint("CENTERLEFT", itemFrame, "CENTERLEFT", 5, 0)
		itemFrame.itemFrameTexture = itemFrameTexture
		
		local itemFrameNameLabel = UI.CreateFrame("Text", itemFrame:GetName() .. ".NameLabel", itemFrame)
		itemFrameNameLabel:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 60, 10)
		itemFrameNameLabel:SetWidth(itemFrame:GetWidth() - 65)
		itemFrame.itemFrameNameLabel = itemFrameNameLabel

		local itemFrameStackLabel = UI.CreateFrame("Text", itemFrame:GetName() .. ".StackLabel", itemFrame)
		itemFrameStackLabel:SetPoint("BOTTOMRIGHT", itemFrame, "BOTTOMRIGHT", -5, -5)
		itemFrame.itemFrameStackLabel = itemFrameStackLabel
		
		itemFrame.index = index
		
		function itemFrame.Event:LeftClick()
			if self.itemTable then
				local itemSelector = self:GetParent():GetParent():GetParent():GetParent():GetParent():GetParent() -- ItemFrame -> ItemListFrame -> MaskFrame -> InnerPanelContent -> InnerPanel -> ItemSelectorContent -> ItemSelector
				SelectItemFrameByIndex(itemSelector, self.index)
			end
		end
		
		table.insert(bItemSelector.itemFrameList, itemFrame)
	end
	
	itemFrame.itemTable = itemTable
	if itemFrame.itemTable then
		local icon = nil
		local name = nil
		local stack = 0
		for _, itemID in pairs(itemFrame.itemTable) do
			local itemDetail = Inspect.Item.Detail(itemID)
			icon = icon or itemDetail.icon
			name = name or itemDetail.name
			stack = stack + (itemDetail.stack or 1)
		end
		itemFrame.itemFrameTexture:SetTexture("Rift", icon)
		itemFrame.itemFrameNameLabel:SetText(name)
		itemFrame.itemFrameStackLabel:SetText("x" .. stack )
		itemFrame:SetVisible(true)
	else
		itemFrame:SetVisible(false)
	end
	return itemFrame
end

--Public
local function GetScrollInterval(self)
	self.scrollInterval = self.scrollInterval or 30
	return self.scrollInterval
end

local function SetScrollInterval(self, val)
	self.scrollInterval = math.max(0, val)
	return self.scrollInterval
end

local function GetSelectedItems(self)
	if not self.selectedIndex or not self.itemFrameList or self.selectedIndex <= 0 or self.selectedIndex > #self.itemFrameList then return end
	local itemFrame = self.itemFrameList[self.selectedIndex]
	return itemFrame.itemTable
end

local function GetAllItems(self)
	self.items = self.items or {}
	return self.items
end

local function SetItems(self, items)
	local fixedLookupTable = {}
	for _, itemID in pairs(items) do
		local itemDetail = Inspect.Item.Detail(itemID)
		local fixedItemType = FixItemType(itemDetail.type)
		fixedLookupTable[fixedItemType] = fixedLookupTable[fixedItemType] or {}
		table.insert(fixedLookupTable[fixedItemType], itemID)
	end
	
	local orderedItemTable = {}
	for fixedItemType, _ in pairs(fixedLookupTable) do
		table.insert(orderedItemTable, fixedItemType)
	end
	table.sort(orderedItemTable, function(a, b) return string.upper(Inspect.Item.Detail(fixedLookupTable[a][1]).name) < string.upper(Inspect.Item.Detail(fixedLookupTable[b][1]).name) end)
	
	local lastNameSelected = nil
	if self.itemFrameList and self.selectedIndex > 0 then
		lastNameSelected = self.itemFrameList[self.selectedIndex].itemFrameNameLabel:GetText()
	end
	
	local totalHeight = 0
	local newSelectedIndex = 0
	for index, fixedItemType in ipairs(orderedItemTable) do
		totalHeight = totalHeight + SetItemFrame(self, index, fixedLookupTable[fixedItemType]):GetHeight()
		if lastNameSelected and self.itemFrameList[index].itemFrameNameLabel:GetText() == lastNameSelected then
			newSelectedIndex = index
		end
	end
	self.itemListFrame:SetHeight(totalHeight)
	
	if self.itemFrameList then
		for index = #orderedItemTable + 1, #self.itemFrameList do
			SetItemFrame(self, index, nil)
		end
	end
	
	if newSelectedIndex <= 0 then
		newSelectedIndex = self.selectedIndex
	end
	
	if newSelectedIndex <= 0 and #orderedItemTable > 0 then
		newSelectedIndex = 1
	elseif newSelectedIndex > #orderedItemTable then
		newSelectedIndex = #orderedItemTable
	end
	SelectItemFrameByIndex(self, newSelectedIndex)	
	
	RepaintSelected(self)
	
	self.items = items
end

function InternalInterface.UI.ItemSelector(name, parent)
	local bItemSelector = UI.CreateFrame("BPanel", name, parent)
	function bItemSelector.Event:Size()
		RepositionScrollbar(self)
	end

	local scrollBar = UI.CreateFrame("RiftScrollbar", bItemSelector:GetName() .. ".ScrollBar", bItemSelector:GetContent())
	scrollBar:SetPoint("TOPLEFT", bItemSelector:GetContent(), "TOPRIGHT", -18, 2)
	scrollBar:SetPoint("BOTTOMRIGHT", bItemSelector:GetContent(), "BOTTOMRIGHT", -2, -30)
	function scrollBar.Event:ScrollbarChange()
		local itemSelector = self:GetParent():GetParent() -- Scrollbar -> ItemSelectorContent -> ItemSelector
		itemSelector.offset = self:GetPosition()
		RepositionItemList(itemSelector)
	end	
	bItemSelector.scrollBar = scrollBar
	
	local innerPanel = UI.CreateFrame("BPanel", bItemSelector:GetName() .. ".InnerPanel", bItemSelector:GetContent())
	innerPanel:SetPoint("TOPLEFT", bItemSelector:GetContent(), "TOPLEFT", 2, 2)
	innerPanel:SetPoint("BOTTOMRIGHT", bItemSelector:GetContent(), "BOTTOMRIGHT", -20, -30)
	innerPanel:SetInvertedBorder(true)
	bItemSelector.innerPanel = innerPanel

	local maskFrame = UI.CreateFrame("Mask", bItemSelector:GetName() .. ".MaskFrame", innerPanel:GetContent())
	maskFrame:SetAllPoints()
	maskFrame:SetBackgroundColor(0.1, 0, 0.1, 1) 
	function maskFrame.Event:WheelForward()
		local itemSelector = self:GetParent():GetParent():GetParent():GetParent() -- MaskFrame -> InnerPanelContent -> InnerPanel -> ItemSelectorContent -> ItemSelector
		local itemListFrame = itemSelector.itemListFrame
		if not itemListFrame or itemListFrame:GetHeight() <= self:GetHeight() then return end
		local minOffset, maxOffset = itemSelector.scrollBar:GetRange()
		itemSelector.offset = math.max(minOffset, itemSelector.offset - itemSelector:GetScrollInterval())
		RepositionScrollbar(itemSelector)
	end
	function maskFrame.Event:WheelBack()
		local itemSelector = self:GetParent():GetParent():GetParent():GetParent() -- MaskFrame -> InnerPanelContent -> InnerPanel -> ItemSelectorContent -> ItemSelector
		local itemListFrame = itemSelector.itemListFrame
		if not itemListFrame or itemListFrame:GetHeight() <= self:GetHeight() then return end
		local minOffset, maxOffset = itemSelector.scrollBar:GetRange()
		itemSelector.offset = math.min(maxOffset, itemSelector.offset + itemSelector:GetScrollInterval())
		RepositionScrollbar(itemSelector)
	end
	bItemSelector.maskFrame = maskFrame

	local itemListFrame = UI.CreateFrame("Frame", bItemSelector:GetName() .. ".ItemListFrame", maskFrame)
	itemListFrame:SetPoint("TOPLEFT", maskFrame, "TOPLEFT")
	itemListFrame:SetPoint("TOPRIGHT", maskFrame, "TOPRIGHT")
	itemListFrame:SetHeight(0)
	function itemListFrame.Event:Size()
		local itemSelector = self:GetParent():GetParent():GetParent():GetParent():GetParent() -- ItemListFrame -> MaskFrame -> InnerPanelContent -> InnerPanel -> ItemSelectorContent -> ItemSelector
		RepositionScrollbar(itemSelector)
	end
	bItemSelector.itemListFrame = itemListFrame

	-- Variables
	bItemSelector.offset = 0
	bItemSelector.selectedIndex = 0
	
	-- Public
	bItemSelector.GetScrollInterval = GetScrollInterval
	bItemSelector.SetScrollInterval = SetScrollInterval
	bItemSelector.GetAllItems = GetAllItems
	bItemSelector.GetSelectedItems = GetSelectedItems
	bItemSelector.SetItems = SetItems
	-- TODO SetSelectedItem
	
	Library.LibBInterface.BEventHandler(bItemSelector, { "ItemSelected" })
	
	RepositionScrollbar(bItemSelector)

	return bItemSelector
end