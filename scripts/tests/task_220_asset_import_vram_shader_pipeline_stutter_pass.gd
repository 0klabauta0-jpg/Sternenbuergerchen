extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/asset_vram_shader_pipeline_harness.gd")
const REPORT_PATH: String = "res://docs/performance/asset_vram_shader_pipeline_report.md"
const TASK_ID: String = "TASK_220"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_220 Asset Import VRAM Shader Pipeline Stutter Pass ===")
	var harness = HARNESS_SCRIPT.new()
	var result: Dictionary = await harness.run_all(root)
	_test_summary(result)
	_test_catalog_budgets(result)
	_test_asset_metrics(result)
	_test_pipeline_snapshot(result)
	_test_warmup(result)
	_test_report_exists()
	print("TASK_220 harness summary: %s" % JSON.stringify(result.get("summary", {})))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_summary(result: Dictionary) -> void:
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	_assert(int(summary.get("catalog_count", 0)) >= 3, "Harness covers central, weapon VFX and comic bubble catalogs")
	_assert(bool(summary.get("all_catalogs_have_performance_budget", false)), "All runtime asset catalogs expose TASK_220 performance budgets")
	_assert(int(summary.get("asset_count", 0)) >= 70, "Harness measures the curated asset expansion breadth")
	_assert(int(summary.get("texture_count", 0)) > 0, "Harness measures Texture2D assets")
	_assert(int(summary.get("glb_count", 0)) > 0, "Harness measures GLB/PackedScene assets")
	_assert(bool(summary.get("all_paths_res", false)), "All measured runtime asset paths stay res://")
	_assert(bool(summary.get("no_local_user_paths", false)), "Measured runtime asset paths contain no local user path")
	_assert(bool(summary.get("all_assets_loadable", false)), "All measured catalog assets load through ResourceLoader")
	_assert(bool(summary.get("has_texture_vram_estimate", false)), "Summary includes estimated texture VRAM")
	_assert(bool(summary.get("has_glb_material_metrics", false)), "Summary includes GLB material metrics")
	_assert(bool(summary.get("has_pipeline_snapshot", false)), "Summary includes first-run pipeline counters")
	_assert(bool(summary.get("warmup_side_effect_free", false)), "Warmup probe remains side-effect free")


func _test_catalog_budgets(result: Dictionary) -> void:
	var catalogs: Dictionary = Dictionary(result.get("catalogs", {}))
	for catalog_id in ["curated", "weapon_fire_vfx", "comic_bubbles"]:
		var catalog: Dictionary = Dictionary(catalogs.get(catalog_id, {}))
		var budget: Dictionary = Dictionary(catalog.get("performance_budget", {}))
		_assert(bool(catalog.get("has_performance_budget", false)), "%s catalog has performance budget metadata" % catalog_id)
		_assert(String(budget.get("task", "")) == TASK_ID, "%s catalog budget is tied to TASK_220" % catalog_id)
	var curated_budget: Dictionary = Dictionary(Dictionary(catalogs.get("curated", {})).get("performance_budget", {}))
	var weapon_budget: Dictionary = Dictionary(Dictionary(catalogs.get("weapon_fire_vfx", {})).get("performance_budget", {}))
	var comic_budget: Dictionary = Dictionary(Dictionary(catalogs.get("comic_bubbles", {})).get("performance_budget", {}))
	_assert(bool(curated_budget.get("runtime_paths_must_be_res", false)), "Curated catalog enforces res:// runtime paths")
	_assert(bool(weapon_budget.get("warmup_candidate", false)), "Weapon fire VFX catalog marks warmup candidates")
	_assert(bool(comic_budget.get("warmup_candidate", false)), "Comic bubble catalog marks warmup candidates")


func _test_asset_metrics(result: Dictionary) -> void:
	var assets: Dictionary = Dictionary(result.get("assets", {}))
	var texture_metrics: Array = Array(assets.get("texture_metrics", []))
	var glb_metrics: Array = Array(assets.get("glb_metrics", []))
	_assert(Array(assets.get("invalid_paths", [])).is_empty(), "Asset metrics found no non-res runtime paths")
	_assert(Array(assets.get("local_path_offenders", [])).is_empty(), "Asset metrics found no local user paths")
	_assert(Array(assets.get("load_failures", [])).is_empty(), "Asset metrics found no ResourceLoader failures")
	_assert(int(assets.get("estimated_texture_vram_bytes", 0)) > 0, "Asset metrics include total estimated texture VRAM")
	for metric_variant in texture_metrics:
		var metric: Dictionary = Dictionary(metric_variant)
		_assert(String(metric.get("path", "")).begins_with("res://"), "Texture path is res://: %s" % String(metric.get("id", "")))
		_assert(int(metric.get("width", 0)) > 0 and int(metric.get("height", 0)) > 0, "Texture has dimensions: %s" % String(metric.get("id", "")))
		_assert(int(metric.get("estimated_vram_bytes", 0)) > 0 and int(metric.get("estimated_vram_bytes", 0)) <= 67108864, "Texture VRAM estimate is bounded: %s" % String(metric.get("id", "")))
	for metric_variant in glb_metrics:
		var metric: Dictionary = Dictionary(metric_variant)
		_assert(String(metric.get("path", "")).begins_with("res://"), "GLB path is res://: %s" % String(metric.get("id", "")))
		_assert(int(metric.get("file_bytes", 0)) > 0 and int(metric.get("file_bytes", 0)) <= 20971520, "GLB file size is bounded: %s" % String(metric.get("id", "")))
		_assert(int(metric.get("mesh_instance_count", 0)) > 0, "GLB has mesh instances: %s" % String(metric.get("id", "")))
		_assert(int(metric.get("surface_count", 0)) > 0, "GLB has mesh surfaces: %s" % String(metric.get("id", "")))
		_assert(int(metric.get("material_count", -1)) >= 0, "GLB material count is reported: %s" % String(metric.get("id", "")))


func _test_pipeline_snapshot(result: Dictionary) -> void:
	var pipeline: Dictionary = Dictionary(result.get("pipeline", {}))
	var draw_budget: Dictionary = Dictionary(pipeline.get("draw_budget_snapshot", {}))
	var compilation: Dictionary = Dictionary(pipeline.get("pipeline_compilation_snapshot", {}))
	_assert(bool(pipeline.get("ok", false)), "Render spike scene returns a pipeline snapshot")
	for key in ["canvas", "mesh", "surface", "draw", "specialization"]:
		_assert(compilation.has(key), "Pipeline compilation snapshot exposes '%s'" % key)
	for key in ["objects_in_frame", "primitives_in_frame", "draw_calls_in_frame", "video_mem_used", "texture_mem_used", "buffer_mem_used"]:
		_assert(draw_budget.has(key), "Draw budget snapshot exposes '%s'" % key)


func _test_warmup(result: Dictionary) -> void:
	var warmup: Dictionary = Dictionary(result.get("warmup", {}))
	_assert(int(warmup.get("loaded_count", 0)) > 0, "Warmup probe loads hidden resources")
	_assert(int(warmup.get("texture_count", 0)) > 0, "Warmup probe covers texture resources")
	_assert(int(warmup.get("visible_side_effect_count", -1)) == 0, "Warmup probe creates no visible side effects")
	_assert(String(warmup.get("policy", "")).contains("hidden") and String(warmup.get("policy", "")).contains("no_gameplay_event"), "Warmup policy documents hidden no-event loading")


func _test_report_exists() -> void:
	var report: String = _read_text(REPORT_PATH)
	_assert(not report.is_empty(), "Asset VRAM shader pipeline report exists")
	for required_text in ["TASK_220", "VRAM", "Pipeline", "Warmup", "res://", "Video-RAM", "Profiler"]:
		_assert(report.contains(required_text), "Report documents '%s'" % required_text)


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
