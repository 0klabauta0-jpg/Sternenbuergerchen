extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SETUP = preload("res://scripts/tests/mission_test_setup.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const FOW = preload("res://scripts/core/fog_of_war_system.gd")
const LOS = preload("res://scripts/core/los_system.gd")
const UNIT = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	var holder := Node.new()
	root.add_child(holder)
	var map_data = MAP.create_empty("review7_real_fow_view", Vector2i(32, 32), Vector2.ZERO, 64.0, 32.0, 3)
	var registry: Node = REGISTRY.new()
	holder.add_child(registry)
	registry.call("configure_iso_grid", Vector2.ZERO, 64.0, 32.0)
	for tile in map_data.get_tiles():
		registry.call("register_tile", tile)
	var observer: Node2D = _unit(holder, "review7_observer", "team_alpha", Vector2(registry.call("grid_to_world", Vector2i(16, 16))))
	var target: Node2D = _unit(holder, "review7_target", "team_bravo", observer.position + Vector2(20.0, 0.0))
	var view: Node = VIEW.new()
	holder.add_child(view)
	view.set_process(false)
	view.call("configure_from_map", map_data)
	view.call("set_unit_nodes", [observer, target])
	var fog = FOW.new()
	var setup: Node = SETUP.new()
	setup.set("_is_initialized", true)
	setup.set("_fog_of_war_system", fog)
	setup.set("_fog_of_war_los_system", LOS.new())
	setup.set("_fog_terrain_registry", registry)
	setup.set("_fog_unit_nodes", [observer, target])
	setup.set("_fog_observer_unit_nodes", [observer])
	setup.set("_terrain_3d_view", view)
	setup.set("fog_of_war_mode", "unexplored_blackout")
	setup.set("fog_of_war_sight_range_world", 160.0)
	holder.add_child(setup)
	setup.set_process(false)
	setup.call("_sync_fog_of_war_visual_state", true)
	for _slice in range(8):
		if String(setup.get("_fog_requested_runtime_signature")).is_empty():
			break
		setup.call("_advance_fog_of_war_visibility_work")
	_check(String(setup.get("_fog_requested_runtime_signature")).is_empty(), "Real mission setup completes its terrain visibility job")
	_check(int(fog.build_team_state_snapshot("team_alpha").get("visibility_revision", 0)) == 1, "Initial real FoW publication has one committed terrain revision")
	var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get("review7_target", null) as Node3D
	_check(proxy != null and proxy.visible, "Real view initially displays the in-range enemy proxy")
	# Render one normal 512-tile slice. The 1024-tile overlay must still be
	# in flight when the next target-only update reaches the real consumer.
	view.call("_process", 1.0 / 60.0)
	var pending_before: Dictionary = _overlay_state(view)
	_check(bool(pending_before["pending"]) and int(pending_before["cursor"]) > 0 and int(pending_before["mesh_id"]) != 0, "Fixture observes a real partially built FoW MultiMesh")
	target.position = observer.position + Vector2(500.0, 0.0)
	setup.call("_sync_fog_of_war_visual_state", false)
	_check(not fog.is_visible("team_alpha", "review7_target") and proxy != null and not proxy.visible, "Target-only update hides the actual out-of-range proxy while overlay is pending")
	_assert_overlay_retained(pending_before, _overlay_state(view), "Pending overlay target removal")
	target.position = observer.position + Vector2(30.0, 0.0)
	setup.call("_sync_fog_of_war_visual_state", false)
	_check(fog.is_visible("team_alpha", "review7_target") and proxy != null and proxy.visible, "Target-only update reveals the same real proxy while overlay is pending")
	_assert_overlay_retained(pending_before, _overlay_state(view), "Pending overlay target return")
	_drain_overlay(view)
	var completed_before: Dictionary = _overlay_state(view)
	_check(not bool(completed_before["pending"]) and int(completed_before["full_rebuilds"]) == 1, "Initial overlay finishes exactly once despite dynamic target updates")
	_check(int(completed_before["safety_id"]) == 0, "Completed real overlay removes its safety blackout")
	target.position = observer.position + Vector2(500.0, 0.0)
	setup.call("_sync_fog_of_war_visual_state", false)
	_check(proxy != null and not proxy.visible, "Completed overlay still hides the out-of-range target immediately")
	_assert_overlay_retained(completed_before, _overlay_state(view), "Completed overlay target removal")
	target.position = observer.position + Vector2(40.0, 0.0)
	setup.call("_sync_fog_of_war_visual_state", false)
	_check(proxy != null and proxy.visible, "Completed overlay still reveals the returning target immediately")
	_assert_overlay_retained(completed_before, _overlay_state(view), "Completed overlay target return")
	for _frame in range(4):
		view.call("_process", 1.0 / 60.0)
	_check(int(view.get("_fow_overlay_full_rebuild_count")) == 1, "Target-only updates do not schedule a delayed extra terrain rebuild")
	_check(int(fog.build_team_state_snapshot("team_alpha").get("visibility_revision", 0)) == 1, "Target-only consumer updates leave the terrain revision unchanged")
	# The optimization must retain the ordinary invalidation boundaries.
	var mesh_before_mode: int = int(_overlay_state(view)["mesh_id"])
	setup.call("set_fog_of_war_mode", "known_terrain")
	for _slice in range(8):
		if String(setup.get("_fog_requested_runtime_signature")).is_empty():
			break
		setup.call("_advance_fog_of_war_visibility_work")
	_check(int(_overlay_state(view)["mesh_id"]) != mesh_before_mode, "A real FoW mode change still invalidates terrain visuals")
	_drain_overlay(view)
	var mesh_before_team: int = int(_overlay_state(view)["mesh_id"])
	fog.set_mode_for_team("team_bravo", "known_terrain")
	view.call("set_fog_of_war_state", fog.build_team_state_snapshot("team_bravo"))
	_check(int(_overlay_state(view)["mesh_id"]) != mesh_before_team, "A viewer-team change still invalidates terrain visuals")
	print("REVIEW7_FOW_VIEW_FACTS ", JSON.stringify({"pending_before": pending_before, "completed_before": completed_before, "final_overlay": _overlay_state(view), "real_view": true, "headless_is_not_pixel_capture": true}))
	holder.free()
	await process_frame
	print("REVIEW7_FOW_VIEW_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _overlay_state(view: Node) -> Dictionary:
	var mesh: Node = view.get("_fow_overlay_multimesh_instance") as Node
	var safety: Node = view.get("_fow_overlay_safety_cover") as Node
	return {
		"mesh_id": mesh.get_instance_id() if mesh != null and is_instance_valid(mesh) else 0,
		"safety_id": safety.get_instance_id() if safety != null and is_instance_valid(safety) else 0,
		"pending": bool(view.get("_fow_overlay_full_rebuild_pending")),
		"cursor": int(view.get("_fow_overlay_pending_cursor")),
		"full_rebuilds": int(view.get("_fow_overlay_full_rebuild_count")),
	}


func _assert_overlay_retained(before: Dictionary, after: Dictionary, label: String) -> void:
	_check(int(after["mesh_id"]) == int(before["mesh_id"]), label + " retains the exact terrain MultiMesh instance")
	_check(int(after["cursor"]) == int(before["cursor"]) and bool(after["pending"]) == bool(before["pending"]), label + " retains exact cursor and pending state")
	_check(int(after["safety_id"]) == int(before["safety_id"]), label + " retains the existing safety-cover lifecycle")
	_check(int(after["full_rebuilds"]) == int(before["full_rebuilds"]), label + " retains the full-rebuild count")


func _drain_overlay(view: Node) -> void:
	for _frame in range(16):
		if not bool(view.get("_fow_overlay_full_rebuild_pending")):
			return
		view.call("_process", 1.0 / 60.0)
	_check(false, "Real overlay finishes within the bounded frame count")


func _unit(holder: Node, id: String, team: String, position: Vector2) -> Node2D:
	var unit: Node2D = UNIT.new()
	unit.set("unit_id", id)
	unit.set("team_id", team)
	unit.set("weapon_1_id", "rifle")
	unit.set("weapon_2_id", "rifle")
	holder.add_child(unit)
	unit.set_process(false)
	unit.set_physics_process(false)
	unit.position = position
	return unit


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)
