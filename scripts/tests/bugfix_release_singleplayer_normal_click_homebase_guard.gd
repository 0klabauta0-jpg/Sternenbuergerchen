extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const TASK_PATH := "res://docs/tasks/BUGFIX_release_singleplayer_normal_click_homebase_guard.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/homebase_direct_dropship_flow_contract.md"
const META_LAYER_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== BUGFIX Release Singleplayer Normal Click Homebase Guard ===")
	_test_docs_and_static_hooks()
	await _test_normal_singleplayer_click_homebase_guard()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("BUGFIX_release_singleplayer_normal_click_homebase_guard: FAILED")
		quit(1)
		return
	print("BUGFIX_release_singleplayer_normal_click_homebase_guard: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var meta_text: String = _read_text(META_LAYER_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "Bugfix task file exists")
	_assert(task_text.contains("Release Singleplayer Normal Click Homebase Guard"), "Task names normal-click guard")
	_assert(status_text.contains("BUGFIX - Release Singleplayer Normal Click Homebase Guard"), "Implementation status tracks normal-click guard")
	_assert(roadmap_text.contains("BUGFIX - Release Singleplayer Normal Click Homebase Guard (implementiert)"), "Roadmap marks normal-click guard implemented")
	_assert(contract_text.contains("Release-Normalstart-Guard"), "Homebase Direct contract documents normalstart guard")
	_assert(meta_text.contains("get_release_singleplayer_normal_click_homebase_guard_snapshot"), "MetaLayer exposes normal-click guard snapshot")
	_assert(meta_text.contains("_ensure_singleplayer_visible_homebase_actionability()"), "Homebase show path reapplies actionability guard")
	_assert(meta_text.contains("_selected_mission_id.strip_edges() != SINGLEPLAYER_RELEASE_DEFAULT_MISSION_ID"), "Actionability rejects stale release mission selection")
	_assert(meta_text.contains("_get_mission_drop_source() != MISSION_DROP_SOURCE_HOMEBASE_DIRECT"), "Actionability rejects stale release drop source")


func _test_normal_singleplayer_click_homebase_guard() -> void:
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	current_scene = menu
	await _wait_frames(4)

	var singleplayer_button := menu.get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton") as Button
	_assert(singleplayer_button != null, "Main menu exposes Singleplayer button")
	if singleplayer_button == null:
		menu.queue_free()
		await _wait_frames(2)
		return

	singleplayer_button.pressed.emit()
	await _wait_frames(16)

	var scene: Node = current_scene
	_assert(scene != null and scene.name == "MetaLayerTest", "Normal Singleplayer click opens MetaLayer scene")
	if scene == null or scene.name != "MetaLayerTest":
		return
	_assert(scene.has_method("get_release_singleplayer_normal_click_homebase_guard_snapshot"), "MetaLayer has normal-click guard callable")
	if not scene.has_method("get_release_singleplayer_normal_click_homebase_guard_snapshot"):
		scene.queue_free()
		current_scene = null
		await _wait_frames(2)
		return

	var snapshot: Dictionary = Dictionary(scene.call("get_release_singleplayer_normal_click_homebase_guard_snapshot"))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.release_singleplayer_normal_click_homebase_guard.v1", "Snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "BUGFIX_release_singleplayer_normal_click_homebase_guard", "Snapshot task id is stable")
	_assert(String(snapshot.get("status", "")) == "pass", "Normal-click Homebase guard passes")
	_assert(int(snapshot.get("failed_count", -1)) == 0, "Normal-click guard has no failed checks")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot does not set gameplay truth")
	_assert(String(snapshot.get("current_meta_view", "")) == "homebase", "Normal click remains on Homebase")
	_assert(String(snapshot.get("selected_mission_id", "")) == "grid_sweep", "Normal click does not show stale FOB Transfer")
	_assert(String(snapshot.get("mission_drop_source", "")) == "homebase_direct", "Normal click uses Homebase Direct drop source")
	_assert(int(snapshot.get("visible_aircraft_count", 0)) >= 1, "Normal click shows a Flightdeck ship")
	_assert(int(snapshot.get("payload_operator_count", 0)) >= 2, "Normal click has payload operators")
	_assert(int(snapshot.get("boarded_operator_count", 0)) >= int(snapshot.get("payload_operator_count", 0)), "Normal click has boarded payload")
	_assert(String(snapshot.get("readiness_overall_state", "")) == "ready", "Normal click readiness is ready")
	_assert(String(snapshot.get("start_button_text", "")) == "Start Mission", "Normal click shows Start Mission")
	_assert(not bool(snapshot.get("start_button_disabled", true)), "Normal click enables Start Mission")
	_assert(String(snapshot.get("mission_team_limit_text", "")).begins_with("Mission payload:"), "Normal click names Homebase Direct payload instead of misleading mission slots")
	_assert(String(snapshot.get("mission_transfer_text", "")).contains("Direct sortie"), "Normal click transfer text names direct sortie")
	_assert(String(snapshot.get("mission_summary_text", "")).contains("Start Mission"), "Normal click summary names the next start action")
	_assert(not String(snapshot.get("mission_summary_text", "")).contains("send the team to FOB"), "Normal click summary does not tell player to send team to FOB")
	var readiness_text: String = String(snapshot.get("rendered_readiness_item_text", ""))
	_assert(readiness_text.find("STOP Team") < 0, "Normal click has no STOP Team blocker")
	_assert(readiness_text.find("STOP Dropship") < 0, "Normal click has no STOP Dropship blocker")
	_assert(readiness_text.find("STOP Pilot") < 0, "Normal click has no STOP Pilot blocker")
	_assert(readiness_text.find("STOP Boarding") < 0, "Normal click has no STOP Boarding blocker")
	_assert(_check_passed(snapshot, "mission_is_grid_sweep"), "Mission check passes")
	_assert(_check_passed(snapshot, "drop_source_homebase_direct"), "Drop-source check passes")
	_assert(_check_passed(snapshot, "start_mission_enabled"), "Start button check passes")
	_assert(_check_passed(snapshot, "no_stop_blockers"), "STOP blocker check passes")
	_assert(_check_passed(snapshot, "homebase_direct_copy_clear"), "Homebase Direct copy check passes")

	scene.queue_free()
	current_scene = null
	await _wait_frames(2)


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


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
