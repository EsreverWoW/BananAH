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
	["PostingPanel/labelItemStack"] = "You have %d available to auction",
	["PostingPanel/labelPricingModel"] = "PRICING MODEL:",
	["PostingPanel/checkPriceMatching"] = "Price matching",
	["PostingPanel/labelStackSize"] = "STACK SIZE:",
	["PostingPanel/labelStackNumber"] = "NUMBER OF STACKS:",
	["PostingPanel/labelUnitBid"] = "UNIT BID:",
	["PostingPanel/checkBindPrices"] = "Bind prices",
	["PostingPanel/labelUnitBuy"] = "UNIT BUYOUT:",
	["PostingPanel/buyWarningLowerSeller"] = "Unit Buyout < Seller",
	["PostingPanel/labelDuration"] = "DURATION:",
	["PostingPanel/labelDurationFormat"] = "%d hours",
	["PostingPanel/buttonUndercut"] = "Set to undercut",
	["PostingPanel/buttonPost"] = "Post",
	["PostingPanel/pricingModelError"] = "Using fallback pricing model...",
	["PostingPanel/postErrorBidHigherBuy"] = "Error: Bid price higher than buyout price.",
	
	["PostingPanel/checkShowHidden"] = "Show hidden",
	["PostingPanel/checkHideItem"] = "Hide this item",

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
	["PostingPanel/bidErrorNoAuction"] = "No auction selected",
	["PostingPanel/bidErrorNoAuctionHouse"] = "Not at the auction house",
	["PostingPanel/bidErrorBidEqualBuy"] = "Bid & Buyout prices are equal",
	["PostingPanel/bidErrorSeller"] = "You're the seller",
	["PostingPanel/bidErrorHighestBidder"] = "You're the highest bidder",
	["PostingPanel/bidErrorNotCached"] = "Need scan refresh",
	["PostingPanel/itemScanStarted"] = "Scan started",
	["PostingPanel/itemScanError"] = "Can't issue an item scan right now, try again later.",
	
	["PostingPanel/labelPostingQueueStatus"] = "Queue status:",
	["PostingPanel/labelPostingQueueStatus0"] = "Busy",
	["PostingPanel/labelPostingQueueStatus1"] = "Paused",
	["PostingPanel/labelPostingQueueStatus2"] = "Empty",
	["PostingPanel/labelPostingQueueStatus3"] = "Req. Auction House",
	["PostingPanel/labelPostingQueueStatus4"] = "Waiting",
	["PostingPanel/buttonShowQueue"] = "Show",
	["PostingPanel/buttonHideQueue"] = "Hide",
	["PostingPanel/buttonPauseQueue"] = "Pause",
	["PostingPanel/buttonResumeQueue"] = "Resume",
	["PostingPanel/buttonCancelQueueAll"] = "Clear",
	["PostingPanel/buttonCancelQueueSelected"] = "Cancel",
	
	-- Bundled Pricing Models
	["PricingModel/fallbackName"] = "Vendor",
	["PricingModel/fixedName"] = "User defined",
	["PricingModel/meanName"] = "Average",
	["PricingModel/meanError"] = "Not enough data",
	["PricingModel/stdevName"] = "Standard deviation",
	["PricingModel/stdevError"] = "Not enough data",
	["PricingModel/medianName"] = "Median",
	["PricingModel/medianError"] = "Not enough data",
	["PricingModel/interPercentileRangeName"] = "IPR",
	["PricingModel/interPercentileRangeError"] = "Not enough data",
}--@end-do-not-package@
--@localization(locale="enUS", format="lua_table", handle-subnamespaces="concat", namespace-delimiter="/")@
)

