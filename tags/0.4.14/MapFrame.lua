-- ***************************************************************************************************************************************************
-- * MapFrame.lua                                                                                                                                    *
-- ***************************************************************************************************************************************************
-- * 0.4.11 / 2013.09.17 / Baanano: First version                                                                                                    *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local MIN_CATEGORY_AREA = 80 * 80
local MIN_ITEM_AREA = MIN_CATEGORY_AREA / 4

local BASE_CATEGORY = InternalInterface.Category.BASE_CATEGORY
local CreateTask = LibScheduler.CreateTask
-- local DataGrid = Yague.DataGrid
-- local Dropdown = Yague.Dropdown
-- local ShadowedText = Yague.ShadowedText
-- local Slider = Yague.Slider
-- local CACancel = Command.Auction.Cancel
local CTooltip = Command.Tooltip
local GetActiveAuctionData = LibPGC.GetActiveAuctionData
local GetAllAuctionData = LibPGC.GetAllAuctionData
-- local GetAuctionCached = LibPGC.GetAuctionCached
-- local GetAuctionCancelCallback = LibPGC.GetAuctionCancelCallback
local CDetail = InternalInterface.Category.Detail
-- local GetOwnAuctionsScoredCompetition = InternalInterface.PGCExtensions.GetOwnAuctionsScoredCompetition
-- local GetPlayerName = InternalInterface.Utility.GetPlayerName
-- local GetPopupManager = InternalInterface.Output.GetPopupManager
-- local GetRarityColor = InternalInterface.Utility.GetRarityColor
-- local IIDetail = Inspect.Item.Detail
-- local IInteraction = Inspect.Interaction
local ITServer = Inspect.Time.Server
-- local L = InternalInterface.Localization.L
-- local MFloor = math.floor
-- local MMin = math.min
local Panel = Yague.Panel
-- local RegisterPopupConstructor = Yague.RegisterPopupConstructor
local Release = LibScheduler.Release
-- local RemainingTimeFormatter = InternalInterface.Utility.RemainingTimeFormatter
-- local SFind = string.find
-- local SFormat = string.format
-- local SLen = string.len
-- local SUpper = string.upper
-- local ScoreColorByScore = InternalInterface.UI.ScoreColorByScore
-- local TInsert = table.insert
local UICreateFrame = UI.CreateFrame
-- local Write = InternalInterface.Output.Write
-- local pcall = pcall
-- local unpack = unpack

local function BinaryInsert(array, value, sortFunction)
	local first, final = 1, #array
	
	while first <= final do
		local mid = math.floor((first + final) / 2)
		if sortFunction(value, array[mid]) then
			final = mid - 1
		else
			first = mid + 1
		end
	end
	
	table.insert(array, first, value)
end

local function DivideTree(tree)
	if #tree.elements <= 1 then
		tree.partition = 0
		tree.count = nil
	else
		Release()
	
		local first, second = { count = 0, elements = {}, }, { count = 0, elements = {}, }
		
		for _, element in pairs(tree.elements) do
			local selected = first.count <= second.count and first or second
			selected.count = selected.count + element.count
			selected.elements[#selected.elements + 1] = element
		end
		
		if first.count < second.count then
			first, second = second, first
		end
		
		tree.partition = first.count / tree.count
		if tree.width >= tree.height then
			first.width = math.floor(tree.width * tree.partition)
			first.height = tree.height
			second.width = tree.width - first.width
			second.height = tree.height
		else
			first.width = tree.width
			first.height = math.floor(tree.height * tree.partition)
			second.width = tree.width
			second.height = tree.height - first.height
			tree.partition = -tree.partition
		end

		DivideTree(first)
		DivideTree(second)
		
		tree.count = nil
		tree.elements = { first, second }
	end
end

local function ExtractParts(tree)
	
	if tree.partition > 0 then
		tree.elements[1].left = tree.left
		tree.elements[1].top = tree.top
		tree.elements[2].left = tree.left + tree.elements[1].width
		tree.elements[2].top = tree.top
	elseif tree.partition < 0 then
		tree.elements[1].left = tree.left
		tree.elements[1].top = tree.top
		tree.elements[2].left = tree.left
		tree.elements[2].top = tree.top + tree.elements[1].height
	else
		return { [{ left = tree.left, top = tree.top, width = tree.width, height = tree.height, element = tree.elements[1] }] = true }
	end
	
	local parts = {}
	
	Release()
	for part in pairs(ExtractParts(tree.elements[1])) do
		parts[part] = true
	end
	
	Release()
	for part in pairs(ExtractParts(tree.elements[2])) do
		parts[part] = true
	end
	
	return parts
end

--[[
local function CancelAuctionPopup(parent)
	local frame = Yague.Popup(parent:GetName() .. ".SaveSearchPopup", parent)
	
	local titleText = ShadowedText(frame:GetName() .. ".TitleText", frame:GetContent())
	local contentText = UICreateFrame("Text", frame:GetName() .. ".ContentText", frame:GetContent())
	local ignoreCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".IgnoreCheck", frame:GetContent())
	local ignoreText = UICreateFrame("Text", frame:GetName() .. ".IgnoreText", frame:GetContent())
	local yesButton = UICreateFrame("RiftButton", frame:GetName() .. ".YesButton", frame:GetContent())
	local noButton = UICreateFrame("RiftButton", frame:GetName() .. ".NoButton", frame:GetContent())	
	
	frame:SetWidth(420)
	frame:SetHeight(160)
	
	titleText:SetPoint("TOPCENTER", frame:GetContent(), "TOPCENTER", 0, 10)
	titleText:SetFontSize(14)
	titleText:SetFontColor(1, 1, 0.75, 1)
	titleText:SetShadowOffset(2, 2)
	titleText:SetText(L["CancelAuctionPopup/Title"])
	
	contentText:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 10, 45)
	contentText:SetText(L["CancelAuctionPopup/ContentText"])
	
	yesButton:SetPoint("BOTTOMRIGHT", frame:GetContent(), "BOTTOMCENTER", 0, -30)
	yesButton:SetText(L["CancelAuctionPopup/ButtonYes"])
	
	noButton:SetPoint("BOTTOMLEFT", frame:GetContent(), "BOTTOMCENTER", 0, -30)
	noButton:SetText(L["CancelAuctionPopup/ButtonNo"])

	ignoreCheck:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 15, 120)
	ignoreCheck:SetChecked(false)
	
	ignoreText:SetPoint("CENTERLEFT", ignoreCheck, "CENTERRIGHT", 5, 0)
	ignoreText:SetText(L["CancelAuctionPopup/IgnoreText"])	
	
	function noButton.Event:LeftPress()
		parent:HidePopup(addonID .. ".CancelAuction", frame)
	end
	
	function frame:SetData(callback)
		function yesButton.Event:LeftPress()
			InternalInterface.AccountSettings.Auctions.BypassCancelPopup = ignoreCheck:GetChecked()
			callback() 
			parent:HidePopup(addonID .. ".CancelAuction", frame)
		end
	end
	
	return frame
end
RegisterPopupConstructor(addonID .. ".CancelAuction", CancelAuctionPopup)


local function SellingAuctionCellType(name, parent)
	local sellingCell = UICreateFrame("Mask", name, parent)
	local itemTextureBackground = UICreateFrame("Frame", name .. ".ItemTextureBackground", sellingCell)
	local itemTexture = UICreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = ShadowedText(name .. ".ItemNameLabel", sellingCell)
	local alterTexture = UICreateFrame("Texture", name .. ".AlterTexture", sellingCell)
	local alterNameLabel = ShadowedText(name .. ".AlterNameLabel", sellingCell)
	local biddedTexture = UICreateFrame("Texture", name .. ".BiddedTexture", sellingCell)
	local itemStackLabel = ShadowedText(name .. ".ItemStackLabel", sellingCell)	
	
	local itemType = nil
	
	itemTextureBackground:SetPoint("CENTERLEFT", sellingCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("TOPLEFT", itemTextureBackground, "TOPRIGHT", 4, 0)
	
	itemStackLabel:SetPoint("BOTTOMLEFT", itemTextureBackground, "BOTTOMRIGHT", 4, -3)	

	biddedTexture:SetPoint("BOTTOMLEFT", itemStackLabel, "BOTTOMRIGHT", 5, -2)
	biddedTexture:SetTextureAsync(addonID, "Textures/Bidded.png")
	
	alterTexture:SetPoint("BOTTOMLEFT", biddedTexture, "BOTTOMRIGHT", 5, 0)
	alterTexture:SetTextureAsync(addonID, "Textures/Alter.png")
	
	alterNameLabel:SetPoint("BOTTOMLEFT", alterTexture, "BOTTOMRIGHT", 0, 2)
	alterNameLabel:SetVisible(false)
	
	function sellingCell:SetValue(key, value, width, extra)
		self:SetWidth(width)
		
		itemTextureBackground:SetBackgroundColor(GetRarityColor(value.itemRarity))
		
		itemTexture:SetTextureAsync("Rift", value.itemIcon)
		
		itemNameLabel:SetText(value.itemName)
		itemNameLabel:SetFontColor(GetRarityColor(value.itemRarity))
		
		itemStackLabel:SetText("x" .. (value.stack or 0))
		
		if value.bidded then
			biddedTexture:ClearWidth()
			biddedTexture:SetVisible(true)
		else
			biddedTexture:SetWidth(-5)
			biddedTexture:SetVisible(false)
		end
		
		local seller = value.sellerName
		alterTexture:SetVisible(seller and seller ~= GetPlayerName() and true or false)

		alterNameLabel:SetText(seller or "")
		
		itemType = value.itemType
	end
	
	function itemTexture.Event:MouseIn()
		pcall(CTooltip, itemType)
	end
	
	function itemTexture.Event:MouseOut()
		CTooltip(nil)
	end	
	
	function alterTexture.Event:MouseIn()
		alterNameLabel:SetVisible(self:GetVisible())
	end
	
	function alterTexture.Event:MouseOut()
		alterNameLabel:SetVisible(false)
	end
	
	return sellingCell
end

local function CancellableCellType(name, parent)
	local cell = UICreateFrame("Frame", name, parent)
	local cancellableCell = UICreateFrame("Texture", name .. ".Texture", cell)
	
	local auctionID = nil

	cancellableCell:SetPoint("CENTER", cell, "CENTER")
	cancellableCell:SetTextureAsync(addonID, "Textures/DeleteDisabled.png")
	
	function cell:SetValue(key, value, width, extra)
		auctionID = key and not value.bidded and GetAuctionCached(key) and value.sellerName == GetPlayerName() and IInteraction("auction") and key or nil
		cancellableCell:SetTextureAsync(addonID, auctionID and "Textures/DeleteEnabled.png" or "Textures/DeleteDisabled.png")
	end
	
	function cancellableCell.Event:LeftClick()
		if auctionID then
			local callback = function() if IInteraction("auction") then CACancel(auctionID, GetAuctionCancelCallback(auctionID)) end end
			if not InternalInterface.AccountSettings.Auctions.BypassCancelPopup then
				local manager = GetPopupManager()
				if manager then
					manager:ShowPopup(addonID .. ".CancelAuction", callback)
				end				
			else
				callback()
			end
		end
	end
	
	return cell
end
]]
function InternalInterface.UI.MapFrame(name, parent)
	local frame = UICreateFrame("Frame", name, parent)
	
	local mapPanel = Panel(name .. ".MapPanel", frame)
	local mapStatusLabel = UICreateFrame("Text", mapPanel:GetName() .. ".MapStatusLabel", mapPanel:GetContent())
	local mainTreeFrame = UICreateFrame("Frame", mapPanel:GetName() .. ".MainTreeFrame", mapPanel:GetContent())
	local categoryFrames = {}
	local itemFrames = {}
	
	local refreshButton = UICreateFrame("RiftButton", frame:GetName() .. ".RefreshButton", frame)
	
--[[	
	local anchor = UICreateFrame("Frame", name .. ".Anchor", frame)
	
	local sellingGrid = DataGrid(name .. ".SellingGrid", frame)
	
	local collapseButton = UICreateFrame("Texture", name .. ".CollapseButton", frame)
	local filterTextPanel = Panel(name .. ".FilterTextPanel", frame)
	local filterTextField = UICreateFrame("RiftTextfield", name .. ".FilterTextField", filterTextPanel:GetContent())
	
	local filterFrame = UICreateFrame("Frame", name .. ".FilterFrame", frame)
	local filterCharacterCheck = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterCharacterCheck", filterFrame)
	local filterCharacterText = UICreateFrame("Text", filterFrame:GetName() .. ".FilterCharacterText", filterFrame)
	local filterCompetitionText = UICreateFrame("Text", filterFrame:GetName() .. ".FilterCompetitionText", filterFrame)
	local filterCompetitionSelector = Dropdown(filterFrame:GetName() .. ".FilterCompetitionSelector", filterFrame)
	local filterBelowText = UICreateFrame("Text", filterFrame:GetName() .. ".FilterBelowText", filterFrame)
	local filterBelowSlider = Slider(filterFrame:GetName() .. ".FilterBelowSlider", filterFrame)
	local filterScorePanel = Panel(filterFrame:GetName() .. ".FilterScorePanel", filterFrame)
	local filterScoreTitle = ShadowedText(filterFrame:GetName() .. ".FilterScoreTitle", filterScorePanel:GetContent())
	local filterScoreChecks = {}
	local filterScoreTexts = {}
	for index = 0, 5 do
		filterScoreChecks[index + 1] = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore" .. tostring(index) .. "Check", filterScorePanel:GetContent())
		filterScoreTexts[index + 1] = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScore" .. tostring(index) .. "Text", filterScorePanel:GetContent())
	end
	
	local auctionsGrid = InternalInterface.UI.OldItemAuctionsGrid(name .. ".ItemAuctionsGrid", filterFrame)
]]

	local fullTree = {}
	local flattenedTree = {}
	local oldItems = {}
	local totalCount = 0
	local currentCategory = BASE_CATEGORY
	
	local function ShowError(e)
		fullTree = {}
		flattenedTree = {}
		oldItems = {}
		totalCount = 0
		
		mapStatusLabel:SetText("ERROR") -- LOCALIZE
		mainTreeFrame:SetVisible(false)
		
		print(e)
	end
	
	local function CreateItemFrame(categoryFrame)
		local index = #itemFrames[categoryFrame] + 1

		local itemFrame = UICreateFrame("Frame", categoryFrame:GetName() .. ".ItemTree." .. index, categoryFrame)
		local contentFrame = UICreateFrame("Frame", itemFrame:GetName() .. ".Content", itemFrame)

		local itemType = nil
		local name = nil
		local currentAverage = 0
		local oldAverage = 0
		
		itemFrame:SetBackgroundColor(0, 0, 0.1, 1)
		
		contentFrame:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 1, 1)
		contentFrame:SetPoint("BOTTOMRIGHT", itemFrame, "BOTTOMRIGHT", -1, -1)

		function itemFrame:Setup(data)
			if not data then
				itemFrame:SetVisible(false)
			else
				itemFrame:SetVisible(true)
				
				itemFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", data.left + 1, data.top + 1)
				itemFrame:SetWidth(data.width - 2)
				itemFrame:SetHeight(data.height - 2)
				
				itemType = data.element.itemType
				name = data.element.name
				currentAverage = math.ceil(data.element.total / data.element.units)
				
				local oldData = oldItems[itemType]
				if not oldData then
					oldAverage = 0
					contentFrame:SetBackgroundColor(0.25, 0.5, 0.75, 1)
				else
					oldAverage = math.ceil(oldData.total / oldData.units)
					
					if currentAverage >= oldAverage then
						local deviation = math.min(currentAverage / oldAverage - 1, 1)
						contentFrame:SetBackgroundColor(1 - deviation, 1, 0.9 * (1 - deviation), 1)
					else
						local deviation = math.min(oldAverage / currentAverage - 1, 1)
						contentFrame:SetBackgroundColor(1, 1 - deviation, 0.9 * (1 - deviation), 1)
					end
				end
			end
		end
		
		contentFrame:EventAttach(Event.UI.Input.Mouse.Cursor.In,
			function()
				pcall(CTooltip, itemType)
				print(name .. ": " .. oldAverage .. " / " .. currentAverage)
			end, contentFrame:GetName() .. ".OnMouseIn")
		
		contentFrame:EventAttach(Event.UI.Input.Mouse.Cursor.Out,
			function()
				pcall(CTooltip, nil)
			end, contentFrame:GetName() .. ".OnMouseOut")
		
		itemFrames[categoryFrame][index] = itemFrame
	end
	
	local function CreateCategoryFrame()
		local index = #categoryFrames + 1
		
		local categoryFrame = UICreateFrame("Frame", mainTreeFrame:GetName() .. ".CategoryTree." .. index, mainTreeFrame)
		local contentFrame = UICreateFrame("Frame", categoryFrame:GetName() .. ".Content", categoryFrame)
		
		contentFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 8, 8)
		contentFrame:SetPoint("BOTTOMRIGHT", categoryFrame, "BOTTOMRIGHT", -8, -8)
		
		function categoryFrame:Setup(data)
			if not data then
				categoryFrame:SetVisible(false)
			else
				categoryFrame:SetVisible(true)
				
				categoryFrame:SetPoint("TOPLEFT", mainTreeFrame, "TOPLEFT", data.left + 2, data.top + 2)
				categoryFrame:SetWidth(data.width - 4)
				categoryFrame:SetHeight(data.height - 4)
				categoryFrame:SetBackgroundColor((index % 3) / 3, (index % 5) / 5, (index % 7) / 7, 1)
				
				local category = data.element
				
				local catWidth, catHeight = contentFrame:GetWidth(), contentFrame:GetHeight()
				local catArea = catWidth * catHeight
				
				local lastItemVisible = #category.itemTypes
				local correctedCount = category.count
				while lastItemVisible > 0 do
					if category.itemTypes[lastItemVisible].count * catArea / correctedCount < MIN_ITEM_AREA then
						correctedCount = correctedCount - category.itemTypes[lastItemVisible].count
						lastItemVisible = lastItemVisible - 1
					else
						break
					end
				end

				local tree = { count = correctedCount, width = catWidth, height = catHeight, elements = {} }
				for i = 1, lastItemVisible do
					tree.elements[#tree.elements + 1] = category.itemTypes[i]
				end
				
				DivideTree(tree)
				tree.left = 0
				tree.top = 0
					
				local parts = ExtractParts(tree)
				local numParts = 0
				for part in pairs(parts) do
					Release()
						
					numParts = numParts + 1
						
					if not itemFrames[contentFrame][numParts] then
						CreateItemFrame(contentFrame)
					end
						
					itemFrames[contentFrame][numParts]:Setup(part)
				end
					
				for index = numParts + 1, #itemFrames[contentFrame] do
					itemFrames[contentFrame][index]:Setup(nil)
				end				
			end
		end
		
		categoryFrames[index] = categoryFrame
		itemFrames[contentFrame] = {}
	end
	
	local function DrawTree()
		if totalCount > 0 then
			mapStatusLabel:SetText("DRAWING") -- LOCALIZE
			
			CreateTask(
				function()
					local totalWidth, totalHeight = mainTreeFrame:GetWidth(), mainTreeFrame:GetHeight()
					local totalArea = totalWidth * totalHeight
					
					local lastCategoryVisible = #flattenedTree
					local correctedCount = totalCount
					while lastCategoryVisible > 0 do
						if flattenedTree[lastCategoryVisible].count * totalArea / correctedCount < MIN_CATEGORY_AREA then
							correctedCount = correctedCount - flattenedTree[lastCategoryVisible].count
							lastCategoryVisible = lastCategoryVisible - 1
						else
							break
						end
					end
					
					local tree = { count = correctedCount, width = totalWidth, height = totalHeight, elements = {} }
					for i = 1, lastCategoryVisible do
						tree.elements[#tree.elements + 1] = flattenedTree[i]
					end
					
					DivideTree(tree)
					
					tree.left = 0
					tree.top = 0
					
					local parts = ExtractParts(tree)
					
					local numParts = 0
					for part in pairs(parts) do
						Release()
						
						numParts = numParts + 1
						
						if not categoryFrames[numParts] then
							CreateCategoryFrame()
						end
						
						categoryFrames[numParts]:Setup(part)
					end
					
					for index = numParts + 1, #categoryFrames do
						categoryFrames[index]:Setup(nil)
					end
					
					mainTreeFrame:SetVisible(true)
				end, nil, ShowError)
		else
			mapStatusLabel:SetText("NO DATA") -- LOCALIZE
		end
	end
	
	local function FlattenTree(category)
		mapStatusLabel:SetText("FLATTENING") -- LOCALIZE
		
		flattenedTree = {}
		totalCount = 0
		currentCategory = category or BASE_CATEGORY
		
		CreateTask(
			function()
				local currentDetail = CDetail(currentCategory)
				
				local subCategories = { [currentCategory] = { name = currentDetail.name, itemTypes = {}, count = 0, buckets = { currentCategory } } }
				if currentDetail.children then
					for _, child in pairs(currentDetail.children) do
						local childDetail = CDetail(child)
						
						local index = 1
						local extendedChildren = { child }
						while extendedChildren[index] do
							local this = extendedChildren[index]
							local thisDetail = CDetail(this)
							
							if thisDetail.children then
								for _, thisChild in pairs(thisDetail.children) do
									extendedChildren[#extendedChildren + 1] = thisChild
								end
							end
							
							index = index + 1
						end
						
						subCategories[child] = { name = childDetail.name, itemTypes = {}, count = 0, buckets = extendedChildren, }
					end
				end
				
				Release()
				
				for subCategory, subCategoryData in pairs(subCategories) do
					local iterators = {}
					for _, bucket in pairs(subCategoryData.buckets) do
						if fullTree[bucket] then
							local current = 1
							local iterator =
							{
								Current = function() return fullTree[bucket][current] end,
								Next = function() current = current + 1; return fullTree[bucket][current] end,
							}
							iterators[iterator] = true
						end
					end

					while next(iterators) do
						Release()
					
						local selectedIterator, selectedValue = nil, nil
						for iterator in pairs(iterators) do
							local value = iterator.Current()
							if not selectedIterator or value.count > selectedValue.count then
								selectedIterator = iterator
								selectedValue = value
							end
						end
						
						subCategoryData.itemTypes[#subCategoryData.itemTypes + 1] = selectedValue
						subCategoryData.count = subCategoryData.count + selectedValue.count
						totalCount = totalCount + selectedValue.count
						
						if not selectedIterator.Next() then
							iterators[selectedIterator] = nil
						end
					end
				end
			
				local sortFunction = function(a, b) return b.count < a.count end
				for _, subCategoryData in pairs(subCategories) do
					subCategoryData.buckets = nil
					BinaryInsert(flattenedTree, subCategoryData, sortFunction)
				end
				
			end, DrawTree, ShowError)
	end
	
	local function BuildTree(auctions)
		mapStatusLabel:SetText("BUILDING") -- LOCALIZE
		
		fullTree = {}
		
		CreateTask(
			function()
				if auctions then
					local itemsByCategory = {}
					
					for auctionID, auctionData in pairs(auctions) do
						if auctionData.buyoutPrice then
							local itemType, category = auctionData.itemType, auctionData.itemCategory
							
							itemsByCategory[category] = itemsByCategory[category] or {}
							itemsByCategory[category][itemType] = itemsByCategory[category][itemType] or
							{
								itemType = itemType,
								name = auctionData.itemName,
								icon = auctionData.itemIcon,
								rarity = auctionData.itemRarity,
								count = 0,
								units = 0,
								total = 0,
							}
							
							itemsByCategory[category][itemType].count = itemsByCategory[category][itemType].count + 1
							--itemsByCategory[category][itemType].count = itemsByCategory[category][itemType].count + auctionData.stack
							itemsByCategory[category][itemType].units = itemsByCategory[category][itemType].units + auctionData.stack
							itemsByCategory[category][itemType].total = itemsByCategory[category][itemType].total + auctionData.buyoutPrice
						end
						
						Release()
					end
					
					for category, categoryItems in pairs(itemsByCategory) do
						fullTree[category] = fullTree[category] or {}
						
						local sortFunction = function(a, b) return categoryItems[b.itemType].count < categoryItems[a.itemType].count end
						for item, itemData in pairs(categoryItems) do
							BinaryInsert(fullTree[category], itemData, sortFunction)
						end
						
						Release()
					end
				end
			end, function() FlattenTree(BASE_CATEGORY) end, ShowError)
	end
	
	local function ProcessOldAuctions(auctions, oldAuctions)
		mapStatusLabel:SetText("PROCESSING AUCTIONS") -- LOCALIZE
		
		oldItems = {}
		
		CreateTask(
			function()
				if oldAuctions then
					for auctionID, auctionData in pairs(oldAuctions) do
						if auctionData.buyoutPrice then
							local itemType = auctionData.itemType
							
							oldItems[itemType] = oldItems[itemType] or
							{
								units = 0,
								total = 0,
							}
							
							oldItems[itemType].units = oldItems[itemType].units + auctionData.stack
							oldItems[itemType].total = oldItems[itemType].total + auctionData.buyoutPrice
						end
						
						Release()
					end
				end
			end, function() BuildTree(auctions) end, ShowError)
		end
	
	local function LoadOldAuctions(auctions)
		GetAllAuctionData(function(oldAuctions) ProcessOldAuctions(auctions, oldAuctions) end, nil, ITServer() - 8 * 24 * 60 * 60, ITServer() - 6 * 24 * 60 * 60)
	end
	
	local function LoadAuctions()
		mapStatusLabel:SetText("LOADING AUCTIONS") -- LOCALIZE
		mainTreeFrame:SetVisible(false)
		GetActiveAuctionData(LoadOldAuctions)
	end

--[[	
	local function ResetAuctions()
		GetOwnAuctionsScoredCompetition(function(auctions) sellingGrid:SetData(auctions) end)
	end
	
	local function SellingGridFilter(key, value)
		if (value.competitionBelow or 0) < filterBelowSlider:GetPosition() then return false end
	
		if (value.competitionQuintile or 1) < filterCompetitionSelector:GetSelectedValue() then return false end

		if filterCharacterCheck:GetChecked() and value.sellerName ~= GetPlayerName() then return false end

		local scoreIndex = InternalInterface.UI.ScoreIndexByScore(value.score) or 0
		if not filterScoreChecks[scoreIndex + 1]:GetChecked() then return false end

		local filterText = SUpper(filterTextField:GetText())
		local upperName = SUpper(value.itemName)
		if not SFind(upperName, filterText) then return false end

		return true
	end
	
	local function ScoreValue(value)
		if not value then return "" end
		return MFloor(MMin(value, 999)) .. " %"
	end

	local function ScoreColor(value)
		local r, g, b = unpack(ScoreColorByScore(value))
		return { r, g, b, 0.1 }
	end
	
	local function CompetitionString(value)
		if not value.competitionBelow or not value.competitionQuintile then return "" end
		return SFormat("%s (%d)", L["General/CompetitionName" .. value.competitionQuintile], value.competitionBelow)
	end
]]

	mapPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 40)
	mapPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, -40)
	mapPanel:GetContent():SetBackgroundColor(0, 0.05, 0.05, 0.5)
	mapPanel:SetInvertedBorder(true)
	
	mapStatusLabel:SetPoint("CENTER", mapPanel:GetContent(), "CENTER")
	mapStatusLabel:SetFontSize(20)
	mapStatusLabel:SetFontColor(1, 1, 0.75, 1)
	mapStatusLabel:SetEffectGlow({})
	mapStatusLabel:SetText("No data") -- LOCALIZE
	mapStatusLabel:SetLayer(100)
	
	mainTreeFrame:SetAllPoints()
	mainTreeFrame:SetBackgroundColor(1, 1, 1, 1)
	mainTreeFrame:SetVisible(false)
	mainTreeFrame:SetLayer(200)
	
	refreshButton:SetPoint("CENTERRIGHT", frame, "BOTTOMRIGHT", -5, -20)
	refreshButton:SetText("Refresh") -- LOCALIZE

--[[	
	anchor:SetPoint("CENTERRIGHT", frame, "BOTTOMRIGHT", 0, -300)
	
	sellingGrid:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 5)
	sellingGrid:SetPoint("BOTTOMRIGHT", anchor, "CENTERRIGHT", -5, 0)
	sellingGrid:SetRowHeight(62)
	sellingGrid:SetRowMargin(2)
	sellingGrid:SetHeadersVisible(true)
	sellingGrid:SetUnselectedRowBackgroundColor({0.15, 0.1, 0.1, 1})
	sellingGrid:SetSelectedRowBackgroundColor({0.45, 0.3, 0.3, 1})
	sellingGrid:AddColumn("item", L["SellingFrame/ColumnItem"], SellingAuctionCellType, 300, 1, nil, "itemName")
	sellingGrid:AddColumn("minexpire", L["SellingFrame/ColumnMinExpire"], "Text", 100, 0, "minExpireTime", true, { Alignment = "center", Formatter = RemainingTimeFormatter })
	sellingGrid:AddColumn("maxexpire", L["SellingFrame/ColumnMaxExpire"], "Text", 100, 0, "maxExpireTime", true, { Alignment = "center", Formatter = RemainingTimeFormatter })
	sellingGrid:AddColumn("bid", L["SellingFrame/ColumnBid"], "MoneyCellType", 130, 0, "bidPrice", true)
	sellingGrid:AddColumn("buy", L["SellingFrame/ColumnBuy"], "MoneyCellType", 130, 0, "buyoutPrice", true)
	sellingGrid:AddColumn("unitbid", L["SellingFrame/ColumnBidPerUnit"], "MoneyCellType", 130, 0, "bidUnitPrice", true)
	sellingGrid:AddColumn("unitbuy", L["SellingFrame/ColumnBuyPerUnit"], "MoneyCellType", 130, 0, "buyoutUnitPrice", true)
	sellingGrid:AddColumn("score", L["SellingFrame/ColumnScore"], "Text", 80, 0, "score", true, { Alignment = "center", Formatter = ScoreValue, Color = ScoreColor })
	sellingGrid:AddColumn("competition", L["SellingFrame/ColumnCompetition"], "Text", 120, 0, nil, "competitionOrder", { Alignment = "center", Formatter = CompetitionString })
	sellingGrid:AddColumn("cancellable", nil, CancellableCellType, 48, 0)
	sellingGrid:AddColumn("background", nil, "WideBackgroundCellType", 0, 0)
	sellingGrid:SetFilter(SellingGridFilter)		
	sellingGrid:SetOrder("minexpire", false)
	sellingGrid:GetInternalContent():SetBackgroundColor(0, 0.05, 0.05, 0.5)	
	
	collapseButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 5, -5)
	collapseButton:SetTextureAsync(addonID, "Textures/ArrowDown.png")

	filterTextPanel:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 35, -33)
	filterTextPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, -3)
	filterTextPanel:SetInvertedBorder(true)
	filterTextPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	filterTextField:SetPoint("CENTERLEFT", filterTextPanel:GetContent(), "CENTERLEFT", 2, 1)
	filterTextField:SetPoint("CENTERRIGHT", filterTextPanel:GetContent(), "CENTERRIGHT", -2, 1)
	filterTextField:SetText("")
	
	filterFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 5, -34)
	filterFrame:SetPoint("TOPRIGHT", anchor, "CENTERRIGHT", -5, 0)

	filterCharacterCheck:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 5, 15)
	filterCharacterCheck:SetChecked(InternalInterface.AccountSettings.Auctions.RestrictCharacterFilter)
	
	filterCharacterText:SetPoint("CENTERLEFT", filterCharacterCheck, "CENTERRIGHT", 5, 0)
	filterCharacterText:SetText(L["SellingFrame/FilterSeller"])
	
	filterCompetitionText:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 5, 60)
	filterCompetitionText:SetText(L["SellingFrame/FilterCompetition"])
	
	filterCompetitionSelector:SetPoint("CENTERLEFT", filterCompetitionText, "CENTERRIGHT", 5, 0)
	filterCompetitionSelector:SetPoint("TOPRIGHT", filterFrame, "TOPLEFT", 290, 53)
	filterCompetitionSelector:SetTextSelector("displayName")
	filterCompetitionSelector:SetOrderSelector("order")
	filterCompetitionSelector:SetValues({
		[1] = { displayName = L["General/CompetitionName1"], order = 1, },
		[2] = { displayName = L["General/CompetitionName2"], order = 2, },
		[3] = { displayName = L["General/CompetitionName3"], order = 3, },
		[4] = { displayName = L["General/CompetitionName4"], order = 4, },
		[5] = { displayName = L["General/CompetitionName5"], order = 5, },
	})
	filterCompetitionSelector:SetSelectedKey(InternalInterface.AccountSettings.Auctions.DefaultCompetitionFilter)
	
	filterBelowText:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 5, 110)
	filterBelowText:SetText(L["SellingFrame/FilterBelow"])
	
	filterBelowSlider:SetPoint("CENTERLEFT", filterBelowText, "CENTERRIGHT", 5, 0)
	filterBelowSlider:SetPoint("CENTERRIGHT", filterFrame, "TOPLEFT", 290, 115)
	filterBelowSlider:SetRange(0, 20)
	filterBelowSlider:SetPosition(InternalInterface.AccountSettings.Auctions.DefaultBelowFilter)
	
	filterScorePanel:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 0, 150)
	filterScorePanel:SetPoint("BOTTOMRIGHT", filterFrame, "BOTTOMLEFT", 290, -5)
	
	filterScoreTitle:SetPoint("CENTER", filterScorePanel:GetContent(), 1/2, 1/8)
	filterScoreTitle:SetText(L["SellingFrame/FilterScore"])
	filterScoreTitle:SetFontSize(14)
	filterScoreTitle:SetFontColor(1, 1, 0.75, 1)
	filterScoreTitle:SetShadowOffset(2, 2)	
	
	for index = 0, 5 do
		filterScoreChecks[index + 1]:SetPoint("CENTERLEFT", filterScorePanel:GetContent(), (index % 2) / 2, (3 + 2 * MFloor(index / 2)) / 8, 5, 0)
		filterScoreChecks[index + 1]:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[index + 1] or false)
		filterScoreTexts[index + 1]:SetPoint("CENTERLEFT", filterScoreChecks[index + 1], "CENTERRIGHT", 5, 0)
		filterScoreTexts[index + 1]:SetText(L["General/ScoreName" .. tostring(index)])
	end
	
	auctionsGrid:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 295, 5)
	auctionsGrid:SetPoint("BOTTOMRIGHT", filterFrame, "BOTTOMRIGHT", 0, -5)	
]]

	refreshButton:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function(self, h)
			LoadAuctions()
		end, refreshButton:GetName() .. ".OnLeftClick")

--[[
	function sellingGrid.Event:SelectionChanged(key, value)
		auctionsGrid:SetItemType(value and value.itemType or nil, key)
		auctionsGrid:SetSelectedKey(key)
	end
	
	function collapseButton.Event:LeftClick()
		filterFrame:SetVisible(collapsed)
		collapsed = not collapsed
		anchor:SetPoint("CENTERRIGHT", frame, "BOTTOMRIGHT", 0, collapsed and -34 or -300)
		self:SetTextureAsync(addonID, collapsed and "Textures/ArrowUp.png" or "Textures/ArrowDown.png")
	end
	
	function filterTextPanel.Event:LeftClick()
		filterTextField:SetKeyFocus(true)
	end

	function filterTextField.Event:KeyFocusGain()
		local length = SLen(self:GetText())
		if length > 0 then
			self:SetSelection(0, length)
		end
	end

	local function UpdateFilter() sellingGrid:RefreshFilter() end
	
	filterTextField.Event.TextfieldChange = UpdateFilter
	filterCharacterCheck.Event.CheckboxChange = UpdateFilter
	filterCompetitionSelector.Event.SelectionChanged = UpdateFilter
	filterBelowSlider.Event.PositionChanged = UpdateFilter
	for index = 0, 5 do
		filterScoreChecks[index + 1].Event.CheckboxChange = UpdateFilter
	end
]]
	function frame:Show()
		--auctionsGrid:SetEnabled(true)
		--ResetAuctions()
	end
	
	function frame:Hide()
		--auctionsGrid:SetEnabled(false)
	end	
--[[	
	function frame:ItemRightClick(params)
		if params and params.id then
			local ok, itemDetail = pcall(IIDetail, params.id)
			if not ok or not itemDetail or not itemDetail.name then return false end
			filterTextField:SetText(itemDetail.name)
			UpdateFilter()
			return true
		end
		return false
	end
	
	TInsert(Event.Interaction, { function(interaction) if frame:GetVisible() and interaction == "auction" then UpdateFilter() end end, addonID, addonID .. ".SellingFrame.OnInteraction" })
	TInsert(Event.LibPGC.AuctionData, { function() if frame:GetVisible() then ResetAuctions() end end, addonID, addonID .. ".SellingFrame.OnAuctionData" })
	
	collapseButton.Event.LeftClick(collapseButton) -- FIXME Event model
]]	
	return frame
end
