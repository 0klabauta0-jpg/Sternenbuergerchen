# TASK_294 - Nature Prop Scale Cover Visibility Repair

## Ziel
Nature Cactus, Bush Cover, Tree Blocker, Rock Cover und aehnliche Nature-Props sollen im Editor und in der Mission sichtbar, groessenmaessig plausibel und taktisch lesbar sein.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_251 - Nature Kit Classic Source Inventory and Subset Import
- TASK_254 - Nature Trees Rocks Vegetation Cover Props
- TASK_292 - Editor Hill Cliff Grid Depth Repair
- TASK_293 - Editor Lighting Shadow Readability Pass

## Kontext
Im Editor sind Cactus/Bush-Objekte aktuell so klein oder unauffaellig, dass man sie kaum sieht. Das ist besonders schlecht, wenn diese Props Cover, LOS-Blocker oder Deko mit taktischer Bedeutung sein sollen.

## Umfang
1. Nature-Prop-Katalog auditieren:
   - `Nature Cactus Cover`
   - `Nature Bush Cover`
   - `Nature Tree Blocker`
   - `Nature Rock Cover`
   - `Nature Deco Logs`
2. Scale und Bodenanker kalibrieren:
   - Pro Prop explizite `scale`, `y_offset`, optional `position_offset`.
   - Props muessen auf H=0/H=1/H=2 sauber auf der Tile-Oberseite stehen.
   - Kleine Props bekommen Mindest-Silhouette, ohne mehrere Tiles zu behaupten.
3. Gameplay-Werte gegen Visual pruefen:
   - Cover-Props zeigen Cover plausibel.
   - Blocker sehen wie Blocker aus.
   - Deko bleibt Deko und darf nicht nach harter Deckung aussehen.
4. Grid-/Selection-Interaktion:
   - Grid darf durch hohe/solide Props nicht dominant durchzeichnen.
   - Selection/Hover muss trotzdem das Tile bedienbar machen.
5. Verifier:
   - Resource-Ladung.
   - Snapshot-Groessenbereiche.
   - H=2-Anker.
   - Cover-/LOS-Feld bleibt im Katalog die Gameplay-Wahrheit.

## Nicht-Ziele
- Keine neuen Pflanzenarten ohne kuratierte Asset-Entscheidung.
- Keine Procedural-Foliage.
- Keine neuen Cover-Regeln.

## Akzeptanzkriterien
- [x] Cactus/Bush/Tree/Rock sind im Editor deutlich sichtbar.
- [x] Props stehen auf der korrekten Hoehe und schweben/sinken nicht.
- [x] Cover-/LOS-Werte passen sichtbar zur Prop-Art.
- [x] Grid/Selection bleibt bedienbar, aber nicht visuell dominierend durch Props.
- [x] Verifier deckt Scale, Anchor, Resource-Pfade und Gameplay-Felder ab.

## Erwartete Dateien
- `data/terrain_3d_asset_mapping.json`
- `data/terrain_object_catalog.json`
- `data/nature_kit_asset_catalog.json`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_294_nature_prop_scale_cover_visibility_repair.gd`
- `docs/manual_checks/nature_prop_scale_cover_visibility_checklist.md`
- `docs/tasks/TASK_294_nature_prop_scale_cover_visibility_repair.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_294_nature_prop_scale_cover_visibility_repair.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_254_nature_trees_rocks_vegetation_cover_props.gd`
- [ ] Manueller Editor-Sichtcheck.
- [ ] `git diff --check`

## Risiken
- Zu grosse Pflanzen koennen Tile-Grenzen und taktische Lesbarkeit verdecken.
- Zu kleine Pflanzen verschwinden wieder in Schatten oder Grid-Linien.
- Visual-Scale darf keine heimliche Aenderung von Cover/LOS sein.

## Naechster Schritt
TASK_295 verbessert die eigentliche Editor-Werkzeugleiste, damit Brush/Select/Eraser/Height klarer bedienbar werden.
