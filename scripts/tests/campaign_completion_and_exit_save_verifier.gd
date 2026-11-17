extends SceneTree
## N10: Die Kampagne speichert zusaetzlich (1) sobald an der Basis ein Auftrag abgeschlossen wurde und (2) beim Beenden
## ueber das Menue (Spiel beenden und zurueck ins Hauptmenue).
## Gelesen wird die gespeicherte Datei und die Meta-Zaehler des Flows (campaign_save_attempts / campaign_save_successes,
## gesetzt von request_campaign_save). Der periodische Basis-Speicherpunkt zaehlt dort nicht mit.
const C = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const START = preload("res://scripts/meta/game_start_contract.gd")
const JOB := "satellite_recovery"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
	else:
		_failed += 1
	print("PASS: " if ok else "FAIL: ", label)


func _boot(action: String) -> Node:
	root.size = Vector2i(1280, 720)
	START.request_start(self, "campaign", action)
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	current_scene = flow
	for i in 24:
		await process_frame
	return flow


func _free_flow(flow: Node) -> void:
	flow.queue_free()
	current_scene = null
	for i in 4:
		await process_frame


func _attempts(flow: Node) -> int:
	return int(flow.get_meta("campaign_save_attempts", 0))


func _successes(flow: Node) -> int:
	return int(flow.get_meta("campaign_save_successes", 0))


## Status des Auftrags in der Datei auf der Platte ("" wenn keine Datei oder kein Eintrag).
func _disk_job_status(job_id: String) -> String:
	var loaded: Dictionary = STORE.load_checkpoint()
	if not bool(loaded.get("ok", false)): return ""
	var jobs: Dictionary = Dictionary(Dictionary(Dictionary(loaded.payload).get("campaign", {})).get("jobs", {}))
	return String(Dictionary(jobs.get(job_id, {})).get("status", ""))


func _disk_text() -> String:
	if not FileAccess.file_exists(STORE.DEFAULT_PATH): return ""
	return FileAccess.get_file_as_string(STORE.DEFAULT_PATH)


func _disk_chip_count() -> int:
	return _disk_text().count("satellite_chip")


func _grant_chip(runtime: Node, request_id: String) -> bool:
	var grant: Dictionary = runtime.call("_commit", "singleplayer_supply", "campaign_cargo", {"container_id": "base:homebase", "item_id": "satellite_chip", "amount": 1}, request_id, {"campaign_authorized": true})
	return bool(grant.get("ok", false))


## Auftrag angenommen, gestartet und der Chip liegt im Basislager: bereit zum Hochladen (Aufbau wie playtest_l01).
func _prepare_upload(flow: Node) -> bool:
	var screen: Node = flow.get_node("HomebaseScreen")
	var runtime: Node = flow.get("_singleplayer_runtime")
	var campaign: RefCounted = runtime.get("_campaign")
	var craft_id := String(Array(flow.get("_homebase_aircraft_definitions"))[0].craft_id)
	var ok: bool = bool(screen.call("request_operation", "accept_job", {"job_id": JOB}).get("ok", false))
	var departure := {"craft_id": craft_id, "origin_location_id": "homebase", "destination_location_id": "satellite_crash", "landing_pad_id": "homebase_pad_01", "job_id": JOB}
	ok = ok and bool(campaign.apply_command(C.build_command("bind_departure", departure, "n10:bind"), {"departure_authorized": true}).get("ok", false))
	ok = ok and bool(campaign.apply_command(C.build_command("activate_job", {"job_id": JOB, "craft_id": craft_id}, "n10:activate"), {"departure_authorized": true}).get("ok", false))
	return ok and _grant_chip(runtime, "n10:chip")


## Echter Blockadezustand: die Basisleute laufen zum Schiff (Speichern wird mit "Bewegung laeuft" abgelehnt).
func _start_boarding(flow: Node) -> bool:
	var screen: Node = flow.get_node("HomebaseScreen")
	var craft := String(Array(flow.get("_homebase_aircraft_definitions"))[0].craft_id)
	return bool(screen.call("request_operation", "base_board", {"craft_id": craft, "fireteam_id": "ft1", "whole_fireteam": true}).get("ok", false))


func _finish_boarding(flow: Node) -> bool:
	var screen: Node = flow.get_node("HomebaseScreen")
	var runtime: Node = flow.get("_singleplayer_runtime")
	var craft := String(Array(flow.get("_homebase_aircraft_definitions"))[0].craft_id)
	var personnel: Node = runtime.call("get_base_personnel_runtime")
	var sim: Node = personnel.call("get_simulation_root")
	for tick in range(3000):
		sim.call("_physics_process", 0.05)
		screen.call("_debug_advance_homebase_direct_boarding", 0.05)
		if personnel.call("is_pilot_aboard", craft) and bool(personnel.call("get_payload_presence", craft).all_aboard) and bool(screen.call("_has_homebase_direct_launch_payload_for_craft", craft)):
			return true
	return false


func _menu() -> Node:
	var menu: Node = root.get_node_or_null("GlobalEscapeMenu")
	if menu != null: menu.call("set_test_mode", true)
	return menu


func _run() -> void:
	# --- 1. Abschluss speichert ---
	var flow: Node = await _boot("new")
	var runtime: Node = flow.get("_singleplayer_runtime")
	_check(await _prepare_upload(flow), "1: Fixture: Auftrag aktiv, Chip im Basislager")
	await create_timer(1.2).timeout
	var attempts_before := _attempts(flow)
	_check(_disk_job_status(JOB) != "completed", "1: vor dem Hochladen ist der Auftrag auf der Platte nicht abgeschlossen")
	var upload: Dictionary = runtime.call("request_operation", "campaign_upload", {"job_id": JOB})
	_check(bool(upload.get("ok", false)), "1: campaign_upload angenommen")
	for i in 8: await process_frame
	await create_timer(1.6).timeout
	_check(_disk_job_status(JOB) == "completed", "1: der Stand auf der Platte enthaelt den Auftrag als completed")
	_check(_attempts(flow) - attempts_before == 1 and _successes(flow) == 1, "1: genau ein erzwungener Speichervorgang (Versuche +%d, gelungen %d)" % [_attempts(flow) - attempts_before, _successes(flow)])
	await create_timer(1.6).timeout
	_check(_attempts(flow) - attempts_before == 1, "1: danach kein weiteres Speichern ohne neuen Abschluss")
	await _free_flow(flow)

	# --- 3. Laden loest nichts aus (Datei aus 1 enthaelt einen abgeschlossenen Auftrag) ---
	_check(_disk_job_status(JOB) == "completed", "3: Fixture: die Datei enthaelt einen abgeschlossenen Auftrag")
	flow = await _boot("continue")
	await create_timer(2.0).timeout
	_check(_attempts(flow) == 0, "3: Laden eines Stands mit abgeschlossenem Auftrag loest kein Speichern aus (Versuche %d)" % _attempts(flow))
	await _free_flow(flow)

	# --- 2. Kein Speichern ohne Abschluss ---
	flow = await _boot("new")
	runtime = flow.get("_singleplayer_runtime")
	_check(_grant_chip(runtime, "n10:chip2"), "2: Fixture: Aenderung am Lager")
	runtime.call("request_operation", "refuel", {})
	await create_timer(2.0).timeout
	_check(_attempts(flow) == 0, "2: andere Aktionen loesen kein erzwungenes Speichern aus (Versuche %d)" % _attempts(flow))
	await _free_flow(flow)

	# --- 4. Wiederholen nach Ablehnung ---
	flow = await _boot("new")
	runtime = flow.get("_singleplayer_runtime")
	_check(await _prepare_upload(flow), "4: Fixture: Auftrag aktiv, Chip im Basislager")
	_check(_start_boarding(flow), "4: Fixture: Basisleute laufen zum Schiff")
	var probe: Dictionary = flow.call("request_campaign_save")
	_check(not bool(probe.get("ok", true)), "4: Fixture: Speichern ist waehrenddessen abgelehnt (Grund %s)" % String(probe.get("reason", "")))
	attempts_before = _attempts(flow)
	var successes_before := _successes(flow)
	runtime.call("request_operation", "campaign_upload", {"job_id": JOB})
	await create_timer(3.2).timeout
	var tried := _attempts(flow) - attempts_before
	_check(_successes(flow) == successes_before and _disk_job_status(JOB) != "completed", "4: solange blockiert, ist kein Stand geschrieben")
	_check(tried >= 1 and tried <= 5, "4: Wiederholung hoechstens einmal je Sekunde (%d Versuche in 3,2 s)" % tried)
	_check(await _finish_boarding(flow), "4: Fixture: Blockade endet (alle an Bord)")
	await create_timer(2.0).timeout
	_check(_successes(flow) == successes_before + 1 and _disk_job_status(JOB) == "completed", "4: nach dem Ende der Blockade genau ein Speichervorgang (gelungen %d)" % (_successes(flow) - successes_before))
	await _free_flow(flow)

	# --- 5. Beenden speichert ---
	flow = await _boot("new")
	runtime = flow.get("_singleplayer_runtime")
	var menu := _menu()
	_check(menu != null, "5: Menue-Autoload vorhanden")
	var chips_before := _disk_chip_count()
	_check(_grant_chip(runtime, "n10:chip5"), "5: Fixture: Aenderung seit dem letzten Speichern")
	_check(_disk_chip_count() == chips_before, "5: Fixture: die Aenderung ist noch nicht auf der Platte")
	attempts_before = _attempts(flow)
	var quit_result: Dictionary = menu.call("request_quit_game")
	_check(_disk_chip_count() > chips_before, "5: nach request_quit_game enthaelt die Platte die Aenderung")
	_check(_attempts(flow) - attempts_before == 1, "5: genau ein Speicherversuch beim Beenden (+%d)" % (_attempts(flow) - attempts_before))
	_check(bool(quit_result.get("ok", false)) and bool(menu.call("was_quit_requested_for_tests")), "5: Beenden laeuft nach gelungenem Speichern durch (Testmodus)")
	menu.call("request_quit_game", true)
	_check(_attempts(flow) - attempts_before == 1, "5: bestaetigter zweiter Aufruf speichert nicht noch einmal")
	await _free_flow(flow)

	# --- 6. Hauptmenue speichert ---
	flow = await _boot("new")
	runtime = flow.get("_singleplayer_runtime")
	menu = _menu()
	chips_before = _disk_chip_count()
	_check(_grant_chip(runtime, "n10:chip6"), "6: Fixture: Aenderung seit dem letzten Speichern")
	attempts_before = _attempts(flow)
	var menu_result: Dictionary = menu.call("return_to_main_menu", false)
	_check(_disk_chip_count() > chips_before, "6: nach return_to_main_menu enthaelt die Platte die Aenderung")
	_check(_attempts(flow) - attempts_before == 1, "6: genau ein Speicherversuch (+%d)" % (_attempts(flow) - attempts_before))
	_check(bool(menu_result.get("ok", false)), "6: Rueckkehr ins Hauptmenue laeuft durch")
	menu.call("return_to_main_menu", false, true)
	_check(_attempts(flow) - attempts_before == 1, "6: bestaetigter zweiter Aufruf speichert nicht noch einmal")
	await _free_flow(flow)

	# --- 7. Beenden bei abgelehntem Speichern ---
	flow = await _boot("new")
	runtime = flow.get("_singleplayer_runtime")
	menu = _menu()
	_check(_grant_chip(runtime, "n10:chip7"), "7: Fixture: Aenderung seit dem letzten Speichern")
	_check(_start_boarding(flow), "7: Fixture: Basisleute laufen zum Schiff")
	var refused: Dictionary = flow.call("request_campaign_save")
	_check(not bool(refused.get("ok", true)) and not String(refused.get("message", "")).is_empty(), "7: Fixture: Speichern abgelehnt, mit Satz (%s)" % String(refused.get("reason", "")))
	var refused_text := String(refused.get("message", ""))
	attempts_before = _attempts(flow)
	var asked: Dictionary = menu.call("request_quit_game")
	_check(_attempts(flow) - attempts_before == 1, "7: genau ein Speicherversuch vor der Nachfrage (+%d)" % (_attempts(flow) - attempts_before))
	_check(String(asked.get("reason", "")) == "confirmation_required" and not bool(menu.call("was_quit_requested_for_tests")), "7: bei abgelehntem Speichern bleibt die Nachfrage wie heute")
	var exit_label: Label = menu.get("_exit_label")
	_check(exit_label != null and exit_label.text.contains(refused_text), "7: die Nachfrage zeigt den Satz aus message")
	menu.call("request_quit_game", true)
	_check(bool(menu.call("was_quit_requested_for_tests")), "7: nach Bestaetigung laeuft das Beenden wie heute durch")
	_check(_attempts(flow) - attempts_before == 1, "7: der bestaetigte Aufruf speichert nicht noch einmal")
	await _free_flow(flow)

	# --- 8. Ausserhalb der Kampagne ---
	var stub_script := GDScript.new()
	stub_script.source_code = "extends Node\nvar campaign := false\nvar saves := 0\nfunc is_campaign_start() -> bool:\n\treturn campaign\nfunc request_campaign_save() -> Dictionary:\n\tsaves += 1\n\treturn {\"ok\": true}\n"
	stub_script.reload()
	var stub := Node.new()
	stub.set_script(stub_script)
	root.add_child(stub)
	current_scene = stub
	menu = _menu()
	menu.call("request_quit_game")
	_check(int(stub.get("saves")) == 0, "8: ausserhalb der Kampagne wird beim Beenden nicht gespeichert")
	menu.call("return_to_main_menu", false)
	_check(int(stub.get("saves")) == 0, "8: ausserhalb der Kampagne wird beim Wechsel ins Hauptmenue nicht gespeichert")
	stub.set("campaign", true)
	menu.call("request_quit_game")
	_check(int(stub.get("saves")) == 1, "8: Gegenprobe: dieselbe Szene als Kampagne speichert beim Beenden genau einmal (%d)" % int(stub.get("saves")))
	current_scene = null
	stub.queue_free()
	await process_frame

	print("campaign_completion_and_exit_save_verifier passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
