extends SceneTree

const LIVE_MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const NPC_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const BLASTER_IMPORT_ROOT: String = "res://Assets/used/npc/blaster_kit"
const EXPECTED_BLASTER_COUNT: int = 4
const EXPECTED_MAPPED_WEAPON_VISUAL_COUNT: int = 6
const EXPECTED_LIVE_PROXY_COUNT: int = 2
const HELMET_SOCKET_NAME: String = "HeadSocket"
const BLASTER_SOCKET_NAME: String = "RightHandSocket"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_174 Character Helmet Blaster Attachment Verifier ===")
	_test_blaster_import_subset_and_license()
	_test_mapping_attachment_contract()
	await _test_live_socket_helmet_and_blaster_attachments()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_blaster_import_subset_and_license() -> void:
	var blaster_paths: PackedStringArray = _list_files_recursive("%s/models" % BLASTER_IMPORT_ROOT, ".glb")
	_assert(blaster_paths.size() == EXPECTED_BLASTER_COUNT, "Blaster subset imports the expected GLB model count")
	for blaster_path in blaster_paths:
		_assert(ResourceLoader.exists(blaster_path), "Blaster GLB is loadable: %s" % blaster_path)
		_assert(blaster_path.get_extension().to_lower() == "glb", "Blaster import is GLB-only: %s" % blaster_path)
	_assert(_list_files_recursive(BLASTER_IMPORT_ROOT, ".fbx").is_empty(), "Blaster subset imports no FBX duplicates")
	_assert(_list_files_recursive(BLASTER_IMPORT_ROOT, ".obj").is_empty(), "Blaster subset imports no OBJ duplicates")
	_assert(_list_files_recursive(BLASTER_IMPORT_ROOT, ".mtl").is_empty(), "Blaster subset imports no MTL duplicates")
	_assert(ResourceLoader.exists("%s/models/Textures/colormap.png" % BLASTER_IMPORT_ROOT), "Blaster GLBs keep their shared colormap texture")
	_assert(ResourceLoader.exists("%s/previews/blaster-a.png" % BLASTER_IMPORT_ROOT), "SMG blaster preview PNG is loadable")
	_assert(ResourceLoader.exists("%s/previews/blaster-b.png" % BLASTER_IMPORT_ROOT), "Medictool blaster preview PNG is loadable")

	var license_text: String = _read_text("%s/License.txt" % BLASTER_IMPORT_ROOT)
	_assert(license_text.find("Creative Commons Zero") >= 0 and license_text.find("CC0") >= 0, "Blaster subset keeps the CC0 license text")
	var readme_text: String = _read_text("%s/README.md" % BLASTER_IMPORT_ROOT)
	_assert(readme_text.find("TASK_174") >= 0 and readme_text.find("RightHandSocket") >= 0, "Blaster README documents TASK_174 socket usage")


func _test_mapping_attachment_contract() -> void:
	var mapping: Dictionary = _load_json(NPC_VISUAL_MAPPING_PATH)
	_assert(not mapping.is_empty(), "NPC unit visual mapping exists")
	var defaults: Dictionary = Dictionary(mapping.get("defaults", {}))
	var helmet_attachment: Dictionary = Dictionary(defaults.get("helmet_attachment", {}))
	_assert(String(helmet_attachment.get("socket_name", "")) == HELMET_SOCKET_NAME, "Helmet attachment targets HeadSocket")
	_assert(float(helmet_attachment.get("max_scale", 1.0)) <= 0.011, "Helmet max scale is tightened for socket fit")
	_assert(_array_vector3_length(helmet_attachment.get("offset", [])) <= 0.001, "Helmet attachment stays centered on HeadSocket")
	_assert(_array_vector3_y(helmet_attachment.get("visual_offset", [])) >= 0.5, "Helmet mesh is lifted locally without moving the HeadSocket root")

	var blaster_attachment: Dictionary = Dictionary(defaults.get("blaster_attachment", {}))
	_assert(String(blaster_attachment.get("socket_name", "")) == BLASTER_SOCKET_NAME, "Blaster attachment targets RightHandSocket")
	_assert(_array_vector3_length(blaster_attachment.get("offset", [])) <= 0.001, "Blaster attachment stays centered on RightHandSocket")
	_assert(_array_vector3_x(blaster_attachment.get("rotation_degrees", [])) >= 80.0 and _array_vector3_y(blaster_attachment.get("rotation_degrees", [])) >= 80.0, "Blaster maps visible barrel down and magazine backward for idle hands")
	_assert(_array_vector3_y(blaster_attachment.get("visual_offset", [])) > 0.0 and _array_vector3_z(blaster_attachment.get("visual_offset", [])) > 0.0, "Blaster mesh is shifted so the grip sits at the hand socket")
	_assert(float(blaster_attachment.get("scale", 0.0)) > 0.0 and float(blaster_attachment.get("scale", 0.0)) <= 0.015, "Blaster attachment uses reduced hand-held visual scale")
	_assert(ResourceLoader.exists(String(blaster_attachment.get("texture_path", ""))), "Blaster attachment maps its shared colormap texture")

	var blaster_paths: Array = Array(mapping.get("blaster_paths", []))
	_assert(blaster_paths.size() == EXPECTED_MAPPED_WEAPON_VISUAL_COUNT, "Mapping tracks imported blaster kit plus expanded weapon visual GLBs")
	for blaster_path_variant in blaster_paths:
		var blaster_path: String = String(blaster_path_variant)
		_assert(ResourceLoader.exists(blaster_path), "Mapped blaster resource is loadable: %s" % blaster_path)
		_assert(blaster_path.get_extension().to_lower() == "glb", "Mapped blaster resource stays GLB-only: %s" % blaster_path)

	var visual_entries: Dictionary = Dictionary(mapping.get("unit_visuals", {}))
	for key in ["team_alpha", "team_bravo", "default"]:
		var entry: Dictionary = Dictionary(visual_entries.get(key, {}))
		_assert(not _resolve_visual_attachment_path(mapping, entry, "helmet_path").is_empty(), "%s visual entry maps a helmet" % key)
		_assert(not _resolve_visual_attachment_path(mapping, entry, "blaster_path").is_empty(), "%s visual entry maps a blaster" % key)

	var unit_entries: Dictionary = Dictionary(mapping.get("unit_ids", {}))
	for enemy_id in ["enemy_delta", "enemy_echo"]:
		var enemy_entry: Dictionary = Dictionary(unit_entries.get(enemy_id, {}))
		_assert(not _resolve_visual_attachment_path(mapping, enemy_entry, "blaster_path").is_empty(), "%s maps a blaster" % enemy_id)


func _test_live_socket_helmet_and_blaster_attachments() -> void:
	var packed_scene := load(LIVE_MISSION_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Live mission scene loads")
	if packed_scene == null:
		return

	var live_scene := packed_scene.instantiate()
	_assert(live_scene != null, "Live mission scene instantiates")
	if live_scene == null:
		return
	get_root().add_child(live_scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var simulation_root: Node = live_scene.get_node_or_null("SimulationRoot")
	var command_count_before: int = _get_array_property_size(simulation_root, "command_queue")
	var effect_count_before: int = _get_array_property_size(simulation_root, "effects_queue")

	var primary_view := live_scene.get_node_or_null("Primary3DView")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Live mission exposes Primary3DView render snapshot")
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null else {}
	var animated_count: int = int(snapshot.get("animated_unit_model_count", 0))
	_assert(animated_count >= EXPECTED_LIVE_PROXY_COUNT, "Live mission has animated unit proxies")
	_assert(int(snapshot.get("unit_head_socket_count", 0)) >= animated_count, "Animated proxies have HeadSocket")
	_assert(int(snapshot.get("unit_right_hand_socket_count", 0)) >= animated_count, "Animated proxies have RightHandSocket")
	_assert(int(snapshot.get("unit_helmet_attachment_count", 0)) >= animated_count, "Animated proxies have helmet attachments")
	_assert(int(snapshot.get("unit_helmet_error_count", 0)) == 0, "Animated proxies have no helmet attachment errors")
	_assert(int(snapshot.get("unit_blaster_attachment_count", 0)) >= animated_count, "Animated proxies have blaster attachments")
	_assert(int(snapshot.get("unit_blaster_error_count", 0)) == 0, "Animated proxies have no blaster attachment errors")
	_assert(int(snapshot.get("unit_visual_error_count", 0)) == 0, "Animated unit visuals have no import errors")

	var unit_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/UnitRoot3D") if primary_view != null else null
	_assert(unit_root != null, "UnitRoot3D is available")
	for proxy_name in ["UnitProxy_unit_alpha", "UnitProxy_enemy_delta"]:
		_assert(_visual_parent_name(unit_root, proxy_name, "HelmetVisual_") == HELMET_SOCKET_NAME, "%s helmet is attached to HeadSocket" % proxy_name)
		_assert(_visual_parent_name(unit_root, proxy_name, "BlasterVisual_") == BLASTER_SOCKET_NAME, "%s blaster is attached to RightHandSocket" % proxy_name)
		_assert(_visual_scale_within(unit_root, proxy_name, "HelmetVisual_", 0.001, 0.011), "%s helmet uses tightened visual scale" % proxy_name)
		_assert(_visual_scale_within(unit_root, proxy_name, "BlasterVisual_", 0.001, 0.015), "%s blaster uses reduced hand-held visual scale" % proxy_name)
		_assert(_visual_close_to_parent_socket(unit_root, proxy_name, "HelmetVisual_", 0.05), "%s helmet stays on HeadSocket instead of under terrain" % proxy_name)
		_assert(_visual_close_to_parent_socket(unit_root, proxy_name, "BlasterVisual_", 0.05), "%s blaster stays on RightHandSocket" % proxy_name)
		_assert(_blaster_has_textured_material(unit_root, proxy_name), "%s blaster uses the shared texture instead of plain white" % proxy_name)
		_assert(_blaster_idle_hold_orientation_matches(unit_root, proxy_name), "%s blaster barrel points down and magazine points back" % proxy_name)
		_assert(_proxy_animation_source_is_real_motion(unit_root, proxy_name, "idle"), "%s idle uses the Idle animation, not the targeting pose" % proxy_name)
		_assert(_proxy_animation_source_is_real_motion(unit_root, proxy_name, "walk"), "%s walk uses the Walk animation, not the targeting pose" % proxy_name)

	await _wait_frames(4)
	_assert(_get_array_property_size(simulation_root, "command_queue") == command_count_before, "Visual attachments do not enqueue SimulationRoot commands")
	_assert(_get_array_property_size(simulation_root, "effects_queue") == effect_count_before, "Visual attachments do not enqueue SimulationRoot effects")

	live_scene.queue_free()
	await process_frame


func _visual_parent_name(unit_root: Node, proxy_name: String, visual_prefix: String) -> String:
	var visual := _proxy_visual(unit_root, proxy_name, visual_prefix)
	if visual == null or visual.get_parent() == null:
		return ""
	return String(visual.get_parent().name)


func _visual_scale_within(unit_root: Node, proxy_name: String, visual_prefix: String, min_value: float, max_value: float) -> bool:
	var visual := _proxy_visual(unit_root, proxy_name, visual_prefix) as Node3D
	if visual == null:
		return false
	return visual.scale.x >= min_value and visual.scale.x <= max_value


func _visual_close_to_parent_socket(unit_root: Node, proxy_name: String, visual_prefix: String, max_distance: float) -> bool:
	var visual := _proxy_visual(unit_root, proxy_name, visual_prefix) as Node3D
	if visual == null or visual.get_parent() == null:
		return false
	var parent_3d := visual.get_parent() as Node3D
	if parent_3d == null:
		return false
	return visual.global_position.distance_to(parent_3d.global_position) <= max_distance


func _blaster_has_textured_material(unit_root: Node, proxy_name: String) -> bool:
	var visual := _proxy_visual(unit_root, proxy_name, "BlasterVisual_")
	if visual == null:
		return false
	return _node_has_textured_material(visual)


func _blaster_idle_hold_orientation_matches(unit_root: Node, proxy_name: String) -> bool:
	var proxy := unit_root.get_node_or_null(proxy_name) as Node3D if unit_root != null else null
	var visual := _proxy_visual(unit_root, proxy_name, "BlasterVisual_") as Node3D
	if proxy == null or visual == null:
		return false
	var barrel_direction: Vector3 = (visual.global_transform.basis * Vector3(0.0, 0.0, -1.0)).normalized()
	var magazine_direction: Vector3 = (visual.global_transform.basis * Vector3(0.0, 1.0, 0.0)).normalized()
	var npc_back: Vector3 = (proxy.global_transform.basis * Vector3(0.0, 0.0, 1.0)).normalized()
	npc_back.y = 0.0
	npc_back = npc_back.normalized()
	return barrel_direction.dot(Vector3.DOWN) >= 0.85 and magazine_direction.dot(npc_back) >= 0.70


func _node_has_textured_material(node: Node) -> bool:
	var mesh := node as MeshInstance3D
	if mesh != null:
		var material := mesh.material_override as StandardMaterial3D
		if material != null and material.albedo_texture != null:
			return true
	for child in node.get_children():
		if _node_has_textured_material(child):
			return true
	return false


func _proxy_visual(unit_root: Node, proxy_name: String, visual_prefix: String) -> Node:
	var proxy := unit_root.get_node_or_null(proxy_name) if unit_root != null else null
	if proxy == null:
		return null
	return _find_node_with_prefix(proxy, visual_prefix)


func _proxy_animation_source_is_real_motion(unit_root: Node, proxy_name: String, animation_name: String) -> bool:
	var proxy := unit_root.get_node_or_null(proxy_name) if unit_root != null else null
	if proxy == null:
		return false
	var player: AnimationPlayer = _find_animation_player(proxy)
	if player == null:
		return false
	var source_name: String = String(player.get_meta("source_animation_%s" % animation_name, "")).strip_edges().to_lower()
	return source_name.find(animation_name.to_lower()) >= 0 and source_name.find("targeting pose") < 0


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer and String(node.name) == "UnitVisualAnimationPlayer":
		return node as AnimationPlayer
	for child in node.get_children():
		var player: AnimationPlayer = _find_animation_player(child)
		if player != null:
			return player
	return null


func _find_node_with_prefix(node: Node, prefix: String) -> Node:
	if String(node.name).begins_with(prefix):
		return node
	for child in node.get_children():
		var found: Node = _find_node_with_prefix(child, prefix)
		if found != null:
			return found
	return null


func _list_files_recursive(root_path: String, extension: String) -> PackedStringArray:
	var result := PackedStringArray()
	_collect_files_recursive(root_path, extension.to_lower().replace(".", ""), result)
	return result


func _collect_files_recursive(root_path: String, extension: String, result: PackedStringArray) -> void:
	var dir := DirAccess.open(root_path)
	if dir == null:
		return
	for file_name in dir.get_files():
		if file_name.get_extension().to_lower() == extension:
			result.append("%s/%s" % [root_path, file_name])
	for dir_name in dir.get_directories():
		_collect_files_recursive("%s/%s" % [root_path, dir_name], extension, result)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _resolve_visual_attachment_path(mapping: Dictionary, visual_entry: Dictionary, key: String) -> String:
	var direct_path: String = String(visual_entry.get(key, "")).strip_edges()
	if not direct_path.is_empty():
		return direct_path
	var loadout_id: String = String(visual_entry.get("visual_loadout_id", visual_entry.get("loadout_id", ""))).strip_edges().to_lower()
	if loadout_id.is_empty():
		loadout_id = String(Dictionary(mapping.get("defaults", {})).get("visual_loadout_id", "")).strip_edges().to_lower()
	var loadouts: Dictionary = Dictionary(mapping.get("visual_loadouts", {}))
	var loadout_entry: Dictionary = Dictionary(loadouts.get(loadout_id, {}))
	return String(loadout_entry.get(key, "")).strip_edges()


func _array_vector3_length(value: Variant) -> float:
	if typeof(value) != TYPE_ARRAY:
		return 999.0
	var values: Array = Array(value)
	if values.size() < 3:
		return 999.0
	return Vector3(float(values[0]), float(values[1]), float(values[2])).length()


func _array_vector3_y(value: Variant) -> float:
	if typeof(value) != TYPE_ARRAY:
		return -999.0
	var values: Array = Array(value)
	if values.size() < 2:
		return -999.0
	return float(values[1])


func _array_vector3_x(value: Variant) -> float:
	if typeof(value) != TYPE_ARRAY:
		return 999.0
	var values: Array = Array(value)
	if values.size() < 1:
		return 999.0
	return float(values[0])


func _array_vector3_z(value: Variant) -> float:
	if typeof(value) != TYPE_ARRAY:
		return -999.0
	var values: Array = Array(value)
	if values.size() < 3:
		return -999.0
	return float(values[2])


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _get_array_property_size(node: Node, property_name: String) -> int:
	if node == null:
		return -1
	var value: Variant = node.get(property_name)
	if typeof(value) != TYPE_ARRAY:
		return -1
	return Array(value).size()


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
