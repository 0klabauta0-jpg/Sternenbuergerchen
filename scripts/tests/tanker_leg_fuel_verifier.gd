extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Nutzt die Basisklasse der echten Kampagnen-Schleife (echte Basis, Pilot und Crew an Bord); _run ist ersetzt.
## T1 des Tanker-Auftrags (21.11.2026): Treibstoff Etappe fuer Etappe statt pauschaler Hin-und-Rueckflug-Reserve.
## Regel 8 in docs/dev/campaign_casualty_retreat_contract.md. Jede Etappe (Abheben, Sprung, Anflug, Ortsabflug,
## Landung) bucht ihren Anteil genau einmal beim Versorgungsbesitzer, wenn sie beginnt; "liegen geblieben"
## ist ein abgeleiteter Zustand (get_fuel_status), kein gespeicherter.

const SUPPLY_SCRIPT: GDScript = preload("res://scripts/core/singleplayer_supply_state.gd")
const FLOW_SCENE: String = "res://scenes/meta/meta_layer_test.tscn"
const DATA_PATH: String = "res://data/singleplayer/trade_offers.json"
const OLD_FIXTURES: Array = [
	"res://scripts/tests/fixtures/main_639a49d65_checkpoint.json",
	"res://docs/qa/review_completion_20261113/post_benit_source/checkpoint_v1.json",
	"res://docs/qa/review_completion_20261113/legacy_source_pair/checkpoint_v1.json",
]

func _data() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))

func _leg_command(craft_id: String, leg: String, origin: String, destination: String, request_id: String) -> Dictionary:
	return {"contract_category": "singleplayer_supply", "operation": "consume_leg_fuel", "payload": {"craft_id": craft_id, "leg": leg, "origin_location_id": origin, "destination_location_id": destination}, "request_id": request_id}

func _run() -> void:
	if "only=table" in OS.get_cmdline_user_args():
		_scenario_table_and_owner()
		_scenario_chains_never_cheaper()
		print("TANKER_LEG_FUEL passed=%d failed=%d" % [_passed, _failed])
		quit(0 if _failed == 0 else 1)
		return
	if "only=restart_other" in OS.get_cmdline_user_args():
		await _scenario_restart_other_target()
		print("TANKER_LEG_FUEL passed=%d failed=%d" % [_passed, _failed])
		quit(0 if _failed == 0 else 1)
		return
	if "only=jump_restart" in OS.get_cmdline_user_args():
		await _scenario_jump_restart()
		print("TANKER_LEG_FUEL passed=%d failed=%d" % [_passed, _failed])
		quit(0 if _failed == 0 else 1)
		return
	_scenario_table_and_owner()
	_scenario_chains_never_cheaper()
	_scenario_save_and_load()
	await _scenario_full_tank_flight()
	await _scenario_jump_restart()
	await _scenario_restart_other_target()
	await _scenario_launch_without_fuel()
	await _scenario_jump_without_fuel()
	await _scenario_stranded_in_orbit()
	await _scenario_outbound_only_approach()
	await _scenario_return_preflight_covered()
	print("TANKER_LEG_FUEL passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

# --- Flow-Sitzung (echte Szene, echter Adapter, echter Versorgungsbesitzer) ----------------------------

func _session(initial_fuel: float) -> Dictionary:
	_configure_entry()
	var flow: Node = load(FLOW_SCENE).instantiate()
	_flow = flow
	root.add_child(flow)
	await process_frame
	var runtime: Object = flow.get("_singleplayer_runtime")
	var screen: Node = flow.get_node("HomebaseScreen")
	_screen = screen
	_runtime = runtime
	_check(await _prepare_initial_base(), "Sitzung: echte Basis mit Pilot und Crew an Bord ist bereit")
	var supply: Object = runtime.get("_supply")
	var crafts: Array = flow.get("_homebase_aircraft_definitions")
	var craft_id: String = _craft_id
	_check(String(crafts[0].craft_id) == craft_id, "Sitzung: das gewaehlte Schiff ist das erste Schiff der Basis")
	var data: Dictionary = _data()
	data["initial_fuel"] = initial_fuel
	supply.configure(crafts, data)
	screen.request_operation("accept_job", {"job_id": "satellite_recovery"})
	screen.request_operation("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"})
	return {"flow": flow, "runtime": runtime, "supply": supply, "screen": screen, "craft_id": craft_id}

func _close(session: Dictionary) -> void:
	var flow: Node = session.flow
	flow.queue_free()
	await process_frame
	await process_frame

func _phase(session: Dictionary) -> String:
	return String(session.runtime.get_space_travel_snapshot(session.craft_id).get("phase", ""))

func _wait_for(session: Dictionary, predicate: Callable, timeout_msec: int) -> bool:
	var deadline: int = Time.get_ticks_msec() + timeout_msec
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return predicate.call()

func _launch(session: Dictionary) -> Dictionary:
	if session.screen.has_meta("singleplayer_departure_error"):
		session.screen.remove_meta("singleplayer_departure_error")
	session.screen.request_operation("start", {"craft_id": session.craft_id})
	var error: Dictionary = Dictionary(session.screen.get_meta("singleplayer_departure_error", {}))
	return error if _phase(session) == "grounded" else {"ok": true}

func _jump(session: Dictionary, target_orbit_id: String) -> Dictionary:
	return session.screen.request_operation("space_start_quantum", {"craft_id": session.craft_id, "target_orbit_id": target_orbit_id})

func _site_orbit(session: Dictionary) -> String:
	return String(Dictionary(session.runtime.get_space_travel_snapshot(session.craft_id).get("location_orbits", {})).get("satellite_crash", ""))

func _arrived(session: Dictionary, orbit_id: String) -> Callable:
	return func() -> bool: return _phase(session) == "orbit" and String(session.runtime.get_space_travel_snapshot(session.craft_id).get("orbit_id", "")) == orbit_id

# --- 1. Tabelle und Besitzer ----------------------------------------------------------------------

func _scenario_table_and_owner() -> void:
	var data: Dictionary = _data()
	var routes: Dictionary = data.route_fuel_costs
	var legs: Dictionary = data.get("leg_fuel_costs", {})
	_check(not legs.is_empty(), "1: leg_fuel_costs ist in den Versorgungsdaten vorhanden")
	var supply: Object = SUPPLY_SCRIPT.new()
	_check(bool(supply.configure([{"craft_id": "ship"}], data).get("ok", false)), "1: Versorgungsdaten mit Etappenblock werden angenommen")
	for route: String in routes:
		var sum: float = 0.0
		for value: Variant in Dictionary(legs.get(route, {})).values():
			sum += float(value)
		_check(is_equal_approx(sum, float(routes[route])), "1: Summe der Etappen == Routenwert fuer " + route)
		# W7: die Summe der ECHT gebuchten Etappen (echte Befehle am Besitzer) == alter Streckenwert, fuer JEDE Strecke inkl. Ort -> Ort.
		var booked: float = _book_route_with_real_legs(String(route))
		_check(booked >= 0.0 and is_equal_approx(booked, float(routes[route])), "1/W7: Summe der real gebuchten Etappen == route_fuel_costs fuer %s (gebucht %s, Soll %s)" % [route, booked, routes[route]])
	# W7: Ort -> Ort muss exakt Ortsabflug des Ortes + Sprung + Anflug von zu Hause sein; weicht die Tabelle ab, wird sie abgelehnt.
	var inconsistent: Dictionary = _data()
	inconsistent.leg_fuel_costs["satellite_crash>trade_outpost"] = {"surface_exit": 6.0, "jump": 1.0, "approach": 3.0}
	_check(not bool(SUPPLY_SCRIPT.new().configure([{"craft_id": "ship"}], inconsistent).get("ok", true)), "W7: Ort->Ort-Eintrag mit anderem Ortsabflug als Ort->Heimat wird abgelehnt")
	var inconsistent_approach: Dictionary = _data()
	inconsistent_approach.leg_fuel_costs["trade_outpost>satellite_crash"] = {"surface_exit": 5.0, "jump": 1.0, "approach": 4.0}
	_check(not bool(SUPPLY_SCRIPT.new().configure([{"craft_id": "ship"}], inconsistent_approach).get("ok", true)), "W7: Ort->Ort-Eintrag mit anderem Anflug als Heimat->Ort wird abgelehnt")
	# Eine Tabelle, die nicht aufgeht, wird abgelehnt.
	var broken: Dictionary = _data()
	broken.leg_fuel_costs["homebase>trade_outpost"]["approach"] = 4.0
	_check(not bool(SUPPLY_SCRIPT.new().configure([{"craft_id": "ship"}], broken).get("ok", true)), "1: eine Etappentabelle, die nicht aufgeht, wird abgelehnt")
	# Vorpruefung ist rein lesend.
	var revision: int = supply.get_revision()
	var gate: Dictionary = supply.preview_leg_fuel({"craft_id": "ship", "leg": "launch", "origin_location_id": "homebase", "destination_location_id": ""}, {"departure_authorized": true})
	_check(gate.get("ok", false) and supply.get_revision() == revision and supply.get_fuel("ship") == 60.0, "Vorpruefung einer Etappe aendert weder Treibstoff noch _revision")
	_check(not supply.preview_leg_fuel({"craft_id": "ship", "leg": "launch", "origin_location_id": "homebase", "destination_location_id": ""}).get("ok", true), "Vorpruefung ohne Abflugberechtigung wird abgelehnt")
	_check(String(supply.preview_leg_fuel({"craft_id": "ship", "leg": "nonsense", "origin_location_id": "homebase", "destination_location_id": "polisa", "x": 1}, {"departure_authorized": true}).get("reason", "")) == "unknown_leg", "Unbekannte Etappe wird als unknown_leg abgelehnt")
	# 6: dieselbe Etappe zweimal (gleiche Request-ID) -> eine Buchung, die zweite Antwort ist replayed.
	var context: Dictionary = {"departure_authorized": true}
	var first: Dictionary = supply.apply_command(_leg_command("ship", "launch", "homebase", "", "t1:launch"), context)
	var second: Dictionary = supply.apply_command(_leg_command("ship", "launch", "homebase", "", "t1:launch"), context)
	_check(first.get("ok", false) and not first.has("replayed") and is_equal_approx(supply.get_fuel("ship"), 59.0), "6: erste Buchung zieht genau den Etappenanteil ab (60 -> 59)")
	_check(second.get("ok", false) and bool(second.get("replayed", false)) and is_equal_approx(supply.get_fuel("ship"), 59.0), "6: zweite Antwort derselben Anfrage ist replayed und bucht nicht noch einmal")
	var conflict: Dictionary = supply.apply_command(_leg_command("ship", "jump", "homebase", "satellite_crash", "t1:launch"), context)
	_check(not conflict.get("ok", true) and String(conflict.get("reason", "")) == "request_id_conflict", "6: dieselbe Request-ID mit anderer Etappe wird abgelehnt")
	# 3: nicht gedeckt -> abgelehnt, nichts gebucht, mit Text "Benoetigt X, vorhanden Y".
	var poor: Object = SUPPLY_SCRIPT.new()
	var poor_data: Dictionary = _data()
	poor_data["initial_fuel"] = 1.0
	poor.configure([{"craft_id": "ship"}], poor_data)
	var rejected: Dictionary = poor.apply_command(_leg_command("ship", "jump", "homebase", "satellite_crash", "t1:poor-jump"), context)
	_check(not rejected.get("ok", true) and String(rejected.get("reason", "")) == "leg_fuel_insufficient", "3: nicht gedeckter Sprung wird mit leg_fuel_insufficient abgelehnt")
	_check(String(rejected.get("message", "")).contains("Treibstoff reicht nicht für diese Etappe") and String(rejected.get("message", "")).contains("Benötigt 10, vorhanden 1"), "3: Text nennt Etappe, benoetigte und vorhandene Menge: " + String(rejected.get("message", "")))
	_check(is_equal_approx(poor.get_fuel("ship"), 1.0) and not poor.has_request("t1:poor-jump"), "3: abgelehnte Etappe bucht nichts und hinterlaesst keinen Beleg")
	# 8 (Besitzerebene): Ortsabflug mit zu wenig Treibstoff behaelt den alten Satz.
	var exit_rejected: Dictionary = poor.apply_command(_leg_command("ship", "surface_exit", "satellite_crash", "homebase", "t1:poor-exit"), context)
	_check(String(exit_rejected.get("reason", "")) == "leg_fuel_insufficient" and String(exit_rejected.get("message", "")) == "Treibstoff reicht nicht für den Rückflug", "8: Ortsabflug mit zu wenig Treibstoff: alter Satz 'Treibstoff reicht nicht für den Rückflug'")
	# Die kostenlose Heimlandung ist immer bezahlbar, auch bei leerem Tank.
	var empty: Object = SUPPLY_SCRIPT.new()
	var empty_data: Dictionary = _data()
	empty_data["initial_fuel"] = 0.0
	empty.configure([{"craft_id": "ship"}], empty_data)
	_check(empty.preview_leg_fuel({"craft_id": "ship", "leg": "landing", "origin_location_id": "", "destination_location_id": "homebase"}, context).get("ok", false), "3: die Heimlandung kostet nichts und ist bei leerem Tank bezahlbar")
	# Alte Belege bleiben gueltig: consume_route_fuel wirkt wie bisher.
	var legacy: Dictionary = poor.apply_command({"contract_category": "singleplayer_supply", "operation": "consume_route_fuel", "payload": {"craft_id": "ship", "origin_location_id": "homebase", "destination_location_id": "trade_outpost"}, "request_id": "t1:old-route"}, context)
	_check(not legacy.get("ok", true) and String(legacy.get("reason", "")) == "insufficient_fuel", "4 (Entscheidung): consume_route_fuel bleibt fuer alte Belege gueltig und prueft wie bisher")
	# Fix-Runde 1 (SMALL 2): "whole_route" und get_return_leg gibt es nicht mehr; der Rueckweg vom Ort ist immer der Ortsabflug.
	_check(supply.get_leg_fuel_cost("homebase", "satellite_crash", "whole_route") < 0.0, "8: whole_route ist keine Etappe mehr (Kosten -1)")
	_check(String(supply.preview_leg_fuel({"craft_id": "ship", "leg": "whole_route", "origin_location_id": "homebase", "destination_location_id": "satellite_crash"}, context).get("reason", "")) == "unknown_leg", "8: whole_route wird als unknown_leg abgelehnt")
	_check(not supply.has_method("get_return_leg"), "8: get_return_leg ist entfernt")
	# already_paid: nur die Differenz wird gebucht, nie mehr als die Etappe, nie zurueck.
	var credit: Object = SUPPLY_SCRIPT.new()
	credit.configure([{"craft_id": "ship"}], _data())
	var credited: Dictionary = _leg_command("ship", "jump", "homebase", "trade_outpost", "t1:credit-a")
	credited.payload["already_paid"] = 6.0
	_check(credit.apply_command(credited, context).get("ok", false) and is_equal_approx(credit.get_fuel("ship"), 60.0), "SMALL 1: Anrechnung in voller Hoehe (6 von 6) bucht nichts")
	var credited_more: Dictionary = _leg_command("ship", "jump", "homebase", "satellite_crash", "t1:credit-b")
	credited_more.payload["already_paid"] = 3.0
	_check(credit.apply_command(credited_more, context).get("ok", false) and is_equal_approx(credit.get_fuel("ship"), 53.0), "SMALL 1: Anrechnung 3 von 10 bucht nur die Differenz 7")
	var credited_over: Dictionary = _leg_command("ship", "jump", "homebase", "trade_outpost", "t1:credit-c")
	credited_over.payload["already_paid"] = 9.0
	_check(credit.apply_command(credited_over, context).get("ok", false) and is_equal_approx(credit.get_fuel("ship"), 53.0), "SMALL 1: zu hohe Anrechnung erstattet nichts zurueck")
	var credited_bad: Dictionary = _leg_command("ship", "jump", "homebase", "trade_outpost", "t1:credit-d")
	credited_bad.payload["already_paid"] = -1.0
	_check(not credit.apply_command(credited_bad, context).get("ok", true) and is_equal_approx(credit.get_fuel("ship"), 53.0), "SMALL 1: negative Anrechnung wird abgelehnt")

## W7: bucht eine Strecke "origin>destination" so, wie die Simulation es im Spiel tut, mit echten Befehlen am Besitzer, und gibt den
## abgezogenen Treibstoff zurueck. Von zu Hause: Abheben, Sprung, Anflug. Nach Hause: Ortsabflug, Sprung, Landung. Ort -> Ort:
## Ortsabflug (Ort -> Heimat), Sprung (Ort -> Ort), Anflug (Heimat -> Ort). Nicht definierte Etappen kosten nichts (unknown_leg).
func _book_route_with_real_legs(route: String) -> float:
	var parts: PackedStringArray = route.split(">")
	var from: String = parts[0]
	var to: String = parts[1]
	var supply: Object = SUPPLY_SCRIPT.new()
	supply.configure([{"craft_id": "ship"}], _data())
	var before: float = supply.get_fuel("ship")
	var context: Dictionary = {"departure_authorized": true}
	var steps: Array = []
	if from == "homebase":
		steps = [["launch", "homebase", ""], ["jump", from, to], ["approach", "homebase", to]]
	elif to == "homebase":
		steps = [["surface_exit", from, "homebase"], ["jump", from, to], ["landing", "", "homebase"]]
	else:
		steps = [["surface_exit", from, "homebase"], ["jump", from, to], ["approach", "homebase", to]]
	var index: int = 0
	for step: Array in steps:
		index += 1
		var result: Dictionary = supply.apply_command(_leg_command("ship", String(step[0]), String(step[1]), String(step[2]), "w7:%s:%d" % [route, index]), context)
		if not result.get("ok", false):
			_check(false, "W7: Etappe %s der Strecke %s wurde abgelehnt: %s" % [step[0], route, JSON.stringify(result)])
			return -1.0
	return before - supply.get_fuel("ship")

# --- W8: ortsfeste Teile und Sprungtabelle; keine Kette ist je billiger als die direkte Strecke --------------

func _scenario_chains_never_cheaper() -> void:
	var data: Dictionary = _data()
	var table: Dictionary = data.leg_fuel_costs
	var routes: Dictionary = data.route_fuel_costs
	# Ortsfeste Teile sind ueberall gleich, kein Sprung ist gratis, der Sprung ist symmetrisch.
	var fixed: Dictionary = {}
	var jumps: Dictionary = {}
	for route: String in table:
		var legs: Dictionary = table[route]
		_check(float(legs.get("jump", 0.0)) > 0.0, "W8: kein Sprung kostet 0: " + route)
		for leg: String in legs:
			if leg == "jump": continue
			if fixed.has(leg): _check(is_equal_approx(float(fixed[leg]), float(legs[leg])), "W8: ortsfester Teil %s ist ueberall gleich (%s)" % [leg, route])
			fixed[leg] = float(legs[leg])
		var parts: PackedStringArray = route.split(">")
		var key: String = parts[0] + "|" + parts[1] if parts[0] <= parts[1] else parts[1] + "|" + parts[0]
		if jumps.has(key): _check(is_equal_approx(float(jumps[key]), float(legs.jump)), "W8: Sprung ist in beide Richtungen gleich: " + key)
		jumps[key] = float(legs.jump)
	# Rechnerisch ueber alle Orbit-Tripel: jump(A,C) <= jump(A,B) + jump(B,C).
	var places: Array = []
	for route: String in table:
		for place: String in route.split(">"):
			if not places.has(place): places.append(place)
	var triples := 0
	for a: String in places:
		for b: String in places:
			for c: String in places:
				if a == b or b == c or a == c: continue
				var ab: String = a + "|" + b if a <= b else b + "|" + a
				var bc: String = b + "|" + c if b <= c else c + "|" + b
				var ac: String = a + "|" + c if a <= c else c + "|" + a
				if jumps.has(ab) and jumps.has(bc) and jumps.has(ac):
					triples += 1
					_check(float(jumps[ac]) <= float(jumps[ab]) + float(jumps[bc]) + 0.00001, "W8: Dreiecksungleichung %s <= %s + %s" % [ac, ab, bc])
	_check(triples > 0, "W8: es gibt Orbit-Tripel zu pruefen")
	# Rechnerisch: jede Kette von Strecken (A>B, B>C) ist mindestens so teuer wie die direkte Strecke A>C, soweit es sie gibt.
	var chains := 0
	for ab_route: String in routes:
		for bc_route: String in routes:
			var p1: PackedStringArray = ab_route.split(">")
			var p2: PackedStringArray = bc_route.split(">")
			if p1[1] != p2[0] or p1[0] == p2[1]: continue
			var direct: String = p1[0] + ">" + p2[1]
			if not routes.has(direct): continue
			chains += 1
			var chain_cost: float = _book_route_with_real_legs(ab_route) + _book_route_with_real_legs(bc_route)
			var direct_cost: float = _book_route_with_real_legs(direct)
			_check(chain_cost >= direct_cost - 0.00001, "W8: Kette %s + %s (%s) ist nicht billiger als direkt %s (%s)" % [ab_route, bc_route, chain_cost, direct, direct_cost])
	_check(chains > 0, "W8: es gibt Ketten zu pruefen")
	# Mit echten Befehlen am Besitzer ein Beispiel: Absturzstelle -> Orbit Handelsposten -> Heimat (Ortsabflug 2, Sprung 7, Sprung 6, Landung 0) = 15 >= direkt 12.
	var supply: Object = SUPPLY_SCRIPT.new()
	supply.configure([{"craft_id": "ship"}], data)
	var context: Dictionary = {"departure_authorized": true}
	var before: float = supply.get_fuel("ship")
	for step: Array in [["surface_exit", "satellite_crash", "homebase"], ["jump", "satellite_crash", "trade_outpost"], ["jump", "trade_outpost", "homebase"], ["landing", "", "homebase"]]:
		_check(supply.apply_command(_leg_command("ship", String(step[0]), String(step[1]), String(step[2]), "w8:" + String(step[0]) + String(step[1])), context).get("ok", false), "W8: Etappe %s %s>%s gebucht" % [step[0], step[1], step[2]])
	_check(before - supply.get_fuel("ship") >= float(routes["satellite_crash>homebase"]), "W8: die Kette ueber den Orbit des Handelspostens (15) ist nicht billiger als die direkte Strecke (12): " + str(before - supply.get_fuel("ship")))
	# Ein Sprung startet nie mit leerem Tank.
	var empty_data: Dictionary = _data()
	empty_data["initial_fuel"] = 0.0
	var empty: Object = SUPPLY_SCRIPT.new()
	empty.configure([{"craft_id": "ship"}], empty_data)
	for route: String in table:
		var parts: PackedStringArray = route.split(">")
		var gate: Dictionary = empty.preview_leg_fuel({"craft_id": "ship", "leg": "jump", "origin_location_id": parts[0], "destination_location_id": parts[1]}, context)
		_check(not gate.get("ok", true) and String(gate.get("reason", "")) == "leg_fuel_insufficient", "W8: Sprung %s startet mit leerem Tank nicht" % route)
	# configure lehnt Daten ab, die eine der Bedingungen verletzen.
	var zero_jump: Dictionary = _data()
	zero_jump.leg_fuel_costs["satellite_crash>trade_outpost"] = {"surface_exit": 2.0, "jump": 0.0, "approach": 1.0}
	zero_jump.route_fuel_costs["satellite_crash>trade_outpost"] = 3.0
	var zero_result: Dictionary = SUPPLY_SCRIPT.new().configure([{"craft_id": "ship"}], zero_jump)
	_check(not bool(zero_result.get("ok", true)) and String(zero_result.get("message", "")).contains("Sprung ohne Kosten"), "W8: configure lehnt einen Sprung mit Kosten 0 ab (Summe und ortsfeste Teile stimmen): " + str(zero_result))
	var asymmetric: Dictionary = _data()
	asymmetric.leg_fuel_costs["trade_outpost>satellite_crash"] = {"surface_exit": 2.0, "jump": 6.0, "approach": 2.0}
	_check(not bool(SUPPLY_SCRIPT.new().configure([{"craft_id": "ship"}], asymmetric).get("ok", true)), "W8: configure lehnt einen nicht symmetrischen Sprung ab")
	var triangle: Dictionary = _data()
	triangle.leg_fuel_costs["homebase>satellite_crash"] = {"launch": 1.0, "jump": 20.0, "approach": 1.0}
	triangle.leg_fuel_costs["satellite_crash>homebase"] = {"surface_exit": 2.0, "jump": 20.0, "landing": 0.0}
	triangle.route_fuel_costs["homebase>satellite_crash"] = 22.0
	triangle.route_fuel_costs["satellite_crash>homebase"] = 22.0
	_check(not bool(SUPPLY_SCRIPT.new().configure([{"craft_id": "ship"}], triangle).get("ok", true)), "W8: configure lehnt eine verletzte Dreiecksungleichung ab (20 > 7 + 6)")
	var uneven: Dictionary = _data()
	uneven.leg_fuel_costs["homebase>trade_outpost"] = {"launch": 2.0, "jump": 5.0, "approach": 1.0}
	_check(not bool(SUPPLY_SCRIPT.new().configure([{"craft_id": "ship"}], uneven).get("ok", true)), "W8: configure lehnt einen nicht ortsfesten Teil ab (Abheben 2 statt 1)")
# --- 9. Speichern, Laden, Altstaende --------------------------------------------------------------

func _scenario_save_and_load() -> void:
	var supply: Object = SUPPLY_SCRIPT.new()
	supply.configure([{"craft_id": "ship"}], _data())
	var context: Dictionary = {"departure_authorized": true}
	supply.apply_command(_leg_command("ship", "launch", "homebase", "", "t1:save:launch"), context)
	supply.apply_command(_leg_command("ship", "jump", "homebase", "satellite_crash", "t1:save:jump"), context)
	var exported: Dictionary = supply.export_state()
	var from_disk: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(exported)))
	var loaded: Object = SUPPLY_SCRIPT.new()
	loaded.configure([{"craft_id": "ship"}], _data())
	var result: Dictionary = loaded.restore_state(from_disk)
	_check(result.get("ok", false), "9: ein frisch gespeicherter Stand mit Etappenbelegen laedt: " + str(result))
	_check(is_equal_approx(loaded.get_fuel("ship"), 49.0) and loaded.has_request("t1:save:launch") and loaded.has_request("t1:save:jump"), "9: Treibstoff und Belege sind nach dem Laden gleich")
	var replay: Dictionary = loaded.apply_command(_leg_command("ship", "jump", "homebase", "satellite_crash", "t1:save:jump"), context)
	_check(bool(replay.get("replayed", false)) and is_equal_approx(loaded.get_fuel("ship"), 49.0), "9: ein geladener Etappenbeleg bucht beim Wiederholen nicht noch einmal")
	# Stand, wie er vor T1 gespeichert wurde (ohne Etappenblock): muss weiter laden.
	var legacy_state: Dictionary = from_disk.duplicate(true)
	legacy_state.definitions.erase("leg_fuel_costs")
	var legacy_target: Object = SUPPLY_SCRIPT.new()
	legacy_target.configure([{"craft_id": "ship"}], _data())
	var legacy_result: Dictionary = legacy_target.restore_state(legacy_state)
	_check(legacy_result.get("ok", false), "9/5: ein Stand ohne leg_fuel_costs (vor T1 gespeichert) laedt weiter: " + str(legacy_result))
	_check(not Dictionary(legacy_target.get_supply_snapshot().get("leg_fuel_costs", {})).is_empty(), "9/5: nach dem Laden eines Altstands gelten die aktuellen Etappenkosten")
	# Ein gespeicherter Block, der vom aktuellen abweicht, bleibt streng abgelehnt.
	var tampered: Dictionary = from_disk.duplicate(true)
	tampered.definitions.leg_fuel_costs["homebase>trade_outpost"]["approach"] = 99.0
	var tamper_target: Object = SUPPLY_SCRIPT.new()
	tamper_target.configure([{"craft_id": "ship"}], _data())
	_check(String(tamper_target.restore_state(tampered).get("reason", "")) == "stale_supply_definitions", "9/5: ein gespeicherter Etappenblock, der vom aktuellen abweicht, wird weiter streng abgelehnt")
	# Echte Altstaende aus dem Repository (Main 639a49d65 und Staende vom 13.11.).
	for path: String in OLD_FIXTURES:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary or not Dictionary(parsed).has("supply"):
			_check(false, "9/5: Altstand lesbar: " + path)
			continue
		var old_state: Dictionary = Dictionary(Dictionary(parsed).supply)
		_check(not Dictionary(old_state.definitions).has("leg_fuel_costs"), "9/5: Altstand kennt keinen Etappenblock: " + path)
		var target: Object = SUPPLY_SCRIPT.new()
		target.configure([{"craft_id": "ship"}], _data())
		var old_result: Dictionary = target.restore_state(old_state)
		_check(old_result.get("ok", false), "9/5: Altstand laedt weiter: " + path + " -> " + str(old_result))

# --- 2. und 7. Voller Tank: jede Etappe bucht ihren Anteil ----------------------------------------

func _scenario_full_tank_flight() -> void:
	var s: Dictionary = await _session(60.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	_check(is_equal_approx(supply.get_fuel(craft_id), 60.0), "2: Ausgangsstand 60 Treibstoff")
	var launch: Dictionary = _launch(s)
	_check(launch.get("ok", false) and _phase(s) == "orbit", "2: Abheben angenommen, Schiff im Mondorbit: " + str(launch))
	_check(is_equal_approx(supply.get_fuel(craft_id), 59.0), "2: Abheben bucht genau seinen Anteil (60 -> 59), ist %s" % supply.get_fuel(craft_id))
	var site_orbit: String = _site_orbit(s)
	var jump: Dictionary = _jump(s, site_orbit)
	_check(jump.get("ok", false), "2: Quantensprung angenommen: " + str(jump))
	_check(is_equal_approx(supply.get_fuel(craft_id), 49.0), "2: der Sprung bucht genau seinen Anteil (59 -> 49), ist %s" % supply.get_fuel(craft_id))
	var arrived: bool = await _wait_for(s, _arrived(s, site_orbit), 20000)
	_check(arrived, "2: Schiff erreicht den Zielorbit")
	_check(is_equal_approx(supply.get_fuel(craft_id), 49.0), "2: das Ankommen bucht nichts")
	var approach: Dictionary = s.screen.request_operation("space_begin_approach", {"craft_id": craft_id, "location_id": "satellite_crash"})
	_check(approach.get("ok", false), "2: Anflug angenommen: " + str(approach))
	_check(is_equal_approx(supply.get_fuel(craft_id), 48.0), "2: der Anflug bucht genau seinen Anteil (49 -> 48), ist %s" % supply.get_fuel(craft_id))
	_check(is_equal_approx(60.0 - supply.get_fuel(craft_id), 12.0), "2: Summe der gebuchten Etappen == Strecke Heimat -> Satelliten-Absturzstelle (12)")
	await _close(s)

# --- 7. Sprung abbrechen und neu starten: eine Buchung ---------------------------------------------

func _scenario_jump_restart() -> void:
	var s: Dictionary = await _session(60.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	_launch(s)
	var site_orbit: String = _site_orbit(s)
	var jump: Dictionary = _jump(s, site_orbit)
	_check(jump.get("ok", false) and is_equal_approx(supply.get_fuel(craft_id), 49.0), "7: der Sprung ist angenommen und gebucht (49)")
	# Wie im echten Spielablauf: erst ein Stueck fliegen lassen, dann abbrechen.
	await _wait_for(s, func() -> bool: return float(s.runtime.get_space_travel_snapshot(craft_id).get("progress", 0.0)) > 0.05, 3000)
	var aborted: Dictionary = s.screen.request_operation("space_abort_quantum", {"craft_id": craft_id})
	_check(aborted.get("ok", false) and _phase(s) == "stopped", "7: Abbruch haelt das Schiff mitten im All an: " + str(aborted) + " Phase " + _phase(s))
	_check(is_equal_approx(supply.get_fuel(craft_id), 49.0), "7: der Abbruch erstattet nichts zurueck")
	var restart: Dictionary = _jump(s, site_orbit)
	_check(restart.get("ok", false), "7: der Neustart aus stopped ist angenommen: " + str(restart))
	_check(is_equal_approx(supply.get_fuel(craft_id), 49.0), "7: der Neustart kostet die Sprungetappe nicht noch einmal, ist %s" % supply.get_fuel(craft_id))
	var status: Dictionary = s.runtime.get_fuel_status(craft_id)
	_check(not bool(status.get("stranded", true)), "7: ein Schiff mit bezahltem, unvollendetem Sprung ist nicht liegen geblieben")
	var arrived: bool = await _wait_for(s, _arrived(s, site_orbit), 20000)
	_check(arrived and is_equal_approx(supply.get_fuel(craft_id), 49.0), "7: nach der Ankunft bleibt es bei einer Sprungbuchung (49)")
	await _close(s)

# --- Klein 1: Neustart aus stopped zu einem anderen Ziel --------------------------------------------

func _orbit_of(session: Dictionary, location_id: String) -> String:
	return String(Dictionary(session.runtime.get_space_travel_snapshot(session.craft_id).get("location_orbits", {})).get(location_id, ""))

## Startet einen Sprung zu first_orbit, bricht ihn mitten im All ab und gibt den Zustand zurueck (Sitzung offen).
func _stopped_after_jump(initial_fuel: float, first_location: String) -> Dictionary:
	var s: Dictionary = await _session(initial_fuel)
	_launch(s)
	var first_orbit: String = _orbit_of(s, first_location)
	var jump: Dictionary = _jump(s, first_orbit)
	s["first_jump"] = jump
	if jump.get("ok", false):
		await _wait_for(s, func() -> bool: return float(s.runtime.get_space_travel_snapshot(s.craft_id).get("progress", 0.0)) > 0.05, 3000)
		s["aborted"] = s.screen.request_operation("space_abort_quantum", {"craft_id": s.craft_id})
	return s

func _scenario_restart_other_target() -> void:
	# A: erst teuer (Satellit 5), dann billiger (Handelsposten 3): nichts erstattet; zurueck zum Satelliten ist schon bezahlt.
	var a: Dictionary = await _stopped_after_jump(60.0, "satellite_crash")
	var supply_a: Object = a.supply
	_check(_orbit_of(a, "satellite_crash") != _orbit_of(a, "trade_outpost") and not _orbit_of(a, "trade_outpost").is_empty(), "Klein 1/A: Satellit und Handelsposten haben verschiedene Orbits")
	_check(a.first_jump.get("ok", false) and bool(Dictionary(a.get("aborted", {})).get("ok", false)) and _phase(a) == "stopped" and is_equal_approx(supply_a.get_fuel(a.craft_id), 49.0), "Klein 1/A: teurer Sprung bezahlt (49) und abgebrochen: " + str(a.get("aborted", {})))
	var cheaper: Dictionary = _jump(a, _orbit_of(a, "trade_outpost"))
	_check(cheaper.get("ok", false) and is_equal_approx(supply_a.get_fuel(a.craft_id), 49.0), "Klein 1/A: Neustart zum billigeren Ziel ist angenommen, bucht nichts und erstattet nichts (49): " + str(cheaper))
	await _wait_for(a, func() -> bool: return float(a.runtime.get_space_travel_snapshot(a.craft_id).get("progress", 0.0)) > 0.05, 3000)
	a.screen.request_operation("space_abort_quantum", {"craft_id": a.craft_id})
	var back: Dictionary = _jump(a, _orbit_of(a, "satellite_crash"))
	_check(back.get("ok", false) and is_equal_approx(supply_a.get_fuel(a.craft_id), 49.0), "Klein 1/A: zurueck zum teuren Ziel kostet nichts mehr, 10 waren bezahlt (49): " + str(back))
	await _close(a)
	# B: erst billig (3), dann teuer (5): nur die Differenz 2 wird gebucht; gleiches Ziel danach kostenlos.
	var b: Dictionary = await _stopped_after_jump(60.0, "trade_outpost")
	var supply_b: Object = b.supply
	_check(b.first_jump.get("ok", false) and _phase(b) == "stopped" and is_equal_approx(supply_b.get_fuel(b.craft_id), 53.0), "Klein 1/B: billiger Sprung bezahlt (53) und abgebrochen: " + str(b.first_jump))
	var dearer: Dictionary = _jump(b, _orbit_of(b, "satellite_crash"))
	_check(dearer.get("ok", false) and is_equal_approx(supply_b.get_fuel(b.craft_id), 49.0), "Klein 1/B: Neustart zum teureren Ziel bucht nur die Differenz 4 (53 -> 49): " + str(dearer))
	await _wait_for(b, func() -> bool: return float(b.runtime.get_space_travel_snapshot(b.craft_id).get("progress", 0.0)) > 0.05, 3000)
	b.screen.request_operation("space_abort_quantum", {"craft_id": b.craft_id})
	var same: Dictionary = _jump(b, _orbit_of(b, "satellite_crash"))
	_check(same.get("ok", false) and is_equal_approx(supply_b.get_fuel(b.craft_id), 49.0), "Klein 1/B: Neustart zum selben Ziel ist kostenlos (49): " + str(same))
	var arrived: bool = await _wait_for(b, _arrived(b, _orbit_of(b, "satellite_crash")), 20000)
	_check(arrived and is_equal_approx(supply_b.get_fuel(b.craft_id), 49.0), "Klein 1/B: nach der Ankunft insgesamt 11 gebucht, Tank 49")
	await _close(b)
	# C: die Differenz ist nicht gedeckt: abgelehnt, nichts gebucht, das Schiff bleibt angehalten und kann zum bezahlten Ziel zurueck.
	var c: Dictionary = await _stopped_after_jump(8.0, "trade_outpost")
	var supply_c: Object = c.supply
	_check(c.first_jump.get("ok", false) and _phase(c) == "stopped" and is_equal_approx(supply_c.get_fuel(c.craft_id), 1.0), "Klein 1/C: 8 - 1 - 6 = 1 Treibstoff im Stillstand: " + str(c.first_jump))
	var revision_c: int = supply_c.get_revision()
	var rejected: Dictionary = _jump(c, _orbit_of(c, "satellite_crash"))
	_check(not rejected.get("ok", true) and String(rejected.get("reason", "")) == "leg_fuel_insufficient", "Klein 1/C: nicht gedeckte Differenz (2 bei 1) wird abgelehnt: " + str(rejected))
	_check(_phase(c) == "stopped" and is_equal_approx(supply_c.get_fuel(c.craft_id), 1.0) and supply_c.get_revision() == revision_c, "Klein 1/C: abgelehnt heisst nichts gebucht, Phase stopped, _revision gleich")
	var resume: Dictionary = _jump(c, _orbit_of(c, "trade_outpost"))
	_check(resume.get("ok", false) and is_equal_approx(supply_c.get_fuel(c.craft_id), 1.0), "Klein 1/C: das bezahlte Ziel kann weiter kostenlos angeflogen werden: " + str(resume))
	await _close(c)

# --- 4. Tank 0 an der Basis: Abheben wird abgelehnt -------------------------------------------------

func _scenario_launch_without_fuel() -> void:
	var s: Dictionary = await _session(0.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	var status_home: Dictionary = s.runtime.get_fuel_status(craft_id)
	_check(not bool(status_home.get("stranded", true)) and bool(status_home.get("refuel_here", false)), "4: an der Heimatbasis ist man nie liegen geblieben (Tankservice vorhanden)")
	var launch: Dictionary = _launch(s)
	_check(not launch.get("ok", true) and String(launch.get("reason", "")) == "leg_fuel_insufficient", "4: Abheben mit leerem Tank wird abgelehnt (leg_fuel_insufficient): " + str(launch))
	_check(_phase(s) == "grounded" and is_equal_approx(supply.get_fuel(craft_id), 0.0), "4: das Schiff bleibt am Boden, nichts gebucht")
	await _close(s)

# --- 3. Abheben gedeckt, Sprung nicht gedeckt ----------------------------------------------------

func _scenario_jump_without_fuel() -> void:
	var s: Dictionary = await _session(6.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	var launch: Dictionary = _launch(s)
	_check(launch.get("ok", false) and _phase(s) == "orbit" and is_equal_approx(supply.get_fuel(craft_id), 5.0), "3: Abheben wird angenommen und bucht seinen Anteil (6 -> 5)")
	var jump: Dictionary = _jump(s, _site_orbit(s))
	_check(not jump.get("ok", true) and String(jump.get("reason", "")) == "leg_fuel_insufficient", "3: der Sprung wird mit leg_fuel_insufficient abgelehnt: " + str(jump))
	_check(String(jump.get("message", "")).contains("Benötigt 10, vorhanden 5"), "3: die Ablehnung nennt benoetigt/vorhanden: " + String(jump.get("message", "")))
	_check(_phase(s) == "orbit" and is_equal_approx(supply.get_fuel(craft_id), 5.0), "3: abgelehnter Sprung bucht nichts, das Schiff bleibt im Mondorbit")
	var status: Dictionary = s.runtime.get_fuel_status(craft_id)
	_check(not bool(status.get("stranded", true)), "3: im Mondorbit ist die kostenlose Heimlandung eine bezahlbare Folgeetappe, also nicht liegen geblieben")
	var landing_affordable: bool = false
	for leg: Dictionary in Array(status.get("next_legs", [])):
		if String(leg.get("leg", "")) == "landing" and bool(leg.get("affordable", false)): landing_affordable = true
	_check(landing_affordable, "3: get_fuel_status fuehrt die Heimlandung als bezahlbare Folgeetappe")
	await _close(s)

# --- 3. Liegen geblieben im Orbit des Ziels ------------------------------------------------------

func _scenario_stranded_in_orbit() -> void:
	var s: Dictionary = await _session(11.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	_launch(s)
	var site_orbit: String = _site_orbit(s)
	_jump(s, site_orbit)
	var arrived: bool = await _wait_for(s, _arrived(s, site_orbit), 20000)
	_check(arrived and is_equal_approx(supply.get_fuel(craft_id), 0.0), "3: im Zielorbit bleiben 0 Treibstoff (11 - 1 - 10)")
	var status: Dictionary = s.runtime.get_fuel_status(craft_id)
	_check(bool(status.get("stranded", false)) and String(status.get("strand_place", "")) == "orbit" and not bool(status.get("refuel_here", true)), "3: weder Anflug (5) noch Rueckflugsprung (5) sind bezahlbar, hier ist kein Tankservice: liegen geblieben im Orbit: " + str(status))
	var approach: Dictionary = s.screen.request_operation("space_begin_approach", {"craft_id": craft_id, "location_id": "satellite_crash"})
	_check(not approach.get("ok", true) and String(approach.get("reason", "")) == "leg_fuel_insufficient", "3: der Anflug wird abgelehnt: " + str(approach))
	_check(is_equal_approx(supply.get_fuel(craft_id), 0.0) and _phase(s) == "orbit", "3: abgelehnter Anflug bucht nichts")
	await _close(s)

# --- 5. Anflug ohne Reserve --------------------------------------------------------------------

func _scenario_outbound_only_approach() -> void:
	var s: Dictionary = await _session(12.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	var reach: Dictionary = s.runtime.call("_fuel_reachability", craft_id, {"homebase": {}, "satellite_crash": {}, "trade_outpost": {}})
	_check(Dictionary(reach.get("satellite_crash", {})).get("ok", false) and Dictionary(reach.get("satellite_crash", {})).get("route_ok", false), "5: Reichweite zeigt den ganzen Hinweg (12 von 12) als gedeckt, ohne Rueckflugreserve")
	_check(Dictionary(reach.get("trade_outpost", {})).get("route_ok", false), "5: Reichweite Handelsposten (8 von 12) gedeckt")
	_launch(s)
	var site_orbit: String = _site_orbit(s)
	_jump(s, site_orbit)
	var arrived: bool = await _wait_for(s, _arrived(s, site_orbit), 20000)
	_check(arrived and is_equal_approx(supply.get_fuel(craft_id), 1.0), "5: im Zielorbit bleibt genau 1 Treibstoff (12 - 1 - 10)")
	var approach: Dictionary = s.screen.request_operation("space_begin_approach", {"craft_id": craft_id, "location_id": "satellite_crash"})
	_check(approach.get("ok", false), "5: der Anflug wird angenommen, wenn nur der Hinweg bezahlbar ist (keine Rueckflugreserve): " + str(approach))
	_check(is_equal_approx(supply.get_fuel(craft_id), 0.0), "5: nach dem Anflug ist der Tank leer")
	var on_ground: bool = await _wait_for(s, func() -> bool: return _phase(s) == "surface", 90000)
	_check(on_ground, "5: das Schiff setzt am Ort auf (Phase surface), Phase ist " + _phase(s))
	var status: Dictionary = s.runtime.get_fuel_status(craft_id)
	var exit_affordable: bool = true
	for leg: Dictionary in Array(status.get("next_legs", [])):
		if String(leg.get("leg", "")) == "surface_exit": exit_affordable = bool(leg.get("affordable", true))
	_check(on_ground and not exit_affordable, "5: am Ort meldet get_fuel_status den Rueckweg (Ortsabflug) als nicht bezahlbar: " + str(status))
	# Fix-Runde 1, Klein 3: Ohne Tankservice am Ort (hier fehlt die gelandete Mission) rettet auch Geld nicht; refuel_affordable braucht den Service.
	# Der Fall "Tankservice vorhanden, Credits reichen nicht" mit echtem Dienst am Ort steht in tanker_result_fuel_verifier (Haltepunkt am Absturzort).
	var credits_before: int = int(supply.get_credits())
	supply.set("_credits", 100000)
	var rich: Dictionary = s.runtime.get_fuel_status(craft_id)
	_check(on_ground and not bool(rich.get("refuel_here", true)) and not bool(rich.get("refuel_affordable", true)) and bool(rich.get("stranded", false)), "Klein 3: ohne Tankservice am Ort hilft Geld nicht: refuel_affordable=false, liegen geblieben: " + str(rich))
	supply.set("_credits", credits_before)
	# Fix-Runde 1, Klein 4: _remaining_outbound_legs zeigt am Ort die wirklich offenen Etappen, im Anflug keine.
	var surface_travel: Dictionary = s.runtime.get_space_travel_snapshot(craft_id)
	var open_legs: Array = s.runtime.call("_remaining_outbound_legs", surface_travel, "trade_outpost")
	var open_names: Array = []
	for open_leg: Dictionary in open_legs: open_names.append("%s:%s>%s" % [open_leg.leg, open_leg.origin, open_leg.destination])
	_check(on_ground and open_names == ["surface_exit:satellite_crash>homebase", "jump:satellite_crash>trade_outpost", "approach:homebase>trade_outpost"], "Klein 4: am Ort offen sind Ortsabflug, Sprung und Anflug zum anderen Ziel: " + str(open_names))
	_check(on_ground and Array(s.runtime.call("_remaining_outbound_legs", surface_travel, "satellite_crash")).is_empty(), "Klein 4: am Zielort selbst ist nichts mehr offen")
	_check(Array(s.runtime.call("_remaining_outbound_legs", {"phase": "approach", "location_id": "satellite_crash"}, "satellite_crash")).is_empty(), "Klein 4: im Anflug ist nichts mehr offen")
	var surface_check: Dictionary = s.runtime.call("_outbound_fuel_check", craft_id, "trade_outpost", surface_travel)
	_check(on_ground and is_equal_approx(float(surface_check.get("needed_total", -1.0)), 10.0) and not bool(surface_check.get("ok", true)), "Klein 4: Ort -> Ort braucht insgesamt 10 und ist ohne Treibstoff nicht gedeckt: " + str(surface_check))
	# 8 und 10 (Flow-Ebene): der Rueckzug ("Abheben" am HUD) nutzt dieselbe Vorpruefung, bleibt lesend und lehnt mit dem Treibstoffgrund ab.
	var before_fuel: float = supply.get_fuel(craft_id)
	var revision: int = supply.get_revision()
	var preflight: Dictionary = s.flow.call("_departure_return_preflight", craft_id)
	_check(not bool(preflight.get("ok", true)) and String(preflight.get("reason", "")) in ["leg_fuel_insufficient", "insufficient_fuel", "insufficient_return_fuel"], "10: die Vorpruefung des HUD-Rueckzugs lehnt ohne Treibstoff fuer den Ortsabflug ab: " + str(preflight))
	_check(is_equal_approx(supply.get_fuel(craft_id), before_fuel) and supply.get_revision() == revision, "10: die Vorpruefung bucht nichts und aendert _revision nicht")
	_check(_phase(s) == "surface", "8: nach der Ablehnung bleibt das Schiff am Ort (Phase surface)")
	await _close(s)

# --- 10. Rueckzug mit gedecktem Ortsabflug ---------------------------------------------------------

func _scenario_return_preflight_covered() -> void:
	var s: Dictionary = await _session(19.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	_launch(s)
	var site_orbit: String = _site_orbit(s)
	_jump(s, site_orbit)
	await _wait_for(s, _arrived(s, site_orbit), 20000)
	s.screen.request_operation("space_begin_approach", {"craft_id": craft_id, "location_id": "satellite_crash"})
	var on_ground: bool = await _wait_for(s, func() -> bool: return _phase(s) == "surface", 90000)
	_check(on_ground and is_equal_approx(supply.get_fuel(craft_id), 7.0), "10: 19 - 1 - 10 - 1 = 7 Treibstoff am Ort, der Ortsabflug kostet 2")
	var revision: int = supply.get_revision()
	var preflight: Dictionary = s.flow.call("_departure_return_preflight", craft_id)
	_check(bool(preflight.get("ok", false)), "10: die Vorpruefung des HUD-Rueckzugs laesst zu, wenn der Ortsabflug gedeckt ist: " + str(preflight))
	_check(is_equal_approx(supply.get_fuel(craft_id), 7.0) and supply.get_revision() == revision, "10: die Vorpruefung bleibt lesend (Treibstoff und _revision gleich)")
	await _close(s)
