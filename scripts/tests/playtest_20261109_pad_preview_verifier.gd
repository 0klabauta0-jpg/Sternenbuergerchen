extends SceneTree

var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var base = load("res://scenes/meta/explorable_homebase.tscn").instantiate()
	root.add_child(base)
	_check(base.has_method("set_pad_preview"), "Existing explorer exposes bounded craft-pad preview mode")
	if not base.has_method("set_pad_preview"):
		base.queue_free()
		await process_frame
		_finish()
		return
	var transport := {"crafts": [{"craft_id": "actual_ship", "craft_type": "dropship", "display_name": "Real Ship", "landing_pad_id": "homebase_pad_01", "location_id": "homebase", "visible_on_pad": true, "busy": false}]}
	base.set_transport_snapshot(transport)
	base.set_pad_preview(true, "actual_ship")
	await process_frame
	var snapshot: Dictionary = base.get_exploration_snapshot()
	_check(snapshot.preview_mode and snapshot.focused_craft_id == "actual_ship", "Preview focuses actual projected ship")
	_check(not base.request_walk_to(snapshot.initial_walk_target), "Preview rejects commander movement commands")
	_check(not base.request_terminal("personnel"), "Preview rejects world terminal commands")
	_check(not (base.get("_model") as Node3D).visible, "Commander is hidden in flightdeck camera")
	_check(not (base.get("_sim") as Node).is_physics_processing(), "Preview disables local movement simulation")
	var viewport: SubViewport = base.get("_viewport")
	_check(viewport.render_target_update_mode != SubViewport.UPDATE_ALWAYS, "Pad preview never permanently renders its viewport")
	var avatar_id: int = snapshot.avatar_instance_id
	var visual_id: int = snapshot.projected_crafts[0].visual_instance_id
	base.set_transport_snapshot(transport)
	base.set_pad_preview(true, "actual_ship")
	var repeated: Dictionary = base.get_exploration_snapshot()
	_check(repeated.avatar_instance_id == avatar_id and repeated.projected_crafts[0].visual_instance_id == visual_id, "Unchanged preview polling reuses scene and actual craft visual")
	base.set_active(true)
	_check(not base.get_exploration_snapshot().preview_mode and (base.get("_model") as Node3D).visible, "Base exploration restores commander and interactive mode")
	base.set_pad_preview(true, "actual_ship")
	base.set_active(false)
	_check(not base.get_exploration_snapshot().active and viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Closing flightdeck disables existing viewport")
	base.queue_free()
	await process_frame
	_finish()

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		printerr("FAIL: " + label)

func _finish() -> void:
	print("PAD_PREVIEW_RESULTS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
