extends SceneTree

const MISSION_SCENE_PATH := "res://scenes/mission/mission_runtime.tscn"
const META_SCENE_PATH := "res://scenes/meta/meta_layer.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/main_menu.tscn"
const MISSION_IDENTITY_SCRIPT_PATH := "res://scripts/mission/mission_runtime_identity.gd"
const CONTROLLER_SOURCE_PATH := "res://scripts/tactical/mission_tactical_sandbox_controller.gd"
const MENU_SOURCE_PATH := "res://scripts/ui/main_menu_screen.gd"
const META_FLOW_SOURCE_PATH := "res://scripts/meta/meta_layer_flow.gd"
const COMMAND_SUBMISSION_RESULT_PATH := "res://scripts/mission/command_submission_result.gd"
const COMMAND_ENTRY_ADAPTER_PATH := "res://scripts/mission/mission_command_entry_adapter.gd"
const COMMAND_GATEWAY_PATH := "res://scripts/tactical/fireteam_command_gateway.gd"
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
	_test_n003_plan_receipt_is_canonical_and_defensive()
	await _test_canonical_mission_public_boundary()
	await _test_public_drop_respects_cooldown()
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
	_assert(controller_source.contains("_issue_command_from_entry(\"public_world_waypoint\", command_type.strip_edges().to_lower(), \"WAYPOINT\", append_mode)"), "Public waypoint forwards append_mode into N003 planning")
	_assert(not _public_method_body(controller_source, "plan_selected_fireteam_waypoint_from_world_position").contains("_build_expected_command_tokens_for_plan"), "Public waypoint does not derive command tokens locally")
	_assert(_public_method_body(controller_source, "plan_selected_fireteam_waypoint_from_world_position").contains("return submission"), "Public waypoint passes the canonical N003 receipt through unchanged")
	_assert(controller_source.contains("func _request_selected_mission_dropship_drop") and controller_source.contains("-> Dictionary"), "Dropship request producer returns a structured acceptance result")
	mission.queue_free()
	await process_frame


func _test_n003_plan_receipt_is_canonical_and_defensive() -> void:
	var gateway_script := load(COMMAND_GATEWAY_PATH) as GDScript
	var adapter_script := load(COMMAND_ENTRY_ADAPTER_PATH) as GDScript
	_assert(gateway_script != null and adapter_script != null, "N003 gateway and adapter scripts load")
	if gateway_script == null or adapter_script == null:
		return
	var gateway = gateway_script.new()
	var adapter = adapter_script.new()
	adapter.call("configure", gateway)
	var plan_result = adapter.call("plan_from_entry", "button", "take", PackedStringArray(["Bravo", "alpha", "bravo"]), Vector2(128.0, 96.0), 2, 7, "team_alpha")
	var receipt: Dictionary = Dictionary(plan_result.call("to_dict")) if plan_result != null and plan_result.has_method("to_dict") else {}
	var plan_id := String(receipt.get("plan_id", "")).strip_edges()
	var expected_tokens: Array = Array(receipt.get("expected_command_tokens", [])).duplicate(true)
	_assert(bool(receipt.get("accepted", false)) and not plan_id.is_empty(), "N003 adapter yields an accepted canonical plan receipt")
	_assert(Array(receipt.get("planned_fireteam_ids", [])) == ["bravo", "alpha"], "Canonical plan receipt exposes normalized planned Fireteams")
	_assert(expected_tokens == ["n003:%s:p7:bravo" % plan_id, "n003:%s:p7:alpha" % plan_id], "Canonical plan receipt exposes Gateway-owned expected tokens")
	_assert(not bool(receipt.get("pending", true)) and not bool(receipt.get("committed", true)), "Canonical plan receipt remains plan-only before GO")
	expected_tokens.append("tampered")
	receipt["expected_command_tokens"] = expected_tokens
	var defensive_receipt: Dictionary = Dictionary(plan_result.call("to_dict")) if plan_result != null and plan_result.has_method("to_dict") else {}
	_assert(not Array(defensive_receipt.get("expected_command_tokens", [])).has("tampered"), "Canonical plan receipt defensively copies expected tokens")
	var public_waypoint_plan = adapter.call("plan_from_entry", "public_world_waypoint", "take", PackedStringArray(["alpha"]), Vector2(160.0, 96.0), 2, 7, "team_alpha")
	var public_waypoint_receipt: Dictionary = Dictionary(public_waypoint_plan.call("to_dict")) if public_waypoint_plan != null and public_waypoint_plan.has_method("to_dict") else {}
	_assert(bool(public_waypoint_receipt.get("accepted", false)) and not Array(public_waypoint_receipt.get("expected_command_tokens", [])).is_empty(), "N003 accepts the public waypoint entry and returns its canonical receipt")


func _test_public_drop_respects_cooldown() -> void:
	var scene := load(MISSION_SCENE_PATH) as PackedScene
	_assert(scene != null, "Canonical mission loads for public drop cooldown behavior")
	if scene == null:
		return
	var mission := scene.instantiate()
	root.add_child(mission)
	await process_frame
	var controller := mission.get_node_or_null("TacticalController")
	_assert(controller != null, "Cooldown behavior uses the public TacticalController")
	if controller != null:
		var craft_id := "cooldown_probe"
		controller.call("set_planning_state", {
			"mission_drop_craft_id": craft_id,
			"mission_drop_state": "waiting",
			"drop_ship_staged": true,
			"has_lz_position": true,
			"lz_position": Vector2(128.0, 96.0),
			"mission_drop_cards": [{
				"craft_id": craft_id,
				"display_name": "Cooldown Probe",
				"state": "waiting",
				"has_lz_position": true,
				"lz_position": Vector2(128.0, 96.0),
				"drop_ship_staged": true,
			}],
		})
		controller.set("_drop_ship_cooldown_remaining", 12.0)
		var requested_before := bool(controller.get("_drop_ship_requested"))
		var receipt: Dictionary = Dictionary(controller.call("request_mission_dropship_drop", craft_id))
		_assert(not bool(receipt.get("accepted", true)) and String(receipt.get("reason", "")) == "drop_cooldown", "Public drop rejects a cooldown without a false acceptance")
		_assert(String(controller.get("_last_command_text")) == "DROP COOLDOWN 12.0S", "Public cooldown rejection formats its visible status without a runtime formatting error")
		_assert(bool(controller.get("_drop_ship_requested")) == requested_before, "Cooldown rejection does not start a drop sequence")
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
	var menu_call_graph := _build_local_call_graph(MENU_SOURCE_PATH)
	var meta_call_graph := _build_local_call_graph(META_FLOW_SOURCE_PATH)
	for forced_handler in [
		"_apply_release_start_mission_deeplink",
		"_apply_release_lz_drop_preview_deeplink",
		"_apply_release_first_go_firefight_deeplink",
		"_request_release_start_mission_from_homebase_for_deeplink",
		"_complete_release_lz_drop_preview_craft_arrival",
		"_force_release_first_engagement_decision",
	]:
		_assert(not Dictionary(meta_call_graph.get("functions", {})).has(forced_handler), "Product MetaLayer no longer compiles forced release handler %s" % forced_handler)
	for argument in ["--release-singleplayer", "--release-singleplayer-start-mission", "--release-singleplayer-lz-drop-preview", "--release-singleplayer-first-go-firefight"]:
		var menu = menu_script.new()
		var snapshot: Dictionary = Dictionary(menu.call("get_release_singleplayer_deeplink_snapshot", PackedStringArray([argument])))
		_assert(bool(snapshot.get("requested", false)), "%s remains observable in deeplink snapshot" % argument)
		_assert(bool(snapshot.get("deprecated", false)) and String(snapshot.get("status", "")) == "blocked" and String(snapshot.get("reason", "")) == "legacy_deeplink_no_public_path", "%s is deprecated without a gameplay handoff" % argument)
		menu.free()
		var call_chain: Array = _build_release_flag_call_chain(argument)
		_assert(_call_chain_is_reachable(menu_call_graph, call_chain), "%s follows the actual MainMenu blocked-release call graph: %s" % [argument, " -> ".join(PackedStringArray(call_chain))])
		_assert(not _call_graph_reaches_forbidden(menu_call_graph, String(call_chain.front()), ["_on_singleplayer_pressed", "_apply_release_start_mission_deeplink", "_apply_release_lz_drop_preview_deeplink", "_apply_release_first_go_firefight_deeplink"]), "%s reaches no forced/test handler from the blocked MainMenu entry branch" % argument)
		print("N004B_RELEASE_CALL_GRAPH %s: %s" % [argument, " -> ".join(PackedStringArray(call_chain))])
		var probe: Dictionary = _run_release_deeplink_probe_process(argument)
		_assert(bool(probe.get("probe_completed", false)), "%s starts the real MainMenu probe" % argument)
		_assert(String(probe.get("scene_path", "")) == MAIN_MENU_SCENE_PATH, "%s leaves the real MainMenu scene active" % argument)
		_assert(bool(probe.get("requested", false)) and not bool(probe.get("applied", true)), "%s has no Meta handoff in the real MainMenu run" % argument)
		_assert(bool(probe.get("deprecated", false)) and String(probe.get("status", "")) == "blocked" and String(probe.get("reason", "")) == "legacy_deeplink_no_public_path", "%s reports the stable public block reason in the real MainMenu run" % argument)
		_assert(not bool(probe.get("meta_layer_present", true)) and not bool(probe.get("mission_runtime_present", true)) and not bool(probe.get("simulation_root_present", true)), "%s real MainMenu run creates no MetaLayer or mission runtime" % argument)


func _build_release_flag_call_chain(_argument: String) -> Array:
	# Every accepted legacy singleplayer flag reaches the same explicitly blocked
	# MainMenu branch. The caller/callee edges themselves are verified below.
	return ["_apply_release_deeplink", "_apply_release_singleplayer_deeplink"]


func _build_local_call_graph(source_path: String) -> Dictionary:
	var function_bodies := _extract_local_function_bodies(FileAccess.get_file_as_string(source_path))
	var edges: Dictionary = {}
	for function_name_variant in function_bodies:
		var function_name := String(function_name_variant)
		edges[function_name] = _find_direct_local_calls(String(function_bodies[function_name]), function_bodies)
	return {"source_path": source_path, "functions": function_bodies, "edges": edges}


func _extract_local_function_bodies(source: String) -> Dictionary:
	var lines := source.split("\n")
	var headers: Array = []
	for line_index in range(lines.size()):
		var stripped := String(lines[line_index]).strip_edges()
		if not stripped.begins_with("func "):
			continue
		var open_paren := stripped.find("(")
		if open_paren < 5:
			continue
		var function_name := stripped.substr(5, open_paren - 5).strip_edges()
		if not function_name.is_empty():
			headers.append({"line": line_index, "name": function_name})
	var functions: Dictionary = {}
	for header_index in range(headers.size()):
		var header: Dictionary = Dictionary(headers[header_index])
		var start_line: int = int(header.get("line", 0)) + 1
		var end_line: int = int(Dictionary(headers[header_index + 1]).get("line", lines.size())) if header_index + 1 < headers.size() else lines.size()
		var body_lines := PackedStringArray()
		for body_line_index in range(start_line, end_line):
			body_lines.append(String(lines[body_line_index]))
		functions[String(header.get("name", ""))] = "\n".join(body_lines)
	return functions


func _find_direct_local_calls(body: String, local_functions: Dictionary) -> Array:
	var pattern := RegEx.new()
	pattern.compile("\\b([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")
	var calls: Array = []
	for match in pattern.search_all(body):
		var candidate := String(match.get_string(1))
		if local_functions.has(candidate) and not calls.has(candidate):
			calls.append(candidate)
	return calls


func _call_chain_is_reachable(call_graph: Dictionary, call_chain: Array) -> bool:
	if call_chain.size() < 2:
		return false
	var edges: Dictionary = Dictionary(call_graph.get("edges", {}))
	for index in range(1, call_chain.size()):
		var caller := String(call_chain[index - 1])
		var callee := String(call_chain[index])
		if not Array(edges.get(caller, [])).has(callee):
			return false
	return true


func _call_graph_reaches_forbidden(call_graph: Dictionary, start_function: String, forbidden_functions: Array) -> bool:
	var edges: Dictionary = Dictionary(call_graph.get("edges", {}))
	var pending: Array = [start_function]
	var visited: Dictionary = {}
	while not pending.is_empty():
		var current := String(pending.pop_front())
		if visited.has(current):
			continue
		visited[current] = true
		if forbidden_functions.has(current):
			return true
		for next_function_variant in Array(edges.get(current, [])):
			var next_function := String(next_function_variant)
			if not visited.has(next_function):
				pending.append(next_function)
	return false


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
	var mission_runtime_present := false
	var simulation_root_present := false
	for child in root_children:
		if child != null and (String(child.name) == "MetaLayer" or String(child.scene_file_path) == META_SCENE_PATH):
			meta_layer_present = true
		if child != null and (String(child.name) == "MissionRuntime" or String(child.scene_file_path) == MISSION_SCENE_PATH):
			mission_runtime_present = true
		if child != null and child.get_node_or_null("SimulationRoot") != null:
			simulation_root_present = true
	var release_argument := ""
	for argument in OS.get_cmdline_user_args():
		if String(argument).begins_with("--release-singleplayer"):
			release_argument = String(argument)
			break
	print("N004B_RELEASE_PROBE:%s" % JSON.stringify({
		"scene_path": String(menu.scene_file_path) if menu != null else "",
		"requested": bool(snapshot.get("requested", false)),
		"applied": bool(snapshot.get("applied", false)),
		"deprecated": bool(snapshot.get("deprecated", false)),
		"status": String(snapshot.get("status", "")),
		"reason": String(snapshot.get("reason", "")),
		"meta_layer_present": meta_layer_present,
		"mission_runtime_present": mission_runtime_present,
		"simulation_root_present": simulation_root_present,
		"release_call_chain": _build_release_flag_call_chain(release_argument),
	}))
	quit(0)


func _public_method_body(source: String, method_name: String) -> String:
	var start := source.find("func %s(" % method_name)
	if start < 0:
		return ""
	var end := source.find("\nfunc ", start + 1)
	return source.substr(start, end - start if end >= 0 else source.length() - start)


func _public_method_body_is_safe(source: String, method_name: String) -> bool:
	var body := _public_method_body(source, method_name)
	if body.is_empty():
		return false
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
