# TASK_753 - Station Homebase Recapture Review Gate

## Ziel / Problem
TASK_752 zeigt die Homebase-Recapture-Erwartungen in der TASK_727-Workbench, aber der Review ist noch zu grob: Der Mensch sieht eine Pflichtcheck-Liste als Text, kann die einzelnen Homebase-Schritte aber nicht sauber abhaken und der Analyzer kann daraus kein klares Follow-up-Gate ableiten.

## Sinnhaftigkeit / Ursache
Der naechste Host/Client-Lauf soll direkt sagen koennen: Ist Cargo -> Debrief -> Homebase -> naechste Sortie spielerisch lesbar, oder fehlt ein konkreter Polish-Punkt? Dafuer braucht die Workbench einzelne, exportierbare Homebase-Checks und der Snapshot braucht einen Status mit fehlenden Checks.

## Umfang
- `StationScenarioF6HostClientPlaytestNotes` baut ein read-only `homebase_recapture_review` aus Prefill-Evidence und Workbench-Notizen.
- Die TASK_727-Workbench bekommt einzelne Checkboxes fuer den Homebase-Recapture.
- Der aktuelle HTML-Bericht, Contract, Status und Roadmap nennen TASK_753.
- Ein neuer Verifier prueft offene, unvollstaendige und vollstaendige Review-Zustaende.

## Nicht-Ziele
- Kein echter Host/Client-Fenster-Sichtentscheid.
- Keine Runtime-UI-Aenderung.
- Keine Homebase-, MissionResult-, Staging-, Navigation- oder Command-Mutation.
- Kein automatisches Erfinden von Findings ohne Workbench-Export.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_752_station_homebase_recapture_workbench_prefill.md`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Die Workbench exportiert einzelne Homebase-Recapture-Checks unter `station_scenario_playtest.homebase_recapture.*`.
- Der Analyzer liefert `homebase_recapture_review.status = needs_homebase_recapture_review`, solange die manuelle Review nicht abgeschlossen ist.
- Bei gesetzter manueller Review, aber fehlenden Checks, liefert er `needs_homebase_recapture_completion` und eine Missing-Check-Liste.
- Bei gesetzter manueller Review und allen Checks liefert er `ready_for_homebase_findings`.
- `read_only = true`, `ui_sets_gameplay_truth = false` und `manual_review_done` bleiben strikt an den Workbench-Export gebunden.

## Betroffene Dateien
- `scripts/mission/station_scenario_f6_host_client_playtest_notes.gd`
- `scripts/tests/task_753_station_homebase_recapture_review_gate.gd`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_753_station_homebase_recapture_review_gate.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_752_station_homebase_recapture_workbench_prefill.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_727_station_scenario_f6_host_client_playtest_notes.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_753 wertet nur den Workbench-Export aus. Der echte Sichtlauf und daraus folgende Runtime-/Visual-Polish-Tasks bleiben der naechste Schritt.
