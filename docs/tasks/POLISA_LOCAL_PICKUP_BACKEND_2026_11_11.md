# Polisa-Abholung: Backend-Transaktionsgrenze

Status: API-Vorschlag vor Produktedits, Basis b67b307b0. Übergeordneter Auftrag
POLISA_LOCAL_SHIP_PICKUP_2026_11_11.md. Root besitzt Flow, Profilagent Tactical/
Pad/Crew. Kein Root-/Flow-/Controller-/Equipment-/Warpedit durch Backendagent.

## Ziel / Ursache
Lokale unbemannte Ausgabe braucht echte stationäre Travelidentität und Beleg
anstatt erfundenem Heim-Outboundtoken. Supply bleibt Geld-/Stock-/Fuel-/Container-
und Erwerbsbelegowner. Nach Hause liefern bleibt separate bestehende Option.

## Vorgeschlagene additive Schnittstellen
station_buy_ship payload.delivery_mode homebase|local, fehlend homebase. Optional
requested_station_pad_id. Bestehender Contextcallback station_ship_fulfillment
(offer,request_id) bleibt unverändert; neuer station_local_ship_fulfillment
(offer,request_id,requested_station_pad_id) getrennt. Query
Supply.get_station_ship_purchase(craft_id) liefert validierten normalisierten Beleg.

Lokaler Beleg schema2: bisheriges deterministisches craft_id/offer/cost plus
delivery_location_id polisa, acquisition_pad_id echt lokal, landing_pad_id echtes
reserviertes Heimatpad, origin_kind local_station_purchase, origin_location_id
polisa, origin_receipt_id request_id. Keine Jobübernahme von anderem Besuch.
Legacybelege ohne neue Felder bleiben ausdrückliche Heimatlieferung.

RootFlow-Bridge vorgeschlagen prepare_polisa_local_ship_purchase(craft_definition,
request_id,requested_station_pad_id)->Dictionary und
commit_polisa_local_ship_purchase(prepared)->Dictionary. Beinhaltet lokales
Controllerpreview (preview_station_craft_admission), echten Mapmarker/Padfit,
gebundene Visitidentity; Commit reject garantiert keine Teilaufnahme. Profileagent
liefert admit_station_craft mit finaler Revalidierung vor echten Writes.

Travel: trusted initialize_surface {craft_id,location_id:polisa}, kein Start vom
Mondorbit. Fleet muss frischen validierten Candidateowner vor Registrierung
vorbereiten und erst bei Kaufcommit veröffentlichen. Vorgeschlagene interne
prepare_surface_registration/commit_surface_registration trennen den fehlbaren
Candidatebau vom finalen no-fail Indexwrite; keine UI-Callables/Statewahrheit.
Gleicher request_id Replay liefert denselben Craft, Konflikt/Existingregistration
wird abgewiesen, kein Fokuswechsel bei bloßem Kauf.

## Vorbereitungs-/Commitreihenfolge
1 Supply-Replay/Konflikt, realer bestehender Polisa-Service, Credits und Stock.
2 Adapter: freie deterministische ID + gebautes freies Heimatrückkehrpad, lokale
   Flow/Tactical-/Marker-/Padprüfung und vollständig vorbereiteter Travelcandidate.
3 Flow/Tactical: finale synchron revalidierte Aufnahme; entweder keinerlei Write
   oder ab hier vollständige no-fail Publication ohne UI/await/Signalsplit.
4 Prepared Travelowner, Flottendefinition/Ort, Heimatpadreservation und Supplycraft
   veröffentlichen; vorhandenen Equipmentregisterweg nutzen, keinen Default raten.
5 Supply führt ausschließlich vorvalidierte Debit-/Stock-/Receiptzuweisungen aus.
Reihenfolge wird vor Code mit Root/Profilagent verbindlich festgelegt. Wenn eine
spätere Operation fehlbar bleibt: echter Rollback oder geänderte Staginggrenze,
niemals halbe Lieferung als atomar bezeichnen.

## Services / lokaler Herkunftsrückflug
Adapter liest validierten Erwerbsbeleg nur bei realem lokalen Ort/Actor und ohne
Pendingtransfer; ein späterer normaler Campaigndeparture hat Vorrang. authorize_return
prüft echten Pilot/Flightguard und nutzt lokale Belegroute polisa>homebase mit
bestehendem Fuelpreis10 und request return:local-purchase:<receipt>:fuel, keinen
gefälschten Heimatabflug. RootFlow muss lokale Visit-/Crew-/Abflug-/Heimkehrbrücke
behalten. Schiff startet unbemannt, echte vorhandene Crew wird separat übergeben.

## Umfang / Dateien
Supply, vorhandene Travel/Fleetowner, CheckpointStore, RuntimeAdapter, PolisaScreen,
eigene kleine Fixtures/Doku. Bestehender Supplycommandcontract soweit neue
trusted Traveloperation im Owner nötig. Keine neuen Fahrzeuge/Lookdev oder
Komponenten-/Warpregeln, kein Away-Save. Gebautes Heimatpad bleibt reserviert;
Erwerbspadbeleg ist keine dauerhafte Belegungswahrheit nach Abflug.

## Akzeptanz / kleine Prüfung
Echte lokale Surfaceinitialisierung/Services/Rückflugfuel einmal; Kaufstock und
Credits atomar; volle/inkompatible Pads/Marker/Owner/Heimatpad/Gates ohne Write;
Replay/Konflikt, zwei Crafts/Orte, lokaler Herkunftsbeleg und kein Fremdjobtoken.
Alter Heimatlieferbeleg und neuer local schema2 nach echter Heimkehr durch echten
Checkpointvalidator; manipulierte Craft-/Pad-/Origin-/Doppelbelege vor Mutation
abgewiesen. Save bleibt all-grounded Heimat. Kleine Ownerchecks/Compile, keine
GPU/Gefechts-/breite Testmatrix. Keine Commits/globalen Statusedits.

## Risiken / offen
Controller-Freigabe und gemeinsamer no-fail Aufnahmevertrag vor Implementierung;
reale einzigartige Crew-/Pilotübergabe ist externer vollständiger Sliceanteil.
UI lokale Option erst anbieten, wenn alle Owner/Brücken wirklich verfügbar sind.

## Freigabe
Root hat additive APIs und Umfang bestätigt. Backendimplementierung freigegeben;
Flow/Controller bleiben fremder Dateibesitz. no-fail Reihenfolge wird an deren
konkretem Prepared/Commitvertrag angeschlossen, UI local bis dahin gesperrt.

## Backendfreeze / enge Prüfung
43/0 echte Backendowner mit expliziten Flow-/Tacticalaufnahme- und Crewstubs;
5Source-Compilechecks0. Nachweise docs/qa/polisa_local_pickup_backend_20261111.
Getrennte Callbackintegration durch Root, echte Pad-/Crew-/Presenceowner durch
Profilagent/Root. Keine Native-/Gesamtrundreise-/Away-Saveabnahme. GUI hat ausdrückliche
Home/Localwahl und Source/Pilot/Wholecrew/Deploy/Board-/Returncommands. Verbindlicher
Gesamtvertrag: docs/dev/polisa_local_ship_pickup_contract.md. Kein Commit/globalstatus.
