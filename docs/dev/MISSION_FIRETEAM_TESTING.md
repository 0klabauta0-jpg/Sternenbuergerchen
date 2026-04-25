# Mission Fireteam Dev-Test

## Direkter Einstieg
Zum schnellen Testen ohne Homebase und FOB kann die Szene direkt gestartet werden:

`res://scenes/tests/mission_fireteam_dev_test.tscn`

Die Szene erbt vom bestehenden Mission-Sandbox-Aufbau und startet mit aktivierten Fireteams auf der Mission Map.

## Area Orders
Auf der Mission Map koennen Gebietsmarker direkt gesetzt werden:

- `SHIFT+RMB`: Verteidigungsgebiet fuer das ausgewaehlte Fireteam.
- `ALT+RMB`: Angriffs-/Kontaktgebiet fuer das ausgewaehlte Fireteam.
- `GO`: fuehrt das Fireteam zum naechsten wartenden Wegpunkt oder Area-Ziel.

Defensive Gebiete werden gruen, offensive Gebiete rot und neutrale Move-Linien blau dargestellt. `#17 SELECTED FIRETEAM` zeigt den aktuellen Area-Befehl, Gebietsgroesse, Approach-/Sicherungsrichtung und Kontaktlage.

## 64x64-Testkarte
Fuer laengere Bewegungs- und Blocker-Tests liegt eine datengetriebene Testkarte bereit:

`res://maps/area_orders_64x64_isometric.json`

Die Karte nutzt zusaetzliche Isometric-City- und Landscape-Tiles aus dem gemeinsamen Terrain-Katalog und enthaelt Stadtflaechen, Wege, Wasser-/Cover-Blocker, Spawns, Objective- und Patrol-Daten.

## Werte live testen
In der Mission Map eine Unit-Karte in `#17 SELECTED FIRETEAM` oeffnen.
Im Charakterblatt steht unten `DEV-WERTE`.

Dort koennen waehrend der Entwicklung Kernwerte wie Treffsicherheit, Tempo, Fuehrung, Zaehigkeit, Erkennung und Disziplin per Slider veraendert werden.
Die Werte gelten fuer die laufende Unit und werden nicht als Kampagnen-Persistenz gespeichert.

## Wichtige Unit-Popups
Auf der Map sollen nur kritische Events direkt ueber den NPCs erscheinen, z.B.:

- `FEUERSTOPP GEBROCHEN!`
- `EIGENBESCHUSS!`
- `DOWN`
- `BLEEDOUT`

Routine-Infos wie Trefferzahlen, Medic-Bewegung oder Such-/Cover-Hinweise gehoeren in Panels und Events, nicht dauerhaft ueber die Figuren.
