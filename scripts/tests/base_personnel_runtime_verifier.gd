extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
var failed := 0
var terminals: Array = []
func _initialize() -> void:
	call_deferred("_run")
func _check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ",label)
	if not value: failed += 1
func _run() -> void:
	START.request_start(self,"campaign","new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	var adapter: Node = flow.get("_singleplayer_runtime")
	var runtime: Node = adapter.get_base_personnel_runtime()
	if runtime == null:
		_check(false,"authoritative runtime exists")
		quit(1)
		return
	var sim: Node = runtime.get_simulation_root()
	sim.set_physics_process(false)
	var state: Dictionary = runtime.get_snapshot()
	_check(state.units.size()==2,"exactly two actual roster actors")
	_check(state.units[0].status == "outside" and state.units[1].status == "outside","both initially outside despite pilot assignment")
	_check(runtime.get_unit_registry().get_all_units().size()==2,"registry has no commander third actor")
	var craft: String = String(flow.get_meta("singleplayer_bootstrap_craft_id"))
	_check(not runtime.is_pilot_aboard(craft),"assignment is not physical pilot presence")
	runtime.terminal_ready.connect(func(id: String, terminal: String): terminals.append([id,terminal]))
	var initial_roster: Array = Array(flow.get("_all_team_units")).duplicate(true)
	var beds: Array = state.layout.beds
	var leader := "campaign_leader"
	var pilot := "campaign_pilot"
	_check(screen.call("request_operation","loadout",{"unit_id":pilot,"key":"weapon_1","value":"medictool"}).ok,"outside pilot equips before checkpoint")
	var result: Dictionary = runtime.request_operation("base_sleep",{"unit_id":leader,"bed_id":beds[0].id})
	_check(result.get("ok",false),"sleep reserves bed and starts real walk")
	_check(runtime.get_snapshot().units[0].status == "moving","sleep never teleports to sleeping")
	result=runtime.request_operation("base_sleep",{"unit_id":pilot,"bed_id":beds[0].id})
	_check(not result.get("ok",false) and result.reason=="bed_occupied","reserved bed rejects other person")
	for i in range(3000):
		sim.call("_physics_process",0.05)
		if runtime.get_snapshot().units[0].status == "sleeping": break
	_check(runtime.get_snapshot().units[0].status=="sleeping","real navigation arrives at reserved bed")
	_check(runtime.request_operation("base_move",{"unit_id":leader,"target_position":runtime.get_actor(pilot).position}).ok,"manual movement interrupts sleeping")
	runtime.request_operation("base_cancel", {"unit_id":leader})
	_check(runtime.request_operation("base_sleep", {"unit_id":leader,"bed_id":String(beds[0].id)}).ok, "person can return to bed after manual movement")
	for i in range(3000):
		sim.call("_physics_process", 0.05)
		if runtime.get_snapshot().units[0].status == "sleeping": break
	_check(runtime.get_snapshot().units[0].status == "sleeping", "person sleeps again before checkpoint")
	_check(Array(flow.get("_all_team_units")) == initial_roster,"sleep never mutates medical roster values")
	var sleep_save: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint",flow,adapter)
	_check(sleep_save.get("ok",false),"sleeping base checkpoint saves at actual bed arrival")
	flow.queue_free()
	await process_frame
	START.request_start(self,"campaign","continue")
	flow=load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	screen=flow.get_node("HomebaseScreen")
	adapter=flow.get("_singleplayer_runtime")
	runtime=adapter.get_base_personnel_runtime()
	sim=runtime.get_simulation_root()
	sim.set_physics_process(false)
	runtime.terminal_ready.connect(func(id: String, terminal: String): terminals.append([id,terminal]))
	_check(runtime.get_snapshot().units[0].status=="sleeping" and runtime.get_snapshot().bed_occupants.get(beds[0].id)==leader,"continue restores actual sleeping person and exclusive bed")
	_check(String(screen.call("_get_member_loadout",pilot).weapon_1)=="medictool","unassigned-team pilot loadout survives checkpoint restore")

	initial_roster = Array(flow.get("_all_team_units")).duplicate(true)
	_check(runtime.request_operation("base_wake",{"unit_id":leader}).ok,"wake frees sleeping person")
	_check(runtime.get_snapshot().bed_occupants.is_empty(),"wake releases bed")
	_check(Array(flow.get("_all_team_units")) == initial_roster,"waking never heals or mutates medical roster values")
	result=runtime.request_operation("base_sleep",{"unit_id":pilot,"bed_id":beds[1].id})
	_check(result.ok,"other person can reserve free bed")
	_check(runtime.request_operation("base_cancel",{"unit_id":pilot}).ok and runtime.get_snapshot().bed_occupants.is_empty(),"cancel walk releases bed")
	var stopped: Vector2 = runtime.get_actor(pilot).position
	for i in range(50): sim.call("_physics_process",0.05)
	_check(runtime.get_actor(pilot).position == stopped,"cancel removes movement intent and holds actual position")
	screen.call("request_operation","navigate",{"mode":"personnel"})
	result=runtime.request_operation("base_terminal",{"unit_id":leader,"terminal_id":"team"})
	_check(result.ok,"terminal request starts validated path")
	for i in range(3000):
		sim.call("_physics_process",0.05)
		if not terminals.is_empty(): break
	_check(terminals.size()==1 and terminals[0]==[leader,"team"],"hidden base still reaches terminal and emits once")
	for i in range(20): sim.call("_physics_process",0.05)
	_check(terminals.size()==1,"arrival does not reopen terminal repeatedly")
	result=runtime.request_operation("base_board",{"craft_id":craft,"fireteam_id":"ft1","whole_fireteam":true})
	_check(result.ok,"crew boarding begins through actual map")
	_check(not runtime.validate_operation("loadout",{"unit_id":leader}).ok,"moving boarding blocks equipment changes")
	for i in range(3000):
		sim.call("_physics_process",0.05)
		screen.call("_debug_advance_homebase_direct_boarding",0.05)
		if runtime.is_pilot_aboard(craft) and runtime.get_snapshot().units[0].status=="aboard": break
	_check(runtime.is_pilot_aboard(craft) and runtime.get_snapshot().units[0].status=="aboard","both same identities board via owner after arrival")
	_check(screen.call("_has_homebase_direct_launch_payload_for_craft",craft),"existing transport owner confirms troop payload")
	result=runtime.request_operation("base_unboard",{"craft_id":craft,"unit_id":pilot})
	_check(result.ok and not runtime.is_pilot_aboard(craft),"pilot exits physically while assignment remains")
	_check(String(screen.call("_get_assigned_pilot_id",craft))==pilot,"unboard retains pilot assignment")
	result=screen.call("request_operation","board",{"craft_id":craft,"fireteam_id":"ft1"})
	_check(result.ok,"repeat team boarding accepts returning pilot without recreating payload")
	for i in range(200): sim.call("_physics_process",0.05)
	_check(runtime.is_pilot_aboard(craft) and runtime.get_snapshot().units[0].status=="aboard" and screen.call("_has_homebase_direct_launch_payload_for_craft",craft),"repeat boarding keeps existing passenger and payload coherent")
	result=screen.call("request_operation","board",{"craft_id":craft,"fireteam_id":"ft1"})
	for i in range(20): sim.call("_physics_process",0.05)
	_check(result.ok and runtime.get_snapshot().units[0].status=="aboard" and runtime.is_pilot_aboard(craft),"already complete boarding is idempotent")
	_check(screen.call("request_operation", "accept_job", {"job_id":"satellite_recovery"}).get("ok", false), "accept actual job before orbital presence regression")
	result = adapter.call("launch_to_moon_orbit", craft)
	_check(result.get("ok", false), "actual boarded crew reaches moon orbit for presence checks")
	if result.get("ok", false):
		_check_away_operations(runtime, "moon orbit")
		result = adapter.call("request_operation", "space_start_quantum", {"craft_id":craft,"target_orbit_id":"planet_orbit"})
		_check(result.get("ok", false), "actual quantum begins for presence checks")
		_check_away_operations(runtime, "quantum")
		adapter.call("advance_space_travel", 0.6)
		result = adapter.call("request_operation", "space_abort_quantum", {"craft_id":craft})
		_check(result.get("ok", false), "actual quantum abort holds remote crew")
		_check_away_operations(runtime, "stopped quantum")
		result = adapter.call("request_operation", "space_start_quantum", {"craft_id":craft,"target_orbit_id":"moon_orbit"})
		_check(result.get("ok", false), "held crew starts actual moon return")
		adapter.call("advance_space_travel", 3.1)
		_check_away_operations(runtime, "returned moon orbit before landing")
		result = adapter.call("request_operation", "space_land_homebase", {"craft_id":craft})
		_check(result.get("ok", false) and runtime.call("_at_home"), "only explicit actual moon landing restores base availability")
	runtime.request_operation("base_unboard",{"craft_id":craft,"unit_id":pilot})
	var saved: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint",flow,adapter)
	_check(saved.get("ok",false),"optional base state passes checkpoint owner validation")
	if not saved.get("ok",false): print(saved)
	flow.queue_free()
	await process_frame
	START.request_start(self,"campaign","continue")
	flow=load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	runtime=flow.get("_singleplayer_runtime").get_base_personnel_runtime()
	_check(runtime.get_snapshot().units.size()==2 and runtime.get_snapshot().units[0].status=="aboard" and runtime.get_snapshot().units[1].status=="outside","continue retains actual positions/presence and identities")
	var restored_screen: Node = flow.get_node("HomebaseScreen")
	_check(String(restored_screen.call("_get_member_loadout",pilot).weapon_1)=="medictool","pilot loadout survives boarded refresh and second Continue")
	_check(restored_screen.call("_has_homebase_direct_launch_payload_for_craft",craft),"continue restores existing transport payload alongside presence")
	var store = load("res://scripts/meta/campaign_checkpoint_store.gd")
	var legacy: Dictionary = store.load_checkpoint().payload.duplicate(true)
	legacy.erase("base_personnel")
	_check(store.validate_payload(legacy).ok,"legacy checkpoint without optional fields remains valid")
	var swapped: Dictionary = legacy.duplicate(true)
	swapped.craft.pilot_id = leader
	swapped.craft.staged_unit_ids = [pilot]
	swapped.craft.fireteam_definitions = [{"id":"ft1","lead_unit_id":pilot,"member_unit_ids":[pilot]}]
	if swapped.has("fleet") and not swapped.fleet.is_empty(): swapped.fleet[0] = swapped.craft.duplicate(true)
	_check(store.validate_payload(swapped).ok,"checkpoint accepts any actual roster person as pilot and other person as leader")
	var invalid: Dictionary = store.load_checkpoint().payload.duplicate(true)
	invalid.base_personnel.units.campaign_pilot.position[0] = "bad"
	_check(not store.validate_payload(invalid).ok,"malformed optional base position rejects restore")
	flow.queue_free()
	await process_frame
	print("BASE_PERSONNEL failed=",failed)
	quit(1 if failed else 0)

func _check_away_operations(runtime: Node, phase_label: String) -> void:
	_check(not runtime.call("_at_home"), phase_label + " is not home without a mission or transfer")
	var before: Dictionary = runtime.call("export_state").duplicate(true)
	for spec: Dictionary in [
		{"operation":"base_cancel","payload":{"unit_id":"campaign_pilot"}},
		{"operation":"base_wake","payload":{"unit_id":"campaign_leader"}},
		{"operation":"base_unboard","payload":{"whole_fireteam":true,"fireteam_id":"ft1"}},
	]:
		var result: Dictionary = runtime.call("request_operation", spec.operation, spec.payload)
		_check(not result.get("ok", false) and String(result.get("reason", "")) == "away_from_base", phase_label + " rejects " + String(spec.operation) + " at owner boundary")
	_check(runtime.call("export_state") == before, phase_label + " commands preserve actual crew presence")
