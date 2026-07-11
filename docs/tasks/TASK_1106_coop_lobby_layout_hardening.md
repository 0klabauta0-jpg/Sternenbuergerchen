# TASK_1106 - Coop Lobby Layout Hardening

## Status: IMPLEMENTIERT

## Ziel / Problem
Die mit TASK_1105 lesbar gemachten Einsatzrollen muessen bei 1280x720 im vorhandenen Lobby-Panel stabil bleiben. Der bestehende Layout-Audit meldet das Panel ausserhalb des Ziel-Viewports.

## Sinnhaftigkeit / Ursache
Die Produktlobby erzeugt einen grossen Setup-Bereich dynamisch und zeigt mehrere Session-/Rollenzeilen. Container-Minimum-Sizes duerfen das bewusst feste, scrollbare 720x560-Panel weder verschieben noch vergroessern.

## Umfang
- Idle- und Drei-Peer-Zustand bei 1280x720 pruefen.
- Feste Panel-Geometrie und Viewport-Grenzen sichern.
- Vertikales Scrollen bei langem Inhalt sicherstellen.
- Lange Spielernamen und Zuschauerhinweis ohne horizontales Panelwachstum abfangen.
- Bestehende Einsatzrollen-, Ready- und Assignment-Wahrheit unveraendert lassen.

## Nicht-Ziele
- Kein manueller Drei-Fenster-Sichttest.
- Kein Redesign der gesamten Lobby.
- Keine Aenderung an Multiplayer-Assignments, Authority oder Missionsstart.
- Kein Fix des getrennten Mission-Control-Layout-Befunds aus TASK_258.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1105_coop_lobby_active_spectator_role_readability.md`
- `docs/qa/fixed_window_clipping_scrollbar_playability_audit.md`
- `docs/dev/drop_light_fixed_layout_contract.md`

## Akzeptanzkriterien
- Lobby-Panel bleibt bei 1280x720 vollstaendig im Viewport.
- Panel bleibt im Idle- und Drei-Peer-Zustand 720x560 gross.
- Der innere `ScrollContainer` bleibt auf die Panelgroesse begrenzt und vertikal scrollbar.
- Rollen-/Assignment-Labels erzwingen keine horizontale Vergroesserung.
- TASK_1105, TASK_1104, TASK_227 und der Lobby-Teil von TASK_258 bleiben konsistent.

## Betroffene Dateien
- `scripts/ui/multiplayer_lobby_screen.gd`
- `scenes/ui/multiplayer_lobby.tscn`
- `scripts/tests/task_1106_coop_lobby_layout_hardening.gd`
- Status-, Roadmap- und HTML-Arbeitsreport-Dokumentation

## Lokale Pruefung
- TASK_1106 Layout-Verifier
- TASK_1105 Rollenlesbarkeit
- TASK_1104 Drei-Peer-Produktlauf
- TASK_227 Lobby-Flow
- TASK_258 Layout-Audit mit getrennt ausgewiesenem Mission-Control-Altbefund
- `git diff --check`

## Risiken / offene Punkte
Der automatische Test belegt Geometrie, Scrollbarkeit und Textgrenzen, ersetzt aber keine subjektive Bewertung von Schriftgroesse oder visueller Hierarchie.

## Ergebnis
Der vermeintliche Produktionsfehler war eine falsche Testkoordinatenbasis: Das Projekt arbeitet headless mit seinem 1920x1080-Viewport, waehrend TASK_258 nach `root.size = 1280x720` trotzdem gegen 1280x720 verglich. Ein echter 1280x720-`SubViewport` prueft nun die Zielauflosung. Das Produktpanel bleibt in Idle und mit drei langen Peer-Zeilen exakt 720x560, zentriert bei `(280,80)`, vertikal scrollbar und horizontal begrenzt. TASK_1106 ist 10/10 gruen; TASK_258 verbessert sich auf 70/71 und meldet nur noch den getrennten Mission-Control-Befund.
