local _, InternalInterface = ...

local L = InternalInterface.Localization.L

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
	else
		self:SetData(nil)
	end
	
	if (lastUpdate or 0) <= 0 then
		self.refreshText:SetText(L["lastUpdateMessage"] .. L["lastUpdateDateFallback"])
	else
		self.refreshText:SetText(L["lastUpdateMessage"] .. os.date(L["lastUpdateDateFormat"], lastUpdate))
	end
	
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
	bAuctionSelector:AddColumn(L["columnSeller"], 100, "Text", true, "sellerName", { Alignment = "left", Formatter = "none" })
	bAuctionSelector:AddColumn(L["columnStack"], 70, "Text", true, "stack", { Alignment = "center", Formatter = "none" })
	bAuctionSelector:AddColumn(L["columnBid"], 120, "MoneyRenderer", true, "bidPrice")
	bAuctionSelector:AddColumn(L["columnBuy"], 120, "MoneyRenderer", true, "buyoutPrice")
	bAuctionSelector:AddColumn(L["columnBidPerUnit"], 120, "MoneyRenderer", true, "bidUnitPrice")
	local defaultOrderColumn = bAuctionSelector:AddColumn(L["columnBuyPerUnit"], 120, "MoneyRenderer", true, "buyoutUnitPrice")
	bAuctionSelector:AddColumn(L["columnMinExpire"], 120, "Text", true, "minExpireTime", { Alignment = "right", Formatter = "date" })
	bAuctionSelector:AddColumn(L["columnMaxExpire"], 120, "Text", true, "maxExpireTime", { Alignment = "right", Formatter = "date" })
	bAuctionSelector:AddColumn("", 0, "AuctionSelectorRenderer")
	defaultOrderColumn.Event.LeftClick(defaultOrderColumn)
	
	local controlFrame = UI.CreateFrame("Frame", name .. ".ControlFrame", bAuctionSelector.externalPanel:GetContent())
	local paddingLeft, _, paddingRight, paddingBottom = bAuctionSelector:GetPadding()
	controlFrame:SetPoint("TOPLEFT", bAuctionSelector.externalPanel:GetContent(), "BOTTOMLEFT", paddingLeft + 2, 2 - paddingBottom)
	controlFrame:SetPoint("BOTTOMRIGHT", bAuctionSelector.externalPanel:GetContent(), "BOTTOMRIGHT", -paddingRight - 2, -2)
	bAuctionSelector.controlFrame = controlFrame

	local buyButton = UI.CreateFrame("RiftButton", bAuctionSelector:GetName() .. ".BuyButton", controlFrame)
	buyButton:SetPoint("CENTERRIGHT", controlFrame, "CENTERRIGHT", 0, 0)
	buyButton:SetText(L["buttonBuy"])
	buyButton:SetEnabled(false)
	-- function buyButton.Event:LeftDown()
		-- if not self:GetEnabled() then return end
		-- local auctionSelector = self:GetParent():GetParent()
		-- local auctionID = auctionSelector:GetSelectedAuction()
		-- if auctionID then
			-- local auctionData = Inspect.Auction.Detail(auctionID)
			-- if auctionData and auctionData.buyout then
				-- Command.Auction.Bid(auctionID, auctionData.buyout)
			-- end
		-- end
	-- end
	-- function buyButton.Event:LeftUp()
		-- if not self:GetEnabled() then return end
		-- local itemSelector = self:GetParent():GetParent():GetParent().itemSelector
		-- if itemSelector then
			-- local items = itemSelector:GetSelectedItems()
			-- if items and #items > 0 then
				-- local itemDetail = Inspect.Item.Detail(items[1])
				-- Command.Auction.Scan({ type = "search", index = 0, text = itemDetail.name })
			-- end
		-- end
	-- end
	-- function buyButton.Event:LeftUpoutside()
		-- if not self:GetEnabled() then return end
		-- local itemSelector = self:GetParent():GetParent():GetParent().itemSelector
		-- if itemSelector then
			-- local items = itemSelector:GetSelectedItems()
			-- if items and #items > 0 then
				-- local itemDetail = Inspect.Item.Detail(items[1])
				-- Command.Auction.Scan({ type = "search", index = 0, text = itemDetail.name })
			-- end
		-- end
	-- end	
	bAuctionSelector.buyButton = buyButton

	local bidButton = UI.CreateFrame("RiftButton", bAuctionSelector:GetName() .. ".BidButton", controlFrame)
	bidButton:SetPoint("CENTERRIGHT", buyButton, "CENTERLEFT", 10, 0)
	bidButton:SetText(L["buttonBid"])
	bidButton:SetEnabled(false)
	-- function bidButton.Event:LeftDown()
		-- if not self:GetEnabled() then return end
		-- local auctionSelector = self:GetParent():GetParent()
		-- local auctionID = auctionSelector:GetSelectedAuction()
		-- if auctionID then
			-- local auctionData = Inspect.Auction.Detail(auctionID)
			-- if auctionData and not auctionData.bidder then
				-- Command.Auction.Bid(auctionID, auctionData.bid + 1)
			-- end
		-- end
	-- end
	-- function bidButton.Event:LeftUp()
		-- if not self:GetEnabled() then return end
		-- Command.Auction.Scan({type = "bids"})
	-- end
	-- function bidButton.Event:LeftUpoutside()
		-- if not self:GetEnabled() then return end
		-- Command.Auction.Scan({type = "bids"})
	-- end	
	bAuctionSelector.bidButton = bidButton

	local refreshPanel = UI.CreateFrame("BPanel", bAuctionSelector:GetName() .. ".RefreshPanel", controlFrame)
	refreshPanel:SetPoint("BOTTOMLEFT", controlFrame, "BOTTOMLEFT", 0, -2)
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
		
		local item = bAuctionSelector:GetItem()
		if not item then return end
		
		local ok, itemDetail = pcall(Inspect.Item.Detail, item)
		if not ok then return end
		
		if not pcall(Command.Auction.Scan, { type = "search", index = 0, text = itemDetail.name }) then
			print(L["itemScanError"])
		else
			print(L["itemScanStarted"])
		end				
	end
	bAuctionSelector.refreshButton = refreshButton

	local refreshText = UI.CreateFrame("Text", refreshPanel:GetName() .. ".RefreshLabel", refreshPanel:GetContent())
	refreshText:SetText(L["lastUpdateMessage"] .. L["lastUpdateDateFallback"])
	refreshText:SetPoint("TOPLEFT", refreshPanel:GetContent(), "TOPLEFT", 30, 1)
	refreshText:SetPoint("BOTTOMLEFT", refreshPanel:GetContent(), "BOTTOMLEFT", 30, -1)
	bAuctionSelector.refreshText = refreshText

	-- Public
	bAuctionSelector.GetItem = GetItem
	bAuctionSelector.SetItem = SetItem
	bAuctionSelector.GetSelectedAuction = GetSelectedAuction
	Library.LibBInterface.BEventHandler(bAuctionSelector, { "AuctionSelected" })
	
	-- Late initialization
	local function RefreshButtons()
		local auctionInteraction = Inspect.Interaction("auction")
		local selectedAuctionCached = false
		local selectedAuctionBid = false
		local selectedAuctionBuy = false
		
		local selectedAuctionID, selectedAuctionData = bAuctionSelector:GetSelectedAuction()
		if selectedAuctionID and selectedAuctionData then 
			selectedAuctionCached = BananAH.GetAuctionCached(selectedAuctionID) or false
			selectedAuctionBid = not selectedAuctionData.buyoutPrice or selectedAuctionData.bidPrice < selectedAuctionData.buyoutPrice
			selectedAuctionBuyout = selectedAuctionData.buyoutPrice and true or false
		end
		
		refreshButton.enabled = auctionInteraction
		refreshButton:SetTexture("BananAH", auctionInteraction and "Textures/RefreshMiniOff.png" or "Textures/RefreshMiniDisabled.png")
		bidButton:SetEnabled(auctionInteraction and selectedAuctionCached and selectedAuctionBid)		
		buyButton:SetEnabled(auctionInteraction and selectedAuctionCached and selectedAuctionBuyout)		
	end
	
	local function OnInteractionChanged(interaction, state)
		if interaction == "auction" then
			RefreshButtons()
		end
	end
	table.insert(Event.Interaction, { OnInteractionChanged, "BananAH", "AuctionSelector.OnInteractionChanged" })
	
	function bAuctionSelector.Event:SelectionChanged(auctionID, auctionData)
		RefreshButtons()
	end

	-- function bAuctionSelector.Event:AuctionSelected(auctionID, auctionData)
		-- if Inspect.Interaction("auction") and auctionID and auctionData and BananAH.GetAuctionCached(auctionID) then
			-- bidButton:SetEnabled(true)
			-- if auctionData.buyoutPrice and auctionData.buyoutPrice > 0 then
				-- buyButton:SetEnabled(true)
				-- bidButton:SetEnabled(auctionData.bidPrice < auctionData.buyoutPrice)
			-- else
				-- buyButton:SetEnabled(false)
				-- bidButton:SetEnabled(true)
			-- end
		-- else
			-- buyButton:SetEnabled(false)
			-- bidButton:SetEnabled(false)
		-- end
	-- end	
	
	return bAuctionSelector
end