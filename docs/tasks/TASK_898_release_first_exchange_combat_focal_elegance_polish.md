# TASK_898 - Release First Exchange Combat Focal Elegance Polish

## Ziel / Problem
TASK_897 hat den echten TASK_896-Fensterblick als Spielerbefund bewertet: CONTACT FIRE ist in #17 Selected Fireteam, #18 Mission Control und #19 Event Log sichtbar, und der Weltkampf-Fokus ist vorhanden. Der Focal-Effekt liest sich aber noch zu technisch, zu grossflaechig und nicht elegant genug als natuerliche Schussbahn.

## Sinnhaftigkeit / Ursache
Der belegte Engpass ist nicht mehr Combat-, Damage- oder HUD-Wahrheit. Mehr Text wuerde die Lesbarkeit eher verschlechtern. Der aktive erste Feuerwechsel braucht eine weichere visuelle Sprache: Source-to-target-Lane, Source-Glow und Target-Halo sollen weiter eindeutig bleiben, aber weniger wie Debug-Markierungen wirken.

## Umfang
- Eng auf TASK_897 und TASK_895 aufbauen.
- Einen eigenen TASK_898-Primary3D-Schalter fuer Focal-Elegance setzen.
- Bestehende TASK_895-Focal-Metadaten erhalten, damit Regressionen stabil bleiben.
- Zusaetzliche Elegance-Metadaten melden: weichere Lane, kleinerer/luftiger Target-Halo, weniger dominanter Source-Glow.
- `get_release_first_exchange_combat_focal_elegance_polish_snapshot()` als Headless-Pruefpunkt bereitstellen.
- Doku, Roadmap, Status und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Contact-, Movement-, Command-, UI- oder Multiplayer-Wahrheit.
- Kein neuer echter Fenster-Capture in diesem Task.
- Kein weiterer Text-Stapel im HUD.
- Kein Map-Editor-/Asset-Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_897_release_first_exchange_world_combat_focal_visual_findings.md`
- `docs/tasks/TASK_895_release_first_exchange_world_combat_focal_hierarchy_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeCombatFocalElegancePolish.build_snapshot()` meldet Schema `sternenbuergerchen.release_first_exchange_combat_focal_elegance_polish.v1` und `task_id = TASK_898`.
- Der Snapshot verlangt TASK_897-Status `ready_for_focal_elegance_polish` und einen bestandenen TASK_895-Focal-Pfad.
- `TerrainMap3DView.get_render_snapshot()` meldet `release_first_exchange_combat_focal_elegance_polish_active = true` und Style-ID `task_898_release_first_exchange_combat_focal_elegance_v1`.
- Die erste Fire-VFX-Entry meldet eine sichtbare elegante Lane, Source-Glow und Target-Halo.
- Die elegante Lane bleibt sichtbar, ist aber schmaler/weicher als TASK_895.
- Target-Halo und Source-Glow bleiben sichtbar, sind aber weniger grossflaechig als TASK_895.
- Read-only-Grenzen bleiben explizit: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_898_release_first_exchange_combat_focal_elegance_polish.md`
- `scripts/mission/release_first_exchange_combat_focal_elegance_polish.gd`
- `scripts/tests/task_898_release_first_exchange_combat_focal_elegance_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_898_release_first_exchange_combat_focal_elegance_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_897_release_first_exchange_world_combat_focal_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_895_release_first_exchange_world_combat_focal_hierarchy_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_898 ist ein Headless-/Runtime-Visual-Polish. Der naechste Slice muss wieder einen echten Fenster-Recapture nachziehen, bevor wir behaupten, dass der Weltkampf-Fokus im Spielerblick wirklich schoen genug ist.

## Naechster Schritt
TASK_899 - Release First Exchange Combat Focal Elegance Real Window Recapture.
