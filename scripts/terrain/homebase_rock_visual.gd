extends RefCounted
## Reuses the existing rock asset inside one true hex; no new primitive rock art.
## Placement/height come from HomebaseRockRules, never a second LOS owner.

static func build(scene: PackedScene, profile: RefCounted, height: float, cell_size: float) -> Node3D:
	var root := Node3D.new()
	root.name = "HomebaseHighRock" if height>0.5 else "HomebaseLowCoverRock"
	var model := scene.instantiate() as Node3D
	if model == null: return root
	var bounds := _bounds(model,Transform3D.IDENTITY)
	var size_value := bounds.size
	# A conservative hex fit including all four XZ bounds corners.
	var half_x := size_value.x*0.5
	var half_z := size_value.z*0.5
	var extent := maxf(half_x,half_x*0.5+half_z*sqrt(3.0)*0.5)
	var planar_scale := cell_size*0.48/maxf(extent,0.001)
	var scaling := Vector3(planar_scale,height/maxf(size_value.y,0.001),planar_scale)
	var center := bounds.get_center()
	var mount := Node3D.new()
	mount.scale = scaling
	root.add_child(mount)
	mount.add_child(model)
	model.position -= Vector3(center.x,bounds.position.y,center.z)
	var material: Material = profile.material_for(Color("a86545") if height>0.5 else Color("b16c48"),true)
	_apply_material(model,material)
	root.set_meta("visual_only",true)
	root.set_meta("source_rule","homebase_rock_rules")
	root.set_meta("source_geometry_unchanged",true)
	root.set_meta("visual_height",height)
	root.set_meta("hex_containment_half_width",cell_size*0.48)
	return root

static func _bounds(node: Node, parent_transform: Transform3D) -> AABB:
	var transform := parent_transform
	if node is Node3D: transform *= node.transform
	var result := AABB()
	var valid := false
	if node is MeshInstance3D and node.mesh != null:
		result = transform*node.mesh.get_aabb()
		valid = true
	for child in node.get_children():
		var child_bounds := _bounds(child,transform)
		if child_bounds.size.length_squared()<=0.000001: continue
		result = result.merge(child_bounds) if valid else child_bounds
		valid = true
	return result

static func _apply_material(node: Node, material: Material) -> void:
	if node is MeshInstance3D: node.material_override = material
	for child in node.get_children(): _apply_material(child,material)
