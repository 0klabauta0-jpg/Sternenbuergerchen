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

Fuer die beiden Einzelspieler-Ortsreisen gilt seit 09.11.2026 die Erweiterung
`orbit_quantum_travel_contract.md`: `Abheben` fuehrt zuerst zum Mondorbit.
Der folgende `to_mission`-Handoff beginnt erst beim ausdruecklichen Ortsanflug
aus dem Planetenorbit. Andere Skirmish-/Compatibility-Transporte behalten den
nachfolgenden bisherigen Send-Vertrag.

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

## Truppkarte und Basisnavigation — 10.11.2026
- Der einzelne ausgewählte Trupp erscheint einmal als gemeinsame Karte mit
  quadratischen Porträts, Status, Haltung, Feuerregel, Details und Aufsitzen.
  Weitere Trupps bleiben in der scrollbaren Übersicht auswählbar.
- Aufsitzen gehört zum Trupp. Es befiehlt dem ausgewählten Trupp den realen
  Rückweg zum eigenen gelandeten Kampagnenschiff und verwendet die vorhandenen
  Boardingeffekte. Andere Trupps werden dabei nicht ausgewählt; kein Abheben.
  Ohne Schiff/Berechtigung/boardingfähige Mitglieder bleibt ein Sperrgrund sichtbar.
- UI-Karten und deren zwischengespeicherte Porträts sind Projektionen.
  Doppelklick nach Truppwechsel muss die aktuelle Person öffnen. Unveränderte
  Projektionen erhalten Controls und Signalverbindungen.
- Basis erkunden bietet ein Hover-Untermenü: Bauen, Werkstatt/Blueprints,
  Lager/Ausrüstung, Datenterminal/Hochladen und Schiff. Die Einträge liegen in der
  linken Navigation; beim Verlassen wird zugeklappt. Tastaturfokus öffnet ebenfalls.
- Das Datenterminal unterscheidet fehlende Daten, fehlgeschlagene Aufträge,
  bereits hochgeladene Daten und einen tatsächlich vorhandenen Upload.
  Schlafen erzeugt/verbraucht keine Missionschips. Upload bleibt der vorhandene
  autoritative Heimatbasis-Command, kein UI-generierter Ersatzchip.

## Basis-Seitenfenster und Aufträge — 10.11.2026
- Bauen, Werkstatt/Blueprints, Lager/Ausrüstung, Datenterminal und Smart Mobile
  öffnen rechts neben der Navigation schließbare Seitenfenster. Die Basis
  bleibt sichtbar; ein Hintergrundfang verhindert unbeabsichtigte Kartenbefehle.
  Öffnen animiert nur die UI-Position/Deckkraft, keine Simulation oder Ladung.
- Tankservice ist Unterpunkt des Flugdecks, kein zweiter Schiff-Eintrag in der
  Basisverwaltung. Derselbe vorhandene Serviceowner bleibt zuständig.
- Ursprüngliches Porträt neben dem Namen erhalten. Größere Figur in bestehender
  Idle-Pose: bis 300×450 im breiten Ausrüstungsfenster, responsive schmaler in engen
  Spalten. Rüstung/Primär/Sekundär liegen seitlich, ohne die Figur zu überdecken. Bestand bleibt frei
  und wird nicht erneut um bereits getragene Gegenstände verringert.
- Smart Mobile projiziert die vorhandenen autoritativen `locked`-Flags. Verborgene
  spätere Missionen bleiben auch gegen direkte Commands gesperrt. Anfangs nur
  Satellitendaten; erst der reale Abschluss mit Heim-Upload öffnet Außenposten.
- Unveränderliche Auftraggeber-Inhaltsidentität kommt aus job_issuers.json über
  den Jobcontract. Satellitendaten: Fragwürdige Geschäftsleute. Kein Rufstand in
  UI/Saves hinzugefügt; Rufskala und Wirkung bleiben als Zukunftsplanung offen.

## Satellitendatenträger und Menü-Illustrationen — 10.11.2026
- Bestätigtes Sichern erzeugt genau einen bekannten Questgegenstand im Rucksack
  des tatsächlichen aktuellen Truppführers. Trusted Adapter liest dafür die
  bestätigten Runtime-Gates und Use-Zustände, nicht UI-Text oder Clientpayloads.
  Der existierende SimulationRoot/SupplyOwner verarbeitet den Item-Command.
- Der Abschluss-/Rücktransportpfad erzeugt keinen zweiten Chip, wenn der
  geborgene Gegenstand bereits vorhanden ist. Bestehende Schiffsfracht bleibt
  als Legacy-Pfad unterstützt. Upload zuhause verbraucht genau den vorhandenen
  Gegenstand aus Rucksack, Fracht oder Basislager, ohne neue Items zu erfinden.
- Charakterdetails auf der Map lesen den vorhandenen Rucksackbestand und zeigen
  den Datenträger als Item mit Icon; sie besitzen keine zweite Inventarwahrheit.
- Menüicons kommen aus einem eigenen illustrierten Atlas. Weltmodelle,
  Waffenwerte und Kartenvisuals werden dadurch nicht ersetzt. Langwaffe,
  Pistole, Sanitätsgerät, gelbes Hand-Mining-Tool und Datenträger bleiben erkennbar.
- Heimat-Tankservice zeigt keine Handelskäufe oder Verkäufe. Vorhandene
  Handelsfunktionen bleiben am tatsächlichen Handelsposten verfügbar.

## Gemeinsame Charakterkarte — 10.11.2026
- Truppausrüstung und Charakterdetails an Basis und Einsatzort verwenden dieselbe
  PersonnelInventoryPanel-Projektion: Porträt, Name, Hauptrolle, Nebenrolle,
  tatsächliche Eignungsbadges/Status, Figur, Ausrüstung und Rucksack. Hauptrolle
  liest role_name, Nebenrolle secondary_specialty; keine zusätzliche Rollenwahrheit.
- Ausrüstungsfelder liegen links der Figur. Dünne Linien ordnen Rüstung dem Torso
  und Primär/Sekundär den seitlichen Positionen zu. Keine Fläche verdeckt die Figur.
  Rechts liegt bei ausreichender Breite der echte Rucksack mit Itemicons, sonst
  darunter. Dieselben Inventarcommands und Zugriffsregeln bleiben maßgeblich.
- Automatisch ruhen ist ein einzeiliger kompakter Schalter direkt links am Text.
  Herkunftsübersichtsbox entfällt, genaue Ableitungen bleiben im einklappbaren Baum.
  Unveränderte Projektionen erhalten Controls, aufgeklappte Äste und Modellvorschau.
- Blueprintkarten zeigen tatsächliche Herstellkosten aus dem SupplyOwner und
  vorhandene Waffenwerte bzw. Werkzeug-/Rüstungsklasse. Keine eigene UI-Balance.
- Smart Mobile klappt Auftragsdetails über den Titel auf/zu. Auswahl und Aufklappen
  sind UI-Zustand; Freischaltung, Annahme, Kartenbefehl und Belohnung bleiben beim Owner.
