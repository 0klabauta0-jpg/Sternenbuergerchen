# TASK_475 - Fireteam Pathfinding Avoidance Stability Pass

## Ziel / Problem
- Im manuellen Fireteam-Drill kommen Move-/Engage-/Take-Auftraege grundsaetzlich an, aber Mitglieder laufen noch zu oft in Gaensemarsch, blockieren sich an engen Ziel-/Pfadstellen oder bleiben nach Avoidance-Korrekturen schwer nachvollziehbar haengen.

## Sinnhaftigkeit / Ursache
- TASK_460 aktiviert Local Avoidance fuer Fireteam-Bewegung und TASK_461 normalisiert Zielslots auf walkable Tiles. Wenn mehrere Formation-Zielslots jedoch auf dieselbe oder zu nahe Ersatzposition fallen, kann das Team trotz korrektem Command in ein selbst erzeugtes Bottleneck laufen.
- Der Avoidance-Pfad markiert Deadlocks bereits, aber der Terrain-Pfad nutzt diese Markierung noch nicht explizit als Repath-Signal.

## Umfang
- Fireteam-Bewegungszielslots nach Walkable-Normalisierung auf Mindestabstand und gleiche Grid-Zellen pruefen.
- Kollabierte Zielslots deterministisch auf nahe, walkable Ausweichslots verteilen.
- Movement-Snapshot um Slot-Stabilitaetsdiagnose erweitern.
- Terrain-Movement bei `local_avoidance_repath_requested` den Pfad neu berechnen lassen.
- Headless-Verifier fuer Zielslot-Kollaps, Command-Zielkonsistenz und Avoidance-Repath ergaenzen.

## Nicht-Ziele
- Keine neue Navigation-Architektur.
- Keine Cover-Auswahl oder Deckungssuche.
- Keine neue Enemy-KI.
- Keine UI-/HUD-Wahrheit.
- Keine finale raupenartige/ueberschlagende Sequenzlogik.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_460_fireteam_movement_avoidance_stability.md`
- `docs/tasks/TASK_461_fireteam_engage_visual_stuck_hotfix.md`
- `docs/tasks/TASK_463_fireteam_auto_defend_guard_enemy_model_visibility.md`
- `docs/tasks/TASK_474_fireteam_down_vfx_performance_stabilization.md`

## Akzeptanzkriterien
- Wenn Terrain-Walkable-Resolution mehrere Fireteam-Zielslots auf dieselbe Grid-Zelle oder zu nahe Position zieht, verteilt der MovementController sie auf unterscheidbare, walkable Zielslots.
- Die ausgegebenen UnitCommands nutzen dieselben stabilisierten Ziele wie der Movement-Completion-State.
- Der Movement-Snapshot meldet Anzahl, Mindestabstand und Details der Target-Spacing-Reparaturen.
- Ein Command mit `local_avoidance_repath_requested = true` verwirft einen alten Pfad und baut den Terrain-Pfad neu.
- Bestehende TASK_460/TASK_461-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/task_475_fireteam_pathfinding_avoidance_stability_pass.gd`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_475_fireteam_pathfinding_avoidance_stability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_460_fireteam_movement_avoidance_stability.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_461_fireteam_engage_visual_stuck_hotfix.gd`
- `git diff --check`

## Risiken / offene Punkte
- Dieser Pass stabilisiert Zielslots und Repath-Signale, ersetzt aber noch keine echte Deckungssuche in der Bewegung.
- Enge echte Engstellen koennen spaeter weiterhin Bottleneck-Reservierung oder Sequenzlogik brauchen.
