extends SceneTree
## M6b B3 (23.11.2026): Skirmish wie Kampagne - Magazinmodus, Startausstattung (volle Faecher der Hauptwaffe, Lager 16/8),
## einmaliges Nachreichen ueber denselben Merker, Verbrauch im Einsatz aus der Versorgung (Quelle "campaign"), Auffuellen von Hand.
## Echte Szene meta_layer_test mit echtem Skirmish-Start (Preset "early", 8 Personen). Braucht ein Wegwerfprofil (SB_REVIEW2_USER_DIR).
## Schlusszeile: AMMO_SKIRMISH passed=N failed=M
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const START = preload("res://scripts/meta/game_start_contract.gd")
const SIM = preload("res://scripts/core/simulation_root.gd")
const FLOW: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const ADAPTER_SRC := "res://scripts/meta/singleplayer_runtime_adapter.gd"
const FLOW_SRC := "res://scripts/meta/meta_layer_flow.gd"
var _passed := 0
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> bool:
	if value:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)
	return value

func _run() -> void:
	var verdict: Dictionary = GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("AMMO_SKIRMISH refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	await _start_part()
	_source_part()
	print("AMMO_SKIRMISH passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _base_n(sup: RefCounted, item: String) -> int:
	return int(Dictionary(Dictionary(sup.get("_inventory").get("base:homebase", {})).get("items", {})).get(item, 0))

func _bag(sup: RefCounted, id: String) -> Dictionary:
	return Dictionary(sup.get("_inventory").get("unit:%s:backpack" % id, {}))

func _start_part() -> void:
	START.request_start(self, "skirmish", "new", "early")
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	await process_frame
	flow.call("_show_homebase")
	var runtime: Node = flow.get("_singleplayer_runtime")
	if not _check(runtime != null and not bool(flow.call("is_campaign_start")), "Skirmish-Start hat eine Laufzeit und ist keine Kampagne"):
		flow.queue_free()
		return
	var sup: RefCounted = runtime.get("_supply")
	var ids: Array = []
	for unit in Array(flow.get("_all_team_units")): ids.append(String(Dictionary(unit).get("unit_id", "")))
	_check(ids.size() == 8, "8 Personen im Preset (%d)" % ids.size())
	_check(bool(sup.get("_campaign_magazine_mode")), "B3: Magazinmodus im Skirmish an")
	_check(_base_n(sup, "ammo_light") == 16 and _base_n(sup, "ammo_rifle") == 8, "B3: Skirmish-Lager 16 leichte, 8 Gewehr-Magazine (%d/%d)" % [_base_n(sup, "ammo_light"), _base_n(sup, "ammo_rifle")])
	_check(bool(Dictionary(sup.export_state()).get("ammo_start_granted", false)), "B3: der Stand traegt den Merker der gewaehrten Startausstattung")
	var all_full := true
	var all_store := true
	for id in ids:
		var bag: Dictionary = _bag(sup, String(id))
		var cap := int(bag.get("armor_chip_capacity", 0))
		if cap <= 0 or int(Dictionary(bag.get("items", {})).get("ammo_rifle", 0)) != cap: all_full = false
		if not bool(sup.call("person_has_magazine_store", String(id))): all_store = false
	_check(all_full, "B3: jede Person hat ein volles Fach Gewehr-Magazine (Hauptwaffe Sturmgewehr)")
	_check(all_store, "B3: jede Person fuehrt einen Magazinvorrat in der Versorgung")
	var leader := String(ids[0])
	var before := int(Dictionary(_bag(sup, leader).items).get("ammo_rifle", 0))
	# Verbrauch im Einsatz: der SimulationRoot des Einsatzes ist an die Versorgung gebunden -> Quelle "campaign".
	var mission_sim: Node = SIM.new()
	mission_sim.call("bind_mission_magazine_supply", sup)
	_check(String(mission_sim.call("get_person_magazine_source", leader)) == "campaign", "B3: Einsatz-Simulation liest die Skirmish-Person aus der Versorgung (Quelle 'campaign')")
	_check(bool(mission_sim.call("take_person_magazine", leader, "ammo_rifle")) and int(Dictionary(_bag(sup, leader).items).get("ammo_rifle", 0)) == before - 1, "B3: Nachladen im Einsatz verbraucht ein echtes Magazin aus dem Fach (%d -> %d)" % [before, int(Dictionary(_bag(sup, leader).items).get("ammo_rifle", 0))])
	mission_sim.free()
	# Auffuellen von Hand: das fehlende Magazin per Befehl aus dem Lager ins Fach.
	var moved: Dictionary = sup.apply_command({"contract_category": "singleplayer_supply", "operation": "inventory_transfer", "payload": {"source_container_id": "base:homebase", "destination_container_id": "unit:%s:backpack" % leader, "item_id": "ammo_rifle", "amount": 1}, "request_id": "m6b:skirmish:1"}, {"accessible_containers": ["base:homebase", "unit:%s:backpack" % leader]})
	_check(bool(moved.get("ok", false)) and int(Dictionary(_bag(sup, leader).items).get("ammo_rifle", 0)) == before and _base_n(sup, "ammo_rifle") == 7, "B3: von Hand aus dem Lager ins Fach gezogen: Fach wieder voll, Lager 8 -> 7 (%s)" % str(moved.get("reason", "ok")))
	# Nachreichen: ein Stand ohne Merker (wie vor M6b) bekommt die Ausstattung einmal.
	sup.set("_ammo_start_granted", false)
	for id in ids:
		Dictionary(_bag(sup, String(id)).items).erase("ammo_rifle")
	Dictionary(Dictionary(sup.get("_inventory")["base:homebase"]).items).erase("ammo_light")
	Dictionary(Dictionary(sup.get("_inventory")["base:homebase"]).items).erase("ammo_rifle")
	_check(bool(runtime.call("grant_ammo_start_if_missing")), "B3: Nachreichen fuer einen Stand ohne Merker gewaehrt jetzt")
	_check(_base_n(sup, "ammo_light") == 16 and _base_n(sup, "ammo_rifle") == 8 and int(Dictionary(_bag(sup, leader).items).get("ammo_rifle", 0)) == int(_bag(sup, leader).armor_chip_capacity), "B3: nachgereicht: Lager 16/8, Fach der Truppfuehrung voll")
	_check(not bool(runtime.call("grant_ammo_start_if_missing")) and _base_n(sup, "ammo_rifle") == 8, "B3: ein zweites Mal gewaehrt nichts")
	flow.queue_free()
	await process_frame

func _source_part() -> void:
	var adapter_src := FileAccess.get_file_as_string(ADAPTER_SRC).replace("\r\n", "\n")
	var flow_src := FileAccess.get_file_as_string(FLOW_SRC).replace("\r\n", "\n")
	_check(adapter_src.contains("bind_mission_magazine_supply\", _supply)") and adapter_src.contains("if (_campaign_mode or _skirmish_mode) and _supply != null and mission_root.has_method(\"bind_mission_magazine_supply\")"), "B3: Quelltext: der Einsatz wird im Skirmish wie in der Kampagne an die Versorgung gebunden")
	_check(flow_src.contains("if (is_campaign_start() or has_meta(\"skirmish_preset_id\")) and _singleplayer_runtime != null and _singleplayer_runtime.has_method(\"grant_ammo_start_if_missing\")"), "B3: Quelltext: die Startausstattung wird auch im Skirmish gewaehrt")
