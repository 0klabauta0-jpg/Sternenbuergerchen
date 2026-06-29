# TASK_584 - Mini AAR Combat Metrics Shell

## Ziel / Problem
TASK_583 macht den SUP-Zaehler als Report-Panel lesbar. Fuer ein spaeteres Debriefing fehlt noch eine kleine gemeinsame Mini-AAR-Schale, in der SUP nicht allein steht, sondern neben den wichtigsten Kampfmetriken gelesen werden kann.

## Sinnhaftigkeit / Ursache
Ein angenehmer taktischer Spiel-Flow braucht nach der Mission eine kurze, ehrliche Rueckmeldung: Was wurde gefeuert, gab es Friendly-Fire-Risiko, wie steht das Fireteam da, und wurde SUP als Druckabsicht genutzt. Dieser Task baut dafuer nur eine read-only Schale aus vorhandenen Snapshots.

## Umfang
- `MissionTacticalSandboxController.get_mini_aar_combat_metrics_snapshot()` als read-only Snapshot.
- Zusammenfassen von:
  - FireEvents / Shots fired / Hits.
  - Friendly-Fire-Event- und Risk-Zaehlern.
  - SUP-Zaehler aus TASK_583.
  - Wounded/Down/Fit aus Fireteam-Member-Status.
  - Extracted-Count als Mission-Result-Feld, wenn vorhanden.
- Kompakter Summary-Text und Row-Liste fuer spaeteres Debriefing/Report.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.
- Verifier fuer Doku, Wiring, integrierten Missionspfad und Snapshot-Leseinvarianz.

## Nicht-Ziele
- Kein vollstaendiger Debriefing-Screen.
- Kein neues Mission-Result-System.
- Kein Persistenz-/XP-/Skill-System.
- Kein Ammo-Verbrauch.
- Kein echtes Suppression-System.
- Keine Aenderung an Combat-Resolver, Damage, Movement oder ROE-Entscheidung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_583_suppress_fire_aar_report_panel_readability.md`
- `docs/tasks/TASK_582_suppress_fire_outcome_aar_diagnostic_stub.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `get_mini_aar_combat_metrics_snapshot()` liefert `schema = sternenbuergerchen.mini_aar_combat_metrics.v1`.
- Der Snapshot zeigt FireEvents / Shots fired.
- Der Snapshot enthaelt Friendly-Fire-Event- und Friendly-Fire-Risk-Felder.
- Der Snapshot uebernimmt den SUP-Zaehler aus TASK_583.
- Der Snapshot enthaelt Wounded/Down/Extracted-Felder.
- Summary und Rows sind kompakt genug fuer eine spaetere Debriefing-Oberflaeche.
- Der Snapshot bleibt read-only und mutiert weder Command-Queue noch SUP-Count.
- TASK_583 und TASK_582 bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_584_mini_aar_combat_metrics_shell.gd`
- `docs/tasks/TASK_584_mini_aar_combat_metrics_shell.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_584_mini_aar_combat_metrics_shell.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_583_suppress_fire_aar_report_panel_readability.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_582_suppress_fire_outcome_aar_diagnostic_stub.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Mini-AAR-Schale ist noch kein fertiger Debriefing-Screen.
- `extracted_count` bleibt 0, solange Mission-Result/Extract-Systeme keinen konkreten Wert liefern.
- Echte Suppression-Wirkung, Ammo-Verbrauch, XP und Skillentwicklung bleiben eigene Folgearbeit.
