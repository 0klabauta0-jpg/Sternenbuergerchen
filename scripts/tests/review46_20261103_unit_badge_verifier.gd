extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const UNIT = preload("res://scripts/npc/test_unit.gd")
const REGISTRY = preload("res://scripts/registries/unit_registry.gd")
const SIMULATION = preload("res://scripts/core/simulation_root.gd")
const RESPAWN = preload("res://scripts/core/respawn_manager.gd")

# Count the real expensive helpers and forward every invocation unchanged. A
# badge-only revision must not turn into another skeleton/vital visual update.
class CountingView:
	extends "res://scripts/terrain/terrain_map_3d_view.gd"
	var aim_calls: int = 0
	var vital_calls: int = 0
	var redraw_calls: int = 0

	func _update_unit_weapon_aim_pose(proxy: Node3D, active_fire_event: Dictionary, weapon_posture: String = "lowered", aim_direction: Vector2 = Vector2.ZERO, cached_weapon_node: Node3D = null, cached_skeleton: Skeleton3D = null, cached_animation_player: AnimationPlayer = null) -> bool:
		aim_calls += 1
		return super._update_unit_weapon_aim_pose(proxy, active_fire_event, weapon_posture, aim_direction, cached_weapon_node, cached_skeleton, cached_animation_player)

	func _update_unit_vital_visual(proxy: Node3D, unit: Node, cached_model_root: Node3D = null) -> bool:
		vital_calls += 1
		return super._update_unit_vital_visual(proxy, unit, cached_model_root)

	func _request_viewport_redraw(continuous: bool = false, duration_msec: int = CONTINUOUS_REDRAW_AFTER_CAMERA_MSEC) -> void:
		redraw_calls += 1
		super._request_viewport_redraw(continuous, duration_msec)


var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	_test_live_badge_revisions()
	_test_real_respawn_countdown()
	print("REVIEW46_UNIT_BADGE_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_live_badge_revisions() -> void:
	var fixture: Node = Node.new()
	fixture.name = "BadgeLiveFixture"
	root.add_child(fixture)
	var unit: Node2D = _make_unit(fixture, "badge_live")
	var view: CountingView = _make_view(fixture, unit)
	var proxy: Node3D = _proxy(view, unit)
	var badge: Label3D = _badge(proxy)
	_check(proxy != null and badge != null, "Public set_unit_nodes builds an actual proxy and Label3D badge")
	if proxy == null or badge == null:
		fixture.free()
		return
	_check(badge.text == "IDLE" and badge.visible, "Initial live unit has a visible IDLE badge")
	var initial_runtime: Dictionary = Dictionary(unit.call("get_runtime_status").call("to_dict"))
	_check(String(initial_runtime.get("movement_posture", "")) == "crouch" and String(initial_runtime.get("weapon_posture", "")) == "lowered", "Fixture starts with an explicit posture recognized by runtime normalization")
	var initial_counts: Vector2i = Vector2i(view.aim_calls, view.vital_calls)
	var initial_redraw_calls: int = view.redraw_calls
	for _index in range(8):
		_step(view)
	_check(Vector2i(view.aim_calls, view.vital_calls) == initial_counts, "Unchanged process frames retain the expensive visual fast path")
	_check(view.redraw_calls == initial_redraw_calls, "Unchanged stationary payload does not request additional viewport redraws")
	var initial_proxy_id: int = proxy.get_instance_id()
	var initial_badge_id: int = badge.get_instance_id()

	# MissionCombatLoopDriver._set_contact_visuals/_clear_unit_contact_states
	# use this public runtime setter independently of model, HP or posture.
	var redraw_before_contact: int = view.redraw_calls
	unit.call("set_contact_state", true, "known_enemy")
	_step(view)
	_check(badge.text == "CONTACT" and badge.visible, "Contact-only runtime change updates the actual visible badge in the next frame")
	_check(badge.modulate.is_equal_approx(Color(1.0, 0.78, 0.34, 1.0)), "Contact-only change updates badge color")
	_check(view.redraw_calls > redraw_before_contact, "Contact-only badge revision requests a viewport redraw")
	unit.call("set_contact_state", false, "")
	_step(view)
	_check(badge.text == "IDLE" and badge.visible, "Clearing contact restores the actual IDLE badge")
	_check(Vector2i(view.aim_calls, view.vital_calls) == initial_counts, "Contact badge changes do not rerun skeleton or vital work")

	# Keep legal postures and geometry identical while changing the command and
	# status values that the existing badge reader displays.
	var redraw_before_source: int = view.redraw_calls
	_check(_set_runtime(unit, "idle", "take"), "Public runtime setter accepts a source-command-only update")
	_step(view)
	_check(badge.text == "TAKE" and badge.visible, "Source-command-only runtime update reaches the actual badge")
	_check(view.redraw_calls > redraw_before_source, "Source-command-only badge revision requests a viewport redraw")
	_check(_set_runtime(unit, "assigned", ""), "Public runtime setter accepts a status-only update")
	_step(view)
	_check(badge.text == "READY" and badge.visible, "Status-only runtime update reaches the actual badge")
	var assigned_runtime: Dictionary = Dictionary(unit.call("get_runtime_status").call("to_dict"))
	_check(assigned_runtime.get("movement_posture") == initial_runtime.get("movement_posture") and assigned_runtime.get("weapon_posture") == initial_runtime.get("weapon_posture"), "Status-only test preserves actual normalized movement and weapon postures")
	print("REVIEW46_BADGE_POSTURE_JSON=", JSON.stringify({"initial": initial_runtime, "assigned": assigned_runtime, "initial_helper_counts": initial_counts, "assigned_helper_counts": Vector2i(view.aim_calls, view.vital_calls)}))
	_check(Vector2i(view.aim_calls, view.vital_calls) == initial_counts, "Status/source changes with unchanged posture retain the expensive fast path")
	_set_runtime(unit, "idle", "")
	_step(view)

	# The tactical controller publishes shot readiness independently of the
	# overwatch posture. Only the badge color changes on this second frame.
	unit.set_meta("overwatch_ready", true)
	unit.set_meta("overwatch_shot_ready", true)
	_step(view)
	_check(badge.text == "DEF" and badge.visible, "Overwatch state displays a visible DEF badge")
	var overwatch_counts: Vector2i = Vector2i(view.aim_calls, view.vital_calls)
	unit.set_meta("overwatch_shot_ready", false)
	_step(view)
	_check(badge.text == "DEF" and badge.modulate.is_equal_approx(Color(0.48, 0.72, 0.78, 0.9)), "Shot-readiness-only change refreshes the actual DEF badge color")
	_check(Vector2i(view.aim_calls, view.vital_calls) == overwatch_counts, "Shot-readiness badge color does not rerun skeleton or vital work")

	view.call("set_order_visual_payload", {"world_label_density_mode": "release_firefight_declutter"})
	_step(view)
	_check(not badge.visible, "Public world-label declutter hides the existing routine badge")
	view.call("set_order_visual_payload", {"world_label_density_mode": "default"})
	_step(view)
	_check(badge.visible and badge.text == "DEF", "Leaving declutter restores the same existing badge")
	_check(Vector2i(view.aim_calls, view.vital_calls) == overwatch_counts, "Declutter revisions do not rerun skeleton or vital work")

	# A change while the parent proxy is hidden must not leave the child label
	# hidden when that same unit becomes visible again.
	unit.visible = false
	unit.call("apply_damage", 10, {"event_id": "badge_hidden_damage"})
	_step(view)
	_check(not proxy.visible, "Runtime unit visibility hides the actual proxy")
	unit.visible = true
	_step(view)
	_check(proxy.visible and badge.visible and badge.text == "HP 90/100", "Revealing an unchanged wounded unit restores the actual badge after its hidden update")
	_check(proxy.get_instance_id() == initial_proxy_id and badge.get_instance_id() == initial_badge_id, "Badge-only and visibility changes preserve proxy and Label3D identity")
	var settled_counts: Vector2i = Vector2i(view.aim_calls, view.vital_calls)
	for _index in range(8):
		_step(view)
	_check(Vector2i(view.aim_calls, view.vital_calls) == settled_counts, "Settled visible badge changes leave later frames on the expensive fast path")
	fixture.free()


func _test_real_respawn_countdown() -> void:
	var fixture: Node = Node.new()
	fixture.name = "BadgeRespawnFixture"
	root.add_child(fixture)
	var registry: Node = REGISTRY.new()
	registry.name = "UnitRegistry"
	fixture.add_child(registry)
	var simulation: Node = SIMULATION.new()
	simulation.name = "SimulationRoot"
	simulation.set("unit_registry_path", NodePath("../UnitRegistry"))
	fixture.add_child(simulation)
	simulation.set_physics_process(false)
	var manager: Node = RESPAWN.new()
	manager.name = "RespawnManager"
	manager.set("unit_registry_path", NodePath("../UnitRegistry"))
	manager.set("simulation_root_path", NodePath("../SimulationRoot"))
	fixture.add_child(manager)
	manager.set_physics_process(false)
	var unit: Node2D = _make_unit(fixture, "badge_respawn")
	_check(bool(registry.call("register_unit", "badge_respawn", unit)), "Real respawn fixture registers the actual runtime unit")
	unit.call("set_respawn_manager", manager)
	unit.call("apply_damage", 100, {"event_id": "badge_respawn_down"})
	_check(bool(manager.call("request_respawn", "badge_respawn", "team_alpha", "rover")), "Real RespawnManager enters the ordinary rover countdown")
	_check(String(unit.call("get_vital_state")) == "respawning" and int(unit.call("get_respawn_remaining_seconds")) == 30, "Runtime unit reads the real initial 30-second respawn timer")
	var view: CountingView = _make_view(fixture, unit)
	var proxy: Node3D = _proxy(view, unit)
	var badge: Label3D = _badge(proxy)
	_check(badge != null and badge.visible and badge.text == "RESPAWN 30s", "Initial real respawn timer has a visible actual badge")
	if badge == null:
		fixture.free()
		return
	var before_counts: Vector2i = Vector2i(view.aim_calls, view.vital_calls)
	var redraw_before_timer: int = view.redraw_calls
	var before_proxy_id: int = proxy.get_instance_id()
	var before_badge_id: int = badge.get_instance_id()
	manager.call("_physics_process", 1.1)
	_check(int(unit.call("get_respawn_remaining_seconds")) == 29, "Ordinary RespawnManager physics advances its own timer to 29 display seconds")
	_step(view)
	_check(badge.visible and badge.text == "RESPAWN 29s", "Timer-only physics change updates the actual visible badge in the next frame")
	_check(view.redraw_calls > redraw_before_timer, "Timer-only badge revision requests a viewport redraw")
	_check(Vector2i(view.aim_calls, view.vital_calls) == before_counts, "Timer-only badge refresh does not rerun skeleton or vital work")
	_check(proxy.get_instance_id() == before_proxy_id and badge.get_instance_id() == before_badge_id, "Countdown retains existing proxy and badge nodes")
	fixture.free()


func _make_unit(fixture: Node, id: String) -> Node2D:
	var unit: Node2D = UNIT.new()
	unit.name = id
	unit.set("unit_id", id)
	unit.set("team_id", "team_alpha")
	unit.set("fireteam_id", "blue")
	unit.set("weapon_1_id", "rifle")
	unit.set("weapon_2_id", "rifle")
	fixture.add_child(unit)
	unit.set_process(false)
	unit.position = Vector2(0.0, 64.0)
	_set_runtime(unit, "idle", "")
	return unit


func _make_view(fixture: Node, unit: Node) -> CountingView:
	var view: CountingView = CountingView.new()
	fixture.add_child(view)
	view.set_process(false)
	view.call("configure_from_map", MAP.create_empty("review46_badge", Vector2i(4, 4), Vector2.ZERO, 64.0, 32.0, 3))
	view.call("set_unit_nodes", [unit])
	_step(view)
	return view


func _set_runtime(unit: Node, status: String, source: String) -> bool:
	# "idle" is not an explicit recognized input of normalize_movement_posture:
	# with status=assigned it falls back to tactical. Crouch is recognized for
	# every status, so status/source-only fixtures genuinely preserve the pose.
	return bool(unit.call("set_runtime_status", status, "", 0, "fire_at_will", source, 1.0, 0.0, 0.0, -1, null, "crouch", "lowered", "", 1.0, 0.0))


func _step(view: CountingView) -> void:
	# Exactly the normal rendered-frame entry point, with no sleeps, throttle
	# manipulation, force_rebuild, repeated set_unit_nodes or direct badge calls.
	view.call("_process", 1.0 / 60.0)


func _proxy(view: Node, unit: Node) -> Node3D:
	return Dictionary(view.get("_unit_proxies_by_id")).get(String(unit.call("get_unit_id")), null) as Node3D


func _badge(proxy: Node3D) -> Label3D:
	return proxy.get_node_or_null("UnitStateBadge") as Label3D if proxy != null else null


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)
