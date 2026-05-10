# Editor Hill Cliff Grid Depth Checklist

- Open `maps/editor_terrain_visual_recovery_reference.json` in the map editor.
- Confirm H0, H1 and H2 are visually distinct at default camera angle.
- Confirm active cliff sides fill the span below raised tiles rather than sitting on the plateau top.
- With brush size `3x3`, stamp H1/H2 using edge mode `Cliff` and confirm `cliff_straight_*` / `cliff_corner_*` tiles are created on the lower neighbor ring.
- Confirm slope/ramp visuals appear only on slope edge tiles.
- Set the height tool edge mode to `Keine`, raise an H0 tile to H1/H2, and confirm the tile stays raised without auto-generating a cliff or slope. This is an intentional authoring/sketch state for manually showing where cliff pieces should go.
- Confirm the yellow base grid does not draw through the wall, Nature rock cover or station container.
- Confirm selection remains visible without becoming a full-map always-front grid.
- Confirm sand, rock and road surface tints remain readable on elevated tiles.
- Rotate and zoom once; repeat the grid-through-wall check.
