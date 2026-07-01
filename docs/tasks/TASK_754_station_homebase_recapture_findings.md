# TASK_754 - Station Homebase Recapture Findings

## Ziel / Problem
TASK_753 macht den Homebase-Recapture als einzelnes Review-Gate auswertbar. Es fehlt noch die direkte Uebersetzung dieses Gate-Status in konkrete Findings und naechste Arbeit: Ist der echte Review noch offen, fehlen einzelne Checks, oder ist der Weg bereit fuer einen spielbaren Homebase-Panel-Polish?

## Sinnhaftigkeit / Ursache
Damit wir nicht in Review-Meta stecken bleiben, muss die Workbench-Auswertung klare Aktionen erzeugen. Der naechste Entwicklergriff soll direkt erkennbar sein, ohne Chat-Kontext oder manuelles Interpretieren der Checkliste.

## Umfang
- `StationScenarioF6HostClientPlaytestNotes` baut aus `homebase_recapture_review` ein read-only `homebase_recapture_findings`.
- Die Findings unterscheiden:
  - echter Review fehlt
  - Review ist unvollstaendig
  - Review ist bereit fuer sichtbaren Homebase-Panel-Polish
- Die TASK_727-Workbench und der aktuelle HTML-Bericht zeigen den Findings-Status und den empfohlenen Folge-Task.
- Contract, Status, Roadmap und Verifier werden aktualisiert.

## Nicht-Ziele
- Kein echter Host/Client-Fenster-Sichtentscheid.
- Keine Runtime-UI-Aenderung in diesem Task.
- Keine Homebase-, MissionResult-, Staging-, Navigation- oder Command-Mutation.
- Keine erfundenen Polishing-Findings ohne Review-Evidence.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_753_station_homebase_recapture_review_gate.md`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Ohne abgeschlossenen Homebase-Review meldet Findings-Status `blocked_missing_real_homebase_review`.
- Bei abgeschlossener Review mit fehlenden Checks meldet Findings-Status `needs_review_completion` und uebernimmt die Missing-Check-Liste.
- Bei vollstaendiger Review meldet Findings-Status `ready_for_homebase_panel_polish`.
- Die empfohlene Folgeaufgabe lautet bei vollstaendigem Review `TASK_755 - Station Homebase Return Panel Polish`.
- `read_only = true`, `ui_sets_gameplay_truth = false` und `creates_command = false` bleiben Pflicht.

## Betroffene Dateien
- `scripts/mission/station_scenario_f6_host_client_playtest_notes.gd`
- `scripts/tests/task_754_station_homebase_recapture_findings.gd`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_754_station_homebase_recapture_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_753_station_homebase_recapture_review_gate.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_727_station_scenario_f6_host_client_playtest_notes.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_754 ist der letzte Findings-Schnitt vor echter Runtime-/Visual-Arbeit. Wenn der Sichtlauf weiter uebersprungen wird, ist der naechste sinnvolle konkrete Schritt trotzdem ein kleiner Homebase-Panel-Polish aus dem bisherigen Headless-/Workbench-Vertrag.
