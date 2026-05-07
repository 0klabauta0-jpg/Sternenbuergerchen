# TASK_180 - Mission Drop Light Fixed HUD Layout

## Ziel
Das Mission-HUD wird nach `d_mission.svg` als festes Full-HD-HUD ueberarbeitet.

Wichtig: Aus der Mission-Vorlage wird nur das UI/HUD uebernommen. Karte, 2.5D-View, Terrain-Rendering, Mission-Simulation, Commander-Commands und Combat bleiben unangetastet.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_177 - Drop Light Fixed UI Layout Contract
- TASK_178 - FOB Drop Light Fixed FullHD Layout
- TASK_179 - Homebase Drop Light Fixed FullHD Layout

## Referenz
- `C:\Users\bjoer\Documents\Codex\2026-05-05\sternenbuergerchen-figma-setup-status-layout-arbeitsvorlage\penpot_sternenbuergerchen_layout\drop_light\d_mission.svg`

## Harte Grenze
Dieser Task darf nur Mission-UI beruehren:
- `TacticalUI`
- Command Matrix
- Selected Fireteam Panel
- Mission Control Panel
- Topbar/Nav/HUD-Panels
- HUD-Buttons und Status-Badges

Dieser Task darf nicht beruehren:
- `TerrainMap3DView`
- Terrain-Daten
- Mission-Simulation
- `SimulationRoot`
- Combat-Entscheidungen
- Pathfinding
- LZ-/Dropship-State als Gameplay-Wahrheit

## Umfang
1. Fester Full-HD-HUD-Rahmen:
   - Ziel-Viewport `1920 x 1080`.
   - UI-Panels haben feste Positionen und Groessen.
   - Karte/2.5D-View bleibt dahinter der Primaerinhalt.
   - Panels muessen nach dem Layout-Pass tatsaechlich an den Contract-Positionen liegen.
   - Nicht ausreichend: nur `custom_minimum_size`, Stretch-Ratio oder `drop_light_rect`-Metadaten setzen.
2. `#16 COMMAND MATRIX`:
   - feste linke untere Position.
   - Command-Buttons quadratisch.
   - Move/Hold/Flank/Take/Target/Clear bleiben bestehende Commands.
   - Stance-/GO-Buttons nur ueber bestehende Controllerpfade.
   - Sichtbare Command-Buttons duerfen keine neuen Command-Typen erfinden und keine toten Fake-Actions als aktiv anzeigen.
3. `#17 SELECTED FIRETEAM`:
   - festes breites unteres Panel.
   - bestehende Fireteam-Karten und Statuszeilen bleiben read-only Spiegelung.
4. `#18 MISSION CONTROL`:
   - feste rechte untere Position.
   - LZ/Drop/Approach Controls nach Vorlage.
   - Richtungstasten klein und fest.
   - LZ/Drop/Approach bleiben reine UI-Einstiege in bestehende Controllerpfade.
5. Topbar/Mission Identity:
   - optisch an `drop_light` angleichen.
   - keine zusaetzliche Missionslogik.

## Layout- und Verifier-Pflicht
- Der TASK_180-Verifier muss nach mindestens einem `process_frame` echte `global_position` und `size` von `#16`, `#17`, `#18`, Topbar/Mission Identity und optionalem Bottom-Dock gegen `DropLightLayoutContract.get_mission_hud_layout()` pruefen.
- Der Verifier darf nicht nur Mindestgroessen, Labels oder Metadaten akzeptieren.
- Der HUD-Layer darf die 2.5D-Karteninteraktion nicht unabsichtlich blockieren; feste Panels duerfen nur ihre eigene Flaeche belegen.
- Reines Styling oder Panel-Rebuild darf keine `SimulationRoot`-Commands, Effects oder Snapshot-Mutationen erzeugen.
- Vorhandene Buttons muessen ueber bestehende Mission-/Tactical-Controllerpfade laufen; nicht implementierte Vorlage-Buttons bleiben ausgeblendet oder eindeutig disabled.

## Nicht-Ziele
- Keine neue Mission-Map.
- Keine neue 2.5D-Darstellung.
- Keine neuen Command-Typen.
- Keine neue Dropship-Mechanik.
- Keine responsive HUD-Logik.

## Akzeptanzkriterien
- [x] Mission-HUD rendert in festen Full-HD-Panelpositionen.
- [x] Der Verifier prueft echte `global_position`/`size` der HUD-Panels gegen den Contract, nicht nur Mindestgroessen oder Metadaten.
- [x] `#16`, `#17` und `#18` bleiben als bekannte Blocklabels erhalten.
- [x] Command-/Action-Buttons im HUD sind quadratisch, wo die Vorlage Commands zeigt.
- [x] Keine sichtbaren aktiven Fake-Actions werden eingefuehrt.
- [x] Die 2.5D-Playability-Verifier bleiben gruen.
- [x] Keine SimulationRoot-Commands oder Effects werden durch reines Styling erzeugt.
- [x] Keine Terrain-/Map-Dateien werden fuer diesen Task geaendert.

## Erwartete Dateien
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_ui_skin.gd`
- `scripts/ui/tactical_ui_theme.gd`
- optional `scripts/tests/task_180_mission_drop_light_fixed_hud_layout_verifier.gd`
- `docs/tasks/TASK_180_mission_drop_light_fixed_hud_layout.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_180_mission_drop_light_fixed_hud_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_164_ui_theme_component_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [ ] Manueller Godot-Sichtcheck Mission-HUD in Full HD.
- [x] `git diff --check`

## Risiken
- HUD-Politur kann versehentlich Input-Pfade verdecken; deshalb muessen Command-, LZ- und Dropship-Buttons weiterhin ueber bestehende Controllerpfade laufen.
- Feste Panels koennen auf kleineren Viewports absichtlich nicht optimal sein; Ziel ist Full HD, nicht responsive UI.

## Naechster Schritt
Nach TASK_180 kann der manuelle Full-HD-Sichtcheck oder TASK_181 als Audit-/Politur-Slice folgen.
