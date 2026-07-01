# TASK_756 - Station Homebase Real Window Recapture

## Ziel / Problem
Nach TASK_755 muss der naechste echte Host/Client-Fensterlauf nicht nur die alte Next-Sortie-Zeile pruefen, sondern den neuen Return-Panel-Zustand: `Rueckkehr abgeschlossen`, `Naechster Auftrag`, Step-Chips und TASK_755-Style.

## Sinnhaftigkeit / Ursache
Die Recapture-Kette aus TASK_750 bis TASK_754 wurde vor dem Return-Panel-Polish gebaut. Ohne Aktualisierung koennte ein echter Fensterlauf weiterhin nur TASK_749-Microcopy abhaken und das neue Panel uebersehen. Das wuerde den Review-Pfad wieder von der sichtbaren Spielerfuehrung entkoppeln.

## Umfang
- Homebase-Recapture-Paket referenziert TASK_755 als aktuelle Quelle.
- Capture-Metadaten enthalten erwarteten Return-Panel-Titel, Aktionszeile, Style-ID, Chip-Anzahl und Chip-Labels.
- TASK_727-Workbench exportiert neue Homebase-Return-Panel-Haken.
- `StationScenarioF6HostClientPlaytestNotes` nimmt die neuen Felder in seine read-only Evidence und Review-Gates auf.
- Verifier prueft Paket, Capture-Script, Workbench, Analyzer und Report-Anker.

## Nicht-Ziele
- Kein menschlicher Sichttest wird als erledigt markiert.
- Kein echtes Gameplay wird aus dem Report heraus mutiert.
- Kein neuer Homebase-Command und keine automatische Navigation.
- Kein Ersatz fuer eine spaetere Findings-/Acceptance-Auswertung nach echtem Export.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_755_station_homebase_return_panel_polish.md`
- `docs/tasks/TASK_750_station_homebase_host_client_recapture_packet.md`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Paket und Capture-Metadaten nennen `TASK_756` und `TASK_755`.
- Erwartet werden `task_755_station_homebase_return_panel_v1`, `Rueckkehr abgeschlossen`, `Naechster Auftrag: Fireteam bereitstellen` und fuenf Step-Chips.
- Workbench exportiert Haken fuer Titel, Aktionszeile, Chips und TASK_755-Abgleich.
- Analyzer meldet `homebase_return_panel_evidence_ready = true`, wenn diese Felder im Capture-Manifest liegen.
- Review-Gate verlangt die neuen Checks, bleibt aber read-only.

## Betroffene Dateien
- `scripts/tools/prepare_station_homebase_host_client_recapture.ps1`
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/mission/station_scenario_f6_host_client_playtest_notes.gd`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `scripts/tests/task_756_station_homebase_real_window_recapture.gd`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/prepare_station_homebase_host_client_recapture.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_756_station_homebase_real_window_recapture.gd`
- Regressionen: TASK_750, TASK_751, TASK_752, TASK_753, TASK_754, TASK_755
- `git diff --check`

## Risiken / offene Punkte
TASK_756 macht die echte Fenster-Recapture-Kette aktuell, behauptet aber weiterhin keine menschliche Abnahme. Nach einem echten Workbench-Export braucht es einen Findings- oder Acceptance-Slice, der konkrete Sichtbefunde auswertet.
