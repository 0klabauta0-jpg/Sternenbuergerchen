# TASK_195 - UI Input and Cursor Asset Availability Pass

## Ziel
UI-Pack, Space-UI-Expansion, Input-Prompts und Cursor-Pack sollen im Projekt gezielt verfuegbar gemacht werden, ohne vorhandene Projektkopien zu duplizieren.

Der Task soll klaeren und absichern, welche Icons, Button-Frames, Prompts und Cursor-States fuer Drop-Light-UI, Mission-Commands, Editor-Tools und Tooltips verwendet werden koennen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_164 - UI Theme and Component Library
- TASK_177 - Drop Light Fixed UI Layout Contract
- TASK_181 - Drop Light Fixed Window Audit Patch
- TASK_193 - Asset Source Inventory and Availability Matrix

## Quellen
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_ui-pack-space-expansion`
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_ui-pack`
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_input-prompts_1.4.1\Keyboard & Mouse`
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_cursor-pixel-pack`

## Bestehende Projektpfade
- `Assets/kenney_ui-pack-space-expansion`
- `Assets/kenney_ui-pack`
- `Assets/kenney_input-prompts_1.4.1`
- `Assets/kenney_cursor-pixel-pack`

## Umfang
1. Reuse-Audit:
   - Vorhandene Projektkopien pruefen.
   - Fehlende relevante Subsets markieren.
   - Keine Doppelkopien in `Assets/curated`, wenn bestehende Pfade ausreichen.
2. UI-Asset-Katalog:
   - `docs/assets/ui_input_cursor_availability.md`
   - Optional `data/ui_asset_catalog.json`
   - Kategorien: panel frame, button, icon, command prompt, cursor, editor tool, tactical marker.
3. Drop-Light-Verwendung:
   - #16/#17/#18, FOB, Homebase und Mission-HUD koennen Icons/Prompts ueber stabile IDs nutzen.
   - Icons in Buttons bevorzugen, wo vorhandene lucide/Projekticons nicht reichen.
   - Keine sichtbaren Erklaertexte nur wegen fehlender Icons.
4. Input-Prompts:
   - Keyboard & Mouse Prompts fuer LMB/RMB, Shift, Ctrl, Q/E, R/F, G, Space, Esc.
   - Nur als Tooltip/Hint/Manual-Check-Asset, nicht als Gameplay-Eingabelogik.
5. Cursor:
   - Select, Move, Attack/Engage, Defend, Take, Area-Drag, Editor-Brush, Height, Marker, Patrol.
   - Cursor-Asset-Auswahl bleibt Anzeige, nicht Tool-State-Wahrheit.
6. Verifier:
   - Projektpfade existieren.
   - Katalog-IDs zeigen auf `res://Assets/...`.
   - Keine lokalen Quellenpfade in Runtime.
   - Keine Duplikat-Importe fuer bereits vorhandene Packs.

## Nicht-Ziele
- Kein neues HUD-Design.
- Kein kompletter Ersatz der UI-Komponenten.
- Kein Eingabesystem-Rewrite.
- Kein Massencopy lokaler UI-Packs.

## Akzeptanzkriterien
- [x] UI-, Input- und Cursor-Assets sind ueber einen Katalog oder eine Availability-Doku auffindbar.
- [x] Bestehende Projektkopien werden wiederverwendet.
- [x] Command-/Editor-relevante Prompts und Cursor-IDs sind definiert.
- [x] Alle Referenzen nutzen `res://...`-Projektpfade.
- [x] Keine absoluten lokalen Pfade in UI-Code, Tests oder Katalog.
- [x] Ein TASK_195-Verifier prueft Pflicht-IDs und Pfadgueltigkeit.

## Erwartete Dateien
- `docs/assets/ui_input_cursor_availability.md`
- `data/ui_asset_catalog.json`
- `scripts/tests/task_195_ui_input_cursor_asset_availability_verifier.gd`
- `docs/tasks/TASK_195_ui_input_cursor_asset_availability_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_195_ui_input_cursor_asset_availability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_164_ui_theme_component_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_181_drop_light_fixed_window_audit_verifier.gd`
- [ ] Manueller Sichtcheck fuer Tooltips/Cursor nur falls UI-Nutzung eingebaut wurde.
- [x] `git diff --check`

## Umsetzung
- `docs/assets/ui_input_cursor_availability.md` dokumentiert die wiederverwendeten Projektpfade fuer UI-Pack, Space-UI-Expansion, Keyboard-&-Mouse-Prompts und Cursor-Pixel-Pack.
- `data/ui_asset_catalog.json` stellt stabile IDs fuer Panel-/Button-/Icon-/Crosshair-Assets, Command-Prompts und Cursor-/Editor-Tool-Zustaende bereit.
- Es wurde nichts nach `Assets/curated` kopiert; vorhandene Projektkopien bleiben fuehrend.
- Der Katalog ist Visual-only: Prompts sind Tooltip-/Hint-Assets, Cursor-IDs sind Anzeige und keine Eingabelogik oder Tool-State-Wahrheit.
- `scripts/tests/task_195_ui_input_cursor_asset_availability_verifier.gd` prueft Pflicht-IDs, Kategorien, `res://Assets/...`-Pfade, Texture2D-Loadbarkeit, fehlende Curated-Duplikate und lokale-Pfad-Freiheit.

## Risiken
- UI-Assets koennen schnell zu dekorativ werden. Drop-Light bleibt funktional, fest und knapp.
- Kataloge duerfen keine zweite Theme-Wahrheit neben TASK_164 werden.

## Naechster Schritt
Nach TASK_195 kann TASK_197 diese UI-/Input-/Cursor-IDs zentral mit anderen Asset-Kategorien zusammenfuehren.
