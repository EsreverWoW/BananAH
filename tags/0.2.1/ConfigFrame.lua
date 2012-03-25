local _, InternalInterface = ...
local L = InternalInterface.Localization.L

local function GeneralSettings(parent)
	local frame = UI.CreateFrame("Frame", parent:GetName() .. ".GeneralSettings", parent)
	
	local showMapIconCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".ShowMapIconCheck", frame)
	local showMapIconText = UI.CreateFrame("Text", frame:GetName() .. ".ShowMapIconText", frame)
	local autoOpenCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".AutoOpenCheck", frame)
	local autoOpenText = UI.CreateFrame("Text", frame:GetName() .. ".AutoOpenText", frame)
	
	InternalInterface.Settings.Config = InternalInterface.Settings.Config or {}

	frame:SetVisible(false)
	
	showMapIconCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	showMapIconCheck:SetChecked(InternalInterface.Settings.Config.showMapIcon or false)
	
	showMapIconText:SetPoint("CENTERLEFT", showMapIconCheck, "CENTERRIGHT", 5, 0)
	showMapIconText:SetFontSize(14)
	showMapIconText:SetText(L["ConfigPanel/mapIconShow"])
	
	autoOpenCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 40)
	autoOpenCheck:SetChecked(InternalInterface.Settings.Config.autoOpen or false)
	
	autoOpenText:SetPoint("CENTERLEFT", autoOpenCheck, "CENTERRIGHT", 5, 0)
	autoOpenText:SetFontSize(14)
	autoOpenText:SetText(L["ConfigPanel/autoOpenWindow"])
	
	function showMapIconCheck.Event:CheckboxChange()
		InternalInterface.Settings.Config.showMapIcon = self:GetChecked()
		local parent = self
		local mapIcon = nil
		while parent ~= nil do
			if parent.mapIcon then
				mapIcon = parent.mapIcon
				break
			end
			parent = parent.GetParent and parent:GetParent() or nil
		end
		if mapIcon then
			mapIcon:SetVisible(self:GetChecked())
		end
	end
	
	function autoOpenCheck.Event:CheckboxChange()
		InternalInterface.Settings.Config.autoOpen = self:GetChecked()
	end
	
	return frame
end

local function PostingSettings(parent)
	local frame = UI.CreateFrame("Frame", parent:GetName() .. ".PostingSettings", parent)

	local startQueuePausedCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".StartQueuePausedCheck", frame)
	local startQueuePausedText = UI.CreateFrame("Text", frame:GetName() .. ".StartQueuePausedText", frame)
	local defaultPricingModelText = UI.CreateFrame("Text", frame:GetName() .. ".DefaultPricingModelText", frame)
	local defaultPricingModelSelector = UI.CreateFrame("BDropdown", frame:GetName() .. ".DefaultPricingModelSelector", frame)
	local defaultPriceMatchingCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".DefaultPriceMatchingCheck", frame)
	local defaultPriceMatchingText = UI.CreateFrame("Text", frame:GetName() .. ".DefaultPriceMatchingText", frame)
	local defaultBindPricesCheck = UI.CreateFrame("RiftCheckbox", frame:GetName() .. ".DefaultBindPricesCheck", frame)
	local defaultBindPricesText = UI.CreateFrame("Text", frame:GetName() .. ".DefaultBindPricesText", frame)
	local defaultDurationText = UI.CreateFrame("Text", frame:GetName() .. ".DefaultDurationText", frame)
	local defaultDurationSlider = UI.CreateFrame("RiftSlider", frame:GetName() .. ".DefaultDurationSlider", frame)
	local defaultDurationTime = UI.CreateFrame("Text", frame:GetName() .. ".DefaultDurationTime", frame)

	InternalInterface.Settings.Config = InternalInterface.Settings.Config or {}

	frame:SetVisible(false)

	startQueuePausedCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	startQueuePausedCheck:SetChecked(InternalInterface.Settings.Config.defaultPausedPostingQueue or false)
	
	startQueuePausedText:SetPoint("CENTERLEFT", startQueuePausedCheck, "CENTERRIGHT", 5, 0)
	startQueuePausedText:SetFontSize(14)
	startQueuePausedText:SetText(L["ConfigPanel/defaultPausedPostingQueue"])
	
	defaultPricingModelText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 70)
	defaultPricingModelText:SetFontSize(14)
	defaultPricingModelText:SetText(L["ConfigPanel/defaultPostingPricingModel"])
	
	defaultPricingModelSelector:SetPoint("CENTERLEFT", defaultPricingModelText, "CENTERRIGHT", 10, 0)
	defaultPricingModelSelector:SetPoint("CENTERRIGHT", defaultPricingModelText, "CENTERRIGHT", 270, 0)
	defaultPricingModelSelector:SetHeight(36)
	local pricingModels = BananAH.GetPricingModels()
	local names = {}
	local ids = {}
	local defaultIndex = nil
	local fallbackIndex = nil
	for id, data in pairs(pricingModels) do
		table.insert(ids, id)
		table.insert(names, data.displayName)
		if id == "fallback" then
			fallbackIndex = #ids
		end		
		if id == InternalInterface.Settings.Config.defaultPricingModel then
			defaultIndex = #ids
		end
	end
	defaultIndex = defaultIndex or fallbackIndex
	defaultPricingModelSelector:SetValues(names)
	defaultPricingModelSelector:SetSelectedIndex(defaultIndex)
	
	defaultPriceMatchingCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 110)
	defaultPriceMatchingCheck:SetChecked(InternalInterface.Settings.Config.defaultPriceMatching or false)
	
	defaultPriceMatchingText:SetPoint("CENTERLEFT", defaultPriceMatchingCheck, "CENTERRIGHT", 5, 0)
	defaultPriceMatchingText:SetFontSize(14)
	defaultPriceMatchingText:SetText(L["ConfigPanel/defaultPriceMatching"])
	
	defaultBindPricesCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 140)
	defaultBindPricesCheck:SetChecked(InternalInterface.Settings.Config.defaultBindPrices or false)
	
	defaultBindPricesText:SetPoint("CENTERLEFT", defaultBindPricesCheck, "CENTERRIGHT", 5, 0)
	defaultBindPricesText:SetFontSize(14)
	defaultBindPricesText:SetText(L["ConfigPanel/defaultBindPrices"])
	
	defaultDurationText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 170)
	defaultDurationText:SetFontSize(14)
	defaultDurationText:SetText(L["ConfigPanel/defaultDuration"])

	defaultDurationSlider:SetPoint("CENTERLEFT", defaultDurationText, "CENTERRIGHT", 40, 5)
	defaultDurationSlider:SetPoint("CENTERRIGHT", defaultDurationText, "CENTERRIGHT", 190, 5)
	defaultDurationSlider:SetRange(1, 3)

	defaultDurationTime:SetPoint("CENTERLEFT", defaultDurationSlider, "CENTERRIGHT", 15, -5)
	defaultDurationTime:SetFontSize(14)
	defaultDurationTime:SetText(string.format(L["PostingPanel/labelDurationFormat"], 48))

	function startQueuePausedCheck.Event:CheckboxChange()
		InternalInterface.Settings.Config.defaultPausedPostingQueue = self:GetChecked()
	end
	
	function defaultPricingModelSelector.Event:SelectionChanged(index)
		InternalInterface.Settings.Config.defaultPricingModel = ids[index] or nil
		BananAH.RegisterPricingModel("")
		BananAH.UnregisterPricingModel("")
	end

	function defaultPriceMatchingCheck.Event:CheckboxChange()
		InternalInterface.Settings.Config.defaultPriceMatching = self:GetChecked()
	end
	
	function defaultBindPricesCheck.Event:CheckboxChange()
		InternalInterface.Settings.Config.defaultBindPrices = self:GetChecked()
	end
	
	function defaultDurationSlider.Event:SliderChange()
		local position = self:GetPosition()
		defaultDurationTime:SetText(string.format(L["PostingPanel/labelDurationFormat"], 6 * 2 ^ position))
		InternalInterface.Settings.Config.defaultDuration = position
	end
	
	defaultDurationSlider:SetPosition(InternalInterface.Settings.Config.defaultDuration or 3)
	
	return frame
end

local function PriceMatchers(parent)
	local frame = UI.CreateFrame("Frame", parent:GetName() .. ".PriceMatchers", parent)

	local selfMatcherText = UI.CreateFrame("Text", frame:GetName() .. ".SelfMatcherText", frame)
	local selfMatcherSlider = UI.CreateFrame("BSlider", frame:GetName() .. ".SelfMatcherSlider", frame)
	local competitionUndercutterText = UI.CreateFrame("Text", frame:GetName() .. ".CompetitionUndercutterText", frame)
	local competitionUndercutterSlider = UI.CreateFrame("BSlider", frame:GetName() .. ".CompetitionUndercutterSlider", frame)

	InternalInterface.Settings.Config = InternalInterface.Settings.Config or {}

	frame:SetVisible(false)

	selfMatcherText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	selfMatcherText:SetFontSize(14)
	selfMatcherText:SetText(L["ConfigPanel/priceMatcherSelfRange"])
	
	competitionUndercutterText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 50)
	competitionUndercutterText:SetFontSize(14)
	competitionUndercutterText:SetText(L["ConfigPanel/priceMatcherUndercutRange"])

	local maxWidth = math.max(selfMatcherText:GetWidth(), competitionUndercutterText:GetWidth())
	
	selfMatcherSlider:SetPoint("CENTERLEFT", selfMatcherText, "CENTERRIGHT", 20 + maxWidth - selfMatcherText:GetWidth(), 8)	
	selfMatcherSlider:SetWidth(300)
	selfMatcherSlider:SetRange(0, 100)
	selfMatcherSlider:SetPosition(InternalInterface.Settings.Config.selfMatcherRange or 25)

	competitionUndercutterSlider:SetPoint("CENTERLEFT", competitionUndercutterText, "CENTERRIGHT", 20 + maxWidth - competitionUndercutterText:GetWidth(), 8)	
	competitionUndercutterSlider:SetWidth(300)
	competitionUndercutterSlider:SetRange(0, 100)
	competitionUndercutterSlider:SetPosition(InternalInterface.Settings.Config.competitionUndercutterRange or 25)
	
	function selfMatcherSlider.Event:PositionChanged(position)
		InternalInterface.Settings.Config.selfMatcherRange = position
	end
	
	function competitionUndercutterSlider.Event:PositionChanged(position)
		InternalInterface.Settings.Config.competitionUndercutterRange = position
	end
	
	return frame
end

local function LoadConfigScreens(self)
	local postingChildren =
	{
		{ title = "\t" .. L["ConfigPanel/subcategoryPostingSettings"], frame = PostingSettings(self.configDisplay), order = 21 },
		{ title = "\t" .. L["ConfigPanel/subcategoryPostingPriceMatchers"], frame = PriceMatchers(self.configDisplay), order = 22 },
	}
	
	local pricingModelsChilden = { }
	local count = 1
	for pricingModelId, pricingModelData in pairs(BananAH.GetPricingModels()) do
		if pricingModelData.configFrame then
			table.insert(pricingModelsChilden, { title = "\t" .. pricingModelData.displayName, frame = pricingModelData.configFrame(self.configDisplay), order = 30 + count })
			count = count + 1
		end
	end
	
	table.insert(self.screens, { title = L["ConfigPanel/categoryGeneral"], frame = GeneralSettings(self.configDisplay), order = 10 })
	table.insert(self.screens, { title = L["ConfigPanel/categoryPosting"], children = postingChildren, order = 20 })
	table.insert(self.screens, { title = L["ConfigPanel/categoryPricingModels"], children = pricingModelsChilden, order = 30 })
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
	configFrame.configSelector = configSelector

	configDisplay:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 300, 10)
	configDisplay:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -5, -10)
	configFrame.configDisplay = configDisplay
	
	configFrame.screens = {}
	LoadConfigScreens(configFrame)

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