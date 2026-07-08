extends SceneTree

const Sync := preload("res://scripts/mission/release_first_exchange_real_window_hud_source_sync.gd")

const TASK_PATH := "res://docs/tasks/TASK_883_release_first_exchange_real_window_hud_source_sync_fix.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_real_window_hud_source_sync.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_first_exchange_real_window_hud_source_sync.v1"
const STYLE_ID := "task_883_release_first_exchange_real_window_hud_source_sync_v1"
const NEXT_TASK := "TASK_884 - Release First Exchange HUD Source Sync Recapture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_883 Release First Exchange Real Window HUD Source Sync Fix ===")
	_test_docs_and_static_hooks()
	_test_helper_syncs_status_and_event_log()
	await _test_meta_layer_hud_source_sync()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_883_release_first_exchange_real_window_hud_source_sync_fix: FAILED")
		quit(1)
		return
	print("TASK_883_release_first_exchange_real_window_hud_source_sync_fix: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_883 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_883 source-sync helper exists")
	_assert(task_text.contains("Release First Exchange Real Window HUD Source Sync Fix"), "Task names TASK_883")
	_assert(status_text.contains("TASK_883 - Release First Exchange Real Window HUD Source Sync Fix"), "Implementation status tracks TASK_883")
	_assert(roadmap_text.contains("TASK_883 - Release First Exchange Real Window HUD Source Sync Fix (implementiert)"), "Roadmap marks TASK_883 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_884 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Real-Window-HUD-Source-Sync-Fix (TASK_883)"), "Contract documents TASK_883")
	_assert(report_text.contains("TASK_883") and report_text.contains("TASK_884"), "HTML report tracks TASK_883 and TASK_884")
	_assert(service_text.contains(SCHEMA), "Helper exposes TASK_883 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_883\""), "Helper writes TASK_883 id")
	_assert(service_text.contains("SOURCE_STATUS_TASK_ID: String = \"TASK_876\""), "Helper links TASK_876")
	_assert(service_text.contains("SOURCE_TRACE_TASK_ID: String = \"TASK_879\""), "Helper links TASK_879")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_882\""), "Helper links TASK_882")
	_assert(service_text.contains("sync_event_log_display"), "Helper syncs event-log display")
	_assert(service_text.contains("task_883_real_window_contact_fire_source_sync"), "Helper creates stable read-only event id")
	_assert(service_text.contains("\"creates_command\": false"), "Helper creates no commands")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Helper creates no fire events")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Helper creates no damage events")
	_assert(service_text.contains("\"creates_movement\": false"), "Helper creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Helper sets no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_EXCHANGE_REAL_WINDOW_HUD_SOURCE_SYNC_SCRIPT"), "Controller preloads TASK_883 helper")
	_assert(controller_text.contains("_build_release_first_exchange_real_window_hud_source_synced_feedback_snapshot"), "Controller builds synced feedback snapshot")
	_assert(controller_text.contains("_apply_release_first_exchange_real_window_hud_source_sync_to_labels"), "Controller applies TASK_883 label sync")
	_assert(controller_text.contains("get_release_first_exchange_real_window_hud_source_sync_snapshot"), "Controller exposes TASK_883 snapshot")
	_assert(controller_text.contains("panel.call(\"set_feedback_snapshot\", _build_release_first_exchange_real_window_hud_source_synced_feedback_snapshot(get_command_feedback_snapshot()))"), "Event log panel consumes synced snapshot")


func _test_helper_syncs_status_and_event_log() -> void:
	var snapshot: Dictionary = Sync.build_snapshot(_helper_source_snapshot(), {})
	var entries: Array = Array(snapshot.get("event_log_entries", []))
	var first_entry: Dictionary = Dictionary(entries[0]) if not entries.is_empty() and typeof(entries[0]) == TYPE_DICTIONARY else {}
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Helper snapshot schema matches TASK_883")
	_assert(String(snapshot.get("task_id", "")) == "TASK_883", "Helper snapshot task id matches TASK_883")
	_assert(String(snapshot.get("source_status_task_id", "")) == "TASK_876", "Helper snapshot links TASK_876")
	_assert(String(snapshot.get("status", "")) == "pass", "Helper snapshot passes")
	_assert(bool(snapshot.get("active", false)), "Helper snapshot is active")
	_assert(bool(snapshot.get("selected_fireteam_contact_fire_first", false)), "Helper binds #17 CONTACT FIRE first")
	_assert(bool(snapshot.get("mission_control_contact_fire_first", false)), "Helper binds #18 CONTACT FIRE first")
	_assert(bool(snapshot.get("event_log_contact_fire_first", false)), "Helper binds #19 CONTACT FIRE first")
	_assert(String(first_entry.get("event_id", "")) == "task_883_real_window_contact_fire_source_sync", "Helper puts TASK_883 event first")
	_assert(String(first_entry.get("short_text", "")).contains("CONTACT FIRE"), "Helper event short text contains CONTACT FIRE")
	_assert(int(first_entry.get("created_msec", 0)) > 42000, "Helper event timestamp outranks existing entries")
	_assert(not bool(snapshot.get("primary_lines_contain_debug_no_fire_before_contact_fire", true)), "Helper keeps NO FIRE behind CONTACT FIRE")
	_assert(bool(snapshot.get("read_only", false)), "Helper snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Helper sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Helper creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Helper creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Helper creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Helper creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Helper sets no multiplayer truth")


func _test_meta_layer_hud_source_sync() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight apply hook")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink"):
		scene.queue_free()
		await _wait_frames(1)
		return
	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(180)
	var active_mission = scene.call("get_active_mission") if scene.has_method("get_active_mission") else null
	_assert(active_mission != null, "Deep-link keeps active mission alive")
	if active_mission == null:
		scene.queue_free()
		await _wait_frames(1)
		return
	var controller: Node = active_mission.get_node_or_null("TacticalController")
	_assert(controller != null, "Active mission exposes TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(1)
		return
	_assert(controller.has_method("get_release_first_exchange_real_window_hud_source_sync_snapshot"), "Controller exposes TASK_883 runtime snapshot")
	if not controller.has_method("get_release_first_exchange_real_window_hud_source_sync_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return
	var snapshot: Dictionary = Dictionary(controller.call("get_release_first_exchange_real_window_hud_source_sync_snapshot"))
	if String(snapshot.get("status", "")) != "pass":
		print("TASK_883_DIAGNOSTIC %s" % JSON.stringify({
			"issues": snapshot.get("issues", []),
			"selected": snapshot.get("selected_fireteam_status_text", ""),
			"mission": snapshot.get("mission_control_status_text", ""),
			"event_first": snapshot.get("event_log_first_entry", {}),
			"event_entries": snapshot.get("event_log_entries", []),
			"combat_hud_density": snapshot.get("combat_hud_density", {}),
			"source": snapshot.get("source", {}),
		}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Runtime snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_883", "Runtime snapshot task id is TASK_883")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Runtime snapshot exposes TASK_883 style id")
	_assert(String(snapshot.get("status", "")) == "pass", "TASK_883 runtime snapshot passes")
	_assert(bool(snapshot.get("active", false)), "TASK_883 source sync is active")
	_assert(bool(snapshot.get("selected_fireteam_contact_fire_first", false)), "#17 starts CONTACT FIRE")
	_assert(bool(snapshot.get("mission_control_contact_fire_first", false)), "#18 starts CONTACT FIRE")
	_assert(bool(snapshot.get("event_log_contact_fire_first", false)), "#19 starts CONTACT FIRE")
	_assert(not bool(snapshot.get("primary_lines_contain_debug_no_fire_before_contact_fire", true)), "NO FIRE does not appear before CONTACT FIRE")
	var rendered_entries: Array = Array(snapshot.get("event_log_rendered_entries", []))
	if not rendered_entries.is_empty() and typeof(rendered_entries[0]) == TYPE_DICTIONARY:
		_assert(String(Dictionary(rendered_entries[0]).get("short_text", "")).contains("CONTACT FIRE"), "Rendered event log starts with CONTACT FIRE")
	else:
		_assert(false, "Rendered event log exposes a first entry")
	_assert(bool(snapshot.get("read_only", false)), "Runtime snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Runtime snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Runtime snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Runtime snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Runtime snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Runtime snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Runtime snapshot sets no multiplayer truth")

	scene.queue_free()
	await _wait_frames(2)


func _helper_source_snapshot() -> Dictionary:
	return {
		"active": true,
		"contact_fire_primary_line": "CONTACT FIRE | FIRE ft1->enemy_a | LOS CLEAR | RNG OK",
		"selected_fireteam_status_text": "NEXT LOS/RANGE KORRIGIEREN | WHY KEIN ZIEL\nKampf NO FIRE NO_LOS",
		"mission_control_status_text": "Kampf NO FIRE NO_LOS",
		"event_log_short_text": "CONTACT FIRE: Feuerwechsel lesen",
		"event_log_map_label": "CONTACT FIRE",
		"selected_fireteam_ids": ["ft1"],
		"created_msec": 41000,
		"combat_hud_density": {
			"visibility_persistence_active": true,
			"release_first_exchange_visible_status_source_active": true,
			"compact_line": "FIRE ft1->enemy_a | LOS CLEAR | RNG OK",
			"visibility_persistence": {
				"task_id": "TASK_876",
				"active": true,
				"event_log_short_text": "CONTACT FIRE: Feuerwechsel lesen",
			},
		},
		"event_log_display": {
			"entries": [
				{
					"event_id": "older_contact_pressure",
					"created_msec": 42000,
					"severity": "warning",
					"short_text": "CONTACT PRESSURE: Position korrigieren",
				}
			],
		},
	}


func _instantiate_scene(path: String) -> Node:
	var packed_scene := ResourceLoader.load(path) as PackedScene
	if packed_scene == null:
		return null
	var node := packed_scene.instantiate()
	root.add_child(node)
	return node


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
