extends "res://scripts/tests/campaign_craft_loss_second_verifier.gd"
## LC2k K1: Die Auftragskiste ist nach einem Schiffsverlust im ECHTEN Spiel wieder ladbar (Wichtig 1 der Schlusspruefung).
## Echter Fluss: Auftrag outpost_recovery wird ueber die echten Kampagnenbefehle angenommen, gebunden, aktiviert und mit record_mission_result
## abgeschlossen (dabei bucht der Adapter die Kiste selbst: Versorgung "campaign-cargo:load:..." und Kampagne "load:..."). Danach Schiffsverlust ueber
## _retire_lost_craft, "Kiste laden" ueber request_operation, und am Ende die Lieferung benit_delivery ueber record_mission_result (deliver_crate).
## Gestellt: Auftrag satellite_recovery gilt als abgeschlossen (Vorgaenger), der Anwerbe-Eintrag "claim_recruit outpost" wird direkt gebucht,
## das Kaufschiff wird in die Flotte gelegt (_inject_bought_ship). Die Kiste und ihre Buchungen sind NICHT von Hand gesetzt.

func _run() -> void:
	_configure_entry()
	await _k1_reload_after_loss(1)
	await _k1_reload_after_loss(2)
	print("CAMPAIGN_CRAFT_LOSS_CRATE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

var _seq := 0

func _cmd(operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	_seq += 1
	return _runtime.call("_commit", "singleplayer_campaign", operation, payload, "k1:%s:%d" % [operation, _seq], context)

func _progress() -> Dictionary:
	return Dictionary(Dictionary(_runtime.get("_campaign").call("get_campaign_snapshot")).get("progress", {}))

func _crate_in(craft_id: String) -> int:
	var inventory: Dictionary = Dictionary(_runtime.get("_supply").get_supply_snapshot().inventory)
	return int(Dictionary(Dictionary(inventory.get("craft:" + craft_id, {})).get("items", {})).get("c_benit_crate", 0))

## Nimmt den Auftrag an, bindet den Abflug, aktiviert und schliesst ihn mit einem Sieg ab (echte Befehle, echter Adapter-Abschluss).
func _run_job(job_id: String, craft_id: String) -> bool:
	var job: Dictionary = Dictionary(Dictionary(_runtime.get("_campaign").call("get_campaign_snapshot")).get("jobs", {})).get(job_id, {})
	var accepted: Dictionary = _cmd("accept_job", {"job_id": job_id})
	var bound: Dictionary = _cmd("bind_departure", {"craft_id": craft_id, "origin_location_id": "homebase", "destination_location_id": String(job.get("location_id", "")), "landing_pad_id": "homebase_pad_01", "job_id": job_id}, {"departure_authorized": true})
	var active: Dictionary = _cmd("activate_job", {"job_id": job_id, "craft_id": craft_id}, {"departure_authorized": true})
	_check(bool(accepted.get("ok", false)) and bool(bound.get("ok", false)) and bool(active.get("ok", false)), "K1: Aufbau: %s angenommen, gebunden, aktiviert (%s | %s | %s | Ziel %s, Orte %s)" % [job_id, str(accepted), str(bound), str(active), String(job.get("location_id", "")), str(Dictionary(Dictionary(_runtime.get("_campaign").call("get_campaign_snapshot")).get("locations", {})).keys())])
	var evidence := {"result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": job.get("required_step_ids", [])}}
	_runtime.call("record_mission_result", evidence, {"craft_id": craft_id, "job_id": job_id, "scenario_id": String(job.get("scenario_id", ""))})
	return String(Dictionary(Dictionary(Dictionary(_runtime.get("_campaign").call("get_campaign_snapshot")).get("jobs", {})).get(job_id, {})).get("status", "")) == "completed"

## losses = 1: ein Verlust, dann Laden mit dem zweiten Schiff, dann Lieferung. losses = 2: die Kiste geht auch ein zweites Mal mit ihrem Schiff verloren.
func _k1_reload_after_loss(losses: int) -> void:
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_runtime = _flow.get("_singleplayer_runtime")
	var tag := "K1/%d: " % losses
	if not _check(_runtime != null, tag + "Aufbau: Meta-Szene und Laufzeit"): return
	var holder := String(_fleet_ids()[0])
	var spares: Array = [_inject_bought_ship("1", "Zweitschiff")]
	if losses == 2: spares.append(_inject_bought_ship("2", "Drittschiff"))
	Dictionary(Dictionary(_runtime.get("_campaign").get("_jobs"))["satellite_recovery"])["status"] = "completed"
	_check(_run_job("outpost_recovery", holder), tag + "outpost_recovery ist ueber den echten Abschluss erledigt")
	_check(bool(_progress().get("crate_loaded", false)) and _crate_in(holder) == 1, tag + "der echte Abschluss hat die Kiste geladen (Merker %s, Kiste im Schiff %d)" % [str(_progress().get("crate_loaded")), _crate_in(holder)])
	_check(bool(_cmd("claim_recruit", {"kind": "outpost"}, {"runtime_authorized": true}).get("ok", false)), tag + "Aufbau: Aussenposten-Person angeworben")
	for i in range(losses):
		_flow.call("_retire_lost_craft", {"craft_id": holder, "ship_name": "Kistenschiff", "outcome": "crash", "rescue_fee": 0})
		_check(not bool(_progress().get("crate_loaded", true)), tag + "Verlust %d: Lade-Merker zurueck" % (i + 1))
		holder = String(spares[i])
		var crate: Dictionary = _runtime.call("request_operation", "campaign_load_crate", {"craft_id": holder})
		_check(bool(crate.get("ok", false)) and not String(crate.get("reason", "")).contains("request_id_conflict"), tag + "Verlust %d: Kiste laden mit dem naechsten Schiff geht (%s)" % [i + 1, str(crate)])
		_check(bool(_progress().get("crate_loaded", false)) and _crate_in(holder) == 1, tag + "Verlust %d: Merker gesetzt und Kiste im Lager des neuen Schiffs (Merker %s, Kiste %d)" % [i + 1, str(_progress().get("crate_loaded")), _crate_in(holder)])
	_check(_run_job("benit_delivery", holder), tag + "benit_delivery ist mit dem neu geladenen Schiff erledigt")
	_check(bool(_progress().get("crate_delivered", false)) and _crate_in(holder) == 0, tag + "deliver_crate hat gegriffen: Kiste abgegeben, Lager leer")
	await _close()
