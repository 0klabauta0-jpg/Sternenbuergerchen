# TASK_435 - Fireteam Manual Visual Regression Pass

## Ziel / Problem

- Der aktuelle Fireteam-Basisstand soll im Godot-Fenster gegen die Drillmap sichtgeprueft und headless abgesichert werden.
- Auffaellige Fensterprobleme sollen direkt gegen die neue Baseline gefixt werden: parallele Bewegung, klare Aim-/Fire-Visuals, sichtbare Gegner, keine doppelten Auswahlmarker und lesbare Command-Bubbles.

## Sinnhaftigkeit / Ursache

- TASK_429 bis TASK_432 haben die Runtime-Baseline fuer `Move`, `Engage`, `Take` und `Defend` bewusst neu ausgerichtet.
- Die Headless-Tests pruefen einzelne Ausschnitte, aber der manuelle Playtest-Pfad muss als zusammenhaengender Sicht-/Feedback-Loop stabil bleiben.

## Umfang

- Drillmap- und Mission-Tactical-Snapshots fuer `C -> Move -> GO`, `Engage Area -> GO -> Take Area`, Feuerkontakt und Auswahlvisuals pruefen.
- Fehlende Diagnose oder schwache Visual-Signale nur dort ergaenzen, wo sie dem sichtbaren Basisverhalten dienen.
- Bestehende Baseline-Regeln nicht durch Flank-, Bounding- oder Legacy-Fallbacks ueberdecken lassen.
- Eine kleine neue Regression fuer den kombinierten Fenster-/Snapshot-Pfad anlegen.

## Nicht-Ziele

- Kein neues Flank-System.
- Kein vollstaendiger Enemy-AI-Ausbau.
- Kein Charakterbogen-/Skill-Balance-Pass.
- Kein UI-Redesign jenseits konkreter Lesbarkeits- oder Doppelungsfixes.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_429_fireteam_behavior_modes_runtime.md`
- `docs/tasks/TASK_431_fireteam_aim_pose_and_card_ui_hotfix.md`
- `docs/tasks/TASK_432_fireteam_muzzle_flash_and_baseline_attack_movement.md`

## Akzeptanzkriterien

- [x] `C -> Move -> GO` erzeugt fuer alle fitten Mitglieder parallele Move-Kommandos mit Aim-/Cautious-Diagnose und ohne `HOLD`-Label.
- [x] Live-Wechsel C/N/A waehrend aktiver Move-Ausfuehrung aktualisiert Command-Revision, Haltung, Speed und Sicht ohne alten Requeue-Override.
- [x] Feuerkontakt meldet sichtbaren Muzzle Flash und Bloom-Marker aus vorhandenen Fire-Events.
- [x] Vier eigene und vier gegnerische Drill-Proxies sind sichtbar, animierte Modelle bleiben aktiv und Team-Basen sind lesbar.
- [x] Auswahlvisuals zeigen nur den 3D-Bodenmarker; alte 2D-Auswahlringe bleiben nach Refresh unterdrueckt.
- [x] FTL-Bubble und `#17`-Status beschreiben den aktiven Befehl konkret statt generisch.
- [x] `Engage Area -> GO -> Take Area` bleibt getrennt: Engage kaempft ohne Besitzpflicht, Take besetzt/kontrolliert.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_435_fireteam_manual_visual_regression_pass.gd`
- `docs/tasks/TASK_435_fireteam_manual_visual_regression_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_435_fireteam_manual_visual_regression_pass.gd`
- Relevante Regressionen: TASK_424, TASK_425, TASK_426, TASK_431, TASK_432
- `git diff --check`

## Risiken / offene Punkte

- Headless-Snapshots ersetzen keinen finalen optischen Blick auf Kamera, Groesse und Lesbarkeit im Godot-Fenster.
- Der Pass soll nur die neue Baseline stabilisieren; groessere Taktikideen bleiben Folge-Tasks.
