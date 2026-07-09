# TASK_965 - Release First Decision Loop Two Polish

## Ziel / Problem
TASK_964 beweist, dass die zweite Entscheidung sichtbar ist. Fuer Spielgefuehl muss der Spieler aber auch sofort verstehen, was `HOLD`, `ADV` und `BACK` bedeuten und dass daraus erst nach `GO` ein echter Befehl wird.

## Sinnhaftigkeit / Ursache
Die bisherige zweite Zeile ist lesbar, aber noch eher ein Auswahltext. TASK_965 macht daraus einen kompakten Intent-Readout: `HOLD Defend`, `ADV Move`, `BACK Return`. So entsteht ein klarer naechster Griff, ohne die SimulationRoot-/GO-Grenze zu umgehen.

## Umfang
- Read-only Analyzer `ReleaseFirstDecisionLoopTwoPolish`.
- Stabile Intent-Reihenfolge:
  - `hold_angle` -> `defend`
  - `advance_cover` -> `move`
  - `fallback_regroup` -> `return`
- Controller-Snapshot `get_release_first_decision_loop_two_polish_snapshot()`.
- HUD-Zeilenhelper `_build_release_first_decision_loop_two_polish_hud_line()`.
- Export in `get_command_feedback_snapshot()` als `release_first_decision_loop_two_polish`, Line, Gate und Status.

## Nicht-Ziele
- Kein Ausfuehren der zweiten Entscheidung.
- Kein neuer Movement-, Fire-, Damage- oder Combat-Resolver.
- Kein Command vor `GO`.
- Keine neue Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_964_release_first_decision_loop_two_playtest.md`
- `docs/tasks/TASK_963_release_first_decision_next_playable_loop.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Bestandener TASK_964-Playtest und aktiver TASK_963-Loop erzeugen `gate = loop_two_polish_passed`.
- Die drei Intents bleiben stabil geordnet und nutzen `defend`, `move`, `return`.
- Alle Intents behalten `execution_boundary = requires_go` und erzeugen keine Commands oder Movement.
- Sichtbare Zeilen zeigen keine rohen Choice-IDs.
- Fehlende Choice routet zurueck zu `TASK_965 - Release First Decision Loop Two Polish`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_965_release_first_decision_loop_two_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_965_release_first_decision_loop_two_polish.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_964_release_first_decision_loop_two_playtest.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_963_release_first_decision_next_playable_loop.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_965 baut Intent-Lesbarkeit, noch keine echte Ausfuehrung. Naechster sinnvoller Schritt ist `TASK_966 - Release First Decision Loop Two Execution Hook`, der diese Intents an den vorhandenen GO-/Command-Pfad anschliesst.
