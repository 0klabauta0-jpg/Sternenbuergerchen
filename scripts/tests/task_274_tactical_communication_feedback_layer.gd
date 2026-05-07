extends SceneTree

const EVENT_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_event.gd")
const RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_resolver.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const COPY_PATH: String = "res://data/tactical_communication_copy.json"
const TASK_PATH: String = "res://docs/tasks/TASK_274_tactical_communication_feedback_layer.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_274 Tactical Communication Feedback Layer ===")
	_test_contract_files_and_copy_catalog()
	_test_event_snapshot_contract()
	_test_priority_and_cooldown_rules()
	_test_ftl_skill_precision_without_hidden_truth()
	_test_multi_fireteam_plan_event_generation()
	await _test_map_marker_visual_snapshot()
	await _test_mission_scene_feedback_layer()
	_test_no_ui_truth_mutation()
	_test_task_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_contract_files_and_copy_catalog() -> void:
	_assert(FileAccess.file_exists("res://scripts/tactical/tactical_communication_event.gd"), "Tactical communication event file exists")
	_assert(FileAccess.file_exists("res://scripts/tactical/tactical_communication_resolver.gd"), "Tactical communication resolver file exists")
	var copy_catalog: Dictionary = _read_json(COPY_PATH)
	_assert(not copy_catalog.is_empty(), "Communication copy catalog is valid JSON")
	var events: Dictionary = Dictionary(copy_catalog.get("events", {}))
	for event_type in [
		EVENT_SCRIPT.EVENT_ORDER_RECEIVED,
		EVENT_SCRIPT.EVENT_PLAN_ROLE_ASSIGNED,
		EVENT_SCRIPT.EVENT_PHASE_STARTED,
		EVENT_SCRIPT.EVENT_PHASE_COMPLETED,
		EVENT_SCRIPT.EVENT_CONTACT_REPORT,
		EVENT_SCRIPT.EVENT_BREAKOUT_ADAPTATION,
		EVENT_SCRIPT.EVENT_CANNOT_EXECUTE,
		EVENT_SCRIPT.EVENT_NEEDS_ORDERS,
		EVENT_SCRIPT.EVENT_OBJECTIVE_PROGRESS,
		EVENT_SCRIPT.EVENT_OBJECTIVE_COMPLETE,
		EVENT_SCRIPT.EVENT_AIR_ASSET_THREATENED,
		EVENT_SCRIPT.EVENT_AIR_ASSET_DESTROYED,
	]:
		_assert(events.has(event_type), "Copy catalog covers %s" % event_type)


func _test_event_snapshot_contract() -> void:
	var event: Dictionary = Dictionary(RESOLVER_SCRIPT.call("build_event", EVENT_SCRIPT.EVENT_PLAN_ROLE_ASSIGNED, {
		"plan_id": "task274_plan",
		"fireteam_id": "blue",
		"display_label": "Blue",
		"role": "lead",
		"role_label": "LEAD",
		"step": "take_area",
		"phase": 1,
		"planned_position": Vector2(512.0, 512.0),
	}, {"now_msec": 1000}))
	_assert(String(event.get("event_id", "")).contains("task274_plan"), "Event ID is stable and plan scoped")
	_assert(String(event.get("fireteam_id", "")) == "blue", "Event snapshot carries Fireteam ID")
	_assert(int(event.get("priority", 0)) == EVENT_SCRIPT.PRIORITY_NORMAL, "Role event has normal priority")
	_assert(PackedStringArray(event.get("channels", PackedStringArray())).has(EVENT_SCRIPT.CHANNEL_SELECTED_FIRETEAM), "Event reaches #17")
	_assert(PackedStringArray(event.get("channels", PackedStringArray())).has(EVENT_SCRIPT.CHANNEL_MISSION_CONTROL), "Event reaches #18")
	_assert(PackedStringArray(event.get("channels", PackedStringArray())).has(EVENT_SCRIPT.CHANNEL_MAP_MARKER), "Event reaches map marker channel")
	_assert(typeof(event.get("anchor_position", null)) == TYPE_VECTOR2, "Event snapshot carries visual anchor")
	_assert(bool(event.get("visual_only", false)), "Event is marked visual-only")


func _test_priority_and_cooldown_rules() -> void:
	var resolver = RESOLVER_SCRIPT.new()
	var normal_event: Dictionary = Dictionary(RESOLVER_SCRIPT.call("build_event", EVENT_SCRIPT.EVENT_ORDER_RECEIVED, {
		"fireteam_id": "blue",
		"phase": 1,
	}, {"now_msec": 2000}))
	var critical_event: Dictionary = Dictionary(RESOLVER_SCRIPT.call("build_event", EVENT_SCRIPT.EVENT_CANNOT_EXECUTE, {
		"fireteam_id": "blue",
		"phase": 1,
		"planned_position": Vector2(320.0, 320.0),
	}, {"now_msec": 2000}))
	var emitted: Array = Array(resolver.call("resolve_events", [normal_event, critical_event], {"now_msec": 2000, "max_events": 1}))
	_assert(emitted.size() == 1, "Resolver caps simultaneous messages")
	_assert(String(Dictionary(emitted[0]).get("event_type", "")) == EVENT_SCRIPT.EVENT_CANNOT_EXECUTE, "Critical message preempts normal status")
	var suppressed: Array = Array(resolver.call("resolve_events", [critical_event], {"now_msec": 2100}))
	_assert(suppressed.is_empty(), "Cooldown suppresses duplicate critical event")
	var after_cooldown: Array = Array(resolver.call("resolve_events", [critical_event], {"now_msec": 2600}))
	_assert(after_cooldown.size() == 1, "Critical event re-emits after critical cooldown")


func _test_ftl_skill_precision_without_hidden_truth() -> void:
	var low_event: Dictionary = Dictionary(RESOLVER_SCRIPT.call("build_event", EVENT_SCRIPT.EVENT_CONTACT_REPORT, {
		"fireteam_id": "blue",
		"communication_clarity": 0.24,
	}, {"now_msec": 3000}))
	var high_event: Dictionary = Dictionary(RESOLVER_SCRIPT.call("build_event", EVENT_SCRIPT.EVENT_CONTACT_REPORT, {
		"fireteam_id": "blue",
		"communication_clarity": 0.86,
		"direction_label": "links",
	}, {"now_msec": 3000}))
	_assert(String(low_event.get("short_text", "")) != String(high_event.get("short_text", "")), "FTL communication skill changes wording precision")
	_assert(not String(low_event.get("short_text", "")).contains("links"), "Low/no-direction event does not invent direction")
	_assert(String(high_event.get("short_text", "")).contains("links"), "High clarity event can include provided direction")
	_assert(String(Dictionary(low_event.get("metadata", {})).get("private_truth", "")).is_empty(), "Snapshot does not expose hidden truth metadata")


func _test_multi_fireteam_plan_event_generation() -> void:
	var plan: Dictionary = {
		"plan_id": "task274_multi",
		"phase": 1,
		"target_position": Vector2(640.0, 640.0),
		"mission_control_text": "PLAN PREVIEW P1 | LEAD=BLUE SUP=GOLD | PRE-GO",
		"role_assignments": [
			{
				"fireteam_id": "blue",
				"display_label": "BLUE",
				"role": "lead",
				"role_label": "LEAD",
				"plan_phase_index": 1,
				"next_step": "take_area",
				"planned_position": Vector2(640.0, 640.0),
				"communication_clarity": 0.82,
			},
			{
				"fireteam_id": "gold",
				"display_label": "GOLD",
				"role": "support",
				"role_label": "SUP",
				"plan_phase_index": 0,
				"next_step": "cover_lead",
				"planned_position": Vector2(544.0, 584.0),
				"status": "blocked_path",
				"blocked_path": true,
				"communication_clarity": 0.55,
			},
		],
	}
	var events: Array = Array(RESOLVER_SCRIPT.call("build_events_for_multi_fireteam_plan", plan, {"now_msec": 4000}))
	_assert(_has_event_type(events, EVENT_SCRIPT.EVENT_PLAN_ROLE_ASSIGNED), "Multi-plan emits role-assigned communication")
	_assert(_has_event_type(events, EVENT_SCRIPT.EVENT_PHASE_STARTED), "Multi-plan emits phase-start communication")
	_assert(_has_event_type(events, EVENT_SCRIPT.EVENT_CANNOT_EXECUTE), "Blocked assignment emits cannot-execute communication")
	_assert(_all_events_have_stable_ids(events), "Generated plan events have stable IDs")
	var selected_text: String = String(RESOLVER_SCRIPT.call("build_selected_fireteam_text", events, PackedStringArray(["blue", "gold"]), 3))
	var mission_text: String = String(RESOLVER_SCRIPT.call("build_mission_control_text", events, 3))
	_assert(selected_text.contains("BLUE") or selected_text.contains("GOLD"), "#17 text contains Fireteam communication")
	_assert(not mission_text.is_empty() and (mission_text.contains("GOLD") or mission_text.contains("Phase")), "#18 text contains mission/control communication")


func _test_map_marker_visual_snapshot() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task274_comm_map", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var center_tile = map_data.call("get_tile_at_grid", Vector2i(4, 4))
	var center_position: Vector2 = Vector2(center_tile.world_position) if center_tile != null else Vector2(512.0, 512.0)
	var event: Dictionary = Dictionary(RESOLVER_SCRIPT.call("build_event", EVENT_SCRIPT.EVENT_BREAKOUT_ADAPTATION, {
		"fireteam_id": "blue",
		"display_label": "BLUE",
		"phase": 1,
		"planned_position": center_position,
		"objective_label": "Relay",
		"communication_clarity": 0.78,
	}, {"now_msec": 5000}))
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"tactical_communication_event_dicts": [event],
	})
	await _wait_frames(6)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("tactical_communication_event_visual_count", 0)) == 1, "3D map renders tactical communication marker")
	var entries: Array = Array(snapshot.get("tactical_communication_event_entries", []))
	_assert(not entries.is_empty() and String(Dictionary(entries[0]).get("event_type", "")) == EVENT_SCRIPT.EVENT_BREAKOUT_ADAPTATION, "3D map snapshot exposes communication event entry")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_mission_scene_feedback_layer() -> void:
	var scene = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node("TacticalController")
	var primary_view: Node = scene.get_node("Primary3DView")
	var objective_position: Vector2 = _get_objective_position(scene, Vector2(960.0, 960.0))
	controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["blue", "gold"]), objective_position + Vector2(-72.0, -72.0), objective_position + Vector2(72.0, 48.0), "take")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("_refresh_order_visuals")
	await _wait_frames(10)
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var events: Array = Array(feedback.get("tactical_communication_events", []))
	var map_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var bubbles: Array = Array(feedback.get("fireteamleader_feedback_bubbles", []))
	_assert(int(feedback.get("tactical_communication_event_count", 0)) >= 2, "Mission scene stores tactical communication event snapshot")
	_assert(_has_event_type(events, EVENT_SCRIPT.EVENT_PLAN_ROLE_ASSIGNED), "Mission scene emits role assignment event")
	_assert(String(feedback.get("selected_order_text", "")).contains("LEAD") or String(feedback.get("selected_order_text", "")).contains("SUP"), "#17 selected text shows role communication")
	_assert(String(feedback.get("mission_control_plan_text", "")).contains("PLAN"), "#18 mission text still exposes plan truth")
	_assert(int(map_snapshot.get("tactical_communication_event_visual_count", 0)) >= 1, "Primary 3D view receives map communication markers")
	_assert(_bubbles_match_event_ids(bubbles, events), "FTL bubbles reference known tactical communication events")
	scene.queue_free()
	await _wait_frames(2)


func _test_no_ui_truth_mutation() -> void:
	for path in [
		"res://scripts/tactical/tactical_communication_event.gd",
		"res://scripts/tactical/tactical_communication_resolver.gd",
	]:
		var text: String = _read_text(path)
		_assert(not text.contains("extends Control"), "%s is not UI node truth" % path)
		_assert(not text.contains("enqueue_command"), "%s does not issue gameplay commands" % path)
		_assert(not text.contains("assign_unit_command"), "%s does not assign unit commands" % path)


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_274 is marked implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_274 checklist is complete")
	_assert(status_text.contains("### TASK_274 - Tactical Communication Feedback Layer"), "Implementation status has TASK_274 section")
	_assert(status_text.contains("tactical_communication_resolver.gd"), "Implementation status references communication resolver")


func _has_event_type(events: Array, event_type: String) -> bool:
	for event_variant in events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		if String(Dictionary(event_variant).get("event_type", "")) == event_type:
			return true
	return false


func _all_events_have_stable_ids(events: Array) -> bool:
	for event_variant in events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			return false
		var event: Dictionary = Dictionary(event_variant)
		var event_id: String = String(event.get("event_id", "")).strip_edges()
		if event_id.is_empty() or not event_id.begins_with("comm:"):
			return false
	return true


func _bubbles_match_event_ids(bubbles: Array, events: Array) -> bool:
	var event_ids: Dictionary = {}
	for event_variant in events:
		if typeof(event_variant) == TYPE_DICTIONARY:
			event_ids[String(Dictionary(event_variant).get("event_id", ""))] = true
	var checked_bubbles: int = 0
	for bubble_variant in bubbles:
		if typeof(bubble_variant) != TYPE_DICTIONARY:
			continue
		var bubble: Dictionary = Dictionary(bubble_variant)
		var event_id: String = String(bubble.get("tactical_communication_event_id", "")).strip_edges()
		if event_id.is_empty():
			continue
		checked_bubbles += 1
		if not event_ids.has(event_id):
			return false
	return checked_bubbles > 0


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


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


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
