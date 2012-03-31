-- Private
local function BuildBorderFrame(bPanel)
	if not bPanel.borderFrame then
		local borderFrame = UI.CreateFrame("Frame", bPanel:GetName() .. ".Border", bPanel)
		borderFrame:SetAllPoints(bPanel)
		borderFrame:SetLayer(bPanel:GetLayer() + 10)
		bPanel.borderFrame = borderFrame
		
		local cornerTopLeft = UI.CreateFrame("Texture", borderFrame:GetName() .. ".CornerTopLeft", borderFrame)
		cornerTopLeft:SetTexture("LibBInterface", "Textures/PanelExtCornerTopLeft.png")
		cornerTopLeft:SetPoint("TOPLEFT", borderFrame, "TOPLEFT", 0, 0)
		borderFrame.cornerTopLeft = cornerTopLeft

		local cornerTopRight = UI.CreateFrame("Texture", borderFrame:GetName() .. ".CornerTopRight", borderFrame)
		cornerTopRight:SetTexture("LibBInterface", "Textures/PanelExtCornerTopRight.png")
		cornerTopRight:SetPoint("TOPRIGHT", borderFrame, "TOPRIGHT", 0, 0)
		borderFrame.cornerTopRight = cornerTopRight

		local cornerBottomLeft = UI.CreateFrame("Texture", borderFrame:GetName() .. ".CornerBottomLeft", borderFrame)
		cornerBottomLeft:SetTexture("LibBInterface", "Textures/PanelExtCornerBottomLeft.png")
		cornerBottomLeft:SetPoint("BOTTOMLEFT", borderFrame, "BOTTOMLEFT", 0, 0)
		borderFrame.cornerBottomLeft = cornerBottomLeft

		local cornerBottomRight = UI.CreateFrame("Texture", borderFrame:GetName() .. ".CornerBottomRight", borderFrame)
		cornerBottomRight:SetTexture("LibBInterface", "Textures/PanelExtCornerBottomRight.png")
		cornerBottomRight:SetPoint("BOTTOMRIGHT", borderFrame, "BOTTOMRIGHT", 0, 0)
		borderFrame.cornerBottomRight = cornerBottomRight

		local borderTop = UI.CreateFrame("Texture", borderFrame:GetName() .. ".BorderTop", borderFrame)
		borderTop:SetTexture("LibBInterface", "Textures/PanelExtBorderTop.png")
		borderTop:SetPoint("TOPLEFT", cornerTopLeft, "TOPRIGHT", 0, 0)
		borderTop:SetPoint("TOPRIGHT", cornerTopRight, "TOPLEFT", 0, 0)
		borderFrame.borderTop = borderTop
		
		local borderBottom = UI.CreateFrame("Texture", borderFrame:GetName() .. ".BorderBottom", borderFrame)
		borderBottom:SetTexture("LibBInterface", "Textures/PanelExtBorderBottom.png")
		borderBottom:SetPoint("BOTTOMLEFT", cornerBottomLeft, "BOTTOMRIGHT", 0, 0)
		borderBottom:SetPoint("BOTTOMRIGHT", cornerBottomRight, "BOTTOMLEFT", 0, 0)
		borderFrame.borderBottom = borderBottom
		
		local borderLeft = UI.CreateFrame("Texture", borderFrame:GetName() .. ".BorderLeft", borderFrame)
		borderLeft:SetTexture("LibBInterface", "Textures/PanelExtBorderLeft.png")
		borderLeft:SetPoint("TOPLEFT", cornerTopLeft, "BOTTOMLEFT", 0, 0)
		borderLeft:SetPoint("BOTTOMLEFT", cornerBottomLeft, "TOPLEFT", 0, 0)
		borderFrame.borderLeft = borderLeft
		
		local borderRight = UI.CreateFrame("Texture", borderFrame:GetName() .. ".BorderRight", borderFrame)
		borderRight:SetTexture("LibBInterface", "Textures/PanelExtBorderRight.png")
		borderRight:SetPoint("TOPRIGHT", cornerTopRight, "BOTTOMRIGHT", 0, 0)
		borderRight:SetPoint("BOTTOMRIGHT", cornerBottomRight, "TOPRIGHT", 0, 0)
		borderFrame.borderRight = borderRight
		
		local background = UI.CreateFrame("Texture", borderFrame:GetName() .. ".Background", borderFrame)
		background:SetTexture("LibBInterface", "Textures/PanelExtBackground.png")
		background:SetPoint("TOPLEFT", cornerTopLeft, "BOTTOMRIGHT", 0, 0)
		background:SetPoint("BOTTOMRIGHT", cornerBottomRight, "TOPLEFT", 0, 0)
		background:SetLayer(-10)
		borderFrame.background = background
		
		borderFrame:SetAlpha(0.75)
	end
end

local function BuildContentFrame(bPanel)
	if not bPanel.contentFrame then
		local contentFrame = UI.CreateFrame("Mask", bPanel:GetName() .. ".Content", bPanel)
		contentFrame:SetPoint("TOPLEFT", bPanel, "TOPLEFT", 4, 4)
		contentFrame:SetPoint("BOTTOMRIGHT", bPanel, "BOTTOMRIGHT", -4, -4)
		contentFrame:SetLayer(bPanel:GetLayer() + 20)
		bPanel.contentFrame = contentFrame
	end
end

-- Public
local function SetInvertedBorder(self, inverted)
	if self.borderFrame then
		if inverted then
			self.borderFrame.cornerTopLeft:SetTexture("LibBInterface", "Textures/PanelIntCornerTopLeft.png")
			self.borderFrame.cornerTopRight:SetTexture("LibBInterface", "Textures/PanelIntCornerTopRight.png")
			self.borderFrame.cornerBottomLeft:SetTexture("LibBInterface", "Textures/PanelIntCornerBottomLeft.png")
			self.borderFrame.cornerBottomRight:SetTexture("LibBInterface", "Textures/PanelIntCornerBottomRight.png")
			self.borderFrame.borderTop:SetTexture("LibBInterface", "Textures/PanelIntBorderTop.png")
			self.borderFrame.borderBottom:SetTexture("LibBInterface", "Textures/PanelIntBorderBottom.png")
			self.borderFrame.borderLeft:SetTexture("LibBInterface", "Textures/PanelIntBorderLeft.png")
			self.borderFrame.borderRight:SetTexture("LibBInterface", "Textures/PanelIntBorderRight.png")
		else
			self.borderFrame.cornerTopLeft:SetTexture("LibBInterface", "Textures/PanelExtCornerTopLeft.png")
			self.borderFrame.cornerTopRight:SetTexture("LibBInterface", "Textures/PanelExtCornerTopRight.png")
			self.borderFrame.cornerBottomLeft:SetTexture("LibBInterface", "Textures/PanelExtCornerBottomLeft.png")
			self.borderFrame.cornerBottomRight:SetTexture("LibBInterface", "Textures/PanelExtCornerBottomRight.png")
			self.borderFrame.borderTop:SetTexture("LibBInterface", "Textures/PanelExtBorderTop.png")
			self.borderFrame.borderBottom:SetTexture("LibBInterface", "Textures/PanelExtBorderBottom.png")
			self.borderFrame.borderLeft:SetTexture("LibBInterface", "Textures/PanelExtBorderLeft.png")
			self.borderFrame.borderRight:SetTexture("LibBInterface", "Textures/PanelExtBorderRight.png")
		end
	end
end

function Library.LibBInterface.BPanel(name, parent)
	local bPanel = UI.CreateFrame("Frame", name, parent)

	BuildBorderFrame(bPanel)
	BuildContentFrame(bPanel)

	-- Public
	bPanel.SetInvertedBorder = SetInvertedBorder
	function bPanel:GetContent()
		return self.contentFrame
	end
	
	return bPanel
end