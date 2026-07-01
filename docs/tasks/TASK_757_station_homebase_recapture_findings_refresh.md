# TASK_757 - Station Homebase Recapture Findings Refresh

## Ziel / Problem
Nach TASK_756 ist die echte Homebase-Recapture-Kette auf den TASK_755-Return-Panel-Zustand aktualisiert. Die Findings-Schicht muss diesen neuen Stand ebenfalls ausdruecken, damit Reports und Workbench nicht mehr auf den bereits erledigten TASK_755-Polish als naechste Arbeit zurueckzeigen.

## Sinnhaftigkeit / Ursache
TASK_754 konnte nur vor TASK_755 entscheiden: Review fehlt, Checks fehlen oder Panel-Polish ist dran. Nach TASK_755/TASK_756 ist der naechste sinnvolle Schritt kein weiterer Panel-Polish, sondern ein echter Workbench-Export beziehungsweise eine enge Acceptance-Auswertung des sichtbaren Homebase-Return-Moments.

## Umfang
- `StationScenarioF6HostClientPlaytestNotes` erzeugt einen zusaetzlichen read-only `homebase_recapture_findings_refresh`-Snapshot.
- Der Refresh unterscheidet:
  - echter TASK_756-Fensterreview fehlt
  - TASK_756-Panelchecks sind unvollstaendig
  - Review ist bereit fuer Acceptance-Auswertung
- Workbench und aktueller HTML-Bericht zeigen TASK_757 als neuen Folgeanker.
- Contract, Status, Roadmap und Verifier werden aktualisiert.

## Nicht-Ziele
- Kein menschlicher Sichttest wird als erledigt markiert.
- Keine Runtime-UI-Aenderung.
- Keine Navigation, kein Startbutton-Commit und kein Command.
- Keine neue Gameplay-Wahrheit in Report oder Workbench.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_756_station_homebase_real_window_recapture.md`
- `docs/tasks/TASK_754_station_homebase_recapture_findings.md`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Ohne echten Review meldet der Refresh `blocked_missing_task_756_window_review`.
- Bei fehlenden Checks meldet der Refresh `needs_task_756_panel_check_completion`.
- Bei vollstaendigem Review meldet der Refresh `ready_for_homebase_acceptance_review`.
- Der Refresh nennt TASK_756 als Quelle, TASK_755 als Panel-Quelle und bleibt read-only.
- Reports exportieren TASK_757-Felder und routen nicht mehr stumpf auf TASK_755 als naechsten Schritt.

## Betroffene Dateien
- `scripts/mission/station_scenario_f6_host_client_playtest_notes.gd`
- `scripts/tests/task_757_station_homebase_recapture_findings_refresh.gd`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_757_station_homebase_recapture_findings_refresh.gd`
- Regressionen: TASK_754, TASK_756
- `git diff --check`

## Risiken / offene Punkte
TASK_757 verbessert Routing und Evidence-Lesbarkeit, ersetzt aber keinen echten sichtbaren Host/Client-Workbench-Export. Der naechste Spielgefuehl-Schritt bleibt ein realer Fensterblick oder eine Acceptance-Auswertung, wenn ein Export vorliegt.
