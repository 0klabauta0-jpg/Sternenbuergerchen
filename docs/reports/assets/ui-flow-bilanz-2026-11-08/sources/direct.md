# Homebase Direct Dropship Flow Contract

Stand: 2026-05-14

## Ziel
Dieses Dokument haelt den manuellen Zielzustand fuer Homebase-Direct-Dropships fest. Der Contract soll verhindern, dass die funktionierende Bedienlogik bei spaeteren UI- oder Performance-Fixes wieder verloren geht.

## Homebase Direct Grundregel
- Homebase Direct umgeht die FOB fuer diesen Ablauf vollstaendig.
- Fireteams, Loadout-Auswahl und Flightdeck werden in der Homebase gebuendelt.
- `#13 LOADOUT` ist fuer Homebase Direct nicht als eigenes Fenster noetig, sobald die Waffen-Dropdowns direkt in `#10 FIRETEAMS` integriert sind.
- Die FOB darf bei Homebase-Direct-Sends keine Dropship- oder Fireteam-Karten erhalten.

## Karten-Wahrheit
- Eine Fireteam-Karte hat nur einen sichtbaren Besitzer.
- Im Homebase-Fireteam-Fenster `#10` ist sie sichtbar, solange sie nicht in ein Dropship gezogen wurde.
- Nach Drag auf eine Dropship-Karte wandert die Fireteam-Karte in genau diese Dropship-Karte und verschwindet aus `#10`.
- In der Mission bleibt ein embarked Fireteam nur in der Dropship-Payloadkarte sichtbar, bis es deboarded ist.
- Erst nach dem Deboarding erscheinen die Fireteam-/Operator-Karten als Bodentrupp links im Missions-HUD.

## Boarding und Send
- Mehrere Dropships muessen parallel boarden koennen.
- Fireteam 1 in Dropship 1 darf weiter boarden, waehrend Fireteam 2 sofort in Dropship 2 gezogen wird.
- Boarding zeigt Mini-Portraits und Fortschritt; Boardingzeit basiert auf Speed und Discipline mit etwa vier Sekunden Durchschnitt pro Fireteam.
- `Send` startet pro Dropship sofort den `to_mission`-Transit und den Fortschrittsbalken.
- Ein zweites Dropship darf senden, waehrend das erste bereits unterwegs ist.

## Mission Dropships
- `to_mission` ist ein unbedienbarer Meta-Transit: Karte grau, Fortschritt sichtbar.
- `waiting` auf der Missionskarte ist bedienbar.
- `inbound`, `landed`, `unloading` und `outbound` sind aktive Map-Phasen und duerfen nicht als unbedienbarer grauer Meta-Transit wirken.
- Erst nach dem sichtbaren Outbound-Flug zum Map-Rand wechselt ein Homebase-Direct-Dropship auf `to_homebase` und wird wieder grau.
- Die Dropship-Karte bleibt waehrend sichtbarer Map-Phasen relevant, weil Gegner das Schiff spaeter abschiessen koennen sollen.

## Per-Craft Unabhaengigkeit
- Jedes Dropship besitzt eigene Payloads, eigene LZ, eigenen Approach-Winkel, eigene Flugphase und eigene Progress-Werte.
- Eine LZ-Aenderung fuer Dropship 2 darf die LZ von Dropship 1 nicht loeschen.
- `LZ`, `NW`, `NE`, `SW`, `SE`, `Drop` und Rueckflug-Aktionen gehoeren zur jeweiligen Dropship-Karte und muessen direkt klickbar sein.
- Es darf kein globaler Drop-/Boarding-/Return-Lock entstehen, der andere Dropships blockiert.

## Visuals
- LZ-Marker bleiben pro Craft beschriftet, zum Beispiel `LZ1` und `LZ2`.
- Der Anflugvektor ist ein breiter, gruenlicher Richtungspfeil/Streifen von der Approach-Seite zur LZ.
- Approach-Buttons stehen kompakt als 2x2-Gruppe.
- Alte 2D-NPC-Sprites duerfen in der Primary-2.5D-Mission nicht sichtbar ueber den 3D-Unit-Visuals liegen.

## Performance-Regel
- Schiffszustaende duerfen pro Frame weiter simulieren.
- Vollstaendige HUD-Rebuilds, Mission-Dropship-Panel-Rebuilds, Planning-State-Emits und rekursive Unit-Tree-Suppression duerfen nicht pro Frame waehrend Fortschrittsbalken laufen.
- Fortschrittsanzeigen sollen in kurzen Intervallen aktualisieren, aber Eingabe, Drag-and-Drop und Map-Flug muessen fluessig bleiben.

## Release-Setup-Readiness
- Der Release-/Test-Direkteinstieg darf Missionstart, Transfer, LZ, Drop, Deboarding und Preview nicht mit festen Framezahlen abschaetzen.
- Missionstart gilt bei sichtbarer Mission und aktiver Missionsinstanz als bereit.
- Transfer gilt erst mit vorhandenen Missionscontroller- und Primary3DView-Nodes als bereit.
- Deboarding gilt nach mindestens einem autoritativen `SimulationRoot`-Tick und sichtbaren deployed Unit-IDs als bereit.
- Preview gilt erst mit passierendem LZ-/Move-Snapshot, geplantem Wegpunkt und explizit weiter unbestaetigtem `GO ready` als bereit.
- Alle Polls sind begrenzt und liefern bei Timeout einen benannten Blocker. Der normale zeitliche Dropship-Gameplaypfad wird dadurch nicht veraendert.

## Release-Normalstart-Guard
- Der sichtbare Release-Pfad `EXE -> Einzelspieler -> Homebase` muss direkt handlungsfaehig sein.
- Die erste Homebase im Release-Normalstart ist eine `grid_sweep`-Homebase-Direct-Sortie, nicht der alte `FOB Transfer`-Arbeitsmodus.
- Beim Anzeigen der Homebase darf der MetaLayer den bestehenden Singleplayer-Actionability-Guard erneut ausfuehren, damit lokale Save-/UI-Fragmente nicht als sichtbares `Start blockiert` stehenbleiben.
- Erwarteter Sichtzustand: Flightdeck mit Schiff, Payload mit Operatoren, Payload geboardet, Readiness `ready`, Button `Start Mission` aktiv.
- Der Guard gehoert in den MetaLayer-Startvertrag. HUD, HomebaseScreen und Snapshots duerfen den Zustand anzeigen, aber keine zweite Gameplay-Wahrheit speichern.
