local _, InternalInterface = ...

InternalInterface.Localization.RegisterLocale("English",--@do-not-package@
{
	-- General
	["General/fullScanStarted"] = "Scan started",
	["General/fullScanError"] = "Can't issue a full scan right now, try again later.",
	["General/slashRegisterError"] = "Failed to register slash commands",
	["General/scanMessage"] = "%s scan: %d total auctions%s%s%s.",
	["General/scanTypeFull"] = "Full",
	["General/scanTypePartial"] = "Partial",
	["General/scanNewCount"] = ", %d new",
	["General/scanUpdatedCount"] = ", %d updated",
	["General/scanRemovedCount"] = ", %d removed (%d before expiration)",

	-- Posting panel
	["PostingPanel/labelStackSize"] = "STACK SIZE",
	["PostingPanel/labelStackNumber"] = "NUMBER OF STACKS",
	["PostingPanel/labelUnitBid"] = "UNIT BID:",
	["PostingPanel/labelUnitBuy"] = "UNIT BUYOUT:",
	["PostingPanel/labelDuration"] = "DURATION:",
	["PostingPanel/labelDurationFormat"] = "%d hours",
	["PostingPanel/buttonUndercut"] = "Set to undercut",
	["PostingPanel/buttonPost"] = "Post",
	["PostingPanel/columnSeller"] = "Seller",
	["PostingPanel/columnStack"] = "Units",
	["PostingPanel/columnBid"] = "Bid",
	["PostingPanel/columnBuy"] = "Buyout",
	["PostingPanel/columnBidPerUnit"] = "Unit Bid",
	["PostingPanel/columnBuyPerUnit"] = "Unit Buyout",
	["PostingPanel/columnMinExpire"] = "Min. Expire",
	["PostingPanel/columnMaxExpire"] = "Max. Expire",
	["PostingPanel/lastUpdateMessage"] = "Last time seen on full scan: ",
	["PostingPanel/lastUpdateDateFormat"] = "%A %x, %X",
	["PostingPanel/lastUpdateDateFallback"] = "Never",
	["PostingPanel/buttonBid"] = "Bid",
	["PostingPanel/buttonBuy"] = "Buy",
	["PostingPanel/itemScanStarted"] = "Scan started",
	["PostingPanel/itemScanError"] = "Can't issue an item scan right now, try again later.",
}--@end-do-not-package@
--@localization(locale="enUS", format="lua_table", handle-subnamespaces="concat", namespace-delimiter="/")@
)

