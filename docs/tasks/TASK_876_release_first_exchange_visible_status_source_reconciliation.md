# TASK_876 - Release First Exchange Visible Status Source Reconciliation

## Ziel / Problem
TASK_875 hat gezeigt: Der TASK_874-Capture ist trusted, aber der echte Fensterblick zeigt nach TASK_873 weiter `NO_FIRE/NO_LOS` und `CONTACT PRESSURE` als erste Spielerlesung. TASK_876 versoehnt deshalb die sichtbaren #17/#18/#19-Statusquellen mit der bereits validierten TASK_873-CONTACT-FIRE-Evidence.

## Sinnhaftigkeit / Ursache
Der Fehler ist keine neue Combat-Regel, sondern ein Anzeige-/Refresh-Problem: Die normale Combat-Diagnose kann nach dem First-Exchange wieder auf `NO_LOS` kippen und dadurch die realen Labels ueberschreiben, obwohl fuer den Release-First-Exchange bereits Fire-Exchange-Evidence existiert. Fuer den echten Fensterblick muss diese Evidence laenger als read-only Statusquelle verfuegbar bleiben.

## Umfang
- TASK_873-Evidence als eigene read-only First-Exchange-Statusquelle im TacticalController halten.
- Combat-HUD-Density nutzt diese Quelle, wenn sie aktiv ist.
- #17 Selected Fireteam, #18 Mission Control und #19 Event Log bekommen weiter CONTACT-FIRE-first waehrend des Release-First-Exchange-Fensters.
- Headless-Snapshot und dynamischer MetaLayer-Verifier sichern den echten Deep-Link-Pfad ab.
- Status, Roadmap und Contract synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents oder Commands.
- Keine zweite Gameplay-Wahrheit.
- Kein neuer Real-Window-Capture in diesem Task.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_875_release_first_exchange_contact_fire_visual_findings.md`
- `docs/tasks/TASK_873_release_first_exchange_contact_fire_readability_fix.md`

## Akzeptanzkriterien
- `get_release_first_exchange_visible_status_source_reconciliation_snapshot()` meldet Gate `pass`.
- Dynamischer MetaLayer-Deep-Link erzeugt aktive TASK_876-Statusquelle.
- #17/#18 beginnen mit CONTACT FIRE.
- #19 Event Log enthaelt CONTACT FIRE statt nur CONTACT PRESSURE.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_876_release_first_exchange_visible_status_source_reconciliation.gd`
- `docs/tasks/TASK_876_release_first_exchange_visible_status_source_reconciliation.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_876_release_first_exchange_visible_status_source_reconciliation.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_875_release_first_exchange_contact_fire_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_876 beweist den Headless-/Deep-Link-Statuspfad. Danach braucht es TASK_877 als frischen echten Fenster-Recapture, um zu sehen, ob der reale PNG-Blick nun ebenfalls CONTACT FIRE / FireTrace / Impact lesbar macht.
