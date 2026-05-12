# TASK_334 - Drop Light Layout Profiles Compact Resolution

## Ziel
Der feste Drop-Light-FullHD-Vertrag bleibt erhalten, bekommt aber ein Profil-System fuer kleinere oder skalierte Viewports. Ziel ist bessere Lesbarkeit und Bedienbarkeit bei 1280x720 und UI-Skalierung, ohne die bestehende 1920x1080-Abnahme zu zerlegen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_258 - Fixed Window Clipping Scrollbar Playability Audit
- TASK_312 - Dropship Command Matrix LZ Go Layout
- TASK_329 - Manual Playtest Stabilization GDD Godot Fix Pass

## Kontext
`DropLightLayoutContract` codiert aktuell 1920x1080 als Ziel. Homebase, FOB und Mission-HUD wenden daraus feste Fensterrechtecke an. Das ist stabil fuer FullHD, aber empfindlich bei kleineren Fenstern, Skalierung und Ultrawide. Dieser Task fuehrt Profile ein, statt verstreute Pixelrechtecke einzeln zu patchen.

## Umfang
1. Profil-Vertrag:
   - `full_hd` als bestehende Referenz unveraendert erhalten.
   - Mindestens ein kompaktes Profil fuer 1280x720 oder eine skalierte Variante ergaenzen.
2. Anwendung:
   - Homebase, FOB und Mission-HUD nutzen weiterhin den Contract statt eigener Layoutwahrheiten.
   - Fenster duerfen intern scrollen, wenn das Profil das erfordert.
3. Tests:
   - FullHD-Vertrag bleibt pixelstabil.
   - Kompaktprofil prueft erreichbare Buttons, keine harten Clipping-Fehler und sinnvolle Mindestgroessen.
4. Report:
   - Offene manuelle Sichtfragen fuer finale optische Balance klar nennen.

## Nicht-Ziele
- Kein neues UI-Designsystem.
- Kein Art- oder Theme-Redesign.
- Keine Umstellung aller Screens auf vollresponsive Container.
- Kein Entfernen des FullHD-Vertrags.

## Akzeptanzkriterien
- [x] `full_hd` liefert dieselben Layoutrechtecke wie vor dem Task oder dokumentierte minimale Abweichungen.
- [x] Ein kompaktes Profil verhindert offensichtliches Button-/Text-Clipping bei 1280x720.
- [x] Homebase, FOB und Mission-HUD nutzen denselben Profilvertrag.
- [x] Playability-Layout-Gates bleiben gruen.
- [x] Manuelle Sichtcheck-Restpunkte sind dokumentiert.

## Erwartete Dateien
- `scripts/meta/drop_light_layout_contract.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/fob_screen.gd`
- betroffener Mission-HUD-Controller
- `scripts/tests/task_334_drop_light_layout_profiles_compact_resolution.gd`
- `docs/reports/drop_light_layout_profiles_compact_resolution.md`
- `docs/tasks/TASK_334_drop_light_layout_profiles_compact_resolution.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_334_drop_light_layout_profiles_compact_resolution.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_312_dropship_command_matrix_lz_go_layout.gd`
- [x] `git diff --check`

## Risiken
- Layoutprofile koennen schnell zu einer zweiten UI-Wahrheit werden. Deshalb muss der Contract zentral bleiben und FullHD weiter die Referenz sein.

## Naechster Schritt
Wenn das Profil-System traegt, koennen spaetere Tasks einzelne Screens auf bessere Container-Layouts migrieren.
