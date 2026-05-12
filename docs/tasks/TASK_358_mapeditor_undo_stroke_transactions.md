# TASK_358 - MapEditor Undo Stroke Transactions

## Ziel
MapEditor-Undo soll ganze Malgesten als eine Transaktion zuruecknehmen, statt bei Brush-, Height- oder Auto-Edge-Aenderungen einzelne Tile-Schritte im Undo-Stack zu erzeugen.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Befund "voller Map-Snapshot pro Undo" passt nicht zum aktuellen Code. `_store_undo_state()` speichert derzeit einzelne Tile-Dictionaries, nicht die komplette Map mit Markern und Szenario. Sinnvoll bleibt aber ein Undo-Task, weil die aktuelle Granularitaet pro Tile/Auto-Aenderung fuer Brush-Strokes und Height-Reconciliation schlecht ist.

## Problem
Ein einzelner Pinselzug kann viele Undo-Eintraege erzeugen. Einmal `Undo` nimmt dann unter Umstaenden nur ein Tile oder eine automatische Edge-Aenderung zurueck, nicht die sichtbare Aktion des Spielers.

## Ursache
Undo wird direkt in den Paint-/Height-/Eraser-Pfaden pro geaendertem Tile gespeichert. Es gibt keine explizite Transaktion fuer "Mouse down bis Mouse up" oder fuer eine zusammenhaengende Tool-Aktion.

## Umfang
- Undo-Transaktions-API einfuehren:
  - `begin_undo_transaction(action_name)`
  - `record_tile_before_change(tile_data)`
  - `commit_undo_transaction()`
  - `cancel_empty_undo_transaction()`
- Brush-, Height- und Eraser-Pfade auf Transaktionen umstellen.
- Automatische Hoehen-/Cliff-/Lower-Neighbor-Aenderungen in dieselbe Transaktion aufnehmen.
- Max-Undo-Grenze auf Transaktionen anwenden.
- Bestehende Einzel-Tile-Undo-Semantik fuer sehr kleine Aktionen erhalten.

## Akzeptanzkriterien
- [x] Ein Brush-Stroke mit mehreren Tiles wird durch ein einziges Undo komplett zurueckgenommen.
- [x] Height-Tool inklusive automatisch erzeugter Cliff-/Edge-Aenderungen wird konsistent zurueckgenommen.
- [x] Eraser-Operationen bleiben in ihrer Layer-Prioritaet erhalten und lassen sich als Aktion undoen.
- [x] Leere Transaktionen erzeugen keinen Undo-Eintrag.
- [x] Headless-Verifier prueft Stroke-Undo, Height-Undo und Stack-Limit.

## Umsetzung
- MapEditor nutzt jetzt explizite Undo-Transaktionen mit `begin_undo_transaction()`, `record_tile_before_change()`, `commit_undo_transaction()` und `cancel_empty_undo_transaction()`.
- Brush-, Height-, Eraser-, Rotate- und Property-Patch-Pfade erfassen geaenderte Tiles als zusammenhaengende Aktion; direkte Test-/Helper-Aufrufe oeffnen bei Bedarf automatisch eine kleine Transaktion.
- Undo-Stack-Limit gilt auf Transaktionsebene, und `_undo_last_change()` stellt alle Tile-States der Transaktion gemeinsam wieder her.
- Der Authoring-Contract meldet `tile_transaction_stack_v3` und `undo_transactional`, damit Regressionen gegen die neue Semantik sichtbar werden.

## Erwartete Dateien
- `scripts/editor/map_editor.gd`
- ggf. `scripts/editor/map_editor_undo_transaction.gd`
- `scripts/tests/task_358_mapeditor_undo_stroke_transactions.gd`
- ggf. `scripts/tests/bugfix_map_editor_station_floor_structure_undo.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_358_mapeditor_undo_stroke_transactions.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_map_editor_station_floor_structure_undo.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Die Reihenfolge von automatischen Edge-Aenderungen muss stabil bleiben, damit Undo keine halb rekonstruierten Cliff-Zustaende erzeugt.
- Marker-, Patrol- und Scenario-Undo sind nicht Teil dieses ersten Tasks, ausser sie nutzen denselben bestehenden Tile-Undo-Pfad.
