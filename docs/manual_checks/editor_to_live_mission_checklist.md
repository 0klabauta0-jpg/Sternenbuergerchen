# Editor-to-Live Mission Checklist

## Scenario
- Load `res://data/mission_scenarios/editor_validation_smoke.json` in `scenes/editor/map_editor.tscn`.
- Confirm the scenario references `res://maps/task_157_editor_mvp_map.json`.
- Confirm no LZ, dropship landing position, Area Order or runtime contact state is shown as authored scenario data.

## Live Start
- Use the editor Live Test action.
- Confirm the live mission opens on the referenced map.
- Confirm the LZ marker is not visible at mission start.
- Confirm enemy wave settings show two waves with one unit per wave.
- Confirm `enemy_delta` and `enemy_echo` use their patrol bindings from the map patrol paths.

## Tactical Smoke
- Select/set an LZ near the objective through the Mission Control panel.
- Call the dropship.
- Confirm the dropship marker flies in from off-map, deploys the selected fireteam, then leaves.
- Confirm the deployed fireteam becomes available for GO/orders only after insertion.
- Drag an Attack Area over the enemy/objective side of the map.
- Execute GO and confirm the Attack Area becomes active.

## Visual Bridge
- Confirm friendly and enemy visuals are visible in the live mission.
- Confirm the ground uses the orange Kenney Space Kit terrain material, not blue/gray debug boxes.
- Confirm no magenta `MissingAsset_*` marker is visible on the authored map.
- Confirm the Area Order overlay is visible after drawing the area.
- Confirm contact markers/overlays appear once the fireteam has LOS to an enemy.
- Confirm Move, Defend and Take waypoints appear in the 2.5D view after authoring the orders.
- Confirm objective capture radius/progress appears in the 2.5D view when friendlies stand inside the radius.
- Confirm unit state badges update for moving, defending, taking, engaging/contact or idle states.
- Confirm mission victory/failure feedback appears in the 2.5D view when the scenario resolves.
- Confirm old free-floating 2D combat/wave/objective labels do not cover the primary 2.5D map.

## Notes
- Record blockers with the exact scenario path, map path and action that failed.
- If a 3D-primary branch is active, repeat the same checks in that view and verify the same data is not only visible in a 2D fallback.
