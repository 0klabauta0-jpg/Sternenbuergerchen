class_name BaseInteriorNavigation
extends RefCounted
## Static authored clearance map. Original coarse MapData remains render authority.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const NAV_PATH := "res://maps/base_interior_navigation.json"
const SCALE := 4
static func supports(base_path: String) -> bool:
 return base_path.get_file() in ["campaign_intro_base.json", "homebase_frontier_exploration.json"]
static func load_map(base_path: String):
 return MAP.load_from_file(NAV_PATH if supports(base_path) else base_path)
static func layout(base_path: String) -> Dictionary:
 var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base_path))
 if not supports(base_path): return Dictionary(source.get("homebase_exploration",{})).duplicate(true)
 var nav: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NAV_PATH))
 return Dictionary(nav.get("homebase_exploration",{})).duplicate(true)
static func plane_at_grid(grid: Vector2i) -> Vector3:
 return Vector3((float(grid.x)+float(grid.y)*.5)/SCALE,0,float(grid.y)*sqrt(3.0)*.5/SCALE)
static func standing_y(plane: Vector3) -> float:
 if Rect2(10.6,4.10,3.8,3.92).has_point(Vector2(plane.x,plane.z)): return .165
 if Rect2(24.61,4.15,5.78,3.83).has_point(Vector2(plane.x,plane.z)): return .19
 return 0.0

# Derived graph cache: TerrainRegistry retains all navigation facts. The graph is
# rebuilt only when that registry revision changes; no scene/mesh/physics query.
var _graph := AStar2D.new()
var _graph_terrain
var _graph_revision := -1
var _graph_ids: Dictionary = {}
var _graph_world: Dictionary = {}
var _graph_build_ms := 0.0
func configure_graph(terrain) -> void:
 if terrain == _graph_terrain and _graph_revision == int(terrain.get_revision()): return
 var begin := Time.get_ticks_usec()
 _graph_terrain = terrain
 _graph_revision = int(terrain.get_revision())
 _graph.clear();_graph_ids.clear();_graph_world.clear()
 var id := 0
 for tile in terrain.get_all_tiles():
  if not terrain.is_walkable(tile.grid_position): continue
  _graph_ids[tile.grid_position] = id
  _graph_world[id] = Vector2(tile.world_position)
  var plane := plane_at_grid(tile.grid_position)
  _graph.add_point(id,Vector2(plane.x,plane.z))
  id += 1
 for pos: Vector2i in _graph_ids:
  for direction in [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,1)]:
   var neighbor: Vector2i = pos + direction
   if _graph_ids.has(neighbor):_graph.connect_points(int(_graph_ids[pos]),int(_graph_ids[neighbor]))
 _graph_build_ms = (Time.get_ticks_usec()-begin)/1000.0
func find_world_path(from_world: Vector2,to_world: Vector2) -> Array:
 if _graph_terrain == null:return []
 configure_graph(_graph_terrain)
 var from_grid: Vector2i = _graph_terrain.world_to_grid(from_world)
 var to_grid: Vector2i = _graph_terrain.world_to_grid(to_world)
 if not _graph_ids.has(from_grid) or not _graph_ids.has(to_grid):return []
 var result: Array = []
 for id in _graph.get_id_path(int(_graph_ids[from_grid]),int(_graph_ids[to_grid])):
  result.append(_graph_world[id])
 return result
func get_graph_diagnostics() -> Dictionary:
 return {"points":_graph.get_point_count(),"build_ms":_graph_build_ms,"terrain_revision":_graph_revision}
