-- ***************************************************************************************************************************************************
-- * ConfigFrame.lua                                                                                                                                 *
-- ***************************************************************************************************************************************************
-- * Config tab frame                                                                                                                                *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.28 / Baanano: Rewritten for 0.4.1                                                                                               *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local BASE_CATEGORY = InternalInterface.Category.BASE_CATEGORY
local BuildConfigFrame = InternalInterface.UI.BuildConfigFrame
local CDetail = InternalInterface.Category.Detail
local DataGrid = Yague.DataGrid
local Dropdown = Yague.Dropdown
local GetAuctionSearchers = LibPGCEx.GetAuctionSearchers
local GetCategoryModels = InternalInterface.PGCConfig.GetCategoryModels
local GetPopupManager = InternalInterface.Output.GetPopupManager
local GetPriceModels = LibPGCEx.GetPriceModels
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local L = InternalInterface.Localization.L
local MMax = math.max
local MMin = math.min
local Panel = Yague.Panel
local RegisterPopupConstructor = Yague.RegisterPopupConstructor
local SFormat = string.format
local ScoreColorByIndex = InternalInterface.UI.ScoreColorByIndex
local ShadowedText = Yague.ShadowedText
local Slider = Yague.Slider
local UICreateFrame = UI.CreateFrame
local pairs = pairs
local type = type
local unpack = unpack

local function BooleanDotCellType(name, parent)
	local baseCell = UICreateFrame("Frame", name, parent)
	
	local dotTexture = UICreateFrame("Texture", name .. ".DotTexture", baseCell)

	local assignedKey = nil
	local interactable = nil

	dotTexture:SetPoint("CENTER", baseCell, "CENTER")
	dotTexture:SetTextureAsync(addonID, "Textures/DotGrey.png")
	
	function baseCell:SetValue(key, value, width, extra)
		assignedKey = key
		
		local active = value
		if extra and extra.Eval then
			active = extra.Eval(value, key)
		end
		
		if active == nil then
			dotTexture:SetTextureAsync(addonID, "Textures/DotGrey.png")
			interactable = nil
		else
			dotTexture:SetTextureAsync(addonID, active and "Textures/DotGreen.png" or "Textures/DotRed.png")
			interactable = extra and extra.Interactable
		end
	end

	function dotTexture.Event:LeftClick()
		if assignedKey and type(interactable) == "function" then
			interactable(assignedKey)
		end
		baseCell:GetParent().Event.LeftClick(baseCell:GetParent())
	end

	return baseCell
end

local function UnsavedChangesPopup(parent)
	local frame = Yague.Popup(parent:GetName() .. ".UnsavedChangesPopup", parent)
	
	local titleText = ShadowedText(frame:GetName() .. ".TitleText", frame:GetContent())
	local contentText = UICreateFrame("Text", frame:GetName() .. ".ContentText", frame:GetContent())
	local continueButton = UICreateFrame("RiftButton", frame:GetName() .. ".ContinueButton", frame:GetContent())
	local cancelButton = UICreateFrame("RiftButton", frame:GetName() .. ".CancelButton", frame:GetContent())	
	
	frame:SetWidth(420)
	frame:SetHeight(130)
	
	titleText:SetPoint("TOPCENTER", frame:GetContent(), "TOPCENTER", 0, 10)
	titleText:SetFontSize(14)
	titleText:SetFontColor(1, 1, 0.75, 1)
	titleText:SetShadowOffset(2, 2)
	titleText:SetText("WARNING") -- LOCALIZE
	
	contentText:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 10, 40)
	contentText:SetText("You have unsaved changes, if you continue they'll be lost.") -- LOCALIZE
	
	continueButton:SetPoint("BOTTOMRIGHT", frame:GetContent(), "BOTTOMCENTER", 0, -10)
	continueButton:SetText("Continue") -- LOCALIZE
	
	cancelButton:SetPoint("BOTTOMLEFT", frame:GetContent(), "BOTTOMCENTER", 0, -10)
	cancelButton:SetText("Cancel") -- LOCALIZE
	
	function frame:SetData(onContinue, onCancel)
		function continueButton.Event:LeftPress()
			onContinue() 
			parent:HidePopup(addonID .. ".UnsavedChanges", frame)
		end

		function cancelButton.Event:LeftPress()
			onCancel() 
			parent:HidePopup(addonID .. ".UnsavedChanges", frame)
		end
	end
	
	return frame
end
RegisterPopupConstructor(addonID .. ".UnsavedChanges", UnsavedChangesPopup)

local function GeneralSettings(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".GeneralSettings", parent)
	
	local showMapIconCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".ShowMapIconCheck", frame)
	local showMapIconText = UICreateFrame("Text", frame:GetName() .. ".ShowMapIconText", frame)
	local autoOpenCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".AutoOpenCheck", frame)
	local autoOpenText = UICreateFrame("Text", frame:GetName() .. ".AutoOpenText", frame)
	local autoCloseCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".AutoCloseCheck", frame)
	local autoCloseText = UICreateFrame("Text", frame:GetName() .. ".AutoCloseText", frame)
	local pauseQueueCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".PauseQueueCheck", frame)
	local pauseQueueText = UICreateFrame("Text", frame:GetName() .. ".PauseQueueText", frame)
	
	frame:SetVisible(false)
	
	showMapIconCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	showMapIconCheck:SetChecked(InternalInterface.AccountSettings.General.ShowMapIcon)
	
	showMapIconText:SetPoint("CENTERLEFT", showMapIconCheck, "CENTERRIGHT", 5, 0)
	showMapIconText:SetFontSize(14)
	showMapIconText:SetText(L["ConfigGeneral/MapIconShow"])
	
	autoOpenCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 55)
	autoOpenCheck:SetChecked(InternalInterface.AccountSettings.General.AutoOpen)
	
	autoOpenText:SetPoint("CENTERLEFT", autoOpenCheck, "CENTERRIGHT", 5, 0)
	autoOpenText:SetFontSize(14)
	autoOpenText:SetText(L["ConfigGeneral/AutoOpenWindow"])
	
	autoCloseCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 85)
	autoCloseCheck:SetChecked(InternalInterface.AccountSettings.General.AutoClose)
	
	autoCloseText:SetPoint("CENTERLEFT", autoCloseCheck, "CENTERRIGHT", 5, 0)
	autoCloseText:SetFontSize(14)
	autoCloseText:SetText(L["ConfigGeneral/AutoCloseWindow"])
	
	pauseQueueCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 130)
	pauseQueueCheck:SetChecked(InternalInterface.AccountSettings.General.QueuePausedOnStart)
	
	pauseQueueText:SetPoint("CENTERLEFT", pauseQueueCheck, "CENTERRIGHT", 5, 0)
	pauseQueueText:SetFontSize(14)
	pauseQueueText:SetText(L["ConfigGeneral/PausePostingQueue"])
	
	function showMapIconCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.General.ShowMapIcon = self:GetChecked()
		InternalInterface.UI.MapIcon:SetVisible(InternalInterface.AccountSettings.General.ShowMapIcon)
	end
	
	function autoOpenCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.General.AutoOpen = self:GetChecked()
	end
	
	function autoCloseCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.General.AutoClose = self:GetChecked()
	end
	
	function pauseQueueCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.General.QueuePausedOnStart = self:GetChecked()
	end
	
	return frame
end

local function SearchSettings(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".GeneralSettings", parent)
	
	local defaultSearcherText = UICreateFrame("Text", frame:GetName() .. ".DefaultSearcherText", frame)
	local defaultSearcherDropdown = Dropdown(frame:GetName() .. ".DefaultSearcherDropdown", frame)

	local defaultSearchModeText = UICreateFrame("Text", frame:GetName() .. ".DefaultSearchModeText", frame)
	local defaultSearchModeDropdown = Dropdown(frame:GetName() .. ".DefaultSearchModeDropdown", frame)

	frame:SetVisible(false)
	
	defaultSearcherText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	defaultSearcherText:SetFontSize(14)
	defaultSearcherText:SetText(L["ConfigSearch/DefaultSearcher"])
	
	defaultSearcherDropdown:SetPoint("CENTERLEFT", defaultSearcherText, "CENTERLEFT", 200, 0)
	defaultSearcherDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 5)
	defaultSearcherDropdown:SetTextSelector("displayName")
	defaultSearcherDropdown:SetOrderSelector("displayName")
	
	local searchers = GetAuctionSearchers()
	for id, name in pairs(searchers) do searchers[id] = { displayName = name } end
	local defaultSearcher = InternalInterface.AccountSettings.Search.DefaultSearcher
	defaultSearcherDropdown:SetValues(searchers)
	if searchers[defaultSearcher] then defaultSearcherDropdown:SetSelectedKey(defaultSearcher) end
	-- TODO Load new searchers when they're created
	
	defaultSearchModeText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 50)
	defaultSearchModeText:SetFontSize(14)
	defaultSearchModeText:SetText(L["ConfigSearch/DefaultSearchMode"])
	
	defaultSearchModeDropdown:SetPoint("CENTERLEFT", defaultSearchModeText, "CENTERLEFT", 200, 0)
	defaultSearchModeDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 45)
	defaultSearchModeDropdown:SetTextSelector("displayName")
	defaultSearchModeDropdown:SetOrderSelector("order")
	local defaultSearchMode = InternalInterface.AccountSettings.Search.DefaultOnline and "online" or "offline"
	defaultSearchModeDropdown:SetValues({
		["online"] = { displayName = L["Misc/SearchModeOnline"], order = 1, },
		["offline"] = { displayName = L["Misc/SearchModeOffline"], order = 2, },
	})
	defaultSearchModeDropdown:SetSelectedKey(defaultSearchMode)
	
	function defaultSearcherDropdown.Event:SelectionChanged(searcher)
		InternalInterface.AccountSettings.Search.DefaultSearcher = searcher
	end
	
	function defaultSearchModeDropdown.Event:SelectionChanged(searchMode)
		InternalInterface.AccountSettings.Search.DefaultOnline = searchMode == "online" and true or false
	end
	
	return frame
end

local function PostingSettings(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".PostingSettings", parent)

	local rarityFilterText = UICreateFrame("Text", frame:GetName() .. ".RarityFilterText", frame)
	local rarityFilterDropdown = Dropdown(frame:GetName() .. ".RarityFilterDropdown", frame)
	-- TODO Action on right click => Absolute Undercut / Relative Undercut / Match
	-- TODO Pause queue on autopost
	local defaultBidPercentageText = UICreateFrame("Text", frame:GetName() .. ".DefaultBidPercentageText", frame)
	local defaultBidPercentageSlider = Slider(frame:GetName() .. ".DefaultBidPercentageSlider", frame)
	local defaultBindPricesCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".DefaultBindPricesCheck", frame)
	local defaultBindPricesText = UICreateFrame("Text", frame:GetName() .. ".DefaultBindPricesText", frame)

	frame:SetVisible(false)

	rarityFilterText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	rarityFilterText:SetFontSize(14)
	rarityFilterText:SetText(L["ConfigPost/RarityFilter"])
	
	rarityFilterDropdown:SetPoint("CENTERLEFT", rarityFilterText, "CENTERLEFT", 200, 0)
	rarityFilterDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 5)
	rarityFilterDropdown:SetTextSelector("displayName")
	rarityFilterDropdown:SetOrderSelector("order")
	rarityFilterDropdown:SetColorSelector(function(key, value) return { GetRarityColor(value.rarity) } end)
	local defaultRarity = InternalInterface.AccountSettings.Posting.RarityFilter
	rarityFilterDropdown:SetValues({
		{ displayName = L["General/Rarity1"], order = 1, rarity = "sellable", },
		{ displayName = L["General/Rarity2"], order = 2, rarity = "common", },
		{ displayName = L["General/Rarity3"], order = 3, rarity = "uncommon", },
		{ displayName = L["General/Rarity4"], order = 4, rarity = "rare", },
		{ displayName = L["General/Rarity5"], order = 5, rarity = "epic", },
		{ displayName = L["General/Rarity6"], order = 6, rarity = "relic", },
		{ displayName = L["General/Rarity7"], order = 7, rarity = "transcendant", },
		{ displayName = L["General/RarityQuest"], order = 8, rarity = "quest", },	
	})
	rarityFilterDropdown:SetSelectedKey(defaultRarity)

	defaultBidPercentageText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 90)
	defaultBidPercentageText:SetFontSize(14)
	defaultBidPercentageText:SetText(L["ConfigPost/BidPercentage"])
	
	defaultBidPercentageSlider:SetPoint("CENTERRIGHT", frame, "TOPRIGHT", -10, 90)
	defaultBidPercentageSlider:SetPoint("CENTERLEFT", defaultBidPercentageText, "CENTERLEFT", 200, 0)
	defaultBidPercentageSlider:SetRange(1, 100)
	defaultBidPercentageSlider:SetPosition(InternalInterface.AccountSettings.Posting.Config.BidPercentage)

	defaultBindPricesCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 130)
	defaultBindPricesCheck:SetChecked(InternalInterface.AccountSettings.Posting.Config.BindPrices)
	
	defaultBindPricesText:SetPoint("CENTERLEFT", defaultBindPricesCheck, "CENTERRIGHT", 5, 0)
	defaultBindPricesText:SetFontSize(14)
	defaultBindPricesText:SetText(L["ConfigPost/DefaultBindPrices"])

	function rarityFilterDropdown.Event:SelectionChanged(rarity)
		InternalInterface.AccountSettings.Posting.RarityFilter = rarity
	end

	function defaultBidPercentageSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.Posting.Config.BidPercentage = position
	end
	
	function defaultBindPricesCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Posting.Config.BindPrices = self:GetChecked()
	end

	return frame
end

local function AuctionsSettings(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".AuctionsSettings", parent)

	local allowLeftCancelCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".AllowLeftCancelCheck", frame)
	local allowLeftCancelText = UICreateFrame("Text", frame:GetName() .. ".AllowLeftCancelText", frame)

	local filterCharacterCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".FilterCharacterCheck", frame)
	local filterCharacterText = UICreateFrame("Text", frame:GetName() .. ".FilterCharacterText", frame)
	
	local filterCompetitionText = UI.CreateFrame("Text", frame:GetName() .. ".FilterCompetitionText", frame)
	local filterCompetitionSelector = Dropdown(frame:GetName() .. ".FilterCompetitionSelector", frame)
	
	local filterBelowText = UI.CreateFrame("Text", frame:GetName() .. ".FilterBelowText", frame)
	local filterBelowSlider = Slider(frame:GetName() .. ".FilterBelowSlider", frame)

	local filterScoreTitle = UICreateFrame("Text", frame:GetName() .. ".FilterScoreTitle", frame)
	local filterFrame = UICreateFrame("Frame", frame:GetName() .. ".FilterFrame", frame)
	
	local filterScoreNilCheck = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScoreNilCheck", filterFrame)
	local filterScoreNilText = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScoreNilText", filterFrame)
	local filterScore1Check = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore1Check", filterFrame)
	local filterScore1Text = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScore1Text", filterFrame)
	local filterScore2Check = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore2Check", filterFrame)
	local filterScore2Text = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScore2Text", filterFrame)
	local filterScore3Check = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore3Check", filterFrame)
	local filterScore3Text = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScore3Text", filterFrame)
	local filterScore4Check = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore4Check", filterFrame)
	local filterScore4Text = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScore4Text", filterFrame)
	local filterScore5Check = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore5Check", filterFrame)
	local filterScore5Text = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScore5Text", filterFrame)
	
	frame:SetVisible(false)

	allowLeftCancelCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	allowLeftCancelCheck:SetChecked(InternalInterface.AccountSettings.Auctions.BypassCancelPopup)
	
	allowLeftCancelText:SetPoint("CENTERLEFT", allowLeftCancelCheck, "CENTERRIGHT", 5, 0)
	allowLeftCancelText:SetFontSize(14)
	allowLeftCancelText:SetText(L["ConfigSelling/BypassCancelPopup"])
	
	filterCharacterCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 70)
	filterCharacterCheck:SetChecked(InternalInterface.AccountSettings.Auctions.RestrictCharacterFilter)
	
	filterCharacterText:SetPoint("CENTERLEFT", filterCharacterCheck, "CENTERRIGHT", 5, 0)
	filterCharacterText:SetFontSize(14)
	filterCharacterText:SetText(L["ConfigSelling/FilterRestrictCharacter"])

	filterCompetitionText:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 120)
	filterCompetitionText:SetFontSize(14)
	filterCompetitionText:SetText(L["ConfigSelling/FilterCompetition"])
	
	filterBelowText:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 170)
	filterBelowText:SetFontSize(14)
	filterBelowText:SetText(L["ConfigSelling/FilterBelow"])

	filterScoreTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 220)
	filterScoreTitle:SetFontSize(14)
	filterScoreTitle:SetText(L["ConfigSelling/FilterScore"])
	
	filterCompetitionSelector:SetPoint("CENTERLEFT", filterCompetitionText, "CENTERLEFT", 200, 0)
	filterCompetitionSelector:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 115)
	filterCompetitionSelector:SetTextSelector("displayName")
	filterCompetitionSelector:SetOrderSelector("order")
	filterCompetitionSelector:SetValues({
		{ displayName = L["General/CompetitionName1"], order = 1, },
		{ displayName = L["General/CompetitionName2"], order = 2, },
		{ displayName = L["General/CompetitionName3"], order = 3, },
		{ displayName = L["General/CompetitionName4"], order = 4, },
		{ displayName = L["General/CompetitionName5"], order = 5, },
	})
	filterCompetitionSelector:SetSelectedKey(InternalInterface.AccountSettings.Auctions.DefaultCompetitionFilter)

	filterBelowSlider:SetPoint("CENTERRIGHT", frame, "TOPRIGHT", -10, 170)
	filterBelowSlider:SetPoint("CENTERLEFT", filterBelowText, "CENTERLEFT", 200, 0)
	filterBelowSlider:SetRange(0, 20)
	filterBelowSlider:SetPosition(InternalInterface.AccountSettings.Auctions.DefaultBelowFilter)

	filterFrame:SetPoint("CENTERLEFT", filterScoreTitle, "CENTERLEFT", 200, 0)
	filterFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 205)
	
	filterScoreNilCheck:SetPoint("CENTERLEFT", filterFrame, 0, 0.5)
	filterScoreNilCheck:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[1] or false)
	filterScore1Check:SetPoint("CENTERLEFT", filterFrame, 1 / 6, 0.5)
	filterScore1Check:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[2] or false)
	filterScore2Check:SetPoint("CENTERLEFT", filterFrame, 2 / 6, 0.5)
	filterScore2Check:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[3] or false)
	filterScore3Check:SetPoint("CENTERLEFT", filterFrame, 3 / 6, 0.5)
	filterScore3Check:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[4] or false)
	filterScore4Check:SetPoint("CENTERLEFT", filterFrame, 4 / 6, 0.5)
	filterScore4Check:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[5] or false)
	filterScore5Check:SetPoint("CENTERLEFT", filterFrame, 5 / 6, 0.5)
	filterScore5Check:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[6] or false)
	
	filterScoreNilText:SetPoint("CENTERLEFT", filterScoreNilCheck, "CENTERRIGHT", 5, 0)
	filterScoreNilText:SetText(L["General/ScoreName0"])
	filterScore1Text:SetPoint("CENTERLEFT", filterScore1Check, "CENTERRIGHT", 5, 0)
	filterScore1Text:SetText(L["General/ScoreName1"])
	filterScore2Text:SetPoint("CENTERLEFT", filterScore2Check, "CENTERRIGHT", 5, 0)
	filterScore2Text:SetText(L["General/ScoreName2"])
	filterScore3Text:SetPoint("CENTERLEFT", filterScore3Check, "CENTERRIGHT", 5, 0)
	filterScore3Text:SetText(L["General/ScoreName3"])
	filterScore4Text:SetPoint("CENTERLEFT", filterScore4Check, "CENTERRIGHT", 5, 0)
	filterScore4Text:SetText(L["General/ScoreName4"])
	filterScore5Text:SetPoint("CENTERLEFT", filterScore5Check, "CENTERRIGHT", 5, 0)
	filterScore5Text:SetText(L["General/ScoreName5"])
	
	function allowLeftCancelCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.BypassCancelPopup = self:GetChecked()
	end
	
	function filterCharacterCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.RestrictCharacterFilter = self:GetChecked()
	end
	
	function filterCompetitionSelector.Event:SelectionChanged()
		InternalInterface.AccountSettings.Auctions.DefaultCompetitionFilter = (self:GetSelectedValue())
	end
	
	function filterBelowSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.Auctions.DefaultBelowFilter = position
	end

	function filterScoreNilCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[1] = self:GetChecked()
	end
	
	function filterScore1Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[2] = self:GetChecked()
	end
	
	function filterScore2Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[3] = self:GetChecked()
	end
	
	function filterScore3Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[4] = self:GetChecked()
	end
	
	function filterScore4Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[5] = self:GetChecked()
	end
	
	function filterScore5Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[6] = self:GetChecked()
	end
	
	return frame
end

local function ScoreSettings(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".PriceScoreSettings", parent)
	
	local defaultPriceScorerText = UICreateFrame("Text", frame:GetName() .. ".DefaultPriceScorerText", frame)
	local defaultPriceScorerDropdown = Dropdown(frame:GetName() .. ".DefaultPriceScorerDropdown", frame)
	local colorNilSample = Panel(frame:GetName() .. ".ColorNilSample", frame)
	local color1Sample = Panel(frame:GetName() .. ".Color1Sample", frame)
	local color2Sample = Panel(frame:GetName() .. ".Color2Sample", frame)
	local color3Sample = Panel(frame:GetName() .. ".Color3Sample", frame)
	local color4Sample = Panel(frame:GetName() .. ".Color4Sample", frame)
	local color5Sample = Panel(frame:GetName() .. ".Color5Sample", frame)
	local colorNilText = UICreateFrame("Text", frame:GetName() .. ".ColorNilText", frame)
	local color1Text = UICreateFrame("Text", frame:GetName() .. ".Color1Text", frame)
	local color2Text = UICreateFrame("Text", frame:GetName() .. ".Color2Text", frame)
	local color3Text = UICreateFrame("Text", frame:GetName() .. ".Color3Text", frame)
	local color4Text = UICreateFrame("Text", frame:GetName() .. ".Color4Text", frame)
	local color5Text = UICreateFrame("Text", frame:GetName() .. ".Color5Text", frame)
	local color1Limit = Slider(frame:GetName() .. ".Color1Limit", frame)
	local color2Limit = Slider(frame:GetName() .. ".Color2Limit", frame)
	local color3Limit = Slider(frame:GetName() .. ".Color3Limit", frame)
	local color4Limit = Slider(frame:GetName() .. ".Color4Limit", frame)
	local samplePanel = Panel(frame:GetName() .. ".SamplePanel", frame)
	local color1SamplePanel = UICreateFrame("Frame", frame:GetName() .. ".Color1SamplePanel", samplePanel:GetContent())
	local color2SamplePanel = UICreateFrame("Frame", frame:GetName() .. ".Color2SamplePanel", samplePanel:GetContent())
	local color3SamplePanel = UICreateFrame("Frame", frame:GetName() .. ".Color3SamplePanel", samplePanel:GetContent())
	local color4SamplePanel = UICreateFrame("Frame", frame:GetName() .. ".Color4SamplePanel", samplePanel:GetContent())
	local color5SamplePanel = UICreateFrame("Frame", frame:GetName() .. ".Color5SamplePanel", samplePanel:GetContent())

	local propagateFlag = false
	
	local function ResetDefaultPriceScorer()
		local priceModels = GetPriceModels() -- FIXME Use those of BananAH, not the LibPGCEx ones
		for id, name in pairs(priceModels) do priceModels[id] = { displayName = name } end
		local defaultScorer = InternalInterface.AccountSettings.Scoring.ReferencePrice
		defaultPriceScorerDropdown:SetValues(priceModels)
		if priceModels[defaultScorer] then
			defaultPriceScorerDropdown:SetSelectedKey(defaultScorer)
		end
	end
	
	local function ResetColorSample()
		color1SamplePanel:ClearAll()
		color2SamplePanel:ClearAll()
		color3SamplePanel:ClearAll()
		color4SamplePanel:ClearAll()

		local limit1, limit2, limit3, limit4 = color1Limit:GetPosition(), color2Limit:GetPosition(), color3Limit:GetPosition(), color4Limit:GetPosition()
		local content = samplePanel:GetContent()
		local width = content:GetWidth()

		color1SamplePanel:SetPoint("TOPLEFT", content, "TOPLEFT")
		color1SamplePanel:SetPoint("BOTTOMRIGHT", content, limit1 / 999, 1)

		color2SamplePanel:SetPoint("TOPLEFT", content, limit1 / 999, 0)
		color2SamplePanel:SetPoint("BOTTOMRIGHT", content, limit2 / 999, 1)

		color3SamplePanel:SetPoint("TOPLEFT", content, limit2 / 999, 0)
		color3SamplePanel:SetPoint("BOTTOMRIGHT", content, limit3 / 999, 1)

		color4SamplePanel:SetPoint("TOPLEFT", content, limit3 / 999, 0)
		color4SamplePanel:SetPoint("BOTTOMRIGHT", content, limit4 / 999, 1)

		color5SamplePanel:SetPoint("TOPLEFT", content, limit4 / 999, 0)
		color5SamplePanel:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT")
		
		InternalInterface.AccountSettings.Scoring.ColorLimits = { limit1, limit2, limit3, limit4 }
	end
	
	frame:SetVisible(false)

	defaultPriceScorerText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	defaultPriceScorerText:SetFontSize(14)
	defaultPriceScorerText:SetText(L["ConfigScore/ReferencePrice"])
	
	defaultPriceScorerDropdown:SetPoint("CENTERLEFT", defaultPriceScorerText, "CENTERLEFT", 200, 0)
	defaultPriceScorerDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 3)
	defaultPriceScorerDropdown:SetTextSelector("displayName")
	
	colorNilSample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 90)
	colorNilSample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 120)
	colorNilSample:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(nil)))
	colorNilSample:SetInvertedBorder(true)
	
	color1Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 140)
	color1Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 170)
	color1Sample:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(1)))
	color1Sample:SetInvertedBorder(true)
	
	color2Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 190)
	color2Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 220)
	color2Sample:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(2)))
	color2Sample:SetInvertedBorder(true)
	
	color3Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 240)
	color3Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 270)
	color3Sample:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(3)))
	color3Sample:SetInvertedBorder(true)
	
	color4Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 290)
	color4Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 320)
	color4Sample:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(4)))
	color4Sample:SetInvertedBorder(true)
	
	color5Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 340)
	color5Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 370)
	color5Sample:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(5)))
	color5Sample:SetInvertedBorder(true)
	
	colorNilText:SetPoint("CENTERLEFT", colorNilSample, "CENTERRIGHT", 10, 0)
	colorNilText:SetFontSize(14)
	colorNilText:SetText(L["General/ScoreName0"])
	
	color1Text:SetPoint("CENTERLEFT", color1Sample, "CENTERRIGHT", 10, 0)
	color1Text:SetFontSize(14)
	color1Text:SetText(L["General/ScoreName1"])
	
	color2Text:SetPoint("CENTERLEFT", color2Sample, "CENTERRIGHT", 10, 0)
	color2Text:SetFontSize(14)
	color2Text:SetText(L["General/ScoreName2"])
	
	color3Text:SetPoint("CENTERLEFT", color3Sample, "CENTERRIGHT", 10, 0)
	color3Text:SetFontSize(14)
	color3Text:SetText(L["General/ScoreName3"])
	
	color4Text:SetPoint("CENTERLEFT", color4Sample, "CENTERRIGHT", 10, 0)
	color4Text:SetFontSize(14)
	color4Text:SetText(L["General/ScoreName4"])
	
	color5Text:SetPoint("CENTERLEFT", color5Sample, "CENTERRIGHT", 10, 0)
	color5Text:SetFontSize(14)
	color5Text:SetText(L["General/ScoreName5"])
	
	color1Limit:SetPoint("TOPLEFT", color1Sample, "BOTTOMRIGHT", 200, 0)
	color1Limit:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 190)
	color1Limit:SetRange(0, 999)
	color1Limit:SetPosition(InternalInterface.AccountSettings.Scoring.ColorLimits[1])
	
	color2Limit:SetPoint("TOPLEFT", color2Sample, "BOTTOMRIGHT", 200, 0)
	color2Limit:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 240)
	color2Limit:SetRange(0, 999)
	color2Limit:SetPosition(InternalInterface.AccountSettings.Scoring.ColorLimits[2])
	
	color3Limit:SetPoint("TOPLEFT", color3Sample, "BOTTOMRIGHT", 200, 0)
	color3Limit:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 290)
	color3Limit:SetRange(0, 999)
	color3Limit:SetPosition(InternalInterface.AccountSettings.Scoring.ColorLimits[3])
	
	color4Limit:SetPoint("TOPLEFT", color4Sample, "BOTTOMRIGHT", 200, 0)
	color4Limit:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 340)
	color4Limit:SetRange(0, 999)
	color4Limit:SetPosition(InternalInterface.AccountSettings.Scoring.ColorLimits[4])
	
	samplePanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 390)
	samplePanel:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 420)
	samplePanel:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(nil)))
	
	color1SamplePanel:SetBackgroundColor(unpack(ScoreColorByIndex(1)))
	color2SamplePanel:SetBackgroundColor(unpack(ScoreColorByIndex(2)))
	color3SamplePanel:SetBackgroundColor(unpack(ScoreColorByIndex(3)))
	color4SamplePanel:SetBackgroundColor(unpack(ScoreColorByIndex(4)))
	color5SamplePanel:SetBackgroundColor(unpack(ScoreColorByIndex(5)))
	
	function defaultPriceScorerDropdown.Event:SelectionChanged()
		local index = self:GetSelectedValue()
		InternalInterface.AccountSettings.Scoring.ReferencePrice = index
	end

	
	function color1Limit.Event:PositionChanged(position)
		if not propagateFlag then
			propagateFlag = true
			color2Limit:SetPosition(MMax(position, color2Limit:GetPosition()))
			color3Limit:SetPosition(MMax(color2Limit:GetPosition(), color3Limit:GetPosition()))
			color4Limit:SetPosition(MMax(color3Limit:GetPosition(), color4Limit:GetPosition()))
			propagateFlag = false
			ResetColorSample()
		end
	end
	
	function color2Limit.Event:PositionChanged(position)
		if not propagateFlag then
			propagateFlag = true
			color1Limit:SetPosition(MMin(color1Limit:GetPosition(), position))
			color3Limit:SetPosition(MMax(position, color3Limit:GetPosition()))
			color4Limit:SetPosition(MMax(color3Limit:GetPosition(), color4Limit:GetPosition()))
			propagateFlag = false
			ResetColorSample()
		end
	end
	
	function color3Limit.Event:PositionChanged(position)
		if not propagateFlag then
			propagateFlag = true
			color2Limit:SetPosition(MMin(color2Limit:GetPosition(), position))
			color1Limit:SetPosition(MMin(color1Limit:GetPosition(), color2Limit:GetPosition()))
			color4Limit:SetPosition(MMax(position, color4Limit:GetPosition()))
			propagateFlag = false
			ResetColorSample()
		end
	end
	
	function color4Limit.Event:PositionChanged(position)
		if not propagateFlag then
			propagateFlag = true
			color3Limit:SetPosition(MMin(color3Limit:GetPosition(), position))
			color2Limit:SetPosition(MMin(color2Limit:GetPosition(), color3Limit:GetPosition()))
			color1Limit:SetPosition(MMin(color1Limit:GetPosition(), color2Limit:GetPosition()))
			propagateFlag = false
			ResetColorSample()
		end
	end
	
	ResetDefaultPriceScorer()
	ResetColorSample()
	
	return frame
end

local function PriceSettings(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".PriceSettings", parent)
	
	local topSelector, topControls = BuildConfigFrame(frame:GetName() .. ".TopSelector", frame, 
		{
			category =
			{
				name = "Item category", -- LOCALIZE
				nameFontSize = 14,
				value = "category",
				defaultValue = "",
			},
			inheritance = 
			{
				name = "Category config.", -- LOCALIZE
				nameFontSize = 14,
				value = "selectOne",
				textSelector = "name",
				orderSelector = "order",
				values =
				{
					["inherit"] = { name = "Inherit from parent category", order = 1 }, -- LOCALIZE
					["own"] = { name = "Define custom parameters for this category", order = 2 }, -- LOCALIZE
				},
				defaultValue = "inherit",
			},
			Layout =
			{ 
				{ "category" },
				{ "inheritance" },
				columns = 1,
			},		
		})
	local saveButton = UICreateFrame("RiftButton", frame:GetName() .. ".SaveButton", frame)
	
	local postFrame = UICreateFrame("Frame", frame:GetName() .. ".PostFrame", frame)
	local stackSelector, stackControls = BuildConfigFrame(postFrame:GetName() .. ".StackSelector", postFrame,
		{
			stackSize =
			{
				name = L["ConfigPost/DefaultStackSize"], -- TODO Remove colon / Move to ConfigPrice
				nameFontSize = 14,
				value = "integer",
				minValue = 1,
				maxValue = 100,
				defaultValue = 100,
			},
			stackNumber =
			{
				name = L["ConfigPost/DefaultStackNumber"], -- TODO Remove colon / Move to ConfigPrice
				nameFontSize = 14,
				value = "integer",
				minValue = 1,
				maxValue = 100,
				defaultValue = 100,
			},
			Layout =
			{
				{ "stackSize" },
				{ "stackNumber" },
				columns = 1,
			},
		})
	local postSelector, postControls = BuildConfigFrame(postFrame:GetName() .. ".StackSelector", postFrame,
		{
			-- matchPrices =
			-- {
				-- name = L["ConfigPost/ApplyMatching"], -- TODO Move to ConfigPrice
				-- nameFontSize = 14,
				-- value = "boolean",
				-- defaultValue = false,
			-- },
			duration =
			{
				name = L["ConfigPost/DefaultDuration"], -- TODO Remove colon / Move to ConfigPrice
				nameFontSize = 14,
				value = "integer",
				minValue = 48,
				maxValue = 48,
				defaultValue = 48,
			},
			Layout =
			{
				-- { "matchPrices" },
				{ "duration" },
				columns = 1,
			},
		})
	local priceGrid = DataGrid(postFrame:GetName() .. ".PriceModelGrid", postFrame)
	local controlFrame = UICreateFrame("Frame", postFrame:GetName() .. ".ControlFrame", priceGrid:GetContent())
	local deleteButton = UICreateFrame("RiftButton", postFrame:GetName() .. ".DeleteButton", controlFrame)
	local editButton = UICreateFrame("RiftButton", postFrame:GetName() .. ".EditButton", controlFrame)
	local newButton = UICreateFrame("RiftButton", postFrame:GetName() .. ".NewButton", controlFrame)
	local matchPanel = Panel(postFrame:GetName() .. ".MatchPanel", controlFrame)
	local matchCheck = UICreateFrame("RiftCheckbox", postFrame:GetName() .. ".MatchCheck", matchPanel:GetContent())
	local matchText = UICreateFrame("Text", postFrame:GetName() .. ".MatchLabel", matchPanel:GetContent())
	
	local currentCategory = topControls.category:GetSelectedValue()
	local currentDefaultModel = nil
	local currentFallbackModel = nil
	
	local function GetSavedSettings(category)
		return category and InternalInterface.AccountSettings.Posting.CategoryConfig[category] or nil
	end
	
	local function SetSavedSettings(category, settings)
		InternalInterface.AccountSettings.Posting.CategoryConfig[category] = settings
	end
	
	local function GetEditSettings()
		if (topControls.inheritance:GetSelectedValue()) == "inherit" then return nil end
		
		local blackList = {}
		local models = priceGrid:GetData()
		for modelID, modelInfo in pairs(models) do
			if not modelInfo.enabled then
				blackList[modelID] = true
			end
		end
		
		return
		{
			DefaultReferencePrice = currentDefaultModel,
			FallbackReferencePrice = currentFallbackModel,
			ApplyMatching = matchCheck:GetChecked(),
			StackSize = stackControls.stackSize:GetPosition(),
			StackNumber = stackControls.stackNumber:GetPosition(),
			StackLimit = false,
			Duration = MMin(postControls.duration:GetPosition() / 12, 3),
			BlackList = blackList,
		}
	end
	
	local function SetEditSettings(settings, inherited)
		topControls.inheritance:SetSelectedKey(inherited and "inherit" or "own")

		currentDefaultModel = settings.DefaultReferencePrice
		currentFallbackModel = settings.FallbackReferencePrice
		
		matchCheck:SetChecked(settings.ApplyMatching)
		stackControls.stackSize:SetPosition(settings.StackSize)
		stackControls.stackNumber:SetPosition(settings.StackNumber)
		-- StackLimit
		postControls.duration:SetPosition(45 + settings.Duration) -- HACK

		local models = GetCategoryModels(currentCategory)
		local blackList = settings.BlackList or {}
		for model, modelInfo in pairs(models) do
			modelInfo.enabled = not blackList[model]
			modelInfo.original = true
		end
		priceGrid:SetData(models)
	end
	
	local function CompareSettings(settings1, settings2)
		if settings1 == nil or settings2 == nil then
			return settings1 == settings2
		end
		
		if settings1.DefaultReferencePrice ~= settings2.DefaultReferencePrice or
	       settings1.FallbackReferencePrice ~= settings2.FallbackReferencePrice or
	       settings1.ApplyMatching ~= settings2.ApplyMatching or
	       settings1.StackSize ~= settings2.StackSize or
	       settings1.StackNumber ~= settings2.StackNumber or
	       settings1.StackLimit ~= settings2.StackLimit or
	       settings1.Duration ~= settings2.Duration then
			return false
		end
		
		for modelID in pairs(settings1.BlackList) do
			if not settings2.BlackList[modelID] then return false end
		end
		for modelID in pairs(settings2.BlackList) do
			if not settings1.BlackList[modelID] then return false end
		end
		
		local editModels = priceGrid:GetData() or {}
		for modelID, modelInfo in pairs(editModels) do
			if not modelInfo.original then return false end
		end
		
		return true
	end
	
	local function IsOriginal(value, key)
		if not value.own then return nil end
		return value.original
	end
	
	local function IsDefaultModel(value, key)
		if not value.enabled then return nil end
		return key == currentDefaultModel
	end
	
	local function IsFallbackModel(value, key)
		if value.modelType ~= "simple" or not value.enabled then return nil end
		return key == currentFallbackModel
	end
	
	local function EnabledInteract(key)
		local data = priceGrid:GetData()
		if key and data and data[key] and key ~= currentDefaultModel and key ~= currentFallbackModel then
			data[key].enabled = not data[key].enabled
		end
		priceGrid:RefreshFilter()
	end
	
	local function DefaultInteract(key)
		currentDefaultModel = key
		priceGrid:RefreshFilter()
	end
	
	local function FallbackInteract(key)
		currentFallbackModel = key
		priceGrid:RefreshFilter()
	end
	
	saveButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 25)
	saveButton:SetText("Save") -- LOCALIZE
	
	topSelector:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 5)
	topSelector:SetPoint("RIGHT", saveButton, "LEFT")

	topControls.inheritance:SetEnabled(false)
	
	postFrame:SetPoint("TOPLEFT", topSelector, "BOTTOMLEFT", 0, 20)
	postFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, -5)
	
	stackSelector:SetPoint("TOPLEFT", postFrame, "TOPLEFT")
	stackSelector:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT")
	
	stackControls.stackSize:AddPostValue(L["Misc/StackSizeMaxKeyShortcut"], "+", L["Misc/StackSizeMax"])
	
	stackControls.stackNumber:AddPostValue(L["Misc/StacksFullKeyShortcut"], "F", L["Misc/StacksFull"])
	stackControls.stackNumber:AddPostValue(L["Misc/StacksAllKeyShortcut"], "A", L["Misc/StacksAll"])
	
	postSelector:SetPoint("BOTTOMLEFT", postFrame, "BOTTOMLEFT")
	postSelector:SetPoint("BOTTOMRIGHT", postFrame, "BOTTOMRIGHT")

	postControls.duration:AddPreValue("1", 12, "12")
	postControls.duration:AddPreValue("2", 24, "24")
	
	priceGrid:SetPadding(1, 1, 1, 38)
	priceGrid:SetHeadersVisible(true)
	priceGrid:SetRowHeight(20)
	priceGrid:SetRowMargin(0)
	priceGrid:SetUnselectedRowBackgroundColor({0.2, 0.2, 0.2, 0.25})
	priceGrid:SetSelectedRowBackgroundColor({0.6, 0.6, 0.6, 0.25})	
	priceGrid:SetPoint("TOPLEFT", stackSelector, "BOTTOMLEFT", 0, 10)
	priceGrid:SetPoint("BOTTOMRIGHT", postSelector, "TOPRIGHT", 0, -10)
	priceGrid:AddColumn("own", "", BooleanDotCellType, 20, 0, nil, false, { Eval = IsOriginal, })
	priceGrid:AddColumn("name", "Reference Price", "Text", 140, 2, "name", true, { Alignment = "left", Formatter = "none", }) -- LOCALIZE
	priceGrid:AddColumn("enabled", "Active", BooleanDotCellType, 60, 0, "enabled", false, { Interactable = EnabledInteract, }) -- LOCALIZE
	priceGrid:AddColumn("default", "Default", BooleanDotCellType, 60, 0, nil, false, { Eval = IsDefaultModel, Interactable = DefaultInteract, }) -- LOCALIZE
	priceGrid:AddColumn("fallback", "Fallback", BooleanDotCellType, 60, 0, nil, false, { Eval = IsFallbackModel, Interactable = FallbackInteract, }) -- LOCALIZE
	priceGrid:SetOrder("name", false)
	priceGrid:GetInternalContent():SetBackgroundColor(0.05, 0, 0.05, 0.25)
	
	controlFrame:SetPoint("TOPLEFT", priceGrid:GetContent(), "BOTTOMLEFT", 3, -36)
	controlFrame:SetPoint("BOTTOMRIGHT", priceGrid:GetContent(), "BOTTOMRIGHT", -3, -2)
	
	deleteButton:SetPoint("CENTERRIGHT", controlFrame, "CENTERRIGHT", 0, 0)
	deleteButton:SetText("Delete") -- LOCALIZE
	deleteButton:SetEnabled(false)

	editButton:SetPoint("CENTERRIGHT", deleteButton, "CENTERLEFT", 10, 0)
	editButton:SetText("Edit") -- LOCALIZE
	editButton:SetEnabled(false)	

	newButton:SetPoint("CENTERRIGHT", editButton, "CENTERLEFT", 10, 0)
	newButton:SetText("New") -- LOCALIZE
	newButton:SetEnabled(false)	-- FIXME Remove this line
	
	matchPanel:SetPoint("BOTTOMLEFT", controlFrame, "BOTTOMLEFT", 0, -2)
	matchPanel:SetPoint("TOPRIGHT", newButton, "TOPLEFT", -3, 2)
	matchPanel:SetInvertedBorder(true)
	matchPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)

	matchCheck:SetPoint("CENTERLEFT", matchPanel:GetContent(), "CENTERLEFT", 5, 0)

	matchText:SetPoint("CENTERLEFT", matchCheck, "CENTERRIGHT", 5, 0)	
	matchText:SetText("Apply matching rules for unconfigured items") -- LOCALIZE
	
	for controlName, control in pairs(topControls) do
		control:SetLayer(9999)
	end
	
	if currentCategory ~= BASE_CATEGORY then
		currentCategory = BASE_CATEGORY
		topControls.category:SetSelectedKey(BASE_CATEGORY)
	end
	SetEditSettings(GetSavedSettings(currentCategory))
	
	function topControls.category.Event:SelectionChanged(category)
		if category ~= currentCategory then
			local function ContinueChange()
				currentCategory = category
				local settings = nil
				while not settings do
					settings = GetSavedSettings(category)
					if not settings then
						local detail = CDetail(category)
						category = detail and detail.parent or BASE_CATEGORY
					end
				end
				SetEditSettings(settings, category ~= currentCategory)
				topControls.inheritance:SetEnabled(currentCategory ~= BASE_CATEGORY)
			end
			
			local function CancelChange()
				topControls.category:SetSelectedKey(currentCategory)
			end
			
			local equal = CompareSettings(GetEditSettings(), GetSavedSettings(currentCategory))
			local manager = GetPopupManager()
			
			if not equal and manager then
				manager:ShowPopup(addonID .. ".UnsavedChanges", ContinueChange, CancelChange)
			else
				ContinueChange()
			end
		end
	end
	
	function topControls.inheritance.Event:SelectionChanged(inheritance)
		postFrame:SetVisible(inheritance == "own")
	end
	
	function saveButton.Event:LeftPress()
		SetSavedSettings(currentCategory, GetEditSettings())
	end
--[[	
	function priceGrid.Event:SelectionChanged(modelID, modelInfo)
		editButton:SetEnabled(modelInfo and modelInfo.own and true or false)
		
		local deleteable = modelInfo and modelInfo.own and modelID:sub(1, 3) == "bah" and true or false
		deleteable = deleteable and modelID ~= currentDefaultModel and modelID ~= currentFallbackModel
		 -- TODO Check deleteable in children categories
		deleteButton:SetEnabled(deleteable)
	end
]]	
	return frame
end

local function LoadConfigScreens(parent)
	local screens = {}
	
	screens["general"] = { title = L["ConfigFrame/CategoryGeneral"], frame = GeneralSettings(parent), order = 0 }
	screens["search"] = { title = L["ConfigFrame/CategorySearch"], frame = SearchSettings(parent), order = 100 }
	screens["post"] = { title = L["ConfigFrame/CategoryPost"], frame = PostingSettings(parent), order = 200 }
	screens["selling"] = { title = L["ConfigFrame/CategorySelling"], frame = AuctionsSettings(parent), order = 300 }
	screens["tracking"] = { title = L["ConfigFrame/CategoryTracking"], frame = nil, order = 400 }
	screens["history"] = { title = L["ConfigFrame/CategoryHistory"], frame = nil, order = 500 }
	screens["pricing"] = { title = L["ConfigFrame/CategoryPricing"], frame = PriceSettings(parent), order = 1000 }
	screens["scoring"] = { title = L["ConfigFrame/CategoryScoring"], frame = ScoreSettings(parent), order = 2000 }
	
	return screens
end

function InternalInterface.UI.ConfigFrame(name, parent)
	local configFrame = UICreateFrame("Frame", name, parent)
	local configSelector = DataGrid(name .. ".ConfigSelector", configFrame)
	local configDisplay = UICreateFrame("Mask", name .. ".ConfigDisplay", configFrame)
	
	local lastShownFrame = nil
	
	local function FontSizeSelector(value, key)
		local data = configSelector:GetData()
		local info = data and key and data[key] or nil
		local order = info and info.order or 0
		return order % 100 == 0 and 16 or 12
	end
	
	local function ColorSelector(value, key)
		local data = configSelector:GetData()
		local info = data and key and data[key] or nil
		if not info or (not info.frame and not info.children) then return { 0.5, 0.5, 0.5 } end
		local order = info and info.order or 0
		return order % 100 == 0 and { 1, 1, 0.75} or { 1, 1, 1 }
	end	
	
	configSelector:SetRowHeight(26)
	configSelector:SetSelectedRowBackgroundColor({0.4, 0.4, 0.4, 0.25})
	configSelector:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 5, 5)
	configSelector:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMLEFT", 295, -5)
	configSelector:AddColumn("title", nil, "Text", 200, 1, "title", false, { FontSize = FontSizeSelector, Color = ColorSelector })
	configSelector:AddColumn("order", nil, "Text", 0, 0, "order", true)
	configSelector:GetInternalContent():SetBackgroundColor(0, 0, 0.05, 0.5)

	configDisplay:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 300, 10)
	configDisplay:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -5, -10)

	function configSelector.Event:SelectionChanged(selectedKey, selectedValue)
		if not selectedKey then return end
		
		local newFrame = selectedValue.frame or (selectedValue.children and selectedValue.children[1].frame or nil)
		
		if lastShownFrame then
			lastShownFrame:SetVisible(false)
		end
		
		lastShownFrame = newFrame

		if lastShownFrame then
			lastShownFrame:SetAllPoints()
			lastShownFrame:SetVisible(true)
		end
	end	
	
	configSelector:SetData(LoadConfigScreens(configDisplay))
	
	return configFrame
end