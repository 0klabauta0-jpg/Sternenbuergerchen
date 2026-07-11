extends SceneTree

const SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
var passed := 0
var failed := 0

func _init() -> void: call_deferred("run")

func run() -> void:
	print("=== TASK_1098 Connected Interaction Progress Performance Budget ===")
	var scene := SCENE.instantiate(); root.add_child(scene); await process_frame
	var controller := scene.get_node("TacticalController")
	controller.set("_network_mission_interaction_feedback", {"interaction_id":"ft7_cargo"})
	var states := {}
	for index in range(8):
		states["ft%d_%s" % [index, "cargo" if index == 7 else "computer"]] = {"state":"holding" if index == 7 else "operating","complete":false,"progress":0.1,"hold_seconds":1.0,"duration_seconds":12.0 if index == 7 else 18.0,"interaction_type":"hold_zone" if index == 7 else "computer"}
	_assert(bool(controller.call("_apply_network_mission_interaction_progress_surface", {"interaction_states":states})), "Parallel snapshot updates surface")
	var preferred := Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(String(preferred.get("interaction_id","")) == "ft7_cargo" and String(preferred.get("display_token","")) == "CARGO", "Preferred active Fireteam interaction wins")
	var started := Time.get_ticks_usec()
	for sample in range(2000):
		var bucket := int(sample / 10) % 100
		var cargo: Dictionary = Dictionary(states["ft7_cargo"])
		cargo["hold_seconds"] = float(bucket % 12)
		cargo["progress"] = float(bucket % 12) / 12.0
		states["ft7_cargo"] = cargo
		controller.call("_apply_network_mission_interaction_progress_surface", {"interaction_states":states})
	var elapsed := Time.get_ticks_usec() - started
	var result := Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	var update_count := int(result.get("progress_update_count",0))
	print("TASK_1098 performance: snapshots=2000 updates=%d elapsed_usec=%d" % [update_count, elapsed])
	_assert(elapsed < 250000, "2000 parallel snapshots stay below 250 ms broad guard")
	_assert(update_count <= 250, "Fingerprint keeps label updates below 250")
	_assert(not bool(result.get("ui_sets_gameplay_truth",true)), "Stress surface remains read-only")
	scene.queue_free(); await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed]); quit(1 if failed else 0)

func _assert(ok: bool, text: String) -> void:
	if ok: passed += 1; print("PASS: %s" % text)
	else: failed += 1; push_error("FAIL: %s" % text)
