# Warp-Antrieb: begrenzte Integration

Frische gemeinsame Laeufe in results.json: Warp42/0, Skirmishreturn14/0,
Rootbinding7/0 und lokale Service-Regression30/0. Root, Kampagnenstarter,
Sternkartenscreen und Heimatpresenter check-only Exit0 ohne Scriptfehler.
Die neun agent-eigenen Compilebelege liegen unter warp_drive_slot_20261111.

Echte Root-/Supply-/Equipment-/Travel-/CheckpointStore-Owner werden in den
kleinen Domainfixtures verwendet. Rueckgabe nutzt echten Adapter/Root/Economy-
Callback mit kleinen Basis-/Flowdoubles. Keine Benutzer-Spielstaende geschrieben,
keine echte Scene, GPU, Schlacht, Reisebedienung oder grosse Matrix.

Unabhaengiger Source-/Deltareview nach zwei konkreten Fehlerkorrekturen: JSON-
Revisionen muessen nach Floatparsing integer-kanonisch verglichen werden;
Skirmishrueckgabe darf bezahlte Upgrades nicht an verwaister Craft-ID verlieren.
Die RED-Logs bleiben als gezielte Reproduktionsbelege beim Teilpaket erhalten.
Finaler Review ohne Restblocker. source_normalized_sha256.json nennt die
LF-normalisierten finalen Produkt-/Fixturequellen.

Begrenzung: Jede eigene Einbauhistorie sperrt vorlaeufig die Skirmishrueckgabe,
auch nach Rueckbau. Unveraenderte Schiffe unregister/refund/replay korrekt.
Konsistente Retirement-/Umruestbelege bleiben ein eigener Folgeschritt. Save
bleibt heimatgebunden. Unbekannte Legacy-Modelle behalten Baseline1; nur explizite
Cutlass erhaelt belegten Odyssey-C/Hemera-A-Slot. Preis/Bestand und relativer
Reisedauereffekt sind initiale Spielbalance. Grosse Native-/Reise-/Save-/
Gefechts-/Performanceabnahme auf Nutzerwunsch spaeter; kein Mainmerge/EXEbau.
