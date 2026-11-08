extends SceneTree
## Read-only normal mission diagnostic, matching TASK174's start and identities.
## No actor/posture/facing/clock/command writes and no orientation acceptance.
const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
var passed := 0
var failed := 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var scene := MISSION.instantiate()
	root.add_child(scene)
	for _frame in range(18):
		await process_frame
	for _frame in range(4):
		await physics_frame
	var view := scene.get_node_or_null("Primary3DView")
	var simulation := scene.get_node_or_null("SimulationRoot")
	check(view != null and simulation != null, "Normal authored mission exposes real visual and simulation owners")
	if view == null or simulation == null:
		scene.queue_free()
		await process_frame
		finish()
		return
	var before := owner_state(view, simulation)
	var sampled := 0
	for unit in Array(view.get("_unit_nodes")):
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var id := String(unit.call("get_unit_id"))
		if id not in ["unit_alpha", "enemy_delta"]:
			continue
		var proxy := Dictionary(view.get("_unit_proxies_by_id")).get(id) as Node3D
		var weapon := find_visual(proxy, "BlasterVisual_") as Node3D
		var mesh := first_mesh(weapon)
		check(proxy != null and weapon != null and mesh != null, id + " has the actual existing proxy, weapon and visible primary mesh")
		if proxy == null or weapon == null or mesh == null:
			continue
		var runtime: Dictionary = view.call("_get_unit_proxy_runtime", id, proxy)
		var player := runtime.get("animation_player") as AnimationPlayer
		var skeleton := runtime.get("skeleton") as Skeleton3D
		var hand: Dictionary = {}
		if skeleton != null:
			for name in ["RightHand", "right_hand", "rightHand", "mixamorig:RightHand"]:
				var bone := skeleton.find_bone(name)
				if bone >= 0:
					var global_hand := skeleton.global_transform * skeleton.get_bone_global_pose(bone)
					hand = {"name": name, "pose_rotation": skeleton.get_bone_pose_rotation(bone), "world_basis": global_hand.basis, "world_position": global_hand.origin}
					break
		var old_root_barrel := (weapon.global_basis * Vector3.FORWARD).normalized()
		var old_root_magazine := (weapon.global_basis * Vector3.UP).normalized()
		var old_back := flat_direction(proxy.global_basis * Vector3.BACK)
		var canonical_forward := flat_direction(proxy.global_basis * Vector3.LEFT)
		var canonical_back := flat_direction(proxy.global_basis * Vector3.RIGHT)
		var mesh_front := (mesh.global_basis * Vector3.FORWARD).normalized()
		var mesh_up := (mesh.global_basis * Vector3.UP).normalized()
		var unit_runtime: Variant = unit.call("get_runtime_status") if unit.has_method("get_runtime_status") else null
		var runtime_state: Dictionary = unit_runtime.call("to_dict") if unit_runtime != null and unit_runtime.has_method("to_dict") else {}
		var socket := weapon.get_parent() as Node3D
		var row: Dictionary = {
			"unit_id": id, "process_frame": Engine.get_process_frames(), "tick": simulation.call("get_tick"),
			"runtime_state": runtime_state, "displayed_weapon_posture": weapon.get_meta("unit_weapon_posture_applied", ""),
			"animation": player.current_animation if player != null else "", "animation_position": player.current_animation_position if player != null else -1,
			"proxy_yaw": proxy.rotation_degrees.y, "canonical_forward": canonical_forward, "canonical_back": canonical_back, "old_assumed_back": old_back,
			"root_barrel": old_root_barrel, "root_up": old_root_magazine, "mesh_front": mesh_front, "mesh_up": mesh_up,
			"legacy_root_barrel_down_dot": old_root_barrel.dot(Vector3.DOWN), "legacy_root_up_old_back_dot": old_root_magazine.dot(old_back),
			"root_up_canonical_back_dot": old_root_magazine.dot(canonical_back), "mesh_front_down_dot": mesh_front.dot(Vector3.DOWN),
			"mesh_up_canonical_back_dot": mesh_up.dot(canonical_back), "mesh_down_canonical_back_dot": (-mesh_up).dot(canonical_back),
			"mesh_front_canonical_forward_dot": mesh_front.dot(canonical_forward), "legacy_back_canonical_back_dot": old_back.dot(canonical_back),
			"weapon_local_position": weapon.position, "weapon_local_rotation": weapon.rotation_degrees, "weapon_world_basis": weapon.global_basis,
			"mesh_name": mesh.name, "mesh_local_position": mesh.position, "mesh_local_rotation": mesh.rotation_degrees, "mesh_world_basis": mesh.global_basis,
			"mesh_aabb": mesh.get_aabb(), "socket_name": socket.name if socket != null else "", "socket_world_basis": socket.global_basis if socket != null else Basis.IDENTITY,
			"hand_bone": hand, "read_only_diagnostic": true, "orientation_accepted": false,
		}
		print("R4_IDLE_AXIS_SAMPLE " + JSON.stringify(row))
		sampled += 1
	check(sampled == 2, "Read the same two existing identities as TASK174 without replacing actors")
	check(owner_state(view, simulation) == before, "Axis inspection leaves actors, runtime, tick, commands and effects unchanged")
	scene.queue_free()
	await process_frame
	finish()


func flat_direction(value: Vector3) -> Vector3:
	value.y = 0.0
	return value.normalized()


func find_visual(node: Node, prefix: String) -> Node:
	if node == null:
		return null
	if String(node.name).begins_with(prefix):
		return node
	for child in node.get_children():
		var found := find_visual(child, prefix)
		if found != null:
			return found
	return null


func first_mesh(node: Node) -> MeshInstance3D:
	if node == null:
		return null
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := first_mesh(child)
		if found != null:
			return found
	return null


func owner_state(view: Node, simulation: Node) -> Dictionary:
	var actors: Dictionary = {}
	for unit in Array(view.get("_unit_nodes")):
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var status: Variant = unit.call("get_runtime_status") if unit.has_method("get_runtime_status") else null
		actors[String(unit.call("get_unit_id"))] = {"position": unit.global_position, "health": unit.call("get_health") if unit.has_method("get_health") else null, "runtime": status.call("to_dict") if status != null and status.has_method("to_dict") else {}}
	return {"actors": actors, "tick": simulation.call("get_tick"), "commands": Array(simulation.get("command_queue")).duplicate(true), "effects": Array(simulation.get("effects_queue")).duplicate(true)}


func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", label)


func finish() -> void:
	print("R4_IDLE_AXIS_INSPECTOR: %d passed, %d failed; orientation acceptance was not evaluated" % [passed, failed])
	if failed == 0:
		print("R4_IDLE_AXIS_INSPECTION_COMPLETE")
	quit(1 if failed else 0)
