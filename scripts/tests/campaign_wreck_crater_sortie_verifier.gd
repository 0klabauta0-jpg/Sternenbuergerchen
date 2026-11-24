extends "res://scripts/tests/campaign_five_actual_sorties_verifier.gd"
## Kapitel 2 / Aufgabe 1: ein echter Einsatz "Wrack am Krater bergen" (wreck_crater_salvage) mit dem Rahmen der fuenf Einsaetze.
## Kapitel 1 wird NICHT gespielt: ein Speicherpunkt mit den fuenf ueber die echten Besitzer abgeschlossenen alten Auftraegen
## wird gebaut (Muster campaign_pilot_swap_two_craft_verifier), danach "Fortsetzen". Dann: annehmen, abfliegen, vier Schritte
## in Reihenfolge, Heimkehr, Belohnung und Beute, Speichern und Laden.
## Zusatz: Beobachtung der Wellen (Zeitpunkt, Anruecken, Zaehlung noch nicht aufgetretener Gegner).
const JOB := "wreck_crater_salvage"
const MAP_PATH := "res://maps/satellite_crash_site.json"
const SHIP1 := "dropship_1"
const SHIP2 := "campaign_buccaneer_01"
const CHAPTER_ONE := ["satellite_recovery", "outpost_recovery", "benit_delivery", "outpost_chip_recovery", "buccaneer_rescue"]
const CAMPAIGN_CONTRACT = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const SUPPLY_CONTRACT = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
const LOOTERS := ["wreck_looter_01", "wreck_looter_02", "wreck_looter_03", "wreck_looter_04"]
var _sequence := 0
var _sim: Node = null
var _waves: Node = null
var _driver: Node = null
var _registry: Node = null
var _game_s := 0.0
var _t0 := 0.0
var _attach_offset := 0.0  # Sekunden Einsatzzeit, die beim Anhaengen der Beobachtung schon vergangen waren (Wellenverzoegerung minus Restzeit)
var _tick_count := 0
var _last_wave := 0
var _wave_at: Dictionary = {}
var _cleared_early := false
var _clear_at := -1.0
var _wave1_all_down_open := false
var _later_group_zero_early := false
var _zero_early_wave := -1
var _looter_first: Dictionary = {}
var _looter_best: Dictionary = {}
var _looter_seen: Dictionary = {}
var _next_log := 0.0
var _fit_log := ""
var _wreck_pos := Vector2.ZERO
var _looter_t_first: Dictionary = {}
var _looter_dwreck_first: Dictionary = {}
var _looter_dwreck_40: Dictionary = {}
var _looter_fell_before_40: Dictionary = {}

func _command(owner: RefCounted, operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	_sequence += 1
	return owner.apply_command(CAMPAIGN_CONTRACT.build_command(operation, payload, "wreck-sortie:%d" % _sequence), context)

## Speicherpunkt nach Kapitel 1: vier verdiente Personen, zweite Rampe, zwei Schiffe; die fuenf Auftraege ueber die echten Besitzer.
func _fixture(flow: Node) -> Dictionary:
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	var onboarding = load("res://scripts/core/campaign_onboarding_state.gd").new()
	campaign.configure(); supply.configure([SHIP1])
	supply.configure_inventory(["campaign_leader", "campaign_pilot", "campaign_outpost_recruit", "campaign_rescue_pilot"], [SHIP1, SHIP2])
	supply.configure_start_inventory("campaign")
	onboarding.configure()
	for id in CHAPTER_ONE:
		var job: Dictionary = campaign.get_campaign_snapshot().jobs[id]
		_command(campaign, "accept_job", {"job_id": id})
		_command(campaign, "bind_departure", {"craft_id": SHIP1, "origin_location_id": "homebase", "destination_location_id": job.location_id, "landing_pad_id": "homebase_pad_01", "job_id": id}, {"departure_authorized": true})
		_command(campaign, "activate_job", {"job_id": id, "craft_id": SHIP1}, {"departure_authorized": true})
		if id == "benit_delivery": _command(campaign, "deliver_crate", {}, {"runtime_authorized": true})
		var done := _command(campaign, "complete_job", {"job_id": id, "craft_id": SHIP1}, {"runtime_evidence": {"scenario_id": job.scenario_id, "result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": job.required_step_ids}}})
		if bool(job.home_upload): done = _command(campaign, "upload_job", {"job_id": id}, {"at_home": true})
		var receipt: Dictionary = done.get("completion_receipt", {})
		supply.apply_command(SUPPLY_CONTRACT.build_command("apply_reward", {"completion_id": receipt.completion_id}, "reward:" + id), {"completion_receipt": receipt})
		if id == "outpost_recovery":
			_command(campaign, "claim_recruit", {"kind": "outpost"}, {"runtime_authorized": true})
			_command(campaign, "load_crate", {}, {"runtime_authorized": true})
		if id == "buccaneer_rescue":
			_command(campaign, "claim_recruit", {"kind": "pilot"}, {"runtime_authorized": true})
			_command(campaign, "build_pad", {}, {"runtime_authorized": true, "at_home": true})
	onboarding.apply_command({"contract_category": "campaign_onboarding", "operation": "observe", "payload": {}}, {"runtime_evidence": {"base_ready": true, "satellite_uploaded": true, "outpost_completed": true, "outpost_recruited": true, "crate_loaded": true, "delivery_completed": true, "outpost_chip_uploaded": true, "rescue_completed": true, "pilot_recruited": true, "second_pad_built": true}})
	var roster: Array = flow.get("_all_team_units").duplicate(true)
	for index in 2:
		var person: Dictionary = roster[index].duplicate(true)
		person.unit_id = "campaign_outpost_recruit" if index == 0 else "campaign_rescue_pilot"
		person.fireteam_id = "ft1" if index == 0 else ""
		roster.append(person)
	var first: Dictionary = flow.call("_build_homebase_aircraft_definition", "dropship", 1)
	var second: Dictionary = flow.call("_build_homebase_aircraft_definition", "fighter", 1)
	second.merge({"craft_id": SHIP2, "display_name": "Buccaneer", "model_id": "buccaneer", "craft_type": "dropship"}, true)
	supply.register_craft(SHIP2)
	var state: Dictionary = campaign.export_state()
	state.departures_by_craft_id = {}; state.selected_location_id = "homebase"; state.selected_job_id = ""
	# Wie nach Kapitel 1 im echten Spiel: die Aussenposten-Person gehoert zum Bodentrupp ft1 und fliegt mit.
	var definitions := [{"id": "ft1", "lead_unit_id": "campaign_leader", "member_unit_ids": ["campaign_leader", "campaign_outpost_recruit"]}]
	var craft := {"definition": first, "pilot_id": "campaign_pilot", "staged_unit_ids": ["campaign_leader", "campaign_outpost_recruit"], "staged_fireteam_ids": ["ft1", "ft1"], "fireteam_definitions": definitions}
	var payload := {"schema_version": 1, "roster": roster, "craft": craft, "fleet": [{"definition": first, "pilot_id": "campaign_pilot", "location": "homebase"}, {"definition": second, "pilot_id": "campaign_rescue_pilot", "location": "homebase"}], "campaign": state, "supply": supply.export_state(), "onboarding": onboarding.export_state()}
	payload.base_personnel = {"version": 1, "units": {}}
	var aboard := {"campaign_leader": SHIP1, "campaign_pilot": SHIP1, "campaign_rescue_pilot": SHIP2, "campaign_outpost_recruit": SHIP1}
	for person: Dictionary in roster:
		var craft_id := String(aboard.get(person.unit_id, ""))
		payload.base_personnel.units[person.unit_id] = {"position": [0, 0], "status": "outside" if craft_id.is_empty() else "aboard", "craft_id": craft_id, "bed_id": ""}
	return payload

func _finish() -> void:
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("CAMPAIGN_WRECK_CRATER_SORTIE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _item_total(item: String) -> int:
	var total := 0
	for container in Dictionary(_runtime.get("_supply").get_supply_snapshot().inventory).values():
		total += int(Dictionary(Dictionary(container).get("items", {})).get(item, 0))
	return total

func _credits() -> int:
	return int(_supply().get("credits", 0))

# ---------------------------------------------------------------- Beobachtung je Tick (nur lesend)

func _attach_watch(mission: Node) -> void:
	_sim = mission.get_node("SimulationRoot")
	_waves = mission.get_node_or_null("EnemyWaveController")
	_driver = mission.get_node("CombatLoopDriver")
	_registry = mission.get_node("UnitRegistry")
	_game_s = 0.0
	_t0 = 0.0
	if _waves != null: _attach_offset = maxf(float(_waves.get("first_wave_delay_seconds")) - float(_waves.get("_time_until_next_wave")), 0.0)
	_wreck_pos = MAP.load_from_file(MAP_PATH).get_marker_position("objective_point")
	_sim.connect("tick_processed", _on_wreck_tick)
	var setup: Node = mission.get_node_or_null("MissionSetup")
	if setup != null: print("WRECK_SETUP hex_setup_pending=%s error=%s attempts=%s" % [str(Array(setup.get("_hex_setup_pending")).size()), str(setup.get("_hex_setup_error")), str(setup.get("_hex_setup_attempts"))])
	for id in LOOTERS:
		print("WRECK_HEX_START %s im_register=%s hex_state_leer=%s" % [id, str(_registry.has_unit(id)), str(Dictionary(_sim.call("get_hex_unit_state", id)).is_empty())])
	print("WRECK_WATCH attached wave_controller=%s wave_now=%d until_next=%s delay_first=%s" % [str(_waves != null), int(_waves.call("get_current_wave_number")) if _waves != null else -1, str(_waves.get("_time_until_next_wave")) if _waves != null else "-", str(_waves.get("first_wave_delay_seconds")) if _waves != null else "-"])

func _on_wreck_tick(_tick: int) -> void:
	if not is_instance_valid(_sim): return
	_tick_count += 1
	_game_s += float(_sim.call("get_last_tick_delta"))
	var wave: int = int(_waves.call("get_current_wave_number")) if is_instance_valid(_waves) else 0
	if wave != _last_wave:
		_last_wave = wave
		_wave_at[wave] = _game_s - _t0
		print("WRECK_WAVE_START wave=%d seit_t0=%.1f s until_next=%s" % [wave, _game_s - _t0, str(_waves.get("_time_until_next_wave"))])
		for id in LOOTERS:
			var unit: Node = _registry.get_unit(id) if _registry.has_unit(id) else null
			print("WRECK_HEX %s im_register=%s hex_state_leer=%s sichtbar=%s" % [id, str(unit != null), str(Dictionary(_sim.call("get_hex_unit_state", id)).is_empty()), str((unit as CanvasItem).visible) if unit != null else "-"])
		_obs_line("welle%d" % wave)
	if _tick_count % 5 != 0 or not is_instance_valid(_driver): return
	var gates: Dictionary = _driver.call("get_mission_scenario_runtime_gate_snapshot")
	var cleared := PackedStringArray(gates.get("completed_step_ids", [])).has("clear_looters")
	if cleared and _clear_at < 0.0:
		_clear_at = _game_s - _t0
		print("WRECK_CLEAR_LOOTERS seit_t0=%.1f s wave=%d" % [_clear_at, wave])
		if wave < 2: _cleared_early = true
	var fit: Dictionary = _driver.call("get_enemy_group_fit_counts")
	var fit_text := str(fit)
	if fit_text != _fit_log:
		_fit_log = fit_text
		print("WRECK_FIT seit_t0=%.1f s wave=%d fit=%s" % [_game_s - _t0, wave, fit_text])
	if wave < 2 and fit.has("looters_pistol") and int(fit.looters_pistol) == 0 and not _later_group_zero_early:
		_later_group_zero_early = true
		_zero_early_wave = wave
	if wave == 1 and fit.has("looters_smg") and int(fit.looters_smg) == 0 and not cleared:
		_wave1_all_down_open = true
	var leader: Node2D = _registry.get_unit("campaign_leader") as Node2D if is_instance_valid(_registry) else null
	for id in LOOTERS:
		var unit: Node2D = _registry.get_unit(id) as Node2D if _registry.has_unit(id) else null
		if unit == null or not is_instance_valid(unit): continue
		_looter_seen[id] = true
		var wreck_dist: float = unit.global_position.distance_to(_wreck_pos)
		if not _looter_t_first.has(id):
			_looter_t_first[id] = _game_s
			_looter_dwreck_first[id] = wreck_dist
		elif not _looter_dwreck_40.has(id) and not _looter_fell_before_40.has(id):
			if String(unit.call("get_vital_state")) != "fit": _looter_fell_before_40[id] = wreck_dist
			elif _game_s - float(_looter_t_first[id]) >= 40.0: _looter_dwreck_40[id] = wreck_dist
		var distance: float = unit.global_position.distance_to(leader.global_position) if leader != null else -1.0
		if not _looter_first.has(id): _looter_first[id] = distance
		_looter_best[id] = minf(float(_looter_best.get(id, distance)), distance)
	if _game_s >= _next_log:
		_next_log = _game_s + 10.0

## Eine knappe Zeile je Welle (und beim Nachsetzen): Truppleben, lebende Pluenderer, kleinster Abstand Trupp - Pluenderer, Befehlsquelle der Pluenderer.
func _obs_line(label: String) -> void:
	if not is_instance_valid(_registry): return
	var fit := 0
	var down := 0
	var nearest := -1.0
	var sources := {}
	var leader: Node2D = _registry.get_unit("campaign_leader") as Node2D if _registry.has_unit("campaign_leader") else null
	for id in LOOTERS:
		var unit: Node2D = _registry.get_unit(id) as Node2D if _registry.has_unit(id) else null
		if unit == null or not is_instance_valid(unit): continue
		if String(unit.call("get_vital_state")) == "fit":
			fit += 1
			var cmd = unit.call("get_current_unit_command") if unit.has_method("get_current_unit_command") else null
			sources[String(cmd.get("source_command_type")) if cmd != null else "none"] = true
			if leader != null:
				var d: float = leader.global_position.distance_to(unit.global_position)
				nearest = d if nearest < 0.0 else minf(nearest, d)
		else:
			down += 1
	print("WRECK_OBS %s t=%.0f fit=%d down=%d nearest=%.0f leader_hp=%s quellen=%s" % [label, _game_s - _t0, fit, down, nearest, str(leader.call("get_health")) if leader != null else "-", str(sources.keys())])

# ---------------------------------------------------------------- Ablauf

func _read_identities() -> void:
	var operations: Dictionary = _screen.call("get_operations_snapshot")
	var craft: Dictionary = operations.selected_craft
	_craft_id = String(craft.id)
	_pilot_id = String(craft.pilot_id)
	_team_id = String(Array(craft.payload_fireteam_ids)[0])
	_crew_ids.clear()
	for team: Dictionary in Array(operations.fireteams):
		if String(team.id) == _team_id:
			for unit: Dictionary in Array(team.members): _crew_ids.append(String(unit.id))

func _open_flow() -> void:
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")

func _run() -> void:
	Engine.time_scale = 4.0
	_configure_entry()
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	await process_frame
	_flow.set_process(false)
	var payload: Dictionary = _fixture(_flow)
	_flow.queue_free()
	await process_frame
	var saved: Dictionary = STORE.save_checkpoint(payload)
	if not _check(bool(saved.get("ok", false)), "Fixture: Speicherpunkt nach Kapitel 1 (zwei Schiffe, vier Personen) gespeichert"):
		print("FIXTURE_SAVE ", saved); await _finish(); return
	START.request_start(self, "campaign", "continue")
	await _open_flow()
	_read_identities()
	print("WRECK_SQUAD crew_ids=%s pilot=%s team=%s" % [str(_crew_ids), _pilot_id, _team_id])
	for person_id in _crew_ids:
		if person_id == _pilot_id: continue
		var gear: Dictionary = _screen.call("_get_member_loadout", person_id)
		print("WRECK_GEAR %s before=%s" % [person_id, str(gear)])
		if String(gear.get("weapon_1", "none")) == "none":
			var equip: Dictionary = _screen.call("request_operation", "inventory_equip", {"unit_id": person_id, "craft_id": _craft_id, "source_container_id": "base:homebase", "item_id": "pistol", "slot": "weapon_1"})
			_check(bool(equip.get("ok", false)), "%s zieht eine Pistole aus dem Basislager" % person_id)
	_check(_crew_ids.has("campaign_leader") and _crew_ids.has("campaign_outpost_recruit"), "Kaderliste des Bodentrupps: Truppfuehrer und Aussenposten-Person (%s)" % str(_crew_ids))
	if not await _board_actual_base_crew():
		await _finish(); return
	var snapshot: Dictionary = _campaign()
	var chapter_ok := true
	for id in CHAPTER_ONE: chapter_ok = chapter_ok and String(Dictionary(snapshot.jobs).get(id, {}).get("status", "")) == "completed"
	_check(chapter_ok and Dictionary(snapshot.jobs).has(JOB) and String(snapshot.jobs[JOB].status) == "offered", "Fortsetzen: Kapitel 1 abgeschlossen, neuer Auftrag steht als offered")
	var credits_before := _credits()
	var salvage_before := _item_total("salvage")
	var armor_before := _item_total("armor_medium")
	var accepted: Dictionary = _runtime.call("request_operation", "accept_job", {"job_id": JOB})
	if not _check(bool(accepted.get("ok", false)), "Auftrag annehmen"):
		print("ACCEPT_RESULT ", accepted); await _finish(); return
	_check(bool(_runtime.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": JOB}).get("ok", false)), "Ziel waehlen")
	if not await _launch_and_land(JOB, MAP_PATH):
		await _finish(); return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	_attach_watch(mission)
	if not await _pilot_safe_aboard(mission, controller): await _finish(); return
	_check(bool(controller.call("set_selected_fireteams_fire_rule", "free")), "Truppfuehrer: Waffen frei")
	if not await _move_and_use(mission, "satellite_data", "salvage_wreck", MAP_PATH): await _finish(); return
	await _await_looters(controller)
	if not await _move_and_use(mission, "objective_point", "recover_wreck_crate", MAP_PATH): await _finish(); return
	if not await _move_and_use(mission, "ship_return", "return_to_ship", MAP_PATH): await _finish(); return
	if not await _wait_homebase(): await _finish(); return
	_flow.call("_show_homebase")
	_final_checks(credits_before, salvage_before, armor_before)
	await _reload_checks()
	await _finish()

func _pilot_safe_aboard(mission: Node, controller: Node) -> bool:
	var sim: Node = mission.get_node("SimulationRoot")
	var access: Dictionary = controller.get_campaign_ground_ship_access(_craft_id)
	var pilot_plan: Dictionary = sim.plan_hex_ground_actor_approach(PackedStringArray([_pilot_id]), access.position, 96.0) if access.get("ok", false) else {}
	if not _check(pilot_plan.get("ok", false), "Pilot bekommt ein erlaubtes Ziel am Schiffszugang"): return false
	var token := "wreck-safe-pilot"
	sim.enqueue_command({"type": "move_to_position", "unit_id": _pilot_id, "team_id": "team_alpha", "target_position": pilot_plan.targets[_pilot_id], "command_token": token, "move_speed_factor": 1.0, "source_command_type": "pilot_board"})
	if not await _wait(func(): return sim.has_hex_destination_arrived(_pilot_id, token), 45000, "Pilot geht zum Schiffszugang"): return false
	var boarding: Dictionary = controller.request_campaign_crew_boarding(_craft_id, "", _pilot_id)
	if not _check(boarding.get("ok", false), "Pilot steigt ein"): print("PILOT_BOARDING ", boarding); return false
	return await _wait(func(): return controller.get_campaign_pilot_flight_guard(_craft_id, false).get("ok", false) and sim.get_hex_unit_state(_pilot_id).is_empty(), 15000, "Pilot sitzt sicher im Schiff")

func _cleared_now() -> bool:
	return is_instance_valid(_driver) and PackedStringArray(_driver.call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids", [])).has("clear_looters")

func _leader_fit() -> bool:
	var leader: Node = _registry.get_unit("campaign_leader") if is_instance_valid(_registry) else null
	return leader != null and is_instance_valid(leader) and String(leader.call("get_vital_state")) == "fit"

## Nur lesend, zweimal je Lauf: warum bleibt ein lebender Pluenderer ungeschossen? Je Paar Abstand, Reichweite, Sichtlinie, Halten; Befehle und Bewegungsstand beider Seiten.
func _obs_stall() -> void:
	var vis = _driver.call("_get_combat_visibility_system")
	var terrain = _driver.call("_get_terrain_registry")
	var units: Array = []
	for id in _crew_ids:
		if id != _pilot_id: units.append(String(id))
	for id in LOOTERS: units.append(id)
	for id in units:
		var unit: Node2D = _registry.get_unit(id) as Node2D if _registry.has_unit(id) else null
		if unit == null or not is_instance_valid(unit): continue
		var cmd = unit.call("get_current_unit_command") if unit.has_method("get_current_unit_command") else null
		var readout: Dictionary = _sim.call("get_hex_movement_readout", id)
		var hex: Dictionary = _sim.call("get_hex_unit_state", id)
		print("WRECK_STALL %s t=%.0f vital=%s hp=%s pos=%s grid=%s cmd=%s src=%s move=%s/%s fire=%s hold=%s" % [id, _game_s - _t0, str(unit.call("get_vital_state")), str(unit.call("get_health")), str(unit.global_position), str(hex.get("grid", "-")), str(cmd.get("command_type")) if cmd != null else "none", str(cmd.get("source_command_type")) if cmd != null else "-", str(readout.get("status", "")), str(readout.get("reason", "")), str(unit.call("get_fire_status")), str(_driver.call("_enemy_should_hold_position", unit)) if id.begins_with("wreck_looter") else "-"])
	for fid in _crew_ids:
		var friend: Node2D = _registry.get_unit(String(fid)) as Node2D if _registry.has_unit(String(fid)) else null
		if friend == null or String(fid) == _pilot_id: continue
		for id in LOOTERS:
			var enemy: Node2D = _registry.get_unit(id) as Node2D if _registry.has_unit(id) else null
			if enemy == null or String(enemy.call("get_vital_state")) != "fit": continue
			var r_f: float = _driver.call("_get_weapon_attack_range", friend, enemy)
			var r_e: float = _driver.call("_get_weapon_attack_range", enemy, friend)
			print("WRECK_STALL_PAIR %s<->%s dist=%.0f range_friend=%.0f range_enemy=%.0f los_friend=%s los_enemy=%s detect=%.0f" % [fid, id, friend.global_position.distance_to(enemy.global_position), r_f, r_e, str(vis.call("has_line_of_sight_between_nodes", friend, enemy, r_f, terrain)), str(vis.call("has_line_of_sight_between_nodes", enemy, friend, r_e, terrain)), float(_driver.call("_get_effective_range", enemy))])

## Position des dem Truppfuehrer naechsten lebenden Pluenderers; gibt es keinen, das Erscheinungsfeld spawn_bravo.
func _nearest_looter_position() -> Vector2:
	var leader: Node2D = _registry.get_unit("campaign_leader") as Node2D
	var best := Vector2.INF
	var best_d := INF
	for id in LOOTERS:
		var unit: Node2D = _registry.get_unit(id) as Node2D if _registry.has_unit(id) else null
		if unit == null or not is_instance_valid(unit) or String(unit.call("get_vital_state")) != "fit": continue
		var d: float = leader.global_position.distance_to(unit.global_position)
		if d < best_d:
			best_d = d
			best = unit.global_position
	if best == Vector2.INF: return MAP.load_from_file(MAP_PATH).get_marker_position("spawn_bravo")
	return best

## Die Pluenderer kommen laut Plan von selbst auf den Trupp zu. Kommen sie nicht, wird das gemeldet und der Trupp geht zu ihnen.
func _await_looters(controller: Node) -> void:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 100000 and not _cleared_now() and _leader_fit():
		await physics_frame
	var came_alone := _cleared_now()
	print("WRECK_QUESTION looters_came_alone=%s seit_t0=%.1f s waves=%s seen=%s" % [str(came_alone), _game_s - _t0, str(_wave_at), str(_looter_seen.keys())])
	if not came_alone and _leader_fit():
		# Wie ein Spieler: alle 10 s Spielzeit beide Truppmitglieder neu auf den naechsten lebenden Pluenderer schicken, bis alle besiegt sind.
		var real_start := Time.get_ticks_msec()
		var orders := 0
		var next_order_s := _game_s
		while not _cleared_now() and _leader_fit() and Time.get_ticks_msec() - real_start < 300000:
			if _game_s >= next_order_s:
				next_order_s = _game_s + 10.0
				var target: Vector2 = _nearest_looter_position()
				if controller.issue_right_click_command_for_test(target, "take", false) and bool(controller.call("execute_selected_fireteam_orders")):
					orders += 1
					if orders == 1 or orders % 6 == 0: _obs_line("befehl%d" % orders)
					if orders == 14 or orders == 40: _obs_stall()
			await physics_frame
		_check(_cleared_now() or not _leader_fit(), "Trupp besiegt die Plünderer (%d Befehle, %.0f s Spielzeit)" % [orders, _game_s - _t0])
		_check(orders > 0, "Trupp hat die Plünderer angegriffen (Befehle: %d)" % orders)
	_check(_leader_fit(), "Truppfuehrer lebt nach den Plünderern")
	_check(_cleared_now(), "clear_looters ist erledigt")

func _final_checks(credits_before: int, salvage_before: int, armor_before: int) -> void:
	var job: Dictionary = Dictionary(_campaign().jobs).get(JOB, {})
	_check(String(job.get("status", "")) == "completed", "Auftrag abgeschlossen (Status %s)" % String(job.get("status", "?")))
	_check(_credits() == credits_before + 200, "Credits +200 (vorher %d, jetzt %d)" % [credits_before, _credits()])
	_check(_item_total("salvage") == salvage_before + 8, "Schrott +8 im Schiff oder Lager (vorher %d, jetzt %d)" % [salvage_before, _item_total("salvage")])
	_check(_item_total("armor_medium") == armor_before + 1, "mittlere Rüstung +1 (vorher %d, jetzt %d)" % [armor_before, _item_total("armor_medium")])
	_check(_wave_at.has(1) and float(_wave_at.get(1, 0.0)) + _attach_offset >= 74.0, "erste Welle erscheint erst >= 75 s nach Einsatzbeginn (seit Anhaengen %s, schon vergangen %.1f s)" % [str(_wave_at), _attach_offset])
	_check(_wave_at.has(2) and absf(float(_wave_at.get(2, 0.0)) - float(_wave_at.get(1, 0.0)) - 60.0) < 3.0, "zweite Welle 60 s nach der ersten (%s)" % str(_wave_at))
	_check(not _cleared_early, "clear_looters war vor dem Erscheinen der zweiten Welle NICHT fertig")
	_check(_looter_seen.size() == 4, "alle vier Plünderer sind aufgetreten (%s)" % str(_looter_seen.keys()))
	var approached := 0
	for id in _looter_seen:
		if float(_looter_best.get(id, 99999.0)) < float(_looter_first.get(id, 0.0)) - 200.0: approached += 1
	_check(approached >= 1, "mindestens ein Plünderer ist merklich auf den Trupp zugelaufen (%d von %d, erste/beste Abstaende %s / %s)" % [approached, _looter_seen.size(), str(_looter_first), str(_looter_best)])
	var closer := 0
	for id in ["wreck_looter_01", "wreck_looter_02"]:
		if _looter_dwreck_40.has(id) and float(_looter_dwreck_40[id]) < float(_looter_dwreck_first.get(id, 0.0)) - 100.0: closer += 1
	_check(closer == 2, "Plünderer der Welle 1 sind 40 s nach Erscheinen näher am Wrack als beim Erscheinen (Abstand beim Erscheinen %s, nach 40 s %s, vorher gefallen %s)" % [str(_looter_dwreck_first), str(_looter_dwreck_40), str(_looter_fell_before_40)])
	print("WRECK_QUESTION wave1_all_down_while_open=%s pistol_group_counted_zero_before_wave2=%s (bei Welle %d) cleared_at=%.1f" % [str(_wave1_all_down_open), str(_later_group_zero_early), _zero_early_wave, _clear_at])

func _reload_checks() -> void:
	if not await _save_verified_milestone("wreck_crater_salvage"): return
	var salvage_home := _item_total("salvage")
	var armor_home := _item_total("armor_medium")
	var credits_home := _credits()
	_flow.queue_free()
	await process_frame
	START.request_start(self, "campaign", "continue")
	await _open_flow()
	var restored: Dictionary = Dictionary(_campaign().jobs).get(JOB, {})
	_check(String(restored.get("status", "")) == "completed", "Fortsetzen nach dem Auftrag: Auftrag bleibt abgeschlossen")
	_check(_item_total("salvage") == salvage_home and _item_total("armor_medium") == armor_home and _credits() == credits_home, "Fortsetzen: Schrott (%d), Rüstung (%d) und Credits (%d) bleiben erhalten" % [salvage_home, armor_home, credits_home])
