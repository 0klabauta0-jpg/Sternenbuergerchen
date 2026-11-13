extends SceneTree
## C10: real controller/index/registry/unit damage and leadership transitions.
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const CONTROLLER = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const UNIT = preload("res://scripts/npc/test_unit.gd")
const REGISTRY = preload("res://scripts/registries/unit_registry.gd")
const INDEX = preload("res://scripts/tactical/mission_runtime_index.gd")
const HUD_MODEL = preload("res://scripts/tactical/mission_hud_read_model.gd")
const SIM = preload("res://scripts/core/simulation_root.gd")
var passed := 0
var failed := 0

class QuietController extends CONTROLLER:
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

class QuietDriver extends DRIVER:
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)

func _unit(scope: Node, registry: Node, sim: Node, id: String, skill: float, lead: bool = false) -> Node2D:
	var unit = UNIT.new()
	unit.name = id
	unit.unit_id = id
	unit.team_id = "team_alpha"
	unit.fireteam_id = "alpha"
	unit.skill_leadership = skill
	unit.is_fireteam_lead = lead
	unit.weapon_1_id = "none"
	unit.weapon_2_id = "none"
	scope.add_child(unit)
	unit.set_process(false)
	unit.set_physics_process(false)
	registry.register_unit(id, unit)
	sim.register_known_unit(id, unit)
	return unit

func _run() -> void:
	var scope := Node2D.new()
	root.add_child(scope)
	var registry = REGISTRY.new()
	registry.name = "UnitRegistry"
	scope.add_child(registry)
	var index = INDEX.new()
	index.name = "MissionRuntimeIndex"
	scope.add_child(index)
	var hud = HUD_MODEL.new()
	hud.name = "MissionHudReadModel"
	scope.add_child(hud)
	var sim = SIM.new()
	sim.name = "SimulationRoot"
	sim.unit_registry_path = NodePath("../UnitRegistry")
	scope.add_child(sim)
	sim.set_process(false)
	sim.set_physics_process(false)
	var controller := QuietController.new()
	controller.name = "TacticalController"
	scope.add_child(controller)
	# Stable index order makes the low-skill member the fallback display anchor.
	var low = _unit(scope, registry, sim, "a_member", 0.3)
	var lead = _unit(scope, registry, sim, "b_leader", 0.2, true)
	var high = _unit(scope, registry, sim, "c_member", 0.9)
	_check(controller._get_fireteam_units("alpha").size() == 3 and registry.get_all_units().size() == 3, "fixture uses actual indexed and registered runtime units")
	_check(controller._resolve_fireteam_leader_for_behavior(" ALPHA ") == lead, "configured fit leader wins over higher skill")
	_check(controller._get_selection_anchor_for_fireteam("alpha") == lead and controller._is_unit_current_fireteam_lead(lead), "live leader anchors selection and lead readout")
	_check(lead.apply_damage(10000) and lead.get_vital_state() == "down", "actual damage downs configured leader")
	_check(controller._resolve_fireteam_leader_for_behavior("alpha") == high, "highest fit leadership succeeds down leader")
	_check(controller._get_selection_anchor_for_fireteam("alpha") == high and not controller._is_unit_current_fireteam_lead(lead), "selection follows live successor without marking casualty as current lead")
	high.apply_damage(10000)
	_check(controller._resolve_fireteam_leader_for_behavior("alpha") == low, "last fit member remains valid fallback")
	low.apply_damage(10000)
	var before: Array = [low.get_vital_status().to_dict(), lead.get_vital_status().to_dict(), high.get_vital_status().to_dict()]
	for iteration in range(8):
		_check(controller._resolve_fireteam_leader_for_behavior("alpha") == null, "all-down behavior has no leader %d" % iteration)
		_check(controller._get_selection_anchor_for_fireteam("alpha") == low, "all-down selection retains stable display anchor %d" % iteration)
		_check(not controller._is_unit_current_fireteam_lead(lead) and not controller._is_unit_current_fireteam_lead(low), "all-down readouts terminate without inventing active leader %d" % iteration)
	_check([low.get_vital_status().to_dict(), lead.get_vital_status().to_dict(), high.get_vital_status().to_dict()] == before and sim.command_queue.is_empty() and sim.effects_queue.is_empty(), "leader projections do not heal, elect, or enqueue commands")
	_check(high.respawn(Vector2.ZERO) and controller._resolve_fireteam_leader_for_behavior("alpha") == high, "real recovery restores fit fallback immediately")
	_check(controller._resolve_fireteam_leader_for_behavior("") == null and controller._get_selection_anchor_for_fireteam("missing") == null, "empty and absent team reads terminate")

	var driver := QuietDriver.new()
	driver.name = "CombatLoopDriver"
	driver.friendly_team_id = "team_alpha"
	driver.simulation_root_path = NodePath("../SimulationRoot")
	driver.friendly_unit_paths.assign([NodePath("../a_member"), NodePath("../b_leader"), NodePath("../c_member")])
	scope.add_child(driver)
	_check(controller._get_mission_combat_loop_driver() == driver, "leader lookup resolves actual mission-scene CombatLoopDriver name")
	driver._init_fireteam_leadership()
	_check(driver.get_current_fireteam_lead_unit("alpha") == lead and controller._resolve_fireteam_leader_for_behavior("alpha") == high, "stale down Driver lead is ignored before next leadership tick")
	var driver_before: Dictionary = driver._fireteam_acting_leads.duplicate(true)
	controller._get_selection_anchor_for_fireteam("alpha")
	_check(driver._fireteam_acting_leads == driver_before, "controller does not rewrite authoritative Driver succession")
	driver._update_fireteam_leadership()
	_check(driver.get_current_fireteam_lead_unit("alpha") == high and controller._resolve_fireteam_leader_for_behavior("alpha") == high, "actual Driver succession remains preferred")
	lead.respawn(Vector2.ZERO)
	_check(controller._resolve_fireteam_leader_for_behavior("alpha") == high, "fit acting Driver lead retains priority until owner updates")
	driver._update_fireteam_leadership()
	_check(controller._resolve_fireteam_leader_for_behavior("alpha") == lead, "actual Driver returns leadership to recovered original")
	lead.apply_damage(10000)
	high.apply_damage(10000)
	_check(controller._resolve_fireteam_leader_for_behavior("alpha") == null and controller._get_selection_anchor_for_fireteam("alpha") == low, "all-down also terminates while Driver still holds stale leader")
	driver._update_fireteam_leadership()
	_check(driver.get_current_fireteam_lead_unit("alpha") == null and controller._resolve_fireteam_leader_for_behavior("alpha") == null, "actual Driver clears unavailable succession")
	for unit in [low, lead, high]:
		registry.unregister_unit(unit.get_unit_id())
		sim.unregister_known_unit(unit.get_unit_id())
		unit.free()
	_check(controller._get_fireteam_units("alpha").is_empty() and controller._get_selection_anchor_for_fireteam("alpha") == null, "empty registered fireteam has no display anchor")
	scope.free()
	await process_frame
	print("ASTRA_LEADER_FIXES passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
