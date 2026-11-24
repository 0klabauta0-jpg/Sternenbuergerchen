extends "res://scripts/tests/campaign_wreck_crater_sortie_verifier.gd"
## Windbruch als freier Kampfort (24.11.2026): echter Einsatz OHNE Kampagnenauftrag, nach dem Muster von campaign_wreck_crater_sortie_verifier.
## Ablauf: Speicherpunkt nach Kapitel 1 -> Fortsetzen -> Dauerauftrag "Rebellen hetzen" annehmen -> Trupp fliegt ohne Auftrag nach Windbruch
## (fortified_outpost) -> kaempft gegen die volle Besatzung (Gegner werden NICHT abgeschwaecht) -> oeffnet die Kiste -> steigt ein und fliegt heim.
## Zweiter Anflug danach: wieder volle Besatzung, neue Kiste. Geprueft wird:
##   - das freie Lager (windbruch_free_camp) ist geladen, kein Auftrag gewaehlt, keine Auftragsaenderung;
##   - N Gegner werden ausgeschaltet (N = vom Pruefer gezaehlt, Soll: alle 4);
##   - beim Abflug werden genau N x 50 Credits gebucht, einmal (auch nach weiteren Bildern und nach dem Heimflug unveraendert);
##   - genau EIN Kistenfund (eine der vier Moeglichkeiten des Szenarios) liegt danach in Fracht oder Basislager;
##   - kein Fehlschlag (kein Verlustbericht, kein gescheiterter Auftrag);
##   - der zweite Anflug ist wieder voll besetzt (4 kampffaehige Gegner, 0 ausgeschaltet), die Kiste ist neu (Besuchszaehler 2).
## Abschlusszeile: CAMPAIGN_WINDBRUCH_FREE_SORTIE passed=%d failed=%d
const WB_LOC := "fortified_outpost"
const WB_SCENARIO := "windbruch_free_camp"
const WB_MAP := "res://maps/windbruch_outpost.json"
const WB_ORDER := "bounty:rebels"
const WB_PAY := 50
const WB_EXPECTED := 4
const WB_POOL := [{"rifle": 1}, {"armor_medium": 1}, {"rocket_launcher": 1, "ammo_rocket": 2}, {"ammo_rocket": 4}]
const WB_ITEMS := ["rifle", "armor_medium", "rocket_launcher", "ammo_rocket"]
const WB_CHEST_PREFIX := "campaign-cargo:loot:windbruch_free_camp:camp_chest:"
var _wb_drv: Node = null
var _wb_reg: Node = null

func _wb_items() -> Dictionary:
	var result := {}
	for item: String in WB_ITEMS: result[item] = _item_total(item)
	return result

func _wb_diff(before: Dictionary, after: Dictionary) -> Dictionary:
	var result := {}
	for item: String in WB_ITEMS:
		var delta: int = int(after.get(item, 0)) - int(before.get(item, 0))
		if delta != 0: result[item] = delta
	return result

func _wb_leader_fit() -> bool:
	var leader: Node = _wb_reg.get_unit("campaign_leader") if is_instance_valid(_wb_reg) and _wb_reg.has_unit("campaign_leader") else null
	return leader != null and is_instance_valid(leader) and String(leader.call("get_vital_state")) == "fit"

func _wb_out() -> int:
	return int(_wb_drv.call("get_enemies_out_of_action_count")) if is_instance_valid(_wb_drv) else -1

func _wb_nearest_enemy() -> Vector2:
	var leader: Node2D = _wb_reg.get_unit("campaign_leader") as Node2D
	var best := Vector2.INF
	var best_d := INF
	for unit in Array(_wb_drv.call("_get_active_enemy_units")):
		if unit == null or not is_instance_valid(unit) or String(unit.call("get_vital_state")) != "fit": continue
		var d: float = leader.global_position.distance_to((unit as Node2D).global_position)
		if d < best_d:
			best_d = d
			best = (unit as Node2D).global_position
	return best

## Wie ein Spieler: alle 6 s echter Zeit den Trupp auf den naechsten kampffaehigen Gegner schicken, bis alle ausser Gefecht sind oder der Truppfuehrer faellt.
func _wb_fight(controller: Node) -> void:
	var started := Time.get_ticks_msec()
	var next_order := 0
	var orders := 0
	var next_obs := 0
	var limit_ms: int = int(OS.get_environment("SB_WB_FIGHT_MS")) if not OS.get_environment("SB_WB_FIGHT_MS").is_empty() else 420000
	while Time.get_ticks_msec() - started < limit_ms and _wb_out() < WB_EXPECTED and _wb_leader_fit():
		if Time.get_ticks_msec() >= next_order:
			next_order = Time.get_ticks_msec() + 6000
			var target: Vector2 = _wb_nearest_enemy()
			if target != Vector2.INF:
				# Marsch auf den naechsten Gegner (Wegpunkt wie _move_and_use); Waffen sind frei, der Trupp schiesst unterwegs selbst.
				controller.call("_create_waypoints_for_selected_fireteams", target, true)
				if bool(controller.call("execute_selected_fireteam_orders")): orders += 1
		if Time.get_ticks_msec() - started >= next_obs:
			next_obs += 20000
			_wb_obs(controller)
		await physics_frame
	print("WB_FIGHT befehle=%d echte_zeit_ms=%d ausgeschaltet=%d fit_gesehen=%d leader_fit=%s" % [orders, Time.get_ticks_msec() - started, _wb_out(), Dictionary(_wb_drv.get("_bounty_seen_fit")).size(), str(_wb_leader_fit())])

## Nur lesend: Lage von Trupp und Gegnern (Ort, Lage, Abstand, Befehlsquelle, Bewegungsstand, Waffenreichweite).
func _wb_obs(controller: Node) -> void:
	var sim: Node = _wb_drv.get_parent().get_node("SimulationRoot")
	for id in _crew_ids:
		if id == _pilot_id: continue
		var u: Node2D = _wb_reg.get_unit(id) as Node2D if _wb_reg.has_unit(id) else null
		if u == null: continue
		var cmd = u.call("get_current_unit_command") if u.has_method("get_current_unit_command") else null
		print("WB_OBS friend %s vital=%s hp=%s pos=%s cmd=%s src=%s move=%s" % [id, str(u.call("get_vital_state")), str(u.call("get_health")), str(u.global_position), str(cmd.get("command_type")) if cmd != null else "none", str(cmd.get("source_command_type")) if cmd != null else "-", str(sim.call("get_hex_movement_readout", id))])
	var leader: Node2D = _wb_reg.get_unit("campaign_leader") as Node2D
	for unit in Array(_wb_drv.call("_get_active_enemy_units")):
		if unit == null or not is_instance_valid(unit): continue
		var e: Node2D = unit as Node2D
		var ecmd = e.call("get_current_unit_command") if e.has_method("get_current_unit_command") else null
		print("WB_OBS enemy %s vital=%s pos=%s dist=%.0f range_to_leader=%s cmd=%s src=%s" % [str(e.call("get_unit_id")), str(e.call("get_vital_state")), str(e.global_position), leader.global_position.distance_to(e.global_position), str(_wb_drv.call("_get_weapon_attack_range", leader, e)), str(ecmd.get("command_type")) if ecmd != null else "none", str(ecmd.get("source_command_type")) if ecmd != null else "-"])

func _wb_card_button() -> Button:
	for node in _flow.find_children("return", "Button", true, false):
		var button := node as Button
		if button != null and String(button.get_meta("mission_dropship_craft_id", "")) == _craft_id and button.is_visible_in_tree(): return button
	return null

func _wb_crew_to_ship(controller: Node) -> bool:
	var ship: Vector2 = controller.call("_campaign_landed_craft_position", _craft_id)
	var access: Dictionary = controller.get_campaign_ground_ship_access(_craft_id)
	if bool(access.get("ok", false)): ship = Vector2(access.position)
	controller.call("_create_waypoints_for_selected_fireteams", ship, true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), "Rueckweg zum Schiff: Befehl wird angenommen"): return false
	var near := func() -> bool:
		var any := false
		for id in _crew_ids:
			if id == _pilot_id: continue
			var unit: Node2D = controller.call("_find_friendly_unit_by_id", id)
			if unit == null or String(unit.call("get_vital_state")) != "fit": continue
			any = true
			if unit.global_position.distance_to(ship) > 128.0: return false
		return any
	if not await _wait(near, 180000, "Trupp erreicht das Schiff"): return false
	controller.call("request_campaign_crew_boarding", _craft_id)
	return await _wait(func(): return bool(controller.call("get_campaign_pilot_flight_guard", _craft_id).ok), 8000, "Trupp ist an Bord (Flugfreigabe)")

## Ein Besuch: anfliegen, kaempfen, Kiste, heimfliegen und messen. Gibt false zurueck, wenn der Ablauf nicht weiterging.
func _wb_visit(number: int) -> bool:
	var tag := "Besuch %d" % number
	var credits_before := _credits()
	var items_before := _wb_items()
	var receipts_before: int = int(_runtime.get("_supply").call("count_requests", WB_CHEST_PREFIX, ":0:0"))
	_launch_tag = ":besuch%d" % number
	var selected: Dictionary = _screen.call("request_operation", "select_destination", {"location_id": WB_LOC, "job_id": "", "request_id": "wb:select:%d" % number})
	if not _check(bool(selected.get("ok", false)), "%s: Windbruch laesst sich ohne Auftrag als Ziel waehlen (%s)" % [tag, str(selected.get("reason", ""))]): return false
	_check(String(_flow.get("_selected_mission_id")) == WB_SCENARIO, "%s: gewaehlt ist das freie Lager (%s)" % [tag, String(_flow.get("_selected_mission_id"))])
	if not await _launch_and_land(WB_SCENARIO, WB_MAP): return false
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	_wb_drv = mission.get_node("CombatLoopDriver")
	_wb_reg = mission.get_node("UnitRegistry")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	_check(String(_campaign().get("selected_job_id", "")) == "", "%s: es laeuft ohne Kampagnenauftrag" % tag)
	_check(float(_flow.get("_active_mission_time_limit_seconds")) <= 0.0, "%s: kein Zeitlimit" % tag)
	if not await _pilot_safe_aboard(mission, controller): return false
	_check(bool(controller.call("set_selected_fireteams_fire_rule", "free")), "%s: Waffen frei" % tag)
	# Besatzung beim Eintreffen: Gegner erscheinen (Gruppen/Welle); volle Besatzung = 4 kampffaehige, 0 ausgeschaltet.
	var manned: bool = await _wait(func(): return Dictionary(_wb_drv.get("_bounty_seen_fit")).size() >= WB_EXPECTED, 120000, "%s: die Besatzung steht" % tag)
	_check(manned and Dictionary(_wb_drv.get("_bounty_seen_fit")).size() == WB_EXPECTED and _wb_out() == 0, "%s: volle Besatzung: %d kampffaehige Gegner gesehen, %d ausgeschaltet (Soll %d / 0)" % [tag, Dictionary(_wb_drv.get("_bounty_seen_fit")).size(), _wb_out(), WB_EXPECTED])
	var fit_groups: Dictionary = _wb_drv.call("get_enemy_group_fit_counts")
	print("WB_GARRISON %s gruppen=%s" % [tag, str(fit_groups)])
	await _wb_fight(controller)
	var out_now := _wb_out()
	_check(_wb_leader_fit(), "%s: Truppfuehrer lebt nach dem Gefecht" % tag)
	_check(out_now == WB_EXPECTED, "%s: alle %d Gegner ausgeschaltet (gezaehlt %d)" % [tag, WB_EXPECTED, out_now])
	if not _wb_leader_fit(): return false
	# Kiste oeffnen (Marke outpost_chip, Interaktion camp_chest).
	if not await _wb_use(mission, "camp_chest", "outpost_chip"): return false
	# Einsteigen und ueber den echten Rueckflugknopf heim.
	if not await _wb_crew_to_ship(controller): _dump("wb_crew_to_ship"); return false
	var out_at_departure := _wb_out()
	# Windbruch hat keinen Haendler: der Weg des Spielers ist der Knopf "Abheben" der Schiffskarte (wie small_outposts_visit_flight_verifier).
	if not await _wait(func():
		var candidate: Button = _wb_card_button()
		return candidate != null and not candidate.disabled, 8000, "%s: der Knopf Abheben der Schiffskarte ist nach dem Einsteigen frei" % tag):
		_dump("wb_return_button")
		return false
	_wb_card_button().pressed.emit()
	if not await _wait_homebase(): return false
	_flow.call("_show_homebase")
	for i in 30: await process_frame
	var credits_after := _credits()
	var diff := _wb_diff(items_before, _wb_items())
	var option_ok := false
	for option: Dictionary in WB_POOL:
		if option == diff: option_ok = true
	print("WB_SORTIE %s gegner=%d ausgeschaltet_bei_abflug=%d credits %d -> %d (erwartet +%d) fund=%s kisten_belege %d -> %d" % [tag, WB_EXPECTED, out_at_departure, credits_before, credits_after, out_at_departure * WB_PAY, str(diff), receipts_before, int(_runtime.get("_supply").call("count_requests", WB_CHEST_PREFIX, ":0:0"))])
	_check(out_at_departure == WB_EXPECTED, "%s: beim Abflug waren %d Gegner ausgeschaltet" % [tag, out_at_departure])
	_check(credits_after == credits_before + out_at_departure * WB_PAY, "%s: genau %d x %d = %d Credits gebucht (vorher %d, nachher %d)" % [tag, out_at_departure, WB_PAY, out_at_departure * WB_PAY, credits_before, credits_after])
	_check(option_ok, "%s: genau ein Kistenfund liegt in Fracht oder Basislager (Unterschied %s)" % [tag, str(diff)])
	_check(int(_runtime.get("_supply").call("count_requests", WB_CHEST_PREFIX, ":0:0")) == receipts_before + 1, "%s: ein Kistenbesuch gebucht (Beleg-Zaehler %d -> %d)" % [tag, receipts_before, int(_runtime.get("_supply").call("count_requests", WB_CHEST_PREFIX, ":0:0"))])
	for i in 60: await process_frame
	_check(_credits() == credits_after, "%s: Credits bleiben nach weiteren Bildern unveraendert (einmal gebucht)" % tag)
	var campaign: Dictionary = _campaign()
	var failed_jobs := 0
	for id in Dictionary(campaign.jobs): if String(Dictionary(campaign.jobs)[id].get("status", "")) == "failed": failed_jobs += 1
	_check(failed_jobs == 0 and String(Dictionary(_flow.get("_last_mission_result")).get("result", "")) != "defeat" and String(campaign.get("selected_job_id", "")) == "", "%s: kein Fehlschlag (gescheiterte Auftraege %d, kein Verlustbericht, kein Auftrag gewaehlt)" % [tag, failed_jobs])
	return true

## Gehen und Benutzen wie _move_and_use der Oberklasse, aber mit eigener Karte und getrennter Marke (Kiste: Interaktion camp_chest, Marke outpost_chip).
func _wb_use(mission: Node, interaction: String, marker: String) -> bool:
	var controller: Node = mission.get_node("TacticalController")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var target: Vector2 = MAP.load_from_file(WB_MAP).get_marker_position(marker)
	controller.call("_create_waypoints_for_selected_fireteams", target, true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), interaction + ": Gehen-Befehl wird angenommen"): return false
	if not await _wait(func():
		var entry: Dictionary = _find_interaction(controller.call("get_mission_interaction_runtime_use_state_snapshot"), interaction)
		return String(entry.get("runtime_use_status", "")) == "usable", 180000, interaction + " ist nach dem Anmarsch benutzbar"):
		var last: Dictionary = _find_interaction(controller.call("get_mission_interaction_runtime_use_state_snapshot"), interaction)
		print("WB_USE_STAND %s status=%s dist=%s reason=%s" % [interaction, str(last.get("runtime_use_status", "")), str(last.get("distance_world", "")), str(last.get("runtime_use_reason", ""))])
		_wb_obs(controller)
		_dump("wb_approach_" + interaction)
		return false
	var intent: Dictionary = controller.call("create_selected_mission_interaction_use_intent", interaction)
	if not _check(bool(intent.get("accepted", false)), interaction + ": Benutzen wird angenommen"): return false
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), interaction + ": Benutzen-Befehl wird angenommen"): return false
	return await _wait(func(): return bool(Dictionary(driver.call("get_mission_interaction_runtime_states").get(interaction, {})).get("complete", false)), 60000, interaction + " ist benutzt")

func _run() -> void:
	Engine.time_scale = 4.0
	_configure_entry()
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	await process_frame
	_flow.set_process(false)
	var payload: Dictionary = _fixture(_flow)
	_flow.queue_free()
	await process_frame
	var saved: Dictionary = STORE.save_checkpoint(payload)
	if not _check(bool(saved.get("ok", false)), "Fixture: Speicherpunkt nach Kapitel 1 gespeichert"):
		await _finish(); return
	START.request_start(self, "campaign", "continue")
	await _open_flow()
	_read_identities()
	var supply_owner: RefCounted = _runtime.get("_supply")
	for i in 2: supply_owner.call("receive_skirmish_equipment", "rifle")
	for person_id in _crew_ids:
		if person_id == _pilot_id: continue
		var gear: Dictionary = _screen.call("_get_member_loadout", person_id)
		if String(gear.get("weapon_1", "none")) == "none":
			var equip: Dictionary = _screen.call("request_operation", "inventory_equip", {"unit_id": person_id, "craft_id": _craft_id, "source_container_id": "base:homebase", "item_id": "rifle", "slot": "weapon_1"})
			_check(bool(equip.get("ok", false)), "%s zieht ein Gewehr aus dem Basislager" % person_id)
		print("WB_GEAR %s %s" % [person_id, str(_screen.call("_get_member_loadout", person_id))])
	if not await _board_actual_base_crew(): await _finish(); return
	var credits_start := _credits()
	var accepted: Dictionary = _runtime.call("request_operation", "standing_accept", {"order_id": WB_ORDER})
	if not _check(bool(accepted.get("ok", false)), "Dauerauftrag Rebellen hetzen angenommen (%s)" % str(accepted.get("reason", ""))):
		await _finish(); return
	_check(_credits() == credits_start, "Annehmen kostet und zahlt nichts")
	var jobs_before: Dictionary = Dictionary(_campaign().jobs).duplicate(true)
	var ok := await _wb_visit(1)
	if ok:
		_check(JSON.stringify(Dictionary(_campaign().jobs)) == JSON.stringify(jobs_before), "Besuch 1: kein Kampagnenauftrag hat sich veraendert")
		ok = await _wb_visit(2)
	if ok:
		_check(JSON.stringify(Dictionary(_campaign().jobs)) == JSON.stringify(jobs_before), "Besuch 2: kein Kampagnenauftrag hat sich veraendert")
	await _finish()

func _finish() -> void:
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("CAMPAIGN_WINDBRUCH_FREE_SORTIE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
