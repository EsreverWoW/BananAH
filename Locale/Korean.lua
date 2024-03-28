﻿local _, InternalInterface = ...

InternalInterface.Localization.RegisterLocale("Korean",
{
	-- ["CancelAuctionPopup/ButtonNo"] = "",
	-- ["CancelAuctionPopup/ButtonYes"] = "",
	-- ["CancelAuctionPopup/ContentText"] = "",
	-- ["CancelAuctionPopup/IgnoreText"] = "",
	-- ["CancelAuctionPopup/Title"] = "",
	-- ["ComplexModelPopup/ButtonCancel"] = "",
	-- ["ComplexModelPopup/ButtonSave"] = "",
	-- ["ComplexModelPopup/Name"] = "",
	-- ["CompositeModelPopup/ButtonAdd"] = "",
	-- ["CompositeModelPopup/ButtonCancel"] = "",
	-- ["CompositeModelPopup/ButtonSave"] = "",
	-- ["CompositeModelPopup/Name"] = "",
	-- ["ConfigFrame/CategoryGeneral"] = "",
	-- ["ConfigFrame/CategoryHistory"] = "",
	-- ["ConfigFrame/CategoryPost"] = "",
	-- ["ConfigFrame/CategoryPricing"] = "",
	-- ["ConfigFrame/CategoryScoring"] = "",
	-- ["ConfigFrame/CategorySearch"] = "",
	-- ["ConfigFrame/CategorySelling"] = "",
	-- ["ConfigFrame/CategoryTracking"] = "",
	-- ["ConfigGeneral/AutoCloseWindow"] = "",
	-- ["ConfigGeneral/AutoOpenWindow"] = "",
	-- ["ConfigGeneral/MapIconShow"] = "",
	-- ["ConfigGeneral/PausePostingQueue"] = "",
	-- ["ConfigPost/AutoPostPause"] = "",
	-- ["ConfigPost/BidPercentage"] = "",
	-- ["ConfigPost/DefaultBindPrices"] = "",
	-- ["ConfigPost/DefaultReferencePrice"] = "",
	-- ["ConfigPost/FallbackReferencePrice"] = "",
	-- ["ConfigPost/RarityFilter"] = "",
	-- ["ConfigPost/UndercutAbsolute"] = "",
	-- ["ConfigPost/UndercutPercentage"] = "",
	-- ["ConfigPrice/ApplyMatching"] = "",
	-- ["ConfigPrice/ButtonDelete"] = "",
	-- ["ConfigPrice/ButtonEdit"] = "",
	-- ["ConfigPrice/ButtonNew"] = "",
	-- ["ConfigPrice/ButtonSave"] = "",
	-- ["ConfigPrice/CategoryConfig"] = "",
	-- ["ConfigPrice/CategoryInherit"] = "",
	-- ["ConfigPrice/CategoryOwn"] = "",
	-- ["ConfigPrice/ColumnActive"] = "",
	-- ["ConfigPrice/ColumnDefault"] = "",
	-- ["ConfigPrice/ColumnFallback"] = "",
	-- ["ConfigPrice/ColumnReferencePrice"] = "",
	-- ["ConfigPrice/DefaultDuration"] = "",
	-- ["ConfigPrice/DefaultMaxAuctions"] = "",
	-- ["ConfigPrice/DefaultStackSize"] = "",
	-- ["ConfigPrice/ItemCategory"] = "",
	-- ["ConfigScore/ReferencePrice"] = "",
	-- ["ConfigSearch/DefaultSearcher"] = "",
	-- ["ConfigSearch/DefaultSearchMode"] = "",
	-- ["ConfigSelling/BypassCancelPopup"] = "",
	-- ["ConfigSelling/FilterBelow"] = "",
	-- ["ConfigSelling/FilterCompetition"] = "",
	-- ["ConfigSelling/FilterRestrictCharacter"] = "",
	-- ["ConfigSelling/FilterScore"] = "",
	-- ["FilterPopupFrame/ButtonAdd"] = "",
	-- ["FilterPopupFrame/Title"] = "",
	-- ["General/CallingAll"] = "",
	-- ["General/CallingCleric"] = "",
	-- ["General/CallingMage"] = "",
	-- ["General/CallingPrimalist"] = "",
	-- ["General/CallingRogue"] = "",
	-- ["General/CallingWarrior"] = "",
	-- ["General/CompetitionName1"] = "",
	-- ["General/CompetitionName2"] = "",
	-- ["General/CompetitionName3"] = "",
	-- ["General/CompetitionName4"] = "",
	-- ["General/CompetitionName5"] = "",
	-- ["General/ModelTypeComplex"] = "",
	-- ["General/ModelTypeComposite"] = "",
	-- ["General/ModelTypeSimple"] = "",
	-- ["General/ModelTypeStatistical"] = "",
	-- ["General/Rarity1"] = "",
	-- ["General/Rarity2"] = "",
	-- ["General/Rarity3"] = "",
	-- ["General/Rarity4"] = "",
	-- ["General/Rarity5"] = "",
	-- ["General/Rarity6"] = "",
	-- ["General/Rarity7"] = "",
	-- ["General/Rarity8"] = "",
	-- ["General/Rarity9"] = "",
	-- ["General/ScoreName0"] = "",
	-- ["General/ScoreName1"] = "",
	-- ["General/ScoreName2"] = "",
	-- ["General/ScoreName3"] = "",
	-- ["General/ScoreName4"] = "",
	-- ["General/ScoreName5"] = "",
	-- ["ItemAuctionsGrid/ButtonBid"] = "",
	-- ["ItemAuctionsGrid/ButtonBuy"] = "",
	-- ["ItemAuctionsGrid/ColumnBid"] = "",
	-- ["ItemAuctionsGrid/ColumnBidPerUnit"] = "",
	-- ["ItemAuctionsGrid/ColumnBuy"] = "",
	-- ["ItemAuctionsGrid/ColumnBuyPerUnit"] = "",
	-- ["ItemAuctionsGrid/ColumnRemaining"] = "",
	-- ["ItemAuctionsGrid/ColumnScore"] = "",
	-- ["ItemAuctionsGrid/ColumnSeller"] = "",
	-- ["ItemAuctionsGrid/ColumnStack"] = "",
	-- ["ItemAuctionsGrid/ErrorBidEqualBuy"] = "",
	-- ["ItemAuctionsGrid/ErrorHighestBidder"] = "",
	-- ["ItemAuctionsGrid/ErrorNoAuction"] = "",
	-- ["ItemAuctionsGrid/ErrorNoAuctionHouse"] = "",
	-- ["ItemAuctionsGrid/ErrorNotCached"] = "",
	-- ["ItemAuctionsGrid/ErrorSeller"] = "",
	-- ["ItemAuctionsGrid/ItemScanError"] = "",
	-- ["ItemAuctionsGrid/ItemScanStarted"] = "",
	-- ["ItemAuctionsGrid/LastUpdateDateFallback"] = "",
	-- ["ItemAuctionsGrid/LastUpdateDateFormat"] = "",
	-- ["ItemAuctionsGrid/LastUpdateMessage"] = "",
	-- ["Main/FullScanError"] = "",
	-- ["Main/FullScanStarted"] = "",
	-- ["Main/MenuAuctions"] = "",
	-- ["Main/MenuBids"] = "",
	-- ["Main/MenuConfig"] = "",
	-- ["Main/MenuFullScan"] = "",
	-- ["Main/MenuHistory"] = "",
	-- ["Main/MenuPost"] = "",
	-- ["Main/MenuSearch"] = "",
	-- ["Main/ScanMessage"] = "",
	-- ["Main/ScanNewCount"] = "",
	-- ["Main/ScanRemovedCount"] = "",
	-- ["Main/ScanUpdatedCount"] = "",
	-- ["Main/SlashRegisterError"] = "",
	-- ["MatcherPopupFrame/ButtonAdd"] = "",
	-- ["MatcherPopupFrame/Title"] = "",
	-- ["Misc/AuctionLimitMax"] = "",
	-- ["Misc/AuctionLimitMaxKeyShortcut"] = "",
	-- ["Misc/DateMonthAbbreviatedNames"] = "",
	-- ["Misc/DateMonthNames"] = "",
	-- ["Misc/DateWeekdayAbbreviatedNames"] = "",
	-- ["Misc/DateWeekdayNames"] = "",
	-- ["Misc/DurationFormatHours"] = "",
	-- ["Misc/DurationFormatHoursDays"] = "",
	-- ["Misc/RemainingTimeDays"] = "",
	-- ["Misc/RemainingTimeHours"] = "",
	-- ["Misc/RemainingTimeMinutes"] = "",
	-- ["Misc/RemainingTimeSeconds"] = "",
	-- ["Misc/SearchModeOffline"] = "",
	-- ["Misc/SearchModeOnline"] = "",
	-- ["Misc/StackSizeMax"] = "",
	-- ["Misc/StackSizeMaxKeyShortcut"] = "",
	-- ["NewModelPopup/ButtonCancel"] = "",
	-- ["NewModelPopup/ButtonContinue"] = "",
	-- ["NewModelPopup/ModelType"] = "",
	-- ["NewModelPopup/Title"] = "",
	-- ["PostFrame/ButtonPost"] = "",
	-- ["PostFrame/ButtonReset"] = "",
	-- ["PostFrame/CheckBindPrices"] = "",
	-- ["PostFrame/CheckPriceMatching"] = "",
	-- ["PostFrame/ErrorAutoPostModelMissing"] = "",
	-- ["PostFrame/ErrorPostBase"] = "",
	-- ["PostFrame/ErrorPostBidPrice"] = "",
	-- ["PostFrame/ErrorPostBuyPrice"] = "",
	-- ["PostFrame/ErrorPostStackNumber"] = "",
	-- ["PostFrame/ErrorPostStackSize"] = "",
	-- ["PostFrame/LabelAuctionLimit"] = "",
	-- ["PostFrame/LabelAuctions"] = "",
	-- ["PostFrame/LabelAuctionsPlural"] = "",
	-- ["PostFrame/LabelAuctionsSingular"] = "",
	-- ["PostFrame/LabelDuration"] = "",
	-- ["PostFrame/LabelIncompleteStack"] = "",
	-- ["PostFrame/LabelItemStack"] = "",
	-- ["PostFrame/LabelPricingModel"] = "",
	-- ["PostFrame/LabelStackSize"] = "",
	-- ["PostFrame/LabelUnitBid"] = "",
	-- ["PostFrame/LabelUnitBuy"] = "",
	-- ["PriceModels/Average"] = "",
	-- ["PriceModels/Fixed"] = "",
	-- ["PriceModels/Market"] = "",
	-- ["PriceModels/Median"] = "",
	-- ["PriceModels/StandardDeviation"] = "",
	-- ["PriceModels/TrimmedMean"] = "",
	-- ["PriceModels/Vendor"] = "",
	-- ["SaveSearchPopup/ButtonCancel"] = "",
	-- ["SaveSearchPopup/ButtonSave"] = "",
	-- ["SaveSearchPopup/DefaultName"] = "",
	-- ["SaveSearchPopup/NameText"] = "",
	-- ["SaveSearchPopup/Title"] = "",
	-- ["SearchFrame/ButtonBid"] = "",
	-- ["SearchFrame/ButtonBuy"] = "",
	-- ["SearchFrame/ButtonReset"] = "",
	-- ["SearchFrame/ButtonSearch"] = "",
	-- ["SearchFrame/ButtonTrack"] = "",
	-- ["SearchFrame/ColumnBid"] = "",
	-- ["SearchFrame/ColumnBidPerUnit"] = "",
	-- ["SearchFrame/ColumnBuy"] = "",
	-- ["SearchFrame/ColumnBuyPerUnit"] = "",
	-- ["SearchFrame/ColumnItem"] = "",
	-- ["SearchFrame/ColumnRemaining"] = "",
	-- ["SearchFrame/ColumnScore"] = "",
	-- ["SearchFrame/ColumnSeller"] = "",
	-- ["SearchFrame/ErrorBidEqualBuy"] = "",
	-- ["SearchFrame/ErrorHighestBidder"] = "",
	-- ["SearchFrame/ErrorNoAuction"] = "",
	-- ["SearchFrame/ErrorNoAuctionHouse"] = "",
	-- ["SearchFrame/ErrorNotCached"] = "",
	-- ["SearchFrame/ErrorSeller"] = "",
	-- ["SellingFrame/ColumnBid"] = "",
	-- ["SellingFrame/ColumnBidPerUnit"] = "",
	-- ["SellingFrame/ColumnBuy"] = "",
	-- ["SellingFrame/ColumnBuyPerUnit"] = "",
	-- ["SellingFrame/ColumnCompetition"] = "",
	-- ["SellingFrame/ColumnItem"] = "",
	-- ["SellingFrame/ColumnRemaining"] = "",
	-- ["SellingFrame/ColumnScore"] = "",
	-- ["SellingFrame/FilterBelow"] = "",
	-- ["SellingFrame/FilterCompetition"] = "",
	-- ["SellingFrame/FilterScore"] = "",
	-- ["SellingFrame/FilterSeller"] = "",
	-- ["SimpleModelPopup/ButtonCancel"] = "",
	-- ["SimpleModelPopup/ButtonSave"] = "",
	-- ["SimpleModelPopup/Name"] = "",
	-- ["StatisticalModelPopup/ButtonCancel"] = "",
	-- ["StatisticalModelPopup/ButtonSave"] = "",
	-- ["StatisticalModelPopup/Name"] = "",
	-- ["UnsavedChangesPopup/ButtonCancel"] = "",
	-- ["UnsavedChangesPopup/ButtonContinue"] = "",
	-- ["UnsavedChangesPopup/ContentText"] = "",
	-- ["UnsavedChangesPopup/Title"] = "",
}

)
