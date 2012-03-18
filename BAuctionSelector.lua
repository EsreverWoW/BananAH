local _, InternalInterface = ...

local L = InternalInterface.Localization.L
local GetLocalizedDateString = InternalInterface.Localization.GetLocalizedDateString

-- Custom renderers
local function AuctionSelectorRenderer(name, parent)
	local auctionSelectorCell = UI.CreateFrame("Frame", name, parent)
	
	function auctionSelectorCell:SetValue(key, value, width, extra)
		self:ClearAll()
		self:SetAllPoints()
		self:SetLayer(self:GetParent():GetLayer() - 1)
		if BananAH.GetAuctionCached(key) then
			self:SetBackgroundColor(0, 0.75, 0.75, 0.1)
		else
			self:SetBackgroundColor(0.75, 0, 0, 0.1)
		end
	end
	
	return auctionSelectorCell
end
Library.LibBInterface.RegisterGridRenderer("AuctionSelectorRenderer", AuctionSelectorRenderer)

local function MoneyRenderer(name, parent)
	local moneyCell = UI.CreateFrame("BMoneyDisplay", name, parent)
	
	local oldSetValue = moneyCell.SetValue
	function moneyCell:SetValue(key, value, width, extra)
		oldSetValue(self, value)
		self:SetWidth(width)
	end
	
	return moneyCell
end
Library.LibBInterface.RegisterGridRenderer("MoneyRenderer", MoneyRenderer)

-- Private
local function RefreshButtons(bAuctionSelector)
	local auctionSelected = false
	local auctionInteraction = Inspect.Interaction("auction")
	local selectedAuctionCached = false
	local selectedAuctionBid = false
	local selectedAuctionBuy = false
	local highestBidder = false
	local seller = false
	local bidPrice = 1
	
	local selectedAuctionID, selectedAuctionData = bAuctionSelector:GetSelectedAuction()
	if selectedAuctionID and selectedAuctionData then 
		auctionSelected = true
		selectedAuctionCached = BananAH.GetAuctionCached(selectedAuctionID) or false
		selectedAuctionBid = not selectedAuctionData.buyoutPrice or selectedAuctionData.bidPrice < selectedAuctionData.buyoutPrice
		selectedAuctionBuyout = selectedAuctionData.buyoutPrice and true or false
		local ok, auctionData = pcall(Inspect.Auction.Detail, selectedAuctionID)
		if ok and auctionData and auctionData.bidder then highestBidder = true end
		local ok, unitDetail = pcall(Inspect.Unit.Detail, "player")
		if ok and unitDetail and unitDetail.name == selectedAuctionData.sellerName then seller = true end
		bidPrice = selectedAuctionData.bidPrice
	end
	
	bAuctionSelector.refreshButton.enabled = auctionInteraction
	bAuctionSelector.refreshButton:SetTexture("BananAH", auctionInteraction and "Textures/RefreshMiniOff.png" or "Textures/RefreshMiniDisabled.png")
	bAuctionSelector.bidButton:SetEnabled(auctionSelected and auctionInteraction and selectedAuctionCached and selectedAuctionBid and not highestBidder and not seller)
	bAuctionSelector.buyButton:SetEnabled(auctionSelected and auctionInteraction and selectedAuctionCached and selectedAuctionBuyout and not seller)

	if not auctionSelected then
		bAuctionSelector.noBidLabel:SetText(L["PostingPanel/bidErrorNoAuction"])
		bAuctionSelector.noBidLabel:SetVisible(true)
		bAuctionSelector.bidMoneySelector:SetVisible(false)
	elseif not selectedAuctionCached then
		bAuctionSelector.noBidLabel:SetText(L["PostingPanel/bidErrorNotCached"])
		bAuctionSelector.noBidLabel:SetVisible(true)
		bAuctionSelector.bidMoneySelector:SetVisible(false)
	elseif not selectedAuctionBid then
		bAuctionSelector.noBidLabel:SetText(L["PostingPanel/bidErrorBidEqualBuy"])
		bAuctionSelector.noBidLabel:SetVisible(true)
		bAuctionSelector.bidMoneySelector:SetVisible(false)
	elseif seller then
		bAuctionSelector.noBidLabel:SetText(L["PostingPanel/bidErrorSeller"])
		bAuctionSelector.noBidLabel:SetVisible(true)
		bAuctionSelector.bidMoneySelector:SetVisible(false)
	elseif highestBidder then
		bAuctionSelector.noBidLabel:SetText(L["PostingPanel/bidErrorHighestBidder"])
		bAuctionSelector.noBidLabel:SetVisible(true)
		bAuctionSelector.bidMoneySelector:SetVisible(false)
	elseif not auctionInteraction then
		bAuctionSelector.noBidLabel:SetText(L["PostingPanel/bidErrorNoAuctionHouse"])
	else
		bAuctionSelector.bidMoneySelector:SetValue(bidPrice + 1)
		bAuctionSelector.bidMoneySelector:SetVisible(true)
		bAuctionSelector.noBidLabel:SetVisible(false)
	end
end

local function AuctionRightClick(self)
	local playerName = Inspect.Unit.Detail("player").name
	local data = self.dataValue
	local sellerName = data and data.sellerName or nil
	local bid = data and data.bidUnitPrice or nil
	local buy = data and data.buyoutUnitPrice or 0
	if playerName and sellerName and bid and self.postSelector then
		if playerName ~= sellerName then
			bid = bid - 1
			buy = buy - 1
		end	
		self.postSelector:SetPrices(bid, buy)
	end
	self.Event.LeftClick(self)
end

-- Public
local function GetItem(self)
	return self.item
end

local function SetItem(self, item)
	self.item = item
	
	local lastUpdate = nil
	if item then
		local auctions = nil
		auctions, lastUpdate = BananAH.GetActiveAuctionData(item)
		self:SetData(auctions)
		for index, row in ipairs(self.rows) do
			row.postSelector = self.postSelector
			row.Event.RightClick = AuctionRightClick
		end
	else
		self:SetData(nil)
	end
	
	if (lastUpdate or 0) <= 0 then
		self.refreshText:SetText(L["PostingPanel/lastUpdateMessage"] .. L["PostingPanel/lastUpdateDateFallback"])
	else
		self.refreshText:SetText(L["PostingPanel/lastUpdateMessage"] .. GetLocalizedDateString(L["PostingPanel/lastUpdateDateFormat"], lastUpdate))
	end
	
	RefreshButtons(self)
	
	return self.item
end

local function GetSelectedAuction(self)
	return self:GetSelectedData()
end

function InternalInterface.UI.AuctionSelector(name, parent)
	local bAuctionSelector = UI.CreateFrame("BDataGrid", name, parent)
	bAuctionSelector:SetPadding(1, 1, 1, 38)
	bAuctionSelector:SetHeadersVisible(true)
	bAuctionSelector:SetRowHeight(20)
	bAuctionSelector:SetRowMargin(0)
	bAuctionSelector:SetUnselectedRowBackgroundColor(0.2, 0.2, 0.2, 0.25)
	bAuctionSelector:SetSelectedRowBackgroundColor(0.6, 0.6, 0.6, 0.25)
	bAuctionSelector:AddColumn(L["PostingPanel/columnSeller"], 100, "Text", true, "sellerName", { Alignment = "left", Formatter = "none" })
	bAuctionSelector:AddColumn(L["PostingPanel/columnStack"], 70, "Text", true, "stack", { Alignment = "center", Formatter = "none" })
	bAuctionSelector:AddColumn(L["PostingPanel/columnBid"], 120, "MoneyRenderer", true, "bidPrice")
	bAuctionSelector:AddColumn(L["PostingPanel/columnBuy"], 120, "MoneyRenderer", true, "buyoutPrice")
	bAuctionSelector:AddColumn(L["PostingPanel/columnBidPerUnit"], 120, "MoneyRenderer", true, "bidUnitPrice")
	local defaultOrderColumn = bAuctionSelector:AddColumn(L["PostingPanel/columnBuyPerUnit"], 120, "MoneyRenderer", true, "buyoutUnitPrice")
	local function LocalizedDateFormatter(value)
		return GetLocalizedDateString("%a %X", value)
	end
	bAuctionSelector:AddColumn(L["PostingPanel/columnMinExpire"], 120, "Text", true, "minExpireTime", { Alignment = "right", Formatter = LocalizedDateFormatter })
	bAuctionSelector:AddColumn(L["PostingPanel/columnMaxExpire"], 120, "Text", true, "maxExpireTime", { Alignment = "right", Formatter = LocalizedDateFormatter })
	bAuctionSelector:AddColumn("", 0, "AuctionSelectorRenderer")
	defaultOrderColumn.Event.LeftClick(defaultOrderColumn)
	
	function bAuctionSelector.Event:SelectionChanged(auctionID, auctionData)
		RefreshButtons(bAuctionSelector)
		if self.Event.AuctionSelected then
			self.Event.AuctionSelected(self, auctionID, auctionData)
		end		
	end
	
	local controlFrame = UI.CreateFrame("Frame", name .. ".ControlFrame", bAuctionSelector.externalPanel:GetContent())
	local paddingLeft, _, paddingRight, paddingBottom = bAuctionSelector:GetPadding()
	controlFrame:SetPoint("TOPLEFT", bAuctionSelector.externalPanel:GetContent(), "BOTTOMLEFT", paddingLeft + 2, 2 - paddingBottom)
	controlFrame:SetPoint("BOTTOMRIGHT", bAuctionSelector.externalPanel:GetContent(), "BOTTOMRIGHT", -paddingRight - 2, -2)
	bAuctionSelector.controlFrame = controlFrame

	local buyButton = UI.CreateFrame("RiftButton", name .. ".BuyButton", controlFrame)
	buyButton:SetPoint("CENTERRIGHT", controlFrame, "CENTERRIGHT", 0, 0)
	buyButton:SetText(L["PostingPanel/buttonBuy"])
	buyButton:SetEnabled(false)
	function buyButton.Event:LeftDown()
		if not self:GetEnabled() then return end
		local auctionID, auctionData = bAuctionSelector:GetSelectedAuction()
		if auctionID then
			Command.Auction.Bid(auctionID, auctionData.buyoutPrice)
		end
	end
	function buyButton.Event:LeftUp()
		if not self:GetEnabled() then return end
		local item = bAuctionSelector:GetItem()
		if not item then return end
		local ok, itemDetail = pcall(Inspect.Item.Detail, item)
		if not ok then return end
		pcall(Command.Auction.Scan, { type = "search", index = 0, text = itemDetail.name })
	end
	function buyButton.Event:LeftUpoutside()
		if not self:GetEnabled() then return end
		local item = bAuctionSelector:GetItem()
		if not item then return end
		local ok, itemDetail = pcall(Inspect.Item.Detail, item)
		if not ok then return end
		pcall(Command.Auction.Scan, { type = "search", index = 0, text = itemDetail.name })
	end	
	bAuctionSelector.buyButton = buyButton

	local bidButton = UI.CreateFrame("RiftButton", name .. ".BidButton", controlFrame)
	bidButton:SetPoint("CENTERRIGHT", buyButton, "CENTERLEFT", 10, 0)
	bidButton:SetText(L["PostingPanel/buttonBid"])
	bidButton:SetEnabled(false)
	function bidButton.Event:LeftDown()
		if not self:GetEnabled() then return end
		local auctionID = bAuctionSelector:GetSelectedAuction()
		if auctionID then
			Command.Auction.Bid(auctionID, bAuctionSelector.bidMoneySelector:GetValue())
		end
	end
	function bidButton.Event:LeftUp()
		if not self:GetEnabled() then return end
		pcall(Command.Auction.Scan, { type = "bids" })
	end
	function bidButton.Event:LeftUpoutside()
		if not self:GetEnabled() then return end
		pcall(Command.Auction.Scan, { type = "bids" })
	end	
	bAuctionSelector.bidButton = bidButton
	
	local bidMoneySelector = UI.CreateFrame("BMoneySelector", name .. ".BidMoneySelector", controlFrame)
	bidMoneySelector:SetPoint("TOPRIGHT", bidButton, "TOPLEFT", -5, 2)
	bidMoneySelector:SetPoint("BOTTOMLEFT", bidButton, "BOTTOMLEFT", -230, -2)
	bidMoneySelector:SetVisible(false)
	bAuctionSelector.bidMoneySelector = bidMoneySelector
	
	local noBidLabel = UI.CreateFrame("BShadowedText", name .. ".NoBidLabel", controlFrame)
	noBidLabel:SetFontColor(1, 0.5, 0, 1)
	noBidLabel:SetShadowColor(0.05, 0, 0.1, 1)
	noBidLabel:SetShadowOffset(2, 2)
	noBidLabel:SetFontSize(14)
	noBidLabel:SetText("")
	noBidLabel:SetPoint("CENTER", bidButton, "CENTERLEFT", -115, 0)
	bAuctionSelector.noBidLabel = noBidLabel

	local refreshPanel = UI.CreateFrame("BPanel", name .. ".RefreshPanel", controlFrame)
	refreshPanel:SetPoint("BOTTOMLEFT", controlFrame, "BOTTOMLEFT", 0, -2)
	refreshPanel:SetPoint("TOPRIGHT", bidButton, "TOPLEFT", -235, 2)
	refreshPanel:SetInvertedBorder(true)
	refreshPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	bAuctionSelector.refreshPanel = refreshPanel

	local refreshButton = UI.CreateFrame("Texture", name .. ".RefreshButton", refreshPanel:GetContent())
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
		
		local item = bAuctionSelector:GetItem()
		if not item then return end
		
		local ok, itemDetail = pcall(Inspect.Item.Detail, item)
		if not ok then return end
		
		if not pcall(Command.Auction.Scan, { type = "search", index = 0, text = itemDetail.name }) then
			print(L["PostingPanel/itemScanError"])
		else
			print(L["PostingPanel/itemScanStarted"])
		end				
	end
	bAuctionSelector.refreshButton = refreshButton

	local refreshText = UI.CreateFrame("Text", name .. ".RefreshLabel", refreshPanel:GetContent())
	refreshText:SetText(L["PostingPanel/lastUpdateMessage"] .. L["PostingPanel/lastUpdateDateFallback"])
	refreshText:SetPoint("TOPLEFT", refreshPanel:GetContent(), "TOPLEFT", 30, 1)
	refreshText:SetPoint("BOTTOMLEFT", refreshPanel:GetContent(), "BOTTOMLEFT", 30, -1)
	bAuctionSelector.refreshText = refreshText

	-- Public
	bAuctionSelector.GetItem = GetItem
	bAuctionSelector.SetItem = SetItem
	bAuctionSelector.GetSelectedAuction = GetSelectedAuction
	Library.LibBInterface.BEventHandler(bAuctionSelector, { "AuctionSelected" })
	
	-- Late initialization
	local function OnInteractionChanged(interaction, state)
		if interaction == "auction" then
			RefreshButtons(bAuctionSelector)
		end
	end
	table.insert(Event.Interaction, { OnInteractionChanged, "BananAH", "AuctionSelector.OnInteractionChanged" })
	
	local function OnAuctionData(full, total, new, updated, removed, before)
		bAuctionSelector:SetItem(bAuctionSelector:GetItem())
	end
	table.insert(Event.BananAH.AuctionData, { OnAuctionData, "BananAH", "AuctionSelector.OnAuctionData" })
	
	return bAuctionSelector
end