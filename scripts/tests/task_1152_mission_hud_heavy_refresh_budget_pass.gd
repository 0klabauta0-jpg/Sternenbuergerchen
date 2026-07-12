extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const CONTROLLER_SOURCE_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const LOBBY_SOURCE_PATH: String = "res://scripts/ui/multiplayer_lobby_screen.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1152 Mission HUD Heavy Refresh Budget Pass ===")
	_test_contract_is_present()
	await _test_periodic_heavy_surfaces_skip_unchanged_state()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_contract_is_present() -> void:
	var source: String = FileAccess.get_file_as_string(CONTROLLER_SOURCE_PATH)
	_assert(source.contains("_build_periodic_strategic_status_signature"), "Strategic status owns a stable periodic input signature")
	_assert(source.contains("_build_periodic_craft_controls_signature"), "Craft controls own a stable periodic input signature")
	_assert(source.contains("_build_periodic_fireteam_cards_signature"), "Fireteam card group reuses runtime signatures before entering card refreshes")
	_assert(source.contains("func _update_ui(include_heavy_surfaces: bool = true, force_heavy_surfaces: bool = true)"), "Direct UI calls default to a forced complete refresh")
	_assert(source.contains("_update_ui(heavy_refresh_due, false)"), "Recurring UI cadence uses guarded heavy surfaces")
	_assert(_function_body(source, "_flush_mission_dropship_runtime_feedback").contains("_update_ui(true, false)"), "Dropship runtime feedback uses guarded heavy surfaces")
	_assert(_function_body(source, "apply_authoritative_mission_dropship_snapshot").contains("_update_ui(true, false)"), "Authoritative dropship snapshots use guarded heavy surfaces")
	_assert(_function_body(source, "refresh_flank_vulnerability_state").contains("_update_ui(true, false)"), "Recurring flank feedback uses guarded heavy surfaces")
	var lobby_source: String = FileAccess.get_file_as_string(LOBBY_SOURCE_PATH)
	_assert(lobby_source.contains('"mission_hud_runtime_surface_guard"'), "Release trace preserves heavy HUD apply/skip evidence")


func _test_periodic_heavy_surfaces_skip_unchanged_state() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	_assert(controller != null and controller.has_method("get_mission_hud_runtime_surface_guard_snapshot"), "Mission fixture exposes heavy HUD guard diagnostics")
	if controller == null or not controller.has_method("get_mission_hud_runtime_surface_guard_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_update_ui", true, false)
	var primed: Dictionary = Dictionary(controller.call("get_mission_hud_runtime_surface_guard_snapshot"))
	controller.call("_update_ui", true, false)
	var unchanged: Dictionary = Dictionary(controller.call("get_mission_hud_runtime_surface_guard_snapshot"))
	_assert(int(unchanged.get("strategic_status_skip_count", 0)) > int(primed.get("strategic_status_skip_count", 0)), "Unchanged periodic strategic status is skipped")
	_assert(int(unchanged.get("craft_controls_skip_count", 0)) > int(primed.get("craft_controls_skip_count", 0)), "Unchanged periodic craft controls are skipped")
	_assert(int(unchanged.get("fireteam_card_group_skip_count", 0)) > int(primed.get("fireteam_card_group_skip_count", 0)), "Unchanged periodic fireteam card group is skipped")

	controller.set("_mission_drop_eta_seconds", int(controller.get("_mission_drop_eta_seconds")) + 5)
	controller.call("_update_ui", true, false)
	var changed: Dictionary = Dictionary(controller.call("get_mission_hud_runtime_surface_guard_snapshot"))
	_assert(int(changed.get("strategic_status_apply_count", 0)) > int(unchanged.get("strategic_status_apply_count", 0)), "Changed ETA reapplies strategic status")
	_assert(int(changed.get("craft_controls_apply_count", 0)) > int(unchanged.get("craft_controls_apply_count", 0)), "Changed ETA reapplies craft controls")

	controller.call("_update_ui")
	var forced: Dictionary = Dictionary(controller.call("get_mission_hud_runtime_surface_guard_snapshot"))
	_assert(int(forced.get("strategic_status_apply_count", 0)) > int(changed.get("strategic_status_apply_count", 0)), "Direct complete refresh reapplies strategic status immediately")
	_assert(int(forced.get("craft_controls_apply_count", 0)) > int(changed.get("craft_controls_apply_count", 0)), "Direct complete refresh reapplies craft controls immediately")
	_assert(bool(forced.get("read_only", false)) and not bool(forced.get("ui_sets_gameplay_truth", true)), "Heavy HUD guard diagnostics remain read-only")

	scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _function_body(source: String, function_name: String) -> String:
	var start: int = source.find("func %s(" % function_name)
	if start < 0:
		return ""
	var finish: int = source.find("\n\nfunc ", start + 5)
	return source.substr(start) if finish < 0 else source.substr(start, finish - start)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
