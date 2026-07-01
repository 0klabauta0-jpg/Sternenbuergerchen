# TASK_721 - Station Route Two-Window Visual Findings

## Ziel / Problem
Nach TASK_720 ist die Host/Client-Capture-Evidence technisch frisch. Der naechste offene Punkt ist der echte Sichtentscheid: Ist der Station-Route-Flow im sichtbaren Host- und Client-Fenster angenehm spielbar, oder braucht er noch UI-Polish?

## Sinnhaftigkeit / Ursache
Gruene Capture-/Contract-Tests beweisen, dass der Pfad technisch laeuft. Sie beweisen aber nicht, dass der Spieler im Fenster schnell versteht, was los ist. Der frische Capture zeigt mehrere konkrete Lesbarkeitsreibungen, die vor einer Akzeptanzentscheidung festgehalten werden muessen.

## Umfang
- Neuer read-only Findings-Service fuer den Zwei-Fenster-Sichtbefund.
- Verknuepfung von frischem Host/Client-Capture und TASK_719-Recheck.
- Dokumentierter visueller Befund aus den aktuellen Host-/Client-Crops:
  - Fireteam-Karten ueberdecken einen relevanten Teil der taktischen Karte.
  - Door-/Station-Labels sind im Gebaeude klein und gedrungen.
  - Oben rechts ist ein leer wirkender Navigations-Placeholder sichtbar.
  - Door-/Route-Texte brauchen mehr Leseflaeche.
- Manifest unter `tmp/station_route_two_window_visual_findings.json`.

## Nicht-Ziele
- Kein Runtime-Gameplay-Umbau.
- Kein automatischer Computer-Vision-Test.
- Kein bestandener menschlicher Zwei-Fenster-Playtest.
- Kein neues Door-/Computer-/Cargo-Verhalten.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_720_station_route_capture_recheck_handbook.md`
- `docs/tasks/TASK_719_station_route_post_polish_recheck.md`
- `docs/tasks/TASK_718_station_route_door_go_reject_visual_polish.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Capture- und Recheck-Evidence muessen read-only bleiben.
- Fehlende Capture-/Recheck-Evidence blockiert den Sichtbefund.
- Offener Sichtbefund meldet `needs_visual_review`.
- Der aktuelle Sichtbefund meldet `needs_visual_polish` und empfiehlt TASK_722.
- Kein UI-/Report-Pfad setzt Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_route_two_window_visual_findings.gd`
- `scripts/tests/task_721_station_route_two_window_visual_findings.gd`
- `docs/tasks/TASK_721_station_route_two_window_visual_findings.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_721_station_route_two_window_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_719_station_route_post_polish_recheck.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_717_station_route_real_click_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_721 ist ein ehrlicher Findings-Slice. Er verbessert noch nicht die sichtbaren UI-Probleme. Der naechste sinnvolle Schritt ist TASK_722 - Station Route HUD Visual Polish: Fireteam-Karten/Map-Freiraum, Station-Label-Lesbarkeit und leerer Nav-Placeholder.
