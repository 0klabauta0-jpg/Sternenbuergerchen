# TASK_708 - Station Route Visual Evidence

## Ziel / Problem
TASK_707 beweist Door -> Computer -> Cargo technisch, aber der Spielerblick braucht ein sichtbares Evidence-Paket. Der naechste Schritt ist eine FullHD-Review-Datei, die zeigt, ob die Stationsroute als kurzer Missionsmoment lesbar genug ist.

## Sinnhaftigkeit / Ursache
Viele Systeme sind einzeln gruen. Das Spiel wird aber erst angenehm, wenn der Spieler im Missionsbild erkennt: Door ist offen, Computer ist kontrolliert, Cargo ist der naechste/abgeschlossene Schritt, und UI/Visuals setzen dabei keine zweite Wahrheit.

## Umfang
- Reproduzierbarer FullHD-Evidence-Smoke fuer die Stationsroute.
- Nutzt dieselbe temporaere Door/Computer/Cargo-Scenario-Variante wie TASK_707.
- Schreibt PNG und JSON unter `tmp/`.
- Manifest trennt technische Evidence von menschlichem Fensterentscheid.
- Neuer Report-/Handbuchstand nennt TASK_708 und die Evidence-Pfade.

## Nicht-Ziele
- Kein echter Host/Client-Klicklauf.
- Keine neue Gameplay-Logik.
- Keine dauerhafte Aenderung an der Frontier-Probe-Scenario-Datei.
- Kein behaupteter manueller Sichtentscheid.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_707_mission_door_computer_cargo_smoke.md`
- `docs/tasks/TASK_706_mission_door_layout_visual_polish.md`

## Akzeptanzkriterien
- Verifier startet die Mission-Testszene bei 1920x1080.
- Door-Open, Computer-Control und Cargo-Complete sind im Manifest belegt.
- PNG existiert, ist FullHD und hat sichtbare Pixel.
- Manifest nennt `manual_window_review_required = true` und `manual_window_review_done = false`.
- Manifest bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.
- Aktueller Handbuch-Refresh exportiert die TASK_708-Pfade.

## Betroffene Dateien
- `docs/tasks/TASK_708_station_route_visual_evidence.md`
- `scripts/tests/task_708_station_route_visual_evidence.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_708_station_route_visual_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_707_mission_door_computer_cargo_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- Headless kann ein generiertes Review-Board statt echter Fensterpixel schreiben. Das ist ehrlich im Manifest markiert.
- Der echte menschliche Sicht-/Bedienentscheid bleibt als Folgearbeit offen.
