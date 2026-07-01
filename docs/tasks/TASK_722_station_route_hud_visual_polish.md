# TASK_722 - Station Route HUD Visual Polish

## Ziel / Problem
Der frische TASK_721-Zwei-Fenster-Befund meldet `needs_visual_polish`: Die linke Fireteam-Uebersicht verdeckt zu viel Karte, Station-/Door-Labels sind im Gebaeude zu klein oder gedrungen, und der Top-Nav-Timer kann wie ein leerer Platzhalter wirken.

## Sinnhaftigkeit / Ursache
Die technische Door/Computer/Cargo-Kette ist pruefbar, aber die sichtbare Host/Client-Abnahme haengt am Spielerblick. Der naechste Slice muss deshalb die vorhandenen HUD- und Render-Vertraege polieren, ohne Door-, Objective-, Multiplayer- oder Runtime-Wahrheit zu verschieben.

## Umfang
- `DropLightLayoutContract.get_mission_hud_layout()` macht die linke Fireteam-Spalte kleiner und verschiebt das Eventlog darunter.
- Mission-Mini-Fireteam-Karten bekommen eine kompaktere `mission_mini`-Dichte.
- Der Top-Nav-Timer versteckt den leeren Zustand statt `--:--` als Placeholder zu zeigen.
- Station-Route- und Interaction-Labels bekommen groesseren Text, staerkeren Outline, groessere Stagger-Abstaende und Backplate-Marker.
- `MissionTacticalSandboxController.get_station_route_hud_visual_polish_snapshot()` dokumentiert den Zustand read-only.

## Nicht-Ziele
- Kein neuer Door-State.
- Kein Objective-Gate-Rewrite.
- Kein neues Multiplayer-Authority-System.
- Kein bestandener menschlicher Host/Client-Sichtentscheid ohne erneuten echten Capture.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_721_station_route_two_window_visual_findings.md`
- `docs/tasks/TASK_720_station_route_capture_recheck_handbook.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Linke Fireteam-Mini-Spalte ist im Mission-HUD kleiner als der TASK_627-Stand und bleibt scrollbar.
- Station-/Door-/Route-Labels melden groessere Label-/Outline-/Backplate-Werte im Render-Snapshot.
- Top-Nav zeigt keinen leeren Timer-Placeholder.
- Der neue Snapshot bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.
- Der Status ist `ready_for_recapture`, nicht automatisch `accepted`.

## Betroffene Dateien
- `scripts/meta/drop_light_layout_contract.gd`
- `scripts/meta/fob_fireteam_card.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/task_722_station_route_hud_visual_polish.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_722_station_route_hud_visual_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_721_station_route_two_window_visual_findings.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_719_station_route_post_polish_recheck.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_627_host_client_fireteam_eventlog_overlap_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_180_mission_drop_light_fixed_hud_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
Der Slice verbessert die sichtbaren Vertraege und die erwartete Lesbarkeit, ersetzt aber keinen erneuten echten Host/Client-Fensterlauf. Nach TASK_722 muss der Capture erneut betrachtet werden.
