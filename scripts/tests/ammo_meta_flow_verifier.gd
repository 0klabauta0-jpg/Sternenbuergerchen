extends SceneTree
## M4c (W2/W3/W4): Munition im echten Meta-Ablauf (echte Szene meta_layer_test, echte neue Kampagne, echter Speicher- und Lade-Weg).
##   A Neue Kampagne: Startausstattung genau einmal (Lager 16/8, Merker); echte Startaufstellung (Anzug, keine Waffe) -> Fach leer
##   B Abflug von der Heimatbasis (replenish_ammo_for_departure, die Funktion hinter launch_to_moon_orbit): Pistole angelegt -> Fach voll,
##     Lager kleiner, zweiter Aufruf aendert nichts; fehlt Vorrat, nennt die Abflugzeile "Munition knapp"
##   C Heimkehr (_replenish_ammo_after_landing): Fach wieder voll; die Meldung steht im Hinweis der Landungs-Speicherung
##   D Laden: derselbe Stand zweimal verschenkt nichts; ein alter Stand ohne Merker bekommt die Ausstattung einmal nachgereicht
##   E Einhaengepunkte als Quelltext-Vertrag (Reihenfolge der Aufrufe), soweit ohne Szene nicht ausloesbar (Anwerbeschleife, Landung)
## Schlusszeile: AMMO_META_FLOW passed=N failed=M. Braucht ein Wegwerfprofil (SB_REVIEW2_USER_DIR), sonst Abbruch ohne Schreiben.
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const START = preload("res://scripts/meta/game_start_contract.gd")
const FLOW: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const FLOW_SRC := "res://scripts/meta/meta_layer_flow.gd"
const ADAPTER_SRC := "res://scripts/meta/singleplayer_runtime_adapter.gd"
const LEADER := "campaign_leader"
const PILOT := "campaign_pilot"
var _passed := 0
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var verdict: Dictionary = GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("AMMO_META_FLOW refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	await _parts_a_b_c()
	await _part_b2_real_launch()
	await _part_d_load_twice_and_old_state()
	_part_e_source_contract()
	print("AMMO_META_FLOW passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _check(value: bool, label: String) -> bool:
	if value:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)
	return value

func _open(action: String) -> Node:
	START.request_start(self, "campaign", action)
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	await process_frame
	return flow

func _close(flow: Node) -> void:
	flow.queue_free()
	await process_frame

func _inv(runtime: Node) -> Dictionary:
	return Dictionary(Dictionary(runtime.call("get_snapshot")).supply.inventory)

func _base_n(runtime: Node, item: String) -> int:
	return int(Dictionary(Dictionary(_inv(runtime).get("base:homebase", {})).get("items", {})).get(item, 0))

func _bag_n(runtime: Node, id: String, item: String) -> int:
	return int(Dictionary(Dictionary(_inv(runtime).get("unit:%s:backpack" % id, {})).get("items", {})).get(item, 0))

func _equip_pistol(flow: Node, runtime: Node, unit_id: String) -> bool:
	var craft := String(flow.get_meta("singleplayer_bootstrap_craft_id"))
	var result: Dictionary = flow.get_node("HomebaseScreen").call("request_operation", "inventory_equip", {"unit_id": unit_id, "craft_id": craft, "source_container_id": "base:homebase", "item_id": "pistol", "slot": "weapon_1"})
	return _check(bool(result.get("ok", false)), "Aufbau: Pistole an %s angelegt ueber die echte Operation: %s" % [unit_id, str(result)])

## Truppfuehrerin und Pilot steigen ueber die echte Operation ein (Muster campaign_launch_actionability_verifier).
func _board_everyone(flow: Node, runtime: Node, craft: String) -> void:
	var screen: Control = flow.get_node("HomebaseScreen")
	screen.call("request_operation", "navigate", {"mode": "mission"})
	var selected: Dictionary = screen.call("get_operations_snapshot").get("selected_craft", {})
	if Array(selected.get("payload_fireteam_ids", [])).is_empty():
		screen.call("request_operation", "board", {"craft_id": craft, "fireteam_id": "ft1"})
	var personnel: Node = runtime.call("get_base_personnel_runtime")
	screen.call("request_operation", "base_board", {"craft_id": craft, "fireteam_id": "ft1", "whole_fireteam": true})
	var sim: Node = personnel.call("get_simulation_root")
	for tick in range(3000):
		sim.call("_physics_process", 0.05)
		screen.call("_debug_advance_homebase_direct_boarding", 0.05)
		if personnel.call("is_pilot_aboard", craft) and Array(flow.call("_aboard_unit_ids_of_craft", craft)).has(LEADER):
			break

func _parts_a_b_c() -> void:
	var flow: Node = await _open("new")
	var runtime: Node = flow.get("_singleplayer_runtime")
	if not _check(runtime != null, "A: neue Kampagne hat ihre Laufzeit"):
		await _close(flow)
		return
	var craft := String(flow.get_meta("singleplayer_bootstrap_craft_id"))
	var sup: RefCounted = runtime.get("_supply")
	# A: Startausstattung genau einmal; die echte Startaufstellung hat nur den Anzug, also bleibt jedes Fach leer.
	_check(_base_n(runtime, "ammo_light") == 16 and _base_n(runtime, "ammo_rifle") == 8, "A: Lager der neuen Kampagne 16 leichte, 8 Gewehr-Magazine (%d/%d)" % [_base_n(runtime, "ammo_light"), _base_n(runtime, "ammo_rifle")])
	_check(bool(Dictionary(sup.export_state()).get("ammo_start_granted", false)), "A: der Stand traegt den Merker der gewaehrten Startausstattung")
	_check(_bag_n(runtime, LEADER, "ammo_light") == 0 and _bag_n(runtime, PILOT, "ammo_light") == 0, "A: echte Startaufstellung (Anzug, keine Waffe): beide Faecher leer")
	_check(not bool(runtime.call("grant_ammo_start_if_missing")) and _base_n(runtime, "ammo_light") == 16, "A: ein zweiter Aufruf gewaehrt nichts mehr")
	# M4d P1: der nicht gespeicherte Kampagnen-Schalter steht in der neuen Kampagne auf wahr; eine Versorgung ohne Kampagne hat ihn nicht.
	_check(bool(sup.get("_campaign_magazine_mode")) and bool(sup.call("person_has_magazine_store", LEADER)), "A: Kampagnen-Schalter des Magazinvorrats steht in der neuen Kampagne auf wahr")
	var bare: RefCounted = load("res://scripts/core/singleplayer_supply_state.gd").new()
	_check(not bool(bare.get("_campaign_magazine_mode")) and not bool(bare.call("person_has_magazine_store", LEADER)), "A: eine Versorgung ohne Kampagne hat den Schalter nicht")
	# B: Abflug. Truppfuehrerin nimmt sich eine Pistole; ohne Auffuellen flöge sie mit leerem Fach los.
	_equip_pistol(flow, runtime, LEADER)
	_check(_bag_n(runtime, LEADER, "ammo_light") == 0, "B: nach dem Anlegen der Pistole ist das Fach noch leer")
	_board_everyone(flow, runtime, craft)
	var aboard: Array = Array(flow.call("_aboard_unit_ids_of_craft", craft))
	_check(aboard.has(LEADER), "B: die Truppfuehrerin ist an Bord des Startschiffs (%s)" % str(aboard))
	var ready: Dictionary = Dictionary(runtime.call("replenish_ammo_for_departure", craft, [LEADER, PILOT]))
	_check(_bag_n(runtime, LEADER, "ammo_light") == 1 and _base_n(runtime, "ammo_light") == 15, "B: Abflug: Fach der Truppfuehrerin voll (1 leichtes Magazin), Lager 16 -> 15 (%d/%d)" % [_bag_n(runtime, LEADER, "ammo_light"), _base_n(runtime, "ammo_light")])
	_check(_bag_n(runtime, PILOT, "ammo_light") == 0 and String(ready.get("short_message", "x")).is_empty(), "B: der Pilot ohne Waffe bekommt nichts; nichts fehlt, also keine Knapp-Meldung")
	var again: Dictionary = Dictionary(runtime.call("replenish_ammo_for_departure", craft, [LEADER, PILOT]))
	_check(int(again.get("added", -1)) == 0 and _bag_n(runtime, LEADER, "ammo_light") == 1 and _base_n(runtime, "ammo_light") == 15, "B: zweiter Aufruf (Abbruch und erneutes Bestaetigen) aendert nichts")
	sup.take_person_magazine(LEADER, "ammo_light")
	Dictionary(Dictionary(sup._inventory["base:homebase"]).items).erase("ammo_light")
	var scarce: Dictionary = Dictionary(runtime.call("replenish_ammo_for_departure", craft, [LEADER, PILOT]))
	_check(_bag_n(runtime, LEADER, "ammo_light") == 0 and String(scarce.get("short_message", "")) == "Munition knapp: 1 Fach blieb leer.", "B: ohne Vorrat im Lager bleibt das Fach leer, nie ins Minus; Meldung '%s'" % str(scarce.get("short_message")))
	flow.call("_report_launch_save", {}, String(scarce.short_message))
	_check(String(flow.get_meta("campaign_save_feedback", "")) == "Munition knapp: 1 Fach blieb leer.", "B: die Abflugzeile zeigt 'Munition knapp' (%s)" % String(flow.get_meta("campaign_save_feedback", "")))
	flow.call("_report_launch_save", {"ok": true}, String(scarce.short_message))
	_check(String(flow.get_meta("campaign_save_feedback", "")) == "Gespeichert. Munition knapp: 1 Fach blieb leer.", "B: mit gelungener Speicherung vor dem Abheben: ein Hinweis, eine Zeile (%s)" % String(flow.get_meta("campaign_save_feedback", "")))
	# C: Heimkehr. Vorrat wieder ins Lager, Fach geleert, Landung: Fach voll, Meldung im Hinweis der Landungs-Speicherung.
	Dictionary(Dictionary(sup._inventory["base:homebase"]).items)["ammo_light"] = 5
	flow.call("_replenish_ammo_after_landing", craft, [LEADER])
	_check(_bag_n(runtime, LEADER, "ammo_light") == 1 and _base_n(runtime, "ammo_light") == 4, "C: Heimkehr fuellt das Fach auf (1), Lager 5 -> 4")
	_check(String(flow.get_meta("ammo_refill_message", "")) == "Munition aufgefüllt: 1 Magazin.", "C: Meldung 'Munition aufgefüllt: 1 Magazin.' (%s)" % String(flow.get_meta("ammo_refill_message", "")))
	var seen_before := int(flow.get_meta("campaign_save_feedback_count", 0))
	flow.call("_arm_landing_save")
	flow.call("_poll_completion_save")
	var toast := String(flow.get_meta("campaign_save_feedback", ""))
	_check(int(flow.get_meta("campaign_save_feedback_count", 0)) == seen_before + 1 and toast == "Gespeichert. Munition aufgefüllt: 1 Magazin.", "C: ein einziger Hinweis der Landungs-Speicherung enthaelt die Meldung (%s)" % toast)
	flow.call("_arm_landing_save")
	flow.call("_poll_completion_save")
	_check(String(flow.get_meta("campaign_save_feedback", "")) == "Gespeichert.", "C: die naechste Landung ohne Auffuellen sagt wieder nur 'Gespeichert.' (%s)" % String(flow.get_meta("campaign_save_feedback", "")))
	await _close(flow)

## M4d P4: der echte Abflug (launch_to_moon_orbit) fuellt das Fach der Mitfliegenden auf. Eigene neue Kampagne, weil das Schiff danach im Flug ist.
## Deckt auch den Fall, dass die Personen nach dem Abheben nicht mehr "aboard" sind (Bordliste dann leer): die Liste wird vorher gelesen.
func _part_b2_real_launch() -> void:
	var flow: Node = await _open("new")
	var runtime: Node = flow.get("_singleplayer_runtime")
	if not _check(runtime != null, "B2: neue Kampagne hat ihre Laufzeit"):
		await _close(flow)
		return
	var craft := String(flow.get_meta("singleplayer_bootstrap_craft_id"))
	_equip_pistol(flow, runtime, LEADER)
	_board_everyone(flow, runtime, craft)
	_check(Array(flow.call("_aboard_unit_ids_of_craft", craft)).has(LEADER), "B2: die Truppfuehrerin ist an Bord")
	var screen: Control = flow.get_node("HomebaseScreen")
	screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery", "request_id": "m4d:accept"})
	screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery", "request_id": "m4d:dest"})
	var launch: Dictionary = Dictionary(runtime.call("launch_to_moon_orbit", craft))
	_check(bool(launch.get("ok", false)), "B2: der echte Abflug (launch_to_moon_orbit) gelingt: %s" % str(launch).left(160))
	_check(_bag_n(runtime, LEADER, "ammo_light") == 1 and _base_n(runtime, "ammo_light") == 15, "B2: der Abflug selbst fuellt das Fach der Truppfuehrerin (%d), Lager 16 -> 15 (%d)" % [_bag_n(runtime, LEADER, "ammo_light"), _base_n(runtime, "ammo_light")])
	await _close(flow)

func _save_new_campaign(strip_marker: bool) -> bool:
	var flow: Node = await _open("new")
	var runtime: Node = flow.get("_singleplayer_runtime")
	if not _check(runtime != null, "D: neue Kampagne hat ihre Laufzeit"):
		await _close(flow)
		return false
	var sup: RefCounted = runtime.get("_supply")
	_equip_pistol(flow, runtime, LEADER)
	if strip_marker:
		# Ein Stand, wie ihn die Fassung vor M4b schrieb: kein Merker, keine Magazine im Lager und in den Faechern.
		sup._ammo_start_granted = false
		for key in ["base:homebase", "unit:%s:backpack" % LEADER, "unit:%s:backpack" % PILOT]:
			var items: Dictionary = Dictionary(Dictionary(sup._inventory[key]).items)
			items.erase("ammo_light")
			items.erase("ammo_rifle")
		_check(not Dictionary(sup.export_state()).has("ammo_start_granted"), "D: alter Stand: der gespeicherte Stand traegt keinen Merker")
	var saved: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint", flow, runtime, true)
	var ok := _check(bool(saved.get("ok", false)) and not bool(saved.get("throttled", false)), "D: erzwungenes Speichern gelingt: " + str(saved))
	await _close(flow)
	return ok

func _load_and_check(label: String, light: int, rifle: int, leader_bag: int) -> void:
	var flow: Node = await _open("continue")
	var runtime: Node = flow.get("_singleplayer_runtime")
	if _check(runtime != null, "D: %s: Fortsetzen liefert eine Laufzeit" % label):
		_check(_base_n(runtime, "ammo_light") == light and _base_n(runtime, "ammo_rifle") == rifle, "D: %s: Lager %d/%d (%d/%d)" % [label, light, rifle, _base_n(runtime, "ammo_light"), _base_n(runtime, "ammo_rifle")])
		_check(_bag_n(runtime, LEADER, "ammo_light") == leader_bag, "D: %s: Fach der Truppfuehrerin %d (%d)" % [label, leader_bag, _bag_n(runtime, LEADER, "ammo_light")])
		_check(bool(runtime.get("_supply").get("_campaign_magazine_mode")), "D: %s: Kampagnen-Schalter nach dem Laden wahr" % label)
	await _close(flow)

func _part_d_load_twice_and_old_state() -> void:
	# Stand MIT Merker: Laden verschenkt nichts, auch beim zweiten Mal nicht (Lager bleibt 16/8, das leere Fach bleibt leer).
	if await _save_new_campaign(false):
		await _load_and_check("Stand mit Merker, erstes Laden", 16, 8, 0)
		await _load_and_check("Stand mit Merker, zweites Laden", 16, 8, 0)
	# Alter Stand OHNE Merker: einmal nachgereicht (Lager 16/8, Fach der bewaffneten Truppfuehrerin voll); dieselbe Datei nochmals laden
	# gibt wieder dasselbe, nichts doppelt.
	if await _save_new_campaign(true):
		await _load_and_check("alter Stand, erstes Laden", 16, 8, 1)
		await _load_and_check("alter Stand, zweites Laden derselben Datei", 16, 8, 1)

## Reihenfolge der Aufrufe im Quelltext: dort, wo die Szene den Ablauf nicht ausloest (Landung eines Schiffs, Anwerbeschleife auf Polisa).
func _between(text: String, from_marker: String, to_marker: String) -> String:
	var a := text.find(from_marker)
	if a < 0: return ""
	var b := text.find(to_marker, a)
	return text.substr(a, (b - a) if b > a else text.length() - a)

func _part_e_source_contract() -> void:
	var flow_src := FileAccess.get_file_as_string(FLOW_SRC).replace("\r\n", "\n")
	var adapter_src := FileAccess.get_file_as_string(ADAPTER_SRC).replace("\r\n", "\n")
	var grant_at := flow_src.find("\"grant_ammo_start_if_missing\")")
	var save_at := flow_src.find("save_home_checkpoint(self,_singleplayer_runtime,true)", grant_at)
	_check(grant_at > 0 and save_at > grant_at and save_at - grant_at < 400, "E: Startausstattung wird gewaehrt, bevor die neue Kampagne zum ersten Mal speichert")
	var landing := _between(flow_src, "func _finish_space_home_landing(", "\nfunc _replenish_ammo_after_landing")
	var seen_at := landing.find("observe_campaign_progress")
	var refill_at := landing.find("_replenish_ammo_after_landing(craft_id, ammo_refill_ids)")
	var arm_at := landing.find("_arm_landing_save()")
	_check(seen_at > 0 and refill_at > seen_at and arm_at > refill_at, "E: Heimkehr fuellt auf, nachdem der Fortschritt gesehen ist und bevor die Landungs-Speicherung angespannt wird")
	var crew_at := landing.find("_aboard_unit_ids_of_craft(craft_id)")
	var stepped_off_at := landing.find("_admit_unplaced_aboard_crew(craft_id)")
	_check(crew_at > 0 and stepped_off_at > crew_at, "E: die Besatzung wird gelesen, bevor sie aussteigt")
	var launch := _between(adapter_src, "func launch_to_moon_orbit(", "\nfunc _publish_space_launch_event")
	var commit_at := launch.find("commit_singleplayer_space_launch")
	var depart_fill_at := launch.find("replenish_ammo_for_departure(craft_id")
	_check(commit_at > 0 and depart_fill_at > commit_at and launch.contains("result.get(\"replayed\", false) else replenish_ammo_for_departure"), "E: der Abflug fuellt erst nach bestaetigtem Abflug auf, nie bei Wiederholung desselben Beleges")
	_check(adapter_src.count("replenish_ammo_for_departure(") == 2 and flow_src.count("replenish_ammo_for_departure") == 0, "E: der Abflug-Aufruf steht nur in launch_to_moon_orbit (kein Auffuellen beim Oeffnen eines Dialogs oder an anderen Orten)")
	var recruit := _between(adapter_src, "func _advance_polisa_recruitment()", "\nfunc get_polisa_snapshot")
	var finalize_at := recruit.find("\"station_recruit_finalize\"")
	var provision_at := recruit.find("provision_new_person(")
	var ok_at := recruit.find("if result.get(\"ok\", false):", finalize_at)
	_check(finalize_at > 0 and ok_at > finalize_at and provision_at > ok_at and recruit.count("provision_new_person(") == 1, "E: K2: die neue Person bekommt ihr Fach genau einmal und erst nach abgeschlossener Anwerbung")
