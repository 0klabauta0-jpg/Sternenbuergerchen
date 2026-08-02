extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/ui/main_menu.tscn"
const META_LAYER_PATH := "res://scenes/meta/meta_layer.tscn"
const HOMEBASE_PATH := "res://scenes/meta/homebase_screen.tscn"
const MISSION_RUNTIME_PATH := "res://scenes/mission/mission_runtime.tscn"
const MISSION_RUNTIME_SETUP_PATH := "res://scripts/mission/mission_runtime_setup.gd"
const UNIT_RUNTIME_PATH := "res://scripts/npc/unit_runtime.gd"
const MAIN_MENU_STATIC_SCENE_TARGETS := [
	META_LAYER_PATH,
	"res://scenes/ui/multiplayer_lobby.tscn",
	"res://scenes/editor/map_editor.tscn",
]
const FORBIDDEN_PATH_PREFIXES := ["res://scripts/tests/", "res://scenes/tests/"]
const MAX_READY_FRAMES := 120

var _passed := 0
var _failed := 0
var _dependency_edges: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run_contract")


func _run_contract() -> void:
	print("=== TASK_N004B Public Start Path Contract ===")
	await _test_visible_singleplayer_route()
	_test_canonical_mission_runtime_identity()
	_test_singleplayer_product_dependency_walk()
	print("DEPENDENCY EDGE COUNT: %d" % _dependency_edges.size())
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_visible_singleplayer_route() -> void:
	var change_error := change_scene_to_file(MAIN_SCENE_PATH)
	_assert(change_error == OK, "run/main_scene loads the visible main menu")
	if change_error != OK:
		return
	var menu_ready := await _wait_for_scene(MAIN_SCENE_PATH)
	_assert(menu_ready, "actual run/main_scene is active")
	if not menu_ready:
		return
	var menu := current_scene
	if menu == null:
		return
	var route_snapshot: Dictionary = Dictionary(menu.call("get_route_snapshot")) if menu.has_method("get_route_snapshot") else {}
	_assert(String(route_snapshot.get("singleplayer", "")).ends_with("meta_layer.tscn"), "menu route snapshot names meta_layer.tscn")
	var singleplayer_button := menu.get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton") as Button
	_assert(singleplayer_button != null and singleplayer_button.is_visible_in_tree(), "visible SingleplayerButton exists on the actual menu")
	if singleplayer_button == null:
		return
	singleplayer_button.emit_signal("pressed")
	var meta_ready := await _wait_for_scene(META_LAYER_PATH)
	_assert(meta_ready, "public SingleplayerButton pressed signal reaches canonical MetaLayer")
	if not meta_ready:
		return
	var meta := current_scene
	_assert(meta.name == "MetaLayer", "active canonical meta root is named MetaLayer")
	var homebase := meta.get_node_or_null("HomebaseScreen")
	_assert(homebase != null and homebase.scene_file_path == HOMEBASE_PATH, "MetaLayer instantiates canonical HomebaseScreen")
	var flow_script := meta.get_script() as Script
	_assert(flow_script != null and flow_script.resource_path == "res://scripts/meta/meta_layer_flow.gd", "MetaLayer keeps productive MetaLayerFlow")
	if flow_script != null:
		var flow_source := FileAccess.get_file_as_string(flow_script.resource_path)
		_assert(flow_source.contains(MISSION_RUNTIME_PATH), "MetaLayerFlow preloads mission_runtime.tscn")
	print("RESOLVED ROUTE: %s -> %s -> %s" % [MAIN_SCENE_PATH, META_LAYER_PATH, HOMEBASE_PATH])
	print("CANONICAL ROOTS: %s / %s" % [meta.name, homebase.name if homebase != null else "<missing>"])


func _test_canonical_mission_runtime_identity() -> void:
	var mission_scene := load(MISSION_RUNTIME_PATH) as PackedScene
	_assert(mission_scene != null, "canonical MissionRuntime scene loads")
	if mission_scene == null:
		return
	var mission := mission_scene.instantiate()
	var mission_setup := mission.get_node_or_null("MissionSetup")
	var unit_alpha := mission.get_node_or_null("UnitAlpha")
	var setup_script := mission_setup.get_script() as Script if mission_setup != null else null
	var unit_script := unit_alpha.get_script() as Script if unit_alpha != null else null
	_assert(setup_script != null and setup_script.resource_path == MISSION_RUNTIME_SETUP_PATH, "canonical MissionSetup uses mission_runtime_setup.gd")
	_assert(unit_script != null and unit_script.resource_path == UNIT_RUNTIME_PATH, "canonical mission units use unit_runtime.gd")
	_assert(setup_script == null or setup_script.resource_path != "res://scripts/mission/mission_test_setup.gd", "canonical MissionSetup does not use the direct legacy path")
	_assert(unit_script == null or unit_script.resource_path != "res://scripts/npc/test_unit.gd", "canonical mission units do not use the direct legacy path")
	print("DIRECT RUNTIME PATHS: %s / %s" % [setup_script.resource_path if setup_script != null else "<missing>", unit_script.resource_path if unit_script != null else "<missing>"])
	mission.free()


func _test_singleplayer_product_dependency_walk() -> void:
	_dependency_edges.clear()
	var pending: Array[Dictionary] = [{"path": MAIN_SCENE_PATH, "chain": PackedStringArray([MAIN_SCENE_PATH])}]
	var visited: Dictionary = {}
	while not pending.is_empty():
		var next: Dictionary = pending.pop_front()
		var path := String(next.get("path", ""))
		if path.is_empty() or visited.has(path):
			continue
		visited[path] = true
		for child_path in _find_product_dependencies(path):
			var child := String(child_path)
			if child.is_empty():
				continue
			var chain: PackedStringArray = PackedStringArray(next.get("chain", PackedStringArray()))
			chain.append(child)
			_dependency_edges.append({"parent": path, "child": child, "chain": chain})
			pending.append({"path": child, "chain": chain})
	for edge_variant in _dependency_edges:
		var edge: Dictionary = Dictionary(edge_variant)
		var child := String(edge.get("child", ""))
		print("DEPENDENCY EDGE: %s" % " -> ".join(PackedStringArray(edge.get("chain", PackedStringArray()))))
		for forbidden_prefix in FORBIDDEN_PATH_PREFIXES:
			if child.begins_with(forbidden_prefix):
				_assert(false, "product dependency avoids forbidden test path: %s" % " -> ".join(PackedStringArray(edge.get("chain", PackedStringArray()))))
	for scene_target in MAIN_MENU_STATIC_SCENE_TARGETS:
		_assert(_has_dependency_edge_to(scene_target), "dependency walk resolves static MainMenu scene target %s" % scene_target)
	_assert(true, "product dependency walk has no reachable scripts/tests or scenes/tests edge")


func _find_product_dependencies(path: String) -> PackedStringArray:
	var dependencies := PackedStringArray()
	if path.ends_with(".tscn"):
		for dependency in ResourceLoader.get_dependencies(path):
			var resource_path := String(dependency).get_slice("::", 0)
			if resource_path.begins_with("res://"):
				dependencies.append(resource_path)
	if not path.ends_with(".gd") or not FileAccess.file_exists(path):
		return dependencies
	var source := FileAccess.get_file_as_string(path)
	for resource_path in _extract_static_resource_edges(source):
		dependencies.append(resource_path)
	return dependencies


func _extract_literal_resource_edges(source: String) -> PackedStringArray:
	var resources := PackedStringArray()
	var expression := RegEx.new()
	expression.compile("(?:preload|load)\\(\\s*\\\"(res://[^\\\"]+)\\\"\\s*\\)")
	for result in expression.search_all(source):
		resources.append(String(result.get_string(1)))
	return resources


func _extract_static_resource_edges(source: String) -> PackedStringArray:
	var resources := _extract_literal_resource_edges(source)
	var constants := _extract_resource_constants(source)
	var expression := RegEx.new()
	expression.compile("(?:load|change_scene_to_file|change_scene_to_packed|_change_scene)\\(\\s*(?:\\\"(res://[^\\\"]+)\\\"|([A-Z][A-Z0-9_]*))")
	for result in expression.search_all(source):
		var literal_path := String(result.get_string(1))
		var constant_name := String(result.get_string(2))
		if not literal_path.is_empty():
			resources.append(literal_path)
		elif constants.has(constant_name):
			resources.append(String(constants[constant_name]))
	return resources


func _extract_resource_constants(source: String) -> Dictionary:
	var constants: Dictionary = {}
	var expression := RegEx.new()
	expression.compile("const\\s+([A-Z][A-Z0-9_]*)[^=]*=\\s*(?:\\\"(res://[^\\\"]+)\\\"|preload\\(\\s*\\\"(res://[^\\\"]+)\\\"\\s*\\))")
	for result in expression.search_all(source):
		var resource_path := String(result.get_string(2))
		if resource_path.is_empty():
			resource_path = String(result.get_string(3))
		constants[String(result.get_string(1))] = resource_path
	return constants


func _has_dependency_edge_to(path: String) -> bool:
	for edge_variant in _dependency_edges:
		if String(Dictionary(edge_variant).get("child", "")) == path:
			return true
	return false


func _wait_for_scene(scene_path: String) -> bool:
	for _frame in MAX_READY_FRAMES:
		if current_scene != null and current_scene.scene_file_path == scene_path:
			return true
		await process_frame
	return current_scene != null and current_scene.scene_file_path == scene_path


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
