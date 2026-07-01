# TASK_759 - Station Slice Next Playtest Target

## Ziel / Problem
Nach TASK_758 ist der Homebase-Return-Slice eng akzeptierbar, aber der naechste spielbare Zielpunkt muss klar sein. Der Workflow soll wieder aus Review/Acceptance heraus in einen echten kleinen Playtest fuehren.

## Sinnhaftigkeit / Ursache
Das Projektziel ist ein angenehmer, spielbarer, multiplayerfaehiger Taktikfluss. Dafuer reicht es nicht, den Rueckweg zur Homebase zu akzeptieren; der naechste Slice muss den Core Loop wieder oeffnen: Homebase -> Fireteam bereitstellen -> Loadout pruefen -> Dropship beladen -> naechste Station-Sortie starten.

## Umfang
- `StationScenarioF6HostClientPlaytestNotes` erzeugt einen read-only `station_next_playtest_target`-Snapshot.
- Der Snapshot basiert nur auf `homebase_return_acceptance_review`.
- Bei akzeptiertem Homebase-Return wird der naechste Ziel-Slice `station_reentry_playtest` bereit.
- Der Ziel-Slice beschreibt Fokus, Runbook-Schritte, Multiplayer-Pflichtchecks und Nicht-Ziele.
- Workbench und aktueller HTML-Bericht zeigen TASK_759 als neuen Zielanker.

## Nicht-Ziele
- Kein neuer Missionsmodus.
- Kein automatischer Start einer Mission.
- Keine Runtime-UI-Aenderung.
- Keine Commands, Navigation oder Gameplay-Mutation.
- Keine Gesamtspiel-Abnahme.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_758_station_homebase_return_acceptance_review.md`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Ohne akzeptierten Homebase-Return bleibt der Ziel-Slice blockiert.
- Bei `accepted_for_next_station_slice` meldet der Snapshot `ready_for_station_reentry_playtest`.
- Der Ziel-Slice nennt `station_reentry_playtest`, die Szenario-Datei und den Fokus auf Homebase-Reentry.
- Runbook-Schritte enthalten Fireteam bereitstellen, Loadout pruefen, Dropship beladen, Start freigeben und erste Mission-Entscheidung.
- Snapshot und Reports bleiben read-only und setzen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_scenario_f6_host_client_playtest_notes.gd`
- `scripts/tests/task_759_station_slice_next_playtest_target.gd`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_759_station_slice_next_playtest_target.gd`
- Regressionen: TASK_758, TASK_757
- `git diff --check`

## Risiken / offene Punkte
TASK_759 definiert den naechsten Ziel-Slice und macht ihn pruefbar, startet ihn aber noch nicht sichtbar. Danach sollte ein Run-Packet oder direkter F6-/Host-Client-Playtest fuer diesen Reentry-Slice folgen.
