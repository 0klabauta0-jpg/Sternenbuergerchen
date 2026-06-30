# TASK_696 - Door Runtime Visual Animation/Asset Swap

## Ziel / Problem
Nach TASK_695 kann der Spieler Door-Breach im HUD ausloesen, aber die Door selbst ist noch nicht eindeutig genug als geschlossen, in Arbeit oder offen lesbar.

## Sinnhaftigkeit / Ursache
Door-Use ist jetzt ein sichtbarer Command-Pfad. Wenn das Objekt danach optisch nicht klar umschaltet, wirkt der Ablauf trotzdem wie ein Debug-Hook. Die Runtime-Wahrheit fuer Collision/LOS bleibt bereits im Door Runtime State Producer; dieser Task macht nur den sichtbaren Runtime-Visualstate belastbarer.

## Umfang
- Door-Reaction-Snapshot exportiert Door-Animation-/Asset-Swap-Felder fuer closed, operating und open.
- TerrainMap3DView zeichnet Door-Proxies mit klarer Closed-/Opening-/Open-Unterscheidung.
- Render-Snapshot enthaelt pruefbare Door-Visual-Felder.
- Der bestehende Door-Runtime-Collision/LOS-Producer bleibt die einzige Quelle fuer effektive Walkability/LOS-Overrides.

## Nicht-Ziele
- Kein neues Door-Gameplay.
- Keine neue TerrainMapData-Wahrheit.
- Kein vollstaendiger GLB-Instancing- oder Animationsimport.
- Kein echter manueller FullHD-Sichtentscheid.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_691_mission_interaction_runtime_visual_assets.md`
- `docs/tasks/TASK_692_door_runtime_collision_los_contract.md`
- `docs/tasks/TASK_693_door_runtime_state_producer.md`
- `docs/tasks/TASK_695_door_interaction_hud_button_shortcut.md`

## Akzeptanzkriterien
- Closed, operating und open liefern unterscheidbare Door-Visual-Snapshotfelder.
- Der Render-Snapshot exportiert Door-Animation-Phase, Asset-Swap-State, Threshold-Status und Leaf-Gap.
- Operating zeigt einen Opening-/Progress-Indikator, open zeigt eine Schwelle, closed zeigt eine Verriegelungs-/Seal-Markierung.
- Snapshot und Visualpfad bleiben read-only und setzen keine Gameplay-Wahrheit.
- Bestehende Door-HUD- und Door-State-Regressions bleiben gruen.

## Betroffene Dateien
- `scripts/mission/mission_interaction_object_reaction.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_696_door_runtime_visual_animation_asset_swap.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_696_door_runtime_visual_animation_asset_swap.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_695_door_interaction_hud_button_shortcut.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Proxy-Animation ist bewusst lightweight und snapshot-getrieben; echte Asset-Animation im importierten GLB bleibt spaetere Politur.
- Der echte FullHD-Sichtlauf im Fenster bleibt offen, wenn die Lesbarkeit menschlich bewertet werden soll.
