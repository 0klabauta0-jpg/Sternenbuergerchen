extends SceneTree
## Presentation-only negative boundaries. Synthetic dictionaries prove no shot.
const VIEW: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view: Node = VIEW.new()
	root.add_child(view)
	view.call("configure_from_map", map_data("r4_context_a"))
	await frames(4)
	var hidden: Dictionary = fire_event("r4_hidden_old", "enemy_r4", "team_bravo")
	view.call("set_fog_of_war_state", fog([]))
	view.call("set_order_visual_payload", {"fire_event_dicts": [hidden]})
	await frames(2)
	check(pulse_count(view) == 0, "An unknown source is not exposed by event receipt")
	await create_timer(0.82).timeout
	view.call("set_fog_of_war_state", fog(["enemy_r4"]))
	await frames(2)
	check(pulse_count(view) == 0, "Later source visibility cannot fire an old retained unknown event as fresh")
	view.call("configure_from_map", map_data("r4_context_b"))
	await frames(2)
	check(pulse_count(view) == 0, "A new map context never replays the previous order payload during map rebuilding")
	var new_context_event: Dictionary = fire_event("r4_same_id", "alpha", "team_alpha")
	view.call("set_fog_of_war_state", {"mode": "off", "team_id": "team_alpha"})
	view.call("set_order_visual_payload", {"fire_event_dicts": [new_context_event]})
	await frames(2)
	check(pulse_count(view) == 1, "A genuine new payload event is admitted in the new map context")
	await create_timer(0.82).timeout
	view.call("configure_from_map", map_data("r4_context_c"))
	await frames(2)
	check(pulse_count(view) == 0, "Context reset does not replay a previously retained friendly event")
	view.call("set_order_visual_payload", {"fire_event_dicts": [new_context_event]})
	await frames(2)
	check(pulse_count(view) == 1, "A new mission receipt can legitimately reuse its own event ID")
	var first_batch: Array = []
	var second_batch: Array = []
	for index in range(8):
		first_batch.append(fire_event("r4_source_a_%d" % index, "source_a_%d" % index, "team_alpha"))
		second_batch.append(fire_event("r4_source_b_%d" % index, "source_b_%d" % index, "team_alpha"))
	view.call("set_order_visual_payload", {"fire_event_dicts": first_batch})
	await frames(2)
	check(pulse_count(view) == 8, "All eight retained visible sources receive lightweight feedback")
	view.call("set_order_visual_payload", {"fire_event_dicts": second_batch})
	await frames(2)
	check(pulse_count(view) == 8, "A second batch cannot grow active transient feedback beyond eight sources")
	var bursts: Array = []
	for index in range(4):
		bursts.append(fire_event("r4_burst_%d" % index, "same_source_r4", "team_alpha"))
	view.call("set_order_visual_payload", {"fire_event_dicts": bursts})
	await frames(2)
	var same_source_count: int = 0
	for node in view.find_children("WeaponFireReadablePulse_r4_burst_*", "", true, false):
		if node is Node3D and node.is_visible_in_tree() and not node.is_queued_for_deletion():
			same_source_count += 1
	check(same_source_count == 1, "Repeated shots by one source retain one newest active pulse instead of stacking icons")
	view.queue_free()
	await frames(2)
	print("R4_MUZZLE_CONTEXT: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_MUZZLE_CONTEXT_PASS")
	quit(1 if failed else 0)

func map_data(id: String) -> RefCounted:
	return MAP.call("create_empty", id, Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2)

func fire_event(id: String, source: String, team: String) -> Dictionary:
	return {"event_id": id, "tick": 7, "event_type": "weapon_fire", "attacker_unit_id": source, "attacker_team_id": team, "target_unit_id": "target_r4", "target_team_id": "team_bravo" if team == "team_alpha" else "team_alpha", "weapon_id": "rifle", "attacker_position": Vector2(96.0, 128.0), "target_position": Vector2(224.0, 128.0)}

func fog(ids: Array) -> Dictionary:
	return {"mode": "known_terrain", "team_id": "team_alpha", "terrain_knowledge": {"visible_tile_ids": []}, "current_visibility": {"visible_target_ids": ids, "visible_event_ids": []}}

func pulse_count(view: Node) -> int:
	var result: int = 0
	for node in view.find_children("WeaponFireReadablePulse_*", "", true, false):
		if node is Node3D and node.is_visible_in_tree() and not node.is_queued_for_deletion():
			result += 1
	return result

func frames(count: int) -> void:
	for _frame in range(count):
		await process_frame

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", message)
