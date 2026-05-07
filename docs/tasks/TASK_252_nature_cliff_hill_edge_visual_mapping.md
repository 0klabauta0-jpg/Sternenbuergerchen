# TASK_252 - Nature Cliff Hill Edge Visual Mapping

## Ziel
Die Nature-Kit-Cliff- und Step-Assets sollen als verbesserte 2.5D-Visuals fuer Huegelkanten, Klippen, Hanglinien und Rand-/Eckfaelle geprueft und gemappt werden.

Die Regel bleibt unveraendert: `edge_type = cliff` ist harte Klippe, `edge_type = slope` ist begehbarer Hang, `edge_type = none` ist kein sichtbarer Hoehenrand. Nur die Darstellung wird verbessert.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_185 - Hill Visuals and Edge Lines Patch
- TASK_246 - Visual Scale Alignment Asset Pass
- TASK_251 - Nature Kit Classic Source Inventory and Subset Import

## Kontext
Das Nature Kit enthaelt `cliffBrown`, `cliffGrey`, `corner`, `cornerInner`, `half`, `block`, `steps`, `entrance`, `top` und Wasserfallteile. Fuer Sternenbuergerchen sind besonders braune/sandige und graue/rockige Kanten interessant. Entscheidend ist, dass die Visuals die bestehenden Hill-Regeln lesen lassen, statt neue Sonderlogik einzufuehren.

## Umfang
1. Mapping-Strategie:
   - Brown-Cliffs fuer Sand/Dirt/Desert-Huegel pruefen.
   - Grey-Cliffs fuer Rock/Station/asteroidischen Boden pruefen.
   - Steps/Entrance nur fuer `edge_type = slope` oder bewusst authorierte Rampen.
   - Block/Half/Corner-Teile fuer Innen-/Aussenkanten testen.
2. Datenanbindung:
   - `data/terrain_3d_asset_mapping.json` um Nature-Kit-Varianten erweitern oder separaten Nature-Mapping-Katalog einhaengen.
   - Surface- oder Theme-Auswahl dokumentieren, ohne Gameplay-Surface umzuschreiben.
   - Fehlende Mapping-Faelle als sichtbare Diagnose zaehlen.
3. Visuelle Regeln:
   - Hoehere Kachel bestimmt Kante, Richtung und Kantenart.
   - Klippe sitzt am Tile-Rand und verdeckt Top-Surface nicht falsch.
   - Slope/Steps muss als begehbar lesbar sein.
   - Plateau-Innenbereiche bleiben frei von falschen Kanten.
4. Editor-/Mission-Konsistenz:
   - Editor-Preview und Mission-2.5D nutzen dieselbe Mapping-Entscheidung.
   - Legacy-2D darf keine abweichende Gameplay-Regel zeigen.
5. Testfixture:
   - Kleine Karte mit Sand-Huegel, Rock-Huegel, Cliff, Slope, Inner-Corner, Outer-Corner, Mauer auf Huegel.
   - Snapshot-Zaehler fuer Nature-Kit-Cliffs, Slope-Steps und Missing-Mappings.

## Nicht-Ziele
- Keine neuen Pathfinding-, LOS- oder Cover-Regeln.
- Keine Fluss-/Wasserfall-Mechanik.
- Kein Austausch aller bisherigen Space-Kit-Terrain-Assets.
- Kein finaler Art-Direction-Pass fuer jede Map.

## Akzeptanzkriterien
- [x] Nature-Kit-Cliff-Assets koennen fuer `cliff` und `slope` projektlokal geladen werden.
- [x] Brown/Grey-Varianten sind dokumentiert und thematisch schaltbar oder bewusst festgelegt.
- [x] Inner-/Outer-Corner- und gerade Kantenfaelle sind testbar.
- [x] Slope-/Step-Visuals werden nicht fuer harte Klippen genutzt.
- [x] Huegel, Klippen, Sand/Rock und Mauer-auf-Huegel bleiben nach TASK_182 bis TASK_185 regelkonform.
- [x] Ein Verifier prueft Mapping, Resource-Ladung, Edge-Zaehler und Missing-Mapping-Diagnose.

## Umsetzung
- `terrain_3d_asset_mapping.json` mappt die aktiven Height-Edge-Keys `cliff_straight`, `cliff_corner` und `slope` auf das projektlokale Nature-Kit-Classic-Subset. Brown ist fuer V1 die aktive Hoehenkanten-Theme; Grey bleibt als dokumentierte, ladbare Kandidatenfamilie fuer Rock-/Asteroid-Folgearbeit erhalten.
- `TerrainMap3DView` zaehlt Nature-Kit-Cliffs, Slope-Steps, Theme-Verteilung und konkrete Height-Edge-Visual-Eintraege im Render-Snapshot. Diese Diagnose bleibt reine Darstellung und veraendert keine Pathfinding-, LOS- oder Cover-Regel.
- `task_252_nature_cliff_hill_edge_visual_mapping.gd` prueft Mapping, Resource-Ladung, Runtime-Edge-Zaehler, Step-vs-Cliff-Rollen, Plateau-Innenbereich, Missing-Mappings und die bestehende TASK_182-Bewegungssemantik.
- `docs/manual_checks/nature_cliff_hill_edge_visual_checklist.md` beschreibt den noch offenen manuellen 2.5D-Sichtcheck fuer Pivot, Rotation, Zoom/Pitch und taktische Lesbarkeit.

## Erwartete Dateien
- `data/terrain_3d_asset_mapping.json`
- `data/nature_kit_asset_catalog.json`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_252_nature_cliff_hill_edge_visual_mapping.gd`
- `docs/manual_checks/nature_cliff_hill_edge_visual_checklist.md`
- `docs/tasks/TASK_252_nature_cliff_hill_edge_visual_mapping.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_252_nature_cliff_hill_edge_visual_mapping.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd`
- [ ] Manueller 2.5D-Sichtcheck mit Rotation, Zoom und Pitch.
- [x] `git diff --check`

## Risiken
- Cliff-Modelle koennen andere Pivot-/Achsenannahmen haben als die bisherigen Space-Kit-Modelle.
- Wenn Corner-Varianten falsch gewaehlt werden, sieht die Karte huebscher, aber taktisch unklarer aus.
- Theme-Auswahl darf keine zweite Terrain-Wahrheit neben `surface_type` und `edge_type` werden.

## Naechster Schritt
TASK_253 kann Ground-/Surface-Visuals und Editor-Palette fuer Nature-Kit-Bodenvarianten vorbereiten.
