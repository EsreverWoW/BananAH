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
	autoCloseText:SetText("Close the addon window when the native Auction House window is closed") -- LOCALIZE
	
	disableMonitorCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 130)
	disableMonitorCheck:SetChecked(InternalInterface.AccountSettings.General.disableBackgroundScanner or false)
	
	disableMonitorText:SetPoint("CENTERLEFT", disableMonitorCheck, "CENTERRIGHT", 5, 0)
	disableMonitorText:SetFontSize(14)
	disableMonitorText:SetText("Disable background scanner at start") -- LOCALIZE
	
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
	
	frame:SetVisible(false)

	startQueuePausedCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	startQueuePausedCheck:SetChecked(InternalInterface.AccountSettings.Posting.startPostingQueuePaused or false)
	
	startQueuePausedText:SetPoint("CENTERLEFT", startQueuePausedCheck, "CENTERRIGHT", 5, 0)
	startQueuePausedText:SetFontSize(14)
	startQueuePausedText:SetText(L["ConfigPanel/defaultPausedPostingQueue"])
	
	defaultPriceMatchingCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 75)
	defaultPriceMatchingCheck:SetChecked(InternalInterface.AccountSettings.Posting.DefaultConfig.usePriceMatching or false)
	
	defaultPriceMatchingText:SetPoint("CENTERLEFT", defaultPriceMatchingCheck, "CENTERRIGHT", 5, 0)
	defaultPriceMatchingText:SetFontSize(14)
	defaultPriceMatchingText:SetText(L["ConfigPanel/defaultPriceMatching"]) -- RELOCALIZE
	
	defaultBindPricesCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 115)
	defaultBindPricesCheck:SetChecked(InternalInterface.AccountSettings.Posting.DefaultConfig.bindPrices or false)
	
	defaultBindPricesText:SetPoint("CENTERLEFT", defaultBindPricesCheck, "CENTERRIGHT", 5, 0)
	defaultBindPricesText:SetFontSize(14)
	defaultBindPricesText:SetText(L["ConfigPanel/defaultBindPrices"]) -- RELOCALIZE
	
	pricingModelGrid:SetPoint("TOPLEFT", frame, "TOPCENTER", 10, 95)
	pricingModelGrid:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -30, 275)
	pricingModelGrid:SetPadding(1, 1, 1, 1)
	pricingModelGrid:SetRowHeight(20)
	pricingModelGrid:SetRowMargin(0)
	pricingModelGrid:SetUnselectedRowBackgroundColor(0.2, 0.2, 0.4, 0.25)
	pricingModelGrid:SetSelectedRowBackgroundColor(0.6, 0.6, 0.8, 0.25)
	pricingModelGrid:AddColumn("", pricingModelGrid:GetWidth(), "Text", false, "displayName", { Alignment = "left", Formatter = "none" })
	pricingModelGrid:AddColumn("", 0, "Text", true, "index")
	
	pricingModelTitle:SetPoint("BOTTOMCENTER", pricingModelGrid, "TOPCENTER", 0, -5)
	pricingModelTitle:SetFontSize(13)
	pricingModelTitle:SetText("Default pricing model order") -- LOCALIZE
	
	pricingModelUp:SetPoint("BOTTOMLEFT", pricingModelGrid, "CENTERRIGHT", 5, -10)
	pricingModelUp:SetTexture(addonID, "Textures/MoveUp.png")
	
	pricingModelDown:SetPoint("TOPLEFT", pricingModelGrid, "CENTERRIGHT", 5, 10)
	pricingModelDown:SetTexture(addonID, "Textures/MoveDown.png")
	
	pricingModelTop:SetPoint("BOTTOMCENTER", pricingModelUp, "TOPCENTER", 0, -20)
	pricingModelTop:SetTexture(addonID, "Textures/MoveTop.png")
	
	pricingModelBottom:SetPoint("TOPCENTER", pricingModelDown, "BOTTOMCENTER", 0, 20)
	pricingModelBottom:SetTexture(addonID, "Textures/MoveBottom.png")
	
	defaultDurationText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 235)
	defaultDurationText:SetFontSize(14)
	defaultDurationText:SetText(L["ConfigPanel/defaultDuration"])

	defaultDurationTime:SetPoint("TOPRIGHT", frame, "TOPCENTER", -10, 235)
	defaultDurationTime:SetPoint("TOPLEFT", frame, "TOPCENTER", -100, 235)
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
	
	ResetPricingModelGrid()
	-- TODO Capture new pricing models & price scorers
	-- TODO Add rarity filter
	-- TODO Add price matcher order
	
	return frame
end

-- local function PriceMatchers(parent)
	-- local frame = UI.CreateFrame("Frame", parent:GetName() .. ".PriceMatchers", parent)

	-- local selfMatcherText = UI.CreateFrame("Text", frame:GetName() .. ".SelfMatcherText", frame)
	-- local selfMatcherSlider = UI.CreateFrame("BSlider", frame:GetName() .. ".SelfMatcherSlider", frame)
	-- local competitionUndercutterText = UI.CreateFrame("Text", frame:GetName() .. ".CompetitionUndercutterText", frame)
	-- local competitionUndercutterSlider = UI.CreateFrame("BSlider", frame:GetName() .. ".CompetitionUndercutterSlider", frame)

	-- InternalInterface.Settings.Config = InternalInterface.Settings.Config or {}

	-- frame:SetVisible(false)

	-- selfMatcherText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	-- selfMatcherText:SetFontSize(14)
	-- selfMatcherText:SetText(L["ConfigPanel/priceMatcherSelfRange"])
	
	-- competitionUndercutterText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 50)
	-- competitionUndercutterText:SetFontSize(14)
	-- competitionUndercutterText:SetText(L["ConfigPanel/priceMatcherUndercutRange"])

	-- local maxWidth = math.max(selfMatcherText:GetWidth(), competitionUndercutterText:GetWidth())
	
	-- selfMatcherSlider:SetPoint("CENTERLEFT", selfMatcherText, "CENTERRIGHT", 20 + maxWidth - selfMatcherText:GetWidth(), 8)	
	-- selfMatcherSlider:SetWidth(300)
	-- selfMatcherSlider:SetRange(0, 100)
	-- selfMatcherSlider:SetPosition(InternalInterface.Settings.Config.selfMatcherRange or 25)

	-- competitionUndercutterSlider:SetPoint("CENTERLEFT", competitionUndercutterText, "CENTERRIGHT", 20 + maxWidth - competitionUndercutterText:GetWidth(), 8)	
	-- competitionUndercutterSlider:SetWidth(300)
	-- competitionUndercutterSlider:SetRange(0, 100)
	-- competitionUndercutterSlider:SetPosition(InternalInterface.Settings.Config.competitionUndercutterRange or 25)
	
	-- function selfMatcherSlider.Event:PositionChanged(position)
		-- InternalInterface.Settings.Config.selfMatcherRange = position
	-- end
	
	-- function competitionUndercutterSlider.Event:PositionChanged(position)
		-- InternalInterface.Settings.Config.competitionUndercutterRange = position
	-- end
	
	-- return frame
-- end

local function LoadConfigScreens(self, configDisplay)
	local postingChildren =
	{
		{ title = "\t" .. L["ConfigPanel/subcategoryPostingSettings"], frame = PostingSettings(configDisplay), order = 21 },
		-- { title = "\t" .. L["ConfigPanel/subcategoryPostingPriceMatchers"], frame = PriceMatchers(configDisplay), order = 22 },
	}
	
	-- local pricingModelsChilden = { }
	-- local count = 1
	-- for pricingModelId, pricingModelData in pairs(BananAH.GetPricingModels()) do
		-- if pricingModelData.configFrame then
			-- table.insert(pricingModelsChilden, { title = "\t" .. pricingModelData.displayName, frame = pricingModelData.configFrame(configDisplay), order = 30 + count })
			-- count = count + 1
		-- end
	-- end
	
	table.insert(self.screens, { title = L["ConfigPanel/categoryGeneral"], frame = GeneralSettings(configDisplay), order = 10 })
	table.insert(self.screens, { title = L["ConfigPanel/categoryPosting"], children = postingChildren, order = 20 })
	-- table.insert(self.screens, { title = L["ConfigPanel/categoryPricingModels"], children = pricingModelsChilden, order = 30 })
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