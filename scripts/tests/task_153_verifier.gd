extends SceneTree

const MATERIAL_PRESET_FACTORY_SCRIPT: GDScript = preload("res://scripts/rendering/material_preset_factory.gd")
const BENCHMARK_SCENE_PATH: String = "res://scenes/tests/transparent_material_benchmark.tscn"
const DOC_PATH: String = "res://docs/rendering/3d_transparency_material_presets.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_153 3D Transparency Material Presets Verifier ===")
	_test_factory_contract_and_presets()
	_test_material_modes()
	_test_benchmark_scene_loads_and_builds_previews()
	_test_docs_status_and_rules()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_factory_contract_and_presets() -> void:
	var preset_ids: PackedStringArray = MATERIAL_PRESET_FACTORY_SCRIPT.call("get_preset_ids")
	var contract: Dictionary = Dictionary(MATERIAL_PRESET_FACTORY_SCRIPT.call("build_preset_contract"))
	var presets: Dictionary = Dictionary(contract.get("presets", {}))
	for preset_id in ["cutout_scissor", "dither_hash", "true_blend"]:
		_assert(preset_ids.has(preset_id), "Factory exposes preset id %s" % preset_id)
		_assert(presets.has(preset_id), "Preset contract documents %s" % preset_id)
	_assert(bool(contract.get("visual_only", false)) and not bool(contract.get("ui_sets_gameplay_truth", true)), "Preset contract is visual-only")


func _test_material_modes() -> void:
	var cutout: StandardMaterial3D = MATERIAL_PRESET_FACTORY_SCRIPT.call("create_material", "cutout_scissor", Color(1, 1, 1, 0.75))
	var hash: StandardMaterial3D = MATERIAL_PRESET_FACTORY_SCRIPT.call("create_material", "dither_hash", Color(1, 1, 1, 0.55))
	var blend: StandardMaterial3D = MATERIAL_PRESET_FACTORY_SCRIPT.call("create_material", "true_blend", Color(1, 1, 1, 0.45))
	_assert(cutout.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, "cutout_scissor uses Alpha Scissor")
	_assert(cutout.alpha_scissor_threshold > 0.0, "cutout_scissor has alpha threshold")
	_assert(hash.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_HASH, "dither_hash uses Alpha Hash")
	_assert(float(hash.get("alpha_hash_scale")) > 0.0, "dither_hash has hash scale")
	_assert(blend.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "true_blend uses Alpha Blend")
	_assert(blend.albedo_color.a < 1.0, "true_blend keeps translucent albedo")
	_assert(blend.depth_draw_mode == BaseMaterial3D.DEPTH_DRAW_ALWAYS, "true_blend uses explicit depth draw mode")


func _test_benchmark_scene_loads_and_builds_previews() -> void:
	var packed_scene: PackedScene = load(BENCHMARK_SCENE_PATH)
	_assert(packed_scene != null, "Transparent material benchmark scene loads")
	if packed_scene == null:
		return
	var scene: Node = packed_scene.instantiate()
	scene.call("build_preview_nodes")
	root.add_child(scene)
	var snapshot: Dictionary = Dictionary(scene.call("get_benchmark_snapshot"))
	_assert(bool(snapshot.get("visual_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Benchmark scene is visual-only")
	_assert(int(snapshot.get("preset_node_count", 0)) == 3, "Benchmark scene builds three preset preview nodes")
	var preset_ids: Array = []
	for node_variant in Array(snapshot.get("preset_nodes", [])):
		var node_snapshot: Dictionary = Dictionary(node_variant)
		preset_ids.append(String(node_snapshot.get("preset_id", "")))
		_assert(bool(node_snapshot.get("has_mesh", false)) and bool(node_snapshot.get("has_material", false)), "Preview node has mesh and material")
	_assert(preset_ids.has("cutout_scissor") and preset_ids.has("dither_hash") and preset_ids.has("true_blend"), "Benchmark scene shows all preset ids")
	scene.queue_free()


func _test_docs_status_and_rules() -> void:
	var task_text: String = _read_text("res://docs/tasks/TASK_153_3d_transparency_material_presets.md")
	var status_text: String = _read_text("res://docs/IMPLEMENTATION_STATUS.md")
	var roadmap_text: String = _read_text("res://docs/TASK_ROADMAP.md")
	var doc_text: String = _read_text(DOC_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_153 implemented")
	_assert(task_text.contains("- [ ] Manuelle Beispielszene oeffnen und Presets visuell pruefen."), "Task keeps visual scene check as explicit manual rest")
	_assert(status_text.contains("### TASK_153 - 3D Transparency Material Presets") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_153 implemented")
	_assert(roadmap_text.contains("TASK_153 - 3D Transparency Material Presets (implementiert)"), "Roadmap marks TASK_153 implemented")
	for token in ["cutout_scissor", "dither_hash", "true_blend", "Alpha Scissor", "Alpha Hash", "Alpha Blend", "Benchmark-Szene", "Keine Gameplay-Kopplung"]:
		_assert(doc_text.contains(token), "Transparency preset docs mention %s" % token)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
