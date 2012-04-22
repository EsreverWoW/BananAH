-- Constants
local VALUE_HEIGHT = 26
local VALUE_MARGIN = 0
local VALUE_BORDER = 1.5
local BORDER_HEIGHT = 8

-- Private
local function SetValueFrame(self, index, value)
	self.valueFrames = self.valueFrames or {}
	local valueFrame = self.valueFrames[index]
	if not valueFrame then
		valueFrame = UI.CreateFrame("Frame", self:GetName() .. ".ValueFrames." .. index, self.dropdownPanel:GetContent())
		valueFrame:SetBackgroundColor(0, 0, 0, 1)
		valueFrame:SetPoint("TOPLEFT", self.dropdownPanel:GetContent(), "TOPLEFT", 0, (index - 1) * (VALUE_HEIGHT + VALUE_MARGIN * 2 +  VALUE_BORDER * 2) + VALUE_MARGIN)
		valueFrame:SetPoint("BOTTOMRIGHT", self.dropdownPanel:GetContent(), "TOPRIGHT", 0, index * (VALUE_HEIGHT + VALUE_MARGIN * 2 +  VALUE_BORDER * 2) - VALUE_MARGIN)
		function valueFrame.Event:MouseIn()
			valueFrame:SetBackgroundColor(1, 0.75, 0, 1)
		end
		function valueFrame.Event:MouseOut()
			valueFrame:SetBackgroundColor(0, 0, 0, 1)
		end
		function valueFrame.Event.LeftClick(valueFrame)
			self:SetSelectedIndex(valueFrame.index)
			self.dropdownPanel:SetVisible(false)
		end
		
		local valueMask = UI.CreateFrame("Mask", valueFrame:GetName() .. ".ValueMask", valueFrame)
		valueMask:SetBackgroundColor(0, 0, 0, 1)
		valueMask:SetPoint("TOPLEFT", valueFrame, "TOPLEFT", 0, VALUE_BORDER)
		valueMask:SetPoint("BOTTOMRIGHT", valueFrame, "BOTTOMRIGHT", 0, -VALUE_BORDER)
		valueFrame.mask = valueMask
		
		local valueText = UI.CreateFrame("Text", valueFrame:GetName() .. ".ValueText", valueMask)
		valueText:SetPoint("TOPLEFT", valueMask, "TOPLEFT", 5, 2)
		valueText:SetPoint("BOTTOMRIGHT", valueMask, "BOTTOMRIGHT", -5, 0)
		valueText:SetFontSize(14)
		valueFrame.text = valueText
		
		valueFrame.index = index
		
		table.insert(self.valueFrames, valueFrame)
	end
	
	if value then
		valueFrame:SetVisible(true)
		valueFrame.text:SetText(tostring(value.displayName))
	else
		valueFrame:SetVisible(false)
	end
	valueFrame.value = value
end

-- Public
local function GetEnabled(self)
	return self.enabled or false
end

local function SetEnabled(self, enabled)
	self.enabled = enabled or nil
	return self.enabled or false
end

local function GetValues(self)
	return self.values or {}
end

local function SetValues(self, values)
	self.values = values or {}
	
	for index, value in ipairs(self.values) do
		SetValueFrame(self, index, value)
	end
	
	self.valueFrames = self.valueFrames or {}
	for index = #self.values + 1, #self.valueFrames do
		SetValueFrame(self, index, nil)
	end
	
	self.dropdownPanel:SetHeight(#self.values * (VALUE_HEIGHT + VALUE_MARGIN * 2 + VALUE_BORDER * 2) + BORDER_HEIGHT)
	
	self:SetEnabled(#self.values > 0)
	self:SetSelectedIndex(#self.values > 0 and 1 or nil)
	
	return self.values	
end

local function GetSelectedValue(self)
	local value = self:GetValues()[self.selectedIndex or 0]
	return self.selectedIndex, value
end

local function GetSelectedIndex(self)
	return self.selectedIndex
end

local function SetSelectedIndex(self, index)
	self.selectedIndex = index
	local _, value = self:GetSelectedValue()
	self.selectedText:SetText(tostring(value and value.displayName or ""))
	if self.Event.SelectionChanged then
		self.Event.SelectionChanged(self, self.selectedIndex, value)
	end		
end

function Library.LibBInterface.BDropdown(name, parent)
	local bDropdown = Library.LibBInterface.BPanel(name, parent)
	bDropdown:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	bDropdown:SetInvertedBorder(true)
	
	local iconPanel = Library.LibBInterface.BPanel(name .. ".IconPanel", bDropdown:GetContent())
	iconPanel:SetPoint("TOPLEFT", bDropdown:GetContent(), "TOPLEFT", 0, 0)
	iconPanel:SetPoint("BOTTOMRIGHT", bDropdown:GetContent(), "BOTTOMLEFT", 30, 0)
	bDropdown.iconPanel = iconPanel
	
	local iconTexture = UI.CreateFrame("Texture", name .. ".IconTexture", iconPanel:GetContent())
	iconTexture:SetPoint("TOPLEFT", iconPanel:GetContent(), "TOPLEFT", 1, 1)
	iconTexture:SetPoint("BOTTOMRIGHT", iconPanel:GetContent(), "BOTTOMRIGHT", -1, -1)
	iconTexture:SetTexture("LibBInterface", "Textures/SortedDescendingGlyph.png")
	function iconTexture.Event:LeftClick()
		if not bDropdown.enabled then return end
		bDropdown.dropdownPanel:SetVisible(not bDropdown.dropdownPanel:GetVisible())
	end
	bDropdown.iconTexture = iconTexture
	
	local selectedMask = UI.CreateFrame("Mask", name .. ".SelectedMask", bDropdown:GetContent())
	selectedMask:SetPoint("TOPLEFT", bDropdown:GetContent(), "TOPLEFT", 35, 2)
	selectedMask:SetPoint("BOTTOMRIGHT", bDropdown:GetContent(), "BOTTOMRIGHT", -5, -2)
	bDropdown.selectedMask = selectedMask
	
	local selectedText = UI.CreateFrame("Text", name .. ".SelectedText", selectedMask)
	selectedText:SetAllPoints()
	selectedText:SetFontSize(14)
	bDropdown.selectedText = selectedText
	
	local dropdownPanel = Library.LibBInterface.BPanel(name .. ".DropdownPanel", parent:GetParent())
	dropdownPanel:SetPoint("TOPLEFT", bDropdown, "BOTTOMLEFT")
	dropdownPanel:SetPoint("TOPRIGHT", bDropdown, "BOTTOMRIGHT")
	dropdownPanel:SetHeight(BORDER_HEIGHT)
	dropdownPanel:SetLayer(bDropdown:GetLayer() + 50)
	dropdownPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	dropdownPanel.borderFrame:SetAlpha(1)
	dropdownPanel:SetVisible(false)
	bDropdown.dropdownPanel = dropdownPanel
	
	-- Public
	bDropdown.GetEnabled = GetEnabled
	bDropdown.SetEnabled = SetEnabled
	bDropdown.GetValues = GetValues
	bDropdown.SetValues = SetValues
	bDropdown.GetSelectedValue = GetSelectedValue
	bDropdown.GetSelectedIndex = GetSelectedIndex
	bDropdown.SetSelectedIndex = SetSelectedIndex
	Library.LibBInterface.BEventHandler(bDropdown, { "SelectionChanged" })
	
	return bDropdown
end