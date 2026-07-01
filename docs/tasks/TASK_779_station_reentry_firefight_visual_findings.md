# TASK_779 - Station Reentry Firefight Visual Findings

## Ziel / Problem
TASK_778 bereitet den sichtbaren Firefight-Playtest vor, behauptet aber bewusst keinen Sichtentscheid. TASK_779 wertet das Paket und optionale HTML-/Workbench-Notizen aus, damit aus dem Fensterblick konkrete Follow-up-Arbeit entsteht.

## Sinnhaftigkeit / Ursache
Der erste Feuerwechsel ist erst dann spielerisch belastbar, wenn Trace, Impact/Fokus, Unit-Badge, Combat-HUD, Metriken und Friendly-Fire-Risiko im echten Fenster zusammen lesbar sind. Headless-Gates koennen diesen Eindruck vorbereiten, aber nicht ersetzen.

## Umfang
- Read-only Findings-Contract fuer das TASK_778-Firefight-Visual-Paket.
- Auswertung von manuellen Review-Haken aus dem HTML-Handbuch/Workbench-Export.
- Status unterscheidet:
  - fehlendes/ungueltiges Paket
  - offener sichtbarer Firefight-Review
  - unvollstaendige Pflichtchecks
  - konkrete Visual-/HUD-/Metrik-/Performance-/Host-Client-Follow-ups
  - bereit fuer naechste Firefight-Iteration
- Manifest unter `tmp/station_reentry_firefight_visual_findings.json`.
- HTML-Handbuch exportiert TASK_779-Felder und Issue-Flags.

## Nicht-Ziele
- Kein automatischer Sichtentscheid.
- Kein Screenshot-Parsing.
- Keine Combat-, Damage-, FireEvent-, Navigation- oder Command-Mutation.
- Kein Fire-/Cover-Visual-Polish in diesem Task.
- Keine Gesamtspiel-Abnahme.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_778_station_reentry_firefight_visual_playtest_packet.md`
- `docs/tasks/TASK_777_station_reentry_firefight_tension_feel_pass.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`
- `scripts/mission/station_reentry_firefight_visual_findings.gd`

## Akzeptanzkriterien
- `StationReentryFirefightVisualFindings.build_snapshot()` liefert ein stabiles TASK_779-Schema.
- Fehlendes oder ungueltiges TASK_778-Paket blockiert.
- Ohne manuell abgeschlossenen Sichttest bleibt der Status `needs_visible_firefight_review`.
- Fehlende Pflichtchecks werden einzeln als `missing_check_ids` ausgegeben.
- Aktive Issue-Flags erzeugen Action Items und routen auf konkrete Folge-Tasks.
- Der Snapshot bleibt read-only und erzeugt keine Navigation, Commands, FireEvents oder DamageEvents.
- Der HTML-Bericht exportiert TASK_779-Manifestpfad, Review-Haken und Issue-Flags.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_visual_findings.gd`
- `scripts/tests/task_779_station_reentry_firefight_visual_findings.gd`
- `docs/tasks/TASK_779_station_reentry_firefight_visual_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_779_station_reentry_firefight_visual_findings.gd`
- Regression: TASK_778 und TASK_777
- `git diff --check`

## Risiken / offene Punkte
TASK_779 wertet die menschliche Sichtpruefung aus, erzeugt sie aber nicht. Ohne echten Screenshot/Workbench-Export bleibt der Status korrekt offen.
