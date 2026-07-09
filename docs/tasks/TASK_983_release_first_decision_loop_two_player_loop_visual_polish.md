# TASK_983 - Release First Decision Loop Two Player Loop Visual Polish

## Ziel / Problem
TASK_982 kann Reibungen im Vier-Choice-Loop benennen, aber noch keine konkreten, anwendbaren Polish-Daten fuer die Runtime-Buttons liefern.

`SECURE`, `PUSH`, `FLANK` und `RESET` sollen sich nicht wie rohe Debug-Knoepfe anfuehlen: groesser lesbar, eindeutig getooltippt, ruhig akzentuiert und mit klarer Confirm-Feedback-Zeile.

## Sinnhaftigkeit / Ursache
Der Spielerloop wird erst angenehm, wenn die naechste Entscheidung im HUD sofort scanbar ist. Kleine Button-Labels brauchen stabile Flaechen, konsistente Tooltips und eine sichtbare `GO separat`-Grenze, damit der Spieler versteht: Choice bestaetigt, Ausfuehrung folgt erst mit `GO`.

## Umfang
- Neuer read-only Visual-Polish-Service fuer TASK_983.
- Vier Button-Visual-Specs fuer die TASK_979-Runtime-Choices.
- Mindestgroessen, Tooltip-Ergaenzungen, Style-IDs, Gruppenlinie und Confirm-Feedback-Zeile.
- Controller-Snapshot und Command-Feedback-Export.
- Anwendung der Visual-Specs auf bestehende Choice-Buttons, ohne neue Command-Logik.

## Nicht-Ziele
- Kein neuer Command-Pfad.
- Kein automatisches `GO`.
- Kein neues UI-Layout-System.
- Kein Combat-, Movement- oder Multiplayer-Rewrite.
- Kein Acceptance-Slice; das ist Folgearbeit.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_982_release_first_decision_loop_two_player_loop_visual_findings.md`
- `docs/tasks/TASK_979_release_first_decision_loop_two_player_loop_runtime_choice_buttons.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_983 blockiert ehrlich, wenn TASK_982 nicht polishbar/read-only ist.
- Eine polishbare TASK_982-Source plus TASK_979-Runtime-Buttons erzeugt vier Button-Visual-Specs.
- Alle Visual-Specs haben stabile Mindestgroesse, Tooltip mit `GO separat`, Style-ID und read-only-Grenze.
- Controller exportiert TASK_983 im Command-Feedback und kann die Visual-Specs auf die bestehenden Choice-Buttons anwenden.
- Snapshot und Controller-Polish erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_visual_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_983_release_first_decision_loop_two_player_loop_visual_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_983_release_first_decision_loop_two_player_loop_visual_polish.gd`
- Regression: TASK_982, TASK_981, TASK_980
- `git diff --check`

## Risiken / offene Punkte
- TASK_983 liefert Polish-Daten und wendet sie an, beweist aber noch keinen akzeptierten Gesamtloop.
- Naechster sinnvoller Schritt: `TASK_984 - Release First Decision Loop Two Player Loop Acceptance Slice`.
