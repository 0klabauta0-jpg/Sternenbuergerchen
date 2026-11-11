extends SceneTree
const FLOW = preload("res://scenes/meta/meta_layer_test.tscn")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
var _checks := 0
var _failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures += 1
	print("PASS: " if ok else "FAIL: ", message)

func _run() -> void:
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	var view: Node = VIEW.new()
	root.add_child(view)
	await process_frame
	flow.set_process(false)
	view.set_process(false)
	flow.call("set_runtime_frame_timing_debug_enabled", true)
	view.call("set_runtime_frame_timing_debug_enabled", true)
	var runtime: Node = flow.get("_singleplayer_runtime")
	var before: Dictionary = runtime.call("get_snapshot")
	flow.call("_process", 0.0)
	view.call("_process", 0.0)
	var frame_id := Engine.get_process_frames()
	var meta: Dictionary = flow.call("get_runtime_frame_timing_debug_snapshot", frame_id)
	var visual: Dictionary = view.call("get_runtime_frame_work_debug_snapshot", frame_id)
	_check(meta.process_frame == frame_id and meta.sample_count == 1 and meta.scopes_sum_usec.has("timer_labels_usec"),
		"Meta receipt identifies the actual producer frame and its work")
	_check(visual.process_frame == frame_id and visual.process.has_sample and visual.process.process_frame == frame_id,
		"View receipt identifies its actual producer frame")
	_check(visual.process.scopes_sum_usec.has("pending_fow_usec") and visual.process.scopes_sum_usec.has("regional_chunks_usec") and visual.process.scopes_sum_usec.has("air_visual_and_redraw_usec"),
		"Previously unnamed view work has explicit scopes")
	var after: Dictionary = runtime.call("get_snapshot")
	_check(before.campaign == after.campaign and before.supply == after.supply and before.space_travel == after.space_travel,
		"Debug producers and getters preserve authoritative campaign/supply/travel state")
	meta.scopes_sum_usec.clear()
	_check(not Dictionary(flow.call("get_runtime_frame_timing_debug_snapshot", frame_id).scopes_sum_usec).is_empty(),
		"Meta getter protects stored scopes against caller mutation")
	while Engine.get_process_frames() == frame_id: await process_frame
	_check(not bool(view.call("get_runtime_frame_work_debug_snapshot").process.has_sample) and int(flow.call("get_runtime_frame_timing_debug_snapshot").sample_count) == 0,
		"Unprocessed later frame cannot borrow old view/meta receipts")
	flow.call("set_runtime_frame_timing_debug_enabled", false)
	view.call("set_runtime_frame_timing_debug_enabled", false)
	_check(not bool(flow.call("get_runtime_frame_timing_debug_snapshot").enabled) and not bool(view.call("get_runtime_frame_work_debug_snapshot").enabled),
		"Disabled view/meta debug clears all retained work")
	view.queue_free()
	flow.queue_free()
	await process_frame
	print("FRAME_STAMP_PIPELINE checks=", _checks, " failures=", _failures)
	quit(0 if _failures == 0 else 1)
