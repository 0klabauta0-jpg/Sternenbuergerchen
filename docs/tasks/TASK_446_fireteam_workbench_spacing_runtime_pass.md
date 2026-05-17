# TASK_446 - Fireteam Workbench Spacing Runtime Pass

## Ziel / Problem

Die aus der Formation-Workbench exportierten Move-/Engage-Werte sollen als erste Runtime-Baseline gegen sichtbaren Gaensemarsch, zu enge Zielslots und Buddy-Team-Klumpen genutzt werden.

## Sinnhaftigkeit / Ursache

Die bisherigen Formation-Zielslots im `FireteamMovementController` waren noch aus einer alten kompakten Baseline abgeleitet. Dadurch konnten Teams trotz parallelem Move wieder wie eine Reihe oder ein dichter Klumpen wirken.

## Umfang

- Workbench-Exports unter `docs/reports/fireteam_formation_tuning_*.json` als Playtest-Input auswerten.
- Move C/N/A und Engage C/N/A auf groessere, symmetrische Zielslot-Abstaende abbilden.
- Buddy-Paare bleiben Zweierteams; Zielslots vermeiden bewusst Einheiten auf demselben Tile.
- Kleine Regression fuer Formation-Breite, Mindestabstand und Engage-Fireline.

## Nicht-Ziele

- Kein neues Gameplay-State-System.
- Kein Flank-Rewrite.
- Keine Skill-/Mut-/Leadership-Skalierung.
- Kein Umbau von Pathfinding, Collision oder Local Avoidance.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/tasks/TASK_445_html_report_workbench_standard.md`
- `docs/reports/fireteam_formation_tuning_workbench.html`

## Akzeptanzkriterien

- Move C/N/A erzeugt keine einseitige Zielslot-Linie mehr und haelt einen sichtbaren Mindestabstand.
- Engage Aggressive bewegt alle Mitglieder als breite Fireline.
- Engage C/N-Bounds behalten Buddy-Teams und groessere Zielslot-Abstaende.
- Runtime-Snapshot zeigt die genutzten Formation-Spacing-Werte.
- Bestehende Engage-/Take-Doktrin-Tests bleiben gruen.

## Betroffene Dateien

- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/task_446_fireteam_workbench_spacing_runtime_pass.gd`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_446_fireteam_workbench_spacing_runtime_pass.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_446_fireteam_workbench_spacing_runtime_pass.gd`
- Relevante TASK_442/TASK_443-Regressionen
- `git diff --check`

## Risiken / offene Punkte

- Die Werte sind eine erste Runtime-Baseline aus der Workbench, noch kein finales Balancing.
- Local Avoidance und Terrain-Pathing koennen die Zielslots spaeter weiterhin beeinflussen; dieser Task setzt nur die gewollten Formation-Ziele sauberer.
