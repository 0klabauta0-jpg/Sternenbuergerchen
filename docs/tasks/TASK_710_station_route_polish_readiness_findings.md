# TASK_710 - Station Route Polish Readiness Findings

## Ziel / Problem
TASK_708 und TASK_709 erzeugen Evidence und Fenster-Notizstruktur, aber daraus fehlt noch eine klare maschinenlesbare Entscheidung: Ist die Stationsroute technisch blockiert, braucht sie erst echten Fensterblick, braucht sie Visual-Polish oder ist sie bereit fuer Host/Client-Akzeptanz?

## Sinnhaftigkeit / Ursache
Damit das Spiel angenehmer, spielbarer und multiplayerfaehiger wird, muessen wir offene Review-Luecken in klare naechste Schritte uebersetzen. Sonst sammeln sich Evidence-Artefakte, ohne dass der naechste Griff eindeutig ist.

## Umfang
- Neuer read-only Service `StationRoutePolishReadinessFindings`.
- Verifier `task_710_station_route_polish_readiness_findings.gd`.
- Bewertung von TASK_708-Evidence und TASK_709-Fenster-Notizen.
- Trennung von technischen Blockern, Polish-Warnungen und offenen manuellen Sichtentscheidungen.
- JSON-Manifest unter `tmp/`.
- Doku, Roadmap, Status und aktueller HTML-Handbuch-Refresh fortschreiben.

## Nicht-Ziele
- Kein automatischer visueller Freispruch.
- Kein neuer Door-/Computer-/Cargo-State.
- Kein Host/Client-Klicklauf.
- Kein Gameplay-State-Commit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_708_station_route_visual_evidence.md`
- `docs/tasks/TASK_709_station_route_window_playtest_notes.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`

## Akzeptanzkriterien
- Snapshot nennt Schema, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Fehlende oder nicht-read-only Evidence wird als technischer Blocker gewertet.
- Unvollstaendige Door-/Objective-Gate-Evidence wird als technischer Blocker gewertet.
- Offener echter Fensterentscheid wird als manueller Hinweis, nicht als technischer Blocker, gewertet.
- Snapshot nennt `blocking_issue_count`, `warning_count`, `manual_note_count`, `visual_polish_ready`, `host_client_acceptance_ready` und `recommended_next_task`.
- Manifest bleibt offen, solange TASK_709 nicht mit menschlichem Sichtentscheid gefuellt ist.

## Betroffene Dateien
- `docs/tasks/TASK_710_station_route_polish_readiness_findings.md`
- `scripts/mission/station_route_polish_readiness_findings.gd`
- `scripts/tests/task_710_station_route_polish_readiness_findings.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_710_station_route_polish_readiness_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_709_station_route_window_playtest_notes.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_710 verbessert die Entscheidungsqualitaet, nicht die Visuals selbst.
- Der echte Fensterblick bleibt die harte Grenze fuer Host/Client-Akzeptanz.
