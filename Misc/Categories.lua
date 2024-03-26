-- ***************************************************************************************************************************************************
-- * Misc/Categories.lua                                                                                                                             *
-- ***************************************************************************************************************************************************
-- * Auxiliary functions to get Item Categories info                                                                                                 *
-- ***************************************************************************************************************************************************
-- * 0.4.16 / 2014.03.10 / Baanano: Added artifacts category                                                                                         *
-- * 0.4.15 / 2014.02.18 / Baanano: Added dream weaver category                                                                                      *
-- * 0.4.4  / 2012.10.23 / Baanano: First version                                                                                                    *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local CopyTableRecursive = InternalInterface.Utility.CopyTableRecursive

local BASE_CATEGORY = ""
local CATEGORIES =
{
	[""] =                                     { name = "All",                  parent = nil,                     children = { "armor", "weapon", "planar", "consumable", "container", "crafting", "misc", "dimension", "artifacts", }, }, -- LOCALIZE
	  ["armor"] =                              { name = "Armor",                parent = "",                      children = { "armor plate", "armor chain", "armor leather", "armor cloth", "armor accessory", "armor costume", "armor cape", }, }, -- LOCALIZE
	    ["armor plate"] =                      { name = "Plate",                parent = "armor",                 children = { "armor plate head", "armor plate shoulders", "armor plate chest", "armor plate hands", "armor plate waist", "armor plate legs", "armor plate feet", }, }, -- LOCALIZE
	      ["armor plate head"] =               { name = "Plate Head",           parent = "armor plate",           children = nil, }, -- LOCALIZE
	      ["armor plate shoulders"] =          { name = "Plate Shoulder",       parent = "armor plate",           children = nil, }, -- LOCALIZE
	      ["armor plate chest"] =              { name = "Plate Chest",          parent = "armor plate",           children = nil, }, -- LOCALIZE
	      ["armor plate hands"] =              { name = "Plate Hands",          parent = "armor plate",           children = nil, }, -- LOCALIZE
	      ["armor plate waist"] =              { name = "Plate Waist",          parent = "armor plate",           children = nil, }, -- LOCALIZE
	      ["armor plate legs"] =               { name = "Plate Legs",           parent = "armor plate",           children = nil, }, -- LOCALIZE
	      ["armor plate feet"] =               { name = "Plate Feet",           parent = "armor plate",           children = nil, }, -- LOCALIZE
	    ["armor chain"] =                      { name = "Chain",                parent = "armor",                 children = { "armor chain head", "armor chain shoulders", "armor chain chest", "armor chain hands", "armor chain waist", "armor chain legs", "armor chain feet", }, }, -- LOCALIZE
	      ["armor chain head"] =               { name = "Chain Head",           parent = "armor chain",           children = nil, }, -- LOCALIZE
	      ["armor chain shoulders"] =          { name = "Chain Shoulder",       parent = "armor chain",           children = nil, }, -- LOCALIZE
	      ["armor chain chest"] =              { name = "Chain Chest",          parent = "armor chain",           children = nil, }, -- LOCALIZE
	      ["armor chain hands"] =              { name = "Chain Hands",          parent = "armor chain",           children = nil, }, -- LOCALIZE
	      ["armor chain waist"] =              { name = "Chain Waist",          parent = "armor chain",           children = nil, }, -- LOCALIZE
	      ["armor chain legs"] =               { name = "Chain Legs",           parent = "armor chain",           children = nil, }, -- LOCALIZE
	      ["armor chain feet"] =               { name = "Chain Feet",           parent = "armor chain",           children = nil, }, -- LOCALIZE
	    ["armor leather"] =                    { name = "Leather",              parent = "armor",                 children = { "armor leather head", "armor leather shoulders", "armor leather chest", "armor leather hands", "armor leather waist", "armor leather legs", "armor leather feet", }, }, -- LOCALIZE
	      ["armor leather head"] =             { name = "Leather Head",         parent = "armor leather",         children = nil }, -- LOCALIZE
	      ["armor leather shoulders"] =        { name = "Leather Shoulder",     parent = "armor leather",         children = nil }, -- LOCALIZE
	      ["armor leather chest"] =            { name = "Leather Chest",        parent = "armor leather",         children = nil }, -- LOCALIZE
	      ["armor leather hands"] =            { name = "Leather Hands",        parent = "armor leather",         children = nil }, -- LOCALIZE
	      ["armor leather waist"] =            { name = "Leather Waist",        parent = "armor leather",         children = nil }, -- LOCALIZE
	      ["armor leather legs"] =             { name = "Leather Legs",         parent = "armor leather",         children = nil }, -- LOCALIZE
	      ["armor leather feet"] =             { name = "Leather Feet",         parent = "armor leather",         children = nil }, -- LOCALIZE
	    ["armor cloth"] =                      { name = "Cloth",                parent = "armor",                 children = { "armor cloth head", "armor cloth shoulders", "armor cloth chest", "armor cloth hands", "armor cloth waist", "armor cloth legs", "armor cloth feet", }, }, -- LOCALIZE
	      ["armor cloth head"] =               { name = "Cloth Head",           parent = "armor cloth",           children = nil, }, -- LOCALIZE
	      ["armor cloth shoulders"] =          { name = "Cloth Shoulder",       parent = "armor cloth",           children = nil, }, -- LOCALIZE
	      ["armor cloth chest"] =              { name = "Cloth Chest",          parent = "armor cloth",           children = nil, }, -- LOCALIZE
	      ["armor cloth hands"] =              { name = "Cloth Hands",          parent = "armor cloth",           children = nil, }, -- LOCALIZE
	      ["armor cloth waist"] =              { name = "Cloth Waist",          parent = "armor cloth",           children = nil, }, -- LOCALIZE
	      ["armor cloth legs"] =               { name = "Cloth Legs",           parent = "armor cloth",           children = nil, }, -- LOCALIZE
	      ["armor cloth feet"] =               { name = "Cloth Feet",           parent = "armor cloth",           children = nil, }, -- LOCALIZE
	    ["armor accessory"] =                  { name = "Accessories",          parent = "armor",                 children = { "armor accessory neck", "armor accessory ring", "armor accessory trinket", "armor accessory seal", }, }, -- LOCALIZE
	      ["armor accessory neck"] =           { name = "Necklace",             parent = "armor accessory",       children = nil, }, -- LOCALIZE
	      ["armor accessory ring"] =           { name = "Ring",                 parent = "armor accessory",       children = nil, }, -- LOCALIZE
	      ["armor accessory trinket"] =        { name = "Trinket",              parent = "armor accessory",       children = nil, }, -- LOCALIZE
	      ["armor accessory seal"] =           { name = "Seal",                 parent = "armor accessory",       children = nil, }, -- LOCALIZE
	    ["armor costume"] =                    { name = "Costume",              parent = "armor",                 children = nil, }, -- LOCALIZE
	    ["armor cape"] =                       { name = "Cape",                 parent = "armor",                 children = nil, }, -- LOCALIZE
	  ["weapon"] =                             { name = "Weapon",               parent = "",                      children = { "weapon onehand", "weapon twohand", "weapon ranged", "weapon totem", "weapon shield", }, }, -- LOCALIZE
	    ["weapon onehand"] =                   { name = "One Handed",           parent = "weapon",                children = { "weapon onehand sword", "weapon onehand axe", "weapon onehand mace", "weapon onehand dagger", }, }, -- LOCALIZE
	      ["weapon onehand sword"] =           { name = "Sword",                parent = "weapon onehand",        children = nil, }, -- LOCALIZE
	      ["weapon onehand axe"] =             { name = "Axe",                  parent = "weapon onehand",        children = nil, }, -- LOCALIZE
	      ["weapon onehand mace"] =            { name = "Mace",                 parent = "weapon onehand",        children = nil, }, -- LOCALIZE
	      ["weapon onehand dagger"] =          { name = "Dagger",               parent = "weapon onehand",        children = nil, }, -- LOCALIZE
	    ["weapon twohand"] =                   { name = "Two Handed",           parent = "weapon",                children = { "weapon twohand sword", "weapon twohand axe", "weapon twohand mace", "weapon twohand polearm", "weapon twohand staff", }, }, -- LOCALIZE
	      ["weapon twohand sword"] =           { name = "Sword",                parent = "weapon twohand",        children = nil, }, -- LOCALIZE
	      ["weapon twohand axe"] =             { name = "Axe",                  parent = "weapon twohand",        children = nil, }, -- LOCALIZE
	      ["weapon twohand mace"] =            { name = "Mace",                 parent = "weapon twohand",        children = nil, }, -- LOCALIZE
	      ["weapon twohand polearm"] =         { name = "Polearm",              parent = "weapon twohand",        children = nil, }, -- LOCALIZE
	      ["weapon twohand staff"] =           { name = "Staff",                parent = "weapon twohand",        children = nil, }, -- LOCALIZE
	    ["weapon ranged"] =                    { name = "Ranged",               parent = "weapon",                children = { "weapon ranged bow", "weapon ranged gun", "weapon ranged wand", }, }, -- LOCALIZE
	      ["weapon ranged bow"] =              { name = "Bows",                 parent = "weapon ranged",         children = nil, }, -- LOCALIZE
	      ["weapon ranged gun"] =              { name = "Guns",                 parent = "weapon ranged",         children = nil, }, -- LOCALIZE
	      ["weapon ranged wand"] =             { name = "Wands",                parent = "weapon ranged",         children = nil, }, -- LOCALIZE	
	    ["weapon totem"] =                     { name = "Totem",                parent = "weapon",                children = nil, }, -- LOCALIZE
	    ["weapon shield"] =                    { name = "Shield",               parent = "weapon",                children = nil, }, -- LOCALIZE
	  ["planar"] =                             { name = "Planar Items",         parent = "",                      children = { "planar lesser", "planar greater", }, }, -- LOCALIZE
	    ["planar lesser"] =                    { name = "Lesser Essence",       parent = "planar",                children = nil, }, -- LOCALIZE
	    ["planar greater"] =                   { name = "Greater Essence",      parent = "planar",                children = nil, }, -- LOCALIZE
	  ["consumable"] =                         { name = "Consumables",          parent = "",                      children = { "consumable food", "consumable drink", "consumable potion", "consumable scroll", "consumable enchantment", "consumable consumable", }, }, -- LOCALIZE
	    ["consumable food"] =                  { name = "Food",                 parent = "consumable",            children = nil, }, -- LOCALIZE
	    ["consumable drink"] =                 { name = "Drink",                parent = "consumable",            children = nil, }, -- LOCALIZE
	    ["consumable potion"] =                { name = "Potion",               parent = "consumable",            children = nil, }, -- LOCALIZE
	    ["consumable scroll"] =                { name = "Scroll",               parent = "consumable",            children = nil, }, -- LOCALIZE
	    ["consumable enchantment"] =           { name = "Item Enchantment",     parent = "consumable",            children = nil, }, -- LOCALIZE
	    ["consumable consumable"] =            { name = "Rift Consumable",      parent = "consumable",            children = nil, }, -- LOCALIZE
	  ["container"] =                          { name = "Containers",           parent = "",                      children = nil, }, -- LOCALIZE
	  ["crafting"] =                           { name = "Crafting",             parent = "",                      children = { "crafting recipe", "crafting material", "crafting ingredient", "crafting augment", }, }, -- LOCALIZE
	    ["crafting recipe"] =                  { name = "Recipes",              parent = "crafting",              children = { "crafting recipe apothecary", "crafting recipe armorsmith", "crafting recipe artificer", "crafting recipe butchering", "crafting recipe foraging", "crafting recipe weaponsmith", "crafting recipe outfitter", "crafting recipe mining", "crafting recipe runecrafting", "crafting recipe fishing", "crafting recipe survival", "crafting recipe dream weaver", }, }, -- LOCALIZE
	      ["crafting recipe apothecary"] =     { name = "Apothecary",           parent = "crafting recipe",       children = nil, }, -- LOCALIZE
	      ["crafting recipe armorsmith"] =     { name = "Armorsmith",           parent = "crafting recipe",       children = nil, }, -- LOCALIZE
	      ["crafting recipe artificer"] =      { name = "Artificer",            parent = "crafting recipe",       children = nil, }, -- LOCALIZE
	      ["crafting recipe butchering"] =     { name = "Butchering",           parent = "crafting recipe",       children = nil, }, -- LOCALIZE
	      ["crafting recipe foraging"] =       { name = "Foraging",             parent = "crafting recipe",       children = nil, }, -- LOCALIZE
	      ["crafting recipe weaponsmith"] =    { name = "Weaponsmith",          parent = "crafting recipe",       children = nil, }, -- LOCALIZE
	      ["crafting recipe outfitter"] =      { name = "Outfitter",            parent = "crafting recipe",       children = nil, }, -- LOCALIZE
	      ["crafting recipe mining"] =         { name = "Mining",               parent = "crafting recipe",       children = nil, }, -- LOCALIZE
	      ["crafting recipe runecrafting"] =   { name = "Runecrafting",         parent = "crafting recipe",       children = nil, }, -- LOCALIZE
	      ["crafting recipe fishing"] =        { name = "Fishing",              parent = "crafting recipe",       children = nil, }, -- LOCALIZE
	      ["crafting recipe survival"] =       { name = "Survival",             parent = "crafting recipe",       children = nil, }, -- LOCALIZE
	      ["crafting recipe dream weaver"] =   { name = "Dream Weaver",         parent = "crafting recipe",       children = nil, }, -- LOCALIZE
	    ["crafting material"] =                { name = "Materials",            parent = "crafting",              children = { "crafting material metal", "crafting material gem", "crafting material wood", "crafting material plant", "crafting material meat", "crafting material cloth", "crafting material component", "crafting material fish", "crafting material butcher", }, }, -- LOCALIZE
	      ["crafting material metal"] =        { name = "Metal",                parent = "crafting material",     children = nil, }, -- LOCALIZE
	      ["crafting material gem"] =          { name = "Gems",                 parent = "crafting material",     children = nil, }, -- LOCALIZE
	      ["crafting material wood"] =         { name = "Wood",                 parent = "crafting material",     children = nil, }, -- LOCALIZE
	      ["crafting material plant"] =        { name = "Plants",               parent = "crafting material",     children = nil, }, -- LOCALIZE
--	      ["crafting material hide"] =         { name = "Hide",                 parent = "crafting material",     children = nil, }, -- LOCALIZE
	      ["crafting material meat"] =         { name = "Meat",                 parent = "crafting material",     children = nil, }, -- LOCALIZE
	      ["crafting material cloth"] =        { name = "Cloth",                parent = "crafting material",     children = nil, }, -- LOCALIZE
	      ["crafting material component"] =    { name = "Rune Components",      parent = "crafting material",     children = nil, }, -- LOCALIZE
	      ["crafting material fish"] =         { name = "Fish",                 parent = "crafting material",     children = nil, }, -- LOCALIZE
	      ["crafting material butcher"] =      { name = "Butchering",           parent = "crafting material",     children = nil, }, -- LOCALIZE
	    ["crafting ingredient"] =              { name = "Ingredients",          parent = "crafting",              children = { "crafting ingredient reagent", "crafting ingredient drop", "crafting ingredient rift", }, }, -- LOCALIZE
	      ["crafting ingredient reagent"] =    { name = "Reagents",             parent = "crafting ingredient",   children = nil, }, -- LOCALIZE
	      ["crafting ingredient drop"] =       { name = "Drops",                parent = "crafting ingredient",   children = nil, }, -- LOCALIZE
	      ["crafting ingredient rift"] =       { name = "Rifts",                parent = "crafting ingredient",   children = nil, }, -- LOCALIZE
	    ["crafting augment"] =                 { name = "Augments",             parent = "crafting",              children = nil, }, -- LOCALIZE
	  ["misc"] =                               { name = "Misc",                 parent = "",                      children = { "misc quest", "misc mount", "misc pet", "misc collectible", "misc other", "misc survival", "misc fishing", }, }, -- LOCALIZE
	    ["misc quest"] =                       { name = "Quest",                parent = "misc",                  children = nil, }, -- LOCALIZE
	    ["misc mount"] =                       { name = "Mounts",               parent = "misc",                  children = nil, }, -- LOCALIZE
	    ["misc pet"] =                         { name = "Pets",                 parent = "misc",                  children = nil, }, -- LOCALIZE
	    ["misc collectible"] =                 { name = "Collectibles",         parent = "misc",                  children = nil, }, -- LOCALIZE
	    ["misc other"] =                       { name = "Other",                parent = "misc",                  children = nil, }, -- LOCALIZE
	    ["misc survival"] =                    { name = "Survival",             parent = "misc",                  children = nil, }, -- LOCALIZE
	    ["misc fishing"] =                     { name = "Fishing",              parent = "misc",                  children = nil, }, -- LOCALIZE
	  ["dimension"] =                          { name = "Dimension Item",       parent = "",                      children = { "dimension lighting", "dimension key", "dimension building", "dimension world", "dimension decoration", "dimension block", "dimension furniture", "dimension module", "dimension interactive", "dimension planar", "dimension landscaping", }, }, -- LOCALIZE
	    ["dimension lighting"] =               { name = "Lighting",             parent = "dimension",             children = nil, }, -- LOCALIZE
	    ["dimension key"] =                    { name = "Dimension Key",        parent = "dimension",             children = nil, }, -- LOCALIZE
	    ["dimension building"] =               { name = "Building",             parent = "dimension",             children = nil, }, -- LOCALIZE
	    ["dimension world"] =                  { name = "World Event",          parent = "dimension",             children = nil, }, -- LOCALIZE
	    ["dimension decoration"] =             { name = "Decoration",           parent = "dimension",             children = { "dimension decoration large", "dimension decoration small", "dimension decoration container", "dimension decoration household", }, }, -- LOCALIZE
	      ["dimension decoration large"] =     { name = "Large Decoration",     parent = "dimension decoration",  children = nil, }, -- LOCALIZE
	      ["dimension decoration small"] =     { name = "Small Decoration",     parent = "dimension decoration",  children = nil, }, -- LOCALIZE
	      ["dimension decoration container"] = { name = "Decorative Container", parent = "dimension decoration",  children = nil, }, -- LOCALIZE
	      ["dimension decoration household"] = { name = "Household Item",       parent = "dimension decoration",  children = nil, }, -- LOCALIZE
	    ["dimension block"] =                  { name = "Building Block",       parent = "dimension",             children = nil, }, -- LOCALIZE
	    ["dimension furniture"] =              { name = "Furniture",            parent = "dimension",             children = nil, }, -- LOCALIZE
	    ["dimension module"] =                 { name = "Building Module",      parent = "dimension",             children = nil, }, -- LOCALIZE
	    ["dimension interactive"] =            { name = "Interactive",          parent = "dimension",             children = nil, }, -- LOCALIZE
	    ["dimension planar"] =                 { name = "Planar",               parent = "dimension",             children = nil, }, -- LOCALIZE
	    ["dimension landscaping"] =            { name = "Landscaping",          parent = "dimension",             children = { "dimension landscaping barrier", "dimension landscaping rock", "dimension landscaping tree", "dimension landscaping plant", }, }, -- LOCALIZE
	      ["dimension landscaping barrier"] =  { name = "Barrier",              parent = "dimension landscaping", children = nil, }, -- LOCALIZE
	      ["dimension landscaping rock"] =     { name = "Rock",                 parent = "dimension landscaping", children = nil, }, -- LOCALIZE
	      ["dimension landscaping tree"] =     { name = "Tree",                 parent = "dimension landscaping", children = nil, }, -- LOCALIZE
	      ["dimension landscaping plant"] =    { name = "Plant",                parent = "dimension landscaping", children = nil, }, -- LOCALIZE
	  ["artifacts"] =                          { name = "Artifacts",            parent = "",                      children = { "artifacts normal", "artifacts twisted", "artifacts unstable", "artifacts bounty", "artifacts other", "artifacts fishing", }, }, -- LOCALIZE
	    ["artifacts normal"] =                 { name = "Normal",               parent = "artifacts",             children = nil, }, -- LOCALIZE
	    ["artifacts twisted"] =                { name = "Twisted",              parent = "artifacts",             children = nil, }, -- LOCALIZE
	    ["artifacts unstable"] =               { name = "Unstable",             parent = "artifacts",             children = nil, }, -- LOCALIZE
	    ["artifacts bounty"] =                 { name = "Bounty",               parent = "artifacts",             children = nil, }, -- LOCALIZE
	    ["artifacts other"] =                  { name = "Other",                parent = "artifacts",             children = nil, }, -- LOCALIZE
	    ["artifacts fishing"] =                { name = "Fishing",              parent = "artifacts",             children = nil, }, -- LOCALIZE
}

InternalInterface.Category = InternalInterface.Category or {}

InternalInterface.Category.BASE_CATEGORY = BASE_CATEGORY

function InternalInterface.Category.List()
	local list = {}
	for category in pairs(CATEGORIES) do
		list[category] = true
	end
	return list
end

function InternalInterface.Category.Detail(category)
	category = category or BASE_CATEGORY
	return CATEGORIES[category] and CopyTableRecursive(CATEGORIES[category]) or nil
end	
