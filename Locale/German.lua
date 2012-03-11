local _, InternalInterface = ...

InternalInterface.Localization.RegisterLocale("German",
{
	-- Posting panel
	["labelStackSize"] = "Stapelgröße",
	["labelStackNumber"] = "Anzahl Stapel",
	["labelUnitBid"] = "EP Bieten:",
	["labelUnitBuy"] = "EP Sofortkauf:",
	["labelDuration"] = "Restzeit:",
	["labelDurationFormat"] = "%d Stunden",
	["buttonUndercut"] = "unterbieten",
	["buttonPost"] = "Anbieten",

	-- Auctions panel
	["columnSeller"] = "Verkäufer",
	["columnStack"] = "Einheiten",
	["columnBid"] = "Bieten",
	["columnBuy"] = "Sofortkauf",
	["columnBidPerUnit"] = "EP Bieten",
	["columnBuyPerUnit"] = "EP Sofortkauf",
	["columnMinExpire"] = "Min. Auslaufend",
	["columnMaxExpire"] = "Max. Auslaufend",
	["lastUpdateMessage"] = "Letztes Update: ",
	["lastUpdateDateFormat"] = "%A %x, %X",
	["lastUpdateDateFallback"] = "Niemals",
	["buttonBid"] = "Bieten",
	["buttonBuy"] = "Sofortkaufen",
   
	-- Messages
	["itemScanStarted"] = "Itemscan gestartet",
	["itemScanError"] = "Fehler.",
	["fullScanStarted"] = "Vollscan gestartet",
	["fullScanError"] = "Fehler.",
	["slashRegisterError"] = "Kommandos konnten nicht registriert werden.",
   
	["scanMessage"] = "%s Scan: %d Gesamt%s%s%s.",
	["scanTypeFull"] = "Voll",
	["scanTypePartial"] = "Item",
	["scanNewCount"] = ", %d Neu",
	["scanUpdatedCount"] = ", %d aktualisiert",
	["scanRemovedCount"] = ", %d entfernt (%d kurz vor dem auslaufen)",
})

