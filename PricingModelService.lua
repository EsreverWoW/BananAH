
-- Pricing Model Services
local PricingModelAddedEvent = Utility.Event.Create("BananAH", "PricingModelAdded")
local PricingModelRemovedEvent = Utility.Event.Create("BananAH", "PricingModelRemoved")

local pricingModels = pricingModels or {}

local function GetPricingModels()
	return pricingModels -- FIXME RETURN COPY!!!
end

local function RegisterPricingModel(id, displayName, pricingFunction, callbackOnPost)
	if not pricingModels[id] then
		pricingModels[id] = { pricingModelId = id, displayName = displayName, pricingFunction = pricingFunction, callbackOnPost = callbackOnPost }
		PricingModelAddedEvent(id, displayName, pricingFunction)
		return true
	end
	return false
end

local function UnregisterPricingModel(id)
	if pricingModels[id] then
		pricingModels[id] = nil
		PricingModelRemovedEvent(id)
		return false
	end
	return false
end

_G.BananAH.GetPricingModels = GetPricingModels
_G.BananAH.RegisterPricingModel = RegisterPricingModel
_G.BananAH.UnregisterPricingModel = UnregisterPricingModel

