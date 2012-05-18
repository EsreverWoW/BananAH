local _, InternalInterface = ...

InternalInterface.Localization.RegisterLocale("English",--@do-not-package@
{
	-- Meta
	["Meta/weekdayNames"] = "Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday",
	["Meta/weekdayAbbreviatedNames"] = "Sun,Mon,Tue,Wed,Thu,Fri,Sat",
	["Meta/monthNames"] = "January,February,March,April,May,June,July,August,September,October,November,December",
	["Meta/monthAbbreviatedNames"] = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec",

	-- General
	["General/menuSearch"] = "SEARCH",
	["General/menuPost"] = "POST",
	["General/menuAuctions"] = "AUCTIONS",
	["General/menuBids"] = "BIDS",
	["General/menuHistory"] = "HISTORY",
	["General/menuConfig"] = "CONFIG",
	
	["General/fullScanStarted"] = "Scan started",
	["General/fullScanError"] = "Can't issue a full scan right now, try again later.",
	["General/slashRegisterError"] = "Failed to register slash commands",

	["General/scanMessage"] = "%s scan: %d total auctions%s%s%s.",
	["General/scanTypeFull"] = "Full",
	["General/scanTypePartial"] = "Partial",
	["General/scanNewCount"] = ", %d new",
	["General/scanUpdatedCount"] = ", %d updated",
	["General/scanRemovedCount"] = ", %d removed (%d before expiration)",

	["General/Rarity1"] = "Sellable", -- NEW
	["General/Rarity2"] = "Common", -- NEW
	["General/Rarity3"] = "Uncommon", -- NEW
	["General/Rarity4"] = "Rare", -- NEW
	["General/Rarity5"] = "Epic", -- NEW
	["General/Rarity6"] = "Relic", -- NEW
	["General/Rarity7"] = "Transcendant", -- NEW
	["General/Rarity0"] = "Quest", -- NEW
	
	["General/ScoreName0"] = "No score", -- NEW
	["General/ScoreName1"] = "Very low", -- NEW
	["General/ScoreName2"] = "Low", -- NEW
	["General/ScoreName3"] = "Medium", -- NEW
	["General/ScoreName4"] = "High", -- NEW
	["General/ScoreName5"] = "Very high", -- NEW

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
	["PostingPanel/buttonAutoPostingSave"] = "Save",
	["PostingPanel/buttonAutoPostingClear"] = "Clear",
	["PostingPanel/buttonAutoPostingMode"] = "Auto post",
	["PostingPanel/autoPostingErrorNoItems"] = "You don't have any item configured for auto posting. To enter auto posting configuration mode, right click on this button and configure them. To return to normal posting mode, right click on this button again.",
	["PostingPanel/autoPostingErrorPricingModelNotFound"] = "Pricing model for %s not found.",
	--["PostingPanel/autoPostingErrorPricingModelFailed"] = "Pricing model for %s failed.", -- UNUSED
	
	["PostingPanel/autoPostingOnLabel"] = "Auto posting enabled",
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
	["PostingPanel/lastUpdateMessage"] = "Last time seen: ", -- CHANGED
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
	
	["PostingPanel/InfoStacks"] = "Stacks:", -- NEW
	["PostingPanel/InfoTotalBid"] = "Total bid:", -- NEW
	["PostingPanel/InfoTotalBuy"] = "Total buyout:", -- NEW
	["PostingPanel/InfoDeposit"] = "Deposit:", -- NEW
	["PostingPanel/InfoDiscountBid"] = "Adjusted bid:", -- NEW
	["PostingPanel/InfoDiscountBuy"] = "Adjusted buyout:", -- NEW
	
	-- Auctions panel
	["AuctionsPanel/CancelWarning"] = "To avoid cancelling auctions by accident, you need to right click on the button to cancel the auction. You can change this behavior in the Config tab.", -- NEW
	["AuctionsPanel/CompetitionName1"] = "Weak", -- NEW
	["AuctionsPanel/CompetitionName2"] = "Moderate", -- NEW
	["AuctionsPanel/CompetitionName3"] = "Intense", -- NEW
	["AuctionsPanel/CompetitionName4"] = "Strong", -- NEW
	["AuctionsPanel/CompetitionName5"] = "Fierce", -- NEW
	["AuctionsPanel/columnItem"] = "Item", -- NEW
	["AuctionsPanel/columnScore"] = "Score", -- NEW
	["AuctionsPanel/columnCompetition"] = "Competition", -- NEW
	["AuctionsPanel/SellerFilter"] = "Show only auctions posted by this character", -- NEW
	["AuctionsPanel/CompetitionFilter"] = "Min. Competition:", -- NEW
	["AuctionsPanel/BelowFilter"] = "Min. Below:", -- NEW
	["AuctionsPanel/ScoreFilter"] = "SCORE FILTER", -- NEW
	
	-- Bundled Pricing Models
	["PricingModel/fallbackName"] = "Vendor",
	["PricingModel/fallbackBidMultiplier"] = "Bid multiplier:",
	["PricingModel/fallbackBuyMultiplier"] = "Buyout multiplier:",
	["PricingModel/fixedName"] = "User defined",
	["PricingModel/meanName"] = "Average",
	["PricingModel/meanWeight"] = "Weight auctions by stack size",
	["PricingModel/meanDays"] = "Number of days:",
	--["PricingModel/meanError"] = "Not enough data", -- UNUSED
	["PricingModel/stdevName"] = "Standard deviation",
	["PricingModel/stdevWeight"] = "Weight auctions by stack size",
	["PricingModel/stdevDays"] = "Number of days:",
	["PricingModel/stdevDeviation"] = "Max percentage away from standard deviation:",
	--["PricingModel/stdevError"] = "Not enough data", -- UNUSED
	["PricingModel/medianName"] = "Median",
	["PricingModel/medianWeight"] = "Weight auctions by stack size",
	["PricingModel/medianDays"] = "Number of days:",
	--["PricingModel/medianError"] = "Not enough data", -- UNUSED
	["PricingModel/interPercentileRangeName"] = "Trimmed mean",
	["PricingModel/interPercentileRangeWeight"] = "Weight auctions by stack size",
	["PricingModel/interPercentileRangeDays"] = "Number of days:",
	["PricingModel/interPercentileRangeRange"] = "Inner range:",
	--["PricingModel/interPercentileRangeError"] = "Not enough data", -- UNUSED
	
	-- Bundled Price Scorers
	["PriceScorer/marketName"] = "Market price", -- NEW
	["PriceScorer/marketWeights"] = "Pricing model weights", -- NEW
	
	-- Bundled Price Matchers
	["PriceMatcher/undercutName"] = "Competition undercut", -- NEW
	["PriceMatcher/undercutRange"] = "Competition undercut range:", -- MOVED
	["PriceMatcher/selfName"] = "Self matcher", -- NEW
	["PriceMatcher/selfRange"] = "Self match range:", -- MOVED
	["PriceMatcher/vendorName"] = "Vendor minimum", -- NEW
	["PriceMatcher/vendorEnable"] = "Enable", -- NEW
	
	-- Configuration
	["ConfigPanel/categoryGeneral"] = "General",
	["ConfigPanel/categoryPosting"] = "Posting",
	["ConfigPanel/subcategoryPostingSettings"] = "Default settings",
	["ConfigPanel/categoryAuctions"] = "Auctions", -- NEW
	["ConfigPanel/subcategoryScoreSettings"] = "Score settings", -- NEW 
	["ConfigPanel/categoryPricingModels"] = "Pricing models",
	["ConfigPanel/categoryPriceScorers"] = "Price scorers", -- NEW
	["ConfigPanel/categoryPriceMatchers"] = "Price matchers",
	
	["ConfigPanel/mapIconShow"] = "Show map icon",
	["ConfigPanel/autoOpenWindow"] = "Open the addon window when the native Auction House window is opened",
	["ConfigPanel/autoCloseWindow"] = "Close the addon window when the native Auction House window is closed", -- NEW
	["ConfigPanel/DisableScanner"] = "Disable background scanner at start", -- NEW
	
	["ConfigPanel/RarityFilter"] = "Minimum rarity filter:", -- NEW
	["ConfigPanel/defaultPausedPostingQueue"] = "Start the posting queue in paused state",
	--["ConfigPanel/defaultPostingPricingModel"] = "Default pricing model:", -- UNUSED
	["ConfigPanel/defaultPriceMatching"] = "Activate price matching for unconfigured items", -- CHANGED
	["ConfigPanel/defaultBindPrices"] = "Bind bid & buyout prices for unconfigured items", -- CHANGED
	["ConfigPanel/defaultDuration"] = "Default duration:",
	["ConfigPanel/DefaultPricingModelOrder"] = "Default pricing model order", -- NEW
	["ConfigPanel/DefaultPriceMatcherOrder"] = "Price matchers order", -- NEW
	
	["ConfigPanel/AuctionLeftCancel"] = "Allow left-click auction cancel", -- NEW
	["ConfigPanel/AuctionSellerFilterDefault"] = "Show only auctions posted by this character by default", -- NEW
	["ConfigPanel/AuctionCompetitionFilterDefault"] = "Default Min. Competition:", -- NEW
	["ConfigPanel/AuctionBelowFilterDefault"] = "Default Min. Below:", -- NEW
	["ConfigPanel/AuctionScoreFilterDefault"] = "Default scores:", -- NEW
	["ConfigPanel/DefaultPriceScorer"] = "Default price scorer:", -- NEW
}--@end-do-not-package@
--@localization(locale="enUS", format="lua_table", handle-subnamespaces="concat", namespace-delimiter="/")@
)

