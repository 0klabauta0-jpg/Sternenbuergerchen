extends SceneTree

const COMMANDER_INTENT_SCRIPT: GDScript = preload("res://scripts/command/commander_intent.gd")
const MULTI_PLAN_SCRIPT: GDScript = preload("res://scripts/tactical/multi_fireteam_plan_resolver.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const CONTRACT_PATH: String = "res://docs/dev/multi_fireteam_plan_contract.md"
const TASK_PATH: String = "res://docs/tasks/TASK_272_multi_fireteam_coordinated_area_plan.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"

const REQUIRED_DOC_SECTIONS: PackedStringArray = [
	"Purpose",
	"Authority Boundary",
	"Roles",
	"Plan Inputs",
	"Plan Output",
	"Preview and Confirmation",
	"Role Swap",
	"Phases",
	"Map and Feedback",
	"Stability Rules",
	"Non Goals",
	"Follow-Up Tasks",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_272 Multi Fireteam Coordinated Area Plan ===")
	_test_contract_doc()
	_test_two_fireteam_take_plan()
	_test_three_fireteam_support_lead_reserve_and_swap()
	_test_contact_and_blocked_path_stability()
	await _test_map_role_label_snapshot()
	await _test_mission_scene_multi_area_feedback()
	_test_no_ui_unit_mutation()
	_test_task_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_contract_doc() -> void:
	var text: String = _read_text(CONTRACT_PATH)
	_assert(not text.is_empty(), "Multi-fireteam plan contract exists")
	for section in REQUIRED_DOC_SECTIONS:
		_assert(text.contains("## %s" % section), "Contract has %s section" % section)
	for token in ["`lead`", "`support`", "`security`", "`reserve`", "`recon`", "CommanderIntent -> MultiFireteamPlanResolver -> FireteamExecutionPlan", "UI may not build individual NPC truth", "blocked_path"]:
		_assert(text.contains(token), "Contract documents %s" % token)


func _test_two_fireteam_take_plan() -> void:
	var intent = _make_intent(PackedStringArray(["blue", "gold"]), "take")
	var plan: Dictionary = Dictionary(MULTI_PLAN_SCRIPT.call("resolve_area_plan", intent, _make_two_contexts(), _make_options()))
	_assert(bool(MULTI_PLAN_SCRIPT.call("is_valid_plan", plan)), "Two-fireteam coordinated take plan validates")
	_assert(String(plan.get("status", "")) == "preview", "New coordinated plan starts as preview")
	_assert(bool(plan.get("requires_player_confirmation", false)), "Coordinated plan waits for player confirmation before GO")
	_assert(not bool(plan.get("ui_sets_unit_truth", true)), "Coordinated plan is not UI truth")
	_assert(String(plan.get("runtime_authority", "")) == "SimulationRoot", "Coordinated plan points to SimulationRoot authority")
	var assignments: Array = Array(plan.get("role_assignments", []))
	_assert(assignments.size() == 2, "Two-fireteam plan creates two role assignments")
	_assert(_role_for(assignments, "blue") == "lead", "Best assault Fireteam becomes lead")
	_assert(_role_for(assignments, "gold") == "support", "Range/disciplined Fireteam becomes support")
	_assert(_all_assignments_have_execution_plans(assignments), "Each role assignment carries a FireteamExecutionPlan snapshot")
	_assert(bool(plan.get("minimum_spacing_ok", false)), "Planned role positions obey minimum spacing")
	_assert(_min_assignment_distance(assignments) >= float(plan.get("minimum_spacing", 0.0)) - 0.01, "Assignments keep explicit spacing distance")
	_assert(String(plan.get("mission_control_text", "")).contains("PRE-GO"), "#18 plan text exposes pre-GO state")
	_assert(_lines_contain(PackedStringArray(plan.get("selected_fireteam_lines", PackedStringArray())), "BLUE LEAD"), "#17 lines expose Blue lead role")


func _test_three_fireteam_support_lead_reserve_and_swap() -> void:
	var intent = _make_intent(PackedStringArray(["blue", "gold", "med"]), "take")
	var plan: Dictionary = Dictionary(MULTI_PLAN_SCRIPT.call("resolve_area_plan", intent, _make_three_contexts(), _make_options()))
	var assignments: Array = Array(plan.get("role_assignments", []))
	_assert(assignments.size() == 3, "Three-fireteam plan creates three assignments")
	_assert(_role_for(assignments, "blue") == "lead", "Three-team plan keeps Blue as lead")
	_assert(_role_for(assignments, "gold") == "support", "Three-team plan assigns Gold support/base")
	_assert(_role_for(assignments, "med") == "reserve", "Medic-heavy team becomes reserve")
	var swapped: Dictionary = Dictionary(MULTI_PLAN_SCRIPT.call("swap_roles", plan, "blue", "med"))
	var swapped_assignments: Array = Array(swapped.get("role_assignments", []))
	_assert(_role_for(swapped_assignments, "blue") == "reserve", "Role swap can move Blue into reserve")
	_assert(_role_for(swapped_assignments, "med") == "lead", "Role swap can move medic team into lead")
	var confirmed: Dictionary = Dictionary(MULTI_PLAN_SCRIPT.call("confirm_plan", swapped))
	_assert(bool(confirmed.get("confirmed", false)), "Confirmed plan marks confirmed state")
	_assert(not bool(confirmed.get("requires_player_confirmation", true)), "Confirmed plan no longer waits for confirmation")
	_assert(String(confirmed.get("mission_control_text", "")).contains("CONFIRMED"), "#18 text reflects confirmed plan")


func _test_contact_and_blocked_path_stability() -> void:
	var intent = _make_intent(PackedStringArray(["blue", "gold", "med"]), "take")
	var contexts: Array = _make_three_contexts()
	Dictionary(contexts[0])["blocked_path"] = true
	Dictionary(contexts[1])["contact_pressure"] = 0.85
	var plan: Dictionary = Dictionary(MULTI_PLAN_SCRIPT.call("resolve_area_plan", intent, contexts, _make_options()))
	_assert(String(plan.get("status", "")) == "blocked_path", "Blocked path marks plan status without deleting plan")
	_assert(Array(plan.get("role_assignments", [])).size() == 3, "Blocked/contact plan keeps all roles visible")
	_assert(PackedStringArray(plan.get("warnings", PackedStringArray())).has("blocked_path:blue"), "Blocked path warning names the Fireteam")
	_assert(PackedStringArray(plan.get("warnings", PackedStringArray())).has("contact_stable:gold"), "Contact warning names the Fireteam")
	_assert(bool(plan.get("minimum_spacing_ok", false)), "Blocked/contact plan still preserves spacing")


func _test_map_role_label_snapshot() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task272_plan_map", Vector2i(10, 10), Vector2.ZERO, 64.0, 32.0, 3)
	var center_tile = map_data.call("get_tile_at_grid", Vector2i(5, 5))
	var center_position: Vector2 = Vector2(center_tile.world_position) if center_tile != null else Vector2.ZERO
	var intent = _make_intent(PackedStringArray(["blue", "gold", "med"]), "take", center_position)
	var plan: Dictionary = Dictionary(MULTI_PLAN_SCRIPT.call("resolve_area_plan", intent, _make_three_contexts(), _make_options(center_position)))
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"multi_fireteam_plan_dicts": [plan],
	})
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("multi_fireteam_plan_entries", []))
	_assert(int(snapshot.get("multi_fireteam_plan_visual_count", 0)) >= 3, "Mission map renders compact role markers")
	_assert(_has_map_role(entries, "lead"), "Mission map snapshot exposes lead role")
	_assert(_has_map_role(entries, "support"), "Mission map snapshot exposes support role")
	_assert(_has_map_role(entries, "reserve"), "Mission map snapshot exposes reserve role")
	_assert(_map_labels_are_compact(entries, 10), "Map role labels stay compact")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_mission_scene_multi_area_feedback() -> void:
	var scene = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node("TacticalController")
	var primary_view: Node = scene.get_node("Primary3DView")
	var objective_position: Vector2 = _get_objective_position(scene, Vector2(960.0, 960.0))
	var refs: Array = Array(controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["blue", "gold"]), objective_position + Vector2(-72.0, -72.0), objective_position + Vector2(72.0, 48.0), "take"))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("_refresh_order_visuals")
	await _wait_frames(8)
	var plans: Array = Array(controller.call("get_multi_fireteam_plan_snapshot"))
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var map_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(refs.size() == 2, "Scene creates one shared Area Order per selected Fireteam")
	_assert(plans.size() == 1, "Scene creates one shared multi-fireteam plan for same area")
	_assert(String(feedback.get("selected_order_text", "")).contains("LEAD") or String(feedback.get("selected_order_text", "")).contains("SUP"), "#17 selected text exposes coordinated roles")
	_assert(String(feedback.get("mission_control_plan_text", "")).contains("PLAN"), "#18 snapshot exposes total plan")
	_assert(int(feedback.get("multi_fireteam_plan_count", 0)) == 1, "Feedback snapshot counts coordinated plan")
	_assert(int(map_snapshot.get("multi_fireteam_plan_visual_count", 0)) >= 2, "Primary map visualizes coordinated role labels")
	scene.queue_free()
	await _wait_frames(2)


func _test_no_ui_unit_mutation() -> void:
	for path in [
		"res://scripts/tactical/multi_fireteam_plan_resolver.gd",
		"res://docs/dev/multi_fireteam_plan_contract.md",
	]:
		var text: String = _read_text(path)
		_assert(not text.contains("extends Control"), "%s is not UI code" % path)
		_assert(not text.contains("assign_unit_command"), "%s does not assign direct UnitCommands" % path)
		_assert(not text.contains("enqueue_command"), "%s does not enqueue SimulationRoot commands" % path)


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_272 is marked implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_272 checklist is complete")
	_assert(status_text.contains("### TASK_272 - Multi Fireteam Coordinated Area Plan"), "Implementation status has TASK_272 section")
	_assert(status_text.contains("multi_fireteam_plan_contract.md"), "Implementation status references plan contract")
	_assert(status_text.contains("multi_fireteam_plan_resolver.gd"), "Implementation status references plan resolver")


func _make_intent(fireteam_ids: PackedStringArray, verb: String, target_position: Vector2 = Vector2(512.0, 512.0)):
	return COMMANDER_INTENT_SCRIPT.new({
		"verb": verb,
		"coordinated_fireteam_ids": fireteam_ids,
		"target_position": target_position,
		"target_area_id": "objective_a",
		"sync_group_id": "task272_shared",
		"phase": 1,
		"tempo": "normal",
		"fire_rule": "return",
		"contact_response": "report",
		"risk": "normal",
	})


func _make_options(center_position: Vector2 = Vector2(512.0, 512.0)) -> Dictionary:
	return {
		"plan_id": "task272_plan",
		"phase": 1,
		"min_spacing": 96.0,
		"area_context": {
			"center_position": center_position,
			"tile_world_positions": [center_position, center_position + Vector2(64.0, 0.0), center_position + Vector2(0.0, 64.0)],
		},
	}


func _make_two_contexts() -> Array:
	return [
		{
			"fireteam_id": "blue",
			"display_label": "BLUE",
			"position": Vector2(240.0, 480.0),
			"leadership": 0.92,
			"discipline": 0.72,
			"cohesion": 0.82,
			"speed": 0.84,
			"accuracy": 0.62,
			"awareness": 0.66,
			"weapon_range": 0.42,
			"readiness": 1.0,
			"member_count": 4,
		},
		{
			"fireteam_id": "gold",
			"display_label": "GOLD",
			"position": Vector2(260.0, 560.0),
			"leadership": 0.62,
			"discipline": 0.9,
			"cohesion": 0.74,
			"speed": 0.54,
			"accuracy": 0.86,
			"awareness": 0.72,
			"weapon_range": 0.96,
			"readiness": 1.0,
			"member_count": 4,
		},
	]


func _make_three_contexts() -> Array:
	var contexts: Array = _make_two_contexts()
	contexts.append({
		"fireteam_id": "med",
		"display_label": "MED",
		"position": Vector2(180.0, 620.0),
		"leadership": 0.58,
		"discipline": 0.78,
		"cohesion": 0.76,
		"communication": 0.82,
		"speed": 0.48,
		"accuracy": 0.52,
		"awareness": 0.64,
		"weapon_range": 0.44,
		"readiness": 0.95,
		"member_count": 3,
		"medic_count": 2,
	})
	return contexts


func _role_for(assignments: Array, fireteam_id: String) -> String:
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		if String(assignment.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id:
			return String(assignment.get("role", ""))
	return ""


func _all_assignments_have_execution_plans(assignments: Array) -> bool:
	for assignment_variant in assignments:
		var execution_plan: Dictionary = Dictionary(Dictionary(assignment_variant).get("execution_plan", {}))
		if execution_plan.is_empty() or String(execution_plan.get("runtime_authority", "")) != "SimulationRoot":
			return false
		if String(execution_plan.get("coordination_role", "")).is_empty():
			return false
	return true


func _min_assignment_distance(assignments: Array) -> float:
	var result: float = INF
	for left_index in range(assignments.size()):
		var left_position: Vector2 = Vector2(Dictionary(assignments[left_index]).get("planned_position", Vector2.ZERO))
		for right_index in range(left_index + 1, assignments.size()):
			var right_position: Vector2 = Vector2(Dictionary(assignments[right_index]).get("planned_position", Vector2.ZERO))
			result = minf(result, left_position.distance_to(right_position))
	return result


func _lines_contain(lines: PackedStringArray, needle: String) -> bool:
	for line in lines:
		if String(line).contains(needle):
			return true
	return false


func _has_map_role(entries: Array, role: String) -> bool:
	for entry_variant in entries:
		if String(Dictionary(entry_variant).get("role", "")) == role:
			return true
	return false


func _map_labels_are_compact(entries: Array, max_length: int) -> bool:
	for entry_variant in entries:
		var label_text: String = String(Dictionary(entry_variant).get("map_label_text", ""))
		if label_text.is_empty() or label_text.length() > max_length:
			return false
	return true


func _get_objective_position(scene: Node, fallback: Vector2) -> Vector2:
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	if simulation_root != null and simulation_root.has_method("get_objective_status"):
		var objective_status = simulation_root.call("get_objective_status")
		if objective_status != null and typeof(objective_status.get("position")) == TYPE_VECTOR2:
			return Vector2(objective_status.get("position"))
	var marker := scene.get_node_or_null("ObjectivePoint") as Node2D
	if marker != null:
		return marker.global_position
	return fallback


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
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
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
