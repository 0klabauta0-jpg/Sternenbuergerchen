extends RefCounted

## Test-only staging for the legacy release first-exchange deeplink.
##
## This file deliberately contains the deterministic positioning and private
## combat-driver setup required by the release capture harness.  It must never
## be called by regular mission flow; MetaLayerFlow only creates it after the
## explicit --release-singleplayer-first-go-firefight argument was supplied.

const SYNTHETIC_FIXTURE: bool = true


func prepare(
	tree: SceneTree,
	controller: Node,
	combat_driver: Node,
	simulation_root: Node,
	fireteam_id: String
) -> Dictionary:
	var contact_setup: Dictionary = _position_enemy_near_fireteam(controller, combat_driver, fireteam_id)
	if contact_setup.is_empty():
		return {
			"synthetic_fixture": true,
			"status": "blocked",
			"reason": "contact_setup_failed",
		}
	_prepare_fireteam_for_first_engagement(controller, fireteam_id, Vector2(contact_setup.get("enemy_position", Vector2.ZERO)))
	_stabilize_target_enemy(controller, contact_setup)
	await tree.physics_frame
	await tree.process_frame
	_update_contact_tracking(combat_driver)
	_force_first_engagement_decision(controller, combat_driver, simulation_root, fireteam_id, contact_setup)
	return {
		"synthetic_fixture": true,
		"status": "prepared",
		"reason": "",
		"contact_setup": contact_setup.duplicate(true),
		"simulation_tick": int(simulation_root.call("get_tick")) if simulation_root.has_method("get_tick") else -1,
		"command_queue_count": Array(simulation_root.get("command_queue")).size(),
		"selected_contact_count": Array(controller.call("get_fireteam_contact_snapshot", fireteam_id)).size(),
	}


func _position_enemy_near_fireteam(controller: Node, combat_driver: Node, fireteam_id: String) -> Dictionary:
	var friendly_units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	var enemy_units: Array = Array(controller.call("_get_all_enemy_units", false))
	if enemy_units.is_empty():
		enemy_units = Array(controller.call("_get_all_enemy_units", true))
	if friendly_units.is_empty() or enemy_units.is_empty():
		return {}
	var friendly := friendly_units[0] as Node2D
	var enemy := enemy_units[0] as Node2D
	if friendly == null or enemy == null:
		return {}
	var placement: Dictionary = _resolve_enemy_placement(friendly, enemy, combat_driver)
	var selected_setup: Dictionary = _build_contact_setup(fireteam_id, friendly, enemy, placement, 1)
	var selected_enemy_id: String = String(selected_setup.get("enemy_unit_id", "")).strip_edges()
	var selected_enemy := _find_unit_by_id(enemy_units, selected_enemy_id) as Node2D
	if selected_enemy == null:
		return {}
	selected_enemy.global_position = Vector2(selected_setup.get("enemy_position", selected_enemy.global_position))
	if selected_enemy is CanvasItem:
		(selected_enemy as CanvasItem).visible = true
	selected_setup["enemy_position"] = selected_enemy.global_position
	selected_setup["pair_candidate_count"] = 1
	selected_setup["style_id"] = "task_868_release_first_exchange_los_setup_polish_v1"
	selected_setup["task_id"] = "TASK_868"
	selected_setup["synthetic_fixture"] = true
	selected_setup["read_only_snapshot_available"] = true
	selected_setup["ui_sets_gameplay_truth"] = false
	return {
		"schema": "sternenbuergerchen.release_first_exchange_los_setup_polish.setup.v1",
		"task_id": "TASK_868",
		"style_id": "task_868_release_first_exchange_los_setup_polish_v1",
		"synthetic_fixture": true,
		"fireteam_id": String(selected_setup.get("fireteam_id", fireteam_id)),
		"friendly_unit_id": String(selected_setup.get("friendly_unit_id", "")),
		"enemy_unit_id": selected_enemy_id,
		"friendly_position": selected_setup.get("friendly_position", Vector2.ZERO),
		"enemy_position": selected_setup.get("enemy_position", Vector2.ZERO),
		"placement_verified_attackable": bool(selected_setup.get("placement_verified_attackable", false)),
		"placement_attempt_count": int(selected_setup.get("placement_attempt_count", 0)),
		"placement_offset": selected_setup.get("placement_offset", Vector2.ZERO),
		"placement_readout": Dictionary(selected_setup.get("placement_readout", {})),
		"pair_candidate_count": int(selected_setup.get("pair_candidate_count", 1)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _resolve_enemy_placement(friendly: Node2D, enemy: Node2D, combat_driver: Node) -> Dictionary:
	var fallback_offset := Vector2(58.0, 0.0)
	var fallback_position: Vector2 = friendly.global_position + fallback_offset
	var candidate_offsets: Array = [
		Vector2(24.0, 0.0), Vector2(0.0, 24.0), Vector2(-24.0, 0.0), Vector2(0.0, -24.0),
		Vector2(42.0, 0.0), Vector2(0.0, 42.0), Vector2(-42.0, 0.0), Vector2(0.0, -42.0),
		Vector2(32.0, 32.0), Vector2(-32.0, 32.0), Vector2(32.0, -32.0), Vector2(-32.0, -32.0),
		Vector2(58.0, 0.0), Vector2(0.0, 58.0), Vector2(-58.0, 0.0), Vector2(0.0, -58.0),
		Vector2(84.0, 0.0), Vector2(0.0, 84.0), Vector2(-84.0, 0.0), Vector2(0.0, -84.0),
	]
	var attempt_count: int = 0
	var fallback_readout: Dictionary = {}
	var original_enemy_position: Vector2 = enemy.global_position
	if combat_driver != null and combat_driver.has_method("build_cover_effectiveness_readout_for_units"):
		for offset_variant in candidate_offsets:
			var offset: Vector2 = offset_variant
			attempt_count += 1
			enemy.global_position = friendly.global_position + offset
			var readout: Dictionary = Dictionary(combat_driver.call("build_cover_effectiveness_readout_for_units", friendly, enemy, "confirmed")).duplicate(true)
			if fallback_readout.is_empty():
				fallback_readout = readout
				fallback_position = enemy.global_position
				fallback_offset = offset
			if bool(readout.get("combat_attackable", false)) \
					and String(readout.get("range_state", "")).strip_edges().to_lower() == "in_range" \
					and String(readout.get("los_state", "")).strip_edges().to_lower() != "blocked":
				return {
					"enemy_position": enemy.global_position,
					"placement_verified_attackable": true,
					"placement_attempt_count": attempt_count,
					"placement_offset": offset,
					"placement_readout": readout,
				}
	enemy.global_position = fallback_position
	if fallback_readout.is_empty():
		enemy.global_position = original_enemy_position
	return {
		"enemy_position": enemy.global_position,
		"placement_verified_attackable": false,
		"placement_attempt_count": attempt_count,
		"placement_offset": fallback_offset,
		"placement_readout": fallback_readout,
	}


func _build_contact_setup(fireteam_id: String, friendly: Node2D, enemy: Node2D, placement: Dictionary, pair_candidate_count: int) -> Dictionary:
	return {
		"fireteam_id": fireteam_id,
		"friendly_unit_id": _unit_id(friendly),
		"enemy_unit_id": _unit_id(enemy),
		"friendly_position": friendly.global_position,
		"enemy_position": Vector2(placement.get("enemy_position", friendly.global_position + Vector2(58.0, 0.0))),
		"placement_verified_attackable": bool(placement.get("placement_verified_attackable", false)),
		"placement_attempt_count": int(placement.get("placement_attempt_count", 0)),
		"placement_offset": placement.get("placement_offset", Vector2.ZERO),
		"placement_readout": Dictionary(placement.get("placement_readout", {})),
		"pair_candidate_count": pair_candidate_count,
	}


func _prepare_fireteam_for_first_engagement(controller: Node, fireteam_id: String, enemy_position: Vector2) -> void:
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit == null:
			continue
		controller.call("queue_release_first_exchange_hold_command", _unit_id(unit), enemy_position, "task832_release_first_go_firefight")


func _stabilize_target_enemy(controller: Node, contact_setup: Dictionary) -> void:
	var enemy_id: String = String(contact_setup.get("enemy_unit_id", "")).strip_edges()
	var friendly_position: Vector2 = Vector2(contact_setup.get("friendly_position", Vector2.ZERO))
	var enemy := _find_unit_by_id(Array(controller.call("_get_all_enemy_units", true)), enemy_id) as Node2D
	if enemy == null:
		return
	controller.call("queue_release_first_exchange_hold_command", enemy_id, friendly_position, "task868_release_first_exchange_los_setup_polish")


func _force_first_engagement_decision(controller: Node, combat_driver: Node, simulation_root: Node, fireteam_id: String, contact_setup: Dictionary) -> void:
	var enemy_id: String = String(contact_setup.get("enemy_unit_id", "")).strip_edges()
	var enemy_ids: PackedStringArray = []
	if not enemy_id.is_empty():
		enemy_ids.append(enemy_id)
	else:
		for enemy_variant in Array(controller.call("_get_all_enemy_units", false)):
			var next_enemy_id: String = _unit_id(enemy_variant as Node)
			if not next_enemy_id.is_empty() and not enemy_ids.has(next_enemy_id):
				enemy_ids.append(next_enemy_id)
	var detection_progress: Dictionary = Dictionary(combat_driver.get("_detection_progress")).duplicate(true)
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit == null:
			continue
		var friendly_id: String = _unit_id(unit)
		if friendly_id.is_empty():
			continue
		for next_enemy_id in enemy_ids:
			detection_progress["%s:%s" % [friendly_id, next_enemy_id]] = 0
			detection_progress["%s:%s" % [next_enemy_id, friendly_id]] = 0
	combat_driver.set("_detection_progress", detection_progress)
	_update_contact_tracking(combat_driver)
	combat_driver.set("_current_tick", maxi(int(combat_driver.get("_current_tick")), 120))
	combat_driver.set("_next_attack_tick", 0)
	if combat_driver.has_method("_try_enqueue_attacks"):
		combat_driver.call("_try_enqueue_attacks", simulation_root)


func _update_contact_tracking(combat_driver: Node) -> void:
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")
	if combat_driver.has_method("_advance_detection_timers"):
		combat_driver.call("_advance_detection_timers")
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")


func _find_unit_by_id(units: Array, unit_id: String) -> Node:
	var normalized_id: String = unit_id.strip_edges()
	if normalized_id.is_empty():
		return null
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit != null and _unit_id(unit) == normalized_id:
			return unit
	return null


func _unit_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id"))
	return unit.name if unit != null else ""
