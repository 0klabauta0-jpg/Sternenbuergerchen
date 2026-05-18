# TASK_476 - Fireteam Corridor Lane Cover Navigation

## Ziel / Problem

Fireteams laufen nach den ersten Avoidance-Fixes seltener auf denselben Zielslot, koennen aber auf dem Weg dorthin weiterhin in Gaensemarsch, seitliche Umwege oder blocker-nahe Engstellen fallen.

Dieser Task fuehrt eine erste, kontrollierte Runtime-Regel fuer Wegkorridore, Buddy-Lanes und Blocker-/Deckungsgewichtung ein.

## Sinnhaftigkeit / Ursache

TASK_475 stabilisiert Zielslots vor dem Enqueue. Der eigentliche Terrain-Pfad pro Unit weiss aber noch nicht, welche Fireteam-Lane sie halten soll und wie stark sie sich vom Marschkorridor entfernen darf. Dadurch koennen mehrere Units trotz guter Zielslots denselben guenstigen Pfad waehlen.

## Umfang

- Fireteam-Bewegungscommands erhalten Navigationsmetadaten fuer:
  - Marschkorridor vom aktuellen Anchor zum naechsten Anchor
  - per Unit gesetzte Buddy-/Formation-Lane
  - Cover-/Exposure-/Blocker-Gewichtung aus Command und C/N/A-Haltung
- `SimulationRoot` normalisiert diese Metadaten in Navigation-Cost-Options.
- `TerrainPathfinder` bewertet Korridor-, Lane- und Blocker-Clearance-Kosten zusaetzlich zu bestehenden Surface-/Cover-/Exposure-Kosten.
- Debug-/Snapshot-Daten bleiben Command-/Navigation-nah und erzeugen keine neue UI-Wahrheit.

## Nicht-Ziele

- Kein komplett neues Pathfinding-System.
- Keine finale Cover-Auswahl oder Deckungssuche im Kampf.
- Keine Doctrine-Sequenzen wie raupenartig/ueberschlagend.
- Keine automatische Enemy-Gefahrenkarte, wenn der FireteamController keinen Kontaktkontext hat.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_475_fireteam_pathfinding_avoidance_stability_pass.md`

## Akzeptanzkriterien

- Fireteam Move/Engage/Take-Bewegungscommands tragen `navigation_corridor_enabled`, Korridor-Endpunkte, Lane-Offset, Lane-Gewicht, Cover-/Exposure-Gewichte und Blocker-Clearance-Gewicht.
- `SimulationRoot._build_navigation_cost_options()` uebergibt diese Werte an den Pathfinder in Grid-Normalform.
- `TerrainPathfinder` kann Kosten fuer:
  - Abstand ausserhalb des Marschkorridors
  - Abweichung von der Unit-Lane
  - Naehe zu nicht-walkable/LOS-blockenden Blockern
  berechnen.
- Ein Verifier prueft Command-Metadaten, Cost-Option-Normalisierung und Kostenunterschiede fuer Lane/Cover/Blocker.
- Bestehende TASK_475-Regression bleibt gruen.

## Betroffene Dateien

- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/core/simulation_root.gd`
- `scripts/terrain/terrain_pathfinder.gd`
- `scripts/tests/task_476_fireteam_corridor_lane_cover_navigation.gd`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_476_fireteam_corridor_lane_cover_navigation.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_475_fireteam_pathfinding_avoidance_stability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte

- Dieser Pass bewertet Pfade, reserviert aber keine Engstellen zeitlich. Bei echten Bottlenecks kann spaeter eine Reservierungs-/Sequenzlogik noetig bleiben.
- Ohne Kontakt-/Enemy-Hazard-Kontext kann Exposure nur vorbereitend gewichtet werden; sichtbare Feindlinien brauchen einen separaten Kontakt-/Gefahrenkarten-Pass.
