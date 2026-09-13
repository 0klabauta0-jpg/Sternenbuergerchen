extends SceneTree
const Catalog=preload("res://scripts/core/catalog.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func run() -> void:
	var longest_ms:=0
	for region: String in ["base","rust","station","bunker_surface","bunker_depths","distribution","tradepost"]:
		var ship: Dictionary={"model":"cutlass","mode":"landed","position":Catalog.landmarks(region).get("shuttle",[-65,70])}
		var access: Array=Catalog.ship_access(ship) if region!="bunker_depths" else Catalog.landmarks(region).elevator
		var from:=Vector2(access[0],access[1])
		for id: String in Catalog.landmarks(region):
			if id in ["shuttle","aa_turret","kitchen","expansion_a","expansion_b"]:continue
			var at: Array=Catalog.interaction_point(region,id)
			var to:=Vector2(at[0],at[1])
			check(Nav.walkable(region,to,ship),region+" approach "+id)
			var started:=Time.get_ticks_msec()
			var path: Array=Nav.path(region,from,to,ship)
			longest_ms=maxi(longest_ms,Time.get_ticks_msec()-started)
			check(not path.is_empty(),region+" route "+id)
			var anchor:=from
			for point: Vector2 in path:
				check(Nav.clear(region,anchor,point,ship),region+" segment avoids static furniture/rocks and ship "+id);anchor=point
		check(Catalog.obstacles(region).size()<600,region+" bounded obstacle catalog")
	var ship: Dictionary={"model":"cutlass","mode":"landed","position":[25,22]}
	check(not Nav.walkable("base",Vector2(25,22),ship),"landed hull excludes crew")
	ship.mode="flying";check(Nav.walkable("base",Vector2(25,22),ship),"airborne hull no ground obstacle")
	check(not Nav.clear("bunker_surface",Vector2(28,0),Vector2(28,-12)),"AA footprint blocks ordinary geometry ray")
	check(Nav.clear("bunker_surface",Vector2(28,0),Vector2(28,-12),{},"object_aa_turret"),"AA own footprint ignored only for targeted ray")
	check(not Nav.clear("bunker_surface",Vector2(0,20),Vector2(0,-40),{},"object_aa_turret"),"target exception cannot bypass bunker wall")
	print("N4_NAV ",checks," checks, ",failures," failures; max route ms=",longest_ms)
	quit(1 if failures else 0)
