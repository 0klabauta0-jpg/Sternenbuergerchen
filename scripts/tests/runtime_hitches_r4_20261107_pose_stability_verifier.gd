extends "res://scripts/tests/runtime_hitches_r4_20261107_muzzle_anchor_verifier.gd"
## Existing imported shoot-hold oracle after ordinary animation advancement.

func run() -> void:
	var view: Node = VIEW.new()
	root.add_child(view)
	view.call("configure_from_map", MAP.call("create_empty", "r4_pose_owner", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2))
	var units: Array = []
	for spec in [["r4_pose_friendly", "team_alpha"], ["enemy_delta", "team_bravo"]]:
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
	var before: Dictionary = actor_state(units)
	var events: Array = []
	for unit in units:
		events.append({"event_id": "r4_hold_" + String(unit.call("get_unit_id")), "tick": 10, "attacker_unit_id": unit.call("get_unit_id"), "attacker_team_id": unit.call("get_team_id"), "target_unit_id": "target", "weapon_id": "rifle", "attacker_position": unit.global_position, "target_position": unit.global_position + Vector2(160.0, 0.0)})
	view.call("set_order_visual_payload", {"fire_event_dicts": events})
	await frames(2) # First ordinary visual update applied the imported hold.
	var clip_start: Dictionary = {}
	for sample_frame in [0, 3, 10]:
		if sample_frame > 0:
			await frames(3 if sample_frame == 3 else 7)
		for unit in units:
			var id: String = String(unit.call("get_unit_id"))
			var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get(id) as Node3D
			var runtime: Dictionary = view.call("_get_unit_proxy_runtime", id, proxy)
			var skeleton: Skeleton3D = runtime.get("skeleton") as Skeleton3D
			var player: AnimationPlayer = runtime.get("animation_player") as AnimationPlayer
			var weapon: Node3D = runtime.get("weapon_node") as Node3D
			var pose: Animation = view.call("_get_unit_weapon_upper_body_pose_animation", player) as Animation
			var expected: Dictionary = view.call("_get_unit_weapon_upper_body_pose_rotations", pose) if pose != null else {}
			var maximum_error: float = 0.0
			var checked_bones: int = 0
			for bone_name in expected:
				var index: int = skeleton.find_bone(String(bone_name)) if skeleton != null else -1
				if index < 0:
					continue
				maximum_error = maxf(maximum_error, rad_to_deg(skeleton.get_bone_pose_rotation(index).angle_to(Quaternion(expected[bone_name]))))
				checked_bones += 1
			check(checked_bones > 0 and maximum_error < 0.1, "%s imported hold bones stay exact after frame%d (max drift %.3fdeg)" % [id, sample_frame, maximum_error])
			check(weapon != null and weapon.position.distance_to(Vector3(weapon.get_meta("unit_aim_pose_base_position", Vector3.INF))) < 0.002, "%s weapon root stays at the original socket in frame%d" % [id, sample_frame])
			if sample_frame == 0:
				clip_start[id] = player.current_animation_position if player != null else -1.0
			if sample_frame == 10:
				check(player != null and player.is_playing() and player.current_animation_position > float(clip_start.get(id, INF)), id + " clip keeps advancing while its imported hold is owned")
			print("R4_POSE_STABILITY_SAMPLE ", JSON.stringify({"unit": id, "sample_frame": sample_frame, "process_frame": Engine.get_process_frames(), "checked_bones": checked_bones, "max_drift_degrees": maximum_error, "animation_position": player.current_animation_position if player != null else -1.0, "pose_active_meta": proxy.get_meta("unit_weapon_upper_body_pose_active", false)}))
	check(actor_state(units) == before, "Visual pose ownership leaves actor state and authority unchanged")
	view.queue_free()
	for unit in units:
		unit.queue_free()
	await frames(2)
	print("R4_POSE_STABILITY: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_POSE_STABILITY_PASS")
	quit(1 if failed else 0)
