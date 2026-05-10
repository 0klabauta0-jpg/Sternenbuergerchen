# TASK_297 - Map Editor Inspector Collapsible Panels

## Ziel
Der rechte Editor-Bereich soll klarer zwischen Tile Properties, Map Settings, Authoring Status und Mission Scenario unterscheiden. Tile Properties sollen immer erreichbar bleiben, waehrend Map-/Szenario-Bereiche einklappbar oder an den rechten Rand minimierbar sind.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_295 - Map Editor Paint Toolbar Tools Polish
- TASK_296 - Map Editor Palette Taxonomy Space Station Assets
- bestehende rechte `PropertyPanel`-Struktur im Map Editor

## Kontext
Rechts stehen derzeit Tile Properties, Authoring Status, Map Settings, Marker und Mission Scenario relativ dicht zusammen. Das ist fuer komplexere Planung unuebersichtlich. Tile Properties sind beim Zeichnen wichtig und sollten nicht von Map-/Szenario-Einstellungen verdraengt werden.

## Umfang
1. Inspector-Struktur:
   - Tile Properties als oberster, immer sichtbarer Bereich.
   - Authoring Status kompakt darunter.
   - Map Settings einklappbar.
   - Markers einklappbar.
   - Mission Scenario einklappbar.
2. Bedienung:
   - Collapse-State bleibt waehrend der Editor-Sitzung erhalten.
   - Optional persistieren in Editor-Settings, aber nicht in Map-Datei.
   - Keine horizontal abgeschnittenen Controls.
3. Layout:
   - Feste Fenster-/Editorbreite beruecksichtigen.
   - Scrollbereich fuer lange Inhalte.
   - Tile Properties duerfen nicht aus dem sichtbaren Bereich rutschen.
4. Datenwahrheit:
   - Tile Properties schreiben nur Tile-Daten.
   - Map Settings schreiben nur Map-Metadaten.
   - Scenario Settings schreiben nur Szenario-Dateien/Marker/Objective-Daten.
5. Verifier:
   - Panel-Nodes vorhanden.
   - Collapse toggles aendern Sichtbarkeit ohne Datenverlust.
   - Property-Editing funktioniert nach Ein-/Ausklappen.

## Nicht-Ziele
- Kein kompletter Szenario-Editor.
- Kein neues Docking-System fuer mehrere Fenster.
- Keine Gameplay-Truth im UI.

## Akzeptanzkriterien
- [x] Tile Properties sind nach Editor-Start sofort sichtbar.
- [x] Map Settings, Markers und Mission Scenario sind einzeln einklappbar.
- [ ] Lange rechte Inhalte nutzen Scrollen statt abgeschnittene Controls.
- [x] Collapse/Expand verliert keine geaenderten Werte.
- [x] Verifier prueft Struktur, Sichtbarkeit und Property-Editing.

## Erwartete Dateien
- `scenes/editor/map_editor.tscn`
- `scripts/editor/map_editor.gd`
- optional `scripts/ui/collapsible_section.gd`
- `scripts/tests/task_297_map_editor_inspector_collapsible_panels.gd`
- `docs/manual_checks/map_editor_inspector_panels_checklist.md`
- `docs/tasks/TASK_297_map_editor_inspector_collapsible_panels.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_297_map_editor_inspector_collapsible_panels.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`
- [ ] Manueller fixed-window Screenshot bei 1920x1080.
- [ ] `git diff --check`

## Risiken
- Collapsible UI kann Status verstecken, den man beim Authoring braucht.
- Persistenz darf nicht in Map-/Scenario-Dateien auslaufen.
- Scrollbereiche duerfen Mausrad-Zoom/Pan im Editor nicht unbrauchbar machen.

## Naechster Schritt
TASK_298 fuehrt den Gesamtpass als Playability-/Visual-Smoke zusammen.
