# TASK_295 - Map Editor Paint Toolbar Tools Polish

## Ziel
Der Map Editor soll eine klarere, paint-artige Werkzeugleiste bekommen: Brush, Select, Eraser, Height, Patrol/Marker und spaeter Szenario-Tools muessen eindeutig erkennbar, gegenseitig sauber exklusiv und schnell bedienbar sein.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_229 - Map Editor Usability Authoring Pass
- TASK_292 - Editor Hill Cliff Grid Depth Repair
- bestehende `scenes/editor/map_editor.tscn`
- bestehende `scripts/editor/map_editor.gd`

## Kontext
Brush und Select sind aktuell funktional, aber die aktive Werkzeuglage ist nicht intuitiv genug. Der User moechte eine normale Toolbar mit vertrauten Symbolen/Verhalten, wie man es aus Paint-/Editor-Tools kennt. Ein Radiergummi fehlt noch.

## Umfang
1. Toolbar-Layout:
   - Linke oder obere kompakte Toolgruppe fuer Authoring-Tools.
   - Icon-first, kurze Tooltips, aktive Tool-Hervorhebung.
   - Keine langen Buttontexte, wenn ein Symbol reicht.
2. Tools:
   - Select: Tile/Objekt auswaehlen, Property-Panel aktualisieren.
   - Brush: Surface/Objekt platzieren.
   - Eraser: Objekt-Layer loeschen, optional Surface auf Boden zuruecksetzen nur mit klarer Option.
   - Height: Raise/Lower/Set H1/H2 plus Edge-Type.
   - Patrol/Marker/Szenario: getrennte Gruppe, damit Terrain-Authoring nicht mit Mission-Authoring verschwimmt.
3. Tool-Exklusivitaet:
   - Ein aktives Hauptwerkzeug zur Zeit.
   - Statusanzeige zeigt exakt das aktive Werkzeug.
   - Shortcuts optional, aber dokumentiert.
4. Safety:
   - Bodenpinsel darf Objekte nicht loeschen.
   - Eraser loescht nur die Ebene, die der User erwartet.
   - Undo fuer alle Tool-Aenderungen.
5. Verifier:
   - Tool-Toggle-Exklusivitaet.
   - Select aktualisiert Selection.
   - Brush und Eraser veraendern die richtigen Felder.
   - Status-Snapshot stimmt.

## Nicht-Ziele
- Kein kompletter Editor-Skin.
- Keine finale Asset-Browser-Neuentwicklung.
- Keine Multiplayer-/Runtime-Aenderungen.

## Akzeptanzkriterien
- [x] Aktives Tool ist auf den ersten Blick sichtbar.
- [x] Brush, Select, Height und Eraser sind eindeutig getrennt.
- [x] Eraser loescht nicht versehentlich Hoehe/Szenario/Gameplay-Felder.
- [x] Terrain-Tools und Szenario-Tools sind gruppiert.
- [x] Verifier prueft Tool-Exklusivitaet und Feld-Sicherheit.
- [ ] Manueller Editor-Klickcheck bestaetigt Bedienbarkeit.

## Erwartete Dateien
- `scenes/editor/map_editor.tscn`
- `scripts/editor/map_editor.gd`
- optional `scripts/ui/editor_tool_button.gd`
- optional `data/ui_asset_catalog.json`
- `scripts/tests/task_295_map_editor_paint_toolbar_tools_polish.gd`
- `docs/manual_checks/map_editor_toolbar_tools_checklist.md`
- `docs/tasks/TASK_295_map_editor_paint_toolbar_tools_polish.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_295_map_editor_paint_toolbar_tools_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`
- [ ] Manueller Editor-Klickcheck.
- [ ] `git diff --check`

## Risiken
- Zu viele Buttons auf einmal machen die Leiste unruhig.
- Eraser-Semantik muss klar sein, sonst gehen Map-Daten verloren.
- Toolbar darf nicht mit dem rechten Inspector um dieselbe Wahrheit konkurrieren.

## Naechster Schritt
TASK_296 sortiert die Tile-Palette und fuegt Space-Station-Kit-Assets kuratiert hinzu.
