# Architecture Performance UX Followup Checklist

## Ziel
Diese Checkliste sammelt die manuellen Sicht- und Spielgefuehlpunkte nach TASK_330 bis TASK_337. Sie ist kein Ersatz fuer die Headless-Gates, sondern die menschliche Abnahme fuer Dinge, die ein automatischer Verifier nur begrenzt sehen kann.

## Sichtcheck FullHD
- [ ] FullHD 1920x1080: Homebase oeffnen und Roster, Transfer Team, Flightdeck, Mission Brief und Character Sheet auf Clipping, Scrollbarkeit und Lesbarkeit pruefen.
- [ ] FullHD 1920x1080: FOB oeffnen und NPC Pool, Fireteams, Loadout, Flightdeck, Boarding Status und Actions auf feste Fenster und klare Drop-Light-Proportionen pruefen.
- [ ] FullHD 1920x1080: Mission-HUD oeffnen und Mission Identity, Fireteam-Mini, Command Matrix, Selected Fireteam und Mission Control auf Ueberlagerungen pruefen.

## Kompaktprofil
- [ ] 1280x720: Homebase pruefen, ob lange Namen, Portraitkarten und Missionsdaten in den vorgesehenen Scrollbereichen bleiben.
- [ ] 1280x720: FOB pruefen, ob Board/Send, Fireteam-Auswahl und Flightdeck-Karten erreichbar bleiben.
- [ ] 1280x720: Mission-HUD pruefen, ob Move, Go, Set LZ und Call Dropship erreichbar und lesbar bleiben.

## Mission-Command-Flow
- [ ] Mission-Command-Flow: Ohne Fireteam-Auswahl Move ausloesen und erwarteten Disabled-Reason sehen.
- [ ] Mission-Command-Flow: Fireteam auswaehlen, ohne Tile Move ausloesen und klaren Tile-Hinweis sehen.
- [ ] Mission-Command-Flow: Gueltiges Tile waehlen, Move/Take/Hold/Go ausfuehren und sicherstellen, dass UI nur Befehle sendet und keine eigene Gameplay-Wahrheit erzeugt.
- [ ] Mission-Command-Flow: Plan loeschen/ersetzen und pruefen, ob Order-Visuals stale-frei aktualisieren.

## Dropship/LZ
- [ ] Dropship/LZ: Call Dropship ohne LZ pruefen und `Set LZ`-/fehlende-LZ-Feedback sehen.
- [ ] Dropship/LZ: LZ setzen, Approach wechseln und sichtbare LZ-/Approach-Linie pruefen.
- [ ] Dropship/LZ: Dropship rufen, Air-Lane-Block bei aktivem Drop sehen und danach zweites Craft testen.
- [ ] Dropship/LZ: Absetzen, Kartenstatus und Rueckflug/RTB-Feedback verfolgen.

## Multiplayer
- [ ] zwei lokale Instanzen starten und Host/Client ueber 127.0.0.1 verbinden.
- [ ] zwei lokale Instanzen: Roster-/Teamzuordnung und Start-Assignments pruefen.
- [ ] Multiplayer: Direct-IP/UPnP-Hinweise im UI lesen und sicherstellen, dass echte Internet-Erreichbarkeit als router-/firewallabhaengig kommuniziert wird.

## Follow-up-Regel
- [ ] Jedes echte Finding als kleinen Folge-Task erfassen, nicht in TASK_337 als Sammelpatch reparieren.
