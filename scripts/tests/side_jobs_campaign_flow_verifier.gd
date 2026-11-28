extends SceneTree
## Nebenauftraege N1, Teil 2b: der ECHTE Spielweg ueber Meta-Szene, Adapter und Kampagnenstand (ohne Flug und ohne Kampf).
## Aufbau nach playtest_l01_upload_active_job_verifier (Kampagne starten, Annehmen ueber den Bildschirm, Abflug binden und aktivieren
## ueber den Befehlsweg des Adapters, Hochladen), campaign_retreat_keeps_job_open_verifier (Zielwahl, Bindung, Aktivieren) und
## campaign_intro_loop_smoke (Heim-Speicherpunkt per save_home_checkpoint, STORE.load_checkpoint, "continue" in eine frische Meta-Szene).
## Einsatzende: record_mission_result(result, {craft_id, job_id, scenario_id}) mit Laufzeitbeleg (mission_scenario_runtime_gates) - das ist der
## Weg, den der Einsatz am Ende selbst nimmt; der Kampf wird nicht gespielt.
## Vorgaenger: satellite_recovery ueber Annehmen, Abflug, Aktivieren, Chip ins Lager, Hochladen (campaign_upload, wie l01);
## outpost_recovery ueber die Befehle complete_job und apply_reward des Adapters (_commit), ohne Frachtkiste.
## Abschlusszeile: SIDE_JOBS_CAMPAIGN_FLOW passed=%d failed=%d
const START = preload("res://scripts/meta/game_start_contract.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const FLOW: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const SIDE_PATH := "res://data/singleplayer/side_jobs.json"
const SIDE_IDS: Array = ["side_relay_silence", "side_farm_night_watch", "side_lab_cold_samples", "side_templer_volunteer"]
var passed := 0
var failed := 0
var _seq := 0
var _flow: Node
var _screen: Node
var _runtime: Node
var _craft := ""
var _rewards: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> bool:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)
	return value

# ---------------------------------------------------------------- Hilfen

func _open(mode: String) -> bool:
	root.size = Vector2i(1280, 720)
	START.request_start(self, "campaign", mode)
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	for i in 24:
		await process_frame
	_screen = _flow.get_node_or_null("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	var crafts: Array = Array(_flow.get("_homebase_aircraft_definitions"))
	_craft = String(Dictionary(crafts[0]).get("craft_id", "")) if not crafts.is_empty() else ""
	return _check(_screen != null and _runtime != null and not _craft.is_empty() and _runtime.get("_campaign") != null, "Kampagne '%s': Meta-Szene, Adapter, Kampagnenstand und Schiff stehen" % mode)

func _close() -> void:
	if _flow != null and is_instance_valid(_flow):
		_flow.queue_free()
	current_scene = null
	for i in 4:
		await process_frame

func _campaign() -> RefCounted:
	return _runtime.get("_campaign")

func _snap() -> Dictionary:
	return Dictionary(_runtime.call("get_snapshot")).get("campaign", {})

func _job(id: String) -> Dictionary:
	return Dictionary(Dictionary(_snap().get("jobs", {})).get(id, {}))

func _avail(id: String) -> Dictionary:
	return Dictionary(Dictionary(_snap().get("job_availability", {})).get(id, {}))

func _status(id: String) -> String:
	return String(_job(id).get("status", ""))

func _rep(faction: String) -> int:
	return int(Dictionary(_snap().get("reputation", {})).get(faction, 0))

func _credits() -> int:
	return int(_runtime.call("get_campaign_credits"))

func _base_items(item_id: String) -> int:
	var supply: RefCounted = _runtime.get("_supply")
	var inventory: Dictionary = Dictionary(supply.get_supply_snapshot().get("inventory", {}))
	return int(Dictionary(Dictionary(inventory.get("base:homebase", {})).get("items", {})).get(item_id, 0))

func _roster_count(unit_id: String) -> int:
	var count := 0
	for unit: Variant in Array(_flow.get("_all_team_units")):
		if String(Dictionary(unit).get("unit_id", "")) == unit_id: count += 1
	return count

func _roster_unit(unit_id: String) -> Dictionary:
	for unit: Variant in Array(_flow.get("_all_team_units")):
		if String(Dictionary(unit).get("unit_id", "")) == unit_id: return Dictionary(unit)
	return {}

func _cmd(operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	_seq += 1
	return _runtime.call("_commit", "singleplayer_campaign", operation, payload, "sjf:%d" % _seq, context)

func _landing() -> Dictionary:
	return Dictionary(_runtime.call("record_home_landing"))

## Annehmen (ueber den Bildschirm wie die Spieloberflaeche), Ziel waehlen, Abflug binden, aktivieren. Neue Abflugkennung je Lauf.
func _start(id: String) -> bool:
	var job: Dictionary = _job(id)
	var accepted: Dictionary = _screen.call("request_operation", "accept_job", {"job_id": id})
	var ok: bool = _check(bool(accepted.get("ok", false)), "%s: annehmen ueber den Bildschirm (%s)" % [id, str(accepted.get("reason", ""))])
	var selected: Dictionary = _screen.call("request_operation", "select_destination", {"location_id": String(job.get("location_id", "")), "job_id": id})
	ok = _check(bool(selected.get("ok", false)) and String(_flow.get("_selected_mission_id")) == String(job.get("scenario_id", "?")), "%s: Ziel gewaehlt, geladen wird das Szenario des Nebenauftrags (%s)" % [id, str(_flow.get("_selected_mission_id"))]) and ok
	var tokens: Dictionary = _runtime.get("_departure_token_by_craft")
	tokens[_craft] = "sjf-token-%d" % (_seq + 1)
	var departure := {"craft_id": _craft, "origin_location_id": "homebase", "destination_location_id": String(job.get("location_id", "")), "landing_pad_id": "homebase_pad_01", "job_id": id}
	var bound: Dictionary = _cmd("bind_departure", departure, {"departure_authorized": true})
	var active: Dictionary = _cmd("activate_job", {"job_id": id, "craft_id": _craft}, {"departure_authorized": true})
	return _check(bool(bound.get("ok", false)) and bool(active.get("ok", false)) and _status(id) == "active", "%s: Abflug gebunden und aktiv (%s %s)" % [id, str(bound.get("reason", "")), str(active.get("reason", ""))]) and ok

## Einsatzende mit Sieg und allen Pflichtschritten ueber den Adapter. Gibt das Ergebnis zurueck (traegt side_job_message).
func _finish_mission(id: String, steps: Array = []) -> Dictionary:
	var job: Dictionary = _job(id)
	var done: Array = steps if not steps.is_empty() else Array(job.get("required_step_ids", []))
	var result := {"result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": done}}
	_runtime.call("record_mission_result", result, {"craft_id": _craft, "job_id": id, "scenario_id": String(job.get("scenario_id", ""))})
	return result

## Ein Nebenauftrag ganz durch; prueft Credits, Ruf, Gegenstaende, Meldung gegen die Belohnung aus side_jobs.json.
func _play_side(id: String, completion_number: int) -> Dictionary:
	var reward: Dictionary = Dictionary(_rewards[id].get("reward", {}))
	var credits_before := _credits()
	var rep_before := {}
	for faction: Variant in Dictionary(_snap().get("reputation", {})): rep_before[faction] = _rep(String(faction))
	var items_before := {}
	for entry: Variant in Array(reward.get("items", [])): items_before[String(Dictionary(entry).item_id)] = _base_items(String(Dictionary(entry).item_id))
	_start(id)
	var result: Dictionary = _finish_mission(id)
	var tag := "%s (Lauf %d)" % [id, completion_number]
	_check(int(_job(id).get("completions", 0)) == completion_number and _status(id) == "cooldown", "%s: Einsatzende bucht den Abschluss, Zustand cooldown, completions %d" % [tag, completion_number])
	_check(not Dictionary(Dictionary(_snap().get("completion_receipts", {})).get("%s:completed:%d" % [id, completion_number], {})).is_empty(), "%s: Beleg %s:completed:%d liegt vor" % [tag, id, completion_number])
	_check(_credits() == credits_before + int(reward.get("credits", 0)), "%s: Credits +%d (vorher %d, jetzt %d)" % [tag, int(reward.get("credits", 0)), credits_before, _credits()])
	var rep_ok := true
	for faction: Variant in Dictionary(reward.get("reputation", {})):
		var expected: int = clampi(int(rep_before.get(faction, 0)) + int(reward.reputation[faction]), -100, 100)
		rep_ok = rep_ok and _rep(String(faction)) == expected
	_check(rep_ok, "%s: Ruf im Kampagnenstand wie reward.reputation" % tag)
	var items_ok := true
	for item_id: Variant in items_before:
		var wanted := 0
		for entry: Variant in Array(reward.get("items", [])):
			if String(Dictionary(entry).item_id) == String(item_id): wanted += int(Dictionary(entry).quantity)
		items_ok = items_ok and _base_items(String(item_id)) == int(items_before[item_id]) + wanted
	_check(items_ok, "%s: Gegenstaende der Belohnung liegen im Basislager (genau +Menge)" % tag)
	_check(String(result.get("side_job_message", "")).contains("Nebenauftrag erledigt"), "%s: Meldung '%s'" % [tag, String(result.get("side_job_message", ""))])
	return result

# ---------------------------------------------------------------- Ablauf

func _finish() -> void:
	await _close()
	print("SIDE_JOBS_CAMPAIGN_FLOW passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SIDE_PATH))
	_rewards = Dictionary(Dictionary(parsed).get("jobs", {})) if typeof(parsed) == TYPE_DICTIONARY else {}
	if not _check(_rewards.size() == 4, "side_jobs.json: vier Nebenauftraege"):
		await _finish()
		return
	if not await _open("new"):
		await _finish()
		return
	_case_visibility_chain_start()
	_prepare_satellite()
	if not _case_templer():
		await _finish()
		return
	if not await _case_checkpoint_one():
		await _finish()
		return
	await _case_farm_and_trade()
	await _case_checkpoint_two()
	await _finish()

# 1: Sichtbarkeit nach dem Vorgaenger -----------------------------------------------------------

func _case_visibility_chain_start() -> void:
	var snap: Dictionary = _snap()
	var all_side := true
	for id: String in SIDE_IDS:
		all_side = all_side and Dictionary(snap.get("jobs", {})).has(id) and bool(_job(id).get("side", false)) and String(_job(id).get("faction", "")) != ""
	_check(all_side, "Adapter-Schnappschuss: vier Nebenauftraege mit side=true und Fraktion in campaign.jobs")
	var hidden := true
	for id: String in SIDE_IDS:
		hidden = hidden and Dictionary(Dictionary(snap.get("job_availability", {})).get(id, {})).has("side") and bool(_avail(id).get("side", false)) and not bool(_avail(id).get("visible", true)) and not bool(_avail(id).get("can_accept", true))
	_check(hidden, "job_availability: alle vier mit side=true, vor ihrem Vorgaenger unsichtbar und nicht annehmbar")
	_check(int(snap.get("home_landings", -1)) == 0 and Dictionary(snap.get("factions", {})).size() == 4, "Kampagnenstart: home_landings 0, vier Fraktionen im Schnappschuss")
	var refused: Dictionary = _screen.call("request_operation", "accept_job", {"job_id": "side_templer_volunteer"})
	_check(not bool(refused.get("ok", true)) and _status("side_templer_volunteer") == "offered", "Annehmen vor dem Vorgaenger wird ueber den Bildschirm abgelehnt")

## satellite_recovery ueber den echten Weg (wie l01): annehmen, Abflug, aktivieren, Chip ins Lager, Hochladen.
func _prepare_satellite() -> void:
	var started: bool = _start_campaign_job("satellite_recovery")
	var grant: Dictionary = _runtime.call("_commit", "singleplayer_supply", "campaign_cargo", {"container_id": "base:homebase", "item_id": "satellite_chip", "amount": 1}, "sjf:chip", {"campaign_authorized": true})
	var upload: Dictionary = _runtime.call("request_operation", "campaign_upload", {"job_id": "satellite_recovery"})
	_check(started and bool(grant.get("ok", false)) and bool(upload.get("ok", false)) and _status("satellite_recovery") == "completed", "Vorgaenger satellite_recovery ueber den echten Weg (annehmen, aktivieren, Chip, Hochladen) abgeschlossen")
	_check(bool(_avail("side_templer_volunteer").get("visible", false)) and bool(_avail("side_templer_volunteer").get("can_accept", false)), "Nach satellite_recovery: Freiwilliger sichtbar und annehmbar")
	_check(not bool(_avail("side_relay_silence").get("visible", true)) and not bool(_avail("side_farm_night_watch").get("visible", true)) and not bool(_avail("side_lab_cold_samples").get("visible", true)), "Nach satellite_recovery: Funkstille, Nachtwache und Proben noch unsichtbar (Vorgaenger fehlen)")

func _start_campaign_job(id: String) -> bool:
	var job: Dictionary = _job(id)
	var accepted: Dictionary = _screen.call("request_operation", "accept_job", {"job_id": id})
	var selected: Dictionary = _screen.call("request_operation", "select_destination", {"location_id": String(job.get("location_id", "")), "job_id": id})
	var tokens: Dictionary = _runtime.get("_departure_token_by_craft")
	tokens[_craft] = "sjf-token-campaign-%s" % id
	var departure := {"craft_id": _craft, "origin_location_id": "homebase", "destination_location_id": String(job.get("location_id", "")), "landing_pad_id": "homebase_pad_01", "job_id": id}
	var bound: Dictionary = _cmd("bind_departure", departure, {"departure_authorized": true})
	var active: Dictionary = _cmd("activate_job", {"job_id": id, "craft_id": _craft}, {"departure_authorized": true})
	return bool(accepted.get("ok", false)) and bool(selected.get("ok", false)) and bool(bound.get("ok", false)) and bool(active.get("ok", false)) and _status(id) == "active"

# 2 und 3 und 4: Freiwilliger (Rekrut), Heimlandung, Abklingzeit --------------------------------

func _case_templer() -> bool:
	var id := "side_templer_volunteer"
	var recruit_1 := "side_templer_volunteer_1_1"
	var recruit_2 := "side_templer_volunteer_2_1"
	var roster_before: int = Array(_flow.get("_all_team_units")).size()
	_play_side(id, 1)
	_check(_roster_count(recruit_1) == 0, "Freiwilliger: vor der Heimlandung ist der Rekrut noch nicht im Kader")
	# Echter Heimlandungsweg der Meta-Szene (zaehlt, holt Gegenstaende und Rekruten nach).
	var landings_before: int = int(_snap().get("home_landings", 0))
	_flow.call("_finish_space_home_landing", _craft)
	_check(int(_snap().get("home_landings", -1)) == landings_before + 1, "Heimlandung ueber _finish_space_home_landing: home_landings +1")
	var unit: Dictionary = _roster_unit(recruit_1)
	_check(_roster_count(recruit_1) == 1 and not String(unit.get("display_name", "")).is_empty() and Array(_flow.get("_all_team_units")).size() == roster_before + 1, "Rekrut %s steht nach der Heimlandung genau einmal mit Namen im Kader (%s)" % [recruit_1, String(unit.get("display_name", ""))])
	var simulation: Node = _runtime.get("_simulation")
	_check(simulation != null and bool(simulation.call("get_personnel_loadout_state").call("has_unit", recruit_1)), "Rekrut hat einen Ausruestungseintrag (Loadout-Stand)")
	var again: Dictionary = _landing()
	_check(bool(again.get("ok", false)) and Array(again.get("recruits", ["x"])).is_empty() and _roster_count(recruit_1) == 1 and Array(_flow.get("_all_team_units")).size() == roster_before + 1, "Zweite Heimlandung (record_home_landing) legt den Rekruten nicht doppelt an")
	# Abklingzeit: cooldown_landings 4, bisher 2 Landungen.
	_check(_status(id) == "cooldown" and not bool(_avail(id).get("visible", true)) and not bool(_avail(id).get("can_accept", true)), "Abklingzeit: nach 2 Landungen ist der Auftrag nicht annehmbar")
	var refused: Dictionary = _screen.call("request_operation", "accept_job", {"job_id": id})
	_check(not bool(refused.get("ok", true)), "Abklingzeit: Annehmen ueber den Bildschirm wird abgelehnt")
	_landing()
	_check(int(_snap().get("home_landings", 0)) == 3 and _status(id) == "cooldown" and not bool(_avail(id).get("can_accept", true)), "Abklingzeit: nach 3 Heimlandungen (cooldown_landings 4) noch nicht annehmbar")
	_landing()
	_check(int(_snap().get("home_landings", 0)) == 4 and _status(id) == "offered" and bool(_avail(id).get("can_accept", false)), "Abklingzeit: nach cooldown_landings (4) Heimlandungen wieder angeboten und annehmbar (home_landings %d)" % int(_snap().get("home_landings", 0)))
	var credits_before := _credits()
	_play_side(id, 2)
	_check(_credits() == credits_before + 60 and int(_job(id).get("completions", 0)) == 2, "Zweiter Abschluss bucht erneut 60 Credits, completions 2")
	_landing()
	_check(_roster_count(recruit_2) == 1 and _roster_count(recruit_1) == 1, "Zweiter Rekrut %s steht nach der Landung im Kader, der erste weiter nur einmal" % recruit_2)
	# Rekrut-Deckung durch den Beleg (reine Regel des Speicherpunkts).
	var receipts: Dictionary = Dictionary(_snap().get("completion_receipts", {}))
	_check(STORE._side_recruit_backed(recruit_1, receipts) and STORE._side_recruit_backed(recruit_2, receipts) and not STORE._side_recruit_backed("side_templer_volunteer_3_1", receipts) and not STORE._side_recruit_backed("side_templer_volunteer_1_2", receipts), "Speicherpunkt-Regel: Rekruten 1_1 und 2_1 durch Belege gedeckt, 3_1 und 1_2 nicht")
	return true

# 5a: Speicherpunkt nach dem Freiwilligen ---------------------------------------------------------

var _expect_rep_templer := 0
var _expect_rep_labor := 0
var _expect_landings := 0
var _expect_credits := 0

func _case_checkpoint_one() -> bool:
	_expect_rep_templer = _rep("templer")
	_expect_rep_labor = _rep("labor")
	_expect_landings = int(_snap().get("home_landings", 0))
	_expect_credits = _credits()
	_check(_expect_rep_templer == 10 and _expect_rep_labor == -4, "Ruf nach zwei Freiwilligen: Templer 10, Labor -4")
	var exported: Dictionary = _runtime.call("export_campaign_checkpoint")
	_check(not exported.is_empty() and Dictionary(exported.get("campaign", {})).has("home_landings") and Dictionary(exported.get("campaign", {})).has("reputation"), "export_campaign_checkpoint liefert den Stand mit home_landings und reputation")
	var saved: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	if not _check(bool(saved.get("ok", false)), "Heim-Speicherpunkt wird geschrieben (%s)" % str(saved.get("reason", ""))):
		return false
	var loaded: Dictionary = STORE.load_checkpoint()
	if not _check(bool(loaded.get("ok", false)), "Gespeicherter Stand besteht validate_payload (%s)" % str(loaded.get("reason", ""))):
		return false
	var payload: Dictionary = Dictionary(loaded.get("payload", {}))
	_check(bool(STORE.validate_payload(payload).get("ok", false)) and Array(payload.get("roster", [])).size() >= 4, "validate_payload ok mit den zwei Rekruten im Kader (%d Personen im Stand)" % Array(payload.get("roster", [])).size())
	await _close()
	if not await _open("continue"):
		return false
	_check(_rep("templer") == _expect_rep_templer and _rep("labor") == _expect_rep_labor, "Nach dem Laden: Ruf Templer %d und Labor %d erhalten" % [_expect_rep_templer, _expect_rep_labor])
	_check(int(_snap().get("home_landings", -1)) == _expect_landings and int(_job("side_templer_volunteer").get("completions", 0)) == 2, "Nach dem Laden: home_landings %d und completions 2 erhalten" % _expect_landings)
	_check(_roster_count("side_templer_volunteer_1_1") == 1 and _roster_count("side_templer_volunteer_2_1") == 1 and not String(_roster_unit("side_templer_volunteer_2_1").get("display_name", "")).is_empty(), "Nach dem Laden: beide Rekruten genau einmal im Kader")
	_check(_status("side_templer_volunteer") == "cooldown" and _credits() == _expect_credits, "Nach dem Laden: Freiwilliger weiter in der Abklingzeit, Credits unveraendert")
	_check(_landing().get("ok", false) == true and _roster_count("side_templer_volunteer_1_1") == 1 and _roster_count("side_templer_volunteer_2_1") == 1, "Weitere Heimlandung nach dem Laden: kein Rekrut doppelt")
	return true

# 2 (Gegenstand), 6: Nachtwache, Handel bei offenem Nebenauftrag ----------------------------------

func _case_farm_and_trade() -> void:
	# Vorgaenger outpost_recovery ueber die Befehle des Adapters (complete_job, apply_reward); die Frachtkiste entfaellt.
	var prereq: bool = _start_campaign_job("outpost_recovery")
	var job: Dictionary = _job("outpost_recovery")
	var done: Dictionary = _cmd("complete_job", {"job_id": "outpost_recovery", "craft_id": _craft}, {"runtime_evidence": {"scenario_id": String(job.get("scenario_id", "")), "result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": Array(job.get("required_step_ids", []))}}})
	var receipt: Dictionary = Dictionary(done.get("completion_receipt", {}))
	var reward: Dictionary = {}
	if not receipt.is_empty():
		reward = _runtime.call("_commit", "singleplayer_supply", "apply_reward", {"completion_id": String(receipt.completion_id)}, "reward:" + String(receipt.completion_id), {"completion_receipt": receipt})
	_check(prereq and bool(done.get("ok", false)) and not receipt.is_empty() and bool(reward.get("ok", false)) and _status("outpost_recovery") == "completed", "Vorgaenger outpost_recovery ueber complete_job und apply_reward des Adapters abgeschlossen (nicht ueber das Hochladen/Flug)")
	_check(bool(_avail("side_farm_night_watch").get("can_accept", false)) and bool(_avail("side_relay_silence").get("can_accept", false)) and not bool(_avail("side_lab_cold_samples").get("visible", true)), "Nach outpost_recovery: Nachtwache und Funkstille annehmbar, Proben noch nicht")
	# Handel bei offenem Nebenauftrag: Nachtwache angenommen (noch nicht aktiv).
	var accepted: Dictionary = _screen.call("request_operation", "accept_job", {"job_id": "side_farm_night_watch"})
	var campaign: RefCounted = _campaign()
	_check(bool(accepted.get("ok", false)) and _status("side_farm_night_watch") == "accepted", "Nachtwache angenommen")
	_check(not Dictionary(campaign.trade_marker_entry("muellers_farm")).is_empty() and not campaign.has_open_job_at("muellers_farm"), "Nachtwache offen: Handelsmarker an Muellers Farm bleibt, has_open_job_at(muellers_farm) ist false")
	var accepted_relay: Dictionary = _screen.call("request_operation", "accept_job", {"job_id": "side_relay_silence"})
	_check(bool(accepted_relay.get("ok", false)) and not Dictionary(campaign.trade_marker_entry("relay_ridge")).is_empty() and not campaign.has_open_job_at("relay_ridge"), "Funkstille offen (nach outpost_recovery ist der freie Besuch am Relaisgrat offen): Handelsmarker am Relaisgrat bleibt, has_open_job_at(relay_ridge) ist false")
	# Nachtwache spielen: schon angenommen, darum nur Zielwahl, Bindung, Aktivieren und Einsatzende.
	var reward_def: Dictionary = Dictionary(_rewards.side_farm_night_watch.get("reward", {}))
	var credits_before := _credits()
	var armor_before := _base_items("armor_light")
	var rep_before_mueller := _rep("mueller")
	var rep_before_templer := _rep("templer")
	var farm: Dictionary = _job("side_farm_night_watch")
	var selected: Dictionary = _screen.call("request_operation", "select_destination", {"location_id": String(farm.get("location_id", "")), "job_id": "side_farm_night_watch"})
	var tokens: Dictionary = _runtime.get("_departure_token_by_craft")
	tokens[_craft] = "sjf-token-farm"
	var departure := {"craft_id": _craft, "origin_location_id": "homebase", "destination_location_id": String(farm.get("location_id", "")), "landing_pad_id": "homebase_pad_01", "job_id": "side_farm_night_watch"}
	var bound: Dictionary = _cmd("bind_departure", departure, {"departure_authorized": true})
	var active: Dictionary = _cmd("activate_job", {"job_id": "side_farm_night_watch", "craft_id": _craft}, {"departure_authorized": true})
	_check(bool(selected.get("ok", false)) and bool(bound.get("ok", false)) and bool(active.get("ok", false)) and _status("side_farm_night_watch") == "active", "Nachtwache: Ziel gewaehlt, Abflug gebunden, aktiv")
	var partial: Dictionary = _finish_mission("side_farm_night_watch", Array(farm.get("required_step_ids", [])).slice(0, 2))
	_check(_status("side_farm_night_watch") == "active" and not partial.has("side_job_message") and _credits() == credits_before, "Einsatzende mit fehlenden Schritten: Auftrag bleibt aktiv, keine Belohnung")
	var result: Dictionary = _finish_mission("side_farm_night_watch")
	_check(_status("side_farm_night_watch") == "cooldown" and _credits() == credits_before + int(reward_def.credits), "Nachtwache: Credits +%d, Zustand cooldown" % int(reward_def.credits))
	_check(_base_items("armor_light") == armor_before + 1, "Nachtwache: armor_light im Basislager genau +1 (vorher %d, jetzt %d)" % [armor_before, _base_items("armor_light")])
	_check(_rep("mueller") == rep_before_mueller + 5 and _rep("templer") == rep_before_templer + 2, "Nachtwache: Ruf Mueller +5, Templer +2")
	_check(String(result.get("side_job_message", "")).contains("Nebenauftrag erledigt") and String(result.get("side_job_message", "")).contains("Cr"), "Nachtwache: Meldung '%s'" % String(result.get("side_job_message", "")))
	# Rueckflug nach Hause: Heimlandung, Gegenstand bleibt genau einmal.
	_landing()
	_check(_base_items("armor_light") == armor_before + 1, "Heimlandung nach der Nachtwache: armor_light weiter genau +1 (keine Doppelbuchung)")

# 5b: Speicherpunkt nach der Nachtwache -------------------------------------------------------------

func _case_checkpoint_two() -> void:
	var armor := _base_items("armor_light")
	var rep_mueller := _rep("mueller")
	var rep_templer := _rep("templer")
	var landings: int = int(_snap().get("home_landings", 0))
	var completions: int = int(_job("side_farm_night_watch").get("completions", 0))
	var saved: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	if not _check(bool(saved.get("ok", false)), "Zweiter Heim-Speicherpunkt wird geschrieben (%s)" % str(saved.get("reason", ""))):
		return
	var loaded: Dictionary = STORE.load_checkpoint()
	if not _check(bool(loaded.get("ok", false)), "Zweiter Stand besteht validate_payload (%s)" % str(loaded.get("reason", ""))):
		return
	await _close()
	if not await _open("continue"):
		return
	_check(_base_items("armor_light") == armor and armor > 0, "Nach dem Laden: armor_light im Lager noch da (%d)" % armor)
	_check(_rep("mueller") == rep_mueller and _rep("templer") == rep_templer and int(_snap().get("home_landings", -1)) == landings, "Nach dem Laden: Ruf Mueller %d, Templer %d und home_landings %d erhalten" % [rep_mueller, rep_templer, landings])
	_check(int(_job("side_farm_night_watch").get("completions", 0)) == completions and _status("side_farm_night_watch") == "cooldown" and not Dictionary(Dictionary(_snap().get("completion_receipts", {})).get("side_farm_night_watch:completed:%d" % completions, {})).is_empty(), "Nach dem Laden: Nachtwache completions %d, cooldown, Beleg vorhanden" % completions)
	_check(_status("side_relay_silence") == "accepted", "Nach dem Laden: angenommene Funkstille bleibt angenommen")
	_check(_roster_count("side_templer_volunteer_1_1") == 1 and _roster_count("side_templer_volunteer_2_1") == 1, "Nach dem Laden: Rekruten weiter genau einmal im Kader")
	_landing()
	_check(_base_items("armor_light") == armor and _roster_count("side_templer_volunteer_1_1") == 1 and _roster_count("side_templer_volunteer_2_1") == 1, "Heimlandung nach dem Laden: weder Gegenstand noch Rekrut doppelt")
