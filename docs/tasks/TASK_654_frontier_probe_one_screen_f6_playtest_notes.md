# TASK_654 - Frontier Probe One-Screen F6 Playtest Notes

## Ziel / Problem
TASK_653 macht den Frontier-Probe-Ablauf als kompakte `PLAN ... | NEXT ...`-Zeile lesbar. Jetzt braucht der Slice ein pruefbares F6-Playtest-Notizpaket: Ist die Zeile im FullHD-Missionsbild dicht genug, fuehrt sie durch LZ, AA, Computer, Cargo und Debrief, und bleibt sie eindeutig als Anzeige statt Gameplay-Wahrheit markiert?

## Sinnhaftigkeit / Ursache
Headless-Verifier beweisen den Contract, aber nicht das menschliche Fenstergefuehl. Fuer die naechste Spielbarkeitsentscheidung brauchen wir ein lokales PNG-/JSON-Artefakt, das den Sichttest vorbereitet und die offenen manuellen Checks festhaelt.

## Umfang
- TASK_653-One-Screen-Snapshot im F6-Testkontext erneut lesen.
- Lokales Evidence-Board und Manifest unter `tmp/` erzeugen.
- Manifest enthaelt Planzeile, Mission-Control-Einbettung, Planoptionen, Sichtcheckliste, Viewport-/Readback-Status und Read-only-Grenzen.
- Aktuellen HTML-Handbuchbericht auf TASK_654 aktualisieren.

## Nicht-Ziele
- Kein neues Gameplay und kein neuer Command.
- Kein echter automatischer Sichttest mit menschlicher Bewertung.
- Kein Combat-, Objective-, Cargo- oder Multiplayer-Rewrite.
- Kein neues HUD-System.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_653_frontier_probe_one_screen_playability_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- `tmp/frontier_probe_one_screen_f6_playtest_notes.json` und `.png` werden erzeugt.
- Manifest nennt die kompakte `PLAN LZ -> AA -> COM 18s -> CARGO | NEXT AA`-Zeile.
- Manifest markiert `manual_review_required = true` und `manual_review_done = false`.
- Manifest bestaetigt, dass Mission Control und Command-Feedback dieselbe Zeile liefern.
- Manifest bleibt read-only und setzt keine Gameplay-Wahrheit.
- Report nennt TASK_654 als letzten Stand und empfiehlt einen kleinen Visual-Tuning-Follow-up.

## Betroffene Dateien
- `docs/tasks/TASK_654_frontier_probe_one_screen_f6_playtest_notes.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `scripts/tests/task_652_current_state_handbook_refresh.gd`
- `scripts/tests/task_653_frontier_probe_one_screen_playability_pass.gd`
- `scripts/tests/task_654_frontier_probe_one_screen_f6_playtest_notes.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_654_frontier_probe_one_screen_f6_playtest_notes.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_653_frontier_probe_one_screen_playability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_652_current_state_handbook_refresh.gd`
- `git diff --check`

## Risiken / offene Punkte
- Headless laeuft als Evidence-Board und ersetzt keinen echten F6-Fensterblick.
- Die Checkliste ist ein Review-Werkzeug, kein Spielsystem.
- Ein belegter visueller Befund gehoert in einen Folge-Slice, nicht in diesen Task.
