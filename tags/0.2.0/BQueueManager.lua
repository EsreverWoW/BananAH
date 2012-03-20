local _, InternalInterface = ...

local GetRarityColor = InternalInterface.Utility.GetRarityColor
local L = InternalInterface.Localization.L

-- Custom renderers
local function QueueManagerRenderer(name, parent)
	local queueManagerCell = UI.CreateFrame("Texture", name, parent)
	queueManagerCell:SetTexture("BananAH", "Textures/ItemRowBackground.png")
	
	local itemTextureBackground = UI.CreateFrame("Frame", name .. ".ItemTextureBackground", queueManagerCell)
	itemTextureBackground:SetPoint("CENTERLEFT", queueManagerCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	queueManagerCell.itemTextureBackground = itemTextureBackground
	
	local itemTexture = UI.CreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	queueManagerCell.itemTexture = itemTexture
	
	local itemNameLabel = UI.CreateFrame("BShadowedText", name .. ".ItemNameLabel", queueManagerCell)
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("TOPLEFT", queueManagerCell, "TOPLEFT", 58, 0)
	queueManagerCell.itemNameLabel = itemNameLabel	
	
	local itemStackLabel = UI.CreateFrame("Text", name .. ".ItemStackLabel", queueManagerCell)
	itemStackLabel:SetPoint("BOTTOMLEFT", queueManagerCell, "BOTTOMLEFT", 58, 0)
	queueManagerCell.itemStackLabel = itemStackLabel
	
	local bidMoneyDisplay = UI.CreateFrame("BMoneyDisplay", name .. ".BidMoneyDisplay", queueManagerCell)
	bidMoneyDisplay:SetPoint("TOPLEFT", queueManagerCell, "BOTTOMRIGHT", -120, -40)
	bidMoneyDisplay:SetPoint("BOTTOMRIGHT", queueManagerCell, "BOTTOMRIGHT", 0, -20)
	queueManagerCell.bidMoneyDisplay = bidMoneyDisplay
	
	local buyMoneyDisplay = UI.CreateFrame("BMoneyDisplay", name .. ".BuyMoneyDisplay", queueManagerCell)
	buyMoneyDisplay:SetPoint("TOPLEFT", queueManagerCell, "BOTTOMRIGHT", -120, -20)
	buyMoneyDisplay:SetPoint("BOTTOMRIGHT", queueManagerCell, "BOTTOMRIGHT", 0, 0)
	queueManagerCell.buyMoneyDisplay = buyMoneyDisplay
	
	
	function queueManagerCell:SetValue(key, value, width, extra)
		local itemDetail = Inspect.Item.Detail(value.itemType)
		self:SetWidth(width)
		self.itemTextureBackground:SetBackgroundColor(GetRarityColor(itemDetail.rarity))
		self.itemTexture:SetTexture("Rift", itemDetail.icon)
		self.itemNameLabel:SetText(itemDetail.name)
		self.itemNameLabel:SetFontColor(GetRarityColor(itemDetail.rarity))
		
		local fullStacks = math.floor(value.amount / value.stackSize)
		local oddStack = value.amount % value.stackSize
		local stack = ""
		if fullStacks > 0 and oddStack > 0 then
			stack = string.format("%d x %d + %d", fullStacks, value.stackSize, oddStack)
		elseif fullStacks > 0 then
			stack = string.format("%d x %d", fullStacks, value.stackSize)
		else
			stack = tostring(oddStack)
		end
		self.itemStackLabel:SetText(stack)
		
		self.bidMoneyDisplay:SetValue(value.amount * (value.unitBidPrice or 0))
		self.buyMoneyDisplay:SetValue(value.amount * (value.unitBuyoutPrice or 0))
	end
	
	return queueManagerCell
end
Library.LibBInterface.RegisterGridRenderer("QueueManagerRenderer", QueueManagerRenderer)

-- Private

-- Public

function InternalInterface.UI.QueueManager(name, parent)
	local bQueueManager = UI.CreateFrame("BPanel", name, parent)
	local pauseResumeButton = UI.CreateFrame("RiftButton", name .. ".PauseResumeButton", bQueueManager:GetContent())
	local queueStatusLabel = UI.CreateFrame("BShadowedText", name .. ".QueueStatus", bQueueManager:GetContent())
	local queueStatus = UI.CreateFrame("BShadowedText", name .. ".QueueStatus", bQueueManager:GetContent())
	local showHideButton = UI.CreateFrame("RiftButton", name .. ".ShowHideButton", bQueueManager:GetContent())
	local queueGrid = UI.CreateFrame("BDataGrid", name .. ".QueueGrid", parent)
	local clearButton = UI.CreateFrame("RiftButton", name .. ".ClearButton", queueGrid.externalPanel:GetContent())
	local cancelButton = UI.CreateFrame("RiftButton", name .. ".CancelButton", queueGrid.externalPanel:GetContent())
	
	bQueueManager:SetInvertedBorder(true)
	bQueueManager:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
	
	queueStatusLabel:SetPoint("TOPLEFT", bQueueManager:GetContent(), "TOPLEFT", 5, 5)
	queueStatusLabel:SetText(L["PostingPanel/labelPostingQueueStatus"])
	queueStatusLabel:SetFontSize(14)
	queueStatusLabel:SetFontColor(1, 1, 0.75, 1)
	queueStatusLabel:SetShadowOffset(2, 2)	

	queueStatus:SetPoint("TOPRIGHT", bQueueManager:GetContent(), "TOPRIGHT", -5, 6)
	queueStatus:SetText(L["PostingPanel/labelPostingQueueStatus2"])
	queueStatus:SetFontSize(13)

	showHideButton:SetPoint("BOTTOMRIGHT", bQueueManager:GetContent(), "BOTTOMCENTER")
	showHideButton:SetText(L["PostingPanel/buttonShowQueue"])
	
	pauseResumeButton:SetPoint("BOTTOMLEFT", bQueueManager:GetContent(), "BOTTOMCENTER")
	pauseResumeButton:SetText(L["PostingPanel/buttonPauseQueue"])
	
	queueGrid:SetPoint("TOPLEFT", bQueueManager, "BOTTOMLEFT", 0, 0)
	queueGrid:SetPoint("BOTTOMRIGHT", bQueueManager, "BOTTOMRIGHT", 0, 235)
	queueGrid:SetLayer(1000)
	queueGrid:SetPadding(0, 0, 0, 32)
	queueGrid:SetHeadersVisible(false)
	queueGrid:SetRowHeight(62)
	queueGrid:SetRowMargin(2)
	queueGrid:SetUnselectedRowBackgroundColor(0.15, 0.2, 0.15, 1)
	queueGrid:SetSelectedRowBackgroundColor(0.45, 0.6, 0.45, 1)
	queueGrid:AddColumn("", 248, "QueueManagerRenderer", false)
	queueGrid.externalPanel.borderFrame:SetAlpha(1)
	queueGrid:SetVisible(false)
	
	clearButton:SetPoint("BOTTOMRIGHT", queueGrid.externalPanel:GetContent(), "BOTTOMCENTER")
	clearButton:SetText(L["PostingPanel/buttonCancelQueueAll"])
	clearButton:SetEnabled(false)
	
	cancelButton:SetPoint("BOTTOMLEFT", queueGrid.externalPanel:GetContent(), "BOTTOMCENTER")
	cancelButton:SetText(L["PostingPanel/buttonCancelQueueSelected"])
	cancelButton:SetEnabled(false)
	
	function showHideButton.Event:LeftPress()
		local visible = not queueGrid:GetVisible()
		queueGrid:SetVisible(visible)
		self:SetText(visible and L["PostingPanel/buttonHideQueue"] or L["PostingPanel/buttonShowQueue"])
	end
	
	function pauseResumeButton.Event:LeftPress()
		BananAH.SetPostingQueuePaused(not BananAH.GetPostingQueuePaused())
	end
	
	function clearButton.Event:LeftPress()
		while #BananAH.GetPostingQueue() > 0 do
			BananAH.CancelPostingByIndex(1)
		end
	end
	
	function cancelButton.Event:LeftPress()
		local key = queueGrid:GetSelectedData()
		if key then
			BananAH.CancelPostingByIndex(key)
		end
	end
	
	function queueGrid.Event:SelectionChanged(key, value)
		cancelButton:SetEnabled(key and true or false)
	end
	
	local function OnQueueStatusChanged()
		local status = BananAH.GetPostingQueueStatus()
		local paused = BananAH.GetPostingQueuePaused()
		queueStatus:SetText(L["PostingPanel/labelPostingQueueStatus" .. status])
		pauseResumeButton:SetText(paused and L["PostingPanel/buttonResumeQueue"] or L["PostingPanel/buttonPauseQueue"])
		
		local queue = BananAH.GetPostingQueue()
		local auctions = {}
		local clearable = false
		for index, data in ipairs(queue) do
			auctions[index] = data
			clearable = true
		end
		queueGrid:SetData(auctions)
		clearButton:SetEnabled(clearable)
	end
	table.insert(Event.BananAH.PostingQueueStatusChanged, { OnQueueStatusChanged, "BananAH", "QueueManager.OnQueueStatusChanged" })
	OnQueueStatusChanged()

	return bQueueManager
end