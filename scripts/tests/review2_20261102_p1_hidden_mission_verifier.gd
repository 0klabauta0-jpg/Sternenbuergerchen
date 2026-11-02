extends SceneTree

# Regression: changing only the visible meta screen must not stop the active
# mission while its monotonic timer continues. All runtime startup is guarded.
const GUARD_PATH: String = "res://scripts/tests/review2_isolated_user_guard.gd"
const META_NAV_PATH: String = "Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/"
const TACTICAL_NAV_PATH: String = "TacticalUI/TopNavPanel/NavMargin/NavRow/"

var _passed: int = 0
var _failed: int = 0
var _samples: Array = []


func _initialize() -> void:
	var guard: GDScript = load(GUARD_PATH)
	if guard == null or not bool(guard.call("require_isolated_user_data")):
		quit(2)
		return
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Review 2 P1 hidden active mission lifecycle ===")
	root.size = Vector2i(1920, 1080)
	var menu: Node = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await _frames(5)
	if not _press(menu, "MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton", "Normal Singleplayer button is actionable"):
		_finish()
		return
	for _index in range(120):
		if current_scene != null and current_scene.scene_file_path == "res://scenes/meta/meta_layer_test.tscn":
			break
		await process_frame
	var flow: Node = current_scene
	_assert(flow != null and flow.scene_file_path == "res://scenes/meta/meta_layer_test.tscn", "Normal Singleplayer opens the real meta flow")
	if flow == null or flow.scene_file_path != "res://scenes/meta/meta_layer_test.tscn":
		_finish()
		return
	await _frames(8)
	if not _press(flow.get_node("HomebaseScreen"), "Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton", "Normal Start Mission button is actionable"):
		_finish()
		return
	for _index in range(120):
		if flow.call("get_active_mission") != null:
			break
		await process_frame
	var mission: Node = flow.call("get_active_mission")
	_assert(mission != null, "Normal Start Mission creates an active mission")
	if mission == null:
		_finish()
		return
	await _frames(8)
	var original_mission_id: int = mission.get_instance_id()
	var timer_start: int = int(flow.get("_active_mission_started_at_msec"))
	_assert(not bool(mission.get_node("TacticalController").get("preview_mode")), "The normal mission is live rather than preview")
	var controller: Node = mission.get_node("TacticalController")
	var los_before: bool = bool(controller.call("is_los_debug_overlay_enabled"))
	await _send_los_hotkey()
	_assert(bool(controller.call("is_los_debug_overlay_enabled")) != los_before, "Visible mission consumes the real LOS hotkey")
	var visible_before: Dictionary = _sample(flow, mission)
	await create_timer(0.35).timeout
	var visible_after: Dictionary = _sample(flow, mission)
	_assert(int(visible_after["tick"]) > int(visible_before["tick"]), "Visible mission advances before navigation")
	_samples.append({"phase": "visible", "before": visible_before, "after": visible_after})

	# These diagnostic units use the normal mission's actual registry, command,
	# effect and respawn paths. They are not a campaign/playability fixture.
	var fixture: Dictionary = _make_runtime_fixture(mission)
	_assert(not fixture.is_empty(), "Diagnostic units use legal indexed mission terrain")
	if fixture.is_empty():
		_finish()
		return
	for view: String in ["homebase", "fob"]:
		var nav_name: String = "HomebaseNavButton" if view == "homebase" else "FOBNavButton"
		if not _press(mission, TACTICAL_NAV_PATH + nav_name, "Visible mission navigation opens " + view):
			break
		await _frames(3)
		_assert(String(flow.get("_current_meta_view")) == view, "Navigation shows " + view)
		_assert(not paused, "Meta navigation does not pause the SceneTree")
		_assert(not mission.visible, "Hidden mission's 2D world is not visible")
		_assert(not mission.get_node("TacticalUI/TopNavPanel").visible and not mission.get_node("TacticalUI/BottomDock").visible, "Hidden tactical controls stay hidden")
		var primary_view: CanvasLayer = mission.get_node_or_null("Primary3DView") as CanvasLayer
		_assert(primary_view != null and not primary_view.visible, "Hidden mission's separate 3D CanvasLayer is hidden")
		var tactical: Node = mission.get_node("TacticalController")
		_assert(tactical.can_process(), "Hidden tactical runtime remains active")
		_assert(not tactical.is_processing_unhandled_input(), "Hidden tactical commands do not receive input")
		_assert(not mission.get_node("MissionCamera").can_process(), "Hidden mission camera does not poll gameplay input")
		var hidden_los_before: bool = bool(tactical.call("is_los_debug_overlay_enabled"))
		await _send_los_hotkey()
		_assert(bool(tactical.call("is_los_debug_overlay_enabled")) == hidden_los_before, "Hidden mission ignores a real tactical hotkey")
		await _assert_hidden_runtime_progress(flow, mission, fixture, view)
		var meta_screen: Node = flow.get_node("HomebaseScreen" if view == "homebase" else "FOBScreen")
		if not _press(meta_screen, META_NAV_PATH + "MissionNavButton", "Meta Mission button returns from " + view):
			break
		await _frames(3)
		_assert(flow.call("get_active_mission") == mission and mission.get_instance_id() == original_mission_id, "Returning retains the same mission instance")
		_assert(int(flow.get("_active_mission_started_at_msec")) == timer_start, "Returning retains the original monotonic mission timer")
		_assert(mission.visible and bool(tactical.get("_tactical_ui_visible")), "Returning restores mission world and tactical UI")
		_assert(tactical.is_processing_unhandled_input() and mission.get_node("MissionCamera").can_process(), "Returning restores tactical and camera input")
		_assert(primary_view.visible, "Returning restores the 3D presentation")

	await _assert_preview_still_disabled(flow, mission)
	print("REVIEW2_HIDDEN_MISSION_SAMPLES=" + JSON.stringify(_samples))
	flow.queue_free()
	current_scene = null
	await _frames(4)
	_finish()


func _assert_hidden_runtime_progress(flow: Node, mission: Node, fixture: Dictionary, view: String) -> void:
	var simulation: Node = mission.get_node("SimulationRoot")
	var respawns: Node = mission.get_node("RespawnManager")
	var mover: Node2D = fixture["mover"]
	var casualty: Node2D = fixture["casualty"]
	var health_before: int = int(mover.call("get_health"))
	var before: Dictionary = _sample(flow, mission)
	var position_before: Vector2 = mover.position
	var requested: bool = bool(respawns.call("request_respawn", casualty.get("unit_id"), casualty.get("team_id"), "rover"))
	_assert(requested or bool(respawns.call("has_pending_respawn", casualty.get("unit_id"))), view + ": a real respawn is pending")
	var respawn_before: float = float(respawns.call("get_remaining_time", casualty.get("unit_id")))
	var target: Vector2 = fixture["target"] if view == "homebase" else fixture["start"]
	simulation.call("enqueue_command", {
		"command_type": "move_to_position", "unit_id": mover.get("unit_id"),
		"team_id": mover.get("team_id"), "target_position": target,
		"move_speed_factor": 0.25, "requeue_until_target": true,
		"command_token": "review2_hidden_" + view,
	})
	simulation.call("enqueue_effect", {
		"effect_type": "damage", "unit_id": mover.get("unit_id"), "damage": 7,
		"hit_chance": 1.0, "roll_override": 0.0, "target_cover_override": 0.0,
	})
	await create_timer(0.7).timeout
	var after: Dictionary = _sample(flow, mission)
	var respawn_after: float = float(respawns.call("get_remaining_time", casualty.get("unit_id")))
	_assert(int(after["tick"]) > int(before["tick"]), view + ": hidden SimulationRoot physics ticks advance")
	_assert(int(after["combat_tick"]) > int(before["combat_tick"]), view + ": hidden CombatLoopDriver follows authoritative ticks")
	_assert(mover.position.distance_to(position_before) > 0.1, view + ": a queued authoritative move executes while hidden")
	_assert(int(mover.call("get_health")) < health_before, view + ": a queued authoritative damage effect executes while hidden")
	_assert(respawn_after < respawn_before and respawn_after > 0.0, view + ": real respawn countdown advances while hidden")
	_assert(float(after["remaining_seconds"]) < float(before["remaining_seconds"]), view + ": monotonic timer and simulation both advance")
	_samples.append({"phase": view, "before": before, "after": after, "move_distance": mover.position.distance_to(position_before), "health_before": health_before, "health_after": mover.call("get_health"), "respawn_before": respawn_before, "respawn_after": respawn_after})


func _make_runtime_fixture(mission: Node) -> Dictionary:
	var terrain: Node = mission.get_node("TerrainRegistry")
	var start: Vector2
	var target: Vector2
	var found: bool = false
	for tile in terrain.call("get_sorted_tiles"):
		var grid: Vector2i = tile.grid_position
		var neighbor := grid + Vector2i.RIGHT
		if terrain.call("is_walkable", grid) and terrain.call("is_walkable", neighbor) and terrain.call("get_height_at", grid) == terrain.call("get_height_at", neighbor):
			start = terrain.call("grid_to_world", grid)
			target = terrain.call("grid_to_world", neighbor)
			found = true
			break
	if not found:
		return {}
	var unit_script: GDScript = load("res://scripts/npc/test_unit.gd")
	var units: Array = []
	for suffix: String in ["mover", "casualty"]:
		var unit: Node2D = unit_script.new()
		unit.name = "Review2_" + suffix
		unit.set("unit_id", "review2_" + suffix)
		unit.set("team_id", "review2_diagnostic")
		unit.set("fireteam_id", "review2_diagnostic")
		unit.position = start if suffix == "mover" else target + Vector2(0.0, 64.0)
		mission.add_child(unit)
		mission.get_node("UnitRegistry").call("register_unit", unit.get("unit_id"), unit)
		units.append(unit)
	return {"mover": units[0], "casualty": units[1], "start": start, "target": target}


func _assert_preview_still_disabled(flow: Node, active_mission: Node) -> void:
	var preview: Node = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	flow.call("_configure_mission_instance", preview, PackedStringArray(), PackedStringArray(), true)
	active_mission.get_parent().add_child(preview)
	await _frames(3)
	flow.call("_sync_mission_host_visibility")
	var preview_simulation: Node = preview.get_node("SimulationRoot")
	var preview_tick: int = int(preview_simulation.call("get_tick"))
	await create_timer(0.2).timeout
	_assert(bool(preview.get_node("TacticalController").get("preview_mode")), "Explicit preview retains preview mode")
	_assert(not preview_simulation.can_process() and int(preview_simulation.call("get_tick")) == preview_tick, "Preview simulation stays disabled even when host is visible")
	_assert(not preview.get_node("CombatLoopDriver").can_process() and not preview.get_node("RespawnManager").can_process(), "Preview combat and respawn stay disabled")
	preview.queue_free()
	await _frames(2)


func _sample(flow: Node, mission: Node) -> Dictionary:
	return {
		"view": String(flow.get("_current_meta_view")),
		"tick": int(mission.get_node("SimulationRoot").call("get_tick")),
		"combat_tick": int(mission.get_node("CombatLoopDriver").get("_current_tick")),
		"simulation_can_process": mission.get_node("SimulationRoot").can_process(),
		"remaining_seconds": float(mission.get_node("CombatLoopDriver").call("get_remaining_time_limit_seconds")),
	}


func _press(owner: Node, path: String, message: String) -> bool:
	var button: Button = owner.get_node_or_null(path) as Button
	var actionable: bool = button != null and not button.disabled and button.is_visible_in_tree()
	_assert(actionable, message)
	if actionable:
		button.pressed.emit()
	return actionable


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _send_los_hotkey() -> void:
	var bindings: Array[InputEvent] = InputMap.action_get_events("tactical_toggle_los")
	_assert(not bindings.is_empty() and bindings[0] is InputEventKey, "LOS action has a real keyboard binding")
	if bindings.is_empty() or not bindings[0] is InputEventKey:
		return
	var key: InputEventKey = bindings[0].duplicate() as InputEventKey
	key.pressed = true
	root.push_input(key)
	await process_frame
	key.pressed = false
	root.push_input(key)
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		print("FAIL: " + message)


func _finish() -> void:
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed == 0:
		print("REVIEW2_P1_HIDDEN_MISSION: ALL PASSED")
	quit(1 if _failed > 0 else 0)
