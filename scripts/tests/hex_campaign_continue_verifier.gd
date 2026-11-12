extends SceneTree
## Actual campaign entry, Store, Adapter, Base and Root. Only unused UI rendering
## and scene startup loops are suppressed; no simulated gameplay owner is replaced.
const START=preload("res://scripts/meta/campaign_start_configuration.gd")
const STORE=preload("res://scripts/meta/campaign_checkpoint_store.gd")
const ADAPTER=preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const BASE=preload("res://scripts/core/base_personnel_runtime.gd")

class OwnerFlow extends "res://scripts/meta/meta_layer_flow.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
class Screen extends "res://scripts/meta/homebase_screen.gd":
	func _ready()->void:pass
	func _rebuild_ui()->void:pass
	func _render_homebase_fireteams()->void:pass
	func _update_homebase_loadout_panel()->void:pass
	func _update_homebase_flightdeck_staging_panel()->void:pass
	func _refresh_homebase_direct_boarding_ui()->void:pass
class Fob extends "res://scripts/meta/fob_screen.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _refresh_ui_state()->void:pass

var passed:=0
var failed:=0
var rigs:Array=[]

func _init()->void:call_deferred("_run")
func _check(value:bool,label:String)->bool:
	if value:passed+=1;print("PASS: ",label)
	else:failed+=1;printerr("FAIL: ",label)
	return value

func _flow()->Node:
	var flow=OwnerFlow.new()
	flow.process_mode=Node.PROCESS_MODE_DISABLED
	flow._game_start_request={"mode":"campaign","action":"new"}
	flow._campaign_start=START.new()
	root.add_child(flow)
	var screen=Screen.new();screen.name="HomebaseScreen";flow.add_child(screen)
	var fob=Fob.new();fob.name="FOBScreen";flow.add_child(fob)
	rigs.append(flow)
	return flow

func _attach_runtime(flow:Node,observe:Callable=Callable())->Node:
	var screen:Control=flow.get_node("HomebaseScreen")
	var fob:Control=flow.get_node("FOBScreen")
	screen.setup_roster(flow._all_team_units,flow._homebase_staged_unit_ids)
	screen.set_fireteam_context(flow._homebase_staged_fireteam_ids,fob._fireteam_definitions,false)
	screen.set_transport_state(flow._homebase_aircraft_definitions,flow._assigned_aircraft_pilot_by_craft,[],[],flow._aircraft_location_by_craft,{}, {}, [])
	var runtime=ADAPTER.new()
	flow.add_child(runtime);flow._singleplayer_runtime=runtime
	if observe.is_valid():
		runtime.child_entered_tree.connect(func(child:Node):
			if child.get_script()==BASE:child.state_changed.connect(observe.bind(child)))
	runtime.configure(flow,screen)
	if is_instance_valid(runtime._simulation):runtime._simulation.set_physics_process(false)
	return runtime

func _positive()->void:
	var map=load("res://scripts/meta/base_interior_navigation.gd").load_map("res://maps/campaign_intro_base.json")
	if not _check(map.get_grid_size()==Vector2i(384,392) and map.get_tile_size()=={"half_width":16.0,"half_height":8.0} and map.get_tactical_grid_rules()=="hex_tactical_v1","private opt-in uses actual authored 384x392 fine navigation with 16x8 cells"):return
	var first:Node=_flow()
	first._campaign_start.configure(first,{"mode":"campaign","action":"new"})
	if not _check(first._campaign_start.error_message.is_empty(),"actual new-campaign entry initializes its real roster and ship"):return
	var runtime:Node=_attach_runtime(first)
	var base:Node=runtime.get_base_personnel_runtime()
	var sim:Node=runtime._simulation
	if not _check(sim.is_hex_ground_runtime_active() and base._terrain.get_tile_count()==map.get_tiles().size(),"actual Adapter/Base/Root use the complete fine registry"):return
	var pilot:String=first._all_team_units[1].unit_id
	var craft:String=first._homebase_aircraft_definitions[0].craft_id
	for person in first._all_team_units:base.request_operation("base_auto_rest",{"unit_id":person.unit_id,"enabled":false})
	var board:Dictionary=base.request_operation("base_board",{"unit_id":pilot,"craft_id":craft})
	if not _check(board.get("ok",false),"actual Base accepts assigned pilot boarding"):return
	for _step in range(1600):
		if base._states[pilot].status=="aboard":break
		sim._physics_process(0.1)
	if not _check(base._states[pilot].status=="aboard" and sim.get_hex_unit_state(pilot).is_empty() and bool(base.get_actor(pilot).get_meta("dropship_embarked",false)),"pilot physically boards through real movement and leaves Ground"):return
	var saved:Dictionary=first._campaign_start.save_home_checkpoint(first,runtime)
	if not _check(saved.get("ok",false),"actual campaign save writes the private atomic checkpoint"):print(saved);return
	var saved_tick:int=sim.tick_counter
	sim._physics_process(0.1)
	var repeated:Dictionary=first._campaign_start.save_home_checkpoint(first,runtime)
	_check(repeated.get("throttled",false) and sim.tick_counter==saved_tick+1,"automatic Hex export is bounded without throttling the actual simulation")
	var forced:Dictionary=first._campaign_start.save_home_checkpoint(first,runtime,true)
	if not _check(forced.get("ok",false) and not forced.get("throttled",false),"explicit save bypasses only the export interval"):return
	var loaded:Dictionary=STORE.load_checkpoint()
	if not _check(loaded.get("ok",false),"actual Store reads and validates the saved owner envelope"):print(loaded);return
	var payload:Dictionary=loaded.payload
	_check(payload.has("hex_tactical") and not payload.has("base_personnel") and payload.hex_tactical.base_personnel.units[pilot].status=="aboard","saved Hex uses one canonical block and preserves aboard status")
	var durable:String=FileAccess.get_file_as_string(STORE.DEFAULT_PATH)
	var bad:Dictionary=payload.duplicate(true);bad.hex_tactical.schema="hex_tactical_checkpoint.v999"
	_check(not STORE.save_checkpoint(bad).get("ok",false) and FileAccess.get_file_as_string(STORE.DEFAULT_PATH)==durable,"unknown checkpoint version rejects without overwriting the valid save")
	bad=payload.duplicate(true);bad.hex_tactical.base_personnel.erase("units")
	_check(not STORE.validate_payload(bad).get("ok",false),"incomplete Base V2 rejects before owner construction")
	var second:Node=_flow()
	second._campaign_start.configure(second,{"mode":"campaign","action":"continue"})
	if not _check(second._campaign_start.error_message.is_empty() and not second._campaign_start.checkpoint.is_empty(),"actual Continue preflight accepts the future roster/transport/Base/Root context"):print(second._campaign_start.error_message);return
	var publications:Array=[]
	var resumed:Node=_attach_runtime(second,func(owner:Node):
		publications.append(owner._states[pilot].status=="aboard" and not owner.get_actor(pilot).visible and owner._sim.get_hex_unit_state(pilot).is_empty()))
	_check(publications==[true],"first restored Base state_changed sees aboard person already hidden and absent from Ground")
	var after:Dictionary=resumed._simulation.export_hex_checkpoint_state()
	if not _check(after.get("ok",false),"fresh actual runtime exports after Continue"):print(after);return
	_check(resumed._simulation!=sim and after.state.tick==payload.hex_tactical.tick and after.state.rng_state==payload.hex_tactical.rng_state and after.state.base_personnel==payload.hex_tactical.base_personnel and after.state.ground==payload.hex_tactical.ground,"fresh owners preserve clock, exact RNG, Base actions and canonical Ground")
	_check(second.get_node("HomebaseScreen")._get_assigned_pilot_id(craft)==pilot and after.state.transport==payload.hex_tactical.transport,"Continue retains existing real pilot/transport ownership")

func _legacy_negative()->void:
	var loaded:Dictionary=STORE.load_checkpoint()
	if not _check(loaded.get("ok",false),"unflagged phase reads the same saved Hex envelope"):return
	var map=load("res://scripts/meta/base_interior_navigation.gd").load_map("res://maps/campaign_intro_base.json")
	_check(map.get_tactical_grid_rules().is_empty(),"negative phase uses the exact original unflagged fine navigation")
	var flow:Node=_flow()
	var before:Array=[flow._all_team_units.duplicate(true),flow._homebase_aircraft_definitions.duplicate(true),flow._assigned_aircraft_pilot_by_craft.duplicate(true)]
	flow._campaign_start.configure(flow,{"mode":"campaign","action":"continue"})
	_check(flow._campaign_start.error_message.contains("checkpoint_base_not_hex_enabled") and flow._campaign_start.checkpoint.is_empty() and [flow._all_team_units,flow._homebase_aircraft_definitions,flow._assigned_aircraft_pilot_by_craft]==before,"saved Hex cannot activate production data or mutate Flow before rejected Continue")

func _run()->void:
	if "--legacy-negative" in OS.get_cmdline_user_args():_legacy_negative()
	else:_positive()
	for rig in rigs:rig.queue_free()
	rigs.clear()
	await process_frame
	await process_frame
	print("HEX_CAMPAIGN_CONTINUE_RESULTS passed=%d failed=%d"%[passed,failed])
	if failed==0:print("HEX_CAMPAIGN_CONTINUE_READY")
	quit(0 if failed==0 else 1)
