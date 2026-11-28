extends SceneTree
## Nebenauftraege N1, Teil 2a: Belohnungen im Versorgungsstand (Credits, Gegenstaende, ausstehende Gegenstaende), Speichern/Laden,
## die vier Szenarien und die Verdrahtung (Heimlandung, Rekruten, Meldung). Keine Szene, kein Flug, kein Einsatz.
## Abschlusszeile: SIDE_JOBS_REWARDS passed=%d failed=%d
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const COMMAND = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const INV = preload("res://scripts/mission/inventory_transfer_contract.gd")
const SCENARIO = preload("res://scripts/mission/mission_scenario_data.gd")
const GATES = preload("res://scripts/mission/mission_scenario_runtime_gates.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const CHECKPOINT = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const OFFER_PATH := "res://data/singleplayer/trade_offers.json"
const SIDE_IDS: Array = ["side_relay_silence", "side_farm_night_watch", "side_lab_cold_samples", "side_templer_volunteer"]
## Besuchsszenario je Nebenauftrag (gleiche Karte, gleicher Handelsmarker).
const VISIT_OF := {"side_relay_silence": "relay_ridge_visit", "side_farm_night_watch": "muellers_farm_visit", "side_lab_cold_samples": "shady_lab_visit", "side_templer_volunteer": "templanon_visit"}
var passed := 0
var failed := 0
var _seq := 0
var _camp_seq := 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _cmd(op: String, payload: Dictionary, request_id: String = "") -> Dictionary:
	_seq += 1
	return {"contract_category": "singleplayer_supply", "operation": op, "payload": payload, "request_id": request_id if not request_id.is_empty() else "sr:%d" % _seq}

func _dat() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(OFFER_PATH)))

func _sup() -> RefCounted:
	var s: RefCounted = SUPPLY.new()
	var cfg: Dictionary = s.configure([], _dat())
	if not bool(cfg.get("ok", false)): print("FAIL: Versorgung nicht konfiguriert: ", cfg)
	s.register_craft("ship", 5.0)
	s.configure_inventory([], ["ship"])
	return s

func _roundtrip(s: RefCounted) -> Dictionary:
	return Dictionary(JSON.parse_string(JSON.stringify(s.export_state())))

func _load_into_fresh(data: Dictionary) -> Dictionary:
	var loaded: RefCounted = SUPPLY.new()
	loaded.configure([], _dat())
	loaded.register_craft("ship", 5.0)
	var result: Dictionary = loaded.restore_state(data)
	result["owner"] = loaded
	return result

func _receipt(job_id: String, n: int, reward: Dictionary) -> Dictionary:
	var cid := "%s:completed:%d" % [job_id, n]
	return {"completion_id": cid, "job_id": job_id, "scenario_id": job_id, "craft_id": "ship", "reward": reward, "runtime_verified": true, "side": true}

func _apply(s: RefCounted, receipt: Dictionary, request_id: String = "") -> Dictionary:
	var cid := String(receipt.completion_id)
	return s.apply_command(_cmd("apply_reward", {"completion_id": cid}, request_id if not request_id.is_empty() else "reward:" + cid), {"completion_receipt": receipt})

func _base(s: RefCounted) -> Dictionary:
	return Dictionary(s.get_supply_snapshot().item_quantities)

func _base_container(s: RefCounted) -> Dictionary:
	return Dictionary(Dictionary(s.get("_inventory")).get("base:homebase", {}))

## Das Basislager bis auf `free` Plaetze mit Erz fuellen.
func _fill_base(s: RefCounted, free: int) -> void:
	var container: Dictionary = _base_container(s)
	var left: int = int(container.capacity) - INV.used(Dictionary(container.items)) - free
	if left > 0:
		container.items["ore"] = int(container.items.get("ore", 0)) + left

func _reward(credits: int, items: Array, recruits: int = 0, reputation: Dictionary = {}) -> Dictionary:
	return {"credits": credits, "blueprint_id": "", "items": items, "recruits": recruits, "reputation": reputation}

func _run() -> void:
	_case_supply_rewards()
	_case_pending_items()
	_case_save_and_load()
	_case_restore_rules()
	_case_real_campaign_chain()
	_case_checkpoint_roster_rule()
	_case_scenarios()
	_case_wiring()
	print("SIDE_JOBS_REWARDS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ---------- 1: Belohnung buchen ----------

func _case_supply_rewards() -> void:
	var s: RefCounted = _sup()
	var credits0: int = s.get_credits()
	var armor0: int = int(_base(s).get("armor_light", 0))
	var farm: Dictionary = _receipt("side_farm_night_watch", 1, _reward(80, [{"item_id": "armor_light", "quantity": 1}], 0, {"mueller": 5, "templer": 2}))
	var first: Dictionary = _apply(s, farm)
	_check(bool(first.get("ok", false)) and int(first.get("credits_added", 0)) == 80 and s.get_credits() == credits0 + 80, "Nebenauftragsbeleg buchen: +80 Credits")
	_check(int(_base(s).get("armor_light", 0)) == armor0 + 1 and Array(first.get("side_items_booked", [])).size() == 1 and Array(first.get("side_items_pending", [])).is_empty(), "Gegenstand landet im Basislager (+1 leichte Ruestung), nichts ausstehend")
	var replay: Dictionary = _apply(s, farm)
	_check(bool(replay.get("replayed", false)) and int(_base(s).get("armor_light", 0)) == armor0 + 1 and s.get_credits() == credits0 + 80, "Gleiche request_id: nichts doppelt")
	var again: Dictionary = _apply(s, farm, "reward:other_request")
	_check(bool(again.get("already_rewarded", false)) and int(_base(s).get("armor_light", 0)) == armor0 + 1 and s.get_credits() == credits0 + 80, "Gleiche completion_id, andere request_id: already_rewarded, nichts doppelt")
	var second: Dictionary = _apply(s, _receipt("side_farm_night_watch", 2, _reward(80, [{"item_id": "armor_light", "quantity": 1}])))
	_check(bool(second.get("ok", false)) and not bool(second.get("already_rewarded", false)) and s.get_credits() == credits0 + 160 and int(_base(s).get("armor_light", 0)) == armor0 + 2, "Zweiter Beleg :completed:2 bucht neu (Credits und Gegenstand)")
	var lab: Dictionary = _apply(s, _receipt("side_lab_cold_samples", 1, _reward(120, [{"item_id": "rocket_launcher", "quantity": 1}, {"item_id": "ammo_rocket", "quantity": 2}])))
	_check(bool(lab.get("ok", false)) and int(_base(s).get("rocket_launcher", 0)) >= 1 and int(_base(s).get("ammo_rocket", 0)) >= 2 and Array(lab.get("side_items_booked", [])).size() == 2, "Probenauftrag: Raketenwerfer und 2 Raketen im Basislager")
	var junk: Dictionary = _apply(s, _receipt("side_templer_volunteer", 1, _reward(60, [{"item_id": "gibt_es_nicht", "quantity": 1}, {"item_id": "armor_light", "quantity": 0}], 1)))
	_check(bool(junk.get("ok", false)) and s.get_pending_side_items().is_empty() and Array(junk.get("side_items_booked", [])).is_empty(), "Unbekannter Gegenstand und Menge 0 werden uebergangen (Credits trotzdem gebucht, nichts ausstehend)")
	var plain: Dictionary = _apply(s, {"completion_id": "plain:completed", "job_id": "plain", "scenario_id": "plain", "reward": {"credits": 5, "items": [{"item_id": "armor_light", "quantity": 1}]}, "runtime_verified": true})
	_check(bool(plain.get("ok", false)) and not plain.has("side_items_booked") and int(_base(s).get("armor_light", 0)) == armor0 + 2, "Beleg ohne side=true: Gegenstaende werden nicht gebucht")

# ---------- 2: volles Lager -> ausstehend -> nachgebucht ----------

func _case_pending_items() -> void:
	var s: RefCounted = _sup()
	_fill_base(s, 0)
	var credits0: int = s.get_credits()
	var result: Dictionary = _apply(s, _receipt("side_farm_night_watch", 1, _reward(80, [{"item_id": "armor_light", "quantity": 1}])))
	_check(bool(result.get("ok", false)) and s.get_credits() == credits0 + 80, "Volles Lager: Credits werden trotzdem gebucht")
	_check(Array(result.get("side_items_booked", [])).is_empty() and Array(result.get("side_items_pending", [])).size() == 1 and s.get_pending_side_items().size() == 1, "Volles Lager: Gegenstand wird ausstehend gemerkt")
	var pending: Dictionary = Dictionary(s.get_pending_side_items()[0])
	_check(String(pending.completion_id) == "side_farm_night_watch:completed:1" and String(pending.item_id) == "armor_light" and int(pending.quantity) == 1, "Ausstehender Eintrag: completion_id, item_id, quantity")
	_check(s.retry_pending_side_items().is_empty() and s.get_pending_side_items().size() == 1, "Erneut versuchen bei vollem Lager: bleibt ausstehend")
	var saved: Dictionary = _roundtrip(s)
	_check(Array(saved.get("pending_side_items", [])).size() == 1, "export_state traegt pending_side_items")
	var loaded: Dictionary = _load_into_fresh(saved)
	_check(bool(loaded.get("ok", false)) and loaded.owner.get_pending_side_items().size() == 1 and int(Dictionary(loaded.owner.get_pending_side_items()[0]).quantity) == 1, "Laden: ausstehender Gegenstand ueberlebt (%s)" % str(loaded.get("reason", "")))
	# Platz schaffen: Erz raus, dann nachbuchen - genau einmal.
	var container: Dictionary = _base_container(loaded.owner)
	container.items.erase("ore")
	var armor_before: int = int(_base(loaded.owner).get("armor_light", 0))
	var booked: Array = loaded.owner.retry_pending_side_items()
	_check(booked.size() == 1 and String(Dictionary(booked[0]).item_id) == "armor_light" and int(_base(loaded.owner).get("armor_light", 0)) == armor_before + 1 and loaded.owner.get_pending_side_items().is_empty(), "Platz frei: ausstehender Gegenstand wird nachgebucht")
	_check(loaded.owner.retry_pending_side_items().is_empty() and int(_base(loaded.owner).get("armor_light", 0)) == armor_before + 1, "Nochmal versuchen: nichts doppelt")
	var reloaded: Dictionary = _load_into_fresh(_roundtrip(loaded.owner))
	_check(bool(reloaded.get("ok", false)) and reloaded.owner.get_pending_side_items().is_empty() and int(_base(reloaded.owner).get("armor_light", 0)) == armor_before + 1, "Neu laden nach dem Nachbuchen: nichts ausstehend, nichts doppelt")
	_check(not Dictionary(_roundtrip(loaded.owner)).has("pending_side_items"), "Ohne Ausstehendes schreibt der Stand den Schluessel nicht")
	# Teilweise passend: 1 Platz frei, 2 Raketen.
	var t: RefCounted = _sup()
	_fill_base(t, 1)
	var partial: Dictionary = _apply(t, _receipt("side_lab_cold_samples", 1, _reward(0, [{"item_id": "ammo_rocket", "quantity": 2}])))
	var booked_n: int = 0
	for entry: Variant in Array(partial.get("side_items_booked", [])): booked_n += int(Dictionary(entry).quantity)
	var pending_n: int = 0
	for entry: Variant in t.get_pending_side_items(): pending_n += int(Dictionary(entry).quantity)
	_check(booked_n == 1 and pending_n == 1 and booked_n + pending_n == 2, "Teilweise Platz: 1 Rakete gebucht, 1 ausstehend (keine geht verloren)")

# ---------- 3: Speichern und Laden mit Nebenauftragsbelegen ----------

func _case_save_and_load() -> void:
	var s: RefCounted = _sup()
	_apply(s, _receipt("side_farm_night_watch", 1, _reward(80, [{"item_id": "armor_light", "quantity": 1}], 0, {"mueller": 5})))
	_apply(s, _receipt("side_farm_night_watch", 2, _reward(80, [{"item_id": "armor_light", "quantity": 1}])))
	_apply(s, _receipt("side_templer_volunteer", 1, _reward(60, [], 1, {"templer": 5})))
	var saved: Dictionary = _roundtrip(s)
	var loaded: Dictionary = _load_into_fresh(saved)
	_check(bool(loaded.get("ok", false)), "Laden: Stand mit drei Nebenauftragsbelegen wird angenommen (%s)" % str(loaded.get("reason", "")))
	var owner: RefCounted = loaded.owner
	_check(owner.get_credits() == s.get_credits() and JSON.stringify(_base(owner), "", true) == JSON.stringify(_base(s), "", true), "Laden: Credits und Basislager gleich")
	_check(Array(owner.get_supply_snapshot().reward_completion_ids).size() == 3 and Array(owner.get_supply_snapshot().reward_completion_ids).has("side_farm_night_watch:completed:2"), "Laden: alle drei Belege vorhanden")
	var replay: Dictionary = _apply(owner, _receipt("side_farm_night_watch", 2, _reward(80, [{"item_id": "armor_light", "quantity": 1}])))
	_check(bool(replay.get("already_rewarded", false)) or bool(replay.get("replayed", false)), "Nach dem Laden: derselbe Beleg bucht nicht noch einmal")
	var credits_before: int = owner.get_credits()
	var armor_before: int = int(_base(owner).get("armor_light", 0))
	var third: Dictionary = _apply(owner, _receipt("side_farm_night_watch", 3, _reward(80, [{"item_id": "armor_light", "quantity": 1}])))
	_check(bool(third.get("ok", false)) and owner.get_credits() == credits_before + 80 and int(_base(owner).get("armor_light", 0)) == armor_before + 1, "Nach dem Laden: Beleg :completed:3 bucht neu")
	var drift: Dictionary = _roundtrip(s)
	var drift_receipt: Dictionary = drift.reward_receipts["side_farm_night_watch:completed:1"]
	drift_receipt.reward.credits = 999
	var drifted: Dictionary = _load_into_fresh(drift)
	_check(bool(drifted.get("ok", false)), "Belohnung im Beleg weicht von der heutigen Datei ab: Stand laedt trotzdem (kein Vergleich)")
	var plain: RefCounted = _sup()
	var old_state: Dictionary = _roundtrip(plain)
	_check(not old_state.has("pending_side_items") and bool(_load_into_fresh(old_state).get("ok", false)) and _load_into_fresh(old_state).owner.get_pending_side_items().is_empty(), "Alter Stand ohne pending_side_items: laedt, Liste leer")

# ---------- 4: strenge und tolerante Regeln beim Laden ----------

func _case_restore_rules() -> void:
	var s: RefCounted = _sup()
	_apply(s, _receipt("side_farm_night_watch", 1, _reward(80, [])))
	var base_state: Dictionary = _roundtrip(s)
	var ghost: Dictionary = base_state.duplicate(true)
	ghost.reward_receipts["side_gibt_es_nicht:completed:1"] = _receipt("side_gibt_es_nicht", 1, _reward(10, []))
	var ghost_loaded: Dictionary = _load_into_fresh(ghost)
	_check(bool(ghost_loaded.get("ok", false)) and Array(ghost_loaded.owner.get_supply_snapshot().reward_completion_ids).has("side_gibt_es_nicht:completed:1") and Array(ghost_loaded.owner.get_supply_snapshot().reward_completion_ids).has("side_farm_night_watch:completed:1"), "Beleg eines unbekannten Nebenauftrags BLEIBT, der bekannte auch")
	var bad_cases := {
		"Zaehler 0": ["side_farm_night_watch:completed:0", "side_farm_night_watch:completed:0", true],
		"Zaehler keine Zahl": ["side_farm_night_watch:completed:x", "side_farm_night_watch:completed:x", true],
		"Zaehler mit fuehrender Null": ["side_farm_night_watch:completed:01", "side_farm_night_watch:completed:01", true],
		"ohne Zaehler": ["side_farm_night_watch:completed", "side_farm_night_watch:completed", true],
		"completion_id passt nicht": ["side_farm_night_watch:completed:2", "side_farm_night_watch:completed:3", true],
		"nicht runtime_verified": ["side_farm_night_watch:completed:2", "side_farm_night_watch:completed:2", false],
	}
	for label: String in bad_cases:
		var entry: Array = bad_cases[label]
		var broken: Dictionary = base_state.duplicate(true)
		var rec: Dictionary = _receipt("side_farm_night_watch", 2, _reward(10, []))
		rec["completion_id"] = entry[1]
		rec["runtime_verified"] = entry[2]
		broken.reward_receipts[entry[0]] = rec
		_check(not bool(_load_into_fresh(broken).get("ok", true)), "Ungueltiger Nebenauftragsbeleg abgelehnt: " + label)
	var strict: Dictionary = base_state.duplicate(true)
	strict.reward_receipts["outpost_recovery:completed"] = {"completion_id": "outpost_recovery:completed", "job_id": "outpost_recovery", "scenario_id": "outpost_recovery", "reward": {"credits": 1}, "runtime_verified": true}
	_check(not bool(_load_into_fresh(strict).get("ok", true)), "Kampagnenbeleg mit abweichender Belohnung bleibt streng abgelehnt")
	var forged: Dictionary = base_state.duplicate(true)
	var forged_receipt: Dictionary = {"completion_id": "outpost_recovery:completed:1", "job_id": "outpost_recovery", "scenario_id": "outpost_recovery", "reward": {"credits": 1}, "runtime_verified": true, "side": true}
	forged.reward_receipts["outpost_recovery:completed:1"] = forged_receipt
	var forged_loaded: Dictionary = _load_into_fresh(forged)
	_check(not bool(forged_loaded.get("ok", false)) or not Array(forged_loaded.owner.get_supply_snapshot().reward_completion_ids).has("outpost_recovery:completed:1"), "side=true auf einem Kampagnenauftrag wird nicht uebernommen")
	var junk_pending: Dictionary = _roundtrip(s)
	junk_pending["pending_side_items"] = [{"completion_id": "a:completed:1", "item_id": "armor_light", "quantity": 2}, {"completion_id": "b", "item_id": "gibt_es_nicht", "quantity": 1}, {"completion_id": "c", "item_id": "armor_light", "quantity": -4}, "kaputt", {"item_id": "armor_light"}]
	var junk_loaded: Dictionary = _load_into_fresh(junk_pending)
	_check(bool(junk_loaded.get("ok", false)) and junk_loaded.owner.get_pending_side_items().size() == 1 and int(Dictionary(junk_loaded.owner.get_pending_side_items()[0]).quantity) == 2, "pending_side_items: unbrauchbare Eintraege werden verworfen, der gute bleibt")

# ---------- 5: echte Kampagne + Versorgung: beide Seiten stimmig (Pruefregel des Checkpoint-Speichers) ----------

func _ccmd(owner: RefCounted, operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	_camp_seq += 1
	return owner.apply_command(COMMAND.build_command(operation, payload, "sr_camp:%d" % _camp_seq), context)

func _cjob(owner: RefCounted, id: String) -> Dictionary:
	return Dictionary(owner.get_campaign_snapshot().jobs.get(id, {}))

func _cstart(owner: RefCounted, id: String) -> bool:
	var job: Dictionary = _cjob(owner, id)
	var dep := {"craft_id": "dropship_1", "origin_location_id": "homebase", "destination_location_id": job.location_id, "landing_pad_id": "homebase_pad_01", "job_id": id}
	var ok: bool = bool(_ccmd(owner, "accept_job", {"job_id": id}).get("ok", false))
	ok = ok and bool(_ccmd(owner, "bind_departure", dep, {"departure_authorized": true}).get("ok", false))
	ok = ok and bool(_ccmd(owner, "activate_job", {"job_id": id, "craft_id": "dropship_1"}, {"departure_authorized": true}).get("ok", false))
	return ok

func _ccomplete(owner: RefCounted, id: String) -> Dictionary:
	var job: Dictionary = _cjob(owner, id)
	var evidence := {"scenario_id": job.scenario_id, "result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": job.required_step_ids}}
	return _ccmd(owner, "complete_job", {"job_id": id, "craft_id": "dropship_1"}, {"runtime_evidence": evidence})

## Kampagnenauftrag ganz durchspielen; der Beleg geht an die Versorgung (wie der Adapter es tut).
func _cfinish(owner: RefCounted, id: String, supply: RefCounted) -> bool:
	var job: Dictionary = _cjob(owner, id)
	var ok: bool = _cstart(owner, id)
	var done: Dictionary = _ccomplete(owner, id)
	ok = ok and bool(done.get("ok", false))
	if bool(job.get("home_upload", false)):
		done = _ccmd(owner, "upload_job", {"job_id": id}, {"at_home": true})
		ok = ok and bool(done.get("ok", false))
	var receipt: Dictionary = Dictionary(done.get("completion_receipt", {}))
	ok = ok and not receipt.is_empty() and bool(_apply(supply, receipt).get("ok", false))
	if id == "outpost_recovery":
		ok = ok and bool(_ccmd(owner, "claim_recruit", {"kind": "outpost"}, {"runtime_authorized": true}).get("ok", false))
		ok = ok and bool(_ccmd(owner, "load_crate", {}, {"runtime_authorized": true}).get("ok", false))
	return ok

func _store_rule(campaign_state: Dictionary, supply_state: Dictionary) -> bool:
	if Dictionary(supply_state.reward_receipts).size() != Dictionary(campaign_state.completion_receipts).size(): return false
	for id: Variant in supply_state.reward_receipts:
		if Dictionary(campaign_state.completion_receipts).get(id) != Dictionary(supply_state.reward_receipts)[id]: return false
	return true

func _case_real_campaign_chain() -> void:
	var campaign: RefCounted = CAMPAIGN.new()
	_check(bool(campaign.configure({}, {}, true).get("ok", false)), "Fixture: Kampagne konfiguriert")
	var supply: RefCounted = _sup()
	_check(_cfinish(campaign, "satellite_recovery", supply) and _cfinish(campaign, "outpost_recovery", supply), "Fixture: Vorgaenger satellite_recovery und outpost_recovery abgeschlossen und bezahlt")
	var credits0: int = supply.get_credits()
	var armor0: int = int(_base(supply).get("armor_light", 0))
	# Nachtwache: echter Beleg aus der Kampagne an die Versorgung.
	_check(_cstart(campaign, "side_farm_night_watch"), "Nachtwache gestartet")
	var farm_done: Dictionary = _ccomplete(campaign, "side_farm_night_watch")
	var farm_receipt: Dictionary = Dictionary(farm_done.get("completion_receipt", {}))
	_check(bool(farm_done.get("ok", false)) and bool(farm_receipt.get("side", false)), "Nachtwache abgeschlossen, Beleg side=true")
	var farm_paid: Dictionary = _apply(supply, farm_receipt)
	_check(bool(farm_paid.get("ok", false)) and supply.get_credits() == credits0 + 80 and int(_base(supply).get("armor_light", 0)) == armor0 + 1, "Echter Beleg der Nachtwache: +80 Credits und leichte Ruestung im Basislager")
	# Freiwilliger: Rekrut steht in der Belohnung (die Person legt der Adapter an), Ruf im Kampagnenstand.
	_check(_cstart(campaign, "side_templer_volunteer"), "Freiwilliger gestartet")
	var vol_done: Dictionary = _ccomplete(campaign, "side_templer_volunteer")
	var vol_receipt: Dictionary = Dictionary(vol_done.get("completion_receipt", {}))
	_check(int(Dictionary(vol_receipt.get("reward", {})).get("recruits", 0)) == 1 and bool(_apply(supply, vol_receipt).get("ok", false)), "Freiwilliger: Beleg nennt 1 Rekruten, Versorgung bucht ihn")
	var rep: Dictionary = Dictionary(campaign.get_campaign_snapshot().reputation)
	_check(int(rep.get("templer", 0)) == 7 and int(rep.get("mueller", 0)) == 5 and int(rep.get("labor", 0)) == -2, "Ruf im Kampagnenstand: Templer 7 (2+5), Mueller 5, Labor -2")
	# Wiederholung: zwei Heimlandungen, dann kommt die Nachtwache wieder und bucht neu.
	for i in 2:
		campaign.apply_command(COMMAND.build_command("home_landing", {}, "home_landing:%d" % (int(campaign.get_campaign_snapshot().home_landings) + 1)))
	_check(_cstart(campaign, "side_farm_night_watch"), "Nachtwache nach Pause erneut gestartet")
	var again: Dictionary = Dictionary(_ccomplete(campaign, "side_farm_night_watch").get("completion_receipt", {}))
	var credits1: int = supply.get_credits()
	_check(String(again.get("completion_id", "")) == "side_farm_night_watch:completed:2" and bool(_apply(supply, again).get("ok", false)) and supply.get_credits() == credits1 + 80 and int(_base(supply).get("armor_light", 0)) == armor0 + 2, "Wiederholung: :completed:2 bucht Credits und Gegenstand erneut")
	# Pruefregel des Checkpoint-Speichers: gleiche Zahl und gleiche Belege auf beiden Seiten.
	var campaign_state: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(campaign.export_state())))
	# Wie export_campaign_checkpoint: zu Hause, ohne Abflugbindung und Auswahl.
	campaign_state["departures_by_craft_id"] = {}
	campaign_state["selected_location_id"] = "homebase"
	campaign_state["selected_job_id"] = ""
	var supply_state: Dictionary = _roundtrip(supply)
	var supply_receipts: int = Dictionary(supply_state.reward_receipts).size()
	var campaign_receipts: int = Dictionary(campaign_state.completion_receipts).size()
	_check(supply_receipts == campaign_receipts and supply_receipts >= 5 and _store_rule(campaign_state, supply_state), "Checkpoint-Regel: Belegzahl und Belege gleich (Kampagne %d, Versorgung %d)" % [campaign_receipts, supply_receipts])
	# Beide Besitzer laden und neu schreiben: bleibt stimmig.
	var campaign_loaded: RefCounted = CAMPAIGN.new()
	campaign_loaded.configure({}, {}, true)
	var campaign_result: Dictionary = campaign_loaded.restore_state(campaign_state)
	var supply_result: Dictionary = _load_into_fresh(supply_state)
	_check(bool(campaign_result.get("ok", false)) and bool(supply_result.get("ok", false)), "Beide Besitzer laden den Stand (Kampagne: %s, Versorgung: %s)" % [str(campaign_result.get("reason", "")), str(supply_result.get("reason", ""))])
	if bool(campaign_result.get("ok", false)) and bool(supply_result.get("ok", false)):
		var campaign_again: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(campaign_loaded.export_state())))
		var supply_again: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(supply_result.owner.export_state())))
		_check(_store_rule(campaign_again, supply_again) and int(campaign_loaded.get_campaign_snapshot().reputation.templer) == 9 and int(campaign_loaded.get_campaign_snapshot().reputation.mueller) == 10, "Nach dem Laden stimmig; Ruf bleibt (Templer 9, Mueller 10)")
	# Ein Beleg ohne Auftrag (es gibt ihn nicht mehr) bleibt auf beiden Seiten gleich erhalten.
	var ghost_campaign: Dictionary = campaign_state.duplicate(true)
	var ghost_supply: Dictionary = supply_state.duplicate(true)
	var ghost_receipt: Dictionary = _receipt("side_gibt_es_nicht", 1, _reward(10, []))
	ghost_campaign.completion_receipts["side_gibt_es_nicht:completed:1"] = ghost_receipt
	ghost_campaign.jobs["side_gibt_es_nicht"] = {"side": true, "status": "cooldown", "id": "side_gibt_es_nicht"}
	ghost_supply.reward_receipts["side_gibt_es_nicht:completed:1"] = ghost_receipt
	var ghost_campaign_owner: RefCounted = CAMPAIGN.new()
	ghost_campaign_owner.configure({}, {}, true)
	var ghost_campaign_result: Dictionary = ghost_campaign_owner.restore_state(ghost_campaign)
	var ghost_supply_result: Dictionary = _load_into_fresh(ghost_supply)
	if bool(ghost_campaign_result.get("ok", false)) and bool(ghost_supply_result.get("ok", false)):
		var gc: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(ghost_campaign_owner.export_state())))
		var gs: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(ghost_supply_result.owner.export_state())))
		_check(_store_rule(gc, gs) and Dictionary(gc.completion_receipts).has("side_gibt_es_nicht:completed:1") and Dictionary(gs.reward_receipts).has("side_gibt_es_nicht:completed:1"), "Unbekannter Nebenauftrag: Beleg bleibt in Kampagne UND Versorgung")
	else:
		_check(false, "Unbekannter Nebenauftrag: beide Besitzer laden (Kampagne: %s, Versorgung: %s)" % [str(ghost_campaign_result.get("reason", "")), str(ghost_supply_result.get("reason", ""))])

# ---------- 6: Rekruten im Checkpoint-Speicher ----------

func _case_checkpoint_roster_rule() -> void:
	var receipts := {"side_templer_volunteer:completed:1": _receipt("side_templer_volunteer", 1, _reward(60, [], 1))}
	_check(CHECKPOINT._side_recruit_backed("side_templer_volunteer_1_1", receipts), "Rekrut side_templer_volunteer_1_1 ist durch den Beleg gedeckt")
	_check(not CHECKPOINT._side_recruit_backed("side_templer_volunteer_1_2", receipts), "Zweiter Rekrut ohne Deckung (Beleg nennt nur 1) wird nicht gedeckt")
	_check(not CHECKPOINT._side_recruit_backed("side_templer_volunteer_2_1", receipts), "Rekrut zu einem fehlenden Beleg (:completed:2) wird nicht gedeckt")
	_check(not CHECKPOINT._side_recruit_backed("side_templer_volunteer_1_0", receipts) and not CHECKPOINT._side_recruit_backed("side_x", receipts) and not CHECKPOINT._side_recruit_backed("polisa_recruit_abc", receipts), "Index 0, kurze und fremde Kennungen werden nicht gedeckt")
	var no_side := {"side_templer_volunteer:completed:1": {"job_id": "side_templer_volunteer", "reward": {"recruits": 1}}}
	_check(not CHECKPOINT._side_recruit_backed("side_templer_volunteer_1_1", no_side) and not CHECKPOINT._side_recruit_backed("side_templer_volunteer_1_1", {}), "Ohne side=true im Beleg und ohne Beleg: nicht gedeckt")

# ---------- 7: die vier Szenarien ----------

func _case_scenarios() -> void:
	var side_jobs: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/side_jobs.json"))).get("jobs", {})
	var locations: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/locations.json")))
	var maps := {}
	for id: String in SIDE_IDS:
		var path: String = "res://data/mission_scenarios/%s.json" % id
		_check(FileAccess.file_exists(path), "Szenariodatei vorhanden: " + id)
		if not FileAccess.file_exists(path): continue
		var job: Dictionary = Dictionary(side_jobs.get(id, {}))
		var scenario = SCENARIO.load_from_file(path)
		_check(scenario != null and String(scenario.scenario_id) == id and String(scenario.scenario_id) == String(job.get("scenario_id", "")), "Szenario laedt, scenario_id passt zum Auftrag: " + id)
		if scenario == null: continue
		var place: Dictionary = Dictionary(locations.get(String(job.get("location_id", "")), {}))
		var map_path: String = String(place.get("map_file_path", ""))
		_check(String(scenario.map_file_path) == map_path, "Karte wie der Ort des Auftrags (%s): %s" % [String(job.get("location_id", "")), map_path])
		var visit_path: String = "res://data/mission_scenarios/%s.json" % String(VISIT_OF[id])
		var visit: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string(visit_path)))
		_check(String(visit.get("map_file_path", "")) == String(scenario.map_file_path), "Gleiche Karte wie das Besuchsszenario " + String(VISIT_OF[id]))
		if not maps.has(map_path): maps[map_path] = MAP.load_from_file(map_path)
		var valid: Dictionary = scenario.validate(maps[map_path])
		_check(bool(valid.get("valid", false)), "Szenario gueltig (Marker der Karte vorhanden): %s %s" % [id, str(valid.get("errors", []))])
		var step_ids: Array = []
		for step: Variant in Array(scenario.vertical_slice.get("flow_steps", [])): step_ids.append(String(Dictionary(step).step_id))
		var wanted: Array = Array(job.get("required_step_ids", []))
		var same: bool = step_ids.size() == wanted.size()
		for step_id: Variant in wanted: same = same and step_ids.has(String(step_id))
		_check(same, "Schritt-IDs gleich required_step_ids des Auftrags: " + id + " " + str(step_ids))
		# Erreichbar: mit allen Zustaenden und ohne lebende Gegner sind alle Schritte erledigt; ohne Zustaende keiner.
		var states := {}
		for step: Variant in Array(scenario.vertical_slice.get("flow_steps", [])): states[String(Dictionary(step).step_id)] = String(Dictionary(step).required_state)
		var fit := {}
		for group: Variant in scenario.enemy_groups: fit[String(Dictionary(group).group_id)] = 0
		var done_gates = GATES.new()
		done_gates.configure_from_slice(scenario.vertical_slice)
		var done: Dictionary = done_gates.update({"step_states": states, "enemy_group_fit_counts": fit})
		var all_done: bool = bool(done.get("all_gates_complete", false))
		for step_id: Variant in wanted: all_done = all_done and Array(done.get("completed_step_ids", [])).has(String(step_id))
		_check(all_done, "Alle Schritte erreichbar und abschliessbar: " + id)
		var idle_gates = GATES.new()
		idle_gates.configure_from_slice(scenario.vertical_slice)
		var idle_fit := {}
		for group: Variant in scenario.enemy_groups: idle_fit[String(Dictionary(group).group_id)] = 3
		var idle: Dictionary = idle_gates.update({"enemy_group_fit_counts": idle_fit})
		_check(not bool(idle.get("all_gates_complete", true)) and Array(idle.get("completed_step_ids", [])).is_empty(), "Ohne Spieler-Tat ist nichts erledigt: " + id)
	var farm = SCENARIO.load_from_file("res://data/mission_scenarios/side_farm_night_watch.json")
	if farm != null:
		var count: int = 0
		for group: Variant in farm.enemy_groups: count += Array(Dictionary(group).get("enemy_ids", [])).size()
		_check(count >= 3 and count <= 4, "Nachtwache: 3 bis 4 Pluenderer (%d)" % count)
		var blocked_gates = GATES.new()
		blocked_gates.configure_from_slice(farm.vertical_slice)
		var all_but_clear := {}
		for step: Variant in Array(farm.vertical_slice.get("flow_steps", [])):
			if String(Dictionary(step).step_id) != "clear_looters": all_but_clear[String(Dictionary(step).step_id)] = String(Dictionary(step).required_state)
		var blocked: Dictionary = blocked_gates.update({"step_states": all_but_clear, "enemy_group_fit_counts": {"looters": 2}})
		_check(not bool(blocked.get("all_gates_complete", true)), "Nachtwache: mit lebenden Pluenderern ist der Auftrag nicht abschliessbar")
	var lab = SCENARIO.load_from_file("res://data/mission_scenarios/side_lab_cold_samples.json")
	if lab != null: _check(lab.enemy_groups.size() >= 1, "Probenauftrag: es gibt Wachen")

# ---------- 8: Verdrahtung (Quelltext) ----------

func _source(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func _case_wiring() -> void:
	var adapter: String = _source("res://scripts/meta/singleplayer_runtime_adapter.gd")
	var flow: String = _source("res://scripts/meta/meta_layer_flow.gd")
	_check(adapter.contains("func record_home_landing()") and adapter.contains("\"home_landing:%d\" % next"), "Adapter: record_home_landing mit eindeutiger request_id aus dem Landungszaehler")
	var landing_pos: int = flow.find("record_home_landing")
	_check(landing_pos > 0 and flow.substr(maxi(0, landing_pos - 400), 400).contains("_restock_market_after_landing() # Handel H2") and flow.substr(landing_pos, 400).contains("_admit_unplaced_aboard_crew(craft_id)"), "Flow: record_home_landing direkt nach dem Marktauffuellen in _finish_space_home_landing")
	_check(adapter.contains("_settle_side_recruits()") and adapter.contains("\"%s_%d_%d\" % [String(receipt.get(\"job_id\"") and adapter.contains("register_campaign_recruit"), "Adapter: Rekruten <auftrag>_<n>_<i> ueber register_campaign_recruit, idempotent ueber die Kennung")
	_check(adapter.contains("side_job_message") and adapter.contains("Nebenauftrag erledigt: ") and _source("res://scripts/meta/debrief_screen.gd").contains("side_job_message"), "Meldung: Adapter schreibt side_job_message, die Auswertung zeigt sie")
	_check(adapter.contains("place_names") and adapter.contains("set_standing_orders_names(place_names"), "Dauerauftraege: Ortsnamen der neuen Posten kommen aus locations.json")
	for script_path: String in ["res://scripts/core/singleplayer_supply_state.gd", "res://scripts/meta/singleplayer_runtime_adapter.gd", "res://scripts/meta/campaign_checkpoint_store.gd", "res://scripts/meta/debrief_screen.gd"]:
		var script = load(script_path)
		_check(script != null and script.can_instantiate(), "Skript laedt ohne Fehler: " + script_path)
