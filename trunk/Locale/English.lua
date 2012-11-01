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
	
	["General/ModelTypeSimple"] = "Simple",
	["General/ModelTypeStatistical"] = "Statistical",
	["General/ModelTypeComplex"] = "Complex",
	["General/ModelTypeComposite"] = "Composite",

	-- Main window
	["Main/MenuSearch"] = "SEARCH",
	["Main/MenuPost"] = "POST",
	["Main/MenuAuctions"] = "SELLING",
	["Main/MenuBids"] = "TRACKING",
	["Main/MenuHistory"] = "HISTORY",
	["Main/MenuConfig"] = "CONFIG",
	["Main/MenuFullScan"] = "FULL SCAN",
	
	["Main/ScanMessage"] = "Scan results: %d total auctions%s%s%s.",
	["Main/ScanNewCount"] = ", %d new",
	["Main/ScanUpdatedCount"] = ", %d updated",
	["Main/ScanRemovedCount"] = ", %d removed (%d before expiration)",
	
	["Main/FullScanStarted"] = "Full scan started...",
	["Main/FullScanError"] = "Can't issue a full scan right now, try again later.",
	["Main/SlashRegisterError"] = "Failed to register slash commands.",
	
	-- Save Search Popup
	["SaveSearchPopup/Title"] = "SAVE SEARCH",
	["SaveSearchPopup/NameText"] = "Saved search name:",
	["SaveSearchPopup/DefaultName"] = "Saved %x %X",
	["SaveSearchPopup/ButtonSave"] = "Save",
	["SaveSearchPopup/ButtonCancel"] = "Cancel",
	
	-- Cancel Auction Popup
	["CancelAuctionPopup/Title"] = "CANCEL AUCTION",
	["CancelAuctionPopup/ContentText"] = "Are you sure you want to cancel this auction?",
	["CancelAuctionPopup/ButtonYes"] = "Yes",
	["CancelAuctionPopup/ButtonNo"] = "No",
	["CancelAuctionPopup/IgnoreText"] = "Don't ask again",
	
	-- Unsaved Changes Popup
	["UnsavedChangesPopup/Title"] = "WARNING",
	["UnsavedChangesPopup/ContentText"] = "You have unsaved changes. If you continue, they'll be lost.",
	["UnsavedChangesPopup/ButtonContinue"] = "Continue",
	["UnsavedChangesPopup/ButtonCancel"] = "Cancel",

	-- New Model Popup
	["NewModelPopup/Title"] = "NEW MODEL",
	["NewModelPopup/ModelType"] = "Model Type:",
	["NewModelPopup/ButtonContinue"] = "Continue",
	["NewModelPopup/ButtonCancel"] = "Cancel",
	
	-- Matcher Popup Frame
	["MatcherPopupFrame/Title"] = "Price Matchers",
	["MatcherPopupFrame/ButtonAdd"] = "Add",
	
	-- Filter Popup Frame
	["FilterPopupFrame/Title"] = "Filters",
	["FilterPopupFrame/ButtonAdd"] = "Add",
	
	-- Simple Model Popup
	["SimpleModelPopup/Name"] = "Name:",
	["SimpleModelPopup/ButtonSave"] = "Save",
	["SimpleModelPopup/ButtonCancel"] = "Cancel",
	
	-- Statistical Model Popup
	["StatisticalModelPopup/Name"] = "Name:",
	["StatisticalModelPopup/ButtonSave"] = "Save",
	["StatisticalModelPopup/ButtonCancel"] = "Cancel",
	
	-- Complex Model Popup
	["ComplexModelPopup/Name"] = "Name:",
	["ComplexModelPopup/ButtonSave"] = "Save",
	["ComplexModelPopup/ButtonCancel"] = "Cancel",
	
	-- Composite Model Popup
	["CompositeModelPopup/Name"] = "Name:",
	["CompositeModelPopup/ButtonAdd"] = "Add",
	["CompositeModelPopup/ButtonSave"] = "Save",
	["CompositeModelPopup/ButtonCancel"] = "Cancel",
	
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
	
	-- Search frame
	["SearchFrame/ButtonReset"] = "Reset",
	["SearchFrame/ButtonSearch"] = "Search",
	["SearchFrame/ButtonTrack"] = "Track auction",
	["SearchFrame/ButtonBuy"] = "Buy",
	["SearchFrame/ButtonBid"] = "Bid",
	["SearchFrame/ColumnItem"] = "Item",
	["SearchFrame/ColumnSeller"] = "Seller",
	["SearchFrame/ColumnMinExpire"] = "Min. expire",
	["SearchFrame/ColumnMaxExpire"] = "Max. expire",
	["SearchFrame/ColumnBid"] = "Bid",
	["SearchFrame/ColumnBuy"] = "Buyout",
	["SearchFrame/ColumnBidPerUnit"] = "Unit Bid",
	["SearchFrame/ColumnBuyPerUnit"] = "Unit Buyout",
	["SearchFrame/ColumnScore"] = "Score",
	["SearchFrame/ErrorNoAuction"] = "No auction selected",
	["SearchFrame/ErrorNoAuctionHouse"] = "Not at the auction house",
	["SearchFrame/ErrorBidEqualBuy"] = "Bid & Buyout prices are equal",
	["SearchFrame/ErrorSeller"] = "You're the seller",
	["SearchFrame/ErrorHighestBidder"] = "You're the highest bidder",
	["SearchFrame/ErrorNotCached"] = "Need scan refresh",
	
	-- Post frame
	["PostFrame/ButtonPost"] = "Post",
	["PostFrame/ButtonReset"] = "Reset",
	["PostFrame/CheckPriceMatching"] = "Apply matching rules",
	["PostFrame/CheckBindPrices"] = "Bind prices",
	["PostFrame/CheckStackLimit"] = "Including active ones",
	["PostFrame/LabelItemStack"] = "You have %d available to auction",
	["PostFrame/LabelPricingModel"] = "REFERENCE PRICE:",
	["PostFrame/LabelStackSize"] = "STACK SIZE:",
	["PostFrame/LabelStackNumber"] = "AUCTIONS:",
	["PostFrame/LabelUnitBid"] = "UNIT BID:",
	["PostFrame/LabelUnitBuy"] = "UNIT BUYOUT:",
	["PostFrame/LabelDuration"] = "DURATION:",
	["PostFrame/ErrorPostBase"] = "Couldn't post the item: %s.",
	["PostFrame/ErrorPostStackSize"] = "Invalid stack size",
	["PostFrame/ErrorPostStackNumber"] = "No stacks to post",
	["PostFrame/ErrorPostBidPrice"] = "No bid price",
	["PostFrame/ErrorPostBuyPrice"] = "Buy price less than bid price",
	["PostFrame/ErrorAutoPostModelMissing"] = "Auto post disabled: Reference price unavailable",
	
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
	
	-- Config frame
	["ConfigFrame/CategoryGeneral"] = "GENERAL",
	["ConfigFrame/CategorySearch"] = "SEARCH",
	["ConfigFrame/CategoryPost"] = "POST",
	["ConfigFrame/CategorySelling"] = "SELLING",
	["ConfigFrame/CategoryTracking"] = "TRACKING",
	["ConfigFrame/CategoryHistory"] = "HISTORY",
	["ConfigFrame/CategoryPricing"] = "PRICES",
	["ConfigFrame/CategoryScoring"] = "SCORE",
	
	["ConfigGeneral/MapIconShow"] = "Show map icon (ignored if using Docker)",
	["ConfigGeneral/AutoOpenWindow"] = "Open the addon window when the native Auction House window is opened",
	["ConfigGeneral/AutoCloseWindow"] = "Close the addon window when the native Auction House window is closed",
	["ConfigGeneral/PausePostingQueue"] = "Pause posting queue on load (note other Auction House addons may override this setting)",
	
	["ConfigSearch/DefaultSearcher"] = "Default searcher:",
	["ConfigSearch/DefaultSearchMode"] = "Default search mode:",
	
	["ConfigPost/RarityFilter"] = "Minimum rarity filter:",
	["ConfigPost/DefaultReferencePrice"] = "Default reference price:",
	["ConfigPost/FallbackReferencePrice"] = "Fallback reference price:",
	["ConfigPost/BidPercentage"] = "Bid percentage (of buyout price):",
	["ConfigPost/DefaultBindPrices"] = "Bind bid & buyout prices for unconfigured items",
	["ConfigPost/UndercutAbsolute"] = "Amount to undercut on right click:",
	["ConfigPost/UndercutPercentage"] = "Percentage to undercut on right click:",
	["ConfigPost/AutoPostPause"] = "Pause the posting queue when autoposting",
	
	["ConfigSelling/BypassCancelPopup"] = "Cancel auctions with a single click (don't ask for confirmation)",
	["ConfigSelling/FilterRestrictCharacter"] = "Show only auctions posted by the current character by default",
	["ConfigSelling/FilterCompetition"] = "Default min. competition:",
	["ConfigSelling/FilterBelow"] = "Default min. auctions below:",
	["ConfigSelling/FilterScore"] = "Default scores:",
	
	["ConfigPrice/ItemCategory"] = "Item category",
	["ConfigPrice/CategoryConfig"] = "Category config.",
	["ConfigPrice/CategoryInherit"] = "Inherit from parent category",
	["ConfigPrice/CategoryOwn"] = "Define custom parameters for this category",
	["ConfigPrice/DefaultStackSize"] = "Default stack size",
	["ConfigPrice/DefaultStackNumber"] = "Default auctions",
	["ConfigPrice/DefaultDuration"] = "Default duration",
	["ConfigPrice/ButtonSave"] = "Save",
	["ConfigPrice/ColumnReferencePrice"] = "Reference Price",
	["ConfigPrice/ColumnActive"] = "Active",
	["ConfigPrice/ColumnDefault"] = "Default",
	["ConfigPrice/ColumnFallback"] = "Fallback",
	["ConfigPrice/ButtonDelete"] = "Delete",
	["ConfigPrice/ButtonEdit"] = "Edit",
	["ConfigPrice/ButtonNew"] = "New",
	["ConfigPrice/ApplyMatching"] = "Apply matching rules for unconfigured items",
	
	["ConfigScore/ReferencePrice"] = "Reference price for scoring:",
	
	-- Misc
	["Misc/DateMonthAbbreviatedNames"] = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec",
	["Misc/DateMonthNames"] = "January,February,March,April,May,June,July,August,September,October,November,December",
	["Misc/DateWeekdayAbbreviatedNames"] = "Sun,Mon,Tue,Wed,Thu,Fri,Sat",
	["Misc/DateWeekdayNames"] = "Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday",
	["Misc/RemainingTimeHours"] = "%d h %d m",
	["Misc/RemainingTimeMinutes"] = "%d m %d s",
	["Misc/RemainingTimeSeconds"] = "%d s",
	["Misc/SearchModeOnline"] = "Online",
	["Misc/SearchModeOffline"] = "Offline",
	["Misc/StackSizeMax"] = "Max",
	["Misc/StacksFull"] = "Full",
	["Misc/StacksAll"] = "All",
	["Misc/StackSizeMaxKeyShortcut"] = "+",
	["Misc/StacksFullKeyShortcut"] = "F",
	["Misc/StacksAllKeyShortcut"] = "A",
	["Misc/DurationFormat"] = "%d hours",
	
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

