class_name MultiplayerWorldRuntime
extends Node
## Lifecycle/index only. Each location's SimulationRoot owns its gameplay.
signal locations_changed
signal local_location_changed(location_id: String, instance: Node)
signal world_completed
signal location_error(reason: String)

const MANIFEST = preload("res://scripts/multiplayer/multiplayer_map_manifest.gd")
const PRODUCT_MAPS = preload("res://scripts/mission/productive_ground_maps.gd")
const REGISTRY = preload("res://scripts/mission/location_runtime_registry.gd")
const BOOTSTRAP = preload("res://scripts/mission/multiplayer_dropship_bootstrap.gd")
const PRESENTATION = preload("res://scripts/multiplayer/multiplayer_location_presentation.gd")
const MISSION = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MAX_LOCATIONS := 8

var _session: Node
var _mission_host: Node
var _registry = REGISTRY.new()
var _entries: Dictionary = {}
var _assignments: Dictionary = {}
var _epoch: String = ""
var _primary_id: String = ""
var _selected_id: String = ""
var _primary_path: String = ""
var _ready_by_location: Dictionary = {}
var _presentations: Dictionary = {}
var _known_map_paths := PackedStringArray()

func configure(session: Node, mission_host: Node) -> void:
	_session = session
	_mission_host = mission_host
	_known_map_paths = PRODUCT_MAPS.playable_paths()

func start_world(assignments: Dictionary, primary_path: String) -> bool:
	if _session == null or _mission_host == null: return false
	var context: Dictionary = _session.call("get_multiplayer_runtime_context")
	if context.is_empty() or assignments.get("multiplayer_runtime_context", {}) != context: return false
	var epoch: String = String(context.get("runtime_token", ""))
	if _epoch != epoch:
		clear_world()
		_epoch = epoch
		_primary_id = epoch
	_primary_path = primary_path
	_assignments = assignments.duplicate(true)
	if multiplayer.is_server():
		if _entries.is_empty():
			var session_manifest: Dictionary = _session.call("get_session_snapshot").get("map_manifest", {})
			var manifest: Dictionary = MANIFEST.build_manifest_for_map(primary_path, String(session_manifest.get("scenario_file_path", "")))
			if not _context_matches_manifest(context, manifest): return false
			var entry: Dictionary = {"id": epoch, "context": context, "manifest": MANIFEST.normalize_manifest(manifest), "teams": _all_teams(), "finished": false}
			_entries[epoch] = entry
			if not _instantiate_location(entry, primary_path):
				_entries.erase(epoch)
				return false
		publish_locations()
	else:
		request_locations.rpc_id(1, _epoch)
	return true

func open_location(map_path: String, allowed_teams: PackedStringArray = PackedStringArray()) -> Dictionary:
	if not multiplayer.is_server() or _epoch.is_empty(): return {"ok":false, "reason":"host_required"}
	if not _known_map_paths.has(map_path): return {"ok":false, "reason":"unknown_product_map"}
	var manifest: Dictionary = MANIFEST.build_manifest_for_map(map_path)
	if not bool(manifest.get("valid", false)): return {"ok":false, "reason":"invalid_map_manifest"}
	for entry: Dictionary in _entries.values():
		if not entry.finished and entry.manifest.map_hash == manifest.map_hash:
			return {"ok":true, "location_id":entry.id, "existing":true}
	var active_count := 0
	for entry: Dictionary in _entries.values():
		if not bool(entry.finished): active_count += 1
	if active_count >= MAX_LOCATIONS: return {"ok":false, "reason":"location_capacity"}
	var teams: PackedStringArray = _all_teams() if allowed_teams.is_empty() else allowed_teams.duplicate()
	for team: String in teams:
		if not _all_teams().has(team): return {"ok":false, "reason":"unknown_team"}
	var token: String = Crypto.new().generate_random_bytes(16).hex_encode()
	var context: Dictionary = {"schema":"multiplayer.runtime_context.v1", "runtime_token":token, "map_id":manifest.map_id, "map_hash":manifest.map_hash}
	if not String(manifest.get("scenario_hash", "")).is_empty(): context.scenario_hash = manifest.scenario_hash
	var entry: Dictionary = {"id":token, "context":context, "manifest":MANIFEST.normalize_manifest(manifest), "teams":teams, "finished":false}
	_entries[token] = entry
	if not _instantiate_location(entry, map_path):
		_entries.erase(token)
		return {"ok":false, "reason":"runtime_binding_failed"}
	publish_locations()
	return {"ok":true, "location_id":token, "existing":false}

func update_assignments(assignments: Dictionary) -> void:
	if _epoch.is_empty() or assignments.get("multiplayer_runtime_context", {}) != _session.call("get_multiplayer_runtime_context"): return
	var previous_fireteams: PackedStringArray = _local_fireteams(_assignments)
	_assignments = assignments.duplicate(true)
	var next_fireteams: PackedStringArray = _local_fireteams(_assignments)
	for id: String in _entries:
		var instance: Node = get_location_instance(id)
		if instance == null: continue
		if not _bind_root(instance.get_node("SimulationRoot"), _entries[id]): continue
		if previous_fireteams != next_fireteams:
			_retain_local_selection(instance, next_fireteams)
	if multiplayer.is_server(): publish_locations()

func on_peer_block_changed(peer_id: int, blocked: bool) -> void:
	# Session primary READY is not an all-location acknowledgement.
	if not multiplayer.is_server() or not blocked: return
	for id: String in _entries:
		Dictionary(_ready_by_location.get(id, {})).erase(peer_id)
		var instance: Node = get_location_instance(id)
		if instance != null: instance.get_node("SimulationRoot").call("set_snapshot_peer_blocked", peer_id, true)

func publish_locations() -> void:
	if not multiplayer.is_server() or _epoch.is_empty(): return
	for peer_id: int in multiplayer.get_peers():
		if _session.call("is_mission_peer_authenticated", peer_id):
			_receive_locations.rpc_id(peer_id, _epoch, _catalog_for_peer(peer_id))
	locations_changed.emit()

@rpc("any_peer", "call_remote", "reliable")
func request_locations(epoch: String) -> void:
	if not multiplayer.is_server() or epoch != _epoch or _epoch.is_empty(): return
	var peer_id: int = multiplayer.get_remote_sender_id()
	if not _session.call("is_mission_peer_authenticated", peer_id): return
	_receive_locations.rpc_id(peer_id, _epoch, _catalog_for_peer(peer_id))

@rpc("authority", "call_remote", "reliable")
func _receive_locations(epoch: String, entries: Array) -> void:
	if multiplayer.is_server() or epoch != _epoch or _epoch.is_empty() or entries.size() > MAX_LOCATIONS: return
	if _session.call("get_multiplayer_runtime_context").get("runtime_token", "") != epoch: return
	var received: Dictionary = {}
	for raw: Variant in entries:
		if not raw is Dictionary: return
		var entry: Dictionary = raw
		if not _valid_entry(entry) or received.has(entry.id): return
		received[entry.id] = entry.duplicate(true)
	# Validate the whole index before mutating local lifecycle.
	for id: String in _entries.keys():
		if not received.has(id):
			_retire_location(id)
			_entries.erase(id)
	for id: String in received:
		var entry: Dictionary = received[id]
		if _entries.has(id) and _entries[id].context != entry.context: continue
		_entries[id] = entry
		if entry.finished:
			_retire_location(id)
			continue
		var instance: Node = get_location_instance(id)
		if instance == null:
			var candidates: Array = []
			if id == _primary_id and not _primary_path.is_empty(): candidates.append(_primary_path)
			# Hint only selects a shipped candidate; local content is hash-verified.
			for candidate: String in _known_map_paths:
				if String(candidate.get_file().get_basename()).to_lower() == String(entry.manifest.map_id).to_lower(): candidates.append(candidate)
			if candidates.is_empty(): candidates.assign(_known_map_paths)
			var local: Dictionary = MANIFEST.check_local_map(entry.manifest, candidates)
			if local.get("state", "") != "known":
				location_error.emit("Karte lokal nicht verfügbar: " + String(entry.manifest.map_name))
				continue
			if not _instantiate_location(entry, String(local.local_path)): continue
		notify_location_ready.rpc_id(1, _epoch, id, entry.context)
	locations_changed.emit()

@rpc("any_peer", "call_remote", "reliable")
func notify_location_ready(epoch: String, id: String, context: Dictionary) -> void:
	if not multiplayer.is_server() or epoch != _epoch or _epoch.is_empty() or not _entries.has(id): return
	var peer_id: int = multiplayer.get_remote_sender_id()
	var entry: Dictionary = _entries[id]
	if not _session.call("is_mission_peer_authenticated", peer_id) or not _peer_allowed(entry, peer_id) or entry.finished or context != entry.context: return
	var instance: Node = get_location_instance(id)
	if instance == null: return
	if not _ready_by_location.has(id): _ready_by_location[id] = {}
	_ready_by_location[id][peer_id] = true
	instance.get_node("SimulationRoot").call("set_snapshot_peer_blocked", peer_id, false)

func select_location(id: String) -> bool:
	var instance: Node = get_location_instance(id)
	if instance == null or not _entries.has(id) or bool(_entries[id].finished): return false
	if not multiplayer.is_server() and not _peer_allowed(_entries[id], multiplayer.get_unique_id()): return false
	for other_id: String in _registry.location_ids():
		var other: Node = get_location_instance(other_id)
		if other != null: _set_local_presentation(other, other_id == id)
	_selected_id = id
	local_location_changed.emit(id, instance)
	locations_changed.emit()
	return true

func get_location_instance(id: String) -> Node:
	return _registry.get_location(id)

func get_selected_location_id() -> String:
	return _selected_id

func get_location_rows() -> Array:
	var rows: Array = []
	for id: String in _entries:
		var entry: Dictionary = _entries[id]
		rows.append({"id":id, "title":String(entry.manifest.map_name), "selected":id == _selected_id, "available":get_location_instance(id) != null and not entry.finished, "finished":bool(entry.finished)})
	return rows

func is_peer_ready(id: String, peer_id: int) -> bool:
	return bool(Dictionary(_ready_by_location.get(id, {})).get(peer_id, false))

func finish_location(id: String, _result: Dictionary = {}) -> bool:
	if not multiplayer.is_server() or not _entries.has(id) or _entries[id].finished: return false
	_entries[id].finished = true
	_retire_location(id)
	_entries.erase(id)
	publish_locations()
	for entry: Dictionary in _entries.values():
		if not entry.finished: return true
	world_completed.emit()
	return true

func clear_world() -> void:
	for id: String in _registry.location_ids():
		var instance: Node = get_location_instance(id)
		if instance != null:
			instance.get_node("SimulationRoot").call("set_snapshot_broadcast_paused", true)
			_set_local_presentation(instance, false)
			instance.process_mode = Node.PROCESS_MODE_DISABLED
			_free_after_network_drain(instance, id, _registry)
	_registry = REGISTRY.new()
	_entries.clear()
	_ready_by_location.clear()
	_presentations.clear()
	_assignments.clear()
	_epoch = ""
	_selected_id = ""
	_primary_id = ""
	local_location_changed.emit("", null)
	locations_changed.emit()

func _instantiate_location(entry: Dictionary, map_path: String) -> bool:
	var scenario_path: String = String(entry.manifest.get("scenario_file_path", ""))
	var scenario_hash: String = String(entry.manifest.get("scenario_hash", ""))
	if not scenario_hash.is_empty() and (scenario_path.is_empty() or not FileAccess.file_exists(scenario_path) or FileAccess.get_file_as_string(scenario_path).sha256_text() != scenario_hash):
		location_error.emit("Szenario lokal nicht zum Manifest passend.")
		return false
	var instance: Node = MISSION.instantiate()
	instance.name = "Place_" + String(entry.id)
	var setup: Node = instance.get_node("MissionSetup")
	setup.set("map_file_path", map_path)
	setup.set("scenario_file_path", scenario_path)
	setup.set("fog_of_war_mode", "unexplored_blackout")
	setup.set("fog_viewer_team_id", _team_for_peer(multiplayer.get_unique_id()))
	var sim: Node = instance.get_node("SimulationRoot")
	if not _bind_root(sim, entry):
		instance.free()
		return false
	# No snapshot can precede this peer's location-specific READY.
	if multiplayer.is_server():
		for peer_id: int in multiplayer.get_peers(): sim.call("set_snapshot_peer_blocked", peer_id, true)
	instance.get_node("CombatLoopDriver").call("set_combat_startup_grace_ticks", 180)
	_mission_host.add_child(instance)
	_registry.register_location(entry.id, instance)
	var presentation = PRESENTATION.new()
	presentation.configure(instance)
	_presentations[instance.get_instance_id()] = presentation
	sim.call("refresh_multiplayer_replica_presence")
	var controller: Node = instance.get_node("TacticalController")
	if multiplayer.is_server():
		var planning: Dictionary = BOOTSTRAP.build_initial_planning_state(controller, _filtered_assignments(entry))
		if not planning.is_empty(): controller.call("set_planning_state", planning)
	_apply_local_perspective(instance)
	instance.get_node("CombatLoopDriver").connect("combat_resolved", func(result: Dictionary): finish_location(entry.id, result))
	_set_local_presentation(instance, false)
	if _selected_id.is_empty(): select_location(entry.id)
	return true

func _bind_root(sim: Node, entry: Dictionary) -> bool:
	var assignments: Dictionary = _filtered_assignments(entry)
	var team: String = _team_for_peer(multiplayer.get_unique_id())
	if team.is_empty(): return false
	if not bool(Dictionary(sim.call("validate_multiplayer_runtime_context_binding", entry.context, team)).get("ok", false)): return false
	sim.set("is_server_authoritative", true)
	sim.call("set_peer_team_assignments", assignments.peer_teams)
	sim.call("set_peer_role_assignments", assignments.peer_roles)
	sim.call("set_peer_fireteam_assignments", assignments.peer_fireteams)
	return bool(Dictionary(sim.call("bind_multiplayer_runtime_context", entry.context, team)).get("ok", false))

func _filtered_assignments(entry: Dictionary) -> Dictionary:
	var result: Dictionary = _assignments.duplicate(true)
	for key: String in ["peer_teams", "peer_roles", "peer_fireteams", "peer_rosters"]:
		var filtered: Dictionary = {}
		for raw_id: Variant in Dictionary(_assignments.get(key, {})):
			if int(raw_id) == 1 or _peer_allowed(entry, int(raw_id)): filtered[raw_id] = _assignments[key][raw_id]
		result[key] = filtered
	return result

func _apply_local_perspective(instance: Node) -> void:
	var controller: Node = instance.get_node("TacticalController")
	controller.call("apply_local_multiplayer_fireteam_perspective", _local_fireteams(_assignments))

func _local_fireteams(assignments: Dictionary) -> PackedStringArray:
	var teams: Dictionary = assignments.get("peer_fireteams", {})
	var result := PackedStringArray(teams.get(multiplayer.get_unique_id(), []))
	result.sort()
	return result

func _retain_local_selection(instance: Node, allowed: PackedStringArray) -> void:
	var controller: Node = instance.get_node("TacticalController")
	var selected: PackedStringArray = controller.call("get_selected_fireteam_ids")
	var retained := PackedStringArray()
	for fireteam_id: String in selected:
		if allowed.has(fireteam_id): retained.append(fireteam_id)
	if retained != selected:
		# The existing controller still owns selection. No default selection/focus.
		controller.call("_set_selected_fireteams", retained, false)

func _set_local_presentation(instance: Node, active: bool) -> void:
	var presentation = _presentations.get(instance.get_instance_id())
	if presentation != null: presentation.set_active(active)

func _retire_location(id: String) -> void:
	var instance: Node = get_location_instance(id)
	if instance != null:
		instance.get_node("SimulationRoot").call("set_snapshot_broadcast_paused", true)
		_set_local_presentation(instance, false)
		instance.process_mode = Node.PROCESS_MODE_DISABLED
		# Keep RPC targets alive briefly for reliable messages already in flight.
		_free_after_network_drain(instance, id, _registry)
	if _entries.has(id): _entries[id].finished = true
	_ready_by_location.erase(id)
	if _selected_id == id:
		_selected_id = ""
		local_location_changed.emit("", null)
		for other_id: String in _entries:
			if not _entries[other_id].finished and get_location_instance(other_id) != null:
				select_location(other_id)
				break

func _free_after_network_drain(instance: Node, location_id: String, registry: RefCounted) -> void:
	var instance_id: int = instance.get_instance_id()
	for _frame in range(4): await get_tree().process_frame
	# Capture the old registry across clear_world/new-world races. Identity guards
	# prevent a delayed retirement from removing a replacement at the same ID.
	registry.call("unregister_location", location_id, instance_id)
	_presentations.erase(instance_id)
	if is_instance_valid(instance) and not instance.is_queued_for_deletion(): instance.queue_free()

func _catalog_for_peer(peer_id: int) -> Array:
	var result: Array = []
	for entry: Dictionary in _entries.values():
		if not entry.finished and _peer_allowed(entry, peer_id): result.append(entry.duplicate(true))
	return result

func _all_teams() -> PackedStringArray:
	var result := PackedStringArray()
	for value: Variant in Dictionary(_assignments.get("peer_teams", {})).values():
		var team: String = String(value)
		if not team.is_empty() and not result.has(team): result.append(team)
	return result

func _team_for_peer(peer_id: int) -> String:
	return String(Dictionary(_assignments.get("peer_teams", {})).get(peer_id, ""))

func _peer_allowed(entry: Dictionary, peer_id: int) -> bool:
	return PackedStringArray(entry.get("teams", [])).has(_team_for_peer(peer_id))

func _valid_entry(entry: Dictionary) -> bool:
	if not entry.get("id") is String or not entry.get("context") is Dictionary or not entry.get("manifest") is Dictionary or not entry.get("finished") is bool: return false
	if not (entry.get("teams") is Array or entry.get("teams") is PackedStringArray): return false
	if not _context_matches_manifest(entry.context, entry.manifest) or entry.id != entry.context.runtime_token: return false
	return _peer_allowed(entry, multiplayer.get_unique_id())

func _context_matches_manifest(context: Dictionary, manifest: Dictionary) -> bool:
	if not bool(MANIFEST.verify_manifest(manifest).get("valid", false)): return false
	for key: Variant in context:
		if key not in ["schema", "runtime_token", "map_id", "map_hash", "scenario_hash"] or not context[key] is String: return false
	var token: String = String(context.get("runtime_token", ""))
	return context.get("schema") == "multiplayer.runtime_context.v1" and token.length() == 32 and token.is_valid_hex_number(false) and context.get("map_id") == manifest.get("map_id") and context.get("map_hash") == manifest.get("map_hash") and context.get("scenario_hash", "") == manifest.get("scenario_hash", "")
