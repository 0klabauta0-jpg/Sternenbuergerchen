extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Regel 8 / Auftrag 21.11.: Die pauschale Hin-und-Rueckflug-Reserve ist weg. Jede Etappe bucht ihren Anteil, wenn sie beginnt;
## eine Etappe, deren Anteil nicht gedeckt ist, startet nicht. Die Sitzung laeuft auf der echten Basis (Pilot und Crew an Bord),
## damit Abheben und Sprung wirklich fliegen (die nackte Testszene hat keinen Piloten an Bord und lehnt das Abheben ab).

func _run() -> void:
	_configure_entry()
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	_check(await _prepare_initial_base(), "Echte Basis mit Pilot und Crew an Bord ist bereit")
	var supply = _runtime.get("_supply")
	var crafts: Array = _flow.get("_homebase_aircraft_definitions")
	var craft_id: String = _craft_id
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/trade_offers.json"))
	# 11 Treibstoff: Abheben (1) und Sprung (10) sind bezahlbar, der Anflug (1) danach nicht mehr (0 vorhanden).
	data.initial_fuel = 11.0
	supply.configure(crafts, data)
	_screen.request_operation("accept_job", {"job_id": "satellite_recovery"})
	_screen.request_operation("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"})
	_screen.request_operation("start", {"craft_id": craft_id})
	_check(String(_runtime.get_snapshot().space_travel.phase) == "orbit", "Abheben mit 11 Treibstoff wird angenommen (Mondorbit)")
	_check(_flow.get("_active_mission") == null, "Abheben startet keinen Einsatz")
	_check(float(supply.get_supply_snapshot().fuel_by_craft_id[craft_id]) == 10.0, "Abheben bucht genau seinen Anteil (11 -> 10)")
	var site_orbit: String = String(Dictionary(_runtime.get_space_travel_snapshot(craft_id).get("location_orbits", {})).get("satellite_crash", ""))
	_screen.request_operation("space_start_quantum", {"craft_id": craft_id, "target_orbit_id": site_orbit})
	var deadline := Time.get_ticks_msec() + 20000
	while String(_runtime.get_snapshot().space_travel.orbit_id) != site_orbit and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(float(supply.get_supply_snapshot().fuel_by_craft_id[craft_id]) == 0.0, "Der Sprung bucht genau seinen Anteil (10 -> 0)")
	var result: Dictionary = _screen.request_operation("space_begin_approach", {"craft_id": craft_id, "location_id": "satellite_crash"})
	_check(not result.get("ok", true) and result.get("reason", "") == "leg_fuel_insufficient", "Der Anflug mit 0 Treibstoff (Anteil 1) wird abgelehnt, nicht wegen einer Rueckflugreserve")
	_check(String(_runtime.get_snapshot().space_travel.phase) == "orbit", "Der abgelehnte Anflug laesst das Schiff im Zielorbit")
	_check(float(supply.get_supply_snapshot().fuel_by_craft_id[craft_id]) == 0.0, "Der abgelehnte Anflug bucht nichts")
	_check(_flow.get("_active_mission") == null and Array(_flow.get("_pending_mission_craft_transfers")).is_empty(), "Der abgelehnte Anflug hinterlaesst keinen Einsatz und keinen halb gestarteten Transfer")
	_check(String(_runtime.get_snapshot().campaign.jobs.satellite_recovery.status) == "accepted", "Der abgelehnte Anflug laesst den Auftrag angenommen")
	# Besitzerebene: ohne Reserve genuegt der eigene Anteil; die Summe der Etappen ist die alte Strecke (12 hin, 12 zurueck).
	var route := {"craft_id": craft_id, "origin_location_id": "homebase", "destination_location_id": "satellite_crash", "leg": "approach"}
	var context := {"departure_authorized": true}
	data.initial_fuel = 1.0
	supply.configure(crafts, data)
	var gate: Dictionary = supply.preview_leg_fuel(route, context)
	_check(gate.get("ok", false), "Der Anflug braucht nur seinen Anteil (1), keine Rueckflugreserve")
	_check(float(supply.get_supply_snapshot().fuel_by_craft_id[craft_id]) == 1.0, "Die Vorpruefung bleibt lesend")
	data.initial_fuel = 0.0
	supply.configure(crafts, data)
	gate = supply.preview_leg_fuel(route, context)
	_check(not gate.get("ok", true) and gate.get("reason", "") == "leg_fuel_insufficient", "Der Versorgungsbesitzer lehnt einen nicht gedeckten Anteil selbst ab, nicht nur die Oberflaeche")
	data.initial_fuel = 24.0
	supply.configure(crafts, data)
	var legs := [["launch", "homebase", ""], ["jump", "homebase", "satellite_crash"], ["approach", "homebase", "satellite_crash"], ["surface_exit", "satellite_crash", "homebase"], ["jump", "satellite_crash", "homebase"], ["landing", "satellite_crash", "homebase"]]
	var expected_fuel := [23.0, 13.0, 12.0, 10.0, 0.0, 0.0]
	for index in legs.size():
		var leg: Array = legs[index]
		var booked: Dictionary = supply.apply_command({"contract_category": "singleplayer_supply", "operation": "consume_leg_fuel", "payload": {"craft_id": craft_id, "leg": leg[0], "origin_location_id": leg[1], "destination_location_id": leg[2]}, "request_id": "leg:%d" % index}, context)
		_check(booked.get("ok", false) and float(supply.get_supply_snapshot().fuel_by_craft_id[craft_id]) == expected_fuel[index], "Etappe %s bucht genau ihren Anteil (Rest %s)" % [leg[0], str(expected_fuel[index])])
	_check(float(supply.get_supply_snapshot().fuel_by_craft_id[craft_id]) == 0.0, "Hin- und Rueckflug zusammen kosten genau 24 und enden sicher bei 0")
	_flow.queue_free()
	await process_frame
	print("ROUNDTRIP_FUEL_RESULTS passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
