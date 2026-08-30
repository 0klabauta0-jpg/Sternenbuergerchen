extends SceneTree

const LIVE_MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const NPC_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const IMPORT_ROOT: String = "res://Assets/used/npc/animated_characters"
const EXPECTED_MODEL_COUNT: int = 2
const EXPECTED_SKIN_COUNT: int = 2
const EXPECTED_ANIMATION_PROBE_COUNT: int = 2

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_171 NPC Model Replacement Verifier ===")
	_test_mapping_and_import_subset()
	await _test_live_primary_view_uses_animated_character_models()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_mapping_and_import_subset() -> void:
	var mapping: Dictionary = _load_json(NPC_VISUAL_MAPPING_PATH)
	_assert(not mapping.is_empty(), "NPC unit visual mapping exists")
	_assert(String(Dictionary(mapping.get("source", {})).get("license", "")) == "CC0", "NPC visual mapping records CC0 license")

	var visual_entries: Dictionary = Dictionary(mapping.get("unit_visuals", {}))
	var model_paths: PackedStringArray = PackedStringArray()
	var skin_paths: PackedStringArray = PackedStringArray()
	for key in ["team_alpha", "team_bravo"]:
		var entry: Dictionary = Dictionary(visual_entries.get(key, {}))
		_assert(not entry.is_empty(), "%s has an explicit animated character visual entry" % key)
		_add_unique_path(model_paths, String(entry.get("model_path", "")))
		_add_unique_path(skin_paths, String(entry.get("skin_path", "")))

	_assert(model_paths.size() == EXPECTED_MODEL_COUNT, "Import subset maps exactly two character models")
	_assert(skin_paths.size() == EXPECTED_SKIN_COUNT, "Import subset maps exactly two astro skins")
	for model_path in model_paths:
		_assert(ResourceLoader.exists(model_path), "Imported model is loadable: %s" % model_path)
	for skin_path in skin_paths:
		_assert(ResourceLoader.exists(skin_path), "Imported skin is loadable: %s" % skin_path)

	var animation_probe_paths: Array = Array(mapping.get("animation_probe_paths", []))
	_assert(animation_probe_paths.size() == EXPECTED_ANIMATION_PROBE_COUNT, "Import subset tracks idle/walk animation probes only")
	for animation_path_variant in animation_probe_paths:
		var animation_path: String = String(animation_path_variant)
		_assert(ResourceLoader.exists(animation_path), "Imported animation probe is loadable: %s" % animation_path)

	var license_text: String = _read_text("%s/License.txt" % IMPORT_ROOT)
	_assert(license_text.find("Creative Commons Zero") >= 0 and license_text.find("CC0") >= 0, "Imported subset keeps the CC0 license text")


func _test_live_primary_view_uses_animated_character_models() -> void:
	var packed_scene := load(LIVE_MISSION_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Live mission scene loads")
	if packed_scene == null:
		return

	var live_scene := packed_scene.instantiate()
	_assert(live_scene != null, "Live mission scene instantiates")
	if live_scene == null:
		return
	get_root().add_child(live_scene)
	await _wait_frames(16)
	await _wait_physics_frames(4)

	var simulation_root: Node = live_scene.get_node_or_null("SimulationRoot")
	var command_count_before: int = _get_array_property_size(simulation_root, "command_queue")
	var effect_count_before: int = _get_array_property_size(simulation_root, "effects_queue")

	var primary_view := live_scene.get_node_or_null("Primary3DView")
	_assert(primary_view != null and primary_view.has_method("get_render_snapshot"), "Live mission exposes Primary3DView render snapshot")
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null else {}
	_assert(bool(snapshot.get("unit_visual_mapping_loaded", false)), "Primary3DView loaded the NPC unit visual mapping")
	_assert(int(snapshot.get("animated_unit_model_count", 0)) >= EXPECTED_MODEL_COUNT, "Live units use animated character model proxies")
	_assert(int(snapshot.get("unit_model_count", 0)) >= EXPECTED_MODEL_COUNT, "Live units remain 3D model proxies")
	_assert(int(snapshot.get("unit_texture_count", 0)) == 0, "Live units do not fall back to 2D unit textures")
	_assert(int(snapshot.get("missing_unit_model_count", 0)) == 0, "Live units have no missing model markers")
	_assert(int(snapshot.get("unit_visual_error_count", 0)) == 0, "Live units have no animated character visual import errors")
	_assert(_animated_unit_model_nodes_have_meshes(primary_view), "Animated unit model nodes contain meshes")

	await _wait_frames(4)
	_assert(_get_array_property_size(simulation_root, "command_queue") == command_count_before, "Visual refresh does not enqueue SimulationRoot commands")
	_assert(_get_array_property_size(simulation_root, "effects_queue") == effect_count_before, "Visual refresh does not enqueue SimulationRoot effects")

	live_scene.queue_free()
	await process_frame


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _add_unique_path(paths: PackedStringArray, path: String) -> void:
	var normalized_path: String = path.strip_edges()
	if normalized_path.is_empty() or paths.has(normalized_path):
		return
	paths.append(normalized_path)


func _animated_unit_model_nodes_have_meshes(primary_view: Node) -> bool:
	if primary_view == null:
		return false
	var unit_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/UnitRoot3D")
	if unit_root == null:
		return false
	var inspected_count: int = 0
	for proxy in unit_root.get_children():
		if proxy.is_queued_for_deletion() or not proxy is Node3D:
			continue
		var model_root: Node = null
		for child in proxy.get_children():
			if String(child.name).begins_with("UnitModel_"):
				model_root = child
				break
		if model_root == null or not _node_has_mesh(model_root):
			return false
		inspected_count += 1
	return inspected_count >= EXPECTED_MODEL_COUNT


func _node_has_mesh(node: Node) -> bool:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return true
	for child in node.get_children():
		if _node_has_mesh(child):
			return true
	return false


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
