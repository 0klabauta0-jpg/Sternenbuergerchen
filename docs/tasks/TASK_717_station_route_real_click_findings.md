# TASK_717 - Station Route Real Host/Client Click Findings

## Ziel / Problem
Nach TASK_716 ist die Stationsroute im HUD als kurze Route-Line lesbar. Der echte Host/Client-Lauf liefert inzwischen Capture- und Screenshot-Evidence, aber daraus fehlt noch ein kleiner read-only Befund, der sagt: Ist der Klicklauf technisch auswertbar, fehlen Daten, oder ist der menschliche Befund noch offen?

## Sinnhaftigkeit / Ursache
TASK_712/TASK_713 bewerten das allgemeine Host/Client-Acceptance-Paket. TASK_716 ergaenzt die Route-Line. Damit der naechste Polish nicht aus Bauchgefuehl startet, braucht der aktuelle Stand einen kombinierten Befund aus beiden Quellen: echter Zwei-Fenster-Capture plus Route-Readout.

## Umfang
- Neuer read-only Service `StationRouteRealClickFindings`.
- Auswertung von `tmp/host_client_two_window_real_run_review.json`.
- Auswertung von `tmp/station_route_run_readout_polish.json`.
- Statuswerte fuer `blocked`, `needs_real_run`, `needs_route_readout`, `ready_for_click_findings_review`, `ready_with_warnings` und `accepted`.
- Manifest unter `tmp/station_route_real_click_findings.json`.
- Status, Roadmap, Contract und HTML-Handbuch-Refresh werden aktualisiert.

## Nicht-Ziele
- Kein Fensterstart.
- Kein neuer Klick-/Command-Pfad.
- Kein automatisches Bestehen des menschlichen Host/Client-Reviews.
- Kein Door-, Computer-, Cargo- oder Multiplayer-State.
- Kein neues UI-Panel.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_712_station_route_host_client_acceptance_packet.md`
- `docs/tasks/TASK_713_station_route_host_client_findings.md`
- `docs/tasks/TASK_716_station_route_run_readout_polish.md`

## Akzeptanzkriterien
- Fehlende Capture- oder Route-Readout-Manifeste blockieren den Befund.
- Falsche Schemas, falsche Task-IDs, fehlende Screenshots oder UI-Truth-Verletzungen blockieren.
- Eine valide Route-Line muss AA, Door, Computer, Cargo und `NEXT DONE` enthalten.
- Ein echter Run mit Screenshots und valider Route-Line wird `ready_for_click_findings_review`, solange `manual_review_done = false` bleibt.
- Der Snapshot bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.
- Der empfohlene naechste Task nennt den sichtbaren Door/GO/Reject-Polish, ohne Gameplay-State zu setzen.

## Betroffene Dateien
- `scripts/mission/station_route_real_click_findings.gd`
- `scripts/tests/task_717_station_route_real_click_findings.gd`
- `docs/tasks/TASK_717_station_route_real_click_findings.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_717_station_route_real_click_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_713_station_route_host_client_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_716_station_route_run_readout_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_717 beweist nur, dass die vorhandene Evidence technisch auswertbar ist. Der echte menschliche Befund, ob Door, GO, Reject, Computer, Cargo und Route-Line im Fenster angenehm funktionieren, bleibt bewusst offen und soll in TASK_718 sichtbar poliert oder entschieden werden.
