# Hill Mechanics 16x16 Testmap Checklist

Map: `res://maps/hill_mechanics_16x16_testmap.json`

Purpose: small fixed 16x16 mission/editor testmap for movement, slope, cliff, surface-cost, cover and LOS misunderstandings. The map is intentionally compact so a single Full-HD tactical view can show the important mechanics without needing a large scenario.

## Zones

- Alpha route: `spawn_alpha` at grid `(1, 1)` starts on H0 and reaches the objective through the north ramp opening `(6, 5) -> (6, 6)`.
- Bravo route: `spawn_bravo` at grid `(14, 14)` follows the south road and uses the south ramp opening `(6, 9) -> (6, 8)`.
- Objective: `objective_point` at grid `(5, 6)` sits on the H1 plateau and remains walkable.
- Cliff probe: `cliff_probe` around grid `(4, 7)` marks an explicit lower-neighbor cliff tile. Direct H1/H0 movement through that side should fail.
- Diagonal probe: `diagonal_probe` around grid `(4, 5)` is for checking an explicit cliff corner tile.
- Compass markers: `corner_north`, `corner_south`, `corner_west` and `corner_east` render as N/E/S/W letters outside the map bounds.
- Hill corner tiles: the visible hill corners use `cliff_corner_sw`, `cliff_corner_se`, `cliff_corner_nw` and `cliff_corner_ne` on lower H0 neighbor tiles, matching the construction style in `new_map.json`.
- The small colored plates on probe points are editor markers, not terrain floor generation.

## Mechanics To Check

- H0/H1 readability: the plateau should be visibly higher than the lowland.
- Hill edge placement: cliff visuals should be authored on the lower neighbor tiles around the raised plateau, not as decorative parts on top of the plateau.
- Ground color: every non-cliff floor tile should use the Space Kit `ground_flat` base (`terrain.glb`) with the sampled, unshaded peach/orange top color from `terrain_SW.png`, not an extra texture overlay and not the old olive-brown fallback.
- Nature Sand/Rock raised ground detail tiles should not be generated in this reference map. Yellow sand remains a `surface_type`/surface tint, not a Nature ground replacement object.
- Compass markers: N/E/S/W should sit just outside the four map edges, not replace corner floor tiles.
- Height/LOS contract: `height_level` stays the gameplay terrain tier (`0..2`), while the visible `0.5` step is only the 2.5D render scale. LOS blockers use `height_level + object_height`.
- Slope movement: north and south ramp openings should allow movement across the H0/H1 height difference.
- Cliff movement: explicit cliff side tiles should block direct movement even when the visual distance looks short.
- Surface costs: road should be faster/cheaper than the south sand basin.
- Blocking cover: tree, rock and station container tiles should block movement; tree/rock/container should also block LOS.
- Space Station visual: the station container should show the shared colormap texture and should not render as a plain grey/white untextured block.
- Soft cover: bush tiles should provide cover while staying walkable and LOS-open.
- Light blocker: cactus should block movement without becoming a tall LOS wall.
- Deco prop: logs should remain visual/no-cover/no-block gameplay.
- Tile selection: selecting slope, cliff and objective tiles should keep the selection visible on top of the terrain grid.

## Local Gate

Run:

```powershell
godot --headless --script res://scripts/tests/hill_mechanics_16x16_testmap_verifier.gd
```

Expected: all tests pass, with no missing map asset mappings in the 3D render snapshot.
