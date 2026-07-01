# TASK_773 - Station Reentry Host Client Identity Cue Polish

## Ziel / Problem
Der echte Zwei-Fenster-Reentry-Lauf rendert Host und Client sichtbar, aber die Fireteam-Mini-Cards zeigen im Client nur den aktuellen Session-Kontext wie `P2 BRAVO`. Dadurch kann eine fremde Fireteam-Karte so wirken, als gehoere sie direkt zur Client-Session oder sei kommandierbar.

## Sinnhaftigkeit / Ursache
TASK_772 hat das Export-/Findings-Gate fuer den Host/Client-Lauf vorbereitet. Der anschliessende echte Capture zeigt: Route, Cue, Welt und Header sind lesbar; die naechste konkrete Reibung liegt in der Identitaetslesbarkeit der Fireteam-Karten.

Die Mini-Card mischt aktuell Session-Identitaet und Fireteam-Status, ohne den Bezug zum Fireteam-Team zu nennen. Das ist besonders im PvP-/Coop-Fall gefaehrlich, weil Host/Client-Session, Team und Fireteam nicht dasselbe sind.

## Umfang
- Fireteam-Mini-Card-Kontext um `OWN`/`VIEW` und Fireteam-Team-Cue erweitern.
- Read-only Presenter-/Snapshot-Helfer fuer Session-vs-Fireteam-Bezug einfuehren.
- Tooltip mit voller Session-/Fireteam-Erklaerung ausgeben.
- Bestehende Mini-Card-Statuszeile weiterverwenden; keine Authority-, Command- oder Team-Zuweisung aendern.
- Laufenden HTML-Iststand-/Handbuchbericht aktualisieren.

## Nicht-Ziele
- Kein Multiplayer-Authority-Rewrite.
- Keine neue Command-Filterung.
- Keine echte Ownership-Mutation im HUD.
- Kein neues Team-/Fireteam-Datenmodell.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_772_station_reentry_host_client_export_findings.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Host/Client-Fireteam-Karten zeigen eine kurze Relation, z. B. eigenes Team oder Fremdteam-View.
- Fremde Fireteam-Karten sind nicht mehr nur mit Session-Text markiert.
- Tooltip benennt Session, Fireteam-Team und Relation.
- Snapshot-/Verifier prueft Own-/Foreign-/Unknown-Faelle read-only.
- UI setzt keine Gameplay-Wahrheit und enqueued keine Commands.

## Betroffene Dateien
- `scripts/mission/station_reentry_host_client_fireteam_card_context.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_773_station_reentry_host_client_identity_cue_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_773_station_reentry_host_client_identity_cue_polish.gd`
- TASK_772 Regression
- `git diff --check`

## Risiken / offene Punkte
- Die sichtbare Lesbarkeit wird technisch abgesichert, aber ein finaler menschlicher Zwei-Fenster-Sichtentscheid bleibt sinnvoll.
- Wenn Fireteam-Teamdaten fehlen, muss der Cue ehrlich `FT ?` melden statt Besitz zu raten.
