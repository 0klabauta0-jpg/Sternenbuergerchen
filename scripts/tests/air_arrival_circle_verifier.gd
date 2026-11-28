extends "res://scripts/tests/campaign_air_support_real_mission_verifier.gd"
## Abschnitt LB: Ankunft in der Luft ("Kreisen") statt Landen, danach Luftangriff und spaeter Landen.
## Teil 1: SimulationRoot-Eintrag request_air_support_arrival mit Attrappen fuer Fluss und Besatzung (Jaeger und Landefaehre).
## Teil 2: echter Missionscontroller auf GM02 (Netzbefehl, Planungszustand, Satz bei Ablehnung, Flugabwehr-Abbruch).
## Teil 3: echte Kampagnen-Mission (Landefaehre mit Trupp): Kreisen, Speichern, Auftragsende, Landen, Absetzen, Heimflug.
const ROOT_SCRIPT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const TERRAIN_MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const DISPERSION = preload("res://scripts/mission/air_support_dispersion.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const MISSION_SCENE = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MP_CONTRACT = preload("res://scripts/multiplayer/multiplayer_command_contract.gd")
const PLAN = preload("res://scripts/mission/air_defense_approach_plan.gd")
const GM02_MAP := "res://maps/Ground_Mission02_128x128.json"
const GM02_SCENARIO := "res://data/mission_scenarios/ground_mission02_128x128.json"
const CIRCLE_HINT := "Das Schiff landet nicht, sondern bleibt über der Landezone in der Luft. Der Trupp bleibt an Bord, bis du landen lässt."
const GENERIC_SAVE_TEXT := "Dieser Zustand kann momentan nicht sicher gespeichert werden."

var _circle_hooks := false
var _saw_landed := false


# ---------------------------------------------------------------- Attrappen fuer Teil 1
class FixFlow extends Node:
	var _active_mission: Node
	var _craft_location_runtime := {"ship":"moon_site"}
	var _assigned_aircraft_pilot_by_craft := {"ship":"pilot"}
	func get_active_mission() -> Node: return _active_mission

class FixPerson extends Node2D:
	var unit_id := ""
	var health := 100
	var team := "blue"
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team
	func get_health() -> int: return health
	func get_character_profile_bundle() -> Dictionary: return {"platform_values":{"dropship_piloting":1.0, "fighter_piloting":1.0}}
	func apply_damage(amount: int, _context: Dictionary = {}) -> bool: health -= amount; return true

class FixVision extends Node:
	func get_multiplayer_visible_unit_ids(_team: String) -> PackedStringArray:
		return PackedStringArray(["foe"])

class FixTransport extends Node:
	var boarded := true
	var landing_clear := true
	# Das Schiff war nie gelandet: kein "geparkt". Das ist der Unterschied zum Start (request_air_support_takeoff).
	func get_campaign_air_support_pilot_guard(_craft_id: String) -> Dictionary:
		return {"ok":true, "pilot_unit_id":"pilot"} if boarded else {"ok":false, "reason":"pilot_boarding_pending"}
	func _is_parked_campaign_dropship(_craft_id: String) -> bool: return false
	func _campaign_landed_craft_position(_craft_id: String) -> Vector2: return Vector2.ZERO
	func _ground_ship_touchdown_ready(_id: String, _position: Vector2, _visual: bool) -> bool: return landing_clear


func _run() -> void:
	_part_root_fixture("buccaneer", false)
	_part_root_fixture("cutlass", true)
	_part_root_fixture("cutlass", false, "polisa")
	await _part_harness()
	await _part_flak_arrival()
	if not "--no-real" in OS.get_cmdline_user_args():
		await _part_real()
	await _finish()


func _finish() -> void:
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("AIR_ARRIVAL_CIRCLE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)


# ---------------------------------------------------------------- Teil 1
func _part_root_fixture(model_id: String, troop_aboard: bool, loc: String = "moon_site") -> void:
	var tag := "[%s%s%s] " % [model_id, " mit Trupp" if troop_aboard else "", " " + loc if loc != "moon_site" else ""]
	print("--- Teil 1 ", tag)
	var flow := FixFlow.new(); root.add_child(flow)
	var adapter = ADAPTER.new(); flow.add_child(adapter); adapter._flow = flow
	var source = ROOT_SCRIPT.new(); adapter.add_child(source); adapter._simulation = source
	var fleet = FLEET.new(); fleet.configure(); fleet.register_craft("ship")
	var equipment = EQUIPMENT.new(); equipment.configure([{"craft_id":"ship", "model_id":model_id}])
	source.configure_singleplayer_owners(null, null, null, fleet); source.configure_ship_equipment(equipment)
	source.configure_departure_adapter(adapter)
	source.get("_space_wing_state").ensure_flying_wings("singleplayer", ["ship"], ["ship"], {"ship":"pilot"})
	flow._craft_location_runtime = {"ship": loc}
	var mission := Node.new(); mission.set_meta("location_id", loc); flow.add_child(mission)
	var mission_root = ROOT_SCRIPT.new(); mission_root.name = "SimulationRoot"; mission.add_child(mission_root); flow._active_mission = mission
	_check(bool(adapter.bind_mission_air_support(mission).ok), tag + "Luftunterstuetzung ist an die Mission gebunden")
	var terrain = TERRAIN.new(); terrain.name = "Terrain"; mission.add_child(terrain); terrain.configure_iso_grid(Vector2.ZERO, 64, 32, "hex_axial_v1")
	terrain.register_tile(TILE.new({"tile_id":"zero", "grid_position":Vector2i.ZERO, "explicit_hex_ramps":true}))
	var units = UNITS.new(); units.name = "Units"; mission.add_child(units)
	mission_root.unit_registry_path = mission_root.get_path_to(units); mission_root.terrain_registry_path = mission_root.get_path_to(terrain)
	var map = TERRAIN_MAP.create_empty(loc, Vector2i(4,3), Vector2.ZERO, 64, 32, 3, "hex_axial_v1"); map.set_tactical_grid_rules("hex_tactical_v1")
	mission_root.configure_hex_ground_runtime(map, terrain)
	var pilot = FixPerson.new(); pilot.unit_id = "pilot"; mission.add_child(pilot); units.register_unit("pilot", pilot); mission_root.register_known_unit("pilot", pilot)
	pilot.set_meta("dropship_embarked", true)
	if troop_aboard:
		var trooper = FixPerson.new(); trooper.unit_id = "trooper"; mission.add_child(trooper); units.register_unit("trooper", trooper); mission_root.register_known_unit("trooper", trooper)
		trooper.set_meta("dropship_embarked", true)
	var vision = FixVision.new(); vision.name = "CombatLoopDriver"; mission.add_child(vision)
	var transport = FixTransport.new(); transport.name = "TacticalController"; mission.add_child(transport)
	for q in range(5, 20):
		for r in range(5, 20): terrain.register_tile(TILE.new({"tile_id":"air:%d:%d" % [q,r], "grid_position":Vector2i(q,r), "explicit_hex_ramps":true}))
	var lz_grid := Vector2i(10, 10)
	var lz_position: Vector2 = terrain.grid_to_world(lz_grid)
	var foe = FixPerson.new(); foe.unit_id = "foe"; foe.team = "red"; mission.add_child(foe); units.register_unit("foe", foe); mission_root.register_known_unit("foe", foe)
	var placements: Array[Dictionary] = [{"unit_id":"foe", "grid":Vector2i(13,10)}]; mission_root.admit_hex_ground_units(placements)
	var flight: RefCounted = fleet.get_flight_state("ship")
	var initial_pose: Dictionary = flight.get_snapshot()
	var combat: RefCounted = source.get("_space_combat_state")
	source.tick_counter = 50

	if loc == "polisa":
		var polisa: Dictionary = mission_root.request_air_support_arrival("ship", lz_position)
		_check(String(polisa.get("reason", "")) == "no_planetary_atmosphere" and flight.get_snapshot() == initial_pose and not mission_root.is_air_support_craft_airborne("ship"), tag + "Polisa ohne Atmosphaere: abgelehnt: " + str(polisa))
		flow.free()
		return

	# Der Start verlangt weiter ein gelandetes Schiff; die Ankunft nicht.
	_check(String(mission_root.request_air_support_takeoff("ship").get("reason", "")) == "craft_not_landed" and not mission_root.is_air_support_craft_airborne("ship"), tag + "der Start ohne Landung wird weiter abgelehnt (craft_not_landed)")

	# Ablehnungsgruende der Ankunft (je einer), jedes Mal ohne Wirkung auf den Flug.
	transport.boarded = false
	var no_pilot: Dictionary = mission_root.request_air_support_arrival("ship", lz_position)
	_check(not bool(no_pilot.get("ok", true)) and String(no_pilot.get("reason", "")) == "pilot_boarding_pending" and flight.get_snapshot() == initial_pose, tag + "kein Pilot an Bord: abgelehnt, Flug unveraendert: " + str(no_pilot))
	transport.boarded = true
	var outside: Dictionary = mission_root.request_air_support_arrival("ship", terrain.grid_to_world(Vector2i(300, 300)))
	_check(not bool(outside.get("ok", true)) and flight.get_snapshot() == initial_pose, tag + "Landeposition ausserhalb der Karte: abgelehnt: " + str(outside))
	var nowhere: Dictionary = mission_root.request_air_support_arrival("ship", Vector2.INF)
	_check(String(nowhere.get("reason", "")) == "landing_position_unavailable", tag + "ohne Landeposition: abgelehnt: " + str(nowhere))
	# Ankunft in der Luft.
	var arrival: Dictionary = mission_root.request_air_support_arrival("ship", lz_position)
	_check(bool(arrival.get("ok", false)), tag + "die Ankunft in der Luft wird angenommen (das Schiff war nie gelandet): " + str(arrival))
	_check(mission_root.is_air_support_craft_airborne("ship") and flight.get_snapshot().motion_mode == "tactical" and flight.get_snapshot().space_area_id == "atmosphere:" + loc, tag + "das Schiff ist in der Luft ueber der Landezone")
	var sorties: Dictionary = mission_root.get("_air_support_sorties")
	var sortie: Dictionary = Dictionary(sorties.get("ship", {}))
	_check(sortie.has_all(["flight", "source", "previous_pose", "landing_position", "landing_grid", "was_inactive"]) and Vector2(sortie.landing_position).is_equal_approx(lz_position) and sortie.landing_grid == lz_grid and sortie.previous_pose == initial_pose, tag + "Sortie-Eintrag wie beim Start (Pose vorher, Landeposition und -zelle = aufgeloeste Landezone)")
	var again: Dictionary = mission_root.request_air_support_arrival("ship", lz_position)
	_check(String(again.get("reason", "")) == "already_airborne", tag + "schon im Flug: abgelehnt (already_airborne)")
	if troop_aboard:
		_check(bool(pilot.get_meta("dropship_embarked", false)) and units.get_unit("trooper") != null, tag + "Pilot und Trupp sind weiterhin eingeschifft (die Ankunft laesst sie an Bord)")

	# Bodenfeuer auf einen sichtbaren Gegner ueber die unveraenderten Eintraege.
	var attack: Dictionary = adapter.request_operation("air_support_attack_order", {"craft_id":"ship", "target_unit_id":"foe"})
	_check(bool(attack.get("ok", false)), tag + "Angriffsbefehl auf den sichtbaren Gegner (unveraendert): " + str(attack))
	var fire_seed := -1
	for candidate in range(300):
		var next_seed: int = (candidate * 1103515245 + 12345) & 0x7fffffff
		if DISPERSION.resolve(Vector2i(13,10), 1.0, next_seed).impact_hex == Vector2i(13,10): fire_seed = candidate; break
	_check(fire_seed >= 0, tag + "ein Zufallswert mit Treffer wurde gefunden")
	mission_root.set("_air_ground_rng_state", fire_seed)
	var shot: Dictionary = adapter.request_operation("air_support_ground_fire", {"craft_id":"ship", "target_unit_id":"foe", "weapon_slot":"weapon_1", "request_id":"circle-shot-1"})
	_check(bool(shot.get("ok", false)) and foe.health < 100, tag + "Bodenfeuer aus dem Kreisen trifft den Gegner (Leben %d): %s" % [foe.health, str(shot.get("reason", "ok"))])
	var cease: Dictionary = mission_root.request_air_support_cease_fire("ship", "circle-stop")
	_check(bool(cease.get("ok", false)), tag + "Feuerstopp (unveraendert)")

	# Spaeter landen ueber den vorhandenen Eintrag.
	transport.landing_clear = false
	var blocked: Dictionary = adapter.request_operation("air_support_landing", {"craft_id":"ship"})
	_check(not bool(blocked.get("ok", true)) and mission_root.is_air_support_craft_airborne("ship"), tag + "Landen bei belegter Landeflaeche wird abgelehnt (unveraendert)")
	transport.landing_clear = true
	var landed: Dictionary = adapter.request_operation("air_support_landing", {"craft_id":"ship"})
	_check(bool(landed.get("ok", false)) and not mission_root.is_air_support_craft_airborne("ship") and not Dictionary(mission_root.get("_air_support_sorties")).has("ship"), tag + "Landen nach der Kreis-Ankunft ueber den vorhandenen Eintrag: Sortie beendet: " + str(landed))
	_check(flight.get_snapshot().motion_mode == initial_pose.motion_mode and flight.get_snapshot().position_plane == initial_pose.position_plane, tag + "das Schiff steht wieder wie vor der Ankunft (Pose)")

	# Systeme ausgefallen (Rumpf 0): die Systeme gibt es seit der ersten Ankunft.
	var systems: Dictionary = combat.get("_ship_systems")["ship"]
	var hull_before: float = float(systems.state.hull)
	systems.state.hull = 0.0
	var landed_pose: Dictionary = flight.get_snapshot()
	var wrecked: Dictionary = mission_root.request_air_support_arrival("ship", lz_position)
	_check(String(wrecked.get("reason", "")) == "systems_unavailable" and flight.get_snapshot() == landed_pose, tag + "Systeme ausgefallen (Rumpf 0): abgelehnt: " + str(wrecked))
	systems.state.hull = hull_before

	# Zelle belegt: ein fremdes Fahrzeug steht ueber der Landezone.
	var blocker = FLIGHT.new(); blocker.configure("blocker", {"position_plane":Vector2.ZERO})
	var blocker_pose := {"expected_revision":blocker.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"atmosphere:" + loc, "position_plane":GRID.HEX.axial_to_plane(Vector2(lz_grid)), "motion_mode":"tactical", "assist_mode":"coupled"}
	var blocker_transition: Dictionary = blocker.validate_area_transition(blocker_pose, 1)
	var blocker_admission: Dictionary = combat.validate_new_local_admission({"craft_id":"blocker", "faction_id":"red", "control_domain":"enemy", "footprint_hexes":[Vector2i.ZERO]}, blocker, blocker_pose, 1)
	if bool(blocker_transition.get("ok", false)) and bool(blocker_admission.get("ok", false)):
		blocker._publish_area_transition(blocker_transition); combat._publish_new_local_admission(blocker_admission)
		var occupied: Dictionary = mission_root.request_air_support_arrival("ship", lz_position)
		_check(String(occupied.get("reason", "")) == "occupied_or_invalid_footprint", tag + "Zelle ueber der Landezone belegt: abgelehnt: " + str(occupied))
	else:
		_check(false, tag + "Fremdfahrzeug fuer den Belegt-Fall konnte nicht eingesetzt werden")
	flow.free()


# ---------------------------------------------------------------- Teil 2
func _open_gm02(parent: Node = null) -> Dictionary:
	var mission: Node = MISSION_SCENE.instantiate()
	var setup: Node = mission.get_node("MissionSetup")
	setup.set("map_file_path", GM02_MAP)
	setup.set("scenario_file_path", GM02_SCENARIO)
	setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo"]))
	setup.set("selected_team_fireteam_ids", PackedStringArray(["ft1", "ft2"]))
	setup.set("defer_friendly_runtime_activation", true)
	(parent if parent != null else root).add_child(mission)
	for _frame in range(3):
		await process_frame
	var controller: Node = mission.get_node("TacticalController")
	controller.set_process(false)
	var teams: PackedStringArray = controller.call("_get_available_fireteam_ids")
	var env := {"mission": mission, "controller": controller, "teams": teams, "ok": teams.size() >= 2}
	if teams.size() < 2:
		return env
	var first_ids: Array = _unit_ids(controller.call("_get_fireteam_units", String(teams[0]), true))
	var second_ids: Array = _unit_ids(controller.call("_get_fireteam_units", String(teams[1]), true))
	var registry: Node = controller.call("_get_terrain_registry")
	var hot_lz: Vector2 = registry.call("grid_to_world", Vector2i(90, 85))
	var quiet_lz: Vector2 = TERRAIN_MAP.load_from_file(GM02_MAP).get_marker_position("spawn_alpha")
	var state: Dictionary = controller.call("get_planning_state")
	var cards: Array = [_card("craft_a", String(teams[0]), first_ids, hot_lz), _card("craft_b", String(teams[1]), second_ids, quiet_lz)]
	state.merge({"mission_drop_source": "homebase_direct", "mission_drop_craft_id": "craft_a", "mission_drop_state": "waiting", "drop_ship_staged": true,
		"embarked_unit_ids": first_ids + second_ids, "deployed_unit_ids": [], "has_lz_position": true, "lz_position": hot_lz, "selected_fireteams": [teams[0]],
		"mission_drop_cards": cards}, true)
	controller.call("set_planning_state", state)
	controller.call("_select_mission_dropship_craft", "craft_a", false)
	controller.call("_set_selected_fireteams", PackedStringArray([teams[0]]), false)
	env.merge({"first_ids": first_ids, "second_ids": second_ids, "hot_lz": hot_lz, "quiet_lz": quiet_lz}, true)
	return env


func _part_harness() -> void:
	print("--- Teil 2 (Controller auf GM02)")
	var env: Dictionary = await _open_gm02()
	if not _check(bool(env.ok), "GM02-Mission mit zwei Trupps geoeffnet"):
		return
	var mission: Node = env.mission
	var controller: Node = env.controller
	var team := String(env.teams[0])
	var simulation_root: Node = mission.get_node("SimulationRoot")

	# E1/E3: Vorgabe, Karte, Planungszustand, Netzbefehl.
	_check(String(controller.get("_current_arrival_mode")) == "land" and String(Dictionary(controller.call("get_planning_state")).get("arrival_mode", "")) == "land", "(g) ohne Angabe gilt Landen; Planungszustand fuehrt arrival_mode")
	var reject: Dictionary = MP_CONTRACT.new().validate({"contract_category": "dropship_command", "command_type": "set_dropship_arrival_mode", "team_id": "team_alpha", "fireteam_id": team, "craft_id": "craft_a", "arrival_mode": "schweben"})
	var missing: Dictionary = MP_CONTRACT.new().validate({"contract_category": "dropship_command", "command_type": "set_dropship_arrival_mode", "team_id": "team_alpha", "fireteam_id": team, "craft_id": "craft_a"})
	var accept: Dictionary = MP_CONTRACT.new().validate({"contract_category": "dropship_command", "command_type": "set_dropship_arrival_mode", "team_id": "team_alpha", "fireteam_id": team, "craft_id": "craft_a", "arrival_mode": "circle"})
	_check(String(reject.get("reason", "")) == "dropship_arrival_mode_invalid" and String(missing.get("reason", "")) == "dropship_arrival_mode_missing" and not String(accept.get("reason", "")).begins_with("dropship_arrival_mode"), "(g) der Netzvertrag lehnt unbekannte und fehlende Werte ab und laesst circle durch: " + String(accept.get("reason", "angenommen")))
	var bad: bool = bool(controller.call("apply_authoritative_dropship_command", {"command_type": "set_dropship_arrival_mode", "craft_id": "craft_a", "fireteam_id": team, "arrival_mode": "schweben"}))
	_check(not bad and String(controller.get("_current_arrival_mode")) == "land", "(g) der Controller lehnt einen ungueltigen Wert ab, der gespeicherte bleibt")
	var good: bool = bool(controller.call("apply_authoritative_dropship_command", {"command_type": "set_dropship_arrival_mode", "craft_id": "craft_a", "fireteam_id": team, "arrival_mode": "circle"}))
	_check(good and String(_find_card(controller, "craft_a").get("arrival_mode", "")) == "circle" and String(_find_card(controller, "craft_b").get("arrival_mode", "land")) == "land", "(g) der Befehl speichert circle nur auf der Karte dieses Schiffs")
	var saved: Dictionary = controller.call("get_planning_state")
	controller.call("_select_arrival_mode", "land")
	controller.call("set_planning_state", saved)
	_check(String(controller.get("_current_arrival_mode")) == "circle" and String(_find_card(controller, "craft_a").get("arrival_mode", "")) == "circle", "(g) der Wert ueberlebt den Planungszustand wie die Anflugart")
	controller.call("_select_mission_dropship_craft", "craft_b", false)
	_check(String(controller.get("_current_arrival_mode")) == "land", "(g) ein anderes Schiff hat seinen eigenen Wert (Vorgabe Landen)")
	controller.call("_select_mission_dropship_craft", "craft_a", false)
	_check(String(controller.get("_current_arrival_mode")) == "circle", "(g) zurueck zum ersten Schiff: circle ist noch da")
	_check(String(controller.call("_effective_arrival_mode")) == "land", "(E1) wo keine Luftunterstuetzung angeboten wird, bleibt der Wert unsichtbar wirkungslos: effektiv Landen")
	controller.call("_update_ui")
	var details := mission.get_node_or_null("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Header/DetailsButton") as Button
	if details != null:
		details.pressed.emit()
	for _frame in range(4):
		await process_frame
	_check(_find_button_by_meta(mission, "mission_dropship_arrival_mode", "circle", "craft_a") == null, "(E1) ohne Luftunterstuetzungs-Zeile gibt es auch keine Ankunfts-Zeile")

	# E5: Ablehnungs-Saetze woertlich.
	var cases := {
		"pilot_boarding_pending": "Kreisen nicht möglich: kein Pilot an Bord – das Schiff landet.",
		"pilot_not_aboard": "Kreisen nicht möglich: kein Pilot an Bord – das Schiff landet.",
		"no_planetary_atmosphere": "Kreisen nicht möglich: hier gibt es keine Atmosphäre – das Schiff landet.",
		"systems_unavailable": "Kreisen nicht möglich: die Schiffssysteme sind ausgefallen – das Schiff landet.",
		"occupied_or_invalid_footprint": "Kreisen nicht möglich: die Zelle über der Landezone ist belegt – das Schiff landet.",
		"already_airborne": "Kreisen nicht möglich: das Schiff ist schon in der Luft – das Schiff landet.",
		"crew_deployment_pending": "Kreisen nicht möglich: die Besatzung steigt noch ein oder aus – das Schiff landet.",
		"irgendein_neuer_grund": "Kreisen nicht möglich – das Schiff landet.",
	}
	for reason in cases:
		_check(String(controller.call("_circle_refusal_message", reason)) == String(cases[reason]), "(e) Satz fuer %s: %s" % [reason, String(cases[reason])])

	# E5 am Controller: Root lehnt ab (hier ist keine Luftunterstuetzung gebunden), das Schiff landet normal und der Spieler liest den Satz.
	controller.call("_select_mission_dropship_craft", "craft_b", false)
	controller.call("_set_selected_fireteams", PackedStringArray([env.teams[1]]), false)
	_check(bool(controller.call("_try_start_drop_sequence", true)), "(e) der Anflug zum ruhigen Landeplatz beginnt")
	var no_source: Dictionary = controller.call("_begin_circling_arrival", "craft_b", Vector2(controller.get("_drop_sequence_lz_position")))
	_check(not bool(no_source.get("ok", true)) and String(no_source.get("reason", "")) == "air_source_unavailable", "(e) der Root-Eintrag lehnt ohne gebundene Luftunterstuetzung ab: " + str(no_source))
	controller.call("_clear_drop_sequence_context")

	# d) Flugabwehr im Anflug bei gewaehltem Kreisen: Abbruch -> kein Sortie-Eintrag, Schiff nicht da.
	controller.call("_select_mission_dropship_craft", "craft_a", false)
	controller.call("_set_selected_fireteams", PackedStringArray([team]), false)
	controller.call("_select_arrival_mode", "circle")
	controller.set("_lz_position", env.hot_lz)
	controller.set("_has_lz_position", true)
	var started: bool = bool(controller.call("_try_start_drop_sequence", true))
	var text: String = String(controller.get("_last_command_text"))
	_check(not started and text.begins_with("Flugabwehr: Anflug abgebrochen"), "(d) Abbruch-Ausgang bei gewaehltem Kreisen: Anflug abgebrochen: " + text)
	_check(Dictionary(simulation_root.get("_air_support_sorties")).is_empty() and String(controller.get("_drop_sequence_phase")) != "inbound", "(d) kein Sortie-Eintrag, das Schiff ist nicht da")
	_check(String(_find_card(controller, "craft_a").get("state", "")) == "waiting", "(d) das Schiff bleibt fuer einen neuen Anruf verfuegbar")
	mission.queue_free()
	await process_frame


# ---------------------------------------------------------------- Teil 2b
# (d) durchgaengig: Flugabwehr trifft im Anflug (aggressiv, Rumpfverlust gebucht), das Schiff kreist danach in der Luft.
func _part_flak_arrival() -> void:
	print("--- Teil 2b (Flugabwehr trifft, Schiff kreist danach)")
	var flow := FixFlow.new(); root.add_child(flow)
	var env: Dictionary = await _open_gm02(flow)
	if not _check(bool(env.ok), "(d) GM02-Mission fuer den durchgaengigen Fall geoeffnet"):
		return
	var mission: Node = env.mission
	var controller: Node = env.controller
	var team := String(env.teams[0])
	var mission_root: Node = mission.get_node("SimulationRoot")
	var pilot_id := String(env.first_ids[0])
	flow._craft_location_runtime = {"craft_a": "moon_site"}
	flow._assigned_aircraft_pilot_by_craft = {"craft_a": pilot_id}
	flow._active_mission = mission
	var adapter = ADAPTER.new(); flow.add_child(adapter); adapter._flow = flow
	var source = ROOT_SCRIPT.new(); adapter.add_child(source); adapter._simulation = source
	var fleet = FLEET.new(); fleet.configure(); fleet.register_craft("craft_a")
	var equipment = EQUIPMENT.new(); equipment.configure([{"craft_id": "craft_a", "model_id": "cutlass"}])
	source.configure_singleplayer_owners(null, null, null, fleet); source.configure_ship_equipment(equipment)
	source.configure_departure_adapter(adapter)
	source.get("_space_wing_state").ensure_flying_wings("singleplayer", ["craft_a"], ["craft_a"], {"craft_a": pilot_id})
	source.tick_counter = 50
	mission.set_meta("location_id", "moon_site")
	mission.set_meta("campaign_ground_pilot_id", pilot_id)
	mission.set_meta("singleplayer_visit_identities", {"craft_a": {"craft_id": "craft_a", "unit_ids": env.first_ids, "location_id": "moon_site"}})
	var bind_result: Dictionary = adapter.bind_mission_air_support(mission)
	_check(bool(bind_result.get("ok", false)), "(d) Luftunterstuetzung ist an die GM02-Mission gebunden: " + str(bind_result))
	var raw_cards: Array = controller.get("_mission_drop_cards")
	for raw_card in raw_cards:
		if raw_card is Dictionary and String(raw_card.get("craft_id", "")) == "craft_a":
			raw_card["pilot_unit_id"] = pilot_id
	controller.set("_mission_drop_pilot_unit_id", pilot_id)
	# aggressiv, Kreisen gewaehlt, Landeplatz mit zwei Treffern (siehe air_defense_approach_landing_verifier)
	controller.call("_select_mission_dropship_craft", "craft_a", false)
	controller.call("_set_selected_fireteams", PackedStringArray([team]), false)
	controller.call("_select_approach_style", "aggressiv")
	controller.call("_select_arrival_mode", "circle")
	_check(String(controller.call("_effective_arrival_mode")) == "circle", "(d) die Ankunft ist hier wirksam Kreisen")
	# (f) die Zeile "Ankunft" erscheint genau dort, wo Kreisen wirken kann
	controller.call("_update_ui")
	var details := mission.get_node_or_null("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Header/DetailsButton") as Button
	if details != null:
		details.pressed.emit()
	for _frame in range(4):
		await process_frame
	_check(bool(controller.call("_can_arrive_circling")) and _find_button_by_meta(mission, "mission_dropship_arrival_mode", "circle", "craft_a") != null, "(f) mit gebundener Luftunterstuetzung zeigt die Karte die Zeile Ankunft")
	controller.set("preview_mode", true)
	controller.call("_update_ui")
	await process_frame
	_check(not bool(controller.call("_can_arrive_circling")) and String(controller.call("_effective_arrival_mode")) == "land", "(f) wo Kreisen nicht wirken kann (Vorschau), gilt dieselbe Bedingung: keine Zeile, effektiv Landen")
	controller.set("preview_mode", false)
	# Suche eine freie Zelle in Reichweite der Flugabwehr, in der der Anflug mit Rumpfverlust gelingt (nicht abbricht).
	var registry: Node = controller.call("_get_terrain_registry")
	var started := false
	var text := ""
	var booked: Dictionary = {}
	for cell_y in range(84, 90):
		for cell_x in range(79, 86):
			mission_root.call("_repair_air_asset_status_at_service", "craft_a", {})
			controller.call("_clear_drop_sequence_context")
			controller.set("_lz_position", registry.call("grid_to_world", Vector2i(cell_x, cell_y)))
			controller.set("_has_lz_position", true)
			started = bool(controller.call("_try_start_drop_sequence", true))
			text = String(controller.get("_last_command_text"))
			for _frame in range(4):
				await physics_frame
			booked = mission_root.call("get_air_asset_status_snapshot", "craft_a")
			if started and int(booked.get("integrity", 100)) < 100:
				break
			started = false
		if started:
			break
	_check(started and text.begins_with("Flugabwehr: ") and text.contains(" Treffer, Rumpf "), "(d) die Flugabwehr trifft, der Anflug geht weiter: " + text)
	_check(String(controller.get("_drop_sequence_phase")) == "inbound" and String(controller.get("_drop_sequence_arrival_mode")) == "circle", "(d) die Folge fliegt an und behaelt Kreisen")
	_check(str(int(booked.get("integrity", -1))) + " %" == text.get_slice("Rumpf ", 1) and int(booked.get("integrity", 100)) < 100, "(d) der Rumpfverlust ist gebucht: " + str(booked.get("integrity")) + " / " + str(booked.get("state")))
	var guard := 0
	while String(controller.get("_drop_sequence_phase")) == "inbound" and guard < 6000:
		controller.call("_update_drop_sequence", 0.1)
		guard += 1
	var sorties: Dictionary = mission_root.get("_air_support_sorties")
	_check(String(controller.get("_drop_sequence_phase")) == "complete" and mission_root.call("is_air_support_craft_airborne", "craft_a"), "(d) nach den Treffern ist das Schiff in der Luft (kein Landen, Phase complete): " + String(controller.get("_last_command_text")))
	_check(sorties.has("craft_a"), "(d) der Sortie-Eintrag ist da")
	var after: Dictionary = mission_root.call("get_air_asset_status_snapshot", "craft_a")
	_check(int(after.get("integrity", -1)) == int(booked.get("integrity", -2)), "(d) der gebuchte Rumpfwert ist nach der Ankunft unveraendert: " + str(after.get("integrity")))
	var embarked: Dictionary = controller.get("_embarked_unit_ids")
	var all_aboard := true
	for id in env.first_ids: all_aboard = all_aboard and embarked.has(id) and not Dictionary(controller.get("_deployed_unit_ids")).has(id)
	_check(all_aboard, "(d) der Trupp ist an Bord, niemand abgesetzt")
	flow.queue_free()
	await process_frame


# ---------------------------------------------------------------- Teil 3
func _part_real() -> void:
	print("--- Teil 3 (echte Kampagne, Landefaehre mit Trupp)")
	_configure_entry()
	_flow = FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not await _prepare_initial_base(): return
	var craft: Dictionary = _screen.call("get_operations_snapshot").get("selected_craft", {})
	_craft_id = String(craft.get("id", "")); _pilot_id = String(craft.get("pilot_id", ""))
	var payload: Array = craft.get("payload_fireteam_ids", [])
	if not _check(not _craft_id.is_empty() and not payload.is_empty(), "(b) echtes Schiff und Trupp sind da"): return
	_team_id = String(payload[0])
	for team: Dictionary in Array(_screen.call("get_operations_snapshot").get("fireteams", [])):
		if String(team.get("id", "")) == _team_id:
			for member: Dictionary in Array(team.get("members", [])): _crew_ids.append(String(member.id))
	if not _check(_screen.call("request_operation", "accept_job", {"job_id":"satellite_recovery", "request_id":"arrival:accept"}).get("ok", false), "(b) Auftrag angenommen"): return
	if not _check(_screen.call("request_operation", "select_destination", {"location_id":"satellite_crash", "job_id":"satellite_recovery", "request_id":"arrival:destination"}).get("ok", false), "(b) Ziel gewaehlt"): return
	_circle_hooks = true
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): return
	_circle_hooks = false
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var root_owner: Node = mission.get_node("SimulationRoot")
	_check(not _saw_landed, "(b) das Schiff hat nie die Phase landed/unloading durchlaufen")
	var sorties: Dictionary = root_owner.get("_air_support_sorties")
	_check(root_owner.call("is_air_support_craft_airborne", _craft_id) and sorties.has(_craft_id), "(b) das Schiff ist in der Luft und hat einen Sortie-Eintrag")
	var embarked: Dictionary = controller.get("_embarked_unit_ids")
	var deployed: Dictionary = controller.get("_deployed_unit_ids")
	var all_aboard := not _crew_ids.is_empty()
	for id in _crew_ids:
		all_aboard = all_aboard and embarked.has(id) and not deployed.has(id)
	_check(all_aboard, "(b) der Trupp ist eingeschifft und nicht auf dem Boden")
	var leader: Node = controller.call("_get_campaign_sortie_unit", "campaign_leader")
	_check(is_instance_valid(leader) and bool(leader.get_meta("dropship_embarked", false)), "(b) der Anfuehrer ist an Bord (Meta dropship_embarked)")
	_check(String(Dictionary(controller.call("_find_mission_dropship_card_entry", _craft_id)).get("state", "")) == "complete" and String(controller.get("_drop_sequence_phase")) == "complete", "(b) die Folge steht auf complete, ohne dass der Trupp ausgestiegen ist")
	_check(String(controller.call("get_campaign_air_support_pilot_guard", _craft_id).get("reason", "ok")) == "ok", "(E8) Pilot-Guard mit eingeschifftem Trupp bleibt gruen")
	var circling_card: Dictionary = controller.call("_find_mission_dropship_card_entry", _craft_id)
	_check(String(circling_card.get("arrival_mode", "")) == "circle", "(b) die Schiffskarte fuehrt arrival_mode circle")

	# f) Speichern im Kreisen.
	var projection: Dictionary = _flow.get("_campaign_start").call("get_save_projection", _flow, _runtime)
	print("SAVE_PROJECTION_CIRCLING reason=", projection.get("save_blocked_reason", ""), " text=", projection.get("save_blocked_text", ""))
	_check(not bool(projection.get("can_save", true)) and not String(projection.get("save_blocked_text", "")).is_empty(), "(f) Speichern waehrend des Kreisens ist gesperrt")
	var capture: Dictionary = load("res://scripts/mission/campaign_active_mission_capture.gd").capture_components(_flow, _runtime)
	print("CAPTURE_CIRCLING reason=", capture.get("reason", ""))
	_check(not bool(capture.get("ok", true)), "(f) der Einsatz-Speicherpunkt wird waehrend des Kreisens abgelehnt (Grund: " + String(capture.get("reason", "")) + ")")
	# E10 finding: with the troop still aboard the earlier gate mission_crew_not_deployed answers first; transport_not_grounded
	# is only reached with a deployed crew.
	# The sentence must come from the player-facing source (campaign_save_projection.gd, BASE_TEXTS) for the reason the projection reports.
	var shown_text: String = String(projection.get("save_blocked_text", ""))
	var source_text: String = String(load("res://scripts/meta/campaign_save_projection.gd").call("blocked_text", String(projection.get("save_blocked_reason", ""))))
	_check(String(capture.get("reason", "")) in ["mission_crew_not_deployed", "transport_not_grounded"] and shown_text == source_text and shown_text != GENERIC_SAVE_TEXT, "(f) Speichern gesperrt (Grund " + String(capture.get("reason", "")) + "); der Spieler liest: " + shown_text)
	_check(shown_text == "Die Besatzung ist noch nicht ausgestiegen. Nach dem Aussteigen erneut speichern.", "(f) der Spieler liest den Satz zu mission_crew_not_deployed: " + shown_text)

	# h) Auftragsende / Heimflug, solange das Schiff kreist.
	var circling_extract: Dictionary = controller.call("request_campaign_extraction", _craft_id)
	var circling_return: bool = bool(controller.call("_can_request_mission_dropship_return", circling_card))
	_check(not bool(circling_extract.get("ok", true)) and String(circling_extract.get("reason", "")) == "craft_not_landed" and String(circling_extract.get("message", "")) == "Schiff muss zum Einsteigen gelandet sein", "(h) Einsteigen/Heimflug waehrend des Kreisens: Spieler liest: " + String(circling_extract.get("message", "")))
	_check(not circling_return, "(h) die Rueckkehr-Taste der Karte ist waehrend des Kreisens nicht freigegeben")

	# Spaeter landen ueber den vorhandenen Knopf.
	controller.call("_refresh_mission_dropship_panel")
	var details: Button = mission.get_node_or_null("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Header/DetailsButton")
	if details != null: details.pressed.emit()
	await process_frame
	var land_button: Button = _air_button(mission, "air_land")
	if not _check(land_button != null and land_button.is_visible_in_tree() and not land_button.disabled, "(E7) der vorhandene Knopf Landen ist nach der Kreis-Ankunft erreichbar"): return
	land_button.pressed.emit()
	# Luftrollen 1b: die Ankunft im Kreisen ist eine echte Rundbahn; "Landen" fliegt erst zur Landezone (landing_pending) und landet dort. Obergrenze 60 s.
	await _wait(func(): return not root_owner.call("is_air_support_craft_airborne", _craft_id), 60000, "(E7) das Schiff fliegt aus der Rundbahn zur Landezone und landet")
	_check(not root_owner.call("is_air_support_craft_airborne", _craft_id) and controller.call("_is_parked_campaign_dropship", _craft_id) and not Dictionary(root_owner.get("_air_support_sorties")).has(_craft_id), "(E7) nach dem Landen ist das Schiff geparkt, Sortie beendet")
	embarked = controller.get("_embarked_unit_ids")
	var still_aboard := true
	for id in _crew_ids: still_aboard = still_aboard and embarked.has(id)
	_check(still_aboard, "(E7) geparkt, Trupp noch an Bord")

	# Trupp absetzen ueber den vorhandenen Weg.
	# Seit 28.11. (Paket I) ist die Vorgabe "Pilot bleibt an Bord"; dieser Ablauf prueft den Weg "ganzer Trupp samt Pilot steigt aus" und stellt ihn ueber den Schalter ein.
	if not bool(controller.call("_is_pilot_disembark_selected", _craft_id)): controller.call("request_campaign_pilot_disembark_toggle", _craft_id)
	var deploy: Dictionary = controller.call("request_campaign_crew_deployment", _craft_id)
	_check(bool(deploy.get("ok", false)), "(b) der Trupp steigt ueber request_campaign_crew_deployment aus: " + str(deploy))
	if not await _wait(func(): return _all_crew_deployed(controller) and int(root_owner.call("get_tick")) > 0, 30000, "(b) der abgesetzte Trupp steht auf dem Boden und ist spielbar"): return
	_saw_landed = false
	# (ii) gelandet nach dem Kreisen, ganzer Trupp samt Pilot abgesetzt: der Einsatzstand laesst sich speichern, arrival_mode bleibt erhalten
	var save_holder := {"value": {}}
	await _wait(func():
		save_holder.value = load("res://scripts/mission/campaign_active_mission_capture.gd").capture_components(_flow, _runtime)
		return bool(Dictionary(save_holder.value).get("ok", false)), 20000, "(ii) der Einsatzstand ist nach dem Absetzen speicherbar (keine ausstehende Arbeit mehr)")
	var landed_save: Dictionary = save_holder.value
	_check(bool(landed_save.get("ok", false)), "(ii) Kreisen, dann gelandet und Trupp abgesetzt: Einsatz speichern geht (Grund: " + String(landed_save.get("reason", "")) + ")")
	_check(String(controller.get("_drop_sequence_arrival_mode")) == "circle", "(ii) die Folge fuehrt arrival_mode circle weiter")

	# h) Vergleich mit einem von Hand gestarteten Schiff. Der Trupp ist beim Speichern vom Schiff weggelaufen: erst zurueck zum Schiff.
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	controller.call("_create_waypoints_for_selected_fireteams", controller.call("_campaign_landed_craft_position", _craft_id), true)
	_check(bool(controller.call("execute_selected_fireteam_orders")), "(h) der Trupp laeuft zum Schiff zurueck")
	if details != null: details.pressed.emit()
	await process_frame
	var pilot_button: Button = _air_button(mission, "air_pilot_board")
	if not _check(pilot_button != null and not pilot_button.disabled, "(h) Knopf Pilot einsteigen vorhanden"): return
	# Luftrollen F(b): ohne Pilot an Bord liest der Spieler den Grund in Klartext (Hinweis am Knopf und Rueckmeldung), nicht einen Code.
	var gate_start: Button = _air_button(mission, "air_start")
	var gate_circle: Button = _air_button(mission, "air_circle")
	if _check(gate_start != null and gate_circle != null, "(F) Knoepfe Start und Kreisen vorhanden"):
		gate_start.mouse_entered.emit()
		gate_circle.mouse_entered.emit()
		_check(gate_start.tooltip_text.contains("Gerade nicht möglich: ") and gate_start.tooltip_text.contains("Pilot") and not gate_start.tooltip_text.contains("pilot_"), "(F) Hinweis am Knopf Start nennt den Pilotengrund: " + gate_start.tooltip_text)
		_check(gate_circle.tooltip_text.contains("Gerade nicht möglich: ") and not gate_circle.tooltip_text.contains("pilot_"), "(F) Hinweis am Knopf Kreisen ohne Rohcode: " + gate_circle.tooltip_text)
		gate_start.pressed.emit()
		var refusal_line: String = String(controller.get("_last_command_text"))
		_check(refusal_line.contains("Pilot") and not refusal_line.contains("_") and not root_owner.call("is_air_support_craft_airborne", _craft_id), "(F) Start ohne Pilot: Rueckmeldung in Klartext, Schiff bleibt am Boden: " + refusal_line)
		gate_circle.pressed.emit()
		_check(not root_owner.call("is_air_support_craft_airborne", _craft_id), "(F) Kreisen ohne Pilot startet nichts")
	var board_deadline := Time.get_ticks_msec() + 90000
	while Time.get_ticks_msec() < board_deadline and not bool(controller.call("get_campaign_air_support_pilot_guard", _craft_id).get("ok", false)):
		pilot_button.pressed.emit()
		for _frame in range(60):
			await process_frame
	if not _check(bool(controller.call("get_campaign_air_support_pilot_guard", _craft_id).get("ok", false)), "(h) der Pilot ist wieder an Bord"):
		return
	var start_button: Button = _air_button(mission, "air_start")
	if not _check(start_button != null and not start_button.disabled, "(h) Knopf Start vorhanden"): return
	start_button.pressed.emit()
	if not _check(root_owner.call("is_air_support_craft_airborne", _craft_id), "(h) das Schiff ist von Hand gestartet"): return
	var hand_extract: Dictionary = controller.call("request_campaign_extraction", _craft_id)
	var hand_return: bool = bool(controller.call("_can_request_mission_dropship_return", controller.call("_find_mission_dropship_card_entry", _craft_id)))
	_check(hand_extract.get("ok", true) == circling_extract.get("ok", false) and hand_extract.get("reason", "") == circling_extract.get("reason", "?") and hand_extract.get("message", "") == circling_extract.get("message", "?") and hand_return == circling_return, "(h) das von Hand gestartete Schiff verhaelt sich bei Einsteigen/Rueckkehr genau wie das kreisend angekommene")
	var hand_save: Dictionary = load("res://scripts/mission/campaign_active_mission_capture.gd").capture_components(_flow, _runtime)
	# The gate reason differs (crew aboard vs. crew deployed, E10 finding); what matters: saving is blocked in both states.
	_check(not bool(hand_save.get("ok", true)) and not bool(capture.get("ok", true)), "(h) Speichern im Handstart ebenfalls gesperrt (Grund: " + String(hand_save.get("reason", "")) + ", beim Kreisen: " + String(capture.get("reason", "")) + ")")
	land_button = _air_button(mission, "air_land")
	if not _check(land_button != null, "(h) Knopf Landen nach dem Handstart"): return
	land_button.pressed.emit()
	_check(controller.call("_is_parked_campaign_dropship", _craft_id), "(h) das von Hand gestartete Schiff ist wieder geparkt")

	# Auftrag normal beenden und heimfliegen (Einsteigen am Ende der Mission, danach Orbit).
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	# (b) Laufbefehl: eine abgesetzte Einheit bekommt den Befehl und erreicht ein anderes Feld.
	var walker: Node2D = root_owner.call("_resolve_known_unit", String(_crew_ids[0])) as Node2D
	if not _check(walker != null, "(b) die abgesetzte Einheit ist als Bodenakteur da"): return
	var walk_start: Vector2 = walker.global_position
	var walk_target: Vector2 = MAP.load_from_file("res://maps/satellite_crash_site.json").get_marker_position("satellite_data")
	controller.call("_create_waypoints_for_selected_fireteams", walk_target, true)
	_check(bool(controller.call("execute_selected_fireteam_orders")), "(b) der Laufbefehl wird angenommen")
	_check(await _wait(func(): return is_instance_valid(walker) and walker.global_position.distance_to(walk_start) > 12.0, 60000, "(b) die Einheit hat den Laufbefehl ausgefuehrt und steht auf einem anderen Feld"), "(b) Laufbefehl ausgefuehrt")
	if not await _move_and_use(mission, "satellite_data", "secure_satellite", "res://maps/satellite_crash_site.json"): return
	if not await _move_and_use(mission, "ship_return", "return_to_ship", "res://maps/satellite_crash_site.json"): return
	if not await _wait(func(): return String(Dictionary(_campaign().get("jobs", {})).get("satellite_recovery", {}).get("status", "")) == "pending_upload", 20000, "(b) der Auftrag ist mit dem Chip abgeschlossen (Rueckkehr zum Schiff wie gewohnt)"): return
	var destination := String(_campaign().get("selected_location_id", ""))
	var destination_orbit := String(Dictionary(_space().get("location_orbits", {})).get(destination, ""))
	await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == destination_orbit, 60000, "(b) der Heimflug beginnt: das Schiff verlaesst den Einsatzort in die Umlaufbahn")


# ---------------------------------------------------------------- Haken in den echten Ablauf
func _wait(predicate: Callable, milliseconds: int, label: String) -> bool:
	if _circle_hooks and label.ends_with("actual outbound transit reaches waiting craft"):
		var ready: bool = await super._wait(predicate, milliseconds, label)
		if ready:
			await _choose_circling_on_card()
		return ready
	if _circle_hooks and label.ends_with("real landing unloads all original crew into authoritative simulation"):
		return await _wait_circling_arrival(label)
	return await super._wait(predicate, milliseconds, label)


func _choose_circling_on_card() -> void:
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	controller.call("_refresh_mission_dropship_panel")
	var details: Button = mission.get_node_or_null("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Header/DetailsButton")
	if details != null: details.pressed.emit()
	await process_frame
	var land_row: Button = _find_button_by_meta(mission, "mission_dropship_arrival_mode", "land", _craft_id)
	var circle_row: Button = _find_button_by_meta(mission, "mission_dropship_arrival_mode", "circle", _craft_id)
	_check(land_row != null and circle_row != null and land_row.text == "Landen" and circle_row.text == "Kreisen", "(E1) die Schiffskarte zeigt die Zeile Ankunft: Landen / Kreisen")
	_check(land_row != null and bool(land_row.get_meta("mission_dropship_card_command_active", false)) and circle_row != null and not bool(circle_row.get_meta("mission_dropship_card_command_active", true)), "(E1) Vorgabe: Landen ist gewaehlt")
	_check(circle_row != null and circle_row.tooltip_text == CIRCLE_HINT, "(E1) Hinweistext Kreisen woertlich: " + (circle_row.tooltip_text if circle_row != null else "-"))
	_check(String(controller.call("get_planning_state").get("arrival_mode", "")) == "land" and Dictionary(mission.get_node("SimulationRoot").get("_air_support_sorties")).is_empty(), "(c) Vorgabe Landen: kein Sortie-Eintrag vor dem Anflug")
	if circle_row != null:
		circle_row.pressed.emit()
	await process_frame
	_check(String(controller.call("get_planning_state").get("arrival_mode", "")) == "circle", "(b) Druck auf Kreisen stellt das Schiff auf Kreisen")
	var active_circle: Button = _find_button_by_meta(mission, "mission_dropship_arrival_mode", "circle", _craft_id)
	_check(active_circle != null and bool(active_circle.get_meta("mission_dropship_card_command_active", false)), "(E1) Kreisen ist danach als gewaehlt markiert")


func _wait_circling_arrival(label: String) -> bool:
	var deadline: int = Time.get_ticks_msec() + 90000
	var last_trace := ""
	var frames := 0
	while Time.get_ticks_msec() < deadline:
		var mission: Node = _flow.get("_active_mission")
		if is_instance_valid(mission):
			var controller: Node = mission.get_node("TacticalController")
			var phase := String(controller.get("_drop_sequence_phase"))
			var trace := "%s|%s|%s|%s" % [phase, controller.get("_drop_sequence_arrival_mode"), controller.get("_drop_sequence_circle_note"), controller.get("_drop_sequence_circle_reason")]
			frames += 1
			if trace != last_trace or (phase == "inbound" and frames % 120 == 0):
				last_trace = trace
				print("ARRIVAL_TRACE ", trace, " last=", controller.get("_last_command_text"), " guard=", controller.call("get_campaign_air_support_pilot_guard", _craft_id), " timer=", controller.get("_drop_sequence_timer"))
			if phase == "landed" or phase == "unloading":
				_saw_landed = true
			if phase == "complete" and bool(mission.get_node("SimulationRoot").call("is_air_support_craft_airborne", _craft_id)):
				return _check(true, "(b) das Schiff kommt in der Luft an (Folge complete, im Flug): " + label)
		await physics_frame
	var late_mission: Node = _flow.get("_active_mission")
	if is_instance_valid(late_mission):
		var late_controller: Node = late_mission.get_node("TacticalController")
		print("ARRIVAL_TIMEOUT_STATE phase=", late_controller.get("_drop_sequence_phase"), " mode=", late_controller.get("_drop_sequence_arrival_mode"), " current=", late_controller.get("_current_arrival_mode"), " effective=", late_controller.call("_effective_arrival_mode"), " offered=", late_controller.call("_is_air_support_offered"), " text=", late_controller.get("_last_command_text"), " pos=", late_controller.get("_drop_sequence_position"), " lz=", late_controller.get("_drop_sequence_lz_position"), " timer=", late_controller.get("_drop_sequence_timer"))
	return _check(false, "TIMEOUT (b) Ankunft in der Luft: " + label)


# ---------------------------------------------------------------- Hilfen
func _find_button_by_meta(node: Node, key: String, value: String, craft_id: String) -> Button:
	for candidate in node.find_children("*", "Button", true, false):
		if String(candidate.get_meta(key, "")) == value and String(candidate.get_meta("mission_dropship_craft_id", "")) == craft_id:
			return candidate
	return null


func _card(id: String, team: String, units: Array, lz: Vector2) -> Dictionary:
	return {"craft_id": id, "model_id": "cutlass", "display_name": id, "payload_source": "homebase_direct", "state": "waiting", "progress": 0.0, "passenger_count": units.size(), "embarked_unit_ids": units, "boarded_fireteam_ids": [team], "has_lz_position": true, "lz_position": lz, "approach_angle": "NW"}


func _find_card(controller: Node, id: String) -> Dictionary:
	for card in Array(Dictionary(controller.call("get_planning_state")).get("mission_drop_cards", [])):
		if String(card.get("craft_id", "")) == id:
			return card
	return {}


func _unit_ids(units: Array) -> Array:
	var ids: Array = []
	for unit in units:
		ids.append(String(unit.call("get_unit_id")))
	return ids
