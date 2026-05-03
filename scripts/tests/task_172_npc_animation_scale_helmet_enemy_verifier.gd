extends SceneTree

const LIVE_MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const NPC_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const IMPORT_ROOT: String = "res://Assets/used/npc/animated_characters"
const EXPECTED_MAX_SCALE: float = 0.23
const EXPECTED_MIN_SCALE: float = 0.20
const EXPECTED_HELMET_MAX_SCALE: float = 0.018
const EXPECTED_HELMET_MIN_SCALE: float = 0.001
const EXPECTED_ENEMY_COUNT: int = 2

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_172 NPC Animation Scale Helmet Enemy Verifier ===")
	_test_mapping_scale_animations_helmets_and_enemies()
	await _test_live_primary_view_animation_helmets_and_enemy_visuals()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_mapping_scale_animations_helmets_and_enemies() -> void:
	var mapping: Dictionary = _load_json(NPC_VISUAL_MAPPING_PATH)
	_assert(not mapping.is_empty(), "NPC unit visual mapping exists")
	var defaults: Dictionary = Dictionary(mapping.get("defaults", {}))
	var default_scale: float = float(defaults.get("scale", 0.0))
	_assert(default_scale >= EXPECTED_MIN_SCALE and default_scale <= EXPECTED_MAX_SCALE, "Default NPC scale is reduced to roughly one third of TASK_171 scale")

	var animation_paths: Dictionary = Dictionary(defaults.get("animation_paths", mapping.get("animation_paths", {})))
	_assert(animation_paths.has("idle") and animation_paths.has("walk"), "Idle and walk animation paths are mapped")
	for animation_name in ["idle", "walk"]:
		var animation_path: String = String(animation_paths.get(animation_name, ""))
		_assert(ResourceLoader.exists(animation_path), "%s animation resource is loadable: %s" % [animation_name, animation_path])

	var helmet_paths: Array = Array(mapping.get("helmet_paths", []))
	_assert(helmet_paths.size() == 2, "Helmet subset tracks exactly two FBX helmets")
	for helmet_path_variant in helmet_paths:
		var helmet_path: String = String(helmet_path_variant)
		_assert(ResourceLoader.exists(helmet_path), "Helmet resource is loadable: %s" % helmet_path)
	var helmet_attachment: Dictionary = Dictionary(defaults.get("helmet_attachment", {}))
	_assert(String(helmet_attachment.get("scale_mode", "")) == "fit_to_model", "Helmet attachment scale is fitted to the smaller NPC model bounds")
	_assert(float(helmet_attachment.get("target_height_ratio", 0.0)) > 0.0 and float(helmet_attachment.get("target_width_ratio", 0.0)) > 0.0, "Helmet fit has explicit height and width ratios")

	var visual_entries: Dictionary = Dictionary(mapping.get("unit_visuals", {}))
	for key in ["team_alpha", "team_bravo", "default"]:
		var entry: Dictionary = Dictionary(visual_entries.get(key, {}))
		_assert(not entry.is_empty(), "%s visual entry exists" % key)
		_assert(float(entry.get("scale", 0.0)) >= EXPECTED_MIN_SCALE and float(entry.get("scale", 0.0)) <= EXPECTED_MAX_SCALE, "%s visual entry uses reduced scale" % key)
		_assert(not String(entry.get("helmet_path", "")).strip_edges().is_empty(), "%s visual entry maps a helmet" % key)

	var unit_entries: Dictionary = Dictionary(mapping.get("unit_ids", {}))
	for enemy_id in ["enemy_delta", "enemy_echo"]:
		var enemy_entry: Dictionary = Dictionary(unit_entries.get(enemy_id, {}))
		_assert(not enemy_entry.is_empty(), "%s has explicit enemy visual mapping" % enemy_id)
		_assert(String(enemy_entry.get("visual_id", "")).begins_with(enemy_id), "%s visual id is enemy-specific" % enemy_id)
		_assert(not String(enemy_entry.get("helmet_path", "")).strip_edges().is_empty(), "%s maps a helmet" % enemy_id)

	var readme_text: String = _read_text("%s/README.md" % IMPORT_ROOT)
	_assert(readme_text.find("TASK_172") >= 0 and readme_text.find("astroHelmet.fbx") >= 0, "Animated character README documents TASK_172 helmet usage")


func _test_live_primary_view_animation_helmets_and_enemy_visuals() -> void:
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
	_assert(int(snapshot.get("animated_unit_model_count", 0)) >= EXPECTED_ENEMY_COUNT, "Animated character model proxies are visible")
	_assert(int(snapshot.get("enemy_animated_unit_model_count", 0)) >= EXPECTED_ENEMY_COUNT, "Enemy NPCs use animated character visual mappings")
	_assert(int(snapshot.get("unit_animation_player_count", 0)) >= int(snapshot.get("animated_unit_model_count", 0)), "Animated unit proxies have runtime AnimationPlayers")
	_assert(int(snapshot.get("unit_animation_error_count", 0)) == 0, "Animated unit proxies have no animation import errors")
	_assert(int(snapshot.get("unit_helmet_attachment_count", 0)) >= int(snapshot.get("animated_unit_model_count", 0)), "Animated unit proxies have helmet attachments")
	_assert(int(snapshot.get("unit_helmet_error_count", 0)) == 0, "Animated unit proxies have no helmet attachment errors")
	_assert(int(snapshot.get("unit_visual_error_count", 0)) == 0, "Animated unit visuals have no import errors")

	var unit_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/UnitRoot3D") if primary_view != null else null
	_assert(unit_root != null, "UnitRoot3D is available")
	_assert(_animated_unit_model_scales_are_reduced(unit_root), "Animated unit model roots use reduced scale")
	_assert(_proxy_has_animation(unit_root, "UnitProxy_unit_alpha", "idle"), "Friendly proxy has idle animation")
	_assert(_proxy_has_animation(unit_root, "UnitProxy_enemy_delta", "idle") and _proxy_has_animation(unit_root, "UnitProxy_enemy_delta", "walk"), "Enemy proxy has idle and walk animations")
	_assert(_proxy_has_helmet(unit_root, "UnitProxy_unit_alpha"), "Friendly proxy has helmet visual attached")
	_assert(_proxy_has_helmet(unit_root, "UnitProxy_enemy_delta"), "Enemy proxy has helmet visual attached")
	_assert(_proxy_helmet_scale_is_reduced(unit_root, "UnitProxy_unit_alpha"), "Friendly helmet visual uses reduced attachment scale")
	_assert(_proxy_helmet_scale_is_reduced(unit_root, "UnitProxy_enemy_delta"), "Enemy helmet visual uses reduced attachment scale")

	var alpha := live_scene.get_node_or_null("UnitAlpha") as Node2D
	if alpha != null:
		alpha.global_position += Vector2(48.0, 0.0)
		await _wait_frames(2)
		_assert(_proxy_animation_current(unit_root, "UnitProxy_unit_alpha") == "walk", "Moved friendly proxy switches to walk animation")

	await _wait_frames(4)
	_assert(_get_array_property_size(simulation_root, "command_queue") == command_count_before, "Visual refresh does not enqueue SimulationRoot commands")
	_assert(_get_array_property_size(simulation_root, "effects_queue") == effect_count_before, "Visual refresh does not enqueue SimulationRoot effects")

	live_scene.queue_free()
	await process_frame


func _animated_unit_model_scales_are_reduced(unit_root: Node) -> bool:
	if unit_root == null:
		return false
	var inspected_count: int = 0
	for proxy in unit_root.get_children():
		var proxy_node := proxy as Node
		if proxy_node == null:
			continue
		var model_root := _find_child_with_prefix(proxy_node, "UnitModel_") as Node3D
		if model_root == null:
			continue
		if model_root.scale.x < EXPECTED_MIN_SCALE or model_root.scale.x > EXPECTED_MAX_SCALE:
			return false
		inspected_count += 1
	return inspected_count >= EXPECTED_ENEMY_COUNT


func _proxy_has_animation(unit_root: Node, proxy_name: String, animation_name: String) -> bool:
	var player: AnimationPlayer = _proxy_animation_player(unit_root, proxy_name)
	return player != null and player.has_animation(animation_name)


func _proxy_animation_current(unit_root: Node, proxy_name: String) -> String:
	var player: AnimationPlayer = _proxy_animation_player(unit_root, proxy_name)
	return String(player.current_animation) if player != null else ""


func _proxy_animation_player(unit_root: Node, proxy_name: String) -> AnimationPlayer:
	var proxy := unit_root.get_node_or_null(proxy_name) if unit_root != null else null
	if proxy == null:
		return null
	return _find_animation_player(proxy)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer and String(node.name) == "UnitVisualAnimationPlayer":
		return node as AnimationPlayer
	for child in node.get_children():
		var player: AnimationPlayer = _find_animation_player(child)
		if player != null:
			return player
	return null


func _proxy_has_helmet(unit_root: Node, proxy_name: String) -> bool:
	var proxy := unit_root.get_node_or_null(proxy_name) if unit_root != null else null
	if proxy == null:
		return false
	return _find_node_with_prefix(proxy, "HelmetVisual_") != null


func _proxy_helmet_scale_is_reduced(unit_root: Node, proxy_name: String) -> bool:
	var proxy := unit_root.get_node_or_null(proxy_name) if unit_root != null else null
	if proxy == null:
		return false
	var helmet := _find_node_with_prefix(proxy, "HelmetVisual_") as Node3D
	if helmet == null:
		return false
	return helmet.scale.x >= EXPECTED_HELMET_MIN_SCALE and helmet.scale.x <= EXPECTED_HELMET_MAX_SCALE


func _find_child_with_prefix(node: Node, prefix: String) -> Node:
	for child in node.get_children():
		if String(child.name).begins_with(prefix):
			return child
	return null


func _find_node_with_prefix(node: Node, prefix: String) -> Node:
	if String(node.name).begins_with(prefix):
		return node
	for child in node.get_children():
		var found: Node = _find_node_with_prefix(child, prefix)
		if found != null:
			return found
	return null


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
