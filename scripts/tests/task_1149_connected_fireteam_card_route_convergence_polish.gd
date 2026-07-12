extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1149 Connected Fireteam Card and Route Convergence Polish ===")
	await _test_active_movement_leads_mini_card_status()
	await _test_outbound_dropship_does_not_draw_map_crossing_vector()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_active_movement_leads_mini_card_status() -> void:
	root.size = Vector2i(1600, 900)
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)
	var controller: Node = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(520.0, 240.0))
	var go_button := scene.find_child("GoPhaseButton", true, false) as Button
	if go_button != null:
		go_button.emit_signal("pressed")
	await process_frame
	await physics_frame
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "blue"))
	var snapshot: Dictionary = _find_fireteam_snapshot(Array(controller.call("get_fireteam_status_card_snapshot")), "blue")
	var movement_text: String = String(snapshot.get("movement_text", "")).strip_edges()
	var primary_text: String = String(snapshot.get("primary_text", "")).strip_edges()
	_assert(not movement_state.is_empty(), "Blue has an authoritative active movement snapshot")
	_assert(not movement_text.is_empty() and movement_text != "-", "Mini-card snapshot translates active movement into player text")
	_assert(primary_text.begins_with(movement_text + " | "), "Visible mini-card status leads with the same active movement snapshot")
	_assert(bool(snapshot.get("ui_sets_gameplay_truth", false)) == false, "Mini-card convergence remains read-only")
	var movement_controller = controller.get("_fireteam_movement_controller")
	if movement_controller != null:
		movement_controller.call("reset_fireteam", "blue")
	var transition_snapshot: Dictionary = _find_fireteam_snapshot(Array(controller.call("get_fireteam_status_card_snapshot")), "blue")
	_assert(String(transition_snapshot.get("primary_text", "")).begins_with("MARSCHIERT | "), "Busy member runtime keeps the mini-card moving during snapshot transition")
	scene.queue_free()
	await _wait_frames(2)


func _test_outbound_dropship_does_not_draw_map_crossing_vector() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_1149_outbound_vector", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var lz_position := Vector2(192.0, 160.0)
	view.call("set_mission_drop_visual_state", {
		"has_lz_position": true,
		"lz_position": lz_position,
		"dropship_visuals": [{
			"craft_id": "dropship_gold",
			"state": "outbound",
			"dropship_visible": true,
			"dropship_position": Vector2(1800.0, 1200.0),
			"approach_vector_origin_position": Vector2(1800.0, 1200.0),
			"approach_vector_target_position": lz_position,
			"show_approach_vector": true,
			"passenger_count": 0,
			"has_lz_position": true,
			"lz_position": lz_position,
		}],
	})
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(int(snapshot.get("dropship_approach_line_count", -1)) == 0, "Outbound personnel Dropship leaves no map-crossing approach vector")
	view.queue_free()
	await _wait_frames(2)


func _find_fireteam_snapshot(entries: Array, fireteam_id: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id:
			return entry
	return {}


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
