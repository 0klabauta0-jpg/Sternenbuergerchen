extends SceneTree

const SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
var passed := 0
var failed := 0

func _init() -> void: call_deferred("run")

func run() -> void:
	print("=== TASK_1097 Connected Interaction Feedback Visual Evidence ===")
	var scene := SCENE.instantiate(); root.add_child(scene); await process_frame
	var controller := scene.get_node("TacticalController")
	var label := controller.get_node_or_null(controller.get("command_feedback_label_path")) as Label
	_assert(label != null, "Command feedback label exists")
	var minimum_before := label.custom_minimum_size
	var colors := {}
	for tone in ["pending", "progress", "success", "blocked"]:
		controller.call("_refresh_network_interaction_command_feedback_label", "COM 42% | 8/18s", tone)
		colors[tone] = label.get_theme_color("font_color").to_html(true)
		_assert(String(label.get_meta("network_interaction_tone", "")) == tone, "%s tone metadata is applied" % tone)
	_assert(Dictionary(colors).values().duplicate().size() == 4 and colors.pending != colors.progress and colors.progress != colors.success and colors.success != colors.blocked, "All feedback tones use distinct colors")
	_assert(label.custom_minimum_size == minimum_before, "Tone styling does not resize label")
	_assert(label.get_theme_constant("outline_size") >= 2, "Feedback keeps readable outline")
	_assert(String(label.get_meta("network_interaction_style_key", "")) == "danger", "Blocked tone maps to established danger style")
	scene.queue_free(); await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed]); quit(1 if failed else 0)

func _assert(ok: bool, text: String) -> void:
	if ok: passed += 1; print("PASS: %s" % text)
	else: failed += 1; push_error("FAIL: %s" % text)
