extends RefCounted
## Encounter metadata references registered motion; it does not copy positions.
const REGISTRY = preload("res://scripts/core/space_ship_registry.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const AREA = preload("res://scripts/core/space_area_grid.gd")
const SHIP_SYSTEMS = preload("res://scripts/tactical/space_component_systems.gd")
var _registry: RefCounted = REGISTRY.new()
var _metadata: Dictionary = {}
var _indexed_revisions: Dictionary = {}
var _flight_controls: Dictionary = {}
var _flight_status: Dictionary = {}
var _navigation_claims: Dictionary = {}
var _claim_cells: Dictionary = {}
var _claim_revisions: Dictionary = {}
var _inactive_actors: Dictionary = {}
var _ship_systems: Dictionary = {}
var _ship_impact_receipts: Dictionary = {}

func bind_ship_systems(craft_id: String, stats: Dictionary, hull_capacity: float) -> Dictionary:
	# SimulationRoot supplies actual equipment stats. A repeat must never repair
	# or refill an existing ship; refit/lifecycle rebinding is a later contract.
	if not _metadata.has(craft_id): return {"ok":false, "reason":"unknown_actor"}
	if _ship_systems.has(craft_id): return {"ok":false, "reason":"systems_already_bound"}
	var initial: Dictionary = SHIP_SYSTEMS.initial(stats, hull_capacity)
	if not initial.get("ok", false): return initial
	_ship_systems[craft_id] = {"stats":stats.duplicate(true), "state":initial.state.duplicate(true), "cooldowns":{}}
	return {"ok":true}

func get_ship_systems(craft_id: String) -> Dictionary:
	return Dictionary(_ship_systems.get(craft_id, {})).duplicate(true)

func ensure_ship_systems(craft_id: String, stats: Dictionary) -> Dictionary:
	if not _metadata.has(craft_id): return {"ok":false, "reason":"unknown_actor"}
	if not _ship_systems.has(craft_id): return bind_ship_systems(craft_id, stats, float(stats.get("hull_capacity", 0.0)))
	var existing: Dictionary = _ship_systems[craft_id].stats.duplicate(true)
	var incoming := stats.duplicate(true)
	# Warp-slot revisions do not alter combat hardware; retain shield/hull on
	# orbit transitions. A changed combat configuration needs explicit refit.
	existing.erase("equipment_revision"); incoming.erase("equipment_revision")
	return {"ok":true} if existing == incoming else {"ok":false, "reason":"systems_refit_required"}

func _commit_ship_impact(event: Dictionary) -> Dictionary:
	# Private owner tail for a Root-resolved shot; never pass a client event here.
	var id: Variant = event.get("id")
	if typeof(id) != TYPE_STRING or String(id).strip_edges().is_empty(): return {"ok":false, "reason":"invalid_event"}
	var signature := var_to_str(event)
	if _ship_impact_receipts.has(id):
		var receipt: Dictionary = _ship_impact_receipts[id]
		if receipt.signature != signature: return {"ok":false, "reason":"event_id_conflict"}
		var replay: Dictionary = receipt.result.duplicate(true); replay["replayed"] = true; return replay
	if _ship_impact_receipts.size() >= 4096: return {"ok":false, "reason":"receipt_capacity"}
	var shooter: Variant = event.get("shooter_id")
	var target: Variant = event.get("hit_craft_id")
	var slot: Variant = event.get("weapon_slot")
	if typeof(shooter) != TYPE_STRING or typeof(target) != TYPE_STRING or typeof(slot) != TYPE_STRING or not _metadata.has(shooter) or not _ship_systems.has(shooter): return {"ok":false, "reason":"invalid_event"}
	if typeof(event.get("damage")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(event.damage)) or float(event.damage) < 0.0: return {"ok":false, "reason":"invalid_event"}
	var source: Dictionary = _ship_systems[shooter]
	if _registry.get_actor(shooter) == null or float(source.state.hull) <= 0.0: return {"ok":false, "reason":"shooter_unavailable"}
	var weapon := {}
	for entry: Dictionary in source.stats.get("weapons", []):
		if entry.get("slot_id") == slot: weapon = entry; break
	if weapon.is_empty() or float(source.cooldowns.get(slot, 0.0)) > 0.0 or typeof(weapon.get("shots_per_second")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(weapon.shots_per_second)) or float(weapon.shots_per_second) <= 0.0: return {"ok":false, "reason":"weapon_unavailable"}
	if not String(target).is_empty() and not is_equal_approx(float(event.damage), float(weapon.damage)): return {"ok":false, "reason":"weapon_damage_mismatch"}
	var consumed: Dictionary = SHIP_SYSTEMS.consume_weapon(source.stats, source.state, 1.0)
	if not consumed.ok: return consumed
	var result := {"ok":true, "replayed":false, "hit_craft_id":target, "shield_damage":0.0, "hull_damage":0.0}
	var hit_state := {}
	if not String(target).is_empty():
		if not _ship_systems.has(target) or not _metadata.has(target) or _registry.get_actor(shooter) == null or _registry.get_actor(target) == null: return {"ok":false, "reason":"target_unavailable"}
		if _registry.get_actor(shooter).get_snapshot().space_area_id != _registry.get_actor(target).get_snapshot().space_area_id: return {"ok":false, "reason":"different_area"}
		var current: Dictionary = _ship_systems[target]
		var hit: Dictionary = SHIP_SYSTEMS.apply_hit(current.stats, current.state, float(event.damage))
		if not hit.ok: return hit
		hit_state = hit.state
		result.shield_damage = hit.shield_damage; result.hull_damage = hit.hull_damage
	elif float(event.damage) != 0.0:
		return {"ok":false, "reason":"invalid_event"}
	# Both proposals are complete before publishing either side. A self-hit is
	# not accepted here; Root's future resolver must use the actual beam index.
	if target == shooter: return {"ok":false, "reason":"invalid_event"}
	source.state = consumed.state
	source.cooldowns[slot] = 1.0 / float(weapon.shots_per_second)
	if not String(target).is_empty(): _ship_systems[target].state = hit_state
	_ship_impact_receipts[id] = {"signature":signature, "result":result.duplicate(true)}
	return result

func advance_ship_systems(delta: float) -> Dictionary:
	if not is_finite(delta) or delta < 0.0: return {"ok":false, "reason":"invalid_tick"}
	var proposals := {}
	var cooldown_proposals := {}
	for craft_id: String in _ship_systems:
		if _registry.get_actor(craft_id) == null: continue
		var current: Dictionary = _ship_systems[craft_id]
		if float(current.state.hull) <= 0.0: continue
		var step: Dictionary = SHIP_SYSTEMS.advance(current.stats, current.state, delta)
		if not step.ok: return step
		proposals[craft_id] = step.state
		var timers: Dictionary = current.cooldowns.duplicate(true)
		for slot: String in timers: timers[slot] = maxf(0.0, float(timers[slot]) - delta)
		cooldown_proposals[craft_id] = timers
	for craft_id: String in proposals: _ship_systems[craft_id].state = proposals[craft_id]
	for craft_id: String in cooldown_proposals: _ship_systems[craft_id].cooldowns = cooldown_proposals[craft_id]
	return {"ok":true}

func admit_actor(definition: Dictionary, flight: RefCounted, allow_local_fixture: bool = false) -> Dictionary:
	# Occupancy and sweep callers still use strategic bounds. Fail closed until
	# the complete local-area admission and navigation path is connected.
	if flight != null and flight.get_snapshot().get("coordinate_frame", "strategic") != "strategic":
		if not allow_local_fixture or not String(definition.get("craft_id", "")).begins_with("space_fixture_"):
			return {"ok":false, "reason":"local_area_not_ready"}
	if flight != null and String(flight.get_snapshot().get("space_area_id", "")).begins_with("atmosphere:") and flight.get_snapshot().get("assist_mode") != "coupled": return {"ok":false, "reason":"atmosphere_requires_coupled"}
	var craft_id: String = String(definition.get("craft_id", ""))
	if _inactive_actors.has(craft_id): return {"ok":false, "reason":"already_inactive"}
	var faction: String = String(definition.get("faction_id", ""))
	var domain: String = String(definition.get("control_domain", ""))
	var cell: Variant = definition.get("start_hex")
	var footprint: Variant = definition.get("footprint_hexes")
	if craft_id.strip_edges().is_empty() or faction.strip_edges().is_empty() or domain not in ["player", "neutral", "enemy"] or typeof(cell) != TYPE_VECTOR2I or typeof(footprint) != TYPE_ARRAY or footprint.is_empty() or footprint.size() > 64:
		return {"ok": false, "reason": "invalid_actor"}
	var unique := {}
	for offset in footprint:
		if typeof(offset) != TYPE_VECTOR2I or unique.has(offset):
			return {"ok": false, "reason": "invalid_footprint"}
		unique[offset] = true
	if not unique.has(Vector2i.ZERO):
		return {"ok": false, "reason": "invalid_footprint"}
	var initial_cells: Array[Vector2i] = _occupied_cells(flight.get_snapshot(), footprint)
	var area_id: String = String(flight.get_snapshot().get("space_area_id", ""))
	if initial_cells.is_empty() or not _registry.query_cells(initial_cells, area_id).is_empty():
		return {"ok": false, "reason": "occupied_or_invalid_footprint"}
	if not _registry.register_actor(craft_id, flight):
		return {"ok": false, "reason": "duplicate_or_invalid_actor"}
	if not _registry.update_actor_cells(craft_id, initial_cells):
		_registry.unregister_actor(craft_id)
		return {"ok": false, "reason": "invalid_actor_cell"}
	_metadata[craft_id] = {"faction_id": faction, "control_domain": domain, "footprint_hexes": footprint.duplicate()}
	_indexed_revisions[craft_id] = int(flight.get_snapshot().revision)
	return {"ok": true}

func get_actor(craft_id: String) -> RefCounted:
	return _registry.get_actor(craft_id)

func get_area_actor_ids(area_id: String) -> Array[String]:
	return _registry.get_area_actor_ids(area_id)

func get_indexed_actor_cells(craft_id: String) -> Array:
	return _registry.get_indexed_actor_cells(craft_id)

func get_inactive_actor(craft_id: String) -> RefCounted:
	return _inactive_actors.get(craft_id)

func validate_new_local_admission(definition: Dictionary, flight: RefCounted, proposal: Dictionary, tick: int) -> Dictionary:
	var craft_id: Variant = definition.get("craft_id")
	var faction: Variant = definition.get("faction_id")
	var domain: Variant = definition.get("control_domain")
	var footprint: Variant = definition.get("footprint_hexes")
	if typeof(craft_id) != TYPE_STRING or String(craft_id).strip_edges().is_empty() or typeof(faction) != TYPE_STRING or String(faction).strip_edges().is_empty() or domain not in ["player", "neutral", "enemy"] or typeof(footprint) != TYPE_ARRAY or _metadata.has(craft_id) or _inactive_actors.has(craft_id) or not _registry.can_register_actor(craft_id, flight): return {"ok":false, "reason":"invalid_actor"}
	var movement: Dictionary = flight.validate_area_transition(proposal, tick)
	if not movement.get("ok", false) or movement.next_pose.get("coordinate_frame") != "local" or movement.next_pose.get("motion_mode") != "tactical": return {"ok":false, "reason":"invalid_transition"}
	if String(movement.next_pose.get("space_area_id", "")).begins_with("atmosphere:") and movement.next_pose.get("assist_mode") != "coupled": return {"ok":false, "reason":"atmosphere_requires_coupled"}
	var cells: Array[Vector2i] = preview_footprint(movement.next_pose, footprint)
	var area_id := String(movement.next_pose.space_area_id)
	if cells.is_empty() or not _registry.query_cells(cells, area_id).is_empty() or not query_navigation_claims(cells, area_id).is_empty(): return {"ok":false, "reason":"occupied_or_invalid_footprint"}
	return {"ok":true, "craft_id":craft_id, "flight":flight, "area_id":area_id, "cells":cells.duplicate(), "indexed_revision":int(movement.next_pose.revision) + 1, "metadata":{"faction_id":faction, "control_domain":domain, "footprint_hexes":footprint.duplicate()}}

func validate_surface_air_admission(craft_id: String, flight: RefCounted, movement: Dictionary, footprint: Array) -> Dictionary:
	if not movement.get("ok", false) or flight == null or not _registry.can_register_actor(craft_id, flight): return {"ok":false, "reason":"invalid_actor"}
	var inactive: RefCounted = _inactive_actors.get(craft_id)
	if inactive != null and inactive != flight: return {"ok":false, "reason":"invalid_actor"}
	if inactive == null and _metadata.has(craft_id): return {"ok":false, "reason":"invalid_actor"}
	var metadata: Dictionary = _metadata.get(craft_id, {"faction_id":"player", "control_domain":"player", "footprint_hexes":footprint.duplicate()})
	if metadata.get("control_domain") != "player" or metadata.get("footprint_hexes") != footprint: return {"ok":false, "reason":"aircraft_metadata_changed"}
	var next: Dictionary = movement.next_pose
	var cells: Array[Vector2i] = preview_footprint(next, footprint)
	if cells.is_empty() or not _registry.query_cells(cells, next.space_area_id).is_empty() or not query_navigation_claims(cells, next.space_area_id).is_empty(): return {"ok":false, "reason":"occupied_or_invalid_footprint"}
	return {"ok":true, "craft_id":craft_id, "flight":flight, "area_id":next.space_area_id, "cells":cells, "indexed_revision":int(next.revision) + 1, "metadata":metadata.duplicate(true), "was_inactive":inactive != null}

func _publish_surface_air_admission(validation: Dictionary) -> void:
	_inactive_actors.erase(validation.craft_id)
	_publish_new_local_admission(validation)

func _publish_new_local_admission(validation: Dictionary) -> void:
	# Root-private tail following Flight preflight and a synchronous wing commit.
	_registry._publish_register_actor_cells(validation.craft_id, validation.flight, validation.area_id, validation.cells)
	_metadata[validation.craft_id] = validation.metadata.duplicate(true)
	_indexed_revisions[validation.craft_id] = validation.indexed_revision

func validate_deactivation(craft_id: String, expected_flight_revision: int, expected_area_revision: int) -> Dictionary:
	var flight: RefCounted = _registry.get_actor(craft_id)
	if flight == null: return {"ok":false, "reason":"unknown_actor"}
	var snapshot: Dictionary = flight.get_snapshot()
	if snapshot.revision != expected_flight_revision: return {"ok":false, "reason":"stale_flight_revision"}
	if snapshot.motion_mode != "tactical" or snapshot.coordinate_frame != "local": return {"ok":false, "reason":"not_active_local"}
	if get_area_revision(snapshot.space_area_id) != expected_area_revision: return {"ok":false, "reason":"stale_area_revision"}
	var cells: Array[Vector2i] = preview_footprint(snapshot, _metadata[craft_id].footprint_hexes)
	if cells.is_empty() or not _registry.actor_cells_match(craft_id, snapshot.space_area_id, cells):
		return {"ok":false, "reason":"stale_spatial_index"}
	return {"ok":true, "craft_id":craft_id, "flight":flight}

func validate_local_departure(craft_id: String, proposal: Dictionary, tick: int, expected_area_revision: int, expected_mode: String = "travel") -> Dictionary:
	var flight: RefCounted = _registry.get_actor(craft_id)
	if flight == null: return {"ok":false, "reason":"unknown_actor"}
	var snapshot: Dictionary = flight.get_snapshot()
	if snapshot.get("coordinate_frame") != "local" or snapshot.get("motion_mode") != "tactical" or get_area_revision(snapshot.space_area_id) != expected_area_revision: return {"ok":false, "reason":"departure_context_changed"}
	var cells: Array[Vector2i] = preview_footprint(snapshot, _metadata[craft_id].footprint_hexes)
	if cells.is_empty() or not _registry.actor_cells_match(craft_id, snapshot.space_area_id, cells): return {"ok":false, "reason":"stale_spatial_index"}
	for claimant in query_navigation_claims(cells, snapshot.space_area_id):
		if claimant != craft_id: return {"ok":false, "reason":"navigation_claimed"}
	var movement: Dictionary = flight.validate_area_transition(proposal, tick)
	if expected_mode not in ["travel", "grounded"] or not movement.get("ok", false) or movement.next_pose.get("coordinate_frame") != "strategic" or not String(movement.next_pose.get("space_area_id", "")).is_empty() or movement.next_pose.get("motion_mode") != expected_mode: return {"ok":false, "reason":"invalid_transition"}
	return {"ok":true, "craft_id":craft_id, "flight":flight}

func _publish_local_departure(validation: Dictionary) -> void:
	var craft_id: String = validation.craft_id
	_remove_navigation_claim(craft_id)
	_registry._publish_unregister_actor(craft_id)
	_metadata.erase(craft_id)
	_indexed_revisions.erase(craft_id)
	_flight_controls.erase(craft_id)
	_flight_status.erase(craft_id)

func _publish_deactivation(validation: Dictionary) -> void:
	# Root-private synchronous tail after fresh validation of every participant.
	var craft_id: String = validation.craft_id
	_remove_navigation_claim(craft_id)
	_registry._publish_unregister_actor(craft_id)
	_inactive_actors[craft_id] = validation.flight
	_indexed_revisions.erase(craft_id)
	_flight_controls.erase(craft_id)
	_flight_status.erase(craft_id)

func deactivate_actor(craft_id: String) -> Dictionary:
	# The flight owner must already be inactive; Root coordinates the full tail.
	var flight: RefCounted = _registry.get_actor(craft_id)
	if flight == null: return {"ok":false, "reason":"unknown_actor"}
	if flight.get_snapshot().get("motion_mode") != "inactive": return {"ok":false, "reason":"flight_not_inactive"}
	_publish_deactivation({"craft_id":craft_id, "flight":flight})
	return {"ok":true}

func preview_reactivation(craft_id: String, proposal: Dictionary, tick: int) -> Dictionary:
	var flight: RefCounted = _inactive_actors.get(craft_id)
	if flight == null: return {"ok":false, "reason":"unknown_actor"}
	var valid: Dictionary = flight.validate_space_activity_transition(proposal, tick)
	if not valid.get("ok", false): return valid
	var snapshot: Dictionary = flight.get_snapshot()
	snapshot.merge(proposal, true)
	var cells: Array[Vector2i] = preview_footprint(snapshot, _metadata[craft_id].footprint_hexes)
	if cells.is_empty(): return {"ok":false, "reason":"invalid_footprint"}
	if not _registry.query_cells(cells, snapshot.space_area_id).is_empty(): return {"ok":false, "reason":"occupied"}
	if not query_navigation_claims(cells, snapshot.space_area_id).is_empty(): return {"ok":false, "reason":"navigation_claimed"}
	return {"ok":true, "cells":cells}

func validate_reactivation(craft_id: String, proposal: Dictionary, tick: int) -> Dictionary:
	var flight: RefCounted = _inactive_actors.get(craft_id)
	if flight == null or not _registry.can_register_actor(craft_id, flight): return {"ok":false, "reason":"index_unavailable"}
	var preview: Dictionary = preview_reactivation(craft_id, proposal, tick)
	if not preview.get("ok", false): return preview
	var snapshot: Dictionary = flight.get_snapshot()
	return {"ok":true, "craft_id":craft_id, "flight":flight, "area_id":String(snapshot.space_area_id), "indexed_revision":int(snapshot.revision) + 1, "cells":preview.cells.duplicate()}

func _publish_reactivation(validation: Dictionary) -> void:
	# Root-private synchronous tail after Flight and registry preflight.
	var craft_id: String = validation.craft_id
	_registry._publish_register_actor_cells(craft_id, validation.flight, validation.area_id, validation.cells)
	_inactive_actors.erase(craft_id)
	_indexed_revisions[craft_id] = validation.indexed_revision

func reactivate_actor(craft_id: String) -> Dictionary:
	# Root must have revalidated body/gate and committed the flight activity first.
	var flight: RefCounted = _inactive_actors.get(craft_id)
	if flight == null: return {"ok":false, "reason":"unknown_actor"}
	var snapshot: Dictionary = flight.get_snapshot()
	if snapshot.motion_mode != "tactical": return {"ok":false, "reason":"flight_not_tactical"}
	var cells: Array[Vector2i] = preview_footprint(snapshot, _metadata[craft_id].footprint_hexes)
	if cells.is_empty(): return {"ok":false, "reason":"invalid_footprint"}
	if not _registry.query_cells(cells, snapshot.space_area_id).is_empty(): return {"ok":false, "reason":"occupied"}
	if not query_navigation_claims(cells, snapshot.space_area_id).is_empty(): return {"ok":false, "reason":"navigation_claimed"}
	if not _registry.register_actor(craft_id, flight): return {"ok":false, "reason":"index_failed"}
	if not _registry.update_actor_cells(craft_id, cells):
		_registry.unregister_actor(craft_id)
		return {"ok":false, "reason":"index_failed"}
	_inactive_actors.erase(craft_id)
	_indexed_revisions[craft_id] = int(snapshot.revision)
	return {"ok":true}

func remove_actor(craft_id: String) -> bool:
	# Runtime owner coordinates lifecycle and wing changes before invoking this.
	if _registry.get_actor(craft_id) == null and not _inactive_actors.has(craft_id): return false
	_remove_navigation_claim(craft_id)
	if _registry.get_actor(craft_id) != null and not _registry.unregister_actor(craft_id): return false
	_inactive_actors.erase(craft_id)
	_metadata.erase(craft_id)
	_indexed_revisions.erase(craft_id)
	_flight_controls.erase(craft_id)
	_flight_status.erase(craft_id)
	_ship_systems.erase(craft_id)
	return true

func query_cells(cells: Array[Vector2i], area_id: String = "") -> Array[String]:
	return _registry.query_cells(cells, area_id)

func get_area_revision(area_id: String) -> int:
	return _registry.get_area_revision(area_id) + int(_claim_revisions.get(area_id, 0))

func actor_cells_match(craft_id: String, area_id: String, cells: Array[Vector2i]) -> bool:
	return _registry.actor_cells_match(craft_id, area_id, cells)

func record_navigation_claim(craft_id: String, area_id: String, cells: Array[Vector2i]) -> Dictionary:
	# Owner-internal cell claims; scheduling/conflict resolution belongs to Root.
	var flight: RefCounted = _registry.get_actor(craft_id)
	if flight == null or String(flight.get_snapshot().get("space_area_id", "")) != area_id or cells.is_empty() or cells.size() > 512:
		return {"ok":false, "reason":"invalid_claim"}
	var snapshot: Dictionary = flight.get_snapshot()
	var unique := {}
	for cell in cells:
		if not AREA.contains(cell, snapshot): return {"ok":false, "reason":"invalid_claim"}
		unique[cell] = true
	var old: Dictionary = _navigation_claims.get(craft_id, {})
	if not old.is_empty() and old.area_id == area_id and old.cells == unique:
		return {"ok":true, "changed":false, "area_revision":get_area_revision(area_id)}
	_remove_navigation_claim(craft_id)
	_navigation_claims[craft_id] = {"area_id":area_id, "cells":unique}
	if not _claim_cells.has(area_id): _claim_cells[area_id] = {}
	for cell in unique:
		if not _claim_cells[area_id].has(cell): _claim_cells[area_id][cell] = {}
		_claim_cells[area_id][cell][craft_id] = true
	_claim_revisions[area_id] = int(_claim_revisions.get(area_id, 0)) + 1
	return {"ok":true, "changed":true, "area_revision":get_area_revision(area_id)}

func release_navigation_claim(craft_id: String) -> Dictionary:
	return {"ok":true, "changed":_remove_navigation_claim(craft_id)}

func query_navigation_claims(cells: Array[Vector2i], area_id: String) -> Array[String]:
	var found := {}
	var indexed: Dictionary = _claim_cells.get(area_id, {})
	for cell in cells:
		for craft_id in indexed.get(cell, {}): found[craft_id] = true
	var result: Array[String] = []
	result.assign(found.keys())
	result.sort()
	return result

func _remove_navigation_claim(craft_id: String) -> bool:
	if not _navigation_claims.has(craft_id): return false
	var old: Dictionary = _navigation_claims[craft_id]
	var area_id: String = old.area_id
	for cell in old.cells:
		_claim_cells[area_id][cell].erase(craft_id)
		if _claim_cells[area_id][cell].is_empty(): _claim_cells[area_id].erase(cell)
	if _claim_cells[area_id].is_empty(): _claim_cells.erase(area_id)
	_navigation_claims.erase(craft_id)
	_claim_revisions[area_id] = int(_claim_revisions.get(area_id, 0)) + 1
	return true

func update_actor_cell(craft_id: String, cell: Vector2i) -> bool:
	var flight: RefCounted = _registry.get_actor(craft_id)
	if flight == null: return false
	var cells: Array[Vector2i] = _occupied_cells(flight.get_snapshot(), _metadata[craft_id].footprint_hexes)
	if cells.is_empty() or not cells.has(cell): return false
	var updated: bool = _registry.update_actor_cells(craft_id, cells)
	if updated:
		_indexed_revisions[craft_id] = int(_registry.get_actor(craft_id).get_snapshot().revision)
	return updated

func get_flight_snapshots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for craft_id in _metadata:
		var flight: RefCounted = _registry.get_actor(craft_id)
		if flight == null: continue
		var snapshot: Dictionary = flight.get_snapshot()
		snapshot["footprint_hexes"] = _metadata[craft_id].footprint_hexes.duplicate()
		result.append(snapshot)
	return result

func get_area_flight_snapshots(area_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for craft_id in _registry.get_area_actor_ids(area_id):
		var flight: RefCounted = _registry.get_actor(craft_id)
		if flight == null: continue
		var snapshot: Dictionary = flight.get_snapshot()
		snapshot["footprint_hexes"] = _metadata[craft_id].footprint_hexes.duplicate()
		result.append(snapshot)
	return result

func preview_actor_cells(craft_id: String, proposal: Dictionary) -> Array[Vector2i]:
	var flight: RefCounted = _registry.get_actor(craft_id)
	if flight == null or not _metadata.has(craft_id): return []
	var snapshot: Dictionary = flight.get_snapshot()
	snapshot.merge(proposal, true)
	return _occupied_cells(snapshot, _metadata[craft_id].footprint_hexes)

func preview_footprint(snapshot: Dictionary, footprint: Array) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if typeof(snapshot.get("position_plane")) != TYPE_VECTOR2 or not snapshot.position_plane.is_finite() or typeof(snapshot.get("heading_rad")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(snapshot.heading_rad)):
		return empty
	if footprint.is_empty() or footprint.size() > 64: return empty
	var seen := {}
	for offset in footprint:
		if typeof(offset) != TYPE_VECTOR2I or seen.has(offset): return empty
		seen[offset] = true
	if not seen.has(Vector2i.ZERO): return empty
	return _occupied_cells(snapshot, footprint)

func _occupied_cells(snapshot: Dictionary, footprint: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if footprint.size() == 1 and footprint[0] == Vector2i.ZERO:
		var anchor: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(Vector2(snapshot.position_plane)))
		if AREA.contains(anchor, snapshot): result.append(anchor)
		return result
	var seen := {}
	for offset in footprint:
		var offset_plane: Vector2 = GRID.HEX.axial_to_plane(Vector2(offset)).rotated(float(snapshot.heading_rad))
		var center: Vector2 = Vector2(snapshot.position_plane) + offset_plane
		var nearest: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(center))
		var source: PackedVector2Array = _hex_polygon(center, float(snapshot.heading_rad))
		var candidates: Array[Vector2i] = [nearest]
		for direction in GRID.HEX.DIRECTIONS: candidates.append(nearest + direction)
		for cell in candidates:
			var target := _hex_polygon(GRID.HEX.axial_to_plane(Vector2(cell)), 0.0)
			var intersections: Array[PackedVector2Array] = Geometry2D.intersect_polygons(source, target)
			var overlaps := false
			for polygon in intersections:
				if polygon.size() >= 3 and absf(_polygon_area(polygon)) > 0.00000001:
					overlaps = true
					break
			if not overlaps: continue
			if not AREA.contains(cell, snapshot): return []
			if not seen.has(cell):
				seen[cell] = true
				result.append(cell)
	return result

func _hex_polygon(center: Vector2, heading: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for corner in 6:
		result.append(center + Vector2.from_angle(heading + PI / 6.0 + corner * PI / 3.0) * GRID.HEX.DEFAULT_RADIUS)
	return result

func _polygon_area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	var origin: Vector2 = polygon[0]
	for index in polygon.size():
		area += (polygon[index] - origin).cross(polygon[(index + 1) % polygon.size()] - origin)
	return area * 0.5

func sync_moved_actors() -> void:
	for craft_id in _metadata:
		var flight: RefCounted = _registry.get_actor(craft_id)
		if flight == null: continue
		var snapshot: Dictionary = flight.get_snapshot()
		if int(_indexed_revisions.get(craft_id, -1)) == int(snapshot.revision):
			continue
		var cell: Vector2i = GRID.cell_at(Vector2(snapshot.position_plane) / GRID.EXTENT)
		if AREA.contains(cell, snapshot):
			update_actor_cell(craft_id, cell)

func get_metadata(craft_id: String) -> Dictionary:
	return Dictionary(_metadata.get(craft_id, {})).duplicate(true)

func set_flight_control(craft_id: String, control: Dictionary) -> bool:
	if not _metadata.has(craft_id): return false
	_flight_controls[craft_id] = control.duplicate(true)
	return true

func clear_flight_control(craft_id: String) -> void:
	_flight_controls.erase(craft_id)
	_remove_navigation_claim(craft_id)

func get_flight_controls() -> Dictionary:
	return _flight_controls.duplicate(true)

func set_flight_status(craft_id: String, status: Dictionary) -> void:
	if _metadata.has(craft_id): _flight_status[craft_id] = status.duplicate(true)

func get_flight_status(craft_id: String) -> Dictionary:
	return Dictionary(_flight_status.get(craft_id, {})).duplicate(true)

# This covers only bound combat hardware, not the complete encounter, area
# registry, navigation claims, or flight bindings. The world transaction must
# reconstruct and validate those independently before publishing this block.
const CHECKPOINT_CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
class PreparedSystemsCheckpoint extends RefCounted:
	pass
var _systems_checkpoint_preparations: Dictionary = {}

func export_systems_checkpoint() -> Dictionary:
	var encoded := CHECKPOINT_CODEC.encode_value({"systems":_ship_systems.duplicate(true), "receipts":_ship_impact_receipts.duplicate(true)})
	if not encoded.ok: return encoded
	return {"schema":"space_systems_checkpoint.v1", "payload":encoded.value}

func prepare_systems_checkpoint_restore(state: Dictionary) -> Dictionary:
	if state.size() != 2 or not state.has_all(["schema", "payload"]) or state.schema != "space_systems_checkpoint.v1": return {"ok":false, "reason":"invalid_systems_checkpoint"}
	var decoded := CHECKPOINT_CODEC.decode_value(state.payload)
	if not decoded.ok or not decoded.value is Dictionary: return {"ok":false, "reason":"invalid_systems_checkpoint"}
	var data: Dictionary = decoded.value
	if data.size() != 2 or not data.has_all(["systems", "receipts"]) or not data.systems is Dictionary or not data.receipts is Dictionary or data.systems.size() != _ship_systems.size() or data.receipts.size() > 4096: return {"ok":false, "reason":"invalid_systems_checkpoint"}
	var actors := {}
	for id in data.systems:
		if typeof(id) != TYPE_STRING or not _ship_systems.has(id) or _registry.get_actor(id) == null or not data.systems[id] is Dictionary: return {"ok":false, "reason":"invalid_systems_checkpoint"}
		var entry: Dictionary = data.systems[id]
		if entry.size() != 3 or not entry.has_all(["stats", "state", "cooldowns"]) or not entry.stats is Dictionary or not entry.state is Dictionary or not entry.cooldowns is Dictionary or JSON.stringify(entry.stats, "", true) != JSON.stringify(_ship_systems[id].stats, "", true): return {"ok":false, "reason":"invalid_systems_checkpoint"}
		if not SHIP_SYSTEMS.advance(entry.stats, entry.state, 0.0).get("ok", false): return {"ok":false, "reason":"invalid_systems_checkpoint"}
		if not is_equal_approx(float(entry.state.hull_capacity), float(_ship_systems[id].state.hull_capacity)): return {"ok":false, "reason":"invalid_systems_checkpoint"}
		var slots := {}
		for weapon in entry.stats.get("weapons", []):
			if weapon is Dictionary and typeof(weapon.get("slot_id")) == TYPE_STRING: slots[weapon.slot_id] = true
		for slot in entry.cooldowns:
			var value: Variant = entry.cooldowns[slot]
			if typeof(slot) != TYPE_STRING or not slots.has(slot) or typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) < 0.0: return {"ok":false, "reason":"invalid_systems_checkpoint"}
		actors[id] = _registry.get_actor(id).get_instance_id()
	for id in data.receipts:
		var receipt: Variant = data.receipts[id]
		if typeof(id) != TYPE_STRING or id.is_empty() or not receipt is Dictionary or typeof(receipt.get("signature")) != TYPE_STRING or not receipt.get("result") is Dictionary: return {"ok":false, "reason":"invalid_systems_checkpoint"}
	for id in _systems_checkpoint_preparations.keys():
		if _systems_checkpoint_preparations[id].handle.get_ref() == null: _systems_checkpoint_preparations.erase(id)
	if _systems_checkpoint_preparations.size() >= 32: return {"ok":false, "reason":"systems_checkpoint_capacity"}
	var handle := PreparedSystemsCheckpoint.new()
	_systems_checkpoint_preparations[handle.get_instance_id()] = {"handle":weakref(handle), "source":export_systems_checkpoint(), "actors":actors, "data":data}
	return {"ok":true, "prepared":handle}

func validate_systems_checkpoint_restore(handle: RefCounted) -> Dictionary:
	if handle == null or not _systems_checkpoint_preparations.has(handle.get_instance_id()): return {"ok":false, "reason":"systems_checkpoint_unknown"}
	var prepared: Dictionary = _systems_checkpoint_preparations[handle.get_instance_id()]
	if prepared.handle.get_ref() != handle or prepared.source != export_systems_checkpoint(): return {"ok":false, "reason":"systems_checkpoint_changed"}
	for id in prepared.actors:
		var actor: RefCounted = _registry.get_actor(id)
		if actor == null or actor.get_instance_id() != prepared.actors[id]: return {"ok":false, "reason":"systems_checkpoint_changed"}
	return {"ok":true}

func commit_systems_checkpoint_restore(handle: RefCounted) -> Dictionary:
	var checked := validate_systems_checkpoint_restore(handle)
	if not checked.ok: return checked
	_publish_systems_checkpoint_restore(handle)
	return {"ok":true}

func _publish_systems_checkpoint_restore(handle: RefCounted) -> void:
	var prepared: Dictionary = _systems_checkpoint_preparations[handle.get_instance_id()]
	_systems_checkpoint_preparations.erase(handle.get_instance_id())
	_ship_systems = prepared.data.systems
	_ship_impact_receipts = prepared.data.receipts

# Snapshot preparation is detached. Only the world transaction may publish it.
const NAVIGATION_CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const NAVIGATION_GUIDANCE = preload("res://scripts/tactical/space_guidance_resolver.gd")
const NAVIGATION_FLIGHT = preload("res://scripts/tactical/space_flight_resolver.gd")

func export_navigation_checkpoint() -> Dictionary:
	var index: Dictionary = _registry.export_checkpoint_index()
	if index.get("schema") != "space_registry_checkpoint.v1": return _navigation_bad()
	var poses := {}
	for id in _metadata:
		var actor: RefCounted = _registry.get_actor(id)
		if actor == null: actor = _inactive_actors.get(id)
		if actor == null: return _navigation_bad()
		poses[id] = actor.get_snapshot()
		if not _inactive_actors.has(id) and (int(_indexed_revisions.get(id, -1)) != int(poses[id].revision) or not _registry.actor_cells_match(id, poses[id].space_area_id, preview_footprint(poses[id], _metadata[id].footprint_hexes))): return _navigation_bad()
	var controls := _flight_controls.duplicate(true)
	for id in controls:
		var control: Dictionary = controls[id]
		if control.has("mission_root"):
			if control.get("air_support_move") != true or not control.mission_root is WeakRef or not is_instance_valid(control.mission_root.get_ref()): return _navigation_bad()
			control.erase("mission_root")
		if control.has("equipment_owner_id"):
			if control.get("singleplayer_move") != true or typeof(control.equipment_owner_id) != TYPE_INT or control.equipment_owner_id == 0: return _navigation_bad()
			control.erase("equipment_owner_id")
	var claims := {}
	for id in _navigation_claims:
		claims[id] = {"area_id":_navigation_claims[id].area_id, "cells":_navigation_claims[id].cells.keys()}
	var inactive: Array = _inactive_actors.keys()
	inactive.sort()
	var encoded := NAVIGATION_CODEC.encode_value({"metadata":_metadata, "indexed_revisions":_indexed_revisions, "flight_snapshots":poses, "controls":controls, "status":_flight_status, "claims":claims, "claim_revisions":_claim_revisions, "inactive":inactive})
	if not encoded.ok: return _navigation_bad()
	return {"schema":"space_navigation_checkpoint.v1", "registry":index, "payload":encoded.value}


static func prepare_navigation_checkpoint_candidate(state: Dictionary, flights: Dictionary, control_bindings: Dictionary = {}) -> Dictionary:
	if state.size() != 3 or not state.has_all(["schema", "registry", "payload"]) or state.schema != "space_navigation_checkpoint.v1" or not state.registry is Dictionary or flights.size() > 4096: return _navigation_bad()
	var decoded := NAVIGATION_CODEC.decode_value(state.payload)
	if not decoded.ok or not decoded.value is Dictionary: return _navigation_bad()
	var data: Dictionary = decoded.value
	var maps := ["metadata", "indexed_revisions", "flight_snapshots", "controls", "status", "claims", "claim_revisions"]
	if data.size() != 8 or not data.has_all(maps + ["inactive"]) or not data.inactive is Array: return _navigation_bad()
	for key in maps:
		if not data[key] is Dictionary or data[key].size() > 4096: return _navigation_bad()
	var registry_proposal: Dictionary = REGISTRY.prepare_checkpoint_candidate(state.registry, flights)
	if not registry_proposal.get("ok", false): return _navigation_bad()
	var candidate: RefCounted = load("res://scripts/core/space_combat_state.gd").new()
	candidate._registry = registry_proposal.candidate
	var inactive := {}
	for id in data.inactive:
		if typeof(id) != TYPE_STRING or inactive.has(id) or not flights.has(id) or candidate._registry.get_actor(id) != null: return _navigation_bad()
		inactive[id] = true
	if data.metadata.size() != state.registry.actors.size() + inactive.size() or data.flight_snapshots.size() != data.metadata.size() or data.indexed_revisions.size() != state.registry.actors.size(): return _navigation_bad()
	var owners := {}
	for id in data.metadata:
		if typeof(id) != TYPE_STRING or id.strip_edges().is_empty() or not flights.has(id) or not flights[id] is RefCounted or not flights[id].has_method("get_snapshot") or not data.flight_snapshots.has(id): return _navigation_bad()
		var actor: RefCounted = flights[id]
		var pose: Dictionary = actor.get_snapshot()
		if owners.has(actor.get_instance_id()) or pose.get("craft_id") != id or data.flight_snapshots[id] != pose: return _navigation_bad()
		owners[actor.get_instance_id()] = true
		var metadata: Variant = data.metadata[id]
		if not metadata is Dictionary or metadata.size() != 3 or not metadata.has_all(["faction_id", "control_domain", "footprint_hexes"]) or typeof(metadata.faction_id) != TYPE_STRING or metadata.faction_id.strip_edges().is_empty() or metadata.control_domain not in ["player", "neutral", "enemy"] or not metadata.footprint_hexes is Array: return _navigation_bad()
		var cells: Array[Vector2i] = candidate.preview_footprint(pose, metadata.footprint_hexes)
		if cells.is_empty(): return _navigation_bad()
		if inactive.has(id):
			if pose.get("motion_mode") != "inactive" or pose.get("coordinate_frame") != "local": return _navigation_bad()
			candidate._inactive_actors[id] = actor
		else:
			if pose.get("motion_mode") == "inactive" or candidate._registry.get_actor(id) != actor or data.indexed_revisions.get(id, -1) != pose.revision or not candidate._registry.actor_cells_match(id, pose.space_area_id, cells): return _navigation_bad()
	for area in data.claim_revisions:
		if typeof(area) != TYPE_STRING or typeof(data.claim_revisions[area]) != TYPE_INT or data.claim_revisions[area] < 0: return _navigation_bad()
	for id in data.claims:
		var claim: Variant = data.claims[id]
		var actor: RefCounted = candidate._registry.get_actor(id)
		if actor == null or not claim is Dictionary or claim.size() != 2 or not claim.has_all(["area_id", "cells"]) or typeof(claim.area_id) != TYPE_STRING or not claim.cells is Array or claim.cells.is_empty() or claim.cells.size() > 512 or claim.area_id != actor.get_snapshot().space_area_id or int(data.claim_revisions.get(claim.area_id, 0)) <= 0: return _navigation_bad()
		var cells: Array[Vector2i] = []
		for cell in claim.cells:
			if typeof(cell) != TYPE_VECTOR2I or cells.has(cell): return _navigation_bad()
			cells.append(cell)
		for occupant in candidate._registry.query_cells(cells, claim.area_id):
			if occupant != id: return _navigation_bad()
		if not candidate.query_navigation_claims(cells, claim.area_id).is_empty() or not candidate.record_navigation_claim(id, claim.area_id, cells).get("ok", false): return _navigation_bad()
	for id in data.controls:
		var actor: RefCounted = candidate._registry.get_actor(id)
		if actor == null or not data.controls[id] is Dictionary: return _navigation_bad()
		var control: Dictionary = data.controls[id].duplicate(true)
		var pose: Dictionary = actor.get_snapshot()
		if not _navigation_control_valid(control, pose): return _navigation_bad()
		if control.get("singleplayer_move", false) or control.get("air_support_move", false):
			var context: Variant = control_bindings.get(id, {})
			if not context is Dictionary or not context.get("equipment_owner") is Object or not is_instance_valid(context.equipment_owner) or not context.equipment_owner.has_method("get_snapshot") or context.equipment_owner.get_snapshot(id) != control.equipment_snapshot or control.area_id != pose.space_area_id: return _navigation_bad()
			if not context.equipment_owner.has_method("get_space_flight_profile"): return _navigation_bad()
			var profile: Dictionary = context.equipment_owner.get_space_flight_profile(id)
			if not profile.get("ok", false) or profile.hull != control.hull or profile.power != control.power or profile.footprint_hexes != data.metadata[id].footprint_hexes or not is_equal_approx(float(profile.mass), float(pose.mass)): return _navigation_bad()
			if not data.claims.has(id): return _navigation_bad()
			var target_cells: Array[Vector2i] = candidate.preview_footprint(pose.merged({"position_plane":control.goal.target_plane}, true), data.metadata[id].footprint_hexes)
			if target_cells.is_empty() or target_cells.size() != data.claims[id].cells.size(): return _navigation_bad()
			for cell in target_cells:
				if not data.claims[id].cells.has(cell): return _navigation_bad()
			if control.get("singleplayer_move", false): control["equipment_owner_id"] = context.equipment_owner.get_instance_id()
			else:
				if not context.get("mission_root") is Node or not is_instance_valid(context.mission_root) or not context.mission_root.has_method("_air_support_motion_context_valid"): return _navigation_bad()
				control["mission_root"] = weakref(context.mission_root)
		candidate._flight_controls[id] = control
	for id in data.status:
		if candidate._registry.get_actor(id) == null or not data.status[id] is Dictionary: return _navigation_bad()
	candidate._metadata = data.metadata.duplicate(true)
	candidate._indexed_revisions = data.indexed_revisions.duplicate(true)
	candidate._flight_status = data.status.duplicate(true)
	candidate._claim_revisions = data.claim_revisions.duplicate(true)
	return {"ok":true, "candidate":candidate}


func validate_navigation_checkpoint_candidate(state: Dictionary, control_bindings: Dictionary = {}) -> Dictionary:
	# The world transaction calls this again immediately before its publish tail.
	var flights := {}
	for id in _metadata:
		flights[id] = _registry.get_actor(id) if not _inactive_actors.has(id) else _inactive_actors[id]
	var validated := prepare_navigation_checkpoint_candidate(state, flights, control_bindings)
	if not validated.get("ok", false): return _navigation_bad()
	return {"ok":true} if validated.candidate.export_navigation_checkpoint() == export_navigation_checkpoint() else _navigation_bad()


static func _navigation_control_valid(control: Dictionary, pose: Dictionary) -> bool:
	var allowed := ["goal", "intent", "hull", "power", "singleplayer_move", "air_support_move", "equipment_snapshot", "area_id", "orbit_auto_transit", "orbit_auto_braking", "orbit_auto_location_id", "orbit_auto_direction"]
	for key in control:
		if not allowed.has(key): return false
	if pose.get("motion_mode") != "tactical" or not control.get("hull") is Dictionary or not control.get("power") is Dictionary or control.has("goal") == control.has("intent"): return false
	for key in ["singleplayer_move", "air_support_move"]:
		if control.has(key) and typeof(control[key]) != TYPE_BOOL: return false
	if control.get("singleplayer_move", false) and control.get("air_support_move", false): return false
	var orbit_fields := ["orbit_auto_transit", "orbit_auto_braking", "orbit_auto_location_id", "orbit_auto_direction"]
	var has_orbit := false
	for field in orbit_fields: has_orbit = has_orbit or control.has(field)
	if has_orbit:
		# A separately validated Intent owner binds this route to its exact
		# craft/location. Braking is transient and is not yet restorable.
		if typeof(control.get("orbit_auto_transit")) != TYPE_BOOL or control.get("orbit_auto_transit") != true or control.has("orbit_auto_braking") or control.get("singleplayer_move") != true or control.get("air_support_move",false) or typeof(control.get("orbit_auto_location_id")) != TYPE_STRING or String(control.orbit_auto_location_id).is_empty() or typeof(control.get("orbit_auto_direction")) != TYPE_STRING or control.get("orbit_auto_direction") not in ["inbound","outbound"] or not String(pose.get("space_area_id","")).begins_with("orbit_approach:"): return false
	var intent: Dictionary = {}
	if control.has("goal"):
		if not control.goal is Dictionary: return false
		var guidance: Dictionary = NAVIGATION_GUIDANCE.resolve(pose, control.goal, control.hull, control.power)
		if not guidance.get("ok", false): return false
		intent = guidance.intent
	else:
		if not control.intent is Dictionary: return false
		intent = control.intent
	if control.get("singleplayer_move", false) or control.get("air_support_move", false):
		if not control.has("goal") or not control.get("equipment_snapshot") is Dictionary or typeof(control.get("area_id")) != TYPE_STRING: return false
	if control.get("air_support_move", false): intent = intent.merged({"assist_mode":"coupled"}, true)
	return NAVIGATION_FLIGHT.step(pose, intent, control.hull, control.power, 0.0, "atmosphere" if String(pose.space_area_id).begins_with("atmosphere:") else "space").get("ok", false)


static func _navigation_bad() -> Dictionary:
	return {"ok":false, "reason":"invalid_navigation_checkpoint"}
