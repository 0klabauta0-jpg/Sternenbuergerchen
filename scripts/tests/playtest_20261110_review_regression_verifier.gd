extends SceneTree
class LandingFixture:
	extends "res://scripts/tests/mission_tactical_sandbox_controller.gd"
	var test_cards: Array=[]
	func _get_mission_dropship_card_entries() -> Array: return test_cards
	func _should_keep_campaign_dropship_landed() -> bool: return true
	func _find_friendly_unit_by_id(_id: String) -> Node: return null
	func _refresh_world_overlays() -> void: pass
class ScreenFixture:
	extends Node
	func _get_member_loadout(_id: String) -> Dictionary: return {"armor":"heavy","weapon_1":"smg","weapon_2":"none"}
class SetupFixture:
	extends Node
	var selected_team_unit_ids:=PackedStringArray(["u","resident"])
	var selected_team_fireteam_ids:=PackedStringArray(["ft1","ft2"])
	var selected_team_unit_configs: Array=[]
	var member_loadouts: Dictionary={"u":{"armor":"light"},"resident":{"armor":"medium"}}
	var scenario_file_path:="res://data/mission_scenarios/satellite_recovery.json"
	var refreshed:=PackedStringArray()
	func apply_runtime_selection_contract(_keep: bool,ids: PackedStringArray=PackedStringArray()) -> void: refreshed=ids
class ControllerFixture:
	extends Node
	func get_planning_state() -> Dictionary: return {"mission_drop_cards":[]}
class DriverFixture:
	extends Node
	var reset_called:=false
	func reset_for_location_job(_path: String) -> void: reset_called=true
class FlowFixture:
	extends "res://scripts/meta/meta_layer_flow.gd"
	var test_screen: Node
	var test_place: Node
	func get_mission_for_craft(_id: String) -> Node: return test_place
	var returned: Array=[]
	var bootstrap_repaired:=false
	func _ensure_singleplayer_release_default_mission_selection() -> bool: return false
	func _ensure_singleplayer_release_homebase_direct_drop_source() -> bool: return false
	func _is_singleplayer_visible_homebase_actionable(_screen: Node) -> bool: return false
	func _repair_singleplayer_bootstrap_start_state(_force: bool) -> void: bootstrap_repaired=true
	func _seed_singleplayer_bootstrap_homebase_payload() -> void: pass
	func _refresh_homebase_screen() -> void: pass
	func _get_homebase_screen(): return test_screen
	func _enter_location_context(instance: Node) -> void:
		_active_singleplayer_identity=instance.get_meta("singleplayer_mission_identity",{})
	func _remember_location(_instance: Node) -> void: pass
	func _apply_planning_state_to_mission(_instance: Node) -> void: pass
	func _is_homebase_direct_mission_drop_source() -> bool: return true
	func _build_homebase_direct_mission_sync_craft_ids(_cards: Array) -> PackedStringArray: return PackedStringArray(["A","B"])
	func _find_pending_mission_craft_transfer(_id: String) -> Dictionary: return {}
	func _find_mission_drop_card_in_planning_state(_id: String) -> Dictionary: return {"payload_source":"homebase_direct"}
	func _begin_mission_craft_transfer(id: String,_phase: String,_duration: float,_source: String="fob") -> void: returned.append(id)
var failed:=0
func _init() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	var landing:=LandingFixture.new(); landing.set("_mission_drop_craft_id","B")
	for state in ["inbound","landing","unloading","waiting"]:
		landing.test_cards=[{"craft_id":"A","state":state,"has_lz_position":true,"lz_position":Vector2(600,400)}]
		check(landing.call("_campaign_occupied_landing_positions").has(Vector2(600,400)),"other arrival reserves footprint during "+state)
	landing.set("_parallel_drop_sequences_by_craft",{"A":{"phase":"complete"},"B":{"phase":"complete"}})
	landing.set("_deployed_unit_ids",{"u":true,"resident":true})
	landing.retire_location_craft_visit("A",PackedStringArray(["u"]))
	check(not landing.get("_parallel_drop_sequences_by_craft").has("A") and landing.get("_parallel_drop_sequences_by_craft").has("B") and not landing.get("_deployed_unit_ids").has("u") and landing.get("_deployed_unit_ids").has("resident"),"surface exit retires only departing craft and actors")
	landing.free()
	var flow:=FlowFixture.new(); var screen:=ScreenFixture.new(); flow.test_screen=screen
	flow.set("_selected_unit_ids",PackedStringArray(["u"])); flow.set("_selected_fireteam_ids",PackedStringArray(["ft1"]))
	flow.set("_all_team_units",[{"unit_id":"u"},{"unit_id":"resident"}])
	flow.set("_active_singleplayer_identity",{"craft_id":"B","job_id":"satellite_recovery","scenario_id":"satellite_recovery","location_id":"satellite_crash","departure_token":"new"})
	var place:=Node.new(); place.set_meta("location_id","satellite_crash"); place.set_meta("singleplayer_mission_identity",{"craft_id":"A","job_id":"","location_id":"satellite_crash"})
	var setup:=SetupFixture.new(); setup.name="MissionSetup"; place.add_child(setup)
	var controller:=ControllerFixture.new(); controller.name="TacticalController"; place.add_child(controller)
	var driver:=DriverFixture.new(); driver.name="CombatLoopDriver"; place.add_child(driver)
	flow.call("_admit_existing_location",place)
	check(setup.member_loadouts.u.armor=="heavy" and setup.member_loadouts.resident.armor=="medium","returning visitor receives current gear while resident gear stays")
	check(setup.refreshed.has("u") and not setup.refreshed.has("resident"),"only arriving actor loadout is refreshed")
	check(String(place.get_meta("singleplayer_mission_identity").craft_id)=="B","new job visit binds actual incoming craft instead of old place visitor")
	check(driver.reset_called,"new job visit receives fresh job gates without rebuilding place")
	flow.set("_active_singleplayer_identity",{"craft_id":"A","job_id":"satellite_recovery"})
	flow.set("_aircraft_location_by_craft",{"A":"mission","B":"mission"})
	flow.call("_return_homebase_direct_craft_after_mission")
	check(flow.returned==["A"],"job result returns its own departure and leaves other visitor alone")
	flow.set_meta("singleplayer_bootstrap_enabled",true)
	flow.set("_location_contexts",{"satellite_crash":{}})
	flow.call("_ensure_singleplayer_visible_homebase_actionability")
	check(not flow.bootstrap_repaired,"return to a retained world never invokes startup roster repair")
	flow.test_place=place
	place.set_meta("singleplayer_visit_identities",{"A":{"unit_ids":["u","unknown"],"fireteam_ids":["ft1","ft3"]}})
	flow.set("_homebase_staged_unit_ids",PackedStringArray(["resident"]))
	flow.set("_homebase_staged_fireteam_ids",PackedStringArray(["ft2"]))
	flow.call("_restore_returning_visit_membership","A")
	check(flow.get("_homebase_staged_unit_ids")==PackedStringArray(["resident","u"]) and flow.get("_homebase_staged_fireteam_ids")==PackedStringArray(["ft2","ft1"]),"home arrival restores only real returning team membership")
	place.free(); flow.free(); screen.free()
	print("REVIEW_REGRESSION failed=",failed); quit(1 if failed else 0)
