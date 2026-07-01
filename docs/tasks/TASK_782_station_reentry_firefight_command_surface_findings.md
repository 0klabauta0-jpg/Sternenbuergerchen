# TASK_782 - Station Reentry Firefight Command Surface Findings

## Ziel / Problem
TASK_781 bereitet den sichtbaren Command-Surface-Recapture vor, behauptet aber bewusst keinen Sichtentscheid. TASK_782 wertet das Paket und optionale HTML-/Workbench-Notizen aus, damit aus dem Fensterblick konkrete Follow-up-Arbeit entsteht.

## Sinnhaftigkeit / Ursache
Der erste Feuerwechsel ist erst spielbar, wenn der Spieler den naechsten Griff im echten Fenster findet: Folgezeile, primaerer Griff, Quick-Actions, HOLD/FLANK/SUP, HOLD FIRE bei Friendly-Fire-Risiko und die No-Auto-Command-Grenze muessen zusammen lesbar sein.

## Umfang
- Read-only Findings-Contract fuer das TASK_781-Command-Surface-Recapture-Paket.
- Auswertung von manuellen Review-Haken aus dem HTML-Handbuch/Workbench-Export.
- Status unterscheidet:
  - fehlendes/ungueltiges Paket
  - offener sichtbarer Command-Surface-Review
  - unvollstaendige Pflichtchecks
  - konkrete Command-Surface-/Host-Client-/Performance-Follow-ups
  - bereit fuer naechste Station-Firefight-Iteration
- Manifest unter `tmp/station_reentry_firefight_command_surface_findings.json`.
- HTML-Handbuch exportiert TASK_782-Felder und Issue-Flags.

## Nicht-Ziele
- Kein automatischer Sichtentscheid.
- Kein Screenshot-Parsing.
- Kein neues Command-UI-System.
- Keine Combat-, Damage-, FireEvent-, Navigation- oder Command-Mutation.
- Keine Gesamtspiel-Abnahme.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_781_station_reentry_firefight_command_surface_recapture.md`
- `docs/tasks/TASK_780_station_reentry_firefight_interaction_polish.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`
- `scripts/mission/station_reentry_firefight_command_surface_findings.gd`

## Akzeptanzkriterien
- `StationReentryFirefightCommandSurfaceFindings.build_snapshot()` liefert ein stabiles TASK_782-Schema.
- Fehlendes oder ungueltiges TASK_781-Paket blockiert.
- Ohne manuell abgeschlossenen Sichttest bleibt der Status `needs_visible_command_surface_review`.
- Fehlende Pflichtchecks werden einzeln als `missing_check_ids` ausgegeben.
- Aktive Issue-Flags erzeugen Action Items und routen auf konkrete Folge-Tasks.
- Der Snapshot bleibt read-only und erzeugt keine Navigation, Commands, FireEvents oder DamageEvents.
- Der HTML-Bericht exportiert TASK_782-Manifestpfad, Review-Haken und Issue-Flags.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_command_surface_findings.gd`
- `scripts/tests/task_782_station_reentry_firefight_command_surface_findings.gd`
- `docs/tasks/TASK_782_station_reentry_firefight_command_surface_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_782_station_reentry_firefight_command_surface_findings.gd`
- Regression: TASK_781, TASK_780, TASK_779
- `git diff --check`

## Risiken / offene Punkte
TASK_782 wertet die menschliche Sichtpruefung aus, erzeugt sie aber nicht. Ohne echten Screenshot/Workbench-Export bleibt der Status korrekt offen.
