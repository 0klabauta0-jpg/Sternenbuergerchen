# Polisa-Abholung: Backendvertrag

Heimatlieferung bleibt Default für alte Commands/Belege. Neue Wahl delivery_mode
local erfordert vollständige echte lokale Aufnahme. Lokaler schema2 Erwerbsbeleg
trennt acquisition_pad_id (Polisa) und landing_pad_id (reservierter gebauter
Heimatrückkehrplatz); origin_kind local_station_purchase, origin_location_id polisa,
origin_receipt_id echte Kaufrequest. Weder Crew/Pilot noch Heim-Outboundjob erfunden.

Supply behält Credits/Stock/Container/Fuel/Kaufreceipts. Querybelege sind abgeleitete
Reads. Frischer Travelcandidate wird autorisiert initialize_surface/polisa gesetzt,
vor erstem Weltwrite vorbereitet und erst nach vollständiger Aufnahme im Fleetindex
veröffentlicht. Kein Fokuswechsel beim Kauf. Alle Fehler vor Publication; keine
UI- oder Awaitlücke zwischen lokalen Ownern und Supplyreceipt.

RootFlow APIs prepare_polisa_local_ship_purchase(craft,request_id,requested_pad_id)
und commit_polisa_local_ship_purchase(prepared) besitzen lebenden Tacticalpad-/
Visitkontext und liefern acquisition_pad_id,pad_position,visit_identity. Beim Fehler
keine Aufnahme. Profileagent besitzt echte Pad-/Card-/Sequence/Crewowner.

Service und Rückflug dürfen nur validierten local_origin plus echten lokalen
Craft-/Pilot-/Pendinggates nutzen. Eine neue normale Reise hat Vorrang. Fuelroute
polisa>homebase nutzt bestehenden Preis10 und einen Kaufbeleg-basierten einmaligen
Returnrequest statt gefälschtem Outboundtoken. Lokales Schiff startet unbemannt.

Homecheckpoint bleibt unverändert heimgebunden. Alte Lieferbelege validieren als
homebase. Neue lokale Belege bleiben nach echter Heimkehr erhalten, Erwerbspad ist
historische Herkunft und keine ewige Belegungswahrheit. Receipt-/Fleet-/Pad-/ID-
Konsistenz wird vor Restore geprüft. Keine Warp-/Equipment-/Kampfregeländerung.
