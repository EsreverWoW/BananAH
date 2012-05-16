--[[
	Sample.lua - Sample pricing model
	2012.05.16 Baanano (BananAH 0.3.0): First version of this file
	
	Pricing models are used by BananAH to estimate bid & buyout prices for items.
	
	Every addon loaded after BananAH can register a pricing model as a module and it will be used by the addon.
	
	This sample aims to explain how to write a simple pricing model so other authors know how to start when writing their own pricing models.
	
]]

--[[
	Function: SamplePricingModel
	Parameters:
		- (string)  item:     The ItemID or ItemTypeID of the item whose price needs to be estimated
		- (table)   auctions: All auctions (active & finished) stored in the addon DB	related to that item
		- (boolean) autoMode: Whether the pricing model is being called for auto-posting or not
	Returns:
		- (number | nil) bid: The recommended starting bid price for the item (in silver coins), or nil if the pricing model can't estimate one
		- (number | nil) buy: The recommended buyout price for the item (in silver coins), or nil if the pricing model can't estimate one
	Description:
		This function is called whenever the addon needs to estimate a price for an item, and is expected to return the
		recommended bid & buyout prices for it
	Note:
		The 'auctions' table is shared by all pricing models and they can be called in any order, so please don't modify it
		or you might cause unexpected behavior in other pricing models.
]]	
local function SamplePricingModel(item, auctions, autoMode)
	-- We'll keep simple this sample and just return a fixed value (1 platinum)
	return 10000, 10000
end

--[[
	Function: SampleCallback
	Parameters:
		- (string)  itemType: The ItemTypeID of the item
		- (number)  bid:      The starting bid price used to post the item
		- (number)  buyout:   The buyout price used to post the item
		- (boolean) auto:     Whether the pricing model has been used for auto-posting or not
	Returns:
		- None
	Description:
		This function is called when the pricing model is used to post an item, so it can keep track of the prices it
		has used in the past.
]]	
local function SampleCallback(itemType, bid, buyout, auto)
	-- We won't do anything with this callback
end

--[[
	Function: SampleConfigFrame
	Parameters:
		- (Frame) parent: The parent frame to which attach the pricing model config frame
	Returns:
		- (Frame) configFrame: The config frame of the pricing model
	Description:
		This function is called by BananAH to get the config frame it'll display for the pricing model under the
		Config tab of the addon.
	Note:
		BananAH currently (version 0.3.0) doesn't add config frames for external pricing models, but is planned to do
		it in the future.
		It's a good idea to create the config frame only the first time this function is called, and then return that same
		copy, to avoid having multiple copies of it in memory.
]]	
local function SampleConfigFrame(parent)
	-- We won't have any config frame for this pricing model
	return nil
end

--[[
	To register the pricing model in BananAH so it's used when estimating prices, you need to use this method:
	
	BananAH.RegisterPricingModel("pricing_model_identifier_used_internally", "Name To Display To The Player", PricingModelPriceFunction, PricingModelCallbackFunction, PricingModelConfigFrameFunction)
]]
BananAH.RegisterPricingModel("samplepricingmodel", "Sample", SamplePricingModel, SampleCallback, SampleConfigFrame)
