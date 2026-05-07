# Nature Kit Hill Playability Visual Checklist

## Fixture
- Create or load a 32x32 test map with H0/H1/H2 terrain.
- Include at least one hard cliff, one walkable slope, one plateau interior, sand/rock/road/ground surfaces and the `Nature Props` palette objects.

## Visual Readability
- Hard cliffs read as blocked edges.
- Slopes read as traversable ramps or steps.
- Nature ground surfaces do not hide cliff/slope side models.
- Tree, rock, bush, cactus and deco props sit on the tile top at H0, H1 and H2.

## Tactical Overlays
- Grid lines remain visible.
- Selection, marker, LZ, waypoint and area-order tiles remain readable.
- FoW dim/blackout overlays still leave known terrain understandable.
- Friendly/enemy unit proxies remain visible against Nature ground and props.

## Gameplay
- Tree and large rock tiles block movement and LOS according to TerrainTileData.
- Bush cover stays walkable and gives light cover.
- Cactus blocks movement but does not block LOS in V1.
- Deco logs give no cover, no LOS block and no movement block.

## Performance
- Check the Godot Monitor values after camera rotate/zoom.
- No missing asset markers are visible.
- If Nature prop counts grow beyond the curated smoke size, consider instancing or stricter editor budgets before adding more variants.
