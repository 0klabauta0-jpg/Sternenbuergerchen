extends RefCounted
## Read-only skeletal equipment projection. No inventory or combat state here.
const PATH := "res://Assets/curated/personnel/armor_20261111/"
const PREFIX := "ArmorVisual_"
static var _parts: Dictionary = {}


static func apply_to_model(model: Node3D, armor_id: String) -> Dictionary:
	if String(model.get_meta("worn_armor_id", "")) == armor_id:
		return {"ok": true, "count": int(model.get_meta("armor_part_count", 0)), "unchanged": true}
	for attachment: Node in model.find_children(PREFIX + "*", "BoneAttachment3D", true, false):
		attachment.free()
	model.set_meta("worn_armor_id", "")
	model.set_meta("armor_part_count", 0)
	if armor_id == "suit":
		model.set_meta("worn_armor_id", armor_id)
		return {"ok": true, "count": 0}
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty() or armor_id not in ["light", "medium", "heavy"]:
		return {"ok": false, "reason": "armor_skeleton_or_class_missing", "count": 0}
	var skeleton: Skeleton3D = skeletons[0]
	var bones := {}
	for key: String in ["Hips", "Chest", "Head", "LeftArm", "RightArm", "LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg"]:
		var index := skeleton.find_bone(key)
		if index < 0:
			return {"ok": false, "reason": "armor_bone_missing:" + key, "count": 0}
		bones[key] = skeleton.get_bone_global_rest(index).origin
	var up: Vector3 = (Vector3(bones.Head) - Vector3(bones.Hips)).normalized()
	var right: Vector3 = Vector3(bones.LeftArm) - Vector3(bones.RightArm)
	right = (right - up * right.dot(up)).normalized()
	var forward := right.cross(up).normalized()
	var axes := Basis(right, up, forward)
	var width: float = Vector3(bones.LeftArm).distance_to(bones.RightArm)
	var torso_height: float = (Vector3(bones.LeftArm) - Vector3(bones.Hips)).dot(up)
	if width <= 0.00001 or torso_height <= 0.00001:
		return {"ok": false, "reason": "armor_rig_dimensions_invalid", "count": 0}
	var center: Vector3 = Vector3(bones.Hips) + up * torso_height * 0.60
	var count := 0
	var bulk: float = {"light": 1.0, "medium": 1.12, "heavy": 1.30}[armor_id]
	count += _attach(skeleton, "Chest", armor_id + "_chest", "Front", axes,
		center + forward * width * 0.48, Vector3(width * 1.05 * bulk, torso_height * 0.70 * bulk, width * 0.18 * bulk))
	count += _attach(skeleton, "Chest", "back_plate", "Back", axes,
		center - forward * width * 0.43, Vector3(width * 0.90 * bulk, torso_height * 0.65 * bulk, width * 0.14 * bulk))
	if armor_id in ["medium", "heavy"]:
		for side: String in ["Left", "Right"]:
			var outward := right if side == "Left" else -right
			count += _attach(skeleton, side + "Arm", "shoulder", side + "Shoulder", axes,
				Vector3(bones[side + "Arm"]) + outward * width * 0.13 - up * width * 0.07,
				Vector3(width * 0.50 * bulk, width * 0.36 * bulk, width * 0.49 * bulk))
	if armor_id == "heavy":
		for side: String in ["Left", "Right"]:
			var thigh: Vector3 = bones[side + "UpLeg"]
			var knee: Vector3 = bones[side + "Leg"]
			var length := thigh.distance_to(knee)
			count += _attach(skeleton, side + "UpLeg", "thigh", side + "Thigh", axes,
				(thigh + knee) * 0.5 + forward * width * 0.29,
				Vector3(width * 0.39, length * 0.76, width * 0.12))
			count += _attach(skeleton, side + "Leg", "shin", side + "Shin", axes,
				knee - up * length * 0.52 + forward * width * 0.23,
				Vector3(width * 0.37, length * 0.80, width * 0.14))
		count += _attach(skeleton, "Chest", "collar", "Collar", axes,
			Vector3(bones.Chest) + up * torso_height * 0.37 - forward * width * 0.12,
			Vector3(width * 1.0, width * 0.16, width * 0.57))
	model.set_meta("armor_part_count", count)
	var ok: bool = count == {"light": 2, "medium": 4, "heavy": 9}[armor_id]
	if ok: model.set_meta("worn_armor_id", armor_id)
	return {"ok": ok, "count": count}


static func _attach(skeleton: Skeleton3D, bone: String, part: String, label: String, axes: Basis, center: Vector3, dimensions: Vector3) -> int:
	if not _parts.has(part):
		var scene: PackedScene = load(PATH + part + ".glb")
		if scene == null:
			return 0
		var probe: Node3D = scene.instantiate()
		var meshes := probe.find_children("*", "MeshInstance3D", true, false)
		if probe is MeshInstance3D:
			meshes.append(probe)
		var bounds := AABB()
		for mesh: MeshInstance3D in meshes:
			var relative: Transform3D = probe.transform.affine_inverse() * mesh.transform if mesh == probe else _relative_transform(probe, mesh)
			var box := relative * mesh.get_aabb()
			bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
		probe.free()
		_parts[part] = {"scene": scene, "bounds": bounds}
	var entry: Dictionary = _parts[part]
	var bounds: AABB = entry.bounds
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or bounds.size.z <= 0.0:
		return 0
	var attachment := BoneAttachment3D.new()
	attachment.name = PREFIX + label
	attachment.bone_name = bone
	skeleton.add_child(attachment)
	attachment.transform = skeleton.get_bone_global_pose(skeleton.find_bone(bone))
	var instance: Node3D = entry.scene.instantiate()
	attachment.add_child(instance)
	var scaled_axes := axes.scaled_local(dimensions / bounds.size)
	var desired := Transform3D(scaled_axes, center - scaled_axes * bounds.get_center())
	instance.transform = skeleton.get_bone_global_rest(skeleton.find_bone(bone)).affine_inverse() * desired
	return 1


static func _relative_transform(root: Node3D, node: Node3D) -> Transform3D:
	var result := node.transform
	var parent := node.get_parent() as Node3D
	while parent != null and parent != root:
		result = parent.transform * result
		parent = parent.get_parent() as Node3D
	return result
