extends SceneTree

const MISSION_SCENE_PATH := "res://scenes/mission/mission_runtime.tscn"
const META_SCENE_PATH := "res://scenes/meta/meta_layer.tscn"
const MISSION_IDENTITY_SCRIPT_PATH := "res://scripts/mission/mission_runtime_identity.gd"
const CONTROLLER_SOURCE_PATH := "res://scripts/tactical/mission_tactical_sandbox_controller.gd"
const MENU_SOURCE_PATH := "res://scripts/ui/main_menu_screen.gd"
const HANDOFF_SCHEMA := "sternenbuergerchen.mission_runtime_identity_handoff.v1"
const HOMEBASE_SELECTOR_PATH := NodePath("HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/MissionSelector")
const HOMEBASE_START_PATH := NodePath("HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_N004B Public grid_sweep structural contract ===")
	await _test_canonical_mission_public_boundary()
	await _test_visible_homebase_identity_handoffs()
	_test_release_deeplinks_are_deprecated()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_canonical_mission_public_boundary() -> void:
	var scene := load(MISSION_SCENE_PATH) as PackedScene
	_assert(scene != null, "Canonical MissionRuntime scene loads")
	if scene == null:
		return
	var source := FileAccess.get_file_as_string(MISSION_SCENE_PATH)
	_assert(not source.contains("res://scripts/tests/"), "Canonical mission scene has no scripts/tests edge")
	_assert(not source.contains("res://scenes/tests/"), "Canonical mission scene has no scenes/tests edge")
	var mission := scene.instantiate()
	_assert(mission.name == "MissionRuntime", "Canonical mission root has product identity")
	root.add_child(mission)
	await process_frame
	var controller := mission.get_node_or_null("TacticalController")
	_assert(controller != null, "Canonical mission exposes TacticalController")
	for method_name in [
		"get_mission_identity_snapshot",
		"begin_dropship_lz_placement",
		"place_dropship_lz_from_world_position",
		"request_mission_dropship_drop",
		"plan_selected_fireteam_waypoint_from_world_position",
		"execute_selected_fireteam_orders",
	]:
		_assert(controller != null and controller.has_method(method_name), "Controller exposes public %s" % method_name)
	var controller_source := FileAccess.get_file_as_string(CONTROLLER_SOURCE_PATH)
	for method_name in [
		"begin_dropship_lz_placement",
		"place_dropship_lz_from_world_position",
		"request_mission_dropship_drop",
		"plan_selected_fireteam_waypoint_from_world_position",
		"get_mission_identity_snapshot",
	]:
		_assert(_public_method_body_is_safe(controller_source, method_name), "Public %s contains no direct authority/test bypass" % method_name)
	mission.queue_free()
	await process_frame


func _test_visible_homebase_identity_handoffs() -> void:
	_assert(ResourceLoader.exists(MISSION_IDENTITY_SCRIPT_PATH), "MissionRuntimeIdentity value exists")
	var receipts_by_mission: Dictionary = {}
	for mission_id in ["grid_sweep", "fob_transfer"]:
		var handoff: Dictionary = await _launch_visible_homebase_mission(mission_id)
		var receipt: Dictionary = Dictionary(handoff.get("receipt", {}))
		_assert(String(handoff.get("mission_id", "")) == mission_id, "Visible Homebase selection launches %s" % mission_id)
		_assert(String(receipt.get("schema", "")) == HANDOFF_SCHEMA, "%s receipt uses exact schema" % mission_id)
		_assert(String(receipt.get("phase", "")) == "enter_tree", "%s receipt is captured in enter_tree" % mission_id)
		_assert(bool(receipt.get("received_before_enter_tree", false)), "%s receipt proves pre-tree handoff" % mission_id)
		_assert(String(receipt.get("mission_id", "")) == mission_id, "%s receipt preserves explicit mission provenance" % mission_id)
		_assert(not String(receipt.get("identity_fingerprint", "")).is_empty(), "%s receipt has fingerprint" % mission_id)
		_assert(String(receipt.get("source", "")) == "meta_layer_selected_mission_definition", "%s receipt names selected-definition source" % mission_id)
		_assert(String(receipt.get("objective_marker_id", "")) == "objective_point", "%s receipt resolves authored objective marker" % mission_id)
		_assert(float(receipt.get("capture_radius", 0.0)) > 0.0, "%s receipt resolves authored capture radius" % mission_id)
		_assert(String(receipt.get("map_path", "")) == "res://maps/Ground_Mission01_32x32.json" and String(receipt.get("scenario_path", "")) == "res://data/mission_scenarios/ground_mission01_default.json", "%s receipt preserves selected authored map/scenario" % mission_id)
		var receipt_position: Dictionary = Dictionary(receipt.get("objective_world_position", {}))
		_assert(float(receipt_position.get("x", 0.0)) == 768.0 and float(receipt_position.get("y", 0.0)) == 960.0, "%s receipt resolves authored objective world position" % mission_id)
		receipts_by_mission[mission_id] = receipt.duplicate(true)
		var setup = handoff.get("setup") as Node
		if setup != null:
			var before := JSON.stringify(receipt)
			var identity_before: Dictionary = Dictionary(handoff.get("identity", {}))
			var identity_script := load(MISSION_IDENTITY_SCRIPT_PATH) as GDScript
			var copied_identity = identity_script.call("from_snapshot", Dictionary(handoff.get("identity", {}))) if identity_script != null else null
			var rejection: Dictionary = Dictionary(setup.call("configure_runtime_identity", copied_identity)) if copied_identity != null else {}
			_assert(bool(rejection.get("rejected", false)), "%s rejects post-tree identity replacement" % mission_id)
			_assert(JSON.stringify(Dictionary(setup.call("get_runtime_identity_handoff_receipt"))) == before, "%s preserves frozen handoff receipt" % mission_id)
			var override_result: Dictionary = Dictionary(setup.call("apply_cmdline_scenario_override", ["--scenario-file=res://bad.json", "--mission-scenario=res://bad.json"]))
			_assert(String(override_result.get("reason", "")) == "runtime_identity_locked" and bool(override_result.get("rejected", false)), "%s rejects scenario override after identity lock" % mission_id)
			var controller: Node = setup.get_parent().get_node_or_null("TacticalController")
			var identity_after: Dictionary = Dictionary(controller.call("get_mission_identity_snapshot")) if controller != null else {}
			_assert(JSON.stringify(Dictionary(identity_before.get("pre_tree_handoff", {}))) == JSON.stringify(Dictionary(identity_after.get("pre_tree_handoff", {}))), "%s locked override leaves controller receipt unchanged" % mission_id)
		var meta = handoff.get("meta") as Node
		if meta != null and is_instance_valid(meta):
			meta.queue_free()
			await process_frame
	var grid_receipt: Dictionary = Dictionary(receipts_by_mission.get("grid_sweep", {}))
	var fob_receipt: Dictionary = Dictionary(receipts_by_mission.get("fob_transfer", {}))
	_assert(String(grid_receipt.get("mission_id", "")) != String(fob_receipt.get("mission_id", "")), "Shared authored files do not erase distinct mission IDs")
	_assert(String(grid_receipt.get("identity_fingerprint", "")) != String(fob_receipt.get("identity_fingerprint", "")), "Distinct mission provenance produces distinct fingerprints")


func _launch_visible_homebase_mission(mission_id: String) -> Dictionary:
	var scene := load(META_SCENE_PATH) as PackedScene
	if scene == null:
		return {}
	var meta := scene.instantiate()
	root.add_child(meta)
	var settled := await _wait_until(func() -> bool:
		var snapshot: Dictionary = Dictionary(meta.call("get_singleplayer_start_bootstrap_snapshot"))
		return not bool(snapshot.get("visible_homebase_post_show_guard_pending", true)) and bool(snapshot.get("visible_homebase_post_show_guard_ran", false)), 180)
	_assert(settled, "%s waits for public Homebase post-show guard" % mission_id)
	var selector := meta.get_node_or_null(HOMEBASE_SELECTOR_PATH) as OptionButton
	var start := meta.get_node_or_null(HOMEBASE_START_PATH) as Button
	_assert(selector != null and start != null, "%s uses visible Homebase selector and start button" % mission_id)
	if selector == null or start == null:
		meta.queue_free()
		await process_frame
		return {}
	if mission_id == "grid_sweep":
		_select_visible_mission(selector, "fob_transfer")
		await process_frame
	_select_visible_mission(selector, mission_id)
	var selected := await _wait_until(func() -> bool:
		return String(Dictionary(meta.call("get_singleplayer_start_bootstrap_snapshot")).get("selected_mission_id", "")) == mission_id, 60)
	_assert(selected, "%s visible selector updates MetaLayer selection" % mission_id)
	var enabled := await _wait_until(func() -> bool: return not start.disabled, 120)
	_assert(enabled, "%s visible start button becomes enabled" % mission_id)
	start.emit_signal("pressed")
	var mission_started := await _wait_until(func() -> bool: return meta.call("get_active_mission") != null, 180)
	_assert(mission_started, "%s visible start button creates active mission" % mission_id)
	var mission = meta.call("get_active_mission")
	var setup: Node = mission.get_node_or_null("MissionSetup") if mission != null else null
	var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
	var receipt: Dictionary = Dictionary(setup.call("get_runtime_identity_handoff_receipt")) if setup != null and setup.has_method("get_runtime_identity_handoff_receipt") else {}
	var identity: Dictionary = Dictionary(controller.call("get_mission_identity_snapshot")) if controller != null and controller.has_method("get_mission_identity_snapshot") else {}
	var result := {"mission_id": mission_id, "setup": setup, "receipt": receipt, "identity": identity}
	result["meta"] = meta
	return result


func _select_visible_mission(selector: OptionButton, mission_id: String) -> void:
	for index in selector.item_count:
		if String(selector.get_item_metadata(index)).strip_edges() == mission_id:
			selector.select(index)
			selector.emit_signal("item_selected", index)
			return
	_assert(false, "Visible selector contains %s" % mission_id)


func _test_release_deeplinks_are_deprecated() -> void:
	var menu_script := load("res://scripts/ui/main_menu_screen.gd") as GDScript
	_assert(menu_script != null, "MainMenuScreen script loads")
	if menu_script == null:
		return
	for argument in ["--release-singleplayer", "--release-singleplayer-start-mission", "--release-singleplayer-lz-drop-preview", "--release-singleplayer-first-go-firefight"]:
		var menu = menu_script.new()
		var snapshot: Dictionary = Dictionary(menu.call("get_release_singleplayer_deeplink_snapshot", PackedStringArray([argument])))
		_assert(bool(snapshot.get("requested", false)), "%s remains observable in deeplink snapshot" % argument)
		_assert(bool(snapshot.get("deprecated", false)) and String(snapshot.get("status", "")) == "blocked" and String(snapshot.get("reason", "")) == "legacy_deeplink_no_public_path", "%s is deprecated without a gameplay handoff" % argument)
		menu.free()
	var source := FileAccess.get_file_as_string(MENU_SOURCE_PATH)
	_assert(not source.contains("_apply_release_start_mission_deeplink"), "MainMenu no longer invokes MetaLayer release start chain")


func _public_method_body_is_safe(source: String, method_name: String) -> bool:
	var start := source.find("func %s(" % method_name)
	if start < 0:
		return false
	var end := source.find("\nfunc ", start + 1)
	var body := source.substr(start, end - start if end >= 0 else source.length() - start)
	for forbidden in ["_for_test", ".call(\"_", "enqueue_command", "UnitCommand", "teleport", "combat_event", "mission_result"]:
		if body.to_lower().contains(forbidden.to_lower()):
			return false
	return true


func _wait_until(predicate: Callable, max_frames: int) -> bool:
	for _frame in max_frames:
		if bool(predicate.call()):
			return true
		await process_frame
	return bool(predicate.call())


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
