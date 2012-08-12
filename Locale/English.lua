local _, InternalInterface = ...

InternalInterface.Localization.RegisterLocale("English",--@do-not-package@
{
	-- General
	["General/CompetitionName1"] = "Weak",
	["General/CompetitionName2"] = "Moderate",
	["General/CompetitionName3"] = "Intense",
	["General/CompetitionName4"] = "Strong",
	["General/CompetitionName5"] = "Fierce",
	
	["General/ScoreName0"] = "No score",
	["General/ScoreName1"] = "Very low",
	["General/ScoreName2"] = "Low",
	["General/ScoreName3"] = "Medium",
	["General/ScoreName4"] = "High",
	["General/ScoreName5"] = "Very high",
	
	["General/CallingAll"] = "All",
	["General/CallingWarrior"] = "Warrior",
	["General/CallingCleric"] = "Cleric",
	["General/CallingRogue"] = "Rogue",
	["General/CallingMage"] = "Mage",
	
	["General/Rarity1"] = "Sellable",
	["General/Rarity2"] = "Common",
	["General/Rarity3"] = "Uncommon",
	["General/Rarity4"] = "Rare",
	["General/Rarity5"] = "Epic",
	["General/Rarity6"] = "Relic",
	["General/Rarity7"] = "Transcendant",
	["General/RarityQuest"] = "Quest",	

	-- Main window
	["Main/MenuSearch"] = "SEARCH",
	["Main/MenuPost"] = "POST",
	["Main/MenuAuctions"] = "SELLING",
	["Main/MenuBids"] = "TRACKING",
	["Main/MenuHistory"] = "HISTORY",
	["Main/MenuConfig"] = "CONFIG",
	
	["Main/ScanMessage"] = "Scan results: %d total auctions%s%s%s.",
	["Main/ScanNewCount"] = ", %d new",
	["Main/ScanUpdatedCount"] = ", %d updated",
	["Main/ScanRemovedCount"] = ", %d removed (%d before expiration)",
	
	["Main/FullScanStarted"] = "Full scan started...",
	["Main/FullScanError"] = "Can't issue a full scan right now, try again later.",
	["Main/SlashRegisterError"] = "Failed to register slash commands.",
	
	-- Item Auctions Grid
	["ItemAuctionsGrid/ButtonBuy"] = "Buy",
	["ItemAuctionsGrid/ButtonBid"] = "Bid",
	["ItemAuctionsGrid/ColumnSeller"] = "Seller",
	["ItemAuctionsGrid/ColumnStack"] = "Units",
	["ItemAuctionsGrid/ColumnBid"] = "Bid",
	["ItemAuctionsGrid/ColumnBuy"] = "Buyout",
	["ItemAuctionsGrid/ColumnBidPerUnit"] = "Unit Bid",
	["ItemAuctionsGrid/ColumnBuyPerUnit"] = "Unit Buyout",
	["ItemAuctionsGrid/ColumnMinExpire"] = "Min. Expire",
	["ItemAuctionsGrid/ColumnMaxExpire"] = "Max. Expire",
	["ItemAuctionsGrid/ColumnScore"] = "Score",
	["ItemAuctionsGrid/ErrorNoAuction"] = "No auction selected",
	["ItemAuctionsGrid/ErrorNoAuctionHouse"] = "Not at the auction house",
	["ItemAuctionsGrid/ErrorBidEqualBuy"] = "Bid & Buyout prices are equal",
	["ItemAuctionsGrid/ErrorSeller"] = "You're the seller",
	["ItemAuctionsGrid/ErrorHighestBidder"] = "You're the highest bidder",
	["ItemAuctionsGrid/ErrorNotCached"] = "Need scan refresh",
	["ItemAuctionsGrid/LastUpdateMessage"] = "Last time seen: %s",
	["ItemAuctionsGrid/LastUpdateDateFormat"] = "%A %x, %X",
	["ItemAuctionsGrid/LastUpdateDateFallback"] = "Never",
	["ItemAuctionsGrid/ItemScanError"] = "Item scan started...",
	["ItemAuctionsGrid/ItemScanStarted"] = "Can't issue an item scan right now, try again later.",
	
	-- Post frame
	["PostFrame/ButtonPost"] = "Post",
	["PostFrame/ButtonReset"] = "Reset",
	["PostFrame/CheckPriceMatching"] = "Match prices",
	["PostFrame/CheckBindPrices"] = "Bind prices",
	["PostFrame/CheckStackLimit"] = "Including active ones",
	["PostFrame/LabelItemStack"] = "You have %d available to auction",
	["PostFrame/LabelPricingModel"] = "PRICING MODEL:",
	["PostFrame/LabelStackSize"] = "STACK SIZE:",
	["PostFrame/LabelStackNumber"] = "AUCTIONS:",
	["PostFrame/LabelUnitBid"] = "UNIT BID:",
	["PostFrame/LabelUnitBuy"] = "UNIT BUYOUT:",
	["PostFrame/LabelDuration"] = "DURATION:",
	["PostFrame/LabelDurationFormat"] = "%d hours",
	
	-- Selling frame
	["SellingFrame/ColumnItem"] = "Item",
	["SellingFrame/ColumnMinExpire"] = "Min. Expire",
	["SellingFrame/ColumnMaxExpire"] = "Max. Expire",
	["SellingFrame/ColumnBid"] = "Bid",
	["SellingFrame/ColumnBuy"] = "Buyout",
	["SellingFrame/ColumnBidPerUnit"] = "Unit Bid",
	["SellingFrame/ColumnBuyPerUnit"] = "Unit Buyout",	
	["SellingFrame/ColumnScore"] = "Score",
	["SellingFrame/ColumnCompetition"] = "Competition",
	["SellingFrame/FilterSeller"] = "Show only auctions posted by this character",
	["SellingFrame/FilterCompetition"] = "Min. Competition:",
	["SellingFrame/FilterBelow"] = "Min. Below:",
	["SellingFrame/FilterScore"] = "SCORE FILTER",
	["SellingFrame/WarningCancel"] = "To avoid cancelling auctions by accident, you need to right click on the button to cancel the auction. You can change this behavior in the Config tab.",

	-- Misc
	["Misc/DateMonthAbbreviatedNames"] = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec",
	["Misc/DateMonthNames"] = "January,February,March,April,May,June,July,August,September,October,November,December",
	["Misc/DateWeekdayAbbreviatedNames"] = "Sun,Mon,Tue,Wed,Thu,Fri,Sat",
	["Misc/DateWeekdayNames"] = "Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday",
	["Misc/RemainingTimeHours"] = "%d h %d m",
	["Misc/RemainingTimeMinutes"] = "%d m %d s",
	["Misc/RemainingTimeSeconds"] = "%d s",
	["Misc/StackSizeMax"] = "Max",
	["Misc/StacksFull"] = "Full",
	["Misc/StacksAll"] = "All",
	
	-- Default price models
	["PriceModels/Fixed"] = "User defined",
	["PriceModels/Vendor"] = "Vendor",
	["PriceModels/Average"] = "Average",
	["PriceModels/Median"] = "Median",
	["PriceModels/StandardDeviation"] = "Standard deviation",
	["PriceModels/TrimmedMean"] = "Trimmed average",
	["PriceModels/Market"] = "Market price",
}--@end-do-not-package@
--@localization(locale="enUS", format="lua_table", handle-subnamespaces="concat", namespace-delimiter="/")@
)

