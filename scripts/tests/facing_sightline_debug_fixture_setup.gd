extends Node

const AIM_FIRETEAM_ID: String = "aim"
const LOOK_FIRETEAM_ID: String = "look"

@export var aimed_unit_path: NodePath = NodePath("../UnitAlpha")
@export var look_unit_path: NodePath = NodePath("../UnitBravo")
@export var tactical_controller_path: NodePath = NodePath("../TacticalController")
@export var terrain_registry_path: NodePath = NodePath("../TerrainRegistry")


func _ready() -> void:
	call_deferred("_apply_fixture")


func _apply_fixture() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	await get_tree().process_frame

	var aimed_unit := get_node_or_null(aimed_unit_path)
	var look_unit := get_node_or_null(look_unit_path)
	var controller := get_node_or_null(tactical_controller_path)
	if aimed_unit == null or look_unit == null or controller == null:
		return

	_place_fixture_units(aimed_unit, look_unit)
	_configure_aimed_unit(aimed_unit)
	_configure_south_aimed_unit(look_unit)

	if controller.has_method("_set_selected_fireteams"):
		controller.call("_set_selected_fireteams", PackedStringArray([AIM_FIRETEAM_ID]), false)
	if controller.has_method("set_fire_sector_overlay_enabled"):
		controller.call("set_fire_sector_overlay_enabled", true)
	if controller.has_method("set_los_debug_overlay_enabled"):
		controller.call("set_los_debug_overlay_enabled", false)
	if controller.has_method("_refresh_order_visuals"):
		controller.call("_refresh_order_visuals")


func _place_fixture_units(aimed_unit: Node, look_unit: Node) -> void:
	var terrain_registry := get_node_or_null(terrain_registry_path)
	_set_unit_world_position(aimed_unit, _grid_to_world(terrain_registry, Vector2i(5, 3), Vector2(0.0, -128.0)))
	_set_unit_world_position(look_unit, _grid_to_world(terrain_registry, Vector2i(7, 8), Vector2(0.0, 128.0)))


func _set_unit_world_position(unit: Node, world_position: Vector2) -> void:
	if unit == null or not (unit is Node2D):
		return
	(unit as Node2D).global_position = world_position
	if unit.has_method("refresh_terrain_readability"):
		unit.call("refresh_terrain_readability")


func _grid_to_world(terrain_registry: Node, grid_position: Vector2i, fallback_offset: Vector2) -> Vector2:
	if terrain_registry != null and terrain_registry.has_method("grid_to_world"):
		return Vector2(terrain_registry.call("grid_to_world", grid_position))
	var aimed_unit := get_node_or_null(aimed_unit_path) as Node2D
	if aimed_unit != null:
		return aimed_unit.global_position + fallback_offset
	return fallback_offset


func _configure_aimed_unit(unit: Node) -> void:
	if unit == null or not (unit is Node2D):
		return
	unit.set_meta("facing_angle", deg_to_rad(-90.0))
	var origin: Vector2 = (unit as Node2D).global_position
	var weapon_target: Vector2 = origin + Vector2(384.0, 0.0)
	if unit.has_method("set_runtime_status"):
		unit.call(
			"set_runtime_status",
			"engaging",
			"engage",
			2,
			"fire_at_will",
			"facing_sightline_debug_fixture",
			1.0,
			0.0,
			0.0,
			1,
			weapon_target,
			"engage",
			"aimed",
			"debug_aimed"
		)
	elif unit.has_method("set_target_position"):
		unit.call("set_target_position", weapon_target)


func _configure_south_aimed_unit(unit: Node) -> void:
	if unit == null:
		return
	unit.set_meta("facing_angle", deg_to_rad(90.0))
	var origin: Vector2 = (unit as Node2D).global_position if unit is Node2D else Vector2.ZERO
	var weapon_target: Vector2 = origin + Vector2(0.0, 384.0)
	if unit.has_method("set_runtime_status"):
		unit.call(
			"set_runtime_status",
			"engaging",
			"engage",
			2,
			"fire_at_will",
			"facing_sightline_debug_fixture",
			1.0,
			0.0,
			0.0,
			1,
			weapon_target,
			"engage",
			"aimed",
			"debug_aimed_south"
		)
	elif unit.has_method("set_target_position"):
		unit.call("set_target_position", weapon_target)
