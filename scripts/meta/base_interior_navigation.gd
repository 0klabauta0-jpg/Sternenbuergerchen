class_name BaseInteriorNavigation
extends RefCounted
## Static authored clearance map. Original coarse MapData remains render authority.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const NAV_PATH := "res://maps/base_interior_navigation.json"
const SCALE := 4
const MODULAR_GEOMETRY = preload("res://scripts/meta/modular_base_geometry.gd")
static func supports(base_path: String) -> bool:
 return base_path.get_file() in ["campaign_intro_base.json", "homebase_frontier_exploration.json"]
static func load_map(base_path: String):
 var data = MAP.load_from_file(NAV_PATH if supports(base_path) else base_path)
 if base_path.get_file() == "campaign_intro_base.json":
  preload("res://scripts/terrain/homebase_rock_rules.gd").apply_fine(data)
 return data
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
var _field_beds: Array = []
var _housing: Array = []
var _craft_rectangles: Array[Rect2] = []
var _modular_rooms: Array = []
var _modular_beds: Array = []
var _field_disabled: Array[int] = []
func set_modular_geometry(rooms: Array, beds: Array) -> void:
 _modular_rooms = rooms.duplicate(true)
 _modular_beds = beds.duplicate(true)
 _apply_field_beds()
func set_craft_rectangles(rectangles: Array[Rect2]) -> void:
 if _craft_rectangles==rectangles:return
 _craft_rectangles=rectangles.duplicate()
 _apply_field_beds()
func set_campaign_housing(houses: Array) -> void:
 _housing = houses.duplicate(true)
 _apply_field_beds()
func set_field_beds(beds: Array) -> void:
 _field_beds = beds.duplicate(true)
 _apply_field_beds()
func _apply_field_beds() -> void:
 for id: int in _field_disabled:
  if _graph.has_point(id): _graph.set_point_disabled(id, false)
 _field_disabled.clear()
 for housing: Dictionary in _housing:
  var raw: Array = housing.get("nav_delta", [])
  if raw.size() != 2: continue
  var delta := Vector2i(int(raw[0]), int(raw[1]))
  for x in range(12, 59):
   for y in range(14, 43):
    var source := Vector2i(x, y)
    var source_plane := plane_at_grid(source)
    if not Rect2(9.0, 3.0, 7.0, 6.0).has_point(Vector2(source_plane.x, source_plane.z)): continue
    var target := source + delta
    if _graph_terrain.is_walkable(source) or not _graph_ids.has(target): continue
    var point: int = _graph_ids[target]
    _graph.set_point_disabled(point, true)
    _field_disabled.append(point)
 for bed: Dictionary in _field_beds:
  if bed.get("visual_kind", "") != "field_bunk": continue
  var pos: Array = bed.sleep_plane
  var row := roundi(float(pos[1]) * SCALE / (sqrt(3.0) * .5))
  var column := roundi(float(pos[0]) * SCALE - float(row) * .5)
  for x in range(column-8, column+9):
   for y in range(row-6, row+7):
    var grid := Vector2i(x,y)
    if not _graph_ids.has(grid): continue
    var id: int = _graph_ids[grid]
    var p: Vector2 = _graph.get_point_position(id)
    if absf(p.x-float(pos[0])) < 0.53 and absf(p.y-float(pos[1])) < 1.10:
     _graph.set_point_disabled(id, true)
     _field_disabled.append(id)
 for room: Dictionary in _modular_rooms:
  var center: Vector2 = MODULAR_GEOMETRY.center(room)
  var low_y := floori((center.y-3.25)*SCALE/(sqrt(3.0)*0.5))-1
  var high_y := ceili((center.y+3.25)*SCALE/(sqrt(3.0)*0.5))+1
  for y in range(low_y,high_y+1):
   var low_x := floori((center.x-3.25)*SCALE-float(y)*0.5)-1
   var high_x := ceili((center.x+3.25)*SCALE-float(y)*0.5)+1
   for x in range(low_x,high_x+1):
    var grid:=Vector2i(x,y)
    if not _graph_ids.has(grid):continue
    var id:int=_graph_ids[grid]
    if MODULAR_GEOMETRY.wall_blocks(room,_graph.get_point_position(id)):
     _graph.set_point_disabled(id,true)
     _field_disabled.append(id)
 for bed: Dictionary in _modular_beds:
  var raw: Array=bed.get("sleep_plane",[])
  if raw.size()!=2:continue
  var origin:=MODULAR_GEOMETRY.plane_grid(Vector2(float(raw[0]),float(raw[1])))
  for x in range(origin.x-10,origin.x+11):
   for y in range(origin.y-10,origin.y+11):
    var grid:=Vector2i(x,y)
    if not _graph_ids.has(grid):continue
    var id:int=_graph_ids[grid]
    if MODULAR_GEOMETRY.bed_blocks(bed,_graph.get_point_position(id)):
     _graph.set_point_disabled(id,true)
     _field_disabled.append(id)
 for rect: Rect2 in _craft_rectangles:
  # Raster only the conservative local AABB, not the complete base graph.
  var first := rect.position
  var last := rect.end
  var low_y := floori(first.y*SCALE/(sqrt(3.0)*0.5))-1
  var high_y := ceili(last.y*SCALE/(sqrt(3.0)*0.5))+1
  for y in range(low_y,high_y+1):
   var low_x := floori(first.x*SCALE-float(y)*0.5)-1
   var high_x := ceili(last.x*SCALE-float(y)*0.5)+1
   for x in range(low_x,high_x+1):
    var grid:=Vector2i(x,y)
    if not _graph_ids.has(grid):continue
    var id:int=_graph_ids[grid]
    if rect.has_point(_graph.get_point_position(id)):
     _graph.set_point_disabled(id,true)
     _field_disabled.append(id)
func configure_graph(terrain) -> void:
 if terrain == _graph_terrain and _graph_revision == int(terrain.get_revision()): return
 var begin := Time.get_ticks_usec()
 _graph_terrain = terrain
 _graph_revision = int(terrain.get_revision())
 _graph.clear();_graph_ids.clear();_graph_world.clear();_field_disabled.clear()
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
 _apply_field_beds()
 _graph_build_ms = (Time.get_ticks_usec()-begin)/1000.0
func find_world_path(from_world: Vector2,to_world: Vector2) -> Array:
 if _graph_terrain == null:return []
 configure_graph(_graph_terrain)
 var from_grid: Vector2i = _graph_terrain.world_to_grid(from_world)
 var to_grid: Vector2i = _graph_terrain.world_to_grid(to_world)
 if not _graph_ids.has(from_grid) or not _graph_ids.has(to_grid):return []
 if _graph.is_point_disabled(int(_graph_ids[from_grid])) or _graph.is_point_disabled(int(_graph_ids[to_grid])):return []
 var result: Array = []
 for id in _graph.get_id_path(int(_graph_ids[from_grid]),int(_graph_ids[to_grid])):
  result.append(_graph_world[id])
 return result
func nearest_available_world(from_world: Vector2) -> Vector2:
 if _graph_terrain == null: return from_world
 configure_graph(_graph_terrain)
 var origin: Vector2i = _graph_terrain.world_to_grid(from_world)
 var best := from_world
 var distance := INF
 for x in range(origin.x-12, origin.x+13):
  for y in range(origin.y-12, origin.y+13):
   var grid := Vector2i(x,y)
   if not _graph_ids.has(grid) or _graph.is_point_disabled(int(_graph_ids[grid])): continue
   var world: Vector2 = _graph_terrain.grid_to_world(grid)
   var d := from_world.distance_squared_to(world)
   if d < distance: distance = d; best = world
 return best
func is_available_world(world: Vector2) -> bool:
 if _graph_terrain == null: return false
 configure_graph(_graph_terrain)
 var grid: Vector2i = _graph_terrain.world_to_grid(world)
 return _graph_ids.has(grid) and not _graph.is_point_disabled(int(_graph_ids[grid]))
func get_graph_diagnostics() -> Dictionary:
 return {"points":_graph.get_point_count(),"build_ms":_graph_build_ms,"terrain_revision":_graph_revision}
