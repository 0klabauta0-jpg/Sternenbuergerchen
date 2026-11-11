# Explizite Hex-Rampen: Daten und Uebergaenge

## Ziel / Ursache
Die bestaetigte Hoehenregel ersetzt nur in versionierten Hexkarten die
bisherige automatische H1-Verbindung durch gerichtete Rampenzellen.
UI/Visuals duerfen keine eigene Bewegungsfreigabe speichern.

## Basis / Vertraege
Isolierter task/native-glut-maps-20261110 auf e55206832 plus parallele
Grafikarbeit; keine Mainintegration. PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES,
explicit_hex_ramps_contract.md, hex_grid_v1_contract.md sind massgebend.

## Umfang / Nicht-Ziele
TerrainTileData: ramp_direction, explicit_hex_ramps, gemeinsame
allows_step/endpoint_height/stand_height-API. TerrainMapData: versionierter
Load/Save-Pfad und interner Tilekopiererhalt. TerrainPathfinder: gemeinsame
Pruefung vor gleicher Hoehe, Kosten nach logischer Standhoehe.
TerrainRegistry: reine Standhoehenabfrage. Bestehende Map-/Editorowner
aendern das Tile und verwenden notify_tile_data_changed fuer Revisionen. HPA verwendet bereits can_traverse_step und braucht keine zweite Regel.
Kein Sicht-/Ziel-/Reservierungsumbau, keine Terrainkomposition oder Viewarbeit.

## Akzeptanz
- Plateau H0/H1 direkt blockiert, Rampen H->H+1 beidseitig nur entlang Achse.
- Rampenseite und unpassende Endhoehe blockiert; H8-Rampe ungueltig.
- Altkarten bleiben im bisherigen Verhalten; Save/Reload und interne Kopien
  erhalten Richtung und Regelkennung.
- Richtungswechsel im Registryowner entwertet die bestehenden Navcaches.
- Kleiner Contract-Verifier und check-only, keine grossen Tests auf Nutzerwunsch.

## Dateien / Pruefung / Risiken
terrain_tile_data.gd, terrain_map_data.gd, terrain_pathfinder.gd,
terrain_registry.gd; scripts/tests/explicit_hex_ramp_contract_test.gd.
Offene Sichtkonsumenten casten Hoehen noch nach int; Standhoehen-API als
Schnittstelle anbieten, Integration getrennt mit Root abstimmen.
Tatsaechliche LocalAvoidance-Korrektur prueft bislang nur Zelle statt Kante;
kleiner Anschluss muss denselben Pathfinder nutzen, sonst Flankenrisiko.


## Ergebnis dieses Teils
Implementiert; enger Contract41/0 und check-only0 ohne Warnungen.
SimRoot hat zusaetzlich den freigegebenen LocalAvoidance-Kantenguard erhalten,
der die bestehende Segmentpartition/Pathfinderquelle wiederverwendet.
QA docs/qa/explicit_hex_ramp_runtime_20261111. Keine grossen Tests,
kein Commit/Push durch Teilagent. Native/Editor-/Sichtanschluesse siehe QA.

Root-Nachsteuerung: User fordert seitlich zusammenhaengende Rampenbaender
und Ecken. Seitliches EndniveauH+.5 erlaubt nur passende Rampen, Plateau
weitergesperrt. Root final49/0 und kleine native Formkontrolle dokumentiert
unter docs/qa/hex_ramp_bands_20261111. Editor gesondert inArbeit.
