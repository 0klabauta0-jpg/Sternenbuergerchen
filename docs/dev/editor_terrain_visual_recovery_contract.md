# Editor Terrain Visual Recovery Contract

## Summary

TASK_291 fixes the editor visual baseline for the TASK_292-TASK_298 chain. Gameplay truth remains `TerrainTileData`: `height_level`, `edge_type`, `surface_type`, `object_type_id`, `walkable`, `blocks_los`, `cover_value` and `object_height`.

## Diagnosis

The yellow editor grid had drifted into an always-front overlay: its material used no depth test and an always depth-draw mode. That made grid lines visible through walls, rocks and other solid 3D assets, which flattened the scene and made cliffs/ramp sides look like decoration on top of the plateau. Selection may stay prominent, but the base grid must participate in depth testing.

Nature props were also scaled too small for the current 2.5D camera and lighting setup. Cactus and bush visuals were technically present, but their silhouette was not strong enough to communicate cover or blocking roles.

## Visual Height Canon

- `height_level` stays 0, 1 or 2.
- `height_step` is `0.5` in `data/terrain_3d_asset_mapping.json`.
- Tile plates use the mapping ground thickness and sit on the tile top surface.
- Standard wall and rock objects stand on the tile top, not on the world floor.
- Active cliffs and ramps use the older Space Kit side/ramp models for this editor pass.
- Height-edge data is read from the higher tile, but the visible cliff/ramp model is anchored on the lower adjacent neighbor tile. Corner pieces are anchored on the diagonal lower outside tile. This matches the Kenney sample language: the hilltop is a plateau, while its surrounding neighbor tiles carry the side walls or ramps.
- The editor height/stamp brush mirrors that construction in authoring data: `edge_type = cliff` on raised tiles creates or refreshes explicit lower-neighbor `cliff_straight_*` and `cliff_corner_*` tiles; `edge_type = none` stays a sketch/manual state.
- Height-edge models fill the vertical span between the lower neighbor and the raised tile top.
- Ramp models are only valid for `edge_type = slope`; hard cliffs must not use ramp models.
- The base grid is a depth-tested editor aid. It sits near the tile top but must not draw through walls, rocks, cliffs or high props.
- Selection is a separate, brighter affordance and can remain more visible than the base grid.

## Central Values

- `HEIGHT_STEP`: `0.5`
- `TILE_GRID_LINE_SURFACE_Y_OFFSET`: `0.052`
- `TILE_SELECTION_SURFACE_Y_OFFSET`: `0.095`
- Editor light rotation: `Vector3(-58, -32, 0)`
- Editor light energy: `1.18`
- Editor shadow opacity: `0.42`
- Editor shadow blur: `2.15`
- Editor ambient energy: `0.92`
- Space Station Kit GLBs receive the shared `models/Textures/colormap.png` atlas at runtime when their imported material lacks an albedo texture.

## Reference Fixture

Use `maps/editor_terrain_visual_recovery_reference.json`.

The fixture contains:

- H0 ground and sand tiles.
- H1 cliff/slope tiles with a wall and a Nature rock cover prop.
- H2 plateau tiles with rock, road and no-edge interior.
- Nature cactus, bush, tree, rock and logs.
- Space-station computer and container objects.
- One marker for visual anchoring.

## Follow-Up Order

1. TASK_292 repairs height, cliff/ramp and grid depth.
2. TASK_293 calibrates editor light and shadows.
3. TASK_294 calibrates Nature prop scale and cover readability.
4. TASK_295 polishes paint-like authoring tools.
5. TASK_296 filters palette taxonomy and adds Space Station assets.
6. TASK_297 adds collapsible inspector sections.
7. TASK_298 runs the integrated visual/playability smoke.
