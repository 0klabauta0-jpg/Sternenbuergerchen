extends SceneTree

const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const REFERENCE_MAP_PATH: String = "res://maps/editor_terrain_visual_recovery_reference.json"
const CONTRACT_PATH: String = "res://docs/dev/editor_terrain_visual_recovery_contract.md"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/editor_lighting_shadow_readability_checklist.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_293 Editor Lighting Shadow Readability Pass ===")
	await _test_light_snapshot_and_toggle()
	_test_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_light_snapshot_and_toggle() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", REFERENCE_MAP_PATH)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var light: Dictionary = Dictionary(snapshot.get("editor_light", {}))
	_assert(not light.is_empty(), "Render snapshot exposes editor light settings")
	_assert(_float_eq(float(light.get("energy", 0.0)), 1.18), "Editor light energy is centrally calibrated")
	var rotation: Vector3 = Vector3(light.get("rotation_degrees", Vector3.ZERO))
	_assert(_float_eq(rotation.x, -58.0) and _float_eq(rotation.y, -32.0), "Editor light direction matches visual contract")
	_assert(bool(light.get("shadow_enabled", false)), "Editor shadows are enabled by default")
	_assert(float(light.get("shadow_opacity", 1.0)) <= 0.45, "Editor shadows stay soft enough for wall and hangar readability")
	_assert(float(light.get("shadow_blur", 0.0)) >= 2.0, "Editor shadows use extra blur for readable object silhouettes")
	_assert(float(light.get("ambient_light_energy", 0.0)) >= 0.9, "Editor ambient fill prevents black wall sides")
	view.call("set_editor_shadow_readability_enabled", false)
	await _wait_frames(2)
	var disabled_snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(not bool(Dictionary(disabled_snapshot.get("editor_light", {})).get("shadow_enabled", true)), "Editor shadow debug hook can disable shadows")
	view.call("set_editor_shadow_readability_enabled", true)
	await _wait_frames(2)
	var enabled_snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(bool(Dictionary(enabled_snapshot.get("editor_light", {})).get("shadow_enabled", false)), "Editor shadow debug hook can restore shadows")
	view.queue_free()
	await _wait_frames(2)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(CONTRACT_PATH), "Visual contract documents lighting")
	_assert(_read_text(CONTRACT_PATH).contains("Editor light rotation"), "Visual contract contains light rotation")
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Manual lighting checklist exists")
	var checklist: String = _read_text(MANUAL_CHECK_PATH)
	for required_text in ["wall", "rock", "cactus", "bush", "shadows"]:
		_assert(checklist.to_lower().contains(required_text), "Lighting checklist covers %s" % required_text)


func _float_eq(actual: float, expected: float) -> bool:
	return absf(actual - expected) <= 0.001


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
