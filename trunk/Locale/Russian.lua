local _, InternalInterface = ...

InternalInterface.Localization.RegisterLocale("Russian",
{
	-- Posting panel
	["labelStackSize"] = "Размер стака",
	["labelStackNumber"] = "Количество стаков",
	["labelUnitBid"] = "Начальная ставка:",
	["labelUnitBuy"] = "Выкуп:",
	["labelDuration"] = "Продолжительность:",
	["labelDurationFormat"] = "%d часов",
	["buttonUndercut"] = "Низшая цена",
	["buttonPost"] = "Разместить",

	-- Auctions panel
	["columnSeller"] = "Продавец",
	["columnStack"] = "Кол-во",
	["columnBid"] = "Ставка",
	["columnBuy"] = "Выкуп",
	["columnBidPerUnit"] = "Ставка за 1",
	["columnBuyPerUnit"] = "Выкуп за 1",
	["columnMinExpire"] = "Мин.время",
	["columnMaxExpire"] = "Макс.время",
	["lastUpdateMessage"] = "Последнее сканирование: ",
	["lastUpdateDateFormat"] = "%A %x, %X",
	["lastUpdateDateFallback"] = "Никогда",
	["buttonBid"] = "Ставка",
	["buttonBuy"] = "Выкупить",
	
	-- Messages
	["itemScanStarted"] = "Сканирование начато",
	["itemScanError"] = "Не могу запустить сканирование этого товара, попробуйте позже.",
	["fullScanStarted"] = "Сканирование начато",
	["fullScanError"] = "Не могу запустить полное сканирование, попробуйте позже.",
	["slashRegisterError"] = "Не могу выполнить /<команду>",
	
	["scanMessage"] = "%s сканирование: всего %d аукционов%s%s%s.",
	["scanTypeFull"] = "Полное",
	["scanTypePartial"] = "Частичное",
	["scanNewCount"] = ", %d новых",
	["scanUpdatedCount"] = ", %d обновлено",
	["scanRemovedCount"] = ", %d удалено (%d до истечения)",
})

