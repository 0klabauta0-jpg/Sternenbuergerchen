extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const UNIT_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_runtime_status.gd")
const NPC_UNIT_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const TASK_PATH: String = "res://docs/tasks/TASK_403_runtime_animation_combat_cases.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const CONTRACT_PATH: String = "res://docs/dev/unit_facing_visual_contract.md"
const EXPECTED_RAW_ANIMATIONS: PackedStringArray = [
	"attack",
	"crouch",
	"crouchIdle",
	"crouchWalk",
	"death",
	"idle",
	"interactGround",
	"interactStanding",
	"jump",
	"kick",
	"punch",
	"racingIdle",
	"racingLeft",
	"racingRight",
	"run",
	"shoot",
	"walk",
]
const EXPECTED_COMBAT_CASES: PackedStringArray = [
	"standShoot",
	"walkShoot",
	"runShoot",
	"crouchShoot",
	"crouchWalkShoot",
	"crouchRunShoot",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_403 Runtime Animation Combat Cases ===")
	_test_posture_contract_accepts_crouch_variants()
	await _test_runtime_view_loads_imported_animations_and_combat_cases()
	_test_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_posture_contract_accepts_crouch_variants() -> void:
	var command = UNIT_COMMAND_SCRIPT.new({
		"command_type": "move_to_position",
		"target_position": Vector2(64.0, 0.0),
		"movement_posture": "crouch-walk",
		"weapon_posture": "aim",
	})
	_assert(command.is_valid(), "UnitCommand accepts crouch walk movement posture")
	_assert(String(command.movement_posture) == "crouch_walk", "UnitCommand normalizes crouch-walk")
	var status = UNIT_RUNTIME_STATUS_SCRIPT.new({
		"movement_posture": "crouch-run",
		"weapon_posture": "aimed",
	})
	_assert(status.is_valid(), "UnitRuntimeStatus accepts crouch run movement posture")
	_assert(String(status.movement_posture) == "crouch_run", "UnitRuntimeStatus normalizes crouch-run")


func _test_runtime_view_loads_imported_animations_and_combat_cases() -> void:
	var mapping: Dictionary = _load_mapping()
	_assert(Dictionary(mapping.get("animation_showcase_paths", {})).size() == EXPECTED_RAW_ANIMATIONS.size(), "Mapping still exposes the 17 imported raw NPC clips")
	_assert(Dictionary(mapping.get("animation_combat_cases", {})).size() == EXPECTED_COMBAT_CASES.size(), "Mapping still exposes six imported combat animation cases")

	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_403_runtime_animation_map", Vector2i(4, 4), Vector2.ZERO, 64.0, 32.0, 2)
	var terrain_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(terrain_view)
	terrain_view.call("configure_from_map", map_data)
	var unit: Node2D = _make_unit("task403_unit", "team_alpha", Vector2(64.0, 64.0))
	root.add_child(unit)
	unit.call("set_runtime_status", "assigned", "hold_position", 10, "fire_at_will", "task_403", 1.0, 0.0, 0.0, -1, unit.global_position, "engage", "aimed", "debug_aimed")
	terrain_view.call("set_unit_nodes", [unit])
	await _wait_frames(8)

	var proxy := _find_proxy_node_by_unit_id(terrain_view, "task403_unit") as Node3D
	var player := _find_unit_visual_animation_player(proxy)
	_assert(proxy != null, "Runtime TerrainMap3DView creates a UnitProxy for the test unit")
	_assert(player != null, "Runtime UnitProxy owns the existing UnitVisualAnimationPlayer")
	if player != null:
		for animation_id in EXPECTED_RAW_ANIMATIONS:
			_assert(player.has_animation(animation_id), "Runtime AnimationPlayer owns raw imported clip %s" % animation_id)
		for case_id in EXPECTED_COMBAT_CASES:
			_assert(player.has_animation(case_id), "Runtime AnimationPlayer owns combat case %s" % case_id)
		var walk_shoot: Animation = player.get_animation("walkShoot") if player.has_animation("walkShoot") else null
		var run_shoot: Animation = player.get_animation("runShoot") if player.has_animation("runShoot") else null
		var crouch_shoot: Animation = player.get_animation("crouchShoot") if player.has_animation("crouchShoot") else null
		_assert(walk_shoot != null and int(walk_shoot.get_meta("unit_animation_pose_track_override_count", 0)) > 0, "Runtime walkShoot bakes imported shoot upper-body tracks")
		_assert(run_shoot != null and int(run_shoot.get_meta("unit_animation_pose_track_override_count", 0)) > 0, "Runtime runShoot bakes imported shoot upper-body tracks")
		_assert(crouch_shoot != null and int(crouch_shoot.get_meta("unit_animation_pose_track_override_count", 0)) > 0, "Runtime crouchShoot bakes imported shoot upper-body tracks")
	var snapshot: Dictionary = Dictionary(terrain_view.call("get_render_snapshot"))
	var proxy_state: Dictionary = Dictionary(Dictionary(snapshot.get("unit_proxy_state_by_id", {})).get("task403_unit", {}))
	_assert(String(proxy_state.get("unit_visual_animation_name", "")) == "standShoot", "Stationary aimed unit holds the imported shoot stance without requiring a fire event")
	_assert(bool(proxy_state.get("unit_weapon_upper_body_pose_active", false)), "Stationary aimed unit keeps the imported shoot upper-body pose active")
	_assert(String(proxy_state.get("unit_posture_source", "")) == "runtime", "Held aim pose comes from runtime posture, not a fake fire event")
	_assert(int(proxy_state.get("unit_animation_raw_imported_count", 0)) >= EXPECTED_RAW_ANIMATIONS.size(), "Runtime snapshot reports imported raw animation coverage")
	_assert(int(proxy_state.get("unit_animation_combat_case_imported_count", 0)) == EXPECTED_COMBAT_CASES.size(), "Runtime snapshot reports imported combat case coverage")
	_assert(int(proxy_state.get("unit_animation_shoot_pose_track_override_count", 0)) > 0, "Runtime snapshot reports shoot pose track overrides")

	terrain_view.call("_update_unit_visual_animation", proxy, true, false, 0.016, "aimed", "engage")
	_assert(player != null and String(player.current_animation) == "walkShoot", "Moving engage+aimed unit selects walkShoot")
	terrain_view.call("_update_unit_visual_animation", proxy, true, false, 0.016, "aimed", "travel")
	_assert(player != null and String(player.current_animation) == "runShoot", "Moving travel+aimed unit selects runShoot")
	terrain_view.call("_update_unit_visual_animation", proxy, false, false, 0.016, "aimed", "crouch")
	_assert(player != null and String(player.current_animation) == "crouchShoot", "Crouch+aimed unit selects crouchShoot")
	terrain_view.call("_update_unit_visual_animation", proxy, true, false, 0.016, "aimed", "crouch_walk")
	_assert(player != null and String(player.current_animation) == "crouchWalkShoot", "Crouch walk+aimed unit selects crouchWalkShoot")
	terrain_view.call("_update_unit_visual_animation", proxy, true, false, 0.016, "aimed", "crouch_run")
	_assert(player != null and String(player.current_animation) == "crouchRunShoot", "Crouch run+aimed unit selects crouchRunShoot")

	terrain_view.queue_free()
	unit.queue_free()
	await _wait_frames(2)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("Runtime-AnimationPlayer"), "Task document records runtime animation integration scope")
	_assert(status_text.contains("### TASK_403 - Runtime-NPC-Animationen und Kampf-Cases"), "Implementation status documents TASK_403")
	_assert(contract_text.contains("animation_combat_cases"), "Facing visual contract mentions runtime combat animation cases")


func _make_unit(unit_id: String, team_id: String, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = team_id
	unit.fireteam_id = "blue" if team_id == "team_alpha" else "red"
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "rifle"
	unit.global_position = position_value
	unit._ready()
	return unit


func _find_proxy_node_by_unit_id(node: Node, unit_id: String) -> Node:
	if node == null:
		return null
	if String(node.get_meta("unit_id", "")) == unit_id:
		return node
	for child in node.get_children():
		var found: Node = _find_proxy_node_by_unit_id(child, unit_id)
		if found != null:
			return found
	return null


func _find_unit_visual_animation_player(node: Node) -> AnimationPlayer:
	if node == null:
		return null
	if node is AnimationPlayer and String(node.name) == "UnitVisualAnimationPlayer":
		return node as AnimationPlayer
	for child in node.get_children():
		var found: AnimationPlayer = _find_unit_visual_animation_player(child)
		if found != null:
			return found
	return null


func _load_mapping() -> Dictionary:
	if not ResourceLoader.exists(NPC_UNIT_VISUAL_MAPPING_PATH):
		return {}
	var file := FileAccess.open(NPC_UNIT_VISUAL_MAPPING_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
