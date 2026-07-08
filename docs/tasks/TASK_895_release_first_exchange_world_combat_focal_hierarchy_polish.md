# TASK_895 - Release First Exchange World Combat Focal Hierarchy Polish

## Ziel / Problem
TASK_894 hat den echten TASK_893-Fensterblick als Spielerbefund bewertet. CONTACT FIRE ist in #17/#18/#19 sichtbar, aber Quelle -> Schussrichtung -> Ziel -> Treffer konkurriert im Weltbild noch zu stark mit Raster, Tiles und dichtem Umfeld.

## Sinnhaftigkeit / Ursache
Der Fehler ist nicht mehr Combat-Wahrheit, sondern visuelle Hierarchie. Mehr Status-Text wuerde die Lesbarkeit nicht wirklich verbessern. Der aktive erste Feuerwechsel braucht einen eigenen Weltkampf-Fokus, der Source-to-target-Spur, Ziel-Halo und Impact-Bezug staerker macht und Nebenlinien/Raster im aktiven Moment leiser stellt.

## Umfang
- Eng auf TASK_892 und TASK_894 aufbauen.
- Einen eigenen TASK_895-Primary3D-Style fuer den bestaetigten CONTACT-FIRE-Moment setzen.
- Source-to-target-Lane, Ziel-Halo und Source-Glow im Render-Snapshot messbar machen.
- Raster-/World-Noise- und World-Line-Dimmung als read-only Visual-Metadaten melden.
- `get_release_first_exchange_world_combat_focal_hierarchy_polish_snapshot()` als Headless-Pruefpunkt bereitstellen.
- Doku, Roadmap, Status und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Contact-, Movement-, Command-, UI- oder Multiplayer-Wahrheit.
- Kein neuer echter Fenster-Capture in diesem Task.
- Kein weiterer Text-Stapel im HUD.
- Kein Map-Editor-/Asset-Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_894_release_first_exchange_fire_direction_impact_visual_findings.md`
- `docs/tasks/TASK_892_release_first_exchange_fire_direction_impact_clarity_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeWorldCombatFocalHierarchyPolish.build_snapshot()` meldet Schema `sternenbuergerchen.release_first_exchange_world_combat_focal_hierarchy_polish.v1` und `task_id = TASK_895`.
- Der Snapshot verlangt TASK_894-Status `ready_for_world_combat_focal_polish` oder einen bestaetigten TASK_892-Pfad.
- `TerrainMap3DView.get_render_snapshot()` meldet `release_first_exchange_world_combat_focal_hierarchy_active = true` und Style-ID `task_895_release_first_exchange_world_combat_focal_hierarchy_v1`.
- Die erste Fire-VFX-Entry meldet sichtbare Focal-Lane, Source-Glow und Target-Halo mit Werten groesser als TASK_892.
- Raster-/World-Noise-Dimmung und World-Line-Dimmung sind als Visual-Policy messbar.
- Read-only-Grenzen bleiben explizit: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_895_release_first_exchange_world_combat_focal_hierarchy_polish.md`
- `scripts/mission/release_first_exchange_world_combat_focal_hierarchy_polish.gd`
- `scripts/tests/task_895_release_first_exchange_world_combat_focal_hierarchy_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_895_release_first_exchange_world_combat_focal_hierarchy_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_894_release_first_exchange_fire_direction_impact_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_892_release_first_exchange_fire_direction_impact_clarity_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_895 ist ein Headless-/Runtime-Visual-Polish. Der naechste Slice muss einen echten Fenster-Recapture nachziehen, bevor wir behaupten, dass der Weltkampf-Fokus im Spielerblick wirklich angenehm genug ist.

## Naechster Schritt
TASK_896 - Release First Exchange World Combat Focal Real Window Recapture.
