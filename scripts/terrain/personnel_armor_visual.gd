extends RefCounted
## Read-only equipment projection: one cached rigid-skinned outfit per rig/class.
const PATH := "res://Assets/curated/personnel/armor_kenney_r07_20261111/"
const PREFIX := "ArmorVisual_"
const REVISION := "kenney_authored_r07_undersuit_v2"
static var _parts: Dictionary = {}
static var _outfits: Dictionary = {}
static var _underlays: Dictionary = {}
static var _headless_meshes: Dictionary = {}
static var _underlay_shader: Shader


static func apply_to_model(model: Node3D, armor_id: String) -> Dictionary:
	_prepare_body_variant(model)
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
	if String(spec.part).begins_with("torso_") or String(spec.part).begins_with("pelvis_") or String(spec.part).begins_with("forearm_") or String(spec.part).begins_with("thigh_") or String(spec.part).begins_with("shin_") or String(spec.part).begins_with("knee_"):
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
		var original: BaseMaterial3D = body.get_meta("armor_underlayer_original") if body.has_meta("armor_underlayer_original") else null
		if original == null:
			original = body.get_active_material(0) as BaseMaterial3D
			if original != null: body.set_meta("armor_underlayer_original", original)
		if original == null: continue
		var is_suit := armor_id == "suit"
		var key := str(original.get_instance_id()) + (":suit" if is_suit else ":armor")
		if not _underlays.has(key):
			if _underlay_shader == null:
				_underlay_shader = Shader.new()
				_underlay_shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform sampler2D base_texture : source_color, hint_default_white;
uniform vec4 base_tint : source_color = vec4(1.0);
uniform bool visible_suit = false;
void fragment(){
 vec4 source = texture(base_texture,UV)*base_tint*COLOR;
 float hi=max(source.r,max(source.g,source.b));
 // Preserve the Kenney face/hair and dark facial marks. Replace the legacy
 // printed neutral armor pattern with one coherent flexible under-suit.
 float warm=step(source.b+0.07,source.r)*step(source.g+0.015,source.r);
 float cloth=(1.0-warm)*smoothstep(0.10,0.20,hi);
 // The unarmored suit retains the original fabric panel and seam contrasts;
 // worn armor keeps its darker neutral underlayer.
 float detail=clamp(dot(source.rgb,vec3(0.2126,0.7152,0.0722)),0.0,1.0);
 vec3 flexible=visible_suit ? mix(vec3(0.10,0.15,0.19),vec3(0.50,0.60,0.65),detail) : vec3(0.050,0.060,0.075)*(0.98+hi*0.025);
 ALBEDO=mix(source.rgb,flexible,cloth);
 ROUGHNESS=0.88;
}"""
			var material := ShaderMaterial.new()
			material.shader = _underlay_shader
			if original.albedo_texture != null: material.set_shader_parameter("base_texture", original.albedo_texture)
			material.set_shader_parameter("base_tint", original.albedo_color)
			material.set_shader_parameter("visible_suit", is_suit)
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
				dimensions.z = torso_bounds.size.z * {"light":1.12,"medium":1.14,"heavy":1.16}[armor_id]
				dimensions.x = width * {"light":1.02,"medium":1.18,"heavy":1.26}[armor_id]
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
			center = axes.inverse() * shoulder.lerp(elbow, 0.07)
			dimensions.y += shoulder.distance_to(elbow)*.06
			var roof_width:float={"light":1.06,"medium":1.40,"heavy":1.62}[armor_id]
			dimensions.x *= roof_width
			dimensions.y *= {"light":1.0,"medium":.90,"heavy":.82}[armor_id]
			if bounds.has_volume():
				center.x = bounds.get_center().x + dimensions.x*(1-1/roof_width)*.40*(1 if bone.begins_with("Left") else -1)
				center.z = bounds.get_center().z
				dimensions.z = bounds.size.z * {"light":1.38,"medium":1.62,"heavy":1.92}[armor_id]
			var roof_center_world:Vector3=axes*center
			axes=axes*Basis(Vector3.BACK,deg_to_rad({"light":0.0,"medium":-40.0,"heavy":-50.0}[armor_id])*(1 if bone.begins_with("Left") else -1))
			center=axes.inverse()*roof_center_world
		elif part.begins_with("knee_"):
			var joint := skeleton.get_bone_global_rest(skeleton.find_bone(bone)).origin
			var ankle := skeleton.get_bone_global_rest(skeleton.find_bone(bone.replace("Leg","Foot"))).origin
			axes = body_axes
			center = axes.inverse()*joint
			var bounds := _joint_section_bounds(model,skeleton,[bone,bone.replace("Leg","UpLeg")],axes,center.y,joint.distance_to(ankle)*.055)
			if bounds.size.x>0.0 and bounds.size.z>0.0:
				dimensions = Vector3(bounds.size.x * {"light":.80,"medium":1.18,"heavy":1.26}[armor_id],bounds.size.x * {"light":.73,"medium":1.0,"heavy":1.02}[armor_id],bounds.size.z*1.10)
				center.x = bounds.get_center().x
				center.z = bounds.get_center().z + bounds.size.z*.13
				model.set_meta("r07_knee_section_"+bone,{"bounds":bounds,"center":center,"dimensions":dimensions})
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
						dimensions.x = bounds.size.x * (1.16 if armor_id=="medium" else 1.24)
						dimensions.z = bounds.size.z * (1.16 if armor_id=="medium" else 1.24)
						center.y-=dimensions.y*.08
						dimensions.y*=.90
					elif part.begins_with("shin_"):
						dimensions.x = bounds.size.x * (1.15 if armor_id=="medium" else 1.25)
						dimensions.z = bounds.size.z * (1.20 if armor_id=="medium" else 1.25)
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


static func _joint_section_bounds(model: Node3D, skeleton: Skeleton3D, bone_names: Array, axes: Basis, section_y: float, half_band: float) -> AABB:
	# Intersect original body triangles with three planes close to the joint.
	# This samples the patella cross-section, not the calf's wider/lower AABB.
	var result := AABB()
	var found := false
	for body: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if not String(body.name).to_lower().contains("character") or body.skin == null: continue
		var accepted: Dictionary = {}
		var rest := Transform3D.IDENTITY
		for bind in body.skin.get_bind_count():
			var bone := body.skin.get_bind_bone(bind)
			var name := String(body.skin.get_bind_name(bind))
			if not name.is_empty():bone = skeleton.find_bone(name)
			elif bone >= 0:name = skeleton.get_bone_name(bone)
			if bone < 0:continue
			if name in bone_names:
				accepted[bind] = true
				rest = skeleton.get_bone_global_rest(bone) * body.skin.get_bind_pose(bind)
		if accepted.is_empty():continue
		var source: Mesh = body.get_meta("armor_original_body_mesh", body.mesh)
		for surface in source.get_surface_count():
			var arrays: Array = source.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			if bones.size() != vertices.size()*4:continue
			for start in range(0,indices.size(),3):
				var points: Array[Vector3] = []
				var belongs := false
				for corner in range(3):
					var index := indices[start+corner]
					points.append(axes.inverse()*(rest*vertices[index]))
					for influence in range(4):
						if accepted.has(bones[index*4+influence]) and weights[index*4+influence]>.45:belongs=true
				if not belongs:continue
				for level in [section_y-half_band,section_y,section_y+half_band]:
					for edge in range(3):
						var a := points[edge]
						var b := points[(edge+1)%3]
						if absf(b.y-a.y)<.00000001:continue
						var t: float = (float(level)-a.y)/(b.y-a.y)
						if t<0.0 or t>1.0:continue
						var point := a.lerp(b,t)
						result = result.expand(point) if found else AABB(point,Vector3.ZERO)
						found=true
	return result


static var _body_variants: Dictionary = {}
static var _body_profile: Dictionary = {}

static func _valid_body_profile(data: Variant) -> bool:
	if not data is Dictionary:return false
	if String(data.get("revision",""))!="kenney_body_r07":return false
	var rows: Variant = data.get("rows")
	if not rows is Array or rows.size()<2:return false
	var previous := -INF
	for row: Variant in rows:
		if not row is Array or row.size()!=3:return false
		for value: Variant in row:
			if typeof(value) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(value)):return false
		if float(row[0])<=previous or float(row[1])<=0.0 or float(row[2])<=0.0:return false
		previous=float(row[0])
	for key in ["lateral_full","lateral_end","depth_center_width"]:
		var value: Variant = data.get(key)
		if typeof(value) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(value)):return false
	if float(data.lateral_end)<=float(data.lateral_full):return false
	var center: Variant = data.get("canonical_bounds_center")
	if not center is Array or center.size()!=3:return false
	for value: Variant in center:
		if typeof(value) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(value)):return false
	for key in ["head_scale","head_blend","deltoid_scale","deltoid_lateral"]:
		var values: Variant=data.get(key)
		if not values is Array or values.size()!={"head_scale":3,"head_blend":2,"deltoid_scale":2,"deltoid_lateral":4}[key]:return false
		for value:Variant in values:
			if typeof(value) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(value)):return false
	if typeof(data.get("head_pivot_height")) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(data.head_pivot_height)):return false
	if float(data.head_blend[0])>=float(data.head_blend[1]):return false
	for value in data.head_scale:
		if float(value)<=0.0:return false
	for value in data.deltoid_scale:
		if float(value)<=0.0:return false
	for index in range(3):
		if float(data.deltoid_lateral[index])>=float(data.deltoid_lateral[index+1]):return false
	return true

static func _body_point(point: Vector3, width: float, height: float) -> Vector3:
	var rows: Array = _body_profile.rows
	var h := point.y/height
	var sx := 1.0
	var sd := 1.0
	for index in rows.size()-1:
		var a: Array = rows[index]
		var b: Array = rows[index+1]
		if h>=float(a[0]) and h<=float(b[0]):
			var t: float = (h-float(a[0]))/(float(b[0])-float(a[0]))
			sx=lerpf(float(a[1]),float(b[1]),t)
			sd=lerpf(float(a[2]),float(b[2]),t)
			break
	var edge := absf(point.x)/width
	var t := clampf((edge-float(_body_profile.lateral_full))/(float(_body_profile.lateral_end)-float(_body_profile.lateral_full)),0,1)
	var mask := 1.0-t*t*(3.0-2.0*t)
	sx=1.0+(sx-1.0)*mask
	sd=1.0+(sd-1.0)*mask
	var center := width*float(_body_profile.depth_center_width)
	var q:=Vector3(point.x*sx,point.y,center+(point.z-center)*sd)
	var lateral:Array=_body_profile.deltoid_lateral
	var shoulder_mask:float=smoothstep(lateral[0],lateral[1],edge)*(1-smoothstep(lateral[2],lateral[3],edge))*(1-smoothstep(1.20,1.28,h))*smoothstep(.70,.82,h)
	q.y=height+(q.y-height)*(1+(float(_body_profile.deltoid_scale[0])-1)*shoulder_mask)
	q.z*=1+(float(_body_profile.deltoid_scale[1])-1)*shoulder_mask
	var hm:float=smoothstep(_body_profile.head_blend[0],_body_profile.head_blend[1],h)
	var pivot:=Vector3(0,height*float(_body_profile.head_pivot_height),0)
	for index in range(3):q[index]=pivot[index]+(q[index]-pivot[index])*(1+(float(_body_profile.head_scale[index])-1)*hm)
	return q

static func _prepare_body_variant(model: Node3D) -> void:
	if String(model.get_meta("body_shape_revision",""))=="kenney_body_r07":return
	if _body_profile.is_empty():
		if not FileAccess.file_exists(PATH+"body_shape_profile.json"):return
		var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH+"body_shape_profile.json"))
		if not _valid_body_profile(loaded):return
		_body_profile=loaded
	var skeletons := model.find_children("*","Skeleton3D",true,false)
	if skeletons.is_empty():return
	var sk: Skeleton3D = skeletons[0]
	for name in ["Hips","Head","LeftArm","RightArm"]:
		if sk.find_bone(name)<0:return
	var hips := sk.get_bone_global_rest(sk.find_bone("Hips")).origin
	var head := sk.get_bone_global_rest(sk.find_bone("Head")).origin
	var left := sk.get_bone_global_rest(sk.find_bone("LeftArm")).origin
	var right := sk.get_bone_global_rest(sk.find_bone("RightArm")).origin
	var up := (head-hips).normalized()
	var horizontal := (left-right).normalized()
	horizontal=(horizontal-up*horizontal.dot(up)).normalized()
	var axes := Basis(horizontal,up,horizontal.cross(up).normalized())
	var width := left.distance_to(right)
	var height := (left-hips).dot(up)
	if width<=0.000001 or height<=0.000001 or axes.determinant()<0.000001:return
	var applied_any := false
	for body: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		if not String(body.name).to_lower().contains("character") or body.skin==null:continue
		var source: Mesh = body.get_meta("armor_source_body_mesh",body.get_meta("r07_source_body_mesh",body.get_meta("r06_source_body_mesh",body.get_meta("armor_original_body_mesh",body.mesh))))
		if source==null or source.get_surface_count()==0 or body.skin.get_bind_count()==0:continue
		body.set_meta("r07_source_body_mesh",source)
		body.set_meta("armor_source_body_mesh",source)
		var bind := 0
		var bone := body.skin.get_bind_bone(bind)
		if not String(body.skin.get_bind_name(bind)).is_empty():bone=sk.find_bone(body.skin.get_bind_name(bind))
		if bone<0:continue
		var mesh_to_rest := sk.get_bone_global_rest(bone)*body.skin.get_bind_pose(bind)
		var canonical := Transform3D(axes.inverse(),-(axes.inverse()*hips))*mesh_to_rest
		# The mission control rig's first bind has a translated origin compared
		# with the base rig. Anchor the Blender profile to the complete immutable
		# body envelope; applying the inverse transform leaves actor placement intact.
		var envelope := AABB()
		var first := true
		for surface in source.get_surface_count():
			for vertex: Vector3 in source.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var p := canonical*vertex
				envelope = AABB(p,Vector3.ZERO) if first else envelope.expand(p)
				first=false
		var reference: Array = _body_profile.canonical_bounds_center
		canonical.origin += Vector3(reference[0],reference[1],reference[2])*width-envelope.get_center()
		var key := str(source.get_rid().get_id())+str(canonical)+str(width)+str(height)
		if not _body_variants.has(key):
			var result := ArrayMesh.new()
			for surface in source.get_surface_count():
				var arrays: Array = source.surface_get_arrays(surface).duplicate(true)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				for index in vertices.size():
					var p := canonical*vertices[index]
					var q := _body_point(p,width,height)
					if p.distance_squared_to(q)<width*width*0.00000000001:continue
					vertices[index]=canonical.affine_inverse()*q
					var eps := width*.0001
					var dx := (_body_point(p+Vector3.RIGHT*eps,width,height)-_body_point(p-Vector3.RIGHT*eps,width,height))/(2*eps)
					var dy := (_body_point(p+Vector3.UP*eps,width,height)-_body_point(p-Vector3.UP*eps,width,height))/(2*eps)
					var dz := (_body_point(p+Vector3.BACK*eps,width,height)-_body_point(p-Vector3.BACK*eps,width,height))/(2*eps)
					var jacobian := canonical.basis.inverse()*Basis(dx,dy,dz)*canonical.basis
					normals[index]=(jacobian.inverse().transposed()*normals[index]).normalized()
				arrays[Mesh.ARRAY_VERTEX]=vertices
				arrays[Mesh.ARRAY_NORMAL]=normals
				result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				result.surface_set_material(surface,source.surface_get_material(surface))
			_body_variants[key]=result
		body.mesh=_body_variants[key]
		body.set_meta("armor_original_body_mesh",body.mesh)
		body.set_meta("r07_body_variant_mesh",body.mesh)
		_prepare_legacy_helmets(model,sk,mesh_to_rest*canonical.affine_inverse(),height)
		applied_any=true
	if applied_any:model.set_meta("body_shape_revision","kenney_body_r07")


static func _prepare_legacy_helmets(model:Node3D,sk:Skeleton3D,canonical_to_rest:Transform3D,height:float)->void:
	var values:Array=_body_profile.head_scale
	var scaling:=Basis.from_scale(Vector3(values[0],values[1],values[2]))
	var pivot:=Vector3(0,height*float(_body_profile.head_pivot_height),0)
	var remap:=canonical_to_rest*Transform3D(scaling,pivot-scaling*pivot)*canonical_to_rest.affine_inverse()
	for helmet:Node3D in model.find_children("HelmetVisual_*","Node3D",true,false):
		var parent:Node3D=helmet.get_parent() as Node3D
		var parent_chain:=Transform3D.IDENTITY
		while parent!=null and not parent is BoneAttachment3D and parent!=sk:
			parent_chain=parent.transform*parent_chain
			parent=parent.get_parent() as Node3D
		if not parent is BoneAttachment3D:continue
		var bone:=sk.find_bone(parent.bone_name)
		if bone<0:continue
		var parent_rest:Transform3D=sk.get_bone_global_rest(bone)*parent_chain
		if not helmet.has_meta("armor_source_transform"):helmet.set_meta("armor_source_transform",helmet.transform)
		var source:Transform3D=helmet.get_meta("armor_source_transform")
		helmet.transform=parent_rest.affine_inverse()*remap*parent_rest*source
		helmet.set_meta("body_shape_revision","kenney_body_r07")
