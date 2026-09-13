extends SceneTree
## Run in the working project and in a Git archive without assets/local.
const Geo = preload("res://scripts/world/world_geometry.gd")

func _initialize() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var failures := 0
	for id in ["craft_cargoA", "freibeuter"]:
		var model := Geo.asset(stage, id, Vector3.ZERO, Vector3(9, 3, 12))
		var meshes := model.find_children("*", "MeshInstance3D", true, false)
		var rendered := not meshes.is_empty()
		for mesh: MeshInstance3D in meshes:
			rendered = rendered and mesh.mesh != null and mesh.get_aabb().size.length_squared() > 0.0
		print("ASSET_DELIVERY ", id, " meshes=", meshes.size(), " valid=", rendered)
		if not rendered:
			failures += 1
	stage.free()
	quit(0 if failures == 0 else 1)
