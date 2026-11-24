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
	_robust_cases(fmc,records)
	print("FORMATION_SHIP_MASK passed=%d failed=%d"%[passed,failed])
	quit(1 if failed else 0)

## Nachbesserung: Ausweichanker ist begehbar, jeder Nachbar wird versucht, danach ein zweiter Ring.
class TerrainProxy extends RefCounted:
	var inner
	var fake_first:=Vector2i(99,99)
	func world_to_grid(world:Vector2)->Vector2i:return inner.world_to_grid(world)
	func grid_to_world(grid:Vector2i)->Vector2:return inner.grid_to_world(grid)
	func is_walkable(grid:Vector2i)->bool:return inner.is_walkable(grid)
	## Meldet einen unbegehbaren Nachbarn als ersten (wie ein Feld, das die Wurzel als Anker abweist).
	func get_legal_hex_neighbors(grid:Vector2i)->Array[Vector2i]:
		var out:Array[Vector2i]=[fake_first]
		out.append_array(inner.get_legal_hex_neighbors(grid))
		return out

func _slot_cells(rig:Dictionary,result:Dictionary,slots:Array)->Array:
	var cells:Array=[]
	var ids:Array=["fa_a","fa_b","fa_c"]
	for i in range(ids.size()):cells.append(rig.terrain.world_to_grid(Vector2(result.get(ids[i],rig.terrain.grid_to_world(slots[i])))))
	return cells

func _outside_walkable_distinct(rig:Dictionary,cells:Array,hull:Array)->bool:
	var good:=true
	for i in range(cells.size()):
		good=good and not hull.has(cells[i]) and rig.terrain.is_walkable(cells[i])
		for j in range(i+1,cells.size()):good=good and cells[i]!=cells[j]
	return good

func _rings(center:Vector2i,count:int)->Array:
	var rig:=_make_rig([])
	var cells:Array=[center]
	var frontier:Array=[center]
	for step in range(count):
		var next_frontier:Array=[]
		for cell in frontier:
			for next in rig.terrain.get_legal_hex_neighbors(cell):
				if not cells.has(next):cells.append(next);next_frontier.append(next)
		frontier=next_frontier
	rig.scene.free()
	return cells

func _robust_cases(fmc,records:Array)->void:
	# 1: erster Nachbar ausserhalb der Maske ist unbegehbar -> naechster Nachbar wird versucht.
	var near:Array=[Vector2i(5,2),Vector2i(6,2),Vector2i(5,3)]
	var slots:Array=[Vector2i(5,2),Vector2i(6,2),Vector2i(7,2)]
	var rig:=_make_rig(near)
	var proxy:=TerrainProxy.new();proxy.inner=rig.terrain
	var targets:Dictionary={}
	for i in range(records.size()):targets[records[i].unit_id]=rig.terrain.grid_to_world(slots[i])
	var result:Dictionary=fmc._resolve_occupied_hex_formation_targets(rig.sim,records,targets,proxy)
	var cells:Array=_slot_cells(rig,result,slots)
	_check(not result.is_empty() and _outside_walkable_distinct(rig,cells,near),"unwalkable first neighbor: slots end on free walkable cells outside the mask (%s)"%[cells])
	rig.scene.free()
	# 2a: Platz mitten unter dem Rumpf (alle sechs Nachbarn in der Maske) -> zweiter Ring.
	var mid_slots:Array=[Vector2i(5,2),Vector2i(8,3),Vector2i(9,3)]
	var ring_one:Array=_rings(Vector2i(5,2),1)
	rig=_make_rig(ring_one)
	result=_resolve(rig,fmc,records,mid_slots)
	cells=_slot_cells(rig,result,mid_slots)
	_check(not result.is_empty() and _outside_walkable_distinct(rig,cells,ring_one) and cells[1]==mid_slots[1] and cells[2]==mid_slots[2],"slot under the middle of the hull moves out via the second ring (%s)"%[cells])
	rig.scene.free()
	# 2b: auch im zweiten Ring nichts frei -> Platz unveraendert, kein Fehler.
	var ring_two:Array=_rings(Vector2i(5,2),2)
	rig=_make_rig(ring_two)
	_check(_resolve(rig,fmc,records,mid_slots).is_empty(),"no free cell in ring one or two: slots stay exactly as assigned")
	rig.scene.free()
	# 3: Ablauf im Kleinen ueber den echten Einstieg (start_execution -> _issue_stage), Ziel mitten im Rumpf.
	var target_grid:=Vector2i(6,3)
	var hull:Array=_rings(target_grid,1)
	var control:=_make_rig([])
	var control_fmc:=FMC.new()
	control_fmc.start_execution("ft1","move",0,control.terrain.grid_to_world(target_grid),null,[control.units.get_unit("fa_a"),control.units.get_unit("fa_b")],control.units.get_unit("fa_a"),control.sim,control.terrain)
	control.sim._physics_process(0.1)
	var control_in_hull:=0
	for id in ["fa_a","fa_b"]:
		if hull.has(Vector2i(control.sim.get_hex_movement_readout(id).get("goal_grid",Vector2i(-1,-1)))):control_in_hull+=1
	control.scene.free()
	rig=_make_rig(hull)
	var staged:=FMC.new()
	var started:Dictionary=staged.start_execution("ft1","move",0,rig.terrain.grid_to_world(target_grid),null,[rig.units.get_unit("fa_a"),rig.units.get_unit("fa_b")],rig.units.get_unit("fa_a"),rig.sim,rig.terrain)
	rig.sim._physics_process(0.1)
	var goals:Array=[]
	for id in ["fa_a","fa_b"]:goals.append(Vector2i(rig.sim.get_hex_movement_readout(id).get("goal_grid",Vector2i(-1,-1))))
	_check(control_in_hull>=1,"stage case is meaningful: without the ship at least one goal falls into the later hull (%d)"%[control_in_hull])
	_check(started.get("started",false) and _outside_walkable_distinct(rig,goals,hull),"real stage issue: both members get different walkable goals outside the mask (%s)"%[goals])
	rig.scene.free()

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
