# TASK_633 - Frontier Probe Callout Layout Polish

## Ziel / Problem
TASK_632 macht die Frontier-Probe-Callouts als Review-Paket sichtbar. Dabei zeigt sich ein echter Layout-Fallstrick: `LZ` und `CARGO` liegen bewusst auf demselben `spawn_alpha`-Marker, duerfen im Primary3D-Bild aber nicht als uebereinanderliegende Labels enden.

## Sinnhaftigkeit / Ursache
Die Mini-Mission soll schnell lesbar sein: landen, AA ausschalten, Computer halten, Cargo rein und wieder raus. Wenn Start- und Cargo-Label an derselben Weltposition kleben, wird die Route schlechter statt besser erklaert.

## Umfang
- Route-Callout-Labels im Primary3D-Statuspfad overlap-aware staffeln.
- Render-Snapshot um Label-Position, Offset und Overlap-Gruppe erweitern.
- TASK_632-Review-Manifest um die neue Layout-Polish-Evidence ergaenzen.
- Rolling HTML-Report und Ist-Stand-/Handbuch-Bericht aktualisieren.
- Regression gegen TASK_632, TASK_631 und TASK_630.

## Nicht-Ziele
- Kein neues Missionssystem.
- Keine Aenderung der Objective-, Cargo- oder Command-Wahrheit.
- Kein Balancing der Route.
- Kein finaler menschlicher Sichtentscheid; dieser Task behebt nur den belegten Label-Overlap-Fall.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_632_frontier_probe_mini_scenario_f6_visual_review.md`

## Akzeptanzkriterien
- `LZ` und `CARGO` behalten dieselbe Gameplay-/Marker-Weltposition, bekommen aber unterschiedliche Label-Offsets.
- Primary3D-Render-Snapshot meldet Overlap-Gruppe, Overlap-Index und Label-Weltposition pro Callout.
- TASK_632-Manifest zeigt `callout_layout_polish_task_id = TASK_633` und `label_overlap_polish_gate = pass`.
- Report und Handbuch exportieren TASK_633-Felder.
- TASK_632, TASK_631 und TASK_630 bleiben gruen.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_632_frontier_probe_mini_scenario_f6_visual_review.gd`
- `scripts/tests/task_633_frontier_probe_callout_layout_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_633_frontier_probe_callout_layout_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_632_frontier_probe_mini_scenario_f6_visual_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_631_frontier_probe_mini_scenario_visual_feel_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_630_frontier_probe_mini_scenario_feel_route.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Staffelung ist ein visueller Readability-Fix, keine automatische Kamera-/Occlusion-Loesung. Wenn ein echter Fensterlauf weitere Label-Konflikte zeigt, braucht es danach gezieltes Callout-Layout-Feintuning.
