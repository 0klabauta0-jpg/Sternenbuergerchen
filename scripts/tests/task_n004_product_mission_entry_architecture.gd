extends SceneTree

const PRODUCT_SCENE_PATH := "res://scenes/mission/mission_runtime.tscn"
const LEGACY_SCENE_PATH := "res://scenes/tests/mission_reactivity_test.tscn"
const META_LAYER_SOURCE_PATH := "res://scripts/meta/meta_layer_flow.gd"
const MULTIPLAYER_LOBBY_SOURCE_PATH := "res://scripts/ui/multiplayer_lobby_screen.gd"
const EXECUTION_PATH_CONTRACT_PATH := "res://scripts/tactical/fireteam_runtime_execution_path_contract.gd"
const PRODUCT_CONTROLLER_SCRIPT_PATH := "res://scripts/tactical/mission_tactical_sandbox_controller.gd"
const REQUIRED_NODE_NAMES := [
	"SimulationRoot",
	"TacticalController",
	"CombatLoopDriver",
	"MissionSetup",
	"TerrainRegistry",
	"UnitRegistry",
	"Primary3DView",
]

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_N004A Product Mission Entry Architecture ===")
	_test_product_scene_exists_and_has_no_test_dependencies()
	_test_visible_entrypoints_preload_the_product_scene()
	_test_execution_path_contract_defaults_to_the_product_controller()
	await _test_legacy_scene_remains_a_product_scene_wrapper()
	await _test_product_scene_preserves_runtime_nodes_and_authority_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_product_scene_exists_and_has_no_test_dependencies() -> void:
	_assert(FileAccess.file_exists(PRODUCT_SCENE_PATH), "Canonical product mission scene exists")
	if not FileAccess.file_exists(PRODUCT_SCENE_PATH):
		return
	var source := FileAccess.get_file_as_string(PRODUCT_SCENE_PATH)
	_assert(not source.contains("res://scripts/tests/"), "Product mission scene has no scripts/tests dependency")
	_assert(not source.contains("res://scenes/tests/"), "Product mission scene has no scenes/tests dependency")


func _test_visible_entrypoints_preload_the_product_scene() -> void:
	var meta_layer_source := FileAccess.get_file_as_string(META_LAYER_SOURCE_PATH)
	var lobby_source := FileAccess.get_file_as_string(MULTIPLAYER_LOBBY_SOURCE_PATH)
	_assert(meta_layer_source.contains(PRODUCT_SCENE_PATH), "MetaLayerFlow preloads the canonical product mission")
	_assert(lobby_source.contains(PRODUCT_SCENE_PATH), "MultiplayerLobbyScreen preloads the canonical product mission")
	_assert(not meta_layer_source.contains(LEGACY_SCENE_PATH), "MetaLayerFlow has no legacy test-scene preload or fallback")
	_assert(not lobby_source.contains(LEGACY_SCENE_PATH), "MultiplayerLobbyScreen has no legacy test-scene preload or fallback")


func _test_execution_path_contract_defaults_to_the_product_controller() -> void:
	var contract_script := load(EXECUTION_PATH_CONTRACT_PATH) as GDScript
	_assert(contract_script != null, "Execution-path contract loads")
	if contract_script == null:
		return
	var default_snapshot: Dictionary = Dictionary(contract_script.call("build_snapshot"))
	_assert(String(default_snapshot.get("command_entry_script", "")) == PRODUCT_CONTROLLER_SCRIPT_PATH, "Execution-path contract defaults to the productive tactical controller")
	_assert(not bool(default_snapshot.get("production_extraction_needed", true)), "Execution-path contract records completed product extraction")


func _test_legacy_scene_remains_a_product_scene_wrapper() -> void:
	_assert(FileAccess.file_exists(LEGACY_SCENE_PATH), "Legacy mission scene remains loadable")
	if not FileAccess.file_exists(LEGACY_SCENE_PATH):
		return
	var legacy_source := FileAccess.get_file_as_string(LEGACY_SCENE_PATH)
	_assert(legacy_source.contains(PRODUCT_SCENE_PATH), "Legacy mission scene instances the canonical product mission")
	var legacy_scene := load(LEGACY_SCENE_PATH) as PackedScene
	_assert(legacy_scene != null, "Legacy mission wrapper loads as a PackedScene")
	if legacy_scene == null:
		return
	var legacy_mission := legacy_scene.instantiate()
	root.add_child(legacy_mission)
	await process_frame
	_assert(legacy_mission.get_node_or_null("SimulationRoot") != null, "Legacy mission wrapper exposes the product runtime graph")
	legacy_mission.queue_free()
	await process_frame


func _test_product_scene_preserves_runtime_nodes_and_authority_snapshot() -> void:
	if not ResourceLoader.exists(PRODUCT_SCENE_PATH):
		_assert(false, "Product mission scene can be instantiated for the runtime contract")
		return
	var product_scene := load(PRODUCT_SCENE_PATH) as PackedScene
	_assert(product_scene != null, "Product mission scene loads as a PackedScene")
	if product_scene == null:
		return
	var mission := product_scene.instantiate()
	root.add_child(mission)
	await process_frame
	for node_name in REQUIRED_NODE_NAMES:
		_assert(mission.get_node_or_null(NodePath(node_name)) != null, "Product mission keeps %s" % node_name)
	var controller := mission.get_node_or_null("TacticalController")
	_assert(controller != null and controller.has_method("get_fireteam_runtime_execution_path_snapshot"), "TacticalController exposes the execution-path snapshot")
	if controller != null and controller.has_method("get_fireteam_runtime_execution_path_snapshot"):
		var snapshot: Dictionary = Dictionary(controller.call("get_fireteam_runtime_execution_path_snapshot"))
		_assert(String(snapshot.get("active_path_id", "")) == "mission_tactical", "Mission tactical path remains active")
		_assert(String(snapshot.get("runtime_authority", "")) == "SimulationRoot", "SimulationRoot remains gameplay authority")
		_assert(String(snapshot.get("simulation_enqueue_method", "")) == "SimulationRoot.enqueue_command", "Mission commands still enqueue through SimulationRoot")
		_assert(String(snapshot.get("command_entry_script", "")) == PRODUCT_CONTROLLER_SCRIPT_PATH, "Runtime snapshot identifies the productive tactical controller")
		_assert(not bool(snapshot.get("snapshots_are_truth", true)), "Mission snapshots remain read-only")
	mission.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
