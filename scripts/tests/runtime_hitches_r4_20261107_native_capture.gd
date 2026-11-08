extends "res://scripts/tests/reference_polish_r3_20261106_native_capture.gd"
## Same normal source route. Optional pure diagnostics are read after timing.

func _profile_normal_movement(view: Node) -> void:
	var controller: Node = view.get_parent().get_node_or_null("TacticalController")
	var queue_before: Dictionary = controller.call("get_periodic_hud_projection_queue_debug_snapshot") if controller != null and controller.has_method("get_periodic_hud_projection_queue_debug_snapshot") else {"available": false}
	await super._profile_normal_movement(view)
	_facts["r4_command_debug"] = controller.call("get_command_commit_timing_debug_snapshot") if controller != null and controller.has_method("get_command_commit_timing_debug_snapshot") else {"available": false}
	_facts["r4_periodic_hud_projection"] = {
		"before_warmup": queue_before,
		"after_measurement": controller.call("get_periodic_hud_projection_queue_debug_snapshot") if controller != null and controller.has_method("get_periodic_hud_projection_queue_debug_snapshot") else {"available": false},
		"profile_start_usec": _profile_start_usec,
		"read_after_measurement": true,
		"changes_gameplay": false,
	}
