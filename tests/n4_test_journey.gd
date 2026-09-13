extends RefCounted
## Shared real-command journey for regressions whose subject is economy/combat.
const Catalog=preload("res://scripts/core/catalog.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
static var serial:=0
static func command(sim: Node,kind: String,data: Dictionary={}) -> Dictionary:
	serial+=1;var c:=data.duplicate(true);c.type=kind;c.request_id="journey-%d"%serial
	var result: Dictionary=sim.submit(c)
	if not result.ok:printerr("JOURNEY ",kind," ",result.reason)
	return result
static func board(sim: Node) -> bool:
	var ids: Array[String]=[]
	for unit: Dictionary in sim.snapshot().crew.values():
		if unit.assignment=="idle":ids.append(unit.id)
	if not ids.is_empty() and not command(sim,"board_crew",{"unit_ids":ids}).ok:return false
	for tick in 600:
		var ready:=true
		for unit: Dictionary in sim.snapshot().crew.values():
			if unit.assignment!="aboard":ready=false
		if ready:return true
		sim.advance(0.5)
	return false
static func trip(sim: Node,destination: String) -> bool:
	if not board(sim):return false
	if sim.snapshot().ship.mode=="landed" and not command(sim,"launch").ok:return false
	if sim.snapshot().region!="orbit":
		if not command(sim,"enter_orbit").ok:return false
		sim.advance(5.05)
	if not command(sim,"travel",{"destination":destination}).ok:return false
	sim.advance(5.05)
	if sim.snapshot().encounter.active:
		if not command(sim,"flee").ok:return false
		sim.advance(7.05)
	return fly_land(sim,Catalog.landmarks(destination).shuttle)
static func fly_land(sim: Node,point: Array,scan: bool=false) -> bool:
	if sim.snapshot().ship.mode=="landed":
		if not board(sim) or not command(sim,"launch").ok:return false
	if scan and not command(sim,"radar_scan").ok:return false
	if not command(sim,"ship_move",{"position":point}).ok:return false
	for tick in 200:
		sim.advance(0.5)
		if Vector2(sim.snapshot().ship.position[0],sim.snapshot().ship.position[1]).distance_to(Vector2(point[0],point[1]))<0.1:break
	if not command(sim,"land").ok:return false
	for id: String in sim.snapshot().crew:
		if not command(sim,"disembark",{"unit_id":id}).ok:return false
	return true
static func site(sim: Node,point: Array,scan: bool=false) -> bool:
	var at:=Vector2(point[0],point[1])+Vector2(0,22)
	var ship: Dictionary=sim.snapshot().ship.duplicate(true);ship.mode="landed";ship.yaw=0.0
	for step in 24:
		var candidate:=at if step==0 else Vector2(point[0],point[1])+Vector2.from_angle(step*TAU/24)*24
		ship.position=[candidate.x,candidate.y]
		if Nav.landing_clear(sim.snapshot().region,ship):return fly_land(sim,ship.position,scan)
	return false
