extends SceneTree
## Gefecht mit Kartenwahl: Vertrag, Menue und ein echter kopfloser Start bis zur geladenen Einsatzszene auf der gewaehlten Karte.
const START = preload("res://scripts/meta/game_start_contract.gd")
const CONFIG = preload("res://scripts/meta/skirmish_start_configuration.gd")
const GROUND_MAPS = preload("res://scripts/mission/productive_ground_maps.gd")
const ROSTER = preload("res://scripts/meta/player_roster_store.gd")
const WITHOUT_ENEMIES: PackedStringArray = ["res://maps/satellite_crash_site.json", "res://maps/trade_outpost.json"]

class MenuProbe:
	extends "res://scripts/ui/main_menu_screen.gd"
	var routed: String = ""
	func _change_scene(path: String) -> void:
		routed = path

var failures := 0
var checks := 0


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)


func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _run() -> void:
	_check_catalog_and_contract()
	await _check_menu()
	var team_path: String = ROSTER.get_save_path()
	var team_existed := FileAccess.file_exists(team_path)
	var before := FileAccess.get_file_as_bytes(team_path) if team_existed else PackedByteArray()
	var maps: Array = CONFIG.playable_maps()
	for entry: Dictionary in maps:
		await _check_flow_start(String(entry.path), "early")
	await _check_flow_start(String(maps[0].path), "")
	await _check_open_start_unchanged()
	check(FileAccess.file_exists(team_path) == team_existed, "Gefechtstart legt das Menue-Team nicht an oder loescht es nicht")
	if team_existed:
		check(FileAccess.get_file_as_bytes(team_path) == before, "Gefechtstart laesst das Menue-Team unveraendert")
	print("Gefecht mit Kartenwahl: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _check_catalog_and_contract() -> void:
	var maps: Array = CONFIG.playable_maps()
	check(maps.size() >= 2, "Mindestens zwei Gefecht-Karten werden angeboten")
	var selectable: PackedStringArray = GROUND_MAPS.selectable_paths()
	for entry: Dictionary in maps:
		var path := String(entry.path)
		check(selectable.has(path), "Gefecht-Karte steht in der Spieler-Auswahlliste: " + path)
		check(not GROUND_MAPS.TEST_ONLY.has(path), "Keine Test-/Uebungskarte: " + path)
		check(FileAccess.file_exists(String(entry.scenario)), "Einsatzdatei vorhanden: " + String(entry.scenario))
		var scenario: Variant = JSON.parse_string(FileAccess.get_file_as_string(String(entry.scenario)))
		# Absturzstelle und Handelsposten sind auf Bjoerns Wunsch (28.11.) ohne Gegner dabei; alle anderen Gefecht-Karten brauchen Gegner.
		if not WITHOUT_ENEMIES.has(path):
			check(scenario is Dictionary and not Array(Dictionary(scenario).get("enemy_groups", [])).is_empty(), "Gefecht hat Gegner: " + path)
		check(CONFIG.is_playable_map(path), "is_playable_map erkennt " + path)
		check(START.request_start(self, "skirmish", "new", "early", {}, path).ok, "Vertrag nimmt Karte an: " + path)
		var consumed: Dictionary = START.consume_start(self)
		check(consumed == {"mode": "skirmish", "action": "new", "preset_id": "early", "map_path": path}, "Karte ueberlebt den Vertrag einmal: " + path)
	for wanted in WITHOUT_ENEMIES:
		check(CONFIG.is_playable_map(wanted), "Auf Wunsch angeboten: " + wanted)
	for bad in ["res://maps/test_mission.json", "res://maps/wall_test_4x4.json", "res://maps/station_outpost_64x64.json", "res://maps/fireteam_command_drill_24x24.json", "res://maps/polisa_station.json", "res://maps/gibt_es_nicht.json"]:
		check(not CONFIG.is_playable_map(bad), "Nicht angeboten: " + bad)
		check(not START.request_start(self, "skirmish", "new", "", {}, bad).ok, "Vertrag lehnt ab: " + bad)
		check(START.consume_start(self).get("mode") == "skirmish" and not START.consume_start(self).has("map_path"), "Abgelehnte Karte hinterlaesst nichts: " + bad)
	check(not START.request_start(self, "campaign", "new", "", {}, String(maps[0].path)).ok, "Kampagne nimmt keine Gefecht-Karte")
	root.set_meta(START.META_KEY, {"mode": "skirmish", "action": "new", "map_path": "res://maps/test_mission.json"})
	check(START.consume_start(self) == {"mode": "skirmish", "action": "new"}, "Verfaelschte Karte im Vertrag faellt auf Standard zurueck")
	root.set_meta(START.META_KEY, {"mode": "skirmish", "action": "new", "map_path": 5})
	check(not START.consume_start(self).has("map_path"), "Falsche Art der Karte faellt auf Standard zurueck")


func _check_menu() -> void:
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	menu.set_script(MenuProbe)
	menu.set("_start_roster_profile_id", "skirmish_map_menu_test")
	menu.set("_start_roster_save_path", "user://profiles/skirmish_map_menu_test/roster_v1.json")
	root.add_child(menu)
	await process_frame
	var maps: Array = CONFIG.playable_maps()
	var buttons: Array = menu.get("_gefecht_map_buttons")
	check(buttons.size() == maps.size(), "Menue zeigt je Gefecht-Karte einen Knopf")
	check(menu.get_gefecht_map_path() == String(maps[0].path), "Vorgabe ist die erste Karte")
	check(String(menu.find_child("GefechtMapLabel", true, false).text) == "Karte:", "Beschriftung Karte")
	menu.call("_on_singleplayer_pressed")
	check(menu.get("_open_section") == "gefecht", "Gefecht-Bereich ist offen")
	var second: Button = buttons[1]
	second.button_pressed = true
	check(menu.get_gefecht_map_path() == String(maps[1].path), "Zweite Karte gewaehlt")
	check(not (buttons[0] as Button).button_pressed, "Genau eine Karte gewaehlt")
	menu.find_child("SkirmishPreset_mid", true, false).pressed.emit()
	check(START.consume_start(self) == {"mode": "skirmish", "action": "new", "preset_id": "mid", "map_path": String(maps[1].path)}, "Vorlage startet auf der gewaehlten Karte")
	await _frames(3)
	check(menu.routed.ends_with("meta_layer_test.tscn"), "Gefecht fuehrt in die Flow-Szene")
	menu.call("_cancel_launch")
	menu.find_child("SkirmishOwnTeam", true, false).pressed.emit()
	check(START.consume_start(self) == {"mode": "skirmish", "action": "new", "map_path": String(maps[1].path)}, "Eigenes Team startet auf der gewaehlten Karte")
	await _frames(3)
	menu.call("_cancel_launch")
	# Freies Spiel -> Allein bleibt der offene Start ohne Karte.
	menu.call("_set_section_open", "frei")
	menu.get("_free_play_solo_button").pressed.emit()
	check(START.consume_start(self) == {"mode": "skirmish", "action": "new"}, "Freies Spiel Allein startet offen ohne Karte")
	await _frames(3)
	menu.call("_cancel_launch")
	menu.queue_free()
	await process_frame


func _start_flow(request_map: String, preset: String) -> Node:
	var result: Dictionary = START.request_start(self, "skirmish", "new", preset, {}, request_map)
	check(bool(result.get("ok", false)), "Start angefragt: %s %s" % [request_map, preset])
	var flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	return flow


func _check_flow_start(map_path: String, preset: String) -> void:
	var label := "%s / %s" % [map_path.get_file(), "eigenes Team" if preset.is_empty() else preset]
	var flow := _start_flow(map_path, preset)
	var waited := 0
	while String(flow.get_meta("skirmish_map_start_status", "")).is_empty() and waited < 600:
		await process_frame
		waited += 1
	check(String(flow.get_meta("skirmish_map_start_status", "")) == "applied", "Gefechtsstart gelungen (%s): %s" % [label, String(flow.get_meta("skirmish_map_start_status", "keiner"))])
	check(flow.get("_current_meta_view") == "mission", "Spieler ist im Einsatz, nicht im offenen Spiel (%s)" % label)
	var mission: Node = flow.get("_active_mission")
	check(mission != null, "Einsatzszene ist geladen (%s)" % label)
	if mission != null:
		var setup: Node = mission.get_node_or_null("MissionSetup")
		check(setup != null and String(setup.get("map_file_path")) == map_path, "Gewaehlte Karte ist in der Einsatzszene (%s)" % label)
		var entry: Dictionary = CONFIG.map_entry(map_path)
		check(setup != null and String(setup.get("scenario_file_path")) == String(entry.scenario), "Einsatz der Karte ist gesetzt (%s)" % label)
		var team: PackedStringArray = setup.get("selected_team_unit_ids") if setup != null else PackedStringArray()
		check(team.size() > 0, "Truppe ist im Einsatz (%s)" % label)
		var known := PackedStringArray()
		for unit: Dictionary in flow.get("_all_team_units"):
			known.append(String(unit.get("unit_id", "")))
		for id in team:
			check(known.has(id), "Einsatzperson gehoert zur gewaehlten Truppe: " + id)
			if not preset.is_empty():
				check(id.begins_with("skirmish_%s_" % preset), "Einsatzperson stammt aus der Vorlage %s: %s" % [preset, id])
	check(flow.get("_selected_mission_id") == "gefecht_karte", "Einsatz-Kennung des Gefechts (%s)" % label)
	flow.queue_free()
	await _frames(2)


func _check_open_start_unchanged() -> void:
	var flow := _start_flow("", "early")
	await _frames(30)
	check(not flow.has_meta("skirmish_map_start_status"), "Ohne Karte kein Direktstart")
	check(flow.get("_active_mission") == null and flow.get("_current_meta_view") != "mission", "Ohne Karte bleibt der Start offen (Basis)")
	check(flow.get("_selected_mission_id") != "gefecht_karte", "Ohne Karte bleibt die Standard-Einsatzwahl")
	flow.queue_free()
	await _frames(2)
