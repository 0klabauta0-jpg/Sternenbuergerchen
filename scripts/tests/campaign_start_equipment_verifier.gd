extends SceneTree
## Startausruestung der NEUEN Kampagne (Auftrag P1 "Tutorial-Pfeile", 21.11.2026).
## Die zwei Startpersonen (campaign_leader, campaign_pilot) tragen nur den Raumanzug (suit / none / none).
## Im Basislager liegen 2 Pistolen und 1 Sanitaetsgeraet, keine leichte Ruestung. Damit muss der Spieler das Ausruesten
## per Drag and Drop gleich lernen.
##   A Lager nach configure_start_inventory("campaign"); Skirmish-Modus aendert nichts
##   B Ein VOR der Aenderung geschriebener Basisstand (mit 2 leichten Ruestungen) laesst sich weiter laden und bleibt unveraendert
##   C Die leichte Ruestung bleibt erreichbar: Satellitenauftrag -> Erwerbserlaubnis light_armor -> Polisa-Angebot kaufbar
##   D Echte neue Kampagne: Loadout-Besitzer, Ansicht und Lager; die Pistole laesst sich ueber die oeffentliche Ausruestungs-Operation anlegen
##   E Ganzer Spielstand: neue Kampagne, beide Personen auf den alten Zustand ausruesten (Pistolen, Sanitaetsgeraet), erzwungen speichern,
##     ueber "Fortsetzen" laden; Ausruestung je Person und Lager bleiben wie gespeichert (Startwerte werden beim Laden nicht erneut gesetzt)
## Nicht hier, sondern in anderen Tests: das Ziehen per Maus (character_navigation_equipment_verifier), der Einsatz mit
## unbewaffnetem Truppfuehrer (campaign_intro_loop_smoke), der Gefechtseinsatz mit einer Pistole (campaign_five_actual_sorties_verifier),
## das Fortsetzen alter Staende (main_legacy_checkpoint_verifier, campaign_preparation_continue_test).
## Abschlusszeile: CAMPAIGN_START_EQUIPMENT passed=%d failed=%d
## Braucht ein Wegwerfprofil (SB_REVIEW2_USER_DIR), sonst Abbruch ohne Schreiben.

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const START = preload("res://scripts/meta/game_start_contract.gd")
const FLOW: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const SUPPLY_COMMANDS = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
const CAMPAIGN_COMMANDS = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const CAMPAIGN_STATE = preload("res://scripts/core/singleplayer_campaign_state.gd")
const START_PEOPLE := ["campaign_leader", "campaign_pilot"]

var _passed := 0
var _failed := 0
var _sequence := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var verdict: Dictionary = GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_START_EQUIPMENT refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_part_a_start_inventory()
	_part_b_old_base_state_loads()
	_part_c_light_armor_chain()
	await _part_d_real_new_campaign()
	await _part_e_continue_keeps_saved_equipment()
	print("CAMPAIGN_START_EQUIPMENT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _new_supply() -> RefCounted:
	var supply: RefCounted = SUPPLY.new()
	_check(bool(Dictionary(supply.configure(["dropship_1"])).get("ok", false)), "supply configures")
	supply.configure_inventory(["campaign_leader"], ["dropship_1"])
	return supply

func _base_items(supply: RefCounted) -> Dictionary:
	return Dictionary(Dictionary(supply.get_supply_snapshot().inventory["base:homebase"]).get("items", {}))

func _part_a_start_inventory() -> void:
	var supply: RefCounted = _new_supply()
	supply.configure_start_inventory("campaign")
	var items: Dictionary = _base_items(supply)
	_check(int(items.get("pistol", 0)) == 2, "A: Basislager hat genau 2 Pistolen: " + str(items))
	_check(int(items.get("medictool", 0)) == 1, "A: Basislager hat genau 1 Sanitaetsgeraet: " + str(items))
	_check(int(items.get("armor_light", 0)) == 0, "A: Basislager hat keine leichte Ruestung: " + str(items))
	_check(items.keys().size() == 2, "A: Basislager enthaelt nur Pistole und Sanitaetsgeraet: " + str(items))
	var other: RefCounted = _new_supply()
	var before: Dictionary = _base_items(other).duplicate(true)
	other.configure_start_inventory("skirmish")
	_check(_base_items(other) == before, "A: nur der Modus campaign setzt den neuen Startbestand")

func _part_b_old_base_state_loads() -> void:
	# Ein Stand, wie ihn die Fassung vor P1 schrieb: 2 leichte Ruestungen, 2 Pistolen, 1 Sanitaetsgeraet im Basislager.
	var old: RefCounted = _new_supply()
	old.configure_start_inventory("campaign")
	for i in 2:
		_check(bool(Dictionary(old.receive_skirmish_equipment("armor_light")).get("ok", false)), "B: alter Stand: leichte Ruestung %d ins Lager gelegt" % [i + 1])
	var saved: Dictionary = old.export_state()
	var restored: RefCounted = SUPPLY.new()
	var result: Dictionary = restored.restore_state(JSON.parse_string(JSON.stringify(saved)))
	_check(bool(result.get("ok", false)), "B: alter Basisstand laesst sich weiter laden: " + str(result))
	var items: Dictionary = _base_items(restored)
	_check(int(items.get("armor_light", 0)) == 2 and int(items.get("pistol", 0)) == 2 and int(items.get("medictool", 0)) == 1, "B: geladener alter Stand behaelt seinen Bestand unveraendert: " + str(items))

func _campaign_call(owner: RefCounted, operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	_sequence += 1
	return owner.apply_command(CAMPAIGN_COMMANDS.build_command(operation, payload, "p1:%d" % _sequence), context)

func _part_c_light_armor_chain() -> void:
	var owner: RefCounted = CAMPAIGN_STATE.new()
	var supply: RefCounted = _new_supply()
	supply.configure_start_inventory("campaign")
	_check(bool(Dictionary(owner.configure()).get("ok", false)), "C: Auftragsstand konfiguriert")
	var offer := "polisa_armor_light"
	var context := {"location_id": "polisa", "craft_id": "dropship_1", "craft_busy": false, "require_blueprints": true}
	var locked: Dictionary = supply.apply_command(SUPPLY_COMMANDS.build_command("buy", {"offer_id": offer, "quantity": 1}, "p1:buy:locked"), context)
	_check(not bool(locked.get("ok", false)) and String(locked.get("reason", "")) == "blueprint_locked", "C: vor dem Satellitenauftrag ist die leichte Ruestung auf Polisa gesperrt: " + str(locked))
	var id := "satellite_recovery"
	var job: Dictionary = owner.get_campaign_snapshot().jobs[id]
	_check(bool(_campaign_call(owner, "accept_job", {"job_id": id}).get("ok", false)), "C: Satellitenauftrag annehmbar")
	var departure := {"craft_id": "dropship_1", "origin_location_id": "homebase", "destination_location_id": job.location_id, "landing_pad_id": "homebase_pad_01", "job_id": id}
	_check(bool(_campaign_call(owner, "bind_departure", departure, {"departure_authorized": true}).get("ok", false)), "C: Abflug gebunden")
	_check(bool(_campaign_call(owner, "activate_job", {"job_id": id, "craft_id": "dropship_1"}, {"departure_authorized": true}).get("ok", false)), "C: Auftrag aktiv")
	var evidence := {"runtime_evidence": {"scenario_id": job.scenario_id, "result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": job.required_step_ids}}}
	var done: Dictionary = _complete_job(owner, id, evidence)
	_check(bool(done.get("ok", false)), "C: Satellitenauftrag mit allen Schritten abgeschlossen (ohne Gegner, ohne Waffe)")
	if bool(job.home_upload):
		done = _campaign_call(owner, "upload_job", {"job_id": id}, {"at_home": true})
		_check(bool(done.get("ok", false)), "C: Chip zu Hause hochgeladen")
	var receipt: Dictionary = done.get("completion_receipt", {})
	var reward: Dictionary = supply.apply_command(SUPPLY_COMMANDS.build_command("apply_reward", {"completion_id": receipt.get("completion_id", "")}, "p1:reward"), {"completion_receipt": receipt})
	_check(bool(reward.get("ok", false)), "C: Belohnung des ersten Auftrags wird vergeben: " + str(reward))
	_check(Array(supply.get_supply_snapshot().blueprints).has("light_armor"), "C: Erwerbserlaubnis (Kennung light_armor) ist vorhanden")
	var credits_before: int = int(supply.get_supply_snapshot().credits)
	var unlocked: Dictionary = supply.apply_command(SUPPLY_COMMANDS.build_command("buy", {"offer_id": offer, "quantity": 1}, "p1:buy:open"), context)
	_check(bool(unlocked.get("ok", false)), "C: danach ist die leichte Ruestung auf Polisa kaufbar (Preis aus den Daten bezahlbar): " + str(unlocked))
	_check(int(supply.get_supply_snapshot().credits) < credits_before, "C: der Kauf kostet Credits")
	var ship_items: Dictionary = Dictionary(Dictionary(supply.get_supply_snapshot().inventory["craft:dropship_1"]).get("items", {}))
	_check(int(ship_items.get("armor_light", 0)) == 1, "C: die gekaufte leichte Ruestung liegt im Schiffslager: " + str(ship_items))

func _complete_job(owner: RefCounted, id: String, evidence: Dictionary) -> Dictionary:
	return _campaign_call(owner, "complete_job", {"job_id": id, "craft_id": "dropship_1"}, evidence)

func _part_d_real_new_campaign() -> void:
	START.request_start(self, "campaign", "new")
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	var runtime: Node = flow.get("_singleplayer_runtime")
	if not _check(runtime != null, "D: echte Kampagne hat ihre Laufzeit"):
		flow.queue_free()
		await process_frame
		return
	var craft := String(flow.get_meta("singleplayer_bootstrap_craft_id"))
	var owner_state: Dictionary = Dictionary(runtime.get("_simulation").call("get_personnel_loadout_state").call("get_snapshot"))
	for id: String in START_PEOPLE:
		var from_owner: Dictionary = Dictionary(owner_state.get(id, {}))
		_check(String(from_owner.get("armor", "")) == "suit" and String(from_owner.get("weapon_1", "")) == "none" and String(from_owner.get("weapon_2", "")) == "none", "D: Loadout-Besitzer: %s traegt nur den Raumanzug: %s" % [id, str(from_owner)])
		var from_screen: Dictionary = screen.call("_get_member_loadout", id)
		_check(String(from_screen.get("armor", "")) == "suit" and String(from_screen.get("weapon_1", "")) == "none" and String(from_screen.get("weapon_2", "")) == "none", "D: Bildschirm-Loadout: %s: %s" % [id, str(from_screen)])
		var from_view: Dictionary = Dictionary(Dictionary(screen.call("get_personnel_inventory_view", id)).get("unit", {})).get("loadout", {})
		_check(String(from_view.get("armor", "")) == "suit" and String(from_view.get("weapon_1", "")) == "none" and String(from_view.get("weapon_2", "")) == "none", "D: Inventarsicht: %s: %s" % [id, str(from_view)])
	for unit: Variant in Array(flow.get("_all_team_units")):
		if typeof(unit) != TYPE_DICTIONARY or not START_PEOPLE.has(String(Dictionary(unit).get("unit_id", ""))):
			continue
		var profile: Dictionary = unit
		_check(String(profile.get("armor_id", "suit")) == "suit" and String(profile.get("weapon_1_id", "none")) == "none" and String(profile.get("weapon_2_id", "none")) == "none", "D: Profil von %s stimmt mit dem Besitzer ueberein" % String(profile.get("unit_id", "")))
	var items: Dictionary = Dictionary(Dictionary(Dictionary(runtime.call("get_snapshot")).supply.inventory["base:homebase"]).get("items", {}))
	_check(int(items.get("pistol", 0)) == 2 and int(items.get("medictool", 0)) == 1 and int(items.get("armor_light", 0)) == 0, "D: Basislager der echten Kampagne: 2 Pistolen, 1 Sanitaetsgeraet, keine leichte Ruestung: " + str(items))
	# Ausruesten ueber die oeffentliche Operation, die auch das Ziehen auf den Platz benutzt.
	var equip: Dictionary = screen.call("request_operation", "inventory_equip", {"unit_id": "campaign_leader", "craft_id": craft, "source_container_id": "base:homebase", "item_id": "pistol", "slot": "weapon_1"})
	_check(bool(equip.get("ok", false)), "D: die Pistole laesst sich aus dem Lager auf Waffe 1 des Truppfuehrers legen: " + str(equip))
	var after_owner: Dictionary = Dictionary(Dictionary(runtime.get("_simulation").call("get_personnel_loadout_state").call("get_snapshot")).get("campaign_leader", {}))
	_check(String(after_owner.get("weapon_1", "")) == "pistol" and String(after_owner.get("armor", "")) == "suit", "D: der Besitzer fuehrt die Pistole, der Anzug bleibt: " + str(after_owner))
	var after_items: Dictionary = Dictionary(Dictionary(Dictionary(runtime.call("get_snapshot")).supply.inventory["base:homebase"]).get("items", {}))
	_check(int(after_items.get("pistol", 0)) == 1, "D: danach liegt noch eine Pistole im Lager (echte Bestandsbuchung): " + str(after_items))
	var pilot_state: Dictionary = Dictionary(Dictionary(runtime.get("_simulation").call("get_personnel_loadout_state").call("get_snapshot")).get("campaign_pilot", {}))
	_check(String(pilot_state.get("weapon_1", "")) == "none", "D: der Pilot bleibt unbewaffnet")
	flow.queue_free()
	await process_frame

func _loadouts_of(runtime: Node) -> Dictionary:
	return Dictionary(runtime.get("_simulation").call("get_personnel_loadout_state").call("get_snapshot"))

func _base_items_of(runtime: Node) -> Dictionary:
	return Dictionary(Dictionary(Dictionary(runtime.call("get_snapshot")).supply.inventory["base:homebase"]).get("items", {}))

func _equip(screen: Control, craft: String, unit_id: String, item: String, slot: String) -> bool:
	var result: Dictionary = screen.call("request_operation", "inventory_equip", {"unit_id": unit_id, "craft_id": craft, "source_container_id": "base:homebase", "item_id": item, "slot": slot})
	return _check(bool(result.get("ok", false)), "E: %s -> %s/%s ueber die echte Operation: %s" % [item, unit_id, slot, str(result)])

func _part_e_continue_keeps_saved_equipment() -> void:
	# W1: Ganzer Spielstand ueber den echten Speicher- und Fortsetzen-Weg. Der Stand ist der ALTE Zustand
	# (beide Personen mit Pistole, eine mit Sanitaetsgeraet, Lager entsprechend leer). Das Laden darf die neue
	# Startausruestung (suit/none/none, Lager 2/1) NICHT noch einmal anwenden.
	START.request_start(self, "campaign", "new")
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	var runtime: Node = flow.get("_singleplayer_runtime")
	if not _check(runtime != null, "E: neue Kampagne hat ihre Laufzeit"):
		flow.queue_free()
		await process_frame
		return
	var craft := String(flow.get_meta("singleplayer_bootstrap_craft_id"))
	_check(int(_base_items_of(runtime).get("pistol", 0)) == 2, "E: Ausgang: neues Lager mit 2 Pistolen")
	_equip(screen, craft, "campaign_leader", "pistol", "weapon_1")
	_equip(screen, craft, "campaign_pilot", "pistol", "weapon_1")
	_equip(screen, craft, "campaign_pilot", "medictool", "weapon_2")
	var items_before: Dictionary = _base_items_of(runtime)
	_check(int(items_before.get("pistol", 0)) == 0 and int(items_before.get("medictool", 0)) == 0, "E: vor dem Speichern ist das Lager leer geraeumt: " + str(items_before))
	var saved: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint", flow, runtime, true)
	_check(bool(saved.get("ok", false)) and not bool(saved.get("throttled", false)), "E: erzwungenes Speichern gelingt: " + str(saved))
	flow.queue_free()
	await process_frame
	START.request_start(self, "campaign", "continue")
	flow = FLOW.instantiate()
	root.add_child(flow)
	await process_frame
	screen = flow.get_node("HomebaseScreen")
	runtime = flow.get("_singleplayer_runtime")
	if not _check(runtime != null, "E: Fortsetzen liefert eine Laufzeit"):
		flow.queue_free()
		await process_frame
		return
	var owner_state: Dictionary = _loadouts_of(runtime)
	var expect := {"campaign_leader": ["pistol", "none"], "campaign_pilot": ["pistol", "medictool"]}
	for id: String in START_PEOPLE:
		var want: Array = expect[id]
		var o: Dictionary = Dictionary(owner_state.get(id, {}))
		_check(String(o.get("armor", "")) == "suit" and String(o.get("weapon_1", "")) == want[0] and String(o.get("weapon_2", "")) == want[1], "E: nach Fortsetzen (Besitzer) %s wie gespeichert %s: %s" % [id, str(want), str(o)])
		var s: Dictionary = screen.call("_get_member_loadout", id)
		_check(String(s.get("weapon_1", "")) == want[0] and String(s.get("weapon_2", "")) == want[1], "E: nach Fortsetzen (Bildschirm) %s: %s" % [id, str(s)])
		var v: Dictionary = Dictionary(Dictionary(screen.call("get_personnel_inventory_view", id)).get("unit", {})).get("loadout", {})
		_check(String(v.get("weapon_1", "")) == want[0] and String(v.get("weapon_2", "")) == want[1], "E: nach Fortsetzen (Inventarsicht) %s: %s" % [id, str(v)])
	var items_after: Dictionary = _base_items_of(runtime)
	_check(int(items_after.get("pistol", 0)) == 0 and int(items_after.get("medictool", 0)) == 0 and int(items_after.get("armor_light", 0)) == 0, "E: Lagerbestand genau wie gespeichert, nicht auf 2/1 zurueckgesetzt: " + str(items_after))
	_check(Array(flow.get("_all_team_units")).size() == 2, "E: Fortsetzen legt keine weiteren Personen an")
	flow.queue_free()
	await process_frame

func _check(value: bool, label: String) -> bool:
	if value:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)
	return value
