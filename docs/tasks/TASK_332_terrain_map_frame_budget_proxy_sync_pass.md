# TASK_332 - Terrain Map Frame Budget Proxy Sync Pass

## Ziel
Die Mission-/Terrain-Ansicht soll weniger schwere Arbeit pro Frame erledigen. Der Task optimiert Proxy-Sync, Order-Visual-Signaturen und Debug-/Label-Updates, ohne sichtbares Verhalten oder taktische Wahrheit zu aendern.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_222 - Performance Regression Gate and Manual Profile Checklist
- TASK_323 - Manual Playtest Mission Command Visuals Fire Sector Dropships

## Kontext
`TerrainMap3DView._process()` synchronisiert Viewport, Unit-Proxies und dynamische Order-Visuals regelmaessig. Fuer aktuelle Szenen ist das wahrscheinlich tragbar, aber groessere Karten, mehr Einheiten oder mehr Overlays koennen diese Pfade kippen lassen. Godots Performance-Leitlinien bevorzugen messbare Hotspot-Reduktion, Dirty-Updates und Instancing/Budgetierung statt pauschaler Full-Refreshes.

## Umfang
1. Messung:
   - Lokale Profilpunkte fuer `_sync_unit_proxies`, dynamische Order-Visuals und relevante Label-/Counter-Updates erfassen.
   - Ist-Werte im Report dokumentieren.
2. Proxy-Sync:
   - Bewegung/Rotation, Sichtbarkeit und schwere Diagnose-/Label-Felder trennen.
   - Schwere Felder nur bei Dirty-Zustand oder sichtbarem Bedarf aktualisieren.
3. Order-Visual-Signatur:
   - Teure Vollserialisierung wie `var_to_str(order_payload)` durch kompakte, stabile Revision-/ID-/Count-Signaturen ersetzen, sofern vorhanden.
   - Semantik der Visuals unveraendert lassen.
4. Redraw-Fenster:
   - Bestehende SubViewport-Redraw-Logik erhalten, aber unnoetige Redraw-Anfragen reduzieren.

## Nicht-Ziele
- Kein Umbau des Terrain-Renderers.
- Keine Aenderung an Fog-of-War-, LOS- oder Cover-Regeln.
- Kein neuer Art-Pass.
- Kein Ersatz durch MultiMesh, ausser eine sehr kleine bestehende Instancing-Stelle ist offensichtlich und risikofrei.

## Akzeptanzkriterien
- [x] Ein Report nennt Vorher/Nachher-Hotspots und die veraenderten Update-Grenzen.
- [x] Proxy-Bewegung bleibt fluessig, aber schwere Counter-/Label-Syncs laufen nicht unnoetig jedes Frame.
- [x] Order-Visuals aktualisieren korrekt bei Auswahl, Plan, Dropship, Fire-Sector und Clear.
- [x] Performance-Gate meldet keine Regression.
- [x] Mission-Command-Visual-Smoke bleibt gruen.

## Erwartete Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- optional betroffene Visual-/Profiler-Helfer
- `scripts/tests/task_332_terrain_map_frame_budget_proxy_sync_pass.gd`
- `docs/reports/terrain_map_frame_budget_proxy_sync_pass.md`
- `docs/tasks/TASK_332_terrain_map_frame_budget_proxy_sync_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_332_terrain_map_frame_budget_proxy_sync_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_fire_sector_overlay.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_313_dropship_arrival_visibility_feedback_smoke.gd`
- [x] `git diff --check`

## Risiken
- Signatur-Aenderungen koennen stale Visuals erzeugen. Deshalb muessen Auswahl-, Plan- und Dropship-Wechsel explizit im Test abgedeckt werden.

## Naechster Schritt
Falls danach weiter Frame-Zeit auffaellt, kann ein separater Renderer-/Instancing-Task entschieden werden.
