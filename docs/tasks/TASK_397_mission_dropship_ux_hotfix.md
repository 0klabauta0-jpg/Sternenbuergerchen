# TASK_397 - Mission Dropship UX Hotfix

## Ziel
Mission-Dropships sollen sich beim manuellen Test weniger traege und entkoppelt anfuehlen: mehrere Schiffe muessen ihre Drops parallel starten koennen, die Anflugrichtung muss wieder als gut lesbarer gruener Streifen sichtbar sein, und alte 2D-NPC-Modelle duerfen in der 2.5D-Mission nicht ueber der 3D-Ansicht auftauchen.

## Sinnhaftigkeit
Der Live-Test zeigt, dass die fachliche Per-Craft-Struktur vorhanden ist, aber UI und Visuals noch sperrig wirken. Ein scheinbar verschwindender Anflugvektor, eine horizontale Button-Reihe und wieder sichtbare Legacy-Sprites machen es schwer zu erkennen, welches Dropship gerade was tut.

## Umfang
- Dropship-Card-Approach-Buttons `NW`, `NE`, `SW`, `SE` werden wieder als kompaktes 2x2-Feld gerendert.
- Der Anflugvektor bleibt eine breite Richtungspfeil-/Streifenform, wird aber deutlich sichtbarer und weniger kopflastig.
- Die Parallel-Drop-Regel wird ueber einen Test abgesichert, bei dem Beta starten darf, waehrend Alpha bereits beim Deboarding ist.
- Legacy-2D-Unit-CanvasItems werden in der Primary-2.5D-Ansicht nach Runtime-Selection-Refresh und Drop-Presence-Updates erneut ausgeblendet.

## Akzeptanz
- Jede Mission-Dropshipkarte zeigt eine eigene 2x2-Approach-Button-Gruppe.
- Der Primary3DView-Snapshot meldet mindestens zwei Approach-Vektoren und eine lesbare Streifenbreite.
- `Drop` fuer Dropship Beta startet, waehrend Dropship Alpha in `unloading` ist; Alpha bleibt als eigene Live-Sequenz erhalten.
- Keine alten Unit-Sprite-Kinder sind in der 2.5D-Mission sichtbar.

## Betroffene Dateien
- `docs/tasks/TASK_397_mission_dropship_ux_hotfix.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_397_mission_dropship_ux_hotfix.gd`

## Pruefung
- [x] `godot --headless --path . --script res://scripts/tests/task_397_mission_dropship_ux_hotfix.gd`
- [x] `godot --headless --path . --script res://scripts/tests/task_396_mission_dropship_lz_drop_hotfix.gd`
- [x] `godot --headless --path . --script res://scripts/tests/task_395_manual_dropship_parallel_flow.gd`
- [x] `godot --headless --path . --script res://scripts/tests/task_394_per_craft_shipcard_commands.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Die genaue optische Balance der Dropshipkarte bleibt ein manueller FullHD-Sichtcheck.
- Der Anflugvektor ist weiterhin eine breite Pfeilform, kein gestrichelter Shader-Streifen.
