-- Private
local function UpdateTextfield(self)
	local text = string.format("%d", self.currentValue)
	self.secretLabel:SetText(text)
	local textWidth = self.secretLabel:GetWidth() + 10

	self.textField:SetText(text)
	self.textField:SetWidth(textWidth)
end

local function RepositionSlider(self)
	if self.minValue >= self.maxValue then
		self.slider:SetRange(self.minValue, self.minValue + 1)
		self.currentValue = self.minValue
		self.slider:SetPosition(self.currentValue)
		self.slider:SetEnabled(false)
	else
		self.slider:SetRange(self.minValue, self.maxValue)
		self.slider:SetPosition(self.currentValue)
		self.slider:SetEnabled(true)
	end
	
	UpdateTextfield(self)
	
	if self.Event.PositionChanged then
		self.Event.PositionChanged(self, self.currentValue)
	end
end

-- Public
local function SetRange(self, minRange, maxRange)
	self.minValue = math.max(minRange, 0)
	self.maxValue = math.min(maxRange, 999)
	self.currentValue = math.max(math.min(self.currentValue, self.maxValue), self.minValue)
	RepositionSlider(self)
end

local function SetPosition(self, position)
	self.currentValue = math.max(math.min(position, self.maxValue), self.minValue)
	RepositionSlider(self)
end

local function GetPosition(self)
	return self.currentValue
end

function Library.LibBInterface.BSlider(name, parent)
	local bSlider = UI.CreateFrame("Frame", name, parent)
	
	local slider = UI.CreateFrame("RiftSlider", name .. ".Slider", bSlider)
	slider:SetPoint("CENTERLEFT", bSlider, "CENTERLEFT", 12, 0)
	slider:SetPoint("CENTERRIGHT", bSlider, "CENTERRIGHT", -60, 0)
	function slider.Event:SliderChange()
		local newPosition = math.floor(self:GetPosition())
		if newPosition == bSlider.currentValue then return end
		bSlider.currentValue = math.max(math.min(newPosition, bSlider.maxValue), bSlider.minValue)
		RepositionSlider(bSlider)
	end
	bSlider.slider = slider
	
	local innerPanel = Library.LibBInterface.BPanel(name .. ".InnerPanel", bSlider)
	innerPanel:SetPoint("CENTERLEFT", slider, "CENTERRIGHT", 14, slider:GetHeight() - 30)
	innerPanel:SetWidth(46)
	innerPanel:SetHeight(30)
	innerPanel:SetInvertedBorder(true)
	innerPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	bSlider.innerPanel = innerPanel
	
	local textField = UI.CreateFrame("RiftTextfield", name .. ".InnerPanel.Textfield", innerPanel:GetContent())
	textField:SetPoint("CENTER", innerPanel:GetContent(), "CENTER", 5, 1)
	textField:SetText("")
	function textField.Event:TextfieldChange()
		local newPosition = tonumber(self:GetText() ~= "" and self:GetText() or "0")
		newPosition = newPosition and math.floor(newPosition)
		if newPosition and newPosition ~= bSlider.currentValue then
			bSlider.currentValue = math.max(math.min(newPosition, bSlider.maxValue), bSlider.minValue)
		end
		RepositionSlider(bSlider)
	end
	function textField.Event:KeyFocusGain()
		self:SetSelection(0, string.len(self:GetText()))
	end
	function innerPanel.contentFrame.Event:LeftClick()
		textField:SetKeyFocus(true)
	end
	bSlider.textField = textField
	
	local secretLabel = UI.CreateFrame("Text", name .. ".SecretLabel", bSlider)
	secretLabel:SetVisible(false)
	bSlider.secretLabel = secretLabel	

	-- Variables
	bSlider.minValue = 0
	bSlider.maxValue = 0
	bSlider.currentValue = 0

	-- Public
	bSlider.SetRange = SetRange
	bSlider.GetPosition = GetPosition
	bSlider.SetPosition = SetPosition
	Library.LibBInterface.BEventHandler(bSlider, { "PositionChanged" })
	
	-- Late Initialization
	RepositionSlider(bSlider)

	return bSlider
end