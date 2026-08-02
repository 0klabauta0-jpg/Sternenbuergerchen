extends SceneTree

const MISSION_SCENE_PATH := "res://scenes/mission/mission_runtime.tscn"
const META_SCENE_PATH := "res://scenes/meta/meta_layer.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/main_menu.tscn"
const MISSION_IDENTITY_SCRIPT_PATH := "res://scripts/mission/mission_runtime_identity.gd"
const CONTROLLER_SOURCE_PATH := "res://scripts/tactical/mission_tactical_sandbox_controller.gd"
const MENU_SOURCE_PATH := "res://scripts/ui/main_menu_screen.gd"
const HANDOFF_SCHEMA := "sternenbuergerchen.mission_runtime_identity_handoff.v1"
const HOMEBASE_SELECTOR_PATH := NodePath("HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/MissionSelector")
const HOMEBASE_START_PATH := NodePath("HomebaseScreen/Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton")

var _passed := 0
var _failed := 0


func _init() -> void:
	if OS.get_cmdline_user_args().has("--n004b-release-deeplink-probe"):
		call_deferred("_run_release_deeplink_probe")
		return
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_N004B Public grid_sweep structural contract ===")
	await _test_canonical_mission_public_boundary()
	await _test_visible_homebase_identity_handoffs()
	_test_release_deeplinks_are_deprecated()
	await _test_meta_legacy_release_helpers_are_blocked()
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
	_assert(controller_source.contains("_issue_command_from_entry(\"public_world_waypoint\", command_type.strip_edges().to_lower(), \"WAYPOINT\", append_mode)"), "Public waypoint forwards append_mode into N003 planning")
	_assert(controller_source.contains("\"expected_command_tokens\": expected_command_tokens"), "Public waypoint receipt reports exact expected command tokens")
	_assert(controller_source.contains("func _request_selected_mission_dropship_drop") and controller_source.contains("-> Dictionary"), "Dropship request producer returns a structured acceptance result")
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
		var meta = handoff.get("meta") as Node
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
			if mission_id == "grid_sweep":
				await _assert_active_refresh_cannot_replace_identity(meta, setup, receipt)
		if meta != null and is_instance_valid(meta):
			meta.queue_free()
			await process_frame
	var grid_receipt: Dictionary = Dictionary(receipts_by_mission.get("grid_sweep", {}))
	var fob_receipt: Dictionary = Dictionary(receipts_by_mission.get("fob_transfer", {}))
	_assert(String(grid_receipt.get("mission_id", "")) != String(fob_receipt.get("mission_id", "")), "Shared authored files do not erase distinct mission IDs")
	_assert(String(grid_receipt.get("identity_fingerprint", "")) != String(fob_receipt.get("identity_fingerprint", "")), "Distinct mission provenance produces distinct fingerprints")


func _assert_active_refresh_cannot_replace_identity(meta: Node, setup: Node, receipt: Dictionary) -> void:
	var selector := meta.get_node_or_null(HOMEBASE_SELECTOR_PATH) as OptionButton
	var start := meta.get_node_or_null(HOMEBASE_START_PATH) as Button
	_assert(selector != null and start != null, "Active refresh test retains visible Homebase controls")
	if selector == null or start == null:
		return
	_select_visible_mission(selector, "fob_transfer")
	start.emit_signal("pressed")
	await process_frame
	await process_frame
	_assert(JSON.stringify(Dictionary(setup.call("get_runtime_identity_handoff_receipt"))) == JSON.stringify(receipt), "Active refresh cannot replace frozen identity receipt")
	_assert(String(setup.get("map_file_path")) == String(receipt.get("map_path", "")) and String(setup.get("scenario_file_path")) == String(receipt.get("scenario_path", "")), "Active refresh preserves frozen map and scenario")


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
	var meta_source := FileAccess.get_file_as_string("res://scripts/meta/meta_layer_flow.gd")
	_assert(not meta_source.contains("call_deferred(\"_apply_release_"), "MetaLayerFlow schedules no release automation chain")
	_assert(not source.contains("change_scene_to_file(SINGLEPLAYER_SCENE_PATH)"), "MainMenu release arguments cannot transition into MetaLayer")
	for argument in ["--release-singleplayer", "--release-singleplayer-start-mission", "--release-singleplayer-lz-drop-preview", "--release-singleplayer-first-go-firefight"]:
		var probe: Dictionary = _run_release_deeplink_probe_process(argument)
		_assert(bool(probe.get("probe_completed", false)), "%s starts the real MainMenu probe" % argument)
		_assert(String(probe.get("scene_path", "")) == MAIN_MENU_SCENE_PATH, "%s leaves the real MainMenu scene active" % argument)
		_assert(bool(probe.get("requested", false)) and not bool(probe.get("applied", true)), "%s has no Meta handoff in the real MainMenu run" % argument)
		_assert(bool(probe.get("deprecated", false)) and String(probe.get("status", "")) == "blocked" and String(probe.get("reason", "")) == "legacy_deeplink_no_public_path", "%s reports the stable public block reason in the real MainMenu run" % argument)
		_assert(not bool(probe.get("meta_layer_present", true)), "%s real MainMenu run creates no MetaLayer" % argument)


func _test_meta_legacy_release_helpers_are_blocked() -> void:
	var scene := load(META_SCENE_PATH) as PackedScene
	_assert(scene != null, "MetaLayer scene loads for legacy helper containment")
	if scene == null:
		return
	for spec in [
		{"method": "_apply_release_start_mission_deeplink", "arg": "--release-singleplayer-start-mission", "snapshot": "get_release_start_mission_deeplink_snapshot"},
		{"method": "_apply_release_lz_drop_preview_deeplink", "arg": "--release-singleplayer-lz-drop-preview", "snapshot": "get_release_lz_drop_preview_deeplink_snapshot"},
		{"method": "_apply_release_first_go_firefight_deeplink", "arg": "--release-singleplayer-first-go-firefight", "snapshot": "get_release_first_go_firefight_deeplink_snapshot"},
	]:
		var meta := scene.instantiate()
		root.add_child(meta)
		await process_frame
		var argument := String(Dictionary(spec).get("arg", ""))
		var helper_name := String(Dictionary(spec).get("method", ""))
		meta.call(helper_name, PackedStringArray([argument]))
		await process_frame
		await process_frame
		var snapshot_name := String(Dictionary(spec).get("snapshot", ""))
		var snapshot: Dictionary = Dictionary(meta.call(snapshot_name, PackedStringArray([argument])))
		_assert(String(snapshot.get("status", "")) == "blocked" and String(snapshot.get("reason", "")) == "legacy_deeplink_no_public_path", "%s reports the stable legacy block" % helper_name)
		_assert(meta.call("get_active_mission") == null and String(snapshot.get("current_meta_view", "homebase")) != "mission", "%s cannot create a mission or switch into mission view" % helper_name)
		meta.queue_free()
		await process_frame


func _run_release_deeplink_probe_process(argument: String) -> Dictionary:
	var output: Array = []
	var arguments := PackedStringArray([
		"--headless",
		"--path",
		ProjectSettings.globalize_path("res://"),
		"--script",
		"res://scripts/tests/task_n004b_public_grid_sweep_contract.gd",
		"--",
		"--n004b-release-deeplink-probe",
		argument,
	])
	var exit_code := OS.execute(OS.get_executable_path(), arguments, output, true)
	var combined_output := "\n".join(PackedStringArray(output))
	var marker := "N004B_RELEASE_PROBE:"
	var marker_index := combined_output.rfind(marker)
	if exit_code != 0 or marker_index < 0:
		return {
			"probe_completed": false,
			"exit_code": exit_code,
			"output": combined_output,
		}
	var payload_text := combined_output.substr(marker_index + marker.length()).split("\n", false)[0].strip_edges()
	var parsed: Variant = JSON.parse_string(payload_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {
			"probe_completed": false,
			"exit_code": exit_code,
			"output": combined_output,
		}
	var result: Dictionary = Dictionary(parsed)
	result["probe_completed"] = true
	result["exit_code"] = exit_code
	return result


func _run_release_deeplink_probe() -> void:
	var transition_error := change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if transition_error != OK:
		print("N004B_RELEASE_PROBE:%s" % JSON.stringify({"transition_error": transition_error}))
		quit(1)
	for _frame in 6:
		await process_frame
	var menu := current_scene
	var snapshot: Dictionary = Dictionary(menu.call("get_release_singleplayer_deeplink_snapshot")) if menu != null and menu.has_method("get_release_singleplayer_deeplink_snapshot") else {}
	var root_children: Array = root.get_children()
	var meta_layer_present := false
	for child in root_children:
		if child != null and (String(child.name) == "MetaLayer" or String(child.scene_file_path) == META_SCENE_PATH):
			meta_layer_present = true
	print("N004B_RELEASE_PROBE:%s" % JSON.stringify({
		"scene_path": String(menu.scene_file_path) if menu != null else "",
		"requested": bool(snapshot.get("requested", false)),
		"applied": bool(snapshot.get("applied", false)),
		"deprecated": bool(snapshot.get("deprecated", false)),
		"status": String(snapshot.get("status", "")),
		"reason": String(snapshot.get("reason", "")),
		"meta_layer_present": meta_layer_present,
	}))
	quit(0)


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
