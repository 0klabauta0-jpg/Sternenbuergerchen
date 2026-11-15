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
	# Gruppe 3: alle Bodenpersonen ausgefallen.
	var none_fit: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	print("BOARDING_NONE_FIT ", none_fit)
	_check(not bool(none_fit.get("ok", true)) and String(none_fit.get("reason", "")) == "crew_unavailable", "Keine Bodenperson einsatzfaehig: crew_unavailable")
	# Gruppe 4: Pilot ausgefallen.
	pilot.call("apply_damage", 10000)
	var no_pilot: Dictionary = controller.call("request_campaign_crew_boarding", _craft_id)
	print("BOARDING_NO_PILOT ", no_pilot)
	_check(not bool(no_pilot.get("ok", true)) and String(no_pilot.get("reason", "")) == "pilot_unavailable", "Pilot nicht einsatzfaehig: pilot_unavailable")
	_check(String(controller.call("get_campaign_pilot_flight_guard", _craft_id).get("reason", "")) == "pilot_unavailable", "Flugfreigabe: Pilot nicht einsatzfaehig meldet pilot_unavailable")
	_flow.queue_free()
	await process_frame
