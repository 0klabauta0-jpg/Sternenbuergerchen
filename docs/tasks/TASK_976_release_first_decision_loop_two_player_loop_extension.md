# TASK_976 - Release First Decision Loop Two Player Loop Extension

## Ziel / Problem
TASK_975 akzeptiert den zweiten Griff als kleinen Ablauf. Jetzt braucht der Spieler danach wieder eine echte naechste Entscheidung, sonst endet der Release-Slice trotz funktionierendem `2ND -> GO -> Feedback` in einer Sackgasse.

## Sinnhaftigkeit / Ursache
Ein taktisches Spiel fuehlt sich erst rund an, wenn Feedback wieder in eine sinnvolle naechste Wahl fuehrt. TASK_976 macht aus dem akzeptierten zweiten Loop eine read-only Auswahl aus `SECURE`, `PUSH`, `FLANK` und `RESET`.

## Umfang
- Read-only Player-Loop-Extension-Analyzer fuer TASK_976.
- Bewertung eines bestandenen TASK_975-Acceptance-Slice.
- Naechste Spielerchoices:
  - `secure_area`
  - `push_objective`
  - `flank_pressure`
  - `reset_spacing`
- Empfehlung aus kleinem taktischem Kontext, ohne Commands oder Movement zu erzeugen.
- Routing zu `TASK_977 - Release First Decision Loop Two Player Loop HUD Wiring`.

## Nicht-Ziele
- Kein Runtime-Button und keine HUD-Verdrahtung in diesem Task.
- Kein automatisches `GO`.
- Keine Command-, Movement-, Combat-, Damage- oder Multiplayer-Mutation.
- Kein neues Missionssystem.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_975_release_first_decision_loop_two_acceptance_slice.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/mission/release_first_decision_loop_two_player_loop_extension.gd`

## Akzeptanzkriterien
- Fehlende oder nicht bestandene TASK_975-Source blockiert.
- Bestandener Acceptance-Slice erzeugt vier naechste Spielerchoices.
- `visible_loop_line` nennt `SECURE / PUSH / FLANK / RESET`.
- Taktischer Kontext kann die Empfehlung auf `push_objective` setzen.
- Der Snapshot bleibt read-only und erzeugt keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_extension.gd`
- `scripts/tests/task_976_release_first_decision_loop_two_player_loop_extension.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_976_release_first_decision_loop_two_player_loop_extension.gd`
- Regressionen: TASK_975, TASK_974, TASK_973
- `git diff --check`

## Risiken / offene Punkte
- TASK_976 erzeugt den naechsten Spielergriff als Contract, zeigt ihn aber noch nicht im HUD. TASK_977 sollte die Zeilen und Choices sichtbar in die bestehenden Command-Surfaces fuehren.
