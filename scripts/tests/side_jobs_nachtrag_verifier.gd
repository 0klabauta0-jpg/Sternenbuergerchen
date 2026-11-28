extends SceneTree
## Nebenauftraege, Nacharbeit R1 (28.11.2026): Gegenstandskennungen, Meldung aus dem wirklich Gebuchten, Rekrutennamen,
## Sperrzeit grau sichtbar (Tafel), Daten der vier Szenarien (Karte, Marker, Handel) und der Kurierfahrten.
## Keine Szene, kein Einsatz. Abschlusszeile: SIDE_JOBS_NACHTRAG passed=%d failed=%d
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const INVENTORY = preload("res://scripts/mission/inventory_transfer_contract.gd")
const PRESENTER = preload("res://scripts/meta/singleplayer_job_board_presenter.gd")
const LABELS = preload("res://scripts/ui/components/personnel_inventory_panel.gd")
const SIDE_IDS: Array = ["side_relay_silence", "side_farm_night_watch", "side_lab_cold_samples", "side_templer_volunteer"]
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _run() -> void:
	_case_items()
	_case_message_and_names()
	_case_board_waiting()
	_case_scenario_data()
	_case_courier()
	print("SIDE_JOBS_NACHTRAG passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ---------- Gegenstandskennungen ----------

func _case_items() -> void:
	var data: Dictionary = _json("res://data/singleplayer/side_jobs.json")
	var bad := ""
	for id in data.jobs:
		for entry in Array(data.jobs[id].get("reward", {}).get("items", [])):
			if not INVENTORY.known(String(Dictionary(entry).get("item_id", ""))): bad += String(id) + ":" + String(Dictionary(entry).get("item_id", "")) + " "
	_check(bad.is_empty(), "side_jobs.json: alle Belohnungsgegenstaende dem Lager bekannt (unbekannt: %s)" % bad)
	_check(INVENTORY.known("rocket_launcher") and INVENTORY.known("ammo_rocket") and INVENTORY.known("armor_light"), "rocket_launcher, ammo_rocket, armor_light sind bekannte Lagergegenstaende")
	_check(String(LABELS.LABELS.get("rocket_launcher", "")) == "Raketenwerfer" and String(LABELS.LABELS.get("ammo_rocket", "")) == "Rakete", "Anzeigenamen fuer Raketenwerfer und Rakete vorhanden")
	var real: RefCounted = CAMPAIGN.new()
	_check(bool(real.configure().get("ok", false)), "Echte Daten laden mit Gegenstandspruefung")
	var defs := {"factions": {"labor": "Labor"}, "jobs": {"x": {"id": "x", "title": "X", "description": "", "location_id": "relay_ridge", "scenario_id": "x", "required_step_ids": ["s1"], "faction": "labor", "reward": {"credits": 1, "items": [{"item_id": "gibt_es_nicht", "quantity": 1}]}}}}
	var strict: RefCounted = CAMPAIGN.new()
	var verdict: Dictionary = strict.configure({}, {}, true, defs)
	_check(not bool(verdict.get("ok", true)) and String(verdict.get("reason", "")) == "invalid_side_job", "Eigene Definition mit unbekanntem Gegenstand wird abgelehnt (%s)" % str(verdict.get("reason", "")))
	defs.jobs.x.reward.items = [{"item_id": "rocket_launcher", "quantity": 1}]
	_check(bool(CAMPAIGN.new().configure({}, {}, true, defs).get("ok", false)), "Dieselbe Definition mit rocket_launcher wird angenommen")

# ---------- Meldung und Rekrutennamen ----------

func _case_message_and_names() -> void:
	var receipt := {"completion_id": "side_templer_volunteer:completed:2", "job_id": "side_templer_volunteer", "scenario_id": "x", "runtime_verified": true, "side": true,
		"reward": {"credits": 60, "items": [{"item_id": "rocket_launcher", "quantity": 1}], "recruits": 1, "reputation": {"templer": 5, "labor": -2}}}
	var labels: Dictionary = LABELS.LABELS
	var factions := {"templer": "Templer", "labor": "Shady Lab"}
	var booked: String = SUPPLY.side_job_message(receipt, {"side_items_booked": [{"item_id": "rocket_launcher", "quantity": 1}], "side_items_pending": []}, labels, factions)
	_check(booked.begins_with("Nebenauftrag erledigt: ") and booked.contains("+60 Cr") and booked.contains("Raketenwerfer") and not booked.contains("Lager voll"), "Meldung mit gebuchtem Gegenstand: '%s'" % booked)
	var pending: String = SUPPLY.side_job_message(receipt, {"side_items_booked": [], "side_items_pending": [{"item_id": "rocket_launcher", "quantity": 1}]}, labels, factions)
	_check(pending.contains("Lager voll – Raketenwerfer liegt bereit"), "Meldung bei vollem Lager nennt das Ausstehende: '%s'" % pending)
	_check(not pending.contains("Raketenwerfer ·") or pending.contains("Lager voll"), "Ausstehender Gegenstand steht nicht zugleich als gebucht da")
	var name_a: String = SUPPLY.side_recruit_name("side_templer_volunteer", 2, 1)
	_check(booked.contains(name_a + " trifft bei der Heimlandung ein") and booked.contains("Ruf Templer +5") and booked.contains("Ruf Shady Lab −2"), "Meldung: eigener Name, Hinweis Heimlandung, Ruf beider Fraktionen")
	_check(name_a == SUPPLY.side_recruit_name("side_templer_volunteer", 2, 1) and not name_a.is_empty(), "Rekrutenname ist stabil")
	var names := {}
	for n in range(1, 9): names[SUPPLY.side_recruit_name("side_templer_volunteer", n, 1)] = true
	_check(names.size() >= 4, "Rekrutennamen wechseln von Ausfuehrung zu Ausfuehrung (%d verschiedene bei 8)" % names.size())
	_check(SUPPLY.side_recruit_unit_id("side_templer_volunteer", 2, 1) == "side_templer_volunteer_2_1", "Rekruten-Kennung wie im Kader-Pruefer erwartet")
	# Lager voll beim Oeffnen: Hinweis, dann nachliefern.
	var owner: RefCounted = SUPPLY.new()
	_check(owner.side_items_notice_on_open(labels).is_empty(), "Lager oeffnen ohne Ausstehendes: kein Hinweis")

# ---------- Tafel: Sperrzeit grau ----------

func _case_board_waiting() -> void:
	var board = PRESENTER.new()
	var job := {"id": "side_relay_silence", "status": "cooldown", "completions": 2}
	var waiting_text: String = board._side_state_text(job, {"waiting": true, "wait_landings": 3})
	_check(waiting_text.begins_with("Wieder verfügbar in 3 Heimlandungen") and waiting_text.contains("Schon 2× erledigt"), "Tafel: Sperrzeit 'Wieder verfügbar in 3 Heimlandungen' (%s)" % waiting_text.replace("\n", " | "))
	var one_text: String = board._side_state_text(job, {"waiting": true, "wait_landings": 1})
	_check(one_text.begins_with("Wieder verfügbar in 1 Heimlandung") and not one_text.begins_with("Wieder verfügbar in 1 Heimlandungen"), "Tafel: Einzahl 'in 1 Heimlandung'")
	var src := FileAccess.get_file_as_string("res://scripts/meta/singleplayer_job_board_presenter.gd")
	_check(src.contains("\"Auftrag abgeben\" if side_selected"), "Tafel: Knopf heisst bei Nebenauftraegen 'Auftrag abgeben'")
	board.free()

# ---------- Daten der vier Szenarien ----------

func _case_scenario_data() -> void:
	var locations: Dictionary = _json("res://data/singleplayer/locations.json")
	var jobs: Dictionary = _json("res://data/singleplayer/side_jobs.json").jobs
	var small: Dictionary = _json("res://data/singleplayer/small_outposts.json")
	var map_text := {}
	for id in SIDE_IDS:
		var job: Dictionary = jobs[id]
		var scenario: Dictionary = _json("res://data/mission_scenarios/%s.json" % id)
		var location: Dictionary = locations[String(job.location_id)]
		_check(String(scenario.get("map_file_path", "")) == String(location.get("map_file_path", "?")), "%s: gleiche Karte wie der Ort (%s)" % [id, String(scenario.get("map_file_path", ""))])
		var path := String(scenario.map_file_path)
		if not map_text.has(path): map_text[path] = FileAccess.get_file_as_string(path)
		var missing := ""
		var markers: Array = []
		for point in Array(scenario.vertical_slice.interaction_points): markers.append(String(point.marker_id))
		for group in Array(scenario.get("enemy_groups", [])): markers.append(String(group.spawn_marker_id))
		for slot in Array(scenario.vertical_slice.team_slots): markers.append(String(slot.spawn_marker_id))
		for marker in markers:
			if not String(map_text[path]).contains("\"%s\"" % marker): missing += marker + " "
		_check(missing.is_empty(), "%s: alle Marker stehen auf der Karte (fehlt: %s)" % [id, missing])
		# Pflichtschritte des Auftrags gibt es als Ablaufschritte.
		var steps: Array = []
		for step in Array(scenario.vertical_slice.flow_steps): steps.append(String(step.step_id))
		var unknown_step := ""
		for step_id in Array(job.required_step_ids):
			if not steps.has(String(step_id)): unknown_step += String(step_id) + " "
		_check(unknown_step.is_empty(), "%s: Pflichtschritte kommen im Szenario vor (fehlt: %s)" % [id, unknown_step])
		# Haendlermarker: vom Ort aus small_outposts.json (kleine Posten oder Besuchs-Handelsmarker) steht auf derselben Karte.
		var entry: Dictionary = Dictionary(Dictionary(small.get("locations", {})).get(String(job.location_id), Dictionary(small.get("visit_trade_markers", {})).get(String(job.location_id), {})))
		_check(not entry.is_empty() and String(map_text[path]).contains("\"%s\"" % String(entry.get("service_marker_id", "?"))), "%s: Handelsmarker '%s' steht auf der Karte" % [id, String(entry.get("service_marker_id", ""))])
		# Rueckflug: wie bei den Kampagnenauftraegen ein Wechselwirkungsschritt (interaction_use), kein location_return.
		var last_type := ""
		for step in Array(scenario.vertical_slice.flow_steps):
			if String(step.step_id) == "return_to_ship": last_type = String(step.get("objective_type", ""))
		_check(last_type == "interaction_use", "%s: Rueckflugschritt return_to_ship (interaction_use) wie bei den Kampagnenauftraegen" % id)

# ---------- Kurierfahrten ----------

func _case_courier() -> void:
	var orders: Array = _json("res://data/singleplayer/standing_orders.json").orders
	var locations: Dictionary = _json("res://data/singleplayer/locations.json")
	var wanted := {"freight:muellers_farm:heilkraeuter": ["muellers_farm", "templanon", "heilkraeuter"], "freight:shady_lab:duenger": ["shady_lab", "muellers_farm", "duenger"], "freight:templanon:aufputschmittel": ["templanon", "shady_lab", "aufputschmittel"]}
	for id in wanted:
		var found := {}
		for order in orders:
			if String(Dictionary(order).get("id", "")) == String(id): found = order
		_check(not found.is_empty() and String(found.origin) == wanted[id][0] and String(found.destination) == wanted[id][1] and String(found.item) == wanted[id][2] and int(found.crates) == 4 and int(found.pay) > 0, "Kurierfahrt %s steht in standing_orders.json" % id)
		_check(Array(locations[wanted[id][0]].services).has("trade") and Array(locations[wanted[id][1]].services).has("trade"), "Kurierfahrt %s: Start und Ziel haben Handel (Kisten kommen mit der Annahme beim Haendler)" % id)
		_check(INVENTORY.known(String(wanted[id][2])), "Kurierfahrt %s: Ware ist ein bekannter Gegenstand" % id)
