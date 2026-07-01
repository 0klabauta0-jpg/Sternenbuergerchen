# TASK_741 - Station Scenario Workbench Recapture Prefill

## Ziel / Problem
Die TASK_727-Workbench bleibt der richtige Ort fuer den menschlichen F6-/Host-Client-Review, aber nach TASK_739 liegen bereits konkrete Recapture-Funde vor. Diese Evidence soll in der Workbench sichtbar und exportierbar sein, ohne den sichtbaren Playtest als erledigt zu markieren.

## Sinnhaftigkeit / Ursache
Der aktuelle Zustand ist technisch gut vorbereitet: echter Host-/Client-Capture, Host-/Client-Crops, Cue im Identity-Body und neutrale Route sind belegt. Wenn diese Daten nicht direkt in der Workbench stehen, muss der Reviewer zwischen Report, tmp-Manifest und Screenshot-Pfaden springen und kann leichter stale Erwartungen bewerten.

## Umfang
- TASK_727-Workbench bekommt einen read-only Recapture-Evidence-Block.
- `StationScenarioF6HostClientPlaytestNotes` kann optionale Recapture-Findings in den Snapshot uebernehmen.
- Current-State-Handbuch, Roadmap, Status und Contract benennen TASK_741 als Vorbereitung fuer den echten Workbench-Export.
- Ein Verifier prueft, dass Prefill-Evidence exportierbar ist und `manual_review_done` weiter false bleibt, solange der Playtest nicht bewusst abgeschlossen wurde.

## Nicht-Ziele
- Kein automatischer menschlicher Sichtentscheid.
- Kein neuer Host-/Client-Capture.
- Keine Harness-Modernisierung.
- Keine Runtime-, Cargo-, Door-, Command- oder Multiplayer-Mutation.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_727_station_scenario_f6_host_client_playtest_notes.md`
- `docs/tasks/TASK_739_station_scenario_identity_cue_recapture_findings.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Workbench exportiert Recapture-Manifestpfad, Host-/Client-Crops, erwartete Cue und neutrale Route.
- Workbench markiert `station_scenario_playtest.playtest_done` nicht automatisch.
- Analyzer-Snapshot uebernimmt optionale Recapture-Findings read-only.
- Offener Snapshot bleibt `needs_visible_playtest` und `manual_review_done = false`.
- Sauberer menschlicher Export bleibt weiterhin `ready_for_findings`.

## Betroffene Dateien
- `scripts/mission/station_scenario_f6_host_client_playtest_notes.gd`
- `scripts/tests/task_741_station_scenario_workbench_recapture_prefill.gd`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_741_station_scenario_workbench_recapture_prefill.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_727_station_scenario_f6_host_client_playtest_notes.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_739_station_scenario_identity_cue_recapture_findings.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_741 macht den Review ergonomischer, ersetzt ihn aber nicht. Der echte naechste Schritt bleibt: TASK_727-Workbench sichtbar ausfuellen und JSON exportieren.
