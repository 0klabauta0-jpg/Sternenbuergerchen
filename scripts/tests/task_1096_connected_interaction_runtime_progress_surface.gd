extends SceneTree

const SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
var passed := 0
var failed := 0

func _init() -> void: call_deferred("run")

func run() -> void:
	print("=== TASK_1096 Connected Interaction Runtime Progress Surface ===")
	var scene := SCENE.instantiate(); root.add_child(scene); await process_frame
	var controller := scene.get_node("TacticalController")
	controller.set("_network_mission_interaction_feedback", {"interaction_id":"aa_shutdown_zone"})
	var progress_snapshot := {"interaction_states":{"aa_shutdown_zone":{"state":"complete","complete":true,"progress":1.0,"hold_seconds":0.0,"duration_seconds":0.0,"interaction_type":"hold_zone"},"station_computer":{"state":"operating","complete":false,"progress":0.42,"hold_seconds":8.0,"duration_seconds":18.0,"interaction_type":"computer"}}}
	_assert(bool(controller.call("_apply_network_mission_interaction_progress_surface", progress_snapshot)), "First replicated progress updates surface")
	var first := Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(String(first.get("compact_line","")) == "COM 42% | 8/18s", "Computer progress is compact")
	_assert(String(first.get("interaction_id","")) == "station_computer", "Active Computer progress outranks completed AA state")
	_assert(not bool(controller.call("_apply_network_mission_interaction_progress_surface", progress_snapshot)), "Identical snapshot is deduplicated")
	var duplicate := Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(int(duplicate.get("progress_update_count",0)) == 1, "Dedup keeps one label update")
	var cargo := {"interaction_states":{"cargo_landing_hold":{"state":"holding","complete":false,"progress":0.58,"hold_seconds":7.0,"duration_seconds":12.0,"interaction_type":"hold_zone"}}}
	_assert(bool(controller.call("_apply_network_mission_interaction_progress_surface", cargo)), "New interaction updates surface")
	_assert(String(Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot")).get("compact_line","")) == "CARGO HALTEN | 7/12s", "Cargo hold uses player language")
	var done := {"interaction_states":{"cargo_landing_hold":{"state":"complete","complete":true,"progress":1.0,"hold_seconds":12.0,"duration_seconds":12.0,"interaction_type":"hold_zone"}}}
	_assert(bool(controller.call("_apply_network_mission_interaction_progress_surface", done)), "Completion updates surface")
	var final := Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(String(final.get("compact_line","")) == "CARGO FERTIG" and String(final.get("tone","")) == "success", "Completion is concise and positive")
	_assert(not bool(final.get("ui_sets_gameplay_truth", true)), "Progress surface remains read-only")
	scene.queue_free(); await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed]); quit(1 if failed else 0)

func _assert(ok: bool, text: String) -> void:
	if ok: passed += 1; print("PASS: %s" % text)
	else: failed += 1; push_error("FAIL: %s" % text)
