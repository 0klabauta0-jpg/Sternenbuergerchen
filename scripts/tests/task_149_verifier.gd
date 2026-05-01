extends SceneTree

const MISSION_LIVE_25D_VISUAL_BRIDGE_SCRIPT: GDScript = preload("res://scripts/tests/mission_live_2_5d_visual_bridge.gd")
const MOVEMENT_LAYER_SCRIPT: GDScript = preload("res://scripts/core/movement_layer.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_149 3D Unit Visual Replacement Verifier ===")
	await _test_bridge_creates_readable_3d_unit_visual_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_bridge_creates_readable_3d_unit_visual_contract() -> void:
	var context: Dictionary = _make_bridge_context()
	var scene: Node = context["scene"]
	var bridge: Node = context["bridge"]
	var friendly_unit: Node2D = context["friendly_unit"]
	var enemy_unit: Node2D = context["enemy_unit"]
	var air_unit: Node2D = context["air_unit"]
	var friendly_position_before: Vector2 = friendly_unit.global_position
	var enemy_position_before: Vector2 = enemy_unit.global_position
	var air_position_before: Vector2 = air_unit.global_position
	for _index in range(4):
		await process_frame
	bridge.call("set_bridge_visible", true)
	var snapshot: Dictionary = Dictionary(bridge.call("sync_runtime_visuals"))
	var units: Dictionary = Dictionary(snapshot.get("units", {}))
	var friendly_snapshot: Dictionary = Dictionary(units.get("friendly_lead", {}))
	var enemy_snapshot: Dictionary = Dictionary(units.get("enemy_guard", {}))
	var air_snapshot: Dictionary = Dictionary(units.get("friendly_air", {}))
	var friendly_visual := bridge.get_node_or_null("RuntimeVisual3D/UnitVisuals3D/Unit_friendly_lead") as MeshInstance3D
	var enemy_visual := bridge.get_node_or_null("RuntimeVisual3D/UnitVisuals3D/Unit_enemy_guard") as MeshInstance3D
	var air_visual := bridge.get_node_or_null("RuntimeVisual3D/UnitVisuals3D/Unit_friendly_air") as MeshInstance3D
	var friendly_selection := bridge.get_node_or_null("RuntimeVisual3D/SelectionVisuals3D/Selection_friendly_lead") as MeshInstance3D
	var air_shadow := bridge.get_node_or_null("RuntimeVisual3D/AirShadowVisuals3D/AirShadow_friendly_air") as MeshInstance3D
	var friendly_2d_visual := friendly_unit.get_node_or_null("Visual") as CanvasItem
	var enemy_2d_visual := enemy_unit.get_node_or_null("Visual") as CanvasItem
	_assert(bool(snapshot.get("valid", false)) and int(snapshot.get("unit_count", 0)) == 3, "Bridge sync sees all registered task 149 units")
	_assert(friendly_visual != null and friendly_visual.get_node_or_null("Head") is MeshInstance3D and friendly_visual.get_node_or_null("TeamBadge") is MeshInstance3D, "Friendly unit gets a composed 3D body with head and team badge")
	_assert(friendly_visual != null and friendly_visual.get_node_or_null("LeadMarker") is MeshInstance3D and bool((friendly_visual.get_node("LeadMarker") as MeshInstance3D).visible), "Fireteam lead gets a visible 3D lead marker")
	_assert(friendly_visual != null and friendly_visual.get_node_or_null("RoleBadge") is Label3D and String((friendly_visual.get_node("RoleBadge") as Label3D).text) == "M", "Role badge exposes a compact readable role marker")
	_assert(enemy_visual != null and friendly_visual.material_override != enemy_visual.material_override, "Friendly and enemy bodies use different materials")
	_assert(air_visual != null and air_visual.material_override != friendly_visual.material_override, "Air unit uses a distinct 3D body material")
	_assert(friendly_selection != null and friendly_selection.visible, "Selected friendly unit keeps a 3D selection ring")
	_assert(air_shadow != null and air_shadow.visible and bool(air_snapshot.get("is_air", false)), "Air unit keeps a visible 3D shadow and air descriptor")
	_assert(bool(friendly_snapshot.get("is_friendly", false)) and bool(enemy_snapshot.get("is_enemy", false)), "Unit snapshots expose friendly/enemy identity")
	_assert(bool(friendly_snapshot.get("is_fireteam_lead", false)) and bool(friendly_snapshot.get("is_selected", false)), "Unit snapshot exposes lead and selection state")
	_assert(not bool(snapshot.get("legacy_2d_unit_visuals_visible", true)) and int(snapshot.get("legacy_2d_unit_visual_hidden_count", 0)) >= 3, "Primary 3D mode hides legacy 2D unit sprites")
	_assert(friendly_2d_visual != null and not friendly_2d_visual.visible and enemy_2d_visual != null and not enemy_2d_visual.visible, "Legacy 2D visual children are hidden while 3D is primary")
	bridge.call("set_2d_fallback_visible", true)
	_assert(friendly_2d_visual != null and friendly_2d_visual.visible and enemy_2d_visual != null and enemy_2d_visual.visible, "2D compare fallback restores legacy unit sprites")
	_assert(friendly_unit.global_position == friendly_position_before and enemy_unit.global_position == enemy_position_before and air_unit.global_position == air_position_before, "3D unit visual sync never mutates authoritative Node2D positions")
	scene.queue_free()
	await process_frame


func _make_bridge_context() -> Dictionary:
	var scene := Node2D.new()
	scene.name = "Task149BridgeContext"
	root.add_child(scene)
	var terrain_registry = TERRAIN_REGISTRY_SCRIPT.new()
	terrain_registry.name = "TerrainRegistry"
	terrain_registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	scene.add_child(terrain_registry)
	_register_tile(terrain_registry, Vector2i(0, 0))
	_register_tile(terrain_registry, Vector2i(1, 0))
	_register_tile(terrain_registry, Vector2i(2, 0))
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var friendly_unit: Node2D = _make_unit("friendly_lead", "team_alpha", "blue", "medic", true, terrain_registry.call("grid_to_world", Vector2i(0, 0)))
	var enemy_unit: Node2D = _make_unit("enemy_guard", "team_bravo", "", "security_guard", false, terrain_registry.call("grid_to_world", Vector2i(1, 0)))
	var air_unit: Node2D = _make_unit("friendly_air", "team_alpha", "blue", "pilot", false, terrain_registry.call("grid_to_world", Vector2i(2, 0)))
	scene.add_child(friendly_unit)
	scene.add_child(enemy_unit)
	scene.add_child(air_unit)
	friendly_unit.call("set_tactical_selected", true)
	air_unit.call("set_runtime_status", "idle", "", 0, "fire_at_will", "", 1.0, 0.0, 0.0, -1, null, 0, MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_AIR, 2)
	unit_registry.call("register_unit", "friendly_lead", friendly_unit)
	unit_registry.call("register_unit", "enemy_guard", enemy_unit)
	unit_registry.call("register_unit", "friendly_air", air_unit)
	var bridge = MISSION_LIVE_25D_VISUAL_BRIDGE_SCRIPT.new()
	bridge.name = "Mission25DVisualBridge"
	bridge.terrain_registry_path = NodePath("../TerrainRegistry")
	bridge.unit_registry_path = NodePath("../UnitRegistry")
	bridge.camera_current_when_visible = true
	bridge.hide_2d_unit_sprites_when_primary = true
	scene.add_child(bridge)
	return {
		"scene": scene,
		"bridge": bridge,
		"friendly_unit": friendly_unit,
		"enemy_unit": enemy_unit,
		"air_unit": air_unit,
	}


func _register_tile(terrain_registry: Node, grid_position: Vector2i) -> void:
	terrain_registry.call("register_tile", TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": "task_149_%d_%d" % [grid_position.x, grid_position.y],
		"type_id": "ground_flat",
		"grid_position": grid_position,
		"world_position": Vector2(float(grid_position.x - grid_position.y) * 64.0, float(grid_position.x + grid_position.y) * 32.0),
		"walkable": true,
	}))


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, role_id: String, is_lead: bool, position: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.role_id = role_id
	unit.is_fireteam_lead = is_lead
	unit.global_position = position
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.visible = true
	unit.add_child(visual)
	return unit


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
