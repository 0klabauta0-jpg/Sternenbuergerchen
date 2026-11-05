extends "res://art/frontier_illustrated_20261101/environment/pass05/buildings/look_probe.gd"
## Reuses the existing mesh audit with new, non-overwriting REVIEW8 evidence.
## Captures are synthetic geometry views; normal mission proof stays separate.
const ACCESS = preload("res://scripts/terrain/frontier_access_anchors.gd")
const PRIMARY_REFERENCE := "res://docs/reports/assets/ui-2026-11-01/mockup_a5_mission_zweireihig.png"
const CONSTRUCTION_REFERENCE := "res://docs/reports/assets/grafik-2026-11-01/references/current/02_freihafen_distribution_center.png"
var _output_dir := ""
var _capture_metadata: Array = []


func _argument(key: String, fallback: String = "") -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size()):
		if args[index] == key and index + 1 < args.size():
			return args[index + 1]
		if args[index].begins_with(key + "="):
			return args[index].trim_prefix(key + "=")
	return fallback


func _run() -> void:
	var stamp := Time.get_datetime_string_from_system(true).replace(":", "").replace("-", "")
	_output_dir = _argument("--graphics-output", "res://output/review_graphics_20261105/hall_" + stamp + "_pid" + str(OS.get_process_id())).trim_suffix("/") + "/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_output_dir)):
		push_error("REVIEW8 graphics evidence target exists; refusing overwrite: " + _output_dir)
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir)) != OK:
		push_error("Cannot create REVIEW8 graphics evidence: " + _output_dir)
		quit(2)
		return
	for hall in [false, true]:
		var shell := AFTER.new()
		root.add_child(shell)
		var original: AABB = HALL if hall else HAB
		shell.build(original, hall)
		await process_frame
		_audit(shell, original, "hall" if hall else "habitat")
		_check(shell.get_meta("access_anchor") == ACCESS.building(original, hall), "original access anchor remains unchanged")
		shell.free()
	for fact in _diagnostics:
		_check(int(fact["mesh_count"]) <= 65 and int(fact["triangles"]) <= 3000, String(fact["id"]) + " stays within original assembly budget")
	_check(_diagnostics.size() == 2, "both building audits completed")
	if OS.get_cmdline_user_args().has("--render"):
		_check(DisplayServer.get_name() != "headless", "captures require native renderer")
		if _failed == 0:
			_setup_world()
			await _capture_current()
	var report := {
		"schema": "sternenbuergerchen.review8.hall_graphics.v1",
		"passed": _passed, "failed": _failed,
		"engine": Engine.get_version_info(),
		"builder_sha256": FileAccess.get_sha256("res://scripts/terrain/frontier_closed_buildings.gd"),
		"source_hashes": _source_hashes(),
		"primary_reference": {"path": PRIMARY_REFERENCE, "sha256": FileAccess.get_sha256(PRIMARY_REFERENCE)},
		"construction_reference": {"path": CONSTRUCTION_REFERENCE, "sha256": FileAccess.get_sha256(CONSTRUCTION_REFERENCE)},
		"diagnostics": _diagnostics, "captures": _capture_metadata,
		"synthetic_fixture": true,
		"scope": "Existing finite/winding/topology/envelope/connectivity audit, assembly budget and original access anchor. Native controlled geometry captures. No mission or general mesh intersection oracle."
	}
	var file := FileAccess.open(_output_dir + "geometry.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write REVIEW8 geometry evidence")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("REVIEW8_GRAPHICS ", JSON.stringify({"passed": _passed, "failed": _failed, "evidence": _output_dir + "geometry.json"}))
	quit(1 if _failed else 0)


func _source_hashes() -> Dictionary:
	var result := {}
	for path in [
		"res://scripts/terrain/frontier_closed_buildings.gd",
		"res://shaders/terrain/frontier_building_wear.gdshader",
		"res://scripts/terrain/frontier_art_profile.gd",
		"res://scripts/terrain/frontier_access_anchors.gd",
		"res://art/frontier_illustrated_20261101/environment/pass05/buildings/look_probe.gd",
		"res://scripts/tests/review8_graphics_verifier.gd",
		"res://project.godot",
	]:
		result[path] = FileAccess.get_sha256(path)
	return result


func _capture_current() -> void:
	for id in ["hall", "ensemble"]:
		_clear_stage()
		for hall in ([false, true] if id == "ensemble" else [true]):
			var shell := AFTER.new()
			_stage.add_child(shell)
			shell.build(HALL if hall else HAB, hall)
			if id == "ensemble":
				shell.position.x = 2.15 if hall else -2.15
		for view in (["front", "rear", "side"] if id == "hall" else ["game"]):
			var direction := Vector3(1.2, 1.30, 1.7)
			if view == "rear":
				direction = Vector3(-1.2, 1.30, -1.7)
			elif view == "side":
				direction = Vector3(-1.7, 1.0, 0.25)
			var target := Vector3(0.0, 0.75, 0.0)
			_camera.size = 9.5 if id == "ensemble" else 4.9
			_camera.position = target + direction.normalized() * 14.0
			_camera.look_at(target)
			for frame in range(8):
				await process_frame
			await RenderingServer.frame_post_draw
			var path: String = _output_dir + "native_" + String(id) + "_" + String(view) + ".png"
			var result := root.get_texture().get_image().save_png(path)
			_check(result == OK, "native capture " + id + "/" + view)
			_capture_metadata.append({
				"building": id, "view": view, "path": path,
				"sha256": FileAccess.get_sha256(path) if result == OK else "",
				"camera": str(_camera.transform), "camera_size": _camera.size,
				"resolution": str(root.size), "light": "unchanged FrontierArtProfile",
				"renderer": RenderingServer.get_current_rendering_method() + "/" + RenderingServer.get_current_rendering_driver_name()
			})
