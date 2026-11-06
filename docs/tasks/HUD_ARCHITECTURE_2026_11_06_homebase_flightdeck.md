# Homebase-Flightdeck: eindeutiger Einsatz und semantischer Status

## Ziel / Problem
Die native Heimatbasis zeigt den gewaehlten Missionsnamen zweimal direkt
untereinander. Der Schiffsstatus verwendet unabhaengig vom Zustand Gelb,
obwohl die bestaetigten Originale Bereitschaft, Transport und Auswahl trennen.

## Ursache / Sinnhaftigkeit
`homebase_operations_presenter.gd` aktualisiert sowohl eine Namenszeile als
auch den vorhandenen Missionsselector mit dem Missionsnamen. Der Status wird
einmal mit GOLD gebaut und erhaelt spaeter nur anderen Text. Die vorhandenen
Operationsdaten besitzen die noetigen Zustandsfelder; `TacticalUITheme`
besitzt bereits den gemeinsamen `status_color`-Pfad.

## Umfang / Nicht-Ziele
Nur Anzeige in `scripts/meta/homebase_operations_presenter.gd`: eindeutiger
Feldtitel `Einsatz` vor dem echten Selector und Schiffsstatusfarbe aus dem
bestehenden Snapshot. Keine neue gespeicherte Zustandsquelle, keine Aenderung
von Gates, Callbacks, Roster, Transport, Mission, Navigation oder Spalten.
Keine Rahmenrunde und keine Engine-/Git-/Saveaktion durch diesen Untertask.

## Relevante Dokumente / Quellen
- `docs/tasks/HUD_ARCHITECTURE_2026_11_06.md`
- `docs/dev/homebase_operations_ux_contract.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/ui_native_design_contract.md`
- `docs/dev/graphics_reference_revision_contract.md`
- Originale `docs/reports/assets/ui-2026-11-01/menu_heimatbasis.png` und
  `menu_fob_loadout.png`; native `02_homebase.png` unter
  `output/continue_20261105/final_native_motion/20261105T143914Z-d2deebb0/final_captures/`.

## Akzeptanzkriterien vor Produktcode
1. Der feste Feldtitel lautet `Einsatz`; allein der vorhandene Selector zeigt
   den aktuellen Missionsnamen und behaelt reale ID, Auswahl und Callback.
2. Leere Schiffsauswahl nutzt den vorhandenen neutralen Themefarbwert.
   Ein laufendes Schiff (`busy`) nutzt `transit`; fehlender Pilot `blocked`;
   startbereites Schiff (`can_start`) `ready`; nicht abgeschlossenes Boarding
   (`has_payload`, Fortschritt unter 100) `transit`; sonstige Vorbereitung
   `pending`. Die Reihenfolge folgt der bisherigen Statusprojektion.
3. Farben kommen ausschliesslich aus `TacticalUITheme.status_color`.
   Kein Parsing deutscher Statustexte und keine neue Kopie des Gameplaystates.
4. Statuswort, Fortschritt, Pilot-/Boarding-/Startgates und Selectorcallbacks
   bleiben unveraendert. Statuswechsel setzt die Farbe ohne Neuaufbau korrekt
   zurueck; reine Refreshes mutieren den Eingabesnapshot nicht und senden keine
   Operation.

## Betroffene Dateien
- `scripts/meta/homebase_operations_presenter.gd`
- `scripts/tests/hud_architecture_20261106_homebase_flightdeck_verifier.gd`
- diese Task-Datei

## Lokale Pruefung / Nachweisgrenze
Neuer fokussierter Verifier prueft echte Presentercontrols mit expliziten
synthetischen Operationssnapshots, Titel-/Selectorwechsel, Statusfarben,
Gateparitaet, Controlwiederverwendung und unveraenderte Eingabebytes. Das ist
ein Darstellungsfixture, kein normaler Flug- oder Gameplaynachweis. Root
fuehrt RED/GREEN und den bestehenden Homebase-Operationsverifier seriell mit
isoliertem Profil aus. Root erzeugt den nativen Vorher/Nachhervergleich und
prueft die tatsaechliche Lesbarkeit; gestalterisches Nutzerurteil bleibt offen.

## Risiken / offene Punkte
Der aktuelle Snapshot liefert keinen eigenen Statusschluessel. Die lokale
Farbprojektion liest nur dessen bestehende boolesche Gates und Fortschritt;
bei kuenftigen neuen Transportzustaenden muss diese Projektion mitgeprueft
werden. Gelb bleibt fuer sonstige Vorbereitung erhalten; normaler laufender
Transport wird nicht als Fehler eingefaerbt. Vorherbild durch Root abwarten,
bevor die Produktdatei geaendert wird.

## Stand
Akzeptanz und Verifier vor dem Produktpatch angelegt. Root fuehrte den
unveraenderten Presenter isoliert aus:
`output/hud_architecture_20261106/homebase_red/20261106T133238Z-cff638d5/report.json`.
Das Original-Log wurde geprueft: 63 PASS / 9 FAIL, ausschliesslich die erwarteten
Titel-/Farbassertions; keine Parsefehler. Snapshot-/Gate-/Callbackchecks bestehen.
Danach den freigegebenen kleinen Presenterpatch angewendet. Root bestaetigt
72/72 GREEN, Exit 0 und Enginefehler 0 unter
`output/hud_architecture_20261106/homebase_green/20261106T133858Z-f9c0fea8/`.
Der bestehende Operations-Neighbor besteht separat unter
`output/hud_architecture_20261106/homebase_neighbor/20261106T133900Z-b188056e/`.
Nativer Nachhervergleich und gestalterisches Nutzerurteil stehen noch aus.

## Direkter Bildabgleich vor dem Patch
Die beiden genannten Original-2D-Ziele sowie das frische native Vorherbild
`output/hud_architecture_20261106/baseline_profile/20261106T132842Z-c93dc5aa/baseline_captures/02_homebase.png`
wurden geoeffnet. Root bestaetigt fuer diesen Lauf echtes 3440x1440-Vollbild.
Der gewaehlte Einsatz steht nativ zweimal direkt untereinander; `Bereit`
steht gelb, waehrend die Originale Bereitschaft mit Cyan/Teal von der gelben
Auswahl unterscheiden. Die neuen koharenten Portraets und reale Ref03-Vorschau
sind sichtbar; der alte Befund uneinheitlicher Pixelportraets ist ueberholt.

Der grosse offene Abstand bleibt die Screenkomposition: vier gleichfoermige
Arbeitsflaechen mit freien Bereichen statt der atmosphaerischen grossen Szene
und klaren Schrittfolge der Originale. In der Mission liegt der Abstand vor
allem im Kameramassstab und der Szenendichte. Diese groesseren Gestaltungsfragen
sind ausdruecklich kein Umfang dieses kleinen Flightdeck-Passes; technische
Gates oder zwei Beschriftungs-/Farbkorrekturen nehmen die Gestaltung nicht ab.
