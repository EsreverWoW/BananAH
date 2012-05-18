-- Constants
local HEADER_FRAME_HEIGHT = 26
local HEADER_FRAME_HORIZONTAL_MARGIN = 2
local HEADER_FRAME_VERTICAL_MARGIN = 2
local HEADER_FONT_SIZE = 13
local HEADER_SORT_GLYPH_WIDTH = 12
local HEADER_SORT_OUT_COLOR = { 1, 1, 1, 1 }
local HEADER_SORT_IN_COLOR = { 0.5, 0.5, 0.5, 1 }
local HEADER_SORT_SHADOW_SELECTED_COLOR = { 0.25, 0.25, 0, 0.25 }
local HEADER_SORT_SHADOW_UNSELECTED_COLOR = { 0, 0, 0, 0.25}

local VERTICAL_SCROLLBAR_WIDTH = 20
local VERTICAL_SCROLLBAR_HORIZONTAL_MARGIN = 2

local ROW_DEFAULT_HEIGHT = 20
local ROW_DEFAULT_MARGIN = 0

-- Renderers
local renderers = {}

function Library.LibBInterface.RegisterGridRenderer(name, constructor)
	if type(constructor) ~= "function" then return false end
	renderers[name] = constructor
end

---- Text Renderer
-- Extra avalaible:
--  * Alignment
--   + left: Aligns text to left (default)
--   + center: Aligns text to center
--   + right: Aligns text to right
--  * Formatter
--   + none: Doesn't apply any format to the value (default)
--   + date: Formats the value as a date (using "%a %X")
--   + function
--  * Color
--   + {r, g, b, a} -- Color to use
--  * FontSize
--   + fontSize
local function TextRenderer(name, parent)
	local cell = UI.CreateFrame("Frame", name, parent)
	local textCell = UI.CreateFrame("Text", name .. ".Text", cell)
	
	function textCell:SetValue(key, value, width, extra)
		-- Apply Formatter
		local text = ""
		if extra and extra.Formatter == "date" and type(value) == "number" then
			text = os.date("%a %X", value)
		elseif extra and type(extra.Formatter) == "function" then
			text = extra.Formatter(value)
		else
			text = tostring(value)
		end
		self:SetText(text)
		
		if extra and type(extra.FontSize) == "number" then
			self:SetFontSize(extra.FontSize)
		end
		
		-- Apply alignment
		local offset = 0
		if extra and extra.Alignment == "center" then
			offset = offset + (width - self:GetWidth()) / 2
		elseif extra and extra.Alignment == "right" then
			offset = offset + width - self:GetWidth()
		end
		self:ClearAll()
		self:SetPoint("CENTERLEFT", cell, "CENTERLEFT", offset, 0)
		
		-- Apply Color
		if extra and type(extra.Color) == "table" then
			self:SetFontColor(unpack(extra.Color))
		elseif extra and type(extra.Color) == "function" then
			self:SetFontColor(unpack(extra.Color(value)))
		end
	end
	
	function cell:SetValue(key, value, width, extra) textCell:SetValue(key, value, width, extra) end
	
	return cell
end
Library.LibBInterface.RegisterGridRenderer("Text", TextRenderer)

-- Private
local function ResetLayout(self)
	local paddingLeft = self.paddingLeft or 0
	local paddingTop = self.paddingTop or 0
	local paddingRight = self.paddingRight or 0
	local paddingBottom = self.paddingBottom or 0

	local contentFrame = self.externalPanel:GetContent()
	local headerFrame = self.headerFrame
	local verticalScrollBar = self.verticalScrollBar
	local internalPanel = self.internalPanel
	
	-- Internal Panel
	local internalPanelPaddingTop = paddingTop + (headerFrame:GetVisible() and HEADER_FRAME_HEIGHT or 0)
	local internalPanelPaddingRight = paddingRight + (verticalScrollBar:GetVisible() and VERTICAL_SCROLLBAR_WIDTH or 0)
	internalPanel:ClearAll()
	internalPanel:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", paddingLeft, internalPanelPaddingTop)
	internalPanel:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -internalPanelPaddingRight, -paddingBottom)
	
	-- Header Frame
	headerFrame:ClearAll()
	headerFrame:SetPoint("TOPLEFT", internalPanel, "TOPLEFT", HEADER_FRAME_HORIZONTAL_MARGIN, HEADER_FRAME_VERTICAL_MARGIN - HEADER_FRAME_HEIGHT)
	headerFrame:SetPoint("BOTTOMRIGHT", internalPanel, "TOPRIGHT", -HEADER_FRAME_HORIZONTAL_MARGIN, -HEADER_FRAME_VERTICAL_MARGIN)
	
	-- Vertical ScrollBar
	verticalScrollBar:ClearAll()
	verticalScrollBar:SetPoint("TOPLEFT", internalPanel, "TOPRIGHT", VERTICAL_SCROLLBAR_HORIZONTAL_MARGIN, 0)
	verticalScrollBar:SetPoint("BOTTOMRIGHT", internalPanel, "BOTTOMRIGHT", VERTICAL_SCROLLBAR_WIDTH - VERTICAL_SCROLLBAR_HORIZONTAL_MARGIN, 0)
end

local function SetRowContent(self, row, key, value)
	if not key or not value then
		row:SetVisible(false)
		return
	end
	row:SetVisible(true)
	
	self.columns = self.columns or {}
	row.cells = row.cells or {}
	local filledWidth = 0
	for columnIndex, columnData in ipairs(self.columns) do
		local cell = row.cells[columnIndex]
		if not cell then
			local rendererConstructor = type(columnData.renderer) == "function" and columnData.renderer or renderers[columnData.renderer] or renderers["Text"]
			cell = rendererConstructor(row:GetName() .. ".Cells." .. columnIndex, row)
			table.insert(row.cells, cell)
		end
		
		cell:ClearAll()
		cell:SetPoint("TOPLEFT", row, "TOPLEFT", filledWidth, 0)
		cell:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", filledWidth, 0)
		
		local binding = columnData.binding
		local extra = columnData.extra
		cell:SetValue(key, not binding and value or value[binding], columnData.size, extra)
		filledWidth = filledWidth + columnData.size
	end
end

local function ApplyOrderAndFilter(self)
	self.data = self.data or {}
	self.lastSelectedIndex = self.lastSelectedIndex or 0

	-- Update header appearance according to the ordering applied
	if self.orderColumn then
		local headerFrame = self.headerFrame
		headerFrame.headers = headerFrame.headers or {}
		local headers = headerFrame.headers
		for index, header in ipairs(headers) do
			header:SetShadowColor(unpack(index == self.orderColumn and HEADER_SORT_SHADOW_SELECTED_COLOR or HEADER_SORT_SHADOW_UNSELECTED_COLOR))
			header.glyph:SetVisible(index == self.orderColumn)
			header.glyph:SetTexture("LibBInterface", self.orderDirection > 0 and "Textures/SortedAscendingGlyph.png" or "Textures/SortedDescendingGlyph.png")
		end
	end
	
	-- Apply the filter
	local filteredData = {}
	local orderLookup = {}
	for key, value in pairs(self.data) do
		if not self.filterFunction or self.filterFunction(key, value) then
			filteredData[key] = value
			table.insert(orderLookup, key)
		end
	end
	
	-- Apply the sorting
	if self.orderColumn then
		local orderFunction = self.columns[self.orderColumn].orderable
		if type(orderFunction) ~= "function" then
			orderFunction = function(a, b, direction)
				if direction > 0 then
					return (a or 0) < (b or 0)
				else
					return (b or 0) < (a or 0)
				end
			end
		end
		local binding = self.columns[self.orderColumn].binding
		table.sort(orderLookup, function(keyA, keyB) return orderFunction(not binding and keyA or filteredData[keyA][binding], not binding and keyB or filteredData[keyB][binding], self.orderDirection) end)
	end
	
	-- Selection stuff
	local newSelectedKey = nil
	local newSelectedIndex = 0
	for index, key in ipairs(orderLookup) do 
		if key == self.lastSelectedKey then 
			newSelectedIndex = index
			newSelectedKey = key
		end 
	end
	if newSelectedIndex <= 0 then
		newSelectedIndex = math.min(self.lastSelectedIndex, #orderLookup)
		if newSelectedIndex <= 0 and #orderLookup > 0 then newSelectedIndex = 1 end
		if newSelectedIndex > 0 then newSelectedKey = orderLookup[newSelectedIndex] end
	end
	if newSelectedKey ~= self.lastSelectedKey then
		self.lastSelectedKey = newSelectedKey
		if self.Event.SelectionChanged then
			self.Event.SelectionChanged(self, newSelectedKey, newSelectedKey and filteredData[newSelectedKey] or nil)
		end
	end
	self.lastSelectedIndex = newSelectedIndex
	
	-- Recalc scrollbar range and position
	local maxOffset = math.max(0, #orderLookup - self.lastNumRowsDisplayable + 1)
	local rowOffset = math.min(math.floor(self.verticalScrollBar:GetPosition()), maxOffset)
	if maxOffset > 0 then
		self.verticalScrollBar:SetEnabled(true)
		self.verticalScrollBar:SetRange(0, maxOffset)
		self.verticalScrollBar:SetPosition(rowOffset)
	else
		self.verticalScrollBar:SetEnabled(false)
		self.verticalScrollBar:SetRange(0, 1)
		self.verticalScrollBar:SetPosition(0)
	end

	-- Show the proper data
	for rowIndex, row in ipairs(self.rows) do
		local key = orderLookup[rowIndex + rowOffset]
		local value = key and filteredData[key] or nil
		SetRowContent(self, row, key, value)
		row.dataKey = key
		row.dataValue = value
		row.dataIndex = rowIndex + rowOffset
		if key == self.lastSelectedKey then
			if self.selectedRowBackgroundColor then
				row:SetBackgroundColor(unpack(self.selectedRowBackgroundColor))
			else
				row:SetBackgroundColor(0, 0, 0, 0)
			end
		else
			if self.unselectedRowBackgroundColor then
				row:SetBackgroundColor(unpack(self.unselectedRowBackgroundColor))
			else
				row:SetBackgroundColor(0, 0, 0, 0)
			end
		end
	end
end

local function ResetRows(self)
	self.rows = self.rows or {}
	
	local internalPanelContent = self.internalPanel:GetContent()
	local rowHeight = self:GetRowHeight()
	local rowMargin = self:GetRowMargin()
	local numRowsDisplayable = math.max(math.ceil(internalPanelContent:GetHeight() / rowHeight), 0)
	
	for newIndex = #self.rows + 1, numRowsDisplayable do
		local newRow = UI.CreateFrame("Frame", self:GetName() .. ".Rows." .. newIndex, internalPanelContent)
		function newRow.Event.LeftClick(row)
			if self.lastSelectedKey ~= row.dataKey then
				self.lastSelectedKey = nil
				self.lastSelectedIndex = row.dataIndex
				ApplyOrderAndFilter(self)
			end
		end
		table.insert(self.rows, newRow)
	end
	
	for rowIndex, row in ipairs(self.rows) do
		row:SetVisible(rowIndex <= numRowsDisplayable)
		row:ClearAll()
		row:SetPoint("TOPLEFT", internalPanelContent, "TOPLEFT", rowMargin, (rowIndex - 1) * rowHeight + rowMargin)
		row:SetPoint("BOTTOMRIGHT", internalPanelContent, "TOPRIGHT", -rowMargin, rowIndex * rowHeight - rowMargin)
	end

	self.lastNumRowsDisplayable = numRowsDisplayable
	ApplyOrderAndFilter(self)
end

local function HeaderMouseIn(self)
	self:SetFontColor(unpack(HEADER_SORT_IN_COLOR))
end

local function HeaderMouseOut(self)
	self:SetFontColor(unpack(HEADER_SORT_OUT_COLOR))
end

-- Public
local function GetPadding(self)
	self.paddingLeft = self.paddingLeft or 0
	self.paddingTop = self.paddingTop or 0
	self.paddingRight = self.paddingRight or 0
	self.paddingBottom = self.paddingBottom or 0
	
	return self.paddingLeft, self.paddingTop, self.paddingRight, self.paddingBottom
end

local function SetPadding(self, left, top, right, bottom)
	self.paddingLeft = math.max(left or 0, self.paddingLeft or 0)
	self.paddingTop = math.max(top or 0, self.paddingTop or 0)
	self.paddingRight = math.max(right or 0, self.paddingRight or 0)
	self.paddingBottom = math.max(bottom or 0, self.paddingBottom or 0)
	ResetLayout(self)
end

local function GetHeadersVisible(self)
	return self.headerFrame:GetVisible()
end

local function SetHeadersVisible(self, visible)
	if type(visible) ~= "boolean" then visible = false end
	self.headerFrame:SetVisible(visible)
	ResetLayout(self)
end

local function GetFilteringFunction(self)
	return self.filterFunction
end

local function SetFilteringFunction(self, func)
	if type(func) ~= "function" then func = nil end
	self.filterFunction = func
end

local function AddColumn(self, title, size, renderer, orderable, binding, extra)
	self.columns = self.columns or {}

	local column = { size = size, orderable = orderable, binding = binding, renderer = renderer, extra = extra }
	table.insert(self.columns, column)
	
	local headerFrame = self.headerFrame
	headerFrame.headers = headerFrame.headers or {}
	local headers = headerFrame.headers
	
	local filledWidth = 0
	for _, header in ipairs(headers) do
		filledWidth = filledWidth + header.size
	end
	
	local newHeader = Library.LibBInterface.BShadowedText(headerFrame:GetName() .. "." .. (#headers + 1), headerFrame)
	newHeader:SetText(title)
	newHeader:SetFontSize(HEADER_FONT_SIZE)
	newHeader:SetShadowOffset(2, 2)
	newHeader:SetFontColor(unpack(HEADER_SORT_OUT_COLOR))
	newHeader:SetShadowColor(unpack(HEADER_SORT_SHADOW_UNSELECTED_COLOR))
	newHeader:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", filledWidth + (size - (orderable and HEADER_SORT_GLYPH_WIDTH or 0) - newHeader:GetWidth()) / 2, 0)
	newHeader:SetPoint("BOTTOMLEFT", headerFrame, "BOTTOMLEFT", filledWidth + (size - (orderable and HEADER_SORT_GLYPH_WIDTH or 0) - newHeader:GetWidth()) / 2, 0)
	local headerGlyph = UI.CreateFrame("Texture", newHeader:GetName() .. ".Glyph", headerFrame)
	headerGlyph:SetPoint("CENTERLEFT", headerFrame, "CENTERLEFT", filledWidth + size - HEADER_SORT_GLYPH_WIDTH, 0)
	headerGlyph:SetPoint("CENTERRIGHT", headerFrame, "CENTERLEFT", filledWidth + size, 0)
	headerGlyph:SetVisible(false)
	newHeader.glyph = headerGlyph
	
	newHeader.index = #self.columns
	newHeader.size = size
	
	if orderable then
		newHeader.Event.MouseIn = HeaderMouseIn
		newHeader.Event.MouseOut = HeaderMouseOut
		function newHeader.Event.LeftClick(newHeader)
			if self.orderColumn == newHeader.index then
				self.orderDirection = -self.orderDirection
			else
				self.orderColumn = newHeader.index
				self.orderDirection = 1
			end
			ApplyOrderAndFilter(self)
		end
	end
	table.insert(headers, newHeader)
	
	if not self.orderColumn and orderable then 
		self.orderColumn = newHeader.index
		self.orderDirection = 1
		ApplyOrderAndFilter(self)
	end
	
	return newHeader
end

local function GetRowHeight(self)
	self.rowHeight = self.rowHeight or ROW_DEFAULT_HEIGHT
	return self.rowHeight
end

local function SetRowHeight(self, height)
	self.rowHeight = math.max(height, 0)
	self.rowMargin = math.min(math.max(self.rowMargin or ROW_DEFAULT_MARGIN, 0), math.floor(self.rowHeight / 2))
	ResetRows(self)
	return self.rowHeight
end

local function GetRowMargin(self)
	self.rowMargin = self.rowMargin or ROW_DEFAULT_MARGIN
	return self.rowMargin
end

local function SetRowMargin(self, margin)
	self.rowMargin = math.min(math.max(margin, 0), math.floor(self:GetRowHeight() / 2))
	ResetRows(self)
	return self.rowMargin
end

local function GetSelectedRowBackgroundColor(self)
	self.selectedRowBackgroundColor = self.selectedRowBackgroundColor or { 0, 0, 0, 0 }
	return unpack(self.selectedRowBackgroundColor)
end

local function SetSelectedRowBackgroundColor(self, r, g, b, a)
	self.selectedRowBackgroundColor = { r, g, b, a }
	ApplyOrderAndFilter(self)
	return unpack(self.selectedRowBackgroundColor)
end

local function GetUnselectedRowBackgroundColor(self)
	self.unselectedRowBackgroundColor = self.unselectedRowBackgroundColor or { 0, 0, 0, 0 }
	return unpack(self.unselectedRowBackgroundColor)
end

local function SetUnselectedRowBackgroundColor(self, r, g, b, a)
	self.unselectedRowBackgroundColor = { r, g, b, a }
	ApplyOrderAndFilter(self)
	return unpack(self.unselectedRowBackgroundColor)
end

local function GetData(self)
	self.data = self.data or {}
	return self.data
end

local function SetData(self, data)
	self.data = data
	ApplyOrderAndFilter(self)
	return self.data
end

local function GetSelectedData(self)
	local selectedValue = nil
	if self.lastSelectedKey then
		selectedValue = self.data[self.lastSelectedKey]
	end
	return self.lastSelectedKey, selectedValue
end

-- Constructor
function Library.LibBInterface.BDataGrid(name, parent)
	local bDataGrid = UI.CreateFrame("Frame", name, parent)
	
	local externalPanel = Library.LibBInterface.BPanel(bDataGrid:GetName() .. ".ExternalPanel", bDataGrid)
	externalPanel:SetAllPoints()
	bDataGrid.externalPanel = externalPanel

	local headerFrame = UI.CreateFrame("Mask", bDataGrid:GetName() .. ".HeaderFrame", externalPanel:GetContent())
	headerFrame:SetVisible(false)
	bDataGrid.headerFrame = headerFrame
	
	local verticalScrollBar = UI.CreateFrame("RiftScrollbar", bDataGrid:GetName() .. ".VerticalScrollBar", externalPanel:GetContent())
	function verticalScrollBar.Event:ScrollbarChange()
		ApplyOrderAndFilter(bDataGrid)
	end
	bDataGrid.verticalScrollBar = verticalScrollBar
	
	local internalPanel = Library.LibBInterface.BPanel(bDataGrid:GetName() .. ".InternalPanel", externalPanel:GetContent())
	internalPanel:SetInvertedBorder(true)
	bDataGrid.internalPanel = internalPanel

	local internalPanelContent = internalPanel:GetContent()
	function internalPanelContent.Event:Size()
		if not self.mw or not self.mh or self.mw < self:GetWidth() or self.mh < self:GetHeight() then
			self.mw = math.max(self.mw or 0, self:GetWidth())
			self.mh = math.max(self.mh or 0, self:GetHeight())
			ResetRows(bDataGrid)
		end
	end
	function internalPanelContent.Event:WheelForward()
		local minRange = verticalScrollBar:GetRange()
		verticalScrollBar:SetPosition(math.max(verticalScrollBar:GetPosition() - 1, minRange))
	end
	function internalPanelContent.Event:WheelBack()
		local _, maxRange = verticalScrollBar:GetRange()
		verticalScrollBar:SetPosition(math.min(verticalScrollBar:GetPosition() + 1, maxRange))
	end		
	
	-- Public
	bDataGrid.GetPadding = GetPadding
	bDataGrid.SetPadding = SetPadding
	bDataGrid.GetHeadersVisible = GetHeadersVisible
	bDataGrid.SetHeadersVisible = SetHeadersVisible
	bDataGrid.GetFilteringFunction = GetFilteringFunction
	bDataGrid.SetFilteringFunction = SetFilteringFunction
	bDataGrid.AddColumn = AddColumn
	bDataGrid.GetRowHeight = GetRowHeight
	bDataGrid.SetRowHeight = SetRowHeight
	bDataGrid.GetRowMargin = GetRowMargin
	bDataGrid.SetRowMargin = SetRowMargin
	bDataGrid.GetSelectedRowBackgroundColor = GetSelectedRowBackgroundColor
	bDataGrid.SetSelectedRowBackgroundColor = SetSelectedRowBackgroundColor
	bDataGrid.GetUnselectedRowBackgroundColor = GetUnselectedRowBackgroundColor
	bDataGrid.SetUnselectedRowBackgroundColor = SetUnselectedRowBackgroundColor
	bDataGrid.GetData = GetData
	bDataGrid.SetData = SetData
	bDataGrid.GetSelectedData = GetSelectedData
	function bDataGrid.ForceUpdate()
		ApplyOrderAndFilter(bDataGrid)	
	end
	Library.LibBInterface.BEventHandler(bDataGrid, { "SelectionChanged" })
	
	-- Late Initialization
	ResetLayout(bDataGrid)
	
	return bDataGrid
end