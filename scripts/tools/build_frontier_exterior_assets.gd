extends SceneTree
## Reuses the same exterior builder as GM01/trade; originals remain unchanged.
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const SHELL = preload("res://scripts/terrain/frontier_closed_buildings.gd")
const SOURCE := "res://Assets/curated/frontier_illustrated_20261101/structures_pass04/"
func _init() -> void: call_deferred("_run")
func _own(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_own(child, owner_node)
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/terrain"))
	var view = VIEW.new()
	var catalog: Dictionary = {}
	for id in ["habitat", "hall"]:
		var source: String = SOURCE + ("habitat_cutaway_01.glb" if id == "habitat" else "freihafen_hall_01.glb")
		var original: Node3D = load(source).instantiate()
		var bounds: Dictionary = view.call("_get_local_visual_bounds", original)
		var minimum: Vector3 = Vector3(bounds.min) * 0.35
		var maximum: Vector3 = Vector3(bounds.max) * 0.35
		original.free()
		var asset := Node3D.new()
		asset.name = "FrontierHabitatExterior" if id == "habitat" else "FrontierHallExterior"
		root.add_child(asset)
		var shell := SHELL.new()
		asset.add_child(shell)
		shell.build(AABB(minimum, maximum - minimum), id == "hall")
		var actual: Dictionary = view.call("_get_local_visual_bounds", asset)
		var center: Vector3 = (Vector3(actual.min) + Vector3(actual.max)) * 0.5
		shell.position -= Vector3(center.x, float(actual.min.y), center.z)
		var final_bounds: Dictionary = view.call("_get_local_visual_bounds", asset)
		var lo: Vector3 = final_bounds.min
		var hi: Vector3 = final_bounds.max
		catalog["frontier_" + id + "_exterior"] = {"model_path": "res://scenes/terrain/frontier_%s_exterior.tscn" % id, "min": [lo.x,lo.y,lo.z], "max": [hi.x,hi.y,hi.z], "source_model": source, "source_sha256": FileAccess.get_sha256(source)}
		asset.set_meta("source_model", source)
		asset.set_meta("source_sha256", FileAccess.get_sha256(source))
		asset.set_meta("visual_family", "frontier_illustrated_v1")
		_own(asset, asset)
		var packed := PackedScene.new()
		var error := packed.pack(asset)
		if error == OK: error = ResourceSaver.save(packed, "res://scenes/terrain/frontier_%s_exterior.tscn" % id)
		asset.free()
		if error != OK: quit(1); return
	view.free()
	var file := FileAccess.open("res://data/frontier_building_visual_catalog.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(catalog, "\t", true, true) + "\n"); file.close()
	quit()
