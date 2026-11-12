extends SceneTree
const CATALOG = preload("res://scripts/terrain/terrain_marker_catalog.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
var failures := 0
var checks := 0
func _init() -> void:
 call_deferred("run")
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1
 print("PASS " if ok else "FAIL ",message)
func run() -> void:
 for name in ["satellite_crash_site","trade_outpost","fortified_outpost"]:
  var path: String = "res://maps/"+name+".json"
  var original_hash: String = FileAccess.get_sha256(path)
  var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
  var source = MAP.load_from_file(path)
  check(not source.has_load_issue(),name+" load valid")
  check(source.get_tiles().size()==131072,name+" loaded all131072 cells")
  var target: String = "user://native_ground_data_join_20261112/"+name+".json"
  check(source.save_to_file(target)==OK,name+" SaveAs")
  var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(target))
  for key in original:
   if key not in ["tiles","markers","enemy_team_configs"]: check(saved.get(key)==original[key],name+" root "+key)
  check(saved.markers.size()==original.markers.size(),name+" marker ID count")
  for id in original.markers:
   var actual_marker: Dictionary = saved.markers.get(id,{})
   var expected_marker: Dictionary = original.markers[id]
   check(not actual_marker.is_empty() and actual_marker.marker_type_id==(expected_marker.marker_type_id if CATALOG.has_type(expected_marker.marker_type_id) else "custom") and actual_marker.name==expected_marker.name and absf(actual_marker.x-expected_marker.x)<=0.501 and absf(actual_marker.y-expected_marker.y)<=0.501,name+" marker semantic/rounded position "+id)
  for id in original.enemy_team_configs: check(saved.enemy_team_configs.has(id),name+" enemy team ID "+id)
  var loaded = MAP.load_from_file(target)
  check(not loaded.has_load_issue() and loaded.get_tiles().size()==131072,name+" reload all cells")
  var index: Dictionary = {}
  for tile in loaded.get_tiles(): index[tile.grid_position]=tile
  check(index.size()==131072,name+" reload unique coordinates")
  var ramps := 0
  var mismatch := 0
  for tile in original.tiles:
   var actual = index.get(Vector2i(tile.grid_position.x,tile.grid_position.y))
   if actual == null:
    mismatch += 1
    continue
   if actual.ramp_direction>=0: ramps += 1
   if actual.height_level!=tile.height_level or actual.ramp_direction!=tile.get("ramp_direction",-1) or actual.object_type_id!=tile.get("object_type_id",""): mismatch += 1
  check(mismatch==0,name+" coordinates/heights/ramps/object IDs preserved")
  var second: String = "user://native_ground_data_join_20261112/twice_"+name+".json"
  check(loaded.save_to_file(second)==OK,name+" second SaveAs")
  var twice: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(second))
  check(twice.markers==saved.markers and twice.enemy_team_configs==saved.enemy_team_configs,name+" canonical marker/enemy normalization stable")
  print("NATIVE_GROUND_MAP ",name," cells=",index.size()," ramps=",ramps," source_sha256=",original_hash)
  check(FileAccess.get_sha256(path)==original_hash,name+" source unchanged")
 print("NATIVE_GROUND_SAVE_RELOAD checks=",checks," failures=",failures)
 quit(1 if failures else 0)
