local _, InternalInterface = ...

local GetDateString = InternalInterface.Utility.GetDateString
local L = InternalInterface.Localization.L

-- Private
local function RepositionAuctionList(bAuctionSelector)
	bAuctionSelector.auctionListFrame:SetPoint("TOPLEFT", bAuctionSelector.maskFrame, "TOPLEFT", 0, -bAuctionSelector.offset)
	bAuctionSelector.auctionListFrame:SetPoint("TOPRIGHT", bAuctionSelector.maskFrame, "TOPRIGHT", 0, -bAuctionSelector.offset)
end

local function RepositionScrollbar(bAuctionSelector)
	if bAuctionSelector.maskFrame:GetHeight() < 0 then return end
	local maxOffset = math.max(0, bAuctionSelector.auctionListFrame:GetHeight() - bAuctionSelector.maskFrame:GetHeight())
	if maxOffset <= 0 then
		bAuctionSelector.offset = 0
		bAuctionSelector.scrollBar:SetEnabled(false)
	else
		if bAuctionSelector.offset > maxOffset then
			bAuctionSelector.offset = maxOffset
		end
		bAuctionSelector.scrollBar:SetEnabled(true)
		bAuctionSelector.scrollBar:SetRange(0, maxOffset)
		bAuctionSelector.scrollBar:SetPosition(bAuctionSelector.offset)
		bAuctionSelector.scrollBar:SetThickness(bAuctionSelector.maskFrame:GetHeight() / bAuctionSelector.auctionListFrame:GetHeight() * maxOffset)
	end
	RepositionAuctionList(bAuctionSelector)
end



local function SetSelectedDesign(auctionFrame, selected)
	if auctionFrame.auctionID and BananAH.GetAuctionCached(auctionFrame.auctionID) then
		if selected then
			auctionFrame:SetBackgroundColor(0, 0.2, 0.2, 1) 
		else
			auctionFrame:SetBackgroundColor(0, 0.1, 0.1, 1) 
		end
	else
		if selected then
			auctionFrame:SetBackgroundColor(0.2, 0, 0, 1) 
		else
			auctionFrame:SetBackgroundColor(0.1, 0, 0, 1) 
		end
	end
end

local function RepaintSelected(bAuctionSelector)
	bAuctionSelector.auctionFrameList = bAuctionSelector.auctionFrameList or {}
	for index, auctionFrame in ipairs(bAuctionSelector.auctionFrameList) do
		SetSelectedDesign(auctionFrame, index == bAuctionSelector.selectedIndex)
	end
end

local function SelectAuctionFrameByIndex(bAuctionSelector, index)
	if index > 0 and index <= #bAuctionSelector.auctionFrameList and bAuctionSelector.auctionFrameList[index]:GetVisible() then
		bAuctionSelector.selectedIndex = index
	else
		bAuctionSelector.selectedIndex = 0
	end
	
	RepaintSelected(bAuctionSelector)
	
	if bAuctionSelector.Event.AuctionSelected then
		if bAuctionSelector.selectedIndex > 0 then
			bAuctionSelector.Event.AuctionSelected(bAuctionSelector, bAuctionSelector.auctionFrameList[index].auctionID, bAuctionSelector.auctionFrameList[index].auctionData)
		else
			bAuctionSelector.Event.AuctionSelected(bAuctionSelector, nil, nil)
		end
	end
end

local function SetAuctionFrame(bAuctionSelector, index, auctionID, auctionData)
	bAuctionSelector.auctionFrameList = bAuctionSelector.auctionFrameList or {}
	local auctionFrame = bAuctionSelector.auctionFrameList[index]
	
	if not auctionFrame then
		auctionFrame = UI.CreateFrame("Frame", bAuctionSelector:GetName() .. ".AuctionFrame." .. index, bAuctionSelector.auctionListFrame)
		auctionFrame:SetPoint("TOPLEFT", bAuctionSelector.auctionListFrame, "TOPLEFT", 0, (index - 1) * 20)
		auctionFrame:SetPoint("BOTTOMRIGHT", bAuctionSelector.auctionListFrame, "TOPRIGHT", 0, index * 20)
		
		if bAuctionSelector.labels then
			auctionFrame.labels = auctionFrame.labels or {}
			for _, column in ipairs(bAuctionSelector.labels) do
				local labelData = column.labelData
				local label = nil
				if labelData.renderer == "Money" then
					label = UI.CreateFrame("BMoneyDisplay", auctionFrame:GetName() .. ".Labels." .. labelData.name, auctionFrame)
				else
					label = UI.CreateFrame("Text", auctionFrame:GetName() .. ".Labels." .. labelData.name, auctionFrame)
				end
				label.labelData = labelData
				table.insert(auctionFrame.labels, label)
			end
		end

		auctionFrame.index = index
		
		function auctionFrame.Event:LeftClick()
			if self.auctionID then
				local auctionSelector = self:GetParent():GetParent():GetParent():GetParent():GetParent():GetParent() -- AuctionFrame -> AuctionListFrame -> MaskFrame -> InnerPanelContent -> InnerPanel -> AuctionSelectorContent -> AuctionSelector
				SelectAuctionFrameByIndex(auctionSelector, self.index)
			end
		end
		
		table.insert(bAuctionSelector.auctionFrameList, auctionFrame)
	end
	
	auctionFrame.auctionID = auctionID
	auctionFrame.auctionData = auctionData
	if auctionID and auctionData then
		local filledSize = 0
		for _, label in ipairs(auctionFrame.labels) do
			local labelData = label.labelData
			label:ClearAll()
			if labelData.renderer == "Text" then
				local text = ""
				local value = auctionData[labelData.binding]
				
				if labelData.extra.formatter == "date" then
					text = GetDateString(value)
				else
					text = tostring(value)
				end
				label:SetText(text)
				
				local offset = 0
				if labelData.extra.alignment == "center" then
					offset = (labelData.size - label:GetWidth()) / 2
				elseif labelData.extra.alignment == "right" then
					offset = labelData.size - label:GetWidth()
				end
				
				label:SetPoint("TOPLEFT", auctionFrame, "TOPLEFT", filledSize + offset, 0)
				label:SetPoint("BOTTOMLEFT", auctionFrame, "BOTTOMLEFT", filledSize + offset, 0)
			elseif labelData.renderer == "Money" then
				label:SetPoint("TOPLEFT", auctionFrame, "TOPLEFT", filledSize, 0)
				label:SetPoint("BOTTOMLEFT", auctionFrame, "BOTTOMLEFT", filledSize, 0)
				label:SetValue(auctionData[labelData.binding])
				label:SetWidth(labelData.size)
			end
			filledSize = filledSize + labelData.size
		end
		auctionFrame:SetVisible(true)
	else
		auctionFrame:SetVisible(false)
	end
	
	return auctionFrame
end



local function SetOrderingDesign(label, ordering)
	if label.shadow then
		if ordering == "ascending" then
			label.shadow:SetFontColor(0.25, 0.25, 0, 0.25)
		elseif ordering == "descending" then
			label.shadow:SetFontColor(0.25, 0.25, 0, 0.25)
		else
			label.shadow:SetFontColor(0, 0, 0, 0.25)
		end
	end
end

local function ApplyOrder(bAuctionSelector)
	for _, label in ipairs(bAuctionSelector.labels) do
		if bAuctionSelector.orderCriteria == label.labelData.binding then
			SetOrderingDesign(label, bAuctionSelector.orderOrdering)
		else
			SetOrderingDesign(label, nil)
		end
	end
	
	bAuctionSelector:SetAuctions(bAuctionSelector:GetAuctions())
end

local function SetOrderCriteria(bAuctionSelector, criteria)
	if bAuctionSelector.orderCriteria == criteria then
		if bAuctionSelector.orderOrdering == "ascending" then
			bAuctionSelector.orderOrdering = "descending"
		else
			bAuctionSelector.orderOrdering = "ascending"
		end
	else
		bAuctionSelector.orderCriteria = criteria
		bAuctionSelector.orderOrdering = "ascending"
	end
	ApplyOrder(bAuctionSelector)
end

local function MouseIn(self)
	self:SetFontColor(0.5, 0.5, 0.5, 1)
end

local function MouseOut(self)
	self:SetFontColor(1, 1, 1, 1)
end

local function LeftClick(self)
	local auctionSelector = self:GetParent():GetParent() -- Label -> AuctionSelectorContent -> AuctionSelector
	SetOrderCriteria(auctionSelector, self.labelData.binding)
end

local function CreateShadow(label)
	label.shadow = label.shadow or UI.CreateFrame("Text", label:GetName() .. ".Shadow", label:GetParent())
	label.shadow:SetText(label:GetText())
	label.shadow:SetFontSize(label:GetFontSize())
	label.shadow:SetFontColor(0, 0, 0, 0.25)
	label.shadow:SetPoint("CENTER", label, "CENTER", 2, 2)
	label.shadow:SetLayer(label:GetLayer() - 1)
end

local function CreateLabel(bAuctionSelector, labelData, offset)
	local label = UI.CreateFrame("Text", bAuctionSelector:GetName() .. ".Labels." .. labelData.name, bAuctionSelector:GetContent()) -- FIXME Code a proper Label Manager
	label:SetText(labelData.title)
	label:SetFontSize(label:GetFontSize() + 1)
	label:SetPoint("TOPLEFT", bAuctionSelector:GetContent(), "TOPLEFT", 6 + offset + (labelData.size - 20 - label:GetWidth()) / 2, 2)
	label:SetPoint("BOTTOMLEFT", bAuctionSelector:GetContent(), "TOPLEFT", 6 + offset + (labelData.size - 20  - label:GetWidth()) / 2, 22)
	label.labelData = labelData
	CreateShadow(label)
	label.Event.MouseIn = MouseIn
	label.Event.MouseOut = MouseOut
	label.Event.LeftClick = LeftClick
	bAuctionSelector.labels = bAuctionSelector.labels or {}
	table.insert(bAuctionSelector.labels, label)
end

local function SetLabels(bAuctionSelector, labels)
	local filledSize = 0
	for _, labelData in ipairs(labels) do
		CreateLabel(bAuctionSelector, labelData, filledSize)
		filledSize = filledSize + labelData.size
	end
end



-- Public
local function GetScrollInterval(self)
	self.scrollInterval = self.scrollInterval or 30
	return self.scrollInterval
end

local function SetScrollInterval(self, val)
	self.scrollInterval = math.max(0, val)
	return self.scrollInterval
end

local function GetSelectedAuction(self)
	if not self.selectedIndex or not self.auctionFrameList or self.selectedIndex <= 0 or self.selectedIndex > #self.auctionFrameList then return end
	local auctionFrame = self.auctionFrameList[self.selectedIndex]
	return auctionFrame.auctionID, auctionFrame.auctionData
end

local function GetAuctions(self)
	self.auctions = self.auctions or {}
	self.lastUpdate = self.lastUpdate or nil
	return self.auctions, self.lastUpdate
end

local function SetAuctions(self, auctions, lastUpdate)
	local orderedAuctionTable = {}
	for auctionID, _ in pairs(auctions) do
		auctions[auctionID].bidUnitPrice = math.ceil((auctions[auctionID].bidPrice or 0) / (auctions[auctionID].stack or 1))
		auctions[auctionID].buyoutUnitPrice = math.ceil((auctions[auctionID].buyoutPrice or 0) / (auctions[auctionID].stack or 1))	
		table.insert(orderedAuctionTable, auctionID)
	end
	local orderCriteria = self.orderCriteria
	local orderOrdering = self.orderOrdering
	if orderCriteria then
		if orderOrdering == "descending" then 
			table.sort(orderedAuctionTable, function(a, b) return (auctions[b][orderCriteria] or 0) < (auctions[a][orderCriteria] or 0) end)
		else
			table.sort(orderedAuctionTable, function(a, b) return (auctions[a][orderCriteria] or 0) < (auctions[b][orderCriteria] or 0) end)
		end
	end
	
	local lastIDSelected = self:GetSelectedAuction()
	
	local totalHeight = 0
	local newSelectedIndex = 0
	for index, auctionID in ipairs(orderedAuctionTable) do
		totalHeight = totalHeight + SetAuctionFrame(self, index, auctionID, auctions[auctionID]):GetHeight()
		if lastIDSelected and self.auctionFrameList[index].auctionID == lastIDSelected then
			newSelectedIndex = index
		end
	end
	self.auctionListFrame:SetHeight(totalHeight)
	
	if self.auctionFrameList then
		for index = #orderedAuctionTable + 1, #self.auctionFrameList do
			SetAuctionFrame(self, index)
		end
	end
	
	if newSelectedIndex <= 0 then
		newSelectedIndex = self.selectedIndex
	end
	
	if newSelectedIndex <= 0 and #orderedAuctionTable > 0 then
		newSelectedIndex = 1
	elseif newSelectedIndex > #orderedAuctionTable then
		newSelectedIndex = #orderedAuctionTable
	end
	SelectAuctionFrameByIndex(self, newSelectedIndex)
	
	RepaintSelected(self)
	
	local refreshText = L["lastUpdateMessage"]
	if (lastUpdate or 0) <= 0 then
		refreshText = refreshText .. L["lastUpdateDateFallback"]
		self.lastUpdate = nil
	else
		refreshText = refreshText .. os.date(L["lastUpdateDateFormat"], lastUpdate)
		self.lastUpdate = lastUpdate
	end
	self.auctions = auctions
	self.refreshText:SetText(refreshText)
end

function InternalInterface.UI.AuctionSelector(name, parent)
	local bAuctionSelector = UI.CreateFrame("BPanel", name, parent)
	function bAuctionSelector.Event:Size()
		RepositionScrollbar(self)
	end
	SetLabels(bAuctionSelector,
	{
		{ name = "sellerLabel",          title = L["columnSeller"],      size = 100, binding = "sellerName",      renderer = "Text", extra = { alignment = "left",   formatter = "none" } },
		{ name = "stackLabel",           title = L["columnStack"],       size = 70,  binding = "stack",           renderer = "Text", extra = { alignment = "center", formatter = "none" } },
		{ name = "bidPriceLabel",        title = L["columnBid"],         size = 120, binding = "bidPrice",        renderer = "Money" },
		{ name = "buyoutPriceLabel",     title = L["columnBuy"],         size = 120, binding = "buyoutPrice",     renderer = "Money" },
		{ name = "bidUnitPriceLabel",    title = L["columnBidPerUnit"],  size = 120, binding = "bidUnitPrice",    renderer = "Money" },
		{ name = "buyoutUnitPriceLabel", title = L["columnBuyPerUnit"],  size = 120, binding = "buyoutUnitPrice", renderer = "Money" },
		{ name = "minExpireLabel",       title = L["columnMinExpire"],   size = 120, binding = "minExpireTime",   renderer = "Text", extra = { alignment = "right",  formatter = "date" } },
		{ name = "maxExpireLabel",       title = L["columnMaxExpire"],   size = 120, binding = "maxExpireTime",   renderer = "Text", extra = { alignment = "right",  formatter = "date" } },
	})
	
	local scrollBar = UI.CreateFrame("RiftScrollbar", bAuctionSelector:GetName() .. ".ScrollBar", bAuctionSelector:GetContent())
	scrollBar:SetPoint("TOPLEFT", bAuctionSelector:GetContent(), "TOPRIGHT", -18, 22)
	scrollBar:SetPoint("BOTTOMRIGHT", bAuctionSelector:GetContent(), "BOTTOMRIGHT", -2, -35)
	function scrollBar.Event:ScrollbarChange()
		local auctionSelector = self:GetParent():GetParent() -- Scrollbar -> AuctionSelectorContent -> AuctionSelector
		auctionSelector.offset = self:GetPosition()
		RepositionAuctionList(auctionSelector)
	end		
	bAuctionSelector.scrollBar = scrollBar
	
	local innerPanel = UI.CreateFrame("BPanel", bAuctionSelector:GetName() .. ".InnerPanel", bAuctionSelector:GetContent())
	innerPanel:SetPoint("TOPLEFT", bAuctionSelector:GetContent(), "TOPLEFT", 2, 22)
	innerPanel:SetPoint("BOTTOMRIGHT", bAuctionSelector:GetContent(), "BOTTOMRIGHT", -20, -35)
	innerPanel:SetInvertedBorder(true)
	bAuctionSelector.innerPanel = innerPanel

	local maskFrame = UI.CreateFrame("Mask", bAuctionSelector:GetName() .. ".MaskFrame", innerPanel:GetContent())
	maskFrame:SetAllPoints()	
	maskFrame:SetBackgroundColor(0, 0.1, 0.1, 1)
	function maskFrame.Event:WheelForward()
		local auctionSelector = self:GetParent():GetParent():GetParent():GetParent() -- MaskFrame -> InnerPanelContent -> InnerPanel -> AuctionSelectorContent -> AuctionSelector
		local auctionListFrame = auctionSelector.auctionListFrame
		if not auctionListFrame or auctionListFrame:GetHeight() <= self:GetHeight() then return end
		local minOffset, maxOffset = auctionSelector.scrollBar:GetRange()
		auctionSelector.offset = math.max(minOffset, auctionSelector.offset - auctionSelector:GetScrollInterval())
		RepositionScrollbar(auctionSelector)
	end
	function maskFrame.Event:WheelBack()
		local auctionSelector = self:GetParent():GetParent():GetParent():GetParent() -- MaskFrame -> InnerPanelContent -> InnerPanel -> AuctionSelectorContent -> AuctionSelector
		local auctionListFrame = auctionSelector.auctionListFrame
		if not auctionListFrame or auctionListFrame:GetHeight() <= self:GetHeight() then return end
		local minOffset, maxOffset = auctionSelector.scrollBar:GetRange()
		auctionSelector.offset = math.min(maxOffset, auctionSelector.offset + auctionSelector:GetScrollInterval())
		RepositionScrollbar(auctionSelector)
	end	
	bAuctionSelector.maskFrame = maskFrame

	local auctionListFrame = UI.CreateFrame("Frame", bAuctionSelector:GetName() .. "AuctionListFrame", maskFrame)
	auctionListFrame:SetPoint("TOPLEFT", maskFrame, "TOPLEFT")
	auctionListFrame:SetPoint("TOPRIGHT", maskFrame, "TOPRIGHT")
	auctionListFrame:SetHeight(0)
	function auctionListFrame.Event:Size()
		local auctionSelector = self:GetParent():GetParent():GetParent():GetParent():GetParent() -- AuctionListFrame -> MaskFrame -> InnerPanelContent -> InnerPanel -> AuctionSelectorContent -> AuctionSelector
		RepositionScrollbar(auctionSelector)
	end	
	bAuctionSelector.auctionListFrame = auctionListFrame
	
	local buyButton = UI.CreateFrame("RiftButton", bAuctionSelector:GetName() .. "BuyButton", bAuctionSelector:GetContent())
	buyButton:SetPoint("TOPRIGHT", bAuctionSelector:GetContent(), "BOTTOMRIGHT", 0, -35)
	buyButton:SetPoint("BOTTOMRIGHT", bAuctionSelector:GetContent(), "BOTTOMRIGHT", 0, 0)
	buyButton:SetText(L["buttonBuy"])
	buyButton:SetEnabled(false)
	function buyButton.Event:LeftDown()
		if not self:GetEnabled() then return end
		local auctionSelector = self:GetParent():GetParent()
		local auctionID = auctionSelector:GetSelectedAuction()
		if auctionID then
			local auctionData = Inspect.Auction.Detail(auctionID)
			if auctionData and auctionData.buyout then
				Command.Auction.Bid(auctionID, auctionData.buyout)
			end
		end
	end
	function buyButton.Event:LeftUp()
		if not self:GetEnabled() then return end
		local itemSelector = self:GetParent():GetParent():GetParent().itemSelector
		if itemSelector then
			local items = itemSelector:GetSelectedItems()
			if items and #items > 0 then
				local itemDetail = Inspect.Item.Detail(items[1])
				Command.Auction.Scan({ type = "search", index = 0, text = itemDetail.name })
			end
		end
	end
	function buyButton.Event:LeftUpoutside()
		if not self:GetEnabled() then return end
		local itemSelector = self:GetParent():GetParent():GetParent().itemSelector
		if itemSelector then
			local items = itemSelector:GetSelectedItems()
			if items and #items > 0 then
				local itemDetail = Inspect.Item.Detail(items[1])
				Command.Auction.Scan({ type = "search", index = 0, text = itemDetail.name })
			end
		end
	end	
	bAuctionSelector.buyButton = buyButton

	local bidButton = UI.CreateFrame("RiftButton", bAuctionSelector:GetName() .. "BidButton", bAuctionSelector:GetContent())
	bidButton:SetPoint("TOPRIGHT", buyButton, "TOPLEFT", 10, 0)
	bidButton:SetPoint("BOTTOMRIGHT", buyButton, "BOTTOMLEFT", 10, 0)
	bidButton:SetText(L["buttonBid"])
	bidButton:SetEnabled(false)
	function bidButton.Event:LeftDown()
		if not self:GetEnabled() then return end
		local auctionSelector = self:GetParent():GetParent()
		local auctionID = auctionSelector:GetSelectedAuction()
		if auctionID then
			local auctionData = Inspect.Auction.Detail(auctionID)
			if auctionData and not auctionData.bidder then
				Command.Auction.Bid(auctionID, auctionData.bid + 1)
			end
		end
	end
	function bidButton.Event:LeftUp()
		if not self:GetEnabled() then return end
		Command.Auction.Scan({type = "bids"})
	end
	function bidButton.Event:LeftUpoutside()
		if not self:GetEnabled() then return end
		Command.Auction.Scan({type = "bids"})
	end	
	bAuctionSelector.bidButton = bidButton

	local refreshPanel = UI.CreateFrame("BPanel", bAuctionSelector:GetName() .. ".RefreshPanel", bAuctionSelector:GetContent())
	refreshPanel:SetPoint("BOTTOMLEFT", bAuctionSelector:GetContent(), "BOTTOMLEFT", 2, -2)
	refreshPanel:SetPoint("TOPRIGHT", bidButton, "TOPLEFT", -2, 2)
	refreshPanel:SetInvertedBorder(true)
	refreshPanel:GetContent():SetBackgroundColor(0.1, 0, 0, 0.75)
	bAuctionSelector.refreshPanel = refreshPanel

	local refreshButton = UI.CreateFrame("Texture", refreshPanel:GetName() .. ".RefreshButton", refreshPanel:GetContent())
	refreshButton:SetTexture("BananAH", "Textures/RefreshMiniDisabled.png")
	refreshButton:SetPoint("TOPLEFT", refreshPanel:GetContent(), "TOPLEFT", 2, 1)
	refreshButton:SetPoint("BOTTOMRIGHT", refreshPanel:GetContent(), "BOTTOMLEFT", 22, -1)
	refreshButton.enabled = false
	function refreshButton.Event:MouseIn()
		if self.enabled then
			self:SetTexture("BananAH", "Textures/RefreshMiniOn.png")
		else
			self:SetTexture("BananAH", "Textures/RefreshMiniDisabled.png")
		end
	end
	function refreshButton.Event:MouseOut()
		if self.enabled then
			self:SetTexture("BananAH", "Textures/RefreshMiniOff.png")
		else
			self:SetTexture("BananAH", "Textures/RefreshMiniDisabled.png")
		end
	end
	function refreshButton.Event:LeftClick()
		if not self.enabled then return end
		local itemSelector = self:GetParent():GetParent():GetParent():GetParent():GetParent().itemSelector
		if itemSelector then
			local items = itemSelector:GetSelectedItems()
			if items and #items > 0 then
				local itemDetail = Inspect.Item.Detail(items[1])
				if not pcall(Command.Auction.Scan, { type = "search", index = 0, text = itemDetail.name }) then
					print(L["itemScanError"])
				else
					print(L["itemScanStarted"])
				end				
			end
		end
	end
	bAuctionSelector.refreshButton = refreshButton


	local refreshText = UI.CreateFrame("Text", refreshPanel:GetName() .. ".RefreshLabel", refreshPanel:GetContent())
	refreshText:SetText(L["lastUpdateMessage"] .. L["lastUpdateDateFallback"])
	refreshText:SetPoint("TOPLEFT", refreshPanel:GetContent(), "TOPLEFT", 30, 1)
	refreshText:SetPoint("BOTTOMLEFT", refreshPanel:GetContent(), "BOTTOMLEFT", 30, -1)
	bAuctionSelector.refreshText = refreshText

	-- Variables
	bAuctionSelector.offset = 0
	bAuctionSelector.selectedIndex = 0
	bAuctionSelector.orderCriteria = "buyoutUnitPrice"
	bAuctionSelector.orderOrdering = "ascending"

	-- Public
	bAuctionSelector.GetScrollInterval = GetScrollInterval
	bAuctionSelector.SetScrollInterval = SetScrollInterval
	bAuctionSelector.GetAuctions = GetAuctions
	bAuctionSelector.SetAuctions = SetAuctions
	bAuctionSelector.GetSelectedAuction = GetSelectedAuction
	
	Library.LibBInterface.BEventHandler(bAuctionSelector, { "AuctionSelected" })
	
	-- Late initialization
	RepositionScrollbar(bAuctionSelector)
	ApplyOrder(bAuctionSelector)

	function bAuctionSelector.Event:AuctionSelected(auctionID, auctionData)
		if Inspect.Interaction("auction") and auctionID and auctionData and BananAH.GetAuctionCached(auctionID) then
			bidButton:SetEnabled(true)
			if auctionData.buyoutPrice and auctionData.buyoutPrice > 0 then
				buyButton:SetEnabled(true)
				bidButton:SetEnabled(auctionData.bidPrice < auctionData.buyoutPrice)
			else
				buyButton:SetEnabled(false)
				bidButton:SetEnabled(true)
			end
		else
			buyButton:SetEnabled(false)
			bidButton:SetEnabled(false)
		end
	end
	local function OnInteractionChanged(interaction, state)
		if interaction == "auction" then
			if state then
				refreshButton.enabled = true
				refreshButton:SetTexture("BananAH", "Textures/RefreshMiniOff.png")
				local auctionID, auctionData = bAuctionSelector:GetSelectedAuction()
				if auctionID and auctionData and BananAH.GetAuctionCached(auctionID) then
					bidButton:SetEnabled(true)
					if auctionData.buyoutPrice and auctionData.buyoutPrice > 0 then
						buyButton:SetEnabled(true)
					end
				end
			else
				refreshButton.enabled = false
				refreshButton:SetTexture("BananAH", "Textures/RefreshMiniDisabled.png")
				buyButton:SetEnabled(false)
				bidButton:SetEnabled(false)
			end
		end
	end
	table.insert(Event.Interaction, { OnInteractionChanged, "BananAH", "AuctionSelector.OnInteractionChanged" })
	
	return bAuctionSelector
end