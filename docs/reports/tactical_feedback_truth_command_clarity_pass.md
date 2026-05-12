# Tactical Feedback Truth Command Clarity Pass

## Ergebnis
TASK_335 ist umgesetzt. Mission-Kommandos liefern jetzt neben dem bisherigen Legacy-`disabled_reason` stabile `disabled_reason_code`-, `disabled_reason_text`- und `disabled_reason_short`-Felder.
Die vorhandenen Disabled-Reasons bleiben kompatibel und bekommen konkrete spielbare Kurztexte.

## Geaendert
- `MissionCommandHierarchyContract` unterscheidet fehlende Fireteam-Auswahl, fehlendes Tile, invalides Tile, fehlende LZ, fehlendes Drop-Team, belegte Air Lane, Cooldown, Observer Mode und fehlende GO-Orders.
- Mission-Buttons uebernehmen diese Codes in ihre Metadaten und Tooltips. Bestehende Legacy-Texte bleiben erhalten, damit alte Regressionstests weiter auf `select`/`map tile` pruefen koennen.
- `MissionTacticalSandboxController` blockt tile-pflichtige Kommandos jetzt auch bei invalidem gespeicherten Tile und meldet `INVALID TILE SELECTED`.
- Der Drop-Button und die Mission-Control-Statuszeile zeigen die wichtigsten Drop-Blocker kurz sichtbar an: `Set LZ`, `Board`, `Air Busy`, `Air Lane belegt`.
- Der Feedback-Snapshot enthaelt `command_clarity` als read-only Zusammenfassung aktiver und blockierter Actions.

## Truth Boundary
Die UI speichert weiterhin keine Gameplay-Wahrheit. Der Contract wertet nur den vom Controller gelieferten Kontext aus. Der Adapter dupliziert Snapshot-Daten defensiv und enthaelt keine `SimulationRoot`-Mutation.

## Verbleibende Playtest-Fragen
- Sind die kurzen Button-Labels `Board` und `Air Busy` im kompakten HUD eindeutig genug?
- Soll die Statuszeile bei gleichzeitig fehlender LZ und fehlendem Team immer LZ priorisieren, oder braucht der Playtest eine andere Reihenfolge?
- Sind Tooltips im Missionsfluss auffindbar genug, oder braucht ein spaeterer UX-Task dezente Inline-Hints?

## Lokale Pruefung
- `scripts/tests/task_335_tactical_feedback_truth_command_clarity_pass.gd`
- `scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- `scripts/tests/task_315_mission_grid_tile_selection_command_gate.gd`
- `scripts/tests/bugfix_mission_right_click_order_flow.gd`
- `git diff --check`
