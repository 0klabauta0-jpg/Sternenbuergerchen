extends SceneTree
## Renderer-only event fixtures. Not evidence of a real gameplay shot or pixels.
const VIEW: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view: Node = VIEW.new()
	root.add_child(view)
	var map_data: RefCounted = MAP.call("create_empty", "r4_muzzle_lifetime", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2)
	view.call("configure_from_map", map_data)
	await frames(4)
	check(pulses(view).is_empty(), "No event creates no firing feedback")
	var events: Array = []
	for index in range(4):
		events.append(event("r4_parallel_%d" % index, "alpha_%d" % index, "team_alpha", Vector2(96.0 + index * 24.0, 128.0)))
	var start_msec: int = Time.get_ticks_msec()
	view.call("set_order_visual_payload", {"fire_event_dicts": events})
	await frames(2)
	var before: Dictionary = pulse_identities(view)
	check(Time.get_ticks_msec() - start_msec < 300, "Fixture observes the live flash window")
	check(before.size() == 4, "Every one of four visible simultaneous sources receives short firing feedback")
	for node in pulses(view):
		var flash: Sprite3D = node.get_node_or_null("MuzzleFlash") as Sprite3D
		check(flash != null and flash.visible and flash.texture != null, "Live feedback retains its textured visible flash: " + node.name)
	# The regular preview setter rebuilds order geometry. An active muzzle is
	# independent transient event feedback, so this must not replace its node.
	view.call("set_area_order_preview_payload", {})
	await frames(2)
	check(not before.is_empty() and pulse_identities(view) == before, "Unrelated order-preview rebuilding preserves active pulse objects and lifetimes")
	view.call("set_order_visual_payload", {})
	await frames(2)
	check(pulse_identities(view) == before, "Rolling events out of the retained order snapshot does not cut their active feedback short")
	await create_timer(0.82).timeout
	check(pulses(view).is_empty(), "Feedback expires without another event")
	view.call("set_order_visual_payload", {"fire_event_dicts": events, "phase_index": 2})
	await frames(2)
	check(pulses(view).is_empty(), "The same retained event IDs never replay expired feedback")
	# A dedicated source gate remains required when feedback has its own root.
	var enemy_event: Dictionary = event("r4_enemy_source", "enemy_r4", "team_bravo", Vector2(192.0, 160.0))
	view.call("set_fog_of_war_state", fog(["enemy_r4"]))
	view.call("set_order_visual_payload", {"fire_event_dicts": [enemy_event]})
	await frames(2)
	check(pulses(view).size() == 1, "A currently known hostile source may display its actual event feedback")
	view.call("set_fog_of_war_state", fog([]))
	await frames(2)
	check(pulses(view).is_empty(), "Losing source visibility hides an already active hostile pulse")
	var hidden_event: Dictionary = event("r4_unknown_source", "unknown_enemy_r4", "team_bravo", Vector2(192.0, 160.0))
	view.call("set_fog_of_war_state", fog(["visible_target_r4"]))
	view.call("set_order_visual_payload", {"fire_event_dicts": [hidden_event]})
	await frames(2)
	check(pulses(view).is_empty(), "A visible target cannot reveal a still unknown shooter's source")
	view.queue_free()
	await frames(2)
	print("R4_MUZZLE_LIFETIME: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_MUZZLE_LIFETIME_PASS")
	quit(1 if failed else 0)

func event(id: String, source_id: String, team_id: String, position: Vector2) -> Dictionary:
	return {"event_id": id, "event_type": "weapon_fire", "attacker_unit_id": source_id, "attacker_team_id": team_id, "target_unit_id": "visible_target_r4", "target_team_id": "team_alpha" if team_id != "team_alpha" else "team_bravo", "weapon_id": "rifle", "attacker_position": position, "target_position": Vector2(256.0, 192.0)}

func fog(visible_ids: Array) -> Dictionary:
	return {"mode": "known_terrain", "team_id": "team_alpha", "terrain_knowledge": {"visible_tile_ids": []}, "current_visibility": {"visible_target_ids": visible_ids, "visible_event_ids": []}}

func pulses(view: Node) -> Array[Node]:
	var result: Array[Node] = []
	for node in view.find_children("WeaponFireReadablePulse_*", "", true, false):
		if node is Node3D and (node as Node3D).is_visible_in_tree() and not node.is_queued_for_deletion():
			result.append(node)
	return result

func pulse_identities(view: Node) -> Dictionary:
	var result: Dictionary = {}
	for node in pulses(view):
		result[String(node.name)] = node.get_instance_id()
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
