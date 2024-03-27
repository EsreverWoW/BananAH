-- ***************************************************************************************************************************************************
-- * ConfigFactory.lua                                                                                                                               *
-- ***************************************************************************************************************************************************
-- * Config frame factory                                                                                                                            *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.10 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local ROW_HEIGHT = 40

local BASE_CATEGORY = InternalInterface.Category.BASE_CATEGORY
local CDetail = InternalInterface.Category.Detail
local Dropdown = Yague.Dropdown
local MoneySelector = Yague.MoneySelector
local Panel = Yague.Panel
local Slider = Yague.Slider
local GetPriceModels = LibPGCEx.GetPriceModels
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local L = InternalInterface.Localization.L
local MCeil = math.ceil
local MLog10 = math.log10
local MMax = math.max
local TInsert = table.insert
local UICreateFrame = UI.CreateFrame
local ipairs = ipairs
local pairs = pairs
local type = type

local maxLevel = 0
local maxSiblingOrder = 0
local function PrebuildCategoryTree(category, level, siblingOrder)
	local detail = CDetail(category)
	if detail then
		maxLevel = MMax(level, maxLevel)
		maxSiblingOrder = MMax(siblingOrder, maxSiblingOrder)
		if detail.children then
			for childOrder, childCategory in ipairs(detail.children) do
				PrebuildCategoryTree(childCategory, level + 1, childOrder)
			end
		end
	end
end
PrebuildCategoryTree(BASE_CATEGORY, 1, 1)

local CategoryTree = {}
local digitsPerLevel = MCeil(MLog10(maxSiblingOrder))
local function BuildCategoryTree(category, level, siblingOrder)
	local detail = CDetail(category)
	if detail then
		CategoryTree[category] = { displayName = ("   "):rep(level - 1) .. detail.name, order = (CategoryTree[detail.parent] and CategoryTree[detail.parent].order or 0) + siblingOrder * 10 ^ ((maxLevel - level) * digitsPerLevel) }
		if detail.children then
			for childOrder, childCategory in ipairs(detail.children) do
				BuildCategoryTree(childCategory, level + 1, childOrder)
			end
		end		
	end
end
BuildCategoryTree(BASE_CATEGORY, 1, 1)

local ControlConstructors =
{
	integer = 
		function(name, parent, extraDescription)
			local control = Slider(name, parent)
			
			control:SetRange(extraDescription.minValue or 0, extraDescription.maxValue or 0)
			control:SetPosition(extraDescription.defaultValue)
			
			local function GetExtra()
				return (control:GetPosition())
			end
			
			local function SetExtra(extra)
				control:SetPosition(extra or extraDescription.defaultValue or 0)
			end
			
			return control, GetExtra, SetExtra
		end,
	money =
		function(name, parent, extraDescription)
			local control = MoneySelector(name, parent)
			
			control:SetHeight(30)
			control:SetValue(extraDescription.defaultValue or 0)
			
			local function GetExtra()
				return (control:GetValue())
			end
			
			local function SetExtra(extra)
				control:SetValue(extra or extraDescription.defaultValue or 0)
			end
			
			return control, GetExtra, SetExtra
		end,
	calling =
		function(name, parent, extraDescription)
			local control = Dropdown(name, parent)
			
			control:SetHeight(35)
			control:SetTextSelector("displayName")
			control:SetOrderSelector("order")
			control:SetValues({
				["nil"] = { displayName = L["General/CallingAll"], order = 1, },
				["warrior"] = { displayName = L["General/CallingWarrior"], order = 2, },
				["cleric"] = { displayName = L["General/CallingCleric"], order = 3, },
				["rogue"] = { displayName = L["General/CallingRogue"], order = 4, },
				["mage"] = { displayName = L["General/CallingMage"], order = 5, },
			})
			control:SetSelectedKey(extraDescription.defaultValue or "nil")
			
			local function GetExtra()
				local value = control:GetSelectedValue()
				return value and value ~= "nil" and value or nil
			end

			local function SetExtra(extra)
				control:SetSelectedKey(extra or extraDescription.defaultValue or "nil")
			end
			
			return control, GetExtra, SetExtra
		end,
	selectOne =
		function(name, parent, extraDescription)
			local control = Dropdown(name, parent)
			
			control:SetHeight(35)
			control:SetTextSelector(extraDescription.textSelector)
			control:SetOrderSelector(extraDescription.orderSelector)
			control:SetColorSelector(extraDescription.colorSelector)
			control:SetValues(extraDescription.values)
			if extraDescription.defaultValue and extraDescription.values and extraDescription.values[extraDescription.defaultValue] then
				control:SetSelectedKey(extraDescription.defaultValue)
			end
			
			local function GetExtra()
				return (control:GetSelectedValue())
			end
			
			local function SetExtra(extra)
				local key = extra or extraDescription.defaultValue
				if key and extraDescription.values and extraDescription.values[key] then
					control:SetSelectedKey(key)
				end
			end
			
			return control, GetExtra, SetExtra
		end,
	rarity =
		function(name, parent, extraDescription)
			local control = Dropdown(name, parent)
			
			control:SetHeight(35)
			control:SetTextSelector("displayName")
			control:SetOrderSelector("order")
			control:SetColorSelector(function(key) return { GetRarityColor(key) } end)
			control:SetValues({
				["sellable"] = { displayName = L["General/Rarity1"], order = 1, },
				[""] = { displayName = L["General/Rarity2"], order = 2, },
				["uncommon"] = { displayName = L["General/Rarity3"], order = 3, },
				["rare"] = { displayName = L["General/Rarity4"], order = 4, },
				["epic"] = { displayName = L["General/Rarity5"], order = 5, },
				["relic"] = { displayName = L["General/Rarity6"], order = 6, },
				["transcendent"] = { displayName = L["General/Rarity7"], order = 7, },
				["quest"] = { displayName = L["General/RarityQuest"], order = 8, },
			})			
			control:SetSelectedKey(extraDescription.defaultValue or "sellable")
			
			local function GetExtra()
				return (control:GetSelectedValue())
			end

			local function SetExtra(extra)
				control:SetSelectedKey(extra or extraDescription.defaultValue or "sellable")
			end
			
			return control, GetExtra, SetExtra
		end,
	category =
		function(name, parent, extraDescription)
			local control = Dropdown(name, parent)
			
			control:SetHeight(35)
			control:SetTextSelector("displayName")
			control:SetOrderSelector("order")
			control:SetValues(CategoryTree)
			control:SetSelectedKey(extraDescription.defaultValue or BASE_CATEGORY)
			
			local function GetExtra()
				return (control:GetSelectedValue())
			end

			local function SetExtra(extra)
				control:SetSelectedKey(extra or extraDescription.defaultValue or "")
			end
			
			return control, GetExtra, SetExtra
		end,
	boolean =
		function(name, parent, extraDescription)
			local control = UICreateFrame("RiftCheckbox", name, parent)
			
			local checked = extraDescription.defaultValue
			if checked == nil then checked = true end
			control:SetChecked(checked and true or false)
			
			local function GetExtra()
				return control:GetChecked()
			end
			
			local function SetExtra(extra)
				local checked = extra
				if checked == nil then checked = extraDescription.defaultValue end
				if checked == nil then checked = true end
				control:SetChecked(checked and true or false)
			end
			
			return control, GetExtra, SetExtra, true
		end,
	text =
		function(name, parent, extraDescription)
			local control = Panel(name, parent)
			local field = UICreateFrame("RiftTextfield", name .. ".Field", control:GetContent())
			
			control:SetHeight(30)
			control:SetInvertedBorder(true)
			control:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
			field:SetPoint("CENTERLEFT", control:GetContent(), "CENTERLEFT", 2, 0)
			field:SetPoint("CENTERRIGHT", control:GetContent(), "CENTERRIGHT", 2, 0)
			field:SetText(extraDescription.defaultValue or "")
			
			function control.Event:LeftClick()
				field:SetKeyFocus(true)
			end

			function field.Event:KeyFocusGain()
				local length = self:GetText():len()
				if length > 0 then
					self:SetSelection(0, length)
				end
			end			
			
			local function GetExtra()
				return field:GetText()
			end
			
			local function SetExtra(extra)
				field:SetText(extra or extraDescription.defaultValue or "")
			end
			
			return control, GetExtra, SetExtra			
		end,
	pricingModel =
		function(name, parent, extraDescription)
			local control = Dropdown(name, parent)
			
			local function ReloadPriceModels()
				local currentModel = control:GetSelectedValue()
				
				local models = GetPriceModels()
				local values = {}
				for modelID, modelName in pairs(models) do
					values[modelID] = { displayName = modelName }
				end
				control:SetValues(values)
			
				if currentModel and values[currentModel] then
					control:SetSelectedKey(currentModel)
				end
			end
			
			control:SetHeight(35)
			control:SetTextSelector("displayName")
			control:SetOrderSelector("displayName")
			ReloadPriceModels()
			
			local function GetExtra()
				return (control:GetSelectedValue())
			end

			local function SetExtra(extra)
				control:SetSelectedKey(extra or InternalInterface.AccountSettings.Scoring.ReferencePrice)
			end
			
			TInsert(Event.LibPGCEx.PriceModelRegistered, { ReloadPriceModels, addonID, addonID .. ".ReloadPriceModels" })
			TInsert(Event.LibPGCEx.PriceModelUnregistered, { ReloadPriceModels, addonID, addonID .. ".ReloadPriceModels" })
			
			return control, GetExtra, SetExtra
		end,
}

function InternalInterface.UI.BuildConfigFrame(name, parent, extraDescription)
	extraDescription = extraDescription or {}
	
	local layout = extraDescription.Layout
	local rows = layout and #layout or 0
	local columns = layout and layout.columns or 0
	
	if rows <= 0 then return nil end

	local frame = UICreateFrame("Frame", name, parent)
	
	local getters = {}
	local setters = {}
	
	local controls = {}
	local frameControls = {}	
	for column = 1, columns do
		local maxColumnTitleWidth = 0
		controls[column] = {}
		
		for row, rowData in ipairs(layout) do
			local valueID = rowData[column]
			local valueData = valueID and extraDescription[valueID] or nil
			
			local control = nil
			local dontAnchorToRight = nil
			
			if valueData then
				local columnTitle = UICreateFrame("Text", name .. "." .. valueID .. ".Title", frame)
				columnTitle:SetPoint("CENTERLEFT", frame, (column - 1) / columns, (row * 2 - 1) / rows / 2, 5, 0)
				columnTitle:SetText(valueData.name or "")
				columnTitle:SetFontSize(valueData.nameFontSize or 12)
				maxColumnTitleWidth = MMax(maxColumnTitleWidth, columnTitle:GetWidth())
				
				local controlName = name .. "." .. valueID .. ".Control"
				local valueType = valueData.value
				
				if ControlConstructors[valueType] then
					control, getters[valueID], setters[valueID], dontAnchorToRight = ControlConstructors[valueType](controlName, frame, valueData)
					frameControls[valueID] = control
				end
			else
				control = controls[column - 1] and controls[column - 1][row] or nil
			end
			controls[column][row] = control
				
			if control and not dontAnchorToRight then				
				control:SetPoint("CENTERRIGHT", frame, column / columns, (row * 2 - 1) / rows / 2, -5, 0)
			end
		end
		
		for row, control in pairs(controls[column]) do
			if not controls[column - 1] or not controls[column - 1][row] or controls[column - 1][row] ~= control then
				control:SetPoint("CENTERLEFT", frame, (column - 1) / columns, (row * 2 - 1) / rows / 2, maxColumnTitleWidth + 10, 0)
			end
		end
	end
	
	frame:SetHeight(rows * ROW_HEIGHT)
	
	function frame:GetExtra()
		local extra = {}
		for key, getter in pairs(getters) do
			extra[key] = getter()
		end
		return extra
	end
		
	function frame:SetExtra(extra)
		extra = extra or {}
		for key, setter in pairs(setters) do
			setter(extra[key])
		end
	end
	
	return frame, frameControls
end
