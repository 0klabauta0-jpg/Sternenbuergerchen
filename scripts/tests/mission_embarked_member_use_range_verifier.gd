extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Eingeschiffte Mitglieder zaehlen weder fuer die Nutzungsentfernung noch fuer die Platzvergabe.
## Echter Kampagnenstart, echte Landung auf der Satellitenkarte (kuerzester Einsatz mit benutzbarem
## Objekt "satellite_data"), echtes Marschieren mit Truppfuehrer und Pilot. Einzige Fixture:
## der Pilot wird mit der Hex-Zelle am Schiffszugang platziert (wie campaign_casualty_boarding_verifier),
## danach geht er ueber den normalen Weg request_campaign_crew_boarding(craft, "", pilot) an Bord.

const OBJECT_ID := "satellite_data"
const MAP_PATH := "res://maps/satellite_crash_site.json"
const USE_RADIUS := 96.0
## Ein Hexfeld in Weltkoordinaten (Abstandsmass fuer die Vorschau-Pruefung).
const HEX_SIZE_WORLD := 88.0

## Leichte Einheit fuer die Stilrechnung am Bewegungsbesitzer: nur was _build_member_records und _resolve_effective_style lesen.
class StubUnit extends Node2D:
	var unit_id := ""
	var vital := "fit"
	func get_unit_id() -> String: return unit_id
	func get_vital_state() -> String: return vital
	func get_team_id() -> String: return "team_alpha"

var _leader_id := "campaign_leader"
var _observed_targets: Dictionary = {}
var _observed_max_count := 0

func _run() -> void:
	Engine.time_scale = 4.0
	_configure_entry()
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not await _prepare_initial_base():
		await _end(); return
	var operations: Dictionary = _screen.call("get_operations_snapshot")
	var craft: Dictionary = operations.selected_craft
	_craft_id = String(craft.id)
	_pilot_id = String(craft.pilot_id)
	_team_id = String(Array(craft.payload_fireteam_ids)[0])
	for team: Dictionary in Array(operations.fireteams):
		if String(team.id) == _team_id:
			for unit: Dictionary in Array(team.members): _crew_ids.append(String(unit.id))
	if not _check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Einsatz angenommen"): await _end(); return
	if not _check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Ziel gewaehlt"): await _end(); return
	if not await _launch_and_land("satellite_recovery", MAP_PATH): await _end(); return
	await _scenarios()
	await _end()

func _end() -> void:
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("MISSION_EMBARKED_USE_RANGE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _until(predicate: Callable, milliseconds: int) -> bool:
	var deadline: int = Time.get_ticks_msec() + milliseconds
	while Time.get_ticks_msec() < deadline:
		if bool(predicate.call()): return true
		await physics_frame
	return false

func _anchor_entry(controller: Node) -> Dictionary:
	for entry in Array(controller.call("_build_fireteam_anchor_visualization_entries")):
		if String(Dictionary(entry).get("fireteam_id", "")) == _team_id.strip_edges().to_lower():
			return Dictionary(entry)
	return {}

func _stub_squad(embarked_count: int, down_count: int) -> Array:
	var units: Array = []
	for index in range(4):
		var unit := StubUnit.new()
		unit.unit_id = "n7_stub_%d" % index
		if index >= 4 - embarked_count: unit.set_meta("dropship_embarked", true)
		elif index >= 4 - embarked_count - down_count: unit.vital = "down"
		units.append(unit)
	return units

func _free_all(units: Array) -> void:
	for unit in units: unit.free()

## Stilwahl am Bewegungsbesitzer: nur Mitglieder am Boden zaehlen; Eingeschiffte sind weder vorhanden noch Verlust, Ausgefallene sind Verluste.
func _style_checks(movement) -> void:
	var doctrine: String = movement._resolve_command_advance_style("engage", "bounding", "")
	var rush: String = movement.ADVANCE_STYLE_RUSH
	_check(doctrine != rush, "Stil: Lehre fuer engage ohne Haltung ist nicht Rush (%s)" % doctrine)
	# 4 Einheiten, 2 eingeschifft, niemand ausgefallen: unvereinfacht.
	var squad_a: Array = _stub_squad(2, 0)
	var records_a: Array = movement._build_member_records(squad_a, squad_a[0])
	var style_a: String = movement._resolve_effective_style(doctrine, squad_a, records_a)
	print("EMBARKED_USE style 4 units, 2 embarked: records=", records_a.size(), " style=", style_a, " doctrine=", doctrine)
	_check(records_a.size() == 2 and style_a == doctrine and style_a != rush, "Stil: 4 Einheiten, 2 eingeschifft, niemand ausgefallen: unvereinfachter Stil, simplified_due_to_losses falsch")
	_free_all(squad_a)
	# 4 Einheiten, 2 ausgefallen, niemand eingeschifft: vereinfacht wie vorher.
	var squad_b: Array = _stub_squad(0, 2)
	var records_b: Array = movement._build_member_records(squad_b, squad_b[0])
	var style_b: String = movement._resolve_effective_style(doctrine, squad_b, records_b)
	print("EMBARKED_USE style 4 units, 2 down: records=", records_b.size(), " style=", style_b)
	_check(records_b.size() == 2 and style_b == rush, "Stil: 4 Einheiten, 2 ausgefallen, niemand eingeschifft: vereinfacht (Rush) wie vorher")
	_free_all(squad_b)
	# Niemand eingeschifft, niemand ausgefallen: nichts aendert sich.
	var squad_c: Array = _stub_squad(0, 0)
	var records_c: Array = movement._build_member_records(squad_c, squad_c[0])
	_check(records_c.size() == 4 and movement._resolve_effective_style(doctrine, squad_c, records_c) == doctrine, "Stil: niemand eingeschifft, niemand ausgefallen: unvereinfacht")
	_free_all(squad_c)
	# Gemischt: 1 eingeschifft, 2 ausgefallen, 1 fit: Verluste zaehlen echt (2 von 3 am Boden), also vereinfacht.
	var squad_d: Array = _stub_squad(1, 2)
	var records_d: Array = movement._build_member_records(squad_d, squad_d[0])
	_check(records_d.size() == 1 and movement._resolve_effective_style(doctrine, squad_d, records_d) == rush, "Stil: 1 eingeschifft, 2 ausgefallen, 1 fit: vereinfacht, Eingeschiffte zaehlen nicht mit")
	_free_all(squad_d)

func _use_entry(controller: Node) -> Dictionary:
	return _find_interaction(controller.call("get_mission_interaction_runtime_use_state_snapshot"), OBJECT_ID)

func _team_position_entry(controller: Node) -> Dictionary:
	for entry in Array(controller.call("_build_mission_interaction_fireteam_positions_for_readability")):
		if String(Dictionary(entry).get("fireteam_id", "")) == _team_id.strip_edges().to_lower():
			return Dictionary(entry)
	return {}

func _team_position_count(controller: Node) -> int:
	return Array(controller.call("_build_mission_interaction_fireteam_positions_for_readability")).size()

func _movement_state(controller: Node) -> Dictionary:
	var movement = controller.get("_fireteam_movement_controller")
	return Dictionary(movement._execution_by_fireteam.get(_team_id.strip_edges().to_lower(), {})) if movement != null else {}

## Merkt sich die zuletzt vergebenen Formationsplaetze (Zielpunkte je Mitglied) des laufenden Marschbefehls.
func _observe_slots(controller: Node, target: Vector2) -> void:
	var state: Dictionary = _movement_state(controller)
	# Nur der Marschbefehl auf genau dieses Ziel zaehlt, keine Reste eines frueheren.
	if state.is_empty() or Vector2(state.get("final_target_position", Vector2(INF, INF))).distance_to(target) > 1.0: return
	var targets: Dictionary = Dictionary(state.get("current_target_positions", {}))
	if not targets.is_empty():
		_observed_targets = targets.duplicate()
		_observed_max_count = maxi(_observed_max_count, targets.size())

func _is_idle(simulation: Node, id: String) -> bool:
	var ground: Dictionary = simulation.call("get_hex_unit_state", id)
	if ground.is_empty(): return true
	return not bool(Dictionary(ground.get("movement_state", {})).get("moving", false)) and not bool(Dictionary(ground.get("route_state", {})).get("has_commitments", false))

## Marschbefehl wie vom Spieler (Wegpunkt + GO). Wartet bis alle genannten Mitglieder zur Ruhe gekommen sind.
func _march(controller: Node, simulation: Node, target: Vector2, walkers: Array, milliseconds: int) -> bool:
	_observed_targets = {}
	_observed_max_count = 0
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	controller.call("_create_waypoints_for_selected_fireteams", target, true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), "Marschbefehl wird angenommen"): return false
	var frames := 0
	var idle_frames := 0
	var deadline: int = Time.get_ticks_msec() + milliseconds
	while Time.get_ticks_msec() < deadline:
		await physics_frame
		frames += 1
		_observe_slots(controller, target)
		var idle := true
		for id in walkers: idle = idle and _is_idle(simulation, String(id))
		idle_frames = idle_frames + 1 if idle and frames > 30 and _observed_max_count > 0 else 0
		if idle_frames >= 90: return true
	return false

func _scenarios() -> void:
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var simulation: Node = mission.get_node("SimulationRoot")
	var map = MAP.load_from_file(MAP_PATH)
	var marker: Vector2 = map.get_marker_position(OBJECT_ID)
	var leader: Node2D = controller.call("_get_campaign_sortie_unit", _leader_id)
	var pilot: Node2D = controller.call("_get_campaign_sortie_unit", _pilot_id)
	if not _check(leader != null and pilot != null, "Truppfuehrer und Pilot stehen im Einsatz"): return
	var access: Dictionary = controller.call("get_campaign_ground_ship_access", _craft_id)
	if not _check(bool(access.get("ok", false)), "Gelandetes Schiff liefert einen Zugangspunkt"): return
	print("EMBARKED_USE marker=", marker, " access=", access.position, " distance_marker_ship=", marker.distance_to(Vector2(access.position)), " leader=", leader.global_position, " pilot=", pilot.global_position)
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	_check(String(leader.call("get_fireteam_id")).to_lower() == String(pilot.call("get_fireteam_id")).to_lower(), "Fixture: Truppfuehrer und Pilot teilen sich einen Trupp")

	# Fall 1: beide am Boden, beide am Objekt.
	var arrived: bool = await _march(controller, simulation, marker, [_leader_id, _pilot_id], 240000)
	_check(arrived, "Fall 1: Trupp kommt beim Objekt zur Ruhe")
	var entry1: Dictionary = _use_entry(controller)
	print("EMBARKED_USE case1 entry=", {"status": entry1.get("runtime_use_status"), "reason": entry1.get("runtime_use_reason"), "distance": entry1.get("distance_world")}, " slots=", _observed_targets, " leader=", leader.global_position, " pilot=", pilot.global_position)
	_check(String(entry1.get("runtime_use_status", "")) == "usable", "Fall 1: beide am Boden nah am Objekt: benutzbar")
	var slots_two := _observed_max_count
	_check(slots_two == 2, "Fall 1: zwei Plaetze bei zwei Mitgliedern am Boden")
	# Teil B, niemand eingeschifft: der Startpunkt des Vorschau-Eintrags ist unveraendert der Wert der Anker-Funktion.
	var preview1: Dictionary = _anchor_entry(controller)
	var old_anchor1: Variant = controller.call("_resolve_fireteam_visual_anchor_position", _team_id.strip_edges().to_lower())
	print("EMBARKED_USE case1 preview_entry=", preview1.get("position"), " old_anchor=", old_anchor1)
	_check(preview1.has("position") and typeof(old_anchor1) == TYPE_VECTOR2 and Vector2(preview1.position).distance_to(Vector2(old_anchor1)) < 0.001, "Fall 1 / Vorschau: niemand eingeschifft, Startpunkt des Vorschau-Eintrags ist der Wert der Anker-Funktion")

	# Pilot laeuft wirklich zum Schiff zurueck (wie campaign_five_actual_sorties_verifier) und geht ueber den normalen Weg an Bord.
	var plan: Dictionary = simulation.plan_hex_ground_actor_approach(PackedStringArray([_pilot_id]), Vector2(access.position), 96.0)
	if not _check(plan.get("ok", false), "Pilot erhaelt ein legales Ziel am Schiffszugang"): return
	var token := "n7-pilot-board"
	simulation.enqueue_command({"type": "move_to_position", "unit_id": _pilot_id, "team_id": "team_alpha", "target_position": plan.targets[_pilot_id], "command_token": token, "move_speed_factor": 1.0, "source_command_type": "pilot_board"})
	var at_ship: bool = await _until(func(): return simulation.has_hex_destination_arrived(_pilot_id, token), 240000)
	if not _check(at_ship, "Pilot laeuft wirklich zum Schiffszugang zurueck"): return
	var boarding: Dictionary = controller.request_campaign_crew_boarding(_craft_id, "", _pilot_id)
	print("EMBARKED_USE pilot_boarding=", boarding)
	if not _check(bool(boarding.get("ok", false)), "Pilot wird ueber den normalen Weg eingeschifft"): return
	var aboard: bool = await _until(func(): return bool(pilot.get_meta("dropship_embarked", false)) and simulation.get_hex_unit_state(_pilot_id).is_empty(), 15000)
	if not _check(aboard, "Pilot ist an Bord (Kennzeichen gesetzt, kein Hex-Zustand)"): return

	# Fall 2: Truppfuehrer allein am Boden. Erst vom Objekt weg, dann auf den Marker marschieren.
	var away: Vector2 = marker + (Vector2(access.position) - marker).normalized() * minf(600.0, marker.distance_to(Vector2(access.position)) * 0.5)
	await _march(controller, simulation, away, [_leader_id], 180000)
	var walked: bool = await _march(controller, simulation, marker, [_leader_id], 240000)
	_check(walked, "Fall 2: Truppfuehrer kommt beim Marker zur Ruhe")
	var slot_leader := Vector2(_observed_targets.get(_leader_id, Vector2(INF, INF)))
	var positions: Dictionary = _team_position_entry(controller)
	var entry2: Dictionary = _use_entry(controller)
	print("EMBARKED_USE case2 slots=", _observed_targets, " leader=", leader.global_position, " leader_to_marker=", leader.global_position.distance_to(marker), " use_position=", positions.get("position"), " entry=", {"status": entry2.get("runtime_use_status"), "reason": entry2.get("runtime_use_reason"), "distance": entry2.get("distance_world")})
	_check(_observed_max_count == 1 and not _observed_targets.has(_pilot_id), "Fall 2 / Fehler 2 (Platz): nur der Truppfuehrer bekommt einen Platz, der eingeschiffte Pilot keinen")
	_check(slot_leader.distance_to(marker) <= USE_RADIUS, "Fall 2 / Fehler 2 (Platz): Platz des Truppfuehrers liegt innerhalb des Nutzungsradius um den Marker")
	_check(leader.global_position.distance_to(marker) <= USE_RADIUS, "Fall 2 / Fehler 2 (Platz): Truppfuehrer steht nach Ankunft innerhalb des Radius")
	_check(positions.has("position") and Vector2(positions.position).distance_to(leader.global_position) < 1.0, "Fall 2 / Fehler 1 (Abstand): Truppposition der Nutzung ist die Position des Truppfuehrers, nicht das Mittel mit dem Piloten an Bord")
	# Teil B, Pilot eingeschifft: Vorschau-Linien und Richtungsanker beginnen beim Truppfuehrer am Boden, nicht zwischen Truppfuehrer und Schiff.
	var preview2: Dictionary = _anchor_entry(controller)
	var old_anchor2: Variant = controller.call("_resolve_fireteam_visual_anchor_position", _team_id.strip_edges().to_lower())
	print("EMBARKED_USE case2 preview_entry=", preview2.get("position"), " old_anchor=", old_anchor2, " leader=", leader.global_position)
	_check(typeof(old_anchor2) == TYPE_VECTOR2 and Vector2(old_anchor2).distance_to(leader.global_position) >= HEX_SIZE_WORLD, "Fall 2 / Vorschau Vorbedingung: der alte Anker laege mindestens ein Hexfeld vom Truppfuehrer entfernt")
	_check(preview2.has("position") and Vector2(preview2.position).distance_to(leader.global_position) < HEX_SIZE_WORLD, "Fall 2 / Vorschau: Startpunkt des Vorschau-Eintrags liegt beim Truppfuehrer (weniger als ein Hexfeld)")
	# Pfad ohne Hex-Bindung (Skirmish, Mehrspieler): dort filtert der Hex-Bereich den Piloten nicht heraus,
	# die Platzvergabe bekommt beide Einheiten. Direkt gegen den echten Bewegungsbesitzer geprueft.
	var movement = controller.get("_fireteam_movement_controller")
	var pure_records: Array = movement._build_member_records([leader, pilot], leader)
	var pure_targets: Dictionary = movement._build_formation_targets(marker, pure_records, _leader_id, 1.0, true, {"command_type": "move", "center_partial_formation": true})
	print("EMBARKED_USE case2 pure_records=", pure_records.size(), " pure_targets=", pure_targets)
	_check(pure_records.size() == 1 and not pure_targets.has(_pilot_id), "Fall 2 / Fehler 2 (Platz, ohne Hex-Bindung): der eingeschiffte Pilot bekommt keinen Platz")
	_check(pure_targets.has(_leader_id) and Vector2(pure_targets.get(_leader_id, Vector2(INF, INF))).distance_to(marker) < 1.0, "Fall 2 / Fehler 2 (Platz, ohne Hex-Bindung): einzelne Person am Boden bekommt den Mittelplatz auf dem Marker")
	_style_checks(movement)
	_check(String(entry2.get("runtime_use_status", "")) == "usable", "Fall 2: Objekt ist benutzbar")
	var intent: Dictionary = controller.call("create_selected_mission_interaction_use_intent", OBJECT_ID)
	print("EMBARKED_USE case2 intent=", intent)
	_check(bool(intent.get("accepted", false)), "Fall 2: Nutzung ueber den oeffentlichen Weg wird angenommen")

	# Fall 4: Rueckweg. Pilot steigt wieder aus, Truppposition und Platzvergabe wie bisher (zwei Plaetze).
	var deployment: Dictionary = controller.request_campaign_crew_deployment(_craft_id)
	print("EMBARKED_USE pilot_deployment=", deployment)
	_check(bool(deployment.get("ok", false)), "Fall 4: Pilot steigt wieder aus")
	var out: bool = await _until(func(): return not bool(pilot.get_meta("dropship_embarked", true)) and not simulation.get_hex_unit_state(_pilot_id).is_empty() and Dictionary(controller.get("_deployed_unit_ids")).has(_pilot_id), 30000)
	if not _check(out, "Fall 4: Pilot steht wieder am Boden"): return
	await _until(func(): return false, 1000)
	var positions4: Dictionary = _team_position_entry(controller)
	var mean := (leader.global_position + pilot.global_position) / 2.0
	_check(positions4.has("position") and Vector2(positions4.position).distance_to(mean) < 1.0, "Fall 4: Truppposition ist wieder das Mittel beider Mitglieder am Boden")
	var records4: Array = movement._build_member_records([leader, pilot], leader)
	var targets4: Dictionary = movement._build_formation_targets(marker, records4, _leader_id, 1.0, true, {"command_type": "move", "center_partial_formation": true})
	_check(records4.size() == 2 and targets4.size() == 2 and targets4.has(_pilot_id), "Fall 4: Platzvergabe ohne Hex-Bindung wieder mit zwei Plaetzen")
	var back: bool = await _march(controller, simulation, Vector2(access.position), [_leader_id, _pilot_id], 240000)
	_check(back, "Fall 4: Trupp kommt am Schiff zur Ruhe")
	_check(_observed_max_count == 2, "Fall 4: Platzvergabe wieder mit zwei Plaetzen")

	# Fall 3: ganzer Trupp eingeschifft (beide stehen nach dem Rueckmarsch am Schiff).
	var all_boarding: Dictionary = controller.request_campaign_crew_boarding(_craft_id)
	print("EMBARKED_USE all_boarding=", all_boarding)
	var all_aboard: bool = await _until(func(): return bool(leader.get_meta("dropship_embarked", false)) and bool(pilot.get_meta("dropship_embarked", false)), 15000)
	if not _check(all_aboard, "Fall 3: ganzer Trupp ist an Bord"): return
	await _until(func(): return false, 1000)
	var entry3: Dictionary = _use_entry(controller)
	print("EMBARKED_USE case3 position_count=", _team_position_count(controller), " entry=", {"status": entry3.get("runtime_use_status"), "reason": entry3.get("runtime_use_reason"), "distance": entry3.get("distance_world")})
	_check(_team_position_count(controller) == 0, "Fall 3: ganzer Trupp eingeschifft liefert keine Truppposition fuer die Nutzung")
	_check(not bool(entry3.get("can_use_now", false)) and String(entry3.get("runtime_use_status", "")) != "usable", "Fall 3: Objekt ist nicht benutzbar")
	var intent3: Dictionary = controller.call("create_selected_mission_interaction_use_intent", OBJECT_ID)
	_check(not bool(intent3.get("accepted", false)), "Fall 3: Nutzung wird abgelehnt (kein Absturz)")

	# Fall 5: Hilfsfunktion der Nutzungsposition direkt. Beide steigen wieder aus, nur der Pilot geht an Bord, der Truppfuehrer bleibt am Boden.
	var deployment5: Dictionary = controller.request_campaign_crew_deployment(_craft_id)
	print("EMBARKED_USE all_deployment=", deployment5)
	if not _check(bool(deployment5.get("ok", false)), "Fall 5: ganzer Trupp steigt wieder aus"): return
	var out5: bool = await _until(func(): return not bool(leader.get_meta("dropship_embarked", true)) and not bool(pilot.get_meta("dropship_embarked", true)) and not simulation.get_hex_unit_state(_leader_id).is_empty() and not simulation.get_hex_unit_state(_pilot_id).is_empty(), 30000)
	if not _check(out5, "Fall 5: beide stehen wieder am Boden"): return
	var plan5: Dictionary = simulation.plan_hex_ground_actor_approach(PackedStringArray([_pilot_id]), Vector2(access.position), 96.0)
	if not _check(plan5.get("ok", false), "Fall 5: Pilot erhaelt ein legales Ziel am Schiffszugang"): return
	var token5 := "n7-pilot-board-5"
	simulation.enqueue_command({"type": "move_to_position", "unit_id": _pilot_id, "team_id": "team_alpha", "target_position": plan5.targets[_pilot_id], "command_token": token5, "move_speed_factor": 1.0, "source_command_type": "pilot_board"})
	if not _check(await _until(func(): return simulation.has_hex_destination_arrived(_pilot_id, token5), 240000), "Fall 5: Pilot laeuft zum Schiffszugang"): return
	# Nach dem Aussteigen setzt das Schiff erst seine Landesequenz fort ("craft_not_landed"): bis zu 30 s warten.
	var attempt: Dictionary = {}
	await _until(func():
		attempt["answer"] = controller.request_campaign_crew_boarding(_craft_id, "", _pilot_id)
		return bool(Dictionary(attempt["answer"]).get("ok", false)) or String(Dictionary(attempt["answer"]).get("reason", "")) != "craft_not_landed", 30000)
	var boarding5: Dictionary = Dictionary(attempt.get("answer", {}))
	print("EMBARKED_USE pilot_boarding_5=", boarding5)
	if not _check(bool(boarding5.get("ok", false)), "Fall 5: Pilot wird eingeschifft"): return
	if not _check(await _until(func(): return bool(pilot.get_meta("dropship_embarked", false)) and not bool(leader.get_meta("dropship_embarked", false)), 15000), "Fall 5: nur der Pilot ist an Bord"): return
	var fireteam_id := _team_id.strip_edges().to_lower()
	# Ausgeschlossenes Mitglied am Boden zaehlt mit, wie vor dem heutigen Tag.
	movement.set_unit_excluded(_leader_id, true)
	var excluded_position: Variant = controller.call("_resolve_fireteam_ground_use_position", fireteam_id)
	movement.set_unit_excluded(_leader_id, false)
	_check(typeof(excluded_position) == TYPE_VECTOR2 and Vector2(excluded_position).distance_to(leader.global_position) < 1.0, "Fall 5: per set_unit_excluded ausgeschlossener Truppfuehrer am Boden zaehlt fuer die Nutzungsposition mit (%s)" % str(excluded_position))
	# Truppfuehrer faellt aus (0 HP), Pilot ist an Bord: niemand einsatzfaehig am Boden, also keine Position.
	leader.call("apply_damage", 10000)
	_check(await _until(func(): return String(leader.call("get_vital_state")) != "fit", 10000), "Fall 5: Truppfuehrer liegt (0 HP)")
	var down_position: Variant = controller.call("_resolve_fireteam_ground_use_position", fireteam_id)
	_check(typeof(down_position) == TYPE_NIL, "Fall 5: Pilot eingeschifft, Truppfuehrer 0 HP: keine Nutzungsposition (%s)" % str(down_position))
