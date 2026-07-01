# TASK_719 - Station Route Post-Polish Recheck Guard

## Ziel / Problem
TASK_718 hat die sichtbaren Door-/GO-/Reject-Zeilen verbessert. Dadurch koennen alte Host/Client-Capture-Manifeste aber stale sein, weil sie noch alte Erwartungszeilen wie `DOOR DOOR B->GO` enthalten. Der aktuelle Stand braucht einen ehrlichen Recheck-Guard, der alte Evidence nicht als aktuelle Fensterlesbarkeit verkauft.

## Sinnhaftigkeit / Ursache
Das Spiel soll spielbar und multiplayer-faehig werden. Dafuer ist es gefaehrlich, technische Tests gruen zu haben, waehrend der echte Fensterbefund auf alten HUD-Erwartungen beruht. Der Guard trennt deshalb: TASK_718-Polish ist vorhanden, aber Capture muss nach dem Polish frisch sein.

## Umfang
- Neuer read-only Service `StationRoutePostPolishRecheck`.
- Bewertung von TASK_718-Polish-Manifest und Host/Client-Capture-Manifest.
- Statuswerte fuer `blocked`, `needs_capture_refresh`, `needs_real_run`, `ready_for_real_window_recheck` und `accepted`.
- Stale-Erkennung fuer alte Door-Zeilen:
  - `DOOR DOOR B->GO`
  - `DOOR DOOR OPEN`
- Manifest unter `tmp/station_route_post_polish_recheck.json`.
- Status, Roadmap, Contract und HTML-Handbuch-Refresh werden aktualisiert.

## Nicht-Ziele
- Kein Fensterstart.
- Kein neuer Klick-/Command-Pfad.
- Kein automatisches Bestehen des menschlichen Reviews.
- Keine Aenderung an Door-/Computer-/Cargo-Runtime.
- Kein UI-Layout-Redesign.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_718_station_route_door_go_reject_visual_polish.md`
- `docs/tasks/TASK_717_station_route_real_click_findings.md`
- `docs/tasks/TASK_712_station_route_host_client_acceptance_packet.md`

## Akzeptanzkriterien
- Fehlendes oder ungueltiges TASK_718-Polish-Manifest blockiert.
- Aktuelle Polish-Evidence muss `B->GO` enthalten und darf `DOOR DOOR` nicht enthalten.
- Capture-Erwartungen muessen `DOOR B->GO` und `DOOR OPEN` enthalten, sonst wird `needs_capture_refresh` gemeldet.
- Frischer Capture mit realem Run und offenem Review wird `ready_for_real_window_recheck`.
- Der Snapshot bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/mission/station_route_post_polish_recheck.gd`
- `scripts/tests/task_719_station_route_post_polish_recheck.gd`
- `docs/tasks/TASK_719_station_route_post_polish_recheck.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_719_station_route_post_polish_recheck.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_718_station_route_door_go_reject_visual_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_717_station_route_real_click_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_719 behebt keine stale Capture-Daten automatisch. Wenn der Status `needs_capture_refresh` ist, muss der echte Host/Client-Capture nach TASK_718 erneut ausgefuehrt oder bewusst im Fenster geprueft werden.
