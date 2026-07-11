extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const SNAPSHOT_CONTRACT_SCRIPT := preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const SELECTED_ROW_PATH := "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow"
const MINI_HOST_PATH := "TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1110 Connected Multi-Dropship Fireteam Selection Perspective ===")
	var host_mission: Node = MISSION_SCENE.instantiate()
	var client_mission: Node = MISSION_SCENE.instantiate()
	host_mission.name = "HostMission"
	client_mission.name = "ClientMission"
	root.add_child(host_mission)
	root.add_child(client_mission)
	await _wait_frames(6)

	var host_controller: Node = host_mission.get_node("TacticalController")
	var client_controller: Node = client_mission.get_node("TacticalController")
	var host_simulation: Node = host_mission.get_node("SimulationRoot")
	var client_simulation: Node = client_mission.get_node("SimulationRoot")
	var blue_ids: Array = _unit_ids(Array(host_controller.call("_get_fireteam_units", "blue", true)))
	var gold_ids: Array = _unit_ids(Array(host_controller.call("_get_fireteam_units", "gold", true)))
	_assert(not blue_ids.is_empty() and not gold_ids.is_empty(), "Host and client fixture exposes Blue and Gold Fireteams")

	var initial_state: Dictionary = _build_state(host_controller, blue_ids, gold_ids, false)
	host_controller.call("set_planning_state", initial_state)
	client_controller.call("set_planning_state", initial_state)
	await _wait_frames(6)
	_assert(bool(client_controller.call("select_mission_dropship_fireteam", "dropship_gold", "gold")), "Client selects Gold locally before authority update")
	await _wait_frames(3)

	var host_mixed_state: Dictionary = _build_state(host_controller, blue_ids, gold_ids, true)
	host_mixed_state["selected_fireteams"] = ["blue"]
	host_mixed_state["mission_drop_craft_id"] = "dropship_blue"
	host_controller.call("set_planning_state", host_mixed_state)
	host_controller.call("_refresh_world_overlays")
	host_simulation.set("tick_counter", 1110)
	var snapshot: Dictionary = Dictionary(host_simulation.call("build_multiplayer_snapshot"))
	var dropship_snapshot: Dictionary = Dictionary(snapshot.get("dropship", {}))
	_assert(Array(dropship_snapshot.get("mission_drop_cards", [])).size() == 2, "Authority snapshot carries both Dropship cards")
	_assert(_same_ids(Array(dropship_snapshot.get("deployed_unit_ids", [])), blue_ids), "Authority snapshot carries deployed Blue IDs")
	_assert(_same_ids(Array(dropship_snapshot.get("embarked_unit_ids", [])), gold_ids), "Authority snapshot carries embarked Gold IDs")
	var metrics: Dictionary = Dictionary(SNAPSHOT_CONTRACT_SCRIPT.new().call("build_serialization_metrics", snapshot))
	_assert(int(metrics.get("transport_chunk_count", 999)) <= 16, "Two-Dropship state remains inside broad snapshot chunk budget")
	_assert(not String(metrics.get("canonical_json", "")).contains("texture_path"), "Dropship snapshot does not replicate texture paths")

	var commands_before: int = Array(client_simulation.get("command_queue")).size()
	var effects_before: int = Array(client_simulation.get("effects_queue")).size()
	var apply_result: Dictionary = Dictionary(client_simulation.call("apply_multiplayer_snapshot", snapshot))
	await _wait_frames(8)
	_assert(bool(apply_result.get("accepted", false)), "Client accepts authoritative multi-Dropship snapshot")
	_assert(String(client_controller.get("_mission_drop_craft_id")) == "dropship_gold", "Client keeps local Gold craft focus")
	_assert(Array(client_controller.get("_selected_fireteam_ids")) == ["gold"], "Client keeps local Gold Fireteam selection")
	_assert(_selected_surface_is_hint(client_mission, "gold"), "Client #17 keeps Gold Dropship hint")
	var client_mini_ids: PackedStringArray = _mini_ids(client_mission)
	_assert(client_mini_ids.has("blue") and not client_mini_ids.has("gold"), "Client shows deployed Blue on ground and embarked Gold only in Dropship")
	var client_state: Dictionary = Dictionary(client_controller.call("get_planning_state"))
	_assert(Array(client_state.get("mission_drop_cards", [])).size() == 2, "Client stores both authoritative Dropship cards")
	_assert(_same_ids(Array(client_state.get("deployed_unit_ids", [])), blue_ids), "Client converges on deployed Blue IDs")
	_assert(_same_ids(_hud_embarked_ids(client_controller), gold_ids), "Client converges on embarked Gold HUD truth")
	_assert(Array(client_simulation.get("command_queue")).size() == commands_before and Array(client_simulation.get("effects_queue")).size() == effects_before, "Snapshot apply creates no client commands or effects")
	_assert(client_controller.has_method("get_authoritative_dropship_snapshot_apply_debug_snapshot"), "Controller exposes Dropship snapshot dedupe diagnostics")
	if client_controller.has_method("get_authoritative_dropship_snapshot_apply_debug_snapshot"):
		var first_apply_debug: Dictionary = Dictionary(client_controller.call("get_authoritative_dropship_snapshot_apply_debug_snapshot"))
		var duplicate_applied: bool = bool(client_controller.call("apply_authoritative_mission_dropship_snapshot", dropship_snapshot))
		var duplicate_debug: Dictionary = Dictionary(client_controller.call("get_authoritative_dropship_snapshot_apply_debug_snapshot"))
		_assert(not duplicate_applied, "Identical Dropship snapshot is deduplicated before HUD rebuild")
		_assert(int(duplicate_debug.get("apply_count", 0)) == int(first_apply_debug.get("apply_count", 0)), "Duplicate snapshot does not increment Dropship apply count")
		_assert(int(duplicate_debug.get("dedupe_count", 0)) == int(first_apply_debug.get("dedupe_count", 0)) + 1, "Duplicate snapshot records one cheap dedupe hit")

	host_mission.queue_free()
	client_mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _build_state(controller: Node, blue_ids: Array, gold_ids: Array, mixed: bool) -> Dictionary:
	var state: Dictionary = Dictionary(controller.call("get_planning_state"))
	state["mission_drop_craft_id"] = "dropship_blue"
	state["mission_drop_state"] = "outbound" if mixed else "waiting"
	state["embarked_unit_ids"] = gold_ids.duplicate() if mixed else blue_ids + gold_ids
	state["deployed_unit_ids"] = blue_ids.duplicate() if mixed else []
	state["deployed_unit_positions"] = _positions(blue_ids, Vector2(320.0, 180.0)) if mixed else {}
	state["selected_fireteams"] = ["blue"]
	state["mission_drop_cards"] = [
		_card("dropship_blue", "Blue Lift", "blue", [] if mixed else blue_ids, "outbound" if mixed else "waiting"),
		_card("dropship_gold", "Gold Lift", "gold", gold_ids, "waiting"),
	]
	return state


func _card(craft_id: String, display_name: String, fireteam_id: String, payload: Array, state: String) -> Dictionary:
	return {
		"craft_id": craft_id,
		"display_name": display_name,
		"state": state,
		"progress": 100.0,
		"passenger_count": payload.size(),
		"embarked_unit_ids": payload.duplicate(),
		"boarded_fireteam_ids": [fireteam_id],
		"has_lz_position": true,
		"lz_position": Vector2(320.0, 180.0),
		"approach_angle": "NW",
	}


func _selected_surface_is_hint(mission: Node, fireteam_id: String) -> bool:
	var row := mission.get_node(SELECTED_ROW_PATH) as HBoxContainer
	return String(row.get_meta("selected_member_cards_fireteam_id", "")).strip_edges().to_lower() == fireteam_id \
		and row.get_child_count() == 1 and row.get_child(0) is Label \
		and String((row.get_child(0) as Label).text) == "Fireteam im Dropship."


func _mini_ids(mission: Node) -> PackedStringArray:
	var result := PackedStringArray()
	var host := mission.get_node(MINI_HOST_PATH) as VBoxContainer
	for child_variant in host.get_children():
		var child := child_variant as Control
		if child == null:
			continue
		var fireteam_id: String = String(child.get_meta("fireteam_id", "")).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			result.append(fireteam_id)
	return result


func _hud_embarked_ids(controller: Node) -> Array:
	var state: Dictionary = Dictionary(controller.call("_build_hud_embarked_unit_state"))
	var result: Array = state.keys()
	result.sort()
	return result


func _unit_ids(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			result.append(String(unit.call("get_unit_id")))
	result.sort()
	return result


func _same_ids(actual: Array, expected: Array) -> bool:
	var sorted_actual: Array = actual.duplicate()
	var sorted_expected: Array = expected.duplicate()
	sorted_actual.sort()
	sorted_expected.sort()
	return sorted_actual == sorted_expected


func _positions(unit_ids: Array, origin: Vector2) -> Dictionary:
	var result := {}
	for index in range(unit_ids.size()):
		result[String(unit_ids[index])] = origin + Vector2(float(index) * 20.0, float(index) * 10.0)
	return result


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
