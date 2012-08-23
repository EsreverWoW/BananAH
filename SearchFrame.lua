-- ***************************************************************************************************************************************************
-- * SearchFrame.lua                                                                                                                                 *
-- ***************************************************************************************************************************************************
-- * Search tab frame                                                                                                                                *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.08 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local DataGrid = Yague.DataGrid
local Dropdown = Yague.Dropdown
local MoneySelector = Yague.MoneySelector
local Panel = Yague.Panel
local ShadowedText = Yague.ShadowedText
local BuildConfigFrame = InternalInterface.UI.BuildConfigFrame
local CABid = Command.Auction.Bid
local GetAuctionBidCallback = LibPGC.GetAuctionBidCallback
local GetAuctionBuyCallback = LibPGC.GetAuctionBuyCallback
local GetAuctionCached = LibPGC.GetAuctionCached
local GetAuctionSearchers = LibPGCEx.GetAuctionSearchers
local GetAuctionSearcherExtraDescription = LibPGCEx.GetAuctionSearcherExtraDescription
local GetLocalizedDateString = InternalInterface.Utility.GetLocalizedDateString
local GetPopupManager = InternalInterface.Output.GetPopupManager
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local IInteraction = Inspect.Interaction
local L = InternalInterface.Localization.L
local MFloor = math.floor
local MMax = math.max
local MMin = math.min
local RegisterPopupConstructor = Yague.RegisterPopupConstructor
local RemainingTimeFormatter = InternalInterface.Utility.RemainingTimeFormatter
local SLen = string.len
local ScoreAuctions = InternalInterface.PGCExtensions.ScoreAuctions
local ScoreColorByScore = InternalInterface.UI.ScoreColorByScore
local SearchAuctions = LibPGCEx.SearchAuctions
local TInsert = table.insert
local Time = os.time
local ODate = os.date
local UICreateFrame = UI.CreateFrame
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local unpack = unpack

local function SearchCellType(name, parent)
	local searchCell = UICreateFrame("Mask", name, parent)
	local itemTextureBackground = UICreateFrame("Frame", name .. ".ItemTextureBackground", searchCell)
	local itemTexture = UICreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = ShadowedText(name .. ".ItemNameLabel", searchCell)
	local itemStackLabel = ShadowedText(name .. ".ItemStackLabel", searchCell)	
	
	local itemType = nil
	
	itemTextureBackground:SetPoint("CENTERLEFT", searchCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("TOPLEFT", itemTextureBackground, "TOPRIGHT", 4, 0)
	
	itemStackLabel:SetPoint("BOTTOMLEFT", itemTextureBackground, "BOTTOMRIGHT", 4, -3)	
	
	function searchCell:SetValue(key, value, width, extra)
		self:SetWidth(width)
		
		itemTextureBackground:SetBackgroundColor(GetRarityColor(value.itemRarity))
		
		itemTexture:SetTextureAsync("Rift", value.itemIcon)
		
		itemNameLabel:SetText(value.itemName)
		itemNameLabel:SetFontColor(GetRarityColor(value.itemRarity))
		
		itemStackLabel:SetText("x" .. (value.stack or 0))

		itemType = value.itemType
	end
	
	function itemTexture.Event:MouseIn()
		Command.Tooltip(itemType)
	end
	
	function itemTexture.Event:MouseOut()
		Command.Tooltip(nil)
	end
	
	return searchCell
end

local function SaveSearchPopup(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".SaveSearchPopup", parent)
	
	local titleText = ShadowedText(frame:GetName() .. ".TitleText", frame)
	local contentText = UICreateFrame("Text", frame:GetName() .. ".ContentText", frame)
	local namePanel = Panel(frame:GetName() .. ".NamePanel", frame)
	local nameField = UICreateFrame("RiftTextfield", frame:GetName() .. ".NameField", namePanel:GetContent())
	local saveButton = UICreateFrame("RiftButton", frame:GetName() .. ".SaveButton", frame)
	local cancelButton = UICreateFrame("RiftButton", frame:GetName() .. ".CancelButton", frame)	
	
	frame:SetWidth(400)
	frame:SetHeight(140)
	frame:SetBackgroundColor(0, 0, 0, 0.9)
	
	titleText:SetPoint("TOPCENTER", frame, "TOPCENTER", 0, 10)
	titleText:SetFontSize(14)
	titleText:SetFontColor(1, 1, 0.75, 1)
	titleText:SetShadowOffset(2, 2)
	titleText:SetText("SAVE SEARCH") -- LOCALIZE
	
	contentText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 40)
	contentText:SetText("Saved search name:") -- LOCALIZE
	
	namePanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 60)
	namePanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, -50)
	namePanel:SetInvertedBorder(true)
	namePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	nameField:SetPoint("CENTERLEFT", namePanel:GetContent(), "CENTERLEFT", 2, 1)
	nameField:SetPoint("CENTERRIGHT", namePanel:GetContent(), "CENTERRIGHT", -2, 1)
	nameField:SetText("")
	
	saveButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMCENTER", 0, -10)
	saveButton:SetText("Save")
	
	cancelButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMCENTER", 0, -10)
	cancelButton:SetText("Cancel")

	function namePanel.Event:LeftClick()
		nameField:SetKeyFocus(true)
	end

	function nameField.Event:KeyFocusGain()
		local length = SLen(self:GetText())
		if length > 0 then
			self:SetSelection(0, length)
		end
	end
	
	function nameField.Event:KeyUp(key)
		if key == "\13" and saveButton:GetEnabled() and saveButton.Event.LeftPress then
			saveButton.Event.LeftPress(saveButton)
		end
	end
	
	function nameField.Event:TextfieldChange()
		saveButton:SetEnabled(self:GetText() ~= "")
	end
	
	function cancelButton.Event:LeftPress()
		parent:HidePopup(addonID .. ".SaveSearch", frame)
	end
	
	function frame:SetData(proposedName, callback)
		nameField:SetText(proposedName)
		function saveButton.Event:LeftPress()
			callback(nameField:GetText()) 
			parent:HidePopup(addonID .. ".SaveSearch", frame)
		end
		nameField:SetKeyFocus(true)
	end
	
	return frame
end
RegisterPopupConstructor(addonID .. ".SaveSearch", SaveSearchPopup)

function InternalInterface.UI.SearchFrame(name, parent)
	local searchFrame = UICreateFrame("Frame", name, parent)
	
	local collapseButton = UICreateFrame("Texture", name .. ".CollapseButton", searchFrame)
	local itemNamePanel = Panel(name .. ".ItemNamePanel", searchFrame)
	local itemNameField = UICreateFrame("RiftTextfield", name .. ".ItemNameField", itemNamePanel:GetContent())
	local onlineButton = UICreateFrame("Texture", name .. ".OnlineButton", itemNamePanel:GetContent())
	local searchButton = UICreateFrame("RiftButton", name .. ".SearchButton", searchFrame)
	local clearButton = UICreateFrame("RiftButton", name .. ".ClearButton", searchFrame)
	local searcherDropdown = Dropdown(name .. ".SearcherDropdown", searchFrame)
	local saveButton = UICreateFrame("Texture", name .. ".SaveButton", searchFrame)
	local deleteButton = UICreateFrame("Texture", name .. ".DeleteButton", searchFrame)
	
	local searcherFrame = UICreateFrame("Frame", name .. ".SearcherFrame", searchFrame)

	local searchGrid = DataGrid(name .. ".SearchGrid", searchFrame)
	
	local controlFrame = UICreateFrame("Frame", name .. ".ControlFrame", searchGrid:GetContent())
	local trackButton = UICreateFrame("RiftButton", name .. ".TrackButton", controlFrame)
	local navigationFrame = UICreateFrame("Frame", name .. ".NavigationFrame", controlFrame)
	local pagePanel = Panel(navigationFrame:GetName() .. ".PagePanel", navigationFrame)
	local pageText = UICreateFrame("Text", navigationFrame:GetName() .. ".PageText", pagePanel:GetContent())
	local previousButton = UICreateFrame("Texture", name .. ".PreviousButton", navigationFrame)
	local nextButton = UICreateFrame("Texture", name .. ".NextButton", navigationFrame)
	local buyButton = UICreateFrame("RiftButton", name .. ".BuyButton", controlFrame)
	local bidButton = UICreateFrame("RiftButton", name .. ".BidButton", controlFrame)
	local auctionMoneySelector = MoneySelector(name .. ".AuctionMoneySelector", controlFrame)
	local noBidLabel = ShadowedText(name .. ".NoBidLabel", controlFrame)

	local collapsed = true
	local searchers = {}
	local currentSearcher = nil
	local lastSearcherUsed = nil
	local lastSearcherExtraInfo = {}
	local onlineMode = false -- TODO Get initial from config
	local onlineInfo = nil
	
	local function PerformSearch()
		local searchInfo = currentSearcher and searchers[currentSearcher] or nil
		local searchFrame = searchInfo and searchInfo.frame or nil
		local extra = searchFrame and searchFrame:GetExtra() or nil

		local function ProcessAuctions(auctions, onlineFeedback)
			local function ProcessAuctionsScored(auctionsScored)
				searchGrid:SetData(auctionsScored)
				onlineInfo = onlineFeedback
				if onlineInfo then
					onlineInfo.page = onlineInfo.page or 1
					pageText:SetText(tostring(onlineInfo.page))
					previousButton:SetVisible(onlineInfo.page > 1) 
					nextButton:SetVisible(onlineInfo.morePages and true or false) 
					navigationFrame:SetVisible(true)
				else
					navigationFrame:SetVisible(false)
				end
			end
			
			ScoreAuctions(ProcessAuctionsScored, auctions)
		end
		
		SearchAuctions(ProcessAuctions, searchInfo.baseSearcher or currentSearcher, onlineInfo, itemNameField:GetText(), extra)
	end
	
	local function ResetOnlineMode()
		local onlineCapable = currentSearcher and searchers[currentSearcher] and searchers[currentSearcher].online
		if not onlineCapable then
			onlineButton:SetTextureAsync(addonID, "Textures/DotGrey.png")
		elseif onlineMode then
			onlineButton:SetTextureAsync(addonID, "Textures/DotGreen.png")
		else
			onlineButton:SetTextureAsync(addonID, "Textures/DotRed.png")
		end
	end
	
	local function ResetSearchers()
		local auctionSearchers = GetAuctionSearchers()
		
		for searcherID, searcherName in pairs(auctionSearchers) do
			if not searchers[searcherID] then
				local searcherExtraDescription = GetAuctionSearcherExtraDescription(searcherID)
				
				local frame = BuildConfigFrame(searcherFrame:GetName() .. "." .. searcherID, searcherFrame, searcherExtraDescription)
				if frame then
					frame:SetPoint("TOPLEFT", searcherFrame, "TOPLEFT", 5, 5)
					frame:SetPoint("TOPRIGHT", searcherFrame, "TOPRIGHT", -5, 5)
					frame:SetVisible(false)
					frame:SetExtra({})
				end
				
				searchers[searcherID] =
				{
					displayName = searcherName,
					frame = frame,
					extra = {},
					extraInfo = searcherExtraDescription.ExtraInfo or {},
					online = searcherExtraDescription.Online,
				}
			end
		end
		
		for searcherID, searcherData in pairs(searchers) do
			if not auctionSearchers[searcherID] then
				searcherData.frame:SetVisible(false)
				searchers[searcherID] = nil
			end
		end
		
		local savedSearchs = InternalInterface.AccountSettings.Search.SavedSearchs or {}
		for savedID, savedInfo in pairs(savedSearchs) do
			local baseSearcher = savedInfo.baseSearcher and searchers[savedInfo.baseSearcher] or nil
			if baseSearcher then
				searchers[savedID] =
				{
					displayName = savedInfo.displayName,
					frame = baseSearcher.frame,
					extra = savedInfo.extra,
					extraInfo = baseSearcher.extraInfo,
					online = baseSearcher.online,
					baseSearcher = savedInfo.baseSearcher,
				}
			end
		end
		
		local prevSearcher = currentSearcher and searchers[currentSearcher] and currentSearcher or nil
		if not prevSearcher and searchers["basic"] then -- TODO Get default from config
			prevSearcher = "basic" -- TODO Get default from config
		end		 
		
		searcherDropdown:SetValues(searchers)
		if prevSearcher then
			searcherDropdown:SetSelectedKey(prevSearcher)
		end
	end

	local function RefreshAuctionButtons()
		local auctionSelected = false
		local auctionInteraction = IInteraction("auction")
		local selectedAuctionCached = false
		local selectedAuctionBid = false
		local selectedAuctionBuy = false
		local highestBidder = false
		local seller = false
		local bidPrice = 1
		local onlineCapable = currentSearcher and searchers[currentSearcher] and searchers[currentSearcher].online
		
		local selectedAuctionID, selectedAuctionData = searchGrid:GetSelectedData()
		if selectedAuctionID and selectedAuctionData then
			auctionSelected = true
			selectedAuctionCached = GetAuctionCached(selectedAuctionID) or false
			selectedAuctionBid = not selectedAuctionData.buyoutPrice or selectedAuctionData.bidPrice < selectedAuctionData.buyoutPrice
			selectedAuctionBuyout = selectedAuctionData.buyoutPrice and true or false
			highestBidder = (selectedAuctionData.ownBidded or 0) == selectedAuctionData.bidPrice
			seller = selectedAuctionData.own
			bidPrice = selectedAuctionData.bidPrice
		end
		
		searchButton:SetEnabled(not onlineCapable or not onlineMode or auctionInteraction)
		bidButton:SetEnabled(auctionSelected and auctionInteraction and selectedAuctionCached and selectedAuctionBid and not highestBidder and not seller)
		buyButton:SetEnabled(auctionSelected and auctionInteraction and selectedAuctionCached and selectedAuctionBuyout and not seller)

		if not auctionSelected then
			noBidLabel:SetText(L["ItemAuctionsGrid/ErrorNoAuction"]) -- LOCALIZE
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not selectedAuctionCached then
			noBidLabel:SetText(L["ItemAuctionsGrid/ErrorNotCached"]) -- LOCALIZE
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif seller then
			noBidLabel:SetText(L["ItemAuctionsGrid/ErrorSeller"]) -- LOCALIZE
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif highestBidder then
			noBidLabel:SetText(L["ItemAuctionsGrid/ErrorHighestBidder"]) -- LOCALIZE
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not auctionInteraction then
			noBidLabel:SetText(L["ItemAuctionsGrid/ErrorNoAuctionHouse"]) -- LOCALIZE
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not selectedAuctionBid then
			noBidLabel:SetText(L["ItemAuctionsGrid/ErrorBidEqualBuy"]) -- LOCALIZE
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		else
			auctionMoneySelector:SetValue(bidPrice + 1)
			auctionMoneySelector:SetVisible(true)
			noBidLabel:SetVisible(false)
		end
	end	
	
	local function ScoreValue(value)
		if not value then return "" end
		return MFloor(MMin(value, 999)) .. " %"
	end

	local function ScoreColor(value)
		local r, g, b = unpack(ScoreColorByScore(value))
		return { r, g, b, 0.1 }
	end

	collapseButton:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 5, 8)
	collapseButton:SetTextureAsync(addonID, "Textures/ArrowDown.png")

	searcherDropdown:SetPoint("TOPRIGHT", searchFrame, "TOPRIGHT", -65, 4)
	searcherDropdown:SetPoint("BOTTOMLEFT", searchFrame, "TOPRIGHT", -315, 36)
	searcherDropdown:SetTextSelector("displayName")
	searcherDropdown:SetOrderSelector("displayName")
	searcherDropdown:SetLayer(9000)
	
	saveButton:SetPoint("CENTERLEFT", searcherDropdown, "CENTERRIGHT", 6, 0)
	saveButton:SetTextureAsync(addonID, "Textures/Save.png")
	
	deleteButton:SetPoint("CENTERLEFT", searcherDropdown, "CENTERRIGHT", 35, 0)
	deleteButton:SetTextureAsync(addonID, "Textures/DeleteDisabled.png")
	
	clearButton:SetPoint("CENTERRIGHT", searcherDropdown, "CENTERLEFT", -5, 0)
	clearButton:SetText("Reset") -- LOCALIZE
	
	searchButton:SetPoint("TOPRIGHT", clearButton, "TOPLEFT", 10, 0)
	searchButton:SetText("Search") -- LOCALIZE
	
	itemNamePanel:SetPoint("CENTERLEFT", collapseButton, "CENTERRIGHT", 5, 0)
	itemNamePanel:SetPoint("TOPRIGHT", searchButton, "TOPLEFT", -5, 3)
	itemNamePanel:SetInvertedBorder(true)
	itemNamePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	onlineButton:SetPoint("CENTERRIGHT", itemNamePanel:GetContent(), "CENTERRIGHT", -2, 0)
	onlineButton:SetTextureAsync(addonID, "Textures/DotGrey.png")
	
	itemNameField:SetPoint("CENTERLEFT", itemNamePanel:GetContent(), "CENTERLEFT", 2, 1)
	itemNameField:SetPoint("CENTERRIGHT", itemNamePanel:GetContent(), "CENTERRIGHT", -20, 1)
	itemNameField:SetText("")
	
	searcherFrame:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 0, 40)
	searcherFrame:SetPoint("TOPRIGHT", searchFrame, "TOPRIGHT", 0, 40)
	searcherFrame:SetHeight(0)
	searcherFrame:SetLayer(8000)
	
	searchGrid:SetPoint("TOPLEFT", searcherFrame, "BOTTOMLEFT", 5, 0)
	searchGrid:SetPoint("BOTTOMRIGHT", searchFrame, "BOTTOMRIGHT", -5, -5)
	searchGrid:SetPadding(1, 1, 1, 38)
	searchGrid:SetHeadersVisible(true)
	searchGrid:SetRowHeight(62)
	searchGrid:SetRowMargin(2)
	searchGrid:SetUnselectedRowBackgroundColor({0.15, 0.1, 0.1, 1})
	searchGrid:SetSelectedRowBackgroundColor({0.45, 0.3, 0.3, 1})
	searchGrid:AddColumn("item", "Item", SearchCellType, 140, 3, nil, "itemName") -- LOCALIZE
	searchGrid:AddColumn("seller", "Seller", "Text", 120, 1, "sellerName", true, { Alignment = "center" }) -- LOCALIZE
	searchGrid:AddColumn("minexpire", "Min. expire", "Text", 90, 0, "minExpireTime", true, { Alignment = "right", Formatter = RemainingTimeFormatter }) -- LOCALIZE
	searchGrid:AddColumn("maxexpire", "Max. expire", "Text", 90, 0, "maxExpireTime", true, { Alignment = "right", Formatter = RemainingTimeFormatter }) -- LOCALIZE
	searchGrid:AddColumn("bid", "Bid", "MoneyCellType", 120, 0, "bidPrice", true) -- LOCALIZE
	searchGrid:AddColumn("buy","Buy", "MoneyCellType", 120, 0, "buyoutPrice", true) -- LOCALIZE
	searchGrid:AddColumn("unitbid", "Unit Bid", "MoneyCellType", 120, 0, "bidUnitPrice", true) -- LOCALIZE
	searchGrid:AddColumn("unitbuy", "Unit Buy", "MoneyCellType", 120, 0, "buyoutUnitPrice", true) -- LOCALIZE
	searchGrid:AddColumn("score", "Score", "Text", 60, 0, "score", true, { Alignment = "center", Formatter = ScoreValue, Color = ScoreColor }) -- LOCALIZE
	searchGrid:AddColumn("background", nil, "WideBackgroundCellType", 0, 0) -- TODO Move to BDataGrid	
	searchGrid:SetOrder("minexpire", false)		

	controlFrame:SetPoint("TOPLEFT", searchGrid:GetContent(), "BOTTOMLEFT", 3, -36)
	controlFrame:SetPoint("BOTTOMRIGHT", searchGrid:GetContent(), "BOTTOMRIGHT", -3, -2)

	trackButton:SetPoint("CENTERLEFT", controlFrame, "CENTERLEFT", 0, 0)
	trackButton:SetText("Track auction") -- LOCALIZE
	trackButton:SetEnabled(false)
	
	navigationFrame:SetPoint("CENTERLEFT", trackButton, "CENTERRIGHT")
	navigationFrame:SetPoint("CENTERRIGHT", auctionMoneySelector, "CENTERLEFT")
	navigationFrame:SetVisible(false)
	
	pagePanel:SetPoint("CENTER", navigationFrame, "CENTER")
	pagePanel:SetHeight(30)
	pagePanel:SetWidth(50)
	pagePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
	
	pageText:SetPoint("CENTER", pagePanel:GetContent(), "CENTER", 0, 0)
	pageText:SetText("0")
	
	previousButton:SetPoint("CENTERRIGHT", pagePanel, "CENTERLEFT", -10, 0)
	previousButton:SetTextureAsync(addonID, "Textures/MovePrevious.png")

	nextButton:SetPoint("CENTERLEFT", pagePanel, "CENTERRIGHT", 10, 0)
	nextButton:SetTextureAsync(addonID, "Textures/MoveNext.png")

	buyButton:SetPoint("CENTERRIGHT", controlFrame, "CENTERRIGHT", 0, 0)
	buyButton:SetText("Buy") -- LOCALIZE
	buyButton:SetEnabled(false)

	bidButton:SetPoint("CENTERRIGHT", buyButton, "CENTERLEFT", 10, 0)
	bidButton:SetText("Bid") -- LOCALIZE
	bidButton:SetEnabled(false)

	auctionMoneySelector:SetPoint("TOPRIGHT", bidButton, "TOPLEFT", -5, 2)
	auctionMoneySelector:SetPoint("BOTTOMLEFT", bidButton, "BOTTOMLEFT", -230, -2)
	auctionMoneySelector:SetVisible(false)
	
	noBidLabel:SetPoint("CENTER", bidButton, "CENTERLEFT", -115, 0)	
	noBidLabel:SetFontColor(1, 0.5, 0, 1)
	noBidLabel:SetShadowColor(0.05, 0, 0.1, 1)
	noBidLabel:SetShadowOffset(2, 2)
	noBidLabel:SetFontSize(14)
	
	function collapseButton.Event:LeftClick()
		local searchFrame = currentSearcher and searchers[currentSearcher] and searchers[currentSearcher].frame or nil
		if searchFrame then searchFrame:SetVisible(collapsed) end
		collapsed = not collapsed
		searcherFrame:SetHeight(not collapsed and searchFrame and searchFrame:GetHeight() + 10 or 0)
		self:SetTexture(addonID, collapsed and "Textures/ArrowDown.png" or "Textures/ArrowUp.png")
	end

	function itemNamePanel.Event:LeftClick()
		itemNameField:SetKeyFocus(true)
	end

	function itemNameField.Event:KeyFocusGain()
		local length = SLen(self:GetText())
		if length > 0 then
			self:SetSelection(0, length)
		end
	end
	
	-- 2012.08.11 Baanano: Key events don't seem to be hardware events, so Command.Auction.Bid fails
	-- function itemNameField.Event:KeyUp(key)
		-- if key == "\13" and searchButton:GetEnabled() then
			-- searchButton.Event.LeftPress(searchButton)
		-- end
	-- end
	
	function onlineButton.Event:LeftClick()
		local onlineCapable = currentSearcher and searchers[currentSearcher] and searchers[currentSearcher].online
		if not onlineCapable then return end
		onlineMode = not onlineMode
		ResetOnlineMode()
		RefreshAuctionButtons()
	end

	function searchButton.Event:LeftPress()
		local searchInfo = currentSearcher and searchers[currentSearcher] or nil
		local extraInfo = searchInfo and searchInfo.extraInfo or {}
		if currentSearcher ~= lastSearcherUsed then
			for columnID in pairs(lastSearcherExtraInfo) do
				searchGrid:RemoveColumn(columnID)
			end
			lastSearcherUsed = currentSearcher
			lastSearcherExtraInfo = {}
			for index, columnID in ipairs(extraInfo) do
				local columnInfo = extraInfo[columnID] or {}
				
				local columnName = columnInfo.name or ""
				local columnType = columnInfo.value
				if columnType == "money" then
					searchGrid:AddColumn(columnID, columnName, "MoneyCellType", 120, 0, columnID, true)
					lastSearcherExtraInfo[columnID] = true
				end
			end
		end
		
		local onlineCapable = searchInfo and searchInfo.online or false
		if onlineCapable and onlineMode then
			onlineInfo = { page = 1, sortType = "time", sortOrder = "descending", } -- FIXME
		else
			onlineInfo = false
		end
		
		PerformSearch()
	end
	
	function clearButton.Event:LeftPress()
		local searchInfo = currentSearcher and searchers[currentSearcher] or nil
		local frame = searchInfo and searchInfo.frame
		local extra = searchInfo and searchInfo.extra or {}
		if frame then
			frame:SetExtra(extra)
		end
		itemNameField:SetText(extra.text or "")
	end
	
	function searcherDropdown.Event:SelectionChanged(searcherID, searcherData)
		if searcherID == currentSearcher then return end
		
		if currentSearcher then
			local currentFrame = searchers[currentSearcher] and searchers[currentSearcher].frame
			if currentFrame then
				currentFrame:SetVisible(false)
			end
		end
		
		currentSearcher = searcherID
		
		if searcherData.frame then
			searcherData.frame:SetVisible(not collapsed)
			searcherData.frame:SetExtra(searcherData.extra)
			itemNameField:SetText(searcherData.extra.text or "")
			searcherFrame:SetHeight(collapsed and 0 or searcherData.frame:GetHeight() + 10)
		else
			searcherFrame:SetHeight(0)
		end
		
		deleteButton:SetTextureAsync(addonID, searcherData.baseSearcher and "Textures/DeleteEnabled.png" or "Textures/DeleteDisabled.png")
		
		ResetOnlineMode()
		RefreshAuctionButtons()
	end
	
	function saveButton.Event:LeftClick()
		local manager = GetPopupManager()
		local searchInfo = currentSearcher and searchers[currentSearcher] or nil
		local searchFrame = searchInfo and searchInfo.frame or nil
		local extra = searchFrame and searchFrame:GetExtra() or nil		
		if manager and extra then
			local timeStamp = Time()
			manager:ShowPopup(addonID .. ".SaveSearch", "Saved " .. GetLocalizedDateString("%x %X", timeStamp),
				function(name)
					InternalInterface.AccountSettings.Search.SavedSearchs["custom-" .. timeStamp] =
					{
						displayName = name, -- LOCALIZE
						extra = extra,
						baseSearcher = searchInfo.baseSearcher or currentSearcher,
					}
					currentSearcher = "custom-" .. timeStamp
					ResetSearchers()
				end)
		end		
	end
	
	function deleteButton.Event:LeftClick()
		InternalInterface.AccountSettings.Search.SavedSearchs[currentSearcher] = nil
		ResetSearchers()
	end
	
	function searchGrid.Event:SelectionChanged()
		RefreshAuctionButtons()
	end
	
	function previousButton.Event:LeftClick()
		if onlineInfo then
			onlineInfo.page = MMax(1, (onlineInfo.page or 1) - 1)
			PerformSearch()
		end
	end
	
	function nextButton.Event:LeftClick()
		if onlineInfo then
			onlineInfo.page = (onlineInfo.page or 1) + 1
			PerformSearch()
		end
	end
	
	function buyButton.Event:LeftPress()
		local auctionID, auctionData = searchGrid:GetSelectedData()
		if auctionID then
			CABid(auctionID, auctionData.buyoutPrice, GetAuctionBuyCallback(auctionID))
		end
	end
	
	function bidButton.Event:LeftPress()
		local auctionID = searchGrid:GetSelectedData()
		if auctionID then
			local bidAmount = auctionMoneySelector:GetValue()
			CABid(auctionID, bidAmount, GetAuctionBidCallback(auctionID, bidAmount))
		end
	end
	
	local function OnAuctionData()
		if searchFrame:GetVisible() then
			RefreshAuctionButtons()
		end
	end
	TInsert(Event.LibPGC.AuctionData, { OnAuctionData, addonID, addonID .. ".SearchFrame.OnAuctionData" })

	local function OnInteraction(interaction)
		if searchFrame:GetVisible() and interaction == "auction" then
			RefreshAuctionButtons()
		end
	end
	TInsert(Event.Interaction, { OnInteraction, addonID, addonID .. ".SearchFrame.OnInteraction" })
	
	function searchFrame:Show()
		RefreshAuctionButtons()
	end
	
	function searchFrame:Hide()
	end
	
	ResetSearchers()
--	InternalInterface.PGCExtensions.GetActiveAuctionsScored(function(auctions) searchGrid:SetData(auctions) end)
	
	return searchFrame
end