extends "res://scripts/tests/campaign_chapter_one_sortie_verifier.gd"
## Stand 27.11.: Vorgabe "Pilot steigt mit aus" (Speichern im Einsatz braucht alle Einheiten draussen). Ein Schalter an der Schiffskarte legt auf "Pilot bleibt an Bord" um.
## Echte Erstlandung der Kampagne, der Schalter wird VOR dem Absetzen umgelegt. Schlusszeile: PILOT_STAYS_ABOARD passed=N failed=M

var _stay_aboard_landing: bool = false

# Wie flugdeck_pilot_actual_sortie_verifier: Der Pilot steigt zuerst aus und tritt dem Trupp FT1 bei, damit er zur Besatzung des Trupps gehoert.
func _prepare_initial_base() -> bool:
	if not await super._prepare_initial_base(): return false
	var people: Node = _runtime.get_base_personnel_runtime()
	var craft: Dictionary = _screen.get_operations_snapshot().selected_craft
	var pilot: String = String(craft.pilot_id)
	var result: Dictionary = people.request_operation("base_unboard", {"unit_id": pilot, "craft_id": _craft_id})
	if not _check(result.get("ok", false), "Pilot steigt an der Basis zuerst aus"): return false
	result = _screen.request_operation("assign", {"unit_id": pilot, "fireteam_id": _team_id})
	if not _check(result.get("ok", false), "Pilot tritt dem Trupp bei"): return false
	return await _board_actual_base_crew()

# Haengt sich vor dem Absetzen in die geerbte _launch_and_land: _landing_target wird direkt vor dem Klick auf "Absetzen" gefragt.
func _landing_target(map) -> Vector2:
	var controller: Node = _flow.get("_active_mission").get_node("TacticalController")
	_check(bool(controller.call("_is_pilot_disembark_selected", _craft_id)) and not bool(controller.call("_is_pilot_kept_aboard", _craft_id, _pilot_id)), "Vorgabe vor dem Absetzen: der Pilot steigt aus")
	var toggled: Dictionary = controller.call("request_campaign_pilot_disembark_toggle", _craft_id)
	_check(bool(toggled.get("ok", false)) and not bool(toggled.get("pilot_disembarks", true)) and bool(controller.call("_is_pilot_kept_aboard", _craft_id, _pilot_id)), "Schalter vor dem Absetzen: der Pilot bleibt an Bord")
	_stay_aboard_landing = true
	return super._landing_target(map)

# Mit Pilot an Bord ist der Pilot nie unter den abgesetzten Einheiten; die geerbte Bedingung (alle Besatzung abgesetzt) wartet sonst ewig.
func _all_crew_deployed(controller: Node) -> bool:
	if not _stay_aboard_landing: return super._all_crew_deployed(controller)
	var deployed: Dictionary = Dictionary(controller.get("_deployed_unit_ids"))
	var others := 0
	for id: String in _crew_ids:
		if id == _pilot_id: continue
		if not deployed.has(id): return false
		others += 1
	var done: bool = others > 0 and bool(controller.call("_fireteam_deploy_effects_are_applied", _team_id)) and not Dictionary(controller.get("_runtime_activation_pending_fireteam_ids")).has(_team_id) and not Dictionary(controller.get("_post_drop_security_pending_fireteam_ids")).has(_team_id)
	# Die geerbte Pruefung des Einsetz-Waechters (campaign_intro_loop_smoke) ist hier durch diese Bedingung ersetzt; sie wartet auf dasselbe (Aktivierung und Rundum-Sicherung fertig).
	if done: _insertion_guard_checked = true
	return done

func _run() -> void:
	Engine.time_scale = 4.0
	_configure_entry()
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen"); _runtime = _flow.get("_singleplayer_runtime")
	if not await _prepare_initial_base(): await _end(); return
	var craft: Dictionary = _screen.call("get_operations_snapshot").selected_craft
	_craft_id = String(craft.id); _pilot_id = String(craft.pilot_id)
	_team_id = String(Array(craft.payload_fireteam_ids)[0])
	for team: Dictionary in Array(_screen.call("get_operations_snapshot").fireteams):
		if String(team.id) == _team_id:
			for unit: Dictionary in Array(team.members): _crew_ids.append(String(unit.id))
	_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Auftrag angenommen")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Ziel gewaehlt")
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): await _end(); return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var deployed: Dictionary = controller.get("_deployed_unit_ids")
	var embarked: Dictionary = controller.get("_embarked_unit_ids")
	var pilot: Node = controller.call("_get_campaign_sortie_unit", _pilot_id)
	# 1) Schalter "bleibt an Bord": Trupp draussen, Pilot an Bord, Abfolge fertig, Schiff geparkt
	_check(not _pilot_id.is_empty() and not deployed.has(_pilot_id), "Pilot an Bord: der Pilot steht nicht unter den abgesetzten Einheiten")
	_check(embarked.has(_pilot_id) and pilot != null and bool(pilot.get_meta("dropship_embarked", false)), "Pilot an Bord: der Pilot ist weiter eingeschifft")
	var outside := 0
	for id: String in _crew_ids:
		if id != _pilot_id and deployed.has(id): outside += 1
	_check(outside == _crew_ids.size() - 1 and outside > 0, "Pilot an Bord: der ganze Trupp ausser dem Piloten ist abgesetzt (%d)" % outside)
	_check(String(controller.get("_drop_sequence_phase")) == "complete" and bool(controller.call("_is_parked_campaign_dropship", _craft_id)), "Pilot an Bord: die Abfolge ist fertig, das Schiff steht geparkt (%s)" % str(controller.get("_drop_sequence_phase")))
	_check(bool(controller.call("get_campaign_pilot_flight_guard", _craft_id, false).get("ok", false)), "Pilot an Bord: der Flugwaechter sieht den Piloten an Bord")
	# 2) nur der Pilot an Bord: Absetzen wird mit eigenem Grund abgelehnt
	var only_pilot: Dictionary = controller.call("request_campaign_crew_deployment", _craft_id)
	_check(not bool(only_pilot.get("ok", true)) and String(only_pilot.get("reason", "")) == "only_pilot_aboard", "Nur der Pilot an Bord: Absetzen abgelehnt mit only_pilot_aboard (%s)" % str(only_pilot))
	_check(not deployed.has(_pilot_id) and embarked.has(_pilot_id), "Nach der Ablehnung ist der Pilot unveraendert an Bord")
	# 3) Zurueck auf die Vorgabe: Pilot steigt mit aus
	var toggled: Dictionary = controller.call("request_campaign_pilot_disembark_toggle", _craft_id)
	_check(bool(toggled.get("ok", false)) and bool(toggled.get("pilot_disembarks", false)) and bool(controller.call("_is_pilot_disembark_selected", _craft_id)), "Zurueck auf Vorgabe: Pilot steigt aus ist gewaehlt")
	var out: Dictionary = controller.call("request_campaign_crew_deployment", _craft_id)
	_check(bool(out.get("ok", false)), "Vorgabe: Absetzen wird angenommen (%s)" % str(out))
	# Der Trupp steht noch auf dem Ausstiegsfeld (er ist in der Pruefung nicht losgelaufen): die Hex-Zulassung findet fuer den Piloten kein freies Feld
	# und die Abfolge wartet ("Ausstieg wartet auf freie Felder"). Das ist das vorhandene Verhalten bei belegtem Ausstiegsfeld, kein Fehler des Schalters.
	# Dass der Pilot bei freiem Feld mit aussteigt, decken die Pruefer der Vorgabe ab (flugdeck_pilot_actual_sortie, l03, compact_team).
	_check(bool(out.get("pending", false)) and String(controller.get("_drop_sequence_phase")) == "unloading", "Vorgabe: der Pilot-Ausstieg laeuft als Abfolge (unloading, pending)")
	_check(await _wait(func(): return String(controller.get("_last_command_text")).begins_with("Ausstieg wartet"), 6000, "Vorgabe: der Pilot wartet auf ein freies Ausstiegsfeld"), "Vorgabe: Pilot wartet auf ein freies Feld (%s)" % str(controller.get("_last_command_text")))
	_check(not controller.get("_deployed_unit_ids").has(_pilot_id) and controller.get("_embarked_unit_ids").has(_pilot_id), "Vorgabe: bis das Feld frei ist, bleibt der Pilot eingeschifft")
	await _end()

func _end() -> void:
	print("PILOT_STAYS_ABOARD passed=%d failed=%d" % [_passed, _failed])
	await _finish()
