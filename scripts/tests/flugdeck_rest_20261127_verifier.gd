extends SceneTree
## Flugdeck-Rest (20261127): 1) Einsteigen ohne Pilot, Abheben verlangt einen Piloten; 2) Einzelperson auf Passagierplatz; 3) Turmschuetzenplatz belegbar.
## Die Turmschuetzen-Belegung ist Anzeige und Zaehlung "an Bord" (keine Schusslogik); der Speicherstand wird in gunner_checkpoint_20261128_verifier geprueft.
## Seit 28.11. nennen die Hinweise ohne Pilot die Handlung ("Ziehe eine Person auf den Pilotenplatz") statt "Pilot zuweisen".
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
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
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
	# --- 1) Einsteigen ohne Pilot ---
	var result: Dictionary = screen.request_operation("pilot", {"unit_id": "", "craft_id": craft_id})
	check(result.get("ok", false) and String(_craft(screen, craft_id).pilot_id).is_empty(), "Pilot vom Schiff genommen")
	result = screen.request_operation("board", {"craft_id": craft_id, "fireteam_id": team})
	check(result.get("ok", false) and String(result.get("reason", "")) != "pilot_missing", "Trupp darf ohne Pilot einsteigen " + str(result))
	check(await advance_until(runtime, sim, team_ids, "aboard"), "Trupp sitzt ohne Pilot wirklich an Bord")
	var entry: Dictionary = _craft(screen, craft_id)
	check(not bool(entry.can_start) and String(entry.status) == "Pilot fehlt" and String(entry.next_step) == "Ziehe eine Person auf den Pilotenplatz", "Ohne Pilot: kein Start, Hinweis mit Handlung (Person auf den Pilotenplatz ziehen) " + str([entry.status, entry.next_step]))
	result = screen.request_operation("start", {"craft_id": craft_id})
	check(not result.get("ok", true) and String(result.get("reason", "")) == "pilot_missing" and String(result.get("message", "")) == "Ziehe eine Person auf den Pilotenplatz", "Start ohne Pilot: klare Meldung mit Handlungshinweis " + str(result))
	var gate: Dictionary = flow.get("_singleplayer_runtime").validate_space_launch(craft_id, false)
	check(not gate.get("ok", true) and String(gate.get("reason", "")) == "pilot_missing" and String(gate.get("message", "")) == "Ziehe eine Person auf den Pilotenplatz", "Abheben (Laufzeit-Pruefung) ohne Pilot: Handlungshinweis " + str(gate))
	# --- 2) Einzelperson als Passagier (der ehemalige Pilot ist jetzt eine freie Person) ---
	var before_count: int = int(entry.passenger_count)
	result = screen.request_operation("board_person", {"unit_id": pilot_id, "craft_id": craft_id, "seat": "passenger"})
	check(result.get("ok", false), "Einzelperson auf Passagierplatz angenommen " + str(result))
	check(await advance_until(runtime, sim, [pilot_id], "aboard"), "Einzelperson geht wirklich an Bord")
	entry = _craft(screen, craft_id)
	check(Array(entry.payload_unit_ids).has(pilot_id) and int(entry.passenger_count) == before_count + 1 and int(entry.aboard_count) == int(entry.passenger_count), "Einzelperson zaehlt als Passagier an Bord (%d -> %d)" % [before_count, int(entry.passenger_count)])
	check(Array(entry.payload_unit_ids).size() == team_ids.size() + 1 and team_ids.all(func(id): return Array(entry.payload_unit_ids).has(id)), "Der Rest des Trupps ist unveraendert an Bord")
	result = screen.request_operation("board_person", {"unit_id": pilot_id, "craft_id": craft_id, "seat": "passenger"})
	check(result.get("ok", false) and bool(result.get("unchanged", false)), "Nochmaliges Ablegen derselben Person aendert nichts")
	result = screen.request_operation("board_person", {"unit_id": "niemand", "craft_id": craft_id})
	check(not result.get("ok", true) and String(result.reason) == "unknown_unit", "Unbekannte Person abgelehnt")
	# --- 3) Turmschuetzenplatz ---
	var other: String = team_ids[0]
	result = screen.request_operation("board_person", {"unit_id": other, "craft_id": craft_id, "seat": "gunner"})
	check(result.get("ok", false), "Person aus dem Schiff kann Turmschuetze werden " + str(result))
	entry = _craft(screen, craft_id)
	check(String(entry.gunner_id) == other and Array(entry.payload_unit_ids).has(other), "Turmschuetze steht im Schnappschuss und bleibt im Payload (zaehlt als an Bord)")
	check(int(entry.aboard_count) == int(entry.passenger_count) and bool(Array(entry.payload_aboard)[Array(entry.payload_unit_ids).find(other)]), "Turmschuetze zaehlt als an Bord")
	screen.request_operation("navigate", {"mode": "mission"})
	var presenter: Node = screen.get("_operations_presenter")
	presenter.refresh()
	for i in 6: await process_frame
	var shown: Node = presenter.find_child("GunnerName", true, false)
	check(shown != null and shown.text == String(screen.call("_build_display_name", other)), "Schiffsdetail zeigt den Turmschuetzen am Turmschuetzenplatz")
	var seat_names: Array = []
	for node in presenter.find_children("SeatName", "Label", true, false): seat_names.append((node as Label).text)
	check(not seat_names.has(String(screen.call("_build_display_name", other))), "Turmschuetze steht nicht zusaetzlich auf einem Passagierplatz " + str(seat_names))
	result = screen.request_operation("board_person", {"unit_id": pilot_id, "craft_id": craft_id, "seat": "gunner"})
	check(not result.get("ok", true) and String(result.reason) == "gunner_taken", "Besetzter Turmschuetzenplatz nimmt keine zweite Person an")
	result = screen.request_operation("board_person", {"unit_id": other, "craft_id": craft_id, "seat": "passenger"})
	check(result.get("ok", false) and String(_craft(screen, craft_id).gunner_id).is_empty(), "Zurueck auf einen Passagierplatz gibt den Turmschuetzenplatz frei")
	screen.request_operation("board_person", {"unit_id": other, "craft_id": craft_id, "seat": "gunner"})
	# Absetzen des Trupps nimmt den Turmschuetzenplatz mit.
	result = screen.request_operation("unboard", {"craft_id": craft_id, "fireteam_id": team})
	check(result.get("ok", false), "Trupp absetzen " + str(result))
	await advance_until(runtime, sim, [other], "outside")
	check(String(_craft(screen, craft_id).gunner_id).is_empty(), "Nach dem Absetzen ist der Turmschuetzenplatz leer")
	# Pilot zurueck: der Pilot nimmt keinen Passagier- oder Turmschuetzenplatz.
	result = screen.request_operation("pilot", {"unit_id": pilot_id, "craft_id": craft_id})
	check(result.get("ok", false), "Pilot wieder zugewiesen " + str(result))
	result = screen.request_operation("board_person", {"unit_id": pilot_id, "craft_id": craft_id, "seat": "gunner"})
	check(not result.get("ok", true) and String(result.reason) == "pilot_seat", "Der Pilot kann nicht Turmschuetze sein")
	flow.queue_free()
	await process_frame
	print("FLUGDECK_REST checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
