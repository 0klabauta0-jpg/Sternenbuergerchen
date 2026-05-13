# TASK_398 - Mission Dropship Outbound Command Hotfix

## Ziel
Mission-Dropships sollen nach dem Deboarding waehrend des sichtbaren Abflugs weiter aktiv wirken und bedienbar/angreifbar bleiben. Shipcard-Commands muessen direkt klickbar sein, ohne dass der Spieler die Karte vorher einmal separat auswaehlen muss.

## Sinnhaftigkeit
Der Live-Test zeigt, dass der Ablauf grundsaetzlich funktioniert, aber das UX-Feedback noch falsch wirkt: `outbound` wird wie ein unzugreifbarer Meta-Transit grau dargestellt, obwohl das Schiff noch auf der Missionskarte fliegt. Gleichzeitig fuehlt sich die Bedienung sperrig an, wenn ein Button-Klick zuerst nur die Karte selektiert.

## Umfang
- `outbound` gilt in der Mission nicht mehr als ausgegrauter Transit-Zustand; erst `to_fob`/`to_homebase` wird wieder grau.
- Approach-Buttons werden etwas groesser und nutzen dieselbe Schriftgroesse wie die anderen Dropship-Command-Buttons.
- Card-GUI-Auswahl ignoriert Klicks auf echte Dropship-Command-Buttons, damit diese direkt ausloesen koennen.
- Embarked Fireteams werden nicht als normale linke Bodentrupp-Fireteamkarten dupliziert, solange sie noch im Dropship sitzen.
- Regressionstest fuer Outbound-Zugriff, direkte unselektierte Button-Kommandos und Approach-Button-Groesse.

## Akzeptanz
- Eine Dropshipkarte im Zustand `outbound` ist nicht als `mission_dropship_card_inaccessible` markiert.
- Nach Erreichen des Map-Rand-/Exit-Punkts wechselt die Karte in einen Transit-Zustand und wird wieder ausgegraut.
- Ein unselektierter Dropship-Button kann seinen Craft direkt auswaehlen und den Command ausfuehren.
- `NW`/`NE`/`SW`/`SE` haben dieselbe Button-Schriftgroesse und ausreichend feste Pixelgroesse.
- Ein Fireteam im Dropship erscheint nur in der Dropship-Payloadkarte, nicht zusaetzlich als linke Ground-Fireteamkarte.

## Betroffene Dateien
- `docs/tasks/TASK_398_mission_dropship_outbound_command_hotfix.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_398_mission_dropship_outbound_command_hotfix.gd`

## Pruefung
- [x] `godot --headless --path . --script res://scripts/tests/task_398_mission_dropship_outbound_command_hotfix.gd`
- [x] `godot --headless --path . --script res://scripts/tests/task_397_mission_dropship_ux_hotfix.gd`
- [x] `godot --headless --path . --script res://scripts/tests/task_396_mission_dropship_lz_drop_hotfix.gd`
- [x] `godot --headless --path . --script res://scripts/tests/task_395_manual_dropship_parallel_flow.gd`
- [x] `godot --headless --path . --script res://scripts/tests/task_394_per_craft_shipcard_commands.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Air-Asset-Abschuss selbst bleibt ein eigener Gameplay-/Combat-Task; dieser Task stellt nur sicher, dass die sichtbare Outbound-Phase nicht als unzugreifbarer Meta-Transit dargestellt wird.
