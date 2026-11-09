extends SceneTree

const SCENE_PATH: String = "res://scenes/meta/explorable_homebase.tscn"
var _passed: int = 0
var _failed: int = 0
var _terminal_events: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(ResourceLoader.exists(SCENE_PATH), "Native explorable Homebase scene exists")
	if not ResourceLoader.exists(SCENE_PATH):
		_finish()
		return
	var scene: PackedScene = load(SCENE_PATH) as PackedScene
	var base: Control = scene.instantiate() as Control
	root.add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	base.call("set_active", true)
	await _frames(5)
	base.connect("terminal_open_requested", _on_terminal)
	var first: Dictionary = base.call("get_exploration_snapshot")
	var render: Dictionary = base.get("_view").call("get_render_snapshot")
	_expect(int(render.get("missing_map_asset_mapping_count", -1)) == 0, "Authored building footprints do not spawn magenta missing-asset cubes")
	_expect(bool(first.get("initialized", false)) and bool(first.get("active", false)), "Active base initializes its isolated runtime")
	_expect(String(first.get("map_path", "")).contains("homebase_frontier_exploration.json"), "Base reads its saved authored map")
	var grid_size: Vector2i = first.get("map_grid_size", Vector2i.ZERO)
	_expect(grid_size.x * grid_size.y > 480 and Array(first.get("interiors", [])).size() == 2, "Expanded base contains two authored interiors beyond the old yard")
	_expect(int(first.get("registered_unit_count", 0)) == 1, "Exactly one ephemeral Commander belongs to local UnitRegistry")
	_expect(String(first.get("movement_owner", "")) == "SimulationRoot", "Existing SimulationRoot owns avatar movement")
	_expect(not bool(first.get("owns_roster", true)) and not bool(first.get("owns_transport", true)), "Exploration owns no roster or transport truth")
	var terminals: Array = first.get("terminals", [])
	var terminal_ids: Array = []
	for terminal in terminals:
		terminal_ids.append(String(terminal.id))
	_expect(terminal_ids.has("personnel") and terminal_ids.has("team") and terminal_ids.has("flightdeck") and terminal_ids.has("mission"), "Existing meta destinations retain real world consoles")
	_expect(bool(base.call("request_terminal", "personnel")) and _terminal_events == ["personnel"], "Nearby real console emits existing personnel destination exactly once")
	_expect(bool(Dictionary(first.get("service_drone", {})).get("decorative", false)) and not bool(Dictionary(first.get("service_drone", {})).get("runtime_unit", true)), "Service drone is an authored visual without another runtime unit")
	var start: Vector2 = first.get("avatar_position", Vector2.ZERO)
	var target: Vector2 = first.get("initial_walk_target", start)
	_expect(bool(base.call("request_walk_to", target)), "Walk request is accepted through command boundary")
	await _physics_frames(90)
	var moved: Dictionary = base.call("get_exploration_snapshot")
	_expect(Vector2(moved.get("avatar_position", start)).distance_to(start) > 1.0, "Real physics ticks move the registered avatar")
	_expect(int(moved.get("simulation_ticks", 0)) > int(first.get("simulation_ticks", 0)), "Authoritative base runtime actually ticks")
	_expect(int(moved.get("movement_command_count", 0)) >= 1, "Movement is backed by a submitted command")
	_expect(Dictionary(first.get("service_drone", {})).get("model_local_rotation") != Dictionary(moved.get("service_drone", {})).get("model_local_rotation"), "Active service drone has actual temporal mesh motion")
	_expect(not bool(base.call("request_walk_to", first.get("blocked_test_position", start))), "Stored terrain blocker rejects walk request")
	_expect(not bool(base.call("request_terminal", "unknown")), "Unknown destination cannot emit meta action")
	var distant_id: String = String(first.get("distant_terminal_id", "mission"))
	_expect(not bool(base.call("request_terminal", distant_id)), "Distant console cannot activate without actual proximity")
	var identity: int = int(moved.get("avatar_instance_id", 0))
	base.call("set_active", false)
	var paused: Dictionary = base.call("get_exploration_snapshot")
	await _physics_frames(12)
	var after_pause: Dictionary = base.call("get_exploration_snapshot")
	_expect(after_pause.get("avatar_position") == paused.get("avatar_position"), "Inactive base stops only its avatar")
	_expect(after_pause.get("simulation_ticks") == paused.get("simulation_ticks"), "Inactive base stops its local simulation ticks")
	_expect(not paused.get("service_drone", {}).get("exhaust", {}).get("operating", true), "Inactive base turns decorative drone thrust off")
	_expect(not paused.get("active", true) and not paused.get("tree_paused", true), "Base lifecycle leaves the global SceneTree running")
	_expect(not bool(base.call("request_walk_to", target)), "Inactive base rejects commands")
	_expect(not bool(base.call("request_terminal", "personnel")), "Inactive base rejects terminal signals")
	base.call("set_active", true)
	await _physics_frames(3)
	_expect(int(Dictionary(base.call("get_exploration_snapshot")).get("avatar_instance_id", 0)) == identity, "Resume preserves ephemeral Commander identity")
	base.queue_free()
	await _frames(3)
	_finish()


func _on_terminal(id: String) -> void:
	_terminal_events.append(id)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		push_error("FAIL: " + message)


func _finish() -> void:
	print("EXPLORABLE_HOMEBASE: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
