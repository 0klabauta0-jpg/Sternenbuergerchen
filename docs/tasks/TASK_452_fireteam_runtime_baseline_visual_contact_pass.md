# TASK_452 - Fireteam Runtime Baseline Visual Contact Pass

## Ziel / Problem

Die Workbench-Runtime-Baseline soll spielbar kontrollierbar werden: fehlende Formationsstartwerte ergaenzen, Aim-Bereitschaft sichtbar machen, Area-Folgeauftraege stabilisieren und Kontakt-/Enemy-Visuals im Drillfenster lesbar machen.

## Sinnhaftigkeit / Ursache

TASK_451 hat C/N/A-Werte und erste Workbench-Formationen in den Runtime-Pfad gebracht. Im Playtest bleiben aber noch Luecken: Take C/N und Defend C/N/A fallen auf alte Formationslogik zurueck, `aim_readiness_percent` wird zwar transportiert, ist aber noch nicht sichtbar wirksam, und Area-/Enemy-/Kontakt-Feedback muss gegen die neue Baseline kontrolliert werden.

## Umfang

- Sinnvolle Startformationen fuer Take C/N und Defend C/N/A im `FireteamMovementController` anlegen.
- `aim_readiness_percent` so in UnitCommands/Visualdiagnose anbinden, dass C/Aim-Bereitschaft sichtbar frueher oder stabiler als niedrige Werte wirkt.
- Engage-Area -> Take-Area und weitere Area-Folgeauftraege gegen die Mission-Tactical-Queue pruefen und bei blockierendem Zustand reparieren.
- Enemy-/Kontakt-Feedback kontrollieren: Gegner sichtbar/patrouillierend, rote Schusslinie bei erkanntem Gegner und sichtbarer Muzzleflash.

## Nicht-Ziele

- Keine finale Skill-Skalierung aus Charakterboegen.
- Kein neuer Behavior-Tree-Umstieg.
- Keine grosse Pathfinding-/Local-Avoidance-Neuarchitektur.
- Keine neue Workbench-Seite, solange die Runtime-Baseline im Vordergrund steht.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/enemy_team_tactics_contract.md`
- `docs/tasks/TASK_451_fireteam_workbench_runtime_import.md`
- `docs/tasks/TASK_438_fireteam_contact_visibility_attack_visuals.md`
- `docs/tasks/TASK_440_enemy_limbo_contact_diagnostics.md`

## Akzeptanzkriterien

- Take C/N und Defend C/N/A melden Workbench-/Runtime-Preset-Keys statt stummem Fallback.
- UnitCommands enthalten eine sichtbare Aim-Bereitschaftsableitung fuer Visual/Timing.
- Area-Folgeauftraege bleiben ausfuehrbar, nachdem ein Engage-/Take-Area-Befehl abgearbeitet wurde.
- Kontaktlinien werden bei Gegnerkontakt rot, Muzzleflash-Ereignisse bleiben im Combat-Snapshot sichtbar.
- Tests decken die neuen Startwerte und mindestens einen Area-/Kontakt-Verifier ab.

## Betroffene Dateien

- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/npc/unit_runtime_status.gd`
- `scripts/npc/test_unit.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_452_fireteam_runtime_baseline_visual_contact_pass.gd`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_452_fireteam_runtime_baseline_visual_contact_pass.gd`
- Relevante TASK_451/TASK_446/TASK_438/TASK_440-Regressionen
- `git diff --check`

## Risiken / offene Punkte

- Die neuen Formationen sind Startwerte, keine finalen Workbench-Exporte.
- Aim-Bereitschaft kann zunaechst nur als Visual-/Timing-Hook wirken; die finale Animation kann spaeter weiter verfeinert werden.
