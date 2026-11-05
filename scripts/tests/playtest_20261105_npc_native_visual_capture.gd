extends "res://scripts/tests/playtest_20261105_npc_combat_feedback_verifier.gd"
## Controlled visual fixture, never evidence of physical mission combat.
## Inherits every original public state transition and all 23 assertions.

const ISOLATION_GUARD: GDScript = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const HEALTH_CAPTURES: PackedStringArray = ["healthy", "wounded", "down", "healed", "down_again", "bleedout", "respawning", "respawned"]
var _capture_view: WeakRef = null
var _capture_unit: WeakRef = null
var _fixture_label: Label = null
var _report_path: String = ""
var _capture_dir: String = ""
var _screen_size: Vector2i = Vector2i.ZERO
var _captures: Array[Dictionary] = []
var _shot_images: Array[Dictionary] = []
var _capture_checks: Array[Dictionary] = []
var _last_health_key: String = ""
var _health_capture_index: int = 0
var _shot_started_msec: int = -1
var _expiry_captured: bool = false
var _view_index: int = 0


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("NPC_VISUAL_FIXTURE_CAPTURE requires a native display, not headless.")
		quit(2)
		return
	if not ISOLATION_GUARD.require_isolated_user_data():
		return
	_report_path = ProjectSettings.globalize_path(_capture_argument("--evidence-output", "res://output/playtest_20261105/npc_visual_fixture_%d.json" % Time.get_ticks_usec()))
	_capture_dir = _report_path.get_basename() + "_captures"
	if FileAccess.file_exists(_report_path):
		push_error("NPC visual fixture refuses to replace existing evidence: " + _report_path)
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	_screen_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	root.mode = Window.MODE_FULLSCREEN
	root.content_scale_size = _screen_size
	_install_fixture_label()
	for _frame in range(16):
		await process_frame
	_capture_expect(root.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN], "Actual native fullscreen window")
	_capture_expect(DisplayServer.window_get_size() == _screen_size, "Physical window covers active display")
	_capture_expect(is_equal_approx(Engine.time_scale, 1.0), "Actual 1x fixture time")
	await super._run()
	# The base quit() requests exit after this synchronous report is written.
	_capture_expect(_health_capture_index == HEALTH_CAPTURES.size(), "Every original owner health transition has a native image")
	_capture_expect(_shot_images.size() == 3 and _expiry_captured, "Synthetic shot captured early, at 120ms and after expiry")
	_capture_expect(_passed + _failed == 23, "All 23 original feedback assertions remain executed")
	var capture_failed: int = 0
	for check in _capture_checks:
		if not bool(check.passed):
			capture_failed += 1
	var report: Dictionary = {
		"scope": "CONTROLLED VISUAL FIXTURE; synthetic weapon payload; NOT physical combat acceptance",
		"base_verifier": "playtest_20261105_npc_combat_feedback_verifier.gd",
		"state_owner_calls": ["apply_damage", "apply_heal", "advance_bleedout", "begin_respawn", "respawn"],
		"product_changes_for_fixture": false,
		"base_passed": _passed, "base_failed": _failed,
		"capture_passed": _capture_checks.size() - capture_failed, "capture_failed": capture_failed,
		"display": _fixture_display(), "captures": _captures, "capture_checks": _capture_checks,
		"user_data_dir": OS.get_user_data_dir(),
	}
	var file: FileAccess = FileAccess.open(_report_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write NPC visual fixture report: " + _report_path)
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("NPC_VISUAL_FIXTURE_CAPTURE: %d passed, %d failed; %s" % [_capture_checks.size() - capture_failed, capture_failed, _report_path])
	quit(1 if _failed > 0 or capture_failed > 0 else 0)


func _make_view() -> Node:
	var view: Node = super._make_view()
	_view_index += 1
	_capture_view = weakref(view)
	_capture_unit = null
	view.set("_camera_size", 4.8)
	view.set("_camera_pitch_degrees", 34.0)
	view.set("_camera_yaw_degrees", 45.0)
	view.call("focus_world_position", Vector2(160.0, 160.0) if _view_index == 1 else Vector2(160.0, 128.0))
	view.call("_request_viewport_redraw", true, 1500)
	return view


func _make_unit(unit_id: String, team_id: String, position_value: Vector2) -> Node2D:
	var unit: Node2D = super._make_unit(unit_id, team_id, position_value)
	_capture_unit = weakref(unit)
	return unit


func _frames(count: int) -> void:
	await super._frames(count)
	var view: Node = _capture_view.get_ref() as Node if _capture_view != null else null
	if not is_instance_valid(view) or not view.is_inside_tree():
		return
	var unit: Node = _capture_unit.get_ref() as Node if _capture_unit != null else null
	if is_instance_valid(unit) and unit.is_inside_tree():
		await _capture_health_transition(view, unit)
		return
	if _view_index != 2:
		return
	var pulse := view.find_child("WeaponFireReadablePulse_*", true, false) as Node3D
	if _shot_started_msec < 0 and pulse != null and pulse.visible:
		_shot_started_msec = int(pulse.get("_started_msec"))
		_shot_images.append(await _read_shot_image(view, "09_synthetic_shot_early", 0))
		while Time.get_ticks_msec() < _shot_started_msec + 120:
			await process_frame
		_shot_images.append(await _read_shot_image(view, "10_synthetic_shot_120ms", 120))
		# Keep both GPU readbacks in memory. PNG encoding here could consume the
		# inherited flash assertion's 300ms lifetime before it inspects the pulse.
	elif _shot_started_msec >= 0 and not _expiry_captured and Time.get_ticks_msec() - _shot_started_msec > 850:
		_expiry_captured = true
		_shot_images.append(await _read_shot_image(view, "11_synthetic_shot_expired", 900))
		for sample in _shot_images:
			_save_fixture_image(sample)
		_capture_expect(int(_shot_images[1].actual_age_msec) >= 120, "Second readback is at least 120ms after event birth")
		_capture_expect(int(_shot_images[2].actual_age_msec) > 850 and not bool(_shot_images[2].pulse_visible), "Expired native frame has no surviving synthetic shot pulse")


func _capture_health_transition(view: Node, unit: Node) -> void:
	var state: String = String(unit.call("get_vital_state"))
	var health: int = int(unit.call("get_health"))
	var key: String = "%s:%d" % [state, health]
	if key == _last_health_key:
		return
	_last_health_key = key
	var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get(String(unit.get("unit_id"))) as Node3D
	if proxy == null:
		return
	var model: Node3D = view.call("_find_unit_model_root", proxy) as Node3D
	var weapon: Node = view.call("_find_unit_blaster_visual_node", proxy)
	var icon := proxy.get_node_or_null("UnitStateIcon") as Sprite3D
	var stage: String = HEALTH_CAPTURES[_health_capture_index] if _health_capture_index < HEALTH_CAPTURES.size() else state
	_health_capture_index += 1
	_fixture_label.text = "KONTROLLIERTE VISUALFIXTURE · kein physischer Kampfnachweis\n%s · %s · HP %d · Originalmodell %d" % [String(unit.get("unit_id")), stage, health, model.get_instance_id() if model != null else 0]
	view.call("_request_viewport_redraw", true, 100)
	await RenderingServer.frame_post_draw
	var sample: Dictionary = {
		"id": "%02d_%s" % [_health_capture_index, stage],
		"image": root.get_texture().get_image(), "wall_msec": Time.get_ticks_msec(),
		"unit_id": String(unit.get("unit_id")), "unit_instance_id": unit.get_instance_id(),
		"vital_state": state, "health": health, "actual_position": str((unit as Node2D).position),
		"model_instance_id": model.get_instance_id() if model != null else 0,
		"weapon_instance_id": weapon.get_instance_id() if weapon != null else 0,
		"model_rotation_degrees": str(model.rotation_degrees) if model != null else "",
		"model_visible": model.is_visible_in_tree() if model != null else false,
		"state_icon_visible": icon != null and icon.is_visible_in_tree(),
		"camera": _fixture_camera(view),
	}
	_save_fixture_image(sample)


func _read_shot_image(view: Node, capture_id: String, target_age_msec: int) -> Dictionary:
	_fixture_label.text = "KONTROLLIERTE VISUALFIXTURE · kein physischer Kampfnachweis\nSynthetischer Weaponpayload feedback_fire_once · Zielzeit %d ms" % target_age_msec
	view.call("_request_viewport_redraw", true, 100)
	await RenderingServer.frame_post_draw
	var result: Dictionary = {"id": capture_id, "target_age_msec": target_age_msec, "actual_age_msec": Time.get_ticks_msec() - _shot_started_msec, "image": root.get_texture().get_image(), "camera": _fixture_camera(view)}
	var pulse := view.find_child("WeaponFireReadablePulse_*", true, false) as Node3D
	var flash := pulse.get_node_or_null("MuzzleFlash") as Sprite3D if pulse != null else null
	var icon := pulse.get_node_or_null("FiringIcon") as Sprite3D if pulse != null else null
	result["pulse_visible"] = pulse != null and pulse.is_visible_in_tree()
	result["flash_visible"] = flash != null and flash.is_visible_in_tree()
	result["shot_icon_visible"] = icon != null and icon.is_visible_in_tree()
	result["event_id"] = "feedback_fire_once"
	result["synthetic_event"] = true
	return result


func _save_fixture_image(sample: Dictionary) -> void:
	var path: String = _capture_dir.path_join(String(sample.id) + ".png")
	var captured_image: Image = sample.get("image") as Image
	var saved: Error = ERR_ALREADY_EXISTS if FileAccess.file_exists(path) else (captured_image.save_png(path) if captured_image != null else ERR_INVALID_DATA)
	_capture_expect(saved == OK, "Native PNG saved: " + String(sample.id))
	var record: Dictionary = sample.duplicate()
	record.erase("image")
	record["path"] = path
	record["image_size"] = str(captured_image.get_size()) if captured_image != null else ""
	_captures.append(record)


func _install_fixture_label() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 70
	root.add_child(overlay)
	_fixture_label = Label.new()
	_fixture_label.position = Vector2(28, 24)
	_fixture_label.add_theme_font_size_override("font_size", 24)
	_fixture_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	_fixture_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_fixture_label.add_theme_constant_override("shadow_offset_x", 2)
	_fixture_label.add_theme_constant_override("shadow_offset_y", 2)
	_fixture_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fixture_label.text = "KONTROLLIERTE VISUALFIXTURE · kein physischer Kampfnachweis"
	overlay.add_child(_fixture_label)


func _fixture_camera(view: Node) -> Dictionary:
	return {"size": view.get("_camera_size"), "pitch": view.get("_camera_pitch_degrees"), "yaw": view.get("_camera_yaw_degrees"), "focus": str(view.get("_focus_grid_position"))}


func _fixture_display() -> Dictionary:
	return {"mode": root.mode, "screen_size": str(_screen_size), "window_size": str(DisplayServer.window_get_size()), "logical_viewport_size": str(root.get_visible_rect().size), "renderer": RenderingServer.get_current_rendering_method(), "display_server": DisplayServer.get_name(), "time_scale": Engine.time_scale}


func _capture_argument(key: String, fallback: String) -> String:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	for index in range(arguments.size() - 1):
		if arguments[index] == key:
			return arguments[index + 1]
	return fallback


func _capture_expect(condition: bool, message: String) -> void:
	_capture_checks.append({"passed": condition, "message": message})
	if not condition:
		push_error("NPC_VISUAL_FIXTURE_CAPTURE: " + message)
