extends RefCounted
## Prepared only after a real, hidden mission scene has finished setup. The
## enclosing world transaction owns scene lifetime and publishes synchronously.
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const TRANSPORT = preload("res://scripts/mission/transport_checkpoint.gd")
const GROUND_ACTORS = preload("res://scripts/mission/mission_ground_actor_transaction.gd")
const LIFECYCLE = preload("res://scripts/mission/stable_mission_lifecycle_checkpoint.gd")

# Instantiate without attaching or publishing. The caller adds it to a hidden
# holder, waits for setup and initial effects, then prepares all participants.
## packed (optional): schon im Hintergrund geladene Einsatz-Szene; ohne sie wird wie bisher synchron geladen.
static func instantiate_scene(data: Dictionary, home: Dictionary, packed: PackedScene = null) -> Dictionary:
	var identity: Variant = data.get("identity")
	var active: Variant = data.get("active_ids")
	var roster: Variant = data.get("roster")
	var campaign: Variant = data.get("campaign")
	if not identity is Dictionary or not active is Array or not roster is Array or not campaign is Dictionary: return _bad("mission_scene_identity")
	var craft: String = identity.get("craft_id", "")
	var pilot: String = data.get("pilot_id", "")
	var location: String = identity.get("location_id", "")
	var scenario: String = identity.get("scenario_id", "")
	if craft.is_empty() or pilot.is_empty() or location.is_empty() or scenario.is_empty() or not active.has(pilot): return _bad("mission_scene_identity")
	var place: Variant = campaign.get("locations", {}).get(location)
	var home_craft: Variant = home.get("craft")
	if not place is Dictionary or not place.get("map_file_path") is String or not home_craft is Dictionary: return _bad("mission_scene_identity")
	var wire: Variant = data.get("transport")
	if not wire is Dictionary or wire.get("schema") != "mission_transport_checkpoint.v1": return _bad("mission_scene_transport")
	var decoded := CODEC.decode_value(wire.get("value"))
	if not decoded.get("ok",false) or not decoded.value is Dictionary or not TRANSPORT.decode_geometry(decoded.value).get("ok",false): return _bad("mission_scene_transport")
	var payload: Dictionary = decoded.value
	if not payload.get("visits") is Dictionary or payload.visits.size()!=1 or not payload.visits.has(craft) or not payload.get("fields") is Dictionary: return _bad("mission_scene_identity")
	var visit: Variant = payload.visits[craft]
	if not visit is Dictionary or visit.get("craft_id") != craft or not visit.get("unit_ids") is Array: return _bad("mission_scene_identity")
	var ids: Array = visit.unit_ids.duplicate()
	if not ids.has(pilot): ids.append(pilot)
	var sorted_ids: Array = ids.duplicate(); sorted_ids.sort()
	var sorted_active: Array = active.duplicate(); sorted_active.sort()
	if sorted_ids != sorted_active: return _bad("mission_scene_identity")
	var teams: Array = Array(visit.get("fireteam_ids", [])).duplicate()
	while teams.size() < ids.size(): teams.append("ft1")
	if teams.size() != ids.size(): return _bad("mission_scene_identity")
	var scene_resource: PackedScene = packed if packed != null else (load("res://scenes/tests/mission_reactivity_test.tscn") as PackedScene)
	var scene: Node = scene_resource.instantiate()
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	scene.set_meta("singleplayer_mission_identity", identity.duplicate(true))
	scene.set_meta("singleplayer_visit_identities", payload.visits.duplicate(true))
	scene.set_meta("location_id", location)
	scene.set_meta("campaign_ground_pilot_id", pilot)
	var setup: Node = scene.get_node("MissionSetup")
	setup.set("selected_team_unit_ids", PackedStringArray(ids))
	setup.set("selected_team_fireteam_ids", PackedStringArray(teams))
	setup.set("selected_team_unit_configs", roster.duplicate(true))
	setup.set("selected_fireteam_definitions", Array(home_craft.get("fireteam_definitions", [])).duplicate(true))
	setup.set("member_loadouts", Dictionary(home_craft.get("member_loadouts", {})).duplicate(true))
	setup.set("map_file_path", place.map_file_path)
	setup.set("scenario_file_path", "res://data/mission_scenarios/" + scenario + ".json")
	setup.set("defer_friendly_runtime_activation", false)
	setup.set("allow_full_roster_when_selection_empty", false)
	var mission_config: Variant = data.get("mission_config")
	if not mission_config is Dictionary or typeof(mission_config.get("time_limit_seconds")) not in [TYPE_INT,TYPE_FLOAT] or typeof(mission_config.get("win_condition"))!=TYPE_STRING: scene.free(); return _bad("active_mission_config_invalid")
	var combat: Node = scene.get_node("CombatLoopDriver")
	combat.set("mission_time_limit_seconds",float(mission_config.time_limit_seconds))
	combat.set("win_condition",mission_config.win_condition)
	var names := ["UnitAlpha","UnitBravo","UnitCharlie","UnitDelta","UnitEcho","UnitFoxtrot","UnitGolf","UnitHotel"]
	var paths: Array[NodePath] = []
	for index in range(ids.size()):
		if index>=names.size(): scene.free(); return _bad("active_mission_config_invalid")
		paths.append(NodePath("../" + names[index]))
	combat.set("friendly_unit_paths",paths)
	var controller: Node = scene.get_node("TacticalController")
	controller.set("_live_drop_bootstrap_consumed", true)
	var driver: Node = scene.get_node_or_null("CommandFlowDriver")
	if driver != null and not ids.is_empty(): driver.set("unit_id", ids[0])
	return {"ok":true,"scene":scene}

static func prepare(scene: Node, data: Dictionary) -> Dictionary:
	if not is_instance_valid(scene) or not scene.is_inside_tree(): return _bad("mission_scene_unavailable")
	var sim: Node = scene.get_node_or_null("SimulationRoot")
	var terrain: Node = scene.get_node_or_null("TerrainRegistry")
	var controller: Node = scene.get_node_or_null("TacticalController")
	var driver: Node = scene.get_node_or_null("CombatLoopDriver")
	if not is_instance_valid(sim) or not is_instance_valid(terrain) or not is_instance_valid(controller) or not is_instance_valid(driver): return _bad("mission_scene_unavailable")
	var identity: Variant = data.get("identity")
	var active: Variant = data.get("active_ids")
	if not identity is Dictionary or not active is Array or not data.get("transport") is Dictionary: return _bad("mission_scene_identity")
	var craft: String = identity.get("craft_id", "")
	var pilot: String = data.get("pilot_id", "")
	if craft.is_empty() or pilot.is_empty() or not active.has(pilot): return _bad("mission_scene_identity")
	var wire: Dictionary = data.transport
	if wire.get("schema") != "mission_transport_checkpoint.v1": return _bad("mission_scene_transport")
	var decoded := CODEC.decode_value(wire.get("value"))
	if not decoded.get("ok",false) or not decoded.value is Dictionary: return _bad("mission_scene_transport")
	var transport: Dictionary = decoded.value
	if not TRANSPORT.decode_geometry(transport).get("ok",false): return _bad("mission_scene_transport")
	if not transport.get("visits") is Dictionary or transport.visits.size() != 1 or not transport.visits.has(craft) or not transport.get("craft_identities") is Dictionary or transport.craft_identities.size() != 1 or not transport.craft_identities.has(craft): return _bad("mission_scene_identity")
	var loaded: Dictionary = load("res://scripts/meta/campaign_checkpoint_store.gd").load_checkpoint()
	if not loaded.get("ok",false): return loaded
	var home: Dictionary = loaded.payload.duplicate(true)
	load("res://scripts/meta/campaign_start_configuration.gd")._migrate_known_main_starter(home)
	var definition: Variant = home.get("craft", {}).get("definition", {})
	if not definition is Dictionary or definition.get("craft_id") != craft or transport.craft_identities[craft] != {"model_id":definition.get("model_id", "")}: return _bad("mission_scene_craft_mismatch")
	var visit: Variant = transport.visits[craft]
	if not visit is Dictionary or visit.get("craft_id") != craft or not visit.get("unit_ids") is Array: return _bad("mission_scene_identity")
	var visit_ids: Array = visit.unit_ids.duplicate()
	if not visit_ids.has(pilot): visit_ids.append(pilot)
	visit_ids.sort()
	var active_sorted: Array = active.duplicate()
	active_sorted.sort()
	if visit_ids != active_sorted or scene.get_meta("singleplayer_visit_identities", {}) != transport.visits or scene.get_meta("singleplayer_mission_identity", {}) != identity: return _bad("mission_scene_identity")
	var actors := {}
	var presence := {}
	for id in active_sorted:
		var actor: Node = sim.get_unit_registry().get_unit(id)
		if not is_instance_valid(actor): return _bad("mission_scene_actor_missing")
		actors[id] = actor
		presence[id] = false
	var bindings := {"actors":actors,"simulation_root":sim,"visits":transport.visits,"craft_identities":transport.craft_identities,"presence_bindings":presence,"pilot_bindings":{craft:pilot}}
	var transport_prepared: Dictionary = controller.prepare_transport_checkpoint_candidate(wire,bindings)
	if not transport_prepared.get("ok",false): return transport_prepared
	var ground = GROUND_ACTORS.new()
	if data.get("ground",{}).get("schema") == "hex_mission_ground.v1":
		var checkpoint: Variant = data.ground.get("checkpoint")
		if not checkpoint is Dictionary: return _bad("active_hex_lifecycle_mismatch")
		if checkpoint.get("tick") != data.get("lifecycle",{}).get("tick") or checkpoint.get("rng_state") != data.get("lifecycle",{}).get("rng"): return _bad("active_hex_lifecycle_mismatch")
		if checkpoint.has("rng_streams") and checkpoint.rng_streams != data.get("lifecycle",{}).get("rng_streams"): return _bad("active_hex_lifecycle_mismatch")
	var gp: Dictionary = ground.prepare_restore(sim,terrain,data.get("ground",{}),data.get("actors",{}),active_sorted,data.get("lifecycle",{}))
	if not gp.get("ok",false): return gp
	var lifecycle = LIFECYCLE.new()
	var lp: Dictionary = lifecycle.prepare_restore(sim,driver,data.get("lifecycle",{}))
	if not lp.get("ok",false): return lp
	return {"ok":true,"scene":scene,"ground":ground,"gp":gp.prepared,"lifecycle":lifecycle,"lp":lp.prepared,"controller":controller,"transport":transport_prepared.candidate,"bindings":bindings}

static func validate(candidate: Dictionary) -> Dictionary:
	if not is_instance_valid(candidate.get("scene")) or not is_instance_valid(candidate.get("controller")): return _bad("mission_scene_changed")
	var checked: Dictionary = candidate.ground.validate_restore(candidate.gp)
	if not checked.get("ok",false): return checked
	checked = candidate.lifecycle.validate_restore(candidate.lp)
	if not checked.get("ok",false): return checked
	return candidate.controller.validate_transport_checkpoint_candidate(candidate.transport,candidate.bindings)

static func publish(candidate: Dictionary) -> void:
	# Call only after all world and scene candidates validate in the same frame.
	candidate.ground._publish_restore(candidate.gp)
	candidate.lifecycle._publish_restore(candidate.lp)
	candidate.controller._publish_transport_checkpoint(candidate.transport)

static func finalize(candidate: Dictionary) -> Dictionary:
	return candidate.ground.finalize_restore(candidate.gp)

static func _bad(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
