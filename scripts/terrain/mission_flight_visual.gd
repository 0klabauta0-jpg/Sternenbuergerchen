extends Node3D
## Display-only motion and exhaust. Source phases and anchors remain read-only.

const CRUISE_CLEARANCE: float = 5.2
const TOUCHDOWN_CLEARANCE: float = 0.03
const APPROACH_DISTANCE: float = 8.0
const AIR_PHASES: Array[String] = ["inbound", "outbound", "departing", "to_mission", "to_fob", "to_homebase", "waiting"]
const GROUND_PHASES: Array[String] = ["landed", "unloading", "complete"]

var _plumes: Array[MeshInstance3D] = []
var _plume_base_scales: Array[Vector3] = []
var _plume_base_positions: Array[Vector3] = []
var _operating_visual: bool = false
var _phase: String = ""
var _visual_time: float = 0.0
var _service_model: WeakRef = null
var _service_base_position: Vector3 = Vector3.ZERO
var _service_base_rotation: Vector3 = Vector3.ZERO


static func clearance_for_phase(phase: String, distance_from_lz: float, legacy_clearance: float) -> float:
	var normalized: String = phase.strip_edges().to_lower()
	if GROUND_PHASES.has(normalized):
		return TOUCHDOWN_CLEARANCE
	if not AIR_PHASES.has(normalized):
		return legacy_clearance
	if normalized == "inbound" or normalized == "outbound" or normalized == "departing" or normalized == "to_fob":
		if distance_from_lz >= 0.0:
			var fraction: float = clampf(distance_from_lz / APPROACH_DISTANCE, 0.0, 1.0)
			var eased: float = fraction * fraction * (3.0 - 2.0 * fraction)
			return lerpf(TOUCHDOWN_CLEARANCE, maxf(CRUISE_CLEARANCE, legacy_clearance), eased)
	return maxf(CRUISE_CLEARANCE, legacy_clearance)


func configure_cutlass_ref03() -> void:
	# Ref03 evaluated nozzle bounds, converted Blender XYZ -> Godot XZ-Y.
	# This helper is only attached to the unchanged Ref03 Cutlass source.
	_visual_time = fmod(float(Time.get_ticks_msec()) / 1000.0, 1000.0)
	for side in [-1.0, 1.0]:
		_add_plume(Vector3(side * 4.8617345, 2.8004422, -8.0), 0.72, 2.8, true)
		_add_plume(Vector3(side * 4.6327021, 2.7067473, 2.8481226), 0.34, 1.35, true)


func configure_service_drone(model: Node3D, nozzle_local_positions: Array[Vector3]) -> void:
	# The caller owns an authored prop or an actual drone identity. Never infer a
	# drone from a planned robot archetype that currently falls back to a person.
	if model == null:
		return
	_service_model = weakref(model)
	_service_base_position = model.position
	_service_base_rotation = model.rotation
	_visual_time = fmod(float(Time.get_ticks_msec()) / 1000.0, 1000.0)
	for anchor in nozzle_local_positions.slice(0, 4):
		_add_plume(anchor, 0.07, 0.26, false)


func set_flight_phase(phase: String) -> void:
	_phase = phase.strip_edges().to_lower()
	set_operating_visual(AIR_PHASES.has(_phase))


func set_operating_visual(active: bool) -> void:
	_operating_visual = active
	for plume in _plumes:
		plume.visible = active
	if not active and _service_model != null:
		var model := _service_model.get_ref() as Node3D
		if is_instance_valid(model):
			model.position = _service_base_position
			model.rotation = _service_base_rotation


func advance_visual(delta: float) -> bool:
	if not _operating_visual or not is_visible_in_tree():
		return false
	_visual_time += maxf(delta, 0.0)
	var hover_offset := Vector3.ZERO
	if _service_model != null:
		var model := _service_model.get_ref() as Node3D
		if not is_instance_valid(model):
			set_operating_visual(false)
			return false
		# Local mesh response only; the caller's gameplay/placement anchor is fixed.
		hover_offset = Vector3(0.0, sin(_visual_time * 2.3) * 0.025, 0.0)
		model.position = _service_base_position + hover_offset
		model.rotation = _service_base_rotation + Vector3(sin(_visual_time * 1.7) * 0.018, 0.0, sin(_visual_time * 1.3) * 0.025)
	for index in range(_plumes.size()):
		var pulse: float = 0.94 + 0.06 * sin(_visual_time * 16.0 + float(index) * 1.7)
		_plumes[index].scale = _plume_base_scales[index] * Vector3(1.0, pulse, 1.0)
		_plumes[index].position = _plume_base_positions[index] + hover_offset
	return true


func get_visual_snapshot() -> Dictionary:
	return {
		"phase": _phase,
		"operating": _operating_visual,
		"plume_count": _plumes.size(),
		"service_drone_visual": _service_model != null,
		"read_only": true,
		"sets_gameplay_truth": false,
	}


func _add_plume(anchor: Vector3, radius: float, length_value: float, rearward: bool) -> void:
	var plume := MeshInstance3D.new()
	plume.name = "ReadOnlyThruster_%d" % _plumes.size()
	var cone := CylinderMesh.new()
	cone.top_radius = radius
	cone.bottom_radius = 0.0
	cone.height = length_value
	cone.radial_segments = 8
	cone.rings = 1
	cone.cap_top = false
	cone.cap_bottom = false
	plume.mesh = cone
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.48, 0.87, 1.0, 0.54)
	material.emission_enabled = true
	material.emission = Color(0.14, 0.64, 0.94)
	material.emission_energy_multiplier = 1.25
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	plume.material_override = material
	plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plume.position = anchor + (Vector3(0.0, 0.0, -length_value * 0.5) if rearward else Vector3(0.0, -length_value * 0.5, 0.0))
	if rearward:
		plume.rotation_degrees.x = 90.0
	plume.visible = _operating_visual
	add_child(plume)
	_plumes.append(plume)
	_plume_base_scales.append(plume.scale)
	_plume_base_positions.append(plume.position)
