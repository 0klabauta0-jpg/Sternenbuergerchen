extends "res://tests/crew_travel_core_test.gd"
const Flight=preload("res://scripts/core/flight_navigation.gd")
const Journey=preload("res://tests/n4_test_journey.gd")
func run() -> void:
	sim=Core.new(1);sim.auto_tick=false;root.add_child(sim);sim.set_guest(7)
	check(Journey.board(sim),"actual crew boards")
	check(cmd("launch").ok,"launch")
	check(cmd("enter_orbit").ok,"ascent");sim.advance(5.1)
	check(cmd("ship_order",{"mode":"patrol","position":[100,0]},7).ok,"guest may order shared ship patrol")
	sim.advance(3)
	check(not sim.snapshot().ship.order.is_empty(),"patrol remains active at turn")
	check(valid(),"patrol state valid")
	check(cmd("toggle_pause").ok,"pause")
	var held: Dictionary=sim.snapshot();sim.advance(20)
	check(sim.snapshot().ship==held.ship,"pause freezes patrol position and index")
	check(sim.save_game("res://output/n6-flight-save.json").ok,"save running patrol")
	cmd("ship_order",{"mode":"stop"})
	check(sim.load_game("res://output/n6-flight-save.json").ok,"load active patrol")
	var restored: Dictionary=sim.snapshot().ship
	check(restored.order.kind==held.ship.order.kind and restored.order.region==held.ship.order.region and int(restored.order.index)==int(held.ship.order.index) and _v(restored.order.points[0]).is_equal_approx(_v(held.ship.order.points[0])) and _v(restored.order.points[1]).is_equal_approx(_v(held.ship.order.points[1])) and _v(restored.position).is_equal_approx(_v(held.ship.position)) and is_equal_approx(restored.yaw,held.ship.yaw),"restore full flight order")
	cmd("toggle_pause");sim.advance(10)
	check(not sim.snapshot().ship.order.is_empty(),"restored patrol continues")
	check(cmd("ship_move",{"position":[0,0]}).ok and sim.snapshot().ship.order.is_empty(),"new manual target cancels patrol")
	check(cmd("travel",{"destination":"base"}).ok,"route home");sim.advance(5.1)
	var destination:=Vector2(25,22);var previous:=Vector2(sim.snapshot().ship.position[0],sim.snapshot().ship.position[1])
	check(not Flight.clear("base","cutlass",previous,destination),"direct home flight intersects actual hills")
	check(cmd("ship_move",{"position":[25,22]}).ok,"pilot accepts detour")
	var safe:=true;var distance:=0.0
	for tick in 1400:
		sim.advance(0.05)
		var at:=Vector2(sim.snapshot().ship.position[0],sim.snapshot().ship.position[1])
		safe=safe and Flight.clear("base","cutlass",previous,at);distance+=previous.distance_to(at);previous=at
		if at.distance_to(destination)<0.1:break
	check(safe,"every actual flight segment avoids expanded hill footprints")
	check(previous.distance_to(destination)<0.1,"detour reaches home dock")
	check(distance>700,"route travelled around hills")
	var blocked: Rect2=Flight.data("base","cutlass").rects[0]
	var before: Dictionary=sim.snapshot().ship
	check(not cmd("ship_move",{"position":[blocked.get_center().x,blocked.get_center().y]}).ok,"blocked target rejected")
	check(sim.snapshot().ship==before,"rejected target leaves active state intact")
	check(cmd("land").ok,"land at dock")
	var stock: int=sim.snapshot().inventory.scrap
	var transfer: Dictionary={"type":"transfer","item":"scrap","amount":3,"direction":"load","request_id":"n6-idempotent"}
	check(sim.submit(transfer).ok,"actual cargo stack loaded")
	check(sim.submit(transfer).ok and sim.snapshot().cargo.scrap==3,"repeated receipt never duplicates cargo")
	check(cmd("transfer",{"item":"scrap","amount":3,"direction":"unload"}).ok and sim.snapshot().inventory.scrap==stock,"unload conserves stack")
	check(not cmd("transfer",{"item":"scrap","amount":13,"direction":"load"}).ok,"invalid amount rejected")
	check(not cmd("claim_contract").ok,"no early mission payment")
	check(cmd("launch").ok and cmd("enter_orbit").ok,"depart again");sim.advance(5.1)
	check(cmd("travel",{"destination":"rust"}).ok,"travel rust");sim.advance(5.1)
	if sim.snapshot().encounter.active:cmd("flee");sim.advance(7.1)
	check(cmd("ship_order",{"mode":"search","position":[145,-125]}).ok,"search raster accepted")
	check(sim.snapshot().discovery.radar_scanned,"search orders radar scan")
	check(valid(),"search valid")
	check(sim.save_game("res://output/n6-search-save.json").ok and sim.load_game("res://output/n6-search-save.json").ok,"search roundtrip")
	for tick in 2400:sim.advance(0.05)
	check(sim.snapshot().ship.order.is_empty(),"finite search ends and holds")
	check(sim.snapshot().discovery.satellite_found,"raster identifies satellite by actual proximity")
	check(valid(),"completed search saves")
	var payload: Dictionary={"schema_version":5,"state":sim.snapshot(),"receipts":{}}
	payload.state.ship.erase("order")
	check(Validator.validate(payload).is_empty(),"previous N5 save without order remains valid")
	payload.state.ship.order={"kind":"patrol","region":"base","points":[[0,0],[1,1]],"index":0}
	check(not Validator.validate(payload).is_empty(),"invalid order-region binding rejected")
	FileAccess.open("res://output/n6-flight-result.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
	print("N6_FLIGHT_CARGO ",checks," checks, ",failures," failures");sim.free();quit(1 if failures else 0)

func _v(at: Array) -> Vector2:return Vector2(at[0],at[1])
