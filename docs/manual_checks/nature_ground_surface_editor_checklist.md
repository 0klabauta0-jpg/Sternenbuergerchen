# Nature Ground Surface Editor Checklist

## Setup
- Open the Map Editor and switch to the 2.5D Primary View.
- Use a small map with H0, H1 and H2 tiles plus at least one cliff, one slope, one selected tile, one marker and one waypoint.

## Editor Palette
- The `Nature Boden` palette group is visible.
- `Nature Dirt`, `Nature Sand/Dirt`, `Nature Rock/Dirt` and `Nature Grass Patch` can be selected.
- Painting a Nature Boden entry changes the intended surface/theme/detail only and does not reset `height_level`, `edge_type`, `object_type_id`, cover, walkable or LOS fields.

## Mission View
- Standard terrain remains the Space Kit base color on flat and elevated tiles.
- Nature Boden renders as an offset detail/patch on top of the existing terrain and does not replace the base floor.
- Nature Grass Patch reads as a detail object on the existing floor.
- Sand, rock and road remain distinguishable through the existing surface tint overlays.
- Cliff and slope side models are not covered by top-surface visuals.

## Tactical Overlays
- Grid lines remain visible.
- Selection, markers, LZ/waypoint tiles and area-order tiles remain readable over Nature ground.
- Missing-Mapping markers do not appear for Nature ground assets.

## Gameplay Boundary
- `surface_type` remains the gameplay source for movement cost and audio surface cues.
- No new surface type such as dirt or grass is saved without a separate gameplay contract.
