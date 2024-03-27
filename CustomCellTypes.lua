local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local function AuctionCachedCellType(name, parent)
	local cachedCell = UI.CreateFrame("Texture", name, parent)
	
	cachedCell:SetTextureAsync(addonID, "Textures/AuctionUnavailable.png")
	cachedCell:SetVisible(false)
	
	function cachedCell:SetValue(key, value, width, extra)
		self:SetVisible(not value.cached)
	end
	
	return cachedCell
end

local function ItemAuctionBackgroundCellType(name, parent)
	local backgroundCell = UI.CreateFrame("Frame", name, parent)
	
	function backgroundCell:SetValue(key, value, width, extra)
		self:ClearAll()
		self:SetAllPoints()
		self:SetLayer(self:GetParent():GetLayer() - 1)
		self:SetBackgroundColor(unpack(extra.Color(value)))
	end
	
	return backgroundCell
end

local function MoneyCellType(name, parent)
	local enclosingCell = UI.CreateFrame("Frame", name, parent)
	local moneyCell = Yague.MoneyDisplay(name .. ".MoneyDisplay", enclosingCell)

	moneyCell:SetPoint("CENTERLEFT", enclosingCell, "CENTERLEFT")
	moneyCell:SetPoint("CENTERRIGHT", enclosingCell, "CENTERRIGHT")
	
	function enclosingCell:SetValue(key, value, width, extra)
		moneyCell:SetValue(value)
	end
	
	return enclosingCell
end

local function WideBackgroundCellType(name, parent)
	local backgroundCell = UI.CreateFrame("Texture", name, parent)
	
	backgroundCell:SetTextureAsync(addonID, "Textures/AuctionRowBackground.png")
	
	function backgroundCell:SetValue(key, value, width, extra)
		self:ClearAll()
		self:SetAllPoints()
		self:SetLayer(-9999)
	end
	
	return backgroundCell
end

Yague.RegisterCellType("AuctionCachedCellType", AuctionCachedCellType)
Yague.RegisterCellType("ItemAuctionBackgroundCellType", ItemAuctionBackgroundCellType)
Yague.RegisterCellType("MoneyCellType", MoneyCellType)
Yague.RegisterCellType("WideBackgroundCellType", WideBackgroundCellType)
