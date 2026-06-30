# TASK_656 - Frontier Probe Real F6 Visual Review

## Ziel / Problem
TASK_655 hat die sichtbare Mission-Control-Zeile fuer Frontier Probe verdichtet. Jetzt braucht dieser Zustand einen echten F6-Review-Slice: ein lokales PNG-/JSON-Paket, das prueft, ob `PLAN LZ -> AA -> COM 18s -> CARGO | NEXT AA` sichtbar bleibt, die redundante NEXT-Zeile nicht wieder auftaucht und der naechste menschliche Fensterblick sauber vorbereitet ist.

## Sinnhaftigkeit / Ursache
Headless-Gruen allein beweist nicht, dass das HUD im echten Fenster angenehm wirkt. Fuer Spielbarkeit und Optik brauchen wir wieder ein Review-Artefakt mit Viewport-/Evidence-Status, damit konkrete visuelle Folgearbeit auf belegten Befunden basiert.

## Umfang
- Frontier-Probe-F6-Kontext laden und den TASK_655-Visual-Tuning-Snapshot lesen.
- PNG und Manifest unter `tmp/` erzeugen.
- Manifest enthaelt Viewport-Readback-Status, Evidence-Board-Status, Mission-Control-Zeilenbefund, Dichte-Gates und offene manuelle Checks.
- Aktuellen HTML-Handbuchbericht auf TASK_656 aktualisieren.

## Nicht-Ziele
- Kein weiteres Text-/HUD-Tuning ohne echten Sichtbefund.
- Kein neues Objective-, Cargo-, Combat-, Multiplayer- oder Command-System.
- Kein automatischer Debrief-/Homebase-Wechsel.
- Kein Gameplay-State im UI.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_655_frontier_probe_one_screen_visual_tuning_findings.md`
- `docs/tasks/TASK_654_frontier_probe_one_screen_f6_playtest_notes.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- `tmp/frontier_probe_real_f6_visual_review.png` und `.json` werden erzeugt.
- Manifest bestaetigt die sichtbare One-Screen-Zeile.
- Manifest bestaetigt, dass die redundante NEXT-Detailzeile im Mission-Control-Text nicht sichtbar ist.
- Manifest haelt fest, ob ein echter Viewport-Readback oder ein Headless-Evidence-Board vorliegt.
- Manifest markiert `manual_review_required = true` und `manual_review_done = false`.
- Snapshot und Manifest bleiben read-only und setzen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_656_frontier_probe_real_f6_visual_review.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `scripts/tests/task_655_frontier_probe_one_screen_visual_tuning_findings.gd`
- `scripts/tests/task_656_frontier_probe_real_f6_visual_review.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_656_frontier_probe_real_f6_visual_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_655_frontier_probe_one_screen_visual_tuning_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_654_frontier_probe_one_screen_f6_playtest_notes.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_652_current_state_handbook_refresh.gd`
- `git diff --check`

## Risiken / offene Punkte
- Headless erzeugt ein Evidence-Board und ersetzt keinen finalen menschlichen Fensterentscheid.
- Falls die echte F6-Ansicht die Zeile zu schwach, zu tief oder zu klein zeigt, gehoert der konkrete Befund in TASK_657.
