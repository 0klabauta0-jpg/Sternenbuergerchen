extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_396 Mission Dropship LZ Drop Hotfix Verifier ===")
	await _test_late_homebase_direct_payload_can_keep_lz_and_drop()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_396: FAILED")
		quit(1)
	else:
		print("TASK_396: ALL PASSED")
		quit(0)


func _test_late_homebase_direct_payload_can_keep_lz_and_drop() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = await _build_two_dropship_meta_scene()
	var homebase_screen := scene.get_node("HomebaseScreen") as Control

	_drop_fireteam_on_shipcard(homebase_screen, "ft1", "dropship_alpha")
	await _finish_boarding(homebase_screen, "ft1")
	homebase_screen.call("request_mission_start", "dropship_alpha")
	await _wait_frames(8)

	_drop_fireteam_on_shipcard(homebase_screen, "ft2", "dropship_beta")
	await _finish_boarding(homebase_screen, "ft2")
	homebase_screen.call("request_mission_start", "dropship_beta")
	await _wait_frames(8)
	await _finish_all_mission_transfers(scene)
	scene.call("_show_mission")
	await _wait_frames(6)

	var active_mission: Node = scene.call("get_active_mission")
	var controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var mission_setup: Node = active_mission.get_node_or_null("MissionSetup") if active_mission != null else null
	var primary_view: Node = active_mission.get_node_or_null("Primary3DView") if active_mission != null else null
	_assert(controller != null and mission_setup != null and primary_view != null, "Active Mission exposes controller, MissionSetup and Primary3DView")
	if controller == null or mission_setup == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var selected_unit_ids := PackedStringArray(mission_setup.get("selected_team_unit_ids"))
	_assert(selected_unit_ids.has("unit_alpha") and selected_unit_ids.has("unit_bravo") and selected_unit_ids.has("unit_charlie") and selected_unit_ids.has("unit_delta"), "Late Direct Send expands the active MissionSetup friendly contract to both payloads")
	_assert(_collect_friendly_unit_ids(active_mission).has("unit_charlie") and _collect_friendly_unit_ids(active_mission).has("unit_delta"), "Late beta payload units are friendly runtime slots, not unused slots")

	var alpha_lz_world := Vector2(384.0, 224.0)
	controller.call("_on_mission_dropship_card_set_lz_pressed", "dropship_alpha")
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", alpha_lz_world))), "Alpha card LZ placement succeeds")
	await _wait_frames(4)
	controller.call("_on_mission_dropship_card_approach_pressed", "dropship_beta", "SE")
	var beta_lz_world := Vector2(672.0, 352.0)
	controller.call("_on_mission_dropship_card_set_lz_pressed", "dropship_beta")
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", beta_lz_world))), "Beta card LZ placement succeeds after Alpha")
	await _wait_frames(8)

	var lz_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(4)
	var alpha_card: Dictionary = _find_card(Array(lz_state.get("mission_drop_cards", [])), "dropship_alpha")
	var beta_card: Dictionary = _find_card(Array(lz_state.get("mission_drop_cards", [])), "dropship_beta")
	_assert(bool(alpha_card.get("has_lz_position", false)) and bool(beta_card.get("has_lz_position", false)), "Alpha and Beta keep simultaneous LZ positions")
	_assert(String(alpha_card.get("lz_label", "")).begins_with("LZ1") and String(beta_card.get("lz_label", "")).begins_with("LZ2"), "LZ labels are short and craft-distinct")

	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(render_snapshot.get("requested_lz_marker_count", 0)) >= 2 and int(render_snapshot.get("dropship_lz_label_count", 0)) >= 2, "Primary3DView renders both planned LZ markers and labels")
	var beta_approach_button := _find_mission_card_button(active_mission, "dropship_beta", "approach_se")
	var beta_drop_button := _find_mission_card_button(active_mission, "dropship_beta", "drop")
	_assert(beta_approach_button != null and bool(beta_approach_button.get_meta("mission_dropship_card_command_active", false)), "Beta approach button reports the active per-card approach")
	_assert(beta_drop_button != null and not beta_drop_button.disabled and beta_drop_button.mouse_filter == Control.MOUSE_FILTER_STOP, "Beta Drop button is enabled and clickable once its own LZ exists")

	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_alpha")
	await _wait_frames(3)
	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_beta")
	await _wait_frames(8)
	var drop_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var alpha_drop_card: Dictionary = _find_card(Array(drop_state.get("mission_drop_cards", [])), "dropship_alpha")
	var beta_drop_card: Dictionary = _find_card(Array(drop_state.get("mission_drop_cards", [])), "dropship_beta")
	var alpha_progress := _find_mission_card_progress(active_mission, "dropship_alpha")
	var beta_progress := _find_mission_card_progress(active_mission, "dropship_beta")
	_assert(String(alpha_drop_card.get("state", "")) == "inbound" and String(beta_drop_card.get("state", "")) == "inbound", "Alpha and Beta drops start independent inbound sequences")
	_assert(alpha_progress != null and alpha_progress.visible and beta_progress != null and beta_progress.visible, "Inbound Dropship cards show progress bars for both ships")

	scene.queue_free()
	await _wait_frames(2)


func _build_two_dropship_meta_scene() -> Node:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)
	var homebase_screen := scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var craft_definitions: Array = [_build_dropship_definition("dropship_alpha", "Dropship Alpha"), _build_dropship_definition("dropship_beta", "Dropship Beta")]
	var pilot_by_craft := {"dropship_alpha": "unit_echo", "dropship_beta": "unit_foxtrot"}
	var location_by_craft := {"dropship_alpha": "homebase", "dropship_beta": "homebase"}
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	scene.set("_homebase_aircraft_definitions", craft_definitions.duplicate(true))
	scene.set("_assigned_aircraft_pilot_by_craft", pilot_by_craft.duplicate(true))
	scene.set("_aircraft_location_by_craft", location_by_craft.duplicate(true))
	homebase_screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]))
	homebase_screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1", "ft2", "ft2"]),
		[
			_build_fireteam_definition("ft1", "ALPHA", PackedStringArray(["unit_alpha", "unit_bravo"])),
			_build_fireteam_definition("ft2", "BRAVO", PackedStringArray(["unit_charlie", "unit_delta"])),
		]
	)
	homebase_screen.call("set_transport_state", craft_definitions, pilot_by_craft, [], [], location_by_craft, {}, {}, [])
	await _wait_frames(3)
	return scene


func _build_dropship_definition(craft_id: String, display_name: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"craft_type": "dropship",
		"display_name": display_name,
		"texture_path": DROPSHIP_TEXTURE_PATH,
		"supports_cargo": false,
		"cargo_options": [],
	}


func _build_fireteam_definition(fireteam_id: String, label: String, unit_ids: PackedStringArray) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": label,
		"lead_unit_id": String(unit_ids[0]) if not unit_ids.is_empty() else "",
		"member_unit_ids": Array(unit_ids),
		"loadout": "medium",
		"respawn_enabled": false,
	}


func _finish_boarding(screen: Control, fireteam_id: String) -> void:
	var total_seconds: float = float(screen.call("_debug_get_homebase_fireteam_boarding_total_seconds", fireteam_id))
	screen.call("_debug_advance_homebase_direct_boarding", total_seconds + 0.2)
	await _wait_frames(3)


func _finish_all_mission_transfers(scene: Node) -> void:
	for _index in range(24):
		scene.call("_on_homebase_transport_timer_timeout")
		await _wait_frames(2)


func _drop_fireteam_on_shipcard(screen: Control, fireteam_id: String, craft_id: String) -> void:
	var target := _find_shipcard_drop_target(screen, craft_id)
	if target == null:
		return
	target.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": fireteam_id, "source_context": "fireteam_list"})


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	for node in _collect_nodes(screen):
		var control := node as Control
		if control != null \
			and bool(control.get_meta("homebase_fireteam_drop_target", false)) \
			and bool(control.get_meta("homebase_fireteam_drop_enabled", false)) \
			and String(control.get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return control
	return null


func _find_card(cards: Array, craft_id: String) -> Dictionary:
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == craft_id:
			return card
	return {}


func _find_mission_card_button(root_node: Node, craft_id: String, action_id: String) -> Button:
	for node in _collect_nodes(root_node):
		var button := node as Button
		if button != null \
			and bool(button.get_meta("mission_dropship_card_command_button", false)) \
			and String(button.get_meta("mission_dropship_craft_id", "")).strip_edges() == craft_id \
			and String(button.get_meta("mission_dropship_card_command", "")).strip_edges() == action_id:
			return button
	return null


func _find_mission_card_progress(root_node: Node, craft_id: String) -> ProgressBar:
	var card_panel := _find_mission_card_panel(root_node, craft_id)
	if card_panel == null:
		return null
	return card_panel.get_node_or_null("MarginContainer/VBox/ProgressBar") as ProgressBar


func _find_mission_card_panel(root_node: Node, craft_id: String) -> Control:
	for node in _collect_nodes(root_node):
		var control := node as Control
		if control != null \
			and bool(control.get_meta("mission_dropship_card", false)) \
			and String(control.get_meta("mission_dropship_craft_id", "")).strip_edges() == craft_id:
			return control
	return null


func _collect_friendly_unit_ids(mission_root: Node) -> Array:
	var result: Array = []
	for node in _collect_nodes(mission_root):
		if not node.has_method("get_team_id") or not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() != "team_alpha":
			continue
		var unit_id: String = String(node.call("get_unit_id")).strip_edges()
		if not unit_id.is_empty():
			result.append(unit_id)
	result.sort()
	return result


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
