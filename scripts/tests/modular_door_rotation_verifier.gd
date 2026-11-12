extends SceneTree
const PLAN = preload("res://scripts/core/campaign_modular_plan.gd")
const GEO = preload("res://scripts/meta/modular_base_geometry.gd")
func _init() -> void:
	var directions := [Vector2i(0,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0)]
	for a_rotation in range(4):
		for b_rotation in range(4):
			for side in range(4):
				var plan := PLAN.empty()
				PLAN.append_room(plan,{"id":"a","type":"sleep","x":0,"y":0,"rotation":a_rotation},true)
				var step: Vector2i = directions[side]
				PLAN.append_room(plan,{"id":"b","type":"storage","x":step.x,"y":step.y,"rotation":b_rotation},true)
				var seam: Vector2 = GEO.center(plan.rooms[0]) + Vector2(step) * 3.0
				if GEO.wall_blocks(plan.rooms[0],seam) or GEO.wall_blocks(plan.rooms[1],seam):
					printerr("FAIL: connected door in orientation ", a_rotation,"/",b_rotation,"/",side); quit(1); return
				var bed: Dictionary = GEO.bed_geometry(plan.rooms[0],{"id":"b0","slot":0})
				var sleep := Vector2(bed.sleep_plane[0],bed.sleep_plane[1])
				var approach := Vector2(bed.rest_plane[0],bed.rest_plane[1])
				var local := GEO.local_point(plan.rooms[0],sleep)
				if not is_equal_approx(local.y,-2.0) or GEO.bed_blocks(bed,approach):
					printerr("FAIL: wall-side bed orientation ",a_rotation); quit(1); return
	print("MODULAR_DOOR_ROTATION_PASS 64 connected orientations and wall-side beds")
	quit(0)
