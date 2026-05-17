# TASK_460 - Fireteam Movement Avoidance Stability

## Ziel / Problem
- Im manuellen Drill-Playtest bleiben Fireteam-Mitglieder bei Move/Engage/Take sichtbar haengen, laufen teilweise in Gaensemarsch und stehen zu eng oder unlesbar aufeinander.

## Sinnhaftigkeit / Ursache
- Der Fireteam-Pfad erzeugt bereits eigene Zielslots und `SimulationRoot` besitzt Local Avoidance. Der Drill-Pfad aktiviert diesen Avoidance-Pfad fuer Fireteam-Commands aber nicht verlaesslich, solange der globale `SimulationRoot.local_avoidance_enabled`-Schalter aus ist.

## Umfang
- Fireteam-Bewegungscommands sollen command-lokal Local Avoidance anfordern.
- `SimulationRoot` soll den Avoidance-Resolver auch fuer solche command-lokalen Anforderungen vorbereiten.
- Local Avoidance darf ausweichen, muss aber weiter Mindestfortschritt in Richtung Ziel behalten.
- Der Debug-Snapshot soll sichtbar machen, dass Avoidance durch einen Command opt-in aktiv wurde.
- Headless-Verifier fuer Fireteam-Command-Opt-in und command-lokale Avoidance ergaenzen.

## Nicht-Ziele
- Keine neue Pathfinding-Architektur.
- Keine finale Bounding-/raupenartige Sequenzlogik.
- Keine neue Gegner-KI.
- Keine UI-/HUD-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_459_fireteam_engage_orientation_enemy_proxy_fix.md`
- `docs/tasks/TASK_446_fireteam_workbench_spacing_runtime_pass.md`
- `docs/tasks/TASK_423_normal_move_parallel_spacing.md`

## Akzeptanzkriterien
- Fireteam Move/Engage/Take-Bewegungscommands tragen `local_avoidance_enabled = true`.
- Hold-/Cover-Commands werden nicht kuenstlich zu Movement-Avoidance-Commands.
- `SimulationRoot` baut Local-Avoidance-Nachbarn auch dann auf, wenn nur der einzelne Command Avoidance angefordert hat.
- Local Avoidance erhaelt einen Mindestanteil Vorwaertsbewegung, damit Zielabschluss nicht durch seitliche Korrektur ausbleibt.
- Der Local-Avoidance-Debug-Snapshot zeigt command-lokales Opt-in.
- Bestehende Movement-/Spacing-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/core/simulation_root.gd`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/task_460_fireteam_movement_avoidance_stability.gd`
- Doku/Status/Roadmap

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_460_fireteam_movement_avoidance_stability.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_423_normal_move_parallel_spacing.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_446_fireteam_workbench_spacing_runtime_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Dieser Slice stabilisiert den vorhandenen Avoidance-Pfad. Echte Terrain-Engstellen, falsche Zielslots oder spaetere Sequenz-Haenger muessen danach separat diagnostiziert werden.
- Enemy-Patrouille, Enemy-Body-Rendering und Combat-Facing bleiben Folgepruefungen aus den angrenzenden Tasks.
