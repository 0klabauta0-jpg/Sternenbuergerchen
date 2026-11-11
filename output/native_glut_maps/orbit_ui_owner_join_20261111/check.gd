extends SceneTree
## One UI/API join; deliberately not a native rendering or travel acceptance.
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const SCREEN = preload("res://scripts/ui/star_map_screen.gd")

class PilotOwner extends Node:
	func is_pilot_aboard(_id: String) -> bool: return true

class FlowEnvelope extends Node:
	var _selected_mission_id := ""
	var _last_mission_result := {}

var fleet: RefCounted
var sim: Node
var adapter: Node
var area_calls: Array[String] = []
var commands: Array[Dictionary] = []
var selected_id := "space_fixture_ui_selected"
var first_id := "space_fixture_ui_first_grounded"
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _snapshot() -> Dictionary:
	# Controlled FULL UI envelope only. Positions/areas come from real owners.
	return {"space_travel":adapter.get_space_travel_snapshot(), "space_wings":sim.get_space_wing_snapshot(),
		"crafts":[{"craft_id":first_id,"display_name":"First: grounded"},{"craft_id":selected_id,"display_name":"Second: local"}],
		"campaign":{"locations":{},"jobs":{}}, "location_runtimes":[]}

func _area(id: String) -> Dictionary:
	area_calls.append(id)
	return adapter.get_space_area_projection(id)

func _command(operation: String, payload: Dictionary) -> Dictionary:
	var result: Dictionary = adapter.request_operation(operation, payload)
	commands.append({"operation":operation,"payload":payload.duplicate(true),"result":result.duplicate(true)})
	return result

func _check(condition: bool, description: String) -> void:
	assert(condition, description)
	checks += 1
	print("PASS ", description)

func _run() -> void:
	sim = ROOT.new()
	fleet = FLEET.new()
	assert(fleet.configure().ok)
	fleet.register_craft(first_id)
	fleet.register_craft(selected_id)
	assert(fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":"launch_to_orbit","payload":{"craft_id":selected_id},"request_id":"ui-join-launch"},{"runtime_authorized":true}).ok)
	var equipment = EQUIPMENT.new()
	assert(equipment.configure([{"craft_id":selected_id,"model_id":"cutlass"}]).ok)
	var pilot = PilotOwner.new()
	sim.configure_singleplayer_owners(null,null,null,fleet)
	sim.configure_ship_equipment(equipment)
	sim.configure_base_personnel(pilot)
	adapter = ADAPTER.new()
	adapter._simulation = sim
	adapter._travel = fleet
	var flow = FlowEnvelope.new()
	adapter._flow = flow
	var flight: RefCounted = fleet.get_flight_state(selected_id)
	var cell: Vector2i = GRID.from_offset(Vector2i(200,100))
	assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision,"coordinate_frame":"local","space_area_id":"orbit_approach:moon","position_plane":GRID.HEX.axial_to_plane(Vector2(cell)),"motion_mode":"tactical"},1).ok)
	var combat: RefCounted = sim.get("_space_combat_state")
	var profile: Dictionary = equipment.get_space_flight_profile(selected_id)
	assert(profile.ok)
	assert(combat.admit_actor({"craft_id":selected_id,"faction_id":"player","control_domain":"player","start_hex":cell,"footprint_hexes":profile.footprint_hexes},flight,true).ok)
	assert(sim.get("_space_wing_state").ensure_flying_wings("singleplayer",[selected_id],[selected_id],{selected_id:"pilot"}).ok)
	var screen = SCREEN.new()
	root.add_child(screen)
	screen.configure(_snapshot,_command,_area)
	screen.set_process(false)
	var canvas: Control = screen.get("_orbit_canvas")
	canvas.size = Vector2(900,500)
	_check(canvas.get_selected_craft_id().is_empty() and screen.get("_orbit_button").disabled and area_calls.is_empty(),"No implicit first-craft or local-craft selection")
	# Emit the real selector event, rather than calling the movement handler.
	var selector: OptionButton = screen.get("_fleet_selector")
	selector.select(1)
	selector.item_selected.emit(1)
	_check(commands.size() == 1 and commands[0].operation == "space_focus_craft" and commands[0].result.ok and fleet.get_snapshot().craft_id == selected_id,"Explicit second craft selection reaches real adapter")
	_check(area_calls.has(selected_id) and canvas.get_selected_craft_id() == selected_id and not screen.get("_orbit_button").disabled,"Real area provider exposes selected local actor")
	var projected: Dictionary = canvas.get_projection()
	_check(projected.ok and projected.actors.size() == 1 and projected.actors[0].craft_id == selected_id and projected.actors[0].flight == flight.get_snapshot(),"Canvas contains exact authoritative Flight snapshot")
	screen.get("_orbit_button").pressed.emit()
	_check(canvas.visible and screen.get("_orbit_visible"),"Orbit button opens actual area canvas")
	var target := cell + Vector2i(4,0)
	var before: Vector2 = flight.get_snapshot().position_plane
	_check(canvas.request_move_at(canvas.hex_to_screen(target)),"Canvas accepts local move intent")
	var sent: Dictionary = commands.back()
	_check(sent.operation == "space_move" and sent.payload.craft_id == selected_id and sent.payload.target_hex == target and sent.result.ok and flight.get_snapshot().position_plane == before,"Screen move reaches real adapter and Root without moving UI state")
	sim._advance_space_flights(0.1,2)
	_check(flight.get_snapshot().position_plane != before,"One real owner tick moves selected Flight")
	screen.call("_refresh_orbit_projection")
	_check(canvas.get_projection().actors[0].flight.position_plane == flight.get_snapshot().position_plane,"Canvas refresh reads moved owner position")
	selector.select(0)
	selector.item_selected.emit(0)
	_check(area_calls.back() == first_id and canvas.get_selected_craft_id().is_empty() and screen.get("_orbit_button").disabled and not canvas.request_move_at(canvas.hex_to_screen(target)),"Grounded selection cannot fall back to other local ship")
	screen.free()
	adapter.free()
	flow.free()
	pilot.free()
	sim.free()
	print("ORBIT_UI_OWNER_JOIN passed=",checks," failed=0")
	quit(0)
