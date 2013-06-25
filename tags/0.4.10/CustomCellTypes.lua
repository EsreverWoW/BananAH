local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local MoneyDisplay = Yague.MoneyDisplay
local RegisterCellType = Yague.RegisterCellType
local UICreateFrame = UI.CreateFrame

local function AuctionCachedCellType(name, parent)
	local cachedCell = UICreateFrame("Texture", name, parent)
	
	cachedCell:SetTextureAsync(addonID, "Textures/AuctionUnavailable.png")
	cachedCell:SetVisible(false)
	
	function cachedCell:SetValue(key, value, width, extra)
		self:SetVisible(not LibPGC.GetAuctionCached(key))
	end
	
	return cachedCell
end

local function ItemAuctionBackgroundCellType(name, parent)
	local backgroundCell = UICreateFrame("Frame", name, parent)
	
	function backgroundCell:SetValue(key, value, width, extra)
		self:ClearAll()
		self:SetAllPoints()
		self:SetLayer(self:GetParent():GetLayer() - 1)
		self:SetBackgroundColor(unpack(extra.Color(value)))
	end
	
	return backgroundCell
end

local function MoneyCellType(name, parent)
	local enclosingCell = UICreateFrame("Frame", name, parent)
	local moneyCell = MoneyDisplay(name .. ".MoneyDisplay", enclosingCell)

	moneyCell:SetPoint("CENTERLEFT", enclosingCell, "CENTERLEFT")
	moneyCell:SetPoint("CENTERRIGHT", enclosingCell, "CENTERRIGHT")
	
	function enclosingCell:SetValue(key, value, width, extra)
		moneyCell:SetValue(value)
	end
	
	return enclosingCell
end

local function WideBackgroundCellType(name, parent)
	local backgroundCell = UICreateFrame("Texture", name, parent)
	
	backgroundCell:SetTextureAsync(addonID, "Textures/AuctionRowBackground.png")
	
	function backgroundCell:SetValue(key, value, width, extra)
		self:ClearAll()
		self:SetAllPoints()
		self:SetLayer(-9999)
	end
	
	return backgroundCell
end

RegisterCellType("AuctionCachedCellType", AuctionCachedCellType)
RegisterCellType("ItemAuctionBackgroundCellType", ItemAuctionBackgroundCellType)
RegisterCellType("MoneyCellType", MoneyCellType)
RegisterCellType("WideBackgroundCellType", WideBackgroundCellType)
