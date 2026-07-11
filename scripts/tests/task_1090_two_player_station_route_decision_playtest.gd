extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1090 Two-Player Station Route Decision Playtest ===")
	await _test_client_bravo_local_command_context()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_client_bravo_local_command_context() -> void:
	root.size = Vector2i(1920, 1080)
	var mission := MISSION_SCENE.instantiate()
	root.add_child(mission)
	await _wait_frames(12)
	var controller := mission.get_node_or_null("TacticalController")
	var mission_setup := mission.get_node_or_null("MissionSetup")
	_assert(controller != null, "Mission exposes TacticalController")
	_assert(mission_setup != null, "Mission exposes MissionSetup")
	if controller == null or mission_setup == null:
		return
	_assert(controller.has_method("get_local_command_team_id"), "Controller exposes local command team resolver")
	if not controller.has_method("get_local_command_team_id"):
		mission.queue_free()
		await _wait_frames(2)
		return
	var session: Dictionary = Dictionary(controller.call("build_review_session_identity_snapshot"))
	var local_team_id: String = String(controller.call("get_local_command_team_id"))
	var local_units: Array = Array(controller.call("_get_all_friendly_units", true))
	var opposing_units: Array = Array(controller.call("_get_all_enemy_units", true))
	var fireteam_ids: PackedStringArray = PackedStringArray(controller.call("_get_available_fireteam_ids"))
	var selected_fireteam_ids: PackedStringArray = PackedStringArray(controller.call("get_selected_fireteam_ids"))
	var interaction_context: Dictionary = Dictionary(controller.call("_build_mission_interaction_runtime_use_context_for_readability"))
	var fog_snapshot: Dictionary = Dictionary(mission_setup.call("get_fog_of_war_runtime_snapshot"))
	var dropship_visual_entries: Array = Array(controller.call("_build_mission_dropship_visual_entries", true, Vector2(96.0, 96.0)))

	_assert(String(session.get("badge_text", "")) == "CLIENT P2 BRAVO", "Client session identity is P2 BRAVO")
	_assert(local_team_id == "team_bravo", "Local command team resolves to Bravo")
	_assert(String(mission_setup.get("team_id")) == "team_alpha", "Scenario bootstrap ownership remains authoritative and independent of the local view")
	_assert(String(fog_snapshot.get("team_id", "")) == "team_bravo", "Fog-of-war perspective resolves to local Bravo team")
	_assert(int(fog_snapshot.get("observer_count", 0)) > 0, "Fog-of-war keeps local observers when legacy 2D visuals are hidden by the 3D view")
	_assert(not local_units.is_empty(), "Bravo client exposes local controllable units")
	_assert(_all_units_match_team(local_units, "team_bravo"), "Local controllable units belong to Bravo")
	_assert(_all_units_exclude_team(opposing_units, "team_bravo"), "Opposing unit view excludes Bravo")
	_assert(fireteam_ids.has("bravo_station_guard") and fireteam_ids.has("bravo_air_defense"), "Bravo client exposes both scenario Fireteams")
	_assert(not selected_fireteam_ids.is_empty() and selected_fireteam_ids == fireteam_ids, "Bravo client initializes its local Fireteam selection once")
	_assert(String(interaction_context.get("current_team_id", "")) == "team_bravo", "Interaction readability uses local Bravo team")
	_assert(_all_position_entries_match_team(Array(interaction_context.get("fireteam_positions", [])), "team_bravo"), "Interaction Fireteam positions use Bravo team")
	_assert(_all_position_entries_match_team(dropship_visual_entries, "team_bravo"), "Mission Dropship visuals use local Bravo perspective")

	mission.queue_free()
	await _wait_frames(2)


func _all_units_match_team(units: Array, team_id: String) -> bool:
	for unit in units:
		if unit == null or not unit.has_method("get_team_id") or String(unit.call("get_team_id")) != team_id:
			return false
	return true


func _all_units_exclude_team(units: Array, team_id: String) -> bool:
	for unit in units:
		if unit != null and unit.has_method("get_team_id") and String(unit.call("get_team_id")) == team_id:
			return false
	return true


func _all_position_entries_match_team(entries: Array, team_id: String) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		if String(Dictionary(entry_variant).get("team_id", "")) != team_id:
			return false
	return true


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
