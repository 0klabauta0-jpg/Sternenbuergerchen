extends SceneTree
const SUPPLY=preload("res://scripts/core/singleplayer_supply_state.gd")
const OWNER=preload("res://scripts/core/automatic_cargo_transfer.gd")
var supply
var allowed:=true
var failed:=0
func check(v:bool,label:String):
	print(("PASS: " if v else "FAIL: ")+label)
	if not v:failed+=1
func validate(_source:String,_target:String)->Dictionary:return {"ok":allowed,"reason":"cargo_ship_unavailable"}
func inventory()->Dictionary:return supply.get_supply_snapshot().inventory
func move(source:String,target:String,item:String,amount:int,id:String)->Dictionary:
	return supply.apply_command({"contract_category":"singleplayer_supply","operation":"inventory_transfer","payload":{"source_container_id":source,"destination_container_id":target,"item_id":item,"amount":amount},"request_id":"step:"+id},{"accessible_containers":[source,target]})
func _init():call_deferred("run")
func run():
	supply=SUPPLY.new();check(supply.configure([{"craft_id":"a"},{"craft_id":"b"}]).get("ok",false),"real supply configured")
	supply.configure_inventory([], ["a","b"],true)
	var command={"contract_category":"singleplayer_supply","operation":"buy","payload":{"offer_id":"polisa_pistol","quantity":2,"craft_id":"a"},"request_id":"purchase"}
	var purchase:Dictionary=supply.apply_command(command,{"location_id":"polisa","craft_id":"a","craft_busy":false,"cargo_lift_delivery":true})
	check(purchase.get("ok",false) and purchase.get("container_id","")=="station:polisa:lift","purchase reaches real station lift container")
	var owner=OWNER.new();owner.configure(Callable(self,"validate"),Callable(self,"inventory"),Callable(self,"move"))
	check(owner.start("order","station:polisa:lift","craft:a").get("ok",false),"order accepted")
	check(owner.blocks_craft("a") and not owner.get_snapshot().checkpoint_safe,"active ship and checkpoint guarded")
	owner.advance(.5)
	check(owner.get_snapshot().completed==0 and int(inventory()["station:polisa:lift"].items.get("pistol",0))==2,"no instant transfer")
	owner.advance(.25)
	check(owner.get_snapshot().completed==1 and int(inventory()["craft:a"].items.get("pistol",0))==1,"one real inventory mutation per elapsed interval")
	check(owner.start("order","station:polisa:lift","craft:a").get("replayed",false),"same order does not duplicate")
	owner.advance(.75)
	check(owner.get_snapshot().phase=="complete" and int(inventory()["craft:a"].items.get("pistol",0))==2,"transfer completes and conserves inventory")
	check(owner.start("back","craft:a","station:polisa:lift").get("ok",false),"reverse direction")
	allowed=false;owner.advance(1.0)
	check(owner.get_snapshot().phase=="blocked" and owner.get_snapshot().reason=="cargo_ship_unavailable","location change blocks without moving items")
	check(owner.cancel().get("ok",false) and owner.get_snapshot().checkpoint_safe,"cancel safely releases guard")
	allowed=true
	check(owner.start("ships","craft:a","craft:b").get("ok",false),"ship-to-ship transfer")
	owner.advance(5.0)
	check(owner.get_snapshot().phase=="complete" and int(inventory()["craft:b"].items.get("pistol",0))==2,"ship-to-ship transfers real items")
	var fill={"contract_category":"singleplayer_supply","operation":"campaign_cargo","payload":{"container_id":"craft:b","item_id":"a_benit","amount":46},"request_id":"fill"}
	check(supply.apply_command(fill,{"campaign_authorized":true}).get("ok",false),"destination can be filled")
	command.request_id="purchase2";command.payload.quantity=1
	check(supply.apply_command(command,{"location_id":"polisa","craft_id":"a","craft_busy":false,"cargo_lift_delivery":true}).get("ok",false),"second purchase enters lift")
	check(owner.start("full","station:polisa:lift","craft:b").get("ok",false),"full destination starts pending order")
	owner.advance(1.0)
	check(owner.get_snapshot().phase=="blocked" and owner.get_snapshot().reason=="container_full" and int(inventory()["station:polisa:lift"].items.get("pistol",0))==1,"full destination leaves source intact")
	owner.cancel()
	check(owner.start("missing","station:polisa:lift","craft:a").get("ok",false),"new transfer can start after cancellation")
	check(move("station:polisa:lift","craft:a","pistol",1,"external").get("ok",false),"other action removes source item")
	owner.advance(1.0)
	check(owner.get_snapshot().phase=="blocked" and owner.get_snapshot().reason=="insufficient_items","missing source cannot create duplicate cargo")
	owner.cancel()
	var stamp={"contract_category":"singleplayer_supply","operation":"cargo_transfer_start","payload":{"source":"station:polisa:lift","target":"craft:a"},"request_id":"cargo-order:persistent"}
	check(supply.apply_command(stamp,{"cargo_transfer_authorized":true}).get("ok",false),"transfer order records persistent replay receipt")
	var saved:Dictionary=supply.export_state()
	var restored=SUPPLY.new();restored.configure([{"craft_id":"a"},{"craft_id":"b"}])
	check(restored.restore_state(saved).get("ok",false) and int(restored.get_supply_snapshot().inventory["craft:b"].items.get("pistol",0))==2,"lift and ship inventories survive supply restore")
	check(restored.apply_command(stamp,{"cargo_transfer_authorized":true}).get("replayed",false),"completed order receipt remains idempotent after restore")
	var legacy:Dictionary=saved.duplicate(true)
	legacy.inventory.erase("station:polisa:lift")
	var old=SUPPLY.new();old.configure([{"craft_id":"a"},{"craft_id":"b"}])
	check(old.restore_state(legacy).get("ok",false),"old save without lift remains valid")
	old.configure_inventory([], ["a","b"],true)
	check(old.get_supply_snapshot().inventory.has("station:polisa:lift") and int(old.get_supply_snapshot().inventory["craft:b"].items.get("pistol",0))==2,"old save gains empty lift without changing ship cargo")
	if failed==0:print("AUTOMATIC_CARGO_TRANSFER_PASS")
	quit(0 if failed==0 else 1)
