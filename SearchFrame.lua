-- ***************************************************************************************************************************************************
-- * SearchFrame.lua                                                                                                                                 *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.08 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local L = InternalInterface.Localization.L

local ScoreAuctions = InternalInterface.PGCExtensions.ScoreAuctions
local SearchAuctions = LibPGCEx.SearchAuctions

local function SearchCellType(name, parent)
	local searchCell = UI.CreateFrame("Mask", name, parent)
	local itemTextureBackground = UI.CreateFrame("Frame", name .. ".ItemTextureBackground", searchCell)
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemCached = UI.CreateFrame("Texture", name .. ".ItemCached", itemTextureBackground)
	local itemNameLabel = Yague.ShadowedText(name .. ".ItemNameLabel", searchCell)
	local itemStackLabel = Yague.ShadowedText(name .. ".ItemStackLabel", searchCell)	
	
	local itemType = nil
	
	itemTextureBackground:SetPoint("CENTERLEFT", searchCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	itemTexture:SetLayer(1)

	itemCached:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -2, -2)
	itemCached:SetLayer(2)
	itemCached:SetVisible(false)
	
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("TOPLEFT", itemTextureBackground, "TOPRIGHT", 4, 0)
	
	itemStackLabel:SetPoint("BOTTOMLEFT", itemTextureBackground, "BOTTOMRIGHT", 4, -3)	
	
	function searchCell:SetValue(key, value, width, extra)
		self:SetWidth(width)
		
		itemTextureBackground:SetBackgroundColor(InternalInterface.Utility.GetRarityColor(value.itemRarity))
		
		itemTexture:SetTextureAsync("Rift", value.itemIcon)
		
		if not LibPGC.Auction.Cached(key) then
			itemCached:SetTextureAsync(addonID, "Textures/AuctionUnavailable.png")
			itemCached:SetVisible(true)
		elseif value.reposted then
			itemCached:SetTextureAsync("Rift", "btn_video_encode.png.dds")
			itemCached:SetVisible(true)
		else
			itemCached:SetVisible(false)
		end
		
		itemNameLabel:SetText(value.itemName)
		itemNameLabel:SetFontColor(InternalInterface.Utility.GetRarityColor(value.itemRarity))
		
		itemStackLabel:SetText("x" .. (value.stack or 0))

		itemType = value.itemType
	end
	
	itemTexture:EventAttach(Event.UI.Input.Mouse.Cursor.In,
		function()
			pcall(Command.Tooltip, itemType)
		end, itemTexture:GetName() .. ".OnCursorIn")
	
	itemTexture:EventAttach(Event.UI.Input.Mouse.Cursor.Out,
		function()
			Command.Tooltip(nil)
		end, itemTexture:GetName() .. ".OnCursorOut")
	
	return searchCell
end

local function SaveSearchPopup(parent)
	local frame = Yague.Popup(parent:GetName() .. ".SaveSearchPopup", parent)
	
	local titleText = Yague.ShadowedText(frame:GetName() .. ".TitleText", frame:GetContent())
	local contentText = UI.CreateFrame("Text", frame:GetName() .. ".ContentText", frame:GetContent())
	local namePanel = Yague.Panel(frame:GetName() .. ".NamePanel", frame:GetContent())
	local nameField = UI.CreateFrame("RiftTextfield", frame:GetName() .. ".NameField", namePanel:GetContent())
	local saveButton = UI.CreateFrame("RiftButton", frame:GetName() .. ".SaveButton", frame:GetContent())
	local cancelButton = UI.CreateFrame("RiftButton", frame:GetName() .. ".CancelButton", frame:GetContent())
	
	local Callback = nil
	
	frame:SetWidth(420)
	frame:SetHeight(160)
	
	titleText:SetPoint("TOPCENTER", frame:GetContent(), "TOPCENTER", 0, 10)
	titleText:SetFontSize(14)
	titleText:SetFontColor(1, 1, 0.75, 1)
	titleText:SetShadowOffset(2, 2)
	titleText:SetText(L["SaveSearchPopup/Title"])
	
	contentText:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 10, 40)
	contentText:SetText(L["SaveSearchPopup/NameText"])
	
	namePanel:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 10, 60)
	namePanel:SetPoint("BOTTOMRIGHT", frame:GetContent(), "BOTTOMRIGHT", -10, -50)
	namePanel:SetInvertedBorder(true)
	namePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	nameField:SetPoint("CENTERLEFT", namePanel:GetContent(), "CENTERLEFT", 2, 1)
	nameField:SetPoint("CENTERRIGHT", namePanel:GetContent(), "CENTERRIGHT", -2, 1)
	nameField:SetText("")
	
	saveButton:SetPoint("BOTTOMRIGHT", frame:GetContent(), "BOTTOMCENTER", 0, -10)
	saveButton:SetText(L["SaveSearchPopup/ButtonSave"])
	
	cancelButton:SetPoint("BOTTOMLEFT", frame:GetContent(), "BOTTOMCENTER", 0, -10)
	cancelButton:SetText(L["SaveSearchPopup/ButtonCancel"])

	namePanel:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			nameField:SetKeyFocus(true)
		end, namePanel:GetName() .. ".OnLeftClick")

	nameField:EventAttach(Event.UI.Input.Key.Focus.Gain,
		function()
			local length = string.len(nameField:GetText())
			if length > 0 then
				nameField:SetSelection(0, length)
			end
		end, nameField:GetName() .. ".OnKeyFocusGain")
	
	nameField:EventAttach(Event.UI.Input.Key.Up,
		function(h, self, key)
			if key == "Return" and saveButton:GetEnabled() then
				if type(Callback) == "function" then
					Callback(nameField:GetText())
				end
				parent:HidePopup(addonID .. ".SaveSearch", frame)
			end
		end, nameField:GetName() .. ".OnKeyUp")
	
	nameField:EventAttach(Event.UI.Textfield.Change,
		function()
			saveButton:SetEnabled(nameField:GetText() ~= "")
		end, nameField:GetName() .. ".OnTextfieldChange")
	
	saveButton:EventAttach(Event.UI.Button.Left.Press,
		function()
			if type(Callback) == "function" then
				Callback(nameField:GetText())
			end
			parent:HidePopup(addonID .. ".SaveSearch", frame)
		end, saveButton:GetName() .. ".OnLeftPress")

	cancelButton:EventAttach(Event.UI.Button.Left.Press,
		function()
			parent:HidePopup(addonID .. ".SaveSearch", frame)
		end, cancelButton:GetName() .. ".OnLeftPress")
	
	function frame:SetData(proposedName, callback)
		nameField:SetText(proposedName)
		nameField:SetKeyFocus(true)
		Callback = callback
	end
	
	return frame
end
Yague.RegisterPopupConstructor(addonID .. ".SaveSearch", SaveSearchPopup)

function InternalInterface.UI.SearchFrame(name, parent)
	local searchFrame = UI.CreateFrame("Frame", name, parent)
	
	local collapseButton = UI.CreateFrame("Texture", name .. ".CollapseButton", searchFrame)
	local itemNamePanel = Yague.Panel(name .. ".ItemNamePanel", searchFrame)
	local itemNameField = UI.CreateFrame("RiftTextfield", name .. ".ItemNameField", itemNamePanel:GetContent())
	local onlineButton = UI.CreateFrame("Texture", name .. ".OnlineButton", itemNamePanel:GetContent())
	local searchButton = UI.CreateFrame("RiftButton", name .. ".SearchButton", searchFrame)
	local clearButton = UI.CreateFrame("RiftButton", name .. ".ClearButton", searchFrame)
	local searcherDropdown = Yague.Dropdown(name .. ".SearcherDropdown", searchFrame)
	local saveButton = UI.CreateFrame("Texture", name .. ".SaveButton", searchFrame)
	local deleteButton = UI.CreateFrame("Texture", name .. ".DeleteButton", searchFrame)
	
	local searcherFrame = UI.CreateFrame("Frame", name .. ".SearcherFrame", searchFrame)

	local searchGrid = Yague.DataGrid(name .. ".SearchGrid", searchFrame)
	
	local controlFrame = UI.CreateFrame("Frame", name .. ".ControlFrame", searchGrid:GetContent())
	local buyButton = UI.CreateFrame("RiftButton", name .. ".BuyButton", controlFrame)
	local bidButton = UI.CreateFrame("RiftButton", name .. ".BidButton", controlFrame)
	local auctionMoneySelector = Yague.MoneySelector(name .. ".AuctionMoneySelector", controlFrame)
	local noBidLabel = Yague.ShadowedText(name .. ".NoBidLabel", controlFrame)

	local collapsed = true
	local currentSearcher = nil
	local searchers = {}
	local extraColumns = {}
	local lastSearcherUsed = nil
	local searchTask = nil
	local searchParams = nil

	local function PerformSearch()
		searchGrid:SetData(nil, nil, nil, true)
		
		if not searchParams then return end

		searchGrid:ShowLoadingBar()
		
		if searchTask and not searchTask:Finished() then
			searchTask:Stop()
		end
		
		searchTask = blTasks.Task.Create(
			function(taskHandle)
--				local scoredAuctions = InternalInterface.PGCExtensions.ScoreAuctions(LibPGCEx.Search.Auctions(searchInfo.baseSearcher or currentSearcher, itemNameField:GetText(), extra):Result()):Result()
				local scoredAuctions = LibPGCEx.Search.Auctions(searchParams.searcher, searchParams.text, searchParams.extra):Result()
				
				taskHandle:BreathLong()

				searchGrid:SetData(scoredAuctions)
			end):Start():Abandon()
	end

	local function ResetSearchers()
		local auctionSearchers = LibPGCEx.Search.Filter.List()
		
		for searcherID in pairs(auctionSearchers) do
			if not searchers[searcherID] then
				local searcherDetail = LibPGCEx.Search.Filter.Get(searcherID)
				local searcherDefinition = searcherDetail and searcherDetail.definition
				if searcherDetail and searcherDetail.name and searcherDefinition then
					local frame = InternalInterface.UI.BuildConfigFrame(searcherFrame:GetName() .. "." .. searcherID, searcherFrame, searcherDefinition)
					if frame then
						frame:SetPoint("TOPLEFT", searcherFrame, "TOPLEFT", 5, 5)
						frame:SetPoint("TOPRIGHT", searcherFrame, "TOPRIGHT", -5, 5)
						frame:SetVisible(false)
						frame:SetExtra({})
					end
					
					local extraInfo = searcherDefinition.ExtraInfo or {}
					
					searchers[searcherID] =
					{
						displayName = searcherDetail.name,
						frame = frame,
						extra = {},
						extraInfo = extraInfo,
						online = searcherDefinition.Online,
					}
					
					
					local neededColumns = {}
					for i = 1, #extraInfo do
						local columnType = extraInfo[extraInfo[i]].value
						if columnType then
							neededColumns[columnType] = (neededColumns[columnType] or 0) + 1
						end
					end
					
					for columnType, num in pairs(neededColumns) do
						extraColumns[columnType] = extraColumns[columnType] or {}
						
						for i = #extraColumns[columnType] + 1, num do
							local columnID = tostring(columnType) .. "." .. i
							extraColumns[columnType][i] = columnID
							if columnType == "money" then
								searchGrid:AddColumn(columnID, columnID, "MoneyCellType", 120, 1, columnID, true, nil, true)
							end
						end
					end
				end
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
		if not prevSearcher and searchers[InternalInterface.AccountSettings.Search.DefaultSearcher] then
			prevSearcher = InternalInterface.AccountSettings.Search.DefaultSearcher
		end		 
		
		searcherDropdown:SetValues(searchers)
		if prevSearcher then
			searcherDropdown:SetSelectedKey(prevSearcher)
		end
	end

	local function RefreshAuctionButtons()
		local auctionSelected = false
		local auctionInteraction = Inspect.Interaction("auction")
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
			selectedAuctionCached = LibPGC.Auction.Cached(selectedAuctionID)
			selectedAuctionBid = selectedAuctionData.buyoutPrice == 0 or selectedAuctionData.bidPrice < selectedAuctionData.buyoutPrice
			selectedAuctionBuyout = selectedAuctionData.buyoutPrice > 0 and true or false
			highestBidder = (selectedAuctionData.ownBidded or 0) == selectedAuctionData.bidPrice
			seller = selectedAuctionData.own
			bidPrice = selectedAuctionData.bidPrice
		end
		
		bidButton:SetEnabled(auctionSelected and auctionInteraction and selectedAuctionCached and selectedAuctionBid and not highestBidder and not seller)
		buyButton:SetEnabled(auctionSelected and auctionInteraction and selectedAuctionCached and selectedAuctionBuyout and not seller)

		if not auctionSelected then
			noBidLabel:SetText(L["SearchFrame/ErrorNoAuction"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not selectedAuctionCached then
			noBidLabel:SetText(L["SearchFrame/ErrorNotCached"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif seller then
			noBidLabel:SetText(L["SearchFrame/ErrorSeller"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif highestBidder then
			noBidLabel:SetText(L["SearchFrame/ErrorHighestBidder"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not auctionInteraction then
			noBidLabel:SetText(L["SearchFrame/ErrorNoAuctionHouse"])
			noBidLabel:SetVisible(true)
			auctionMoneySelector:SetVisible(false)
		elseif not selectedAuctionBid then
			noBidLabel:SetText(L["SearchFrame/ErrorBidEqualBuy"])
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
		return math.floor(math.min(value, 999)) .. " %"
	end

	local function ScoreColor(value)
		local r, g, b = unpack(InternalInterface.UI.ScoreColorByScore(value))
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
	clearButton:SetText(L["SearchFrame/ButtonReset"])
	
	searchButton:SetPoint("TOPRIGHT", clearButton, "TOPLEFT", 10, 0)
	searchButton:SetText(L["SearchFrame/ButtonSearch"])
	
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
	searchGrid:AddColumn("item", L["SearchFrame/ColumnItem"], SearchCellType, 140, 3, nil, "itemName")
	searchGrid:AddColumn("seller", L["SearchFrame/ColumnSeller"], "Text", 120, 1, "sellerName", true, { Alignment = "center" })
	searchGrid:AddColumn("minexpire", L["SearchFrame/ColumnMinExpire"], "Text", 90, 0, "minExpireTime", true, { Alignment = "right", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	searchGrid:AddColumn("maxexpire", L["SearchFrame/ColumnMaxExpire"], "Text", 90, 0, "maxExpireTime", true, { Alignment = "right", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	searchGrid:AddColumn("bid", L["SearchFrame/ColumnBid"], "MoneyCellType", 120, 1, "bidPrice", true)
	searchGrid:AddColumn("buy", L["SearchFrame/ColumnBuy"], "MoneyCellType", 120, 1, "buyoutPrice", true)
	searchGrid:AddColumn("unitbid", L["SearchFrame/ColumnBidPerUnit"], "MoneyCellType", 120, 1, "bidUnitPrice", true)
	searchGrid:AddColumn("unitbuy", L["SearchFrame/ColumnBuyPerUnit"], "MoneyCellType", 120, 1, "buyoutUnitPrice", true)
--	searchGrid:AddColumn("score", L["SearchFrame/ColumnScore"], "Text", 60, 0, "score", true, { Alignment = "center", Formatter = ScoreValue, Color = ScoreColor })
	searchGrid:AddColumn("background", nil, "WideBackgroundCellType", 0, 0)
	searchGrid:SetOrder("unitbuy", false)
	searchGrid:GetInternalContent():SetBackgroundColor(0, 0.05, 0.05, 0.5)
	searchGrid:SetLoadingBarEnabled(true)

	controlFrame:SetPoint("TOPLEFT", searchGrid:GetContent(), "BOTTOMLEFT", 3, -36)
	controlFrame:SetPoint("BOTTOMRIGHT", searchGrid:GetContent(), "BOTTOMRIGHT", -3, -2)

	buyButton:SetPoint("CENTERRIGHT", controlFrame, "CENTERRIGHT", 0, 0)
	buyButton:SetText(L["SearchFrame/ButtonBuy"])
	buyButton:SetEnabled(false)

	bidButton:SetPoint("CENTERRIGHT", buyButton, "CENTERLEFT", 10, 0)
	bidButton:SetText(L["SearchFrame/ButtonBid"])
	bidButton:SetEnabled(false)

	auctionMoneySelector:SetPoint("TOPRIGHT", bidButton, "TOPLEFT", -5, 2)
	auctionMoneySelector:SetPoint("BOTTOMLEFT", bidButton, "BOTTOMLEFT", -230, -2)
	auctionMoneySelector:SetVisible(false)
	
	noBidLabel:SetPoint("CENTER", bidButton, "CENTERLEFT", -115, 0)	
	noBidLabel:SetFontColor(1, 0.5, 0, 1)
	noBidLabel:SetShadowColor(0.05, 0, 0.1, 1)
	noBidLabel:SetShadowOffset(2, 2)
	noBidLabel:SetFontSize(14)

	collapseButton:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			local searchFrame = currentSearcher and searchers[currentSearcher] and searchers[currentSearcher].frame or nil
			if searchFrame then searchFrame:SetVisible(collapsed) end
			
			searcherFrame:SetHeight(collapsed and searchFrame and searchFrame:GetHeight() + 10 or 0)
			
			collapsed = not collapsed
			
			collapseButton:SetTexture(addonID, collapsed and "Textures/ArrowDown.png" or "Textures/ArrowUp.png")
		end, collapseButton:GetName() .. ".OnLeftClick")

	itemNamePanel:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			itemNameField:SetKeyFocus(true)
		end, itemNamePanel:GetName() .. ".OnLeftClick")

	itemNameField:EventAttach(Event.UI.Input.Key.Focus.Gain,
		function()
			local length = string.len(itemNameField:GetText())
			if length > 0 then
				itemNameField:SetSelection(0, length)
			end
		end, itemNameField:GetName() .. ".OnKeyFocusGain")
	
	searchButton:EventAttach(Event.UI.Button.Left.Press,
		function()
			local searchInfo = currentSearcher and searchers[currentSearcher] or nil
			local extraInfo = searchInfo and searchInfo.extraInfo or {}
			
			if currentSearcher ~= lastSearcherUsed then
				lastSearcherUsed = currentSearcher
				
				local columnsConsumed = {}
				for i = 1, #extraInfo do
					local columnInfo = extraInfo[extraInfo[i]] or {}
					
					local columnName = columnInfo.name or ""
					local columnType = columnInfo.value
					
					columnsConsumed[columnType] = (columnsConsumed[columnType] or 0) + 1
					local columnID = tostring(columnType) .. "." .. columnsConsumed[columnType]
					
					searchGrid:ModifyColumn(columnID, columnName, extraInfo[i], true, false)
				end
				
				for columnType, columnCollection in pairs(extraColumns) do
					for index = (columnsConsumed[columnType] or 0) + 1, #columnCollection do
						local columnID = columnCollection[index]
						searchGrid:ModifyColumn(columnID, columnID, nil, false, true)
					end
				end
			end

			local searchFrame = searchInfo and searchInfo.frame or nil
			local extra = searchFrame and searchFrame:GetExtra() or nil
			
			searchParams =
			{
				searcher = searchInfo.baseSearcher or currentSearcher,
				text = itemNameField:GetText(),
				extra = extra,
			}
			
			PerformSearch()
		end, searchButton:GetName() .. ".OnLeftPress")

	clearButton:EventAttach(Event.UI.Button.Left.Press,
		function()
			local searchInfo = currentSearcher and searchers[currentSearcher] or nil
			local frame = searchInfo and searchInfo.frame
			local extra = searchInfo and searchInfo.extra or {}
			if frame then
				frame:SetExtra(extra)
			end
			itemNameField:SetText(extra.text or "")
		end, clearButton:GetName() .. ".OnLeftPress")

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
	end

	saveButton:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			local manager = InternalInterface.Output.GetPopupManager()
			local searchInfo = currentSearcher and searchers[currentSearcher] or nil
			local searchFrame = searchInfo and searchInfo.frame or nil
			local extra = searchFrame and searchFrame:GetExtra() or nil		
			if manager and extra then
				local timeStamp = os.time()
				manager:ShowPopup(addonID .. ".SaveSearch", InternalInterface.Utility.GetLocalizedDateString(L["SaveSearchPopup/DefaultName"], timeStamp),
					function(name)
						InternalInterface.AccountSettings.Search.SavedSearchs["custom-" .. timeStamp] =
						{
							displayName = name,
							extra = extra,
							baseSearcher = searchInfo.baseSearcher or currentSearcher,
						}
						currentSearcher = "custom-" .. timeStamp
						ResetSearchers()
					end)
			end		
		end, saveButton:GetName() .. ".OnLeftClick")
	
	deleteButton:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			InternalInterface.AccountSettings.Search.SavedSearchs[currentSearcher] = nil
			ResetSearchers()
		end, deleteButton:GetName() .. ".OnLeftClick")

	function searchGrid.Event:SelectionChanged()
		RefreshAuctionButtons()
	end

	buyButton:EventAttach(Event.UI.Button.Left.Press,
		function()
			local auctionID, auctionData = searchGrid:GetSelectedData()
			if auctionID then
				Command.Auction.Bid(auctionID, auctionData.buyoutPrice, LibPGC.Callback.Buy(auctionID))
			end
		end, buyButton:GetName() .. ".OnLeftPress")
	
	bidButton:EventAttach(Event.UI.Button.Left.Press,
		function()
			local auctionID = searchGrid:GetSelectedData()
			if auctionID then
				local bidAmount = auctionMoneySelector:GetValue()
				Command.Auction.Bid(auctionID, bidAmount, LibPGC.Callback.Bid(auctionID, bidAmount))
			end
		end, bidButton:GetName() .. ".OnLeftPress")
	
	local function OnAuctionData()
		if not searchFrame:GetVisible() then
			RefreshAuctionButtons()
		end
	end
	Command.Event.Attach(Event.LibPGC.Scan.End, OnAuctionData, addonID .. ".SearchFrame.OnAuctionData")

	local function OnInteraction(h, interaction)
		if searchFrame:GetVisible() and interaction == "auction" then
			RefreshAuctionButtons()
		end
	end
	Command.Event.Attach(Event.Interaction, OnInteraction, addonID .. ".SearchFrame.OnInteraction")

	function searchFrame:Show()
		RefreshAuctionButtons()
	end
	
	function searchFrame:Hide()
	end
	
	function searchFrame:ItemRightClick(params)
		if params and params.id then
			local ok, itemDetail = pcall(Inspect.Item.Detail, params.id)
			if not ok or not itemDetail or not itemDetail.name then return false end
			itemNameField:SetText(itemDetail.name)
			return true
		end
		return false
	end

	ResetSearchers()
	
	return searchFrame
end
