-- Public
local function GetMinWidth(self)
	self.minWidth = self.minWidth or 400
	return self.minWidth
end

local function GetMaxWidth(self)
	return self.maxWidth
end

local function GetMinHeight(self)
	self.minHeight = self.minHeight or 390
	return self.minHeight
end

local function GetMaxHeight(self)
	return self.maxHeight
end

local function SetMinWidth(self, val)
	self.minWidth = math.max(400, val)
	if self:GetWidth() < self.minWidth then
		self:SetWidth(self.minWidth)
	end
	return self.minWidth
end

local function SetMaxWidth(self, val)
	self.maxWidth = val
	if self.maxWidth and self:GetWidth() > self.maxWidth then
		self:SetWidth(self.maxWidth)
	end
	return self.maxWidth
end

local function SetMinHeight(self, val)
	self.minHeight = math.max(390, val)
	if self:GetHeight() < self.minHeight then
		self:SetHeight(self.minHeight)
	end
	return self.minHeight
end

local function SetMaxHeight(self, val)
	self.maxHeight = val
	if self.maxHeight and self:GetHeight() > self.maxHeight then
		self:SetHeight(self.maxHeight)
	end
	return self.maxHeight
end

local function GetCloseable(self)
	self.closeable = self.closeable or false
	return self.closeable
end

local function SetCloseable(self, closeable)
	if closeable then
		if not self.closeButton then
			local closeButton = UI.CreateFrame("RiftButton", self:GetName() .. "CloseButton", self)
			closeButton:SetSkin("close")
			closeButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -8, 15)
			function closeButton.Event:LeftPress()
				local parent = self:GetParent()
				parent:SetVisible(false)
				if parent.Event.Close then
					parent.Event.Close(parent)
				end			
			end
			self.closeButton = closeButton
		end
		self.closeButton:SetVisible(true)
	elseif self.closeButton then
		self.closeButton:SetVisible(false)
	end
	self.closeable = closeable
	return self.closeable
end

local function GetDraggable(self)
	self.draggable = self.draggable or false
	return self.draggable
end

local function SetDraggable(self, draggable)
	if draggable and not self.dragFrame then
		local dragFrame = UI.CreateFrame("Frame", self:GetName() .. "DragFrame", self)
		local left, top = self:GetTrimDimensions()
		dragFrame:SetAlpha(0)
		dragFrame:SetPoint("TOPLEFT", self, "TOPLEFT", left, 17)
		dragFrame:SetPoint("BOTTOMRIGHT", self,  "TOPRIGHT", -42, top - 17)
		function dragFrame.Event:LeftDown()
			local parent = self:GetParent()
			if self.dragInfo or not parent:GetDraggable() then return end
			local mouse = Inspect.Mouse()
			self.dragInfo = 
			{
				x = mouse.x, 
				y = mouse.y,
				left = parent:GetLeft(),
				top = parent:GetTop(),
				width = parent:GetWidth(),
				height = parent:GetHeight(),
			}
			parent:ClearAll()
			parent:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.dragInfo.left, self.dragInfo.top)
			parent:SetWidth(self.dragInfo.width)
			parent:SetHeight(self.dragInfo.height)
		end
		function dragFrame.Event:LeftUp()
			self.dragInfo = nil
		end
		function dragFrame.Event:LeftUpoutside()
			self.dragInfo = nil
		end
		function dragFrame.Event:MouseMove(x, y)
			if not self.dragInfo then return end
			local dx = x - self.dragInfo.x
			local dy = y - self.dragInfo.y
			self:GetParent():SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.dragInfo.left + dx, self.dragInfo.top + dy)
		end
		self.dragFrame = dragFrame
	end
	self.draggable = draggable
	return self.draggable
end

local function GetResizable(self)
	self.resizable = self.resizable or false
	return self.resizable
end

local function SetResizable(self, resizable)
	if resizable then
		local left, top, right, bottom = self:GetTrimDimensions()
		local function leftDown(self)
			local parent = self:GetParent()
			if self.resizeInfo or not parent:GetResizable() then return end
			local mouse = Inspect.Mouse()
			self.resizeInfo = 
			{
				x = mouse.x, 
				y = mouse.y,
				left = parent:GetLeft(),
				top = parent:GetTop(),
				width = parent:GetWidth(),
				height = parent:GetHeight(),
			}
			parent:ClearAll()
			parent:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.resizeInfo.left, self.resizeInfo.top)
			parent:SetWidth(self.resizeInfo.width)
			parent:SetHeight(self.resizeInfo.height)
		end
		local function leftUp(self)
			self.resizeInfo = nil
		end
		local function leftUpoutside(self)
			self.resizeInfo = nil
		end
		if not self.leftResizeFrame then
			local leftResizeFrame = UI.CreateFrame("Frame", self:GetName() .. "LeftResizeFrame", self)
			leftResizeFrame:SetAlpha(0)
			leftResizeFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 17)
			leftResizeFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", left, -bottom)
			leftResizeFrame.Event.LeftDown = leftDown
			leftResizeFrame.Event.LeftUp = leftUp
			leftResizeFrame.Event.LeftUpoutside = leftUpoutside
			function leftResizeFrame.Event:MouseMove(x, y)
				if not self.resizeInfo then return end
				local parent = self:GetParent()
				local dx = math.min(x - self.resizeInfo.x, self.resizeInfo.width - parent:GetMinWidth())
				if parent:GetMaxWidth() then
					dx = math.max(dx, self.resizeInfo.width - parent:GetMaxWidth())
				end
				parent:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.resizeInfo.left + dx, self.resizeInfo.top)
				parent:SetWidth(self.resizeInfo.width - dx)
			end
			self.lestResizeFrame = leftResizeFrame
		end
		if not self.rightResizeFrame then
			local rightResizeFrame = UI.CreateFrame("Frame", self:GetName() .. "RightResizeFrame", self)
			rightResizeFrame:SetAlpha(0)
			rightResizeFrame:SetPoint("TOPLEFT", self, "TOPRIGHT", -right, 17)
			rightResizeFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, -bottom)
			rightResizeFrame.Event.LeftDown = leftDown
			rightResizeFrame.Event.LeftUp = leftUp
			rightResizeFrame.Event.LeftUpoutside = leftUpoutside
			function rightResizeFrame.Event:MouseMove(x, y)
				if not self.resizeInfo then return end
				local parent = self:GetParent()
				local dx = math.max(x - self.resizeInfo.x, parent:GetMinWidth() - self.resizeInfo.width)
				if parent:GetMaxWidth() then
					dx = math.min(dx, parent:GetMaxWidth() - self.resizeInfo.width)
				end
				parent:SetWidth(self.resizeInfo.width + dx)
			end
			self.rightResizeFrame = rightResizeFrame
		end
		if not self.bottomResizeFrame then
			local bottomResizeFrame = UI.CreateFrame("Frame", self:GetName() .. "BottomResizeFrame", self)
			bottomResizeFrame:SetAlpha(0)
			bottomResizeFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", left, -bottom)
			bottomResizeFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -right, 0)
			bottomResizeFrame.Event.LeftDown = leftDown
			bottomResizeFrame.Event.LeftUp = leftUp
			bottomResizeFrame.Event.LeftUpoutside = leftUpoutside
			function bottomResizeFrame.Event:MouseMove(x, y)
				if not self.resizeInfo then return end
				local parent = self:GetParent()
				local dy = math.max(y - self.resizeInfo.y, parent:GetMinHeight() - self.resizeInfo.height)
				if parent:GetMaxHeight() then
					dy = math.min(dy, parent:GetMaxHeight() - self.resizeInfo.height)
				end
				parent:SetHeight(self.resizeInfo.height + dy)
			end
			self.bottomResizeFrame = bottomResizeFrame
		end
		if not self.bottomLeftResizeFrame then
			local bottomLeftResizeFrame = UI.CreateFrame("Frame", self:GetName() .. "BottomLeftResizeFrame", self)
			bottomLeftResizeFrame:SetAlpha(0)
			bottomLeftResizeFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -bottom)
			bottomLeftResizeFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", left, 0)
			bottomLeftResizeFrame.Event.LeftDown = leftDown
			bottomLeftResizeFrame.Event.LeftUp = leftUp
			bottomLeftResizeFrame.Event.LeftUpoutside = leftUpoutside
			function bottomLeftResizeFrame.Event:MouseMove(x, y)
				if not self.resizeInfo then return end
				local parent = self:GetParent()
				local dx = math.min(x - self.resizeInfo.x, self.resizeInfo.width - parent:GetMinWidth())
				local dy = math.max(y - self.resizeInfo.y, parent:GetMinHeight() - self.resizeInfo.height)
				if parent:GetMaxWidth() then
					dx = math.max(dx, self.resizeInfo.width - parent:GetMaxWidth())
				end
				if parent:GetMaxHeight() then
					dy = math.min(dy, parent:GetMaxHeight() - self.resizeInfo.height)
				end
				parent:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.resizeInfo.left + dx, self.resizeInfo.top)
				parent:SetWidth(self.resizeInfo.width - dx)
				parent:SetHeight(self.resizeInfo.height + dy)
			end
			self.bottomLeftResizeFrame = bottomLeftResizeFrame
		end
		if not self.bottomRightResizeFrame then
			local bottomRightResizeFrame = UI.CreateFrame("Frame", self:GetName() .. "BottomRightResizeFrame", self)
			bottomRightResizeFrame:SetAlpha(0)
			bottomRightResizeFrame:SetPoint("TOPLEFT", self, "BOTTOMRIGHT", -right, -bottom)
			bottomRightResizeFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
			bottomRightResizeFrame.Event.LeftDown = leftDown
			bottomRightResizeFrame.Event.LeftUp = leftUp
			bottomRightResizeFrame.Event.LeftUpoutside = leftUpoutside
			function bottomRightResizeFrame.Event:MouseMove(x, y)
				if not self.resizeInfo then return end
				local parent = self:GetParent()
				local dx = math.max(x - self.resizeInfo.x, parent:GetMinWidth() - self.resizeInfo.width)
				local dy = math.max(y - self.resizeInfo.y, parent:GetMinHeight() - self.resizeInfo.height)
				if parent:GetMaxWidth() then
					dx = math.min(dx, parent:GetMaxWidth() - self.resizeInfo.width)
				end
				if parent:GetMaxHeight() then
					dy = math.min(dy, parent:GetMaxHeight() - self.resizeInfo.height)
				end
				parent:SetWidth(self.resizeInfo.width + dx)
				parent:SetHeight(self.resizeInfo.height + dy)
			end
			self.bottomRightResizeFrame = bottomRightResizeFrame
		end
	end
	self.resizable = resizable
	return self.resizable
end

function Library.LibBInterface.BWindow(name, parent)
	local bWindow = UI.CreateFrame("RiftWindow", name, parent)

	bWindow.oldSetWidth = bWindow.SetWidth
	function bWindow:SetWidth(val)
		val = math.max(val, self:GetMinWidth())
		if self:GetMaxWidth() then
			val = math.min(val, self:GetMaxWidth())
		end
		self:oldSetWidth(val)
	end
	
	bWindow.oldSetHeight = bWindow.SetHeight
	function bWindow:SetHeight(val)
		val = math.max(val, self:GetMinHeight())
		if self:GetMaxHeight() then
			val = math.min(val, self:GetMaxHeight())
		end
		self:oldSetHeight(val)
	end
	
	bWindow.GetMinWidth = GetMinWidth
	bWindow.GetMaxWidth = GetMaxWidth
	bWindow.GetMinHeight = GetMinHeight
	bWindow.GetMaxHeight = GetMaxHeight
	bWindow.SetMinWidth = SetMinWidth
	bWindow.SetMaxWidth = SetMaxWidth
	bWindow.SetMinHeight = SetMinHeight
	bWindow.SetMaxHeight = SetMaxHeight
	
	bWindow.GetCloseable = GetCloseable
	bWindow.SetCloseable = SetCloseable

	bWindow.GetDraggable = GetDraggable
	bWindow.SetDraggable = SetDraggable

	bWindow.GetResizable = GetResizable
	bWindow.SetResizable = SetResizable
	
	Library.LibBInterface.BEventHandler(bWindow, { "Close" })

	return bWindow
end