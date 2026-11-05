extends SceneTree

const VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_original_model_lies_above_ground_and_recovers()
	await _test_event_impulse_expires_and_does_not_replay()
	print("=== NPC COMBAT FEEDBACK: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_original_model_lies_above_ground_and_recovers() -> void:
	var view: Node = _make_view()
	var unit: Node2D = _make_unit("feedback_enemy", "team_bravo", Vector2(160.0, 160.0))
	root.add_child(unit)
	view.call("set_unit_nodes", [unit])
	await _frames(10)
	var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get("feedback_enemy") as Node3D
	_assert(proxy != null, "Actual runtime enemy receives a 3D proxy")
	if proxy == null:
		view.queue_free()
		unit.queue_free()
		return
	var model: Node3D = view.call("_find_unit_model_root", proxy) as Node3D
	_assert(model != null, "Actual animated character model is present before damage")
	if model == null:
		view.queue_free()
		unit.queue_free()
		return
	var original_id: int = model.get_instance_id()
	var original_transform: Transform3D = model.transform
	var weapon: Node = view.call("_find_unit_blaster_visual_node", proxy)
	var original_weapon_id: int = weapon.get_instance_id() if weapon != null else 0
	unit.call("apply_damage", 30, {"fire_event_id": "feedback_wounded"})
	await _frames(4)
	var icon: Sprite3D = proxy.get_node_or_null("UnitStateIcon") as Sprite3D
	_assert(icon != null and icon.visible and icon.texture != null, "Owner wound state displays a visible shape icon")
	var wounded_image: PackedByteArray = icon.texture.get_image().get_data() if icon != null and icon.texture != null else PackedByteArray()
	unit.call("apply_damage", 200, {"fire_event_id": "feedback_down"})
	await _frames(4)
	_assert(model.get_instance_id() == original_id and model.is_visible_in_tree(), "Down retains the identical visible original model")
	_assert(weapon != null and weapon.get_instance_id() == original_weapon_id, "Down retains the identical weapon attachment")
	_assert(absf(model.rotation_degrees.x) >= 65.0, "Down visibly lays the existing model horizontally")
	var core: Node3D = proxy.get_node_or_null("UnitBodyReadabilityCore") as Node3D
	_assert(core == null or not core.visible, "Down hides the upright visual capsule beside the original figure")
	var bounds: Dictionary = Dictionary(view.call("_get_local_visual_bounds", model))
	_assert(bool(bounds.get("valid", false)) and Vector3(bounds.get("min", Vector3.DOWN)).y >= 0.005, "Down model bounds stay above the proxy ground plane")
	icon = proxy.get_node_or_null("UnitStateIcon") as Sprite3D
	_assert(icon != null and icon.visible and icon.texture != null, "Down owner state displays a visible critical icon")
	if icon != null and icon.texture != null:
		_assert(icon.texture.get_image().get_data() != wounded_image, "Critical and wounded icons differ by shape, not only modulation")
	unit.call("apply_heal", 50)
	await _frames(4)
	_assert(model.get_instance_id() == original_id and model.transform.is_equal_approx(original_transform), "Owner healing restores the same model and its original transform")
	unit.call("apply_damage", 200, {"fire_event_id": "feedback_down_again"})
	await _frames(4)
	unit.call("advance_bleedout")
	await _frames(4)
	_assert(model.get_instance_id() == original_id and absf(model.rotation_degrees.x) >= 65.0, "Bleedout keeps the same original lying model")
	unit.call("begin_respawn")
	await _frames(4)
	_assert(model.get_instance_id() == original_id and (core == null or not core.visible), "Respawn countdown preserves lying identity without the capsule")
	unit.call("respawn", Vector2(160.0, 160.0))
	await _frames(4)
	_assert(model.get_instance_id() == original_id and model.transform.is_equal_approx(original_transform), "Actual respawn restores the same model and its original transform")
	_assert(core == null or core.visible, "Actual respawn restores the normal readable body policy")
	view.queue_free()
	unit.queue_free()
	await _frames(2)


func _test_event_impulse_expires_and_does_not_replay() -> void:
	var view: Node = _make_view()
	await _frames(3)
	_assert(view.find_child("WeaponFireReadablePulse_*", true, false) == null, "No event produces no firing impulse")
	var event: Dictionary = {
		"event_id": "feedback_fire_once", "event_type": "weapon_fire",
		"attacker_unit_id": "alpha", "attacker_team_id": "team_alpha",
		"target_unit_id": "bravo", "target_team_id": "team_bravo", "weapon_id": "rifle",
		"attacker_position": Vector2(96.0, 128.0), "target_position": Vector2(224.0, 128.0),
	}
	view.call("set_order_visual_payload", {"fire_event_dicts": [event]})
	await _frames(2)
	var pulse: Node3D = view.find_child("WeaponFireReadablePulse_*", true, false) as Node3D
	_assert(pulse != null and pulse.visible, "A real event creates a visible muzzle impulse")
	if pulse != null:
		var flash: Sprite3D = pulse.get_node_or_null("MuzzleFlash") as Sprite3D
		var firing_icon: Sprite3D = pulse.get_node_or_null("FiringIcon") as Sprite3D
		_assert(flash != null and flash.texture != null and flash.visible, "Event impulse includes a camera-facing flash card")
		_assert(firing_icon != null and firing_icon.texture != null and firing_icon.visible, "The same event displays a readable shot symbol")
	await create_timer(0.85).timeout
	pulse = view.find_child("WeaponFireReadablePulse_*", true, false) as Node3D
	_assert(pulse == null or not pulse.visible, "Flash and shot symbol expire without another gameplay event")
	view.call("set_order_visual_payload", {"fire_event_dicts": [event], "phase_index": 9})
	await _frames(2)
	pulse = view.find_child("WeaponFireReadablePulse_*", true, false) as Node3D
	_assert(pulse == null or not pulse.visible, "Rebuilding another order does not replay an old shot")
	view.call("set_fog_of_war_state", {
		"mode": "known_terrain", "team_id": "team_alpha",
		"terrain_knowledge": {"visible_tile_ids": []},
		"current_visibility": {"visible_target_ids": [], "visible_event_ids": []},
	})
	var hidden_event: Dictionary = event.duplicate(true)
	hidden_event["event_id"] = "feedback_hidden_fire"
	hidden_event["attacker_unit_id"] = "unseen_enemy"
	hidden_event["target_unit_id"] = "unseen_target"
	hidden_event["attacker_team_id"] = "team_bravo"
	hidden_event["target_team_id"] = "team_charlie"
	view.call("set_order_visual_payload", {"fire_event_dicts": [hidden_event]})
	await _frames(2)
	pulse = view.find_child("WeaponFireReadablePulse_*", true, false) as Node3D
	_assert(pulse == null or not pulse.visible, "Unknown combat does not leak a firing impulse through the existing FoW gate")
	view.call("set_fog_of_war_state", {
		"mode": "known_terrain", "team_id": "team_alpha",
		"terrain_knowledge": {"visible_tile_ids": []},
		"current_visibility": {"visible_target_ids": ["unseen_target"], "visible_event_ids": []},
	})
	hidden_event["event_id"] = "feedback_hidden_source_visible_target"
	view.call("set_order_visual_payload", {"fire_event_dicts": [hidden_event]})
	await _frames(2)
	pulse = view.find_child("WeaponFireReadablePulse_*", true, false) as Node3D
	_assert(pulse == null or not pulse.visible, "A visible target does not expose a still unknown shooter's source icon")
	view.queue_free()
	await _frames(2)


func _make_view() -> Node:
	var view: Node = VIEW_SCRIPT.new()
	root.add_child(view)
	var map_data = MAP_SCRIPT.call("create_empty", "npc_feedback", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2)
	view.call("configure_from_map", map_data)
	return view


func _make_unit(unit_id: String, team_id: String, position_value: Vector2) -> Node2D:
	var unit: Node2D = UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.set("unit_id", unit_id)
	unit.set("display_name", unit_id)
	unit.set("team_id", team_id)
	unit.set("weapon_1_id", "rifle")
	unit.set("weapon_2_id", "none")
	unit.position = position_value
	return unit


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] " + message)
	else:
		_failed += 1
		push_error("[FAIL] " + message)
