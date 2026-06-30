# TASK_634 - Frontier Probe Real F6 Callout Sight Review

## Ziel / Problem
TASK_633 trennt die `LZ`- und `CARGO`-Labels am gemeinsamen `spawn_alpha`-Marker. Was noch fehlt, ist ein reproduzierbarer echter F6-Sichtreview-Pfad, der Kamera, Zoom, Occlusion und Lesbarkeit im Fensterbild pruefbar macht, ohne schon einen menschlichen Review als erledigt zu behaupten.

## Sinnhaftigkeit / Ursache
Die bisherige Headless-Evidence beweist Datenfluss und Label-Staffelung. Sie ersetzt aber nicht den Blick auf das echte Missionsfenster. Gerade Callouts koennen im echten Bild durch Kameraausschnitt, Gebaeude, HUD oder Zoom trotzdem stoeren.

## Umfang
- Einen kleinen Verifier fuer den abgeschlossenen Frontier-Probe-Zustand erstellen.
- Wenn ein echter Viewport-Readback verfuegbar ist, ein FullHD-PNG aus dem Fensterbild schreiben.
- Im Headless-Lauf ein klar markiertes Evidence-Board schreiben.
- Ein Manifest mit Pflichtchecks fuer den menschlichen F6-Sichtreview schreiben.
- Reports und Contracts um den neuen Review-Anker erweitern.

## Nicht-Ziele
- Kein neuer Runtime-Callout-Renderer.
- Keine Gameplay-, Cargo-, Objective-, Movement-, Combat- oder Multiplayer-Mutation.
- Kein behaupteter erledigter manueller Sichttest.
- Kein automatischer OCR-/Bildbewertungsersatz fuer den menschlichen Blick.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_632_frontier_probe_mini_scenario_f6_visual_review.md`
- `docs/tasks/TASK_633_frontier_probe_callout_layout_polish.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- Der Verifier schreibt `tmp/frontier_probe_real_f6_callout_sight_review.png`.
- Der Verifier schreibt `tmp/frontier_probe_real_f6_callout_sight_review.json`.
- Das Manifest enthaelt `viewport_readback_available`, `generated_evidence_board`, `manual_review_required = true`, `manual_review_done = false`, `label_overlap_polish_gate = pass`, `real_window_review_done = false`, `read_only = true` und `ui_sets_gameplay_truth = false`.
- LZ/CARGO bleiben am gleichen Marker, ihre Labelanker bleiben getrennt.
- Headless wird nicht als echter Fensterblick ausgegeben.

## Betroffene Dateien
- `scripts/tests/task_634_frontier_probe_real_f6_callout_sight_review.gd`
- `docs/tasks/TASK_634_frontier_probe_real_f6_callout_sight_review.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_634_frontier_probe_real_f6_callout_sight_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_633_frontier_probe_callout_layout_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_632_frontier_probe_mini_scenario_f6_visual_review.gd`
- `git diff --check`

## Risiken / offene Punkte
- Ein Headless-Board ist nur Review-Ersatzmaterial. Der echte Sichtentscheid bleibt offen, bis das Skript ohne `--headless` oder per F6-Fensterlauf betrachtet wurde.
- Der Task korrigiert keine neuen Callout-Findings. Wenn der echte Blick weitere Occlusion zeigt, braucht es einen kleinen Folge-Polish-Slice.
