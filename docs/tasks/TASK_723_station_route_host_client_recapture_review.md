# TASK_723 - Station Route Host/Client Recapture Review

## Ziel / Problem
Nach TASK_722 ist das Station-Route-HUD technisch poliert, aber der echte Host/Client-Fensterblick muss erneut bewertet werden. Ohne ein eigenes Recapture-Gate koennte der alte TASK_721-Sichtbefund weiter als aktueller Zustand gelesen werden.

## Sinnhaftigkeit / Ursache
TASK_722 meldet bewusst nur `ready_for_recapture`. Der naechste Schritt muss deshalb nachweisen, dass ein frischer Zwei-Fenster-Capture auf dem neuen HUD-Stand existiert, und den menschlichen Sichtentscheid sauber offen halten.

## Umfang
- `capture_host_client_two_window_real_run.ps1` markiert Nach-TASK_722-Recaptures mit TASK_722-/TASK_723-Metadaten und neuen Review-Checks.
- `StationRouteHostClientRecaptureReview` kombiniert Capture-Manifest, TASK_722-HUD-Polish-Manifest und optionalen Sichtbefund read-only.
- Statuswerte unterscheiden technische Blocker, fehlenden Recapture, offenen Sichtentscheid, Folge-Polish und Akzeptanzbereitschaft.
- Der HTML-Ist-Stand-/Handbuchbericht fuehrt TASK_723 als aktuelles Recapture-Gate.

## Nicht-Ziele
- Keine neue Mission-, Door-, Objective- oder Multiplayer-Wahrheit.
- Kein automatischer bestandener Sichttest.
- Kein weiterer HUD-Polish in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_722_station_route_hud_visual_polish.md`
- `docs/tasks/TASK_721_station_route_two_window_visual_findings.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Nach-TASK_722-Capture referenziert TASK_722 und TASK_723 explizit.
- Der Recapture-Review-Snapshot ist `read_only = true` und `ui_sets_gameplay_truth = false`.
- Frischer Capture + HUD-Polish ohne Sichtbefund meldet `needs_visual_review`, nicht `accepted`.
- Sauberer expliziter Sichtbefund kann `ready_for_acceptance_decision` melden.
- Folge-Polish-Flags koennen `needs_followup_polish` ausloesen.

## Betroffene Dateien
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/mission/station_route_host_client_recapture_review.gd`
- `scripts/tests/task_723_station_route_host_client_recapture_review.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [x] `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 10`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_723_station_route_host_client_recapture_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_722_station_route_hud_visual_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_721_station_route_two_window_visual_findings.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
TASK_723 erzeugt die fachliche Klammer fuer den Recapture, ersetzt aber keine menschliche Sichtentscheidung. Wenn im Fenster weiterhin Kartenflaeche, Label-Lesbarkeit oder Route-Line stoeren, ist TASK_724 ein kleiner Folge-Polish statt ein Runtime-Umbau.
