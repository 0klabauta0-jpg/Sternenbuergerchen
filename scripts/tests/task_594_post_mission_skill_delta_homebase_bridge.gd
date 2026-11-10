extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/playability/playability_test_harness.gd")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const MISSION_PROGRESSION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/mission_progression_resolver.gd")

const HOMEBASE_SCENE_PATH: String = "res://scenes/meta/homebase_test_screen.tscn"
const TASK_PATH: String = "res://docs/tasks/TASK_594_post_mission_skill_delta_homebase_bridge.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HOMEBASE_SCREEN_PATH: String = "res://scripts/meta/homebase_screen.gd"
const CHARACTER_SHEET_FORMATTER_PATH: String = "res://scripts/meta/character_sheet_formatter.gd"
const META_FLOW_PATH: String = "res://scripts/meta/meta_layer_flow.gd"
const TASK_593_TEST_PATH: String = "res://scripts/tests/task_593_skill_progress_award_contract.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_594 Post Mission Skill Delta Homebase Bridge ===")
	_test_docs_and_wiring()
	await _test_homebase_skill_delta_sheet_bridge()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_594: FAILED")
		quit(1)
		return
	print("TASK_594: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var homebase_text: String = _read_text(HOMEBASE_SCREEN_PATH)
	var formatter_text: String = _read_text(CHARACTER_SHEET_FORMATTER_PATH)
	var meta_flow_text: String = _read_text(META_FLOW_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_594 task file exists")
	_assert(task_text.contains("Post Mission Skill Delta Homebase Bridge"), "TASK_594 task file names the bridge")
	_assert(status_text.contains("TASK_594 - Post Mission Skill Delta Homebase Bridge"), "Implementation status tracks TASK_594")
	_assert(status_text.contains("TASK_595 - Homebase Progression Visual Polish"), "Implementation status names TASK_595 follow-up")
	_assert(roadmap_text.contains("TASK_594 - Post Mission Skill Delta Homebase Bridge (implementiert)"), "Roadmap marks TASK_594 implemented")
	_assert(roadmap_text.contains("TASK_595 - Homebase Progression Visual Polish"), "Roadmap names TASK_595 follow-up")
	_assert(report_text.contains("TASK_594 - Post Mission Skill Delta Homebase Bridge"), "Review workbench tracks TASK_594")
	_assert(report_text.contains("TASK_595 - Homebase Progression Visual Polish"), "Review workbench names TASK_595 follow-up")
	_assert(contract_text.contains("Post-Mission-Skill-Delta-Homebase-Bridge"), "Mission feedback contract documents TASK_594")
	_assert(homebase_text.contains("get_post_mission_skill_delta_snapshot"), "Homebase exposes skill delta snapshot")
	_assert(homebase_text.contains("sternenbuergerchen.post_mission_skill_delta_homebase_bridge.v1"), "Homebase snapshot exposes stable schema")
	_assert(formatter_text.contains("Letzter Zuwachs"), "Character sheet formatter exposes Last Award row")
	_assert(formatter_text.contains("character_sheet.post_mission_skill_delta"), "Character sheet row has stable help id")
	_assert(meta_flow_text.contains("set_post_mission_skill_delta_summary"), "MetaLayerFlow forwards award summary to Homebase")
	_assert(FileAccess.file_exists(TASK_593_TEST_PATH), "TASK_593 verifier remains available")


func _test_homebase_skill_delta_sheet_bridge() -> void:
	root.size = Vector2i(1920, 1080)
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task594_homebase_delta", 18))
	var units: Array = Array(roster.get("units", [])).duplicate(true)
	_assert(units.size() >= 3, "Generated roster has enough operators for Homebase bridge")
	if units.size() < 3:
		return
	var leader: Dictionary = Dictionary(units[0]).duplicate(true)
	var member: Dictionary = Dictionary(units[1]).duplicate(true)
	leader["is_fireteam_lead"] = true
	leader["display_name"] = "Homebase Delta Lead"
	member["display_name"] = "Homebase Delta Rifle"
	units[0] = leader
	units[1] = member
	roster["units"] = units
	var leader_id: String = String(leader.get("unit_id", "task594_lead"))
	var member_id: String = String(member.get("unit_id", "task594_member"))
	var fireteam_id: String = String(leader.get("fireteam_id", "ft_delta")).strip_edges().to_lower()
	if fireteam_id.is_empty():
		fireteam_id = "ft_delta"
	var mission_result: Dictionary = _build_mission_result(leader_id, member_id, fireteam_id)
	var progression_result: Dictionary = Dictionary(MISSION_PROGRESSION_RESOLVER_SCRIPT.call("apply_mission_result", roster, mission_result))
	var updated_roster: Dictionary = Dictionary(progression_result.get("updated_roster", {}))
	var updated_units: Array = Array(updated_roster.get("units", []))
	var award_summary: Dictionary = Dictionary(progression_result.get("award_summary", {}))
	_assert(String(award_summary.get("schema", "")) == "sternenbuergerchen.skill_progress_award_summary.v1", "Resolver award summary feeds the Homebase bridge")

	var homebase: Node = HARNESS_SCRIPT.instantiate_scene(HOMEBASE_SCENE_PATH, root)
	_assert(homebase != null, "Homebase instantiates for post-mission skill delta bridge")
	if homebase == null:
		return
	await _wait_frames(3)
	homebase.call("setup_roster", updated_units, PackedStringArray([leader_id, member_id]))
	homebase.call("set_fireteam_context", PackedStringArray([fireteam_id, fireteam_id]))
	homebase.call("set_post_mission_skill_delta_summary", award_summary)
	await _wait_frames(3)

	var roster_card := _find_npc_card(homebase, leader_id)
	_assert(roster_card != null, "Awarded operator card remains reachable in Homebase")
	_assert(_open_npc_card(roster_card), "Awarded operator card opens Character Sheet")
	await _wait_frames(3)
	var snapshot: Dictionary = Dictionary(homebase.call("get_post_mission_skill_delta_snapshot"))
	var labels: PackedStringArray = _collect_label_texts(homebase)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.post_mission_skill_delta_homebase_bridge.v1", "Homebase bridge snapshot reports stable schema")
	_assert(String(snapshot.get("task_id", "")) == "TASK_594", "Homebase bridge snapshot reports task id")
	_assert(String(snapshot.get("gate", "")) == "pass", "Homebase bridge gate passes")
	_assert(String(snapshot.get("authority", "")) == "MissionProgressionResolver", "Homebase bridge keeps resolver authority visible")
	_assert(bool(snapshot.get("read_only", false)), "Homebase bridge is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Homebase bridge does not set gameplay truth")
	_assert(int(snapshot.get("unit_delta_count", 0)) >= 2, "Homebase bridge indexes unit awards")
	_assert(String(snapshot.get("focused_delta_text", "")).contains("XP +"), "Focused delta text contains XP gain")
	_assert(bool(snapshot.get("character_sheet_delta_visible", false)), "Character sheet delta visibility is reported")
	_assert(_labels_contain(labels, "Letzter Zuwachs"), "Character sheet displays Last Award row")
	_assert(_labels_contain(labels, "XP +"), "Character sheet displays XP delta text")
	_assert(_check_passed(snapshot, "read_only"), "Read-only check passes")
	homebase.queue_free()
	await _wait_frames(2)


func _build_mission_result(leader_id: String, member_id: String, fireteam_id: String) -> Dictionary:
	return {
		"mission_id": "task594_homebase_delta_bridge",
		"mission_outcome": "success",
		"result": "success",
		"winning_team_id": "team_alpha",
		"objective_captured": true,
		"win_condition_type": "objective_capture",
		"duration_seconds": 210.0,
		"selected_unit_ids": PackedStringArray([leader_id, member_id]),
		"selected_fireteam_ids": PackedStringArray([fireteam_id, fireteam_id]),
		"team_states": [
			{"unit_id": leader_id, "display_name": "Homebase Delta Lead", "fireteam_id": fireteam_id, "vital_state": "fit", "health_points": 96},
			{"unit_id": member_id, "display_name": "Homebase Delta Rifle", "fireteam_id": fireteam_id, "vital_state": "fit", "health_points": 84},
		],
		"unit_events": {
			leader_id: {"unit_id": leader_id, "objective_participation": true, "issued_orders": true, "coordinated_plan": true, "contact_report": true, "breakout_decision": true},
			member_id: {"unit_id": member_id, "fired_weapon": true, "objective_participation": true},
		},
	}


func _open_npc_card(card: Node) -> bool:
	if card == null or not card.has_signal("card_open_requested") or not card.has_method("get_unit_id") or not card.has_method("get_profile"):
		return false
	if not HARNESS_SCRIPT.has_signal_connection(card, "card_open_requested"):
		return false
	var unit_id: String = String(card.call("get_unit_id"))
	var source_context: String = String(card.call("get_source_context")) if card.has_method("get_source_context") else ""
	card.emit_signal("card_open_requested", unit_id, card.call("get_profile"), source_context)
	return true


func _find_npc_card(root_node: Node, unit_id: String) -> Node:
	for node in _collect_nodes(root_node):
		if not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_unit_id")) == unit_id:
			return node
	return null


func _collect_label_texts(root_node: Node) -> PackedStringArray:
	var result := PackedStringArray()
	for node in _collect_nodes(root_node):
		var label := node as Label
		if label != null:
			result.append(label.text)
	return result


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = []
	if root_node == null:
		return nodes
	nodes.append(root_node)
	for child in root_node.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


func _labels_contain(labels: PackedStringArray, fragment: String) -> bool:
	if fragment.strip_edges().is_empty():
		return false
	for text in labels:
		if String(text).contains(fragment):
			return true
	return false


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		if typeof(check_variant) != TYPE_DICTIONARY:
			continue
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
