-- Private
local function ResetMoneySelector(self)
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
	
	if self.Event.ValueChanged then
		self.Event.ValueChanged(self, self.value)
	end
end

-- Public
local function GetEnabled(self)
	return self.enabled or false
end

local function SetEnabled(self, enabled)
	self.enabled = enabled or nil
	if not enabled then
		self.silverInput:SetKeyFocus(false)
		self.goldInput:SetKeyFocus(false)
		self.platinumInput:SetKeyFocus(false)
	end
	return self.enabled
end

local function GetValue(self)
	self.value = self.value or 0
	return self.value
end

local function SetValue(self, value)
	self.value = math.min(math.max(value, 0), 999999999)
	ResetMoneySelector(self)
	return self.value
end

function Library.LibBInterface.BMoneySelector(name, parent)
	local bMoneySelector = UI.CreateFrame("Frame", name, parent)
	
	local silverPanel = Library.LibBInterface.BPanel(name .. ".SilverPanel", bMoneySelector)
	silverPanel:SetPoint("TOPRIGHT", bMoneySelector, "TOPRIGHT", 0, 0)
	silverPanel:SetPoint("BOTTOMRIGHT", bMoneySelector, "BOTTOMRIGHT", 0, 0)
	silverPanel:SetWidth(60)
	silverPanel:SetInvertedBorder(true)
	silverPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	bMoneySelector.silverPanel = silverPanel

	local silverTexture = UI.CreateFrame("Texture", bMoneySelector:GetName() .. ".SilverTexture", silverPanel:GetContent())
	silverTexture:SetTexture("LibBInterface", "Textures/CoinSilver.png")
	silverTexture:SetPoint("BOTTOMRIGHT", silverPanel:GetContent(), "BOTTOMRIGHT", -1, -2)
	bMoneySelector.silverTexture = silverTexture
	
	local silverInput = UI.CreateFrame("RiftTextfield", name .. ".SilverInput", silverPanel:GetContent())
	silverInput:SetPoint("CENTERRIGHT", silverPanel:GetContent(), "CENTERRIGHT", -11, 1)
	silverInput:SetText("")
	function silverInput.Event:TextfieldChange()
		local newValue = tonumber(self:GetText() ~= "" and self:GetText() or "0")
		newValue = newValue and math.max(math.min(math.floor(newValue), 99), 0)
		if newValue then
			bMoneySelector.value = math.floor(bMoneySelector.value / 100) * 100 + newValue
		end
		ResetMoneySelector(bMoneySelector)
	end	
	function silverInput.Event:KeyFocusGain()
		if not bMoneySelector.enabled then self:SetKeyFocus(false) end
		self:SetSelection(0, string.len(self:GetText()))
	end
	function silverPanel.contentFrame.Event:LeftClick()
		silverInput:SetKeyFocus(true)
	end
	bMoneySelector.silverInput = silverInput	

	local goldPanel = Library.LibBInterface.BPanel(name .. ".GoldPanel", bMoneySelector)
	goldPanel:SetPoint("TOPRIGHT", bMoneySelector, "TOPRIGHT", -65, 0)
	goldPanel:SetPoint("BOTTOMRIGHT", bMoneySelector, "BOTTOMRIGHT", -65, 0)
	goldPanel:SetWidth(60)
	goldPanel:SetInvertedBorder(true)
	goldPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	bMoneySelector.goldPanel = goldPanel

	local goldTexture = UI.CreateFrame("Texture", bMoneySelector:GetName() .. ".GoldTexture", goldPanel:GetContent())
	goldTexture:SetTexture("LibBInterface", "Textures/CoinGold.png")
	goldTexture:SetPoint("BOTTOMRIGHT", goldPanel:GetContent(), "BOTTOMRIGHT", -2, -1)
	bMoneySelector.goldTexture = goldTexture

	local goldInput = UI.CreateFrame("RiftTextfield", name .. ".GoldInput", goldPanel:GetContent())
	goldInput:SetPoint("CENTERRIGHT", goldPanel:GetContent(), "CENTERRIGHT", -11, 1)
	goldInput:SetText("")
	function goldInput.Event:TextfieldChange()
		local newValue = tonumber(self:GetText() ~= "" and self:GetText() or "0")
		newValue = newValue and math.max(math.min(math.floor(newValue), 99), 0)
		if newValue then
			bMoneySelector.value = math.floor(bMoneySelector.value / 10000) * 10000 + newValue * 100 + bMoneySelector.value % 100
		end
		ResetMoneySelector(bMoneySelector)
	end		
	function goldInput.Event:KeyFocusGain()
		if not bMoneySelector.enabled then self:SetKeyFocus(false) end
		self:SetSelection(0, string.len(self:GetText()))
	end
	function goldPanel.contentFrame.Event:LeftClick()
		goldInput:SetKeyFocus(true)
	end
	bMoneySelector.goldInput = goldInput	
	
	local platinumPanel = Library.LibBInterface.BPanel(name .. ".PlatinumPanel", bMoneySelector)
	platinumPanel:SetPoint("TOPLEFT", bMoneySelector, "TOPLEFT", 0, 0)
	platinumPanel:SetPoint("BOTTOMRIGHT", bMoneySelector, "BOTTOMRIGHT", -130, 0)
	platinumPanel:SetInvertedBorder(true)
	platinumPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	bMoneySelector.platinumPanel = platinumPanel

	local platinumTexture = UI.CreateFrame("Texture", bMoneySelector:GetName() .. ".PlatinumTexture", platinumPanel:GetContent())
	platinumTexture:SetTexture("LibBInterface", "Textures/CoinPlatinum.png")
	platinumTexture:SetPoint("BOTTOMRIGHT", platinumPanel:GetContent(), "BOTTOMRIGHT", -1, -2)
	bMoneySelector.platinumTexture = platinumTexture

	local platinumInput = UI.CreateFrame("RiftTextfield", name .. ".PlatinumInput", platinumPanel:GetContent())
	platinumInput:SetPoint("CENTERRIGHT", platinumPanel:GetContent(), "CENTERRIGHT", -11, 1)
	platinumInput:SetText("")
	function platinumInput.Event:TextfieldChange()
		local newValue = tonumber(self:GetText() ~= "" and self:GetText() or "0")
		newValue = newValue and math.max(math.min(math.floor(newValue), 99999), 0)
		if newValue then
			bMoneySelector.value = newValue * 10000 + bMoneySelector.value % 10000
		end
		ResetMoneySelector(bMoneySelector)
	end		
	function platinumInput.Event:KeyFocusGain()
		if not bMoneySelector.enabled then self:SetKeyFocus(false) end
		self:SetSelection(0, string.len(self:GetText()))
	end
	function platinumPanel.contentFrame.Event:LeftClick()
		platinumInput:SetKeyFocus(true)
	end
	bMoneySelector.platinumInput = platinumInput
	
	local secretLabel = UI.CreateFrame("Text", name .. ".SecretLabel", bMoneySelector)
	secretLabel:SetVisible(false)
	bMoneySelector.secretLabel = secretLabel
	
	-- Variables
	bMoneySelector.enabled = true
	bMoneySelector.value = 0
	
	-- Public
	bMoneySelector.GetEnabled = GetEnabled
	bMoneySelector.SetEnabled = SetEnabled
	bMoneySelector.GetValue = GetValue
	bMoneySelector.SetValue = SetValue
	Library.LibBInterface.BEventHandler(bMoneySelector, { "ValueChanged" })
	
	-- Late Initialization
	ResetMoneySelector(bMoneySelector)
	
	return bMoneySelector
end