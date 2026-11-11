extends SceneTree
const ARMOR = preload("res://scripts/terrain/personnel_armor_visual.gd")
const ACTOR = preload("res://scripts/core/base_personnel_actor.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const UNIT = preload("res://scripts/npc/test_unit.gd")
var _passed := 0
var _failed := 0
var _models: Array[Node3D] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var stage := Node3D.new()
	root.add_child(stage)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.3
	camera.position = Vector3(1.65, 0.95, 6.0)
	camera.look_at(Vector3(1.65, 0.95, 0.0))
	var light := DirectionalLight3D.new()
	stage.add_child(light)
	light.rotation_degrees = Vector3(-40, -35, 0)
	light.light_energy = 1.5
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("17353e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("dfedee")
	env.environment.ambient_light_energy = 0.65
	stage.add_child(env)
	var view := VIEW.new()
	var unit := UNIT.new()
	unit.unit_id = "armor_probe"
	var classes := ["suit", "light", "medium", "heavy"]
	var counts := [0, 15, 15, 20]
	for row in range(2):
		for index in range(4):
			unit.armor_id = classes[index]
			var model: Node3D = view.call("_create_unit_proxy", unit) if row == 1 else load("res://Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb").instantiate()
			stage.add_child(model)
			if row == 0: model.scale = Vector3.ONE * 0.4
			model.position = Vector3(index * 1.1, 1.0 if row == 0 else 0.0, 0.0)
			if row == 1: model.rotation.y = PI * 0.5
			var result := ARMOR.apply_to_model(model, classes[index])
			for body: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
				if not String(body.name).to_lower().contains("character"): continue
				_check(body.has_meta("armor_source_body_mesh") and body.has_meta("r07_body_variant_mesh"), "Original body and derived body remain separately available")
				_check(body.get_meta("armor_source_body_mesh", body.mesh) != body.get_meta("r07_body_variant_mesh", body.mesh), "All armor classes, including suit, use the revised body")
			# Mission proxies already project actual equipment before this call.
			var attachments := model.find_children("ArmorVisual_*", "MeshInstance3D", true, false)
			_check(attachments.size() == (0 if index == 0 else 1), "One combined skinned outfit")
			if row == 1:
				# Applying to a wrapper must replace any previous attachments once.
				_check(int(model.get_meta("armor_part_count", 0)) == counts[index], "Actual proxy segments %s" % classes[index])
			_check(result.ok and result.count == counts[index], "Skeletal parts %d/%s" % [row, classes[index]])
			var again := ARMOR.apply_to_model(model, classes[index])
			_check(again.get("unchanged", false), "No rebuild for unchanged armor")
			var skeletons := model.find_children("*", "Skeleton3D", true, false)
			for attachment: MeshInstance3D in attachments:
				_check(attachment.skin != null and attachment.skin.get_bind_count() == skeletons[0].get_bone_count(), "Skin uses actual existing bones")
				_check(attachment.mesh.get_surface_count() <= 5, "At most five shared material surfaces")
				var clear_visor := false
				var used_bones := {}
				for surface in attachment.mesh.get_surface_count():
					var material := attachment.mesh.surface_get_material(surface) as BaseMaterial3D
					if material != null and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and material.albedo_color.a > 0.0 and material.albedo_color.a < 1.0:
						clear_visor = true
					var arrays: Array = attachment.mesh.surface_get_arrays(surface)
					var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
					var bone_indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
					for influence in weights.size():
						if weights[influence] > 0.5:
							used_bones[skeletons[0].get_bone_name(bone_indices[influence])] = true
					_check(weights.size() == arrays[Mesh.ARRAY_VERTEX].size() * 4, "Four skin indices per vertex")
					for vertex in arrays[Mesh.ARRAY_VERTEX]:
						if not vertex.is_finite(): _check(false, "Finite fitted vertex")
				if classes[index] in ["light", "medium"]:
					_check(clear_visor, "Light and medium retain a visible transparent visor")
					_check(used_bones.has("Spine") and used_bones.has("Hips"), "Abdominal plates use torso and hip articulation")
			var label := Label3D.new()
			label.text = ("Basis · " if row == 0 else "Einsatz · ") + classes[index]
			label.font_size = 32
			label.pixel_size = 0.0017
			label.position = model.position + Vector3(0, 0.85, 0)
			stage.add_child(label)
			_models.append(model)
			for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
				for clip in player.get_animation_list():
					if "idle" in String(clip).to_lower():
						player.play(clip)
						player.advance(0)
						player.pause()
						break
	await process_frame
	await _capture("armor_front")
	for model in _models:
		var walk_clips: Array[String] = []
		for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
			var clip := _walk_clip(player)
			if clip.is_empty(): continue
			walk_clips.append(clip)
			player.play(clip)
			player.advance(0.25)
			player.pause()
		_check(not walk_clips.is_empty(), "Actual non-crouched walk clip available")
		print("ARMOR_WALK_CLIPS ", walk_clips)
	await process_frame
	await _capture("armor_walk")
	for index in range(4, 8):
		_check(view.call("_update_unit_visual_animation", _models[index], false, true, 0.0, "ready", "combat"), "Existing firing animation available")
		for player: AnimationPlayer in _models[index].find_children("*", "AnimationPlayer", true, false):
			player.advance(0.12)
			player.pause()
	await process_frame
	await _capture("armor_fire")
	for model in _models: model.rotation.y += PI
	await process_frame
	await _capture("armor_rear")
	for model in _models:
		model.rotation.y -= PI
		var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
		var head := skeleton.find_bone("Head")
		skeleton.set_bone_pose_rotation(head, Quaternion(Vector3.UP, deg_to_rad(25)))
		_check(skeleton.get_bone_pose_rotation(head).is_finite(), "Finite head-turn pose on actual rig")
	await process_frame
	await _capture("armor_head_turn")
	var duplicate := load("res://Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb").instantiate() as Node3D
	stage.add_child(duplicate)
	var duplicate_result := ARMOR.apply_to_model(duplicate, "heavy")
	var cached: MeshInstance3D = _models[3].find_children("ArmorVisual_*", "MeshInstance3D", true, false)[0]
	var medium: MeshInstance3D = _models[2].find_children("ArmorVisual_*", "MeshInstance3D", true, false)[0]
	_check(cached.mesh != medium.mesh, "Armor classes retain distinct cached outfit meshes")
	var reused: MeshInstance3D = duplicate.find_children("ArmorVisual_*", "MeshInstance3D", true, false)[0]
	_check(duplicate_result.ok and cached.mesh == reused.mesh and cached.skin == reused.skin, "Identical rigs share baked mesh and skin")
	duplicate.queue_free()
	for model in _models:
		for body: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			if not body.has_meta("armor_original_body_mesh"): continue
			var original: Mesh = body.get_meta("armor_original_body_mesh")
			var closed := String(model.get_meta("worn_armor_id")) == "heavy"
			_check((body.mesh != original) == closed, "Opaque heavy helmet covers head without mutating original mesh")
		if String(model.get_meta("worn_armor_id")) == "heavy":
			_check(ARMOR.apply_to_model(model, "medium").ok, "Heavy-to-medium equipment switch succeeds")
			for body: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
				if body.has_meta("armor_original_body_mesh"):
					_check(body.mesh == body.get_meta("armor_original_body_mesh"), "Clear medium visor restores face after opaque heavy helmet")
		_check(ARMOR.apply_to_model(model, "suit").count == 0 and model.find_children("ArmorVisual_*", "MeshInstance3D", true, false).is_empty(), "Unequip removes only armor attachments")
		for body: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			if body.has_meta("armor_original_body_mesh"):
				_check(body.mesh == body.get_meta("armor_original_body_mesh"), "Unequip restores original head geometry")
				_check(body.mesh == body.get_meta("r07_body_variant_mesh") and body.mesh != body.get_meta("armor_source_body_mesh"), "Unequip retains the revised shoulder and waist shape")
		for helmet: Node3D in model.find_children("HelmetVisual_*", "Node3D", true, false):
			_check(helmet.visible, "Unequip restores existing space helmet")
	view.free()
	unit.free()
	stage.queue_free()
	await process_frame
	print("PERSONNEL_ARMOR_VISUAL %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/native_glut_maps/revision_%s.png" % name)

func _walk_clip(player: AnimationPlayer) -> String:
	for clip in player.get_animation_list():
		var key := String(clip).to_lower()
		if key == "walk" or key.ends_with("/walk") or key.ends_with("|walk"):
			return String(clip)
	for clip in player.get_animation_list():
		var key := String(clip).to_lower()
		if "walk" in key and not "crouch" in key and not "back" in key and not "strafe" in key:
			return String(clip)
	return ""

func _check(ok: bool, message: String) -> void:
	if ok: _passed += 1
	else:
		_failed += 1
		push_error(message)
