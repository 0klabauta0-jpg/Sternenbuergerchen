extends "res://scripts/tests/runtime_hitches_r4_20261107_muzzle_anchor_verifier.gd"
## Actual imported human/weapon, synthetic renderer feed only. No actor poses,
## authority, HP, positions or gameplay-facing are modified after construction.

func run() -> void:
	var view: Node = VIEW.new()
	root.add_child(view)
	view.call("configure_from_map", MAP.call("create_empty", "r4_pose_feed", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2))
	var unit: Node2D = UNIT.new()
	unit.set("unit_id", "r4_pose_source")
	unit.set("team_id", "team_alpha")
	unit.set("weapon_1_id", "rifle")
	unit.set("weapon_2_id", "none")
	root.add_child(unit)
	unit.position = Vector2(96.0, 128.0)
	view.call("set_unit_nodes", [unit])
	await frames(10)
	var before: Dictionary = actor_state([unit])
	var current: Dictionary = fire("r4_pose_current_100", "r4_pose_source", 100, Vector2.RIGHT)
	var history: Dictionary = fire("r4_pose_history_1", "r4_pose_source", 1, Vector2.LEFT)
	history["presentation_history_only"] = true
	view.call("set_order_visual_payload", {"fire_event_dicts": [current, history]})
	await frames(4)
	assert_pose(view, unit, current, "Appended old history cannot own the actual figure's aim")
	view.call("set_order_visual_payload", {"fire_event_dicts": [history]})
	await frames(4)
	var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get("r4_pose_source") as Node3D
	check(proxy != null and String(proxy.get_meta("unit_aim_pose_source_event_id", "")).is_empty(), "History-only feed leaves no active fire-event pose source")
	check(proxy != null and not bool(proxy.get_meta("unit_aim_pose_active", false)), "History-only feed reads the real lowered runtime posture instead of inventing shooting")
	var newest: Dictionary = fire("r4_pose_newest_200", "r4_pose_source", 200, Vector2.LEFT)
	var older: Dictionary = fire("r4_pose_older_199", "r4_pose_source", 199, Vector2.RIGHT)
	view.call("set_order_visual_payload", {"fire_event_dicts": [newest, older]})
	await frames(4)
	assert_pose(view, unit, newest, "Shuffled regular events choose the newest authoritative tick")
	var eight: Array = [fire("r4_pose_front_old_300", "r4_pose_source", 300, Vector2.RIGHT)]
	for index in range(1, 8):
		eight.append(fire("r4_pose_fixed_%d" % index, "r4_fixed_source_%d" % index, 300 + index, Vector2.RIGHT))
	view.call("set_order_visual_payload", {"fire_event_dicts": eight})
	await frames(4)
	assert_pose(view, unit, Dictionary(eight[0]), "Eight-source fixture initially applies its first real source")
	var heavy_signature: String = String(view.get("_order_visual_signature"))
	var order_ids: Array = order_node_ids(view)
	check(not order_ids.is_empty(), "Heavy trace fixture contains actual unrelated order nodes")
	var fresh_first: Dictionary = fire("r4_pose_front_new_308", "r4_pose_source", 308, Vector2.LEFT)
	var replaced: Array = eight.duplicate(true)
	replaced[0] = fresh_first
	view.call("set_order_visual_payload", {"fire_event_dicts": replaced})
	await frames(4)
	check(String(view.get("_order_visual_signature")) == heavy_signature, "Refreshing only the early source leaves the last-three heavy signature unchanged")
	check(order_node_ids(view) == order_ids, "Refreshing only the early source preserves unrelated heavy order node identities")
	assert_pose(view, unit, fresh_first, "Full-eight input refresh reaches the actual pose even with fixed last three")
	check(actor_state([unit]) == before, "All renderer-feed cases preserve the original actor state and gameplay authority")
	view.queue_free()
	unit.queue_free()
	await frames(2)
	print("R4_FIRE_POSE_FEED: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_FIRE_POSE_FEED_PASS")
	quit(1 if failed else 0)

func fire(id: String, source: String, tick: int, direction: Vector2) -> Dictionary:
	return {"event_id": id, "tick": tick, "attacker_unit_id": source, "attacker_team_id": "team_alpha", "target_unit_id": "r4_target_" + ("east" if direction.x > 0.0 else "west"), "target_team_id": "team_bravo", "weapon_id": "rifle", "attacker_position": Vector2(96.0, 128.0), "target_position": Vector2(96.0, 128.0) + direction * 160.0}

func assert_pose(view: Node, unit: Node2D, expected: Dictionary, label: String) -> void:
	var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get("r4_pose_source") as Node3D
	check(proxy != null and String(proxy.get_meta("unit_aim_pose_source_event_id", "")) == String(expected.event_id), label + ": actual proxy event ID")
	var weapon: Node3D = view.call("_find_unit_blaster_visual_node", proxy) as Node3D if proxy != null else null
	var muzzle: Variant = weapon.get_meta("unit_muzzle_socket", null) if weapon != null else null
	var direction: Vector3 = (Vector3(view.call("_world_to_3d_position", Vector2(expected.target_position), 0.0)) - Vector3(view.call("_world_to_3d_position", unit.global_position, 0.0))).normalized()
	var dot: float = (-muzzle.global_transform.basis.z.normalized()).dot(direction) if is_instance_valid(muzzle) else -1.0
	check(is_instance_valid(muzzle) and dot > 0.5, label + ": actual original weapon mesh front (dot %.3f)" % dot)
	print("R4_FIRE_POSE_FEED_SAMPLE ", JSON.stringify({"label": label, "expected_event": expected.event_id, "actual_event": proxy.get_meta("unit_aim_pose_source_event_id", "") if proxy != null else "missing", "weapon_front_dot": dot}))

func order_node_ids(view: Node) -> Array:
	var result: Array = []
	var order_root: Node = view.get("_order_root") as Node
	if order_root != null:
		for node in order_root.get_children():
			result.append(node.get_instance_id())
	return result
