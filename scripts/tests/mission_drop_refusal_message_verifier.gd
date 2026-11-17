extends "res://scripts/tests/playtest_20261110_extraction_loop.gd"
## Meldung beim "Absetzen": Lehnt die Landung den Landeplatz ab, liest der Spieler den Grund der Landepruefung
## und nicht "NO DROP TEAM AVAILABLE". Der Text "NO DROP TEAM AVAILABLE" bleibt fuer den Fall ohne absetzbaren Trupp.
## Fall 1 setzt auf dem echten Zweiflug-Ablauf der Kampagne auf (Elterntest playtest_20261110_extraction_loop): Am
## Handelsaussenposten nimmt das Setzen per Kartenklick den Landeplatz an, die Landung lehnt ihn mit footprint_blocked ab.
## Fall 2 nutzt die Mission-Szene wie air_defense_approach_landing_verifier ohne absetzbaren Trupp.
const MISSION_SCENE = preload("res://scenes/tests/mission_reactivity_test.tscn")
const NO_TEAM_TEXT := "NO DROP TEAM AVAILABLE"
var _case_one_reached := false
var _aux_mission: Node

func _wait(predicate: Callable, milliseconds: int, label: String) -> bool:
	if label == "trade_outpost_visit real landing unloads all original crew into authoritative simulation":
		_case_one_reached = true
		await _check_refused_landing()
		await _check_no_team_available()
		return false
	return await super._wait(predicate, milliseconds, label)

func _check_refused_landing() -> void:
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var accepted: Dictionary = controller.call("_resolve_campaign_field_lz")
	_check(bool(accepted.get("ok", false)), "Fall 1: das Setzen hat den Landeplatz angenommen (_resolve_campaign_field_lz ok), lz=" + str(controller.get("_lz_position")))
	var landing: Dictionary = controller.call("_prepare_ground_ship_landing", _craft_id, accepted)
	var reason_text: String = String(landing.get("message", "Landeplatz ist noch nicht bereit"))
	if not _check(not bool(landing.get("ok", true)), "Fall 1: die Landepruefung lehnt denselben Landeplatz ab: " + str(landing.get("reason", "")) + " / " + reason_text):
		return
	# Derselbe Weg wie der Knopf "Absetzen" auf der Schiffskarte.
	controller.call("_on_mission_dropship_card_drop_pressed", _craft_id)
	var card: Dictionary = controller.call("_find_mission_dropship_card_entry", _craft_id)
	var card_text: String = String(card.get("card_feedback_text", ""))
	var command_text: String = String(controller.get("_last_command_text"))
	print("FALL1 card_text=", card_text, " command_text=", command_text)
	_check(card_text.contains(reason_text), "Fall 1: die Schiffskarte nennt den Grund der Landepruefung: " + card_text)
	_check(card_text != NO_TEAM_TEXT and command_text != NO_TEAM_TEXT, "Fall 1: weder Karte noch Befehlszeile zeigen " + NO_TEAM_TEXT)
	_check(command_text.contains(reason_text), "Fall 1: die Befehlszeile nennt denselben Grund: " + command_text)
	_check(Dictionary(controller.get("_deployed_unit_ids")).is_empty() and String(card.get("state", "")) == "waiting", "Fall 1: der Trupp ist noch an Bord, die Karte wartet")
	await _check_retry_with_accepted_landing(mission, controller, reason_text)

## Fix-Runde 1: Der Spieler waehlt danach einen besseren Platz. Der alte Ablehnungsgrund darf waehrend des Anflugs nicht
## mehr auf der Karte stehen. Danach landet der Trupp, und der Knopf "Absetzen" des gelandeten Schiffs wird gelesen.
func _check_retry_with_accepted_landing(mission: Node, controller: Node, reason_text: String) -> void:
	var map = MAP.load_from_file("res://maps/trade_outpost.json")
	var view: Node = mission.get_node("Primary3DView")
	var good: Vector2 = map.get_marker_position("spawn_alpha")
	view.call("focus_world_position", good)
	controller.call("_on_mission_dropship_card_set_lz_pressed", _craft_id)
	var placed: bool = bool(controller.call("_place_lz_from_screen_position", view.call("world_to_screen_position", good)))
	var accepted: Dictionary = controller.call("_resolve_campaign_field_lz")
	var landing: Dictionary = controller.call("_prepare_ground_ship_landing", _craft_id, accepted)
	if not _check(placed and bool(landing.get("ok", false)), "Wiederholung: ein neu gesetzter Landeplatz wird von Setzen und Landung angenommen: " + str(landing.get("reason", "ok"))):
		return
	controller.call("_on_mission_dropship_card_drop_pressed", _craft_id)
	var card: Dictionary = controller.call("_find_mission_dropship_card_entry", _craft_id)
	var card_text: String = String(card.get("card_feedback_text", ""))
	print("WIEDERHOLUNG phase=", controller.get("_drop_sequence_phase"), " card_text=", card_text)
	_check(String(controller.get("_drop_sequence_phase")) == "inbound", "Wiederholung: das Schiff fliegt an")
	_check(not card_text.contains(reason_text), "Wiederholung: die Karte zeigt waehrend des Anflugs nicht mehr den alten Ablehnungsgrund: " + card_text)
	if not await super._wait(func(): return _all_crew_deployed(controller) and int(mission.get_node("SimulationRoot").call("get_tick")) > 0, 60000, "Wiederholung: der Trupp landet am neuen Platz"):
		return
	# Gelandetes Schiff, kein absetzbarer Trupp mehr: Knopfweg (fuehrt in der Kampagne nicht durch _request_selected_mission_dropship_drop).
	controller.call("_on_mission_dropship_card_drop_pressed", _craft_id)
	card = controller.call("_find_mission_dropship_card_entry", _craft_id)
	var landed_text: String = String(card.get("card_feedback_text", ""))
	print("FALL3 card_text=", landed_text, " command_text=", controller.get("_last_command_text"))
	# Befund: Auf dem gelandeten Schiff laeuft der Knopf nicht durch _try_start_drop_sequence; das Spiel nennt hier den eigenen Grund.
	_check(landed_text.begins_with("Absetzen braucht ein gelandetes Schiff mit Kräften an Bord") and not landed_text.contains(reason_text), "Fall 3: gelandetes Schiff ohne absetzbaren Trupp, Knopfweg: die Karte nennt den eigenen Grund statt eines alten Texts: " + landed_text)

func _check_no_team_available() -> void:
	# Fall 2: eigene Mission-Szene neben dem Flow (der Elterntest liest den Flow nach dem Abbruch noch).
	var mission: Node = MISSION_SCENE.instantiate()
	_aux_mission = mission
	var setup: Node = mission.get_node("MissionSetup")
	setup.set("map_file_path", "res://maps/Ground_Mission02_128x128.json")
	setup.set("scenario_file_path", "res://data/mission_scenarios/ground_mission02_128x128.json")
	setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo"]))
	setup.set("selected_team_fireteam_ids", PackedStringArray(["ft1", "ft2"]))
	setup.set("defer_friendly_runtime_activation", true)
	root.add_child(mission)
	for _frame in range(3):
		await process_frame
	var controller: Node = mission.get_node("TacticalController")
	controller.set_process(false)
	var lz: Vector2 = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/Ground_Mission02_128x128.json").get_marker_position("spawn_alpha")
	var state: Dictionary = controller.call("get_planning_state")
	var empty_card := {"craft_id": "craft_empty", "model_id": "cutlass", "display_name": "craft_empty", "payload_source": "homebase_direct", "state": "waiting", "progress": 0.0,
		"passenger_count": 0, "embarked_unit_ids": [], "boarded_fireteam_ids": [], "has_lz_position": true, "lz_position": lz, "approach_angle": "NW"}
	state.merge({"mission_drop_source": "homebase_direct", "mission_drop_craft_id": "craft_empty", "mission_drop_state": "waiting", "drop_ship_staged": true,
		"embarked_unit_ids": [], "deployed_unit_ids": [], "has_lz_position": true, "lz_position": lz, "selected_fireteams": [], "mission_drop_cards": [empty_card]}, true)
	controller.call("set_planning_state", state)
	controller.call("_select_mission_dropship_craft", "craft_empty", false)
	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	controller.call("_request_selected_mission_dropship_drop", true)
	var text: String = String(controller.get("_last_command_text"))
	print("FALL2 command_text=", text)
	_check(text == NO_TEAM_TEXT, "Fall 2: ohne absetzbaren Trupp zeigt das Spiel weiter " + NO_TEAM_TEXT + ", gelesen: " + text)

func _finish() -> void:
	if not _case_one_reached:
		_check(false, "Der Ablauf kam bis zum Absetzen am Handelsaussenposten")
	if is_instance_valid(_aux_mission):
		_aux_mission.queue_free()
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("mission_drop_refusal_message_verifier passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
