# TASK_319 - Manual Playtest FOB Second Dropship Assignment and Scale

## Ziel
Fireteams sollen im FOB-Flightdeck einem konkreten Dropship zugewiesen werden koennen. Ein Fireteam fuer `Dropship 2` darf nicht automatisch in die Queue von `Dropship 1` rutschen.

## Status: IMPLEMENTIERT

## Kontext
Im manuellen Playtest rutschten Fireteams beim Zuweisen auf ein zweites Dropship nach oben in `Dropship 1`. Gleichzeitig war die Shipcard im FOB-Flightdeck durch transparente Asset-Raender optisch zu klein und schwer zu treffen.

## Umfang
1. Per-Craft Boarding Queue:
   - FOB speichert Boarding-/Staging-Queues pro Transport-Craft-ID.
   - Fireteams behalten ihr Ziel `dropship|dropship_2`.
2. Shipcard-Auswahl:
   - Dropship-Karten sind klickbar/selectable.
   - Auswahl wird klarer markiert.
3. Visual Scale:
   - Dropship-Bild wird groesser/cropped dargestellt.
   - Transparente Asset-Raender werden optisch abgefedert.

## Nicht-Ziele
- Kein neuer Transport-Simulationszustand ausserhalb der bestehenden Meta-/Mission-Flows.
- Keine finale Pixel-Art-/Asset-Kalibrierung.

## Akzeptanzkriterien
- [x] Fireteam fuer Dropship 2 bleibt in Dropship 2.
- [x] FOB-Shipcards koennen das aktive Craft wechseln.
- [x] Shipcard nutzt weniger leeren Transparentbereich.
- [x] Bestehende Boarding-/Send-Flows bleiben kompatibel.

## Erwartete Dateien
- `scripts/meta/fob_screen.gd`
- `scripts/tests/bugfix_fob_second_dropship_assignment_and_scale.gd`
- `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- `docs/tasks/TASK_319_manual_playtest_fob_second_dropship_assignment_scale.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `bugfix_fob_second_dropship_assignment_and_scale.gd`
- [x] `task_316_fob_fireteam_staging_migration.gd`
- [x] `task_308_compact_flightdeck_dropship_occupants_actions.gd`
- [x] `task_310_fob_flightdeck_fireteam_userology_smoke.gd`
- [x] `bugfix_dropship_mission_flow_verifier.gd`
- [x] `git diff --check`

## Risiken
- Der finale Sichtcheck der Shipcard-Proportionen bleibt manuell, weil Headless-Tests kein gutes Urteil ueber transparente Asset-Raender liefern.
