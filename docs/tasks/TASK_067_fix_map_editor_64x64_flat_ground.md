# TASK_067 – Fix Map-Editor 64x64 Flat Ground

- Phase: 14 – Map-Editor-Workflow und Politur
- Status: offen
- Abhaengigkeiten: TASK_066 (Corridor-Wall Typen, Typ-Texturen und Auto-Cliff)

## Ziel
Der Map-Editor soll nicht mehr an der fruehen 8x8-Testkarte haengen, sondern groessere Karten robust laden und neue Karten mit sinnvoller Default-Groesse anlegen koennen.

## Anforderungen
1. Fehlende oder uninitialisierte Karten sollen auf ein 64x64-Grid mit sinnvollem Default-Zoom zurueckfallen.
2. `New` soll nicht mehr starr eine 8x8-Karte anlegen, sondern einen kleinen Dialog fuer Breite und Hoehe oeffnen.
3. Der Dialog fuer neue Karten soll mit 32x32 als Default starten.
4. Neue Tiles sollen mit einem klaren Default-Typ wie `ground_flat` erzeugt werden, damit Katalog-/Palette-Erkennung funktioniert.

## Akzeptanzkriterien
- Der Editor laedt fehlende Karten robust als grosse Flat-Ground-Karte.
- Neue Karten koennen mit frei waehlbarer Groesse erzeugt werden.
- Frisch erzeugte Tiles haben einen konsistenten Default-Typ.

## Nicht in diesem Task
- frei definierbare Preset-Vorlagen fuer neue Karten
- komplexe Template-Bibliotheken
- Gameplay-Wirkung groesserer Karten ausserhalb des bestehenden Terrain-Workflows
