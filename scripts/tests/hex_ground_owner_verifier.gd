extends SceneTree

const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const SIM = preload("res://scripts/core/simulation_root.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
var passed := 0
var failed := 0

class DeniedSimulation extends SimulationRoot:
	var deny := false
	func _should_skip_local_tick_processing() -> bool:
		return deny

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		print("FAIL: ", label)

func _batch(entries: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.assign(entries)
	return result

func _write_map(suffix: String, extra: Dictionary) -> RefCounted:
	var payload := {"map_name":"owner_fixture", "grid_topology":"hex_axial_v1",
		"grid_size":{"x":2,"y":1}, "tiles":[], "terrain_height_rules":"explicit_hex_ramps_v1"}
	payload.merge(extra, true)
	var path := "user://owner_%s.json" % suffix
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()
	return MAP.load_from_file(path)

func _run() -> void:
	var sim = SIM.new()
	root.add_child(sim)
	var map = MAP.new()
	_check(map.has_method("get_tactical_grid_rules") and map.has_method("set_tactical_grid_rules")
		and sim.has_method("configure_hex_ground_runtime") and sim.has_method("get_hex_unit_state"),
		"versioned MapData and SimulationRoot owner APIs exist")
	if failed > 0:
		sim.free()
		_finish()
		return
	var terrain = REGISTRY.new()
	terrain.configure_iso_grid(Vector2.ZERO,64.0,32.0,"hex_axial_v1")
	terrain.register_tile(TILE.new({"tile_id":"ramp","grid_position":Vector2i.ZERO,
		"height_level":2,"ramp_direction":0,"explicit_hex_ramps":true,"walkable":true}))
	var legacy = _write_map("legacy",{})
	_check(not legacy.has_load_issue() and legacy.get_tactical_grid_rules().is_empty(),"missing flag remains legacy")
	_check(sim.configure_hex_ground_runtime(legacy,terrain).ok and not sim.is_hex_ground_runtime_active(),"legacy does not activate ground runtime")
	_check(not sim.admit_hex_ground_units(_batch([{"unit_id":"a","grid":Vector2i.ZERO}])).ok,"inactive owner rejects admission")
	for bad in [{"tactical_grid_rules":"hex_tactical_v2"}, {"tactical_grid_rules":null},
		{"tactical_grid_rules":7}, {"tactical_grid_rules":"hex_tactical_v1","grid_topology":"square8"}]:
		var invalid = _write_map("invalid",bad)
		_check(invalid.has_load_issue() and not invalid.get_load_issue_message().is_empty(),"invalid tactical metadata reports load issue")
		_check(not sim.configure_hex_ground_runtime(invalid,terrain).ok,"invalid map cannot configure owner")
		invalid.set_tactical_grid_rules("")
		_check(invalid.has_load_issue() and invalid.save_to_file("user://aborted_save.json")==ERR_INVALID_DATA,
			"aborted load remains invalid after changing its version flag")
	var active = _write_map("active",{"tactical_grid_rules":"hex_tactical_v1","regional_terrain_version":3})
	_check(not active.has_load_issue() and is_equal_approx(active.get_regional_height_step(),0.75),"regional v3 compatibility preserved")
	_check(active.save_to_file("user://owner_roundtrip.json")==OK,"flagged map saved")
	var loaded = MAP.load_from_file("user://owner_roundtrip.json")
	_check(loaded.get_tactical_grid_rules()=="hex_tactical_v1" and loaded.get_terrain_height_rules()=="explicit_hex_ramps_v1","tactical and ramp metadata roundtrip")
	_check(sim.configure_hex_ground_runtime(loaded,terrain).ok and sim.is_hex_ground_runtime_active(),"explicit valid context activates owner")
	_check(sim.admit_hex_ground_units(_batch([{"unit_id":"a","grid":Vector2i.ZERO,"facing_dir":2}])).ok,"owner admits exclusive placement")
	_check(sim.get_hex_unit_state("a").stand_height_steps2==5,"owner reads precise ramp stand height")
	var before: Dictionary = sim.get_hex_ground_planning_snapshot()
	sim.tick_counter = 17
	_check(sim.get_hex_ground_planning_snapshot().current_tick==17,"planning snapshot reads current owner tick")
	before = sim.get_hex_ground_planning_snapshot()
	_check(not sim.configure_hex_ground_runtime(null,terrain).ok and sim.get_hex_ground_planning_snapshot()==before,"null map preserves active context")
	for empty_map in [MAP.new(), MAP.load_from_file("user://missing_map.json")]:
		_check(not sim.configure_hex_ground_runtime(empty_map,terrain).ok and sim.get_hex_ground_planning_snapshot()==before,
			"empty or missing legacy map cannot clear active context")
	if failed > 0:
		sim.free()
		terrain.free()
		_finish()
		return
	var invalid = _write_map("future",{"tactical_grid_rules":"future"})
	_check(not sim.configure_hex_ground_runtime(invalid,terrain).ok and sim.get_hex_ground_planning_snapshot()==before,"failed configure preserves active context")
	var square = REGISTRY.new()
	square.configure_iso_grid(Vector2.ZERO,64.0,32.0,"square8")
	_check(not sim.configure_hex_ground_runtime(loaded,square).ok and sim.get_hex_ground_planning_snapshot()==before,"mismatched registry preserves active context")
	var copy: Dictionary = sim.get_hex_unit_state("a")
	copy.grid=Vector2i(99,99)
	_check(sim.get_hex_unit_state("a").grid==Vector2i.ZERO and sim.get_hex_unit_state("unknown").is_empty(),"owner read cannot mutate state or create IDs")
	sim.release_hex_ground_unit("a","removed")
	_check(sim.get_hex_unit_state("a").is_empty(),"owner releases placement")
	loaded.set_tactical_grid_rules("")
	_check(not loaded.has_load_issue() and sim.configure_hex_ground_runtime(loaded,terrain).ok and not sim.is_hex_ground_runtime_active(),"removing opt-in cleanly selects legacy")
	loaded.set_tactical_grid_rules("future")
	_check(loaded.has_load_issue(),"setter cannot silently accept unknown version")
	_check(loaded.save_to_file("user://invalid_save.json")==ERR_INVALID_DATA and not FileAccess.file_exists("user://invalid_save.json"),"invalid tactical metadata cannot be saved")
	loaded.set_tactical_grid_rules("hex_tactical_v1")
	_check(not loaded.has_load_issue(),"valid setter repairs tactical metadata issue")
	var denied := DeniedSimulation.new()
	root.add_child(denied)
	_check(denied.configure_hex_ground_runtime(loaded,terrain).ok and denied.admit_hex_ground_units(_batch([{"unit_id":"a","grid":Vector2i.ZERO}])).ok,"authority fixture starts with valid owner state")
	var denied_before := denied.get_hex_ground_planning_snapshot()
	denied.deny = true
	_check(not denied.configure_hex_ground_runtime(legacy,terrain).ok and not denied.admit_hex_ground_units(_batch([])).ok,"authority policy rejects configuration and admission")
	denied.release_hex_ground_unit("a","denied")
	_check(denied.get_hex_ground_planning_snapshot()==denied_before,"authority policy rejects release without mutation")
	denied.free()
	var square_legacy = _write_map("square_legacy",{"grid_topology":"square8"})
	_check(not square_legacy.has_load_issue(),"square map without tactical flag remains valid")
	square_legacy.set_tactical_grid_rules("hex_tactical_v1")
	_check(square_legacy.has_load_issue(),"setter enforces hex topology too")
	square.free()
	terrain.free()
	sim.free()
	_finish()

func _finish() -> void:
	print("RESULTS: %d passed, %d failed" % [passed,failed])
	if failed==0:
		print("HEX_GROUND_OWNER_PASS")
	quit(0 if failed==0 else 1)
