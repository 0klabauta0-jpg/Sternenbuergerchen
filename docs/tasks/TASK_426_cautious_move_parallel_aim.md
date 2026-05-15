# TASK_426 - Cautious Move Parallel Aim

## Ziel / Problem

Im Playtest startet `Move` mit `C`-Stance sichtbar als Hold-/Deckungsbewegung: ueber einzelnen NPCs steht `HOLD`, nur ein Mitglied laeuft, und die Waffen gehen nicht gemeinsam in Aim. Fuer den aktuellen `Move`-Vertrag soll `C` aber eine vorsichtige Gruppenbewegung sein: alle fitten Mitglieder laufen gleichzeitig, langsamer, mit Waffe im Anschlag.

## Sinn / Ursache

`FireteamBehaviorResolver` liess bei `Move + cautious` den vorsichtigeren Leader-/Trait-Advance-Style (`creep`/`bounding`) bestehen. `FireteamMovementController` interpretiert diese Styles korrekt als Caterpillar/Bounding mit Deckungsgruppe und `hold_position`-Commands. Das ist fuer explizite Advance-Styles sinnvoll, aber nicht fuer den sichtbaren `Move`-Button mit C/N/A-Haltung.

## Umfang

- `Move` wird im Resolver unabhaengig von C/N/A als direkter Gruppen-Travel-Style (`rush`) ausgegeben.
- `cautious` bleibt als Haltung erhalten und steuert weiterhin Aim, Speed x0.65 und Sicht x1.2.
- Explizite `bounding`-/`creep`-Profile im `FireteamMovementController` bleiben unberuehrt.
- Regressionstest fuer Resolver, direkte Runtime-Commands und Drill-Szenenpfad.

## Nicht-Ziele

- Kein Entfernen von Bounding/Caterpillar als Bewegungsmuster.
- Kein neues UI fuer explizite Advance-Styles.
- Keine Aenderung an Defend/Take/Flank-Entscheidungen.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`
- `docs/tasks/TASK_423_normal_move_parallel_spacing.md`
- `docs/tasks/TASK_425_live_move_stance_update.md`

## Akzeptanzkriterien

- [x] `FireteamBehaviorResolver.resolve_profile(..., "move", ..., "cautious")` liefert `advance_style = "rush"` und behaelt `tactical_stance = "cautious"`.
- [x] `Move + cautious` erzeugt fuer alle fitten Fireteam-Mitglieder `move_to_position`-Commands, keine `hold_position`-Deckungsgruppe.
- [x] Alle `Move + cautious`-Commands tragen `movement_posture = "engage"` und `weapon_posture = "aimed"`.
- [x] Der Drill-Szenenpfad startet mit vorher gesetzter C-Stance eine parallele Aim-Bewegung ohne `HOLD`-Commands.

## Betroffene Dateien

- `docs/tasks/TASK_426_cautious_move_parallel_aim.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/tactical/fireteam_behavior_resolver.gd`
- `scripts/tests/task_426_cautious_move_parallel_aim.gd`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_426_cautious_move_parallel_aim.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_421_move_stance_posture_speed_sight.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_425_live_move_stance_update.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_109_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_423_normal_move_parallel_spacing.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Alte Smoke-Tests, die `cautious Move` bewusst als Bounding/Caterpillar-Abkuerzung benutzt haben, sind fachlich ueberholt. Fuer explizite Bounding/Caterpillar-Auswahl braucht es spaeter einen eigenen Bedienpfad.
- `scripts/tests/task_101_verifier.gd` wurde zusaetzlich ausgefuehrt und hat nur auf der alten `cohesion_threshold == 95.0`-Erwartung im Flank-Fall versagt; der Move-/Cautious-Pfad war dort gruen.
