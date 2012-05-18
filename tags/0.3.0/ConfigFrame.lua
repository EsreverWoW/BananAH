local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local L = InternalInterface.Localization.L

local function GeneralSettings(parent)
	local frame = UI.CreateFrame("Frame", parent:GetName() .. ".GeneralSettings", parent)
	
	local showMapIconCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".ShowMapIconCheck", frame)
	local showMapIconText = UI.CreateFrame("Text", frame:GetName() .. ".ShowMapIconText", frame)
	local autoOpenCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".AutoOpenCheck", frame)
	local autoOpenText = UI.CreateFrame("Text", frame:GetName() .. ".AutoOpenText", frame)
	local autoCloseCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".AutoCloseCheck", frame)
	local autoCloseText = UI.CreateFrame("Text", frame:GetName() .. ".AutoCloseText", frame)
	local disableMonitorCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".DisableMonitorCheck", frame)
	local disableMonitorText = UI.CreateFrame("Text", frame:GetName() .. ".DisableMonitorText", frame)
	
	frame:SetVisible(false)
	
	showMapIconCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	showMapIconCheck:SetChecked(InternalInterface.AccountSettings.General.showMapIcon or false)
	
	showMapIconText:SetPoint("CENTERLEFT", showMapIconCheck, "CENTERRIGHT", 5, 0)
	showMapIconText:SetFontSize(14)
	showMapIconText:SetText(L["ConfigPanel/mapIconShow"])
	
	autoOpenCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 55)
	autoOpenCheck:SetChecked(InternalInterface.AccountSettings.General.autoOpen or false)
	
	autoOpenText:SetPoint("CENTERLEFT", autoOpenCheck, "CENTERRIGHT", 5, 0)
	autoOpenText:SetFontSize(14)
	autoOpenText:SetText(L["ConfigPanel/autoOpenWindow"])
	
	autoCloseCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 85)
	autoCloseCheck:SetChecked(InternalInterface.AccountSettings.General.autoClose or false)
	
	autoCloseText:SetPoint("CENTERLEFT", autoCloseCheck, "CENTERRIGHT", 5, 0)
	autoCloseText:SetFontSize(14)
	autoCloseText:SetText(L["ConfigPanel/autoCloseWindow"])
	
	disableMonitorCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 130)
	disableMonitorCheck:SetChecked(InternalInterface.AccountSettings.General.disableBackgroundScanner or false)
	
	disableMonitorText:SetPoint("CENTERLEFT", disableMonitorCheck, "CENTERRIGHT", 5, 0)
	disableMonitorText:SetFontSize(14)
	disableMonitorText:SetText(L["ConfigPanel/DisableScanner"])
	
	function showMapIconCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.General.showMapIcon = self:GetChecked()
		InternalInterface.UI.MapIcon:SetVisible(InternalInterface.AccountSettings.General.showMapIcon)
	end
	
	function autoOpenCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.General.autoOpen = self:GetChecked()
	end
	
	function autoCloseCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.General.autoClose = self:GetChecked()
	end
	
	function disableMonitorCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.General.disableBackgroundScanner = self:GetChecked()
	end
	
	return frame
end

local function PostingSettings(parent)
	local frame = UI.CreateFrame("Frame", parent:GetName() .. ".PostingSettings", parent)

	local startQueuePausedCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".StartQueuePausedCheck", frame)
	local startQueuePausedText = UI.CreateFrame("Text", frame:GetName() .. ".StartQueuePausedText", frame)
	local rarityFilterText = UI.CreateFrame("Text", frame:GetName() .. ".RarityFilterText", frame)
	local rarityFilterDropdown = UI.CreateFrame("BDropdown", frame:GetName() .. ".RarityFilterDropdown", frame)
	local defaultPriceMatchingCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".DefaultPriceMatchingCheck", frame)
	local defaultPriceMatchingText = UI.CreateFrame("Text", frame:GetName() .. ".DefaultPriceMatchingText", frame)
	local defaultBindPricesCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".DefaultBindPricesCheck", frame)
	local defaultBindPricesText = UI.CreateFrame("Text", frame:GetName() .. ".DefaultBindPricesText", frame)
	local pricingModelTitle = UI.CreateFrame("Text", frame:GetName() .. ".PricingModelTitle", frame)
	local pricingModelGrid = UI.CreateFrame("BDataGrid", frame:GetName() .. ".PricingModelGrid", frame)
	local pricingModelTop = UI.CreateFrame("Texture", frame:GetName() .. ".PricingModelTop", frame)
	local pricingModelUp = UI.CreateFrame("Texture", frame:GetName() .. ".PricingModelUp", frame)
	local pricingModelDown = UI.CreateFrame("Texture", frame:GetName() .. ".PricingModelDown", frame)
	local pricingModelBottom = UI.CreateFrame("Texture", frame:GetName() .. ".PricingModelBottom", frame)
	local priceMatcherTitle = UI.CreateFrame("Text", frame:GetName() .. ".PriceMatcherTitle", frame)
	local priceMatcherGrid = UI.CreateFrame("BDataGrid", frame:GetName() .. ".PriceMatcherGrid", frame)
	local priceMatcherTop = UI.CreateFrame("Texture", frame:GetName() .. ".PriceMatcherTop", frame)
	local priceMatcherUp = UI.CreateFrame("Texture", frame:GetName() .. ".PriceMatcherUp", frame)
	local priceMatcherDown = UI.CreateFrame("Texture", frame:GetName() .. ".PriceMatcherDown", frame)
	local priceMatcherBottom = UI.CreateFrame("Texture", frame:GetName() .. ".PriceMatcherBottom", frame)
	local defaultDurationText = UI.CreateFrame("Text", frame:GetName() .. ".DefaultDurationText", frame)
	local defaultDurationSlider = UI.CreateFrame("RiftSlider", frame:GetName() .. ".DefaultDurationSlider", frame)
	local defaultDurationTime = UI.CreateFrame("Text", frame:GetName() .. ".DefaultDurationTime", frame)

	local function ResetPricingModelGrid()
		local defaultOrder = InternalInterface.AccountSettings.Posting.DefaultConfig.pricingModelOrder or {}

		local pricingModels = InternalInterface.PricingModelService.GetAllPricingModels()
		local priceScorers = InternalInterface.PricingModelService.GetAllPriceScorers() 

		local data = {}
		
		local count = 0
		for _, key in ipairs(defaultOrder) do
			if priceScorers[key] then
				data[key] = { displayName = priceScorers[key].displayName, index = count }
				count = count + 1
			elseif pricingModels[key] then
				data[key] = { displayName = pricingModels[key].displayName, index = count }
				count = count + 1
			end
		end
		
		for key, priceScorer in pairs(priceScorers) do
			if not data[key] then
				data[key] = { displayName = priceScorer.displayName, index = count }
				count = count + 1
			end
		end
		
		for key, pricingModel in pairs(pricingModels) do
			if not data[key] then
				data[key] = { displayName = pricingModel.displayName, index = count }
				count = count + 1
			end
		end
		
		pricingModelGrid:SetData(data)
	end
	
	local function ResetPriceMatcherGrid()
		local defaultOrder = InternalInterface.AccountSettings.Posting.DefaultConfig.priceMatcherOrder or {}

		local priceMatchers = InternalInterface.PricingModelService.GetAllPriceMatchers() 

		local data = {}
		
		local count = 0
		for _, key in ipairs(defaultOrder) do
			if priceMatchers[key] then
				data[key] = { displayName = priceMatchers[key].displayName, index = count }
				count = count + 1
			end
		end
		
		for key, priceMatcher in pairs(priceMatchers) do
			if not data[key] then
				data[key] = { displayName = priceMatcher.displayName, index = count }
				count = count + 1
			end
		end
		
		priceMatcherGrid:SetData(data)
	end
	
	frame:SetVisible(false)

	startQueuePausedCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	startQueuePausedCheck:SetChecked(InternalInterface.AccountSettings.Posting.startPostingQueuePaused or false)
	
	startQueuePausedText:SetPoint("CENTERLEFT", startQueuePausedCheck, "CENTERRIGHT", 5, 0)
	startQueuePausedText:SetFontSize(14)
	startQueuePausedText:SetText(L["ConfigPanel/defaultPausedPostingQueue"])
	
	rarityFilterText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 90)
	rarityFilterText:SetFontSize(14)
	rarityFilterText:SetText(L["ConfigPanel/RarityFilter"])
	
	rarityFilterDropdown:SetPoint("CENTERLEFT", rarityFilterText, "CENTERRIGHT", 10, 0)
	rarityFilterDropdown:SetPoint("TOPRIGHT", frame, "TOPCENTER", -20, 83)
	rarityFilterDropdown:SetValues({
		{ displayName = L["General/Rarity1"], rarity = "sellable", },
		{ displayName = L["General/Rarity2"], rarity = nil, },
		{ displayName = L["General/Rarity3"], rarity = "uncommon", },
		{ displayName = L["General/Rarity4"], rarity = "rare", },
		{ displayName = L["General/Rarity5"], rarity = "epic", },
		{ displayName = L["General/Rarity6"], rarity = "relic", },
		{ displayName = L["General/Rarity7"], rarity = "transcendant", },
		{ displayName = L["General/Rarity0"], rarity = "quest", },
	})
	rarityFilterDropdown:SetSelectedIndex(InternalInterface.AccountSettings.Posting.rarityFilter or 1)
	
	defaultPriceMatchingCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 170)
	defaultPriceMatchingCheck:SetChecked(InternalInterface.AccountSettings.Posting.DefaultConfig.usePriceMatching or false)
	
	defaultPriceMatchingText:SetPoint("CENTERLEFT", defaultPriceMatchingCheck, "CENTERRIGHT", 5, 0)
	defaultPriceMatchingText:SetFontSize(14)
	defaultPriceMatchingText:SetText(L["ConfigPanel/defaultPriceMatching"])
	
	defaultBindPricesCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 210)
	defaultBindPricesCheck:SetChecked(InternalInterface.AccountSettings.Posting.DefaultConfig.bindPrices or false)
	
	defaultBindPricesText:SetPoint("CENTERLEFT", defaultBindPricesCheck, "CENTERRIGHT", 5, 0)
	defaultBindPricesText:SetFontSize(14)
	defaultBindPricesText:SetText(L["ConfigPanel/defaultBindPrices"])
	
	pricingModelGrid:SetPoint("TOPLEFT", frame, "TOPCENTER", 10, 30)
	pricingModelGrid:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -30, 195)
	pricingModelGrid:SetPadding(1, 1, 1, 1)
	pricingModelGrid:SetRowHeight(20)
	pricingModelGrid:SetRowMargin(0)
	pricingModelGrid:SetUnselectedRowBackgroundColor(0.2, 0.2, 0.4, 0.25)
	pricingModelGrid:SetSelectedRowBackgroundColor(0.6, 0.6, 0.8, 0.25)
	pricingModelGrid:AddColumn("", pricingModelGrid:GetWidth(), "Text", false, "displayName", { Alignment = "left", Formatter = "none" })
	pricingModelGrid:AddColumn("", 0, "Text", true, "index")
	
	pricingModelTitle:SetPoint("BOTTOMCENTER", pricingModelGrid, "TOPCENTER", 0, -5)
	pricingModelTitle:SetFontSize(13)
	pricingModelTitle:SetText(L["ConfigPanel/DefaultPricingModelOrder"])
	
	pricingModelUp:SetPoint("BOTTOMLEFT", pricingModelGrid, "CENTERRIGHT", 5, -10)
	pricingModelUp:SetTexture(addonID, "Textures/MoveUp.png")
	
	pricingModelDown:SetPoint("TOPLEFT", pricingModelGrid, "CENTERRIGHT", 5, 10)
	pricingModelDown:SetTexture(addonID, "Textures/MoveDown.png")
	
	pricingModelTop:SetPoint("BOTTOMCENTER", pricingModelUp, "TOPCENTER", 0, -20)
	pricingModelTop:SetTexture(addonID, "Textures/MoveTop.png")
	
	pricingModelBottom:SetPoint("TOPCENTER", pricingModelDown, "BOTTOMCENTER", 0, 20)
	pricingModelBottom:SetTexture(addonID, "Textures/MoveBottom.png")
	
	priceMatcherGrid:SetPoint("TOPLEFT", frame, "TOPCENTER", 10, 255)
	priceMatcherGrid:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -30, 415)
	priceMatcherGrid:SetPadding(1, 1, 1, 1)
	priceMatcherGrid:SetRowHeight(20)
	priceMatcherGrid:SetRowMargin(0)
	priceMatcherGrid:SetUnselectedRowBackgroundColor(0.2, 0.2, 0.4, 0.25)
	priceMatcherGrid:SetSelectedRowBackgroundColor(0.6, 0.6, 0.8, 0.25)
	priceMatcherGrid:AddColumn("", priceMatcherGrid:GetWidth(), "Text", false, "displayName", { Alignment = "left", Formatter = "none" })
	priceMatcherGrid:AddColumn("", 0, "Text", true, "index")

	priceMatcherTitle:SetPoint("BOTTOMCENTER", priceMatcherGrid, "TOPCENTER", 0, -5)
	priceMatcherTitle:SetFontSize(13)
	priceMatcherTitle:SetText(L["ConfigPanel/DefaultPriceMatcherOrder"])

	priceMatcherUp:SetPoint("BOTTOMLEFT", priceMatcherGrid, "CENTERRIGHT", 5, -10)
	priceMatcherUp:SetTexture(addonID, "Textures/MoveUp.png")
	
	priceMatcherDown:SetPoint("TOPLEFT", priceMatcherGrid, "CENTERRIGHT", 5, 10)
	priceMatcherDown:SetTexture(addonID, "Textures/MoveDown.png")
	
	priceMatcherTop:SetPoint("BOTTOMCENTER", priceMatcherUp, "TOPCENTER", 0, -20)
	priceMatcherTop:SetTexture(addonID, "Textures/MoveTop.png")
	
	priceMatcherBottom:SetPoint("TOPCENTER", priceMatcherDown, "BOTTOMCENTER", 0, 20)
	priceMatcherBottom:SetTexture(addonID, "Textures/MoveBottom.png")
	
	defaultDurationText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 330)
	defaultDurationText:SetFontSize(14)
	defaultDurationText:SetText(L["ConfigPanel/defaultDuration"])

	defaultDurationTime:SetPoint("TOPRIGHT", frame, "TOPCENTER", -10, 330)
	defaultDurationTime:SetPoint("TOPLEFT", frame, "TOPCENTER", -100, 330)
	defaultDurationTime:SetFontSize(14)

	defaultDurationSlider:SetPoint("CENTERLEFT", defaultDurationText, "CENTERRIGHT", 40, 8)
	defaultDurationSlider:SetPoint("CENTERRIGHT", defaultDurationTime, "CENTERLEFT", -40, 8)
	defaultDurationSlider:SetRange(1, 3)
	defaultDurationSlider:SetPosition(InternalInterface.AccountSettings.Posting.DefaultConfig.duration or 3)

	defaultDurationTime:SetText(string.format(L["PostingPanel/labelDurationFormat"],  6 * 2 ^ defaultDurationSlider:GetPosition()))
	
	function startQueuePausedCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Posting.startPostingQueuePaused = self:GetChecked()
	end

	function defaultPriceMatchingCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Posting.DefaultConfig.usePriceMatching = self:GetChecked()
	end
	
	function defaultBindPricesCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Posting.DefaultConfig.bindPrices = self:GetChecked()
	end
	
	function defaultDurationSlider.Event:SliderChange()
		local position = self:GetPosition()
		defaultDurationTime:SetText(string.format(L["PostingPanel/labelDurationFormat"], 6 * 2 ^ position))
		InternalInterface.AccountSettings.Posting.DefaultConfig.duration = position
	end
	
	function pricingModelTop.Event:LeftClick()
		local data = pricingModelGrid:GetData()
		local selectedKey = pricingModelGrid:GetSelectedData()
		local newData = {}
		local newOrder = {}
		
		for key, value in pairs(data) do
			if key == selectedKey then
				newData[key] = -1
				table.insert(newOrder, key)
			else
				newData[key] = value.index
				table.insert(newOrder, key)
			end
		end
		table.sort(newOrder, function(a,b) return newData[a] < newData[b] end)
		
		InternalInterface.AccountSettings.Posting.DefaultConfig.pricingModelOrder = newOrder
		ResetPricingModelGrid()
	end
	
	function pricingModelUp.Event:LeftClick()
		local data = pricingModelGrid:GetData()
		local selectedKey = pricingModelGrid:GetSelectedData()
		local newData = {}
		local newOrder = {}
		
		for key, value in pairs(data) do
			if key == selectedKey then
				newData[key] = value.index - 1.1
				table.insert(newOrder, key)
			else
				newData[key] = value.index
				table.insert(newOrder, key)
			end
		end
		table.sort(newOrder, function(a,b) return newData[a] < newData[b] end)
		
		InternalInterface.AccountSettings.Posting.DefaultConfig.pricingModelOrder = newOrder
		ResetPricingModelGrid()
	end
	
	function pricingModelDown.Event:LeftClick()
		local data = pricingModelGrid:GetData()
		local selectedKey = pricingModelGrid:GetSelectedData()
		local newData = {}
		local newOrder = {}
		
		for key, value in pairs(data) do
			if key == selectedKey then
				newData[key] = value.index + 1.1
				table.insert(newOrder, key)
			else
				newData[key] = value.index
				table.insert(newOrder, key)
			end
		end
		table.sort(newOrder, function(a,b) return newData[a] < newData[b] end)
		
		InternalInterface.AccountSettings.Posting.DefaultConfig.pricingModelOrder = newOrder
		ResetPricingModelGrid()
	end
	
	function pricingModelBottom.Event:LeftClick()
		local data = pricingModelGrid:GetData()
		local selectedKey = pricingModelGrid:GetSelectedData()
		local newData = {}
		local newOrder = {}
		
		for key, value in pairs(data) do
			if key == selectedKey then
				newData[key] = math.huge
				table.insert(newOrder, key)
			else
				newData[key] = value.index
				table.insert(newOrder, key)
			end
		end
		table.sort(newOrder, function(a,b) return newData[a] < newData[b] end)
		
		InternalInterface.AccountSettings.Posting.DefaultConfig.pricingModelOrder = newOrder
		ResetPricingModelGrid()
	end
	
	function priceMatcherTop.Event:LeftClick()
		local data = priceMatcherGrid:GetData()
		local selectedKey = priceMatcherGrid:GetSelectedData()
		local newData = {}
		local newOrder = {}
		
		for key, value in pairs(data) do
			if key == selectedKey then
				newData[key] = -1
				table.insert(newOrder, key)
			else
				newData[key] = value.index
				table.insert(newOrder, key)
			end
		end
		table.sort(newOrder, function(a,b) return newData[a] < newData[b] end)
		
		InternalInterface.AccountSettings.Posting.DefaultConfig.priceMatcherOrder = newOrder
		ResetPriceMatcherGrid()
	end
	
	function priceMatcherUp.Event:LeftClick()
		local data = priceMatcherGrid:GetData()
		local selectedKey = priceMatcherGrid:GetSelectedData()
		local newData = {}
		local newOrder = {}
		
		for key, value in pairs(data) do
			if key == selectedKey then
				newData[key] = value.index - 1.1
				table.insert(newOrder, key)
			else
				newData[key] = value.index
				table.insert(newOrder, key)
			end
		end
		table.sort(newOrder, function(a,b) return newData[a] < newData[b] end)
		
		InternalInterface.AccountSettings.Posting.DefaultConfig.priceMatcherOrder = newOrder
		ResetPriceMatcherGrid()
	end
	
	function priceMatcherDown.Event:LeftClick()
		local data = priceMatcherGrid:GetData()
		local selectedKey = priceMatcherGrid:GetSelectedData()
		local newData = {}
		local newOrder = {}
		
		for key, value in pairs(data) do
			if key == selectedKey then
				newData[key] = value.index + 1.1
				table.insert(newOrder, key)
			else
				newData[key] = value.index
				table.insert(newOrder, key)
			end
		end
		table.sort(newOrder, function(a,b) return newData[a] < newData[b] end)
		
		InternalInterface.AccountSettings.Posting.DefaultConfig.priceMatcherOrder = newOrder
		ResetPriceMatcherGrid()
	end
	
	function priceMatcherBottom.Event:LeftClick()
		local data = priceMatcherGrid:GetData()
		local selectedKey = priceMatcherGrid:GetSelectedData()
		local newData = {}
		local newOrder = {}
		
		for key, value in pairs(data) do
			if key == selectedKey then
				newData[key] = math.huge
				table.insert(newOrder, key)
			else
				newData[key] = value.index
				table.insert(newOrder, key)
			end
		end
		table.sort(newOrder, function(a,b) return newData[a] < newData[b] end)
		
		InternalInterface.AccountSettings.Posting.DefaultConfig.priceMatcherOrder = newOrder
		ResetPriceMatcherGrid()
	end
	
	function rarityFilterDropdown.Event:SelectionChanged()
		InternalInterface.AccountSettings.Posting.rarityFilter = self:GetSelectedIndex() or 1
	end
	
	table.insert(Event[addonID].PricingModelAdded, { ResetPricingModelGrid, addonID, "ConfigFrame.PricingModelAdded" })
	table.insert(Event[addonID].PriceScorerAdded, { ResetPricingModelGrid, addonID, "ConfigFrame.PriceScorerAdded" })
	table.insert(Event[addonID].PriceMatcherAdded, { ResetPriceMatcherGrid, addonID, "ConfigFrame.PriceMatcherAdded" })

	ResetPricingModelGrid()
	ResetPriceMatcherGrid()
	
	return frame
end

local function AuctionsSettings(parent)
	local frame = UI.CreateFrame("Frame", parent:GetName() .. ".AuctionsSettings", parent)

	local allowLeftCancelCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".allowLeftCancelCheck", frame)
	local allowLeftCancelText = UI.CreateFrame("Text", frame:GetName() .. ".allowLeftCancelText", frame)

	local filterCharacterCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".FilterCharacterCheck", frame)
	local filterCharacterText = UI.CreateFrame("Text", frame:GetName() .. ".FilterCharacterText", frame)
	
	local filterCompetitionText = UI.CreateFrame("Text", frame:GetName() .. ".FilterCompetitionText", frame)
	local filterCompetitionSelector = UI.CreateFrame("BDropdown", frame:GetName() .. ".FilterCompetitionSelector", frame)
	
	local filterBelowText = UI.CreateFrame("Text", frame:GetName() .. ".FilterBelowText", frame)
	local filterBelowSlider = UI.CreateFrame("BSlider", frame:GetName() .. ".FilterBelowSlider", frame)

	local filterScoreTitle = UI.CreateFrame("Text", frame:GetName() .. ".FilterScoreTitle", frame)
	local filterFrame = UI.CreateFrame("Frame", frame:GetName() .. ".FilterFrame", frame)
	
	local filterScoreNilCheck = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScoreNilCheck", filterFrame)
	local filterScoreNilText = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterScoreNilText", filterFrame)
	local filterScore1Check = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore1Check", filterFrame)
	local filterScore1Text = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterScore1Text", filterFrame)
	local filterScore2Check = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore2Check", filterFrame)
	local filterScore2Text = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterScore2Text", filterFrame)
	local filterScore3Check = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore3Check", filterFrame)
	local filterScore3Text = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterScore3Text", filterFrame)
	local filterScore4Check = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore4Check", filterFrame)
	local filterScore4Text = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterScore4Text", filterFrame)
	local filterScore5Check = UI.CreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore5Check", filterFrame)
	local filterScore5Text = UI.CreateFrame("Text", filterFrame:GetName() .. ".FilterScore5Text", filterFrame)
	
	frame:SetVisible(false)

	allowLeftCancelCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	allowLeftCancelCheck:SetChecked(InternalInterface.AccountSettings.Auctions.allowLeftCancel or false)
	
	allowLeftCancelText:SetPoint("CENTERLEFT", allowLeftCancelCheck, "CENTERRIGHT", 5, 0)
	allowLeftCancelText:SetFontSize(14)
	allowLeftCancelText:SetText(L["ConfigPanel/AuctionLeftCancel"])
	
	filterCharacterCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 70)
	filterCharacterCheck:SetChecked(InternalInterface.AccountSettings.Auctions.restrictCharacterFilter or false)
	
	filterCharacterText:SetPoint("CENTERLEFT", filterCharacterCheck, "CENTERRIGHT", 5, 0)
	filterCharacterText:SetFontSize(14)
	filterCharacterText:SetText(L["ConfigPanel/AuctionSellerFilterDefault"])

	filterCompetitionText:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 120)
	filterCompetitionText:SetFontSize(14)
	filterCompetitionText:SetText(L["ConfigPanel/AuctionCompetitionFilterDefault"])
	
	filterBelowText:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 170)
	filterBelowText:SetFontSize(14)
	filterBelowText:SetText(L["ConfigPanel/AuctionBelowFilterDefault"])

	filterScoreTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 220)
	filterScoreTitle:SetFontSize(14)
	filterScoreTitle:SetText(L["ConfigPanel/AuctionScoreFilterDefault"])
	
	local offset = math.max(filterScoreTitle:GetWidth(), math.max(filterCompetitionText:GetWidth(), filterBelowText:GetWidth())) + 10
	
	filterCompetitionSelector:SetPoint("CENTERLEFT", filterCompetitionText, "CENTERRIGHT", offset - filterCompetitionText:GetWidth(), 0)
	filterCompetitionSelector:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 113)
	filterCompetitionSelector:SetValues({
		{ displayName = L["AuctionsPanel/CompetitionName1"], },
		{ displayName = L["AuctionsPanel/CompetitionName2"], },
		{ displayName = L["AuctionsPanel/CompetitionName3"], },
		{ displayName = L["AuctionsPanel/CompetitionName4"], },
		{ displayName = L["AuctionsPanel/CompetitionName5"], },
	})
	filterCompetitionSelector:SetSelectedIndex(InternalInterface.AccountSettings.Auctions.defaultCompetitionFilter or 1)

	filterBelowSlider:SetPoint("CENTERLEFT", filterBelowText, "CENTERRIGHT", offset - filterBelowText:GetWidth(), 0)
	filterBelowSlider:SetPoint("CENTERRIGHT", frame, "TOPRIGHT", 0, 185)
	filterBelowSlider:SetRange(0, 20)
	filterBelowSlider:SetPosition(InternalInterface.AccountSettings.Auctions.defaultBelowFilter or 0)

	filterFrame:SetPoint("CENTERLEFT", filterScoreTitle, "CENTERRIGHT", offset - filterScoreTitle:GetWidth(), 0)
	filterFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 205)
	
	filterScoreNilCheck:SetPoint("CENTERLEFT", filterFrame, 0, 0.5)
	filterScoreNilCheck:SetChecked(InternalInterface.AccountSettings.Auctions.defaultScoreFilter[1] or false)
	filterScore1Check:SetPoint("CENTERLEFT", filterFrame, 1 / 6, 0.5)
	filterScore1Check:SetChecked(InternalInterface.AccountSettings.Auctions.defaultScoreFilter[2] or false)
	filterScore2Check:SetPoint("CENTERLEFT", filterFrame, 2 / 6, 0.5)
	filterScore2Check:SetChecked(InternalInterface.AccountSettings.Auctions.defaultScoreFilter[3] or false)
	filterScore3Check:SetPoint("CENTERLEFT", filterFrame, 3 / 6, 0.5)
	filterScore3Check:SetChecked(InternalInterface.AccountSettings.Auctions.defaultScoreFilter[4] or false)
	filterScore4Check:SetPoint("CENTERLEFT", filterFrame, 4 / 6, 0.5)
	filterScore4Check:SetChecked(InternalInterface.AccountSettings.Auctions.defaultScoreFilter[5] or false)
	filterScore5Check:SetPoint("CENTERLEFT", filterFrame, 5 / 6, 0.5)
	filterScore5Check:SetChecked(InternalInterface.AccountSettings.Auctions.defaultScoreFilter[6] or false)
	
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
		InternalInterface.AccountSettings.Auctions.allowLeftCancel = self:GetChecked()
	end
	
	function filterCharacterCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.restrictCharacterFilter = self:GetChecked()
	end
	
	function filterCompetitionSelector.Event:SelectionChanged()
		InternalInterface.AccountSettings.Auctions.defaultCompetitionFilter = self:GetSelectedIndex()
	end
	
	function filterBelowSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.Auctions.defaultBelowFilter = position
	end

	function filterScoreNilCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.defaultScoreFilter[1] = self:GetChecked()
	end
	
	function filterScore1Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.defaultScoreFilter[2] = self:GetChecked()
	end
	
	function filterScore2Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.defaultScoreFilter[3] = self:GetChecked()
	end
	
	function filterScore3Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.defaultScoreFilter[4] = self:GetChecked()
	end
	
	function filterScore4Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.defaultScoreFilter[5] = self:GetChecked()
	end
	
	function filterScore5Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.defaultScoreFilter[6] = self:GetChecked()
	end
	
	return frame
end

local function PriceScoreSettings(parent)
	local frame = UI.CreateFrame("Frame", parent:GetName() .. ".PriceScoreSettings", parent)
	
	InternalInterface.AccountSettings.PriceScorers.Settings.colorLimits = InternalInterface.AccountSettings.PriceScorers.Settings.colorLimits or { 85, 85, 115, 115 }
	
	local defaultPriceScorerText = UI.CreateFrame("Text", frame:GetName() .. ".DefaultPriceScorerText", frame)
	local defaultPriceScorerDropdown = UI.CreateFrame("BDropdown", frame:GetName() .. ".DefaultPriceScorerDropdown", frame)
	local colorNilSample = UI.CreateFrame("BPanel", frame:GetName() .. ".ColorNilSample", frame)
	local color1Sample = UI.CreateFrame("BPanel", frame:GetName() .. ".Color1Sample", frame)
	local color2Sample = UI.CreateFrame("BPanel", frame:GetName() .. ".Color2Sample", frame)
	local color3Sample = UI.CreateFrame("BPanel", frame:GetName() .. ".Color3Sample", frame)
	local color4Sample = UI.CreateFrame("BPanel", frame:GetName() .. ".Color4Sample", frame)
	local color5Sample = UI.CreateFrame("BPanel", frame:GetName() .. ".Color5Sample", frame)
	local colorNilText = UI.CreateFrame("Text", frame:GetName() .. ".ColorNilText", frame)
	local color1Text = UI.CreateFrame("Text", frame:GetName() .. ".Color1Text", frame)
	local color2Text = UI.CreateFrame("Text", frame:GetName() .. ".Color2Text", frame)
	local color3Text = UI.CreateFrame("Text", frame:GetName() .. ".Color3Text", frame)
	local color4Text = UI.CreateFrame("Text", frame:GetName() .. ".Color4Text", frame)
	local color5Text = UI.CreateFrame("Text", frame:GetName() .. ".Color5Text", frame)
	local color1Limit = UI.CreateFrame("BSlider", frame:GetName() .. ".Color1Limit", frame)
	local color2Limit = UI.CreateFrame("BSlider", frame:GetName() .. ".Color2Limit", frame)
	local color3Limit = UI.CreateFrame("BSlider", frame:GetName() .. ".Color3Limit", frame)
	local color4Limit = UI.CreateFrame("BSlider", frame:GetName() .. ".Color4Limit", frame)
	local samplePanel = UI.CreateFrame("BPanel", frame:GetName() .. ".SamplePanel", frame)
	local color1SamplePanel = UI.CreateFrame("Frame", frame:GetName() .. ".Color1SamplePanel", samplePanel:GetContent())
	local color2SamplePanel = UI.CreateFrame("Frame", frame:GetName() .. ".Color2SamplePanel", samplePanel:GetContent())
	local color3SamplePanel = UI.CreateFrame("Frame", frame:GetName() .. ".Color3SamplePanel", samplePanel:GetContent())
	local color4SamplePanel = UI.CreateFrame("Frame", frame:GetName() .. ".Color4SamplePanel", samplePanel:GetContent())
	local color5SamplePanel = UI.CreateFrame("Frame", frame:GetName() .. ".Color5SamplePanel", samplePanel:GetContent())
	
	local function ResetDefaultPriceScorer()
		local priceScorers = InternalInterface.PricingModelService.GetAllPriceScorers()
		local values = {}
		local defaultIndex = 1
		for priceScorerID, priceScorerData in pairs(priceScorers) do
			table.insert(values, { priceScorerID = priceScorerID, displayName = priceScorerData.displayName })
			if priceScorerID == InternalInterface.AccountSettings.PriceScorers.Settings.default then
				defaultIndex = #values
			end
		end
		defaultPriceScorerDropdown:SetValues(values)
		defaultPriceScorerDropdown:SetSelectedIndex(defaultIndex)
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
		
		InternalInterface.AccountSettings.PriceScorers.Settings.colorLimits = { limit1, limit2, limit3, limit4 }
	end
	
	frame:SetVisible(false)

	defaultPriceScorerText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	defaultPriceScorerText:SetFontSize(14)
	defaultPriceScorerText:SetText(L["ConfigPanel/DefaultPriceScorer"])
	
	defaultPriceScorerDropdown:SetPoint("CENTERLEFT", defaultPriceScorerText, "CENTERRIGHT", 10, 0)
	defaultPriceScorerDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 3)
	
	colorNilSample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 90)
	colorNilSample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 120)
	colorNilSample:GetContent():SetBackgroundColor(unpack(InternalInterface.UI.ScoreColorByIndex(nil)))
	colorNilSample:SetInvertedBorder(true)
	
	color1Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 140)
	color1Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 170)
	color1Sample:GetContent():SetBackgroundColor(unpack(InternalInterface.UI.ScoreColorByIndex(1)))
	color1Sample:SetInvertedBorder(true)
	
	color2Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 190)
	color2Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 220)
	color2Sample:GetContent():SetBackgroundColor(unpack(InternalInterface.UI.ScoreColorByIndex(2)))
	color2Sample:SetInvertedBorder(true)
	
	color3Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 240)
	color3Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 270)
	color3Sample:GetContent():SetBackgroundColor(unpack(InternalInterface.UI.ScoreColorByIndex(3)))
	color3Sample:SetInvertedBorder(true)
	
	color4Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 290)
	color4Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 320)
	color4Sample:GetContent():SetBackgroundColor(unpack(InternalInterface.UI.ScoreColorByIndex(4)))
	color4Sample:SetInvertedBorder(true)
	
	color5Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 340)
	color5Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 370)
	color5Sample:GetContent():SetBackgroundColor(unpack(InternalInterface.UI.ScoreColorByIndex(5)))
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
	color1Limit:SetPosition(InternalInterface.AccountSettings.PriceScorers.Settings.colorLimits[1])
	
	color2Limit:SetPoint("TOPLEFT", color2Sample, "BOTTOMRIGHT", 200, 0)
	color2Limit:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 240)
	color2Limit:SetRange(0, 999)
	color2Limit:SetPosition(InternalInterface.AccountSettings.PriceScorers.Settings.colorLimits[2])
	
	color3Limit:SetPoint("TOPLEFT", color3Sample, "BOTTOMRIGHT", 200, 0)
	color3Limit:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 290)
	color3Limit:SetRange(0, 999)
	color3Limit:SetPosition(InternalInterface.AccountSettings.PriceScorers.Settings.colorLimits[3])
	
	color4Limit:SetPoint("TOPLEFT", color4Sample, "BOTTOMRIGHT", 200, 0)
	color4Limit:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 340)
	color4Limit:SetRange(0, 999)
	color4Limit:SetPosition(InternalInterface.AccountSettings.PriceScorers.Settings.colorLimits[4])
	
	samplePanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 390)
	samplePanel:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 420)
	samplePanel:GetContent():SetBackgroundColor(unpack(InternalInterface.UI.ScoreColorByIndex(nil)))
	
	color1SamplePanel:SetBackgroundColor(unpack(InternalInterface.UI.ScoreColorByIndex(1)))
	color2SamplePanel:SetBackgroundColor(unpack(InternalInterface.UI.ScoreColorByIndex(2)))
	color3SamplePanel:SetBackgroundColor(unpack(InternalInterface.UI.ScoreColorByIndex(3)))
	color4SamplePanel:SetBackgroundColor(unpack(InternalInterface.UI.ScoreColorByIndex(4)))
	color5SamplePanel:SetBackgroundColor(unpack(InternalInterface.UI.ScoreColorByIndex(5)))
	
	function defaultPriceScorerDropdown.Event:SelectionChanged()
		local index, data = self:GetSelectedValue()
		InternalInterface.AccountSettings.PriceScorers.Settings.default = data and data.priceScorerID or "market"
	end

	local propagate = false
	
	function color1Limit.Event:PositionChanged(position)
		if not propagate then
			propagate = true
			color2Limit:SetPosition(math.max(position, color2Limit:GetPosition()))
			color3Limit:SetPosition(math.max(color2Limit:GetPosition(), color3Limit:GetPosition()))
			color4Limit:SetPosition(math.max(color3Limit:GetPosition(), color4Limit:GetPosition()))
			propagate = false
			ResetColorSample()
		end
	end
	
	function color2Limit.Event:PositionChanged(position)
		if not propagate then
			propagate = true
			color1Limit:SetPosition(math.min(color1Limit:GetPosition(), position))
			color3Limit:SetPosition(math.max(position, color3Limit:GetPosition()))
			color4Limit:SetPosition(math.max(color3Limit:GetPosition(), color4Limit:GetPosition()))
			propagate = false
			ResetColorSample()
		end
	end
	
	function color3Limit.Event:PositionChanged(position)
		if not propagate then
			propagate = true
			color2Limit:SetPosition(math.min(color2Limit:GetPosition(), position))
			color1Limit:SetPosition(math.min(color1Limit:GetPosition(), color2Limit:GetPosition()))
			color4Limit:SetPosition(math.max(position, color4Limit:GetPosition()))
			propagate = false
			ResetColorSample()
		end
	end
	
	function color4Limit.Event:PositionChanged(position)
		if not propagate then
			propagate = true
			color3Limit:SetPosition(math.min(color3Limit:GetPosition(), position))
			color2Limit:SetPosition(math.min(color2Limit:GetPosition(), color3Limit:GetPosition()))
			color1Limit:SetPosition(math.min(color1Limit:GetPosition(), color2Limit:GetPosition()))
			propagate = false
			ResetColorSample()
		end
	end
	
	ResetDefaultPriceScorer()
	ResetColorSample()
	
	table.insert(Event[addonID].PriceScorerAdded, { ResetDefaultPriceScorer, addonID, "ConfigFrame.PriceScorerAdded" })
	
	return frame
end

local function LoadConfigScreens(self, configDisplay)
	local pricingModels = InternalInterface.PricingModelService.GetAllPricingModels()
	local pricingModelsChilden = { }
	local count = 1
	for pricingModelId, pricingModelData in pairs(pricingModels) do
		if pricingModelData.configFrameConstructor then
			table.insert(pricingModelsChilden, { title = "\t" .. pricingModelData.displayName, frame = pricingModelData.configFrameConstructor(configDisplay), order = 100 + count })
			count = count + 1
		end
	end
	
	local priceScorers = InternalInterface.PricingModelService.GetAllPriceScorers()
	local priceScorersChildren = {{ title = "\t" .. L["ConfigPanel/subcategoryScoreSettings"], frame = PriceScoreSettings(configDisplay), order = 201 }}
	count = 2
	for priceScorerId, priceScorerData in pairs(priceScorers) do
		if priceScorerData.configFrameConstructor then
			table.insert(priceScorersChildren, { title = "\t" .. priceScorerData.displayName, frame = priceScorerData.configFrameConstructor(configDisplay), order = 200 + count })
			count = count + 1
		end
	end
	
	local priceMatchers = InternalInterface.PricingModelService.GetAllPriceMatchers()
	local priceMatchersChilden = { }
	count = 1
	for priceMatcherId, priceMatcherData in pairs(priceMatchers) do
		if priceMatcherData.configFrameConstructor then
			table.insert(priceMatchersChilden, { title = "\t" .. priceMatcherData.displayName, frame = priceMatcherData.configFrameConstructor(configDisplay), order = 300 + count })
			count = count + 1
		end
	end
	
	table.insert(self.screens, { title = L["ConfigPanel/categoryGeneral"], frame = GeneralSettings(configDisplay), order = 10 })
	table.insert(self.screens, { title = L["ConfigPanel/categoryPosting"], frame = PostingSettings(configDisplay), order = 30 })
	table.insert(self.screens, { title = L["ConfigPanel/categoryAuctions"], frame = AuctionsSettings(configDisplay), order = 40 })
	table.insert(self.screens, { title = L["ConfigPanel/categoryPricingModels"], children = pricingModelsChilden, order = 100 })
	table.insert(self.screens, { title = L["ConfigPanel/categoryPriceScorers"], children = priceScorersChildren, order = 200 })
	table.insert(self.screens, { title = L["ConfigPanel/categoryPriceMatchers"], children = priceMatchersChilden, order = 300 })
end

function InternalInterface.UI.ConfigFrame(name, parent)
	local configFrame = UI.CreateFrame("Frame", name, parent)
	local configSelector = UI.CreateFrame("BDataGrid", name .. ".ConfigSelector", configFrame)
	local configDisplay = UI.CreateFrame("Mask", name .. ".ConfigDisplay", configFrame)
	
	configSelector:SetRowHeight(26)
	configSelector:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 5, 5)
	configSelector:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMLEFT", 295, -5)
	configSelector:AddColumn("Title", 260, "Text", false, "title", { FontSize = 16, Color = { 1, 1, 0.75, 1 } })
	configSelector:AddColumn("Order", 0, "Text", true, "order")
	configSelector:SetSelectedRowBackgroundColor(0, 0, 0, 0.25)

	configDisplay:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 300, 10)
	configDisplay:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -5, -10)
	
	configFrame.screens = {}
	LoadConfigScreens(configFrame, configDisplay)

	function configSelector.Event:SelectionChanged(selectedKey, selectedValue)
		if not selectedKey then return end
		local newFrame = selectedValue.frame or selectedValue.children[1].frame
		if configFrame.shownFrame then
			configFrame.shownFrame:SetVisible(false)
		end
		configFrame.shownFrame = newFrame
		configFrame.shownFrame:SetAllPoints()
		configFrame.shownFrame:SetVisible(true)
	end
	
	local data = {}
	for _, screen in ipairs(configFrame.screens) do
		table.insert(data, screen)
		if screen.children then
			for _, child in ipairs(screen.children) do
				table.insert(data, child)
			end
		end
	end
	configSelector:SetData(data)
	
	function configFrame:Show() end
	
	return configFrame
end