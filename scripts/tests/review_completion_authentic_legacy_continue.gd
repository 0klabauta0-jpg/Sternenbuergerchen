extends "res://scripts/tests/campaign_active_mission_continue_verifier.gd"
## Historical files produced by an actual campaign on snapshot d1efd4047a7c.
## No edited Home digest, fabricated win, transport state or gameplay restore.
## This checks reconstruction and a new native save, not a full mission playthrough.
const LEGACY_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const LEGACY_CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const LEGACY_ACTIVE = preload("res://scripts/meta/campaign_active_checkpoint_store.gd")
const LEGACY_RNG = preload("res://scripts/core/gameplay_rng_state.gd")
const SOURCE_DIR := "res://docs/qa/review_completion_20261113/legacy_source_pair/"
const SOURCE_HOME_SHA := "2752850e878c6a4a756cc38be978fa01f2f299a604ee57ff2c582f61c2e6350a"
const SOURCE_ACTIVE_SHA := "84d645b84abead91cffd4a72e48620f4dc8779e75ce1d69251a82566b20117af"
var _original_home: PackedByteArray
var _original_active: PackedByteArray
var _old_home: Dictionary = {}
var _old_components: Dictionary = {}

func _run() -> void:
	# The inherited SceneTree constructor already defers this entry point.
	if not LEGACY_GUARD.require_isolated_user_data(): return
	if not _check(FileAccess.file_exists("user://review2_isolation_canary.json"), "runner's real isolation autoload ran before campaign bootstrap"):
		await _finish(); return
	if not _copy_authentic_pair(): await _finish(); return
	if not await _continue_from_files("historical Legacy pair"): await _finish(); return
	_check_restored_owners(_old_components, true)
	_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == _original_home and FileAccess.get_file_as_bytes(LEGACY_ACTIVE.DEFAULT_PATH) == _original_active, "first Continue preserves both historical private-profile files byte for byte")
	# Exercise the same Save command as a player, against the actual published
	# owners. Post-restore freezing only prevents unrelated simulation ticks.
	var menu: Node = root.get_node("GlobalEscapeMenu")
	var saved: Dictionary = menu.call("save_current_mission_slot")
	if not _check(saved.get("ok", false), "actual Escape Save writes the reconstructed mission as native Hex"):
		print("AUTHENTIC_LEGACY_SAVE_FAILURE ", saved)
		await _finish(); return
	var native: Variant = JSON.parse_string(FileAccess.get_file_as_string(LEGACY_ACTIVE.DEFAULT_PATH))
	if not _check(native is Dictionary and native.get("components") is Dictionary, "native Save produces a complete active envelope"):
		await _finish(); return
	var components: Dictionary = native.components
	_check(components.ground.schema == "hex_mission_ground.v1" and components.has("home_hex_tactical"), "native Save captures both actual Hex mission and away-base owners")
	_check(components.home_sha256 == SOURCE_HOME_SHA and FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == _original_home, "native Save keeps the actual historical Home hash and unchanged Home file")
	var native_bytes := FileAccess.get_file_as_bytes(LEGACY_ACTIVE.DEFAULT_PATH)
	_flow.queue_free()
	await process_frame
	_flow = null
	if not await _continue_from_files("new native Hex save"): await _finish(); return
	_check_restored_owners(components, false)
	_check(FileAccess.get_file_as_bytes(LEGACY_ACTIVE.DEFAULT_PATH) == native_bytes, "second Continue reads the newly saved Hex file without rewriting it")
	await _finish()

func _copy_authentic_pair() -> bool:
	var source_home := SOURCE_DIR + "checkpoint_v1.json"
	var source_active := SOURCE_DIR + "active_checkpoint_v1.json"
	if not _check(FileAccess.file_exists(source_home) and FileAccess.file_exists(source_active), "authentic historical Home and Active fixtures exist"):
		return false
	_original_home = FileAccess.get_file_as_bytes(source_home)
	_original_active = FileAccess.get_file_as_bytes(source_active)
	if not _check(FileAccess.get_sha256(source_home) == SOURCE_HOME_SHA and FileAccess.get_sha256(source_active) == SOURCE_ACTIVE_SHA, "historical fixture hashes match the recorded real producer artifacts"):
		return false
	var home: Variant = JSON.parse_string(_original_home.get_string_from_utf8())
	var active: Variant = JSON.parse_string(_original_active.get_string_from_utf8())
	if not _check(home is Dictionary and active is Dictionary and active.get("components") is Dictionary, "historical files decode without rewriting their payloads"):
		return false
	_old_home = home
	_old_components = active.components
	if not _check(_old_components.home_sha256 == SOURCE_HOME_SHA and not _old_home.has("hex_tactical") and _old_components.ground.schema == "legacy_ground_positions.v1" and not _old_components.lifecycle.has("rng_streams"), "the real old pair has matching Home identity and the original pre-activation schemas"):
		return false
	var lifecycle: Dictionary = LEGACY_CODEC.decode_value(_old_components.lifecycle.payload)
	if not _check(lifecycle.get("ok", false) and not lifecycle.value.has("combat_cooldowns"), "original lifecycle genuinely predates the cooldown extension"):
		return false
	if not _check(not FileAccess.file_exists(STORE.DEFAULT_PATH) and not FileAccess.file_exists(LEGACY_ACTIVE.DEFAULT_PATH), "isolated profile is empty before installing fixtures"):
		return false
	for pair in [[STORE.DEFAULT_PATH, _original_home], [LEGACY_ACTIVE.DEFAULT_PATH, _original_active]]:
		if not _check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(String(pair[0])).get_base_dir()) == OK, "private campaign directory is available"):
			return false
		var file := FileAccess.open(String(pair[0]), FileAccess.WRITE)
		if not _check(file != null, "private campaign fixture opens for an exact byte copy"): return false
		file.store_buffer(pair[1])
		file.flush()
		var error := file.get_error()
		file.close()
		if not _check(error == OK and FileAccess.get_file_as_bytes(String(pair[0])) == pair[1], "private campaign copy preserves every original byte"): return false
	return true

func _continue_from_files(label: String) -> bool:
	if not _check(START.request_start(self, "campaign", "continue").get("ok", false), label + ": normal Continue request accepted"): return false
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	if not is_instance_valid(_flow): return _check(false, label + ": Flow rejected startup")
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not await _wait(func():
		return not is_instance_valid(_flow) or bool(_flow.get_meta("campaign_active_restore_complete", false)) or _flow.has_meta("campaign_active_restore_error"), 60000, label + ": actual reconstruction reaches a decision"):
		return false
	if not is_instance_valid(_flow): return _check(false, label + ": Flow survived reconstruction")
	if not _check(bool(_flow.get_meta("campaign_active_restore_complete", false)) and is_instance_valid(_flow.get("_active_mission")), label + ": actual world and scene transaction published"):
		print("AUTHENTIC_LEGACY_RESTORE_FAILURE ", _flow.get_meta("campaign_active_restore_error", {}))
		_log_restore_base()
		return false
	# Freeze only AFTER the real asynchronous reconstruction has completed.
	# No state, clock, command, lifecycle or RNG value is injected by the test.
	_flow.process_mode = Node.PROCESS_MODE_DISABLED
	var mission: Node = _flow.get("_active_mission")
	mission.get_node("SimulationRoot").set_physics_process(false)
	mission.get_node("CombatLoopDriver").set_physics_process(false)
	_runtime.get("_simulation").set_physics_process(false)
	return true

func _check_restored_owners(expected: Dictionary, legacy: bool) -> void:
	var mission: Node = _flow.get("_active_mission")
	var sim: Node = mission.get_node("SimulationRoot")
	var terrain: Node = mission.get_node("TerrainRegistry")
	var registry: Node = mission.get_node("UnitRegistry")
	var controller: Node = mission.get_node("TacticalController")
	var setup: Node = mission.get_node("MissionSetup")
	var driver: Node = mission.get_node("CombatLoopDriver")
	_check(sim.is_hex_ground_runtime_active(), "restored mission uses the actual authoritative Hex owner")
	_check(mission.get_meta("singleplayer_mission_identity", {}) == expected.identity and _flow.get("_active_singleplayer_identity") == expected.identity and _flow.get("_campaign_start").get("campaign_run_id") == expected.campaign_run_id, "mission, craft, departure, location and campaign-run identities survive Continue")
	_check(registry.get_all_units().size() == expected.active_ids.size() and Dictionary(controller.get("_deployed_unit_ids")).size() == expected.active_ids.size(), "registry and controller contain exactly the saved deployed crew")
	_check(_same(setup.get("member_loadouts"), _old_home.craft.member_loadouts) and _same(setup.get("selected_fireteam_definitions"), _old_home.craft.fireteam_definitions), "actual mission setup restores original Home equipment and fireteam definitions")
	_check(_same(_flow.get("_all_team_units"), expected.roster), "actual roster preserves saved names, skills and identity data")
	var planning: Dictionary = sim.get_hex_ground_planning_snapshot()
	_check(Dictionary(planning.get("units_by_id", {})).size() == expected.active_ids.size() and Dictionary(planning.get("occupant_by_grid", {})).size() == expected.active_ids.size(), "logical Ground has exactly one occupied cell per saved person")
	var anchors := {}
	for id in expected.active_ids:
		var decoded: Dictionary = LEGACY_CODEC.decode_value(expected.actors.actors[id].payload)
		if not decoded.get("ok", false): _check(false, "saved actor payload decodes: " + id); continue
		var anchor: Vector2i = terrain.world_to_grid(decoded.value.position)
		if not anchors.has(anchor): anchors[anchor] = id
	var occupied := {}
	for id in expected.active_ids:
		var actor: Node = registry.get_unit(id)
		if not _check(is_instance_valid(actor), "same actual registered person exists: " + id): continue
		var old_record: Dictionary = expected.actors.actors[id]
		var old_model: Dictionary = LEGACY_CODEC.decode_value(old_record.payload).value
		var record: Dictionary = actor.export_mission_actor_checkpoint()
		var model: Dictionary = LEGACY_CODEC.decode_value(record.payload).value
		_check(record.unit_id == old_record.unit_id and record.team_id == old_record.team_id and record.fireteam_id == old_record.fireteam_id and record.max_health == old_record.max_health, "actor identity and maximum health remain unchanged: " + id)
		_check(model.vital == old_model.vital and model.damage == old_model.damage, "actual health, vital state and damage history survive: " + id)
		_check(model.runtime == old_model.runtime and model.command == old_model.command and model.contact_active == old_model.contact_active and model.contact_target == old_model.contact_target, "actual actor runtime, hold command and contact state survive: " + id)
		var loadout: Dictionary = _old_home.craft.member_loadouts[id]
		_check(actor.get_armor_id() == loadout.armor and actor.get_weapon_1_id() == loadout.weapon_1 and actor.get_weapon_2_id() == loadout.weapon_2, "actual actor wears and carries saved equipment: " + id)
		var ground: Dictionary = sim.get_hex_unit_state(id)
		if not _check(ground.get("grid") is Vector2i, "actual Ground admits saved person: " + id): continue
		var grid: Vector2i = ground.grid
		_check(not occupied.has(grid) and planning.occupant_by_grid.get(grid) == id and bool(terrain.is_walkable(grid)) and actor.global_position.distance_to(terrain.grid_to_world(grid)) < 0.01, "actor position agrees with a unique walkable occupied Hex cell: " + id)
		occupied[grid] = true
		var desired: Vector2i = terrain.world_to_grid(old_model.position)
		if legacy:
			var delta := grid - desired
			var distance := maxi(maxi(absi(delta.x), absi(delta.y)), absi(delta.x + delta.y))
			_check(grid == desired if anchors[desired] == id else distance <= 64, "legacy placement preserves its anchor or resolves a same-cell collision within the bounded admission: " + id)
		else:
			_check(actor.global_position.distance_to(old_model.position) < 0.01, "native Hex re-Continue preserves the saved exact position: " + id)
		var binding: Dictionary = sim.get_hex_actor_execution_binding(id)
		_check(binding.get("actor") == actor.get_instance_id() and binding.get("root_id") == sim.get_instance_id() and sim._is_current_hex_payload({"unit_id":id, "_hex_lifecycle":sim._hex_payload_identity(id)}), "permission identity binds the reconstructed actor instance to its actual Root: " + id)
		print("AUTHENTIC_LEGACY_POSITION ", id, " saved=", old_model.position, " restored=", actor.global_position, " grid=", grid)
	var supply: Dictionary = _runtime.get("_supply").export_state()
	_check(supply.credits == expected.supply.credits and _same(supply.fuel_by_craft_id, expected.supply.fuel_by_craft_id) and _same(supply.inventory, expected.supply.inventory) and _same(supply.reward_receipts, expected.supply.reward_receipts), "credits, craft fuel, inventory and paid-reward receipts survive without charging again")
	_check(_same(_runtime.get("_campaign").export_state(), expected.campaign) and _same(_runtime.get("_ship_equipment").export_state(), expected.equipment), "actual campaign progress and ship equipment are the persisted owner states")
	var state: Dictionary = _flow.call("get_singleplayer_snapshot")
	_check(state.space_travel.phase == "surface" and state.space_travel.location_id == expected.identity.location_id, "ship remains on the saved mission surface")
	var base: Dictionary = _runtime.get("_base_personnel").export_state()
	var all_aboard: bool = base.units.size() == expected.active_ids.size()
	for id in expected.active_ids:
		all_aboard = all_aboard and base.units.has(id) and base.units[id].status == "aboard" and base.units[id].craft_id == expected.identity.craft_id
	var home_sim: Node = _runtime.get("_simulation")
	_check(all_aboard and home_sim.is_hex_ground_runtime_active() and Dictionary(home_sim.get_hex_ground_planning_snapshot().get("units_by_id", {})).is_empty(), "deployed crew retains away-base aboard ownership with no duplicate base Ground occupancy")
	_check(driver.mission_time_limit_seconds == expected.mission_config.time_limit_seconds and driver.win_condition == expected.mission_config.win_condition and driver._get_duration_seconds() >= float(expected.lifecycle.elapsed_msec) / 1000.0 and driver._get_duration_seconds() < float(expected.lifecycle.elapsed_msec) / 1000.0 + 10.0, "mission timer and actual victory configuration continue from the saved lifecycle")
	var expected_rng: Dictionary = expected.lifecycle.get("rng_streams", LEGACY_RNG.from_legacy(expected.lifecycle.rng))
	_check(_same(sim.export_gameplay_rng_state(), expected_rng), "actual Root restores saved combat RNG and the documented legacy secondary defaults")
	var reference := RandomNumberGenerator.new()
	reference.state = int(expected.lifecycle.rng)
	var sequence_matches := true
	for index in range(16): sequence_matches = sim.get_next_combat_roll() == reference.randf() and sequence_matches
	_check(sequence_matches and String(sim.export_gameplay_rng_state().combat) == str(reference.state), "sixteen actual owner rolls continue the historical RNG sequence exactly")

func _same(left: Variant, right: Variant) -> bool:
	# JSON parses saved integer-valued numbers as floats; validated owners expose
	# their native ints again. Permit exactly equal numbers, never a tolerance,
	# while preserving every key, sequence position and non-numeric value/type.
	if typeof(left) in [TYPE_INT, TYPE_FLOAT] and typeof(right) in [TYPE_INT, TYPE_FLOAT]:
		return left == right
	if typeof(left) != typeof(right): return false
	if left is Dictionary:
		if left.size() != right.size(): return false
		for key in left:
			if not right.has(key) or not _same(left[key], right[key]): return false
		return true
	if left is Array:
		if left.size() != right.size(): return false
		for index in range(left.size()):
			if not _same(left[index], right[index]): return false
		return true
	return left == right

func _log_restore_base() -> void:
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(LEGACY_ACTIVE.DEFAULT_PATH))
	var components: Dictionary = saved.get("components", {}) if saved is Dictionary else {}
	var expected_base: Dictionary = Dictionary(components.get("home_hex_tactical", {})).get("base_personnel", {})
	var runtime: Node = _flow.get("_singleplayer_runtime")
	var base: Node = runtime.get("_base_personnel") if is_instance_valid(runtime) else null
	var sim: Node = runtime.get("_simulation") if is_instance_valid(runtime) else null
	var actual_base: Dictionary = base.export_checkpoint_state() if is_instance_valid(base) else {}
	var diagnostics := {"actual_base":actual_base, "saved_base":expected_base, "exact_numeric_structure_matches":_same(actual_base, expected_base), "root_tick":sim.get("tick_counter") if is_instance_valid(sim) else null, "root_physics":sim.is_physics_processing() if is_instance_valid(sim) else false, "root_process_mode":sim.process_mode if is_instance_valid(sim) else -1, "base_physics":base.is_physics_processing() if is_instance_valid(base) else false, "base_process_mode":base.process_mode if is_instance_valid(base) else -1}
	print("AUTHENTIC_LEGACY_BASE_RESTORE_DIAGNOSTICS ", JSON.stringify(diagnostics,"",true,true))

func _finish() -> void:
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	if not _original_home.is_empty():
		_check(FileAccess.get_file_as_bytes(SOURCE_DIR + "checkpoint_v1.json") == _original_home and FileAccess.get_sha256(SOURCE_DIR + "checkpoint_v1.json") == SOURCE_HOME_SHA, "original historical Home fixture remains byte-identical")
		_check(FileAccess.get_file_as_bytes(SOURCE_DIR + "active_checkpoint_v1.json") == _original_active and FileAccess.get_sha256(SOURCE_DIR + "active_checkpoint_v1.json") == SOURCE_ACTIVE_SHA, "original historical Active fixture remains byte-identical")
		_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == _original_home, "actual Continue and native resave leave the private historical Home file unchanged")
	print("REVIEW_COMPLETION_AUTHENTIC_LEGACY_CONTINUE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
