extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1059 Multi-Fireteam First Contact Runtime Trace ===")
	await _test_two_deboarded_fireteams_create_confirmed_contacts()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_two_deboarded_fireteams_create_confirmed_contacts() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = await _build_two_dropship_meta_scene()
	var homebase := scene.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null and PackedStringArray(homebase.call("get_selected_unit_ids")).size() == 4, "Eight-slot fixture stages two complete Fireteams")
	if homebase == null:
		return

	homebase.call("_on_homebase_shipcard_fireteam_dropped", "ft1", "dropship_alpha")
	await _finish_boarding(homebase, "ft1")
	homebase.call("request_mission_start", "dropship_alpha")
	await _wait_frames(8)
	homebase.call("_on_homebase_shipcard_fireteam_dropped", "ft2", "dropship_beta")
	await _finish_boarding(homebase, "ft2")
	homebase.call("request_mission_start", "dropship_beta")
	await _wait_frames(8)
	await _finish_all_mission_transfers(scene)
	scene.call("_show_mission")
	await _wait_frames(6)

	var mission: Node = scene.call("get_active_mission")
	var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
	var combat_driver: Node = mission.get_node_or_null("CombatLoopDriver") if mission != null else null
	var primary_view: Node = mission.get_node_or_null("Primary3DView") if mission != null else null
	_assert(controller != null and combat_driver != null and primary_view != null, "Active mission exposes tactical, combat and terrain surfaces")
	if controller == null or combat_driver == null or primary_view == null:
		_cleanup(scene)
		return

	_deboard_two_dropships(controller, primary_view)
	await _wait_frames(4)
	var runtime_units: Array = Array(combat_driver.call("_get_friendly_combat_units"))
	_assert(_has_runtime_fireteam_members(runtime_units, "ft1", ["unit_alpha", "unit_bravo"]), "ft1 keeps both members in the combat registry after Deboarding")
	_assert(_has_runtime_fireteam_members(runtime_units, "ft2", ["unit_charlie", "unit_delta"]), "ft2 keeps both members in the combat registry after Deboarding")
	_assert(bool(controller.call("_is_fireteam_runtime_active", "ft1")) and bool(controller.call("_is_fireteam_runtime_active", "ft2")), "Both Fireteams are tactically runtime-active before first contact")

	var enemies: Array = Array(combat_driver.call("_get_enemy_combat_units"))
	var ft1_los_ready := _position_enemy_for_fireteam(controller, combat_driver, runtime_units, enemies, "ft1", 0)
	var ft2_los_ready := _position_enemy_for_fireteam(controller, combat_driver, runtime_units, enemies, "ft2", 1)
	_assert(ft1_los_ready and ft2_los_ready, "Controlled fixture finds valid LOS positions for both Fireteams")
	if ft1_los_ready and ft2_los_ready:
		for _tick in range(18):
			combat_driver.call("_update_contact_tracking")
			combat_driver.call("_advance_detection_timers")
		combat_driver.call("_update_contact_tracking")
		controller.call("_set_selected_fireteams", PackedStringArray(["ft1", "ft2"]), false)
		controller.call("refresh_contact_overlay")
		controller.call("_refresh_world_overlays")
		controller.call("_update_ui")
		await _wait_frames(4)

	var contacts: Array = Array(controller.call("get_contact_snapshot"))
	var readability: Dictionary = Dictionary(controller.call("get_mission_first_contact_readability_snapshot"))
	_assert(_contact_snapshot_has_fireteam(contacts, "ft1"), "ft1 receives a confirmed ContactTracker report from its LOS contact")
	_assert(_contact_snapshot_has_fireteam(contacts, "ft2"), "ft2 receives a confirmed ContactTracker report from its LOS contact")
	_assert(not bool(readability.get("ui_sets_gameplay_truth", true)), "First-contact readability remains a read-only presentation of combat state")
	_assert(Array(readability.get("selected_contacts", [])).size() >= 2, "Selected multi-Fireteam feedback exposes both contact contexts")

	_cleanup(scene)


func _deboard_two_dropships(controller: Node, primary_view: Node) -> void:
	controller.call("_on_mission_dropship_card_set_lz_pressed", "dropship_alpha")
	controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", Vector2(384.0, 224.0)))
	controller.call("_on_mission_dropship_card_approach_pressed", "dropship_beta", "SE")
	controller.call("_on_mission_dropship_card_set_lz_pressed", "dropship_beta")
	controller.call("_place_lz_from_screen_position", primary_view.call("world_to_screen_position", Vector2(672.0, 352.0)))
	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_alpha")
	controller.call("_on_mission_dropship_card_drop_pressed", "dropship_beta")
	for _step in range(180):
		controller.call("_update_drop_sequence", 0.2)
		var state: Dictionary = Dictionary(controller.call("get_planning_state"))
		if _all_dropship_payloads_deboarded(Array(state.get("mission_drop_cards", []))):
			return


func _position_enemy_for_fireteam(controller: Node, combat_driver: Node, runtime_units: Array, enemies: Array, fireteam_id: String, enemy_index: int) -> bool:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return false
	var friendly: Node2D = _find_fireteam_friendly(runtime_units, fireteam_id)
	var enemy: Node2D = enemies[enemy_index] as Node2D
	if friendly == null or enemy == null:
		return false
	for offset in [Vector2(48.0, 0.0), Vector2(-48.0, 0.0), Vector2(0.0, 48.0), Vector2(0.0, -48.0), Vector2(96.0, 0.0), Vector2(-96.0, 0.0), Vector2(0.0, 96.0), Vector2(0.0, -96.0)]:
		enemy.global_position = Vector2(controller.call("_snap_world_position_to_primary_tile", friendly.global_position + offset))
		if bool(combat_driver.call("_has_valid_los", friendly, enemy)):
			return true
	return false


func _find_fireteam_friendly(units: Array, fireteam_id: String) -> Node2D:
	for unit_variant in units:
		var unit := unit_variant as Node2D
		if unit != null and unit.has_method("get_fireteam_id") and String(unit.call("get_fireteam_id")).strip_edges().to_lower() == fireteam_id:
			return unit
	return null


func _has_runtime_fireteam_members(units: Array, fireteam_id: String, expected_unit_ids: Array) -> bool:
	var found: Dictionary = {}
	for unit_variant in units:
		if unit_variant == null or not unit_variant.has_method("get_unit_id") or not unit_variant.has_method("get_fireteam_id"):
			continue
		if String(unit_variant.call("get_fireteam_id")).strip_edges().to_lower() != fireteam_id:
			continue
		found[String(unit_variant.call("get_unit_id")).strip_edges()] = true
	for expected_unit_id_variant in expected_unit_ids:
		if not found.has(String(expected_unit_id_variant)):
			return false
	return true


func _contact_snapshot_has_fireteam(contacts: Array, fireteam_id: String) -> bool:
	for contact_variant in contacts:
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant)
		if String(contact.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id and String(contact.get("detection_state", "")).strip_edges().to_lower() in ["spotted", "confirmed"]:
			return true
	return false


func _all_dropship_payloads_deboarded(cards: Array) -> bool:
	var payload_card_count := 0
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges().is_empty():
			continue
		payload_card_count += 1
		if not Array(card.get("embarked_unit_ids", [])).is_empty():
			return false
	return payload_card_count >= 2


func _build_two_dropship_meta_scene() -> Node:
	var scene: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)
	var homebase := scene.get_node("HomebaseScreen") as Control
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var craft_definitions := [_build_dropship_definition("dropship_alpha", "Dropship Alpha"), _build_dropship_definition("dropship_beta", "Dropship Beta")]
	var pilots := {"dropship_alpha": "unit_echo", "dropship_beta": "unit_foxtrot"}
	var locations := {"dropship_alpha": "homebase", "dropship_beta": "homebase"}
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_all_team_units", roster.duplicate(true))
	scene.set("_homebase_aircraft_definitions", craft_definitions.duplicate(true))
	scene.set("_assigned_aircraft_pilot_by_craft", pilots.duplicate(true))
	scene.set("_aircraft_location_by_craft", locations.duplicate(true))
	homebase.call("set_mission_context", [], "res://maps/station_outpost_192x192.json", "Task 1059 Multi-Fireteam Contact", 8, "task_1059_multi_contact")
	homebase.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]))
	homebase.call("set_fireteam_context", PackedStringArray(["ft1", "ft1", "ft2", "ft2"]), [
		_build_fireteam_definition("ft1", "ALPHA", PackedStringArray(["unit_alpha", "unit_bravo"])),
		_build_fireteam_definition("ft2", "BRAVO", PackedStringArray(["unit_charlie", "unit_delta"])),
	])
	homebase.call("set_transport_state", craft_definitions, pilots, [], [], locations, {}, {}, [])
	await _wait_frames(3)
	return scene


func _build_dropship_definition(craft_id: String, display_name: String) -> Dictionary:
	return {"craft_id": craft_id, "craft_type": "dropship", "display_name": display_name, "texture_path": DROPSHIP_TEXTURE_PATH, "supports_cargo": false, "cargo_options": []}


func _build_fireteam_definition(fireteam_id: String, label: String, unit_ids: PackedStringArray) -> Dictionary:
	return {"id": fireteam_id, "label": label, "lead_unit_id": String(unit_ids[0]), "member_unit_ids": Array(unit_ids), "loadout": "medium", "respawn_enabled": false}


func _finish_boarding(homebase: Control, fireteam_id: String) -> void:
	var total_seconds: float = float(homebase.call("_debug_get_homebase_fireteam_boarding_total_seconds", fireteam_id))
	homebase.call("_debug_advance_homebase_direct_boarding", total_seconds + 0.2)
	await _wait_frames(3)


func _finish_all_mission_transfers(scene: Node) -> void:
	for _index in range(24):
		scene.call("_on_homebase_transport_timer_timeout")
		await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _cleanup(scene: Node) -> void:
	if scene != null:
		scene.queue_free()
	await _wait_frames(2)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
