# TASK_739 - Station Scenario Identity Cue Recapture Findings

## Ziel / Problem
Nach TASK_738 wurde der Host-/Client-Capture erneut ausgefuehrt. Dieser Befund soll nicht nur im Chat stehen bleiben: Das Projekt braucht ein read-only Findings-Manifest, das den frischen Capture, die vorhandenen Crops und den neuen Identity-Cue-Snapshot zusammenhaelt.

## Sinnhaftigkeit / Ursache
TASK_738 hat die sichtbare Reibung im Identity-Body behoben. Ohne eigenen Findings-Guard koennen spaeter stale Screenshots oder alte Harness-Empfehlungen wieder wie aktueller Stand wirken.

## Umfang
- Verifier liest `tmp/host_client_two_window_real_run_review.json`.
- Verifier prueft Host-/Client-Crops und aktuelle Identity-Cue-Daten aus der Mission-Testszene.
- Verifier schreibt `tmp/station_scenario_identity_cue_recapture_findings.json`.
- Roadmap, Status, Contract und Handbuchbericht werden auf TASK_739 aktualisiert.
- Harness-Modernisierung wird auf TASK_740 verschoben und bleibt nur bei belegtem Harness-Problem empfohlen.

## Nicht-Ziele
- Kein menschlicher TASK_727-Workbench-Export.
- Kein neues Capture-Harness.
- Keine Runtime-, Gate-, Cargo- oder Authority-Mutation.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_738_station_scenario_identity_cue_visibility_polish.md`
- `docs/tasks/TASK_727_station_scenario_f6_host_client_playtest_notes.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Capture-Manifest meldet `real_run_done`, Host-Crop und Client-Crop.
- Host-/Client-Crop-Dateien existieren.
- Aktueller Identity-Body-Snapshot enthaelt die polierte Cue und die neutrale Route.
- Aktueller Identity-Body-Snapshot versteckt Future-Cargo-Blocker im Display.
- Output-Manifest bleibt read-only und empfiehlt TASK_727-Workbench statt Harness-Modernisierung.

## Betroffene Dateien
- `scripts/tests/task_739_station_scenario_identity_cue_recapture_findings.gd`
- `docs/tasks/TASK_739_station_scenario_identity_cue_recapture_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `scripts/tests/task_738_station_scenario_identity_cue_visibility_polish.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_739_station_scenario_identity_cue_recapture_findings.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_738_station_scenario_identity_cue_visibility_polish.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_739 belegt den Recapture-Zustand und den verbesserten Identity-Body, ersetzt aber weiterhin nicht die menschliche TASK_727-Workbench-Abnahme.
