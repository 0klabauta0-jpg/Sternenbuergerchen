# TASK_724 - Station Route Recapture Visual Followup

## Ziel / Problem
Der Nach-TASK_722-Recapture ist technisch bereit, aber der echte Fensterblick ist noch nicht angenehm genug fuer Akzeptanz: Die linke Mini-Fireteam-Spalte nimmt weiter Kartenrand weg, die Station-/Route-Labels wirken in der Station eng, und die Top-Navigation liest sich als zu breiter leerer Balken.

## Sinnhaftigkeit / Ursache
TASK_723 meldet bewusst `needs_visual_review`. Der aktuelle Screenshot zeigt keine Runtime-Blocker, aber noch UI-Reibung. Diese Reibung soll gezielt als Darstellungs-/Layout-Polish behandelt werden, nicht als Door-, Objective- oder Multiplayer-Umbau.

## Umfang
- Mission-TopNav im `DropLightLayoutContract` schmaler machen, ohne das feste HUD-Raster zu brechen.
- Fireteam-Mini-Spalte im Mission-HUD weiter kompakt halten und Eventlog darunter nachziehen.
- Station-/Route-3D-Labels weiter voneinander weg staggert darstellen und minimale Label-Kontrastwerte als TASK_724-Snapshot exportieren.
- HTML-Ist-Stand-/Handbuchbericht und Contracts auf TASK_724 aktualisieren.

## Nicht-Ziele
- Kein neuer Door-State.
- Kein Objective-Gate-Rewrite.
- Kein Multiplayer-Authority-Umbau.
- Kein akzeptierter Sichtentscheid ohne erneuten Capture nach dem Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_723_station_route_host_client_recapture_review.md`
- `docs/tasks/TASK_722_station_route_hud_visual_polish.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Layout-Snapshot meldet schmalere TopNav und niedrigere Fireteam-Mini-Spalte als TASK_723-Recapture-Befund.
- Station-/Route-Label-Stagger-Abstaende sind groesser und bleiben reine Darstellung.
- Neuer Snapshot bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.
- Ergebnis-Gate ist `ready_for_recapture`, nicht `accepted`.

## Betroffene Dateien
- `scripts/meta/drop_light_layout_contract.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/task_724_station_route_recapture_visual_followup.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_724_station_route_recapture_visual_followup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_723_station_route_host_client_recapture_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_722_station_route_hud_visual_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_180_mission_drop_light_fixed_hud_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
TASK_724 verbessert den sichtbaren Recapture-Befund, ersetzt aber erneut keinen echten Host/Client-Fensterlauf. Nach dem Polish muss ein frischer Capture entscheiden, ob die Station-Route als kleiner Multiplayer-Slice akzeptiert werden kann.
