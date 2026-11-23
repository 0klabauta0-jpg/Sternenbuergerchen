extends "res://scripts/tests/campaign_craft_loss_flow_verifier.gd"
## LC2g Punkt 2: Stand nach Schiffsverlust ueber den ECHTEN Ladeweg (Meta-Szene, Startanforderung "campaign"/"continue_home"; kein Stand-Test).
## Der Stand wird mit dem echten Speicher (campaign_checkpoint_store) geschrieben und von der Kampagnenszene geladen.
## (a) Landungsschiff verloren, Buccaneer bleibt: Laden steht an der Basis mit der Buccaneer, Beleg da, Speichern danach moeglich.
## (b) Kaufschiff verloren, neues gekauft: beide Belege richtig, das neue Schiff hat seinen Landeplatz, das verlorene bekommt keinen.
## (c) Rueckfallweg der Notrettung (fallback:true): Speichern und Laden gelingen, niemand ist an Bord eines fehlenden Schiffs.
## (FIXTURE kommt seit LC2i vom Flow-Pruefer.)

func _run() -> void:
	_configure_entry()
	await _a_dropship_lost_buccaneer_remains()
	await _b_bought_ship_lost_and_replaced()
	await _c_rescue_fallback_save_and_load()
	print("CAMPAIGN_CRAFT_LOSS_LOAD passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _write_real(checkpoint: Dictionary, label: String) -> bool:
	var saved: Dictionary = STORE.save_checkpoint(JSON.parse_string(JSON.stringify(checkpoint)))
	return _check(bool(saved.get("ok", false)), "%s: der Stand ist schreibbar (%s)" % [label, str(saved.get("reason", ""))])

func _save_later(label: String) -> bool:
	var saved: Dictionary = {}
	return await _wait(func():
		saved.clear()
		saved.merge(Dictionary(_flow.call("request_campaign_save")))
		return bool(saved.get("ok", false)), 60000, "%s: Speichern gelingt (%s)" % [label, str(saved.get("reason", ""))])

func _lost_ids() -> Array:
	var ids: Array = []
	for entry in Array(_flow.get("_lost_craft_records")): ids.append(String(Dictionary(entry).get("craft_id", "")))
	return ids

func _a_dropship_lost_buccaneer_remains() -> void:
	var base: Dictionary = FIXTURE.new().build()
	var supply = base.supply
	var checkpoint: Dictionary = Dictionary(base.checkpoint).duplicate(true)
	var dropship: Dictionary = Dictionary(Dictionary(checkpoint.fleet[0]).definition).duplicate(true)
	var buccaneer_entry: Dictionary = Dictionary(checkpoint.fleet[1]).duplicate(true)
	supply.retire_lost_craft("dropship_1")
	checkpoint.fleet = [buccaneer_entry]
	checkpoint.craft = {"definition": buccaneer_entry.definition, "pilot_id": buccaneer_entry.pilot_id}
	checkpoint.supply = supply.export_state()
	checkpoint.lost_craft = [{"craft_id": "dropship_1", "definition": dropship, "ship_name": "Dropship 1", "outcome": "crash", "equipment_kept": false}]
	if not _write_real(checkpoint, "A"): return
	if not await _open_scene("campaign", "continue_home"): return
	_check(_fleet_ids() == ["campaign_buccaneer_01"], "A: nach dem Laden besteht die Flotte nur aus der Buccaneer (%s)" % str(_fleet_ids()))
	_check(_lost_ids() == ["dropship_1"], "A: der Verlustbeleg des Landungsschiffs ist da (%s)" % str(_lost_ids()))
	print("A_VIEW ", _flow.get("_current_meta_view"))
	_check(Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).get("campaign_buccaneer_01", "") == "campaign_rescue_pilot", "A: die Buccaneer hat ihren Piloten")
	await _save_later("A: nach dem Laden")
	await _close()

func _b_bought_ship_lost_and_replaced() -> void:
	var fx = FIXTURE.new()
	var base: Dictionary = fx.build()
	var supply = base.supply
	var checkpoint: Dictionary = Dictionary(base.checkpoint).duplicate(true)
	var offer: Dictionary = Dictionary(Dictionary(supply.get("_definitions")).get("offers", {})).get("polisa_ship_cutlass", {})
	var requests: Dictionary = supply.get("_requests")
	requests["lc2g-pad"] = {"signature": JSON.stringify({"operation": "station_build_home_pad", "payload": {}}, "", true), "result": {"ok": true, "operation": "station_build_home_pad", "request_id": "lc2g-pad", "home_pad_count": 3, "cost": 200}}
	var first: Dictionary = fx.receipt("lc2g-buy-1", "homebase_pad_03", int(offer.get("unit_price")))
	var second: Dictionary = fx.receipt("lc2g-buy-2", "homebase_pad_03", int(offer.get("unit_price")))
	requests["lc2g-buy-1"] = first
	supply.register_craft(String(first.result.craft_id))
	supply.retire_lost_craft(String(first.result.craft_id))
	requests["lc2g-buy-2"] = second
	supply.register_craft(String(second.result.craft_id))
	var new_id := String(second.result.craft_id)
	var lost_id := String(first.result.craft_id)
	var definition := {"craft_id": new_id, "craft_type": String(offer.get("craft_type", "")), "model_id": String(offer.get("model_id", ""))}
	var lost_definition := {"craft_id": lost_id, "craft_type": String(offer.get("craft_type", "")), "model_id": String(offer.get("model_id", ""))}
	checkpoint.fleet.append({"definition": definition, "pilot_id": "", "location": "homebase"})
	checkpoint.lost_craft = [{"craft_id": lost_id, "definition": lost_definition, "ship_name": "Cutlass", "outcome": "crash", "equipment_kept": false}]
	checkpoint.supply = supply.export_state()
	if not _write_real(checkpoint, "B"): return
	if not await _open_scene("campaign", "continue_home"): return
	_check(_fleet_ids().has(new_id) and not _fleet_ids().has(lost_id), "B: das neue Schiff ist in der Flotte, das verlorene nicht (%s)" % str(_fleet_ids()))
	var pads: Dictionary = _runtime.get("_pad_by_craft")
	print("B_PADS ", pads)
	_check(pads.has(new_id) and not pads.has(lost_id), "B: das neue Schiff hat seinen Landeplatz, das verlorene bekommt keinen (%s)" % str(pads))
	var loaded_requests: Dictionary = _runtime.get("_supply").get("_requests")
	_check(loaded_requests.has("lc2g-buy-1") and loaded_requests.has("lc2g-buy-2") and bool(Dictionary(loaded_requests["lc2g-buy-1"].result).get("craft_lost", false)) and not bool(Dictionary(loaded_requests["lc2g-buy-2"].result).get("craft_lost", false)), "B: beide Kaufbelege sind da, nur der des verlorenen Schiffs ist als verloren gekennzeichnet")
	_check(_lost_ids() == [lost_id], "B: der Verlustbeleg des Kaufschiffs ist da (%s)" % str(_lost_ids()))
	await _save_later("B: nach dem Laden")
	await _close()

func _c_rescue_fallback_save_and_load() -> void:
	if not await _open_scene("campaign", "new"): return
	var base: Node = _runtime.call("get_base_personnel_runtime")
	var states: Dictionary = base.get("_states")
	var sim: Node = base.get("_sim")
	var was_required: Variant = base.get("_hex_required")
	var registry: Variant = sim.get("_hex_ground_registry")
	base.set("_hex_required", true)
	sim.set("_hex_ground_registry", null)
	for id in [LEADER, PILOT]:
		states[id]["status"] = "aboard"
		states[id]["craft_id"] = "lc2g_lost_ship"
	var result: Dictionary = Dictionary(base.call("rescue_crew_from_lost_craft", "lc2g_lost_ship"))
	sim.set("_hex_ground_registry", registry)
	base.set("_hex_required", was_required)
	_check(bool(result.get("ok", false)) and bool(result.get("fallback", false)), "C: die Notrettung ging ueber den Rueckfallweg (%s)" % str(result))
	await _save_later("C: nach dem Rueckfallweg")
	await _close()
	if not await _open_scene("campaign", "continue_home"): return
	var loaded_states: Dictionary = _runtime.call("get_base_personnel_runtime").get("_states")
	for id in [LEADER, PILOT]:
		_check(loaded_states.has(id) and String(loaded_states[id].get("status", "")) != "aboard" and String(loaded_states[id].get("craft_id", "x")).is_empty(), "C: nach dem Laden steht %s an der Basis, nicht an Bord (%s)" % [id, str(loaded_states.get(id, {}))])
	await _save_later("C: nach dem Laden")
	await _close()
