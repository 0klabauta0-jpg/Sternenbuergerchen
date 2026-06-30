# TASK_713 - Station Route Host/Client Findings

## Ziel / Problem
TASK_712 macht den Station-Route-Host/Client-Acceptance-Run konkret, aber danach fehlt eine maschinenlesbare Auswertung: Ist das Paket technisch kaputt, ist der echte Zwei-Fenster-Lauf noch offen, sind die Artefakte bereit fuer Review oder kann daraus Multiplayer-Polish folgen?

## Sinnhaftigkeit / Ursache
Door -> Computer -> Cargo soll nicht nur als Checkliste existieren. Damit der naechste Schritt spielorientiert bleibt, brauchen wir einen kleinen Findings-Contract, der offene menschliche Akzeptanz von technischen Blockern trennt.

## Umfang
- Neuer read-only Service `StationRouteHostClientFindings`.
- Verifier `task_713_station_route_host_client_findings.gd`.
- Bewertung des TASK_712-Real-Run-Manifests.
- Trennung von technischen Blockern, Paket-Warnungen und offenen manuellen Findings.
- JSON-Manifest unter `tmp/station_route_host_client_findings.json`.
- Contract, Status, Roadmap und aktueller HTML-Handbuch-Refresh werden aktualisiert.

## Nicht-Ziele
- Kein Klickbot und kein automatischer Host/Client-Freispruch.
- Kein neues Door-, Computer-, Cargo-, Objective-, Multiplayer- oder SimulationRoot-Verhalten.
- Kein Mutieren von Runtime-, Peer- oder Gameplay-State.
- Kein Ersetzen des echten Zwei-Fenster-Playtests.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_712_station_route_host_client_acceptance_packet.md`
- `docs/tasks/TASK_708_station_route_visual_evidence.md`
- `docs/tasks/TASK_709_station_route_window_playtest_notes.md`
- `docs/tasks/TASK_710_station_route_polish_readiness_findings.md`

## Akzeptanzkriterien
- Snapshot nennt Schema, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Fehlendes oder nicht-read-only TASK_712-Paket wird als technischer Blocker gewertet.
- Erwartete Station-Route-Sequenz `door_open -> computer_controlled -> cargo_departed` wird geprueft.
- Manual-Checks fuer Host/Client-Fenster, Door, Computer, Cargo, Wrong-Team-Reject, Snapshot-Sync, HUD und Notes-Export werden geprueft.
- `manual_open` fuehrt zu `needs_real_run`, nicht zu einem bestandenen Review.
- `review_ready` mit Screenshot-/Run-Evidence fuehrt zu `ready_for_findings_review`.
- `review_done` ohne Real-Run-/Screenshot-Evidence blockiert.
- Snapshot nennt `blocking_issue_count`, `warning_count`, `manual_note_count`, `technical_packet_ready`, `manual_acceptance_open`, `host_client_findings_ready`, `status` und `recommended_next_task`.

## Betroffene Dateien
- `scripts/mission/station_route_host_client_findings.gd`
- `scripts/tests/task_713_station_route_host_client_findings.gd`
- `docs/tasks/TASK_713_station_route_host_client_findings.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_713_station_route_host_client_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_712_station_route_host_client_acceptance_packet.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_713 verbessert die Auswertung des Acceptance-Pakets, nicht den echten Multiplayerlauf selbst. Der harte naechste Schritt bleibt: Station-Route in zwei Fenstern wirklich spielen, Sicht/Sync/Reject bewerten und danach aus dem Findings-Status ableiten, ob TASK_714 Multiplayer-Polish oder ein Fix noetig ist.
