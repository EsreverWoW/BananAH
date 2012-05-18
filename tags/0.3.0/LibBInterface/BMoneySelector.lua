-- Private
local function ResetMoneySelector(self)
	self.value = math.floor(self.value or 0)

	local silver = self.value % 100
	local gold = math.floor(self.value / 100) % 100
	local platinum = math.floor(self.value / 10000)

	self.secretLabel:SetText(string.format("%d", silver))
	self.silverInput:SetText(self.secretLabel:GetText())
	self.silverInput:SetWidth(self.secretLabel:GetWidth() + 10)	

	self.secretLabel:SetText(string.format("%d", gold))
	self.goldInput:SetText(self.secretLabel:GetText())
	self.goldInput:SetWidth(self.secretLabel:GetWidth() + 10)	

	self.secretLabel:SetText(string.format("%d", platinum))
	self.platinumInput:SetText(self.secretLabel:GetText())
	self.platinumInput:SetWidth(self.secretLabel:GetWidth() + 10)
	
	local color = { 0, 0, 0 }
	if self.compareFunction then
		color = self.compareFunction(self.value)
		color[1] = math.max(color[1] * 0.2, 0)
		color[2] = math.max(color[2] * 0.2, 0)
		color[3] = math.max(color[3] * 0.2, 0)
	end
	color[4] = 0.5
	self.silverPanel:GetContent():SetBackgroundColor(unpack(color))
	self.goldPanel:GetContent():SetBackgroundColor(unpack(color))
	self.platinumPanel:GetContent():SetBackgroundColor(unpack(color))
	
	if self.Event.ValueChanged then
		self.Event.ValueChanged(self, self.value)
	end
end

local function PanelLeftClick(self)
	if self.input then
		self.input:SetKeyFocus(true)
	end
end

local function InputKeyDown(self, key)
	self.lastText = self:GetText()
	self.lastCursor = self:GetCursor()
	self.ignoreChange = not tonumber(key) and string.byte(key) and string.byte(key) ~= 8
end
local function InputChange(self)
	local newText = self:GetText()
	local newValue = tonumber(newText) or 0
	local moneySelector = self.moneySelector
	
	if moneySelector.disabled or self.ignoreChange or newValue > self.maxValue or newValue < self.minValue then
		self:SetText(self.lastText)
		self:SetCursor(self.lastCursor)
		return
	end
	
	self:SetText(tostring(newValue))
	local platinum = tonumber(moneySelector.platinumInput:GetText()) or 0
	local gold = tonumber(moneySelector.goldInput:GetText()) or 0
	local silver = tonumber(moneySelector.silverInput:GetText()) or 0
	moneySelector:SetValue(platinum * 10000 + gold * 100 + silver)
	
	if self:GetText() == "0" then
		self:SetCursor(1)
	end
end
local function InputKeyUp(self, key)
	if key == "\9" or key == "\13" or key == "." or key == " " then
		if self.nextInput then
			self.nextInput:SetKeyFocus(true)
		else
			self:SetKeyFocus(false)
		end
	end
end

-- Public
local function GetEnabled(self)
	return not self.disabled
end

local function SetEnabled(self, enabled)
	self.disabled = not enabled or nil
	if not enabled then
		self.silverInput:SetKeyFocus(false)
		self.goldInput:SetKeyFocus(false)
		self.platinumInput:SetKeyFocus(false)
	end
	return enabled
end

local function GetValue(self)
	return self.value or 0
end

local function SetValue(self, value)
	value = math.min(math.max(value, 0), 999999999)
	if value ~= self.value then
		self.value = value
		ResetMoneySelector(self)
	end
	return self.value
end

local function SetCompareFunction(self, compareFunction)
	self.compareFunction = compareFunction
	ResetMoneySelector(self)
end

function Library.LibBInterface.BMoneySelector(name, parent)
	local bMoneySelector = UI.CreateFrame("Frame", name, parent)

	local platinumPanel = Library.LibBInterface.BPanel(name .. ".PlatinumPanel", bMoneySelector)
	local goldPanel = Library.LibBInterface.BPanel(name .. ".GoldPanel", bMoneySelector)
	local silverPanel = Library.LibBInterface.BPanel(name .. ".SilverPanel", bMoneySelector)
	local secretLabel = UI.CreateFrame("Text", name .. ".SecretLabel", bMoneySelector)

	local platinumTexture = UI.CreateFrame("Texture", bMoneySelector:GetName() .. ".PlatinumTexture", platinumPanel:GetContent())
	local goldTexture = UI.CreateFrame("Texture", bMoneySelector:GetName() .. ".GoldTexture", goldPanel:GetContent())
	local silverTexture = UI.CreateFrame("Texture", bMoneySelector:GetName() .. ".SilverTexture", silverPanel:GetContent())
	local platinumInput = UI.CreateFrame("RiftTextfield", name .. ".PlatinumInput", platinumPanel:GetContent())
	local goldInput = UI.CreateFrame("RiftTextfield", name .. ".GoldInput", goldPanel:GetContent())
	local silverInput = UI.CreateFrame("RiftTextfield", name .. ".SilverInput", silverPanel:GetContent())

	platinumPanel:SetPoint("TOPLEFT", bMoneySelector, "TOPLEFT", 0, 0)
	platinumPanel:SetPoint("BOTTOMRIGHT", bMoneySelector, "BOTTOMRIGHT", -130, 0)
	platinumPanel:SetInvertedBorder(true)
	platinumPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	platinumPanel.input = platinumInput
	platinumPanel.Event.LeftClick = PanelLeftClick
	bMoneySelector.platinumPanel = platinumPanel

	goldPanel:SetPoint("TOPRIGHT", bMoneySelector, "TOPRIGHT", -65, 0)
	goldPanel:SetPoint("BOTTOMRIGHT", bMoneySelector, "BOTTOMRIGHT", -65, 0)
	goldPanel:SetWidth(60)
	goldPanel:SetInvertedBorder(true)
	goldPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	goldPanel.input = goldInput
	goldPanel.Event.LeftClick = PanelLeftClick
	bMoneySelector.goldPanel = goldPanel
	
	silverPanel:SetPoint("TOPRIGHT", bMoneySelector, "TOPRIGHT", 0, 0)
	silverPanel:SetPoint("BOTTOMRIGHT", bMoneySelector, "BOTTOMRIGHT", 0, 0)
	silverPanel:SetWidth(60)
	silverPanel:SetInvertedBorder(true)
	silverPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	silverPanel.input = silverInput
	silverPanel.Event.LeftClick = PanelLeftClick
	bMoneySelector.silverPanel = silverPanel

	secretLabel:SetVisible(false)
	bMoneySelector.secretLabel = secretLabel

	platinumTexture:SetTexture("LibBInterface", "Textures/CoinPlatinum.png")
	platinumTexture:SetPoint("BOTTOMRIGHT", platinumPanel:GetContent(), "BOTTOMRIGHT", -1, -2)
	bMoneySelector.platinumTexture = platinumTexture

	goldTexture:SetTexture("LibBInterface", "Textures/CoinGold.png")
	goldTexture:SetPoint("BOTTOMRIGHT", goldPanel:GetContent(), "BOTTOMRIGHT", -2, -1)
	bMoneySelector.goldTexture = goldTexture

	silverTexture:SetTexture("LibBInterface", "Textures/CoinSilver.png")
	silverTexture:SetPoint("BOTTOMRIGHT", silverPanel:GetContent(), "BOTTOMRIGHT", -1, -2)
	bMoneySelector.silverTexture = silverTexture
	
	platinumInput:SetPoint("CENTERRIGHT", platinumPanel:GetContent(), "CENTERRIGHT", -11, 1)
	platinumInput:SetText("")
	platinumInput.minValue = 0
	platinumInput.maxValue = 99999
	platinumInput.moneySelector = bMoneySelector
	platinumInput.nextInput = goldInput
	platinumInput.Event.KeyDown = InputKeyDown
	platinumInput.Event.TextfieldChange = InputChange
	platinumInput.Event.KeyUp = InputKeyUp
	bMoneySelector.platinumInput = platinumInput

	goldInput:SetPoint("CENTERRIGHT", goldPanel:GetContent(), "CENTERRIGHT", -11, 1)
	goldInput:SetText("")
	goldInput.minValue = 0
	goldInput.maxValue = 99
	goldInput.moneySelector = bMoneySelector
	goldInput.nextInput = silverInput
	goldInput.Event.KeyDown = InputKeyDown
	goldInput.Event.TextfieldChange = InputChange
	goldInput.Event.KeyUp = InputKeyUp
	bMoneySelector.goldInput = goldInput	
	
	silverInput:SetPoint("CENTERRIGHT", silverPanel:GetContent(), "CENTERRIGHT", -11, 1)
	silverInput:SetText("")
	silverInput.minValue = 0
	silverInput.maxValue = 99
	silverInput.moneySelector = bMoneySelector
	silverInput.Event.KeyDown = InputKeyDown
	silverInput.Event.TextfieldChange = InputChange
	silverInput.Event.KeyUp = InputKeyUp
	bMoneySelector.silverInput = silverInput	

	-- function platinumInput.Event:TextfieldSelect()
		-- if Inspect.Time.Real() - (self.selectOnFocus or 0) <= 0.1 then
			-- self.selectOnFocus = nil
			-- self:SetCursor(string.len(self:GetText()))
			-- self:SetSelection(0, string.len(self:GetText()))
		-- end
	-- end
	-- function platinumInput.Event:KeyFocusGain()
		-- if not bMoneySelector.enabled then self:SetKeyFocus(false) end
		-- self.selectOnFocus = nil
		-- self:SetCursor(string.len(self:GetText()))
		-- self:SetSelection(0, string.len(self:GetText()))
		-- self.selectOnFocus = Inspect.Time.Real()
	-- end
	
	-- Public
	bMoneySelector.GetEnabled = GetEnabled
	bMoneySelector.SetEnabled = SetEnabled
	bMoneySelector.GetValue = GetValue
	bMoneySelector.SetValue = SetValue
	bMoneySelector.SetCompareFunction = SetCompareFunction
	Library.LibBInterface.BEventHandler(bMoneySelector, { "ValueChanged" })
	
	-- Late Initialization
	ResetMoneySelector(bMoneySelector)
	
	return bMoneySelector
end