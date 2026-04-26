# TASK_132 - Kenney Isometric Asset Palette Expansion

## Ziel
Der Map-Editor soll mehr Assets aus `res://Assets/kenney_space-kit/Isometric/` nutzbar machen, ohne die Palette unuebersichtlich zu fluten oder Gameplay-Semantik in reine Deko-Assets zu mischen.

## Status: IMPLEMENTIERT

## Voraussetzung
- `TASK_082 - Gemeinsamer Terrain-Renderer fuer Editor und Mission`
- `TASK_115 - Gemeinsames Markersystem fuer Editor und Taktikkarte`
- Aktueller Editor-Branch mit Wall-Richtungskorrektur, entfernten Flank-Anchors und 50er-Slot-Limit

## Kontext
- Der aktuelle `terrain_tile_catalog.json` enthaelt nur einen kleinen Satz: Boden, Waende, Cliffs, Rampen und Felsen.
- Im Kenney-Isometric-Ordner liegen deutlich mehr Assets, unter anderem Barrels, Crater, Desk-/Computer-Props, Gates, Hangars, Machines, Pipes, Platforms, Rails, Monorail, Rockets, Satellites, Structures, Turrets und Vehicles.
- Nicht jedes Sprite sollte sofort Gameplay-Werte bekommen. Viele Assets sind zunaechst reine Editor-/Visual-Objekte.

## Umfang
0. Asset-Audit vor der Auswahl:
   - Dateinamen im Kenney-Isometric-Ordner nach Familien und Richtungssuffixen gruppieren.
   - Familien mit vollstaendigen Richtungssaetzen bevorzugen (`_NE`, `_NW`, `_SE`, `_SW`).
   - Ergebnis als kleine Audit-Summary im Verifier ausgeben, damit die Auswahl nachvollziehbar bleibt.
1. Asset-Auswahl kuratieren:
   - Erste sinnvolle V1-Gruppen: `deko`, `technik`, `gebaeude`, `plattformen`, `pipes`, `rails`, `crater`, `fahrzeuge`.
   - Pro Gruppe eine kleine, verwendbare Auswahl statt kompletter Masseneintrag.
   - Alle Assets mit vorhandenen Richtungsvarianten konsistent benennen (`*_ne`, `*_nw`, `*_se`, `*_sw`).
2. `terrain_tile_catalog.json` erweitern:
   - neue `palette_groups` fuer die ausgewaehlten Gruppen.
   - neue `tile_types` mit `texture_path`, lesbarem `display_name` und defensiven Defaults.
   - Deko-Assets standardmaessig nicht walkable, aber nicht automatisch LOS-blockend, ausser es ist klar ein grosses Objekt.
3. Renderer-/Editor-Kompatibilitaet pruefen:
   - Assets mit `texture_path` werden als `object_type_id` ueber dem bestehenden Boden gerendert.
   - `TerrainMapRenderer.resolve_tile_texture()` bleibt fuer den Bodentile zustaendig; `resolve_object_texture()` liefert das Objekt-Overlay.
   - Keine neuen Sonder-Match-Zweige fuer jedes Asset, solange die Katalog-Textur reicht.
   - Nur falls grosse Objekte falsch sitzen: kleiner, allgemeiner Offset-/Anchor-Vertrag im Katalog statt harter Einzel-Fixes.
4. Gameplay-Werte konservativ setzen:
   - `walkable`, `blocks_los`, `cover_value`, `object_height`, `surface_type` pro Kategorie bewusst waehlen.
   - Keine neuen Combat- oder Navigation-Regeln in diesem Task.
5. Editor-Usability:
   - Palette bleibt gruppiert und scanbar.
   - Keine sichtbaren Legacy-Controls zurueckbringen.
   - Einfache Vorschau im bestehenden Tile-Button reicht fuer V1.
6. Tests:
   - Katalog laedt alle neuen Texture-Pfade.
   - Editor-Palette enthaelt die neuen Gruppen.
   - Renderer kann mindestens je Gruppe ein Beispiel-Asset auf eine Testmap rendern.

## Nicht-Ziele
- Kein automatisches Import-/Generierungssystem fuer alle Kenney-Dateien.
- Keine 3D- oder Materialarbeit.
- Keine neuen Gameplay-Systeme fuer Gebaeude, Tuerlogik, Monorail, Fahrzeuge oder Turrets.
- Keine Massenaenderung vorhandener Karten.
- Kein Re-Save grosser JSON-Maps als Nebeneffekt.

## Architekturregeln
- Der Katalog bleibt Datenquelle fuer Editor-Auswahl und Renderer-Texturen.
- UI bleibt Editor-Werkzeug; Gameplay-Wahrheit entsteht nicht aus UI-Callbacks.
- Runtime-Systeme wie `SimulationRoot`, Combat und Navigation werden nur ueber bestehende Tile-Datenfelder beeinflusst.
- Keine SceneTree-Vollscans im Runtime-Pfad.

## Akzeptanzkriterien
- [x] Mindestens 30 neue nutzbare Asset-Tile-Typen aus dem Kenney-Isometric-Ordner sind im Editor verfuegbar.
- [x] Mindestens 5 neue Palette-Gruppen sind sichtbar und sinnvoll benannt.
- [x] Der Verifier gruppiert vorhandene Kenney-Assets nach Familie/Richtung und markiert die kuratierte Auswahl.
- [x] Alle neuen `texture_path`-Eintraege zeigen auf existierende Dateien.
- [x] Pro neuer Gruppe rendert mindestens ein Beispiel-Asset im gemeinsamen TerrainRenderer als Objekt ueber sichtbarem Boden.
- [x] Objekt-Layer-Assets ersetzen nicht mehr die Bodentextur und speichern/laden ueber `object_type_id`.
- [x] Bestehende Wall-/Marker-/Editor-Verifier bleiben gruen.
- [x] Keine bestehende Map-Datei wird nur durch Formatierung oder Re-Save veraendert.

## Erwartetes Ergebnis
Der Editor wird deutlich brauchbarer fuer Map-Blockout und visuelles Dressing: mehr Objekte, Technik, Plattformen und Umgebungsteile koennen direkt platziert werden, ohne den Boden visuell zu ersetzen, waehrend die Runtime weiterhin die bekannten Tile-Datenfelder fuer Walkability, LOS, Cover und Hoehe auswertet.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_132_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_115_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/wall_direction_mapping_verifier.gd`

## Dateien
- `data/terrain_tile_catalog.json`
- `scripts/editor/map_editor.gd`
- `scripts/terrain/terrain_map_data.gd`
- `scripts/terrain/terrain_map_renderer.gd`
- `scripts/terrain/terrain_tile_catalog.gd`
- `scripts/terrain/terrain_tile_data.gd`
- `scripts/tests/task_132_verifier.gd`

## Risiken
- Der Asset-Ordner ist gross; ein kompletter Blindimport wuerde die Palette schlechter statt besser machen.
- Grosse Kenney-Sprites koennen trotz gemeinsamer Diamond-Positionierung visuell andere Anchors brauchen.
- Zu aggressive Defaults fuer `blocks_los` oder `walkable` koennen Navigation/LOS unbeabsichtigt veraendern.
