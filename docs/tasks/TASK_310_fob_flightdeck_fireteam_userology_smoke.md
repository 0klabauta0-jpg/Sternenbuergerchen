# TASK_310 - FOB Flightdeck Fireteam Userology Smoke

## Ziel
Die erweiterten FOB/VB-/Flight-Deck-/Fireteam-UX-Tasks sollen zusammen getestet werden: Ankunfts-Pool, kompakte Dropship-Karte, Insassenanzeige, Remove-X, Fireteam-Rahmen, Unassigned-Spalte und Actionstyle-Lesbarkeit.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_303 - FOB Transfer Dragdrop Card Readability
- TASK_307 - FOB Arrivals Unassigned Operator Pool
- TASK_308 - Compact Flightdeck Dropship Occupants Actions
- TASK_309 - Fireteam Assignment Board Compact Frames

## Kontext
Diese Features greifen direkt ineinander. Wenn jemand von der Homebase ankommt, soll er im FOB nicht verloren gehen, ins Dropship oder Fireteam gezogen werden koennen und bei Entfernung wieder in einen nachvollziehbaren Zustand fallen.

## Umfang
1. Automatisierter Smoke:
   - Homebase -> FOB Transit abschliessen.
   - Operator erscheint in Unassigned.
   - Operator in Fireteam ziehen.
   - Operator aus Fireteam per X zurueck in Unassigned.
   - Fireteam umbenennen.
   - Operator/Team ins Dropship boarden.
   - Dropship zeigt Pilot und Insassen.
   - Remove-X im Dropship fordert Confirm und fuehrt in korrekten Zielzustand.
2. Layout-/Lesbarkeit:
   - Actionstyle-Text nicht grau auf grau.
   - Flight Deck kompakt.
   - Fireteam-Rahmen nicht riesig.
   - Mini-Karten noch lesbar.
3. Manual:
   - Fixed FullHD.
   - Drag-and-drop mit ueberlappenden Fenstern.
   - Tooltips fuer Badges/Spezialraenge.

## Nicht-Ziele
- Keine neuen Transfer- oder Air-Asset-Regeln.
- Keine finale Balancing-Entscheidung fuer Fireteam-Groessen.
- Kein Multiplayer-Zwei-Client-Test.

## Akzeptanzkriterien
- [x] TASK_310-Smoke laeuft gruen.
- [x] Unassigned, Fireteam und Dropship zeigen nie dieselbe Person doppelt als aktive Karte.
- [x] Remove-X und Dragdrop fuehren zu nachvollziehbaren Zielzustaenden.
- [x] Actionstyle- und graue UI-Texte sind lesbar.
- [x] Manuelle Checkliste ist angelegt.

## Erwartete Dateien
- `scripts/tests/task_310_fob_flightdeck_fireteam_userology_smoke.gd`
- `docs/manual_checks/fob_flightdeck_fireteam_userology_smoke.md`
- optional `docs/reports/fob_flightdeck_fireteam_userology_report.md`
- `docs/tasks/TASK_310_fob_flightdeck_fireteam_userology_smoke.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_310_fob_flightdeck_fireteam_userology_smoke.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_303_fob_transfer_dragdrop_card_readability.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_307_fob_arrivals_unassigned_operator_pool.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_308_compact_flightdeck_dropship_occupants_actions.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_309_fireteam_assignment_board_compact_frames.gd`
- [ ] `git diff --check`

## Risiken
- Wenn die Tests nur Struktur pruefen, kann echte Lesbarkeit trotzdem leiden; manueller Fixed-FullHD-Check bleibt Pflicht.
- Zu viele kompakte Karten koennen wieder Scroll-/Clipping-Probleme erzeugen.

## Naechster Schritt
Offene Restpunkte aus dem Smoke als kleine Follow-up-Tasks schneiden.
