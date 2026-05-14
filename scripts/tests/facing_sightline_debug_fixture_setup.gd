extends Node

const AIM_FIRETEAM_ID: String = "aim"
const LOOK_FIRETEAM_ID: String = "look"

@export var aimed_unit_path: NodePath = NodePath("../UnitAlpha")
@export var look_unit_path: NodePath = NodePath("../UnitBravo")
@export var tactical_controller_path: NodePath = NodePath("../TacticalController")


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

	_configure_aimed_unit(aimed_unit)
	_configure_look_unit(look_unit)

	if controller.has_method("_set_selected_fireteams"):
		controller.call("_set_selected_fireteams", PackedStringArray([AIM_FIRETEAM_ID]), false)
	if controller.has_method("set_fire_sector_overlay_enabled"):
		controller.call("set_fire_sector_overlay_enabled", true)
	if controller.has_method("set_los_debug_overlay_enabled"):
		controller.call("set_los_debug_overlay_enabled", false)
	if controller.has_method("_refresh_order_visuals"):
		controller.call("_refresh_order_visuals")


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


func _configure_look_unit(unit: Node) -> void:
	if unit == null:
		return
	unit.set_meta("facing_angle", PI)
	if unit.has_method("set_runtime_status"):
		unit.call(
			"set_runtime_status",
			"idle",
			"",
			0,
			"fire_at_will",
			"facing_sightline_debug_fixture",
			1.0,
			0.0,
			0.0,
			1,
			null,
			"idle",
			"lowered",
			"debug_lowered"
		)
