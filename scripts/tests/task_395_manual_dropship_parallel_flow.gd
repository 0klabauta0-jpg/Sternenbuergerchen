extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_395 Manual Dropship Parallel Flow Verifier ===")
	await _test_boarding_refresh_does_not_cancel_active_drag()
	await _test_homebase_direct_send_starts_transport_timer_immediately()
	await _test_mission_lz_drop_and_approach_arrow_are_per_craft()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_395: FAILED")
		quit(1)
	else:
		print("TASK_395: ALL PASSED")
		quit(0)


func _test_boarding_refresh_does_not_cancel_active_drag() -> void:
	var screen: Control = await _build_two_dropship_homebase_screen()
	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	screen.call("_debug_advance_homebase_direct_boarding", 0.5)
	await _wait_frames(2)

	var beta_target_before := _find_shipcard_drop_target(screen, "dropship_beta")
	var beta_target_id: int = beta_target_before.get_instance_id() if beta_target_before != null else 0
	screen.set_meta("debug_gui_drag_in_progress", true)
	screen.call("_debug_advance_homebase_direct_boarding", 0.5)
	await _wait_frames(2)
	var beta_target_during := _find_shipcard_drop_target(screen, "dropship_beta")
	var snapshot_during: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	_assert(beta_target_before != null and beta_target_during != null and beta_target_during.get_instance_id() == beta_target_id, "Boarding UI refresh does not rebuild shipcard targets during active GUI drag")
	_assert(bool(snapshot_during.get("boarding_refresh_deferred_for_drag", false)), "Homebase records a deferred boarding refresh while drag is active")

	screen.set_meta("debug_gui_drag_in_progress", false)
	_drop_fireteam_on_shipcard(screen, "ft2", "dropship_beta")
	screen.call("_debug_advance_homebase_direct_boarding", 0.6)
	await _wait_frames(3)
	var alpha_card := _find_homebase_payload_fireteam_card(screen, "ft1", "dropship_alpha")
	var beta_card := _find_homebase_payload_fireteam_card(screen, "ft2", "dropship_beta")
	var snapshot_after: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	var payload_by_craft: Dictionary = Dictionary(snapshot_after.get("payload_fireteam_ids_by_craft", {}))
	_assert(alpha_card != null and beta_card != null, "Second Dropship accepts its Fireteam while first Dropship is still boarding")
	_assert(float(alpha_card.get_meta("homebase_direct_payload_boarding_progress", 0.0)) > 0.0 and float(beta_card.get_meta("homebase_direct_payload_boarding_progress", 0.0)) > 0.0, "Both Dropships advance boarding progress in parallel after the deferred refresh")
	_assert(Array(payload_by_craft.get("dropship_alpha", [])).has("ft1") and Array(payload_by_craft.get("dropship_beta", [])).has("ft2"), "Parallel boarding truth stays separated per Dropship")

	screen.queue_free()
	await _wait_frames(2)


func _test_homebase_direct_send_starts_transport_timer_immediately() -> void:
	var scene: Node = await _build_two_dropship_meta_scene()
	var homebase_screen := scene.get_node("HomebaseScreen") as Control
	var transport_timer := scene.get_node_or_null("TransportTimer") as Timer

	_drop_fireteam_on_shipcard(homebase_screen, "ft1", "dropship_alpha")
	_drop_fireteam_on_shipcard(homebase_screen, "ft2", "dropship_beta")
	await _finish_boarding(homebase_screen, "ft1")
	await _finish_boarding(homebase_screen, "ft2")

	homebase_screen.call("request_mission_start", "dropship_alpha")
	await _wait_frames(6)
	var pending_after_alpha: Array = Array(scene.get("_pending_mission_craft_transfers"))
	_assert(transport_timer != null and not transport_timer.is_stopped(), "Homebase Direct Send starts the transport timer immediately")
	_assert(_has_pending_mission_transfer(pending_after_alpha, "dropship_alpha", "to_mission"), "Alpha Direct Send creates its own pending to_mission transfer")

	homebase_screen.call("request_mission_start", "dropship_beta")
	await _wait_frames(6)
	var pending_after_beta: Array = Array(scene.get("_pending_mission_craft_transfers"))
	_assert(_has_pending_mission_transfer(pending_after_beta, "dropship_alpha", "to_mission") and _has_pending_mission_transfer(pending_after_beta, "dropship_beta", "to_mission"), "Beta Direct Send starts while Alpha transfer remains active")

	scene.call("_on_homebase_transport_timer_timeout")
	await _wait_frames(4)
	var active_mission: Node = scene.call("get_active_mission")
	var controller: Node = active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state")) if controller != null else {}
	var alpha_card: Dictionary = _find_card(Array(planning_state.get("mission_drop_cards", [])), "dropship_alpha")
	var beta_card: Dictionary = _find_card(Array(planning_state.get("mission_drop_cards", [])), "dropship_beta")
	_assert(float(alpha_card.get("progress", 0.0)) > 0.0 and float(beta_card.get("progress", 0.0)) > 0.0, "Both Direct transfer progress bars advance from Homebase timer ticks without a Mission Map click")

	scene.queue_free()
	await _wait_frames(2)


func _test_mission_lz_drop_and_approach_arrow_are_per_craft() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(controller != null and primary_view != null, "Mission scene exposes controller and Primary3DView for per-craft LZ checks")
	if controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var unit_ids: Array = _collect_friendly_unit_ids(scene)
	if unit_ids.size() < 4:
		unit_ids = ["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_craft_id"] = "dropship_alpha"
	planning_state["mission_drop_state"] = "waiting"
	planning_state["drop_ship_staged"] = true
	planning_state["has_lz_position"] = false
	planning_state["lz_position"] = Vector2.ZERO
	planning_state["deployed_unit_ids"] = []
	planning_state["deployed_unit_positions"] = {}
	planning_state["mission_drop_cards"] = [
		_build_waiting_mission_card("dropship_alpha", "Dropship Alpha", unit_ids.slice(0, 2), "alpha_ft", "NW"),
		_build_waiting_mission_card("dropship_beta", "Dropship Beta", unit_ids.slice(2, 4), "beta_ft", "SE"),
	]
	controller.call("set_planning_state", planning_state)
	await _wait_frames(6)

	var beta_lz_world := Vector2(640.0, 320.0)
	controller.call("_on_mission_dropship_card_set_lz_pressed", "dropship_beta")
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", beta_lz_world))), "Beta card LZ placement succeeds through the card-bound LZ path")
	await _wait_frames(4)
	var beta_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var beta_after_lz: Dictionary = _find_card(Array(beta_state.get("mission_drop_cards", [])), "dropship_beta")
	_assert(bool(beta_after_lz.get("has_lz_position", false)), "Beta keeps its own LZ after card placement")

	var alpha_lz_world := Vector2(384.0, 224.0)
	controller.call("_on_mission_dropship_card_set_lz_pressed", "dropship_alpha")
	_assert(bool(controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", alpha_lz_world))), "Alpha card LZ placement succeeds independently after Beta")
	await _wait_frames(6)
	var alpha_beta_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var alpha_card: Dictionary = _find_card(Array(alpha_beta_state.get("mission_drop_cards", [])), "dropship_alpha")
	var beta_card: Dictionary = _find_card(Array(alpha_beta_state.get("mission_drop_cards", [])), "dropship_beta")
	_assert(bool(alpha_card.get("has_lz_position", false)) and bool(beta_card.get("has_lz_position", false)), "Alpha LZ placement does not clear Beta LZ")
	_assert(Vector2(alpha_card.get("lz_position", Vector2.ZERO)).distance_to(Vector2(beta_card.get("lz_position", Vector2.ZERO))) > 32.0, "Alpha and Beta store different per-craft LZ positions")

	var visual_entries: Array = Array(controller.call("_build_mission_dropship_visual_entries", false, Vector2.ZERO))
	var alpha_visual: Dictionary = _find_visual_entry(visual_entries, "dropship_alpha")
	var beta_visual: Dictionary = _find_visual_entry(visual_entries, "dropship_beta")
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(String(alpha_visual.get("approach_vector_shape", "")) == "wide_arrow" and String(beta_visual.get("approach_vector_shape", "")) == "wide_arrow", "Both planned Dropships export directional approach arrows")
	_assert(int(render_snapshot.get("requested_lz_marker_count", 0)) >= 2 and int(render_snapshot.get("dropship_approach_arrow_count", 0)) >= 2, "Primary3DView renders both LZs with independent approach arrows")

	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_alpha")
	await _wait_frames(3)
	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_beta")
	await _wait_frames(4)
	var parallel_sequences: Dictionary = Dictionary(controller.get("_parallel_drop_sequences_by_craft"))
	var drop_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var alpha_drop_card: Dictionary = _find_card(Array(drop_state.get("mission_drop_cards", [])), "dropship_alpha")
	var beta_drop_card: Dictionary = _find_card(Array(drop_state.get("mission_drop_cards", [])), "dropship_beta")
	_assert(parallel_sequences.has("dropship_alpha") and String(controller.get("_drop_sequence_craft_id")) == "dropship_beta", "Beta Drop starts while Alpha Drop continues as a parallel sequence")
	_assert(String(alpha_drop_card.get("state", "")) == "inbound" and String(beta_drop_card.get("state", "")) == "inbound", "Alpha and Beta Dropships keep independent inbound states")

	scene.queue_free()
	await _wait_frames(2)


func _build_two_dropship_homebase_screen() -> Control:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await _wait_frames(2)
	screen.call("set_mission_context", [], "res://maps/Ground_Mission01_32x32.json", "Task 395", 5, "task_395")
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]))
	screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1", "ft2", "ft2"]),
		[
			_build_fireteam_definition("ft1", "ALPHA", PackedStringArray(["unit_alpha", "unit_bravo"])),
			_build_fireteam_definition("ft2", "BRAVO", PackedStringArray(["unit_charlie", "unit_delta"])),
		]
	)
	screen.call("set_transport_state", _build_two_dropship_definitions(), {"dropship_alpha": "unit_echo", "dropship_beta": "unit_foxtrot"}, [], [], {"dropship_alpha": "homebase", "dropship_beta": "homebase"}, {}, {}, [])
	await _wait_frames(3)
	return screen


func _build_two_dropship_meta_scene() -> Node:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)
	var homebase_screen := scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var craft_definitions: Array = _build_two_dropship_definitions()
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


func _build_two_dropship_definitions() -> Array:
	return [_build_dropship_definition("dropship_alpha", "Dropship Alpha"), _build_dropship_definition("dropship_beta", "Dropship Beta")]


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


func _build_waiting_mission_card(craft_id: String, display_name: String, unit_ids: Array, fireteam_id: String, approach_angle: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"display_name": display_name,
		"state": "waiting",
		"progress": 100.0,
		"embarked_unit_ids": unit_ids.duplicate(),
		"boarded_fireteam_ids": [fireteam_id],
		"queued_fireteam_ids": [fireteam_id],
		"passenger_count": unit_ids.size(),
		"approach_angle": approach_angle,
		"drop_ship_staged": true,
	}


func _finish_boarding(screen: Control, fireteam_id: String) -> void:
	var total_seconds: float = float(screen.call("_debug_get_homebase_fireteam_boarding_total_seconds", fireteam_id))
	screen.call("_debug_advance_homebase_direct_boarding", total_seconds + 0.2)
	await _wait_frames(3)


func _drop_fireteam_on_shipcard(screen: Control, fireteam_id: String, craft_id: String) -> void:
	var target := _find_shipcard_drop_target(screen, craft_id)
	if target == null:
		return
	target.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": fireteam_id, "source_context": "fireteam_list"})


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	if screen == null:
		return null
	for node in _collect_nodes(screen):
		var control := node as Control
		if control != null \
			and bool(control.get_meta("homebase_fireteam_drop_target", false)) \
			and bool(control.get_meta("homebase_fireteam_drop_enabled", false)) \
			and String(control.get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return control
	return null


func _find_homebase_payload_fireteam_card(screen: Control, fireteam_id: String, craft_id: String) -> Control:
	if screen == null:
		return null
	for node in _collect_nodes(screen):
		var control := node as Control
		if control != null \
			and bool(control.get_meta("homebase_shipcard_payload_fireteam_card", false)) \
			and String(control.get_meta("fireteam_id", "")).strip_edges() == fireteam_id \
			and String(control.get_meta("craft_id", "")).strip_edges() == craft_id:
			return control
	return null


func _has_pending_mission_transfer(transfers: Array, craft_id: String, phase: String) -> bool:
	for transfer_variant in transfers:
		if typeof(transfer_variant) != TYPE_DICTIONARY:
			continue
		var transfer: Dictionary = Dictionary(transfer_variant)
		if String(transfer.get("craft_id", "")).strip_edges() == craft_id and String(transfer.get("phase", "")).strip_edges() == phase:
			return true
	return false


func _find_card(cards: Array, craft_id: String) -> Dictionary:
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == craft_id:
			return card
	return {}


func _find_visual_entry(entries: Array, craft_id: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == craft_id:
			return entry
	return {}


func _collect_friendly_unit_ids(mission_root: Node) -> Array:
	var result: Array = []
	if mission_root == null:
		return result
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
