extends SceneTree

const RECOVERY_STATE_SCRIPT: GDScript = preload("res://scripts/meta/air_asset_recovery_state.gd")
const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const DOC_PATH: String = "res://docs/dev/air_asset_loss_recovery_meta_loop.md"
const TASK_PATH: String = "res://docs/tasks/TASK_278_air_asset_loss_recovery_meta_loop.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HELP_CATALOG_PATH: String = "res://data/contextual_help_catalog.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_278 Air Asset Loss Recovery Meta Loop ===")
	_test_recovery_contract()
	await _test_meta_roundtrip_debrief_homebase_fob()
	_test_task_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_recovery_contract() -> void:
	_assert(FileAccess.file_exists(DOC_PATH), "Air asset loss recovery doc exists")
	_assert(FileAccess.file_exists("res://scripts/meta/air_asset_recovery_state.gd"), "AirAssetRecoveryState script exists")
	var damaged: Dictionary = Dictionary(RECOVERY_STATE_SCRIPT.call("from_air_asset_status", {
		"asset_id": "dropship_test",
		"asset_type": "dropship",
		"display_name": "Dropship Test",
		"state": "damaged",
		"integrity": 42,
	}, {"craft_id": "dropship_test", "pilot_unit_id": "unit_hotel"}, {"repair_seconds": 12.0}))
	_assert(str(damaged.get("meta_state", "")) == "damaged_repairing", "Damaged air asset enters repair state")
	_assert(int(damaged.get("eta_seconds", 0)) == 12, "Repair state has visible ETA")
	_assert(bool(damaged.get("softlock_guard", false)) and bool(damaged.get("can_recover", false)), "Repair state carries softlock guard")
	var destroyed: Dictionary = Dictionary(RECOVERY_STATE_SCRIPT.call("from_air_asset_status", {
		"asset_id": "dropship_test",
		"asset_type": "dropship",
		"display_name": "Dropship Test",
		"state": "crashed",
		"integrity": 0,
	}, {"craft_id": "dropship_test", "pilot_unit_id": "unit_hotel"}, {"replacement_seconds": 20.0}))
	_assert(str(destroyed.get("meta_state", "")) == "destroyed_replacement_pending", "Destroyed air asset enters replacement state")
	_assert(str(destroyed.get("pilot_state", "")) == "pilot_safe_homebase", "Default destroyed state keeps pilot safe at Homebase")
	var completed: Dictionary = Dictionary(RECOVERY_STATE_SCRIPT.call("tick_recovery", destroyed, 25.0))
	_assert(str(completed.get("meta_state", "")) == "craft_available" and int(completed.get("eta_seconds", -1)) == 0, "Recovery timer returns craft to available")
	var doc_text: String = _read_text(DOC_PATH)
	for token in ["craft_available", "damaged_repairing", "destroyed_replacement_pending", "pilot_safe_homebase", "Debrief", "Homebase", "FOB", "softlock_guard", "load_air_asset_recovery_snapshot"]:
		_assert(doc_text.contains(token), "Recovery doc contains %s" % token)
	var help_catalog: Dictionary = _read_json(HELP_CATALOG_PATH)
	_assert(JSON.stringify(help_catalog).contains("repair/replacement ETA"), "Flightdeck help explains repair/replacement ETA")


func _test_meta_roundtrip_debrief_homebase_fob() -> void:
	var scene := META_LAYER_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)
	scene.set("_homebase_aircraft_definitions", [_craft_definition()])
	scene.set("_assigned_aircraft_pilot_by_craft", {"dropship_test": "unit_hotel"})
	scene.set("_aircraft_location_by_craft", {"dropship_test": "mission"})
	scene.set("_mission_planning_state", {
		"launch_ready_craft_id": "dropship_test",
		"mission_drop_craft_id": "dropship_test",
		"mission_drop_display_name": "Dropship Test",
		"mission_drop_pilot_unit_id": "unit_hotel",
		"mission_drop_state": "waiting",
		"drop_ship_staged": true,
	})
	var mission_result: Dictionary = {
		"result": "defeat",
		"mission_outcome": "ended",
		"air_asset_status": {
			"asset_id": "dropship_test",
			"asset_type": "dropship",
			"display_name": "Dropship Test",
			"state": "crashed",
			"integrity": 0,
			"max_integrity": 100,
			"pilot_unit_id": "unit_hotel",
		},
	}
	var result: Dictionary = Dictionary(scene.call("apply_air_asset_recovery_from_mission_result_for_test", mission_result))
	var recovery: Dictionary = Dictionary(result.get("air_asset_recovery", {}))
	_assert(str(recovery.get("meta_state", "")) == "destroyed_replacement_pending", "Mission result creates replacement recovery state")
	_assert(str(recovery.get("craft_id", "")) == "dropship_test" and str(recovery.get("pilot_unit_id", "")) == "unit_hotel", "Recovery keeps craft and pilot IDs stable")
	_assert(bool(result.get("softlock_guard", false)), "Mission result marks softlock guard")

	var snapshot: Dictionary = Dictionary(scene.call("get_air_asset_recovery_snapshot"))
	_assert(snapshot.has("dropship_test"), "MetaLayer exposes air asset recovery snapshot")
	var saved_snapshot: Dictionary = snapshot.duplicate(true)
	scene.call("load_air_asset_recovery_snapshot", {})
	_assert(Dictionary(scene.call("get_air_asset_recovery_snapshot")).is_empty(), "Recovery snapshot can be cleared for load test")
	scene.call("load_air_asset_recovery_snapshot", saved_snapshot)
	_assert(Dictionary(scene.call("get_air_asset_recovery_snapshot")).has("dropship_test"), "Recovery snapshot reload persists state")

	var homebase: Node = scene.get_node("HomebaseScreen")
	var fob: Node = scene.get_node("FOBScreen")
	var home_snapshot: Dictionary = Dictionary(homebase.call("get_aircraft_panel_snapshot"))
	_assert(String(home_snapshot.get("selected_status_text", "")).to_lower().contains("replacement pending"), "Homebase Flightdeck shows replacement status")
	_assert(not bool(home_snapshot.get("can_send_selected", true)), "Homebase blocks sending unavailable craft")
	var fob_snapshot: Dictionary = Dictionary(fob.call("get_flightdeck_snapshot"))
	_assert(String(fob_snapshot.get("dropship_status", "")).to_lower().contains("replacement"), "FOB Flightdeck shows replacement status")
	_assert(not bool(fob_snapshot.get("can_board", true)) and not bool(fob_snapshot.get("can_start_mission", true)), "FOB blocks boarding and mission start")

	var debrief: Node = scene.get_node("DebriefScreen")
	debrief.call("set_mission_result", result)
	await _wait_frames(2)
	var labels: PackedStringArray = _collect_label_texts(debrief)
	_assert(_labels_contain(labels, "Air asset:"), "Debrief shows air asset recovery line")
	_assert(_labels_contain(labels, "replacement ETA"), "Debrief shows replacement ETA")

	scene.call("advance_air_asset_recovery_time", 999.0)
	var completed_snapshot: Dictionary = Dictionary(scene.call("get_air_asset_recovery_snapshot"))
	var completed_recovery: Dictionary = Dictionary(completed_snapshot.get("dropship_test", {}))
	_assert(str(completed_recovery.get("meta_state", "")) == "craft_available", "Recovery timer completes back to available craft")
	home_snapshot = Dictionary(homebase.call("get_aircraft_panel_snapshot"))
	_assert(String(home_snapshot.get("selected_status_text", "")).to_lower().contains("ready"), "Homebase shows recovered craft as ready")
	scene.queue_free()
	await _wait_frames(2)


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_278 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("TASK_278") and status_text.to_lower().contains("implementiert"), "Implementation status mentions TASK_278 implemented")
	_assert(roadmap_text.contains("TASK_278") and roadmap_text.to_lower().contains("implementiert"), "Roadmap mentions TASK_278 implemented")


func _craft_definition() -> Dictionary:
	return {
		"craft_id": "dropship_test",
		"craft_type": "dropship",
		"display_name": "Dropship Test",
		"summary": "Task 278 test craft",
		"texture_path": "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png",
		"supports_cargo": false,
		"cargo_options": [],
	}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _read_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(_read_text(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _collect_label_texts(node: Node) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if node == null:
		return result
	if node is Label:
		result.append((node as Label).text)
	for child in node.get_children():
		result.append_array(_collect_label_texts(child))
	return result


func _labels_contain(labels: PackedStringArray, needle: String) -> bool:
	var normalized_needle: String = needle.to_lower()
	for label in labels:
		if String(label).to_lower().contains(normalized_needle):
			return true
	return false


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
