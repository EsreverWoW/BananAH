local _, InternalInterface = ...

local FixItemType = InternalInterface.Utility.FixItemType
local GetRarityColor = InternalInterface.Utility.GetRarityColor

-- Custom renderers
local function ItemSelectorRenderer(name, parent)
	local itemSelectorCell = UI.CreateFrame("Texture", name, parent)
	itemSelectorCell:SetTexture("BananAH", "Textures/ItemRowBackground.png")
	
	local itemTextureBackground = UI.CreateFrame("Frame", name .. ".ItemTextureBackground", itemSelectorCell)
	itemTextureBackground:SetPoint("CENTERLEFT", itemSelectorCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	itemSelectorCell.itemTextureBackground = itemTextureBackground
	
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	itemSelectorCell.itemTexture = itemTexture
	
	local itemNameLabel = UI.CreateFrame("BShadowedText", name .. ".ItemNameLabel", itemSelectorCell)
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("TOPLEFT", itemSelectorCell, "TOPLEFT", 58, 8)
	itemSelectorCell.itemNameLabel = itemNameLabel	
	
	local itemStackLabel = UI.CreateFrame("Text", name .. ".ItemStackLabel", itemSelectorCell)
	itemStackLabel:SetPoint("BOTTOMRIGHT", itemSelectorCell, "BOTTOMRIGHT", -4, -4)
	itemSelectorCell.itemStackLabel = itemStackLabel	
	
	function itemSelectorCell:SetValue(key, value, width, extra)
		self:SetWidth(width)
		self.itemTextureBackground:SetBackgroundColor(GetRarityColor(value.rarity))
		self.itemTexture:SetTexture("Rift", value.icon)
		self.itemNameLabel:SetText(value.name)
		self.itemStackLabel:SetText("x" .. value.stack)
		self.itemNameLabel:SetFontColor(GetRarityColor(value.rarity))
	end
	
	return itemSelectorCell
end
Library.LibBInterface.RegisterGridRenderer("ItemSelectorRenderer", ItemSelectorRenderer)

-- Private
local function OrderItemsClosure(self)
	return function(a, b)
		local items = self:GetData()
		return string.upper(items[a].name) < string.upper(items[b].name)
	end
end

-- Public
local function ResetItems(self)
	local slot = Utility.Item.Slot.Inventory()
	local items = Inspect.Item.List(slot)
	
	local itemTypeTable = {}
	for _, itemID in pairs(items) do repeat
		if type(itemID) == "boolean" then break end 
		local ok, itemDetail = pcall(Inspect.Item.Detail, itemID)
		if not ok or itemDetail.bound then break end
		
		local fixedItemType = FixItemType(itemDetail.type)
		itemTypeTable[fixedItemType] = itemTypeTable[fixedItemType] or { name = itemDetail.name, icon = itemDetail.icon, rarity = itemDetail.rarity, stack = 0, items = {} }
		itemTypeTable[fixedItemType].stack = itemTypeTable[fixedItemType].stack + (itemDetail.stack or 1)
		table.insert(itemTypeTable[fixedItemType].items, itemID)
	until true end
	
	local itemTable = {}
	for fixedItemType, itemData in pairs(itemTypeTable) do
		if itemData.stack > 0 and #itemData.items > 0 then
			itemTable[itemData.items[1]] = itemData
			itemTable[itemData.items[1]].fixedType = fixedItemType
			itemData.items = nil
		end
	end
	
	self:SetData(itemTable)
end

local function GetSelectedItem(self)
	return self:GetSelectedData()
end

function InternalInterface.UI.ItemSelector(name, parent)
	local bItemSelector = UI.CreateFrame("BDataGrid", name, parent)
	bItemSelector:SetPadding(1, 1, 1, 38)
	bItemSelector:SetHeadersVisible(false)
	bItemSelector:SetRowHeight(62)
	bItemSelector:SetRowMargin(2)
	bItemSelector:SetUnselectedRowBackgroundColor(0.2, 0.15, 0.2, 1)
	bItemSelector:SetSelectedRowBackgroundColor(0.6, 0.45, 0.6, 1)
	bItemSelector:AddColumn("Item", 248, "ItemSelectorRenderer", OrderItemsClosure(bItemSelector))
	
	local filterFrame = UI.CreateFrame("Frame", name .. ".FilterFrame", bItemSelector.externalPanel:GetContent())
	local paddingLeft, _, paddingRight, paddingBottom = bItemSelector:GetPadding()
	filterFrame:SetPoint("TOPLEFT", bItemSelector.externalPanel:GetContent(), "BOTTOMLEFT", paddingLeft + 2, 2 - paddingBottom)
	filterFrame:SetPoint("BOTTOMRIGHT", bItemSelector.externalPanel:GetContent(), "BOTTOMRIGHT", -paddingRight - 2, -2)
	bItemSelector.filterFrame = filterFrame
	
	local showHiddenCheckbox = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".ShowHiddenCheckbox", filterFrame)
	showHiddenCheckbox:SetPoint("BOTTOMRIGHT", filterFrame, "BOTTOMRIGHT")
	InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
	showHiddenCheckbox:SetChecked(InternalInterface.Settings.Posting.ShowHiddenItems or false)
	function showHiddenCheckbox.Event:CheckboxChange()
		InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
		InternalInterface.Settings.Posting.ShowHiddenItems = self:GetChecked() or nil
		bItemSelector:ForceUpdate()
	end
	bItemSelector.showHiddenCheckbox = showHiddenCheckbox
	
	local showHiddenLabel = UI.CreateFrame("Text", filterFrame:GetName() .. ".ShowHiddenLabel", filterFrame)
	showHiddenLabel:SetFontSize(11)
	showHiddenLabel:SetText("Show hidden") -- LOCALIZE
	showHiddenLabel:SetPoint("BOTTOMRIGHT", showHiddenCheckbox, "BOTTOMLEFT", -2, 2)
	bItemSelector.showHiddenCheckbox = showHiddenCheckbox
	
	local hideItemCheckbox = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".HideItemCheckbox", filterFrame)
	hideItemCheckbox:SetPoint("TOPRIGHT", filterFrame, "TOPRIGHT")
	function hideItemCheckbox.Event:CheckboxChange()
		InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
		InternalInterface.Settings.Posting.HiddenItems = InternalInterface.Settings.Posting.HiddenItems or {}
		
		local _, value = bItemSelector:GetSelectedData()
		if not value then return end

		local oldState = InternalInterface.Settings.Posting.HiddenItems[value.fixedType]
		InternalInterface.Settings.Posting.HiddenItems[value.fixedType] = self:GetChecked() or nil
		
		if not showHiddenCheckbox:GetChecked() and oldState ~= InternalInterface.Settings.Posting.HiddenItems[value.fixedType] then
			bItemSelector:ForceUpdate()
		end	
	end
	bItemSelector.hideItemCheckbox = hideItemCheckbox
	
	local hideItemLabel = UI.CreateFrame("Text", filterFrame:GetName() .. ".HideItemLabel", filterFrame)
	hideItemLabel:SetFontSize(11)
	hideItemLabel:SetText("Hide this item") -- LOCALIZE
	hideItemLabel:SetPoint("BOTTOMRIGHT", hideItemCheckbox, "BOTTOMLEFT", -2, 2)
	bItemSelector.hideItemLabel = hideItemLabel

	local filterTextPanel = UI.CreateFrame("BPanel", filterFrame:GetName() .. ".FilterTextPanel", filterFrame)
	if hideItemLabel:GetWidth() > showHiddenLabel:GetWidth() then
		filterTextPanel:SetPoint("BOTTOMLEFT", filterFrame, "BOTTOMLEFT", 0, -2)
		filterTextPanel:SetPoint("TOPRIGHT", hideItemLabel, "TOPLEFT", -1, 2)
	else
		filterTextPanel:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 0, 2)
		filterTextPanel:SetPoint("BOTTOMRIGHT", showHiddenLabel, "BOTTOMLEFT", -1, -2)
	end
	filterTextPanel:SetInvertedBorder(true)
	filterTextPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	bItemSelector.filterTextPanel = filterTextPanel
	
	local filterTextField = UI.CreateFrame("RiftTextfield", filterFrame:GetName() .. ".FilterTextField", filterTextPanel:GetContent())
	filterTextField:SetPoint("CENTERLEFT", filterTextPanel:GetContent(), "CENTERLEFT", 2, 1)
	filterTextField:SetPoint("CENTERRIGHT", filterTextPanel:GetContent(), "CENTERRIGHT", -22, 1)
	filterTextField:SetText("")
	function filterTextField.Event:TextfieldChange()
		bItemSelector:ForceUpdate()
	end
	function filterTextField.Event:KeyFocusGain()
		local length = string.len(self:GetText())
		if length > 0 then
			self:SetSelection(0, length)
		end
	end
	function filterTextPanel.Event:LeftClick()
		filterTextField:SetKeyFocus(true)
	end	
	bItemSelector.filterTextField = filterTextField
	
	local filterIcon = UI.CreateFrame("Texture", filterFrame:GetName() .. ".FilterIcon", filterTextPanel:GetContent())
	filterIcon:SetPoint("TOPRIGHT", filterTextPanel:GetContent(), "TOPRIGHT", -3, 3)
	filterIcon:SetPoint("BOTTOMLEFT", filterTextPanel:GetContent(), "BOTTOMRIGHT", -19, -3)
	filterIcon:SetAlpha(0.5)
	filterIcon:SetTexture("BananAH", "Textures/SearchIcon.png")
	bItemSelector.filterIcon = filterIcon

	function bItemSelector.Event:SelectionChanged(item, itemInfo)
		InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
		InternalInterface.Settings.Posting.HiddenItems = InternalInterface.Settings.Posting.HiddenItems or {}
		self.hideItemCheckbox:SetChecked(itemInfo and InternalInterface.Settings.Posting.HiddenItems[itemInfo.fixedType] or false)
		
		if self.Event.ItemSelected then
			self.Event.ItemSelected(self, item)
		end
	end
	
	local function ItemSelectorGridFilter(key, value)
		local filterText = string.upper(filterTextField:GetText())
		local upperName = string.upper(value.name)
		if not string.find(upperName, filterText) then return false end
		
		if not showHiddenCheckbox:GetChecked() then
			InternalInterface.Settings.Posting = InternalInterface.Settings.Posting or {}
			InternalInterface.Settings.Posting.HiddenItems = InternalInterface.Settings.Posting.HiddenItems or {}
			if InternalInterface.Settings.Posting.HiddenItems[value.fixedType] then return false end
		end
		
		return true
	end
	bItemSelector:SetFilteringFunction(ItemSelectorGridFilter)
	
	
	-- Public
	bItemSelector.ResetItems = ResetItems
	bItemSelector.GetSelectedItem = GetSelectedItem
	--TODO SetSelectedItem
	Library.LibBInterface.BEventHandler(bItemSelector, { "ItemSelected" })

	-- Late initialization
	table.insert(Event.Item.Slot, { function(updates) bItemSelector:ResetItems() end, "BananAH", "ItemSelector.OnItemChangeSlot" })
	table.insert(Event.Item.Update, { function(updates) bItemSelector:ResetItems() end, "BananAH", "ItemSelector.OnItemChangeUpdate" })

	return bItemSelector
end