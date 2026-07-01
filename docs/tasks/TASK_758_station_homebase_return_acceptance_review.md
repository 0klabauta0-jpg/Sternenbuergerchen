# TASK_758 - Station Homebase Return Acceptance Review

## Ziel / Problem
Nach TASK_757 ist das Follow-up-Routing wieder korrekt, aber es fehlt eine enge Acceptance-Entscheidung fuer den Homebase-Return-Moment: Ist Cargo -> Debrief -> Homebase inklusive TASK_755-Return-Panel gut genug fuer den naechsten Stations-Playtest-Slice, oder muss der echte Workbench-Export erst nachgeholt werden?

## Sinnhaftigkeit / Ursache
Ohne Acceptance-Schicht bleiben die Tasks in Review-/Findings-Meta stecken. Das Spiel soll aber in einen angenehmen, spielbaren Zustand kommen. Deshalb braucht der kleine Abschlussmoment eine klare Entscheidung: akzeptiert fuer den naechsten Slice, oder sauber zurueck zur echten Fensterpruefung.

## Umfang
- `StationScenarioF6HostClientPlaytestNotes` erzeugt einen read-only `homebase_return_acceptance_review`-Snapshot.
- Die Acceptance basiert nur auf `homebase_recapture_findings_refresh`.
- Der Snapshot unterscheidet:
  - echter TASK_756-Review fehlt
  - TASK_756-Checks fehlen
  - Homebase-Return ist eng akzeptiert fuer den naechsten Station-Slice
- Workbench und aktueller HTML-Bericht zeigen TASK_758 als neuen Statusanker.
- Contract, Status, Roadmap und Verifier werden aktualisiert.

## Nicht-Ziele
- Keine Gesamtspiel-Abnahme.
- Kein menschlicher Sichttest wird erfunden.
- Keine Runtime-UI-Aenderung.
- Keine Commands, Navigation oder Gameplay-Mutation.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_757_station_homebase_recapture_findings_refresh.md`
- `docs/tasks/TASK_756_station_homebase_real_window_recapture.md`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Ohne `ready_for_homebase_acceptance_review` bleibt Acceptance blockiert.
- Fehlende TASK_756-Checks werden als `needs_task_756_completion` weitergereicht.
- Bei vollstaendigem Refresh meldet Acceptance `accepted_for_next_station_slice`.
- Acceptance nennt explizit, dass sie nur den Homebase-Return-Slice akzeptiert.
- Snapshot und Reports bleiben read-only und setzen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_scenario_f6_host_client_playtest_notes.gd`
- `scripts/tests/task_758_station_homebase_return_acceptance_review.gd`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_758_station_homebase_return_acceptance_review.gd`
- Regressionen: TASK_757, TASK_756
- `git diff --check`

## Risiken / offene Punkte
TASK_758 akzeptiert nur den kleinen Homebase-Return-Abschluss fuer die naechste Arbeit. Der echte Spielzustand braucht danach wieder sichtbaren Mission-/Homebase-Playtest, besonders fuer HUD-Gefuehl, Multiplayer-Sync und Command-Tempo.
