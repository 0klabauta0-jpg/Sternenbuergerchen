# TASK_628 - Mission HUD Legacy Contract Refresh

## Ziel / Problem
Der alte Drop-Light-HUD-Verifier aus TASK_180 faellt nach dem aktuellen Host/Client-HUD-Polish an zwei Stellen, die fuer den Spielerblick relevant sind:
- #16 erwartet noch Reserve-Slots in den Positionen 11-14, obwohl dort inzwischen bewusst Fire-Rule-Controls liegen.
- #17 zeigt fuer ein ausgewaehltes Fireteam im Dropship keine Member-Cards, obwohl die linke Mini-Card dasselbe Fireteam sichtbar macht.

## Sinnhaftigkeit / Ursache
Der Command-Matrix-Vertrag ist historisch nicht mit den spaeteren Fire-Rule-Controls nachgezogen worden. Die Selected-Fireteam-Lane filtert ausserdem Ground-Units zu frueh heraus; fuer Inbound-/Dropship-Fireteams ist das lesbar schlechter, weil der Spieler gerade vor dem Drop wissen will, wer im Team sitzt.

## Umfang
- TASK_180-Verifier an die aktuelle #16-Realitaet mit Fire-Rule-Buttons in Slots 11-14 anpassen.
- #17 Selected-Fireteam-Member-Lane fuer ein einzelnes ausgewaehltes Inbound-Fireteam mit deaktivierten Member-Cards fuellen.
- Contract und Status dokumentieren.
- Bestehende Runtime-/SimulationRoot-Wahrheit unveraendert lassen.

## Nicht-Ziele
- Kein neues Fire-Rule-System.
- Keine Aenderung an Combat-, ROE- oder Multiplayer-Authority-Entscheidungen.
- Kein komplettes HUD-Redesign.
- Kein neuer Dropship-State.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_627_host_client_fireteam_eventlog_overlap_polish.md`
- `scripts/tests/task_180_mission_drop_light_fixed_hud_layout_verifier.gd`

## Akzeptanzkriterien
- TASK_180 akzeptiert Fire-Rule-Controls als echte #16-Slots 11-14.
- Ein ausgewaehltes Fireteam im Dropship setzt `selected_member_cards_fireteam_id` auf dieses Fireteam.
- #17 zeigt fuer dieses Inbound-Fireteam mindestens die erwarteten Member-Cards, visuell deaktiviert.
- Keine UI-Schicht mutiert Gameplay-State.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_180_mission_drop_light_fixed_hud_layout_verifier.gd`
- `scripts/tests/task_628_mission_hud_legacy_contract_refresh.gd`
- Status/Roadmap/Contract-Doku

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_628_mission_hud_legacy_contract_refresh.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_180_mission_drop_light_fixed_hud_layout_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_627_host_client_fireteam_eventlog_overlap_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die #17-Lane zeigt Inbound-Member-Cards deaktiviert. Wenn spaeter echte Dropship-Loadout-Aktionen direkt aus #17 entstehen, brauchen diese Buttons eigene Authority-/State-Gates.
