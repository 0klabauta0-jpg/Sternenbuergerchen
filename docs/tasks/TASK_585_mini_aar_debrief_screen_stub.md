# TASK_585 - Mini AAR Debrief Screen Stub

## Ziel / Problem
TASK_584 sammelt FireEvents, Friendly-Fire-Risiko, SUP und Fireteam-Status in einer read-only Mini-AAR-Schale. Fuer Spielbarkeit fehlt der naechste kleine Schritt: diese Daten sollen als Debrief-Screen-Stub lesbar werden, ohne daraus schon ein vollstaendiges Result-, XP-, Ammo- oder Suppression-System zu machen.

## Sinnhaftigkeit / Ursache
Ein taktisches Spiel wird angenehmer, wenn der Spieler nach einem Einsatz sofort versteht, was passiert ist. Der Stub gibt dem spaeteren Debriefing eine konkrete Form: Titel, Summary, Metrikzeilen, Chips und ehrliche Grenzen.

## Umfang
- `MissionTacticalSandboxController.get_mini_aar_debrief_screen_snapshot()` als read-only Snapshot.
- Aufbau aus `get_mini_aar_combat_metrics_snapshot()`.
- Kompakte Debrief-Struktur:
  - Titel und Untertitel.
  - Summary-Zeile.
  - Metrik-Cards/Rows fuer Fire, Friendly Fire, SUP und Status.
  - kurze Chips fuer `shots`, `ff`, `sup`, `wounded`, `extracted`.
  - Grenztext: keine XP, keine Ammo, keine echte Suppression.
- HTML-Zwischenbericht, Status, Roadmap und Contract fortschreiben.
- Verifier fuer Doku, Wiring, integrierten Missionspfad und Snapshot-Leseinvarianz.

## Nicht-Ziele
- Kein vollstaendiger Debriefing-Screen mit Navigation.
- Keine XP-/Skill-Vergabe.
- Kein Ammo-Verbrauch.
- Keine echte Suppression-Wirkung.
- Keine MissionResult-Mutation.
- Keine neue Scene oder grosses UI-Layout.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_584_mini_aar_combat_metrics_shell.md`
- `docs/tasks/TASK_583_suppress_fire_aar_report_panel_readability.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `get_mini_aar_debrief_screen_snapshot()` liefert `schema = sternenbuergerchen.mini_aar_debrief_screen_stub.v1`.
- Der Snapshot liest den TASK_584-Mini-AAR-Snapshot und meldet dessen Schema.
- Titel, Summary, Rows und Chips sind vorhanden und kompakt.
- Der Grenztext nennt keine XP/Ammo/echte Suppression als erledigt.
- Der Snapshot bleibt read-only und mutiert weder Command-Queue noch SUP-Count.
- TASK_584 und TASK_583 bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_585_mini_aar_debrief_screen_stub.gd`
- `docs/tasks/TASK_585_mini_aar_debrief_screen_stub.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_585_mini_aar_debrief_screen_stub.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_584_mini_aar_combat_metrics_shell.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_583_suppress_fire_aar_report_panel_readability.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Stub ist noch kein echtes navigierbares Debriefing.
- Echte Mission-Result-Visualisierung, XP, Skillentwicklung, Ammo und Suppression-Wirkung bleiben eigene Tasks.
