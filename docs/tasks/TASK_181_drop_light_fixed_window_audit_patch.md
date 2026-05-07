# TASK_181 - Drop Light Fixed Window Audit Patch

## Ziel
Alle `drop_light`-Screens werden nach TASK_178 bis TASK_180 noch einmal gezielt darauf geprueft und gepatcht, dass die Hauptfenster echte feste Full-HD-Fenster sind.

Der Patch-Task ist ein Layout-Audit, kein neuer UI-Entwurf. Er soll variable oder responsive Hauptfenster finden, sichtbar machen und beseitigen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_177 - Drop Light Fixed UI Layout Contract
- TASK_178 - FOB Drop Light Fixed FullHD Layout
- TASK_179 - Homebase Drop Light Fixed FullHD Layout
- TASK_180 - Mission Drop Light Fixed HUD Layout

## Kontext
Die `drop_light`-Linie will feste Fensterpositionen und feste Fenstergroessen. Es reicht nicht, Hauptfenstern nur eine Mindestgroesse, Stretch-Ratio oder ein `drop_light_rect`-Meta zu geben, wenn sie am Ende weiter durch alte `HBoxContainer`-/`VBoxContainer`-Logik variabel fliessen.

Innenbereiche duerfen weiterhin Container, Scrollbereiche und Listen nutzen. Die aeusseren Hauptfenster muessen aber nach dem Layout-Pass exakt am Contract sitzen.

## Umfang
1. Gemeinsamer Audit-Verifier:
   - Neuer Verifier fuer FOB, Homebase und Mission-HUD.
   - Instanziert die relevanten Test-Screens in `1920 x 1080`.
   - Wartet mindestens ein `process_frame` nach `_ready()` und Layout-Pass.
   - Prueft echte `global_position` und `size` der Hauptfenster gegen `DropLightLayoutContract`.
   - Prueft nicht nur `custom_minimum_size`, Stretch-Ratio oder Metadaten.
2. Fixed-Window-Korrekturen:
   - Variable/responsive Hauptfenster auf feste Rechtecke patchen.
   - Alte dynamische Primaercontainer duerfen nur noch Innenlayout machen, nicht die Hauptfensterposition bestimmen.
   - Falls noetig: feste Overlay-/Host-Layer fuer die Hauptfenster einfuehren, ohne fachliche Screen-Logik umzuziehen.
3. Erlaubte Flexibilitaet:
   - ScrollContainer innerhalb fester Fenster.
   - Dynamische Listen innerhalb fester Fenster.
   - Auto-Layout fuer Zeilen, Karten und Inhalte innerhalb eines festen Hauptfensters.
4. Verbotene Flexibilitaet:
   - Hauptfenster, deren Position oder Groesse von Viewport-Stretch, `SIZE_EXPAND_FILL`, Stretch-Ratio oder Nachbarfenstern abhaengt.
   - Hauptfenster, die nur per `custom_minimum_size` groesser werden, aber keine feste `position`/`size` haben.
   - Responsive Umordnung der Hauptfenster fuer kleinere Viewports.
5. UI-Wahrheit bleibt getrennt:
   - Der Audit darf keine neuen Gameplay-State-Pfade einfuehren.
   - Keine neuen Commands, keine neuen Transport-/Loadout-/Mission-Wahrheiten.
   - Fixes duerfen bestehende Controller-/Callback-Pfade nur unveraendert weiterverwenden.

## Zu pruefende Hauptfenster
- FOB:
  - `topbar`
  - `fireteams`
  - `loadout`
  - `flightdeck`
  - `boarding_status`
  - `actions`
- Homebase:
  - `topbar`
  - `mission_brief`
  - `roster`
  - `transfer_team`
  - `flightdeck`
  - `character_sheet`
- Mission-HUD:
  - `mission_identity`
  - `top_nav`
  - `fireteam_mini`
  - `command_matrix`
  - `selected_fireteam`
  - `mission_control`

## Nicht-Ziele
- Kein neues visuelles Design.
- Keine neue responsive Variante.
- Keine Gameplay-Aenderungen.
- Keine Terrain-/Map-/SimulationRoot-Aenderungen.
- Keine Umbenennung bestehender fachlicher Nodes, wenn stabile Pfade fuer Verifier oder Runtime existieren.

## Akzeptanzkriterien
- [x] Ein TASK_181-Verifier prueft echte `global_position` und `size` aller Drop-Light-Hauptfenster gegen den Contract.
- [x] Der Verifier faellt, wenn ein Hauptfenster nur Mindestgroesse/Meta setzt, aber nicht am festen Rect sitzt.
- [x] FOB, Homebase und Mission-HUD bestehen den festen Fenster-Audit.
- [x] Innenlisten und Scrollbereiche bleiben innerhalb der festen Fenster benutzbar.
- [x] Keine sichtbaren aktiven Fake-Actions werden durch den Patch eingefuehrt.
- [x] Keine Gameplay-State-Mutation wird in UI-Callbacks als neue Wahrheit eingefuehrt.
- [x] Bestehende Regressionen fuer Recovery, Dropship, Loadout und 2.5D-Playability bleiben gruen.

## Erwartete Dateien
- `scripts/tests/task_181_drop_light_fixed_window_audit_verifier.gd`
- `scripts/meta/drop_light_layout_contract.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- optional kleine Helper in bestehenden UI-Skripten, falls fuer feste Fenster noetig
- `docs/tasks/TASK_181_drop_light_fixed_window_audit_patch.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_181_drop_light_fixed_window_audit_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_178_fob_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_180_mission_drop_light_fixed_hud_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_114_meta_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [ ] Manueller Full-HD-Sichtcheck fuer FOB, Homebase und Mission-HUD.
- [x] `git diff --check`

## Risiken
- Ein zu harter Audit kann sinnvolle Innenlayouts faelschlich blockieren. Deshalb gilt der feste Rect-Zwang nur fuer Hauptfenster, nicht fuer Listen oder Karten innerhalb dieser Fenster.
- Absolute Positionierung darf keine bestehenden Controllerpfade brechen. Wenn dafuer Host-Layer noetig sind, muessen sie klein und explizit bleiben.
- Mission-HUD-Fixes duerfen keine Input-Flaeche ueber die 2.5D-Map legen, ausser dort sitzt laut Contract ein HUD-Panel.

## Naechster Schritt
Nach TASK_181 sind die `drop_light`-Screens als feste Full-HD-Arbeitsflaechen abgesichert. Danach koennen der manuelle Sichtcheck, visuelle Politur oder Gameplay-Folge-Slices separat entschieden werden.
