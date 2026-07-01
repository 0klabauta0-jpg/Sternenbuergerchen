# TASK_772 - Station Reentry Host Client Export Findings

## Ziel / Problem
TASK_771 macht den sichtbaren Host/Client-Reentry-Lauf exportierbar. Jetzt braucht der Export eine Auswertungsschicht: Fehlt der echte Export noch, sind Checks unvollstaendig oder gibt es belegte Reibung, muss daraus ein konkreter naechster Task entstehen.

## Sinnhaftigkeit / Ursache
Ohne Findings-Gate wuerde das Exportpaket nur starten, aber keine klare Entscheidung erzeugen. Fuer den spielbaren Multiplayer-Zustand brauchen wir nachvollziehbar, ob Host/Client denselben naechsten Auftrag sehen oder ob gezielter Polish noetig ist.

## Umfang
- Neuer read-only Analyzer `StationReentryHostClientExportFindings`.
- Neuer Verifier schreibt `tmp/station_reentry_host_client_export_findings.json`.
- Auswertung von TASK_771-Exportpaket plus optionalen HTML-/Workbench-Notizen.
- Reentry-Handbuchbericht markiert TASK_772 als aktuellen Auswertungsschritt.

## Nicht-Ziele
- Kein automatisiertes Bestehen des sichtbaren Playtests.
- Kein Screenshot-/OCR-Vergleich.
- Kein Netzwerk-, Authority-, UI- oder Combat-Rewrite.
- Kein Gameplay-Commit, keine Navigation und kein GO.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_771_station_reentry_visible_host_client_playtest_export.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Findings-Snapshot bleibt `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_command = false`.
- Ungueltiges oder fehlendes TASK_771-Paket blockiert sauber.
- Ohne manuellen sichtbaren Export empfiehlt der Snapshot TASK_771 erneut.
- Fehlende Pflichtchecks werden einzeln gemeldet.
- Aktive Issue-Flags routen auf konkrete Folgeaufgaben.
- Gruene, vollstaendige Notizen routen auf TASK_773 als naechste spielbare Iteration/Acceptance.

## Betroffene Dateien
- `scripts/mission/station_reentry_host_client_export_findings.gd`
- `scripts/tests/task_772_station_reentry_host_client_export_findings.gd`
- `docs/tasks/TASK_772_station_reentry_host_client_export_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_772_station_reentry_host_client_export_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_771_station_reentry_visible_host_client_playtest_export.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_772 wertet nur Export-/Notizdaten aus. Der echte Sichtentscheid muss weiterhin aus einem manuellen Host/Client-Lauf kommen.
- Wenn der Export sauber ist, bleibt die naechste Spielbarkeitsentscheidung TASK_773.
