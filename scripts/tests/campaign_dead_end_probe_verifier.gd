extends "res://scripts/tests/campaign_five_actual_sorties_verifier.gd"
## K2: zwei moegliche Sackgassen der Kampagne ueber die Spielwege nachgestellt.
## Fall 1 "Haendler verpasst": Auftrag 2 wird gewonnen, der Haendler am Aussenposten wird NICHT angesprochen,
##   das Schiff fliegt heim. Gefragt: Sagt das Spiel, was fehlt? Gibt es einen Weg, benit_delivery freizuschalten?
## Fall 2 "Treibstoff reicht nicht": Es wird nie vor einem Flug aufgetankt (das tut der Elterntest). Aus den
##   60 Anfangseinheiten werden 24 (Satellit) + 16 (Aussenposten) + 16 (Wiederbesuch) verbraucht; gefragt: Kann der
##   Spieler am Zielort ohne Rueckflug-Treibstoff stehen? Was sieht er, wenn der Tank zu Hause nicht reicht?
## Es wird kein Spielcode geschrieben und nichts eingeschoben. Rot bleibt rot: Jede Pruefung sagt, was ein Spieler braucht.

const SATELLITE_MAP := "res://maps/satellite_crash_site.json"
const OUTPOST_MAP := "res://maps/trade_outpost.json"
const OUTPOST_ROUND_TRIP := 16.0
const SATELLITE_ROUND_TRIP := 24.0

## Zweiter Flug zum selben Ort mit demselben Szenarionamen: Der Elterntest benutzt feste Anfrage-Nummern
## ("loop:jump:<szenario>"); der Besitzer beantwortet eine wiederholte Nummer aus dem Beleg, ohne zu fliegen.
## Die Bedienoberflaeche vergibt jedes Mal neue Nummern, deshalb hier dieselben Schritte mit eigener Endung.
func _launch_and_land_again(scenario_id: String, map_path: String, suffix: String) -> bool:
	_screen.call("request_operation", "craft", {"craft_id": _craft_id})
	_screen.call("request_operation", "focus_fireteam", {"fireteam_id": _team_id})
	if not await _prepare_sortie_base(): return false
	var launch: Dictionary = _screen.call("request_operation", "start", {"craft_id": _craft_id})
	if not _check(bool(launch.get("ok", false)), scenario_id + " " + suffix + ": Schiff hebt ab (" + _msg(launch) + ")"): return false
	if not _check(String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == "moon_orbit", scenario_id + " " + suffix + ": Mondorbit erreicht"): return false
	var destination := String(_campaign().get("selected_location_id", ""))
	var destination_orbit := String(Dictionary(_space().get("location_orbits", {})).get(destination, ""))
	if not _check(not destination_orbit.is_empty(), scenario_id + " " + suffix + ": Ziel hat einen Orbit"): return false
	var jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": destination_orbit, "request_id": "k2:jump:" + suffix})
	if not _check(bool(jump.get("ok", false)) and not bool(jump.get("replayed", false)), scenario_id + " " + suffix + ": Quantumsprung beginnt (" + _msg(jump) + ")"): return false
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == destination_orbit, 15000, scenario_id + " " + suffix + ": Ziel-Orbit erreicht"): return false
	var approach: Dictionary = _screen.call("request_operation", "space_begin_approach", {"craft_id": _craft_id, "location_id": destination, "request_id": "k2:approach:" + suffix})
	if not _check(bool(approach.get("ok", false)), scenario_id + " " + suffix + ": Anflug angenommen (" + _msg(approach) + ")"): return false
	if not await _wait(func(): return _flow.get("_active_mission") != null, 180000, scenario_id + " actual mission instance exists"): return false
	_flow.call("_show_mission")
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	if not await _wait(func(): return String(Dictionary(controller.call("_find_mission_dropship_card_entry", _craft_id)).get("state", "")) == "waiting", 30000, scenario_id + " " + suffix + ": Schiff wartet am Ziel"): return false
	var map = MAP.load_from_file(map_path)
	var view: Node = mission.get_node("Primary3DView")
	var lz: Vector2 = _landing_target(map)
	view.call("focus_world_position", lz)
	controller.call("_on_mission_dropship_card_set_lz_pressed", _craft_id)
	if not _check(bool(controller.call("_place_lz_from_screen_position", view.call("world_to_screen_position", lz))), scenario_id + " " + suffix + ": Landeplatz gesetzt"): return false
	controller.call("_on_mission_dropship_card_drop_pressed", _craft_id)
	if not await _wait(func(): return _all_crew_deployed(controller) and int(mission.get_node("SimulationRoot").call("get_tick")) > 0, 30000, scenario_id + " " + suffix + ": Besatzung abgesetzt"): return false
	_check(String(mission.get_node("MissionSetup").get("scenario_file_path")).get_file().get_basename() == scenario_id, scenario_id + " " + suffix + ": geladenes Szenario (beobachtet " + String(mission.get_node("MissionSetup").get("scenario_file_path")) + ")")
	return true

func _fuel_now() -> float:
	return float(Dictionary(_supply().get("fuel_by_craft_id", {})).get(_craft_id, -1.0))

func _credits_now() -> int:
	return int(_supply().get("credits", -1))

func _msg(reply: Dictionary) -> String:
	return "reason=%s message=\"%s\" ok=%s" % [String(reply.get("reason", "")), String(reply.get("message", "")), str(reply.get("ok", null))]

func _job_status_of(job: String) -> String:
	return String(Dictionary(Dictionary(_campaign().get("jobs", {})).get(job, {})).get("status", ""))

func _progress() -> Dictionary:
	return Dictionary(_campaign().get("progress", {}))

func _guidance_text() -> String:
	var tutorial: Control = _flow.get("_campaign_tutorial")
	if not is_instance_valid(tutorial): return "<keine Hilfe>"
	tutorial.call("refresh")
	var label: Label = tutorial.get("_guidance")
	return String(label.text) if is_instance_valid(label) else "<kein Hilfetext>"

func _next_step_id() -> String:
	return String(Dictionary(_flow.call("get_singleplayer_snapshot").get("onboarding", {})).get("next_step_id", ""))

func _hostile_alive_count(mission: Node) -> int:
	var own_team := ""
	if not _crew_ids.is_empty():
		var leader: Node = mission.get_node("UnitRegistry").get_unit(_crew_ids[0])
		if is_instance_valid(leader): own_team = String(leader.get_team_id())
	var count := 0
	for actor: Node in mission.get_node("UnitRegistry").get_all_units():
		if not is_instance_valid(actor) or not actor.has_method("get_team_id") or String(actor.get_team_id()) == own_team: continue
		if float(actor.get_health()) > 0.0: count += 1
	return count

## Wie der Elterntest: Pilot sichern, Trupp sammeln, Wachen angreifen, bis der Schritt clear_outpost steht.
func _fight_through_guards(mission: Node, controller: Node, tag: String, map_path: String) -> bool:
	var sim: Node = mission.get_node("SimulationRoot")
	var access: Dictionary = controller.get_campaign_ground_ship_access(_craft_id)
	var pilot_plan: Dictionary = sim.plan_hex_ground_actor_approach(PackedStringArray([_pilot_id]), access.position, 96.0) if access.get("ok", false) else {}
	if not _check(pilot_plan.get("ok", false), tag + ": Pilot bekommt einen Weg zum Schiff"): return false
	var pilot_token := "k2-safe-pilot:" + tag
	sim.enqueue_command({"type":"move_to_position","unit_id":_pilot_id,"team_id":"team_alpha","target_position":pilot_plan.targets[_pilot_id],"command_token":pilot_token,"move_speed_factor":1.0,"source_command_type":"pilot_board"})
	if not await _wait(func(): return sim.has_hex_destination_arrived(_pilot_id, pilot_token), 45000, tag + ": Pilot geht zum Schiff"): return false
	var boarding: Dictionary = controller.request_campaign_crew_boarding(_craft_id, "", _pilot_id)
	if not _check(boarding.get("ok", false), tag + ": Pilot steigt ein"): print("PILOT_BOARDING ", boarding); return false
	if not await _wait(func(): return controller.get_campaign_pilot_flight_guard(_craft_id, false).get("ok", false) and sim.get_hex_unit_state(_pilot_id).is_empty(), 15000, tag + ": Pilot ist an Bord"): return false
	_check(bool(controller.call("set_selected_fireteams_fire_rule", "free")), tag + ": Waffen frei")
	var enemy_target: Vector2 = MAP.load_from_file(map_path).get_marker_position("spawn_enemy_defense")
	var rally: Vector2 = Vector2(access.position).lerp(enemy_target, 0.80)
	controller.call("_create_waypoints_for_selected_fireteams", rally, true)
	if not _check(controller.execute_selected_fireteam_orders(), tag + ": Sammeln GO"): return false
	var needed_live: int = _crew_ids.size() - (1 if _crew_ids.has(_pilot_id) else 0)
	if not _check(needed_live >= 1, tag + ": mindestens eine Person ausser dem Piloten"): return false
	if not await _wait(func():
		var live := 0
		for id in _crew_ids:
			var actor = sim.call("_resolve_known_unit_for_contract", String(id))
			if sim.get_hex_unit_state(String(id)).is_empty() or not is_instance_valid(actor) or actor.get_vital_state() != "fit": continue
			live += 1
			if actor.global_position.distance_to(rally) > 400.0: return false
		return live >= needed_live, 180000, tag + ": actual ground squad gathers before enemy contact"):
		_trace_actual_combat("rally_timeout"); return false
	if not _check(controller.issue_right_click_command_for_test(enemy_target, "take", false), tag + ": TAKE-Plan"): return false
	_check(bool(controller.call("execute_selected_fireteam_orders")), tag + ": Anmarsch GO")
	if not await _wait(func():
		if PackedStringArray(mission.get_node("CombatLoopDriver").get_mission_scenario_runtime_gate_snapshot().get("completed_step_ids", [])).has("clear_outpost"): return true
		var active_ground_members := 0
		for id in _crew_ids:
			var actor = sim.call("_resolve_known_unit_for_contract", String(id))
			if not is_instance_valid(actor) or sim.get_hex_unit_state(String(id)).is_empty() or String(actor.get_vital_state()) != "fit": continue
			active_ground_members += 1
			if actor.global_position.distance_to(enemy_target) > 640.0: return false
		return active_ground_members > 0, 180000, tag + ": actual squad reaches outpost combat area"):
		_dump("k2_outpost_approach"); return false
	if not await _wait(func(): return PackedStringArray(mission.get_node("CombatLoopDriver").call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids", [])).has("clear_outpost"), 60000, tag + ": actual combat defeats outpost guards"):
		_dump("k2_outpost_combat"); return false
	return true

func _run() -> void:
	Engine.time_scale = 4.0
	_configure_entry()
	_flow = FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen"); _runtime = _flow.get("_singleplayer_runtime")
	var initial: Dictionary = _screen.call("get_operations_snapshot")
	_pilot_id = String(Dictionary(initial.get("selected_craft", {})).get("pilot_id", ""))
	if not _check(not _pilot_id.is_empty(), "Pilot ist vor dem ersten Einschiffen bekannt"): await _finish(); return
	if not await _prepare_initial_base(): await _finish(); return
	var operations: Dictionary = _screen.call("get_operations_snapshot")
	var craft: Dictionary = operations.selected_craft
	_craft_id = String(craft.id); _pilot_id = String(craft.pilot_id)
	_team_id = String(Array(craft.payload_fireteam_ids)[0])
	for team: Dictionary in Array(operations.fireteams):
		if String(team.id) == _team_id:
			for unit: Dictionary in Array(team.members): _crew_ids.append(String(unit.id))
	var start_fuel := _fuel_now()
	var start_credits := _credits_now()
	print("K2_START fuel=%s credits=%d" % [str(start_fuel), start_credits])
	_check(is_equal_approx(start_fuel, 60.0), "Kampagnenstart: Schiff hat 60 Treibstoff (beobachtet %s)" % str(start_fuel))
	# ---- Auftrag 1 wie im Elterntest, aber OHNE vorher aufzutanken ----
	_check(_screen.call("request_operation", "accept_job", {"job_id":"satellite_recovery"}).get("ok", false), "Auftrag 1 angenommen")
	_check(_screen.call("request_operation", "select_destination", {"location_id":"satellite_crash", "job_id":"satellite_recovery"}).get("ok", false), "Ziel Satellit gewaehlt")
	if not await _launch_and_land("satellite_recovery", SATELLITE_MAP): await _finish(); return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	if not await _move_and_use(mission, "satellite_data", "secure_satellite", SATELLITE_MAP): await _finish(); return
	if not await _move_and_use(mission, "ship_return", "return_to_ship", SATELLITE_MAP): await _finish(); return
	if not await _wait_homebase(): await _finish(); return
	_flow.call("_show_homebase")
	_check(bool(_runtime.call("request_operation", "campaign_upload", {"job_id":"satellite_recovery"}).get("ok", false)), "Chip hochgeladen")
	var fuel_after_one := _fuel_now()
	print("K2_AFTER_JOB1 fuel=%s credits=%d" % [str(fuel_after_one), _credits_now()])
	_check(is_equal_approx(fuel_after_one, start_fuel - SATELLITE_ROUND_TRIP), "Nach Auftrag 1 ohne Nachtanken: 60 - 24 = 36 Treibstoff (beobachtet %s)" % str(fuel_after_one))
	if not await _fall_1_haendler_verpasst(): await _finish(); return
	if not await _fall_2_treibstoff(): await _finish(); return
	await _finish()

# ---------------------------------------------------------------------------------------------
# Fall 1
# ---------------------------------------------------------------------------------------------
func _fall_1_haendler_verpasst() -> bool:
	print("K2_FALL1_BEGIN fuel=%s" % str(_fuel_now()))
	_flow.call("_show_homebase")
	var accepted: Dictionary = _runtime.call("request_operation", "accept_job", {"job_id":"outpost_recovery"})
	if not _check(bool(accepted.get("ok", false)), "Auftrag 2 angenommen"): print(accepted); return false
	_check(_runtime.call("request_operation", "select_destination", {"location_id":"trade_outpost", "job_id":"outpost_recovery"}).get("ok", false), "Ziel Handelsaussenposten gewaehlt (Treibstoff %s, ohne Nachtanken)" % str(_fuel_now()))
	if not await _launch_and_land("outpost_recovery", OUTPOST_MAP): return false
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	print("K2_FALL1_GUARDS_AT_FIRST_VISIT hostile_alive=%d" % _hostile_alive_count(mission))
	if not await _fight_through_guards(mission, controller, "Besuch 1", OUTPOST_MAP): return false
	if not await _move_and_use(mission, "recover_crate", "recover_crate", OUTPOST_MAP): return false
	# Beobachtung vor dem Abflug: Der Spieler hat den Haendler NICHT angesprochen.
	var contexts: Dictionary = Dictionary(_flow.call("get_singleplayer_snapshot").get("service_contexts_by_craft_id", {}))
	_check(not contexts.has(_craft_id), "Besuch 1: ohne Haendlerkontakt gibt es keinen Serviceort fuers Schiff (Beobachtung: %s)" % str(contexts.has(_craft_id)))
	var services: Control = _flow.get("_singleplayer_services")
	if is_instance_valid(services):
		services.call("set_selected_craft", _craft_id)
		await process_frame
		var back: Button = services.find_child("ServiceReturnHomebase", true, false)
		print("K2_FALL1_RETURN_BUTTON_BEFORE_LEAVING exists=%s visible=%s disabled=%s tooltip=\"%s\"" % [str(back != null), str(back.is_visible_in_tree()) if back != null else "-", str(back.disabled) if back != null else "-", back.tooltip_text if back != null else "-"])
	# Abflug: der Auftragsschritt return_to_ship fuehrt das Schiff heim, ohne dass der Haendler gebraucht wird.
	if not await _move_and_use(mission, "ship_return", "return_to_ship", OUTPOST_MAP): return false
	if not _check(await _wait_homebase(), "Fall 1.1: Abflug vom Aussenposten ohne Haendlerkontakt wird zugelassen, das Schiff landet zu Hause"): return false
	_flow.call("_show_homebase")
	var fuel_home := _fuel_now()
	print("K2_FALL1_HOME fuel=%s credits=%d job2=%s job3=%s progress=%s" % [str(fuel_home), _credits_now(), _job_status_of("outpost_recovery"), _job_status_of("benit_delivery"), str(_progress())])
	_check(_job_status_of("outpost_recovery") == "completed", "Fall 1.2: Auftrag 2 ist zu Hause abgeschlossen (beobachtet %s)" % _job_status_of("outpost_recovery"))
	var gate: Dictionary = _runtime.call("request_operation", "accept_job", {"job_id":"benit_delivery"})
	var availability: Dictionary = Dictionary(Dictionary(_campaign().get("job_availability", {})).get("benit_delivery", {}))
	print("K2_FALL1_BENIT_GATE accept=%s availability=%s" % [_msg(gate), str(availability)])
	_check(not bool(gate.get("ok", true)), "Fall 1.2: benit_delivery ist nach verpasstem Haendler gesperrt (beobachtet: %s)" % _msg(gate))
	var gate_message := String(gate.get("message", ""))
	_check(gate_message.contains("Handelsposten"), "Fall 1.2: die Sperrmeldung nennt den Handelsposten als Ursache (beobachtet: \"%s\")" % gate_message)
	_check(bool(availability.get("visible", false)), "Fall 1.2: benit_delivery steht auf der Auftragstafel, damit der Spieler die Sperrmeldung dort lesen kann (beobachtet visible=%s, Tafeltext sonst: \"Zurzeit keine verfuegbaren Auftraege.\")" % str(availability.get("visible", null)))
	var step := _next_step_id()
	var guidance := _guidance_text()
	print("K2_FALL1_HELP next_step_id=%s text=\"%s\"" % [step, guidance])
	_check(guidance.contains("Handelsposten") and guidance.contains("aufnehmen"), "Fall 1.2: die Kampagnenhilfe sagt dem Spieler, dass er am Handelsposten die Person aufnehmen muss (beobachtet: \"%s\")" % guidance)
	# Fall 1.3: erneut anfliegen
	var fuel_before_revisit := _fuel_now()
	var selected: Dictionary = _runtime.call("request_operation", "select_destination", {"location_id":"trade_outpost", "job_id":""})
	print("K2_FALL1_REVISIT_SELECT %s fuel=%s" % [_msg(selected), str(fuel_before_revisit)])
	if not _check(bool(selected.get("ok", false)), "Fall 1.3: der Spieler kann den Handelsaussenposten ohne Auftrag wieder ansteuern (beobachtet: %s)" % _msg(selected)): return true
	# Seit Handel H1/W3 (df700a832, 5720ddf1c; 24.11.) bleibt ein abgeschlossener Aussenposten als friedlicher Besuch offen: Der Wiederbesuch ohne Auftrag
	# laedt das Besuchsszenario aus open_outposts.json (trade_outpost_open_visit, ohne Gegner, ohne Zeitlimit), nicht mehr das Auftragsszenario outpost_recovery.
	# Die Sackgassenfrage bleibt dieselbe: Kann der Spieler den verpassten Haendler nachholen und die Person aufnehmen? Dazu wird der Besuch ueber dieses Szenario geflogen.
	var location_scenario := String(Dictionary(Dictionary(_campaign().get("locations", {})).get("trade_outpost", {})).get("scenario_file_path", "")).get_file().get_basename()
	var scenario := String(Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/open_outposts.json"))).get("trade_outpost", ""))
	print("K2_FALL1_REVISIT_SCENARIO from_location=%s open_visit=%s selected_mission_id=%s" % [location_scenario, scenario, String(_flow.get("_selected_mission_id"))])
	_check(scenario == "trade_outpost_open_visit" and String(_flow.get("_selected_mission_id")) == scenario, "Fall 1.3: der Wiederbesuch ohne Auftrag waehlt das friedliche Besuchsszenario trade_outpost_open_visit (beobachtet: gewaehlt %s, Datei %s)" % [String(_flow.get("_selected_mission_id")), scenario])
	if not await _launch_and_land_again(scenario, OUTPOST_MAP, "wiederbesuch"): return false
	mission = _flow.get("_active_mission")
	controller = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	var guards := _hostile_alive_count(mission)
	print("K2_FALL1_GUARDS_AT_REVISIT scenario=%s hostile_alive=%d" % [String(mission.get_node("MissionSetup").get("scenario_file_path")), guards])
	_check(guards == 0, "Fall 1.3: der friedliche Wiederbesuch hat keine Gegner (beobachtet: %d)" % guards)
	if guards > 0:
		if not await _fight_through_guards(mission, controller, "Besuch 2", OUTPOST_MAP): return false
	var contexts_before: Dictionary = Dictionary(_flow.call("get_singleplayer_snapshot").get("service_contexts_by_craft_id", {}))
	_check(not contexts_before.has(_craft_id), "Fall 1.3: Landung allein gibt noch keinen Serviceort")
	var trader_ok: bool = await _move_and_use(mission, "trade_service", "trade_service", OUTPOST_MAP)
	_check(trader_ok, "Fall 1.3: der Haendler (trade_service) ist beim Wiederbesuch erreichbar und benutzbar")
	if not trader_ok: return false
	_check(await _wait(func(): return Dictionary(_flow.call("get_singleplayer_snapshot").get("service_contexts_by_craft_id", {})).has(_craft_id), 3000, "Fall 1.3: nach der Haendlernutzung gibt es den Serviceort"), "Serviceort steht")
	var recruit: Dictionary = _runtime.call("request_operation", "campaign_recruit", {"craft_id": _craft_id})
	print("K2_FALL1_RECRUIT_ON_REVISIT %s progress=%s" % [_msg(recruit), str(_progress())])
	_check(bool(recruit.get("ok", false)) and bool(_progress().get("recruited_outpost", false)), "Fall 1.3: beim Wiederbesuch laesst sich die Person aufnehmen (beobachtet: %s)" % _msg(recruit))
	# Heimflug ueber den Rueckflugknopf des Versorgungsfensters (kein Auftragsschritt mehr offen).
	if not await _return_from_revisit(mission, controller): return false
	_flow.call("_show_homebase")
	var unlocked: Dictionary = Dictionary(Dictionary(_campaign().get("job_availability", {})).get("benit_delivery", {}))
	print("K2_FALL1_AFTER_REVISIT fuel=%s credits=%d progress=%s availability=%s" % [str(_fuel_now()), _credits_now(), str(_progress()), str(unlocked)])
	_check(bool(unlocked.get("can_accept", false)), "Fall 1.3: nach dem Wiederbesuch ist benit_delivery annehmbar (beobachtet: %s)" % str(unlocked))
	return true

func _return_from_revisit(mission: Node, controller: Node) -> bool:
	# Wie beim Pilot im Elterntest: legaler Zugangspunkt am Schiff, jede Person bekommt ihren Weg dorthin.
	var sim: Node = mission.get_node("SimulationRoot")
	var access: Dictionary = controller.get_campaign_ground_ship_access(_craft_id)
	if not _check(bool(access.get("ok", false)), "Wiederbesuch: Schiffszugang ist bekannt"): return false
	var ids: PackedStringArray = PackedStringArray()
	for id in _crew_ids:
		if not sim.get_hex_unit_state(String(id)).is_empty() and not ids.has(String(id)): ids.append(String(id))
	if not sim.get_hex_unit_state(_pilot_id).is_empty() and not ids.has(_pilot_id): ids.append(_pilot_id)
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(access.position), true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), "Wiederbesuch: Trupp geht zum Schiffszugang (GO)"): return false
	if not await _wait(func():
		for id in ids:
			var unit: Node2D = controller.call("_find_friendly_unit_by_id", String(id))
			if unit == null or unit.global_position.distance_to(Vector2(access.position)) > 130.0: return false
		return true, 90000, "Wiederbesuch: Trupp steht am Schiff"):
		_trace_actual_approach("k2_revisit_board_timeout")
		return false
	var boarding: Dictionary = {}
	var board_deadline: int = Time.get_ticks_msec() + 40000
	while Time.get_ticks_msec() < board_deadline:
		boarding = controller.request_campaign_crew_boarding(_craft_id)
		if bool(boarding.get("ok", false)): break
		for _i in 60: await physics_frame
	print("K2_REVISIT_BOARDING ", boarding)
	var diag_units: Array = []
	for id in ids:
		var u3: Node2D = controller.call("_find_friendly_unit_by_id", String(id))
		diag_units.append({"id":id, "dist_access":u3.global_position.distance_to(Vector2(access.position)) if u3 != null else -1.0, "dist_ship":u3.global_position.distance_to(Vector2(controller.call("_campaign_landed_craft_position", _craft_id))) if u3 != null else -1.0})
	print("K2_REVISIT_BOARDING_UNITS ", diag_units)
	if not await _wait(func(): return bool(controller.call("get_campaign_pilot_flight_guard", _craft_id).ok), 5000, "Wiederbesuch: Besatzung ist an Bord"): return false
	# Der Rueckflugknopf des Versorgungsfensters bleibt hier unsichtbar (nur beobachtet, siehe Bericht); der Knopf ruft
	# denselben Befehl return_homebase, den das Spiel auch ueber den Besitzer annimmt.
	var services: Control = _flow.get("_singleplayer_services")
	var back: Button = null
	if is_instance_valid(services):
		services.call("set_selected_craft", _craft_id)
		await process_frame
		back = services.find_child("ServiceReturnHomebase", true, false)
	print("K2_REVISIT_BUTTON exists=%s visible=%s disabled=%s tooltip=\"%s\" service_context_services=%s" % [str(back != null), str(back.is_visible_in_tree()) if back != null else "-", str(back.disabled) if back != null else "-", back.tooltip_text if back != null else "-", str(Dictionary(_runtime.call("_service_context", _craft_id)).get("services", []))])
	var result: Dictionary = _runtime.call("request_operation", "return_homebase", {"craft_id": _craft_id})
	print("K2_FALL1_REVISIT_RETURN %s" % _msg(result))
	if not _check(bool(result.get("ok", false)), "Wiederbesuch: Rueckflugbefehl wird angenommen (%s)" % _msg(result)): return false
	return await _wait_homebase()

# ---------------------------------------------------------------------------------------------
# Fall 2
# ---------------------------------------------------------------------------------------------
## Von zu Hause bis zum Anflug, ohne zu landen: Abheben, Sprung zum Zielorbit, Anflug. Gibt die Antworten zurueck.
func _probe_departure(tag: String, destination: String) -> Dictionary:
	var notes: Dictionary = {"start":{}, "jump":{}, "approach":{}, "reached_orbit":false}
	if not await _prepare_sortie_base(): return notes
	notes.start = _screen.call("request_operation", "start", {"craft_id": _craft_id})
	print("K2_FALL2_%s_START fuel=%s %s phase=%s" % [tag, str(_fuel_now()), _msg(notes.start), String(_space().get("phase", ""))])
	if not bool(notes.start.get("ok", false)): return notes
	var destination_orbit := String(Dictionary(_space().get("location_orbits", {})).get(destination, ""))
	notes.jump = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": destination_orbit, "request_id": "k2:fall2:jump:" + tag})
	print("K2_FALL2_%s_JUMP fuel=%s %s" % [tag, str(_fuel_now()), _msg(notes.jump)])
	if not bool(notes.jump.get("ok", false)): return notes
	notes.reached_orbit = await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == destination_orbit, 15000, "Fall 2 " + tag + ": Zielorbit erreicht")
	if not notes.reached_orbit: return notes
	notes.approach = _screen.call("request_operation", "space_begin_approach", {"craft_id": _craft_id, "location_id": destination, "request_id": "k2:fall2:approach:" + tag})
	print("K2_FALL2_%s_APPROACH fuel=%s %s" % [tag, str(_fuel_now()), _msg(notes.approach)])
	return notes

func _fall_2_treibstoff() -> bool:
	var fuel := _fuel_now()
	print("K2_FALL2_BEGIN fuel=%s credits=%d" % [str(fuel), _credits_now()])
	_flow.call("_show_homebase")
	var accepted: Dictionary = _runtime.call("request_operation", "accept_job", {"job_id":"benit_delivery"})
	if not _check(bool(accepted.get("ok", false)), "Fall 2: Auftrag 3 angenommen (%s)" % _msg(accepted)): return false
	_check(_runtime.call("request_operation", "select_destination", {"location_id":"satellite_crash", "job_id":"benit_delivery"}).get("ok", false), "Fall 2: Ziel Satellit gewaehlt")
	var reach: Dictionary = Dictionary(Dictionary(_flow.call("get_singleplayer_snapshot").get("space_travel", {})).get("fuel_reachability", {}))
	print("K2_FALL2_REACHABILITY fuel=%s %s" % [str(fuel), str(reach)])
	var satellite_reach: Dictionary = Dictionary(reach.get("satellite_crash", {}))
	# Regel 8 / Auftrag 21.11.: keine Rueckflugreserve mehr. "ok" heisst: die naechste Etappe (Abheben) ist bezahlbar; "route_ok" sagt, ob der ganze Hinweg reicht.
	_check(bool(satellite_reach.get("ok", false)) and not bool(satellite_reach.get("route_ok", true)) and float(satellite_reach.get("needed_total", 0.0)) > fuel, "Fall 2: die Erreichbarkeitsanzeige sagt, dass mit %s Treibstoff die naechste Etappe geht, der ganze Hinweg zum Satelliten aber nicht reicht (beobachtet: %s)" % [str(fuel), str(satellite_reach)])
	# 2.2a: mit 4 Treibstoff. Gefragt wird: Wo haelt das Spiel den Spieler auf, und mit welcher Meldung?
	var low: Dictionary = await _probe_departure("niedrig", "satellite_crash")
	# Regel 8 / Auftrag 21.11.: das Abheben (2) ist gedeckt und wird angenommen; der Sprung (5) startet nicht, weil nur noch 2 da sind.
	var stopped_at_home: bool = not bool(Dictionary(low.start).get("ok", false))
	var stopped_at_jump: bool = bool(Dictionary(low.start).get("ok", false)) and not bool(Dictionary(low.jump).get("ok", true))
	var stopped_at_approach: bool = bool(low.reached_orbit) and not bool(Dictionary(low.approach).get("ok", true))
	_check(stopped_at_home or stopped_at_jump or stopped_at_approach, "Fall 2: ein Flug, den der Treibstoff nicht traegt, wird gestoppt, bevor der Spieler am Ziel steht (Abflug: %s, Sprung: %s, Anflug: %s)" % [_msg(Dictionary(low.start)), _msg(Dictionary(low.jump)), _msg(Dictionary(low.approach))])
	_check(stopped_at_jump and String(Dictionary(low.jump).get("reason", "")) == "leg_fuel_insufficient", "Fall 2: mit 4 Treibstoff wird zuerst das Abheben angenommen und dann der Sprung mit leg_fuel_insufficient abgelehnt (beobachtet: %s)" % _msg(Dictionary(low.jump)))
	var stop_text: String = String(Dictionary(low.start).get("message", "")) if stopped_at_home else (String(Dictionary(low.jump).get("message", "")) if stopped_at_jump else String(Dictionary(low.approach).get("message", "")))
	_check(stop_text.to_lower().contains("treibstoff"), "Fall 2: die Meldung nennt den Treibstoff als Ursache (beobachtet: \"%s\")" % stop_text)
	# Die Meldung nennt benoetigte und vorhandene Menge (Auftrag 21.11.); der Hinweis zum Auftanken kommt erst mit dem Tankdienst (spaetere Abschnitte).
	_check(stop_text.contains("Benötigt") and stop_text.contains("vorhanden"), "Fall 2: die Meldung nennt benoetigte und vorhandene Menge (beobachtet: \"%s\")" % stop_text)
	var fuel_after_stop := _fuel_now()
	# Die Abhebekosten stehen je Route in den Daten (leg_fuel_costs); die Erreichbarkeitsanzeige nennt sie als needed_next der ersten Etappe (hier Heimat>Satellit: 1).
	var launch_cost: float = float(satellite_reach.get("needed_next", 2.0))
	_check(is_equal_approx(fuel_after_stop, fuel - launch_cost), "Fall 2: gebucht ist nur das angenommene Abheben (%s laut Erreichbarkeit), der abgelehnte Sprung bucht nichts (vorher %s, nachher %s)" % [str(launch_cost), str(fuel), str(fuel_after_stop)])
	# 2.2b: Steht das Schiff nach dem Stopp irgendwo im Weltraum? Dann muss es von dort heim.
	if bool(Dictionary(low.start).get("ok", false)):
		print("K2_FALL2_STOPPED_IN_SPACE phase=%s orbit=%s" % [String(_space().get("phase", "")), String(_space().get("orbit_id", ""))])
		if stopped_at_jump:
			# Regel 8 / Auftrag 21.11.: das Schiff steht nach dem abgelehnten Sprung im Mondorbit; die Heimlandung kostet nichts und geht auch mit 2 Treibstoff.
			var home_land: Dictionary = _screen.call("request_operation", "space_land_homebase", {"craft_id": _craft_id})
			if not _check(bool(home_land.get("ok", false)), "Fall 2: aus dem Mondorbit gelingt die kostenlose Heimlandung mit %s Treibstoff (%s)" % [str(fuel_after_stop), _msg(home_land)]): return false
			if not await _wait(func(): return String(_craft(_flow.call("get_singleplayer_snapshot")).get("location_id", "")) == "homebase" and not bool(_craft(_flow.call("get_singleplayer_snapshot")).get("busy", true)), 35000, "Fall 2: das Schiff steht nach der Heimlandung wieder zu Hause"): return false
			_check(is_equal_approx(_fuel_now(), fuel_after_stop), "Fall 2: die Heimlandung bucht nichts")
		elif not _check(await _wait_homebase(), "Fall 2: nach dem gestoppten Anflug kommt das Schiff mit %s Treibstoff ohne Hilfe zurueck nach Hause" % str(fuel_after_stop)): return false
	_flow.call("_show_homebase")
	print("K2_FALL2_BACK_HOME fuel=%s credits=%d phase=%s" % [str(_fuel_now()), _credits_now(), String(_space().get("phase", ""))])
	# 2.2c: nachtanken auf genau 24. Regel 8 / Auftrag 21.11.: Die frueheren Pruefung "23 reicht nicht" entfaellt, weil es keine Reserve mehr gibt:
	# mit 23 wuerde der Hinweg (12) gedeckt angeflogen und das Schiff stuende am Ort mit 11 (der Rueckweg braucht 12). Diesen Zustand
	# ("liegen geblieben") deckt tanker_leg_fuel_verifier ab; hier bleibt der Weg mit genau 24.
	var credits_before := _credits_now()
	var top_up: Dictionary = _runtime.call("request_operation", "refuel", {"craft_id": _craft_id, "amount": 24.0 - _fuel_now()})
	if not _check(bool(top_up.get("ok", false)) and is_equal_approx(_fuel_now(), 24.0), "Fall 2: zu Hause laesst sich auf genau 24 nachtanken (%s, Kosten %d Credits, beobachtet %s)" % [_msg(top_up), credits_before - _credits_now(), str(_fuel_now())]): return false
	_flow.call("_show_homebase")
	# 2.2d: mit genau 24 (null Reserve) die ganze Auftragsfahrt; am Ziel muss der Rueckflug bezahlt sein.
	if not await _launch_and_land_again("benit_delivery", SATELLITE_MAP, "fall2"): return false
	var at_destination := _fuel_now()
	print("K2_FALL2_AT_DESTINATION fuel=%s" % str(at_destination))
	_check(at_destination + 0.00001 >= 12.0, "Fall 2: am Zielort sind mindestens 12 Treibstoff (Rueckflug) uebrig (beobachtet %s)" % str(at_destination))
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	if not await _move_and_use(mission, "trade_service", "deliver_benit", SATELLITE_MAP): return false
	if not await _move_and_use(mission, "ship_return", "return_to_ship", SATELLITE_MAP): return false
	var came_home: bool = await _wait_homebase()
	_check(came_home, "Fall 2: mit genau 24 Treibstoff gelingt der Rueckflug vom Ziel ohne Nachtanken")
	if not came_home: return false
	_flow.call("_show_homebase")
	print("K2_FALL2_HOME_EMPTY fuel=%s credits=%d job3=%s" % [str(_fuel_now()), _credits_now(), _job_status_of("benit_delivery")])
	_check(_job_status_of("benit_delivery") == "completed", "Fall 2: Auftrag 3 abgeschlossen (beobachtet %s)" % _job_status_of("benit_delivery"))
	_check(_fuel_now() < 0.5, "Fall 2: Tank ist nach der knappen Fahrt leer (beobachtet %s)" % str(_fuel_now()))
	var refill: Dictionary = _runtime.call("request_operation", "refuel", {"craft_id": _craft_id, "amount": 40.0})
	_check(bool(refill.get("ok", false)), "Fall 2: mit leerem Tank und %d Credits laesst sich zu Hause nachtanken (%s)" % [_credits_now(), _msg(refill)])
	return true

func _finish() -> void:
	_check(FileAccess.get_file_as_bytes(ROSTER.get_save_path()) == _skirmish_bytes, "Kampagne schreibt das Skirmish-Team nicht")
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	print("campaign_dead_end_probe_verifier passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
