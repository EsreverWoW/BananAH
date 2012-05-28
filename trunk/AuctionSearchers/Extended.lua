local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local AUCTION_SEARCHER_ID = "extended"
local AUCTION_SEARCHER_NAME = "Extended" -- LOCALIZE
local ONLINE = false

local SEARCH_HEIGHT = 120

local searchFrame = nil
local extraFrame = nil
local configFrame = nil

local function DefaultConfig()
	InternalInterface.AccountSettings.AuctionSearchers[AUCTION_SEARCHER_ID] = InternalInterface.AccountSettings.PriceMatchers[AUCTION_SEARCHER_ID] or
	{
	}
end

local function AuctionSearcher(text)
	if searchFrame then
		local _, calling = searchFrame.callingsDropdown:GetSelectedValue()
		local _, rarity = searchFrame.rarityDropdown:GetSelectedValue()
		local _, category = searchFrame.categoryDropdown:GetSelectedValue()
		local bidMin = searchFrame.minBidSelector:GetValue()
		local bidMax = searchFrame.maxBidSelector:GetValue()
		local priceMin = searchFrame.minPriceSelector:GetValue()
		local priceMax = searchFrame.maxPriceSelector:GetValue()
		local levelMin = searchFrame.minLevelSlider:GetPosition()
		local levelMax = searchFrame.maxLevelSlider:GetPosition()
		local duration = searchFrame.durationSlider:GetPosition()
		local sellerName = string.upper(searchFrame.sellerNameField:GetText() or "")
		
		bidMin = bidMin > 0 and bidMin or nil
		bidMax = bidMax > 0 and bidMax or nil
		priceMin = priceMin > 0 and priceMin or nil
		priceMax = priceMax > 0 and priceMax or nil
		levelMax = levelMax ~= 0 and levelMax or nil
		
		if bidMin and bidMax and bidMin > bidMax then
			bidMin = nil
			searchFrame.minBidSelector:SetValue(0)
		end
		
		if priceMin and priceMax and priceMin > priceMax then
			priceMin = nil
			searchFrame.minPriceSelector:SetValue(0)
		end
		
		if levelMin and levelMax and levelMin > levelMax then
			levelMin = levelMax
			searchFrame.minLevelSlider:SetPosition(levelMax)
		end
		
		return 
		{
			calling = calling.calling,
			rarity = rarity.rarity,
			levelMin = levelMin,
			levelMax = levelMax,
			category = category.category,
			priceMin = priceMin,
			priceMax = priceMax,
			name = text,
			bidMin = bidMin,
			bidMax = bidMax,
			duration = duration,
			sellerName = sellerName,
		}
	end
	return { name = text }
end

local function AuctionFilter(activeAuctions, searchSettings)
	local maxTime = os.time() + searchSettings.duration * 3600

	for auctionID, auctionData in pairs(activeAuctions) do
		if (auctionData.maxExpireTime > maxTime) or 
		   (searchSettings.bidMin and auctionData.bidPrice < searchSettings.bidMin) or
		   (searchSettings.bidMax and auctionData.bidPrice > searchSettings.bidMax) or
		   (searchSettings.sellerName and searchSettings.sellerName ~= "" and not string.find(string.upper(auctionData.sellerName), searchSettings.sellerName)) 
		   then 
			activeAuctions[auctionID] = nil
		end
	end
	return activeAuctions
end

local function AuctionClear()
	if searchFrame then
		searchFrame.callingsDropdown:SetSelectedIndex(1)
		searchFrame.rarityDropdown:SetSelectedIndex(1)
		searchFrame.categoryDropdown:SetSelectedIndex(1)
		searchFrame.minBidSelector:SetValue(0)
		searchFrame.maxBidSelector:SetValue(0)
		searchFrame.minPriceSelector:SetValue(0)
		searchFrame.maxPriceSelector:SetValue(0)
		searchFrame.minLevelSlider:SetPosition(0)
		searchFrame.maxLevelSlider:SetPosition(0)
		searchFrame.durationSlider:SetPosition(48)
		searchFrame.sellerNameField:SetText("")
	end
end

local function AuctionSnipe()
end

local function SearchFrame(parent)
	if searchFrame then return searchFrame, SEARCH_HEIGHT end

	searchFrame = UI.CreateFrame("Frame", parent:GetName() .. ".BasicSearcher", parent)
	local callingsText = UI.CreateFrame("Text", searchFrame:GetName() .. ".CallingsText", searchFrame)
	local rarityText = UI.CreateFrame("Text", searchFrame:GetName() .. ".RarityText", searchFrame)
	local categoryText = UI.CreateFrame("Text", searchFrame:GetName() .. ".CategoryText", searchFrame)
	local minLevelText = UI.CreateFrame("Text", searchFrame:GetName() .. ".MinLevelText", searchFrame)
	local maxLevelText = UI.CreateFrame("Text", searchFrame:GetName() .. ".MaxLevelText", searchFrame)
	local minBidText = UI.CreateFrame("Text", searchFrame:GetName() .. ".MinBidText", searchFrame)
	local maxBidText = UI.CreateFrame("Text", searchFrame:GetName() .. ".MaxBidText", searchFrame)
	local minPriceText = UI.CreateFrame("Text", searchFrame:GetName() .. ".MinPriceText", searchFrame)
	local maxPriceText = UI.CreateFrame("Text", searchFrame:GetName() .. ".MaxPriceText", searchFrame)
	local durationText = UI.CreateFrame("Text", searchFrame:GetName() .. ".DurationText", searchFrame)
	local sellerText = UI.CreateFrame("Text", searchFrame:GetName() .. ".SellerText", searchFrame)
	local callingsDropdown = UI.CreateFrame("BDropdown", searchFrame:GetName() .. ".CallingsDropdown", searchFrame)
	local rarityDropdown = UI.CreateFrame("BDropdown", searchFrame:GetName() .. ".RarityDropdown", searchFrame)
	local categoryDropdown = UI.CreateFrame("BDropdown", searchFrame:GetName() .. ".CategoryDropdown", searchFrame)
	local minBidSelector = UI.CreateFrame("BMoneySelector", searchFrame:GetName() .. ".MinBidSelector", searchFrame)
	local maxBidSelector = UI.CreateFrame("BMoneySelector", searchFrame:GetName() .. ".MaxBidSelector", searchFrame)
	local minPriceSelector = UI.CreateFrame("BMoneySelector", searchFrame:GetName() .. ".MinPriceSelector", searchFrame)
	local maxPriceSelector = UI.CreateFrame("BMoneySelector", searchFrame:GetName() .. ".MaxPriceSelector", searchFrame)
	local minLevelSlider = UI.CreateFrame("BSlider", searchFrame:GetName() .. ".MinLevelSlider", searchFrame)
	local maxLevelSlider = UI.CreateFrame("BSlider", searchFrame:GetName() .. ".MaxLevelSlider", searchFrame)
	local durationSlider = UI.CreateFrame("BSlider", searchFrame:GetName() .. ".DurationSlider", searchFrame)
	local sellerNamePanel = UI.CreateFrame("BPanel", searchFrame:GetName() .. ".SellerNamePanel", searchFrame)
	local sellerNameField = UI.CreateFrame("RiftTextfield", searchFrame:GetName() .. ".SellerNameField", sellerNamePanel:GetContent())	
	
	callingsText:SetPoint("CENTERLEFT", searchFrame, 0, 1/6)
	callingsText:SetText("Calling:") -- LOCALIZE
	
	rarityText:SetPoint("CENTERLEFT", searchFrame, 0.25, 1/6)
	rarityText:SetText("Min. rarity:") -- LOCALIZE
	
	categoryText:SetPoint("CENTERLEFT", searchFrame, 0.5, 1/6)
	categoryText:SetText("Category:") -- LOCALIZE

	minBidText:SetPoint("CENTERLEFT", searchFrame, 0, 3/6)
	minBidText:SetText("Min. bid price:") -- LOCALIZE
	
	maxBidText:SetPoint("CENTERLEFT", searchFrame, 0.25, 3/6)
	maxBidText:SetText("Max. bid price:") -- LOCALIZE

	minPriceText:SetPoint("CENTERLEFT", searchFrame, 0.5, 3/6)
	minPriceText:SetText("Min. buyout price:") -- LOCALIZE
	
	maxPriceText:SetPoint("CENTERLEFT", searchFrame, 0.75, 3/6)
	maxPriceText:SetText("Max. buyout price:") -- LOCALIZE

	minLevelText:SetPoint("CENTERLEFT", searchFrame, 0, 5/6)
	minLevelText:SetText("Min. level:") -- LOCALIZE
	
	maxLevelText:SetPoint("CENTERLEFT", searchFrame, 0.25, 5/6)
	maxLevelText:SetText("Max. level:") -- LOCALIZE
	
	durationText:SetPoint("CENTERLEFT", searchFrame, 0.5, 5/6)
	durationText:SetText("Max. hours left:") -- LOCALIZE
	
	sellerText:SetPoint("CENTERLEFT", searchFrame, 0.75, 5/6)
	sellerText:SetText("Seller:") -- LOCALIZE
	
	local align1Offset = math.max(math.max(callingsText:GetWidth(), minBidText:GetWidth()), minLevelText:GetWidth())
	local align2Offset = math.max(math.max(rarityText:GetWidth(), maxBidText:GetWidth()), maxLevelText:GetWidth())
	local align3Offset = math.max(math.max(categoryText:GetWidth(), minPriceText:GetWidth()), durationText:GetWidth())
	local align4Offset = math.max(maxPriceText:GetWidth(), sellerText:GetWidth())
	
	callingsDropdown:SetPoint("CENTERLEFT", callingsText, "CENTERLEFT", align1Offset + 5, 0)
	callingsDropdown:SetPoint("CENTERRIGHT", rarityText, "CENTERLEFT", -5, 0)
	callingsDropdown:SetHeight(34)
	callingsDropdown:SetValues({
		{ displayName = "All", calling = nil }, -- LOCALIZE
		{ displayName = "Warrior", calling = "warrior" }, -- LOCALIZE
		{ displayName = "Cleric", calling = "cleric" }, -- LOCALIZE
		{ displayName = "Rogue", calling = "rogue" }, -- LOCALIZE
		{ displayName = "Mage", calling = "mage" }, -- LOCALIZE
	})
	searchFrame.callingsDropdown = callingsDropdown

	rarityDropdown:SetPoint("CENTERLEFT", rarityText, "CENTERLEFT", align2Offset + 5, 0)
	rarityDropdown:SetPoint("CENTERRIGHT", categoryText, "CENTERLEFT", -5, 0)
	rarityDropdown:SetHeight(34)
	rarityDropdown:SetValues({
		{ displayName = L["General/Rarity1"], rarity = "sellable", },
		{ displayName = L["General/Rarity2"], rarity = "", },
		{ displayName = L["General/Rarity3"], rarity = "uncommon", },
		{ displayName = L["General/Rarity4"], rarity = "rare", },
		{ displayName = L["General/Rarity5"], rarity = "epic", },
		{ displayName = L["General/Rarity6"], rarity = "relic", },
		{ displayName = L["General/Rarity7"], rarity = "transcendant", },
		{ displayName = L["General/Rarity0"], rarity = "quest", },
	})
	searchFrame.rarityDropdown = rarityDropdown

	categoryDropdown:SetPoint("CENTERLEFT", categoryText, "CENTERLEFT", align3Offset + 5, 0)
	categoryDropdown:SetPoint("CENTERRIGHT", searchFrame, 1, 1/6)
	categoryDropdown:SetHeight(34)
	categoryDropdown:SetValues({
		{ displayName = "All", category = nil }, -- LOCALIZE
		{ displayName = "\t" .. "Armor", category = "armor" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Plate", category = "armor plate" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Plate Head", category = "armor plate head" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Plate Shoulder", category = "armor plate shoulders" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Plate Chest", category = "armor plate chest" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Plate Hands", category = "armor plate hands" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Plate Waist", category = "armor plate waist" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Plate Legs", category = "armor plate legs" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Plate Feet", category = "armor plate feet" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Chain", category = "armor chain" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Chain Head", category = "armor chain head" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Chain Shoulder", category = "armor chain shoulders" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Chain Chest", category = "armor chain chest" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Chain Hands", category = "armor chain hands" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Chain Waist", category = "armor chain waist" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Chain Legs", category = "armor chain legs" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Chain Feet", category = "armor chain feet" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Leather", category = "armor leather" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Leather Head", category = "armor leather head" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Leather Shoulder", category = "armor leather shoulders" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Leather Chest", category = "armor leather chest" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Leather Hands", category = "armor leather hands" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Leather Waist", category = "armor leather waist" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Leather Legs", category = "armor leather legs" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Leather Feet", category = "armor leather feet" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Cloth", category = "armor cloth" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Cloth Head", category = "armor cloth head" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Cloth Shoulder", category = "armor cloth shoulders" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Cloth Chest", category = "armor cloth chest" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Cloth Hands", category = "armor cloth hands" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Cloth Waist", category = "armor cloth waist" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Cloth Legs", category = "armor cloth legs" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Cloth Feet", category = "armor cloth feet" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Accessories", category = "armor accessory" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Necklace", category = "armor accessory neck" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Ring", category = "armor accessory ring" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Trinket", category = "armor accessory trinket" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Seal", category = "armor accessory seal" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Costume", category = "armor costume" }, -- LOCALIZE
		{ displayName = "\t" .. "Weapon", category = "weapon" }, -- LOCALIZE
		{ displayName = "\t\t" .. "One Handed", category = "weapon onehand" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Sword", category = "weapon onehand sword" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Axe", category = "weapon onehand axe" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Mace", category = "weapon onehand mace" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Dagger", category = "weapon onehand dagger" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Two Handed", category = "weapon twohand" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Sword", category = "weapon twohand sword" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Axe", category = "weapon twohand axe" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Mace", category = "weapon twohand mace" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Polearm", category = "weapon twohand polearm" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Staff", category = "weapon twohand staff" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Ranged", category = "weapon ranged" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Bows", category = "weapon ranged bow" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Guns", category = "weapon ranged gun" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Wands", category = "weapon ranged wand" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Totem", category = "weapon totem" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Shield", category = "weapon shield" }, -- LOCALIZE
		{ displayName = "\t" .. "Planar Items", category = "planar" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Lesser Essence", category = "planar lesser" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Greater Essence", category = "planar greater" }, -- LOCALIZE
		{ displayName = "\t" .. "Consumables", category = "consumable" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Food", category = "consumable food" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Drink", category = "consumable drink" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Potion", category = "consumable potion" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Scroll", category = "consumable scroll" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Item Enchantment", category = "consumable enchantment" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Rift Consumable", category = "consumable consumable" }, -- LOCALIZE
		{ displayName = "\t" .. "Containers", category = "container" }, -- LOCALIZE
		{ displayName = "\t" .. "Crafting", category = "crafting" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Recipes", category = "crafting recipe" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Apothecary", category = "crafting recipe alchemy" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Armorsmith", category = "crafting recipe armorsmith" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Artificer", category = "crafting recipe artificer" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Butchering", category = "crafting recipe butchering" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Foraging", category = "crafting recipe foraging" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Weaponsmith", category = "crafting recipe weaponsmith" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Outfitter", category = "crafting recipe outfitter" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Mining", category = "crafting recipe mining" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Runecrafting", category = "crafting recipe runecrafting" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Fishing", category = "crafting recipe fishing" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Survival", category = "crafting recipe survival" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Materials", category = "crafting material" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Metal", category = "crafting material metal" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Gems", category = "crafting material gem" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Wood", category = "crafting material wood" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Plants", category = "crafting material plant" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Hide", category = "crafting material hide" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Meat", category = "crafting material meat" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Cloth", category = "crafting material cloth" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Rune Components", category = "crafting material component" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Fish", category = "crafting material fish" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Ingredients", category = "crafting ingredient" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Reagents", category = "crafting ingredient reagent" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Drops", category = "crafting ingredient drop" }, -- LOCALIZE
		{ displayName = "\t\t\t" .. "Rifts", category = "crafting ingredient rift" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Augments", category = "crafting augment" }, -- LOCALIZE
		{ displayName = "\t" .. "Misc", category = "misc" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Quest", category = "misc quest" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Mounts", category = "misc mount" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Pets", category = "misc pet" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Collectibles", category = "misc collectible" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Other", category = "misc other" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Survival", category = "misc survival misc" }, -- LOCALIZE
		{ displayName = "\t\t" .. "Fishing", category = "misc fishing misc" }, -- LOCALIZE
	})
	searchFrame.categoryDropdown = categoryDropdown

	minBidSelector:SetPoint("CENTERLEFT", minBidText, "CENTERLEFT", align1Offset + 5, 0)
	minBidSelector:SetPoint("CENTERRIGHT", maxBidText, "CENTERLEFT", -5, 0)
	minBidSelector:SetHeight(34)
	searchFrame.minBidSelector = minBidSelector
	
	maxBidSelector:SetPoint("CENTERLEFT", maxBidText, "CENTERLEFT", align2Offset + 5, 0)
	maxBidSelector:SetPoint("CENTERRIGHT", minPriceText, "CENTERLEFT", -5, 0)
	maxBidSelector:SetHeight(34)
	searchFrame.maxBidSelector = maxBidSelector

	minPriceSelector:SetPoint("CENTERLEFT", minPriceText, "CENTERLEFT", align3Offset + 5, 0)
	minPriceSelector:SetPoint("CENTERRIGHT", maxPriceText, "CENTERLEFT", -5, 0)
	minPriceSelector:SetHeight(34)
	searchFrame.minPriceSelector = minPriceSelector
	
	maxPriceSelector:SetPoint("CENTERLEFT", maxPriceText, "CENTERLEFT", align4Offset + 5, 0)
	maxPriceSelector:SetPoint("CENTERRIGHT", searchFrame, 1, 3/6)
	maxPriceSelector:SetHeight(34)
	searchFrame.maxPriceSelector = maxPriceSelector
	
	minLevelSlider:SetPoint("CENTERLEFT", minLevelText, "CENTERLEFT", align1Offset + 5, 8)
	minLevelSlider:SetPoint("CENTERRIGHT", maxLevelText, "CENTERLEFT", -5, 8)
	minLevelSlider:SetRange(0, 50)
	searchFrame.minLevelSlider = minLevelSlider
	
	maxLevelSlider:SetPoint("CENTERLEFT", maxLevelText, "CENTERLEFT", align2Offset + 5, 8)
	maxLevelSlider:SetPoint("CENTERRIGHT", durationText, "CENTERLEFT", -5, 8)
	maxLevelSlider:SetRange(0, 50)
	searchFrame.maxLevelSlider = maxLevelSlider

	durationSlider:SetPoint("CENTERLEFT", durationText, "CENTERLEFT", align3Offset + 5, 8)
	durationSlider:SetPoint("CENTERRIGHT", sellerText, "CENTERLEFT", -5, 8)
	durationSlider:SetRange(1, 48)
	durationSlider:SetPosition(48)
	searchFrame.durationSlider = durationSlider
	
	sellerNamePanel:SetPoint("CENTERLEFT", sellerText, "CENTERLEFT", align4Offset + 5, 0)
	sellerNamePanel:SetPoint("CENTERRIGHT", searchFrame, 1, 5/6)
	sellerNamePanel:SetHeight(34)
	sellerNamePanel:SetInvertedBorder(true)
	sellerNamePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	sellerNameField:SetPoint("CENTERLEFT", sellerNamePanel:GetContent(), "CENTERLEFT", 2, 1)
	sellerNameField:SetPoint("CENTERRIGHT", sellerNamePanel:GetContent(), "CENTERRIGHT", -2, 1)
	sellerNameField:SetText("")	
	searchFrame.sellerNameField = sellerNameField
	
	return searchFrame, SEARCH_HEIGHT
end

local function ExtraFrame()
end

local function ConfigFrame()
end

_G[addonID].RegisterAuctionSearcher(AUCTION_SEARCHER_ID, AUCTION_SEARCHER_NAME, ONLINE, AuctionSearcher, AuctionFilter, AuctionClear, AuctionSnipe, SearchFrame, ExtraFrame, ConfigFrame)
