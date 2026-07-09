# TASK_966 - Release First Decision Loop Two Execution Hook

## Ziel / Problem
TASK_965 macht die zweite Entscheidung lesbar, aber sie ist noch nicht an einen vorhandenen Ausfuehrungspfad anschliessbar. TASK_966 baut den sicheren Hook: ein ausgewaehlter zweiter Intent wird zu einem Command-Draft, der erst durch bestehende Confirm-/GO-Pfade wirksam werden darf.

## Sinnhaftigkeit / Ursache
Der Ablauf soll sich wie ein kleines Spiel anfuehlen: Nach dem ersten Kontakt kann der Spieler nicht nur `HOLD / ADV / BACK` lesen, sondern sieht auch, welcher vorhandene Befehlspfad dafuer bereitsteht. Gleichzeitig bleibt die Architekturgrenze erhalten: der Hook ruft nichts selbst auf.

## Umfang
- Read-only Analyzer `ReleaseFirstDecisionLoopTwoExecutionHook`.
- Command-Draft fuer:
  - `hold_angle` -> `_issue_command("defend")`, danach `execute_selected_fireteam_orders`
  - `advance_cover` -> `_issue_command("move")`, danach `execute_selected_fireteam_orders`
  - `fallback_regroup` -> `return_selected_fireteams_to_plan`
- Controller-Snapshot `get_release_first_decision_loop_two_execution_hook_snapshot()`.
- Export in `get_command_feedback_snapshot()` als `release_first_decision_loop_two_execution_hook`, Line, Gate und Status.

## Nicht-Ziele
- Kein automatisches Confirm.
- Kein automatisches `GO`.
- Kein neuer Movement-, Fire-, Damage- oder Combat-Resolver.
- Keine Multiplayer-Wahrheit im HUD.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_965_release_first_decision_loop_two_polish.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Bestandener TASK_965-Polish erzeugt `gate = execution_hook_ready`.
- HOLD/ADV/BACK nutzen bestehende Controller-Pfade.
- Der Hook setzt `auto_confirms = false` und `auto_executes_go = false`.
- Snapshot bleibt read-only und erzeugt keine Commands, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.
- Naechster Schritt ist ein GO-Smoke, der die echte Ausfuehrung ueber den vorhandenen Pfad prueft.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_execution_hook.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_966_release_first_decision_loop_two_execution_hook.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_966_release_first_decision_loop_two_execution_hook.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_965_release_first_decision_loop_two_polish.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_964_release_first_decision_loop_two_playtest.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_966 ist bewusst noch kein echter GO-Test. `TASK_967 - Release First Decision Loop Two GO Smoke` sollte nachweisen, dass ein zweiter Intent ueber den vorhandenen Bedienpfad tatsaechlich geplant und danach per GO ausgefuehrt werden kann.
