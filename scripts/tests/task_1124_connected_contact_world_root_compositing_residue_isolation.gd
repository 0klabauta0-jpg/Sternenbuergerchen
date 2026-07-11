extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const BLUE_PRODUCT := "res://tmp/task_1119_product_first_contact_blue.png"
const GOLD_PRODUCT := "res://tmp/task_1119_product_first_contact_gold.png"
const BLUE_WORLD := "res://tmp/task_1124_first_contact_blue_world.png"
const GOLD_WORLD := "res://tmp/task_1124_first_contact_gold_world.png"
const RESIDUE_RECT := Rect2i(1540, 450, 190, 240)

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1124 Connected Contact World Root Compositing Residue Isolation ===")
	var mission: Node = MISSION_SCENE.instantiate()
	var second_mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	root.add_child(second_mission)
	for _frame in range(10):
		await process_frame
	var view: Node = mission.get_node_or_null("Primary3DView")
	var second_view: Node = second_mission.get_node_or_null("Primary3DView")
	var visual_snapshot: Dictionary = Dictionary(view.call("get_map_visual_bounds_snapshot")) if view != null and view.has_method("get_map_visual_bounds_snapshot") else {}
	_assert(not Array(visual_snapshot.get("world_mesh_entries", [])).is_empty(), "Existing read-only visual diagnostics remains available")
	var subviewport := view.get("_subviewport") as SubViewport if view != null else null
	var second_subviewport := second_view.get("_subviewport") as SubViewport if second_view != null else null
	_assert(subviewport != null and second_subviewport != null and subviewport.own_world_3d and second_subviewport.own_world_3d, "Every tactical SubViewport owns its World3D")
	_assert(subviewport != null and second_subviewport != null and subviewport.find_world_3d() != second_subviewport.find_world_3d(), "Parallel tactical SubViewports do not share World3D state")
	mission.queue_free()
	second_mission.queue_free()
	await process_frame
	for perspective in ["blue", "gold"]:
		var product_path: String = BLUE_PRODUCT if perspective == "blue" else GOLD_PRODUCT
		var world_path: String = BLUE_WORLD if perspective == "blue" else GOLD_WORLD
		var product: Image = _load_image(product_path)
		var world: Image = _load_image(world_path)
		_assert(product != null and product.get_size() == Vector2i(1920, 1080), "%s product capture is Full HD" % perspective.to_upper())
		_assert(world != null and world.get_size() == Vector2i(1920, 1080), "%s pure target-world capture is Full HD" % perspective.to_upper())
		if product != null and world != null:
			var product_occupancy: int = _count_non_background_pixels(product, RESIDUE_RECT)
			var world_occupancy: int = _count_non_background_pixels(world, RESIDUE_RECT)
			print("TASK1124 %s RESIDUE PIXELS product=%d world=%d" % [perspective.to_upper(), product_occupancy, world_occupancy])
			_assert(product_occupancy <= 100, "%s product capture contains no disconnected right-side world residue" % perspective.to_upper())
			_assert(world_occupancy <= 100, "%s target World3D contains no foreign peer residue" % perspective.to_upper())
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _load_image(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	return image if image.load(path) == OK else null


func _count_non_background_pixels(image: Image, rect: Rect2i) -> int:
	var clipped: Rect2i = rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var count: int = 0
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			var color: Color = image.get_pixel(x, y)
			if color.a > 0.5 and (color.r + color.g + color.b) > 0.35:
				count += 1
	return count


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
