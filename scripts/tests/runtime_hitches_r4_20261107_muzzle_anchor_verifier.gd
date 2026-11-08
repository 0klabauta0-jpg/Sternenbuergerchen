extends SceneTree
## Real imported model/mesh/pose transforms. Not native pixel/physical-shot proof.
const VIEW: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const UNIT: GDScript = preload("res://scripts/npc/test_unit.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view: Node = VIEW.new()
	root.add_child(view)
	view.call("configure_from_map", MAP.call("create_empty", "r4_muzzle_anchor", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2))
	var units: Array = []
	for spec in [["r4_front_friendly", "team_alpha"], ["enemy_delta", "team_bravo"]]:
		var unit: Node2D = UNIT.new()
		unit.set("unit_id", String(spec[0]))
		unit.set("team_id", String(spec[1]))
		unit.set("weapon_1_id", "rifle")
		unit.set("weapon_2_id", "none")
		root.add_child(unit)
		unit.position = Vector2(96.0 + units.size() * 64.0, 128.0)
		units.append(unit)
	view.call("set_unit_nodes", units)
	await frames(10)
	var actor_before: Dictionary = actor_state(units)
	var original_weapons: Dictionary = {}
	for unit in units:
		original_weapons[String(unit.call("get_unit_id"))] = weapon_state(view, unit)
	for direction_index in range(2):
		var events: Array = []
		for unit in units:
			var id: String = String(unit.call("get_unit_id"))
			events.append({"event_id": "r4_front_%s_%d" % [id, direction_index], "tick": 10 + direction_index * 20, "attacker_unit_id": id, "attacker_team_id": unit.call("get_team_id"), "target_unit_id": "target", "weapon_id": "rifle", "attacker_position": unit.global_position, "target_position": unit.global_position + (Vector2(160.0, 0.0) if direction_index == 0 else Vector2(0.0, 160.0))})
		view.call("set_order_visual_payload", {"fire_event_dicts": events})
		trace_pose(view, units, "event0_direction%d" % direction_index)
		await frames(3)
		trace_pose(view, units, "event3_direction%d" % direction_index)
		await frames(7)
		trace_pose(view, units, "event10_direction%d" % direction_index)
		# Headless frames can span only a few real milliseconds. Observe the
		# ordinary visual yaw reaching its event direction before judging the
		# imported weapon axes; never write a model/actor rotation to settle it.
		var deadline_msec: int = Time.get_ticks_msec() + 1500
		var settled: bool = false
		while Time.get_ticks_msec() < deadline_msec and not settled:
			await process_frame
			settled = true
			for unit in units:
				var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get(String(unit.call("get_unit_id"))) as Node3D
				var desired_yaw: float = float(view.call("_get_unit_world_direction_yaw", unit.global_position, Vector2(events[units.find(unit)].target_position), proxy.rotation_degrees.y))
				settled = settled and absf(wrapf(desired_yaw - proxy.rotation_degrees.y, -180.0, 180.0)) < 0.5
		check(settled, "Ordinary event-driven visual yaw settles before front-axis assessment: %d" % direction_index)
		trace_pose(view, units, "settled_direction%d" % direction_index)
		# A second real renderer-fixture event in the SAME direction provides a
		# fresh flash window after the preceding direction has actually settled.
		for fixture_event in events:
			fixture_event["event_id"] = String(fixture_event.event_id) + "_settled"
			fixture_event["tick"] = 11 + direction_index * 20
		view.call("set_order_visual_payload", {"fire_event_dicts": events})
		await frames(3)
		var feedback: Dictionary = view.call("get_weapon_fire_feedback_snapshot")
		for unit in units:
			var id: String = String(unit.call("get_unit_id"))
			var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get(id) as Node3D
			var weapon: Node3D = view.call("_find_unit_blaster_visual_node", proxy) as Node3D
			var muzzle: Variant = weapon.get_meta("unit_muzzle_socket", null) if weapon != null else null
			check(is_instance_valid(muzzle) and muzzle.get_parent() is MeshInstance3D, id + " muzzle is attached to the actual primary weapon mesh")
			if not is_instance_valid(muzzle):
				continue
			var entry: Dictionary = view.call("_get_unit_visual_entry", unit)
			var local_position: Vector3 = view.call("_get_vector3_from_variant", entry.get("muzzle_mesh_local_position"), Vector3.ZERO)
			check(muzzle.position.is_equal_approx(local_position), id + " uses the GLB front coordinate through the existing attachment mapping")
			var sample: Dictionary = {}
			for item in Array(feedback.get("entries", [])):
				if String(Dictionary(item).get("attacker_unit_id", "")) == id:
					sample = Dictionary(item)
			check(String(sample.get("anchor_kind", "")) == "weapon_mesh_muzzle", id + " uses a real weapon muzzle rather than the catalog/head fallback")
			check(bool(sample.get("flash_visible", false)) and Vector3(sample.get("muzzle_position", Vector3.INF)).distance_to(muzzle.global_position) < 0.003, id + " live flash follows actual socket, animated pose and mesh transforms")
			print("R4_MUZZLE_ANCHOR_SAMPLE ", JSON.stringify({"unit": id, "direction_index": direction_index, "sample": sample, "weapon_local_position": weapon.position, "muzzle_local_position": muzzle.position, "parent_transform": muzzle.get_parent().global_transform}))
			check(float(sample.get("weapon_forward_dot", -1.0)) > 0.5, id + " actual weapon-front direction points along the current fire direction")
	view.call("set_order_visual_payload", {})
	await frames(3)
	for unit in units:
		var id: String = String(unit.call("get_unit_id"))
		check(weapon_state(view, unit) == original_weapons[id], id + " empty event feed restores exact original idle mesh/root/socket/scale")
	var repeated_events: Array = []
	for unit in units:
		var id: String = String(unit.call("get_unit_id"))
		repeated_events.append({"event_id": "r4_front_again_" + id, "tick": 50, "attacker_unit_id": id, "attacker_team_id": unit.call("get_team_id"), "target_unit_id": "target", "weapon_id": "rifle", "attacker_position": unit.global_position, "target_position": unit.global_position + Vector2(160.0, 0.0)})
	view.call("set_order_visual_payload", {"fire_event_dicts": repeated_events})
	await frames(3)
	var repeated_count: int = 0
	for item in Array(Dictionary(view.call("get_weapon_fire_feedback_snapshot")).get("entries", [])):
		var sample: Dictionary = Dictionary(item)
		if String(sample.get("event_id", "")).begins_with("r4_front_again_"):
			repeated_count += 1
			check(float(sample.get("weapon_forward_dot", -1.0)) > 0.5, String(sample.get("attacker_unit_id", "")) + " repeated aim corrects the front again without accumulated rotation")
	check(repeated_count == units.size(), "Repeated aim has a genuinely fresh event pulse for every original source")
	view.call("set_order_visual_payload", {})
	await frames(3)
	for unit in units:
		var id: String = String(unit.call("get_unit_id"))
		check(weapon_state(view, unit) == original_weapons[id], id + " second aim exit restores original attachment values again")
	check(actor_state(units) == actor_before, "Presentation event/pose handling preserves original actor health, position and runtime state")
	view.queue_free()
	for unit in units:
		unit.queue_free()
	await frames(2)
	print("R4_MUZZLE_ANCHOR: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_MUZZLE_ANCHOR_PASS")
	quit(1 if failed else 0)

func actor_state(units: Array) -> Dictionary:
	var result: Dictionary = {}
	for unit in units:
		result[String(unit.call("get_unit_id"))] = {"position": unit.position, "health": unit.call("get_health"), "runtime": unit.call("get_runtime_status").call("to_dict")}
	return result

func weapon_state(view: Node, unit: Node) -> Dictionary:
	var id: String = String(unit.call("get_unit_id"))
	var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get(id) as Node3D
	var weapon: Node3D = view.call("_find_unit_blaster_visual_node", proxy) as Node3D
	if weapon == null:
		return {}
	var children: Dictionary = {}
	for child in weapon.get_children():
		if child is Node3D:
			children[str(child.get_instance_id())] = {"position": child.position, "rotation": child.rotation_degrees, "scale": child.scale}
	return {"id": weapon.get_instance_id(), "parent_id": weapon.get_parent().get_instance_id(), "position": weapon.position, "rotation": weapon.rotation_degrees, "scale": weapon.scale, "children": children}

func trace_pose(view: Node, units: Array, phase: String) -> void:
	for unit in units:
		var id: String = String(unit.call("get_unit_id"))
		var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get(id) as Node3D
		var runtime: Dictionary = view.call("_get_unit_proxy_runtime", id, proxy)
		var skeleton: Skeleton3D = runtime.get("skeleton") as Skeleton3D
		var player: AnimationPlayer = runtime.get("animation_player") as AnimationPlayer
		var weapon: Node3D = runtime.get("weapon_node") as Node3D
		var pose: Animation = view.call("_get_unit_weapon_upper_body_pose_animation", player) as Animation
		var expected: Dictionary = view.call("_get_unit_weapon_upper_body_pose_rotations", pose) if pose != null else {}
		var bone_rows: Array = []
		var max_drift_degrees: float = 0.0
		if skeleton != null:
			for bone_name in expected:
				var index: int = skeleton.find_bone(String(bone_name))
				if index < 0:
					continue
				var actual: Quaternion = skeleton.get_bone_pose_rotation(index)
				var wanted: Quaternion = expected[bone_name]
				var drift: float = rad_to_deg(actual.angle_to(wanted))
				max_drift_degrees = maxf(max_drift_degrees, drift)
				bone_rows.append({"name": bone_name, "actual": actual, "imported_hold": wanted, "drift_degrees": drift})
		var muzzle: Variant = weapon.get_meta("unit_muzzle_socket", null) if weapon != null else null
		print("R4_MUZZLE_POSE_TRACE ", JSON.stringify({"phase": phase, "frame": Engine.get_process_frames(), "wall_msec": Time.get_ticks_msec(), "unit": id, "proxy_yaw": proxy.rotation_degrees.y, "pose_active_meta": proxy.get_meta("unit_weapon_upper_body_pose_active", false), "pose_source": proxy.get_meta("unit_weapon_upper_body_pose_source_animation", ""), "event_id": proxy.get_meta("unit_aim_pose_source_event_id", ""), "animation": player.current_animation if player != null else "", "animation_position": player.current_animation_position if player != null else 0.0, "muzzle_forward": -muzzle.global_transform.basis.z.normalized() if is_instance_valid(muzzle) else Vector3.ZERO, "max_imported_hold_drift_degrees": max_drift_degrees, "bones": bone_rows}))

func frames(count: int) -> void:
	for _frame in range(count):
		await process_frame

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", message)
