# Explizite Hex-Rampen: Daten-/Uebergangsintegration

Isolierter task/native-glut-maps-20261110, bewusst auf e55206832 plus
paralleler View-/Kompositionsarbeit. Keine Commits durch Teilagent.

## Implementiert
- Versionierte Mapkennung terrain_height_rules=explicit_hex_ramps_v1 aktiviert
  Tile.explicit_hex_ramps; alte Dateien behalten ihre bisherigen Regeln.
- Rampenrichtung -1/0..5 und bool/regional_grade bleiben in internen Tilekopien.
  MapSave erhaelt die Mapkennung und ramp_direction. Kein zweiterOwner.
- TerrainTileData.allows_step/endpoint_height/stand_height bilden gemeinsame
  Regeln. Achse beidseitig, Ende H/H+1, logisch H+0.5, Flanken gesperrt.
- Pathfinder prueft denselben Vertrag auch bei gleichem height_level und
  berechnet Hoehenkosten aus der logischen Standhoehe. HPA-Komponenten,
  Portale und Pfadkosten verwenden bereits diesen Pathfinder.
- Registry bietet reine get_stand_height_at/get_stand_height_at_world Getter.
  Der bestehende Map-/Editorowner muss nach Rampen-Aenderungen wie bisher
  notify_tile_data_changed([grid]) aufrufen. Kein neuer Registry-Mutator.
- SimRoot prueft bei expliziten Rampen LocalAvoidance-Korrektursegmente ueber
  die vorhandene LocalAvoidanceResolver._is_spacing_transition_walkable-
  Partition und damit jede gekreuzte Pathfinderkante. Dies schliesst auch
  den Deadlock-Desire-Fallback ein. Alte Karten behalten ihren bisherigen Guard.

## Kleine lokale Pruefung
Godot4.6.2, headless, private APPDATA unter output/native_glut_maps.
Check-only0; gezielter kleiner Contract-Verifier41/0, exit0, keine
Script-/Enginefehler oder Warnungen. Nur wenige Zellen und drei gespeicherte
JSON-Fixtures; keine grossen Gefechts-/Leistungs-/Matrix- oder Multiplayer-
Tests, wie vom Nutzer gewuenscht. Ein enger Revisionssetter-Prototyp wurde
vor Uebergabe entfernt, um die Registry als Lookup-Schicht zu erhalten.
Das finale41/0 nutzt die vorhandene Owneraenderung+notify-Schnittstelle.

Geprueft: alle6Rampenachsen und beidseitige Enden, Seiten, Plateauklippe,
H8-Rejection, Blocker, Altkarten, interne Kopie, echter Astar, HPA-Komponenten,
SimRoot-Korrekturguard, Navrevision, MapSave/Reload. Keine nativen Pixel-
oder breiten Laufzeit-/FPS-Behauptungen aus diesem Fixture.

## Konkrete noch offene Anschluesse
- View/Profil/Geometriecache und neue A/B/C-Komposition sind Root/anderer Agent.
- CombatVisibilityCache._height_at_world castet get_height_at_world nach int;
  LOS source/target tile.height_level und FoW-Tilesnapshot lesen noch Ganzzahlen.
  Die floatStandhoehen-API ist vorhanden; Sichtanschluss bleibt getrennt von
  dieser engen Daten-/Bewegungsarbeit, kein eigenstaendiger Zielsystemumbau.
- Editor benutzt mehrere manuelle Snapshot-/Undo-Feldlisten, insbesondere
  map_editor.gd um5051/5115/5122 sowie building_layout_authoring.FIELDS.
  Diese muessen vor produktivem Rampen-Authoring Richtung/Regel konservieren;
  to_dict-basierte Kopien sind in diesem Teil bereits korrekt.
- Vollstaendige native Bewegung, dynamische Hindernisse, alte Savevarianten,
  alle generierten Karten und neue Blick-/Zielregeln bleiben spaeter zu pruefen.
