extends SceneTree
## Turmschuetzenplatz im Heimat-Speicherstand (28.11.2026, Paket RE Punkt 1).
## A) Turmschuetze per Ablegen belegen, speichern, laden: er sitzt noch auf dem Turmplatz, "frei" bleibt gleich und nie negativ.
## B) Zweites Speichern nach dem Laden bleibt stabil.
## C) Alter Stand ohne Feld "gunner" laedt weiter (Platz leer, nichts kaputt); falsche Eintraege (Pilot, Fremder) werden abgelehnt.
## Mit umgebogenem APPDATA starten (schreibt user://campaigns/introduction/checkpoint_v1.json).
const START = preload("res://scripts/meta/game_start_contract.gd")
const FLOW = preload("res://scenes/meta/meta_layer_test.tscn")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
var checks := 0
var failures := 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)
	else:
		print("PASS: ", label)
func _craft(screen: Node, id: String) -> Dictionary:
	for craft in Array(screen.get_operations_snapshot().get("crafts", [])):
		if String(Dictionary(craft).id) == id: return Dictionary(craft)
	return {}
func _status(runtime: Node, id: String) -> String:
	for person: Dictionary in runtime.get_snapshot().units:
		if String(person.unit_id) == id: return String(person.status)
	return ""
func advance_until(runtime: Node, sim: Node, ids: Array, status: String) -> bool:
	for i in range(6000):
		sim.call("_physics_process", 0.05)
		runtime.get("_screen").call("_debug_advance_homebase_direct_boarding", 0.05)
		var all := true
		for id in ids:
			if _status(runtime, String(id)) != status: all = false
		if all: return true
		if i % 100 == 0: await process_frame
	return false
func _open_flow(mode: String) -> Node:
	START.request_start(self, "campaign", mode)
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	await process_frame
	return flow
func _close_flow(flow: Node) -> void:
	flow.queue_free()
	await process_frame
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = await _open_flow("new")
	var screen: Node = flow.get_node("HomebaseScreen")
	var snapshot: Dictionary = screen.get_operations_snapshot()
	var craft_id: String = String(snapshot.selected_craft.id)
	var pilot_id: String = String(snapshot.selected_craft.pilot_id)
	var team: String = String(snapshot.fireteams[0].id)
	var team_ids: Array = []
	for member in Array(snapshot.fireteams[0].members): team_ids.append(String(Dictionary(member).id))
	var runtime: Node = flow.get("_singleplayer_runtime").get_base_personnel_runtime()
	var sim: Node = runtime.get_simulation_root()
	sim.set_physics_process(false)
	check(not pilot_id.is_empty() and not team_ids.is_empty(), "Testwelt hat Pilot und Trupp")
	var gunner_id: String = String(team_ids[0])
	# --- A) belegen, speichern, laden ---
	var result: Dictionary = screen.request_operation("board", {"craft_id": craft_id, "fireteam_id": team})
	check(result.get("ok", false), "Trupp steigt ein " + str(result))
	check(await advance_until(runtime, sim, team_ids, "aboard"), "Trupp sitzt wirklich an Bord")
	result = screen.request_operation("board_person", {"unit_id": gunner_id, "craft_id": craft_id, "seat": "gunner"})
	check(result.get("ok", false), "Person wird per Ablegen Turmschuetze " + str(result))
	var entry: Dictionary = _craft(screen, craft_id)
	check(String(entry.gunner_id) == gunner_id, "Turmschuetze steht vor dem Speichern auf dem Platz")
	var free_before: int = int(screen.call("_free_passenger_seats", entry))
	check(free_before >= 0, "Vor dem Speichern: frei ist nicht negativ (%d)" % free_before)
	check(String(screen.call("get_checkpoint_gunner_id", craft_id)) == gunner_id, "Speicher-Auskunft nennt den Turmschuetzen")
	var saved: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint", flow, flow.get("_singleplayer_runtime"), true)
	check(saved.get("ok", false), "Heimat-Speicherstand mit Turmschuetze wird geschrieben " + str(saved))
	var stored: Dictionary = STORE.load_checkpoint()
	check(stored.get("ok", false), "Gespeicherter Stand ist gueltig " + str(stored.get("reason", "")))
	var transport: Dictionary = {}
	if stored.get("ok", false): transport = Dictionary(Dictionary(stored.payload.hex_tactical).transport).get(craft_id, {})
	check(String(transport.get("gunner", "")) == gunner_id and transport.size() == 4, "Stand enthaelt das Feld gunner additiv (%s)" % str(transport.keys()))
	await _close_flow(flow)
	flow = await _open_flow("continue")
	screen = flow.get_node("HomebaseScreen")
	entry = _craft(screen, craft_id)
	check(String(entry.get("gunner_id", "")) == gunner_id, "Nach dem Laden sitzt der Turmschuetze noch auf dem Turmplatz (%s)" % str(entry.get("gunner_id", "")))
	var free_after: int = int(screen.call("_free_passenger_seats", entry))
	check(free_after == free_before and free_after >= 0, "Nach dem Laden: frei = %d (vorher %d), nie negativ" % [free_after, free_before])
	check(String(entry.get("pilot_id", "")) == pilot_id, "Pilot unveraendert")
	check(Array(entry.get("payload_unit_ids", [])).has(gunner_id), "Turmschuetze steht weiter im Schiff (zaehlt als an Bord)")
	# --- B) zweites Speichern nach dem Laden ---
	saved = flow.get("_campaign_start").call("save_home_checkpoint", flow, flow.get("_singleplayer_runtime"), true)
	check(saved.get("ok", false), "Speichern nach dem Laden gelingt " + str(saved))
	stored = STORE.load_checkpoint()
	var again: Dictionary = Dictionary(Dictionary(stored.payload.hex_tactical).transport).get(craft_id, {}) if stored.get("ok", false) else {}
	check(String(again.get("gunner", "")) == gunner_id, "Zweiter Stand traegt den Turmschuetzen weiter")
	# --- C) Fehleintraege abgelehnt, alter Stand ohne Feld laedt ---
	if stored.get("ok", false):
		var payload: Dictionary = stored.payload.duplicate(true)
		payload.hex_tactical.transport[craft_id]["gunner"] = pilot_id
		check(not bool(STORE.validate_payload(payload).get("ok", true)), "Pilot als Turmschuetze wird abgelehnt")
		payload.hex_tactical.transport[craft_id]["gunner"] = "niemand_im_schiff"
		check(not bool(STORE.validate_payload(payload).get("ok", true)), "Fremde Person als Turmschuetze wird abgelehnt")
		payload.hex_tactical.transport[craft_id]["gunner"] = ""
		check(not bool(STORE.validate_payload(payload).get("ok", true)), "Leerer Turmschuetze-Eintrag wird abgelehnt")
		payload.hex_tactical.transport[craft_id].erase("gunner")
		var legacy: Dictionary = STORE.save_checkpoint(payload)
		check(legacy.get("ok", false), "Alter Stand ohne Feld gunner ist gueltig und wird geschrieben " + str(legacy.get("reason", "")))
		await _close_flow(flow)
		flow = await _open_flow("continue")
		screen = flow.get_node("HomebaseScreen")
		entry = _craft(screen, craft_id)
		check(not entry.is_empty() and String(entry.get("gunner_id", "")).is_empty(), "Alter Stand laedt weiter: Turmplatz leer")
		check(String(entry.get("pilot_id", "")) == pilot_id and Array(flow.get("_all_team_units")).size() == 2, "Alter Stand: Pilot und Personal unveraendert")
		check(int(screen.call("_free_passenger_seats", entry)) >= 0, "Alter Stand: frei ist nicht negativ")
	await _close_flow(flow)
	print("GUNNER_CHECKPOINT checks=%d failures=%d passed=%d" % [checks, failures, checks - failures])
	quit(1 if failures else 0)
