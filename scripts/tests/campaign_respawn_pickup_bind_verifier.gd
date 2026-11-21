extends "res://scripts/tests/polisa_player_ship_recruit_board_verifier.gd"
## R4c Respawn (Abholen auf Polisa), Basis-Runtime: bind_confirmed_polisa_player_boarding bindet nur Angeworbene (Kennung) und Personen,
## die auf Abholung warten (awaiting_pickup); wer noch ausfaellt (respawning) nie.
## Aufbau wie polisa_player_ship_recruit_board_verifier (echte Basis-Runtime, echtes Hex-Bodenmodell, Besuchs-Szene mit eingestiegenem Darsteller).
## B1 awaiting_pickup (Kennung ohne polisa_recruit_): ohne Einstieg abgelehnt, mit Einstieg an Bord (craft_id), Wiederholung ist ein Replay
## B2 respawning: wird auch mit eingestiegenem Darsteller nie gebunden, bleibt station   B3 Angeworbene: wie vorher gebunden (Gegenprobe)
## Abschlusszeile: CAMPAIGN_RESPAWN_PICKUP_BIND passed=%d failed=%d

const PICKUP_BIND_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")

func _bind_case(rig: Dictionary, visit: Dictionary, flow: Node, id: String, profile: Dictionary) -> Dictionary:
	visit.scene.set_meta("singleplayer_visit_identities", {"ship": {"unit_ids": [id]}})
	var actor := StationActor.new()
	actor.unit_id = id
	actor.team_id = "blue"
	visit.scene.add_child(actor)
	visit.units.register_unit(id, actor)
	visit.sim.register_known_unit(id, actor)
	flow._all_team_units.append(profile)
	rig.base.sync_roster()
	return {"actor": actor}

func _finish() -> void:
	var verdict: Dictionary = PICKUP_BIND_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_PICKUP_BIND refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	var rig: Dictionary = _boarding_rig()
	var visit: Dictionary = _admission_rig([Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)])
	visit.sim.name = "SimulationRoot"
	visit.units.name = "UnitRegistry"
	visit.sim.unit_registry_path = visit.sim.get_path_to(visit.units)
	var controller := Controller.new()
	controller.name = "TacticalController"
	visit.scene.add_child(controller)
	visit.scene.set_meta("location_id", "polisa")
	var flow := VisitFlow.new()
	rig.scene.add_child(flow)
	flow.mission = visit.scene
	flow._aircraft_location_by_craft["ship"] = "mission"
	rig.base._flow = flow
	rig.base._navigation_graph = null

	# B1: awaiting_pickup, Kennung ohne polisa_recruit_
	var waiting_id := "pickup_on_ship"
	var waiting_case: Dictionary = _bind_case(rig, visit, flow, waiting_id, {"unit_id": waiting_id, "display_name": "Wartende", "availability_status": "awaiting_pickup", "recovery_state": {"state": "awaiting_pickup", "pickup_location_id": "polisa"}, "respawns_used": 1})
	_check(String(rig.base._states[waiting_id].status) == "station" and rig.base.is_awaiting_pickup(waiting_id), "B1: Fixture: die Wartende steht auf station, der Kader fuehrt sie als awaiting_pickup")
	var refused: Dictionary = rig.base.bind_confirmed_polisa_player_boarding(waiting_id, "ship", visit.scene)
	_check(not bool(refused.get("ok", false)) and String(rig.base._states[waiting_id].status) == "station", "B1: ohne tatsaechlichen Einstieg bleibt die Wartende auf station (%s)" % [refused])
	waiting_case.actor.set_meta("dropship_embarked", true)
	waiting_case.actor.visible = false
	var bound: Dictionary = rig.base.bind_confirmed_polisa_player_boarding(waiting_id, "ship", visit.scene)
	_check(bool(bound.get("ok", false)) and String(rig.base._states[waiting_id].status) == "aboard" and String(rig.base._states[waiting_id].craft_id) == "ship" and not rig.base._unit_is_home(waiting_id), "B1: mit tatsaechlichem Einstieg ist die Wartende an Bord des Schiffs (%s)" % [bound])
	var replay: Dictionary = rig.base.bind_confirmed_polisa_player_boarding(waiting_id, "ship", visit.scene)
	_check(bool(replay.get("ok", false)) and bool(replay.get("replayed", false)), "B1: die Bindung ist wiederholbar (Replay)")

	# B2: respawning wird nie gebunden
	var down_id := "pickup_still_down"
	var down_case: Dictionary = _bind_case(rig, visit, flow, down_id, {"unit_id": down_id, "display_name": "Ausfallende", "availability_status": "respawning", "recovery_state": {"state": "respawning", "death_number": 1, "seconds_total": 3600, "seconds_remaining": 600, "pickup_location_id": "polisa", "source": "left_behind"}, "respawns_used": 1})
	down_case.actor.set_meta("dropship_embarked", true)
	down_case.actor.visible = false
	var down_bound: Dictionary = rig.base.bind_confirmed_polisa_player_boarding(down_id, "ship", visit.scene)
	_check(not bool(down_bound.get("ok", false)) and String(rig.base._states[down_id].status) == "station" and String(rig.base._states[down_id].craft_id).is_empty(), "B2: eine Ausfallende (respawning) wird nicht gebunden, auch nicht mit eingestiegenem Darsteller (%s)" % [down_bound])

	# B3: Angeworbene wie vorher
	var recruit_id := "polisa_recruit_pickup_bind_control"
	var recruit_case: Dictionary = _bind_case(rig, visit, flow, recruit_id, {"unit_id": recruit_id, "display_name": "Angeworbene", "recruit_location": "polisa"})
	recruit_case.actor.set_meta("dropship_embarked", true)
	recruit_case.actor.visible = false
	var recruit_bound: Dictionary = rig.base.bind_confirmed_polisa_player_boarding(recruit_id, "ship", visit.scene)
	_check(bool(recruit_bound.get("ok", false)) and String(rig.base._states[recruit_id].status) == "aboard" and String(rig.base._states[recruit_id].craft_id) == "ship", "B3: eine Angeworbene (polisa_recruit_) wird wie vorher gebunden (%s)" % [recruit_bound])

	visit.scene.free()
	rig.scene.free()
	print("CAMPAIGN_RESPAWN_PICKUP_BIND passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
