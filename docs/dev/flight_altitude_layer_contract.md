# Flight Altitude Layer Contract

## Zweck
`mission_air` ist ein Anzeige- und Missionsstatus-Layer fuer Dropship-/Flieger-Visuals. Er ist bewusst getrennt von Terrain-`height_level`.

## Terrain-Grenze
- Terrain-`height_level` beschreibt die begehbare/LOS-relevante Oberflaeche eines Tiles.
- Air-Visuals werden relativ zur aktuellen Terrainoberflaeche positioniert, aber setzen keine Walkability, Cover, LOS oder Objekt-Hoehe.
- Dropship-/Fliegerbewegung veraendert Gameplay nur ueber autoritative SimulationRoot-Events wie Deploy/Embark, nicht ueber Visual-Hoehe.

## 2.5D-View
- Friendly Dropship-Visuals sitzen auf `mission_air` oberhalb der lokalen Tile-Oberflaeche.
- Die Mindest-Clearance ist groesser als die Hoehenkante, damit kein Z-Fighting mit Huegeln, Waenden oder Surface-Tints entsteht.
- Im Vollbild-Spielpass vom 05.11.2026 wird der vorhandene Flugstatus lesend
  sichtbar: `inbound` gleitet aus dem Reiseflug in der Naehe der tatsaechlichen
  LZ ab; `landed`, `unloading` und `complete` stehen mit dem Ground-Pivot auf
  der Oberflaeche. `outbound`/`departing` steigen mit der echten Entfernung von
  dieser LZ. Der reine Anzeigepfad bestimmt weder Phase noch Landeposition.
  Die Reiseflug-Mindest-Clearance gilt fuer die Luftphase; bekannter
  Bodenkontakt darf sie unterschreiten. Payloads ohne bekannten Status behalten
  ihre bisherige explizite Clearance fuer Kompatibilitaet.
- Schub liest denselben sichtbaren Flugstatus und bleibt an den vorhandenen
  Modell-Owner gebunden. Bodenkontakt, Unsichtbarkeit und Ownerentfernung
  erzeugen keine weiteren Flugeffekte. Eine dekorative Basis-Servicedrohne
  darf ihren lokalen Meshhover zeigen, ohne Runtime- oder Roster-State zu besitzen.
- LZ- und Approach-Marker bleiben Terrain-/Surface-Marker und sind nicht Teil der Air-Hoehe.

## FoW
- Friendly Air kann fuer das eigene Team sichtbar bleiben.
- LZ-/Approach-Surface-Marker werden bei aktivem FoW nur gezeichnet, wenn das betroffene Tile sichtbar ist.
- Enemy-/Air-Contacts folgen der bestehenden Contact-/FoW-Regel und erscheinen nur bei sichtbarem Target, sichtbarer Position oder erlaubtem Last-Known-Kontakt.
- Air-Visuals duerfen unbekanntes Terrain nicht freilegen.

## Multiplayer
- Multiplayer-Snapshots transportieren Air-/Dropship-State read-only: `visible`, `state`, `position`, `target_position`, `lz_position`, `team_id`, `air_layer`, `flight_altitude_clearance`.
- Clients wenden diese Daten als Anzeige an und simulieren keinen eigenen Flugstatus.
- Snapshot-Normalisierung setzt `terrain_height_independent = true` und `reveals_unknown_terrain = false`.

## Editor
- Der Editor speichert keine automatische LZ und keinen Flugpfad als Scenario-Wahrheit.
- Authoring-relevant bleiben Map-/Scenario-Marker, Startbereiche und Patrol-/Enemy-Daten. Eine echte Air-Route oder LZ-Regelaenderung braucht einen eigenen Task.
