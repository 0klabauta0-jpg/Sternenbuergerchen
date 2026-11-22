extends "res://scripts/tests/campaign_air_support_real_mission_verifier.gd"
## LC6 Fix-Runde 1 (W1, W2): die ECHTE Zielquelle get_air_support_threat_targets() und der ECHTE Feuerstopp
## request_air_support_cease_fire() mit dem echten Kampagnenweg (Schiffskarte, Pilot, Start), ohne Attrappe.
## Nur ueber den isolierten Testlauf (Wegwerfprofil) starten.

const GFA_REAL = preload("res://scripts/combat/ground_fire_vs_air.gd")
const HEX_REAL = preload("res://scripts/terrain/hex_grid.gd")


func _run() -> void:
	_configure_entry()
	_flow = FLOW.instantiate(); root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not await _prepare_initial_base(): await _finish(); return
	var craft: Dictionary = _screen.call("get_operations_snapshot").get("selected_craft", {})
	_craft_id = String(craft.get("id", "")); _pilot_id = String(craft.get("pilot_id", ""))
	var payload: Array = craft.get("payload_fireteam_ids", [])
	if not _check(not _craft_id.is_empty() and not payload.is_empty(), "actual craft and team are available"): await _finish(); return
	_team_id = String(payload[0])
	for team: Dictionary in Array(_screen.call("get_operations_snapshot").get("fireteams", [])):
		if String(team.get("id", "")) == _team_id:
			for member: Dictionary in Array(team.get("members", [])): _crew_ids.append(String(member.id))
	if not _check(_screen.call("request_operation", "accept_job", {"job_id":"satellite_recovery", "request_id":"gfa-real:accept"}).get("ok", false), "regular mission accepted"): await _finish(); return
	if not _check(_screen.call("request_operation", "select_destination", {"location_id":"satellite_crash", "job_id":"satellite_recovery", "request_id":"gfa-real:destination"}).get("ok", false), "regular destination selected"): await _finish(); return
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): await _finish(); return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var root_owner: Node = mission.get_node("SimulationRoot")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var terrain: Node = controller.call("_get_terrain_registry")
	controller.call("_refresh_mission_dropship_panel")
	var details: Button = mission.get_node_or_null("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Header/DetailsButton")
	if not _check(details != null and not details.disabled, "actual dropship details control is available"): await _finish(); return
	details.pressed.emit()
	await process_frame
	# W1 (gelandet): die echte Quelle liefert fuer ein gelandetes Schiff kein Ziel.
	_check(Array(root_owner.call("get_air_support_threat_targets")).is_empty(), "W1 gelandet: die echte Zielquelle liefert kein Ziel")
	var pilot_button: Button = _air_button(mission, "air_pilot_board")
	if not _check(pilot_button != null and not pilot_button.disabled, "actual pilot boarding button available"): await _finish(); return
	pilot_button.pressed.emit()
	if not await _wait(func(): return controller.call("get_campaign_air_support_pilot_guard", _craft_id).get("ok", false), 8000, "actual pilot completes boarding"): await _finish(); return
	_check(Array(root_owner.call("get_air_support_threat_targets")).is_empty(), "W1 gelandet, Pilot an Bord: weiterhin kein Ziel")
	var start_button: Button = _air_button(mission, "air_start")
	if not _check(start_button != null and not start_button.disabled and start_button.is_visible_in_tree(), "real air-start button is visible and enabled"): await _finish(); return
	start_button.pressed.emit()
	if not _check(bool(root_owner.call("is_air_support_craft_airborne", _craft_id)), "actual dropship card starts the fleet flight"): await _finish(); return
	# W1 (in der Luft): Eintrag aus dem echten Start, Zelle aus der echten Flugpose, Pilotenwert des zugeteilten Piloten.
	var targets: Array = root_owner.call("get_air_support_threat_targets")
	_check(targets.size() == 1 and String(Dictionary(targets[0]).get("craft_id", "")) == _craft_id, "W1 in der Luft: genau dieses Schiff ist Ziel (%d)" % targets.size())
	if targets.size() == 1:
		var target: Dictionary = targets[0]
		var pose: Dictionary = root_owner.call("get_air_support_world_pose", _craft_id)
		_check(not pose.is_empty() and Vector2(target.position).is_equal_approx(Vector2(pose.position)), "W1: Position = echte Flugpose")
		_check(Vector2i(target.cell) == Vector2i(terrain.call("world_to_grid", pose.position)), "W1: Zelle = Zelle unter der Flugpose (%s)" % str(target.get("cell")))
		var landed_cell: Vector2i = terrain.call("world_to_grid", controller.call("_campaign_landed_craft_position", _craft_id))
		_check(HEX_REAL.distance(Vector2i(target.cell), landed_cell) <= 1, "W1: kurz nach dem Start liegt die Zelle am Landeplatz")
		var binding: Dictionary = root_owner.call("_resolve_air_support_craft", _craft_id)
		var pilot_check: Dictionary = root_owner.call("_resolve_air_support_pilot", _craft_id)
		var model_id: String = String(binding.equipment.get_snapshot(_craft_id).get("model_id", ""))
		var key := "dropship_piloting" if model_id == "cutlass" else "fighter_piloting"
		var expected: float = float(Dictionary(pilot_check.pilot.call("get_character_profile_bundle")).platform_values[key])
		_check(absf(float(target.pilot_skill) - expected) < 0.000001 and expected >= 0.0 and expected <= 1.0, "W1: Pilotenwert = Wert des zugeteilten Piloten (%s = %f)" % [key, expected])
		_check(target.has("status"), "W1: Eintrag traegt den Rumpfstand")
	# W1 (Anflugfolge / nicht in der Luft): ein Eintrag ohne Flug in der Atmosphaere ist kein Ziel.
	root_owner.get("_air_support_sorties")["approach_probe"] = {}
	targets = root_owner.call("get_air_support_threat_targets")
	_check(targets.size() == 1 and String(Dictionary(targets[0]).get("craft_id", "")) == _craft_id, "W1 Anflugfolge: ein Eintrag ohne Flug in der Atmosphaere ist kein Ziel")
	root_owner.get("_air_support_sorties").erase("approach_probe")
	# W2: ein Angriffsbefehl liegt an (echte Fluegel-Verwaltung); der Baustein beendet ihn ueber den ECHTEN Feuerstopp.
	var binding2: Dictionary = root_owner.call("_resolve_air_support_craft", _craft_id)
	var pilot_team: String = String(Dictionary(root_owner.call("_resolve_air_support_pilot", _craft_id)).pilot.call("get_team_id"))
	# In diesem Auftrag steht beim Start noch kein Gegner (nur die eigenen Leute); der Befehl geht direkt an die echte
	# Fluegel-Verwaltung (die Sichtpruefung des Root-Befehls entfaellt), das Ziel ist eine Kennung.
	var enemy_id := "gfa_probe_target"
	_check(pilot_team == "team_alpha" and Array(driver.call("_get_enemy_combat_units")).is_empty(), "W2: Aufbau - kein Gegner im Auftrag, Befehl geht direkt an die Fluegel-Verwaltung")
	var flight_pose: Dictionary = binding2.flight.get_snapshot()
	var wing_snapshot: Dictionary = binding2.wings.get_snapshot()
	var issued: Dictionary = binding2.wings.apply_command({"contract_category":"space_combat", "operation":"order_issue", "request_id":"gfa-real:order", "expected_revision":wing_snapshot.revision,
		"payload":{"wing_ids":[binding2.wing_id], "verb":"attack_target", "target_id":enemy_id, "fire_rule":"free"}},
		{"authorized":true, "actor_id":"singleplayer", "phase":"tactical", "known_targets":[enemy_id], "coordinate_frame":"local", "space_area_id":flight_pose.space_area_id})
	_check(bool(issued.get("ok", false)), "W2: Angriffsbefehl liegt an (%s)" % str(issued.get("reason", "ok")))
	# Rumpf 40 % (unter der Grenze 50 % des Stils normal): das Schiff ist abgedreht, der Feuerstopp steht aus.
	root_owner.call("enqueue_effect", {"effect_type": "air_asset_status_update", "asset_id": _craft_id, "asset_type": "dropship", "state": "damaged",
		"status_snapshot": {"asset_id": _craft_id, "asset_type": "dropship", "state": "damaged", "integrity": 40, "max_integrity": 100}, "priority": 80})
	for i in range(4): await physics_frame
	var gfa = GFA_REAL.new()
	gfa.set("_cease_pending", {_craft_id: true})
	# Erster Versuch mitten im Takt: die echte Root meldet simulation_busy, der Feuerstopp bleibt ausstehend.
	root_owner.set("is_processing_tick", true)
	var tick_now: int = int(root_owner.get("tick_counter"))
	gfa.call("advance", driver, root_owner, controller, tick_now)
	root_owner.set("is_processing_tick", false)
	var order_after_busy: Dictionary = Dictionary(binding2.wings.get_snapshot().wings.get(binding2.wing_id, {})).get("order", {})
	_check(not order_after_busy.is_empty() and Dictionary(gfa.get("_cease_pending")).has(_craft_id), "W2: bei simulation_busy bleibt der Befehl bestehen und der Feuerstopp ausstehend")
	# Zweiter Versuch: geht durch, der Angriffsbefehl endet wirklich, nichts steht mehr aus.
	gfa.call("advance", driver, root_owner, controller, tick_now + 3)
	var order_after: Dictionary = Dictionary(binding2.wings.get_snapshot().wings.get(binding2.wing_id, {})).get("order", {})
	_check(order_after.is_empty() and Dictionary(gfa.get("_cease_pending")).is_empty(), "W2: der naechste Versuch beendet den Angriffsbefehl wirklich (echter Feuerstopp), nichts steht mehr aus")
	# Stil (echte Schiffskarte): die Sperre rechnet mit dem aktuellen Stil des Schiffs; Zielliste traegt den Stil.
	var hull_60: Dictionary = {"effect_type": "air_asset_status_update", "asset_id": _craft_id, "asset_type": "dropship", "state": "damaged",
		"status_snapshot": {"asset_id": _craft_id, "asset_type": "dropship", "state": "damaged", "integrity": 60, "max_integrity": 100}, "priority": 80}
	root_owner.call("enqueue_effect", hull_60)
	for i in range(4): await physics_frame
	var style_cases := {"vorsichtig": true, "normal": false, "aggressiv": false}
	for style: String in style_cases.keys():
		controller.call("_select_approach_style", style)
		_check(String(root_owner.call("_air_attack_style", _craft_id)) == style, "Stil %s: die Root liest ihn von der Schiffskarte" % style)
		var styled_targets: Array = root_owner.call("get_air_support_threat_targets")
		_check(styled_targets.size() == 1 and String(Dictionary(styled_targets[0]).get("approach_style", "")) == style, "Stil %s: die Zielliste traegt ihn" % style)
		var refusal: Dictionary = root_owner.call("request_air_support_attack_order", {"craft_id": _craft_id, "target_unit_id": enemy_id, "request_id": "gfa-real:style:" + style})
		_check((String(refusal.get("reason", "")) == "hull_too_damaged") == bool(style_cases[style]), "Stil %s bei 60 %% Rumpf: Angriffsbefehl %s (%s)" % [style, "gesperrt" if bool(style_cases[style]) else "nicht gesperrt", str(refusal.get("reason", "ok"))])
	# Schiffsart ueber den echten Weg Schiffskarte -> Zielliste -> Schaden: Landefaehre = 34 %, Jaeger = 50 %, fehlende Art = Landefaehre (34 %).
	var real_card: Dictionary = Dictionary(controller.call("_find_mission_dropship_card_entry", _craft_id))
	var as_dropship: Dictionary = Dictionary(Array(root_owner.call("get_air_support_threat_targets"))[0])
	_check(String(real_card.get("craft_type", "")) == "dropship" and String(as_dropship.get("craft_type", "")) == "dropship" and GFA_REAL.hit_damage_percent("rocket_launcher", String(as_dropship.craft_type)) == 34, "Schiffsart Landefaehre: Karte und Zielliste sagen dropship, Raketentreffer 34 %% (%s)" % str(as_dropship.get("craft_type")))
	var cards: Array = controller.get("_mission_drop_cards")
	var edited := 0
	var kept_types: Array = []
	for card_variant in cards:
		var card: Dictionary = card_variant
		if String(card.get("craft_id", "")) == _craft_id:
			kept_types.append([card, card.get("craft_type", "")])
			card["craft_type"] = "fighter"
			edited += 1
	var as_fighter: Dictionary = Dictionary(Array(root_owner.call("get_air_support_threat_targets"))[0])
	_check(edited == 0 or (String(as_fighter.get("craft_type", "")) == "fighter" and GFA_REAL.hit_damage_percent("rocket_launcher", String(as_fighter.craft_type)) == 50 and GFA_REAL.hit_damage_percent("rail_gun", String(as_fighter.craft_type)) == 37), "Schiffsart Jaeger: Karte -> Zielliste sagt fighter, Raketentreffer 50 %% (%s, %d Karte(n) gesetzt)" % [str(as_fighter.get("craft_type")), edited])
	_check(edited > 0, "Schiffsart Jaeger: die Schiffskarte der Sortie liess sich fuer die Probe setzen")
	for card_variant in cards:
		var card: Dictionary = card_variant
		if String(card.get("craft_id", "")) == _craft_id: card["craft_type"] = ""
	var untyped: Dictionary = Dictionary(Array(root_owner.call("get_air_support_threat_targets"))[0])
	_check(GFA_REAL.hit_damage_percent("rocket_launcher", String(untyped.get("craft_type", ""))) == 34 and GFA_REAL.hit_damage_percent("rail_gun", String(untyped.get("craft_type", ""))) == 25, "fehlende Schiffsart gilt als Landefaehre: Raketentreffer 34 %%, Schiene 25 %% (Art '%s')" % str(untyped.get("craft_type", "")))
	for pair in kept_types:
		Dictionary(pair[0])["craft_type"] = pair[1]
	# W1 (gelandet nach Sortie): die Landung nimmt das Schiff aus der Zielliste.
	var landing: Dictionary = root_owner.call("request_air_support_landing", _craft_id)
	_check(bool(landing.get("ok", false)) and not bool(root_owner.call("is_air_support_craft_airborne", _craft_id)), "W1: Landung gelungen (%s)" % str(landing.get("reason", "ok")))
	_check(Array(root_owner.call("get_air_support_threat_targets")).is_empty(), "W1 gelandet nach der Sortie: die echte Zielquelle liefert kein Ziel")
	await _finish()


func _finish() -> void:
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	print("GROUND_FIRE_VS_AIR_REAL passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
