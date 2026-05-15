# TASK_434 - LimboAI Enemy Behavior Adapter Smoke

## Ziel / Problem

Die neu installierte LimboAI-Erweiterung soll in einem kleinen, kontrollierten Slice an das bestehende Enemy-Verhalten angebunden werden.

Der Smoke soll zeigen, dass einfache Enemy-Entscheidungen als Behavior Tree laufen koennen, ohne den bestehenden autoritativen Command-Pfad aufzubrechen.

## Sinnhaftigkeit / Ursache

`MissionCombatLoopDriver` enthaelt aktuell mehrere Enemy-Entscheidungszweige fuer Team-Taktiken, Patrols, Kontakt-Hold und Cover-Reposition. LimboAI passt als Decision-Layer, darf aber keine zweite Gameplay-Wahrheit neben `SimulationRoot` und den bestehenden Runtime-Controllern erzeugen.

## Umfang

- Ein kleiner LimboAI-Adapter fuer Enemy-Patrol, Contact-Hold und Cover-Suche.
- Der Behavior Tree entscheidet nur, welcher bestehende Command-Ausgabepfad genutzt wird.
- Runtime-Mutationen laufen weiter ueber `SimulationRoot.enqueue_command()`.
- Explizite `EnemyTeamTacticsProfile`-Gruppen bleiben vor dem Smoke-Pfad priorisiert.
- Headless-Verifier fuer BT-Klassen, Prioritaet und Command-Quelle.

## Nicht-Ziele

- Kein vollstaendiger Enemy-AI-Refactor.
- Kein Editor fuer BehaviorTree-Assets.
- Kein Ersetzen von `EnemyTeamTacticsProfile`.
- Kein neuer Combat-, LOS-, Terrain- oder Multiplayer-Authority-Pfad.
- Kein Kopieren von OpenRTS-Code in die Runtime.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/enemy_team_tactics_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/tasks/TASK_433_install_third_party_godot_plugins.md`

## Akzeptanzkriterien

- LimboAI-Klassen werden lokal ueber Godot geladen.
- Der Adapter baut einen echten LimboAI-BehaviorTree mit Selector/Sequence/Condition/Action.
- Cover hat Prioritaet vor Contact-Hold, Contact-Hold vor Patrol.
- Der Adapter gibt keine Unit- oder Combat-Wahrheit direkt aus, sondern ruft nur autorisierte Callables auf.
- `MissionCombatLoopDriver` nutzt den Adapter nur als schmalen Smoke-Pfad und laesst bestehende Team-Taktik-Kommandos zuerst laufen.
- Lokale Headless-Pruefung dokumentiert, dass Commands weiter als Dictionaries an `SimulationRoot.enqueue_command()` gehen.

## Betroffene Dateien

- `scripts/tactical/enemy_limbo_behavior_adapter.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_434_limboai_enemy_behavior_adapter_smoke.gd`
- `docs/tasks/TASK_434_limboai_enemy_behavior_adapter_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_434_limboai_enemy_behavior_adapter_smoke.gd`
- `godot_console.exe --headless --path . --quit`
- `git diff --check`

## Risiken / offene Punkte

- Der Slice ist bewusst klein und noch kein endgueltiges Enemy-AI-Authoring-System.
- Der BehaviorTree wird programmgesteuert aufgebaut; ein spaeterer Task kann editorbare `.tres`-Trees einziehen.
- Cover-Suche bleibt ueber Cooldown begrenzt, nutzt aber weiterhin `TerrainRegistry.get_walkable_cover_tiles_in_radius()` und ist damit auf bestehende Terrain-Daten angewiesen.
