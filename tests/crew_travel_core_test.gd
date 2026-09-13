extends SceneTree
const Catalog=preload("res://scripts/core/catalog.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
const Validator=preload("res://scripts/core/save_validator.gd")
const Core=preload("res://scripts/core/simulation_root.gd")
var sim: Node
var checks:=0
var failures:=0
var serial:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL "+label)
func cmd(kind: String,data: Dictionary={},sender: int=1) -> Dictionary:
	serial+=1;var c:=data.duplicate(true);c.type=kind;c.request_id="n4-%d"%serial
	return sim.submit(c,sender)
func run() -> void:
	sim=Core.new(1);sim.auto_tick=false;root.add_child(sim)
	check(sim.snapshot().schema_version==5,"schema5")
	sim.set_guest(7)
	check(cmd("move",{"unit_id":"ida","position":[0,1]},7).ok,"guest commands all crew")
	check(not cmd("travel",{"destination":"rust"}).ok,"surface travel cannot skip orbit")
	check(not cmd("launch").ok,"empty ship cannot launch")
	check(cmd("board",{"unit_id":"ida","role":"pilot"}).ok,"explicit pilot boarding")
	check(cmd("board",{"unit_id":"jaro","role":"gunner"},7).ok,"explicit gunner boarding")
	check(valid(),"boarding state saves")
	check(not cmd("launch").ok,"reserved seats are not occupied")
	var searches: int=Nav.searches
	sim.advance(30)
	check(Nav.searches-searches<=2,"navigation route cached while walking")
	check(sim.snapshot().crew.ida.assignment=="aboard" and sim.snapshot().crew.jaro.assignment=="aboard","both arrive at access")
	check(valid(),"aboard landed saves")
	check(cmd("launch",{},7).ok,"guest launches occupied ship")
	check(not cmd("disembark",{"unit_id":"ida"}).ok,"no airborne disembark")
	check(cmd("enter_orbit",{},7).ok,"explicit orbit climb")
	check(valid(),"orbit climb saves")
	sim.advance(5.1)
	check(sim.snapshot().region=="orbit","separate orbit region")
	check(cmd("travel",{"destination":"base"}).ok,"orbit route accepted")
	check(valid(),"travel saves")
	sim.advance(5.1)
	check(sim.snapshot().region=="base" and sim.snapshot().ship.mode=="flying","arrival flying")
	check(sim.snapshot().crew.ida.assignment=="aboard","arrival no automatic exit")
	check(cmd("ship_move",{"position":Catalog.landmarks("base").shuttle}).ok,"fly to dock")
	sim.advance(40)
	check(cmd("land").ok,"dock landing full hull clearance")
	check(valid(),"landed board state saves")
	check(cmd("disembark",{"unit_id":"ida"}).ok,"explicit disembark")
	check(cmd("disembark",{"unit_id":"jaro"},7).ok,"guest disembarks other crew")
	check(valid(),"disembarked state saves")
	check(not cmd("move",{"unit_id":"ida","position":sim.snapshot().ship.position}).ok,"ship hull blocks walk target")
	check(cmd("board_crew",{"unit_ids":["jaro","ida"]}).ok,"automatic group seats")
	check(sim.snapshot().ship.roles.pilot=="ida","highest pilot independent of array order")
	check(cmd("cancel_board",{"unit_id":"ida"}).ok and cmd("cancel_board",{"unit_id":"jaro"}).ok,"cancel releases seats")
	sim._state.crew.ida.skills.pilot=0;sim._state.crew.jaro.skills.pilot=8
	check(cmd("board_crew",{"unit_ids":["ida","jaro"]}).ok,"group assignment after skill swap")
	check(sim.snapshot().ship.roles.pilot=="jaro","changed best pilot selected")
	cmd("cancel_board",{"unit_id":"ida"});cmd("cancel_board",{"unit_id":"jaro"})
	check(cmd("board",{"unit_id":"ida","role":"pilot"}).ok,"explicit role overrides lower skill")
	check(cmd("board_crew",{"unit_ids":["ida","jaro"]}).ok and sim.snapshot().ship.roles.pilot=="ida","auto group preserves existing explicit pilot")
	cmd("cancel_board",{"unit_id":"ida"});cmd("cancel_board",{"unit_id":"jaro"})
	var store: Array=Catalog.interaction_point("base","storage")
	check(cmd("move",{"unit_id":"ida","position":store}).ok,"walk to inventory access")
	sim.advance(30)
	# Focused finite inventory fixture: every operation below must conserve these items.
	for item: String in ["backpack","medgun","multitool","mining_attachment","salvage_attachment"]:sim._state.inventory[item]=1
	sim._state.inventory.med_charge=10
	check(cmd("equip_item",{"unit_id":"ida","slot":"backpack","item":"backpack","source":"inventory"},7).ok,"guest equips backpack")
	check(cmd("equip_item",{"unit_id":"ida","slot":"tool","item":"multitool","source":"inventory"}).ok,"equip multitool")
	check(cmd("equip_item",{"unit_id":"ida","slot":"attachment","item":"mining_attachment","source":"inventory"}).ok,"equip mining head")
	check(not cmd("equip_item",{"unit_id":"ida","slot":"tool","item":"medgun","source":"inventory"}).ok,"tool swap cannot discard attachment")
	check(cmd("unequip_item",{"unit_id":"ida","slot":"attachment","destination":"inventory"}).ok,"return attachment")
	check(cmd("equip_item",{"unit_id":"ida","slot":"tool","item":"medgun","source":"inventory"}).ok,"swap returns multitool")
	check(sim.snapshot().inventory.multitool==1,"swap item conserved")
	check(not cmd("backpack_transfer",{"unit_id":"ida","item":"med_charge","amount":9,"source":"inventory","destination":"backpack"}).ok,"capacity rejects whole transfer")
	check(sim.snapshot().inventory.med_charge==10,"rejection no consumption")
	check(cmd("backpack_transfer",{"unit_id":"ida","item":"med_charge","amount":8,"source":"inventory","destination":"backpack"}).ok,"fill backpack")
	check(not cmd("unequip_item",{"unit_id":"ida","slot":"backpack","destination":"inventory"}).ok,"cannot lose full backpack")
	var patient: Dictionary=sim._state.crew.jaro
	patient.position=sim._state.crew.ida.position.duplicate();patient.target=patient.position.duplicate();patient.health=20.0
	check(cmd("use_medgun",{"unit_id":"ida","target_id":"jaro"}).ok,"healing real health")
	check(patient.health==55 and sim.snapshot().crew.ida.backpack.items.med_charge==7,"one charge for 35 hp")
	patient.health=0.0;patient.assignment="downed";patient.respawn_remaining=15.0
	check(cmd("use_medgun",{"unit_id":"ida","target_id":"jaro"},7).ok,"guest revives crew")
	check(patient.health==35 and patient.assignment=="idle" and patient.respawn_remaining==0,"revive cancels respawn timer")
	check(valid(),"equipment and treatment state saves")
	check(sim.save_game("user://n4-core-check.json").ok,"atomic schema5 save")
	check(sim.load_game("user://n4-core-check.json").ok,"schema5 JSON roundtrip")
	var stock: int=int(sim.snapshot().inventory.med_charge)
	var parts: int=int(sim.snapshot().inventory.parts)
	check(cmd("assign_work",{"unit_id":"ida","recipe_id":"med_charge"},7).ok,"guest reserves charge recipe")
	check(sim.snapshot().inventory.parts==parts-1,"charge recipe debits actual parts")
	sim.advance(20)
	check(sim.snapshot().inventory.med_charge==stock+3,"charge recipe yields three finite charges")
	check(valid(),"completed new recipe valid")
	print("N4_CORE ",checks," checks, ",failures," failures")
	sim.free();quit(1 if failures else 0)

func valid() -> bool:
	var error: String=Validator.validate({"schema_version":5,"state":sim.snapshot(),"receipts":{}})
	if not error.is_empty():printerr(error)
	return error.is_empty()
