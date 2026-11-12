extends SceneTree

class Flow extends "res://scripts/meta/meta_layer_flow.gd":
	var remembered := 0
	func _ready() -> void: pass
	func _process(_d: float) -> void: pass
	func _remember_location(_instance: Node) -> void: remembered += 1
	func _refresh_fob_screen() -> void: pass
	func _refresh_homebase_screen() -> void: pass
	func _refresh_map_screen() -> void: pass
	func _is_homebase_direct_mission_drop_source() -> bool: return false
	func _sync_mission_drop_transport_fields_from_fob() -> void: pass
class Root extends Node:
	var context := 1
	var hex := true
	func get_hex_ground_context_revision() -> int: return context
	func is_hex_ground_runtime_required() -> bool: return hex
	func is_hex_ground_runtime_active() -> bool: return hex
class Controller extends Node:
	var calls: Array = []
	var commit_ready := false
	var void_result := false
	var ticket := {"opaque": ["bound", 9]}
	func retire_location_craft_visit(craft_id: String, unit_ids: PackedStringArray, binding: Dictionary = {}) -> Variant:
		calls.append({"craft":craft_id,"units":unit_ids,"binding":binding})
		if void_result: return null
		return {"status":"committed"} if commit_ready else {"status":"waiting","retirement_binding":ticket}
class Runtime extends Node:
	var results: Array = []
	var after_record: Callable
	var fuel_commits := 0
	func authorize_return(_craft: String) -> Dictionary:
		fuel_commits += 1
		return {"ok":true}
	func get_space_travel_snapshot(_craft: String = "") -> Dictionary: return {"craft_id":"craft","phase":"surface"}
	func enter_space_orbit(_craft: String) -> Dictionary: return {"ok":true}
	func observe_campaign_progress() -> void: pass
	func record_mission_result(result: Dictionary, identity: Dictionary) -> void:
		results.append([result, identity])
		if after_record.is_valid(): after_record.call()

var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func fixture() -> Dictionary:
	var flow := Flow.new(); root.add_child(flow)
	var place := Node.new(); place.name="Place"; flow.add_child(place)
	place.set_meta("location_id","polisa")
	var visit := {"craft_id":"craft","location_id":"polisa","job_id":"job","unit_ids":["pilot","member"]}
	place.set_meta("singleplayer_visit_identities",{"craft":visit})
	place.set_meta("singleplayer_mission_identity",visit)
	var owner := Root.new(); owner.name="SimulationRoot"; place.add_child(owner)
	var controller := Controller.new(); controller.name="TacticalController"; place.add_child(controller)
	var runtime := Runtime.new(); flow.add_child(runtime); flow._singleplayer_runtime=runtime
	flow._location_registry.register_location("polisa",place)
	flow._craft_location_runtime["craft"]="polisa"
	flow._aircraft_location_by_craft["craft"]="mission"
	var timer := Timer.new(); timer.name="TransportTimer"; flow.add_child(timer)
	return {"flow":flow,"place":place,"owner":owner,"controller":controller,"runtime":runtime,"visit":visit}
func run() -> void:
	var f := fixture(); var flow = f.flow; var c = f.controller
	flow._finish_space_surface_departure("craft")
	check(flow._aircraft_location_by_craft.craft=="mission" and flow.remembered==0 and f.runtime.results.is_empty(),"waiting publishes neither location nor remember nor aborted")
	if not flow.has_method("get_surface_departure_retirement_guard"):
		check(false,"bound retry API exists")
		flow.free(); finish(); return
	check(c.calls.size()==1 and c.calls[0].binding.is_empty(),"initial two argument call")
	check(not flow.get_surface_departure_retirement_guard("craft").ok and flow.get_surface_departure_retirement_guard("other","polisa").ok and not flow._pending_mission_craft_transfers.is_empty(),"pending gates exact craft and save without freezing parallel visitors")
	flow._begin_space_approach("craft",{"destination_location_id":"elsewhere"})
	check(flow._craft_location_runtime.craft=="polisa" and flow._space_approaches.is_empty(),"approach rejects before first Flowwrite")
	flow._on_homebase_transport_timer_timeout()
	check(c.calls.size()==2 and c.calls[1].binding==c.ticket and c.ticket=={"opaque":["bound",9]} and not flow._pending_mission_craft_transfers.is_empty(),"actual timer returns unchanged opaque binding and retains marker")
	c.commit_ready=true
	flow._on_homebase_transport_timer_timeout()
	check(flow._aircraft_location_by_craft.craft=="starmap" and flow.remembered==1 and f.runtime.results.size()==1 and flow._pending_mission_craft_transfers.is_empty(),"commit alone publishes previous completion tail exactly once")
	flow._on_homebase_transport_timer_timeout()
	check(c.calls.size()==3 and f.runtime.results.size()==1,"no repeated completion")
	flow.free()
	for kind in ["visit","root_context","root_instance"]:
		f=fixture(); flow=f.flow; c=f.controller
		flow._finish_space_surface_departure("craft")
		flow._pending_mission_craft_transfers.append({"craft_id":"craft","phase":"fresh_transfer","transfer_id":"new"})
		if kind=="visit":
			var next_visit: Dictionary=f.visit.duplicate(true); next_visit.unit_ids=["new_pilot"]
			f.place.set_meta("singleplayer_visit_identities",{"craft":next_visit})
		elif kind=="root_context": f.owner.context+=1
		else:
			f.owner.free(); var replacement:=Root.new(); replacement.name="SimulationRoot"; f.place.add_child(replacement)
		flow._retry_space_surface_departures()
		check(c.calls.size()==1 and flow._aircraft_location_by_craft.craft=="mission" and f.runtime.results.is_empty() and flow._pending_mission_craft_transfers.size()==1 and flow._pending_mission_craft_transfers[0].transfer_id=="new","stale "+kind+" preserves fresh transfer and owners")
		flow.free()
	for hex in [false,true]:
		f=fixture(); flow=f.flow; f.owner.hex=hex; f.controller.void_result=true
		flow._finish_space_surface_departure("craft")
		check(flow._aircraft_location_by_craft.craft==("mission" if hex else "starmap"),"void compatible only legacy hex="+str(hex))
		flow.free()
	f=fixture(); flow=f.flow; f.controller.commit_ready=true
	f.runtime.after_record=func(): flow._aircraft_location_by_craft.craft="new_visit"
	flow._finish_space_surface_departure("craft")
	check(flow._aircraft_location_by_craft.craft=="new_visit","completion observer cannot have new visit overwritten by old tail")
	flow.free()
	f=fixture(); flow=f.flow
	flow._all_team_units=[{"unit_id":"member","fireteam_id":"ft1"}]
	flow._assigned_aircraft_pilot_by_craft={"craft":"pilot"}
	flow._finish_space_surface_departure("craft")
	flow._finish_space_home_landing("craft")
	check(flow._aircraft_location_by_craft.craft=="mission" and flow._homebase_staged_unit_ids.is_empty(),"early HomeLanding stays in exact pending record without membership restore")
	f.controller.commit_ready=true
	f.runtime.after_record=func(): flow._aircraft_location_by_craft.craft="new_visit"
	flow._on_homebase_transport_timer_timeout()
	check(flow._homebase_staged_unit_ids.has("member") and flow._aircraft_location_by_craft.craft=="new_visit" and f.runtime.results.size()==1,"bound HomeLanding completes before final aborted observer without later old tail")
	flow.free()
	f=fixture(); flow=f.flow
	flow._active_singleplayer_identity={"craft_id":"craft"}
	flow._begin_mission_craft_transfer("craft","to_homebase",1.0)
	check(not flow._pending_mission_craft_transfers.is_empty() and f.controller.calls.is_empty() and flow._aircraft_location_by_craft.craft=="mission","positive Travelreceipt immediately captures marker before deferred initial callback")
	var newer: Dictionary=f.visit.duplicate(true); newer.unit_ids=["other_pilot"]
	f.place.set_meta("singleplayer_visit_identities",{"craft":newer})
	await process_frame
	check(f.controller.calls.is_empty() and flow._pending_mission_craft_transfers.is_empty() and flow._aircraft_location_by_craft.craft=="mission","deferred initial callback cannot capture a newer visit")
	flow.free()
	f=fixture(); flow=f.flow
	flow._active_singleplayer_identity={"craft_id":"craft"}
	f.controller.free()
	flow._begin_mission_craft_transfer("craft","to_homebase",1.0)
	check(f.runtime.fuel_commits==0 and flow._pending_mission_craft_transfers.is_empty() and flow._aircraft_location_by_craft.craft=="mission","failed retirement preflight runs before any legacy return fuel debit")
	flow.free()
	finish()
func finish() -> void:
	print("BOUND_SURFACE_DEPARTURE checks=%d failures=%d"%[checks,failures])
	quit(0 if failures==0 else 1)
