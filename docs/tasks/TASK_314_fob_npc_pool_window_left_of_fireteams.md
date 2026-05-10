# TASK_314 - FOB NPC Pool Window Left Of Fireteams

## Ziel
In der FOB/VB-Ansicht soll links neben `#10 FIRETEAMS` wieder ein eigenes, festes Fenster fuer unzugewiesene NPCs sichtbar sein. Von dort sollen Operator-Karten direkt in die Fireteam-Rahmen gezogen werden koennen.

## Status: IMPLEMENTIERT

## Kontext
TASK_307 und TASK_309 hatten den Unassigned-Pool bereits als Daten-/Userology-Vertrag abgesichert. Im festen Drop-Light-FOB-Layout war das alte Available-Fenster aber noch ausgeblendet, wodurch der Einstieg in die Fireteam-Zuweisung visuell fehlte.

## Umfang
1. Festes Fenster:
   - `#09 NPC POOL` liegt links neben `#10 FIRETEAMS`.
   - FullHD-Layout bleibt fest und rasterbasiert.
   - `#14 FLIGHTDECK` bleibt breit.
2. Drag-and-Drop:
   - NPC-Karten aus `#09` koennen in Fireteams unter `#10` gezogen werden.
   - Fireteam-Mitglieder koennen wieder in den NPC-Pool zurueck.
   - UI setzt nur Meta-Zuweisungen, keine Mission-/SimulationRoot-Wahrheit.
3. Lesbarkeit:
   - Pool hat Header, Hilfetext und Scrollbereich.
   - Nur unzugewiesene, am FOB verfuegbare NPCs werden dort angezeigt.
4. Verifier:
   - Fenster ist sichtbar, fix positioniert und links von `#10`.
   - Zuweisung entfernt NPC aus dem Pool.
   - Ruecknahme fuehrt NPC zurueck in den Pool.

## Nicht-Ziele
- Kein neues Personalwirtschaftssystem.
- Keine automatische Fireteam-Auswahl.
- Kein Umbau von Dropship-, Loadout- oder Mission-State.

## Akzeptanzkriterien
- [x] `#09 NPC POOL` ist im FOB sichtbar und sitzt links neben `#10 FIRETEAMS`.
- [x] `#10`, `#13` und `#14` bleiben feste Drop-Light-Fenster.
- [x] Unassigned-NPCs erscheinen im Pool, zugewiesene NPCs nicht.
- [x] Zuweisung in Fireteams und Ruecknahme in den Pool funktionieren ueber bestehende Meta-Pfade.
- [x] Verifier prueft Layout und Assignment-Zyklus.

## Erwartete Dateien
- `scripts/meta/drop_light_layout_contract.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/tests/task_314_fob_npc_pool_window_left_of_fireteams.gd`
- `docs/tasks/TASK_314_fob_npc_pool_window_left_of_fireteams.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_314_fob_npc_pool_window_left_of_fireteams.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_178_fob_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_181_drop_light_fixed_window_audit_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_307_fob_arrivals_unassigned_operator_pool.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_309_fireteam_assignment_board_compact_frames.gd`
- [x] `git diff --check`

## Risiken
- Die zusaetzliche linke Spalte macht `#13 LOADOUT` schmaler. Weitere Loadout-Politur muss deshalb kompakt bleiben.
- Der Pool darf nicht als zweites Homebase-Roster verstanden werden; er zeigt nur FOB/VB-unassigned Operator.
