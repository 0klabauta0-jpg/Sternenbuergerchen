# TASK_684 - Map Editor Interaction Focus Scroll

## Ziel / Problem
TASK_683 hat gezeigt, dass Binding-Inspector und Binding-Editor in FullHD vorhanden sind, aber im rechten Property-Panel erst nach bewusstem Scroll-Fokus bequem sichtbar werden. Beim echten Mapbau soll ein selektierter Interaction-Marker den relevanten Binding-Bereich automatisch in den Blick holen.

## Ursache / Sinnhaftigkeit
Die Funktion war korrekt, aber der Workflow blieb reibend: Marker auswaehlen, Preset setzen, Apply/Remove nutzen und danach im langen Property-Panel suchen. Das fuehlt sich fuer Content-Bau langsam an und verdeckt die neuen Presets genau in dem Moment, in dem man sie braucht.

## Umfang
- Kleiner Fokus-/Scroll-Helper im bestehenden Map-Editor.
- Markerauswahl, Preset-Apply, Binding-Apply und Binding-Remove fokussieren den Interaction-Binding-Bereich.
- Snapshot ergaenzt den Fokus-/Scroll-Zustand fuer Verifier.
- Report-, Contract-, Status- und Roadmap-Update.

## Nicht-Ziele
- Kein Layout-Redesign des Property-Panels.
- Keine neue Sidebar oder neues Fenster.
- Keine Runtime-Interaction oder Mission-State-Aenderung.
- Keine Aenderung am Scenario-Speicherformat.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_683_map_editor_interaction_fullhd_sight_pass.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Nach Markerauswahl wird der Binding-Editor im FullHD-Property-Panel sichtbar, ohne dass der Test manuell ans Panelende scrollt.
- Preset-Apply fokussiert denselben Bereich erneut.
- Binding-Apply und Binding-Remove halten den Bereich sichtbar.
- Snapshot meldet `editor_visible_footprint = true`, `property_panel_scrollable = true` und `ui_sets_gameplay_truth = false`.
- TASK_683 bleibt gruen.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_684_map_editor_interaction_focus_scroll.gd`
- `docs/tasks/TASK_684_map_editor_interaction_focus_scroll.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_684_map_editor_interaction_focus_scroll.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_683_map_editor_interaction_fullhd_sight_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_682_mission_interaction_binding_presets.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Helper scrollt den vorhandenen Property-ScrollContainer, ersetzt aber keinen echten Sichtentscheid. Wenn das Panel trotz Fokus zu dicht wirkt, braucht es spaeter einen gezielten Layout-Polish.
