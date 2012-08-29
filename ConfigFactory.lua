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

local Dropdown = Yague.Dropdown
local MoneySelector = Yague.MoneySelector
local Panel = Yague.Panel
local Slider = Yague.Slider
local GetPriceModels = LibPGCEx.GetPriceModels
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local L = InternalInterface.Localization.L
local MMax = math.max
local UICreateFrame = UI.CreateFrame
local ipairs = ipairs
local pairs = pairs
local type = type

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
				["transcendant"] = { displayName = L["General/Rarity7"], order = 7, },
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
			control:SetValues({
				[""] = { displayName = "All", order = 000000, }, -- LOCALIZE
				["armor"] = { displayName = "\t" .. "Armor", order = 010000, }, -- LOCALIZE
				["armor plate"] = { displayName = "\t\t" .. "Plate", order = 010100, }, -- LOCALIZE
				["armor plate head"] = { displayName = "\t\t\t" .. "Plate Head", order = 010101, }, -- LOCALIZE
				["armor plate shoulders"] = { displayName = "\t\t\t" .. "Plate Shoulder", order = 010102, }, -- LOCALIZE
				["armor plate chest"] = { displayName = "\t\t\t" .. "Plate Chest", order = 010103, }, -- LOCALIZE
				["armor plate hands"] = { displayName = "\t\t\t" .. "Plate Hands", order = 010104, }, -- LOCALIZE
				["armor plate waist"] = { displayName = "\t\t\t" .. "Plate Waist", order = 010105, }, -- LOCALIZE
				["armor plate legs"] = { displayName = "\t\t\t" .. "Plate Legs", order = 010106, }, -- LOCALIZE
				["armor plate feet"] = { displayName = "\t\t\t" .. "Plate Feet", order = 010107, }, -- LOCALIZE
				["armor chain"] = { displayName = "\t\t" .. "Chain", order = 010200, }, -- LOCALIZE
				["armor chain head"] = { displayName = "\t\t\t" .. "Chain Head", order = 010201, }, -- LOCALIZE
				["armor chain shoulders"] = { displayName = "\t\t\t" .. "Chain Shoulder", order = 010202, }, -- LOCALIZE
				["armor chain chest"] = { displayName = "\t\t\t" .. "Chain Chest", order = 010203, }, -- LOCALIZE
				["armor chain hands"] = { displayName = "\t\t\t" .. "Chain Hands", order = 010204, }, -- LOCALIZE
				["armor chain waist"] = { displayName = "\t\t\t" .. "Chain Waist", order = 010205, }, -- LOCALIZE
				["armor chain legs"] = { displayName = "\t\t\t" .. "Chain Legs", order = 010206, }, -- LOCALIZE
				["armor chain feet"] = { displayName = "\t\t\t" .. "Chain Feet", order = 010207, }, -- LOCALIZE
				["armor leather"] = { displayName = "\t\t" .. "Leather", order = 010300, }, -- LOCALIZE
				["armor leather head"] = { displayName = "\t\t\t" .. "Leather Head", order = 010301, }, -- LOCALIZE
				["armor leather shoulders"] = { displayName = "\t\t\t" .. "Leather Shoulder", order = 010302, }, -- LOCALIZE
				["armor leather chest"] = { displayName = "\t\t\t" .. "Leather Chest", order = 010303, }, -- LOCALIZE
				["armor leather hands"] = { displayName = "\t\t\t" .. "Leather Hands", order = 010304, }, -- LOCALIZE
				["armor leather waist"] = { displayName = "\t\t\t" .. "Leather Waist", order = 010305, }, -- LOCALIZE
				["armor leather legs"] = { displayName = "\t\t\t" .. "Leather Legs", order = 010306, }, -- LOCALIZE
				["armor leather feet"] = { displayName = "\t\t\t" .. "Leather Feet", order = 010307, }, -- LOCALIZE
				["armor cloth"] = { displayName = "\t\t" .. "Cloth", order = 010400, }, -- LOCALIZE
				["armor cloth head"] = { displayName = "\t\t\t" .. "Cloth Head", order = 010401, }, -- LOCALIZE
				["armor cloth shoulders"] = { displayName = "\t\t\t" .. "Cloth Shoulder", order = 010402, }, -- LOCALIZE
				["armor cloth chest"] = { displayName = "\t\t\t" .. "Cloth Chest", order = 010403, }, -- LOCALIZE
				["armor cloth hands"] = { displayName = "\t\t\t" .. "Cloth Hands", order = 010404, }, -- LOCALIZE
				["armor cloth waist"] = { displayName = "\t\t\t" .. "Cloth Waist", order = 010405, }, -- LOCALIZE
				["armor cloth legs"] = { displayName = "\t\t\t" .. "Cloth Legs", order = 010406, }, -- LOCALIZE
				["armor cloth feet"] = { displayName = "\t\t\t" .. "Cloth Feet", order = 010407, }, -- LOCALIZE
				["armor accessory"] = { displayName = "\t\t" .. "Accessories", order = 010500, }, -- LOCALIZE
				["armor accessory neck"] = { displayName = "\t\t\t" .. "Necklace", order = 010501, }, -- LOCALIZE
				["armor accessory ring"] = { displayName = "\t\t\t" .. "Ring", order = 010502, }, -- LOCALIZE
				["armor accessory trinket"] = { displayName = "\t\t\t" .. "Trinket", order = 010503, }, -- LOCALIZE
				["armor accessory seal"] = { displayName = "\t\t\t" .. "Seal", order = 010504, }, -- LOCALIZE
				["armor costume"] = { displayName = "\t\t" .. "Costume", order = 010600, }, -- LOCALIZE
				["weapon"] = { displayName = "\t" .. "Weapon", order = 020000, }, -- LOCALIZE
				["weapon onehand"] = { displayName = "\t\t" .. "One Handed", order = 020100, }, -- LOCALIZE
				["weapon onehand sword"] = { displayName = "\t\t\t" .. "Sword", order = 020101, }, -- LOCALIZE
				["weapon onehand axe"] = { displayName = "\t\t\t" .. "Axe", order = 020102, }, -- LOCALIZE
				["weapon onehand mace"] = { displayName = "\t\t\t" .. "Mace", order = 020103, }, -- LOCALIZE
				["weapon onehand dagger"] = { displayName = "\t\t\t" .. "Dagger", order = 020104, }, -- LOCALIZE
				["weapon twohand"] = { displayName = "\t\t" .. "Two Handed", order = 020200, }, -- LOCALIZE
				["weapon twohand sword"] = { displayName = "\t\t\t" .. "Sword", order = 020201, }, -- LOCALIZE
				["weapon twohand axe"] = { displayName = "\t\t\t" .. "Axe", order = 020202, }, -- LOCALIZE
				["weapon twohand mace"] = { displayName = "\t\t\t" .. "Mace", order = 020203, }, -- LOCALIZE
				["weapon twohand polearm"] = { displayName = "\t\t\t" .. "Polearm", order = 020204, }, -- LOCALIZE
				["weapon twohand staff"] = { displayName = "\t\t\t" .. "Staff", order = 020205, }, -- LOCALIZE
				["weapon ranged"] = { displayName = "\t\t" .. "Ranged", order = 020300, }, -- LOCALIZE
				["weapon ranged bow"] = { displayName = "\t\t\t" .. "Bows", order = 020301, }, -- LOCALIZE
				["weapon ranged gun"] = { displayName = "\t\t\t" .. "Guns", order = 020302, }, -- LOCALIZE
				["weapon ranged wand"] = { displayName = "\t\t\t" .. "Wands", order = 020303, }, -- LOCALIZE
				["weapon totem"] = { displayName = "\t\t" .. "Totem", order = 020400, }, -- LOCALIZE
				["weapon shield"] = { displayName = "\t\t" .. "Shield", order = 020500, }, -- LOCALIZE
				["planar"] = { displayName = "\t" .. "Planar Items", order = 030000, }, -- LOCALIZE
				["planar lesser"] = { displayName = "\t\t" .. "Lesser Essence", order = 030100, }, -- LOCALIZE
				["planar greater"] = { displayName = "\t\t" .. "Greater Essence", order = 030200, }, -- LOCALIZE
				["consumable"] = { displayName = "\t" .. "Consumables", order = 040000, }, -- LOCALIZE
				["consumable food"] = { displayName = "\t\t" .. "Food", order = 040100, }, -- LOCALIZE
				["consumable drink"] = { displayName = "\t\t" .. "Drink", order = 040200, }, -- LOCALIZE
				["consumable potion"] = { displayName = "\t\t" .. "Potion", order = 040300, }, -- LOCALIZE
				["consumable scroll"] = { displayName = "\t\t" .. "Scroll", order = 040400, }, -- LOCALIZE
				["consumable enchantment"] = { displayName = "\t\t" .. "Item Enchantment", order = 040500, }, -- LOCALIZE
				["consumable consumable"] = { displayName = "\t\t" .. "Rift Consumable", order = 040600, }, -- LOCALIZE
				["container"] = { displayName = "\t" .. "Containers", order = 050000, }, -- LOCALIZE
				["crafting"] = { displayName = "\t" .. "Crafting", order = 060000, }, -- LOCALIZE
				["crafting recipe"] = { displayName = "\t\t" .. "Recipes", order = 060100, }, -- LOCALIZE
				["crafting recipe alchemy"] = { displayName = "\t\t\t" .. "Apothecary", order = 060101, }, -- LOCALIZE
				["crafting recipe armorsmith"] = { displayName = "\t\t\t" .. "Armorsmith", order = 060102, }, -- LOCALIZE
				["crafting recipe artificer"] = { displayName = "\t\t\t" .. "Artificer", order = 060103, }, -- LOCALIZE
				["crafting recipe butchering"] = { displayName = "\t\t\t" .. "Butchering", order = 060104, }, -- LOCALIZE
				["crafting recipe foraging"] = { displayName = "\t\t\t" .. "Foraging", order = 060105, }, -- LOCALIZE
				["crafting recipe weaponsmith"] = { displayName = "\t\t\t" .. "Weaponsmith", order = 060106, }, -- LOCALIZE
				["crafting recipe outfitter"] = { displayName = "\t\t\t" .. "Outfitter", order = 060107, }, -- LOCALIZE
				["crafting recipe mining"] = { displayName = "\t\t\t" .. "Mining", order = 060108, }, -- LOCALIZE
				["crafting recipe runecrafting"] = { displayName = "\t\t\t" .. "Runecrafting", order = 060109, }, -- LOCALIZE
				["crafting recipe fishing"] = { displayName = "\t\t\t" .. "Fishing", order = 060110, }, -- LOCALIZE
				["crafting recipe survival"] = { displayName = "\t\t\t" .. "Survival", order = 060111, }, -- LOCALIZE
				["crafting material"] = { displayName = "\t\t" .. "Materials", order = 060200, }, -- LOCALIZE
				["crafting material metal"] = { displayName = "\t\t\t" .. "Metal", order = 060201, }, -- LOCALIZE
				["crafting material gem"] = { displayName = "\t\t\t" .. "Gems", order = 060202, }, -- LOCALIZE
				["crafting material wood"] = { displayName = "\t\t\t" .. "Wood", order = 060203, }, -- LOCALIZE
				["crafting material plant"] = { displayName = "\t\t\t" .. "Plants", order = 060204, }, -- LOCALIZE
				["crafting material hide"] = { displayName = "\t\t\t" .. "Hide", order = 060205, }, -- LOCALIZE
				["crafting material meat"] = { displayName = "\t\t\t" .. "Meat", order = 060206, }, -- LOCALIZE
				["crafting material cloth"] = { displayName = "\t\t\t" .. "Cloth", order = 060207, }, -- LOCALIZE
				["crafting material component"] = { displayName = "\t\t\t" .. "Rune Components", order = 060208, }, -- LOCALIZE
				["crafting material fish"] = { displayName = "\t\t\t" .. "Fish", order = 060209, }, -- LOCALIZE
				["crafting ingredient"] = { displayName = "\t\t" .. "Ingredients", order = 060300, }, -- LOCALIZE
				["crafting ingredient reagent"] = { displayName = "\t\t\t" .. "Reagents", order = 060301, }, -- LOCALIZE
				["crafting ingredient drop"] = { displayName = "\t\t\t" .. "Drops", order = 060302, }, -- LOCALIZE
				["crafting ingredient rift"] = { displayName = "\t\t\t" .. "Rifts", order = 060303, }, -- LOCALIZE
				["crafting augment"] = { displayName = "\t\t" .. "Augments", order = 060400, }, -- LOCALIZE
				["misc"] = { displayName = "\t" .. "Misc", order = 070000, }, -- LOCALIZE
				["misc quest"] = { displayName = "\t\t" .. "Quest", order = 070100, }, -- LOCALIZE
				["misc mount"] = { displayName = "\t\t" .. "Mounts", order = 070200, }, -- LOCALIZE
				["misc pet"] = { displayName = "\t\t" .. "Pets", order = 070300, }, -- LOCALIZE
				["misc collectible"] = { displayName = "\t\t" .. "Collectibles", order = 070400, }, -- LOCALIZE
				["misc other"] = { displayName = "\t\t" .. "Other", order = 070500, }, -- LOCALIZE
				["misc survival misc"] = { displayName = "\t\t" .. "Survival", order = 070600, }, -- LOCALIZE
				["misc fishing misc"] = { displayName = "\t\t" .. "Fishing", order = 070700, }, -- LOCALIZE
			})			
			control:SetSelectedKey(extraDescription.defaultValue or "")
			
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
			
			local models = GetPriceModels()
			local values = {}
			for modelID, modelName in pairs(models) do
				values[modelID] = { displayName = modelName }
			end
			
			control:SetHeight(35)
			control:SetTextSelector("displayName")
			control:SetOrderSelector("displayName")
			control:SetValues(values)			
			
			local function GetExtra()
				return (control:GetSelectedValue())
			end

			local function SetExtra(extra)
				control:SetSelectedKey(extra or InternalInterface.AccountSettings.Scoring.ReferencePrice)
			end
			
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
				maxColumnTitleWidth = MMax(maxColumnTitleWidth, columnTitle:GetWidth())
				
				local controlName = name .. "." .. valueID .. ".Control"
				local valueType = valueData.value
				
				if ControlConstructors[valueType] then
					control, getters[valueID], setters[valueID], dontAnchorToRight = ControlConstructors[valueType](controlName, frame, valueData)
				end
			else
				control = controls[column - 1][row]
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
	
	return frame
end
