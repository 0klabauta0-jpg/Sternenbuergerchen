extends Node

signal wave_started(wave_number: int)
signal all_waves_complete()

const STATUS_LABEL_NAME: String = "WaveStatusLabel"
const STATUS_LABEL_POSITION: Vector2 = Vector2(542.0, 176.0)
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")

@export var wave_count: int = 3
@export var units_per_wave: int = 2
@export var wave_delay_seconds: float = 45.0
@export var first_wave_delay_seconds: float = 5.0
@export var unit_registry_path: NodePath
@export var simulation_root_path: NodePath
@export var preview_mode: bool = false

var _enemy_units: Array = []
var _spawn_positions_by_unit_id: Dictionary = {}
var _patrol_paths_by_unit_id: Dictionary = {}
var _enemy_tactics_by_unit_id: Dictionary = {}
var _current_wave_number: int = 0
var _time_until_next_wave: float = 0.0
var _status_label: Label = null
var _all_waves_complete_emitted: bool = false
var _overlay_visible: bool = true
var _hex_required_hint:=false
var _hex_wave_required:=false
var _hex_wave_root_id:=0
var _hex_wave_context:=-1
var _hex_wave_slots:Array[Dictionary]=[]
var _hex_wave_generation:=0
var _hex_wave_last_stamp:=""
var _hex_wave_attempts:=0
var _hex_wave_error:Dictionary={}
var _hex_publishing_wave:=false


func _ready() -> void:
	call_deferred("_finish_ready")


func initialize_enemy_units(enemy_units: Array) -> void:
	_hex_wave_generation+=1
	var generation:int=_hex_wave_generation
	var lifetime:WeakRef=weakref(self)
	_hex_publishing_wave=false
	_hex_wave_slots.clear()
	_hex_wave_last_stamp=""
	_hex_wave_attempts=0
	_hex_wave_error.clear()
	var simulation:Node=_get_simulation_root()
	_hex_wave_required=_hex_required_hint or (simulation!=null and simulation.has_method("is_hex_ground_runtime_required") and simulation.is_hex_ground_runtime_required())
	_hex_wave_root_id=simulation.get_instance_id() if _hex_wave_required and simulation!=null else 0
	_hex_wave_context=simulation.get_hex_ground_context_revision() if _hex_wave_required and simulation!=null else -1
	_enemy_units.clear()
	_spawn_positions_by_unit_id.clear()
	_current_wave_number = 0
	_all_waves_complete_emitted = false
	for enemy_unit in enemy_units:
		if not is_instance_valid(enemy_unit) or not enemy_unit.has_method("get_unit_id"):
			continue

		_enemy_units.append(enemy_unit)
		var unit_id: String = String(enemy_unit.call("get_unit_id"))
		if enemy_unit is Node2D:
			_spawn_positions_by_unit_id[unit_id] = (enemy_unit as Node2D).global_position

		_apply_enemy_tactics(enemy_unit)
		_deactivate_enemy_unit(enemy_unit)
		var owner=lifetime.get_ref()
		if not is_instance_valid(owner) or owner.is_queued_for_deletion() or generation!=owner._hex_wave_generation:return
		if _hex_wave_required and is_instance_valid(simulation) and simulation.is_hex_ground_runtime_active() and enemy_unit is Node2D:
			if not Vector2(_spawn_positions_by_unit_id[unit_id]).is_finite():
				_hex_wave_error={"ok":false,"reason":"invalid_wave_spawn_position"}
				return
			_hex_wave_slots.append({"unit_id":unit_id,"grid":simulation.get_hex_ground_terrain_registry().world_to_grid(_spawn_positions_by_unit_id[unit_id]),"identity":simulation.call("_hex_payload_identity",unit_id)})
		if _patrol_paths_by_unit_id.has(unit_id) and enemy_unit.has_method("set_patrol_path"):
			enemy_unit.call("set_patrol_path", Array(_patrol_paths_by_unit_id.get(unit_id, [])).duplicate(true))

	_time_until_next_wave = maxf(first_wave_delay_seconds, 0.0)
	if _enemy_units.is_empty():
		_refresh_status_label()
		return

	if _time_until_next_wave <= 0.0 and _should_process_locally():
		if not _attempt_scheduled_wave():return

	_refresh_status_label()


func set_patrol_paths(patrol_paths_by_unit_id: Dictionary) -> void:
	_patrol_paths_by_unit_id.clear()
	for unit_id_variant in patrol_paths_by_unit_id.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		_patrol_paths_by_unit_id[unit_id] = Array(patrol_paths_by_unit_id.get(unit_id_variant, [])).duplicate(true)


func get_patrol_path_for_unit(unit_id: String) -> Array:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return []
	return Array(_patrol_paths_by_unit_id.get(normalized_unit_id, [])).duplicate(true)


func set_enemy_tactics(tactics_by_unit_id: Dictionary) -> void:
	_enemy_tactics_by_unit_id.clear()
	for unit_id_variant in tactics_by_unit_id.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		_enemy_tactics_by_unit_id[unit_id] = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", tactics_by_unit_id.get(unit_id_variant, {}))


func get_tactic_config_for_unit(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_default_config_for_map_size", Vector2i.ZERO)
	if _enemy_tactics_by_unit_id.has(normalized_unit_id):
		return Dictionary(_enemy_tactics_by_unit_id.get(normalized_unit_id, {})).duplicate(true)
	return ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_default_config_for_map_size", Vector2i.ZERO)


func get_current_wave_number() -> int:
	return _current_wave_number


func get_total_wave_count() -> int:
	if units_per_wave <= 0:
		return 0

	var configured_wave_count: int = max(wave_count, 0)
	var required_wave_count: int = int(ceili(float(_enemy_units.size()) / float(units_per_wave)))
	if configured_wave_count == 0:
		return required_wave_count

	return mini(configured_wave_count, required_wave_count)


func are_all_waves_started() -> bool:
	var total_wave_count: int = get_total_wave_count()
	return total_wave_count > 0 and _current_wave_number >= total_wave_count


func _process(delta: float) -> void:
	if preview_mode:
		return
	if not _should_process_locally():
		_refresh_status_label()
		return

	if _enemy_units.is_empty() or are_all_waves_started():
		_refresh_status_label()
		return

	_time_until_next_wave = maxf(_time_until_next_wave - delta, 0.0)
	if _time_until_next_wave > 0.0:
		_refresh_status_label()
		return

	if not _attempt_scheduled_wave():return

	_refresh_status_label()


func _attempt_scheduled_wave()->bool:
	var generation:int=_hex_wave_generation
	var owner_ref:WeakRef=weakref(self)
	var started:bool=_start_next_wave()
	var owner=owner_ref.get_ref()
	if not is_instance_valid(owner) or owner.is_queued_for_deletion() or generation!=owner._hex_wave_generation:return false
	if not owner.are_all_waves_started():owner._time_until_next_wave=maxf(owner.wave_delay_seconds,0.0) if started else 0.1
	return true


func _start_next_wave() -> bool:
	var total_wave_count: int = get_total_wave_count()
	if total_wave_count <= 0 or _current_wave_number >= total_wave_count or _hex_publishing_wave:
		return false
	var simulation:Node=_get_simulation_root()
	if _hex_wave_required or (simulation!=null and simulation.has_method("is_hex_ground_runtime_required") and simulation.is_hex_ground_runtime_required()):return _start_hex_wave(simulation)

	_current_wave_number += 1
	var wave_start_index: int = (_current_wave_number - 1) * max(units_per_wave, 1)
	var wave_end_index: int = mini(wave_start_index + max(units_per_wave, 1), _enemy_units.size())
	for index in range(wave_start_index, wave_end_index):
		var enemy_unit = _enemy_units[index]
		_activate_enemy_unit(enemy_unit)

	wave_started.emit(_current_wave_number)
	if are_all_waves_started() and not _all_waves_complete_emitted:
		_all_waves_complete_emitted = true
		all_waves_complete.emit()
	return true


func set_hex_ground_required(required:bool)->void:
	_hex_required_hint=required


func get_hex_wave_status()->Dictionary:
	return {"required":_hex_wave_required,"attempts":_hex_wave_attempts,"error":_hex_wave_error.duplicate(true)}


func _start_hex_wave(simulation:Node)->bool:
	if not is_instance_valid(simulation) or simulation.get_instance_id()!=_hex_wave_root_id or simulation.get_hex_ground_context_revision()!=_hex_wave_context:
		_hex_wave_error={"ok":false,"reason":"stale_hex_wave_context"}
		return false
	if not simulation.is_hex_ground_runtime_active() or simulation.call("_should_skip_local_tick_processing"):return false
	var start:int=_current_wave_number*maxi(units_per_wave,1)
	var finish:int=mini(start+maxi(units_per_wave,1),_enemy_units.size())
	if _hex_wave_slots.size()!=_enemy_units.size():return false
	var candidates:Array[Dictionary]=[]
	var ids:=PackedStringArray()
	for index in range(start,finish):
		var slot:Dictionary=_hex_wave_slots[index]
		var actor=_enemy_units[index]
		if not is_instance_valid(actor) or actor!=simulation.call("_resolve_known_unit_for_contract",slot.unit_id) or not simulation.call("_is_current_hex_payload",{"unit_id":slot.unit_id,"_hex_lifecycle":slot.identity}):
			_hex_wave_error={"ok":false,"reason":"stale_hex_wave_actor"}
			return false
		candidates.append(slot)
		ids.append(slot.unit_id)
	var excluded:Array[Vector2i]=[]
	var ship_signature:String=""
	var producer:Node=get_node_or_null("../TacticalController")
	if producer!=null and producer.has_method("get_ground_ship_blocked_cells"):
		var mask:Dictionary=producer.call("get_ground_ship_blocked_cells")
		if not mask.get("ok",false) or int(mask.get("registry_id",0))!=simulation.get_hex_ground_terrain_registry().get_instance_id():
			_hex_wave_error={"ok":false,"reason":"wave_ship_footprint_unavailable"}
			return false
		excluded.assign(mask.blocked_cells)
		ship_signature=String(mask.get("source_signature",""))
	var stamp:String=str([_current_wave_number,simulation.get_hex_ground_revision(),simulation.get_hex_ground_terrain_registry().get_revision(),ship_signature])
	if stamp==_hex_wave_last_stamp:return false
	_hex_wave_last_stamp=stamp
	_hex_wave_attempts+=1
	var result:Dictionary=simulation.admit_hex_ground_setup_actors(candidates,true,false,excluded)
	_hex_wave_error={} if result.ok else result.duplicate(true)
	if not result.ok:return false
	_current_wave_number+=1
	_hex_publishing_wave=true
	var generation:int=_hex_wave_generation
	var number:int=_current_wave_number
	var owner_ref:WeakRef=weakref(self)
	var simulation_ref:WeakRef=weakref(simulation)
	simulation.call("_publish_hex_setup_actors",ids)
	var owner=owner_ref.get_ref()
	if not is_instance_valid(owner) or owner.is_queued_for_deletion() or generation!=owner._hex_wave_generation:return true
	var bound_simulation=simulation_ref.get_ref()
	if not is_instance_valid(bound_simulation) or bound_simulation.is_queued_for_deletion() or owner._get_simulation_root()!=bound_simulation or bound_simulation.get_hex_ground_context_revision()!=owner._hex_wave_context:return true
	owner.wave_started.emit(number)
	owner=owner_ref.get_ref()
	if not is_instance_valid(owner) or owner.is_queued_for_deletion() or generation!=owner._hex_wave_generation:return true
	bound_simulation=simulation_ref.get_ref()
	if not is_instance_valid(bound_simulation) or bound_simulation.is_queued_for_deletion() or owner._get_simulation_root()!=bound_simulation or bound_simulation.get_hex_ground_context_revision()!=owner._hex_wave_context:return true
	owner._hex_publishing_wave=false
	if owner.are_all_waves_started() and not owner._all_waves_complete_emitted:
		owner._all_waves_complete_emitted=true
		owner.all_waves_complete.emit()
	return true


func _activate_enemy_unit(enemy_unit) -> void:
	if enemy_unit == null or not enemy_unit.has_method("get_unit_id"):
		return

	var unit_id: String = String(enemy_unit.call("get_unit_id"))
	var spawn_position: Vector2 = Vector2.ZERO
	if _spawn_positions_by_unit_id.has(unit_id):
		spawn_position = _spawn_positions_by_unit_id[unit_id]
	elif enemy_unit is Node2D:
		spawn_position = (enemy_unit as Node2D).global_position

	if enemy_unit.has_method("activate_for_wave"):
		enemy_unit.call("activate_for_wave", spawn_position)
	elif enemy_unit is CanvasItem:
		enemy_unit.visible = true
	_apply_enemy_tactics(enemy_unit)

	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("register_unit"):
		return

	if unit_registry.call("has_unit", unit_id):
		return

	unit_registry.call("register_unit", unit_id, enemy_unit)


func _deactivate_enemy_unit(enemy_unit) -> void:
	if enemy_unit == null or not enemy_unit.has_method("get_unit_id"):
		return

	var unit_id: String = String(enemy_unit.call("get_unit_id"))
	var simulation:Node=_get_simulation_root()
	if simulation!=null and simulation.has_method("is_hex_ground_runtime_active") and simulation.is_hex_ground_runtime_active() and simulation.call("_resolve_known_unit_for_contract",unit_id)==enemy_unit:
		simulation.release_hex_ground_unit(unit_id,"wave_staged")
	var unit_registry = _get_unit_registry()
	if unit_registry != null and unit_registry.has_method("unregister_unit") and unit_registry.call("get_unit",unit_id)==enemy_unit:
		unit_registry.call("unregister_unit", unit_id)

	if enemy_unit.has_method("deactivate_for_wave"):
		enemy_unit.call("deactivate_for_wave")
	elif enemy_unit is CanvasItem:
		enemy_unit.visible = false


func _apply_enemy_tactics(enemy_unit) -> void:
	if enemy_unit == null or not enemy_unit.has_method("get_unit_id") or not (enemy_unit is Node):
		return
	var unit_id: String = String(enemy_unit.call("get_unit_id")).strip_edges()
	if unit_id.is_empty():
		return
	var config: Dictionary = get_tactic_config_for_unit(unit_id)
	(enemy_unit as Node).set_meta("enemy_tactics_config", config.duplicate(true))
	(enemy_unit as Node).set_meta("enemy_tactics_profile_id", String(config.get("profile_id", "")))
	(enemy_unit as Node).set_meta("enemy_security_mode", String(config.get("security_mode", "")))
	(enemy_unit as Node).set_meta("enemy_facing", String(config.get("facing", "")))


func _get_unit_registry():
	if unit_registry_path.is_empty():
		return null

	return get_node_or_null(unit_registry_path)


func _ensure_status_label() -> void:
	var scene_root = get_parent()
	if scene_root == null:
		return

	_status_label = scene_root.get_node_or_null(STATUS_LABEL_NAME) as Label
	if _status_label == null:
		_status_label = Label.new()
		_status_label.name = STATUS_LABEL_NAME
		_status_label.top_level = true
		_status_label.position = STATUS_LABEL_POSITION
		_status_label.add_theme_font_size_override("font_size", 12)
		_status_label.add_theme_constant_override("outline_size", 2)
		_status_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		scene_root.add_child(_status_label)


func _refresh_status_label() -> void:
	if _status_label == null or preview_mode:
		return

	var total_wave_count: int = get_total_wave_count()
	if total_wave_count <= 0:
		_status_label.text = "WAVE -/-"
		return

	var lines: PackedStringArray = []
	lines.append("WAVE %d/%d" % [_current_wave_number, total_wave_count])
	if not are_all_waves_started():
		lines.append("NEXT %.0fs" % ceil(_time_until_next_wave))

	_status_label.text = "\n".join(lines)


func _finish_ready() -> void:
	if preview_mode:
		_remove_status_label()
		return
	_ensure_status_label()
	_apply_overlay_visibility()
	_refresh_status_label()


func set_preview_mode(is_preview: bool) -> void:
	preview_mode = is_preview
	if preview_mode:
		_remove_status_label()
		return
	if is_inside_tree():
		_ensure_status_label()
		_apply_overlay_visibility()
		_refresh_status_label()


func set_overlay_visible(is_visible: bool) -> void:
	_overlay_visible = is_visible
	_apply_overlay_visibility()


func _apply_overlay_visibility() -> void:
	if _status_label == null:
		return
	_status_label.visible = _overlay_visible and not preview_mode


func _remove_status_label() -> void:
	if _status_label != null:
		_status_label.queue_free()
		_status_label = null


func _get_simulation_root()->Node:
	var simulation_root = null
	if not simulation_root_path.is_empty():
		simulation_root = get_node_or_null(simulation_root_path)
	elif get_parent() != null:
		simulation_root = get_parent().get_node_or_null("SimulationRoot")
	return simulation_root


func _should_process_locally() -> bool:
	var simulation_root:Node=_get_simulation_root()
	if simulation_root!=null and simulation_root.has_method("_should_skip_local_tick_processing") and simulation_root.call("_should_skip_local_tick_processing"):return false

	if simulation_root == null:
		return true

	var is_server_authoritative: Variant = simulation_root.get("is_server_authoritative")
	if not _variant_to_bool(is_server_authoritative):
		return true

	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return true

	return multiplayer.is_server()


func _variant_to_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var normalized := String(value).strip_edges().to_lower()
			return normalized == "true" or normalized == "1"
		_:
			return value != null
