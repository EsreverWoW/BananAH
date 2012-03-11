local _, InternalInterface = ...

InternalInterface.Localization.RegisterLocale("English",
{
	-- Posting panel
	["labelStackSize"] = "STACK SIZE",
	["labelStackNumber"] = "NUMBER OF STACKS",
	["labelUnitBid"] = "UNIT BID:",
	["labelUnitBuy"] = "UNIT BUYOUT:",
	["labelDuration"] = "DURATION:",
	["labelDurationFormat"] = "%d hours",
	["buttonUndercut"] = "Set to undercut",
	["buttonPost"] = "Post",

	-- Auctions panel
	["columnSeller"] = "Seller",
	["columnStack"] = "Units",
	["columnBid"] = "Bid",
	["columnBuy"] = "Buyout",
	["columnBidPerUnit"] = "Unit Bid",
	["columnBuyPerUnit"] = "Unit Buyout",
	["columnMinExpire"] = "Min. Expire",
	["columnMaxExpire"] = "Max. Expire",
	["lastUpdateMessage"] = "Last time seen on full scan: ",
	["lastUpdateDateFormat"] = "%A %x, %X",
	["lastUpdateDateFallback"] = "Never",
	["buttonBid"] = "Bid",
	["buttonBuy"] = "Buy",
	
	-- Messages
	["itemScanStarted"] = "Scan started",
	["itemScanError"] = "Can't issue an item scan right now, try again later.",
	["fullScanStarted"] = "Scan started",
	["fullScanError"] = "Can't issue a full scan right now, try again later.",
	["slashRegisterError"] = "Failed to register slash commands",
	
	["scanMessage"] = "%s scan: %d total auctions%s%s%s.",
	["scanTypeFull"] = "Full",
	["scanTypePartial"] = "Partial",
	["scanNewCount"] = ", %d new",
	["scanUpdatedCount"] = ", %d updated",
	["scanRemovedCount"] = ", %d removed (%d before expiration)",
})

