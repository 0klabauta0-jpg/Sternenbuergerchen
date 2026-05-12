extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_343 Homebase Direct Mission Prep FOB Bypass V1 ===")
	await _test_homebase_direct_prep_handoff_without_fob_visit()
	await _test_homebase_character_sheet_popup()
	_test_task_documents_updated()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_homebase_direct_prep_handoff_without_fob_visit() -> void:
	var scene := META_LAYER_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(6)
	_seed_meta_layer(scene)
	scene.call("_refresh_homebase_screen")
	await _wait_frames(4)

	var homebase: Control = scene.get_node("HomebaseScreen")
	var fob: Control = scene.get_node("FOBScreen")
	scene.call("_on_homebase_selection_changed", PackedStringArray(["unit_alpha", "unit_bravo"]))
	scene.call("_refresh_homebase_screen")
	await _wait_frames(3)

	homebase.call("set_direct_member_loadout_for_test", "unit_alpha", "heavy", "rocket_launcher", "none")
	await _wait_frames(3)
	var prep_snapshot: Dictionary = Dictionary(homebase.call("get_direct_mission_prep_snapshot"))
	_assert(bool(prep_snapshot.get("homebase_direct_mission_prep", false)), "Homebase exposes direct mission prep snapshot")
	_assert(bool(prep_snapshot.get("loadout_visible", false)), "Homebase direct prep shows editable loadout rows")
	_assert(Array(prep_snapshot.get("loadout_entries", [])).size() == 2, "Homebase direct prep has one loadout entry per staged operator")
	_assert(PackedStringArray(prep_snapshot.get("boardable_craft_ids", PackedStringArray())).has("dropship_home"), "Homebase dropship can board the staged direct team")

	homebase.call("request_direct_dropship_board_for_test", "dropship_home")
	await _wait_frames(8)
	var direct_snapshot: Dictionary = Dictionary(scene.call("get_homebase_direct_mission_prep_snapshot"))
	var payload_by_craft: Dictionary = Dictionary(direct_snapshot.get("payload_by_craft", {}))
	var payload: Dictionary = Dictionary(payload_by_craft.get("dropship_home", {}))
	var mission_drop_state: Dictionary = Dictionary(direct_snapshot.get("mission_drop_state", {}))
	_assert(bool(direct_snapshot.get("can_start_without_fob", false)), "Homebase direct payload can start without visiting FOB")
	_assert(bool(payload.get("uses_fob_payload_contract", false)), "Homebase payload declares the shared FOB mission-drop contract")
	_assert(Array(payload.get("unit_ids", [])).has("unit_alpha") and Array(payload.get("unit_ids", [])).has("unit_bravo"), "Homebase direct payload keeps boarded operators")
	_assert(String(Dictionary(Dictionary(payload.get("member_loadouts", {})).get("unit_alpha", {})).get("weapon_1", "")) == "rocket_launcher", "Homebase direct loadout is carried into payload")
	_assert(bool(mission_drop_state.get("drop_ship_staged", false)) and String(mission_drop_state.get("mission_drop_state", "")) == "waiting", "Mission drop state is staged as waiting payload")
	_assert(Array(mission_drop_state.get("embarked_unit_ids", [])).has("unit_alpha"), "Mission drop state carries embarked unit ids")
	_assert(not bool(direct_snapshot.get("ui_sets_gameplay_truth", true)), "Direct prep snapshot keeps UI out of gameplay truth")

	var fob_definitions: Array = Array(fob.call("get_fireteam_definitions"))
	var fob_loadout: Dictionary = _find_member_loadout(fob_definitions, "unit_alpha")
	_assert(String(fob_loadout.get("weapon_1", "")) == "rocket_launcher", "Hidden FOB state receives the same member loadout shape")

	var start_button := homebase.get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button
	_assert(start_button != null and not start_button.disabled, "Homebase Start is enabled by direct dropship payload")
	homebase.call("request_mission_start")
	await _wait_frames(12)
	var active_mission = scene.call("get_active_mission")
	_assert(active_mission != null, "Homebase direct start creates the live mission")
	if active_mission != null:
		var setup = active_mission.get_node_or_null("MissionSetup")
		_assert(setup != null and PackedStringArray(setup.get("selected_team_unit_ids")).has("unit_alpha"), "MissionSetup receives direct Homebase selected units")
		var mission_loadouts: Dictionary = Dictionary(setup.get("member_loadouts"))
		_assert(String(Dictionary(mission_loadouts.get("unit_alpha", {})).get("weapon_1", "")) == "rocket_launcher", "MissionSetup receives direct Homebase loadout")

	scene.queue_free()
	await _wait_frames(3)


func _test_homebase_character_sheet_popup() -> void:
	var scene := META_LAYER_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(6)
	_seed_meta_layer(scene)
	scene.call("_refresh_homebase_screen")
	await _wait_frames(3)

	var homebase: Control = scene.get_node("HomebaseScreen")
	homebase.call("open_character_sheet_popup_for_unit", "unit_alpha")
	await _wait_frames(3)
	var popup_snapshot: Dictionary = Dictionary(homebase.call("get_character_sheet_popup_snapshot"))
	_assert(bool(popup_snapshot.get("open", false)), "Homebase double-click path can open Character Sheet popup")
	_assert(bool(popup_snapshot.get("uses_existing_character_sheet_view", false)), "Character Sheet popup uses existing CharacterSheetView")
	_assert(int(popup_snapshot.get("content_child_count", 0)) > 0, "Character Sheet popup renders sheet content")
	homebase.call("close_character_sheet_popup")
	await _wait_frames(2)
	popup_snapshot = Dictionary(homebase.call("get_character_sheet_popup_snapshot"))
	_assert(not bool(popup_snapshot.get("open", true)), "Character Sheet popup can close again")

	scene.queue_free()
	await _wait_frames(3)


func _test_task_documents_updated() -> void:
	var task_doc: String = _read_text("res://docs/tasks/TASK_343_homebase_direct_mission_prep_fob_bypass_v1.md")
	var status_doc: String = _read_text("res://docs/IMPLEMENTATION_STATUS.md")
	var roadmap_doc: String = _read_text("res://docs/TASK_ROADMAP.md")
	_assert(task_doc.contains("## Status: IMPLEMENTIERT"), "TASK_343 task document status is implemented")
	_assert(not task_doc.contains("- [ ]"), "TASK_343 checklist has no unchecked acceptance or local checks")
	_assert(status_doc.contains("TASK_343 - Homebase Direct Mission Prep FOB Bypass V1") and status_doc.contains("Status: implementiert im Arbeitsstand"), "Implementation status records TASK_343")
	_assert(roadmap_doc.contains("TASK_343 - Homebase Direct Mission Prep FOB Bypass V1 (implementiert im Arbeitsstand)"), "Roadmap records TASK_343 as implemented")


func _seed_meta_layer(scene: Node) -> void:
	var roster: Array = [
		{
			"unit_id": "unit_alpha",
			"display_name": "Anja Voss",
			"role_name": "FTL",
			"skill_accuracy": 0.72,
			"skill_speed": 0.65,
			"skill_leadership": 0.81,
			"skill_toughness": 0.63,
		},
		{
			"unit_id": "unit_bravo",
			"display_name": "Milo Kern",
			"role_name": "Medic",
			"skill_accuracy": 0.56,
			"skill_speed": 0.61,
			"skill_leadership": 0.44,
			"skill_toughness": 0.70,
		},
		{
			"unit_id": "unit_pilot",
			"display_name": "Rin Pilot",
			"role_name": "Pilot",
			"skill_accuracy": 0.50,
			"skill_speed": 0.59,
			"skill_leadership": 0.48,
			"skill_toughness": 0.57,
		},
	]
	scene.set("_all_team_units", roster.duplicate(true))
	scene.set("_available_team_units", roster.duplicate(true))
	scene.set("_homebase_staged_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo"]))
	scene.set("_selected_unit_ids", PackedStringArray())
	scene.set("_selected_fireteam_ids", PackedStringArray())
	scene.set("_homebase_aircraft_definitions", [
		{
			"craft_id": "dropship_home",
			"craft_type": "dropship",
			"display_name": "Dropship Home",
			"summary": "Direct mission prep test dropship.",
			"texture_path": "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png",
			"supports_cargo": false,
			"cargo_options": [],
		}
	])
	scene.set("_assigned_aircraft_pilot_by_craft", {"dropship_home": "unit_pilot"})
	scene.set("_aircraft_location_by_craft", {"dropship_home": "homebase"})
	scene.set("_homebase_direct_member_loadouts", {})
	scene.set("_homebase_direct_payload_by_craft", {})
	scene.set("_homebase_direct_launch_ready_craft_id", "")


func _find_member_loadout(fireteam_definitions: Array, unit_id: String) -> Dictionary:
	for definition_variant in fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		var member_loadouts: Dictionary = definition.get("member_loadouts", {}) if typeof(definition.get("member_loadouts", {})) == TYPE_DICTIONARY else {}
		if member_loadouts.has(unit_id) and typeof(member_loadouts.get(unit_id)) == TYPE_DICTIONARY:
			return Dictionary(member_loadouts.get(unit_id)).duplicate(true)
	return {}


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
