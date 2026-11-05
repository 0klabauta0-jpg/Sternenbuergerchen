extends SceneTree
## Normal menu -> Homebase -> default mission -> real timed insertion -> Move/GO.
## No release fixture, teleports, forced arrival/unloading, or private state writes.
const MENU := "res://scenes/ui/main_menu.tscn"
const META := "res://scenes/meta/meta_layer_test.tscn"
const MISSION := "res://scenes/tests/mission_reactivity_test.tscn"
const CUTLASS := "res://Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb"
const BUCCANEER := "res://Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/buccaneer_01.glb"
const ROSTER := "user://profiles/local_player/roster_v1.json"
const EVIDENCE_ROOT := "res://output/grafik_20261101/main_adoption_runtime/"
var _output := ""
var _capture_root := ""
var _deadline := 0
var _started := 0
var _checks: Array = []
var _stages: Array = []
var _captures: Array = []
var _facts := {"synthetic_fixture":false,"time_acceleration":false,"forced_arrival":false,"forced_unloading":false,"private_simulation_state_writes":false,"profile_reset":false}
var _roster_before := ""
var _roster_identity_before := ""
var _roster_existed := false
var _finished := false

func _initialize() -> void:
	call_deferred("_run")

func _argument(key: String,fallback: String = "") -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size()):
		if args[index].begins_with(key+"="): return args[index].substr(key.length()+1)
		if args[index]==key and index+1<args.size(): return args[index+1]
	return fallback

func _check(condition: bool,label: String) -> bool:
	_checks.append({"passed":condition,"label":label})
	print("PASS: " if condition else "FAIL: ",label)
	return condition

func _snapshot(node: Node,method: String) -> Dictionary:
	if node==null or not is_instance_valid(node) or not node.has_method(method): return {}
	var value: Variant = node.call(method)
	return value if value is Dictionary else {}

func _keep(source: Dictionary,keys: Array) -> Dictionary:
	var result := {}
	for key in keys:
		if source.has(key): result[key] = source[key]
	return result

func _stage(id: String,details: Dictionary = {}) -> void:
	_stages.append({"id":id,"elapsed_msec":Time.get_ticks_msec()-_started,"details":details})
	print("FRONTIER_STARTUP_STAGE ",id)

func _wait_until(label: String,predicate: Callable,seconds: float = 15.0) -> bool:
	var end := mini(_deadline,Time.get_ticks_msec()+roundi(seconds*1000.0))
	while Time.get_ticks_msec()<end:
		if bool(predicate.call()): return true
		await create_timer(0.10).timeout
	return _check(false,"Timed out waiting for "+label)

func _frames(count: int) -> void:
	for index in range(count): await process_frame

func _capture(id: String,view: Node = null,settle_frames: int = 8) -> void:
	if DisplayServer.get_name()=="headless": return
	if view!=null and view.has_method("_request_viewport_redraw"):
		view.call("_request_viewport_redraw",true,60000)
	await _frames(settle_frames)
	await RenderingServer.frame_post_draw
	var path := _capture_root+id+".png"
	if not _check(not FileAccess.file_exists(path),"Capture target is new: "+id): return
	var error := root.get_texture().get_image().save_png(path)
	_check(error==OK,"Native capture saved: "+id)
	var capture := {"id":id,"path":path,"error":error,"width":root.size.x,"height":root.size.y,"sha256":FileAccess.get_sha256(path) if error==OK else "","scene":current_scene.scene_file_path if current_scene!=null else ""}
	if view!=null:
		var camera := view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/Camera3D") as Camera3D
		if camera!=null:
			capture["camera_transform"] = str(camera.global_transform)
			capture["camera_size"] = camera.size
			capture["camera_projection"] = camera.projection
	_captures.append(capture)

func _model_identities(node: Node) -> Array:
	var result: Array = []
	if node==null: return result
	var nodes: Array = [node]
	nodes.append_array(node.find_children("*","Node",true,false))
	for candidate in nodes:
		var path: String = candidate.scene_file_path
		if not path.ends_with(".glb"): continue
		var item := {"node":str(candidate.get_path()),"resource":path,"sha256":FileAccess.get_sha256(path)}
		if candidate is Node3D:
			item["global_position"] = str(candidate.global_position)
			item["global_scale"] = str(candidate.global_transform.basis.get_scale())
		result.append(item)
	return result

func _visual_snapshot(view: Node) -> Dictionary:
	var snapshot := _snapshot(view,"get_render_snapshot")
	return _keep(snapshot,["frontier_art_enabled","frontier_art_override","frontier_art_profile_id","grid_topology","tile_count","unit_model_count","dropship_model_visible","dropship_visual_count","missing_asset_mapping_count","missing_dropship_model_count","read_only","ui_sets_gameplay_truth"])

func _planning_snapshot(controller: Node) -> Dictionary:
	# Avoid exporting player names, profile content or full mission dictionaries.
	return _keep(_snapshot(controller,"get_planning_state"),["has_lz_position","lz_position","mission_drop_source","mission_drop_craft_id","mission_drop_state","mission_drop_progress","mission_drop_eta_seconds","drop_ship_requested","drop_ship_staged","embarked_unit_ids","deployed_unit_ids","deployed_unit_positions","selected_fireteams"])

func _positions(mission: Node,unit_ids: Array) -> Dictionary:
	var result := {}
	var registry := mission.get_node_or_null("UnitRegistry")
	if registry==null: return result
	for id in unit_ids:
		var unit: Node = registry.call("get_unit",String(id))
		if unit is Node2D: result[String(id)] = unit.position
	return result

func _roster_identity_digest() -> String:
	if not FileAccess.file_exists(ROSTER): return ""
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROSTER))
	if not parsed is Dictionary: return ""
	var roster: Dictionary = parsed.get("roster",{})
	var ids := PackedStringArray()
	for unit in roster.get("units",[]): ids.append(String(unit.get("unit_id","")))
	if ids.is_empty(): return ""
	ids.sort()
	return JSON.stringify([parsed.get("profile_id",""),parsed.get("generator_id",""),parsed.get("generator_seed",""),ids]).sha256_text()

func _authored_mission_points(map_path: String,mission: Node) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(map_path))
	if not _check(parsed is Dictionary,"Original default map JSON is available"): return {}
	var data: Dictionary = parsed
	var markers: Dictionary = data.get("markers",{})
	if not _check(markers.has("spawn_alpha"),"Default mission retains its authored Alpha insertion marker"): return {}
	var marker: Dictionary = markers["spawn_alpha"]
	var lz := Vector2(float(marker["x"]),float(marker["y"]))
	var registry := mission.get_node_or_null("TerrainRegistry")
	if not _check(registry!=null,"Normal mission exposes the authoritative terrain registry"): return {}
	var grid: Vector2i = registry.call("world_to_grid",lz)
	if not _check(bool(registry.call("is_walkable",grid)),"Authored Alpha insertion marker is on walkable terrain"): return {}
	var gameplay := data.duplicate(true)
	gameplay.erase("terrain_visual_theme_id")
	gameplay.erase("surface_visual_theme_id")
	_facts["default_map"] = {"path":map_path,"sha256":FileAccess.get_sha256(map_path),"gameplay_without_theme_sha256":JSON.stringify(gameplay).sha256_text(),"lz_marker":"spawn_alpha","lz_world":lz,"lz_grid":grid}
	for offset in [Vector2i(0,-3),Vector2i(3,0),Vector2i(-3,0),Vector2i(0,3)]:
		var target: Vector2i = grid+offset
		var line: Array = registry.call("get_grid_line",grid,target)
		var clear := not line.is_empty()
		for cell in line: clear = clear and bool(registry.call("is_walkable",cell))
		if clear: return {"lz":lz,"move":registry.call("grid_to_world",target)}
	_check(false,"Authoritative registry exposes a clear short Move route from insertion")
	return {}

func _run() -> void:
	_started = Time.get_ticks_msec()
	_deadline = _started+roundi(clampf(float(_argument("--startup-timeout-seconds","150")),45.0,300.0)*1000.0)
	var stamp := Time.get_datetime_string_from_system(true).replace(":","").replace("-","")
	_output = _argument("--evidence-output",EVIDENCE_ROOT+"startup_"+stamp+"_pid"+str(OS.get_process_id())+".json")
	if FileAccess.file_exists(_output):
		print("FRONTIER_MAIN_STARTUP FAILED: evidence output already exists; no overwrite: ",_output)
		quit(2)
		return
	_capture_root = _output.get_basename()+"_captures/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_capture_root)):
		print("FRONTIER_MAIN_STARTUP FAILED: capture directory already exists; no overwrite: ",_capture_root)
		quit(2)
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output.get_base_dir()))
	if directory_error==OK: directory_error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_root))
	if directory_error!=OK:
		print("FRONTIER_MAIN_STARTUP FAILED: cannot create unique evidence directory: ",directory_error)
		quit(2)
		return
	root.size = Vector2i(1920,1080)
	_roster_existed = FileAccess.file_exists(ROSTER)
	_roster_before = FileAccess.get_sha256(ROSTER) if _roster_existed else ""
	_roster_identity_before = _roster_identity_digest()
	var source_hashes := {}
	for path in ["res://project.godot",MENU,META,MISSION,"res://scripts/tests/frontier_main_startup_verifier.gd","res://scripts/ui/main_menu_screen.gd","res://scripts/meta/meta_layer_flow.gd","res://scripts/tests/mission_test_setup.gd","res://scripts/terrain/terrain_map_3d_view.gd",CUTLASS,BUCCANEER]:
		source_hashes[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "missing"
	_facts["sources_sha256"] = source_hashes
	if not _check(String(ProjectSettings.get_setting("application/run/main_scene",""))==MENU,"Project normal entry is MainMenu"):
		await _finish()
		return
	var packed := load(MENU) as PackedScene
	if not _check(packed!=null,"Normal main menu scene loads"):
		await _finish()
		return
	var menu := packed.instantiate()
	root.add_child(menu)
	current_scene = menu
	await _frames(5)
	var background := _snapshot(menu,"get_background_catalog_snapshot")
	var background_path := String(background.get("path",""))
	var background_node := menu.get_node_or_null("Background") as TextureRect
	_check(background_node!=null and background_node.texture!=null,"MainMenu displays a background texture")
	_check(bool(background.get("uses_catalog",false)),"MainMenu background comes from the existing catalog")
	_check(background_path == "res://Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg","Normal MainMenu restores the original TASK199 title artwork")
	_stage("main_menu",{"scene":menu.scene_file_path,"background_path":background_path,"background_sha256":FileAccess.get_sha256(background_path) if FileAccess.file_exists(background_path) else ""})
	await _capture("01_main_menu")
	var button := menu.get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton") as Button
	if not _check(button!=null and not button.disabled,"Real Singleplayer button is actionable"):
		await _finish()
		return
	button.pressed.emit()
	if not await _wait_until("normal Singleplayer scene",func() -> bool: return current_scene!=null and current_scene.scene_file_path==META):
		await _finish()
		return
	var flow := current_scene
	await _frames(8)
	var bootstrap := _snapshot(flow,"get_singleplayer_start_bootstrap_snapshot")
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	if not _check(homebase!=null and homebase.is_visible_in_tree(),"Normal Singleplayer opens visible Homebase"):
		await _finish()
		return
	var craft_id := String(bootstrap.get("craft_id",""))
	_check(String(bootstrap.get("selected_mission_id",""))=="grid_sweep","Original normal grid_sweep mission remains selected")
	_check(Array(bootstrap.get("selected_unit_ids",[])).size()>=2,"Normal Homebase bootstrap provides a playable team")
	_check(not craft_id.is_empty() and not String(bootstrap.get("pilot_unit_id","")).is_empty(),"Normal Homebase has a craft and pilot")
	_check(String(_snapshot(homebase,"get_pre_mission_readiness_snapshot").get("overall_state",""))=="ready","Normal Homebase payload is ready without fixture mutation")
	_stage("homebase",_keep(bootstrap,["selected_mission_id","selected_mission_map_path","craft_id","craft_location","payload_seeded","visible_homebase_post_show_guard_after_actionable"]))
	await _capture("02_homebase")
	if not _check(bool(homebase.call("can_request_mission_start")),"Normal Homebase launch command is accepted"):
		await _finish()
		return
	# No craft override: this is the visible Start Mission action and its normal route.
	homebase.call("request_mission_start")
	if not await _wait_until("normal active mission",func() -> bool: return flow.call("get_active_mission")!=null):
		await _finish()
		return
	if not await _wait_until("deferred mission runtime nodes",func() -> bool:
		var active: Node = flow.call("get_active_mission")
		return active!=null and active.has_node("TacticalController") and active.has_node("Primary3DView") and active.has_node("SimulationRoot")
	):
		await _finish()
		return
	var mission: Node = flow.call("get_active_mission")
	var controller := mission.get_node_or_null("TacticalController")
	var view := mission.get_node_or_null("Primary3DView")
	var simulation := mission.get_node_or_null("SimulationRoot")
	if not _check(controller!=null and view!=null and simulation!=null,"Normal mission owns TacticalController, Primary3DView and SimulationRoot"):
		await _finish()
		return
	if not await _wait_until("default map visual configuration",func() -> bool: return int(_visual_snapshot(view).get("tile_count",0))>0):
		await _finish()
		return
	_check(mission.scene_file_path==MISSION,"Menu launch reaches the regular mission scene")
	var handoff := _snapshot(flow,"get_homebase_to_mission_handoff_snapshot")
	_check(String(handoff.get("selected_mission_id",""))=="grid_sweep","Handoff retains the original default mission")
	_check(String(handoff.get("handoff_gate",""))=="pass","Normal Homebase-to-Mission handoff passes")
	var render := _visual_snapshot(view)
	_check(bool(render.get("frontier_art_enabled",false)),"Default mission enables the Frontier visual profile")
	_check(int(render.get("frontier_art_override",-2))==-1,"Frontier activation comes from normal map data without a test override")
	_check(String(render.get("grid_topology",""))=="hex_axial_v1","Rebuilt default mission uses its saved, user-requested Hex topology")
	_check(bool(render.get("read_only",false)) and not bool(render.get("ui_sets_gameplay_truth",true)),"Regular renderer remains a read-only state consumer")
	var points := _authored_mission_points(String(bootstrap.get("selected_mission_map_path","")),mission)
	if points.is_empty():
		await _finish()
		return
	_stage("mission_started",{"scene":mission.scene_file_path,"render":render,"planning":_planning_snapshot(controller)})
	await _capture("03_default_mission",view)
	if not await _wait_until("normal 18-second craft arrival",func() -> bool:
		var state := String(_planning_snapshot(controller).get("mission_drop_state",""))
		return state=="waiting"
	,45.0):
		await _finish()
		return
	_stage("craft_arrived",{"planning":_planning_snapshot(controller)})
	# Existing UI handler and normal screen-to-tile LZ placement; no resolved-position injection.
	controller.call("_on_mission_dropship_card_set_lz_pressed",craft_id)
	var lz: Vector2 = points["lz"]
	view.call("focus_world_position",lz)
	await _frames(2)
	var screen: Vector2 = view.call("world_to_screen_position",lz)
	if not _check(bool(controller.call("_place_lz_from_screen_position",screen)),"Normal Set LZ handler places the existing default-mission LZ"):
		await _finish()
		return
	_check(bool(_planning_snapshot(controller).get("has_lz_position",false)),"Normal planning exposes the requested LZ")
	controller.call("_on_mission_dropship_card_drop_pressed",craft_id)
	if not await _wait_until("accepted Drop request",func() -> bool: return bool(_planning_snapshot(controller).get("drop_ship_requested",false)),10.0):
		await _finish()
		return
	var expected_payload: Array = _planning_snapshot(controller).get("embarked_unit_ids",[])
	_check(expected_payload.size()>=2,"Normal Drop request retains a playable embarked team")
	_stage("drop_requested",{"planning":_planning_snapshot(controller)})
	if not await _wait_until("actual regular dropship model",func() -> bool: return bool(_visual_snapshot(view).get("dropship_model_visible",false)),8.0):
		await _finish()
		return
	if DisplayServer.get_name()!="headless":
		# Observe the real flight near the LZ, rather than photographing initial
		# instantiation outside the map. No runtime is paused or advanced by hand.
		if not await _wait_until("near-LZ flight phase",func() -> bool:
			var planning := _planning_snapshot(controller)
			return String(planning.get("mission_drop_state",""))!="inbound" or float(planning.get("mission_drop_progress",0.0))>=75.0
		,12.0):
			await _finish()
			return
	var models := _model_identities(view)
	_facts["approach_models"] = models.duplicate(true)
	_stage("lz_approach",{"render":_visual_snapshot(view),"planning":_planning_snapshot(controller)})
	await _capture("04_lz_approach",view,0)
	if not await _wait_until("real timed deployment and full payload",func() -> bool:
		var planning := _planning_snapshot(controller)
		var deployed_ids: Array = planning.get("deployed_unit_ids",[])
		for id in expected_payload:
			if not deployed_ids.has(id): return false
		return deployed_ids.size()>=2 and Array(planning.get("embarked_unit_ids",[])).is_empty()
	,65.0):
		await _finish()
		return
	await _frames(8)
	var deployed: Array = _planning_snapshot(controller).get("deployed_unit_ids",[])
	_check(deployed.size()>=2,"Normal drop deploys a playable payload without forced unloading")
	models.append_array(_model_identities(view))
	var cutlass_hash := FileAccess.get_sha256(CUTLASS)
	var actual_cutlass := false
	for item in models:
		actual_cutlass = actual_cutlass or (not cutlass_hash.is_empty() and item.get("sha256","")==cutlass_hash)
	_check(actual_cutlass,"Actual regular dropship instance uses the active Ref03 Cutlass bytes")
	_check(int(_visual_snapshot(view).get("unit_model_count",0))>=2,"Deployed units use actual regular 3D model instances")
	_facts["deployment_models"] = models
	_stage("deployed",{"planning":_planning_snapshot(controller),"render":_visual_snapshot(view)})
	await _capture("05_deployed",view)
	var before_positions := _positions(mission,deployed)
	var before_tick := int(simulation.call("get_tick"))
	var move_target: Vector2 = points["move"]
	if not _check(bool(controller.call("issue_right_click_command_for_test",move_target,"move",false)),"Existing Move action creates the normal selected-team plan"):
		await _finish()
		return
	if not _check(bool(controller.call("execute_selected_fireteam_orders")),"Existing GO action commits the selected-team plan"):
		await _finish()
		return
	if not await _wait_until("authoritative movement after GO",func() -> bool:
		if int(simulation.call("get_tick"))<=before_tick: return false
		var positions := _positions(mission,deployed)
		for id in before_positions:
			if positions.has(id) and Vector2(positions[id]).distance_to(Vector2(before_positions[id]))>0.05: return true
		return false
	,15.0):
		await _finish()
		return
	_stage("go_movement",{"tick_before":before_tick,"tick_after":simulation.call("get_tick"),"before_positions":before_positions,"after_positions":_positions(mission,deployed),"planning":_planning_snapshot(controller)})
	await _capture("06_go_movement",view)
	await _finish()

func _finish() -> void:
	if _finished: return
	_finished = true
	if not _roster_identity_before.is_empty():
		_check(_roster_identity_digest()==_roster_identity_before,"Existing player profile, generator and unit identities remain unchanged")
	_facts["player_roster_existed_before"] = _roster_existed
	_facts["player_roster_created_by_normal_start"] = not _roster_existed and FileAccess.file_exists(ROSTER)
	_facts["player_roster_before_sha256"] = _roster_before
	_facts["player_roster_after_sha256"] = FileAccess.get_sha256(ROSTER) if FileAccess.file_exists(ROSTER) else ""
	_facts["player_roster_identity_before_sha256"] = _roster_identity_before
	_facts["player_roster_identity_after_sha256"] = _roster_identity_digest()
	var failed := 0
	for check in _checks:
		if not check["passed"]: failed += 1
	var report := {"schema":"sternenbuergerchen.frontier_main_startup.v1","passed":_checks.size()-failed,"failed":failed,"checks":_checks,"stages":_stages,"captures":_captures,"facts":_facts,"engine":Engine.get_version_info(),"renderer":{"display":DisplayServer.get_name(),"method":RenderingServer.get_current_rendering_method(),"driver":RenderingServer.get_current_rendering_driver_name()},"elapsed_msec":Time.get_ticks_msec()-_started,"scope":"Actual normal scene/UI-command route with real timer-driven transport/deployment. Bounded smoke, no complete campaign/combat/performance/art acceptance."}
	var file := FileAccess.open(_output,FileAccess.WRITE)
	if file==null:
		print("FRONTIER_MAIN_STARTUP FAILED: evidence open error ",FileAccess.get_open_error())
		quit(2)
		return
	file.store_string(JSON.stringify(report,"\t"))
	file.flush()
	file.close()
	if current_scene!=null:
		current_scene.queue_free()
		current_scene = null
	await _frames(2)
	print("FRONTIER_MAIN_STARTUP ",JSON.stringify({"passed":report["passed"],"failed":failed,"evidence_output":_output,"stages":_stages.size()}))
	quit(1 if failed else 0)
