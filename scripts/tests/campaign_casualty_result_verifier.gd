extends "res://scripts/tests/campaign_pilot_ground_loop_test.gd"
## Task 3 (Ausfall und Rueckzug): Kampagneneinsatz schaltet die Verlustregeln am Driver ein
## und das Missionsergebnis traegt was_downed / near_ship / aboard je Person.
## Echter Kampagnenstart, echte Meta-Szene, echter Einsatz. Skirmish-Gegenprobe am Ende.

const CASUALTY_RULES = preload("res://scripts/core/campaign_casualty_rules.gd")
const EXTRA_KEYS := ["was_downed", "near_ship", "aboard"]

func _on_actual_landed(_controller: Node) -> void:
	pass

func _wait(predicate: Callable, milliseconds: int, label: String) -> bool:
	# Der Lauf unter niedriger Prioritaet ist langsam; die Fristen der Elternklasse sind knapp.
	# Die Missionsinstanz entsteht erst nach der Gelaendevorbereitung der grossen Karte: bis zu 180 s.
	if label.ends_with("actual mission instance exists"):
		milliseconds = maxi(milliseconds, 180000)
	return await super._wait(predicate, milliseconds * 4 if milliseconds < 180000 else milliseconds, label)

func _entry(result: Dictionary, unit_id: String) -> Dictionary:
	for state: Dictionary in Array(result.get("team_states", [])):
		if String(state.get("unit_id", "")) == unit_id:
			return state
	return {}

func _run() -> void:
	var rules: Dictionary = CASUALTY_RULES.load_rules()
	var radius: float = float(rules.get("recovery_radius_world", 0.0))
	_check(radius > 88.0 and radius < 265.0, "Regeldatei liefert einen Rueckholradius zwischen Nachbarfeld (88) und drei Feldern (265)")
	_configure_entry()
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if await _campaign_part(radius):
		await _skirmish_part()
	print("CAMPAIGN_CASUALTY_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _campaign_part(radius: float) -> bool:
	if not await _prepare_initial_base(): return false
	_crew_ids = ["campaign_leader"]
	_pilot_id = "campaign_pilot"
	_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Accept actual job")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Choose actual location")
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): return false
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var simulation: Node = mission.get_node("SimulationRoot")
	_check(bool(driver.get("campaign_casualty_rules_enabled")), "Kampagneneinsatz: Schalter am CombatLoopDriver ist an")
	_check(is_equal_approx(float(driver.get("down_revive_window_seconds")), 60.0), "Kampagneneinsatz: Frist stammt aus den Regeln (60 s)")
	var leader: Node2D = controller.call("_get_campaign_sortie_unit", "campaign_leader")
	var pilot: Node2D = controller.call("_get_campaign_sortie_unit", "campaign_pilot")
	if not _check(leader != null and pilot != null, "Beide echten Personen stehen im Einsatz"): return false
	var access: Dictionary = controller.call("get_campaign_ground_ship_access", _craft_id)
	if not _check(bool(access.get("ok", false)), "Gelandetes Schiff liefert einen Zugangspunkt"): return false
	var hex_required: bool = bool(controller.call("_requires_hex_deployment_owner"))
	print("CASUALTY_RESULT_FIXTURE hex_required=", hex_required, " ship_access=", access.get("position"))
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, "Treiber merkt sich die ausgefallene Person"):
		print("CASUALTY_RESULT_DEBUG vital=", leader.call("get_vital_state"), " hp=", leader.call("get_health"), " team=", leader.call("get_team_id"), " friendly_team=", driver.get("friendly_team_id"), " flags=", driver.call("get_casualty_flags"), " paths=", driver.get("friendly_unit_paths"), " connections=", leader.get_signal_connection_list("vital_status_changed").size(), " runs_local=", driver.get("_runs_local_authority"), " alpha_is_leader=", mission.get_node("UnitAlpha") == leader, " bravo_is_leader=", mission.get_node("UnitBravo") == leader, " leader_path=", leader.get_path(), " enabled=", driver.get("campaign_casualty_rules_enabled"), " in_known=", driver.get("_was_downed_unit_ids"))
		return false
	_check(not bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_pilot", {}).get("was_downed", true)), "Unversehrter Pilot ist nicht als ausgefallen markiert")
	pilot.set_meta("dropship_embarked", true)
	# Fall 1: etwa drei Felder (270) vom Schiff entfernt.
	if not await _place_leader(leader, simulation, access, Vector2(270.0, 0.0)): return false
	var far: Dictionary = _flow.call("_build_mission_result", mission, {})
	var far_leader: Dictionary = _entry(far, "campaign_leader")
	_check(bool(far_leader.get("was_downed", false)) and not bool(far_leader.get("near_ship", true)) and not bool(far_leader.get("aboard", true)), "270 Einheiten entfernt: was_downed, nicht near_ship, nicht aboard")
	var far_pilot: Dictionary = _entry(far, "campaign_pilot")
	_check(bool(far_pilot.get("aboard", false)) and not bool(far_pilot.get("was_downed", true)), "Pilot im Schiff: aboard, nicht was_downed")
	# Fall 2: ein Feld daneben (88).
	if not await _place_leader(leader, simulation, access, Vector2(88.0, 0.0)): return false
	var near: Dictionary = _flow.call("_build_mission_result", mission, {})
	var near_leader: Dictionary = _entry(near, "campaign_leader")
	_check(bool(near_leader.get("was_downed", false)) and bool(near_leader.get("near_ship", false)) and not bool(near_leader.get("aboard", true)), "88 Einheiten entfernt: was_downed, near_ship, nicht aboard")
	_check(Array(near.get("team_states", [])).size() == 2, "Weiterhin genau die zwei Personen im Ergebnis")
	for state: Dictionary in Array(near.get("team_states", [])):
		for key: String in EXTRA_KEYS:
			_check(state.has(key) and typeof(state.get(key)) == TYPE_BOOL, "Kampagneneintrag %s hat bool %s" % [state.get("unit_id"), key])
	_check(radius > 0.0, "Radius kam aus den Regeln, nicht aus dem Code")
	_flow.queue_free()
	await process_frame
	return true

## Setzt die Person auf Abstand vom Schiffszugang, ueber dieselbe Positionsquelle wie das Ergebnis.
func _place_leader(leader: Node2D, simulation: Node, access: Dictionary, offset: Vector2) -> bool:
	var target: Vector2 = Vector2(access.position) + offset
	var registry: Node = simulation.call("get_hex_ground_terrain_registry")
	var ground: Dictionary = simulation.call("get_hex_unit_state", "campaign_leader")
	if not _check(not ground.is_empty() and registry != null, "Hex-Zustand der Person ist lesbar (Satellitenkarte ist eine Hex-Karte)"): return false
	# Test-Fixture: der Hex-Zustand ist die Quelle des Ergebnisses; es gibt keinen oeffentlichen Setter.
	var runtime: RefCounted = simulation.get("_hex_ground_runtime")
	var grid: Variant = registry.call("world_to_grid", target)
	Dictionary(runtime.get("_units_by_id")["campaign_leader"])["grid"] = grid
	var cell_world: Vector2 = registry.call("grid_to_world", Dictionary(simulation.call("get_hex_unit_state", "campaign_leader")).grid)
	var distance: float = cell_world.distance_to(Vector2(access.position))
	print("CASUALTY_RESULT_HEX_TARGET offset=", offset, " cell_distance=", distance)
	# Das Hex-Raster ist grob (Zellabstand ca. 88; Messung gegen den Radius aus den Regeln): die Zelle muss auf der gewuenschten Seite des Radius liegen.
	var radius: float = float(CASUALTY_RULES.load_rules().get("recovery_radius_world", 0.0))
	var on_wanted_side: bool = distance > radius if offset.length() > radius else distance <= radius
	if not _check(on_wanted_side, "Zelle liegt auf der gewuenschten Seite des Rueckholradius %s (Abstand %s, gewuenscht %s)" % [radius, distance, offset.length()]): return false
	# Irrefuehrende Weltposition: das Ergebnis muss den Hex-Zustand lesen, nicht global_position.
	leader.global_position = Vector2(access.position)
	return true

func _skirmish_part() -> void:
	START.request_start(self, "skirmish", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_flow.call("_start_mission")
	var mission: Node = _flow.get("_active_mission")
	if not _check(mission != null, "Skirmish-Einsatz wird gestartet"): return
	await process_frame
	var driver: Node = mission.get_node("CombatLoopDriver")
	_check(not bool(driver.get("campaign_casualty_rules_enabled")), "Skirmish: Schalter am CombatLoopDriver bleibt aus")
	_check(is_equal_approx(float(driver.get("down_revive_window_seconds")), 3.0), "Skirmish: Frist bleibt beim Standardwert")
	var result: Dictionary = _flow.call("_build_mission_result", mission, {})
	var states: Array = Array(result.get("team_states", []))
	_check(not states.is_empty(), "Skirmish-Ergebnis hat Eintraege")
	for state: Dictionary in states:
		for key: String in EXTRA_KEYS:
			_check(not state.has(key), "Skirmish-Eintrag %s hat kein Feld %s" % [state.get("unit_id"), key])
		_check(state.keys().size() == 6, "Skirmish-Eintrag %s hat unveraenderte sechs Felder" % state.get("unit_id"))
	_flow.queue_free()
	await process_frame
