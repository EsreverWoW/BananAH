-- Private
local function ResetMoneyFrame(self)
	local value = math.floor(self.value or 0)
	local silver = value % 100
	local gold = math.floor(value / 100) % 100
	local platinum = math.floor(value / 10000)

	if silver > 0 or gold > 0 or platinum > 0 then
		self.silverTexture:SetVisible(true)
		self.silverText:SetVisible(true)
		self.silverText:SetText(tostring(silver))
	else
		self.silverTexture:SetVisible(false)
		self.silverText:SetVisible(false)
	end
	
	if gold > 0 or platinum > 0 then
		self.goldTexture:SetVisible(true)
		self.goldText:SetVisible(true)
		self.goldText:SetText(tostring(gold))
	else
		self.goldTexture:SetVisible(false)
		self.goldText:SetVisible(false)
	end
	
	if platinum > 0 then
		self.platinumTexture:SetVisible(true)
		self.platinumText:SetVisible(true)
		self.platinumText:SetText(tostring(platinum))
	else
		self.platinumTexture:SetVisible(false)
		self.platinumText:SetVisible(false)
	end
	
	local color = { 1, 1, 1, 1 }
	if self.compareValue then
		local relative = value / self.compareValue
		if relative < 0.7 then color = { 0, 0.75, 1, 1 }
		elseif relative < 0.9 then color = { 0, 0.75, 0, 1 }
		elseif relative < 1.1 then color = { 0.75, 0.75, 0, 1 }
		elseif relative < 1.5 then color = { 0.75, 0.5, 0, 1 }
		else color = { 0.75, 0, 0, 1 }
		end
	end
	self.silverText:SetFontColor(unpack(color))
	self.goldText:SetFontColor(unpack(color))
	self.platinumText:SetFontColor(unpack(color))
end

-- Public
local function GetValue(self)
	self.value = self.value or 0
	return self.value
end

local function SetValue(self, newValue)
	self.value = math.max(newValue or 0, 0)
	ResetMoneyFrame(self)
	return self.value
end

local function SetCompareValue(self, compareValue)
	self.compareValue = compareValue
	ResetMoneyFrame(self)
end

function Library.LibBInterface.BMoneyDisplay(name, parent)
	local bMoneyDisplay = UI.CreateFrame("Frame", name, parent)
	
	local silverTexture = UI.CreateFrame("Texture", bMoneyDisplay:GetName() .. ".SilverTexture", bMoneyDisplay)
	silverTexture:SetTexture("LibBInterface", "Textures/CoinSilver.png")
	silverTexture:SetPoint("BOTTOMRIGHT", bMoneyDisplay, "BOTTOMRIGHT", -1, -3)
	bMoneyDisplay.silverTexture = silverTexture
	
	local goldTexture = UI.CreateFrame("Texture", bMoneyDisplay:GetName() .. ".GoldTexture", bMoneyDisplay)
	goldTexture:SetTexture("LibBInterface", "Textures/CoinGold.png")
	goldTexture:SetPoint("BOTTOMRIGHT", bMoneyDisplay, "BOTTOMRIGHT", -38, -3)
	bMoneyDisplay.goldTexture = goldTexture
	
	local platinumTexture = UI.CreateFrame("Texture", bMoneyDisplay:GetName() .. ".PlatinumTexture", bMoneyDisplay)
	platinumTexture:SetTexture("LibBInterface", "Textures/CoinPlatinum.png")
	platinumTexture:SetPoint("BOTTOMRIGHT", bMoneyDisplay, "BOTTOMRIGHT", -73, -3)
	bMoneyDisplay.platinumTexture = platinumTexture
	
	local silverText = UI.CreateFrame("Text", bMoneyDisplay:GetName() .. ".SilverText", bMoneyDisplay)
	silverText:SetText("0")
	silverText:SetPoint("TOPRIGHT", bMoneyDisplay, "TOPRIGHT", -16, 0)
	silverText:SetPoint("BOTTOMRIGHT", bMoneyDisplay, "BOTTOMRIGHT", -16, 0)
	bMoneyDisplay.silverText = silverText
	
	local goldText = UI.CreateFrame("Text", bMoneyDisplay:GetName() .. ".GoldText", bMoneyDisplay)
	goldText:SetText("0")
	goldText:SetPoint("TOPRIGHT", bMoneyDisplay, "TOPRIGHT", -52, 0)
	goldText:SetPoint("BOTTOMRIGHT", bMoneyDisplay, "BOTTOMRIGHT", -52, 0)
	bMoneyDisplay.goldText = goldText
	
	local platinumText = UI.CreateFrame("Text", bMoneyDisplay:GetName() .. ".PlatinumText", bMoneyDisplay)
	platinumText:SetText("0")
	platinumText:SetPoint("TOPRIGHT", bMoneyDisplay, "TOPRIGHT", -88, 0)
	platinumText:SetPoint("BOTTOMRIGHT", bMoneyDisplay, "BOTTOMRIGHT", -88, 0)
	bMoneyDisplay.platinumText = platinumText

	-- Variables
	bMoneyDisplay.value = 0

	-- Public
	bMoneyDisplay.GetValue = GetValue
	bMoneyDisplay.SetValue = SetValue
	bMoneyDisplay.SetCompareValue = SetCompareValue
	
	-- Late initialization
	ResetMoneyFrame(bMoneyDisplay)
	
	return bMoneyDisplay
end