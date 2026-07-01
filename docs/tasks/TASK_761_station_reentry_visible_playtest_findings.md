# TASK_761 - Station Reentry Visible Playtest Findings

## Ziel / Problem
TASK_760 macht den Station-Reentry-Lauf startbar, aber die sichtbare Auswertung ist noch nicht verdichtet. Es braucht ein Findings-Gate, das offene Sichtchecks ehrlich markiert und konkrete Folgeaufgaben aus Reentry-Notizen ableitet.

## Sinnhaftigkeit / Ursache
Der naechste Spielzug soll wieder anfassbar werden: Homebase-Return lesen, Fireteam bereitstellen, Loadout pruefen, Dropship beladen, Start freigeben und die erste Missionsentscheidung mit Preview treffen. Ohne getrennte Reentry-Findings wuerden alte Station-Route-Checks und neuer Sortie-Start vermischt.

## Umfang
- Neuer read-only Analyzer `StationReentryPlaytestFindings`.
- Manifest `tmp/station_reentry_visible_playtest_findings.json`.
- Reentry-spezifische Workbench-Checks und Follow-up-Flags.
- Status, Roadmap, Contract und HTML-Handbuch werden aktualisiert.

## Nicht-Ziele
- Kein automatischer sichtbarer Playtest.
- Kein Gameplay-Commit, kein Start-Command und keine Navigation.
- Kein Combat-, Dropship- oder Loadout-Rewrite.
- Keine Gesamtspiel-Abnahme.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_760_station_reentry_playtest_run_packet.md`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Findings-Schema ist `sternenbuergerchen.station_reentry_visible_playtest_findings.v1`.
- Quelle ist das TASK_760-Run-Packet.
- Fehlendes oder ungueltiges Packet blockiert.
- Ohne manuelle Reentry-Notizen bleibt der Status `needs_visible_reentry_playtest`.
- Unvollstaendige Reentry-Checks melden fehlende Check-IDs.
- Aktive Reentry-Issue-Flags werden in konkrete Action-Items uebersetzt.
- Snapshot und Manifest bleiben read-only und setzen keine UI-/Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_playtest_findings.gd`
- `scripts/tests/task_761_station_reentry_visible_playtest_findings.gd`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/prepare_station_reentry_playtest_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_761_station_reentry_visible_playtest_findings.gd`
- Regressionen: TASK_760, TASK_759
- `git diff --check`

## Risiken / offene Punkte
TASK_761 sagt weiterhin nicht, dass der sichtbare Reentry-Playtest erledigt ist. Der naechste echte Fortschritt entsteht entweder durch einen Workbench-Export mit Befunden oder durch einen kleinen Folgepolish aus konkreten Reentry-Flags.
