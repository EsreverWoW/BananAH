
local DEFAULT_OFFSET = 1
local DEFAULT_SHADOW_COLOR = { 0, 0, 0, 0.25 }

function Library.LibBInterface.BShadowedText(name, parent)
	local label = UI.CreateFrame("Text", name, parent)
	
	local shadow = UI.CreateFrame("Text", name .. ".Shadow", parent)
	shadow:SetPoint("CENTER", label, "CENTER", DEFAULT_OFFSET, DEFAULT_OFFSET)
	shadow:SetLayer(label:GetLayer() - 1)
	shadow:SetFontColor(unpack(DEFAULT_SHADOW_COLOR))
	label.shadow = shadow
	
	local oldSetFont = label.SetFont
	function label:SetFont(source, font)
		oldSetFont(self, source, font)
		self.shadow:SetFont(source, font)
	end

	local oldSetFontSize = label.SetFontSize
	function label:SetFontSize(fontSize)
		oldSetFontSize(self, fontSize)
		self.shadow:SetFontSize(fontSize)
	end

	local oldSetText = label.SetText
	function label:SetText(text)
		oldSetText(self, text)
		self.shadow:SetText(text)
	end

	local oldSetWordwrap = label.SetWordwrap
	function label:SetWordwrap(wordWrap)
		oldSetWordwrap(self, wordWrap)
		self.shadow:SetWordwrap(wordWrap)
	end
	
	local oldSetVisible = label.SetVisible
	function label:SetVisible(visible)
		oldSetVisible(self, visible)
		self.shadow:SetVisible(visible)
	end
	
	function label:SetShadowColor(r, g, b, a)
		self.shadow:SetFontColor(r, g, b, a)
	end
	
	function label:SetShadowOffset(x, y)
		self.shadow:ClearAll()
		self.shadow:SetPoint("CENTER", self, "CENTER", x or DEFAULT_OFFSET, y or DEFAULT_OFFSET)
	end

	return label
end