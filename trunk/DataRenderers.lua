local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local UICreateFrame = UI.CreateFrame

local RegisterGridRenderer = Library.LibBInterface.RegisterGridRenderer

-- MoneyRenderer
local function MoneyRenderer(name, parent)
	local renderCell = UICreateFrame("Frame", name, parent)
	local moneyCell = UICreateFrame("BMoneyDisplay", name .. ".MoneyDisplay", renderCell)

	moneyCell:SetPoint("CENTERLEFT", renderCell, "CENTERLEFT")
	moneyCell:SetPoint("CENTERRIGHT", renderCell, "CENTERRIGHT")
	moneyCell:SetHeight(20)
	renderCell.moneyCell = moneyCell
	
	function renderCell:SetValue(key, value, width, extra)
		self:SetWidth(width)
		moneyCell:SetValue(value)
	end
	
	return renderCell
end

-- AuctionRenderer
local function AuctionRenderer(name, parent)
	local auctionCell = UICreateFrame("Frame", name, parent)
	
	function auctionCell:SetValue(key, value, width, extra)
		self:ClearAll()
		self:SetAllPoints()
		self:SetLayer(self:GetParent():GetLayer() - 1)
		self:SetBackgroundColor(unpack(extra.Color(value)))
	end
	
	return auctionCell
end

-- AuctionCachedRenderer
local function AuctionCachedRenderer(name, parent)
	local cachedCell = UICreateFrame("Texture", name, parent)
	
	cachedCell:SetTexture(addonID, "Textures/AuctionUnavailable.png")
	cachedCell:SetVisible(false)
	
	function cachedCell:SetValue(key, value, width, extra)
		self:SetVisible(not _G[addonID].GetAuctionCached(key))
	end
	
	return cachedCell
end

RegisterGridRenderer("MoneyRenderer", MoneyRenderer)
RegisterGridRenderer("AuctionRenderer", AuctionRenderer)
RegisterGridRenderer("AuctionCachedRenderer", AuctionCachedRenderer)
