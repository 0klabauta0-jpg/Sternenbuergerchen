# TASK_177 - Drop Light Fixed UI Layout Contract

## Ziel
Die `drop_light`-Vorlagen werden als verbindlicher UI-Layout-Vertrag fuer die naechsten Meta-/HUD-Umbauten festgelegt.

Dieser Task ist kein Gameplay-Task. Er definiert die gemeinsame Grundlage fuer feste Full-HD-Screens, feste Fensterbreiten, einheitliche Panel-Komponenten und die Abgrenzung zwischen UI-Darstellung und Gameplay-Wahrheit.

## Status: IMPLEMENTIERT

## Referenzen
- `C:\Users\bjoer\Documents\Codex\2026-05-05\sternenbuergerchen-figma-setup-status-layout-arbeitsvorlage\penpot_sternenbuergerchen_layout\drop_light\a_components.svg`
- `C:\Users\bjoer\Documents\Codex\2026-05-05\sternenbuergerchen-figma-setup-status-layout-arbeitsvorlage\penpot_sternenbuergerchen_layout\drop_light\z_all_frames_light.svg`

## Kontext
Die letzte reine Theme-/Skin-Aenderung ist nicht der fachliche Zielzustand und darf nicht als Layout-Ausgangspunkt behandelt werden. Die naechsten Umbauten sollen von den konkreten `drop_light`-Frames ausgehen und die bestehenden Godot-Screens gezielt auf feste, kontrollierte UI-Fenster uebertragen.

## Umfang
1. Gemeinsame UI-Konstanten fuer `drop_light` definieren:
   - Ziel-Viewport: Full HD `1920 x 1080`.
   - Feste Screen-Frames statt dynamischer Fensterbreiten.
   - Feste Panelpositionen und Panelgroessen pro Screen.
   - 8 px Basisraster.
   - Panelradius maximal 6 px.
   - Buttons in Aktionsleisten quadratisch, wo die Vorlage Commands/Actions zeigt.
2. Komponentenvertrag festlegen:
   - `Panel / Fixed`
   - `NPC Card / Compact`
   - `NPC Stack Card`
   - `Ship Slot Card`
   - `Status Badge`
   - `Command Button`
   - `Pad Field / 3x5`
3. Bestehende Projektassets als erlaubte Runtime-Assets dokumentieren:
   - Kenney Space-Kit Isometric Platforms.
   - Kenney Space-Kit Craft-Texturen fuer Dropship/Shuttle/Frachter.
   - Bereits importierte Blaster-Previews fuer Loadout.
4. Architekturgrenze festschreiben:
   - UI liest und setzt Staging-Commands.
   - Gameplay-State bleibt in Meta-/Mission-Setup, SimulationRoot und bestehenden Runtime-Systemen.
   - Keine neuen Gameplay-Wahrheiten in UI-Skripten.
5. Die vorherige breite Theme-only-Aenderung pruefen:
   - Falls sie dem festen Layout-Umbau widerspricht, im jeweiligen Folgetask gezielt ersetzen.
   - Kein grossflaechiges Revert ohne klare Sichtpruefung.

## Nicht-Ziele
- Keine Umsetzung von FOB/Homebase/Mission in diesem Task.
- Keine neuen Gameplay-Regeln.
- Keine dynamischen Responsive-Layouts.
- Keine Asset-Referenzen auf absolute Benutzerpfade.
- Keine neuen UI-Systeme neben den bestehenden Meta-/HUD-Pfaden, wenn bestehende Komponenten reichen.

## Akzeptanzkriterien
- [x] Ein gemeinsamer `drop_light`-Layoutvertrag ist im Code oder in einer kleinen UI-Konstanten-Datei nachvollziehbar.
- [x] Folgetasks koennen feste Full-HD-Panelgroessen ohne Ratespiel uebernehmen.
- [x] Der Vertrag benennt explizit, dass Mission nur HUD/UI aus `drop_light` uebernimmt.
- [x] Keine Gameplay- oder SimulationRoot-Pfade werden geaendert.
- [x] Verifier prueft mindestens, dass die UI-Basis keine absolute `C:\Users\...`-Assetpfade enthaelt.

## Erwartete Dateien
- `scripts/meta/meta_ui_skin.gd`
- optional `scripts/meta/drop_light_layout_contract.gd`
- optional `scripts/tests/task_177_drop_light_fixed_ui_layout_contract_verifier.gd`
- `docs/tasks/TASK_177_drop_light_fixed_ui_layout_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Risiken
- Wenn nur Farben geaendert werden, aber Fenster nicht fest gesetzt werden, bleibt das eigentliche Layoutproblem bestehen.
- Wenn zu viel auf einmal umgebaut wird, kann der Meta-Layer schwer pruefbar werden.
- Wenn Mission-Map und Mission-HUD vermischt werden, entsteht Architektur-Drift.

## Naechster Schritt
TASK_178 setzt den FOB-Screen nach `c_fob.svg` als erstes konkretes festes Full-HD-Layout um.

## Ergebnis
- `scripts/meta/drop_light_layout_contract.gd` definiert den gemeinsamen Full-HD-Vertrag fuer die `drop_light`-Folgetasks.
- Der Vertrag enthaelt feste Panel-Rechtecke fuer FOB, Homebase und Mission-HUD.
- FOB legt `#14 FLIGHTDECK` breiter als `#13 LOADOUT` an und haelt die unteren Action-Buttons quadratisch.
- Mission ist explizit als HUD-only Scope markiert; `TerrainMap3DView`, `SimulationRoot` und weitere Runtime-Ziele sind als verbotene Mission-Umbauziele dokumentiert.
- `scripts/tests/task_177_drop_light_fixed_ui_layout_contract_verifier.gd` prueft Full-HD, Grid, Komponenten, Assetpfade und die Mission-HUD-Grenze.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_177_drop_light_fixed_ui_layout_contract_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_164_ui_theme_component_verifier.gd`
- [x] `git diff --check`
