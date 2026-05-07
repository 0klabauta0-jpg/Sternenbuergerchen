# Nature Terrain Prop Rules

TASK_254 introduces a first Nature Kit prop slice for tactical maps. The meshes are only visuals; gameplay remains in `TerrainTileData`.

## Gameplay Truth
- `object_type_id` selects the visible prop.
- `walkable` controls whether movement may enter the tile.
- `blocks_los` plus `height_level + object_height` controls LOS blocking.
- `cover_value` controls cover scoring.
- Mesh size, mesh bounds and material names are not gameplay truth.

## Prop Roles
- `nature_tree_blocker`: tall tree, not walkable, blocks LOS, strong cover, `object_height = 3`.
- `nature_rock_cover`: large rock, not walkable, blocks LOS, medium cover, `object_height = 2`.
- `nature_bush_cover`: walkable soft cover, no LOS block, light cover, `object_height = 1`.
- `nature_cactus_cover`: small blocking desert cover, no LOS block in V1, `object_height = 1`.
- `nature_deco_logs`: visual-only small prop, walkable, no LOS block, no cover, `object_height = 0`.

## Editor Rules
- Nature props live in the `Nature Props` object palette.
- Placing a Nature prop writes `object_type_id`, `walkable`, `blocks_los`, `cover_value` and `object_height`.
- Placement preserves `type_id`, `surface_type`, `height_level` and `edge_type`.
- Removing or replacing a Nature prop must not flatten hills or change the surface.

## Visual Rules
- Props anchor to the top of the terrain tile, including H1/H2 hills.
- Overlays, selection and waypoints remain above prop/top-surface visuals.
- Missing Nature prop mappings must create visible missing-asset markers and diagnostic counts.
