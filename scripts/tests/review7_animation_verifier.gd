extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const UNIT = preload("res://scripts/npc/test_unit.gd")

# Observe the real request and preserve its actual SubViewport side effect.
class CountingView:
	extends "res://scripts/terrain/terrain_map_3d_view.gd"
	var redraw_calls: int = 0
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
	var fixture := Node.new()
	root.add_child(fixture)
	var unit: Node2D = UNIT.new()
	unit.set("unit_id", "review7_live_animation")
	unit.set("team_id", "team_alpha")
	unit.set("fireteam_id", "blue")
	unit.set("weapon_1_id", "rifle")
	unit.set("weapon_2_id", "rifle")
	fixture.add_child(unit)
	unit.set_process(false)
	unit.set_physics_process(false)
	unit.position = Vector2(0.0, 64.0)
	_set_posture(unit, "tactical")
	var view := CountingView.new()
	fixture.add_child(view)
	view.set_process(false)
	view.call("configure_from_map", MAP.create_empty("review7_animation", Vector2i(4, 4), Vector2.ZERO, 64.0, 32.0, 3))
	view.call("set_unit_nodes", [unit])
	await _settle(view)
	# Let the real bootstrap redraw deadline expire. Never patch a viewport
	# mode, cached signature or dirty flag to manufacture UPDATE_ONCE coverage.
	await create_timer(1.35).timeout
	view.call("_process", 1.0 / 60.0)
	await process_frame
	await process_frame
	var cases: Array = []
	for posture in ["tactical", "crouch"]:
		_set_posture(unit, posture)
		await _settle(view)
		var facts: Dictionary = await _observe(view, unit, 1.0 / 60.0, 36)
		facts["posture"] = posture
		cases.append(facts)
		_check(bool(facts.get("fixture_ok", false)), "%s uses the real visible animated model, player and skeleton" % posture)
		_check(String(facts.get("animation_name", "")) == ("idle" if posture == "tactical" else "crouchIdle"), "%s exercises the expected stable idle clip" % posture)
		_check(int(facts.get("time_changed_frames", 0)) > 0 and int(facts.get("bone_changed_frames", 0)) > 0, "%s positive-delta frames advance actual animation time and bone poses" % posture)
		_check(int(facts.get("pose_changed_without_redraw_frames", -1)) == 0, "%s every observed bone-pose change requests a real viewport redraw" % posture)
		_check(int(facts.get("redraw_calls", 0)) > 0 and bool(facts.get("all_redraws_use_update_once", false)), "%s stable clip redraws through UPDATE_ONCE after bootstrap" % posture)
	var runtime: Dictionary = Dictionary(Dictionary(view.get("_unit_proxy_runtime_by_id")).get(String(unit.call("get_unit_id")), {}))
	var player: AnimationPlayer = runtime.get("animation_player", null) as AnimationPlayer
	if player != null:
		player.speed_scale = 0.0
		await _settle(view)
		var frozen: Dictionary = await _observe(view, unit, 1.0 / 60.0, 12)
		_check(int(frozen.get("time_changed_frames", -1)) == 0 and int(frozen.get("bone_changed_frames", -1)) == 0, "Frozen real animation leaves time and bone poses unchanged")
		_check(int(frozen.get("redraw_calls", -1)) == 0, "Frozen animation does not request recurring redraws")
		player.speed_scale = 1.0
		await _settle(view)
		var zero_delta: Dictionary = await _observe(view, unit, 0.0, 12)
		_check(int(zero_delta.get("time_changed_frames", -1)) == 0 and int(zero_delta.get("redraw_calls", -1)) == 0, "Zero-delta settled frames neither advance animation nor request redraws")
		unit.visible = false
		await _settle(view)
		var hidden: Dictionary = await _observe(view, unit, 1.0 / 60.0, 12)
		_check(not bool(hidden.get("proxy_visible", true)), "Ordinary runtime unit visibility hides the real proxy")
		_check(int(hidden.get("redraw_calls", -1)) == 0, "Hidden animation does not request recurring viewport redraws")
		unit.visible = true
		await _settle(view)
		var revealed: Dictionary = await _observe(view, unit, 1.0 / 60.0, 12)
		_check(bool(revealed.get("proxy_visible", false)) and int(revealed.get("bone_changed_frames", 0)) > 0 and int(revealed.get("pose_changed_without_redraw_frames", -1)) == 0, "Revealing the same animated proxy restores pose redraws")
	else:
		_check(false, "Frozen/hidden controls require the real AnimationPlayer")
	view.call("set_unit_nodes", [])
	await _settle(view)
	var redraw_before_static: int = view.redraw_calls
	for _frame in range(12):
		view.call("_process", 1.0 / 60.0)
		await process_frame
	_check(view.redraw_calls == redraw_before_static, "Static terrain with no animated units does not request recurring redraws")
	print("REVIEW7_ANIMATION_FACTS ", JSON.stringify({"cases": cases, "real_assets": true, "headless_is_not_pixel_capture": true}))
	fixture.free()
	await process_frame
	print("REVIEW7_ANIMATION_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _observe(view: CountingView, unit: Node2D, delta: float, frames: int) -> Dictionary:
	var unit_id: String = String(unit.call("get_unit_id"))
	var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get(unit_id, null) as Node3D
	var runtime: Dictionary = Dictionary(Dictionary(view.get("_unit_proxy_runtime_by_id")).get(unit_id, {}))
	var player: AnimationPlayer = runtime.get("animation_player", null) as AnimationPlayer
	var skeleton: Skeleton3D = runtime.get("skeleton", null) as Skeleton3D
	if proxy == null or player == null or skeleton == null:
		return {"fixture_ok": false}
	var previous_time: float = player.current_animation_position
	var previous_pose: Array = _bone_poses(skeleton)
	var before_redraw: int = view.redraw_calls
	var time_changed_frames: int = 0
	var bone_changed_frames: int = 0
	var pose_changed_without_redraw_frames: int = 0
	var all_redraws_use_update_once: bool = true
	var viewport: SubViewport = view.get("_subviewport") as SubViewport
	for _frame in range(frames):
		var redraw_before_frame: int = view.redraw_calls
		view.call("_process", delta)
		var current_pose: Array = _bone_poses(skeleton)
		var pose_changed: bool = false
		for index in range(current_pose.size()):
			if not Transform3D(current_pose[index]).is_equal_approx(Transform3D(previous_pose[index])):
				pose_changed = true
				break
		if pose_changed:
			bone_changed_frames += 1
			if view.redraw_calls == redraw_before_frame:
				pose_changed_without_redraw_frames += 1
		if not is_equal_approx(player.current_animation_position, previous_time):
			time_changed_frames += 1
		if view.redraw_calls > redraw_before_frame and viewport.render_target_update_mode != SubViewport.UPDATE_ONCE:
			all_redraws_use_update_once = false
		previous_time = player.current_animation_position
		previous_pose = current_pose
		await process_frame
	return {
		"fixture_ok": proxy.visible and bool(proxy.get_meta("uses_animated_character_model", false)) and skeleton.get_bone_count() > 0,
		"proxy_visible": proxy.visible, "animation_name": String(player.current_animation),
		"time_changed_frames": time_changed_frames, "bone_changed_frames": bone_changed_frames,
		"pose_changed_without_redraw_frames": pose_changed_without_redraw_frames,
		"redraw_calls": view.redraw_calls - before_redraw,
		"all_redraws_use_update_once": all_redraws_use_update_once,
	}


func _settle(view: CountingView) -> void:
	for _frame in range(12):
		view.call("_process", 1.0 / 60.0)
		await process_frame


func _bone_poses(skeleton: Skeleton3D) -> Array:
	var poses: Array = []
	for index in range(skeleton.get_bone_count()):
		poses.append(skeleton.get_bone_pose(index))
	return poses


func _set_posture(unit: Node, posture: String) -> void:
	unit.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, posture, "lowered", "", 1.0, 0.0)


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)
