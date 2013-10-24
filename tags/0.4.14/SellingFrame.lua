-- ***************************************************************************************************************************************************
-- * SellingFrame.lua                                                                                                                                *
-- ***************************************************************************************************************************************************
-- * Selling tab frame                                                                                                                               *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.07 / Baanano: Rewritten for 0.4.1                                                                                               *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local DataGrid = Yague.DataGrid
local Dropdown = Yague.Dropdown
local Panel = Yague.Panel
local ShadowedText = Yague.ShadowedText
local Slider = Yague.Slider
local CACancel = Command.Auction.Cancel
local CTooltip = Command.Tooltip
local GetAuctionCached = LibPGC.GetAuctionCached
local GetAuctionCancelCallback = LibPGC.GetAuctionCancelCallback
local GetOwnAuctionsScoredCompetition = InternalInterface.PGCExtensions.GetOwnAuctionsScoredCompetition
local GetPlayerName = InternalInterface.Utility.GetPlayerName
local GetPopupManager = InternalInterface.Output.GetPopupManager
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local IIDetail = Inspect.Item.Detail
local IInteraction = Inspect.Interaction
local L = InternalInterface.Localization.L
local MFloor = math.floor
local MMin = math.min
local RegisterPopupConstructor = Yague.RegisterPopupConstructor
local RemainingTimeFormatter = InternalInterface.Utility.RemainingTimeFormatter
local SFind = string.find
local SFormat = string.format
local SLen = string.len
local SUpper = string.upper
local ScoreColorByScore = InternalInterface.UI.ScoreColorByScore
local TInsert = table.insert
local UICreateFrame = UI.CreateFrame
local Write = InternalInterface.Output.Write
local pcall = pcall
local unpack = unpack

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

function InternalInterface.UI.SellingFrame(name, parent)
	local sellingFrame = UICreateFrame("Frame", name, parent)
	
	local anchor = UICreateFrame("Frame", name .. ".Anchor", sellingFrame)
	
	local sellingGrid = DataGrid(name .. ".SellingGrid", sellingFrame)
	
	local collapseButton = UICreateFrame("Texture", name .. ".CollapseButton", sellingFrame)
	local filterTextPanel = Panel(name .. ".FilterTextPanel", sellingFrame)
	local filterTextField = UICreateFrame("RiftTextfield", name .. ".FilterTextField", filterTextPanel:GetContent())
	
	local filterFrame = UICreateFrame("Frame", name .. ".FilterFrame", sellingFrame)
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
	
	local collapsed = false

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
	
	anchor:SetPoint("CENTERRIGHT", sellingFrame, "BOTTOMRIGHT", 0, -300)
	
	sellingGrid:SetPoint("TOPLEFT", sellingFrame, "TOPLEFT", 5, 5)
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
	
	collapseButton:SetPoint("BOTTOMLEFT", sellingFrame, "BOTTOMLEFT", 5, -5)
	collapseButton:SetTextureAsync(addonID, "Textures/ArrowDown.png")

	filterTextPanel:SetPoint("TOPLEFT", sellingFrame, "BOTTOMLEFT", 35, -33)
	filterTextPanel:SetPoint("BOTTOMRIGHT", sellingFrame, "BOTTOMRIGHT", -5, -3)
	filterTextPanel:SetInvertedBorder(true)
	filterTextPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	filterTextField:SetPoint("CENTERLEFT", filterTextPanel:GetContent(), "CENTERLEFT", 2, 1)
	filterTextField:SetPoint("CENTERRIGHT", filterTextPanel:GetContent(), "CENTERRIGHT", -2, 1)
	filterTextField:SetText("")
	
	filterFrame:SetPoint("BOTTOMLEFT", sellingFrame, "BOTTOMLEFT", 5, -34)
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

	function sellingGrid.Event:SelectionChanged(key, value)
		auctionsGrid:SetItemType(value and value.itemType or nil, key)
		auctionsGrid:SetSelectedKey(key)
	end
	
	function collapseButton.Event:LeftClick()
		filterFrame:SetVisible(collapsed)
		collapsed = not collapsed
		anchor:SetPoint("CENTERRIGHT", sellingFrame, "BOTTOMRIGHT", 0, collapsed and -34 or -300)
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

	function sellingFrame:Show()
		auctionsGrid:SetEnabled(true)
		ResetAuctions()
	end
	
	function sellingFrame:Hide()
		auctionsGrid:SetEnabled(false)
	end	
	
	function sellingFrame:ItemRightClick(params)
		if params and params.id then
			local ok, itemDetail = pcall(IIDetail, params.id)
			if not ok or not itemDetail or not itemDetail.name then return false end
			filterTextField:SetText(itemDetail.name)
			UpdateFilter()
			return true
		end
		return false
	end
	
	TInsert(Event.Interaction, { function(interaction) if sellingFrame:GetVisible() and interaction == "auction" then UpdateFilter() end end, addonID, addonID .. ".SellingFrame.OnInteraction" })
	TInsert(Event.LibPGC.AuctionData, { function() if sellingFrame:GetVisible() then ResetAuctions() end end, addonID, addonID .. ".SellingFrame.OnAuctionData" })
	
	collapseButton.Event.LeftClick(collapseButton) -- FIXME Event model
	
	return sellingFrame
end