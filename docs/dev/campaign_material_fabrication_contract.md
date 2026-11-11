# Kampagnenfertigung mit Materialeingaben

SingleplayerSupplyState bleibt alleiniger Owner fuer Credits, Basisbestand,
Entwicklung und Requestbelege. Neue Rezepte duerfen ein additives inputs-Dictionary
mit bekannten, positiven ganzzahligen Itemmengen enthalten. Reservierte
Auftragsgegenstaende sind keine Werkstoffe. Rezeptidentitaet (Payload blueprint_id,
Beleg recipe_id) und Outputidentitaet (item_id) sind getrennt.

preview_campaign_fabrication liest nur freigeschaltetes Rezept, Credits und
base:homebase. Sie liefert benoetigte inputs, keine bereits erfolgte Entnahme.
Die Fertigungsprojektionen liegen revisioniert gecacht unter
supply.research.fabrication; kalte Lagerinitialisierung invalidiert den Cache.
Der Werkstattpresenter kombiniert sie mit dem bestehenden Heimat-/Servicegate.
Er sendet den unveraenderten campaign_fabricate-Command und besitzt keine Items.

Der Command prueft Heimat, Bauplan, Material, Credits und endgueltige Kapazitaet
vor der ersten Mutation. Material wird nur aus dem Basislager entnommen, dann
ein Output dort erzeugt; keine implizite Fernentnahme aus Schiffen/Personen.
Ein volles Lager darf2Werkstoffe zu1Output verarbeiten, weil die belegte
Kapazitaet sinkt. Nach erfolgreichem Check gibt es keinen fehlschlagenden
Callback zwischen Material-, Credits- und Outputcommit. Bestehender Requestreplay
verbraucht nichts erneut; eine geaenderte Payload mit derselbenID bleibt Konflikt.

Nur materialhaltige neue Rezepte erhalten recipe_id, cost und materials_consumed
als zusaetzliche kanonische Belegfelder. Restore prueft diese gegen das aktuelle
Rezept und prueft auch bei alten Fertigungsbelegen die Outputidentitaet. Alte
echte Belege ohne Inputfelder bleiben gueltig; neue Materialbelege duerfen ihre
Pflichtfelder nicht verlieren oder als altes Rezept umetikettiert werden.
Es gibt keinen neuen Saveowner und keine geaenderte Saveversion.

Erster Slice: research_recycling nach research_industry und gefertigtem
salvage_tool, einmal100Cr. Rezept backpack_recycling braucht2salvage+20Cr und
liefert1backpack. Der unveraenderte Rucksackconsumer gibt12Slots; der freie
Anzug-Datenkartenslot funktioniert weiter ohne Rucksack. Neue Kosten sind
vorlaeufige Balance, kein allgemeiner Raffinerie-/Flottenbaum.
