# Sternenbuergerchen Penpot Setup

Status: Layout-Arbeitsvorlage, nicht in Godot integriert.

## Ziel

Penpot soll als freies, maus-basiertes Layout-Werkzeug dienen, damit Homebase, FOB und Mission ohne Godot-Umbau sichtbar sortiert werden koennen. Die Datei ist Konzeptarbeit. Gameplay-State, Commands, Loadouts und Boarding-Wahrheit bleiben spaeter in den bestehenden Godot-/Meta-/Simulation-Pfaden.

## Penpot-Datei

Lege in Penpot eine Datei an:

`Sternenbuergerchen UI Layout`

Empfohlene Seiten:

- `00 Assets`
- `01 Homebase`
- `02 FOB`
- `03 Mission`
- `90 Handoff`

## Boards

Lege diese Boards an:

- `Homebase / Roster + Fleet Assignment` - 1440 x 900
- `FOB / Fireteam + Loadout + Flightdeck` - 1440 x 900
- `Mission / Tactical HUD` - 1440 x 900

Nutze fuer alle Boards:

- feste Boardgroesse
- keine Auto-Resize-Panels
- 8 px Basisabstand
- 6 px Panelradius maximal
- dunkle Arbeitsflaeche wie im HTML-Mockup
- UI-Gruppen sperren, sobald sie nur noch Hintergrund oder Referenz sind

## Assets Importieren

Importiere zuerst diese Projektassets auf die Seite `00 Assets`:

- `Assets/kenney_space-kit/Isometric/platform_large_NW.png`
- `Assets/kenney_space-kit/Isometric/craft_speederA_NE.png`
- `Assets/kenney_space-kit/Isometric/craft_speederB_NE.png`
- `Assets/kenney_space-kit/Isometric/craft_speederD_NE.png`
- `Assets/kenney_space-kit/Isometric/craft_cargoA_NE.png`
- `Assets/used/npc/blaster_kit/previews/blaster-a.png`
- `Assets/used/npc/blaster_kit/previews/blaster-b.png`

Optional spaeter:

- Portraitbilder fuer NPC-Karten
- weitere Schiffe nur, wenn sie wirklich als UI-Auswahl gebraucht werden
- Medbay-/Respawn-Assets als eigener Vorschlag, nicht im Flightdeck vermischen

## Komponenten

Baue diese Elemente zuerst als wiederverwendbare Penpot-Komponenten:

- `Panel / Fixed`: fester Rahmen mit Header, Badge rechts, Body.
- `NPC Card / Compact`: 30 px Avatar, Name, Rolle/Status, kleines Badge.
- `NPC Stack Card`: 116-128 px breit, Avatar, Kurzname, Badge, Progress-Bar.
- `Ship Slot Card`: Schiffname, Pilot-Slot, Passenger-/Cargo-Dropzone, Progress-Bar.
- `Status Badge`: gruen, amber, rot, neutral.
- `Command Button`: quadratisch fuer Mission `#16`.
- `Windrose Button`: kleine Richtungstaste fuer Mission `#18`.
- `Pad Field / 3x5`: Gruppe aus 15 `platform_large_NW.png`-Instanzen.
- `Flightdeck Group`: Pad Field, Schiffe, NPC-Stapel und Ship Slot Cards als zusammenhaengende Gruppe.

## Pad Field Regeln

Das Pad Field ist kein Kartenersatz, sondern eine visuelle Boarding-Buehne.

Homebase:

- 3 Kacheln Breite, 5 Kacheln Laenge.
- Kanten muessen sichtbare Linien bilden.
- Schiffe starten oben links.
- Zwischen Schiffen bleibt eine freie Kachel.
- Schiff sitzt jeweils auf der zweiten Kachel seines 3er-Bereichs.
- NPC-Karten liegen knapp ueber dem Schiff und duerfen nur leicht ueberlappen.
- Dropship/Frachter bekommen darunter kompakte Slot Cards fuer Pilot, Passagiere und Boarding-Fortschritt.

FOB `#14`:

- gleiches 3x5-Padprinzip wie Homebase.
- Flightdeck sitzt rechts.
- Schiffe starten oben links und lassen eine Kachel Abstand.
- Keine Medbay in diesem Feld.
- Medbay/Respawn bekommt spaeter eigenes kleines Visual.
- Schiffe und Boarding-Stapel sollen klarer sein als Dekoration.

## Screen-Schwerpunkte

Homebase:

- Roster ist Hauptfokus.
- Fahrzeug-/Schiffauswahl mit Pilotenzuordnung.
- Boarding-Stapel nur fuer ausgehende Schiffe.
- Keine echte Karte.

FOB:

- Fireteams zusammenstellen.
- `#13 LOADOUT` bleibt kompakt mit SMG und Medictool.
- `#14 FLIGHTDECK` zeigt Boarding/Slots.
- Flightdeck rechts, sichtbar mit Assets.

Mission:

- Map-first.
- `#16 COMMAND MATRIX` bekommt quadratische Buttons.
- `GO`, Stance und Befehlsauswahl gehoeren in `#16`.
- `#18 MISSION CONTROL` bekommt kleine Windrose plus LZ/Drop-Buttons.

## Arbeitsweise In Penpot

1. Assets auf `00 Assets` importieren und benennen.
2. Komponenten aus den Assets und UI-Basiselementen bauen.
3. Screen-Boards duplizieren, bevor groessere Layoutvarianten ausprobiert werden.
4. Pad Fields und grobe Hintergrundgruppen sperren, sobald ihre Position passt.
5. Offene Fragen als Penpot-Kommentare oder kleine Notes direkt neben dem Board notieren.
6. Nur bestaetigte Varianten fuer den HTML-Mockup uebernehmen.

## Handoff Nach Godot

Wenn ein Penpot-Stand passt:

1. Board als Referenzbild exportieren.
2. Komponentenliste mit Namen, Groessen und Positionen notieren.
3. Zuerst `separated_screens.html` aktualisieren.
4. Danach nur bestaetigte Teile als Godot-Slice schneiden.
5. Keine Gameplay-Logik aus Penpot ableiten.

## Offene Entscheidungen

- Exakte Groesse der NPC-Karten mit Portrait.
- Finales Medbay-/Respawn-Visual.
- Wie viele Schiffe Homebase maximal gleichzeitig zeigt.
- Ob Frachter im Flightdeck anders visualisiert wird oder separat bleibt.
- Ob Penpot fuer uns besser als Figma ist oder nur als schneller Layout-Test dient.
