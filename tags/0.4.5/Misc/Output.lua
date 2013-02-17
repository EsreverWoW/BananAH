-- ***************************************************************************************************************************************************
-- * Misc/Output.lua                                                                                                                                 *
-- ***************************************************************************************************************************************************
-- * Allows to redirect addon output to destinations other than the chat console                                                                     *
-- ***************************************************************************************************************************************************
-- * 0.4.0  / 2012.05.30 / Baanano: First version, splitted out of the old Init.lua                                                                  *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local outputFunction = print
local popupManager = nil
InternalInterface.Output = InternalInterface.Output or {}

-- ***************************************************************************************************************************************************
-- * GetOutputFunction                                                                                                                               *
-- ***************************************************************************************************************************************************
-- * Returns the current output function                                                                                                             *
-- ***************************************************************************************************************************************************
function InternalInterface.Output.GetOutputFunction()
	return outputFunction
end

-- ***************************************************************************************************************************************************
-- * SetOutputFunction                                                                                                                               *
-- ***************************************************************************************************************************************************
-- * Changes the output function                                                                                                                     *
-- ***************************************************************************************************************************************************
function InternalInterface.Output.SetOutputFunction(func)
	outputFunction = func
end

-- ***************************************************************************************************************************************************
-- * Write                                                                                                                                           *
-- ***************************************************************************************************************************************************
-- * Writes a string to the current output function                                                                                                  *
-- ***************************************************************************************************************************************************
function InternalInterface.Output.Write(text)
	outputFunction(text)
end

-- ***************************************************************************************************************************************************
-- * GetPopupManager                                                                                                                                 *
-- ***************************************************************************************************************************************************
-- * Returns the current popup manager                                                                                                               *
-- ***************************************************************************************************************************************************
function InternalInterface.Output.GetPopupManager()
	return popupManager
end

-- ***************************************************************************************************************************************************
-- * SetPopupManager                                                                                                                                 *
-- ***************************************************************************************************************************************************
-- * Changes the popup manager                                                                                                                       *
-- ***************************************************************************************************************************************************
function InternalInterface.Output.SetPopupManager(manager)
	popupManager = manager
end
