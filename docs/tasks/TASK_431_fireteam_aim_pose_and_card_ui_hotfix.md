# TASK_431 - Fireteam Aim Pose And Card UI Hotfix

## Ziel / Problem
- Cautious-Move soll sichtbar mit gehobener Waffe laufen.
- Die Fireteam-Mini-Card oben links darf beim C/N/A-Umschalten nicht flackern oder Klicks verlieren.
- FTL-Bubbles sollen einander ersetzen, damit nie mehrere alte Befehlsblasen hintereinander stehen.
- Command-Matrix #16 braucht unten rechts einen festen Wegpunkt-Loeschbutton.

## Sinnhaftigkeit / Ursache
- Die Aim-Pose nutzte bisher den ersten Key der Shoot-Animation; dieser kann noch die gesenkte Waffe enthalten.
- Die Mini-Card wurde bei jedem Refresh geloescht und neu gebaut. Dadurch verliert der Button unter der Maus seinen Zustand.
- Mehrere Feedback-Bubbles machen den aktuellen Befehl schwer lesbar.

## Umfang
- Aim-Hold aus einem mittleren Shoot-Key sampeln und fuer Upper-Body-Combat-Clips als statische Hold-Pose verwenden.
- Mini-Cards pro Fireteam wiederverwenden statt neu zu erzeugen.
- Ueberfluessige FTL-Readiness-Gauge in der Mini-Card entfernen, Loadout-Text ausblenden und Readiness unten anzeigen.
- Mini-Mitgliederportraits und Statusreihe unten in der Mini-Card anzeigen.
- `WP-` in Slot #16.20 als Alias fuer Wegpunkt-/Order-Loeschen ergaenzen.

## Nicht-Ziele
- Keine neue Fireteam-KI oder neue Command-Semantik.
- Kein Entfernen der internen Return-to-Plan-/Recovery-Mechanik.
- Kein Rework der Charakterbogenwerte.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`
- `docs/tasks/TASK_425_live_move_stance_update.md`
- `docs/tasks/TASK_426_cautious_move_parallel_aim.md`
- `docs/tasks/TASK_427_fireteam_decision_feedback_aim_pose.md`

## Akzeptanzkriterien
- `C -> Move -> GO` aktiviert sichtbar eine Upper-Body-Aim-Hold-Pose und bleibt nicht auf dem gesenkten ersten Shoot-Key.
- C/N/A-Buttons in der Mini-Card behalten ihre Instanzen ueber UI-Refreshes und schalten ohne Flackern.
- Die Mini-Card zeigt keinen runden FTL-Readiness-Indikator und keinen `LD MEDIUM`-Text mehr.
- Readiness steht unten in der Mini-Card; Mitglieder werden als kleine Portraits angezeigt.
- Es gibt maximal eine aktive FTL-Befehlssprechblase.
- #16.20 zeigt `WP-`, bleibt quadratisch und loescht wie `Del` den fokussierten Wegpunkt oder Area-Order.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/ui/mission_command_hierarchy_contract.gd`
- `scripts/tests/task_422_go_continue_fireteam_hud_cleanup.gd`
- `scripts/tests/task_431_fireteam_aim_pose_and_card_ui_hotfix.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_431_fireteam_aim_pose_and_card_ui_hotfix.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_422_go_continue_fireteam_hud_cleanup.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_427_fireteam_decision_feedback_aim_pose.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_403_runtime_animation_combat_cases.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der gewaehlte Shoot-Key ist ein erster sichtbarer Fix. Falls das Modell spaeter eigene Aim-Idle-Clips bekommt, sollte dieser Hold-Pose-Sampler durch explizite Aim-Clips ersetzt werden.
