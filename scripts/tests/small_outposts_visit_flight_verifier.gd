extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Handel 2a, Aufgabe 2: echter Besuchsflug zu einem kleinen Aussenposten (Standard Muellers Farm; die Geschwister
## small_outposts_visit_shady_lab_verifier und small_outposts_visit_templanon_verifier ueberschreiben nur _place_id()).
## Der Treiber fliegt zuerst die Satellitenbergung (echt). Statt des zweiten Ausflugs wird dann der kleine Aussenposten besucht:
##   1 vor outpost_recovery ist der Ort gesperrt (Text "Gesperrt: ..."), die Anflugwahl wird abgelehnt;
##   2 Testvorbereitung (NICHT geflogen): outpost_recovery wird im Besitzer auf "completed" gesetzt (die Freischaltung ist die Pruefung, nicht der Auftrag);
##   3 Anflug: Abheben, Sprung, Landung beim Haendler-Marker (Landefeld nahe dem Haendler), Besuchsszenario geladen, Gang zum Haendler;
##   4 Rueckflug: Besatzung steigt ein, Abflug, Heimkehr; der Auftragsstatus wird davor auf den echten Wert zurueckgesetzt.
## Abschlusszeile: SMALL_OUTPOSTS_VISIT_FLIGHT place=<id> passed=%d failed=%d (danach die Zeile des Treibers SINGLEPLAYER_LOOP_RESULTS ...).
const LOCKED_TEXT := "Gesperrt: Erst nach dem Auftrag am Handelsaußenposten"
var _sv_flown := false
var _sv_near_trader := false
var _sv_marker := ""
var _sv_map := ""

func _place_id() -> String:
	return "muellers_farm"

func _launch_and_land(scenario_id: String, map_path: String) -> bool:
	if scenario_id != "outpost_recovery" or _sv_flown:
		return await super._launch_and_land(scenario_id, map_path)
	_sv_flown = true
	await _visit_part()
	return false

## Landefeld: das dem Haendler naechste Feld innerhalb von 250 Einheiten, auf dem die echte Landepruefung des Spiels besteht und dessen Rumpf
## den Haendler mindestens 2 Felder frei laesst (wie campaign_open_outposts_verifier).
func _landing_target(map) -> Vector2:
	if not _sv_near_trader:
		return super._landing_target(map)
	var active: Node = _flow.get("_active_mission")
	var controller: Node = active.get_node("TacticalController")
	var registry: Node = controller.call("_get_terrain_registry")
	var hex_registry: Node = active.get_node("SimulationRoot").call("get_hex_ground_terrain_registry")
	var contract = load("res://scripts/mission/field_landing_contract.gd")
	var hex = load("res://scripts/terrain/hex_grid.gd")
	var trader: Vector2 = map.get_marker_position(_sv_marker)
	var trader_grid: Vector2i = hex_registry.call("world_to_grid", trader)
	var card: Dictionary = Dictionary(controller.call("_find_mission_dropship_card_entry", _craft_id)).duplicate(true)
	var best: Vector2 = Vector2.INF
	var best_clearance := -1
	for tile in map.get_tiles():
		var d: float = tile.world_position.distance_to(trader)
		if d > 250.0 or (best.is_finite() and d >= best.distance_to(trader)): continue
		if not bool(contract.validate(registry, tile.grid_position, []).ok): continue
		card["lz_position"] = tile.world_position
		var projection: Dictionary = controller.call("_read_ground_ship_landing_projection", card, tile.world_position, "NW")
		var profile: Dictionary = load("res://scripts/mission/polisa_ground_body_profile.gd").from_projection(card, projection)
		if not bool(profile.get("ok", false)) or not bool(controller.call("_check_ground_ship_landing_site", card, tile.world_position, profile.profile).get("ok", false)): continue
		var hull: Dictionary = controller.call("_get_bound_ground_ship_cells", hex_registry, card, tile.world_position, profile.profile)
		if not bool(hull.get("ok", false)): continue
		var clearance := 1000000
		for cell: Vector2i in hull.blocked_cells: clearance = mini(clearance, int(hex.distance(cell, trader_grid)))
		if clearance < 2: continue
		best = tile.world_position
		best_clearance = clearance
	print("SV_LANDING place=%s trader_grid=%s chosen=%s distance=%s hull_clearance_cells=%d" % [_place_id(), str(trader_grid), str(best), str(snappedf(best.distance_to(trader), 0.1)) if best.is_finite() else "-", best_clearance])
	_check(best.is_finite(), "C: auf der Karte von %s gibt es hoechstens 250 Einheiten vom Haendler ein gueltiges Landefeld, dessen Rumpf mindestens 2 Felder Abstand zum Haendler laesst" % _place_id())
	return best if best.is_finite() else super._landing_target(map)

func _visit_part() -> void:
	var place := _place_id()
	var entry: Dictionary = Dictionary(Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/small_outposts.json"))).locations).get(place, {})
	_sv_marker = String(entry.get("service_marker_id", ""))
	var definition: Dictionary = Dictionary(Dictionary(_campaign().locations).get(place, {}))
	_sv_map = String(definition.get("map_file_path", ""))
	var scenario_id := place + "_visit"
	var live: RefCounted = _runtime.get("_campaign")
	var locked: Dictionary = live.validate_location_visit(place)
	_check(String(locked.get("reason", "")) == "outpost_locked" and String(locked.get("message", "")) == LOCKED_TEXT, "C1: vor outpost_recovery ist %s gesperrt (%s)" % [place, str(locked)])
	var refused: Dictionary = _screen.call("request_operation", "select_destination", {"location_id": place, "job_id": "", "request_id": "sv:locked"})
	_check(not bool(refused.get("ok", true)), "C1: die Anflugwahl des gesperrten Ortes wird abgelehnt (%s)" % str(refused))
	var job: Dictionary = live.get("_jobs")["outpost_recovery"]
	var original_status := String(job.status)
	job.status = "completed"
	print("SV_PREPARE outpost_recovery status %s -> completed (Testvorbereitung, nicht geflogen)" % original_status)
	_check(bool(live.validate_location_visit(place).get("ok", false)), "C2: nach outpost_recovery ist %s anfliegbar" % place)
	var selected: Dictionary = _screen.call("request_operation", "select_destination", {"location_id": place, "job_id": "", "request_id": "sv:open"})
	_check(bool(selected.get("ok", false)), "C2: der Ort laesst sich ohne Auftrag als Ziel waehlen (%s)" % str(selected))
	_check(String(_flow.get("_selected_mission_id")) == scenario_id, "C2: gewaehlt ist das Besuchsszenario %s (%s)" % [scenario_id, String(_flow.get("_selected_mission_id"))])
	_sv_near_trader = true
	var landed_ok: bool = await _launch_and_land(scenario_id, _sv_map)
	_sv_near_trader = false
	if not landed_ok:
		return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	var driver: Node = mission.get_node("CombatLoopDriver")
	_check(float(driver.get("mission_time_limit_seconds")) <= 0.0 and float(_flow.get("_active_mission_time_limit_seconds")) <= 0.0, "C3: der Besuch laeuft ohne Zeitlimit")
	var trader: Vector2 = MAP.load_from_file(_sv_map).get_marker_position(_sv_marker)
	var landed_at: Vector2 = Vector2(controller.call("_campaign_landed_craft_position", _craft_id))
	_check(landed_at.distance_to(trader) <= 256.0, "C3: das Schiff steht beim Haendler (%s Einheiten, erlaubt 256)" % str(snappedf(landed_at.distance_to(trader), 0.1)))
	if not await _move_and_use(mission, _sv_marker, "service_visit", _sv_map):
		return
	_no_trade_part(place)
	job.status = original_status
	print("SV_PREPARE outpost_recovery status zurueck auf %s" % original_status)
	if not await _prepare_visit_return(mission):
		return
	# Der Versorgungsknopf "Rueckflug" gehoert zum Haendlerdienst (Aufgabe 3) und erscheint hier nicht. Der Weg des Spielers an einem Ort ohne
	# Dienst: die Besatzung geht zum Schiff und steigt ein (_prepare_visit_return), dann der Knopf "Abheben" der Schiffskarte.
	var service_button: Button = _flow.find_child("ServiceReturnHomebase", true, false) as Button
	_check(service_button == null or not service_button.is_visible_in_tree(), "C4: der Versorgungsknopf Rueckflug ist am Posten nicht da (kein Dienst bis Aufgabe 3)")
	if not await _wait(func():
		var candidate: Button = _ship_card_return_button()
		return candidate != null and not candidate.disabled, 5000, "C4: der Knopf Abheben der Schiffskarte ist nach dem Einsteigen frei"):
		_dump("small_outpost_card_return")
		return
	var card_button: Button = _ship_card_return_button()
	_check(card_button.text == "Abheben", "C4: der Knopf der Schiffskarte heisst Abheben (%s)" % card_button.text)
	card_button.pressed.emit()
	print("SV_RETURN_BUTTON Abheben der Schiffskarte gedrueckt")
	if not await _wait_homebase():
		return
	_flow.call("_show_homebase")
	_check(String(Dictionary(_campaign().jobs).get("outpost_recovery", {}).get("status", "")) == original_status, "C5: nach der Heimkehr hat der Besuch den Auftragsstatus nicht veraendert")
	var again: Dictionary = _runtime.get("_campaign").validate_location_visit(place)
	_check(String(again.get("reason", "")) == "outpost_locked", "C5: Gegenprobe: mit echtem Auftragsstatus ist der Ort wieder gesperrt")

## Der Knopf "return" (Beschriftung "Abheben") der Schiffskarte des eigenen Schiffs; null, solange keine Karte sichtbar ist.
func _ship_card_return_button() -> Button:
	for node in _flow.find_children("return", "Button", true, false):
		var button := node as Button
		if button != null and String(button.get_meta("mission_dropship_craft_id", "")) == _craft_id and button.is_visible_in_tree(): return button
	return null

## Kl1: vor Aufgabe 3 ist am Posten ueber die Spielwege kein Kauf und kein Verkauf moeglich. Der Kaufbefehl und der Verkaufsbefehl, die das Spiel
## absetzt (Anfrage mit Versorgungsort), werden vom Laufzeit-Adapter abgelehnt, weil das Schiff dort keinen Versorgungskontext hat.
func _no_trade_part(place: String) -> void:
	var item := {"muellers_farm": "food", "shady_lab": "stim", "templanon": "bandage"}.get(place, "food") as String
	var before_credits := int(Dictionary(_runtime.call("get_snapshot").get("supply", {})).get("credits", -1))
	var buy: Dictionary = _runtime.call("request_operation", "buy", {"craft_id": _craft_id, "service_location_id": place, "offer_id": "market:%s:%s" % [place, item], "quantity": 1, "request_id": "sv:buy"})
	var sell: Dictionary = _runtime.call("request_operation", "sell", {"craft_id": _craft_id, "service_location_id": place, "source_container_id": "craft:" + _craft_id, "item_id": "c_benit", "quantity": 1, "request_id": "sv:sell"})
	print("SV_NO_TRADE buy=", buy, " sell=", sell)
	# Gueter-Dreieck (24.11.2026): am Haendler-Marker gilt jetzt der Handelsdienst (das Schiff hat einen Versorgungskontext), aber nur fuer Heilkraeuter,
	# Duenger und Aufputschmittel. Ein frueheres Handelsgut (Nahrung usw.) und Benit werden mit den Gruenden des Versorgungszustands abgelehnt -
	# nicht mehr mit service_location_changed (das hiesse: kein Dienst am Ort).
	_check(not bool(buy.get("ok", true)) and String(buy.get("reason", "")) == "unknown_offer", "Kl1: Kauf eines nicht gehandelten Guts am Posten %s abgelehnt, Grund %s" % [place, String(buy.get("reason", "?"))])
	_check(not bool(sell.get("ok", true)) and String(sell.get("reason", "")) == "not_purchased", "Kl1: Verkauf von Benit am Posten %s abgelehnt, Grund %s" % [place, String(sell.get("reason", "?"))])
	_check(int(Dictionary(_runtime.call("get_snapshot").get("supply", {})).get("credits", -2)) == before_credits, "Kl1: die Credits haben sich am Posten nicht bewegt (%d)" % before_credits)

func _finish() -> void:
	print("SMALL_OUTPOSTS_VISIT_FLIGHT place=%s passed=%d failed=%d" % [_place_id(), _passed, _failed])
	await super._finish()
