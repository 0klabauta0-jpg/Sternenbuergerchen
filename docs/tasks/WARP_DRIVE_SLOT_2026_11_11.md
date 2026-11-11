# Warp-Antrieb: erster funktionaler Slot

## Ziel/Ursache
Polisa verkauft einen tatsächlich nutzbaren, belegten Warp-Antrieb statt einer
dekorativen Komponente. Erkul nennt die Quelle Quantumdrive; Spielername Warp.
Qualitäten D schlecht, C, B, A gut; nur Odyssey C und Hemera A belegt.

## Scope / Nicht-Ziele
Ein Slot für explizite model_id cutlass. Kein Rollenraten, keine Fahrzeugmodelle,
Waffen/Fuel/Schilde oder Unterwegs-Saves. Unsourced Legacy behält baseline1 ohne
Slot. Vorläufig Hemera160Cr, Bestand4, Effekt238314/326114; Odyssey Default1.
Relevanz: polisa_ship_equipment_contract.md und Quantum-Slot-Audit desselben Datums.

## Akzeptanz
Kauf ins reale Schiffslager, separater Einbau, altes Teil zurück; Replay/Konflikt,
Kompatibilität, Flug-/Service-/Kapazitätsfehler ohne Teilmutation. Gebundener
Equipmentowner, Supply bleibt Credit/Bestands-/Belegowner. Travel friert Effekt
beim Start ein und zeigt/verbraucht dieselbe Dauer. Versionierter Heimatcheckpoint
mit explizitem Default alter Saves und Crosscheck von Fleet/Belegen/Bestand.

## Dateien/Prüfung/Risiken
Neuer Coreowner/Catalog/Data, Supply-/Inventorycontract, Supply, Travel, Adapter,
CheckpointStore, PolisaScreen, Tradeoffers; Rootglue separat durch Rootagent.
Kleine Owner-/Reise-/Restorefixtures, Compile; keine GPU/große Matrix/Commit.
Spielpreis/Effekt vorläufig, keine Star-Citizen-Flugsimulation. Äußeres Saveformat1
und bestehender Heimatsave-Gate bleiben. Root/Tabletop-Dateibesitz respektieren.

Verbindliche Nutzerterminologie: docs/dev/warp_drive_quality_contract.md.


## Reviewkorrektur: Schiffsrückgabe / Retirement
Skirmish-Rückgabe prüft den Equipmentowner VOR vorhandenen Mutationen/Refund.
Ein Schiff mit irgendeiner eigenen Installationshistorie wird derzeit ausdrücklich
abgewiesen: „Nach einem Antriebsumbau ist die Schiffsrückgabe derzeit nicht verfügbar“.
Auch Rückbau zum Odyssey löscht keine Geschichte und umgeht diesen Gate nicht.
Das ist der enge vorläufige Return/Retire-Lifecycle, keine behauptete Archivierung.
Unmodifizierte Schiffe ohne eigene Installationsbelege bleiben rückgebbar;
validate_craft_return/unregister_unmodified_craft entfernen sie wirklich aus dem
Owner, ohne die globale Installrevision oder fremde Belege zu ändern. Vollständige
belegkonsistente Archivierung/Retirement umgebauter Schiffe bleibt eigener Restpunkt.
