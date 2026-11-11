# Gemeinsame Orbitbereiche und Oberflächenanflug

## Verbindliches Ziel

Die Nutzerentscheidung vom 11.11.2026 ersetzt die frühere Vorgabe von drei
Orbitmarkern: Jeder Stern, Planet und Mond hat genau ein Orbitziel und einen
gemeinsam genutzten lokalen Bereich mit 512 × 256 Hexfeldern. Die strategische
Sternkarte bleibt 256 × 256. Eine Ankunft erzeugt keine private Kopie der Karte.

Warpankünfte erfolgen unten. Oben mittig ragt ein riesiger Himmelskörper als
flacher Bogen in die Karte: nominal 256 Felder breit und höchstens vier Felder
tief. Vier bezeichnet die sichtbare Tiefe, nicht den tatsächlichen Radius.
Der restliche Körper liegt außerhalb der Karte. Für die erste Geometrie gelten
Spalten 128 bis 383 und höchstens Reihen 0 bis 3 als sichtbare Körpermaske.

Der geometrische Anflugsaum liegt jeweils in der ersten freien Zelle direkt
unter dieser Maske. So bleibt er erreichbar, wenn die Körpermasse gesperrt ist.
Der breite Anflugraum ermöglicht räumliche Blockaden; drei auswählbare Marker
oder eine UI-Liste gesperrter Marker ersetzen diese Geometrie nicht.

## Wahrheit und Zuständigkeiten

- `SpaceWingState` aus dem Weltraumkampf-Chat besitzt Rottenmitgliedschaft und
  Rottenaufträge. Jedes fliegende Schiff gehört genau einer Rotte an, auch
  Dropship/Cutlass und Einzelschiffe. Die Karte erzeugt keinen zweiten Bestand.
- Der vorhandene `SpaceFlightState` bleibt die Bewegungswahrheit je Schiff und
  erhält Bereichs-ID und Koordinatenbezug. Reise und Kampf verwenden dasselbe
  Objekt. Lokale Koordinaten dürfen nicht strategisch normalisiert werden.
- Die bestehenden Reiseowner besitzen Warp-, Orbit- und Anflugphase.
  `SimulationRoot` koordiniert Bereichswechsel, Belegung, Rotte und Reisephase
  atomar. Kartenansicht und Kartenwechsel setzen keine Schiffe zurück.
- `OrbitApproachLayout` liefert reine Geometrie. Seine Gatezellen sind Kandidaten,
  keine Zugangsfreigabe. Darstellung liest Projektionen und sendet Commands.

Bereichsgrenzen und Belegungsindizes müssen ausdrücklich gebietsbezogen sein.
`StrategicHexGrid` wird nicht global auf 512 vergrößert. Gleiche Zellen in zwei
verschiedenen Orbitbereichen dürfen sich nicht gegenseitig blockieren.

## Übergänge und Gates

Ein angenommener Warp endet mit frei belegbaren vollständigen Schiffsfootprints
im unteren Eintrittsband des Zielbereichs. Der Geometriekandidat verwendet die
unteren 32 Reihen; tatsächliche Positionen und Verteilung bestätigt der Owner.
Ist kein Platz frei, bleibt der Übergang ausdrücklich ausstehend oder schlägt
kontrolliert fehl. Kein Überspringen einer Blockade durch Ersatzspawn am Saum.

Erst nach tatsächlichem lokalen Flug zum Saum darf ein Schiff zu einer passenden
Oberflächenkarte dieses Körpers weiterfliegen. Die Freigabe liest den echten
Flight-/Bereichs-/Reisezustand und prüft vollständigen Footprint, Pilot, Besatzung,
Ziel und bestehende Reisebedingungen. Sie erfolgt vor Treibstoffverbrauch und
wird beim verbindlichen Übergang erneut gegen die erwarteten Revisionen geprüft.
UI-Auswahl, Cursor, Flugziel und interpolierte Darstellung sind kein Saumbeleg.
Sterne ohne Oberflächenziele erhalten dadurch keine erfundene Landemöglichkeit.

Beim Start von der Oberfläche und bei der Rückkehr gelten dieselben Owner und
Rottenregeln. Eine neue lokale Polisa-Abholung muss beim Flugbeginn denselben
kanonischen Rottenanschluss verwenden wie ein vorhandenes Schiff.

## Integration und aktueller Stand

Dieser Vertrag beschreibt das neue Ziel. Die produktive Drei-Marker-Reise bleibt
bis zum vollständigen Anschluss Warp → lokaler Flug → Saum → Oberfläche erhalten.
Alte Marker-IDs, Körperdefinitionen einschließlich Sternorbit und Validatoren
werden beim Umschalten ausdrücklich migriert. Away-Speichern wird dadurch nicht
stillschweigend freigegeben.

Der Layouthelper ist zunächst unverdrahtete Vorbereitung. Die API- und
Dateibesitzabstimmung mit dem Weltraumkampf-Chat geht Änderungen an gemeinsamen
Flight-/Root-/Reisedateien voraus. Siehe `ORBITAL_APPROACH_MAPS_2026_11_11.md` und
`ORBIT_BODYMAP_INTERFACE_AUDIT_2026_11_11.md` unter `docs/tasks/`.
