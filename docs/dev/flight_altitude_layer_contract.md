# Flight Altitude Layer Contract

## Zweck
`mission_air` ist ein Anzeige- und Missionsstatus-Layer fuer Dropship-/Flieger-Visuals. Er ist bewusst getrennt von Terrain-`height_level`.

Die am 12.11. gewünschte Luftunterstützung ist eine Erweiterung des bestehenden
gemeinsamen Flug-/Rotten-/Kampfowners; sie ist hiermit noch nicht implementiert.
Der Layer selbst bleibt Darstellung. Details und Pakete stehen in
`space_combat_contract.md` und `../tasks/SPACE_GROUND_AIR_SUPPORT_2026_11_12.md`.

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
- Bei `unexplored_blackout` werden LZ-/Approach-Surface-Marker nur gezeichnet,
  wenn das betroffene Tile aktuell sichtbar ist. Bereits erkundet allein reicht
  nicht; ein eigenes Flugobjekt erteilt keine Terrain-/Markerfreigabe.
- Bei `known_terrain` bleibt selbst gesetzte eigene LZ-/Approach-Planungsabsicht
  auch ohne aktuelle Bodensicht sichtbar. Das Terrain ist in diesem Modus
  vollstaendig bekannt. Dieser bereits spaeter etablierte Erststartpfad aus
  `mission_command_feedback_contract.md` (Insertion/First Order, TASK_539)
  muss vor dem ersten Absetzen ohne Bodenobserver bedienbar bleiben.
  Fremde und neutrale Marker brauchen weiterhin aktuelle Tilesicht. Bei
  mehreren Craft-Eintraegen wird deren eigener `team_id` ausgewertet, nicht
  der Besitzer des gesamten Anzeigepayloads. `off` behaelt sichtbare Marker.
- Enemy-/Air-Contacts folgen der bestehenden Contact-/FoW-Regel und erscheinen nur bei sichtbarem Target, sichtbarer Position oder erlaubtem Last-Known-Kontakt.
- Air-Visuals duerfen unbekanntes Terrain nicht freilegen.

## Multiplayer
- Multiplayer-Snapshots transportieren Air-/Dropship-State read-only: `visible`, `state`, `position`, `target_position`, `lz_position`, `team_id`, `air_layer`, `flight_altitude_clearance`.
- Clients wenden diese Daten als Anzeige an und simulieren keinen eigenen Flugstatus.
- Snapshot-Normalisierung setzt `terrain_height_independent = true` und `reveals_unknown_terrain = false`.

## Editor
- Der Editor speichert keine automatische LZ und keinen Flugpfad als Scenario-Wahrheit.
- Authoring-relevant bleiben Map-/Scenario-Marker, Startbereiche und Patrol-/Enemy-Daten. Eine echte Air-Route oder LZ-Regelaenderung braucht einen eigenen Task.
