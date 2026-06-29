# TASK_583 - Suppress Fire AAR Report Panel Readability

## Ziel / Problem
TASK_582 zaehlt SUP-Contact-Decisions als kleinen AAR-/Debug-Wert. Der Wert ist aber noch nicht als spaeteres Debriefing-/Report-Panel lesbar. Der Spieler oder Playtester soll erkennen koennen: Wie oft wurde `SUP` als Druckabsicht eingesetzt, welches Fireteam war beteiligt, und was behauptet das System bewusst noch nicht.

## Sinnhaftigkeit / Ursache
Ein Messwert ohne lesbare Darstellung hilft nur im Testcode. Fuer einen angenehmen, spielbaren taktischen Flow braucht `SUP` eine ehrliche Auswertungssprache: nutzbar fuer spaetere AARs, aber ohne falsche Versprechen zu Ammo-Verbrauch oder echter Suppression-Wirkung.

## Umfang
- `MissionTacticalSandboxController` baut aus dem TASK_582-Snapshot ein read-only SUP-AAR-Report-Panel-Snapshot.
- Das Panel enthaelt Titel, Summary, Detailtext, Count-Chips und Fireteam-Zeilen.
- Die Darstellung nennt explizit die Grenze: keine Ammo, keine echte Suppression, kein Damage-Mod.
- Der laufende HTML-Zwischenbericht dokumentiert TASK_583 als erledigten Arbeitsstand und benennt den naechsten Anschluss.
- Verifier fuer Doku, Wiring, integrierten Missionspfad und Snapshot-Leseinvarianz.

## Nicht-Ziele
- Kein vollstaendiger Debriefing-Screen.
- Kein neues Mission-Result-System.
- Kein Ammo-Verbrauch.
- Kein echtes Suppression-System.
- Keine Aenderung an Hit-Chance, Damage, Weapon-Ticks, Movement oder ROE-Entscheidung.
- Keine UI-seitige Combat-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_582_suppress_fire_outcome_aar_diagnostic_stub.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `get_suppress_fire_aar_report_panel_snapshot()` liefert `schema = sternenbuergerchen.suppress_fire_aar_report_panel.v1`.
- Summary oder Count-Chip zeigt `SUP` und den gemessenen Count.
- Fireteam-Zeilen zeigen mindestens das beteiligte Fireteam und `SUP xN`.
- Detailtext nennt die Grenze: keine Ammo, keine echte Suppression und kein Damage-Mod.
- Der Snapshot liest den TASK_582-Diagnostic-Snapshot und bleibt read-only.
- Snapshot-Lesezugriffe veraendern weder Command-Queue noch SUP-Count.
- TASK_582 bleibt gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_583_suppress_fire_aar_report_panel_readability.gd`
- `docs/tasks/TASK_583_suppress_fire_aar_report_panel_readability.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_583_suppress_fire_aar_report_panel_readability.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_582_suppress_fire_outcome_aar_diagnostic_stub.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_581_suppress_fire_intent_outcome_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das Panel ist noch ein Snapshot, kein echter Debriefing-Screen.
- Echte Suppression-Wirkung, Munitionsverbrauch und detaillierte AAR-Metriken bleiben eigene Folgearbeit.
