# TASK_311 - Dropship LZ Target Pick Accuracy Contract

## Ziel
Beim Dropship-Befehl soll nicht nur ein einzelner Strich oder eine unklare Linie erscheinen. Der User waehlt eine Ziel-LZ, diese Zielzone bleibt sichtbar markiert, und die tatsaechliche Landung trifft je nach Pilot-/Team-Skill in einem begrenzten Abweichungsradius.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_106 - Dropship LZ Insertion und verzoegerte Aktivierung
- TASK_117 - Dropship Deploy als Simulation Effects
- TASK_270 - Commander to Fireteam Leader Delegation Contract
- TASK_277 - Dropship Freighter Anti Armor Threat Contract
- TASK_302 - Dropship Flight Deck Boarding Rename Userology

## Kontext
Aktuell wirkt die LZ-Auswahl wie "nur ein Strich". Der Spieler muss aber immer erkennen, was das gewuenschte Ziel ist. Die echte Landeposition kann leicht abweichen, soll aber nicht so stark streuen, dass der Befehl unkontrollierbar wirkt.

## Umfang
1. Datenvertrag:
   - `requested_lz_grid` oder `target_lz_position` als Zielwahrheit des Commander-Befehls.
   - `resolved_lz_grid` oder `actual_landing_position` als berechnete Landeposition.
   - `lz_accuracy_radius` oder `landing_deviation` als Diagnose/Feedback.
   - Seeded Abweichung fuer Tests und Multiplayer.
2. Skill-Einfluss:
   - Pilot-/Dropship-/Team-Skill beeinflusst Abweichung.
   - Abweichung bleibt im V1 eng begrenzt.
   - Keine extreme Fehl-Landung ohne spaeteren eigenen Risk-Task.
3. Visual:
   - Ziel-LZ bleibt als Zielmarker sichtbar.
   - Tatsaechliche Landung wird separat sichtbar, sobald berechnet/ausgefuehrt.
   - Linie/Approach-Strich darf unterstuetzen, aber nicht die einzige Information sein.
4. Gameplay:
   - Fireteam startet an der tatsaechlichen Landeposition.
   - Commander-/FTL-Plan referenziert weiterhin das Ziel und bekommt Feedback, falls Abweichung relevant ist.
   - Multiplayer nutzt serverautoritative resolved LZ.
5. Verifier:
   - Ziel und tatsaechliche LZ sind getrennt.
   - Seeded Abweichung bleibt innerhalb Limit.
   - Skill reduziert Abweichung.
   - Insertion nutzt resolved LZ, UI zeigt requested LZ.

## Nicht-Ziele
- Keine neue Flugphysik.
- Keine grosse Crash-/Scatter-Mechanik.
- Keine feindliche Luftabwehr in diesem Task.
- Keine komplette Command-Matrix-UI-Anordnung; das kommt in TASK_312.

## Akzeptanzkriterien
- [x] LZ-Befehl speichert requested und resolved LZ getrennt.
- [x] User sieht die Ziel-LZ jederzeit klar.
- [x] Tatsaechliche Landung kann leicht skillabhaengig abweichen.
- [x] Abweichung bleibt im V1 klein und seeded testbar.
- [x] Fireteam wird an der resolved LZ aktiviert.
- [x] Verifier prueft Skill, Radius, Visual-Snapshot und Multiplayer-Authority-Felder.

## Erwartete Dateien
- `scripts/meta/...`
- `scripts/mission/...`
- `scripts/command/...`
- `scripts/tactical/...`
- `scripts/tests/task_311_dropship_lz_target_pick_accuracy_contract.gd`
- `docs/dev/dropship_lz_target_accuracy_contract.md`
- `docs/manual_checks/dropship_lz_target_pick_accuracy_checklist.md`
- `docs/tasks/TASK_311_dropship_lz_target_pick_accuracy_contract.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_311_dropship_lz_target_pick_accuracy_contract.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_106_dropship_lz_insertion_und_verzoegerte_aktivierung.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_117_verifier.gd`
- [ ] `git diff --check`

## Risiken
- Zu grosse Abweichung macht den Befehl frustrierend.
- Wenn Ziel- und Landeposition nicht getrennt sind, wird UI wieder zur falschen Gameplay-Wahrheit.
- Multiplayer muss die resolved LZ vom Server bekommen.

## Naechster Schritt
TASK_312 ordnet LZ-Pick und Go-Button in der Command Matrix neu an.
