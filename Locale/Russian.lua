﻿local _, InternalInterface = ...

InternalInterface.Localization.RegisterLocale("Russian",
{
	["CancelAuctionPopup/ButtonNo"] = "Нет", -- Needs review
	["CancelAuctionPopup/ButtonYes"] = "Да", -- Needs review
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
	["ConfigGeneral/AutoCloseWindow"] = "Закрывать окно аддона при закрытии окна аукционного дома", -- Needs review
	["ConfigGeneral/AutoOpenWindow"] = "Открывать окно аддона при открытии окна аукционного дома", -- Needs review
	-- ["ConfigGeneral/MapIconShow"] = "",
	-- ["ConfigGeneral/PausePostingQueue"] = "",
	["ConfigPost/AutoPostPause"] = "Приостановить размещение очереди в режиме Autoposting", -- Needs review
	["ConfigPost/BidPercentage"] = "Ставка процента (цена выкупа)", -- Needs review
	-- ["ConfigPost/DefaultBindPrices"] = "",
	-- ["ConfigPost/DefaultReferencePrice"] = "",
	-- ["ConfigPost/FallbackReferencePrice"] = "",
	-- ["ConfigPost/RarityFilter"] = "",
	-- ["ConfigPost/UndercutAbsolute"] = "",
	-- ["ConfigPost/UndercutPercentage"] = "",
	["ConfigPrice/ApplyMatching"] = "Применить правила соответствия", -- Needs review
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
	["ConfigSelling/BypassCancelPopup"] = "Отмена аукционов с одним щелчком мыши (не спрашивая подтверждения)", -- Needs review
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
	["General/Rarity1"] = "Серые", -- Needs review
	["General/Rarity2"] = "Обычные", -- Needs review
	["General/Rarity3"] = "Необычные", -- Needs review
	["General/Rarity4"] = "Редкие", -- Needs review
	["General/Rarity5"] = "Эпические", -- Needs review
	["General/Rarity6"] = "Реликвии", -- Needs review
	["General/Rarity7"] = "Совершенные", -- Needs review
	["General/Rarity8"] = "Вознесенные", -- Needs review
	["General/Rarity9"] = "Вечный", -- Needs review
	-- ["General/ScoreName0"] = "",
	-- ["General/ScoreName1"] = "",
	-- ["General/ScoreName2"] = "",
	-- ["General/ScoreName3"] = "",
	-- ["General/ScoreName4"] = "",
	-- ["General/ScoreName5"] = "",
	["ItemAuctionsGrid/ButtonBid"] = "Ставка", -- Needs review
	["ItemAuctionsGrid/ButtonBuy"] = "Покупка", -- Needs review
	-- ["ItemAuctionsGrid/ColumnBid"] = "",
	-- ["ItemAuctionsGrid/ColumnBidPerUnit"] = "",
	-- ["ItemAuctionsGrid/ColumnBuy"] = "",
	-- ["ItemAuctionsGrid/ColumnBuyPerUnit"] = "",
	-- ["ItemAuctionsGrid/ColumnMaxExpire"] = "",
	-- ["ItemAuctionsGrid/ColumnMinExpire"] = "",
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
	["MatcherPopupFrame/ButtonAdd"] = "Добавить", -- Needs review
	-- ["MatcherPopupFrame/Title"] = "",
	["Misc/AuctionLimitMax"] = "Все", -- Needs review
	-- ["Misc/AuctionLimitMaxKeyShortcut"] = "",
	-- ["Misc/DateMonthAbbreviatedNames"] = "",
	-- ["Misc/DateMonthNames"] = "",
	-- ["Misc/DateWeekdayAbbreviatedNames"] = "",
	-- ["Misc/DateWeekdayNames"] = "",
	-- ["Misc/DurationFormat"] = "",
	-- ["Misc/RemainingTimeHours"] = "",
	-- ["Misc/RemainingTimeMinutes"] = "",
	-- ["Misc/RemainingTimeSeconds"] = "",
	-- ["Misc/SearchModeOffline"] = "",
	-- ["Misc/SearchModeOnline"] = "",
	-- ["Misc/StackSizeMax"] = "",
	-- ["Misc/StackSizeMaxKeyShortcut"] = "",
	["NewModelPopup/ButtonCancel"] = "Отмена", -- Needs review
	["NewModelPopup/ButtonContinue"] = "Продолжение", -- Needs review
	-- ["NewModelPopup/ModelType"] = "",
	-- ["NewModelPopup/Title"] = "",
	["PostFrame/ButtonPost"] = "Размещение", -- Needs review
	["PostFrame/ButtonReset"] = "Сброс", -- Needs review
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
	["SaveSearchPopup/ButtonCancel"] = "Отмена", -- Needs review
	["SaveSearchPopup/ButtonSave"] = "Сохранить", -- Needs review
	-- ["SaveSearchPopup/DefaultName"] = "",
	-- ["SaveSearchPopup/NameText"] = "",
	-- ["SaveSearchPopup/Title"] = "",
	["SearchFrame/ButtonBid"] = "Ставка", -- Needs review
	["SearchFrame/ButtonBuy"] = "Покупка", -- Needs review
	["SearchFrame/ButtonReset"] = "Сброс", -- Needs review
	["SearchFrame/ButtonSearch"] = "Поиск", -- Needs review
	["SearchFrame/ButtonTrack"] = "Ослеживание", -- Needs review
	-- ["SearchFrame/ColumnBid"] = "",
	-- ["SearchFrame/ColumnBidPerUnit"] = "",
	-- ["SearchFrame/ColumnBuy"] = "",
	-- ["SearchFrame/ColumnBuyPerUnit"] = "",
	-- ["SearchFrame/ColumnItem"] = "",
	-- ["SearchFrame/ColumnMaxExpire"] = "",
	-- ["SearchFrame/ColumnMinExpire"] = "",
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
	-- ["SellingFrame/ColumnMaxExpire"] = "",
	-- ["SellingFrame/ColumnMinExpire"] = "",
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
	["UnsavedChangesPopup/ButtonCancel"] = "Отмена", -- Needs review
	["UnsavedChangesPopup/ButtonContinue"] = "Продолжение", -- Needs review
	-- ["UnsavedChangesPopup/ContentText"] = "",
	-- ["UnsavedChangesPopup/Title"] = "",
}

)
