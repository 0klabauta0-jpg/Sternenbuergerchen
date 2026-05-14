extends Node3D

const NPC_UNIT_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const DEFAULT_MODEL_PATH: String = "res://Assets/used/npc/animated_characters/models/characterMedium.fbx"
const DEFAULT_SKIN_PATH: String = "res://Assets/used/npc/animated_characters/skins/astroMaleA.png"
const SHOWCASE_ANIMATION_ORDER: PackedStringArray = [
	"attack",
	"crouch",
	"crouchIdle",
	"crouchWalk",
	"death",
	"idle",
	"interactGround",
	"interactStanding",
	"jump",
	"kick",
	"punch",
	"racingIdle",
	"racingLeft",
	"racingRight",
	"run",
	"shoot",
	"walk",
]
const SHOWCASE_COMBAT_CASE_ORDER: PackedStringArray = [
	"standShoot",
	"walkShoot",
	"runShoot",
	"crouchShoot",
	"crouchWalkShoot",
	"crouchRunShoot",
]
const SHOWCASE_COLUMNS: int = 8
const SHOWCASE_SPACING: float = 2.28
const SHOWCASE_MODEL_SCALE: float = 0.22
const SHOWCASE_MODEL_ROOT_ROTATION_Y: float = 270.0
const SHOWCASE_LABEL_HEIGHT: float = 1.42
const SHOWCASE_SCREEN_DOWN_Z_OFFSET: float = 2.25
const SHOWCASE_SHOOT_UPPER_BODY_BONE_HINTS: PackedStringArray = [
	"spine",
	"chest",
	"neck",
	"head",
	"shoulder",
	"arm",
	"forearm",
	"hand",
	"thumb",
	"index",
	"middle",
	"ring",
	"pinky",
]
const SHOWCASE_SHOOT_RIGHT_WEAPON_ARM_BONE_HINTS: PackedStringArray = [
	"rightshoulder",
	"rightarm",
	"rightforearm",
	"righthand",
	"righthandthumb",
	"righthandindex",
	"righthandmiddle",
	"righthandring",
	"righthandpinky",
]

var _slot_roots: Array[Node3D] = []
var _animation_paths: Dictionary = {}
var _combat_cases: Dictionary = {}
var _skin_material: StandardMaterial3D
var _tile_material: StandardMaterial3D
var _tile_alt_material: StandardMaterial3D


func _ready() -> void:
	_build_showcase()


func _process(delta: float) -> void:
	for slot_root in _slot_roots:
		if slot_root == null or not is_instance_valid(slot_root):
			continue
		var player := slot_root.find_child("ShowcaseAnimationPlayer", true, false) as AnimationPlayer
		if player == null or not player.is_playing():
			continue
		player.advance(maxf(delta, 0.0))


func get_showcase_snapshot() -> Dictionary:
	var entries: Array = []
	for slot_root in _slot_roots:
		if slot_root == null or not is_instance_valid(slot_root):
			continue
		entries.append({
			"animation_id": String(slot_root.get_meta("showcase_animation_id", "")),
			"case_type": String(slot_root.get_meta("showcase_case_type", "")),
			"base_animation_id": String(slot_root.get_meta("showcase_base_animation_id", "")),
			"upper_body_pose_animation_id": String(slot_root.get_meta("showcase_upper_body_pose_animation_id", "")),
			"pose_track_scope": String(slot_root.get_meta("showcase_pose_track_scope", "")),
			"shoot_pose_track_override_count": int(slot_root.get_meta("showcase_shoot_pose_track_override_count", 0)),
			"animation_path": String(slot_root.get_meta("showcase_animation_path", "")),
			"animation_loaded": bool(slot_root.get_meta("showcase_animation_loaded", false)),
			"label_text": String(slot_root.get_meta("showcase_label_text", "")),
		})
	return {
		"entry_count": entries.size(),
		"entries": entries,
		"expected_animation_count": SHOWCASE_ANIMATION_ORDER.size(),
		"expected_combat_case_count": SHOWCASE_COMBAT_CASE_ORDER.size(),
	}


func _build_showcase() -> void:
	_clear_showcase()
	_animation_paths = _load_showcase_animation_paths()
	_combat_cases = _load_combat_cases()
	_ensure_camera_and_light()
	_skin_material = _make_texture_material(DEFAULT_SKIN_PATH)
	_tile_material = _make_color_material(Color(0.18, 0.23, 0.24, 1.0))
	_tile_alt_material = _make_color_material(Color(0.22, 0.19, 0.25, 1.0))

	var model_scene := load(DEFAULT_MODEL_PATH) as PackedScene
	if model_scene == null:
		push_warning("NPC animation showcase could not load model: %s" % DEFAULT_MODEL_PATH)
		return

	for index in range(_get_showcase_entry_count()):
		var showcase_entry: Dictionary = _get_showcase_entry(index)
		var animation_id: String = String(showcase_entry.get("animation_id", "")).strip_edges()
		var base_animation_id: String = String(showcase_entry.get("base_animation_id", animation_id)).strip_edges()
		var upper_body_pose_animation_id: String = String(showcase_entry.get("upper_body_pose_animation_id", "")).strip_edges()
		var pose_track_scope: String = String(showcase_entry.get("pose_track_scope", "")).strip_edges()
		var case_type: String = String(showcase_entry.get("case_type", "raw")).strip_edges()
		var animation_path: String = String(_animation_paths.get(base_animation_id, "")).strip_edges()
		var slot_root := Node3D.new()
		slot_root.name = "AnimationSlot_%02d_%s" % [index + 1, _sanitize_node_name(animation_id)]
		slot_root.position = _slot_position(index)
		slot_root.set_meta("showcase_animation_id", animation_id)
		slot_root.set_meta("showcase_case_type", case_type)
		slot_root.set_meta("showcase_base_animation_id", base_animation_id)
		slot_root.set_meta("showcase_upper_body_pose_animation_id", upper_body_pose_animation_id)
		slot_root.set_meta("showcase_pose_track_scope", pose_track_scope)
		slot_root.set_meta("showcase_shoot_pose_track_override_count", 0)
		slot_root.set_meta("showcase_animation_path", animation_path)
		slot_root.set_meta("showcase_label_text", animation_id)
		add_child(slot_root)
		_slot_roots.append(slot_root)

		_add_slot_tile(slot_root, index)
		_add_slot_label(slot_root, animation_id)
		var model_root := Node3D.new()
		model_root.name = "ModelRoot"
		model_root.rotation_degrees.y = SHOWCASE_MODEL_ROOT_ROTATION_Y
		slot_root.add_child(model_root)

		var model_instance := model_scene.instantiate() as Node3D
		if model_instance == null:
			slot_root.set_meta("showcase_animation_loaded", false)
			continue
		model_instance.name = "CharacterMedium"
		model_instance.scale = Vector3.ONE * SHOWCASE_MODEL_SCALE
		model_root.add_child(model_instance)
		if _skin_material != null:
			_apply_material_override_recursive(model_instance, _skin_material)

		var animation: Animation = _load_animation_from_scene(animation_path, base_animation_id)
		if animation == null:
			slot_root.set_meta("showcase_animation_loaded", false)
			continue
		var upper_body_pose_animation: Animation = null
		if not upper_body_pose_animation_id.is_empty():
			var upper_body_pose_path: String = String(_animation_paths.get(upper_body_pose_animation_id, "")).strip_edges()
			upper_body_pose_animation = _load_animation_from_scene(upper_body_pose_path, upper_body_pose_animation_id)
			if upper_body_pose_animation == null:
				slot_root.set_meta("showcase_animation_loaded", false)
				continue
		_add_animation_player(slot_root, model_root, model_instance, animation_id, base_animation_id, animation, upper_body_pose_animation, pose_track_scope)
		slot_root.set_meta("showcase_animation_loaded", true)


func _clear_showcase() -> void:
	for slot_root in _slot_roots:
		if slot_root != null and is_instance_valid(slot_root):
			slot_root.queue_free()
	_slot_roots.clear()


func _load_showcase_animation_paths() -> Dictionary:
	if not ResourceLoader.exists(NPC_UNIT_VISUAL_MAPPING_PATH):
		return {}
	var file := FileAccess.open(NPC_UNIT_VISUAL_MAPPING_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(Dictionary(parsed).get("animation_showcase_paths", {}))


func _load_combat_cases() -> Dictionary:
	if not ResourceLoader.exists(NPC_UNIT_VISUAL_MAPPING_PATH):
		return {}
	var file := FileAccess.open(NPC_UNIT_VISUAL_MAPPING_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(Dictionary(parsed).get("animation_combat_cases", {}))


func _get_showcase_entry_count() -> int:
	return SHOWCASE_ANIMATION_ORDER.size() + SHOWCASE_COMBAT_CASE_ORDER.size()


func _get_showcase_entry(index: int) -> Dictionary:
	if index < SHOWCASE_ANIMATION_ORDER.size():
		var animation_id: String = String(SHOWCASE_ANIMATION_ORDER[index])
		return {
			"animation_id": animation_id,
			"case_type": "raw",
			"base_animation_id": animation_id,
			"upper_body_pose_animation_id": "",
			"pose_track_scope": "raw",
		}
	var combat_case_id: String = String(SHOWCASE_COMBAT_CASE_ORDER[index - SHOWCASE_ANIMATION_ORDER.size()])
	var combat_case: Dictionary = Dictionary(_combat_cases.get(combat_case_id, {}))
	return {
		"animation_id": combat_case_id,
		"case_type": "combat_case",
		"base_animation_id": String(combat_case.get("base_animation", "")).strip_edges(),
		"upper_body_pose_animation_id": String(combat_case.get("upper_body_pose_animation", "")).strip_edges(),
		"pose_track_scope": String(combat_case.get("pose_track_scope", "")).strip_edges(),
	}


func _slot_position(index: int) -> Vector3:
	var row: int = index / SHOWCASE_COLUMNS
	var column: int = index % SHOWCASE_COLUMNS
	var total_columns: int = min(SHOWCASE_COLUMNS, _get_showcase_entry_count())
	var total_rows: int = int(ceil(float(_get_showcase_entry_count()) / float(SHOWCASE_COLUMNS)))
	var x_offset: float = (float(total_columns - 1) * SHOWCASE_SPACING) * 0.5
	var z_offset: float = (float(total_rows - 1) * SHOWCASE_SPACING) * 0.5
	return Vector3(float(column) * SHOWCASE_SPACING - x_offset, 0.0, float(row) * SHOWCASE_SPACING - z_offset + SHOWCASE_SCREEN_DOWN_Z_OFFSET)


func _add_slot_tile(slot_root: Node3D, index: int) -> void:
	var tile := MeshInstance3D.new()
	tile.name = "Tile"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.58, 1.58)
	tile.mesh = plane
	tile.position.y = -0.02
	tile.material_override = _tile_material if index % 2 == 0 else _tile_alt_material
	slot_root.add_child(tile)


func _add_slot_label(slot_root: Node3D, animation_id: String) -> void:
	var label := Label3D.new()
	label.name = "AnimationLabel"
	label.text = animation_id
	label.position = Vector3(0.0, SHOWCASE_LABEL_HEIGHT, 0.0)
	label.pixel_size = 0.012
	label.font_size = 22
	label.modulate = Color(0.82, 0.96, 1.0, 1.0)
	label.outline_size = 5
	label.outline_modulate = Color(0.02, 0.03, 0.04, 0.92)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	slot_root.add_child(label)


func _add_animation_player(slot_root: Node3D, model_root: Node3D, model_instance: Node3D, animation_id: String, base_animation_id: String, animation: Animation, upper_body_pose_animation: Animation = null, pose_track_scope: String = "") -> void:
	var duplicated := animation.duplicate(true) as Animation
	if duplicated == null:
		slot_root.set_meta("showcase_animation_loaded", false)
		return
	duplicated.loop_mode = Animation.LOOP_LINEAR
	if upper_body_pose_animation != null:
		var override_count: int = _override_animation_shoot_pose_tracks(duplicated, upper_body_pose_animation, pose_track_scope)
		slot_root.set_meta("showcase_shoot_pose_track_override_count", override_count)
	var library := AnimationLibrary.new()
	library.add_animation(animation_id, duplicated)
	var player := AnimationPlayer.new()
	player.name = "ShowcaseAnimationPlayer"
	player.set("callback_mode_process", AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL)
	player.add_animation_library("", library)
	model_root.add_child(player)
	player.root_node = player.get_path_to(model_instance)
	player.play(animation_id)
	slot_root.set_meta("showcase_base_animation_playing", base_animation_id)


func _load_animation_from_scene(animation_scene_path: String, preferred_animation_name: String = "") -> Animation:
	if animation_scene_path.is_empty() or not ResourceLoader.exists(animation_scene_path):
		return null
	var animation_scene := load(animation_scene_path) as PackedScene
	if animation_scene == null:
		return null
	var animation_root := animation_scene.instantiate()
	if animation_root == null:
		return null
	var animation: Animation = _find_best_animation(animation_root, preferred_animation_name)
	animation_root.free()
	return animation


func _find_best_animation(node: Node, preferred_animation_name: String = "") -> Animation:
	var animation_player := node as AnimationPlayer
	if animation_player != null:
		var preferred_text: String = preferred_animation_name.strip_edges().to_lower()
		if not preferred_text.is_empty():
			for animation_name in animation_player.get_animation_list():
				var normalized_name: String = String(animation_name).strip_edges().to_lower()
				if normalized_name == "reset" or normalized_name.find("targeting pose") >= 0:
					continue
				if normalized_name.find(preferred_text) >= 0:
					return animation_player.get_animation(animation_name)
		for animation_name in animation_player.get_animation_list():
			var normalized_name: String = String(animation_name).strip_edges().to_lower()
			if normalized_name.is_empty() or normalized_name == "reset" or normalized_name.find("targeting pose") >= 0:
				continue
			return animation_player.get_animation(animation_name)
	for child in node.get_children():
		var child_animation: Animation = _find_best_animation(child, preferred_animation_name)
		if child_animation != null:
			return child_animation
	return null


func _override_animation_shoot_pose_tracks(base_animation: Animation, shoot_animation: Animation, pose_track_scope: String) -> int:
	if base_animation == null or shoot_animation == null:
		return 0
	var normalized_scope: String = pose_track_scope.strip_edges().to_lower()
	var target_length: float = maxf(base_animation.length, 0.001)
	var source_length: float = maxf(shoot_animation.length, 0.001)
	for track_index in range(base_animation.get_track_count() - 1, -1, -1):
		if base_animation.track_get_type(track_index) != Animation.TYPE_ROTATION_3D:
			continue
		var base_bone_name: String = _get_bone_name_from_animation_track_path(String(base_animation.track_get_path(track_index)))
		if not _matches_showcase_shoot_pose_scope(base_bone_name, normalized_scope):
			continue
		base_animation.remove_track(track_index)
	var override_count: int = 0
	for track_index in range(shoot_animation.get_track_count()):
		if shoot_animation.track_get_type(track_index) != Animation.TYPE_ROTATION_3D:
			continue
		var shoot_track_path: String = String(shoot_animation.track_get_path(track_index))
		var shoot_bone_name: String = _get_bone_name_from_animation_track_path(shoot_track_path)
		if not _matches_showcase_shoot_pose_scope(shoot_bone_name, normalized_scope):
			continue
		if shoot_animation.track_get_key_count(track_index) <= 0:
			continue
		var new_track_index: int = base_animation.add_track(Animation.TYPE_ROTATION_3D)
		base_animation.track_set_path(new_track_index, NodePath(shoot_track_path))
		base_animation.track_set_interpolation_type(new_track_index, shoot_animation.track_get_interpolation_type(track_index))
		for key_index in range(shoot_animation.track_get_key_count(track_index)):
			var key_time: float = shoot_animation.track_get_key_time(track_index, key_index)
			var key_value: Variant = shoot_animation.track_get_key_value(track_index, key_index)
			if typeof(key_value) != TYPE_QUATERNION:
				continue
			var mapped_key_time: float = clampf(key_time / source_length * target_length, 0.0, target_length)
			base_animation.track_insert_key(new_track_index, mapped_key_time, Quaternion(key_value))
		override_count += 1
	base_animation.set_meta("showcase_shoot_pose_track_override_count", override_count)
	base_animation.set_meta("showcase_shoot_pose_scope", normalized_scope)
	base_animation.set_meta("showcase_shoot_pose_source", "shoot")
	return override_count


func _matches_showcase_shoot_pose_scope(bone_name: String, pose_track_scope: String) -> bool:
	var normalized_scope: String = pose_track_scope.strip_edges().to_lower()
	if normalized_scope == "shoot_right_weapon_arm":
		return _bone_name_matches_any_hint(bone_name, SHOWCASE_SHOOT_RIGHT_WEAPON_ARM_BONE_HINTS)
	return _bone_name_matches_any_hint(bone_name, SHOWCASE_SHOOT_UPPER_BODY_BONE_HINTS)


func _bone_name_matches_any_hint(bone_name: String, hints: PackedStringArray) -> bool:
	var normalized_name: String = bone_name.strip_edges().to_lower()
	if normalized_name.is_empty():
		return false
	for hint in hints:
		if normalized_name.find(String(hint)) >= 0:
			return true
	return false


func _get_bone_name_from_animation_track_path(track_path: String) -> String:
	var separator_index: int = track_path.rfind(":")
	if separator_index < 0:
		return track_path.get_file().strip_edges()
	return track_path.substr(separator_index + 1).strip_edges()


func _ensure_camera_and_light() -> void:
	if get_node_or_null("Camera3D") == null:
		var camera := Camera3D.new()
		camera.name = "Camera3D"
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 18.0
		camera.current = true
		camera.position = Vector3(0.0, 10.8, 13.8)
		camera.rotation_degrees = Vector3(-58.0, 0.0, 0.0)
		add_child(camera)
	if get_node_or_null("DirectionalLight3D") == null:
		var light := DirectionalLight3D.new()
		light.name = "DirectionalLight3D"
		light.rotation_degrees = Vector3(-62.0, 38.0, 0.0)
		light.light_energy = 1.55
		add_child(light)
	if get_node_or_null("WorldEnvironment") == null:
		var environment_node := WorldEnvironment.new()
		environment_node.name = "WorldEnvironment"
		var environment := Environment.new()
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.055, 0.065, 0.07, 1.0)
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(0.78, 0.84, 0.88, 1.0)
		environment.ambient_light_energy = 0.7
		environment_node.environment = environment
		add_child(environment_node)


func _make_texture_material(texture_path: String) -> StandardMaterial3D:
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return null
	var texture := load(texture_path) as Texture2D
	if texture == null:
		return null
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 0.86
	material.metallic = 0.0
	return material


func _make_color_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.metallic = 0.0
	return material


func _apply_material_override_recursive(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material_override_recursive(child, material)


func _sanitize_node_name(value: String) -> String:
	var sanitized: String = value.strip_edges()
	for token in [" ", ".", "/", "\\", ":", ";", ",", "(", ")", "[", "]"]:
		sanitized = sanitized.replace(token, "_")
	return sanitized
