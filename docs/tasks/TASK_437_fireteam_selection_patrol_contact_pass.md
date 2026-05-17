# TASK_437 - Fireteam Selection Patrol Contact Pass

## Ziel / Problem

- Der aktuelle Playtest zeigt vier sichtbare Stoerstellen: Auswahlmarker wirken blau/teilweise wie ein Block unter Units, Fireteam- und #17-Auswahlrahmen sollen gelb sein, Fireteams laufen teils im Gaensemarsch, und gegnerische Drill-NPCs wirken nicht als vier sichtbare patrouillierende/feuernde Kontakte.

## Sinnhaftigkeit / Ursache

- Die Fireteam-Baseline ist jetzt funktional, aber die Lesbarkeit im Fenster muss eindeutiger werden. Auswahlfarbe und Grounding sind reine Anzeige. Formation, Kontaktfeuer und Patrol muessen ueber bestehende Runtime-/Command-/Scenario-Pfade geprueft werden, ohne UI zur Gameplay-Wahrheit zu machen.

## Umfang

- Auswahlfarbe fuer 3D-Map-Marker, Fireteam-Mini-Card und #17-Member-Cards auf Gelb umstellen.
- Sicherstellen, dass Auswahlmarker bodennah bleiben und nicht wie Spawn-/Hoehenbloecke wirken.
- Normale Fireteam-Bewegung gegen Gaensemarsch stabilisieren.
- Klaeren und fixen, warum Move-in-Kontakt nicht feuert, sofern eine bestehende Feuerregel den Kontakt blockiert.
- Drill-Gegner als vier sichtbare Kontakte/Patrol-Teilnehmer absichern.

## Nicht-Ziele

- Kein neues Combat-System.
- Kein neues Enemy-AI-System.
- Kein Flank- oder Skill-Balancing.
- Kein Redesign der Fireteam-Karten.

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
- `docs/tasks/TASK_436_fireteam_sight_security_visuals.md`

## Akzeptanzkriterien

- [x] Selected-Unit-Marker im 3D-Overlay sind gelb und liegen bodennah.
- [x] Ausgewaehlte Fireteam-Mini-Cards und #17-Member-Cards haben gelbe statt cyan/blaue Auswahlrahmen.
- [x] Normale Move-Zielslots bilden eine breite/versetzte Formation statt einer engen Linie hintereinander.
- [x] Move in sichtbaren Feindkontakt erzeugt nachvollziehbare Fire-Events oder einen expliziten Diagnosegrund, warum nicht geschossen wird.
- [x] Drill-Szene zeigt vier getrennte Enemy-Proxies und die vier Scenario-Patrol-Bindings werden aktiv angewendet.

## Betroffene Dateien

- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/ui/tactical_ui_theme.gd`
- `scripts/meta/fob_fireteam_card.gd`
- `scripts/meta/npc_compact_card.gd`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tactical/combat_fire_decision_resolver.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tools/generate_fireteam_command_drill_24x24.gd`
- `maps/fireteam_command_drill_24x24.json`
- `data/mission_scenarios/fireteam_command_drill_24x24.json`
- `scripts/tests/task_437_fireteam_selection_patrol_contact_pass.gd`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_437_fireteam_selection_patrol_contact_pass.gd`
- relevante Regressionen: TASK_423, TASK_424, TASK_432, TASK_435, TASK_436
- `git diff --check`

## Risiken / offene Punkte

- Falls das Nicht-Schiessen durch eine bewusste Combat-ROE kommt, soll zuerst ein Diagnosegrund sichtbar werden statt still eine neue Regel einzubauen.
- Enemy-Patrol bleibt ein Drillmap-Slice und ersetzt keine vollstaendige Enemy-Taktik.
