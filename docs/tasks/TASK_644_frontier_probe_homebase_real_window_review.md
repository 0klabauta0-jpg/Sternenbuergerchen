# TASK_644 - Frontier Probe Homebase Real Window Review

## Ziel / Problem
Nach TASK_643 ist das Homebase-Readiness-Evidence-Board lesbar, aber der echte Homebase-Fensterblick ist noch nicht als eigener Review-Anker festgehalten. Fuer Spielgefuehl, Auffaelligkeit und Schoenheit reicht ein Headless-Board nicht aus.

## Sinnhaftigkeit / Ursache
Der Core-Loop ist technisch verbunden: Frontier Probe -> Debrief -> Homebase -> Next Sortie. Der naechste Qualitaetsschritt ist ein reproduzierbares Paket, das ohne `--headless` einen echten Homebase-Viewport-Readback speichern kann und im Headless-Fall klar markiert, dass der sichtbare Fensterentscheid noch offen ist.

## Umfang
- Neuer Verifier erzeugt `tmp/frontier_probe_homebase_real_window_review.png` und `tmp/frontier_probe_homebase_real_window_review.json`.
- Ohne `--headless` wird der echte Homebase-Viewport nach Debrief-Return gespeichert.
- Mit `--headless` wird das beschriftete TASK_642/TASK_643-Evidence-Board als Fallback genutzt.
- Manifest trennt `visible_window_readback_available`, `generated_evidence_board`, `real_window_review_gate`, `manual_review_required` und `manual_review_done`.
- Reports und Handbuch nennen TASK_644 als aktuellen Stand und halten den menschlichen Sichtentscheid offen.

## Nicht-Ziele
- Kein Runtime-Homebase-Layoutumbau.
- Kein Button-, Progression-, MissionResult- oder Command-Commit.
- Kein behaupteter menschlicher Sichtentscheid.
- Kein neuer Screenshot-Automationsstandard fuer alle Szenen.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_642_frontier_probe_homebase_visible_readiness_review.md`
- `docs/tasks/TASK_643_frontier_probe_homebase_readiness_visual_polish_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`
- `docs/reports/project_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Der TASK_644-Verifier erzeugt ein FullHD-PNG und ein Manifest.
- Das Manifest enthaelt `task_id = TASK_644`, `source_task_ids = [TASK_642, TASK_643]`, `gate = pass`, `real_window_review_gate`, `visible_window_readback_available`, `generated_evidence_board`, `manual_review_required = true`, `manual_review_done = false`, `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false` und `creates_command = false`.
- Der Homebase-Snapshot bleibt gruen: Post-Debrief-Summary sichtbar, Next-Sortie sichtbar, keine Overlap-/Overflow-Regression.
- Im Headless-Fall behauptet das Manifest keinen echten Fensterentscheid, sondern `real_window_review_gate = manual_open`.
- Reports und Handbuch exportieren TASK_644-Felder und nennen den naechsten Schritt: nur bei konkreter Reibung einen Runtime-UI-Polish schneiden.

## Betroffene Dateien
- `scripts/tests/task_644_frontier_probe_homebase_real_window_review.gd`
- `docs/tasks/TASK_644_frontier_probe_homebase_real_window_review.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`
- `docs/reports/project_state_handbook_2026_06_30.html`
- angrenzende Report-Regressions unter `scripts/tests/task_638_*.gd` bis `scripts/tests/task_643_*.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_642_frontier_probe_homebase_visible_readiness_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_644_frontier_probe_homebase_real_window_review.gd`
- Optional fuer echten Fenster-Readback: `godot_console.exe --path . --script scripts/tests/task_644_frontier_probe_homebase_real_window_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_643_frontier_probe_homebase_readiness_visual_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- In Headless-Umgebung bleibt der echte sichtbare Fensterblick offen. Das ist korrekt und wird im Manifest nicht als erledigt behauptet.
- Wenn der echte Fensterlauf konkrete Reibung zeigt, ist der naechste sinnvolle Task ein kleiner Runtime-UI-Polish fuer Summary/Next-Sortie-Lesbarkeit.
