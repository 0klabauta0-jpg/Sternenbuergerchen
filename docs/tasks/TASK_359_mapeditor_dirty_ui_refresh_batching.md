# TASK_359 - MapEditor Dirty UI Refresh Batching

## Ziel
MapEditor-UI-Refreshes fuer Selection, Property Panel, Hover Preview und Editor-Status sollen ueber Dirty-Flags gebatcht werden, statt bei jeder Mouse-Move-/Paint-Zwischenstufe synchron zu laufen.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll. Der aktuelle Code hat mit `_queue_3d_map_refresh()` bereits ein gutes Coalescing-Muster fuer die 2.5D-Ansicht, aber mehrere 2D-/Inspector-Refreshes werden in Paint- und Input-Pfaden direkt angestossen.

## Problem
Schnelles Bewegen oder Drag-Painting kann mehrere UI-Refreshes pro Frame erzeugen. Das ist bei kleinen Maps okay, fuehlt sich aber mit groesseren Maps, Inspector-Panels und 2.5D-Preview leichter traege an.

## Ursache
Refresh-Aufrufe wie Selection-Visual, Property-Panel und Hover-Preview liegen verteilt in Tool-Callbacks. Es gibt keine gemeinsame Dirty-Flag-Sammelstelle fuer Editor-UI.

## Umfang
- Kleine Dirty-Refresh-Queue im MapEditor einfuehren, z. B. `_queue_editor_ui_refresh(flags)`.
- Dirty-Flags fuer Selection, Properties, Tool-State, Hover und Scenario-Panel unterscheiden.
- Bestehende `_queue_3d_map_refresh()`-Logik als Vorbild nutzen.
- Direktes Feedback nur dort synchron lassen, wo es fuer Klick-/Drag-Gefuehl noetig ist.
- Refreshes pro Frame oder per `call_deferred` coalescen.

## Akzeptanzkriterien
- [x] Mehrere Paint-/Mouse-Move-Events in einem Frame fuehren zu einem gebatchten UI-Refresh.
- [x] Tile-Auswahl, Property Panel und Hover Preview bleiben korrekt und stale-frei.
- [x] 3D-Refresh-Coalescing bleibt unveraendert.
- [x] Kein sichtbarer Lag beim Umschalten von Tools oder beim Auswaehlen einzelner Tiles.
- [x] Headless-Verifier oder Diagnose-Snapshot prueft Dirty-Flag-Coalescing.

## Umsetzung
- MapEditor hat eine deferred Dirty-Queue fuer Editor-UI-Refreshes mit getrennten Flags fuer `selection`, `properties`, `tool_state`, `hover` und `scenario`.
- Paint-, Height-, Eraser-, Area-Selection-, Undo-/Dirty- und Hover-Motion-Pfade sammeln Refresh-Wuensche und flushen sie gebuendelt im naechsten Frame.
- Die bestehende `_queue_3d_map_refresh()`-Logik bleibt separat und unveraendert; der neue Debug-Snapshot zeigt UI-Requests, Pending-/Flush-Flags und Hover-Queue-State.
- `get_authoring_action_contract_snapshot()` dokumentiert den neuen batched Editor-UI-Refresh-Vertrag.

## Erwartete Dateien
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_359_mapeditor_dirty_ui_refresh_batching.gd`
- ggf. `scripts/tests/task_295_map_editor_paint_toolbar_tools_polish.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_359_mapeditor_dirty_ui_refresh_batching.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_295_map_editor_paint_toolbar_tools_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Zu aggressives Batching kann Property-Panels kurz stale wirken lassen. Der Task braucht deshalb kleine, gut benannte Dirty-Flags statt eines globalen "refresh all spaeter".
