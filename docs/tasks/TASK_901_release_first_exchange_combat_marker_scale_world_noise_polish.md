# TASK_901 - Release First Exchange Combat Marker Scale And World Noise Polish

## Ziel / Problem
TASK_900 hat den echten Spielerblick nach TASK_898/TASK_899 bewertet: CONTACT FIRE ist sichtbar, aber Target-Halo/Fire-Marker lesen noch zu scheibenhaft, und Grid-/World-Noise konkurriert weiter mit der Kampfspur.

## Sinnhaftigkeit / Ursache
Der naechste Fortschritt entsteht nicht durch mehr Combat- oder HUD-Text, sondern durch ruhigere visuelle Hierarchie im Weltbild. Der belegte erste Feuerwechsel soll wie eine kurze Kampfspur wirken, nicht wie ein Debug-Markerpaket.

## Umfang
- Bestehenden TASK_898-Focal-Elegance-Pfad erweitern, nicht ersetzen.
- Target-Halo und Target-Focus kleiner und weniger deckend rendern.
- Source-to-target-Lane schmal halten, aber als Beziehung klarer als reine Scheibe lesen lassen.
- Grid-/World-Line-Noise fuer den aktiven First-Exchange-Polish weiter dimmen.
- Runtime- und Render-Snapshots mit TASK_901-Style-ID und effektiven Werten erweitern.
- HTML-Zwischenbericht, Status, Roadmap und Contract aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Movement-Commands oder Contact-Wahrheit.
- Keine neue UI-/HUD-Gameplay-Wahrheit.
- Kein neuer echter Fenster-Capture in diesem Task.
- Keine Shortcut-, Export- oder Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_900_release_first_exchange_combat_focal_elegance_visual_findings.md`
- `docs/tasks/TASK_898_release_first_exchange_combat_focal_elegance_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Akzeptanzkriterien
- `TerrainMap3DView.get_render_snapshot()` meldet einen aktiven TASK_901-Style, wenn TASK_898 aktiv ist und der neue Payload-Schalter gesetzt ist.
- Der effektive Target-Halo ist kleiner und transparenter als TASK_898.
- Der effektive Target-Focus ist kleiner als TASK_898 und laesst die Welt weniger zu.
- Grid-/World-Line-Dimming ist staerker als TASK_898/895, ohne Map-Geometrie oder Gameplay-State zu veraendern.
- `ReleaseFirstExchangeCombatMarkerScaleWorldNoisePolish.build_snapshot()` prueft die Werte read-only.
- Der Mission-Controller setzt den neuen Primary3D-Payload-Schalter nur als Fortsetzung der bestehenden TASK_898-Kette.

## Betroffene Dateien
- `docs/tasks/TASK_901_release_first_exchange_combat_marker_scale_world_noise_polish.md`
- `scripts/mission/release_first_exchange_combat_marker_scale_world_noise_polish.gd`
- `scripts/tests/task_901_release_first_exchange_combat_marker_scale_world_noise_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_901_release_first_exchange_combat_marker_scale_world_noise_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_900_release_first_exchange_combat_focal_elegance_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_898_release_first_exchange_combat_focal_elegance_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_901 ist noch kein neuer echter Fensterbeweis. Der naechste Slice muss nach frischem Export/Capture pruefen, ob der kleinere Halo und das ruhigere Raster im Spielerblick wirklich besser wirken.

## Naechster Schritt
TASK_902 - Release First Exchange Combat Marker Scale Real Window Recapture.
