extends SceneTree
const TRAVEL=preload("res://scripts/core/singleplayer_space_travel_state.gd")
const FLEET=preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
var count:=0
var failed:=0
func check(ok:bool,label:String)->void:
	count+=1
	if not ok:failed+=1
	print("PASS " if ok else "FAIL ",label)
func birth(owner,id:String,request:String)->Dictionary:
	return owner.apply_command({"contract_category":"singleplayer_space_travel","operation":"initialize_surface","payload":{"craft_id":id,"location_id":"polisa"},"request_id":request},{"runtime_authorized":true})
func _initialize()->void:
	var travel=TRAVEL.new();travel.configure()
	var flight=travel.get_flight_state()
	var born:=birth(travel,"polisa_ship","birth")
	check(born.get("ok",false) and travel.get_snapshot().craft_id=="polisa_ship" and flight.get_snapshot().craft_id=="polisa_ship" and travel.get_flight_state()==flight,"surface birth binds exact identity on the original Flight")
	var before:=JSON.stringify([travel.get_snapshot(),flight.get_snapshot(),travel.get("_requests")],"",true)
	check(birth(travel,"polisa_ship","birth").get("replayed",false) and JSON.stringify([travel.get_snapshot(),flight.get_snapshot(),travel.get("_requests")],"",true)==before,"identical surface birth retry changes no owner")
	var mismatched=TRAVEL.new();mismatched.configure("other_ship")
	before=JSON.stringify([mismatched.get_snapshot(),mismatched.get_flight_state().get_snapshot(),mismatched.get("_requests")],"",true)
	check(not birth(mismatched,"polisa_ship","wrong").get("ok",false) and JSON.stringify([mismatched.get_snapshot(),mismatched.get_flight_state().get_snapshot(),mismatched.get("_requests")],"",true)==before,"mismatched existing Flight fails before any Travel or Flight mutation")
	var fleet=FLEET.new();fleet.configure()
	var prepared:Dictionary=fleet.prepare_surface_registration("polisa_fleet_ship","polisa","fleetbirth")
	var admitted:Dictionary=fleet.commit_surface_registration(prepared)
	check(admitted.get("ok",false) and fleet.get_snapshot("polisa_fleet_ship").phase=="surface" and fleet.get_flight_state("polisa_fleet_ship").get_snapshot().craft_id=="polisa_fleet_ship","actual fleet local registration publishes the same identified Flight")
	print("POLISA_BIRTH_IDENTITY checks=",count," failed=",failed)
	quit(1 if failed else 0)
