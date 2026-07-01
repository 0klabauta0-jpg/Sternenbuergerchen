# TASK_725 - Station Route Host/Client Recapture Acceptance Review

## Ziel / Problem
Nach TASK_724 ist der sichtbare Station-Route-Polish erneut capture-reif. Jetzt muss der frische Host/Client-Fensterblick als enger Akzeptanzentscheid festgehalten werden: Ist dieser kleine Station-Route-Multiplayer-Slice gut genug, um den naechsten spielbaren Szenario-Slice zu bauen?

## Sinnhaftigkeit / Ursache
TASK_724 war bewusst Visual-/Layout-Polish und kein Gameplay-Umbau. Ohne neues Akzeptanz-Gate wuerden alte Screenshots, offene Sichtnotizen und neuer Polish leicht durcheinanderlaufen. TASK_725 trennt daher technische Evidence, menschlichen Sichtentscheid und naechste Arbeit.

## Umfang
- `capture_host_client_two_window_real_run.ps1` markiert Nach-TASK_724-Recaptures mit TASK_724-/TASK_725-Metadaten und neuen Review-Checks.
- `StationRouteRecaptureAcceptanceReview` wertet Capture, TASK_724-Followup-Manifest und manuellen Sichtentscheid read-only aus.
- Verifier schreibt `tmp/station_route_recapture_acceptance_review.json`.
- Ist-Stand-/Handbuchbericht und Contracts nennen den aktuellen Gate-Stand.

## Nicht-Ziele
- Kein neues Objective.
- Kein HUD-Layout-Polish.
- Kein Door-, Computer-, Cargo- oder Multiplayer-Authority-Umbau.
- Keine breite Spiel-Akzeptanz: `accepted_for_next_slice` gilt nur fuer den kleinen Station-Route-Multiplayer-Slice.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_724_station_route_recapture_visual_followup.md`
- `docs/tasks/TASK_723_station_route_host_client_recapture_review.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Capture-Manifest referenziert TASK_724 und TASK_725.
- TASK_725-Snapshot bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.
- Status unterscheidet `blocked`, `needs_recapture`, `needs_visual_review`, `needs_followup_polish`, `ready_for_acceptance_decision` und `accepted_for_next_slice`.
- Der saubere Sichtentscheid empfiehlt als naechstes einen kleinen spielbaren Szenario-Drill statt weiteren HUD-Polish.

## Betroffene Dateien
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/mission/station_route_recapture_acceptance_review.gd`
- `scripts/tests/task_725_station_route_host_client_recapture_acceptance_review.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [x] `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 10`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_725_station_route_host_client_recapture_acceptance_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_724_station_route_recapture_visual_followup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_723_station_route_host_client_recapture_review.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
TASK_725 akzeptiert keinen fertigen Gesamtzustand. Der kleine Station-Route-Slice ist nach dem Sichtentscheid nur gut genug, um daraus den naechsten kompakten Playtest zu bauen. Sinnvoller Folgegriff: TASK_726 - One-Screen Multiplayer Station Scenario Drill.
