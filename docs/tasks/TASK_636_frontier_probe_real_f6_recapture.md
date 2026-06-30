# TASK_636 - Frontier Probe Real F6 Re-Capture

## Ziel / Problem
TASK_635 hat den echten Callout-Sichtbefund aus TASK_634 visuell gepolished: staerkere Labels, Route-Linien und ein ausweichendes Mission-Result-Label. Was noch fehlt, ist ein reproduzierbarer Re-Capture, der belegt, dass diese Nachbesserung im echten F6-/Viewport-Pfad ankommt.

## Sinnhaftigkeit / Ursache
Der vorherige Sichttest hat gezeigt, dass Datenfluss allein nicht reicht. Nach einem Visual-Fix braucht es wieder ein Bild-/Manifest-Artefakt, damit der naechste Schritt nicht auf Bauchgefuehl, sondern auf einem konkreten Screenshotpaket aufsetzt.

## Umfang
- Einen Re-Capture-Verifier fuer den abgeschlossenen Frontier-Probe-Zustand erstellen.
- Dasselbe FullHD-PNG-/Manifest-Prinzip wie TASK_634 nutzen.
- TASK_635-Style-Felder im Re-Capture pruefen: High-Contrast-Style, Font, Outline und Route-Linien.
- Reports und Contract auf TASK_636 als aktuellen Review-Anker fortschreiben.

## Nicht-Ziele
- Keine neue Gameplay-Route oder Missionslogik.
- Keine weitere Callout-Visual-Tuning-Aenderung ohne neuen Sichtbefund.
- Keine Objective-, Cargo-, Command-, Movement-, Combat-, Peer- oder Multiplayer-Mutation.
- Kein behaupteter erledigter menschlicher Playtest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_635_frontier_probe_callout_sight_findings.md`
- `docs/tasks/TASK_634_frontier_probe_real_f6_callout_sight_review.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- Der Verifier schreibt `tmp/frontier_probe_real_f6_recapture.png`.
- Der Verifier schreibt `tmp/frontier_probe_real_f6_recapture.json`.
- Das Manifest enthaelt `schema = sternenbuergerchen.frontier_probe_real_f6_recapture.v1`, `task_id = TASK_636`, `source_task_id = TASK_635` und `capture_type = frontier_probe_real_f6_recapture`.
- Das Manifest enthaelt `post_polish_style_id = task_635_high_contrast_route_callouts`, `route_line_count >= 3`, `label_font_size >= 18` und `label_outline_size >= 7`.
- LZ/CARGO bleiben am gleichen Marker, ihre Labelanker bleiben getrennt.
- `manual_review_required = true`, `manual_review_done = false`, `read_only = true` und `ui_sets_gameplay_truth = false` bleiben gesetzt.

## Betroffene Dateien
- `scripts/tests/task_636_frontier_probe_real_f6_recapture.gd`
- `docs/tasks/TASK_636_frontier_probe_real_f6_recapture.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_636_frontier_probe_real_f6_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_635_frontier_probe_callout_sight_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_634_frontier_probe_real_f6_callout_sight_review.gd`
- optional sichtbar: `godot_console.exe --path . --script scripts/tests/task_636_frontier_probe_real_f6_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Re-Capture beweist Verfuegbarkeit und technische Lesbarkeitsdaten, ersetzt aber keinen laengeren Spielgefuehltest.
- Wenn das echte Bild weiterhin zu laut, zu leise oder verdeckt wirkt, sollte TASK_637 als kleiner Playfeel-/Interaction-Findings-Slice folgen.
