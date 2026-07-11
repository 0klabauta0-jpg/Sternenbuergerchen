# TASK_1130 - Fireteam Mini-Card Identity and Typography Polish

## Status: IMPLEMENTIERT

## Ziel / Problem
Der TASK-1129-Full-HD-Beleg zeigt links korrekte BLUE-/GOLD-Karten, aber sehr kleine Statuszeilen und das sichtbare Badge `FT ?`, obwohl in der normalen Mission gar keine Review-/Multiplayer-Session aktiv ist.

## Sinnhaftigkeit / Ursache
- Der Review-Session-Presenter liefert bei leerer Session ehrlich `FT ?`; der Controller blendet diesen Kontext jedoch auch dann ein, wenn `session.active == false`.
- `FOBFireteamCard` reduziert im `mission_mini`-Kontext Titel auf 10 px und Stage-/Memberzeilen auf 8 px.
- Die Fireteam- und Team-Wahrheit selbst ist vorhanden; der Fehler liegt ausschließlich in Sichtbarkeit und Typografie der Leseschicht.

## Umfang
- Review-Session-Kontext auf Mini-Cards nur anzeigen, wenn eine Session wirklich aktiv ist.
- In aktiven Host/Client-Sessions OWN/VIEW/FT?-Semantik unveraendert lassen.
- Mission-Mini-Card-Titel auf mindestens 12 px anheben.
- Stage- und Memberstatus auf mindestens 10 px anheben.
- Full-HD-Capture auf Clipping, Bubble-Anker und Kartenabstand erneut pruefen.

## Nicht-Ziele
- Keine Aenderung der Fireteam-, Team-, Peer- oder Multiplayer-Zuweisung.
- Kein Redesign der gesamten linken Seitenleiste.
- Keine Entfernung des ehrlichen `FT ?` bei einer tatsaechlich aktiven Session mit unbekannter Teamzuordnung.
- Keine Gameplay-, Command-, Event-, Effect-, RPC- oder Snapshotmutation.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_773_station_reentry_host_client_identity_cue_polish.md`
- `docs/tasks/TASK_1128_tactical_communication_hud_bubble_density_real_window_readability.md`
- `docs/tasks/TASK_1129_tactical_communication_bubble_typography_mode_contract_reconciliation.md`

## Akzeptanzkriterien
- Normale lokale Mission zeigt auf keiner Fireteam-Mini-Card `FT ?`.
- BLUE- und GOLD-Titel bleiben korrekt und verwenden mindestens 12 px.
- Stage- und Memberstatus verwenden mindestens 10 px.
- Aktive unbekannte Review-Session liefert im Presenter weiterhin `FT ?`.
- Zwei Fireteam-Bubbles bleiben nach der Kartenvergroesserung kollisionsfrei und korrekt verankert.
- Multiplayer- und Performance-Gates bleiben gruen.

## Betroffene Dateien
- `scripts/meta/fob_fireteam_card.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1130_fireteam_mini_card_identity_typography_polish.gd`
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1130 RED/GREEN.
- TASK_773 fuer aktive Unknown-Session-Semantik.
- TASK_1128 headless und Real Window.
- TASK_431, TASK_503, TASK_1119, TASK_1104 und TASK_222.
- `git diff --check`.

## Risiken / offene Punkte
Groessere Schrift kann Text abschneiden oder den vertikalen Kartenabstand veraendern. Der echte Full-HD-Capture ist deshalb Teil der Akzeptanz und nicht nur optionaler Schmuck.

Der Full-HD-Beleg bleibt kollisionsfrei. Der verbleibende sichtbare Befund ist der schwache BLUE-/GOLD-Headerkontrast direkt unter den oberen Bars; dieser wird als eigener Folge-Slice behandelt.

## Ergebnis
- Eine inaktive lokale Review-Session erzeugt keinen sichtbaren Kontexttext und kein `FT ?`.
- Aktive OWN/VIEW/Unknown-Semantik des Host/Client-Presenters bleibt unveraendert.
- Mission-Mini-Card-Titel verwenden 12 px, Stage- und Memberstatus 10 px.
- BLUE und GOLD bleiben die sichtbaren Fireteam-Namen.
- Der echte Full-HD-Capture zeigt weder Karten-/Bubble-Kollision noch abgeschnittene Bubbles.

## Lokale Pruefergebnisse
- TASK_1130: 6/6.
- TASK_773: 25/25.
- TASK_431: 19/19.
- TASK_1128 Real Window: 8/8.
- Sichtbeleg: `tmp/task_1128_tactical_communication_hud_bubble_density.png`.
