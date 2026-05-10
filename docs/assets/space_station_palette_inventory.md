# Space Station Palette Inventory

## Source

- Bundle: Kenney Space Station Kit
- Project root: `res://Assets/curated/kenney/space_station/`
- Runtime rule: only project-local `res://` paths are used.

## Palette Subset

| Type ID | Resource | Role |
| --- | --- | --- |
| `station_wall` | `models/wall.glb` | wall panel / hard cover |
| `station_wall_door` | `models/wall-door.glb` | airlock door wall |
| `station_computer` | `models/computer.glb` | console / soft cover |
| `station_table_display` | `models/table-display.glb` | display table / soft cover |
| `station_container_wide` | `models/container-wide.glb` | cargo cover |
| `station_bed_single` | `models/bed-single.glb` | medbay prop |
| `station_floor_panel` | `models/floor-panel.glb` | floor insert visual |

The subset is intentionally small. More multi-tile structures should be added only with a snapping/placement task.

The runtime 3D view applies the shared `models/Textures/colormap.png` atlas to these GLBs, because the imported `colormap` material can arrive without an albedo texture.
