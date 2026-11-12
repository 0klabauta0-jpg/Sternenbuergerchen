extends SceneTree
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var view = VIEW.new(); root.add_child(view)
	await process_frame
	var event := {"event_id":"laser-test", "attacker_position":Vector2.ZERO, "aim_position":Vector2(96, 0), "target_position":Vector2(104, 0)}
	assert(view.show_air_support_laser(event))
	var laser_root: Node3D = view.get("_air_support_laser_root")
	assert(is_instance_valid(laser_root) and laser_root.get_child_count() == 1 and laser_root.get_child(0).get_child_count() == 2)
	var bad := event.duplicate(); bad.target_position = Vector2(NAN, 0)
	assert(not view.show_air_support_laser(bad) and laser_root.get_child_count() == 1)
	view.set("_fog_of_war_mode", "unexplored_blackout")
	assert(not view.show_air_support_laser(event) and laser_root.get_child_count() == 1)
	view.set("_fog_of_war_mode", "off")
	await create_timer(0.3).timeout
	await process_frame
	assert(laser_root.get_child_count() == 0)
	view.queue_free()
	print("AIR_SUPPORT_LASER passed")
	quit()
