# TASK_777 - Station Reentry Firefight Tension Feel Pass

## Ziel / Problem
TASK_776 macht den ersten Kontakt- und Druckmoment lesbar. Jetzt muss der erste Feuerwechsel selbst als spielbarer Moment pruefbar werden: Der Spieler soll erkennen, wer feuert, auf wen, mit welchem Outcome, welche Visuals dazu gehoeren und ob daraus Druck, Verletzung oder noch keine finale Ausschaltung entsteht.

## Sinnhaftigkeit / Ursache
Kontakt allein macht noch keinen taktischen Kampf. Wenn FireEvents, Fire-/Cover-Visuals, Combat-HUD und Mini-AAR-Metriken nicht zusammen lesbar sind, fuehlt sich der erste Schuss entweder wie Debug-Ausgabe oder wie ein unerklaerter Zufall an. Der Pass bindet die vorhandenen Snapshots zusammen, bevor spaetere Tasks echte Tension-, Suppression- oder AAR-Politur vertiefen.

## Umfang
- Read-only Feel-Pass fuer den ersten Firefight-Moment im Station-Reentry-Slice.
- Bewertung von:
  - TASK_776-Contact-Pressure als Voraussetzung
  - erstem FireEvent/Engagement mit Attacker, Target, Weapon und Outcome
  - Fire-/Cover-Visuals mit Trace, Impact und Unit-Badge
  - Mini-AAR-/Combat-Metriken fuer Shots, Hits, Wounded, Down und Friendly-Fire-Risiko
  - kompakter HUD-/Next-Decision-Sprache nach dem ersten Feuerwechsel
- Status, Roadmap, Contract und HTML-Handbuch aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue Damage-, Suppression-, Ammo- oder Morale-Wirkung.
- Keine neue KI-Logik.
- Keine FireEvents, Damage-Events, Commands oder Navigation aus diesem Feel-Pass.
- Kein Ersatz fuer sichtbaren Playtest oder echten Balancing-Entscheid.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_776_station_reentry_contact_pressure_feel_pass.md`
- `docs/tasks/TASK_543_mission_first_engagement_feedback.md`
- `docs/tasks/TASK_544_mission_fire_cover_visual_polish.md`
- `docs/tasks/TASK_546_mission_combat_feedback_hud_density.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Ohne gruenen TASK_776-Contact-Pressure-Pass blockiert der Firefight-Tension-Pass.
- Ein erster Feuerwechsel nennt Attacker, Target, Weapon und Outcome.
- Fire-/Cover-Visuals melden Trace, Impact/Fokus und Unit-Status-Badge.
- Combat-Metriken melden Shots, Hits, Wounded, Down und Friendly-Fire-Risiko.
- Der erste Feuerwechsel bleibt als Spannung lesbar: Treffer/Verfehlen/Verwundung/Down werden ehrlich benannt, ohne ein komplettes Balance-Urteil zu behaupten.
- HUD-/Next-Decision-Text bleibt kompakt und nennt mindestens FIRE/WAIT/NO FIRE/CONTACT plus einen naechsten Spielergriff wie hold, push, cover, retreat, flank oder suppress.
- Der Snapshot bleibt read-only, setzt keine Gameplay-Wahrheit und erzeugt keine FireEvents, Commands oder Navigation.
- Bei gruenen Gates meldet der Snapshot `ready_for_firefight_tension_playtest`.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_tension_feel_pass.gd`
- `scripts/tests/task_777_station_reentry_firefight_tension_feel_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_777_station_reentry_firefight_tension_feel_pass.gd`
- Regression: TASK_776
- `git diff --check`

## Risiken / offene Punkte
TASK_777 beweist, dass der erste Feuerwechsel als Feedback-/Tension-Moment lesbar ist. Echte Balance, laengere Feuerwechsel, Suppression/Morale und sichtbarer F6-Playtest bleiben Folgearbeit.
