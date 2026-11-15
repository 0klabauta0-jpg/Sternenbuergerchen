extends "res://scripts/tests/campaign_casualty_result_verifier.gd"
## Task 4 (Ausfall und Rueckzug): Ausgefallene blockieren das Einschiffen im Kampagneneinsatz nicht mehr.
## Echter Kampagnenstart, echte Meta-Szene, echter Einsatz (Aufbau wie campaign_casualty_result_verifier).
## Reihenfolge ist Absicht: ein Einsatz, Zustand wandert von Gruppe zu Gruppe.

func _run() -> void:
	_configure_entry()
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	await _boarding_part()
	print("CAMPAIGN_CASUALTY_BOARDING passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

## Setzt eine Person auf die Hex-Zelle am Schiffszugang (Fixture wie im Ergebnis-Test: es gibt keinen oeffentlichen Setter).
func _place_at(simulation: Node, access: Dictionary, unit_id: String, offset: Vector2) -> bool:
	var registry: Node = simulation.call("get_hex_ground_terrain_registry")
	var ground: Dictionary = simulation.call("get_hex_unit_state", unit_id)
	if not _check(not ground.is_empty() and registry != null, "Hex-Zustand von %s ist lesbar" % unit_id): return false
	var runtime: RefCounted = simulation.get("_hex_ground_runtime")
	Dictionary(runtime.get("_units_by_id")[unit_id])["grid"] = registry.call("world_to_grid", Vector2(access.position) + offset)
	return true

func _boarding_part() -> void:
	if not await _prepare_initial_base(): return
	_crew_ids = ["campaign_leader"]
	_pilot_id = "campaign_pilot"
	_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Accept actual job")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Choose actual location")
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var simulation: Node = mission.get_node("SimulationRoot")
	_check(bool(driver.get("campaign_casualty_rules_enabled")), "Kampagneneinsatz: Schalter am CombatLoopDriver ist an")
	var leader: Node2D = controller.call("_get_campaign_sortie_unit", "campaign_leader")
	var pilot: Node2D = controller.call("_get_campaign_sortie_unit", "campaign_pilot")
	if not _check(leader != null and pilot != null, "Beide echten Personen stehen im Einsatz"): return
	var access: Dictionary = controller.call("get_campaign_ground_ship_access", _craft_id)
	if not _check(bool(access.get("ok", false)), "Gelandetes Schiff liefert einen Zugangspunkt"): return
	if not _check(bool(controller.call("_requires_hex_deployment_owner")), "Satellitenkarte ist eine Hex-Karte"): return
	var deployed: Dictionary = controller.get("_deployed_unit_ids")
	var embarked: Dictionary = controller.get("_embarked_unit_ids")
	_check(deployed.has("campaign_leader") and deployed.has("campaign_pilot"), "Beide Personen sind am Boden, keiner eingestiegen")
	# Gruppe 6: einsatzfaehige Person nicht am Schiff blockiert weiter (Schalter an).
	if not _place_at(simulation, access, "campaign_pilot", Vector2.ZERO): return
	if not _place_at(simulation, access, "campaign_leader", Vector2(700.0, 0.0)): return
	var away: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	print("BOARDING_AWAY ", away)
	_check(not bool(away.get("ok", true)) and String(away.get("reason", "")) == "crew_not_at_ship", "Einsatzfaehige Person nicht am Schiff: crew_not_at_ship")
	_check(deployed.has("campaign_pilot") and not embarked.has("campaign_pilot"), "Abgelehnt: niemand wurde eingeschifft")
	# Beide am Schiff, Anführer faellt aus.
	if not _place_at(simulation, access, "campaign_leader", Vector2.ZERO): return
	leader.call("apply_damage", 10000)
	_check(String(leader.call("get_vital_state")) != "fit", "Anführer ist nicht mehr einsatzfaehig")
	# Gruppe 5: Schalter aus (Altpfad): unveraendert crew_unavailable, kein neues Feld, keine Mutation.
	driver.set("campaign_casualty_rules_enabled", false)
	var off: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	print("BOARDING_OFF ", off)
	_check(not bool(off.get("ok", true)) and String(off.get("reason", "")) == "crew_unavailable", "Schalter aus: Ausgefallener blockiert wie bisher (crew_unavailable)")
	_check(not off.has("casualty_unit_ids"), "Schalter aus: Rueckgabe hat kein casualty_unit_ids")
	_check(deployed.has("campaign_pilot") and not embarked.has("campaign_pilot"), "Schalter aus: niemand wurde eingeschifft")
	driver.set("campaign_casualty_rules_enabled", true)
	# Gruppe 1: Schalter an, eine von zwei Bodenpersonen ausgefallen.
	var on: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	print("BOARDING_ON ", on)
	_check(bool(on.get("ok", false)), "Schalter an: Einschiffen mit einer ausgefallenen Person gelingt")
	_check(on.has("casualty_unit_ids") and PackedStringArray(on.get("casualty_unit_ids", PackedStringArray())) == PackedStringArray(["campaign_leader"]), "casualty_unit_ids nennt genau die Ausgefallene")
	_check(embarked.has("campaign_pilot") and not deployed.has("campaign_pilot"), "Einsatzfaehiger Pilot ist an Bord")
	_check(deployed.has("campaign_leader") and not embarked.has("campaign_leader"), "Ausgefallene bleibt liegen: nicht eingeschifft, weiter am Boden")
	_check(not Dictionary(simulation.call("get_hex_unit_state", "campaign_leader")).is_empty(), "Ausgefallene behaelt ihren Hex-Zustand (nicht bewegt)")
	_check(PackedStringArray(controller.call("_campaign_craft_crew_ids", _craft_id)).has("campaign_leader"), "Ausgefallene bleibt in der Besatzungsliste")
	# Gruppe 2: Ausgefallene zaehlen nicht als fehlende Besatzung.
	var guard: Dictionary = controller.call("get_campaign_pilot_flight_guard", _craft_id)
	print("BOARDING_GUARD ", guard)
	_check(bool(guard.get("ok", false)), "Flugfreigabe: Ausgefallene zaehlen nicht als fehlende Besatzung")
	# Wiederholbarkeit: Pilot an Bord, Ausgefallene liegt noch. Jeder weitere Aufruf liefert dasselbe, niemand wird doppelt eingeschifft.
	for round_index in 2:
		var again: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
		print("BOARDING_AGAIN ", round_index, " ", again)
		_check(bool(again.get("ok", false)), "Wiederholter Aufruf %d: ok" % (round_index + 1))
		_check(PackedStringArray(again.get("casualty_unit_ids", PackedStringArray())) == PackedStringArray(["campaign_leader"]), "Wiederholter Aufruf %d: casualty_unit_ids nennt die Liegende" % (round_index + 1))
		_check(embarked.size() == 1 and embarked.has("campaign_pilot") and deployed.has("campaign_leader") and not embarked.has("campaign_leader"), "Wiederholter Aufruf %d: niemand doppelt oder zusaetzlich eingeschifft" % (round_index + 1))
	# Teilpfad Trupp: Truppmitglied(er) mit dem Pilot im selben Trupp; fitter Teil an Bord, eine Person liegt.
	var leader_team: String = String(leader.call("get_fireteam_id"))
	var pilot_team: String = String(pilot.call("get_fireteam_id"))
	print("BOARDING_TEAMS leader=", leader_team, " pilot=", pilot_team)
	if leader_team == pilot_team:
		for round_index in 2:
			var team_again: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id, leader_team)
			print("BOARDING_TEAM_AGAIN ", round_index, " ", team_again)
			_check(bool(team_again.get("ok", false)) and PackedStringArray(team_again.get("casualty_unit_ids", PackedStringArray())) == PackedStringArray(["campaign_leader"]), "Truppaufruf %d (fitter Teil an Bord, eine liegt): ok mit casualty_unit_ids" % (round_index + 1))
	_check(leader_team == pilot_team, "Fixture: Truppfuehrer und Pilot teilen sich einen Trupp")
	# Ganzer Trupp liegt (Fixture: Truppfuehrer allein in eigenem Trupp, er liegt, niemand aus dem Trupp ist fit oder an Bord).
	_check(bool(leader.call("set_fireteam_id", "ft_test_solo")), "Fixture: Truppfuehrer in eigenen Test-Trupp gesetzt")
	var team_down: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id, "ft_test_solo")
	print("BOARDING_TEAM_DOWN ", team_down)
	_check(not bool(team_down.get("ok", true)) and String(team_down.get("reason", "")) == "crew_unavailable", "Truppaufruf, ganzer Trupp liegt: crew_unavailable")
	leader.call("set_fireteam_id", leader_team)
	# Gruppe 4: Pilot ausgefallen.
	pilot.call("apply_damage", 10000)
	var no_pilot: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	print("BOARDING_NO_PILOT ", no_pilot)
	_check(not bool(no_pilot.get("ok", true)) and String(no_pilot.get("reason", "")) == "pilot_unavailable", "Pilot nicht einsatzfaehig: pilot_unavailable")
	_check(String(controller.call("get_campaign_pilot_flight_guard", _craft_id).get("reason", "")) == "pilot_unavailable", "Flugfreigabe: Pilot nicht einsatzfaehig meldet pilot_unavailable")
	_flow.queue_free()
	await process_frame
