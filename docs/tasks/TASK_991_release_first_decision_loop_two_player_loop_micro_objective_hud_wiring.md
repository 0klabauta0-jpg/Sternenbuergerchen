# TASK_991 - Release First Decision Loop Two Player Loop Micro Objective HUD Wiring

## Ziel / Problem
TASK_990 erzeugt drei sinnvolle naechste Micro-Objectives, aber sie sind noch kein klarer HUD-Griff fuer den Spieler.

TASK_991 verdrahtet diese read-only Karten als kompakte HUD-Chips und Statuszeilen, damit `SICHERN`, `DRUECKEN` und `SAMMELN` im bestehenden Command-Feedback lesbar werden.

## Sinnhaftigkeit / Ursache
Ein kleines rundes Spiel braucht nach einem Ergebnis sofort einen lesbaren naechsten Griff. Dieser Task macht die Objective-Karten sichtbar planbar, ohne den Auswahl- oder Execute-Pfad schon umzubauen.

## Umfang
- Neuer read-only HUD-Wiring-Service fuer TASK_991.
- Bewertung einer bereiten TASK_990-Quelle.
- Drei HUD-Chips fuer `SICHERN`, `DRUECKEN` und `SAMMELN`.
- Selected-Fireteam-, Mission-Control- und Command-Feedback-Zeilen.
- Fokus auf empfohlene oder per Kontext fokussierte Micro-Objective-Karte.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Kein neuer Runtime-Button.
- Kein automatischer Command-Confirm.
- Kein automatischer `GO`.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Rewrite.
- Kein echtes Choice-Hook-Verhalten; das ist TASK_992.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_990_release_first_decision_loop_two_player_loop_next_micro_objective.md`
- `docs/tasks/TASK_989_release_first_decision_loop_two_player_loop_outcome_playability_slice.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_991 blockiert ehrlich, wenn TASK_990 nicht bereit oder nicht read-only ist.
- Ein bereiter TASK_990-Snapshot erzeugt drei lesbare HUD-Chips.
- Default-Fokus folgt der TASK_990-Empfehlung `SICHERN`.
- Kontext darf eine valide Karte fokussieren, ohne Gameplay-State zu setzen.
- Selected-Fireteam-, Mission-Control- und Command-Feedback-Zeilen nennen den naechsten Griff und behalten `GO separat`.
- Controller exportiert TASK_991 im Command-Feedback.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_991_release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_991_release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.gd`
- Regression: TASK_990, TASK_989, TASK_988
- `git diff --check`

## Risiken / offene Punkte
- TASK_991 macht die Micro-Objectives im Command-Feedback sichtbar, aber noch nicht als echte klickbare Runtime-Auswahl.
- Naechster sinnvoller Schritt: `TASK_992 - Release First Decision Loop Two Player Loop Micro Objective Choice Hook`.
