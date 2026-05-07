# TASK_255 - Nature Kit Hill Playability Visual Performance Smoke

## Ziel
Die Nature-Kit-Reihe soll in einem zusammenhaengenden Smoke geprueft werden: Import, Projektlokalitaet, Editor-Authoring, Huegel-/Klippenvisuals, Ground-Varianten, Baeume/Felsen/Vegetation, Gameplay-Regeln und Performance.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_247 - Used Asset Project Locality Audit Gate
- TASK_249 - Post Audio Visual Performance Optimization Pass
- TASK_251 - Nature Kit Classic Source Inventory and Subset Import
- TASK_252 - Nature Cliff Hill Edge Visual Mapping
- TASK_253 - Nature Ground Surface Editor Palette Pass
- TASK_254 - Nature Trees Rocks Vegetation Cover Props

## Kontext
Nature-Kit-Assets beruehren Editor, Terrain-Visuals, Gameplay-Daten, Asset-Katalog, Projektlokalitaet und Performance. Der Abschluss-Smoke verhindert, dass ein schoener Huegel in der Mission anders funktioniert als im Editor oder das Performance-Budget sprengt.

## Umfang
1. Import-/Locality-Gate:
   - `--import` fuer Nature-Kit-Subset.
   - `.gltf`/`.bin`-Paare pruefen.
   - TASK_247-Pfadgate ausfuehren.
2. Editor-Fixture:
   - Kleine 32x32-Testkarte mit Sand/Dirt/Rock-Ground, H=0/H=1/H=2, Cliff, Slope, Inner-/Outer-Corner.
   - Baum, Fels, Busch/Cactus und Deko-Prop platzieren.
   - Save/Load pruefen.
3. Mission-Fixture:
   - Mission-2.5D zeigt dieselbe Karte.
   - Friendly/Enemy bewegen sich um Blocker und nutzen Cover.
   - LOS ueber Baum/Fels/Huegel/Klippe bleibt regelkonform.
4. Visual-Readability:
   - Klippe hart lesbar, Slope begehbar lesbar.
   - Brown/Grey/Surface-Varianten nicht verwirrend.
   - Grid, Marker, Selection, Waypoints, FoW und NPCs bleiben sichtbar.
5. Performance:
   - Node-/Draw-/Resource-Budget gegen TASK_249/TASK_222 pruefen.
   - Warnung bei zu vielen individuellen Nature-Props.
   - Vorschlag fuer Instancing/Pooling/Batching dokumentieren, falls noetig.
6. Abschlussbericht:
   - `docs/reports/nature_kit_hill_playability_visual_performance_smoke.md`
   - Offene Art-/Scale-/Editor-Punkte als Folgeaufgaben.

## Nicht-Ziele
- Kein finaler Natur-Biome-Editor.
- Kein grosses Kampagnenkarten-Set.
- Keine automatische Optimierungsarchitektur, solange Budgets gruen bleiben.

## Umsetzung
- `scripts/tests/task_255_nature_kit_hill_playability_visual_performance_smoke.gd` prueft eine 32x32-Nature-Fixture mit H0/H1/H2, Klippen, Slope-Einstieg, Sand/Rock/Road/Ground, Tree/Rock/Bush/Cactus/Deco-Props, Save/Load, Pathfinding, LOS, Cover, 2.5D-Render-Snapshot, taktischen Overlays, FoW und Performance-Budget.
- `docs/reports/nature_kit_hill_playability_visual_performance_smoke.md` dokumentiert Scope, abgedeckte Assets, Budget-Gate und offene manuelle Kunst-/Scale-Punkte.
- `docs/manual_checks/nature_kit_hill_playability_visual_checklist.md` fuehrt den Editor-/Mission-Sichtcheck fuer Fixture, Lesbarkeit, Overlays, Gameplay und Performance.

## Akzeptanzkriterien
- [x] Nature-Kit-Subset importiert ohne fehlende `.bin`-/Resource-Abhaengigkeiten.
- [x] Editor kann eine Nature-Huegelkarte erstellen, speichern und laden.
- [x] Mission-2.5D zeigt Klippen, Slope, Ground und Props regelkonform.
- [x] Pathfinding, LOS und Cover bleiben bei Huegeln und Nature-Props konsistent.
- [x] Grid/Marker/FoW/NPCs bleiben lesbar.
- [x] Performance-Gate meldet keine neue kritische Regression oder dokumentiert konkrete Optimierungen.
- [x] Abschlussbericht und manuelle Checkliste existieren.

## Erwartete Dateien
- `scripts/tests/task_255_nature_kit_hill_playability_visual_performance_smoke.gd`
- `docs/reports/nature_kit_hill_playability_visual_performance_smoke.md`
- `docs/manual_checks/nature_kit_hill_playability_visual_checklist.md`
- optional `maps/test_nature_hill_fixture.json`
- `docs/tasks/TASK_255_nature_kit_hill_playability_visual_performance_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_255_nature_kit_hill_playability_visual_performance_smoke.gd` (183/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_247_used_asset_project_locality_audit_gate.gd` (27/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_249_post_audio_visual_performance_optimization_pass.gd` (39/0)
- [ ] Manueller Editor-/Mission-Sichtcheck.
- [x] `git diff --check`

## Risiken
- Ein End-to-End-Smoke lokalisiert Fehler schlechter als Einzelverifier.
- Headless kann die finale Lesbarkeit der Naturkanten nur teilweise bewerten.
- Viele Nature-Props koennen Performance-Probleme erzeugen, die spaeter Instancing oder strengere Editor-Budgets brauchen.

## Naechster Schritt
Nach TASK_255 kann entschieden werden, ob daraus ein groesserer Biome-/Theme-Pass fuer Wuesten-, Fels- oder Gruenflaechenkarten entsteht.
