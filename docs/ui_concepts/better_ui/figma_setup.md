# Sternenbuergerchen Figma Setup

Status: Layout-Arbeitsvorlage, nicht in Godot integriert.

## Ziel

Figma soll als Maus-basiertes Layout-Werkzeug dienen, damit Homebase, FOB und Mission schneller sichtbar sortiert werden koennen. Die Datei ist nur Konzeptarbeit. Gameplay-State, Commands und Loadout-Wahrheit bleiben spaeter in den bestehenden Godot-/Meta-/Simulation-Pfaden.

## Figma Frames

Lege diese Top-Level-Frames an:

- `Homebase / Roster + Fleet Assignment` - 1440 x 900
- `FOB / Fireteam + Loadout + Flightdeck` - 1440 x 900
- `Mission / Tactical HUD` - 1440 x 900

Nutze fuer alle Frames:

- feste Framegroesse
- keine Auto-Resize-Panels
- 8 px Basisabstand
- 6 px Panelradius maximal
- dunkle Arbeitsflaeche wie im HTML-Mockup

## Assets Importieren

Diese Projektassets zuerst in Figma importieren:

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

Baue diese Komponenten zuerst als Figma Components:

- `Panel / Fixed`: fester Rahmen mit Header, Badge rechts, Body.
- `NPC Card / Compact`: 30 px Avatar, Name, Rolle/Status, kleines Badge.
- `NPC Stack Card`: 116-128 px breit, Avatar, Kurzname, Badge, Progress-Bar.
- `Ship Slot Card`: Schiffname, Pilot-Slot, Passenger-/Cargo-Dropzone, Progress-Bar.
- `Status Badge`: gruen, amber, rot, neutral.
- `Command Button`: quadratisch fuer Mission `#16`.
- `Windrose Button`: kleine Richtungstaste fuer Mission `#18`.
- `Pad Field / 3x5`: Gruppe aus 15 `platform_large_NW.png`-Instanzen.

## Pad Field Regeln

Das Pad Field ist kein Kartenersatz, sondern eine visuelle Boarding-Buehne.

Homebase:

- 3 Kacheln Breite, 5 Kacheln Laenge.
- Kanten muessen sichtbare Linien bilden.
- Schiffe starten oben links.
- Zwischen Schiffen bleibt eine freie Kachel.
- NPC-Karten liegen knapp ueber dem Schiff und duerfen nur leicht ueberlappen.

FOB `#14`:

- gleiches 3x5-Padprinzip wie Homebase.
- Flightdeck sitzt rechts.
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

## Handoff Nach Godot

Wenn ein Figma-Stand passt:

1. Frame als Referenzbild exportieren.
2. Komponentenliste mit Namen und Groessen notieren.
3. Nur bestaetigte Teile in Godot uebernehmen.
4. Keine Gameplay-Logik aus Figma ableiten.
5. Erst HTML-Konzept aktualisieren, dann Godot-Slice schneiden.

## Offene Entscheidungen

- Exakte Groesse der NPC-Karten mit Portrait.
- Finales Medbay-/Respawn-Visual.
- Wie viele Schiffe Homebase maximal gleichzeitig zeigt.
- Ob Frachter im Flightdeck anders visualisiert wird oder separat bleibt.
