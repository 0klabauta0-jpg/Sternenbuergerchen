extends RefCounted
## Read-only equipment projection: one cached rigid-skinned outfit per rig/class.
const PATH := "res://Assets/curated/personnel/armor_kenney_r05_20261111/"
const PREFIX := "ArmorVisual_"
const REVISION := "kenney_authored_r05"
static var _parts: Dictionary = {}
static var _outfits: Dictionary = {}
static var _underlays: Dictionary = {}
static var _headless_meshes: Dictionary = {}
static var _underlay_shader: Shader


static func apply_to_model(model: Node3D, armor_id: String) -> Dictionary:
	if String(model.get_meta("worn_armor_id", "")) == armor_id and String(model.get_meta("armor_revision", "")) == REVISION:
		return {"ok": true, "count": int(model.get_meta("armor_part_count", 0)), "unchanged": true}
	for node: Node in model.find_children(PREFIX + "*", "", true, false):
		if is_instance_valid(node): node.free()
	model.set_meta("worn_armor_id", "")
	model.set_meta("armor_part_count", 0)
	if armor_id not in ["suit", "light", "medium", "heavy"]:
		return {"ok": false, "reason": "armor_class_missing", "count": 0}
	_prepare_underlayer(model, armor_id)
	if armor_id == "suit":
		model.set_meta("worn_armor_id", armor_id)
		model.set_meta("armor_revision", REVISION)
		return {"ok": true, "count": 0, "surfaces": 0}
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return {"ok": false, "reason": "armor_skeleton_missing", "count": 0}
	var skeleton: Skeleton3D = skeletons[0]
	var rest_signature: Array = []
	for index in skeleton.get_bone_count():
		rest_signature.append([skeleton.get_bone_name(index), skeleton.get_bone_global_rest(index)])
	var key := REVISION + armor_id + var_to_bytes(rest_signature).hex_encode()
	for body: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if String(body.name).to_lower().contains("character"):
			var source: Mesh = body.get_meta("armor_original_body_mesh", body.mesh)
			key += str(source.get_rid().get_id())
			break
	if not _outfits.has(key):
		var baked := _bake_outfit(skeleton, armor_id, model)
		if not baked.get("ok", false): return baked
		_outfits[key] = baked
	var data: Dictionary = _outfits[key]
	var outfit := MeshInstance3D.new()
	outfit.name = PREFIX + "Outfit"
	outfit.mesh = data.mesh
	outfit.skin = data.skin
	outfit.skeleton = NodePath("..")
	outfit.set_meta("armor_segment_count", data.count)
	outfit.set_meta("armor_class", armor_id)
	skeleton.add_child(outfit)
	model.set_meta("worn_armor_id", armor_id)
	model.set_meta("armor_part_count", data.count)
	model.set_meta("armor_revision", REVISION)
	return {"ok": true, "count": int(data.count), "surfaces": outfit.mesh.get_surface_count()}


static func _bake_outfit(skeleton: Skeleton3D, armor_id: String, model: Node3D) -> Dictionary:
	var bones := {}
	for key: String in ["Hips", "Chest", "Head", "LeftArm", "RightArm", "LeftForeArm", "RightForeArm", "LeftHand", "RightHand", "LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot"]:
		var index := skeleton.find_bone(key)
		if index < 0: return {"ok": false, "reason": "armor_bone_missing:" + key, "count": 0}
		bones[key] = skeleton.get_bone_global_rest(index).origin
	var up: Vector3 = (Vector3(bones.Head) - Vector3(bones.Hips)).normalized()
	var right: Vector3 = Vector3(bones.LeftArm) - Vector3(bones.RightArm)
	right = (right - up * right.dot(up)).normalized()
	var forward := right.cross(up).normalized()
	var axes := Basis(right, up, forward)
	var width: float = Vector3(bones.LeftArm).distance_to(bones.RightArm)
	var torso: float = (Vector3(bones.LeftArm) - Vector3(bones.Hips)).dot(up)
	var head_span: float = Vector3(bones.Head).distance_to(bones.Chest)
	if width <= 0.00001 or torso <= 0.00001:
		return {"ok": false, "reason": "armor_rig_dimensions_invalid", "count": 0}
	var bulk: float = {"light": 0.93, "medium": 1.22, "heavy": 1.50}[armor_id]
	var specs: Array = []
	_add_spec(specs, "torso_" + armor_id, "Chest", axes,
		Vector3(bones.Hips) + up * torso * 0.61 + forward * width * (0.055 if armor_id != "heavy" else 0.025),
		Vector3(width * 1.10 * bulk, torso * 1.04, width * (0.90 if armor_id == "medium" else 0.98 if armor_id == "light" else 0.88) * bulk))
	_add_spec(specs, "pelvis_" + armor_id, "Hips", axes,
		Vector3(bones.Hips) + up * torso * 0.02,
		Vector3(width * 1.06 * bulk, torso * 0.32, width * 0.78 * bulk))
	if armor_id in ["light", "medium", "heavy"]:
		var head_bounds := _bone_bounds(model, skeleton, "Head", axes)
		var helmet_center: Vector3 = Vector3(bones.Head) + up * head_span * 0.56
		var helmet_size := Vector3(width * 1.38 * bulk, head_span * 1.25, width * 1.30 * bulk)
		if head_bounds.has_volume():
			helmet_center = axes * head_bounds.get_center()
			if armor_id != "heavy": helmet_center -= up * head_bounds.size.y * 0.025
			helmet_size = head_bounds.size * Vector3(1.38, 1.00, 1.30)
			if armor_id == "medium":
				helmet_size = head_bounds.size * Vector3(1.36, 1.08, 1.20)
			elif armor_id == "light":
				helmet_size = head_bounds.size * Vector3(1.34, 1.08, 1.20)
		model.set_meta("armor_head_fit", {"center": helmet_center, "size": helmet_size})
		_add_spec(specs, "helmet_" + armor_id, "Head", axes,
			helmet_center, helmet_size)
	if armor_id == "heavy":
		_add_spec(specs, "collar", "Chest", axes,
			Vector3(bones.Head) - up * width * 0.24,
			Vector3(width * 1.75, torso * 0.34, width * 1.48))
	for side: String in ["Left", "Right"]:
		var arm: Vector3 = bones[side + "Arm"]
		var elbow: Vector3 = bones[side + "ForeArm"]
		var wrist: Vector3 = bones[side + "Hand"]
		if armor_id in ["light", "medium", "heavy"]:
			_add_spec(specs, "pauldron_" + armor_id, side + "Arm", _limb_axes((arm-elbow).normalized(), forward),
				arm.lerp(elbow, 0.24),
				Vector3(width * {"light":0.39,"medium":0.56,"heavy":0.72}[armor_id],
					arm.distance_to(elbow) * {"light":0.43,"medium":0.65,"heavy":0.82}[armor_id],
					width * {"light":0.48,"medium":0.66,"heavy":0.77}[armor_id]))
		if armor_id == "heavy":
			_add_limb(specs, "upper_arm_" + armor_id, side + "Arm", arm, elbow, forward,
				width * 0.40, width * 0.49, 0.73)
		_add_limb(specs, "forearm_" + armor_id, side + "ForeArm", elbow, wrist, forward,
			width * {"light":0.30,"medium":0.53,"heavy":0.58}[armor_id],
			width * {"light":0.46,"medium":0.56,"heavy":0.60}[armor_id], 0.78 if armor_id == "light" else 0.90)
		if armor_id == "heavy":
			var hand_axis := (elbow - wrist).normalized()
			_add_spec(specs, "hand_guard_" + armor_id, side + "Hand", _limb_axes(hand_axis, forward),
				wrist - hand_axis * width * 0.13 + forward * width * 0.035,
				Vector3(width * 0.30, width * 0.31, width * 0.24))
		if armor_id == "light":
			_add_spec(specs, "knee_light", side + "Leg", axes,
				Vector3(bones[side + "Leg"]) + forward * width * 0.20,
				Vector3(width * 0.32, width * 0.30, width * 0.23))
		var hip: Vector3 = bones[side + "UpLeg"]
		var knee: Vector3 = bones[side + "Leg"]
		var ankle: Vector3 = bones[side + "Foot"]
		if armor_id == "light":
			var sign_side := 1.0 if side == "Left" else -1.0
			_add_spec(specs, "thigh_light", side + "UpLeg", _limb_axes((hip-knee).normalized(),forward),
				hip.lerp(knee,0.32) + forward * width * 0.19 + right * sign_side * width * 0.12,
				Vector3(width * 0.25, hip.distance_to(knee)*0.36, width*0.21))
			_add_spec(specs, "shin_light", side + "Leg", _limb_axes((knee-ankle).normalized(),forward),
				knee.lerp(ankle,0.58) + forward * width * 0.04,
				Vector3(width * 0.18, knee.distance_to(ankle)*0.33, width*0.25))
		else:
			_add_limb(specs, "thigh_" + armor_id, side + "UpLeg", hip, knee, forward,
				width * 0.43 * bulk, width * 0.66 * bulk, 0.78)
			_add_spec(specs, "knee_" + armor_id, side + "Leg", axes, knee + forward * width * 0.22,
				Vector3(width * 0.45 * bulk, width * 0.38, width * 0.24))
			_add_limb(specs, "shin_" + armor_id, side + "Leg", knee, ankle, forward,
				width * 0.43 * bulk, width * 0.62 * bulk, 0.78)
		var foot_axes := axes
		var toe_index := skeleton.find_bone(side + "Toes")
		if toe_index >= 0:
			var foot_forward: Vector3 = skeleton.get_bone_global_rest(toe_index).origin - ankle
			foot_forward = (foot_forward - up * foot_forward.dot(up)).normalized()
			foot_axes = Basis(up.cross(foot_forward).normalized(), up, foot_forward)
		var foot_bounds := _bone_bounds(model, skeleton, side + "Foot", foot_axes)
		var toe_bounds := _bone_bounds(model, skeleton, side + "Toes", foot_axes)
		if toe_bounds.has_volume(): foot_bounds = foot_bounds.merge(toe_bounds)
		_add_spec(specs, "boot_" + armor_id, side + "Foot", foot_axes,
			foot_axes * foot_bounds.get_center(),
			foot_bounds.size * Vector3(1.13 if armor_id == "light" else 1.10, 1.10, 1.12 if armor_id == "light" else 1.08))
		if toe_index >= 0:
			specs[-1]["toe_bone"] = toe_index
			specs[-1]["toe_origin"] = skeleton.get_bone_global_rest(toe_index).origin
			specs[-1]["toe_forward"] = foot_axes.z
	_fit_anatomical_specs(specs, model, skeleton, armor_id, axes, width)
	var buckets: Dictionary = {}
	for spec: Dictionary in specs:
		var result := _append_segment(buckets, skeleton, spec)
		if not result.ok: return result
	var mesh := ArrayMesh.new()
	var names := buckets.keys()
	names.sort()
	for name: String in names:
		var bucket: Dictionary = buckets[name]
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(bucket.vertices)
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(bucket.normals)
		arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(bucket.uvs)
		arrays[Mesh.ARRAY_BONES] = PackedInt32Array(bucket.bones)
		arrays[Mesh.ARRAY_WEIGHTS] = PackedFloat32Array(bucket.weights)
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(bucket.indices)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, bucket.material)
	var skin := Skin.new()
	for index in skeleton.get_bone_count():
		skin.add_bind(index, skeleton.get_bone_global_rest(index).affine_inverse())
	return {"ok": true, "mesh": mesh, "skin": skin, "count": specs.size()}


static func _bone_bounds(model: Node3D, skeleton: Skeleton3D, bone_name: String, axes: Basis) -> AABB:
	var bounds := AABB()
	var found := false
	var target := skeleton.find_bone(bone_name)
	if target < 0: return AABB()
	for body: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if not String(body.name).to_lower().contains("character") or body.skin == null: continue
		var bind := -1
		for index in body.skin.get_bind_count():
			if body.skin.get_bind_bone(index) == target or String(body.skin.get_bind_name(index)) == bone_name:
				bind = index
				break
		if bind < 0: continue
		var rest := skeleton.get_bone_global_rest(target) * body.skin.get_bind_pose(bind)
		# Closed helmets hide the head only in the projected mesh. Fit against the
		# immutable original, including on subsequent medium/heavy switches.
		var source: Mesh = body.get_meta("armor_original_body_mesh", body.mesh)
		for surface in source.get_surface_count():
			var arrays: Array = source.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			if indices.size() != vertices.size() * 4: continue
			for index in vertices.size():
				var belongs := false
				for influence in range(4):
					if indices[index * 4 + influence] == bind and weights[index * 4 + influence] >= 0.45: belongs = true
				if not belongs: continue
				var point := axes.inverse() * (rest * vertices[index])
				bounds = bounds.expand(point) if found else AABB(point, Vector3.ZERO)
				found = true
	return bounds


static func _add_spec(specs: Array, part: String, bone: String, axes: Basis, center: Vector3, dimensions: Vector3) -> void:
	specs.append({"part": part, "bone": bone, "axes": axes, "center": center, "dimensions": dimensions})


static func _add_limb(specs: Array, part: String, bone: String, start: Vector3, end: Vector3, forward: Vector3, width: float, depth: float, coverage: float) -> void:
	var axis := (start - end).normalized()
	_add_spec(specs, part, bone, _limb_axes(axis, forward), (start + end) * 0.5,
		Vector3(width, start.distance_to(end) * coverage, depth))


static func _limb_axes(up: Vector3, front: Vector3) -> Basis:
	var right := up.cross(front).normalized()
	return Basis(right, up, right.cross(up).normalized())


static func _load_part(name: String) -> Dictionary:
	if _parts.has(name): return _parts[name]
	var scene := load(PATH + name + ".glb") as PackedScene
	if scene == null: return {}
	var root := scene.instantiate() as Node3D
	if root == null: return {}
	var primitives: Array = []
	var bounds := AABB()
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D: meshes.append(root)
	for instance: MeshInstance3D in meshes:
		var transform := _relative_transform(root, instance)
		var box := transform * instance.get_aabb()
		bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
		for surface in instance.mesh.get_surface_count():
			primitives.append({"arrays": instance.mesh.surface_get_arrays(surface), "transform": transform,
				"material": instance.mesh.surface_get_material(surface)})
	root.free()
	if name.begins_with("torso_"): _assign_torso_components(primitives)
	_parts[name] = {"primitives": primitives, "bounds": bounds}
	return _parts[name]


static func _relative_transform(root: Node3D, node: Node3D) -> Transform3D:
	if node == root: return Transform3D.IDENTITY
	var result := node.transform
	var parent := node.get_parent() as Node3D
	while parent != null and parent != root:
		result = parent.transform * result
		parent = parent.get_parent() as Node3D
	return result


static func _append_segment(buckets: Dictionary, skeleton: Skeleton3D, spec: Dictionary) -> Dictionary:
	var part := _load_part(String(spec.part))
	if part.is_empty(): return {"ok": false, "reason": "armor_part_missing:" + String(spec.part), "count": 0}
	var bounds: AABB = part.bounds
	if String(spec.part).begins_with("torso_") or String(spec.part).begins_with("pelvis_") or String(spec.part).begins_with("forearm_") or String(spec.part).begins_with("thigh_") or String(spec.part).begins_with("shin_"):
		bounds = AABB(Vector3(-0.5,-0.5,-0.5),Vector3.ONE)
	if minf(bounds.size.x, minf(bounds.size.y, bounds.size.z)) <= 0.0:
		return {"ok": false, "reason": "armor_part_bounds_invalid", "count": 0}
	var axes: Basis = spec.axes
	var scaled := axes.scaled_local(Vector3(spec.dimensions) / bounds.size)
	var desired := Transform3D(scaled, Vector3(spec.center) - scaled * bounds.get_center())
	var bone_index := skeleton.find_bone(String(spec.bone))
	for primitive: Dictionary in part.primitives:
		var material: Material = primitive.material
		var name := material.resource_name if material != null else "missing"
		if not buckets.has(name):
			buckets[name] = {"vertices": [], "normals": [], "uvs": [], "bones": [], "weights": [], "indices": [], "material": material}
		var bucket: Dictionary = buckets[name]
		var arrays: Array = primitive.arrays
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var transform: Transform3D = desired * Transform3D(primitive.transform)
		var normal_basis := transform.basis.inverse().transposed()
		var offset: int = bucket.vertices.size()
		for index in vertices.size():
			bucket.vertices.append(transform * vertices[index])
			bucket.normals.append((normal_basis * normals[index]).normalized())
			bucket.uvs.append(uvs[index] if index < uvs.size() else Vector2.ZERO)
			var vertex_bone := bone_index
			if primitive.has("bone_tags"):
				var named_bone := skeleton.find_bone(["Chest","Spine","Hips"][int(primitive.bone_tags[index])])
				if named_bone >= 0: vertex_bone = named_bone
			if spec.has("toe_bone") and (transform * vertices[index] - Vector3(spec.toe_origin)).dot(Vector3(spec.toe_forward)) > 0.0:
				vertex_bone = int(spec.toe_bone)
			bucket.bones.append_array([vertex_bone, 0, 0, 0])
			bucket.weights.append_array([1.0, 0.0, 0.0, 0.0])
		if indices.is_empty():
			for index in vertices.size(): bucket.indices.append(offset + index)
		else:
			for index in indices: bucket.indices.append(offset + index)
	return {"ok": true}


static func _prepare_underlayer(model: Node3D, armor_id: String) -> void:
	for legacy: Node3D in model.find_children("Gear_Modular", "Node3D", true, false): legacy.hide()
	for helmet: Node3D in model.find_children("HelmetVisual_*", "Node3D", true, false):
		helmet.visible = armor_id == "suit"
	for body: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if not String(body.name).to_lower().contains("character"): continue
		_set_covered_head(body, armor_id == "heavy")
		if body.has_meta("armor_underlayer_applied"): continue
		var original := body.get_active_material(0) as BaseMaterial3D
		if original == null: continue
		var key := str(original.get_instance_id())
		if not _underlays.has(key):
			if _underlay_shader == null:
				_underlay_shader = Shader.new()
				_underlay_shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform sampler2D base_texture : source_color, hint_default_white;
uniform vec4 base_tint : source_color = vec4(1.0);
void fragment(){
 vec4 source = texture(base_texture,UV)*base_tint*COLOR;
 float hi=max(source.r,max(source.g,source.b));
 // Preserve the Kenney face/hair and dark facial marks. Replace the legacy
 // printed neutral armor pattern with one coherent flexible under-suit.
 float warm=step(source.b+0.07,source.r)*step(source.g+0.015,source.r);
 float cloth=(1.0-warm)*smoothstep(0.10,0.20,hi);
 vec3 flexible=vec3(0.050,0.060,0.075)*(0.98+hi*0.025);
 ALBEDO=mix(source.rgb,flexible,cloth);
 ROUGHNESS=0.88;
}"""
			var material := ShaderMaterial.new()
			material.shader = _underlay_shader
			if original.albedo_texture != null: material.set_shader_parameter("base_texture", original.albedo_texture)
			material.set_shader_parameter("base_tint", original.albedo_color)
			_underlays[key] = material
		body.material_override = _underlays[key]
		body.set_meta("armor_underlayer_applied", true)


static func _set_covered_head(body: MeshInstance3D, covered: bool) -> void:
	if not body.has_meta("armor_original_body_mesh"):
		body.set_meta("armor_original_body_mesh", body.mesh)
	var source: Mesh = body.get_meta("armor_original_body_mesh")
	if not covered:
		body.mesh = source
		return
	if body.skin == null: return
	var head := -1
	for index in body.skin.get_bind_count():
		if String(body.skin.get_bind_name(index)) == "Head":
			head = index
			break
	if head < 0:
		var skeleton := body.get_node_or_null(body.skeleton) as Skeleton3D
		if skeleton != null:
			for index in body.skin.get_bind_count():
				if body.skin.get_bind_bone(index) == skeleton.find_bone("Head"):
					head = index
					break
	if head < 0: return
	var key := str(source.get_rid().get_id()) + ":" + str(head)
	if not _headless_meshes.has(key):
		var mesh := ArrayMesh.new()
		for surface in source.get_surface_count():
			var arrays: Array = source.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				for index in vertices.size(): indices.append(index)
			var kept := PackedInt32Array()
			for triangle in range(0, indices.size(), 3):
				var head_triangle := false
				for corner in range(3):
					var vertex := indices[triangle + corner]
					for influence in range(4):
						if bones[vertex * 4 + influence] == head and weights[vertex * 4 + influence] >= 0.45:
							head_triangle = true
				if not head_triangle:
					kept.append_array([indices[triangle], indices[triangle + 1], indices[triangle + 2]])
			if kept.is_empty(): continue
			arrays[Mesh.ARRAY_INDEX] = kept
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			mesh.surface_set_material(mesh.get_surface_count() - 1, source.surface_get_material(surface))
		_headless_meshes[key] = mesh
	body.mesh = _headless_meshes[key]


static func _fit_anatomical_specs(specs: Array, model: Node3D, skeleton: Skeleton3D, armor_id: String, body_axes: Basis, width: float) -> void:
	# Fit only when assembling an outfit. Original body meshes remain immutable.
	# Limb depth comes from the actual local body envelope, not shoulder span.
	for spec: Dictionary in specs:
		var part := String(spec.part)
		var bone := String(spec.bone)
		var axes: Basis = spec.axes
		var dimensions: Vector3 = spec.dimensions
		var center: Vector3 = axes.inverse() * Vector3(spec.center)
		if part.begins_with("torso_"):
			var torso_bounds := _bone_bounds(model, skeleton, "Spine", axes)
			for name in ["Chest", "Hips"]:
				var addition := _bone_bounds(model, skeleton, name, axes)
				if addition.size.length() > 0.0: torso_bounds = torso_bounds.merge(addition)
			if torso_bounds.size.z > 0.0:
				center.z = torso_bounds.get_center().z
				dimensions.z = torso_bounds.size.z * {"light":1.18,"medium":1.25,"heavy":1.26}[armor_id]
				dimensions.x = width * {"light":1.02,"medium":1.16,"heavy":1.36}[armor_id]
				if armor_id=="heavy":dimensions.y*=.93
		elif part.begins_with("pelvis_"):
			var bounds := _bone_bounds(model, skeleton, "Hips", axes)
			if bounds.has_volume():
				center.z = bounds.get_center().z
				dimensions.z = bounds.size.z * {"light":1.04,"medium":1.10,"heavy":1.18}[armor_id]
		elif part.begins_with("pauldron_"):
			var bounds := _bone_bounds(model, skeleton, bone, axes)
			var elbow := skeleton.get_bone_global_rest(skeleton.find_bone(bone.replace("Arm","ForeArm"))).origin
			var shoulder := skeleton.get_bone_global_rest(skeleton.find_bone(bone)).origin
			center = axes.inverse() * shoulder.lerp(elbow, 0.10)
			if bounds.has_volume():
				center.x = bounds.get_center().x
				center.z = bounds.get_center().z
				dimensions.z = bounds.size.z * {"light":1.38,"medium":1.62,"heavy":1.92}[armor_id]
		elif part.begins_with("knee_"):
			var joint := skeleton.get_bone_global_rest(skeleton.find_bone(bone)).origin
			var ankle := skeleton.get_bone_global_rest(skeleton.find_bone(bone.replace("Leg","Foot"))).origin
			axes = _limb_axes((joint-ankle).normalized(),body_axes.z)
			var bounds := _bone_bounds(model,skeleton,bone,axes)
			center = axes.inverse()*joint
			if bounds.has_volume():
				dimensions = Vector3(bounds.size.x * {"light":0.70,"medium":1.16,"heavy":1.33}[armor_id],bounds.size.x * {"light":0.65,"medium":0.75,"heavy":0.80}[armor_id],bounds.size.z * {"light":0.18,"medium":0.24,"heavy":0.30}[armor_id])
				center.x = bounds.get_center().x
				center.z = bounds.end.z + dimensions.z * 0.15
		elif part.begins_with("forearm_") or part.begins_with("thigh_") or part.begins_with("shin_") or part.begins_with("upper_arm_"):
			var bounds := _bone_bounds(model,skeleton,bone,axes)
			if bounds.has_volume():
				if armor_id=="light" and (part.begins_with("thigh_") or part.begins_with("shin_")):
					center.z = bounds.end.z-dimensions.z*.35
				else:
					center.x = bounds.get_center().x
					center.z = bounds.get_center().z
					if part.begins_with("forearm_"):
						dimensions.x = bounds.size.x * {"light":0.90,"medium":1.35,"heavy":1.42}[armor_id]
						dimensions.z = bounds.size.z * {"light":1.13,"medium":1.30,"heavy":1.40}[armor_id]
					elif part.begins_with("thigh_"):
						dimensions.x = bounds.size.x * (1.10 if armor_id=="medium" else 1.22)
						dimensions.z = bounds.size.z * (1.12 if armor_id=="medium" else 1.22)
						center.y-=dimensions.y*.08
						dimensions.y*=.90
					elif part.begins_with("shin_"):
						dimensions.x = bounds.size.x * (1.10 if armor_id=="medium" else 1.30)
						dimensions.z = bounds.size.z * (1.18 if armor_id=="medium" else 1.30)
					else:
						dimensions.z=bounds.size.z*1.25
		spec.axes=axes
		spec.center=axes*center
		spec.dimensions=dimensions


static func _component_root(parents: Array[int], index: int) -> int:
	while parents[index] != index:
		parents[index] = parents[parents[index]]
		index = parents[index]
	return index


static func _assign_torso_components(primitives: Array) -> void:
	# Weld glTF's UV/normal/material vertex splits for connectivity only. A
	# complete rigid shell gets one bone from its component center, never a
	# different bone for individual vertices on opposite sides of a threshold.
	var points: Array[Vector3] = []
	var parents: Array[int] = []
	var welded: Dictionary = {}
	for primitive: Dictionary in primitives:
		var arrays: Array = primitive.arrays
		var mapping := PackedInt32Array()
		for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
			var point: Vector3 = Transform3D(primitive.transform) * vertex
			if not welded.has(point):
				welded[point] = points.size()
				parents.append(points.size())
				points.append(point)
			mapping.append(int(welded[point]))
		primitive["component_vertices"] = mapping
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for index in mapping.size():indices.append(index)
		for start in range(0,indices.size(),3):
			var root := _component_root(parents,mapping[indices[start]])
			for offset in [1,2]:parents[_component_root(parents,mapping[indices[start+offset]])]=root
	var bounds: Dictionary = {}
	for index in points.size():
		var root := _component_root(parents,index)
		bounds[root] = AABB(points[index],Vector3.ZERO) if not bounds.has(root) else (bounds[root] as AABB).expand(points[index])
	for primitive: Dictionary in primitives:
		var tags := PackedInt32Array()
		for index in primitive.component_vertices:
			var center: Vector3 = (bounds[_component_root(parents,index)] as AABB).get_center()
			tags.append(2 if center.y<-.39 else 1 if center.y<-.07 else 0)
		primitive["bone_tags"]=tags
		primitive.erase("component_vertices")
