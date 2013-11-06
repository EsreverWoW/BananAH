-- ***************************************************************************************************************************************************
-- * SellingFrame.lua                                                                                                                                *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.07 / Baanano: Rewritten for 0.4.1                                                                                               *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local L = InternalInterface.Localization.L

local function CancelAuctionPopup(parent)
	local frame = Yague.Popup(parent:GetName() .. ".SaveSearchPopup", parent)
	
	local titleText = Yague.ShadowedText(frame:GetName() .. ".TitleText", frame:GetContent())
	local contentText = UI.CreateFrame("Text", frame:GetName() .. ".ContentText", frame:GetContent())
	local ignoreCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".IgnoreCheck", frame:GetContent())
	local ignoreText = UI.CreateFrame("Text", frame:GetName() .. ".IgnoreText", frame:GetContent())
	local yesButton = UI.CreateFrame("RiftButton", frame:GetName() .. ".YesButton", frame:GetContent())
	local noButton = UI.CreateFrame("RiftButton", frame:GetName() .. ".NoButton", frame:GetContent())
	
	local Callback = nil
	
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
	
	yesButton:EventAttach(Event.UI.Button.Left.Press,
		function()
			InternalInterface.AccountSettings.Auctions.BypassCancelPopup = ignoreCheck:GetChecked()
			if type(Callback) == "function" then
				Callback() 
			end
			parent:HidePopup(addonID .. ".CancelAuction", frame)
		end, yesButton:GetName() .. ".OnLeftPress")
		
	noButton:EventAttach(Event.UI.Button.Left.Press,
		function()
			parent:HidePopup(addonID .. ".CancelAuction", frame)
		end, noButton:GetName() .. ".OnLeftPress")
	
	function frame:SetData(callback)
		Callback = callback
	end
	
	return frame
end
Yague.RegisterPopupConstructor(addonID .. ".CancelAuction", CancelAuctionPopup)

local function SellingAuctionCellType(name, parent)
	local sellingCell = UI.CreateFrame("Mask", name, parent)
	local itemTextureBackground = UI.CreateFrame("Frame", name .. ".ItemTextureBackground", sellingCell)
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = Yague.ShadowedText(name .. ".ItemNameLabel", sellingCell)
	local alterTexture = UI.CreateFrame("Texture", name .. ".AlterTexture", sellingCell)
	local alterNameLabel = Yague.ShadowedText(name .. ".AlterNameLabel", sellingCell)
	local biddedTexture = UI.CreateFrame("Texture", name .. ".BiddedTexture", sellingCell)
	local itemStackLabel = Yague.ShadowedText(name .. ".ItemStackLabel", sellingCell)	
	
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
		
		itemTextureBackground:SetBackgroundColor(InternalInterface.Utility.GetRarityColor(value.itemRarity))
		
		itemTexture:SetTextureAsync("Rift", value.itemIcon)
		
		itemNameLabel:SetText(value.itemName)
		itemNameLabel:SetFontColor(InternalInterface.Utility.GetRarityColor(value.itemRarity))
		
		itemStackLabel:SetText("x" .. (value.stack or 0))
		
		if value.bidded then
			biddedTexture:ClearWidth()
			biddedTexture:SetVisible(true)
		else
			biddedTexture:SetWidth(-5)
			biddedTexture:SetVisible(false)
		end
		
		local seller = value.sellerName
		alterTexture:SetVisible(seller and seller ~= blUtil.Player.Name() and true or false)

		alterNameLabel:SetText(seller or "")
		
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
	
	alterTexture:EventAttach(Event.UI.Input.Mouse.Cursor.In,
		function()
			alterNameLabel:SetVisible(alterTexture:GetVisible())
		end, alterTexture:GetName() .. ".OnCursorIn")
	
	alterTexture:EventAttach(Event.UI.Input.Mouse.Cursor.Out,
		function()
			alterNameLabel:SetVisible(false)
		end, alterTexture:GetName() .. ".OnCursorOut")
	
	return sellingCell
end

local function CancellableCellType(name, parent)
	local cell = UI.CreateFrame("Frame", name, parent)
	local cancellableCell = UI.CreateFrame("Texture", name .. ".Texture", cell)
	
	local auctionID = nil

	cancellableCell:SetPoint("CENTER", cell, "CENTER")
	cancellableCell:SetTextureAsync(addonID, "Textures/DeleteDisabled.png")
	
	function cell:SetValue(key, value, width, extra)
		auctionID = key and not value.bidded and value.cached and value.sellerName == blUtil.Player.Name() and Inspect.Interaction("auction") and key or nil
		cancellableCell:SetTextureAsync(addonID, auctionID and "Textures/DeleteEnabled.png" or "Textures/DeleteDisabled.png")
	end
	
	cancellableCell:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			if auctionID then
				local callback = function() if Inspect.Interaction("auction") then Command.Auction.Cancel(auctionID, LibPGC.Callback.Cancel(auctionID)) end end
				if not InternalInterface.AccountSettings.Auctions.BypassCancelPopup then
					local manager = InternalInterface.Output.GetPopupManager()
					if manager then
						manager:ShowPopup(addonID .. ".CancelAuction", callback)
					end				
				else
					callback()
				end
			end
		end, cancellableCell:GetName() .. ".OnLeftClick")
	
	return cell
end

function InternalInterface.UI.SellingFrame(name, parent)
	local sellingFrame = UI.CreateFrame("Frame", name, parent)
	
	local anchor = UI.CreateFrame("Frame", name .. ".Anchor", sellingFrame)
	
	local sellingGrid = Yague.DataGrid(name .. ".SellingGrid", sellingFrame)
	
	local collapseButton = UI.CreateFrame("Texture", name .. ".CollapseButton", sellingFrame)
	local filterTextPanel = Yague.Panel(name .. ".FilterTextPanel", sellingFrame)
	local filterTextField = UI.CreateFrame("RiftTextfield", name .. ".FilterTextField", filterTextPanel:GetContent())
	
	local filterFrame = UI.CreateFrame("Frame", name .. ".FilterFrame", sellingFrame)
	local filterCharacterCheck = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterCharacterCheck", filterFrame)
	local filterCharacterText = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterCharacterText", filterFrame)
	local filterCompetitionText = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterCompetitionText", filterFrame)
	local filterCompetitionSelector = Yague.Dropdown(filterFrame:GetName() .. ".FilterCompetitionSelector", filterFrame)
	local filterBelowText = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterBelowText", filterFrame)
	local filterBelowSlider = Yague.Slider(filterFrame:GetName() .. ".FilterBelowSlider", filterFrame)
	local filterScorePanel = Yague.Panel(filterFrame:GetName() .. ".FilterScorePanel", filterFrame)
	local filterScoreTitle = Yague.ShadowedText(filterFrame:GetName() .. ".FilterScoreTitle", filterScorePanel:GetContent())
	local filterScoreChecks = {}
	local filterScoreTexts = {}
	for index = 0, 5 do
		filterScoreChecks[index + 1] = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore" .. tostring(index) .. "Check", filterScorePanel:GetContent())
		filterScoreTexts[index + 1] = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterScore" .. tostring(index) .. "Text", filterScorePanel:GetContent())
	end
	
	local auctionsGrid = InternalInterface.UI.ItemAuctionsGrid(name .. ".ItemAuctionsGrid", filterFrame)
	
	local collapsed = true
	local refreshTask = nil

	local function ResetAuctions()
		if refreshTask and not refreshTask:Finished() then
			refreshTask:Stop()
		end
		
		refreshTask = blTasks.Task.Create(
			function(taskHandle)
				local ownAuctions = InternalInterface.PGCExtensions.GetOwnAuctionsScoredCompetition():Result()
				sellingGrid:SetData(ownAuctions)
			end):Start():Abandon()
	end
	
	local function SellingGridFilter(key, value)
		if (value.competitionBelow or 0) < filterBelowSlider:GetPosition() then return false end
	
		if (value.competitionQuintile or 1) < filterCompetitionSelector:GetSelectedValue() then return false end

		if filterCharacterCheck:GetChecked() and value.sellerName ~= blUtil.Player.Name() then return false end

		local scoreIndex = InternalInterface.UI.ScoreIndexByScore(value.score) or 0
		if not filterScoreChecks[scoreIndex + 1]:GetChecked() then return false end

		local filterText = string.upper(filterTextField:GetText())
		local upperName = string.upper(value.itemName)
		if not string.find(upperName, filterText, 1, true) then return false end

		return true
	end
	
	local function ScoreValue(value)
		if not value then return "" end
		return math.floor(math.min(value, 999)) .. " %"
	end

	local function ScoreColor(value)
		local r, g, b = unpack(InternalInterface.UI.ScoreColorByScore(value))
		return { r, g, b, 0.1 }
	end
	
	local function CompetitionString(value)
		if not value.competitionBelow or not value.competitionQuintile then return "" end
		return string.format("%s (%d)", L["General/CompetitionName" .. value.competitionQuintile], value.competitionBelow)
	end
	
	anchor:SetPoint("CENTERRIGHT", sellingFrame, "BOTTOMRIGHT", 0, -34)
	
	sellingGrid:SetPoint("TOPLEFT", sellingFrame, "TOPLEFT", 5, 5)
	sellingGrid:SetPoint("BOTTOMRIGHT", anchor, "CENTERRIGHT", -5, 0)
	sellingGrid:SetRowHeight(62)
	sellingGrid:SetRowMargin(2)
	sellingGrid:SetHeadersVisible(true)
	sellingGrid:SetUnselectedRowBackgroundColor({0.15, 0.1, 0.1, 1})
	sellingGrid:SetSelectedRowBackgroundColor({0.45, 0.3, 0.3, 1})
	sellingGrid:AddColumn("item", L["SellingFrame/ColumnItem"], SellingAuctionCellType, 300, 1, nil, "itemName")
	sellingGrid:AddColumn("minexpire", L["SellingFrame/ColumnMinExpire"], "Text", 100, 0, "minExpireTime", true, { Alignment = "center", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
	sellingGrid:AddColumn("maxexpire", L["SellingFrame/ColumnMaxExpire"], "Text", 100, 0, "maxExpireTime", true, { Alignment = "center", Formatter = InternalInterface.Utility.RemainingTimeFormatter })
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
	
	collapseButton:SetPoint("BOTTOMLEFT", sellingFrame, "BOTTOMLEFT", 5, -5)
	collapseButton:SetTextureAsync(addonID, "Textures/ArrowUp.png")

	filterTextPanel:SetPoint("TOPLEFT", sellingFrame, "BOTTOMLEFT", 35, -33)
	filterTextPanel:SetPoint("BOTTOMRIGHT", sellingFrame, "BOTTOMRIGHT", -5, -3)
	filterTextPanel:SetInvertedBorder(true)
	filterTextPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	filterTextField:SetPoint("CENTERLEFT", filterTextPanel:GetContent(), "CENTERLEFT", 2, 1)
	filterTextField:SetPoint("CENTERRIGHT", filterTextPanel:GetContent(), "CENTERRIGHT", -2, 1)
	filterTextField:SetText("")
	
	filterFrame:SetPoint("BOTTOMLEFT", sellingFrame, "BOTTOMLEFT", 5, -34)
	filterFrame:SetPoint("TOPRIGHT", anchor, "CENTERRIGHT", -5, 0)
	filterFrame:SetVisible(false)

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
		filterScoreChecks[index + 1]:SetPoint("CENTERLEFT", filterScorePanel:GetContent(), (index % 2) / 2, (3 + 2 * math.floor(index / 2)) / 8, 5, 0)
		filterScoreChecks[index + 1]:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[index + 1] or false)
		filterScoreTexts[index + 1]:SetPoint("CENTERLEFT", filterScoreChecks[index + 1], "CENTERRIGHT", 5, 0)
		filterScoreTexts[index + 1]:SetText(L["General/ScoreName" .. tostring(index)])
	end
	
	auctionsGrid:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 295, 5)
	auctionsGrid:SetPoint("BOTTOMRIGHT", filterFrame, "BOTTOMRIGHT", 0, -5)	

	function sellingGrid.Event:SelectionChanged(key, value)
		auctionsGrid:SetItemAuctions(value and value.itemType or nil, value and value.competition or nil, key)
	end
	
	collapseButton:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			filterFrame:SetVisible(collapsed)
			collapsed = not collapsed
			anchor:SetPoint("CENTERRIGHT", sellingFrame, "BOTTOMRIGHT", 0, collapsed and -34 or -300)
			collapseButton:SetTextureAsync(addonID, collapsed and "Textures/ArrowUp.png" or "Textures/ArrowDown.png")
		end, collapseButton:GetName() .. ".OnLeftClick")
	
	filterTextPanel:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			filterTextField:SetKeyFocus(true)
		end, filterTextPanel:GetName() .. ".OnLeftClick")

	filterTextField:EventAttach(Event.UI.Input.Key.Focus.Gain,
		function()
			local length = string.len(filterTextField:GetText())
			if length > 0 then
				filterTextField:SetSelection(0, length)
			end
		end, filterTextField:GetName() .. ".OnKeyFocusGain")

	local function UpdateFilter() sellingGrid:RefreshFilter() end
	
	filterTextField:EventAttach(Event.UI.Textfield.Change, UpdateFilter, filterTextField:GetName() .. ".OnTextfieldChange")
	filterCharacterCheck:EventAttach(Event.UI.Checkbox.Change , UpdateFilter, filterTextField:GetName() .. ".OnCheckboxChange")
	filterCompetitionSelector.Event.SelectionChanged = UpdateFilter
	filterBelowSlider.Event.PositionChanged = UpdateFilter
	for index = 0, 5 do
		filterScoreChecks[index + 1]:EventAttach(Event.UI.Checkbox.Change , UpdateFilter, filterScoreChecks[index + 1]:GetName() .. ".OnCheckboxChange")
	end

	function sellingFrame:Show()
		ResetAuctions()
	end
	
	function sellingFrame:Hide()
		if refreshTask and not refreshTask:Finished() then
			refreshTask:Stop()
		end
	end
	
	function sellingFrame:ItemRightClick(params)
		if params and params.id then
			local ok, itemDetail = pcall(Inspect.Item.Detail, params.id)
			if not ok or not itemDetail or not itemDetail.name then return false end
			filterTextField:SetText(itemDetail.name)
			UpdateFilter()
			return true
		end
		return false
	end
	
	Command.Event.Attach(Event.Interaction, function(h, interaction) if sellingFrame:GetVisible() and interaction == "auction" then UpdateFilter() end end, addonID .. ".SellingFrame.OnInteraction")
	Command.Event.Attach(Event.LibPGC.Scan.End, function() if sellingFrame:GetVisible() then ResetAuctions() end end, addonID .. ".SellingFrame.OnAuctionData")
	
	return sellingFrame
end