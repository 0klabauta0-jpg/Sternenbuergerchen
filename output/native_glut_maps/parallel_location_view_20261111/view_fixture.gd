extends SceneTree
class FlowProbe extends "res://scripts/meta/meta_layer_flow.gd":
	var host := Control.new()
	var admissions := 0
	var arrival_root: Node
	func _begin_mission_craft_transfer(_id: String,_phase: String,_duration: float,_source: String = MISSION_DROP_SOURCE_FOB) -> void: pass
	func _sync_homebase_direct_mission_drop_transport_fields() -> void: pass
	func _begin_active_mission_timer() -> void: pass
	func _ensure_transport_timer_state() -> void: pass
	func _start_or_update_active_mission(_map = null,_cache: RefCounted = null) -> void:
		admissions += 1
		_enter_location_context(arrival_root if arrival_root != null else _location_registry.get_location("polisa"))
		var controller = _active_mission.get_node("TacticalController")
		controller.plan["arrival_count"] = admissions
		_active_mission.get_node("MissionSetup").selected_team_unit_ids = PackedStringArray(["reinforcement"])
		_show_mission()
	func _ready() -> void: pass
	func _process(_d: float) -> void: pass
	func _get_mission_host(): return host
	func _get_homebase_screen(): return null
	func _get_fob_screen(): return null
	func _get_debrief_screen(): return null
	func _refresh_homebase_screen() -> void: pass
	func _refresh_preview_mission_lifecycle() -> void: pass
	func _set_navigation_visible(_v: bool) -> void: pass
	func _refresh_navigation_state() -> void: pass
	func _is_homebase_direct_mission_drop_source() -> bool: return true
class Place extends Node2D:
	var ticks := 0
	func _physics_process(_d: float) -> void: ticks += 1
class Controller extends Node:
	var retired := []
	var plan := {}
	func get_planning_state() -> Dictionary: return plan.duplicate(true)
	func set_tactical_ui_visible(_v: bool) -> void: pass
	func retire_location_craft_visit(id: String, _units: PackedStringArray) -> void: retired.append(id)
class Setup extends Node:
	var selected_team_unit_ids := PackedStringArray()
	var selected_team_fireteam_ids := PackedStringArray()
	var map_file_path := "fixture_map"
class Driver extends Node:
	var mission_timer_started_at_msec := 0
	var mission_time_limit_seconds := 0.0
class Runtime extends Node:
	var results := []
	var focus := "b"
	var phase := "quantum"
	func get_space_travel_snapshot(_id: String = "") -> Dictionary: return {"craft_id":focus,"phase":phase,"location_id":"polisa"}
	func record_mission_result(result: Dictionary, identity: Dictionary) -> void: results.append([result,identity])
	func observe_campaign_progress() -> void: pass
	func finish_space_approach(_id: String) -> void: pass
var commands := []
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ",label)
func make_place(id: String, craft: String, time: int) -> Place:
	var place := Place.new()
	place.set_meta("location_id",id)
	place.set_meta("singleplayer_mission_identity",{"craft_id":craft,"scenario_id":id,"job_id":"job_"+id})
	place.set_meta("singleplayer_visit_identities",{craft:{"unit_ids":[]}})
	var c := Controller.new(); c.name="TacticalController"; place.add_child(c)
	var s := Setup.new(); s.name="MissionSetup"; place.add_child(s)
	var d := Driver.new(); d.name="CombatLoopDriver"; d.mission_timer_started_at_msec=time; d.mission_time_limit_seconds=time*0.5; place.add_child(d)
	return place
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var flow := FlowProbe.new(); root.add_child(flow); flow.add_child(flow.host)
	var runtime := Runtime.new(); flow.add_child(runtime); flow._singleplayer_runtime=runtime
	var a := make_place("combat_a","a",1234); var b := make_place("polisa","b",5678)
	flow.host.add_child(a); flow.host.add_child(b)
	flow._location_registry.register_location("combat_a",a); flow._location_registry.register_location("polisa",b)
	flow._homebase_aircraft_definitions=[{"craft_id":"a"},{"craft_id":"b"},{"craft_id":"c"}]
	flow._aircraft_location_by_craft={"a":"mission","b":"mission","c":"homebase"}
	flow._craft_location_runtime={"a":"combat_a","b":"polisa"}
	flow._remember_location(a); flow._remember_location(b)
	check(flow.open_location_view("combat_a").ok,"open A")
	var identity := flow._active_singleplayer_identity.duplicate(true)
	check(flow._active_mission_started_at_msec==1234 and flow._active_mission_time_limit_seconds==617.0,"A existing Driver clock")
	check(flow.open_location_view("homebase").ok and flow._current_meta_view=="homebase","Home during quantum")
	check(flow.get_location_view_snapshot().craft_id=="","no Home autochoice")
	check(flow.select_location_view_craft("homebase","c").ok,"explicit Home choice")
	check(flow.get_location_view_snapshot().craft_id=="c","Home choice shown")
	flow.open_location_view("star_map")
	check(flow.get_location_view_snapshot().location_id=="","star has no service location")
	flow.open_location_view("polisa")
	check(flow._active_mission_started_at_msec==5678 and flow._active_mission_time_limit_seconds==2839.0,"B distinct Driver clock")
	check(flow.get_location_view_snapshot().craft_id=="","no primary/focus fallback")
	check(flow.select_location_view_craft("polisa","b").ok,"explicit Polisa choice")
	check(flow._active_singleplayer_identity.craft_id=="b" and runtime.focus=="b","selection preserves runtime identity/focus")
	check(not flow.select_location_view_craft("polisa","a").ok,"reject foreign craft")
	check(not flow.select_location_view_craft("polisa","unknown").ok,"reject unknown craft")
	flow._aircraft_location_by_craft.b="starmap"
	check(flow.get_location_view_snapshot().craft_id=="","stale selection empty")
	flow._aircraft_location_by_craft.b="mission"
	flow.open_location_view("combat_a")
	check(flow._active_singleplayer_identity==identity and flow._active_mission==a,"return preserves context and instance")
	check(a.visible and not b.visible,"only focused place visible")
	var at := a.ticks; var bt := b.ticks
	for i in range(4): await physics_frame
	check(a.ticks>at and b.ticks>bt,"both live roots tick while B hidden")
	flow._run_location_callback(b,func(_payload: Dictionary): flow._show_homebase(true),{})
	check(flow._active_mission==a and flow._current_meta_view=="mission" and flow._active_singleplayer_identity==identity,"background callback restores foreign context")
	check(flow._active_mission_started_at_msec==1234 and flow._active_mission_time_limit_seconds==617.0,"background callback restores A clock")
	flow._finish_space_surface_departure("b")
	check(flow._active_mission==a and flow._current_meta_view=="mission","background departure keeps A view")
	check(b.get_node("TacticalController").retired==["b"] and runtime.results.size()==1,"real retire and primary abort preserved")
	flow._finish_space_home_landing("b")
	check(flow._active_mission==a and flow._current_meta_view=="mission" and flow._active_singleplayer_identity==identity,"background landing keeps A context")
	check(flow._aircraft_location_by_craft.b=="homebase","real home arrival preserved")
	flow._craft_location_runtime.b="combat_a"; flow._aircraft_location_by_craft.b="mission"
	flow._finish_space_surface_departure("b")
	check(flow._active_mission==a and flow._current_meta_view=="mission","secondary same-place departure keeps viewer")
	check(a.get_node("TacticalController").retired==["b"] and runtime.results.size()==1,"secondary departure retires only own visit without primary abort")
	check(not flow.open_location_view("unloaded").ok,"unloaded view rejected")
	check(a.get_node("MissionSetup").selected_team_unit_ids.is_empty() and b.get_node("MissionSetup").selected_team_unit_ids.is_empty(),"view switches never admit/configure real crew")
	check(flow.admissions==0,"pure navigation and callbacks do not admit/configure")
	flow._craft_location_runtime.b="polisa"; flow._aircraft_location_by_craft.b="starmap"
	runtime.phase="approach"
	var entry := {"identity":{"craft_id":"b","location_id":"polisa","scenario_id":"polisa"},"mission_id":"polisa","mission":{},"units":PackedStringArray(),"teams":PackedStringArray(),"planning":{},"requires_resources":false}
	flow._space_approaches.b=entry.duplicate(true)
	flow._finish_space_approach("b")
	check(flow.admissions==1,"real approach still admits its destination")
	check(flow._active_mission==a and flow._current_meta_view=="mission" and flow._active_singleplayer_identity==identity,"background approach restores foreign view and identity")
	check(flow._active_mission_started_at_msec==1234 and flow._active_mission_time_limit_seconds==617.0,"approach restores foreign clock")
	flow.open_location_view("star_map")
	flow._space_approaches.b=entry.duplicate(true)
	flow._finish_space_approach("b")
	check(flow.admissions==2 and flow._active_mission==b and flow._current_meta_view=="mission","focused star traveller arrival may follow destination")
	flow.arrival_root=a
	flow.open_location_view("combat_a")
	flow._space_approaches.b=entry.duplicate(true)
	flow._finish_space_approach("b")
	check(flow._active_mission==a and flow._current_meta_view=="mission","same-place arrival keeps viewer")
	check(flow._mission_planning_state.get("arrival_count",0)==3 and flow._selected_unit_ids==PackedStringArray(["reinforcement"]),"same-place arrival rereads current Controller and Setup instead of stale projection")
	flow.open_location_view("homebase")
	flow._run_location_callback(a,func(_payload: Dictionary):
		a.get_node("TacticalController").plan["background_edit"]=true
		a.get_node("MissionSetup").selected_team_unit_ids=PackedStringArray(["crew_changed"])
	,{})
	check(flow._current_meta_view=="homebase" and flow._active_mission==a,"hidden same-root callback retains Home view")
	check(flow._mission_planning_state.get("background_edit",false) and flow._selected_unit_ids==PackedStringArray(["crew_changed"]),"hidden same-root callback rereads live projections")
	flow._run_location_callback(a,func(_payload: Dictionary):
		a.get_node("TacticalController").plan["terminal_edit"]=true
		a.get_node("MissionSetup").selected_team_unit_ids=PackedStringArray(["terminal_crew"])
		flow._release_active_mission()
	,{})
	check(flow._current_meta_view=="homebase" and flow._active_mission==a and flow._location_registry.get_location("combat_a")==a,"terminal hidden same-root release keeps registered place and Home view")
	check(flow._mission_planning_state.get("terminal_edit",false) and flow._selected_unit_ids==PackedStringArray(["terminal_crew"]),"terminal hidden same-root release restores live Controller/Setup projection")
	var screen = load("res://scripts/ui/star_map_screen.gd").new()
	root.add_child(screen)
	screen.configure(func(): return {"space_travel":{"phase":"surface"}},func(op: String,payload: Dictionary): commands.append([op,payload]); return {"ok":true})
	check(screen._view_homebase.visible and not screen._close.visible,"surface retains independent Basis ansehen")
	screen._view_homebase.pressed.emit()
	check(commands.back()==["open_location_view",{"location_id":"homebase"}],"Basis button view-only command")
	screen.refresh({"space_travel":{"phase":"grounded"}})
	screen._close.pressed.emit()
	check(commands.back()[0]=="space_prepare_launch","grounded Close still prepares actual launch")
	screen.refresh({"space_travel":{"phase":"orbit"},"location_runtimes":[{"location_id":"polisa"}]})
	screen._visit_buttons.polisa.pressed.emit()
	check(commands.back()==["open_location_view",{"location_id":"polisa"}],"loaded place button view-only command")
	screen._close.pressed.emit()
	check(commands.back()[0]=="space_open_operations","orbit Close retains operations command")
	screen.refresh({"space_travel":{"phase":"surface"}})
	check(screen._visit_buttons.is_empty(),"stale place buttons removed")
	screen.queue_free()
	print("LOCATION_VIEW_RESULT checks=",checks," failures=",failures)
	flow.queue_free(); await process_frame
	quit(1 if failures else 0)
