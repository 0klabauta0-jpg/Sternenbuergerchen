extends SceneTree

const LIVE_MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const NPC_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const CHARACTER_MODEL_PATHS: PackedStringArray = [
	"res://Assets/used/npc/animated_characters/models/characterMedium.fbx",
	"res://Assets/used/npc/animated_characters/models/characterSmall.fbx",
]
const ANIMATION_PATHS: PackedStringArray = [
	"res://Assets/used/npc/animated_characters/animations/idle.fbx",
	"res://Assets/used/npc/animated_characters/animations/walk.fbx",
]
const REQUIRED_BONES: PackedStringArray = ["Hips", "Spine", "Head", "RightHand", "LeftHand"]
const REQUIRED_SOCKETS: PackedStringArray = ["HeadSocket", "RightHandSocket"]
const EXPECTED_LIVE_PROXY_COUNT: int = 2

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_173 NPC Animation Skeleton Socket Verifier ===")
	_test_mapping_socket_contract()
	_test_imported_model_skeletons()
	_test_animation_skeleton_contract()
	await _test_live_primary_view_sockets()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_mapping_socket_contract() -> void:
	var mapping: Dictionary = _load_json(NPC_VISUAL_MAPPING_PATH)
	_assert(not mapping.is_empty(), "NPC unit visual mapping exists")
	var defaults: Dictionary = Dictionary(mapping.get("defaults", {}))
	var sockets: Dictionary = Dictionary(defaults.get("sockets", {}))
	_assert(not sockets.is_empty(), "Default socket contract is mapped")
	for socket_name in REQUIRED_SOCKETS:
		var socket_entry: Dictionary = Dictionary(sockets.get(socket_name, {}))
		_assert(not socket_entry.is_empty(), "%s is present in the socket contract" % socket_name)
		_assert(Array(socket_entry.get("bone_names", [])).size() > 0, "%s has explicit bone candidates" % socket_name)
		_assert(Array(socket_entry.get("fallback_anchor", [])).size() == 3, "%s has a documented fallback anchor" % socket_name)

	var visual_entries: Dictionary = Dictionary(mapping.get("unit_visuals", {}))
	for key in ["team_alpha", "team_bravo", "default"]:
		_assert(Dictionary(visual_entries.get(key, {})).has("model_path"), "%s visual entry keeps explicit model mapping" % key)


func _test_imported_model_skeletons() -> void:
	for model_path in CHARACTER_MODEL_PATHS:
		_assert(ResourceLoader.exists(model_path), "Character model resource exists: %s" % model_path)
		var scene := load(model_path) as PackedScene
		_assert(scene != null, "Character model loads as PackedScene: %s" % model_path)
		if scene == null:
			continue
		var instance := scene.instantiate()
		_assert(instance != null, "Character model instantiates: %s" % model_path)
		if instance == null:
			continue
		var skeleton: Skeleton3D = _find_first_skeleton(instance)
		_assert(skeleton != null, "Character model has a Skeleton3D: %s" % model_path)
		if skeleton != null:
			for bone_name in REQUIRED_BONES:
				_assert(skeleton.find_bone(bone_name) >= 0, "%s contains bone %s" % [model_path.get_file(), bone_name])
		instance.free()


func _test_animation_skeleton_contract() -> void:
	for animation_path in ANIMATION_PATHS:
		_assert(ResourceLoader.exists(animation_path), "Animation resource exists: %s" % animation_path)
		var scene := load(animation_path) as PackedScene
		_assert(scene != null, "Animation loads as PackedScene: %s" % animation_path)
		if scene == null:
			continue
		var instance := scene.instantiate()
		_assert(instance != null, "Animation scene instantiates: %s" % animation_path)
		if instance == null:
			continue
		var skeleton: Skeleton3D = _find_first_skeleton(instance)
		_assert(skeleton != null, "Animation scene keeps the shared skeleton: %s" % animation_path)
		if skeleton != null:
			_assert(skeleton.find_bone("Head") >= 0 and skeleton.find_bone("RightHand") >= 0, "%s animates head and right-hand bones" % animation_path.get_file())
		var animation: Animation = _find_first_animation(instance)
		_assert(animation != null, "Animation scene exposes a playable Animation: %s" % animation_path)
		instance.free()


func _test_live_primary_view_sockets() -> void:
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
	_assert(int(snapshot.get("unit_skeleton_count", 0)) >= animated_count, "Animated live proxies report Skeleton3D availability")
	_assert(int(snapshot.get("unit_head_socket_count", 0)) >= animated_count, "Animated live proxies report HeadSocket availability")
	_assert(int(snapshot.get("unit_right_hand_socket_count", 0)) >= animated_count, "Animated live proxies report RightHandSocket availability")
	_assert(int(snapshot.get("unit_socket_count", 0)) >= animated_count * REQUIRED_SOCKETS.size(), "Animated live proxies report required sockets")
	_assert(int(snapshot.get("unit_socket_fallback_count", -1)) == 0, "Known TASK_171 models use bone sockets without fallback anchors")
	_assert(int(snapshot.get("unit_animation_retarget_fallback_count", -1)) == 0, "Idle/Walk need no animation retarget fallback for TASK_171 models")

	var unit_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/UnitRoot3D") if primary_view != null else null
	_assert(unit_root != null, "UnitRoot3D is available")
	for proxy_name in ["UnitProxy_unit_alpha", "UnitProxy_enemy_delta"]:
		_assert(_proxy_has_socket(unit_root, proxy_name, "HeadSocket"), "%s has a HeadSocket node" % proxy_name)
		_assert(_proxy_has_socket(unit_root, proxy_name, "RightHandSocket"), "%s has a RightHandSocket node" % proxy_name)
		_assert(_proxy_socket_is_bone_attachment(unit_root, proxy_name, "HeadSocket"), "%s HeadSocket uses BoneAttachment3D" % proxy_name)
		_assert(_proxy_socket_is_bone_attachment(unit_root, proxy_name, "RightHandSocket"), "%s RightHandSocket uses BoneAttachment3D" % proxy_name)
		_assert(_proxy_has_animation(unit_root, proxy_name, "idle"), "%s has idle animation" % proxy_name)
		_assert(_proxy_has_animation(unit_root, proxy_name, "walk"), "%s has walk animation" % proxy_name)

	await _wait_frames(4)
	_assert(_get_array_property_size(simulation_root, "command_queue") == command_count_before, "Visual socket setup does not enqueue SimulationRoot commands")
	_assert(_get_array_property_size(simulation_root, "effects_queue") == effect_count_before, "Visual socket setup does not enqueue SimulationRoot effects")

	live_scene.queue_free()
	await process_frame


func _proxy_has_socket(unit_root: Node, proxy_name: String, socket_name: String) -> bool:
	return _proxy_socket(unit_root, proxy_name, socket_name) != null


func _proxy_socket_is_bone_attachment(unit_root: Node, proxy_name: String, socket_name: String) -> bool:
	var socket := _proxy_socket(unit_root, proxy_name, socket_name)
	return socket is BoneAttachment3D


func _proxy_socket(unit_root: Node, proxy_name: String, socket_name: String) -> Node:
	var proxy := unit_root.get_node_or_null(proxy_name) if unit_root != null else null
	if proxy == null:
		return null
	return _find_named_node(proxy, socket_name)


func _proxy_has_animation(unit_root: Node, proxy_name: String, animation_name: String) -> bool:
	var proxy := unit_root.get_node_or_null(proxy_name) if unit_root != null else null
	if proxy == null:
		return false
	var player: AnimationPlayer = _find_animation_player(proxy)
	return player != null and player.has_animation(animation_name)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer and String(node.name) == "UnitVisualAnimationPlayer":
		return node as AnimationPlayer
	for child in node.get_children():
		var player: AnimationPlayer = _find_animation_player(child)
		if player != null:
			return player
	return null


func _find_first_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var skeleton: Skeleton3D = _find_first_skeleton(child)
		if skeleton != null:
			return skeleton
	return null


func _find_first_animation(node: Node) -> Animation:
	if node is AnimationPlayer:
		var animation_player := node as AnimationPlayer
		for animation_name in animation_player.get_animation_list():
			var name_text: String = String(animation_name)
			if name_text.strip_edges().is_empty() or name_text == "RESET":
				continue
			var animation := animation_player.get_animation(name_text)
			if animation != null:
				return animation
	for child in node.get_children():
		var animation: Animation = _find_first_animation(child)
		if animation != null:
			return animation
	return null


func _find_named_node(node: Node, node_name: String) -> Node:
	if String(node.name) == node_name:
		return node
	for child in node.get_children():
		var found: Node = _find_named_node(child, node_name)
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
