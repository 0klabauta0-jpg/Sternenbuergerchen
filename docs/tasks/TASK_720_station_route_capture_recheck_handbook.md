# TASK_720 - Station Route Capture Recheck + Handbuch

## Ziel / Problem
Nach TASK_718 war die Door-/GO-/Reject-Sprache korrigiert, aber das alte Host/Client-Capture-Manifest enthielt noch stale Erwartungszeilen wie `DOOR DOOR B->GO` und `DOOR DOOR OPEN`. Zusaetzlich wollte der laufende Arbeitsstand wieder als HTML-Bericht plus Handbuch lesbar sein.

## Sinnhaftigkeit / Ursache
Der naechste sinnvolle Spielschritt ist nicht mehr ein neuer Runtime-Umbau, sondern ein ehrlicher Fensterbefund. Dafuer muss die Capture-Evidence zuerst zu den aktuellen HUD-Texten passen. Der Bericht soll denselben Stand fuer Spielerhandbuch, Entwicklerkontext und naechste Entscheidung zusammenfassen.

## Umfang
- Neuer HTML-Ist-Stand-/Handbuch-Bericht unter `docs/reports/`.
- Frischer Host/Client-Capture mit aktuellen Door-Erwartungen.
- Recheck von TASK_719, TASK_717 und TASK_718 gegen diesen Stand.
- Keine Runtime-, UI- oder Multiplayer-Logikaenderung.

## Nicht-Ziele
- Kein bestandener menschlicher Zwei-Fenster-Playtest.
- Kein neues Missionssystem.
- Kein neues Door-/Computer-/Cargo-Feature.
- Keine Gameplay-Wahrheit im Report oder in `tmp`-Manifesten.

## Relevante Contracts / Dokumente
- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_719_station_route_post_polish_recheck.md`
- `docs/tasks/TASK_718_station_route_door_go_reject_visual_polish.md`
- `docs/tasks/TASK_717_station_route_real_click_findings.md`

## Akzeptanzkriterien
- Der neue HTML-Bericht hat `JSON exportieren`, Arbeitsnotizen und Handbuch-/Ist-Stand-Bereiche.
- Das frische Capture-Manifest nennt `DOOR B->GO`, `DOOR OPEN` und Station-Route `DOOR OPEN`.
- TASK_719 meldet `ready_for_real_window_recheck`.
- TASK_717 und TASK_718 bleiben gruen.
- Bericht und Task dokumentieren, dass der echte menschliche Fensterbefund weiter offen ist.

## Betroffene Dateien
- `docs/tasks/TASK_720_station_route_capture_recheck_handbook.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 10`
- `godot_console.exe --headless --path . --script scripts/tests/task_719_station_route_post_polish_recheck.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_717_station_route_real_click_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_718_station_route_door_go_reject_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Capture ist frisch und technisch pruefbar, ersetzt aber nicht den menschlichen Zwei-Fenster-Klicklauf. Naechster sinnvoller Slice ist ein echter Station-Route-Playtestentscheid: Door/GO/Reject, Computer, Cargo, Route-Line, Snapshot-Sync und Bediengefuehl im sichtbaren Host/Client-Fenster.
