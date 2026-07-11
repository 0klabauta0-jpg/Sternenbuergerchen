# TASK_1144 - Tactical Panel Header and Navigation Player Language Polish

## Ziel / Problem
Der aktuelle Full-HD-HUD zeigt trotz der bisherigen Sprachbereinigung weiterhin `COMMAND MATRIX`, `SELECTED FIRETEAM`, `MISSION CONTROL` und `Mission` als auffaellige englische Flaechentitel.

## Ursache / Sinn
Diese Texte sind statische Szenenlabels aus dem historischen Drop-Light-Layout. Ihre Node-Namen und Pfade sind technische Vertraege, die sichtbaren Texte selbst aber nicht.

## Umfang
- Die drei unteren Paneltitel in kurze deutsche Spielersprache uebersetzen.
- Den oberen Navigationspunkt `Mission` als `Einsatz` anzeigen.
- `Homebase` und `FOB` als etablierte Eigennamen beibehalten.
- Bestehende Node-Namen, NodePaths und Blocknummern unveraendert lassen.

## Nicht-Ziele
- Kein Layoutumbau und keine neue Lokalisierungsarchitektur.
- Keine Aenderung an Navigation, Commands, Simulation, Multiplayer oder Snapshots.
- Keine repo-weite Uebersetzung historischer Testmeldungen oder technischer Begriffe.

## Akzeptanzkriterien
- Sichtbar stehen `#16 BEFEHLE`, `#17 AUSGEWAEHLTES FIRETEAM`, `#18 EINSATZKONTROLLE` und `Einsatz`.
- `Homebase` und `FOB` bleiben sichtbar unveraendert.
- Die bestehenden technischen Node-Namen und Navigationscallbacks bleiben erhalten.
- Fixed-HUD-, Button-, Multiplayer-, Performance- und Full-HD-Regressionslaeufe bleiben gruen.

## Betroffene Dateien
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/task_1144_tactical_panel_header_navigation_player_language_polish.gd`
- bestehender Fixed-HUD-Verifier
- Status, Roadmap, Contract und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1144-Verifier
- TASK_180 Fixed-HUD-Layout
- TASK_257 Button-Reachability
- TASK_1118 Multiplayer-Perspektive
- TASK_1136 Real Window
- TASK_222 Performance-Gate
- `git diff --check`

## Risiken / offene Punkte
Historische Testmeldungen duerfen weiterhin von `#16/#17/#18` und den alten englischen Bezeichnungen sprechen. Geaendert werden nur aktuelle sichtbare Assertions und Szenentexte, nicht historische Evidenz oder stabile NodePaths.
