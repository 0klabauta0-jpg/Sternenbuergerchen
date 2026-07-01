# TASK_775 - Station Reentry Mission Interaction Feel Pass

## Ziel / Problem
TASK_774 akzeptiert den Station-Reentry-Slice eng fuer den naechsten spielbaren Schritt. Jetzt muss der Missionsmoment selbst wieder in den Vordergrund: Der Spieler soll nach dem Drop nicht nur stabile Panels sehen, sondern sofort verstehen, welche Interaktion als naechstes dran ist und welcher Befehl dazu passt.

## Sinnhaftigkeit / Ursache
Die Review-Probleme lagen immer wieder an Bruechen im Spielerpfad: Daten waren vorhanden, aber der naechste Griff war nicht eindeutig. Nach Homebase, Dropship, Preview und Host/Client-Identity muss deshalb AA -> Door -> Computer -> Cargo als Missionshandlung lesbar sein.

## Umfang
- Read-only Feel-Pass fuer die Station-Reentry-Missionsinteraktionen.
- Bewertung von:
  - TASK_774-Acceptance
  - Route-Sequenz `AA > DOOR > COM > CARGO`
  - je einem spielernahen Cue fuer AA, Door, Computer und Cargo
  - Command-Affordances fuer Move, Take, Breach, Defend und GO
  - kurze HUD-/Cue-Texte ohne zweite UI-Wahrheit
- Report, Status, Roadmap und Contract aktualisieren.

## Nicht-Ziele
- Kein neues Objective-System.
- Keine neue Interaction-Mutation.
- Kein Combat-Rewrite.
- Kein vollstaendiger Playtest oder Gesamtspiel-Acceptance.
- Keine Commands, Navigation oder Gameplay-Wahrheit aus dem Feel-Pass.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_774_station_reentry_next_playable_slice_acceptance.md`
- `scripts/mission/station_scenario_route_cue_polish.gd`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Ohne akzeptierten TASK_774-Slice blockiert der Feel-Pass.
- Route-Sequenz enthaelt AA, DOOR, COM und CARGO in richtiger Reihenfolge.
- Cues fuer alle vier Schritte sind aktiv, kurz, lesbar und nutzen Handlungssprache.
- Command-Affordances nennen Move, Take, Breach, Defend und GO.
- Der Snapshot bleibt read-only, setzt keine Gameplay-Wahrheit und erzeugt keine Commands.
- Bei gruenen Gates meldet der Snapshot `ready_for_mission_interaction_playtest`.

## Betroffene Dateien
- `scripts/mission/station_reentry_mission_interaction_feel_pass.gd`
- `scripts/tests/task_775_station_reentry_mission_interaction_feel_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_775_station_reentry_mission_interaction_feel_pass.gd`
- Regression: TASK_774
- `git diff --check`

## Risiken / offene Punkte
TASK_775 beweist Spielgriff-Lesbarkeit, nicht Kampfspannung. Danach ist der naechste sinnvolle Schritt ein Contact-/Combat-Pressure-Feel-Pass, damit die Station nicht nur bedienbar, sondern taktisch spannend wird.
