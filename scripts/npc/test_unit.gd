class_name TestUnit
extends Node2D

const COMMANDER_COMMAND_SCRIPT: GDScript = preload("res://scripts/command/commander_command.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT_SKILLS_SCRIPT: GDScript = preload("res://scripts/npc/unit_skills.gd")
const UNIT_TRAIT_SCRIPT: GDScript = preload("res://scripts/npc/unit_trait.gd")
const UNIT_PROFILE_MATH_SCRIPT: GDScript = preload("res://scripts/npc/unit_profile_math.gd")
const UNIT_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_runtime_status.gd")
const UNIT_VITAL_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_vital_status.gd")
const VISUAL_SPRITE_NAME: String = "Visual"
const WEAPON_VISUAL_NAME: String = "WeaponVisual"
const DEFAULT_WEAPON_VISUAL_DIRECTION: String = "SE"
const WEAPON_VISUAL_OFFSETS: Dictionary = {
	"SE": Vector2(10.0, -4.0),
	"SW": Vector2(-10.0, -4.0),
	"NE": Vector2(8.0, -14.0),
	"NW": Vector2(-8.0, -14.0),
}
const STATUS_LABEL_NAME: String = "DebugStatusLabel"
const FIRETEAM_LABEL_NAME: String = "DebugFireteamLabel"
const PHASE_LABEL_NAME: String = "DebugPhaseLabel"
const TACTICAL_STANCE_LABEL_NAME: String = "DebugTacticalStanceLabel"
const EVENT_LABEL_NAME: String = "DebugEventLabel"
const SELECTION_RING_NAME: String = "SelectionRing"
const STATUS_LABEL_OFFSET: Vector2 = Vector2(-54.0, -48.0)
const FIRETEAM_LABEL_SPACING: float = 8.0
const EVENT_LABEL_OFFSET: Vector2 = Vector2(-42.0, -70.0)
const EVENT_DURATION_SECONDS: float = 1.2
const REMOTE_POSITION_LERP_WEIGHT: float = 0.75
const WORLD_EVENT_LABEL_ALLOWLIST: PackedStringArray = [
	"FEUERSTOPP GEBROCHEN!",
	"EIGENBESCHUSS!",
	"SEC 360",
	"TOUCHDOWN",
	"AB",
	"DOWN",
	"BLEEDOUT",
]

signal runtime_status_changed(runtime_status)
signal unit_command_assigned(command)
signal damage_applied(amount, health_points, hit_context)
signal healed_applied(amount, health_points, heal_context)
signal vital_status_changed(vital_status)
signal identity_changed()

@export var unit_id: String = "unit_test_001":
	set(value):
		if unit_id == value:
			return
		unit_id = value
		identity_changed.emit()
@export var display_name: String = "Test Unit"
@export var portrait_path: String = ""
@export var callsign: String = ""
@export var role_id: String = "security_guard"
@export var role_name: String = "Operator"
@export var homeworld: String = ""
@export var age_years: int = 0
@export_multiline var short_description: String = ""
@export_multiline var biography_text: String = ""
@export_multiline var loadout_summary: String = ""
@export var armor_id: String = "medium"
@export var weapon_1_id: String = "rifle"
@export var weapon_2_id: String = "rifle"
@export var team_id: String = "team_test":
	set(value):
		if team_id == value:
			return
		team_id = value
		identity_changed.emit()
@export var fireteam_id: String = "":
	set(value):
		var normalized_id: String = _normalize_fireteam_id(value)
		if fireteam_id == normalized_id:
			return
		fireteam_id = normalized_id
		identity_changed.emit()
@export var max_health_points: int = 100
@export_range(0.0, 1.0, 0.01) var skill_accuracy: float = 0.5
@export_range(0.0, 1.0, 0.01) var skill_speed: float = 0.5
@export_range(0.0, 1.0, 0.01) var skill_leadership: float = 0.3
@export_range(0.0, 1.0, 0.01) var skill_toughness: float = 0.5
@export_range(0.0, 1.0, 0.01) var awareness: float = 0.5
@export_range(0.0, 1.0, 0.01) var recognition: float = 0.5
@export_range(0.0, 1.0, 0.01) var stealth: float = 0.5
@export_range(0.0, 1.0, 0.01) var discipline: float = 0.5
@export_range(0.0, 1.0, 0.01) var speech_quality: float = 0.5
@export_range(0.0, 1.0, 0.01) var speech_quantity: float = 0.4
@export_range(-1.0, 1.0, 0.01) var ground_vehicle_handling: float = -1.0
@export_range(-1.0, 1.0, 0.01) var dropship_piloting: float = -1.0
@export_range(-1.0, 1.0, 0.01) var freighter_piloting: float = -1.0
@export_range(-1.0, 1.0, 0.01) var fighter_piloting: float = -1.0
@export var trait_ids: PackedStringArray = []
@export var is_fireteam_lead: bool = false
@export var show_world_debug_labels: bool = false
@export var show_world_event_labels: bool = true

var _runtime_status: RefCounted = UNIT_RUNTIME_STATUS_SCRIPT.new()
var _current_unit_command: RefCounted = null
var _vital_status: RefCounted = UNIT_VITAL_STATUS_SCRIPT.new()
var _leadership_bonus: float = 0.0
var _loadout_modifiers: Dictionary = {}
var _skills: RefCounted = UNIT_SKILLS_SCRIPT.new()
var _traits: Array = []
var _character_profile_bundle: Dictionary = {}
var _last_damage_context: Dictionary = {}
var _status_label: Label = null
var _fireteam_label: Label = null
var _phase_label: Label = null
var _tactical_stance_label: Label = null
var _event_label: Label = null
var _current_event_text: String = ""
var _current_event_color: Color = Color(1.0, 0.95, 0.5, 1.0)
var _event_time_remaining: float = 0.0
var _contact_active: bool = false
var _contact_target_id: String = ""
var _is_tactical_selected: bool = false
var _selection_ring: Line2D = null
var _world_selection_ring_visible: bool = true
var _weapon_visual: Sprite2D = null
var _weapon_visual_direction: String = DEFAULT_WEAPON_VISUAL_DIRECTION
var _respawn_manager = null
var _terrain_registry = null
var _tactical_stance_id: String = "normal"
var _tactical_stance_revision: int = 0


func _ready() -> void:
	fireteam_id = _normalize_fireteam_id(fireteam_id)
	if not child_entered_tree.is_connected(_on_child_entered_tree):
		child_entered_tree.connect(_on_child_entered_tree)
	_rebuild_identity_data()
	_ensure_readability_labels()
	_runtime_status = _build_runtime_status("idle")
	_vital_status = _build_vital_status("fit", max_health_points, 0)
	_apply_vital_visual()
	_refresh_weapon_visual()
	_refresh_readability()


func _process(delta: float) -> void:
	_sync_readability_positions()
	if _event_time_remaining > 0.0:
		_event_time_remaining = maxf(_event_time_remaining - delta, 0.0)
		if _event_time_remaining == 0.0:
			_current_event_text = ""
			_refresh_event_label()


func get_unit_id() -> String:
	return unit_id


func get_runtime_status():
	return _runtime_status


func get_current_unit_command():
	return _current_unit_command


func get_health() -> int:
	return int(_vital_status.health_points)


func get_max_health_points() -> int:
	return max_health_points


func get_team_id() -> String:
	return team_id


func get_display_name() -> String:
	return display_name


func get_portrait_path() -> String:
	return portrait_path


func get_callsign() -> String:
	return callsign


func get_role_id() -> String:
	return role_id


func get_role_name() -> String:
	return role_name


func get_specialty_text() -> String:
	return String(_character_profile_bundle.get("primary_specialty", "")).strip_edges()


func get_homeworld() -> String:
	return homeworld


func get_short_description() -> String:
	return short_description


func get_biography_text() -> String:
	return biography_text


func get_loadout_summary() -> String:
	return loadout_summary


func get_armor_id() -> String:
	return armor_id


func get_weapon_1_id() -> String:
	return weapon_1_id


func get_weapon_2_id() -> String:
	return weapon_2_id


func get_active_weapon_id() -> String:
	return _resolve_active_combat_weapon_id()


func has_loadout_item(item_id: String) -> bool:
	var normalized_item_id: String = WEAPON_DATA_SCRIPT.normalize_weapon_id(item_id)
	if normalized_item_id.is_empty():
		return false
	return WEAPON_DATA_SCRIPT.normalize_weapon_id(weapon_1_id) == normalized_item_id or WEAPON_DATA_SCRIPT.normalize_weapon_id(weapon_2_id) == normalized_item_id


func has_medic_tool() -> bool:
	return has_loadout_item("medictool")


func has_attack_weapon() -> bool:
	return not _resolve_active_combat_weapon_id().is_empty()


func get_weapon_visual() -> Sprite2D:
	return _weapon_visual


func get_weapon_visual_direction() -> String:
	return _weapon_visual_direction


func get_tactical_stance_indicator_id() -> String:
	return _tactical_stance_id


func get_tactical_stance_indicator_revision() -> int:
	return _tactical_stance_revision


func get_tactical_stance_badge_text() -> String:
	return _build_tactical_stance_label_text()


func get_tactical_stance_badge_snapshot() -> Dictionary:
	return {
		"tactical_stance": _tactical_stance_id,
		"tactical_stance_revision": _tactical_stance_revision,
	}


func get_weapon_visual_texture_path() -> String:
	if _weapon_visual == null or _weapon_visual.texture == null:
		return ""

	return String(_weapon_visual.texture.resource_path).strip_edges()


func get_fireteam_id() -> String:
	return fireteam_id


func get_vital_status():
	return _vital_status


func get_vital_state() -> String:
	return String(_vital_status.state)


func get_fire_status() -> String:
	return String(_runtime_status.fire_status)


func get_phase() -> int:
	return int(_runtime_status.phase)


func get_source_command_type() -> String:
	return String(_runtime_status.source_command_type)


func get_move_speed_factor() -> float:
	return float(_runtime_status.move_speed_factor)


func get_sight_range_factor() -> float:
	return float(_runtime_status.sight_range_factor)


func get_movement_posture() -> String:
	return String(_runtime_status.movement_posture)


func get_weapon_posture() -> String:
	return String(_runtime_status.weapon_posture)


func get_posture_policy_id() -> String:
	return String(_runtime_status.posture_policy_id)


func get_cover_score() -> float:
	return float(_runtime_status.cover_score)


func get_attack_bonus() -> float:
	return float(_runtime_status.attack_bonus)


func get_last_damage_context() -> Dictionary:
	return _last_damage_context.duplicate(true)


func get_skills():
	return _skills


func get_accuracy_skill() -> float:
	return float(_skills.accuracy)


func get_speed_skill() -> float:
	return float(_skills.speed)


func get_leadership_skill() -> float:
	return float(_skills.leadership)


func get_awareness() -> float:
	return awareness


func get_stealth() -> float:
	return stealth


func get_discipline() -> float:
	return discipline


func get_recognition() -> float:
	return recognition


func get_toughness_skill() -> float:
	return float(_skills.toughness)


func get_effective_cover_score() -> int:
	var loadout_cover_bonus: float = float(_loadout_modifiers.get("cover_mod", 0.0)) * 100.0
	return int(roundi(clampf(get_cover_score() + _get_terrain_cover_bonus() + loadout_cover_bonus, 0.0, 80.0)))


func get_height_level() -> int:
	if _terrain_registry == null or not _terrain_registry.has_method("get_height_at_world"):
		return 0

	return int(_terrain_registry.call("get_height_at_world", global_position))


func get_surface_type() -> String:
	if _terrain_registry == null or not _terrain_registry.has_method("get_surface_type_at_world"):
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_SURFACE_TYPE

	return String(_terrain_registry.call("get_surface_type_at_world", global_position))


func get_surface_speed_factor() -> float:
	if _terrain_registry == null or not _terrain_registry.has_method("get_surface_speed_factor_at_world"):
		return 1.0

	return float(_terrain_registry.call("get_surface_speed_factor_at_world", global_position))


func get_traits() -> Array:
	return _traits.duplicate()


func get_trait_ids() -> PackedStringArray:
	return trait_ids.duplicate()


func get_trait_tags() -> PackedStringArray:
	var tags: PackedStringArray = []
	for unit_trait in _traits:
		if unit_trait == null:
			continue

		tags.append("[%s]" % String(unit_trait.short_tag))

	return tags


func get_skill_summary_text() -> String:
	return "A:%.1f S:%.1f L:%.1f T:%.1f" % [
		get_accuracy_skill(),
		get_speed_skill(),
		get_leadership_skill(),
		get_toughness_skill(),
	]


func get_trait_summary_text() -> String:
	return " ".join(get_trait_tags())


func get_character_profile_bundle() -> Dictionary:
	return _character_profile_bundle.duplicate(true)


func get_combat_effects() -> Dictionary:
	var effects: Dictionary = Dictionary(_character_profile_bundle.get("combat_effects", {}))
	var result:Dictionary=effects.duplicate(true) if not effects.is_empty() else {"hit_chance_multiplier":1.0,"speed_multiplier":1.0,"hit_modifier":0.0,"evasion_modifier":0.0,"damage_taken_multiplier":1.0}
	if not result.has("moving_shot_accuracy_multiplier"):
		var core:Dictionary=Dictionary(_character_profile_bundle.get("core_values",{}))
		var accuracy:float=float(core.accuracy) if core.has("accuracy") else get_accuracy_skill()
		result["moving_shot_accuracy_multiplier"]=UNIT_PROFILE_MATH_SCRIPT.accuracy_to_moving_shot_multiplier(accuracy)
	result["hit_modifier"] = float(result.get("hit_modifier", 0.0)) + _leadership_bonus
	return _apply_loadout_modifiers_to_effects(result)


## Opt into the canonical per-effect bulk read; all combat wrappers above/below
## derive from these same effective profile/loadout/leadership values.
func get_damage_profile_snapshot() -> Dictionary:
	return get_combat_effects()


func apply_leadership_bonus(bonus: float) -> void:
	_leadership_bonus = maxf(bonus, 0.0)


func clear_leadership_bonus() -> void:
	_leadership_bonus = 0.0


func get_leadership_bonus() -> float:
	return _leadership_bonus


func get_leadership_hit_modifier() -> float:
	return _leadership_bonus


func apply_loadout_modifiers(modifiers: Dictionary) -> void:
	_loadout_modifiers = Dictionary(modifiers).duplicate(true)


func clear_loadout_modifiers() -> void:
	_loadout_modifiers.clear()


func get_loadout_modifiers_snapshot() -> Dictionary:
	return _loadout_modifiers.duplicate(true)


func get_combat_hit_chance_multiplier() -> float:
	return float(get_combat_effects().get("hit_chance_multiplier", 1.0))


func get_combat_speed_multiplier() -> float:
	return float(get_combat_effects().get("speed_multiplier", 1.0))


func get_combat_hit_modifier() -> float:
	return float(get_combat_effects().get("hit_modifier", 0.0))


func get_combat_evasion_modifier() -> float:
	return float(get_combat_effects().get("evasion_modifier", 0.0))


func get_combat_damage_taken_multiplier() -> float:
	return float(get_combat_effects().get("damage_taken_multiplier", 1.0))


func get_initiative_speed_multiplier() -> float:
	return get_combat_speed_multiplier()


func get_order_fidelity_hit_modifier() -> float:
	return UNIT_PROFILE_MATH_SCRIPT.order_fidelity_to_hit_modifier(_get_behavior_axis("order_fidelity"))


func get_autonomy_hit_modifier() -> float:
	return UNIT_PROFILE_MATH_SCRIPT.autonomy_to_hit_modifier(_get_behavior_axis("autonomy"))


func get_signature_control_evasion_modifier() -> float:
	return UNIT_PROFILE_MATH_SCRIPT.signature_control_to_evasion_modifier(_get_behavior_axis("signature_control"))


func get_contact_stability_damage_taken_multiplier() -> float:
	return UNIT_PROFILE_MATH_SCRIPT.contact_stability_to_damage_taken_multiplier(_get_behavior_axis("contact_stability"))


func _apply_loadout_modifiers_to_effects(effects: Dictionary) -> Dictionary:
	var next_effects: Dictionary = effects.duplicate(true)
	if _loadout_modifiers.is_empty():
		return next_effects
	var speed_mod: float = float(_loadout_modifiers.get("speed_mod", 0.0))
	var accuracy_mod: float = float(_loadout_modifiers.get("accuracy_mod", 0.0))
	var toughness_mod: float = float(_loadout_modifiers.get("toughness_mod", 0.0))
	next_effects["hit_modifier"] = maxf(float(next_effects.get("hit_modifier", 0.0)), 0.0) + accuracy_mod
	next_effects["speed_multiplier"] = maxf(float(next_effects.get("speed_multiplier", 1.0)) + speed_mod, 0.1)
	var base_damage_taken_multiplier: float = float(next_effects.get("damage_taken_multiplier", 1.0))
	next_effects["damage_taken_multiplier"] = maxf(base_damage_taken_multiplier * (1.0 - toughness_mod), 0.2)
	return next_effects


func get_target_position():
	return _runtime_status.target_position


func apply_identity_config(identity_config: Dictionary) -> void:
	var should_rebuild_identity_data: bool = _character_profile_bundle.is_empty()
	var should_refresh_visuals: bool = false
	var profile_keys := {
		"role_id": true,
		"role_name": true,
		"skill_accuracy": true,
		"skill_speed": true,
		"skill_leadership": true,
		"skill_toughness": true,
		"awareness": true,
		"recognition": true,
		"stealth": true,
		"discipline": true,
		"speech_quality": true,
		"speech_quantity": true,
		"ground_vehicle_handling": true,
		"dropship_piloting": true,
		"freighter_piloting": true,
		"fighter_piloting": true,
		"trait_ids": true,
	}
	var visual_keys := {
		"display_name": true,
		"callsign": true,
		"fireteam_id": true,
		"is_fireteam_lead": true,
		"armor": true,
		"armor_id": true,
		"weapon_1": true,
		"weapon_1_id": true,
		"weapon_2": true,
		"weapon_2_id": true,
	}
	for identity_key_variant in identity_config.keys():
		var identity_key: String = String(identity_key_variant)
		if profile_keys.has(identity_key):
			should_rebuild_identity_data = true
		if visual_keys.has(identity_key):
			should_refresh_visuals = true

	if identity_config.has("unit_id"):
		unit_id = String(identity_config["unit_id"]).strip_edges()

	if identity_config.has("display_name"):
		display_name = String(identity_config["display_name"])

	if identity_config.has("portrait_path"):
		portrait_path = String(identity_config["portrait_path"]).strip_edges()

	if identity_config.has("callsign"):
		callsign = String(identity_config["callsign"]).strip_edges()

	if identity_config.has("role_id"):
		role_id = UNIT_PROFILE_MATH_SCRIPT.normalize_role_id(String(identity_config["role_id"]))
	elif identity_config.has("role_name"):
		role_id = UNIT_PROFILE_MATH_SCRIPT.normalize_role_id(String(identity_config["role_name"]))

	if identity_config.has("role_name"):
		role_name = String(identity_config["role_name"]).strip_edges()

	if identity_config.has("homeworld"):
		homeworld = String(identity_config["homeworld"]).strip_edges()

	if identity_config.has("age_years"):
		age_years = int(identity_config["age_years"])

	if identity_config.has("short_description"):
		short_description = String(identity_config["short_description"]).strip_edges()

	if identity_config.has("biography_text"):
		biography_text = String(identity_config["biography_text"]).strip_edges()

	if identity_config.has("loadout_summary"):
		loadout_summary = String(identity_config["loadout_summary"]).strip_edges()

	if identity_config.has("armor") or identity_config.has("armor_id"):
		armor_id = String(identity_config.get("armor_id", identity_config.get("armor", "medium"))).strip_edges().to_lower()

	if identity_config.has("weapon_1") or identity_config.has("weapon_1_id"):
		weapon_1_id = WEAPON_DATA_SCRIPT.sanitize_weapon_id(String(identity_config.get("weapon_1_id", identity_config.get("weapon_1", WEAPON_DATA_SCRIPT.DEFAULT_WEAPON_ID))))

	if identity_config.has("weapon_2") or identity_config.has("weapon_2_id"):
		weapon_2_id = WEAPON_DATA_SCRIPT.sanitize_weapon_id(String(identity_config.get("weapon_2_id", identity_config.get("weapon_2", WEAPON_DATA_SCRIPT.DEFAULT_WEAPON_ID))))

	if identity_config.has("team_id"):
		team_id = String(identity_config["team_id"]).strip_edges()

	if identity_config.has("fireteam_id"):
		fireteam_id = _normalize_fireteam_id(String(identity_config["fireteam_id"]))

	if identity_config.has("is_fireteam_lead"):
		is_fireteam_lead = bool(identity_config["is_fireteam_lead"])

	if identity_config.has("skill_accuracy"):
		skill_accuracy = clampf(float(identity_config["skill_accuracy"]), 0.0, 1.0)

	if identity_config.has("skill_speed"):
		skill_speed = clampf(float(identity_config["skill_speed"]), 0.0, 1.0)

	if identity_config.has("skill_leadership"):
		skill_leadership = clampf(float(identity_config["skill_leadership"]), 0.0, 1.0)

	if identity_config.has("skill_toughness"):
		skill_toughness = clampf(float(identity_config["skill_toughness"]), 0.0, 1.0)

	if identity_config.has("awareness"):
		awareness = clampf(float(identity_config["awareness"]), 0.0, 1.0)

	if identity_config.has("recognition"):
		recognition = clampf(float(identity_config["recognition"]), 0.0, 1.0)

	if identity_config.has("stealth"):
		stealth = clampf(float(identity_config["stealth"]), 0.0, 1.0)

	if identity_config.has("discipline"):
		discipline = clampf(float(identity_config["discipline"]), 0.0, 1.0)

	if identity_config.has("speech_quality"):
		speech_quality = clampf(float(identity_config["speech_quality"]), 0.0, 1.0)

	if identity_config.has("speech_quantity"):
		speech_quantity = clampf(float(identity_config["speech_quantity"]), 0.0, 1.0)

	if identity_config.has("ground_vehicle_handling"):
		ground_vehicle_handling = clampf(float(identity_config["ground_vehicle_handling"]), -1.0, 1.0)

	if identity_config.has("dropship_piloting"):
		dropship_piloting = clampf(float(identity_config["dropship_piloting"]), -1.0, 1.0)

	if identity_config.has("freighter_piloting"):
		freighter_piloting = clampf(float(identity_config["freighter_piloting"]), -1.0, 1.0)

	if identity_config.has("fighter_piloting"):
		fighter_piloting = clampf(float(identity_config["fighter_piloting"]), -1.0, 1.0)

	if identity_config.has("trait_ids"):
		trait_ids = _coerce_trait_ids(identity_config["trait_ids"])

	if should_rebuild_identity_data:
		_rebuild_identity_data()
	if should_refresh_visuals:
		_refresh_weapon_visual()
	_refresh_readability()


func set_fireteam_id(next_fireteam_id: String) -> bool:
	fireteam_id = _normalize_fireteam_id(next_fireteam_id)

	if _runtime_status == null:
		_refresh_readability()
		return true

	var runtime_status = _build_runtime_status(
		String(_runtime_status.status),
		String(_runtime_status.active_command_type),
		int(_runtime_status.priority),
		String(_runtime_status.fire_status),
		String(_runtime_status.source_command_type),
		float(_runtime_status.move_speed_factor),
		float(_runtime_status.cover_score),
		float(_runtime_status.attack_bonus),
		int(_runtime_status.phase),
		_runtime_status.target_position,
		String(_runtime_status.movement_posture),
		String(_runtime_status.weapon_posture),
		String(_runtime_status.posture_policy_id),
		float(_runtime_status.sight_range_factor),
		float(_runtime_status.aim_readiness_percent)
	)
	if not bool(runtime_status.call("is_valid")):
		return false

	_runtime_status = runtime_status
	runtime_status_changed.emit(_runtime_status)
	_refresh_readability()
	return true


func set_respawn_manager(respawn_manager) -> void:
	_respawn_manager = respawn_manager
	_refresh_readability()


func set_terrain_registry(terrain_registry) -> void:
	_terrain_registry = terrain_registry
	_refresh_readability()


func set_tactical_stance_indicator(next_stance_id: String, revision: int = -1) -> void:
	var normalized_stance_id: String = _normalize_tactical_stance_id(next_stance_id)
	var next_revision: int = _tactical_stance_revision
	if revision >= 0:
		if revision < _tactical_stance_revision:
			return
		next_revision = revision
	elif normalized_stance_id != _tactical_stance_id:
		next_revision += 1
	if normalized_stance_id == _tactical_stance_id and next_revision == _tactical_stance_revision:
		return
	_tactical_stance_id = normalized_stance_id
	_tactical_stance_revision = next_revision
	_refresh_readability()


func _on_child_entered_tree(node: Node) -> void:
	if node != null and String(node.name) == VISUAL_SPRITE_NAME:
		_refresh_weapon_visual()


func apply_remote_snapshot(snapshot: Dictionary, interpolation_alpha: float = REMOTE_POSITION_LERP_WEIGHT) -> void:
	if typeof(snapshot) != TYPE_DICTIONARY:
		return

	if self is CanvasItem and snapshot.has("visible"):
		visible = bool(snapshot["visible"])

	if snapshot.has("position"):
		var remote_position: Vector2 = snapshot["position"] if snapshot["position"] is Vector2 else global_position
		global_position = global_position.lerp(remote_position, clampf(interpolation_alpha, 0.0, 1.0))

	if snapshot.has("fireteam_id"):
		fireteam_id = _normalize_fireteam_id(String(snapshot["fireteam_id"]))

	_apply_remote_runtime_status(_build_remote_runtime_dict(snapshot))
	_apply_remote_vital_status(_build_remote_vital_dict(snapshot))
	if snapshot.has("tactical_stance") or snapshot.has("tactical_stance_revision"):
		var stance_revision: int = -1
		if snapshot.has("tactical_stance_revision"):
			stance_revision = maxi(int(snapshot.get("tactical_stance_revision", _tactical_stance_revision)), 0)
		set_tactical_stance_indicator(String(snapshot.get("tactical_stance", _tactical_stance_id)), stance_revision)

	_refresh_readability()


func apply_remote_vital_update(vital_update: Dictionary) -> void:
	if typeof(vital_update) != TYPE_DICTIONARY:
		return

	_apply_remote_vital_status(_build_remote_vital_dict(vital_update))
	_refresh_readability()


func refresh_terrain_readability() -> void:
	_refresh_readability()


func apply_damage(amount: int, hit_context: Dictionary = {}) -> bool:
	if amount <= 0:
		return false

	var next_health: int = maxi(get_health() - amount, 0)
	var next_state: String = String(_vital_status.state)
	if next_health == 0 and next_state == "fit":
		next_state = "down"

	_set_vital_status(next_state, next_health, int(_vital_status.bleedout_ticks))
	_last_damage_context = hit_context.duplicate(true)
	show_event_text("HIT -%d" % amount, Color(1.0, 0.8, 0.35, 1.0))
	damage_applied.emit(amount, next_health, _last_damage_context)
	return true


func apply_heal(amount: int, heal_context: Dictionary = {}) -> bool:
	if amount <= 0:
		return false

	var vital_state: String = String(_vital_status.state)
	if vital_state != "fit" and vital_state != "down":
		return false

	var current_health: int = get_health()
	if vital_state == "fit" and current_health >= max_health_points:
		return false

	var next_health: int = mini(current_health + amount, max_health_points)
	if next_health <= current_health:
		return false

	var next_state: String = vital_state
	var recovered_from_down: bool = vital_state == "down" and next_health > 0
	if recovered_from_down:
		next_state = "fit"
		_runtime_status = _build_runtime_status("idle")
		runtime_status_changed.emit(_runtime_status)
		_current_unit_command = null
		_last_damage_context = {}
		_contact_active = false
		_contact_target_id = ""

	_set_vital_status(next_state, next_health, 0 if recovered_from_down else int(_vital_status.bleedout_ticks))
	var restored_amount: int = maxi(next_health - current_health, 0)
	if restored_amount <= 0:
		return false

	var resolved_context: Dictionary = heal_context.duplicate(true)
	show_event_text("PATCH +%d" % restored_amount, Color(0.55, 1.0, 0.72, 1.0))
	healed_applied.emit(restored_amount, next_health, resolved_context)
	return true


func advance_bleedout() -> bool:
	if String(_vital_status.state) != "down":
		return false

	_set_vital_status("bleedout", get_health(), int(_vital_status.bleedout_ticks) + 1)
	show_event_text("BLEEDOUT", Color(0.95, 0.55, 0.55, 1.0))
	return true


func begin_respawn() -> bool:
	var vital_state: String = String(_vital_status.state)
	if vital_state != "down" and vital_state != "bleedout":
		return false

	_runtime_status = _build_runtime_status("idle")
	runtime_status_changed.emit(_runtime_status)
	_set_vital_status("respawning", get_health(), int(_vital_status.bleedout_ticks))
	_current_unit_command = null
	_contact_active = false
	_contact_target_id = ""
	_refresh_readability()
	show_event_text("RESPAWNING", Color(0.7, 0.9, 1.0, 1.0), 1.8)
	return true


func activate_for_wave(spawn_position: Vector2) -> void:
	position = spawn_position
	_current_unit_command = null
	_last_damage_context = {}
	_contact_active = false
	_contact_target_id = ""
	_current_event_text = ""
	_event_time_remaining = 0.0
	_runtime_status = _build_runtime_status("idle")
	runtime_status_changed.emit(_runtime_status)
	_set_vital_status("fit", max_health_points, 0)
	visible = true
	_refresh_event_label()
	_refresh_readability()


func deactivate_for_wave() -> void:
	_current_unit_command = null
	_last_damage_context = {}
	_contact_active = false
	_contact_target_id = ""
	_current_event_text = ""
	_event_time_remaining = 0.0
	_runtime_status = _build_runtime_status("idle")
	runtime_status_changed.emit(_runtime_status)
	_set_vital_status("fit", max_health_points, 0)
	visible = false
	_refresh_event_label()
	_refresh_readability()


func respawn(spawn_position: Vector2) -> bool:
	var vital_state: String = String(_vital_status.state)
	if vital_state != "down" and vital_state != "bleedout" and vital_state != "respawning":
		return false

	position = spawn_position
	_set_vital_status("fit", max_health_points, 0)
	_runtime_status = _build_runtime_status("idle")
	runtime_status_changed.emit(_runtime_status)
	_current_unit_command = null
	_last_damage_context = {}
	_contact_active = false
	_contact_target_id = ""
	_refresh_readability()
	show_event_text("RESPAWN", Color(0.5, 1.0, 0.7, 1.0), 2.0)
	return true


func set_target_position(target_position: Variant) -> bool:
	return set_runtime_status(
		String(_runtime_status.status),
		String(_runtime_status.active_command_type),
		int(_runtime_status.priority),
		String(_runtime_status.fire_status),
		String(_runtime_status.source_command_type),
		float(_runtime_status.move_speed_factor),
		float(_runtime_status.cover_score),
		float(_runtime_status.attack_bonus),
		int(_runtime_status.phase),
		target_position,
		String(_runtime_status.movement_posture),
		String(_runtime_status.weapon_posture),
		String(_runtime_status.posture_policy_id),
		float(_runtime_status.sight_range_factor)
	)


func assign_unit_command(command) -> bool:
	if command == null or not command.has_method("is_valid") or not bool(command.call("is_valid")):
		push_warning("TestUnit.assign_unit_command expects a valid UnitCommand-like object.")
		return false

	_current_unit_command = command
	var source_task_type: String = String(command.get("source_task_type")).strip_edges().to_lower()
	if source_task_type == "post_drop_360_security":
		set_meta("post_drop_security_active", true)
	else:
		remove_meta("post_drop_security_active")

	var status_name: String = _map_unit_command_to_status(String(command.get("command_type")))
	if not set_runtime_status(
		status_name,
		String(command.get("command_type")),
		int(command.get("priority")),
		String(command.get("fire_status")),
		String(command.get("source_command_type")),
		float(command.get("move_speed_factor")),
		float(command.get("cover_score")),
		float(command.get("attack_bonus")),
		int(command.get("phase")),
		command.get("target_position"),
		String(command.get("movement_posture")),
		String(command.get("weapon_posture")),
		String(command.get("posture_policy_id")),
		float(command.get("sight_range_factor")),
		float(command.get("aim_readiness_percent"))
	):
		return false

	unit_command_assigned.emit(command)
	_refresh_readability()
	return true


func set_runtime_status(
	status_name: String,
	active_command_type: String = "",
	priority: int = 0,
	fire_status: String = "fire_at_will",
	source_command_type: String = "",
	move_speed_factor: float = 1.0,
	cover_score: float = 0.0,
	attack_bonus: float = 0.0,
	phase: int = -1,
	target_position: Variant = null,
	movement_posture: String = "",
	weapon_posture: String = "",
	posture_policy_id: String = "",
	sight_range_factor: float = 1.0,
	aim_readiness_percent: float = 0.0
) -> bool:
	var runtime_status = _build_runtime_status(
		status_name,
		active_command_type,
		priority,
		fire_status,
		source_command_type,
		move_speed_factor,
		cover_score,
		attack_bonus,
		phase,
		target_position,
		movement_posture,
		weapon_posture,
		posture_policy_id,
		sight_range_factor,
		aim_readiness_percent
	)
	if not bool(runtime_status.call("is_valid")):
		push_warning("TestUnit.set_runtime_status expects a valid UnitRuntimeStatus-compatible value.")
		return false

	_runtime_status = runtime_status
	runtime_status_changed.emit(_runtime_status)
	_refresh_readability()
	return true


func set_contact_state(is_active: bool, target_unit_id: String = "") -> void:
	_contact_active = is_active
	_contact_target_id = target_unit_id
	_refresh_status_label()


func is_in_contact() -> bool:
	return _contact_active


func get_contact_target_id() -> String:
	return _contact_target_id


func is_tactical_selected() -> bool:
	return _is_tactical_selected


func set_tactical_selected(is_selected: bool) -> void:
	_is_tactical_selected = is_selected
	_refresh_selection_ring()


func set_world_selection_ring_visible(visible: bool) -> void:
	_world_selection_ring_visible = visible
	_refresh_selection_ring()


func show_event_text(event_text: String, event_color: Color = Color(1.0, 0.95, 0.5, 1.0), duration_seconds: float = EVENT_DURATION_SECONDS) -> void:
	var normalized_event_text: String = event_text.strip_edges()
	if not _should_show_world_event_text(normalized_event_text):
		return
	_current_event_text = event_text
	_current_event_color = event_color
	_event_time_remaining = duration_seconds
	_refresh_event_label()


func set_world_debug_labels_visible(visible: bool) -> void:
	show_world_debug_labels = visible
	_sync_readability_positions()


func _should_show_world_event_text(event_text: String) -> bool:
	if event_text.is_empty():
		return false
	return WORLD_EVENT_LABEL_ALLOWLIST.has(event_text.to_upper())


func _build_runtime_status(
	status_name: String,
	active_command_type: String = "",
	priority: int = 0,
	fire_status: String = "fire_at_will",
	source_command_type: String = "",
	move_speed_factor: float = 1.0,
	cover_score: float = 0.0,
	attack_bonus: float = 0.0,
	phase: int = -1,
	target_position: Variant = null,
	movement_posture: String = "",
	weapon_posture: String = "",
	posture_policy_id: String = "",
	sight_range_factor: float = 1.0,
	aim_readiness_percent: float = 0.0
):
	var runtime_status = UNIT_RUNTIME_STATUS_SCRIPT.new()
	runtime_status.status = status_name
	runtime_status.active_command_type = active_command_type
	runtime_status.priority = priority
	runtime_status.unit_id = unit_id
	runtime_status.team_id = team_id
	runtime_status.fireteam_id = fireteam_id
	runtime_status.fire_status = fire_status
	runtime_status.source_command_type = source_command_type
	runtime_status.move_speed_factor = move_speed_factor
	runtime_status.sight_range_factor = maxf(sight_range_factor, 0.0)
	runtime_status.cover_score = cover_score
	runtime_status.attack_bonus = attack_bonus
	runtime_status.target_position = target_position
	runtime_status.phase = phase
	var posture_defaults: Dictionary = _get_default_runtime_postures(status_name)
	runtime_status.movement_posture = UNIT_RUNTIME_STATUS_SCRIPT.call("normalize_movement_posture", movement_posture, String(posture_defaults.get("movement_posture", UNIT_RUNTIME_STATUS_SCRIPT.MOVEMENT_POSTURE_IDLE)))
	runtime_status.weapon_posture = UNIT_RUNTIME_STATUS_SCRIPT.call("normalize_weapon_posture", weapon_posture, String(posture_defaults.get("weapon_posture", UNIT_RUNTIME_STATUS_SCRIPT.WEAPON_POSTURE_LOWERED)))
	runtime_status.posture_policy_id = posture_policy_id.strip_edges().to_lower()
	runtime_status.aim_readiness_percent = clampf(aim_readiness_percent, 0.0, 100.0)
	return runtime_status


func _get_default_runtime_postures(status_name: String) -> Dictionary:
	match status_name.strip_edges().to_lower():
		"pending_move":
			return {
				"movement_posture": UNIT_RUNTIME_STATUS_SCRIPT.MOVEMENT_POSTURE_TRAVEL,
				"weapon_posture": UNIT_RUNTIME_STATUS_SCRIPT.WEAPON_POSTURE_LOWERED,
			}
		"engaging":
			return {
				"movement_posture": UNIT_RUNTIME_STATUS_SCRIPT.MOVEMENT_POSTURE_ENGAGE,
				"weapon_posture": UNIT_RUNTIME_STATUS_SCRIPT.WEAPON_POSTURE_AIMED,
			}
		"holding":
			return {
				"movement_posture": UNIT_RUNTIME_STATUS_SCRIPT.MOVEMENT_POSTURE_OVERWATCH,
				"weapon_posture": UNIT_RUNTIME_STATUS_SCRIPT.WEAPON_POSTURE_READY,
			}
		"assigned":
			return {
				"movement_posture": UNIT_RUNTIME_STATUS_SCRIPT.MOVEMENT_POSTURE_TACTICAL,
				"weapon_posture": UNIT_RUNTIME_STATUS_SCRIPT.WEAPON_POSTURE_READY,
			}
		_:
			return {
				"movement_posture": UNIT_RUNTIME_STATUS_SCRIPT.MOVEMENT_POSTURE_IDLE,
				"weapon_posture": UNIT_RUNTIME_STATUS_SCRIPT.WEAPON_POSTURE_LOWERED,
			}


func _build_vital_status(state: String, health_points: int, bleedout_ticks: int):
	var vital_status = UNIT_VITAL_STATUS_SCRIPT.new()
	vital_status.state = state
	vital_status.health_points = health_points
	vital_status.bleedout_ticks = bleedout_ticks
	return vital_status


func _set_vital_status(state: String, health_points: int, bleedout_ticks: int) -> void:
	var vital_status = _build_vital_status(state, health_points, bleedout_ticks)
	if not bool(vital_status.call("is_valid")):
		return

	_vital_status = vital_status
	_apply_vital_visual()
	vital_status_changed.emit(_vital_status)
	_refresh_readability()


func _apply_remote_runtime_status(runtime_dict: Dictionary) -> void:
	if runtime_dict.is_empty():
		return

	var merged_runtime_dict: Dictionary = runtime_dict.duplicate(true)
	if not merged_runtime_dict.has("unit_id"):
		merged_runtime_dict["unit_id"] = unit_id
	if not merged_runtime_dict.has("team_id"):
		merged_runtime_dict["team_id"] = team_id
	if not merged_runtime_dict.has("fireteam_id") and not fireteam_id.is_empty():
		merged_runtime_dict["fireteam_id"] = fireteam_id

	var runtime_status = UNIT_RUNTIME_STATUS_SCRIPT.call("from_dict", merged_runtime_dict)
	if runtime_status == null or not runtime_status.has_method("is_valid") or not bool(runtime_status.call("is_valid")):
		return

	_runtime_status = runtime_status
	runtime_status_changed.emit(_runtime_status)


func _apply_remote_vital_status(vital_dict: Dictionary) -> void:
	if vital_dict.is_empty():
		return

	var previous_state: String = String(_vital_status.state)
	var vital_status = UNIT_VITAL_STATUS_SCRIPT.call("from_dict", vital_dict)
	if vital_status == null or not vital_status.has_method("is_valid") or not bool(vital_status.call("is_valid")):
		return

	_vital_status = vital_status
	_apply_vital_visual()
	vital_status_changed.emit(_vital_status)
	if previous_state == "respawning" and String(_vital_status.state) == "fit":
		show_event_text("RESPAWN", Color(0.5, 1.0, 0.7, 1.0), 2.0)


func _build_remote_runtime_dict(snapshot: Dictionary) -> Dictionary:
	var runtime_variant: Variant = snapshot.get("runtime_status", {})
	if typeof(runtime_variant) == TYPE_DICTIONARY and not Dictionary(runtime_variant).is_empty():
		return (runtime_variant as Dictionary).duplicate(true)

	var runtime_dict: Dictionary = {
		"status": String(snapshot.get("runtime_state", _runtime_status.status)),
		"active_command_type": String(snapshot.get("active_command_type", _runtime_status.active_command_type)),
		"priority": int(snapshot.get("priority", _runtime_status.priority)),
		"unit_id": String(snapshot.get("unit_id", unit_id)),
		"team_id": String(snapshot.get("team_id", team_id)),
		"fireteam_id": String(snapshot.get("fireteam_id", fireteam_id)),
		"fire_status": String(snapshot.get("fire_mode", _runtime_status.fire_status)),
		"source_command_type": String(snapshot.get("source_command_type", _runtime_status.source_command_type)),
		"move_speed_factor": float(snapshot.get("move_speed_factor", _runtime_status.move_speed_factor)),
		"sight_range_factor": float(snapshot.get("sight_range_factor", _runtime_status.sight_range_factor)),
		"cover_score": float(snapshot.get("cover_score", _runtime_status.cover_score)),
		"attack_bonus": float(snapshot.get("attack_bonus", _runtime_status.attack_bonus)),
		"phase": int(snapshot.get("phase", _runtime_status.phase)),
		"movement_posture": String(snapshot.get("movement_posture", _runtime_status.movement_posture)),
		"weapon_posture": String(snapshot.get("weapon_posture", _runtime_status.weapon_posture)),
		"posture_policy_id": String(snapshot.get("posture_policy_id", _runtime_status.posture_policy_id)),
	}
	return runtime_dict


func _build_remote_vital_dict(snapshot: Dictionary) -> Dictionary:
	var vital_variant: Variant = snapshot.get("vital_status", {})
	if typeof(vital_variant) == TYPE_DICTIONARY and not Dictionary(vital_variant).is_empty():
		return (vital_variant as Dictionary).duplicate(true)

	return {
		"state": String(snapshot.get("vital_state", _vital_status.state)),
		"health_points": int(snapshot.get("health", _vital_status.health_points)),
		"bleedout_ticks": int(snapshot.get("bleedout_ticks", _vital_status.bleedout_ticks)),
	}


func _map_unit_command_to_status(command_type: String) -> String:
	match command_type:
		"move_to_position":
			return "pending_move"
		"engage_area":
			return "engaging"
		"hold_position":
			return "holding"
		_:
			return "assigned"


func _apply_vital_visual() -> void:
	match String(_vital_status.state):
		"down":
			modulate = Color(1.0, 0.55, 0.55, 0.85)
			rotation_degrees = 28.0
		"bleedout":
			modulate = Color(0.45, 0.45, 0.45, 0.7)
			rotation_degrees = 45.0
		"respawning":
			modulate = Color(0.7, 0.9, 1.0, 0.5)
			rotation_degrees = 45.0
		_:
			modulate = Color(1.0, 1.0, 1.0, 1.0)
			rotation_degrees = 0.0


func _refresh_weapon_visual() -> void:
	var visual_root := get_node_or_null(VISUAL_SPRITE_NAME) as Sprite2D
	if visual_root == null:
		_weapon_visual = null
		_weapon_visual_direction = DEFAULT_WEAPON_VISUAL_DIRECTION
		return

	var weapon_visual := _ensure_weapon_visual(visual_root)
	if weapon_visual == null:
		return

	_weapon_visual_direction = _resolve_weapon_visual_direction(visual_root)
	var weapon_id: String = _resolve_visual_weapon_id()
	if weapon_id.is_empty():
		weapon_visual.texture = null
		weapon_visual.visible = false
		return
	var asset_path: String = WEAPON_DATA_SCRIPT.get_asset_path(weapon_id, _weapon_visual_direction)
	if asset_path.is_empty():
		weapon_visual.texture = null
		weapon_visual.visible = false
		return
	var weapon_texture := load(asset_path) as Texture2D
	if weapon_texture == null:
		weapon_visual.texture = null
		weapon_visual.visible = false
		return

	weapon_visual.texture = weapon_texture
	weapon_visual.position = _get_weapon_visual_offset(_weapon_visual_direction)
	weapon_visual.scale = WEAPON_DATA_SCRIPT.get_sprite_scale(weapon_id)
	weapon_visual.modulate = WEAPON_DATA_SCRIPT.get_sprite_modulate(weapon_id)
	weapon_visual.visible = true


func _resolve_active_combat_weapon_id() -> String:
	var primary_weapon_id: String = WEAPON_DATA_SCRIPT.sanitize_weapon_id(weapon_1_id)
	if WEAPON_DATA_SCRIPT.is_attack_weapon_id(primary_weapon_id):
		return primary_weapon_id
	var secondary_weapon_id: String = WEAPON_DATA_SCRIPT.sanitize_weapon_id(weapon_2_id)
	if WEAPON_DATA_SCRIPT.is_attack_weapon_id(secondary_weapon_id):
		return secondary_weapon_id
	return ""


func _resolve_visual_weapon_id() -> String:
	var primary_weapon_id: String = WEAPON_DATA_SCRIPT.sanitize_weapon_id(weapon_1_id)
	if WEAPON_DATA_SCRIPT.is_valid_weapon_id(primary_weapon_id):
		return primary_weapon_id
	return _resolve_active_combat_weapon_id()


func _ensure_weapon_visual(visual_root: Sprite2D) -> Sprite2D:
	_weapon_visual = visual_root.get_node_or_null(WEAPON_VISUAL_NAME) as Sprite2D
	if _weapon_visual == null:
		_weapon_visual = Sprite2D.new()
		_weapon_visual.name = WEAPON_VISUAL_NAME
		_weapon_visual.z_index = 1
		visual_root.add_child(_weapon_visual)

	_weapon_visual.centered = true
	return _weapon_visual


func _resolve_weapon_visual_direction(visual_root: Sprite2D) -> String:
	if visual_root == null or visual_root.texture == null:
		return DEFAULT_WEAPON_VISUAL_DIRECTION

	var texture_path: String = String(visual_root.texture.resource_path).strip_edges()
	for direction_variant in ["NE", "NW", "SE", "SW"]:
		var direction: String = String(direction_variant)
		if texture_path.ends_with("_%s.png" % direction):
			return direction

	if texture_path.ends_with("_N.png"):
		return "NE"
	if texture_path.ends_with("_S.png"):
		return "SW"
	if texture_path.ends_with("_E.png"):
		return "SE"
	if texture_path.ends_with("_W.png"):
		return "NW"

	return DEFAULT_WEAPON_VISUAL_DIRECTION


func _get_weapon_visual_offset(direction: String) -> Vector2:
	if WEAPON_VISUAL_OFFSETS.has(direction):
		return Vector2(WEAPON_VISUAL_OFFSETS[direction])

	return Vector2(WEAPON_VISUAL_OFFSETS[DEFAULT_WEAPON_VISUAL_DIRECTION])


func _ensure_readability_labels() -> void:
	_status_label = get_node_or_null(STATUS_LABEL_NAME) as Label
	if _status_label == null:
		_status_label = Label.new()
		_status_label.name = STATUS_LABEL_NAME
		_status_label.top_level = true
		add_child(_status_label)

	_fireteam_label = get_node_or_null(FIRETEAM_LABEL_NAME) as Label
	if _fireteam_label == null:
		_fireteam_label = Label.new()
		_fireteam_label.name = FIRETEAM_LABEL_NAME
		_fireteam_label.top_level = true
		add_child(_fireteam_label)

	_phase_label = get_node_or_null(PHASE_LABEL_NAME) as Label
	if _phase_label == null:
		_phase_label = Label.new()
		_phase_label.name = PHASE_LABEL_NAME
		_phase_label.top_level = true
		add_child(_phase_label)

	_tactical_stance_label = get_node_or_null(TACTICAL_STANCE_LABEL_NAME) as Label
	if _tactical_stance_label == null:
		_tactical_stance_label = Label.new()
		_tactical_stance_label.name = TACTICAL_STANCE_LABEL_NAME
		_tactical_stance_label.top_level = true
		add_child(_tactical_stance_label)

	_event_label = get_node_or_null(EVENT_LABEL_NAME) as Label
	if _event_label == null:
		_event_label = Label.new()
		_event_label.name = EVENT_LABEL_NAME
		_event_label.top_level = true
		add_child(_event_label)

	_status_label.add_theme_font_size_override("font_size", 11)
	_fireteam_label.add_theme_font_size_override("font_size", 10)
	_phase_label.add_theme_font_size_override("font_size", 10)
	_tactical_stance_label.add_theme_font_size_override("font_size", 10)
	_event_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_constant_override("outline_size", 2)
	_fireteam_label.add_theme_constant_override("outline_size", 2)
	_phase_label.add_theme_constant_override("outline_size", 2)
	_tactical_stance_label.add_theme_constant_override("outline_size", 2)
	_event_label.add_theme_constant_override("outline_size", 2)
	_status_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_fireteam_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_phase_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_tactical_stance_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_event_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_ensure_selection_ring()
	_sync_readability_positions()


func _sync_readability_positions() -> void:
	var base_position: Vector2 = global_position + STATUS_LABEL_OFFSET
	if _status_label != null:
		_status_label.visible = show_world_debug_labels and is_visible_in_tree()
		_status_label.global_position = base_position
		var inline_offset_x: float = _status_label.get_combined_minimum_size().x + FIRETEAM_LABEL_SPACING
		if _fireteam_label != null:
			_fireteam_label.visible = show_world_debug_labels and is_visible_in_tree() and not fireteam_id.is_empty()
			_fireteam_label.global_position = _status_label.global_position + Vector2(inline_offset_x, 0.0)
			if _fireteam_label.visible:
				inline_offset_x += _fireteam_label.get_combined_minimum_size().x + FIRETEAM_LABEL_SPACING
		if _phase_label != null:
			_phase_label.visible = show_world_debug_labels and is_visible_in_tree() and not _build_phase_label_text().is_empty()
			_phase_label.global_position = _status_label.global_position + Vector2(inline_offset_x, 0.0)
			if _phase_label.visible:
				inline_offset_x += _phase_label.get_combined_minimum_size().x + FIRETEAM_LABEL_SPACING
		if _tactical_stance_label != null:
			_tactical_stance_label.visible = show_world_debug_labels and is_visible_in_tree() and not _build_tactical_stance_label_text().is_empty()
			_tactical_stance_label.global_position = _status_label.global_position + Vector2(inline_offset_x, 0.0)

	elif _fireteam_label != null:
		_fireteam_label.visible = show_world_debug_labels and is_visible_in_tree() and not fireteam_id.is_empty()
		_fireteam_label.global_position = base_position
		var fallback_offset_x: float = 0.0
		if _fireteam_label.visible:
			fallback_offset_x += _fireteam_label.get_combined_minimum_size().x + FIRETEAM_LABEL_SPACING
		if _phase_label != null:
			_phase_label.visible = show_world_debug_labels and is_visible_in_tree() and not _build_phase_label_text().is_empty()
			_phase_label.global_position = base_position + Vector2(fallback_offset_x, 0.0)
			if _phase_label.visible:
				fallback_offset_x += _phase_label.get_combined_minimum_size().x + FIRETEAM_LABEL_SPACING
		if _tactical_stance_label != null:
			_tactical_stance_label.visible = show_world_debug_labels and is_visible_in_tree() and not _build_tactical_stance_label_text().is_empty()
			_tactical_stance_label.global_position = base_position + Vector2(fallback_offset_x, 0.0)

	if _event_label != null:
		_event_label.visible = show_world_event_labels and is_visible_in_tree() and not _current_event_text.is_empty()
		_event_label.global_position = global_position + EVENT_LABEL_OFFSET


func _refresh_readability() -> void:
	_refresh_status_label()
	_refresh_fireteam_label()
	_refresh_phase_label()
	_refresh_tactical_stance_label()
	_refresh_event_label()
	_refresh_selection_ring()
	_sync_readability_positions()


func _refresh_status_label() -> void:
	if _status_label == null:
		return

	var lines: PackedStringArray = []
	lines.append(_build_unit_name_label())
	var primary_status_label: String = _build_primary_status_label()
	if not primary_status_label.is_empty():
		lines.append(primary_status_label)

	var secondary_status_label: String = _build_secondary_status_label()
	if not secondary_status_label.is_empty():
		lines.append(secondary_status_label)

	var terrain_status_label: String = _build_terrain_status_label()
	if not terrain_status_label.is_empty():
		lines.append(terrain_status_label)

	lines.append(get_skill_summary_text())
	var trait_summary_text: String = get_trait_summary_text()
	if not trait_summary_text.is_empty():
		lines.append(trait_summary_text)

	_status_label.text = "\n".join(lines)
	_status_label.modulate = _build_status_label_color()


func _refresh_fireteam_label() -> void:
	if _fireteam_label == null:
		return

	if fireteam_id.is_empty():
		_fireteam_label.text = ""
		_fireteam_label.visible = false
		return

	_fireteam_label.text = fireteam_id.to_upper()
	_fireteam_label.modulate = _build_fireteam_label_color()
	_fireteam_label.visible = show_world_debug_labels and is_visible_in_tree()


func _refresh_phase_label() -> void:
	if _phase_label == null:
		return

	var phase_text: String = _build_phase_label_text()
	_phase_label.text = phase_text
	_phase_label.modulate = Color(0.88, 0.98, 0.88, 1.0)
	_phase_label.visible = show_world_debug_labels and is_visible_in_tree() and not phase_text.is_empty()


func _refresh_tactical_stance_label() -> void:
	if _tactical_stance_label == null:
		return

	var stance_text: String = _build_tactical_stance_label_text()
	_tactical_stance_label.text = stance_text
	_tactical_stance_label.modulate = _build_tactical_stance_label_color()
	_tactical_stance_label.visible = show_world_debug_labels and is_visible_in_tree() and not stance_text.is_empty()


func _refresh_event_label() -> void:
	if _event_label == null:
		return

	_event_label.text = _current_event_text
	_event_label.modulate = _current_event_color
	_event_label.visible = show_world_event_labels and not _current_event_text.is_empty()


func _build_unit_name_label() -> String:
	if not display_name.is_empty():
		return display_name

	return unit_id


func _build_primary_status_label() -> String:
	var vital_state: String = String(_vital_status.state)
	match vital_state:
		"down":
			return "DOWN"
		"bleedout":
			return "BLEEDOUT"
		"respawning":
			var respawn_seconds: int = _get_respawn_remaining_seconds()
			if respawn_seconds > 0:
				return "RESPAWN %ds" % respawn_seconds
			return "RESPAWNING"

	var source_command_type: String = String(_runtime_status.source_command_type)
	if bool(get_meta("post_drop_security_active", false)):
		return "SEC 360"
	match source_command_type:
		"move":
			return "MOVE"
		"defend":
			return "DEFEND"
		"flank":
			return "FLANK"
		"take":
			return "ENGAGE"

	match String(_runtime_status.status):
		"engaging":
			return "ENGAGE"
		"holding":
			return "HOLD"
		"pending_move":
			return "MOVE"
		"assigned":
			return "ASSIGNED"
		_:
			return "IDLE"


func _build_secondary_status_label() -> String:
	if String(_vital_status.state) != "fit":
		return ""

	var parts: PackedStringArray = []
	var fire_status: String = String(_runtime_status.fire_status)
	if fire_status == "hold_fire":
		parts.append("HF")
	elif fire_status == "fire_at_will":
		parts.append("FAW")

	if _contact_active:
		parts.append("LOS")

	if get_health() < max_health_points and String(_vital_status.state) == "fit":
		parts.append("HP %d" % get_health())

	return " ".join(parts)


func _build_terrain_status_label() -> String:
	var effective_cover: int = get_effective_cover_score()
	var height_level: int = get_height_level()
	var surface_type: String = get_surface_type()
	var surface_speed_factor: float = get_surface_speed_factor()
	if _terrain_registry == null and effective_cover <= 0 and height_level <= 0 and surface_type == TERRAIN_TILE_DATA_SCRIPT.DEFAULT_SURFACE_TYPE:
		return ""

	return "COV:%d H:%d %s:%.1f" % [
		effective_cover,
		height_level,
		TERRAIN_TILE_DATA_SCRIPT.get_surface_short_code(surface_type),
		surface_speed_factor,
	]


func _build_status_label_color() -> Color:
	if String(_vital_status.state) == "down":
		return Color(1.0, 0.78, 0.78, 1.0)

	if String(_vital_status.state) == "bleedout":
		return Color(0.82, 0.82, 0.82, 1.0)

	if String(_vital_status.state) == "respawning":
		return Color(0.7, 0.9, 1.0, 0.8)

	if team_id == "team_alpha":
		return Color(0.85, 0.95, 1.0, 1.0)

	return Color(1.0, 0.88, 0.88, 1.0)


func _build_fireteam_label_color() -> Color:
	match fireteam_id:
		"blue", "ft1":
			return Color(0.45, 0.72, 1.0, 1.0)
		"gold", "ft2":
			return Color(1.0, 0.88, 0.35, 1.0)
		_:
			return Color(0.9, 0.9, 0.9, 1.0)


func _ensure_selection_ring() -> void:
	_selection_ring = get_node_or_null(SELECTION_RING_NAME) as Line2D
	if _selection_ring == null:
		_selection_ring = Line2D.new()
		_selection_ring.name = SELECTION_RING_NAME
		_selection_ring.width = 3.0
		_selection_ring.closed = true
		_selection_ring.z_index = 6
		_selection_ring.points = PackedVector2Array([
			Vector2(0.0, -14.0),
			Vector2(28.0, 0.0),
			Vector2(0.0, 14.0),
			Vector2(-28.0, 0.0),
		])
		add_child(_selection_ring)
	_refresh_selection_ring()


func _refresh_selection_ring() -> void:
	if _selection_ring == null:
		return
	_selection_ring.default_color = _build_fireteam_label_color().lightened(0.18)
	_selection_ring.visible = _world_selection_ring_visible and _is_tactical_selected and is_visible_in_tree()


func _build_phase_label_text() -> String:
	return COMMANDER_COMMAND_SCRIPT.get_phase_short_name(int(_runtime_status.phase))


func _build_tactical_stance_label_text() -> String:
	match _tactical_stance_id:
		"cautious":
			return "C"
		"aggressive":
			return "A"
		_:
			return "N"


func _build_tactical_stance_label_color() -> Color:
	match _tactical_stance_id:
		"cautious":
			return Color(0.62, 0.82, 1.0, 1.0)
		"aggressive":
			return Color(1.0, 0.52, 0.44, 1.0)
		_:
			return Color(0.94, 0.94, 0.9, 1.0)


func _normalize_fireteam_id(value: String) -> String:
	return value.strip_edges().to_lower()


func _normalize_tactical_stance_id(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	match normalized_value:
		"cautious", "aggressive":
			return normalized_value
		_:
			return "normal"


func get_respawn_remaining_seconds() -> int:
	return _get_respawn_remaining_seconds()


func _get_respawn_remaining_seconds() -> int:
	if _respawn_manager == null or not _respawn_manager.has_method("get_remaining_time"):
		return 0

	return maxi(int(ceili(float(_respawn_manager.call("get_remaining_time", unit_id)))), 0)


func _get_terrain_cover_bonus() -> float:
	if _terrain_registry == null or not _terrain_registry.has_method("get_cover_at_world"):
		return 0.0

	return float(_terrain_registry.call("get_cover_at_world", global_position))


func _rebuild_identity_data() -> void:
	_skills = UNIT_SKILLS_SCRIPT.new(
		{
			"accuracy": skill_accuracy,
			"speed": skill_speed,
			"leadership": skill_leadership,
			"toughness": skill_toughness,
		}
	)
	_traits.clear()
	for trait_id in trait_ids:
		var unit_trait = UNIT_TRAIT_SCRIPT.from_id(String(trait_id))
		if unit_trait == null:
			continue

		unit_trait.apply_to_skills(_skills)
		_traits.append(unit_trait)

	var metric_input: Dictionary = {
		"role_id": role_id,
		"trait_ids": trait_ids.duplicate(),
		"accuracy": float(_skills.accuracy),
		"speed": float(_skills.speed),
		"leadership": float(_skills.leadership),
		"toughness": float(_skills.toughness),
		"awareness": awareness,
		"recognition": recognition,
		"stealth": stealth,
		"discipline": discipline,
		"speech_quality": speech_quality,
		"speech_quantity": speech_quantity,
		"ground_vehicle_handling": ground_vehicle_handling,
		"dropship_piloting": dropship_piloting,
		"freighter_piloting": freighter_piloting,
		"fighter_piloting": fighter_piloting,
	}
	_character_profile_bundle = UNIT_PROFILE_MATH_SCRIPT.build_character_bundle(metric_input)

	var core_values: Dictionary = Dictionary(_character_profile_bundle.get("core_values", {}))
	awareness = float(core_values.get("awareness", awareness))
	recognition = float(core_values.get("recognition", recognition))
	stealth = float(core_values.get("stealth", stealth))
	discipline = float(core_values.get("discipline", discipline))
	var communication_values: Dictionary = Dictionary(_character_profile_bundle.get("communication_values", {}))
	speech_quality = float(communication_values.get("speech_quality", speech_quality))
	speech_quantity = float(communication_values.get("speech_quantity", speech_quantity))
	var platform_values: Dictionary = Dictionary(_character_profile_bundle.get("platform_values", {}))
	ground_vehicle_handling = float(platform_values.get("ground_vehicle_handling", ground_vehicle_handling))
	dropship_piloting = float(platform_values.get("dropship_piloting", dropship_piloting))
	freighter_piloting = float(platform_values.get("freighter_piloting", freighter_piloting))
	fighter_piloting = float(platform_values.get("fighter_piloting", fighter_piloting))
	if short_description.is_empty() and not biography_text.is_empty():
		var biography_parts: PackedStringArray = biography_text.split(".", false)
		if not biography_parts.is_empty():
			short_description = "%s." % String(biography_parts[0]).strip_edges()


func _coerce_trait_ids(value: Variant) -> PackedStringArray:
	if value is PackedStringArray:
		return (value as PackedStringArray).duplicate()

	var result: PackedStringArray = []
	if value is Array:
		for entry in value:
			var trait_id: String = String(entry).strip_edges().to_lower()
			if trait_id.is_empty():
				continue

			result.append(trait_id)

	return result


func _get_behavior_axis(axis_name: String) -> float:
	return clampf(float(Dictionary(_character_profile_bundle.get("behavior_axes", {})).get(axis_name, 0.0)), 0.0, 1.0)


# Prepared medical actor model transition. Root owns ticket/ground/manager commit.
class PreparedActorRespawn extends RefCounted:
	pass
var _prepared_actor_respawns:Dictionary={}
var _actor_respawn_epoch:=0

func prepare_actor_respawn(owner:Node,transition:String,world_position:Vector2=Vector2.ZERO)->Dictionary:
	if transition not in ["begin","complete"] or not world_position.is_finite():return {"ok":false,"reason":"invalid_actor_respawn_transition"}
	if not _actor_respawn_owner_matches(owner):return {"ok":false,"reason":"actor_respawn_owner_unbound"}
	if not _actor_respawn_models_valid():return {"ok":false,"reason":"actor_respawn_invalid_models"}
	var source_state:String=String(_vital_status.state)
	if source_state not in (["down","bleedout"] if transition=="begin" else ["down","bleedout","respawning"]):return {"ok":false,"reason":"actor_respawn_not_eligible"}
	if not _actor_respawn_frame_valid():return {"ok":false,"reason":"actor_respawn_invalid_frame"}
	for key in _prepared_actor_respawns.keys():
		var old:Dictionary=_prepared_actor_respawns[key]
		if old.handle.get_ref()==null or old.epoch!=_actor_respawn_epoch:_prepared_actor_respawns.erase(key)
	if _prepared_actor_respawns.size()>=32:return {"ok":false,"reason":"actor_respawn_prepare_capacity"}
	var runtime:RefCounted=_build_runtime_status("idle")
	var vital:RefCounted=_build_vital_status("respawning" if transition=="begin" else "fit",get_health() if transition=="begin" else max_health_points,int(_vital_status.bleedout_ticks) if transition=="begin" else 0)
	if not runtime.is_valid() or not vital.is_valid():return {"ok":false,"reason":"actor_respawn_invalid_patch"}
	var source:Dictionary=_actor_respawn_binding(owner)
	var post:Dictionary=_actor_respawn_model_stamp()
	post.runtime_id=runtime.get_instance_id();post.runtime=runtime.to_dict().duplicate(true)
	post.vital_id=vital.get_instance_id();post.vital=vital.to_dict().duplicate(true)
	post.command_id=0;post.command={};post.contact_active=false;post.contact_target=""
	var damage:Dictionary=_last_damage_context.duplicate(true) if transition=="begin" else {}
	post.damage=damage.duplicate(true)
	var handle:=PreparedActorRespawn.new()
	_prepared_actor_respawns[handle.get_instance_id()]={"handle":weakref(handle),"owner":weakref(owner),"epoch":_actor_respawn_epoch,"phase":"prepared","transition":transition,"source":source,"post_models":post,"runtime":runtime,"vital":vital,"damage":damage,"world_position":world_position,"parent_id":get_parent().get_instance_id(),"registry_id":owner.get_unit_registry().get_instance_id()}
	return {"ok":true,"prepared":handle}

func validate_prepared_actor_respawn(prepared:RefCounted)->Dictionary:
	var record:Dictionary=_actor_respawn_record(prepared)
	if record.is_empty():return {"ok":false,"reason":"unknown_actor_respawn"}
	if record.phase!="prepared" or record.epoch!=_actor_respawn_epoch:return {"ok":false,"reason":"actor_respawn_already_published"}
	var owner:Node=record.owner.get_ref()
	if not _actor_respawn_owner_matches(owner) or not _actor_respawn_models_valid() or not _actor_respawn_frame_valid() or _actor_respawn_binding(owner)!=record.source:return {"ok":false,"reason":"actor_respawn_context_changed"}
	return {"ok":true,"prepared_id":prepared.get_instance_id()}

# Call only after the whole Root transaction validates before any model writes.
# Pose/Visual setters may notify Canvas observers and therefore belong to finalize.
func _publish_prepared_actor_respawn(prepared:RefCounted,_validation:Dictionary)->Dictionary:
	var record:Dictionary=_prepared_actor_respawns[prepared.get_instance_id()]
	_runtime_status=record.runtime
	_vital_status=record.vital
	_current_unit_command=null
	_contact_active=false
	_contact_target_id=""
	_last_damage_context=record.damage
	record.phase="published"
	_actor_respawn_epoch+=1
	return {"ok":true}

func finalize_actor_respawn(prepared:RefCounted)->Dictionary:
	var record:Dictionary=_actor_respawn_record(prepared)
	if record.is_empty():return {"ok":false,"reason":"unknown_actor_respawn"}
	if record.phase=="finalized":return {"ok":true,"replayed":true}
	if record.phase!="published":return {"ok":false,"reason":"actor_respawn_not_published"}
	record.phase="finalized" # Before pose notifications or any signal/reentry.
	var lifetime:WeakRef=weakref(self)
	if not _actor_respawn_can_finalize(record):return {"ok":true,"context_changed":true}
	if record.transition=="complete":global_position=record.world_position
	if not is_instance_valid(lifetime.get_ref()) or not _actor_respawn_can_finalize(record):return {"ok":true,"context_changed":true}
	_apply_vital_visual()
	if not is_instance_valid(lifetime.get_ref()) or not _actor_respawn_can_finalize(record):return {"ok":true,"context_changed":true}
	# Existing medical event order, with every model already complete beforehand.
	if record.transition=="begin":runtime_status_changed.emit(_runtime_status)
	else:vital_status_changed.emit(_vital_status)
	if not is_instance_valid(lifetime.get_ref()) or not _actor_respawn_can_finalize(record):return {"ok":true,"context_changed":true}
	if record.transition=="begin":vital_status_changed.emit(_vital_status)
	else:runtime_status_changed.emit(_runtime_status)
	if not is_instance_valid(lifetime.get_ref()) or not _actor_respawn_can_finalize(record):return {"ok":true,"context_changed":true}
	_refresh_readability()
	if not is_instance_valid(lifetime.get_ref()) or not _actor_respawn_can_finalize(record):return {"ok":true,"context_changed":true}
	if record.transition=="begin":show_event_text("RESPAWNING",Color(0.7,0.9,1.0,1.0),1.8)
	else:show_event_text("RESPAWN",Color(0.5,1.0,0.7,1.0),2.0)
	return {"ok":true,"replayed":false}

func _actor_respawn_record(prepared:RefCounted)->Dictionary:
	if prepared==null or not _prepared_actor_respawns.has(prepared.get_instance_id()):return {}
	var record:Dictionary=_prepared_actor_respawns[prepared.get_instance_id()]
	return record if record.handle.get_ref()==prepared else {}

func _actor_respawn_can_finalize(record:Dictionary)->bool:
	var owner:Node=record.owner.get_ref()
	if not _actor_respawn_owner_matches(owner):return false
	# Respawn may legitimately advance the per-unit lifecycle, never its world.
	if owner._hex_payload_identity(unit_id).get("context",-1)!=record.source.lifecycle.context:return false
	return not is_queued_for_deletion() and owner.get_unit_registry().get_instance_id()==record.registry_id and _actor_respawn_models_valid() and _actor_respawn_frame_valid() and get_parent().get_instance_id()==record.parent_id and _actor_respawn_model_stamp()==record.post_models

func _actor_respawn_owner_matches(owner:Node)->bool:
	if not is_instance_valid(owner) or owner.is_queued_for_deletion() or not is_inside_tree():return false
	for method in ["get_unit_registry","_resolve_known_unit_for_contract","_hex_payload_identity"]:
		if not owner.has_method(method):return false
	var registry=owner.get_unit_registry()
	return is_instance_valid(registry) and registry.has_method("get_unit") and registry.get_unit(unit_id)==self and owner._resolve_known_unit_for_contract(unit_id)==self and is_instance_valid(owner.get_parent()) and owner.get_parent().is_ancestor_of(self)

func _actor_respawn_frame_valid()->bool:
	if not global_position.is_finite() or not is_instance_valid(get_parent()):return false
	var parent=get_parent()
	if parent is Node2D:
		var frame:Transform2D=parent.global_transform
		return frame.is_finite() and absf(frame.determinant())>0.000001
	return true

func _actor_respawn_models_valid()->bool:
	return is_instance_valid(_vital_status) and _vital_status.get_script()==UNIT_VITAL_STATUS_SCRIPT and _vital_status.is_valid() and is_instance_valid(_runtime_status) and _runtime_status.get_script()==UNIT_RUNTIME_STATUS_SCRIPT and _runtime_status.is_valid() and (_current_unit_command==null or (_current_unit_command.has_method("to_dict") and _current_unit_command.has_method("is_valid") and _current_unit_command.is_valid()))

func _actor_respawn_binding(owner:Node)->Dictionary:
	return {"actor_id":get_instance_id(),"owner_id":owner.get_instance_id(),"registry_id":owner.get_unit_registry().get_instance_id(),"lifecycle":Dictionary(owner._hex_payload_identity(unit_id)).duplicate(true),"parent_id":get_parent().get_instance_id(),"world_transform":global_transform,"parent_transform":get_parent().global_transform if get_parent() is Node2D else Transform2D.IDENTITY,"models":_actor_respawn_model_stamp()}

func _actor_respawn_model_stamp()->Dictionary:
	return {"unit_id":unit_id,"team_id":team_id,"fireteam_id":fireteam_id,"max_health_points":max_health_points,"vital_id":_vital_status.get_instance_id(),"vital":_vital_status.to_dict().duplicate(true),"runtime_id":_runtime_status.get_instance_id(),"runtime":_runtime_status.to_dict().duplicate(true),"command_id":_current_unit_command.get_instance_id() if _current_unit_command!=null else 0,"command":_current_unit_command.to_dict().duplicate(true) if _current_unit_command!=null else {},"contact_active":_contact_active,"contact_target":_contact_target_id,"damage":_last_damage_context.duplicate(true),"manager_id":_respawn_manager.get_instance_id() if is_instance_valid(_respawn_manager) else 0,"terrain_id":_terrain_registry.get_instance_id() if is_instance_valid(_terrain_registry) else 0}
