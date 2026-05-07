extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/ui_hud_comic_bubble_performance_harness.gd")
const REPORT_PATH: String = "res://docs/performance/ui_hud_comic_bubble_profile_report.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_219 UI HUD Meta Comic Bubble Performance Pass ===")
	var harness = HARNESS_SCRIPT.new()
	var result: Dictionary = await harness.run_all(root)
	_test_summary(result)
	_test_screen_counts(result)
	_test_bubble_modes(result)
	_test_theme_reuse(result)
	_test_report_exists()
	print("TASK_219 harness summary: %s" % JSON.stringify(result.get("summary", {})))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_summary(result: Dictionary) -> void:
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	_assert(int(summary.get("screen_count", 0)) >= 4, "Harness covers Homebase, FOB, Mission-HUD and Main Menu")
	_assert(bool(summary.get("has_homebase", false)), "Summary includes Homebase")
	_assert(bool(summary.get("has_fob", false)), "Summary includes FOB")
	_assert(bool(summary.get("has_mission_hud", false)), "Summary includes Mission-HUD")
	_assert(bool(summary.get("has_main_menu", false)), "Summary includes Main Menu")
	_assert(bool(summary.get("has_ui_counts", false)), "Summary marks UI control counts")
	_assert(bool(summary.get("fixed_window_stable", false)), "Summary keeps fixed Drop-Light window size")
	_assert(bool(summary.get("bubble_off_zero", false)), "Summary marks off-mode zero bubble nodes")
	_assert(bool(summary.get("bubble_normal_capped", false)), "Summary marks normal-mode bubble cap")
	_assert(bool(summary.get("thought_hidden_zero", false)), "Summary marks hidden thoughts as zero nodes")
	_assert(bool(summary.get("thought_hold_bounded", false)), "Summary marks thought hold as bounded")
	_assert(bool(summary.get("theme_reuse_enabled", false)), "Summary marks Theme StyleBox reuse")


func _test_screen_counts(result: Dictionary) -> void:
	var screens: Dictionary = Dictionary(result.get("screens", {}))
	for screen_id in ["homebase", "fob", "mission_hud", "main_menu"]:
		var screen: Dictionary = Dictionary(screens.get(screen_id, {}))
		var counts: Dictionary = Dictionary(screen.get("counts", {}))
		var fixed_window: Dictionary = Dictionary(screen.get("fixed_window", {}))
		_assert(bool(screen.get("ok", false)), "%s screen instantiates" % String(screen_id))
		_assert(int(counts.get("control_count", 0)) > 0, "%s exposes Control count" % String(screen_id))
		_assert(int(counts.get("label_count", 0)) > 0, "%s exposes Label count" % String(screen_id))
		_assert(int(counts.get("button_count", 0)) >= 0 and int(counts.get("panel_container_count", 0)) >= 0, "%s exposes button/panel counts" % String(screen_id))
		_assert(bool(fixed_window.get("matches_target", false)), "%s keeps target window size during perf probe" % String(screen_id))


func _test_bubble_modes(result: Dictionary) -> void:
	var bubbles: Dictionary = Dictionary(result.get("bubbles", {}))
	var off_mode: Dictionary = Dictionary(bubbles.get("off", {}))
	var minimal_mode: Dictionary = Dictionary(bubbles.get("minimal", {}))
	var normal_mode: Dictionary = Dictionary(bubbles.get("normal", {}))
	var thought_hidden: Dictionary = Dictionary(bubbles.get("thought_hidden", {}))
	var thought_hold: Dictionary = Dictionary(bubbles.get("thought_hold", {}))
	_assert(int(Dictionary(off_mode.get("gate", {})).get("emitted_count", -1)) == 0, "Off mode emits zero bubble payloads")
	_assert(int(Dictionary(off_mode.get("render", {})).get("feedback_bubble_visual_count", -1)) == 0, "Off mode renders zero bubble nodes")
	_assert(int(Dictionary(minimal_mode.get("gate", {})).get("emitted_count", 0)) > 0, "Minimal mode keeps important bubbles")
	_assert(int(Dictionary(minimal_mode.get("gate", {})).get("emitted_count", 99)) < int(Dictionary(minimal_mode.get("gate", {})).get("input_count", 0)), "Minimal mode suppresses non-important bubbles")
	_assert(int(Dictionary(normal_mode.get("render", {})).get("feedback_bubble_visual_count", 99)) <= 4, "Normal mode render count obeys max bubble cap")
	_assert(int(Dictionary(thought_hidden.get("render", {})).get("feedback_bubble_visual_count", -1)) == 0, "Thoughts hidden without hold render zero nodes")
	_assert(int(Dictionary(thought_hold.get("render", {})).get("feedback_bubble_visual_count", 99)) <= 4, "Thought hold render count stays bounded")
	_assert(int(Dictionary(thought_hold.get("render", {})).get("feedback_bubble_visual_count", 0)) > 0, "Thought hold can render bounded thought nodes")


func _test_theme_reuse(result: Dictionary) -> void:
	var theme: Dictionary = Dictionary(result.get("theme", {}))
	var cache_snapshot: Dictionary = Dictionary(theme.get("cache_snapshot", {}))
	_assert(bool(theme.get("same_stylebox_reused", false)), "TacticalUITheme reuses identical StyleBoxFlat resources")
	_assert(bool(theme.get("different_stylebox_distinct", false)), "TacticalUITheme keeps distinct StyleBoxFlat variants separate")
	_assert(bool(cache_snapshot.get("stylebox_reuse_enabled", false)), "Theme cache snapshot marks reuse enabled")
	_assert(int(cache_snapshot.get("flat_stylebox_cache_count", 0)) >= 2, "Theme cache records reused and distinct StyleBoxes")


func _test_report_exists() -> void:
	var report: String = _read_text(REPORT_PATH)
	_assert(not report.is_empty(), "UI HUD Comic Bubble profile report exists")
	_assert(report.contains("TASK_219") and report.contains("Homebase") and report.contains("FOB"), "Report documents TASK_219 screen matrix")
	_assert(report.contains("Comic-Bubbles") and report.contains("StyleBox"), "Report documents bubble and theme reuse scope")
	_assert(report.contains("Fixed Window") and report.contains("Profiler"), "Report documents fixed window and profiler residual risk")


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
