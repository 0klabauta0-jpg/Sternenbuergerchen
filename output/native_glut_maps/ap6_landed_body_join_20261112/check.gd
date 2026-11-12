extends SceneTree
const SOURCE = preload("res://scripts/tests/hex_ground_ship_producer_verifier.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const ROOT = preload("res://scripts/core/simulation_root.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const CATALOG = preload("res://scripts/terrain/frontier_ship_visuals.gd")
class MethodView extends VIEW:
	func _ready() -> void: pass
class JoinController extends SOURCE.Sandbox:
	var fixture_view: Node
	var fixture_terrain: Node
	func _get_primary_3d_view(): return fixture_view
	func _get_terrain_registry(): return fixture_terrain
	func _should_keep_campaign_dropship_landed() -> bool: return true
	func _get_units_for_drop_operation() -> Array: return fixture_crew
	func _store_active_drop_sequence_card() -> void: pass
	func _find_mission_dropship_card_entry(id: String) -> Dictionary:
		for card in _mission_drop_cards:
			if card.get("craft_id")==id: return card.duplicate(true)
		return {}
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func _init() -> void: call_deferred("run")
func run() -> void:
	var scene := Node.new(); root.add_child(scene); scene.set_meta("location_id","polisa")
	var terrain = TERRAIN.new(); terrain.name="TerrainRegistry"; scene.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for q in range(-1,2):
		for r in range(-1,3): terrain.register_tile(TILE.new({"tile_id":str(Vector2i(q,r)),"grid_position":Vector2i(q,r),"walkable":true}))
	var map = MAP.create_empty("body_join",Vector2i(3,4),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	var units = UNITS.new(); units.name="UnitRegistry"; scene.add_child(units)
	var sim = ROOT.new(); sim.name="SimulationRoot"; sim.unit_registry_path=NodePath("../UnitRegistry"); sim.terrain_registry_path=NodePath("../TerrainRegistry"); scene.add_child(sim); sim.set_physics_process(false)
	check(sim.configure_hex_ground_runtime(map,terrain).ok,"real Root configures bounded twelve-field terrain")
	var view := MethodView.new(); view._camera_yaw_degrees=25.0
	var controller := JoinController.new(); scene.add_child(controller); controller.set_process(false); controller.set_physics_process(false)
	controller.fixture_map=map; controller.fixture_terrain=terrain; controller.fixture_view=view
	var craft := {"craft_id":"join_cutlass","model_id":"cutlass","craft_type":"dropship","crew_capacity":8,"state":"waiting","has_lz_position":true,"lz_position":Vector2.ZERO,"approach_angle":"NW"}
	controller._mission_drop_cards=[craft]; controller._mission_drop_craft_id=craft.craft_id; controller._mission_drop_state="waiting"; controller._has_lz_position=true; controller._lz_position=Vector2.ZERO
	var actor = SOURCE.CrewActor.new(); actor.unit_id="join_crew"; actor.set_meta("dropship_embarked",true); actor.visible=false; scene.add_child(actor); units.register_unit(actor.unit_id,actor); sim.register_known_unit(actor.unit_id,actor); controller.fixture_crew=[actor]
	var before: Dictionary=controller._field_landing_by_craft.duplicate(true)
	var projected: Dictionary=controller._read_ground_ship_landing_projection(craft,Vector2.ZERO,"NW")
	var asset: Dictionary=CATALOG.get_ui_identity(craft)
	check(projected.get("ok",false) and projected.get("asset_id")==asset.asset_id and projected.get("model_scale")==asset.scale and projected.get("bounds").size==Vector3(asset.bounds_size[0],asset.bounds_size[1],asset.bounds_size[2]) and controller._field_landing_by_craft==before,"actual Controller getter joins real imported Cutlass without binding during preflight")
	var accepted: bool=controller._try_start_drop_sequence()
	var landing: Dictionary=controller._field_landing_by_craft.get(craft.craft_id,{})
	check(accepted and landing.has("ground_body_profile"),"actual arrival start binds accepted real geometry")
	if landing.has("ground_body_profile"):
		var profile: Dictionary=landing.ground_body_profile.duplicate(true)
		var card := craft.duplicate(true); card.state="landed"; card.dropship_position=landing.resolved_lz_position; card.lz_position=landing.resolved_lz_position
		var visual: Dictionary=controller._build_mission_dropship_visual_entry(card,0,false,landing.resolved_lz_position,false,false)
		check(visual.get("ground_body_profile")==profile and view._get_dropship_rotation_y_for_payload(visual,landing.resolved_lz_position)==profile.yaw_degrees,"actual visualentry and render yaw match accepted total angle")
		var stable := true
		for camera in [0.0,93.0,280.0]:
			view._camera_yaw_degrees=camera
			stable=stable and view._get_dropship_rotation_y_for_payload(visual,landing.resolved_lz_position)==profile.yaw_degrees and controller._field_landing_by_craft[craft.craft_id].ground_body_profile==profile
		check(stable,"camera updates neither rotate nor rewrite the accepted landed body")
		visual.ground_body_profile.yaw_degrees=-99
		check(controller._field_landing_by_craft[craft.craft_id].ground_body_profile==profile,"visual payload remains detached from accepted owner profile")
	view.free(); scene.free()
	print("AP6_LANDED_BODY_JOIN_RESULT checks=%d failures=%d native_approved=false"%[checks,failures])
	quit(1 if failures else 0)
