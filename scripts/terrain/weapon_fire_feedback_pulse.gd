extends Node3D

const ICONS_SCRIPT: GDScript = preload("res://scripts/terrain/unit_feedback_icons.gd")
const FLASH_DURATION_MSEC: int = 300
const ICON_DURATION_MSEC: int = 720
const EVENT_HISTORY_LIMIT: int = 128

var _started_msec: int = 0
var _flash: Sprite3D = null
var _icon: Sprite3D = null


static func add_for_event(view_owner: Node, parent: Node3D, event_id: String, texture: Texture2D, muzzle_position: Vector3, source_position: Vector3) -> Node3D:
	if view_owner == null or parent == null or event_id.is_empty():
		return null
	var map_data: Object = view_owner.get("_terrain_map_data") as Object
	var map_instance_id: int = map_data.get_instance_id() if map_data != null else 0
	if int(view_owner.get_meta("weapon_fire_feedback_map_instance_id", -1)) != map_instance_id:
		view_owner.set_meta("weapon_fire_feedback_event_started_msec", {})
		view_owner.set_meta("weapon_fire_feedback_map_instance_id", map_instance_id)
	var started_by_event: Dictionary = Dictionary(view_owner.get_meta("weapon_fire_feedback_event_started_msec", {}))
	var now_msec: int = Time.get_ticks_msec()
	var started_msec: int = int(started_by_event.get(event_id, now_msec))
	if not started_by_event.has(event_id):
		started_by_event[event_id] = started_msec
		while started_by_event.size() > EVENT_HISTORY_LIMIT:
			started_by_event.erase(started_by_event.keys()[0])
		view_owner.set_meta("weapon_fire_feedback_event_started_msec", started_by_event)
	var age_msec: int = now_msec - started_msec
	if age_msec >= ICON_DURATION_MSEC:
		return null
	var pulse_script: GDScript = load("res://scripts/terrain/weapon_fire_feedback_pulse.gd")
	var pulse: Node3D = pulse_script.new()
	pulse.name = "WeaponFireReadablePulse_%s" % event_id.validate_node_name()
	pulse.set("_started_msec", started_msec)
	parent.add_child(pulse)
	var viewport: SubViewport = view_owner.get("_subviewport") as SubViewport
	var camera_size: float = float(view_owner.call("get_camera_size"))
	var world_per_pixel: float = camera_size / maxf(float(viewport.size.y) if viewport != null else 720.0, 1.0)
	if texture != null and age_msec < FLASH_DURATION_MSEC:
		var flash: Sprite3D = _make_sprite(texture, clampf(world_per_pixel * 24.0, 0.36, 1.12), muzzle_position, "MuzzleFlash")
		flash.modulate = Color(1.0, 0.96, 0.63, 1.0)
		pulse.add_child(flash)
		pulse.set("_flash", flash)
	var icon_texture: Texture2D = ICONS_SCRIPT.call("get_icon", "shot") as Texture2D
	if icon_texture != null:
		var icon: Sprite3D = _make_sprite(icon_texture, clampf(world_per_pixel * 19.0, 0.27, 0.90), source_position, "FiringIcon")
		icon.modulate = Color(1.0, 0.88, 0.50, 1.0)
		pulse.add_child(icon)
		pulse.set("_icon", icon)
	view_owner.call("_request_viewport_redraw", true, ICON_DURATION_MSEC - age_msec + 32)
	return pulse


static func _make_sprite(texture: Texture2D, world_width: float, local_position: Vector3, node_name: String) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.pixel_size = world_width / maxf(float(texture.get_width()), 1.0)
	sprite.position = local_position
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.no_depth_test = false
	sprite.double_sided = true
	return sprite


func _process(_delta: float) -> void:
	var age_msec: int = Time.get_ticks_msec() - _started_msec
	if _flash != null:
		_flash.visible = age_msec < FLASH_DURATION_MSEC
		_flash.modulate.a = clampf(1.0 - float(age_msec) / float(FLASH_DURATION_MSEC), 0.0, 1.0)
	if _icon != null:
		_icon.modulate.a = clampf(float(ICON_DURATION_MSEC - age_msec) / 220.0, 0.0, 1.0)
	if age_msec >= ICON_DURATION_MSEC:
		visible = false
		queue_free()
