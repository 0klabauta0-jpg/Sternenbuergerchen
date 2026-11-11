extends SceneTree
## One refresh must read a coherent owner projection once, including its guard.
class RuntimeProbe:
	extends Node
	var reads := 0
	var mode := "campaign"
	func get_snapshot() -> Dictionary:
		reads += 1
		return {"mode":mode,"onboarding":{"stage_index":2,"next_step_id":"outpost_completed","completed":false},
			"checkpoint_guard":{"ok":false,"message":"Owner projection " + str(reads)}}

var _checks := 0
var _failures := 0
func _init() -> void:
	call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures += 1
	print("PASS: " if ok else "FAIL: ", message)
func _run() -> void:
	var runtime := RuntimeProbe.new()
	root.add_child(runtime)
	var tutorial = load("res://scripts/meta/campaign_tutorial_presenter.gd").new()
	root.add_child(tutorial)
	tutorial.configure(runtime, null)
	runtime.reads = 0
	var children: int = tutorial.get_child_count()
	tutorial.set_runtime_frame_timing_debug_enabled(true)
	tutorial.refresh()
	_check(runtime.reads == 1, "A tutorial refresh builds one complete owner projection")
	_check(tutorial.get("_checkpoint_label").text == "Owner projection 1",
		"Checkpoint guard belongs to the same fresh owner snapshot as guidance")
	_check(tutorial.get_presentation_snapshot().step_id == "outpost_completed" and String(tutorial.get("_guidance").text).contains("Karte B"),
		"Current chapter guidance remains sourced from the owner")
	var diagnostic: Dictionary = tutorial.get_runtime_frame_timing_debug_snapshot()
	_check(diagnostic.sample_count == 1 and diagnostic.scopes_sum_usec.has("initial_snapshot_usec"),
		"Debug evidence records the actual single projection")
	_check(tutorial.get_child_count() == children, "Refreshing retains the existing UI tree")
	tutorial.set_runtime_frame_timing_debug_enabled(false)
	runtime.reads = 0
	tutorial.refresh()
	_check(runtime.reads == 1 and tutorial.get_runtime_frame_timing_debug_snapshot().sample_count == 0,
		"Debug disabled keeps the same one-read presentation and no receipts")
	runtime.mode = "skirmish"
	runtime.reads = 0
	tutorial.refresh()
	_check(runtime.reads == 1 and not tutorial.visible, "Skirmish remains hidden after one owner read")
	tutorial.free()
	runtime.free()
	print("TUTORIAL_SINGLE_PROJECTION checks=", _checks, " failures=", _failures)
	quit(0 if _failures == 0 else 1)
