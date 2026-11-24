extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"
## Ein Formationsplatz, der in die Maske eines gelandeten Schiffs fiele, wird bei der
## Zuteilung auf ein freies Feld gelegt (wie ein von einer Einheit belegter Platz).
## Ohne Schiff oder weit davon entfernt bleiben die Plaetze unveraendert.
## Echte Wurzel und echte Bodenlaufzeit; die Maske kommt ueber einen Erzeuger
## "TacticalController" neben der Wurzel, wie im Spiel.
const ACTOR=preload("res://scripts/npc/test_unit.gd")
const FMC=preload("res://scripts/tactical/fireteam_movement_controller.gd")
const START:=Vector2i(3,2)

class Producer extends Node:
	var cells:Array=[]
	var registry_id:=0
	func get_ground_ship_blocked_cells(_craft:String="")->Dictionary:return {"ok":true,"registry_id":registry_id,"source_signature":str(cells),"blocked_cells":cells}

func _run()->void:
	var near:Array=[Vector2i(5,2),Vector2i(6,2),Vector2i(5,3)]
	var slots:Array=[Vector2i(5,2),Vector2i(6,2),Vector2i(7,2)]
	var far_slots:Array=[Vector2i(7,3),Vector2i(8,3),Vector2i(8,2)]
	var rig:=_make_rig(near)
	var fmc:=FMC.new()
	var records:Array=[{"unit_id":"fa_a"},{"unit_id":"fa_b"},{"unit_id":"fa_c"}]
	var result:Dictionary=_resolve(rig,fmc,records,slots)
	var cells:Array=[]
	for id in ["fa_a","fa_b","fa_c"]:cells.append(rig.terrain.world_to_grid(Vector2(result.get(id,rig.terrain.grid_to_world(slots[cells.size()])))))
	var in_hull:=0
	var walkable:=true
	for cell in cells:
		if near.has(cell):in_hull+=1
		walkable=walkable and rig.terrain.is_walkable(cell)
	var distinct:=true
	for i in range(cells.size()):
		for j in range(i+1,cells.size()):distinct=distinct and cells[i]!=cells[j]
	_check(in_hull==0,"no assigned slot lies in the ship mask (in hull: %d, cells %s)"%[in_hull,cells])
	_check(walkable and distinct,"all slots walkable and pairwise different (%s)"%[cells])
	_check(cells[2]==slots[2],"the slot outside the hull keeps its cell")
	rig.scene.free()
	rig=_make_rig([])
	_check(_resolve(rig,fmc,records,slots).is_empty(),"without a ship the slots stay exactly as assigned")
	rig.scene.free()
	rig=_make_rig(near)
	_check(_resolve(rig,fmc,records,far_slots).is_empty(),"slots away from the ship stay exactly as assigned")
	rig.scene.free()
	print("FORMATION_SHIP_MASK passed=%d failed=%d"%[passed,failed])
	quit(1 if failed else 0)

func _make_rig(hull:Array)->Dictionary:
	var rig:=_admission_rig(_cells())
	rig.sim.name="SimulationRoot";rig.units.name="UnitRegistry";rig.terrain.name="TerrainRegistry"
	rig.sim.unit_registry_path=rig.sim.get_path_to(rig.units);rig.sim.terrain_registry_path=rig.sim.get_path_to(rig.terrain)
	rig.sim.set_physics_process(false)
	var producer:=Producer.new();producer.name="TacticalController"
	producer.cells=hull;producer.registry_id=rig.terrain.get_instance_id()
	rig.scene.add_child(producer)
	var ids:PackedStringArray=PackedStringArray()
	for id in ["fa_a","fa_b","fa_c"]:
		var actor:=ACTOR.new();actor.unit_id=id;actor.team_id="team_alpha";actor.fireteam_id="ft1";actor.is_fireteam_lead=id=="fa_a"
		actor.weapon_1_id="none";actor.weapon_2_id="none";rig.scene.add_child(actor);actor.set_physics_process(false)
		rig.units.register_unit(id,actor);rig.sim.register_known_unit(id,actor)
		ids.append(id)
	rig.sim.admit_hex_ground_actor_group(ids,START)
	return rig

func _cells()->Array:
	var cells:Array=[]
	for x in range(10):
		for y in range(6):cells.append(Vector2i(x,y))
	return cells

func _resolve(rig:Dictionary,fmc,records:Array,slots:Array)->Dictionary:
	var targets:Dictionary={}
	for i in range(records.size()):targets[records[i].unit_id]=rig.terrain.grid_to_world(slots[i])
	return fmc._resolve_occupied_hex_formation_targets(rig.sim,records,targets,rig.terrain)
