extends SceneTree
## Content validation uses actual map/scenario parsers and hex reachability.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const SCENARIO = preload("res://scripts/mission/mission_scenario_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const GATES = preload("res://scripts/mission/mission_scenario_runtime_gates.gd")
var passed := 0
var failed := 0
func _init() -> void: call_deferred("_run")
func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print("PASS: " if value else "FAIL: ", label)
func _run() -> void:
	var jobs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/jobs.json"))
	var ids := ["satellite_recovery", "outpost_recovery", "benit_delivery", "outpost_chip_recovery", "buccaneer_rescue"]
	_check(jobs.size() >= 5 and jobs.has_all(ids), "five authored chapter-one jobs present")
	for id in ids:
		var path: String = "res://data/mission_scenarios/%s.json" % id
		_check(FileAccess.file_exists(path), "scenario exists: " + id)
		if not FileAccess.file_exists(path): continue
		var scenario = SCENARIO.load_from_file(path)
		var valid: Dictionary = scenario.validate()
		_check(bool(valid.get("valid", false)), "scenario validates: %s %s" % [id, str(valid.get("errors", []))])
		for binding: Dictionary in scenario.vertical_slice.get("interaction_points",[]):
			_check(String(binding.get("interaction_id",""))==String(binding.get("marker_id","")), "runtime interaction retains authored marker identity: %s/%s" % [id,String(binding.get("marker_id",""))])
		if id=="benit_delivery":
			var return_step: Dictionary={}
			for step: Dictionary in scenario.vertical_slice.get("flow_steps",[]):
				if String(step.step_id)=="return_to_ship": return_step=step
			_check(String(return_step.get("requires_step_id",""))=="deliver_benit", "delivery requires actual return after trader interaction")
			_check(Array(jobs.benit_delivery.required_step_ids).has("return_to_ship"), "delivery completion requires verified ship return")
		var enemies := 0
		for group in scenario.enemy_groups: enemies += Array(group.get("enemy_ids", [])).size()
		if id in ["outpost_recovery", "outpost_chip_recovery"]:
			_check(enemies == (1 if id == "outpost_recovery" else 2), "authored enemy count: " + id)
			var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
			_check(bool(Dictionary(raw.get("vertical_slice",{})).get("finite_enemy_roster",false)), "campaign outpost guards do not respawn: " + id)
			_check(String(raw.enemy_groups[0].tactics.get("weapon_id",""))==("pistol" if id=="outpost_recovery" else "smg"), "explicit supported guard weapon: " + id)
			_check(String(scenario.enemy_groups[0].tactics.get("weapon_id",""))==("pistol" if id=="outpost_recovery" else "smg"), "loaded runtime retains explicit guard weapon: " + id)
			var gates = GATES.new()
			gates.configure_from_slice(scenario.vertical_slice)
			# Je Gruppe die Zahl ihrer Wachen (der Auftrag mit Raketenwerfer hat zwei Gruppen).
			var alive: Dictionary = {}
			var down: Dictionary = {}
			for group in scenario.enemy_groups:
				alive[String(group.group_id)] = Array(group.get("enemy_ids", [])).size()
				down[String(group.group_id)] = 0
			var pending: Dictionary = gates.update({"enemy_group_fit_counts":alive})
			_check(not bool(pending.all_gates_complete) and Array(pending.completed_step_ids).is_empty(), "living guards block authored outpost gates: " + id)
			if id == "outpost_chip_recovery":
				# (i) nur die Wache mit der Maschinenpistole ausgeschaltet: Schritt NICHT erledigt, Chip bleibt gesperrt.
				var smg_only: Dictionary = alive.duplicate()
				smg_only["outpost_guards"] = 0
				var gates_smg = GATES.new()
				gates_smg.configure_from_slice(scenario.vertical_slice)
				var partial: Dictionary = gates_smg.update({"enemy_group_fit_counts":smg_only})
				_check(not Array(partial.completed_step_ids).has("clear_outpost") and not Array(partial.completed_step_ids).has("secure_outpost_chip"), "only the smg guard down: clear_outpost not done, chip stays locked")
				var rocket_only: Dictionary = alive.duplicate()
				rocket_only["outpost_guards_rocket"] = 0
				var gates_rocket = GATES.new()
				gates_rocket.configure_from_slice(scenario.vertical_slice)
				_check(not Array(gates_rocket.update({"enemy_group_fit_counts":rocket_only}).completed_step_ids).has("clear_outpost"), "only the rocket guard down: clear_outpost not done")
				var gates_unknown = GATES.new()
				gates_unknown.configure_from_slice(scenario.vertical_slice)
				_check(not Array(gates_unknown.update({"enemy_group_fit_counts":{"outpost_guards":0}}).completed_step_ids).has("clear_outpost"), "a group missing from the counts is not treated as down")
				# Szenariodaten: Hin-und-Rueck-Serialisierung und unbekannte Gruppen-ID.
				var kept := false
				for step in Dictionary(scenario.to_dict().vertical_slice).flow_steps:
					if String(step.step_id) == "clear_outpost": kept = Array(step.get("enemy_group_ids", [])) == ["outpost_guards", "outpost_guards_rocket"]
				_check(kept, "enemy_group_ids survives load and save")
				var raw_chip: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
				for flow_step in raw_chip.vertical_slice.flow_steps:
					if String(flow_step.step_id) == "clear_outpost": flow_step["enemy_group_ids"] = ["outpost_guards", "no_such_group"]
				var bad = SCENARIO.from_dict(raw_chip)
				var has_unknown := false
				for error in PackedStringArray(Dictionary(bad.validate()).get("errors", PackedStringArray())): has_unknown = has_unknown or String(error).contains("unknown group: no_such_group")
				_check(has_unknown, "unknown group id in enemy_group_ids is a validation error")
			var cleared: Dictionary = gates.update({"enemy_group_fit_counts":down})
			_check(Array(cleared.completed_step_ids).has("clear_outpost") and not bool(cleared.all_gates_complete), "defeating guards still requires physical recovery and return: " + id)
	for name in ["satellite_crash_site", "trade_outpost", "fortified_outpost"]:
		var path: String = "res://maps/%s.json" % name
		if not FileAccess.file_exists(path): _check(false, "map exists: " + name); continue
		var map = MAP.load_from_file(path)
		_check(map.get_load_issue_message().is_empty(), "map loads: " + name)
		_check(map.get_tiles().size() >= 9000, "large playable map: " + name)
		var spawn: Vector2i = _marker_grid(map, "spawn_alpha")
		var visited := _reachable(map, spawn)
		for marker in map.get_marker_ids():
			var target: Vector2i = _marker_grid(map, marker)
			_check(visited.has(target), "reachable marker %s/%s" % [name, marker])
		if name == "satellite_crash_site":
			_check(visited.has(Vector2i(27,-1)), "actual height-aware navigation can leave the M3 recruit ridge")
			_check(HEX.distance(spawn, _marker_grid(map,"satellite_data")) >= 25, "satellite requires exploration beyond landing area")
			_check(HEX.distance(_marker_grid(map,"trade_service"), _marker_grid(map,"satellite_data")) >= 25, "satellite and trader are distinct destinations")
		if name == "trade_outpost":
			_check(HEX.distance(_marker_grid(map,"trade_service"), _marker_grid(map,"recover_crate")) >= 25, "outpost and trader are spatially separate")
	var sites: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/location_resources.json"))
	for pair in [["satellite_crash", ["a_benit", "b_benit"]], ["trade_outpost", ["a_benit", "c_benit"]]]:
		var ores: Array = []
		for site in Dictionary(sites.get(pair[0], {})).values():
			if String(site.get("item_id", "")).ends_with("_benit"): ores.append(site.item_id)
		_check(ores.size() == 2 and ores.has(pair[1][0]) and ores.has(pair[1][1]), "two complementary ores at " + pair[0])
	print("CAMPAIGN_MAPS_CONTENT passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
func _marker_grid(map, id: String) -> Vector2i:
	var position: Vector2 = map.get_marker_position(id)
	var nearest := Vector2i.ZERO
	var distance := INF
	for tile in map.get_tiles():
		var candidate: float = tile.world_position.distance_squared_to(position)
		if candidate < distance: distance = candidate; nearest = tile.grid_position
	return nearest
func _reachable(map, start: Vector2i) -> Dictionary:
	var registry = REGISTRY.new()
	registry.configure_iso_grid(map.get_grid_origin(),64,32,map.get_grid_topology())
	for tile in map.get_tiles(): registry.register_tile(tile)
	var pathfinder = PATHFINDER.new()
	var visited := {start: true}
	var queue: Array[Vector2i] = [start]
	var index := 0
	while index < queue.size():
		var current := queue[index]
		index += 1
		var source = map.get_tile_at_grid(current)
		for adjacent in HEX.neighbors(current):
			if visited.has(adjacent): continue
			var tile = map.get_tile_at_grid(adjacent)
			if tile == null or not pathfinder.can_traverse_step(current,adjacent,registry): continue
			visited[adjacent] = true
			queue.append(adjacent)
	registry.free()
	return visited
