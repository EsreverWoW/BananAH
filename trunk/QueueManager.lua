-- ***************************************************************************************************************************************************
-- * Main.lua                                                                                                                                        *
-- ***************************************************************************************************************************************************
-- * Creates the addon windows                                                                                                                       *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.29 / Baanano: Updated for 0.4.1                                                                                                 *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local CTooltip = Command.Tooltip
local CancelAll = LibPGC.CancelAll
local CancelPostingByIndex = LibPGC.CancelPostingByIndex
local DataGrid = Yague.DataGrid
local GetPostingQueue = LibPGC.GetPostingQueue
local GetPostingQueuePaused = LibPGC.GetPostingQueuePaused
local GetPostingQueueStatus = LibPGC.GetPostingQueueStatus
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local IIDetail = Inspect.Item.Detail
local MFloor = math.floor
local MoneyDisplay = Yague.MoneyDisplay
local Panel = Yague.Panel
local SFormat = string.format
local SetPostingQueuePaused = LibPGC.SetPostingQueuePaused
local ShadowedText = Yague.ShadowedText
local TInsert = table.insert
local UICreateFrame = UI.CreateFrame
local tostring = tostring

local function QueueCellType(name, parent)
	local queueManagerCell = UICreateFrame("Mask", name, parent)
	
	local cellBackground = UICreateFrame("Texture", name .. ".CellBackground", queueManagerCell)
	local itemTextureBackground = UICreateFrame("Frame", name .. ".ItemTextureBackground", queueManagerCell)
	local itemTexture = UICreateFrame("Texture", name .. ".ItemTexture", itemTextureBackground)
	local itemNameLabel = ShadowedText(name .. ".ItemNameLabel", queueManagerCell)
	local itemStackLabel = UICreateFrame("Text", name .. ".ItemStackLabel", queueManagerCell)
	local bidMoneyDisplay = MoneyDisplay(name .. ".BidMoneyDisplay", queueManagerCell)
	local buyMoneyDisplay = MoneyDisplay(name .. ".BuyMoneyDisplay", queueManagerCell)

	local itemType = nil
	
	cellBackground:SetAllPoints()
	cellBackground:SetTextureAsync(addonID, "Textures/ItemRowBackground.png") -- TODO Move to BDataGrid
	cellBackground:SetLayer(-9999)
	
	itemTextureBackground:SetPoint("CENTERLEFT", queueManagerCell, "CENTERLEFT", 4, 0)
	itemTextureBackground:SetWidth(50)
	itemTextureBackground:SetHeight(50)
	
	itemTexture:SetPoint("TOPLEFT", itemTextureBackground, "TOPLEFT", 1.5, 1.5)
	itemTexture:SetPoint("BOTTOMRIGHT", itemTextureBackground, "BOTTOMRIGHT", -1.5, -1.5)
	queueManagerCell.itemTexture = itemTexture
	
	itemNameLabel:SetFontSize(13)
	itemNameLabel:SetPoint("TOPLEFT", queueManagerCell, "TOPLEFT", 58, 0)
	
	itemStackLabel:SetPoint("BOTTOMLEFT", queueManagerCell, "BOTTOMLEFT", 58, 0)
	
	bidMoneyDisplay:SetPoint("TOPLEFT", queueManagerCell, "BOTTOMRIGHT", -120, -40)
	bidMoneyDisplay:SetPoint("BOTTOMRIGHT", queueManagerCell, "BOTTOMRIGHT", 0, -20)
	
	buyMoneyDisplay:SetPoint("TOPLEFT", queueManagerCell, "BOTTOMRIGHT", -120, -20)
	buyMoneyDisplay:SetPoint("BOTTOMRIGHT", queueManagerCell, "BOTTOMRIGHT", 0, 0)

	function queueManagerCell:SetValue(key, value, width, extra)
		local itemDetail = IIDetail(value.itemType)
		self:SetWidth(width)
		
		itemTextureBackground:SetBackgroundColor(GetRarityColor(itemDetail.rarity))
		
		itemTexture:SetTexture("Rift", itemDetail.icon)
		itemType = value.itemType
		
		itemNameLabel:SetText(itemDetail.name)
		itemNameLabel:SetFontColor(GetRarityColor(itemDetail.rarity))
		
		local fullStacks = MFloor(value.amount / value.stackSize)
		local oddStack = value.amount % value.stackSize
		local stack = ""
		if fullStacks > 0 and oddStack > 0 then
			stack = SFormat("%d x %d + %d", fullStacks, value.stackSize, oddStack)
		elseif fullStacks > 0 then
			stack = SFormat("%d x %d", fullStacks, value.stackSize)
		else
			stack = tostring(oddStack)
		end
		itemStackLabel:SetText(stack)
		
		bidMoneyDisplay:SetValue(value.amount * (value.unitBidPrice or 0))
		buyMoneyDisplay:SetValue(value.amount * (value.unitBuyoutPrice or 0))
	end
	
	function itemTexture.Event:MouseIn()
		CTooltip(itemType)
	end
	
	function itemTexture.Event:MouseOut()
		CTooltip(nil)
	end
	
	return queueManagerCell
end

function InternalInterface.UI.QueueManager(name, parent)
	local queueFrame = UICreateFrame("Frame", name, parent)

	local queuePanel = Panel(name .. ".QueueSizePanel", queueFrame)
	local queueSizeText = UICreateFrame("Text", queuePanel:GetName() .. ".QueueSizeText", queuePanel:GetContent())
	local clearButton = UICreateFrame("Texture", name .. ".ClearButton", queueFrame)
	local playButton = UICreateFrame("Texture", name .. ".PlayButton", queueFrame)
	
	local queueGrid = DataGrid(name .. ".QueueGrid", parent)
		
	local function UpdateQueue()
		local queue = GetPostingQueue()
		queueGrid:SetData(queue)
	end
		
	local function UpdateQueueStatus()
		local status, size = GetPostingQueueStatus()

		playButton:SetTextureAsync(addonID, GetPostingQueuePaused() and "Textures/Play.png" or "Textures/Pause.png")

		queueSizeText:SetText(tostring(size))
		
		if status == 1 then
			queueSizeText:SetFontColor(0, 0.75, 0.75, 1)
		elseif status == 3 then
			queueSizeText:SetFontColor(1, 0.5, 0, 1)
		else
			queueSizeText:SetFontColor(1, 1, 1, 1)
		end
	end
	
	playButton:SetPoint("CENTERLEFT", queueFrame, "CENTERLEFT")
	playButton:SetTextureAsync(addonID, "Textures/Pause.png")

	clearButton:SetPoint("CENTERLEFT", queueFrame, "CENTERLEFT", 30, 0)
	clearButton:SetTextureAsync(addonID, "Textures/Stop.png")

	queuePanel:SetPoint("CENTERLEFT", queueFrame, "CENTERLEFT", 60, 0)
	queuePanel:SetPoint("CENTERRIGHT", queueFrame, "CENTERRIGHT")
	queuePanel:SetHeight(30)
	queuePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
	
	queueSizeText:SetPoint("CENTER", queuePanel:GetContent(), "CENTER")
	
	queueGrid:SetPoint("BOTTOMLEFT", queueFrame, "TOPRIGHT", -290, 0)
	queueGrid:SetPoint("TOPRIGHT", queueFrame, "TOPRIGHT", 0, -400)
	queueGrid:SetLayer(9001)
	queueGrid:SetPadding(1, 1, 1, 1)
	queueGrid:SetHeadersVisible(false)
	queueGrid:SetRowHeight(62)
	queueGrid:SetRowMargin(2)
	queueGrid:SetUnselectedRowBackgroundColor({0.15, 0.2, 0.15, 1})
	queueGrid:SetSelectedRowBackgroundColor({0.45, 0.6, 0.45, 1})
	queueGrid:AddColumn("item", nil, QueueCellType, 248, 0, nil, "I DON'T CARE")
	queueGrid:SetVisible(false)

	function playButton.Event:LeftClick()
		SetPostingQueuePaused(not GetPostingQueuePaused())
	end	

	function clearButton.Event:LeftClick()
		if queueGrid:GetVisible() then
			local key = queueGrid:GetSelectedData()
			if key then
				CancelPostingByIndex(key)
			end
		else
			CancelAll()
		end
	end
	
	function queuePanel.Event:LeftClick()
		queueGrid:SetVisible(not queueGrid:GetVisible())
	end
	queuePanel.Event.RightClick = queuePanel.Event.LeftClick

	TInsert(Event.LibPGC.PostingQueueStatusChanged, { UpdateQueueStatus, addonID, addonID .. ".OnQueueStatusChanged" })
	UpdateQueueStatus()
	
	TInsert(Event.LibPGC.PostingQueueChanged, { UpdateQueue, addonID, addonID .. ".OnQueueChanged" })
	UpdateQueue()
	
	return queueFrame
end
