extends "res://scripts/tests/hex_base_boarding_verifier.gd"

class StationActor extends "res://scripts/npc/test_unit.gd":
	func _ready() -> void: pass
class VisitFlow extends Flow:
	var mission: Node
	func _find_homebase_aircraft_definition(craft: String) -> Dictionary: return {"craft_id":craft} if craft == "ship" else {}
	func get_mission_for_craft(craft: String) -> Node: return mission if craft == "ship" else null
class Controller extends Node:
	var _deployed_unit_ids := {}

func _finish() -> void:
	var rig: Dictionary = _boarding_rig()
	var visit: Dictionary = _admission_rig([Vector2i.ZERO,Vector2i(1,0)])
	visit.sim.name="SimulationRoot"; visit.units.name="UnitRegistry"
	visit.sim.unit_registry_path=visit.sim.get_path_to(visit.units)
	var controller := Controller.new(); controller.name="TacticalController"; visit.scene.add_child(controller)
	visit.scene.set_meta("location_id","polisa")
	var id := "polisa_recruit_on_ship"
	visit.scene.set_meta("singleplayer_visit_identities",{"ship":{"unit_ids":[id]}})
	var actor := StationActor.new(); actor.unit_id=id; actor.team_id="blue"; visit.scene.add_child(actor)
	visit.units.register_unit(id,actor); visit.sim.register_known_unit(id,actor)
	var flow := VisitFlow.new(); rig.scene.add_child(flow); flow.mission=visit.scene; flow._aircraft_location_by_craft["ship"]="mission"
	rig.base._flow=flow; rig.base._navigation_graph=null
	flow._all_team_units.append({"unit_id":id,"display_name":"Recruit","recruit_location":"polisa"})
	rig.base.sync_roster()
	if not rig.base.has_method("bind_confirmed_polisa_player_boarding"):
		_check(false,"real player ship boarding binds station recruit")
	else:
		var refused: Dictionary=rig.base.bind_confirmed_polisa_player_boarding(id,"ship",visit.scene)
		_check(not refused.get("ok",false) and rig.base._states[id].status=="station","without actual embark person remains on station")
		actor.set_meta("dropship_embarked",true); actor.visible=false
		var accepted: Dictionary=rig.base.bind_confirmed_polisa_player_boarding(id,"ship",visit.scene)
		_check(accepted.get("ok",false) and rig.base._states[id].status=="aboard" and rig.base._states[id].craft_id=="ship" and not rig.base._unit_is_home(id),"actual embarked actor updates base transport binding")
		var replay: Dictionary=rig.base.bind_confirmed_polisa_player_boarding(id,"ship",visit.scene)
		_check(replay.get("ok",false) and replay.get("replayed",false),"player boarding binding is idempotent")
		flow._aircraft_location_by_craft["ship"]="homebase"
		_check(rig.base._unit_is_home(id) and rig.base._states[id].status=="aboard","actual home arrival leaves passenger aboard for explicit unboarding")
	visit.scene.free(); rig.scene.free()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0: print("POLISA_PLAYER_SHIP_RECRUIT_BOARD_PASS")
	quit(0 if failed==0 else 1)
