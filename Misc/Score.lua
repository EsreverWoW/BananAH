-- ***************************************************************************************************************************************************
-- * Misc/Score.lua                                                                                                                                  *
-- ***************************************************************************************************************************************************
-- * Score helper functions                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * 0.4.0 / 2012.06.17 / Baanano: Splitted from PricingModelService                                                                                 *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

InternalInterface.UI = InternalInterface.UI or {}

function InternalInterface.UI.ScoreColorByIndex(index)
	if not index or type(index) ~= "number" then return { 0.75, 0.5, 0.75 } end
	if index <= 1 then return { 0, 0.75, 0.75 }
	elseif index <= 2 then return { 0, 0.75, 0 }
	elseif index <= 3 then return { 0.75, 0.75, 0 }
	elseif index <= 4 then return { 0.75, 0.5, 0 }
	else return { 0.75, 0, 0 }
	end
	return { 0.75, 0.5, 0.75 }
end

function InternalInterface.UI.ScoreIndexByScore(score)
	local index = nil
	local limits = InternalInterface.AccountSettings.PriceScorers.Settings.colorLimits or { 85, 85, 115, 115 }
	if score then
		if score <= limits[1] then index = 1
		elseif score <= limits[2] then index = 2
		elseif score <= limits[3] then index = 3
		elseif score <= limits[4] then index = 4
		else index = 5
		end
	end
	return index
end

function InternalInterface.UI.ScoreColorByScore(score)
	return InternalInterface.UI.ScoreColorByIndex(InternalInterface.UI.ScoreIndexByScore(score))
end
