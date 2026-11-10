extends Node3D
## Display-only motion and exhaust. Source phases and anchors remain read-only.

const CRUISE_CLEARANCE: float = 5.2
const TOUCHDOWN_CLEARANCE: float = 0.03
const APPROACH_DISTANCE: float = 8.0
const AIR_PHASES: Array[String] = ["inbound", "outbound", "departing", "to_mission", "to_fob", "to_homebase", "waiting"]
const GROUND_PHASES: Array[String] = ["landed", "unloading", "complete"]

var _plumes: Array[MeshInstance3D] = []
var _plume_base_scales: Array[Vector3] = []
var _nozzle_count: int = 0
var _thrust_fraction: float = 1.0
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
	if _nozzle_count > 0:
		return
	# Ref03 evaluated nozzle bounds, converted Blender XYZ -> Godot XZ-Y.
	# This helper is only attached to the unchanged Ref03 Cutlass source.
	_visual_time = fmod(float(Time.get_ticks_msec()) / 1000.0, 1000.0)
	for side in [-1.0, 1.0]:
		_add_plume(Vector3(side * 4.8617345, 2.8004422, -8.0), 0.72, 4.0, true)
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


func set_flight_response(phase: String, thrust_fraction: float = 1.0) -> void:
	set_flight_phase(phase)
	_thrust_fraction = clampf(thrust_fraction, 0.0, 1.0)


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
		var plume := _plumes[index]
		var length_scale: float = pulse * lerpf(0.42, 1.0, _thrust_fraction)
		plume.scale = _plume_base_scales[index] * Vector3(1.0, length_scale, 1.0)
		# Reposition the center after scaling: the cylinder top stays at the mouth.
		plume.position = Vector3(plume.get_meta("nozzle_anchor")) - plume.basis.y * ((plume.mesh as CylinderMesh).height * 0.5) + hover_offset
	return true


func get_visual_snapshot() -> Dictionary:
	return {
		"phase": _phase,
		"operating": _operating_visual,
		"plume_count": _nozzle_count,
		"exhaust_mesh_count": _plumes.size(),
		"thrust_fraction": _thrust_fraction,
		"service_drone_visual": _service_model != null,
		"read_only": true,
		"sets_gameplay_truth": false,
	}


func _add_plume(anchor: Vector3, radius: float, length_value: float, rearward: bool) -> void:
	_nozzle_count += 1
	_add_jet_layer(anchor, radius, length_value, rearward, false)
	_add_jet_layer(anchor, radius * 0.58, length_value * 0.62, rearward, true)


func _add_jet_layer(anchor: Vector3, radius: float, length_value: float, rearward: bool, core: bool) -> void:
	var plume := MeshInstance3D.new()
	plume.name = "ReadOnlyThruster_%d" % _plumes.size()
	var cone := CylinderMesh.new()
	cone.top_radius = radius
	cone.bottom_radius = 0.015 * radius
	cone.height = length_value
	cone.radial_segments = 16
	cone.rings = 4
	cone.cap_top = false
	cone.cap_bottom = false
	plume.mesh = cone
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec3 jet_color = vec3(0.24, 0.65, 1.0);
uniform float intensity = 0.7;
void fragment() {
	// Cylinder UV.y=0 at mouth, 1 at tip: feather both ends and sides.
	float along = (1.0 - smoothstep(0.0, 1.0, UV.y)) * smoothstep(0.0, 0.045, UV.y);
	float facing = 0.35 + 0.65 * abs(dot(normalize(NORMAL), normalize(VIEW)));
	ALBEDO = jet_color;
	EMISSION = jet_color * 1.8;
	ALPHA = along * facing * intensity;
}
"""
	material.shader = shader
	material.set_shader_parameter("jet_color", Vector3(0.70, 0.91, 1.0) if core else Vector3(0.16, 0.50, 0.92))
	material.set_shader_parameter("intensity", 0.86 if core else 0.46)
	plume.material_override = material
	plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if rearward:
		plume.rotation_degrees.x = 90.0
	plume.position = anchor - plume.basis.y * length_value * 0.5
	plume.set_meta("nozzle_anchor", anchor)
	plume.visible = _operating_visual
	add_child(plume)
	_plumes.append(plume)
	_plume_base_scales.append(plume.scale)


static func _ease(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


static func sample_maneuver(phase: String, progress: float) -> Dictionary:
	# Pure presentation curve. Caller supplies authoritative phase/progress and
	# applies route_fraction between its existing display-only route anchors.
	var t: float = clampf(progress, 0.0, 1.0)
	var departing: bool = phase.strip_edges().to_lower() in ["departing", "outbound", "takeoff"]
	var route_fraction: float = _ease((t - 0.28) / 0.72) if departing else _ease(t / 0.72)
	var height_fraction: float = _ease(t / 0.72) if departing else 1.0 - _ease((t - 0.28) / 0.72)
	var attitude: float = sin(route_fraction * PI) * (5.0 if departing else -4.0)
	return {
		"route_fraction": route_fraction,
		"clearance": lerpf(TOUCHDOWN_CLEARANCE, CRUISE_CLEARANCE, height_fraction),
		"pitch_degrees": attitude,
		"thrust_fraction": lerpf(0.55, 1.0, sin(t * PI)),
	}


static func normal_arrival_speed(distance_world: float) -> float:
	return lerpf(160.0, 1200.0, clampf(distance_world / 700.0, 0.0, 1.0))

static func arrival_clearance(distance_from_lz: float, touchdown_progress: float) -> float:
	if distance_from_lz <= 0.1:
		var t := clampf(touchdown_progress, 0.0, 1.0)
		return lerpf(2.0, TOUCHDOWN_CLEARANCE, t * t * (3.0 - 2.0*t))
	var fraction := clampf(distance_from_lz / APPROACH_DISTANCE, 0.0, 1.0)
	return lerpf(2.0, CRUISE_CLEARANCE, fraction*fraction*(3.0-2.0*fraction)) + sin(fraction*PI)*0.35
