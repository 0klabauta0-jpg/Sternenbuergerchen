extends SceneTree
const Core=preload("res://scripts/core/simulation_root.gd")
const V3=preload("res://scripts/core/legacy_validator_v3.gd")
const V2=preload("res://scripts/core/legacy_validator_v2.gd")
const V1=preload("res://scripts/core/legacy_validator_v1.gd")
const Stage=preload("res://scripts/core/stage_state.gd")
const Ground=preload("res://scripts/core/ground_state.gd")
const Old=preload("res://scripts/core/legacy_catalog_v3.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func base_v1() -> Dictionary:
	return {"schema_version":1,"state":{"schema_version":1,"revision":5,"time":2.0,"paused":false,"region":"base","credits":180,"inventory":{"scrap":8,"parts":3,"toolkit":0,"cutter":0,"blackbox":0},"cargo":{"scrap":0,"parts":0,"toolkit":0,"cutter":0,"blackbox":0},"blueprints":["toolkit","repair"],"ship":{"condition":72.0,"capacity":12},"crew":{"ida":{"id":"ida","name":"Ida","skill":3,"owner":1,"position":[-1.0,1.0],"target":[-1.0,1.0],"assignment":"idle"},"jaro":{"id":"jaro","name":"Jaro","skill":1,"owner":7,"position":[1.0,2.0],"target":[1.0,2.0],"assignment":"idle"}},"contract":{"status":"available","reward":260},"work":{"active":false,"unit_id":"","recipe_id":"","remaining":0.0,"total":0.0,"phase":"idle","reserved":{}},"salvage":{"active":false,"unit_id":"","remaining":0.0,"total":0.0,"phase":"idle"},"travel":{"active":false,"from":"","to":"","remaining":0.0,"total":0.0,"phase":"idle"},"wreck_remaining":8,"log":["Historischer Spielstand"]},"receipts":{"1:prior":{"ok":false,"reason":"Alte Ablehnung","request_id":"prior"}}}
func load_fixture(payload: Dictionary,label: String) -> Node:
	var file:=FileAccess.open("user://n4-migration-input.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(payload));file.close()
	var sim:=Core.new(1);sim.auto_tick=false;root.add_child(sim)
	var result: Dictionary=sim.load_game("user://n4-migration-input.json")
	check(result.ok,label+": "+result.reason)
	check(sim.snapshot().schema_version==5,label+" schema5")
	check(sim.snapshot().credits==payload.state.credits,label+" funds preserved")
	check(sim.submit({"type":"move","unit_id":"ida","position":[0,0],"request_id":"prior"}).reason=="Alte Ablehnung",label+" receipts preserved")
	check(sim.save_game("user://n4-migration-result.json").ok,label+" valid saved result")
	return sim
func run() -> void:
	var v1:=base_v1();check(V1.validate(v1).is_empty(),"independent v1 fixture valid")
	var sim: Node=load_fixture(v1,"v1");sim.free()
	var v2: Dictionary=Stage.migrate(v1);check(V2.validate(v2).is_empty(),"v2 fixture valid")
	sim=load_fixture(v2,"v2");sim.free()
	var v3:=Ground.migrate(v2);check(V3.validate(v3).is_empty(),"v3 fixture valid")
	# An actual legacy work reservation survives relocation to the new room.
	v3.state.crew.ida.assignment="work";v3.state.crew.ida.target=Old.interaction_point("base","workbench")
	v3.state.inventory.scrap-=2;v3.state.inventory.parts-=1
	v3.state.work={"active":true,"unit_id":"ida","recipe_id":"toolkit","remaining":6.0,"total":6.0,"phase":"walking","reserved":{"scrap":2,"parts":1}}
	check(V3.validate(v3).is_empty(),"legacy active work valid")
	sim=load_fixture(v3,"v3 active work")
	check(sim.snapshot().work.reserved==v3.state.work.reserved,"reservation retained")
	sim.advance(30);check(sim.snapshot().inventory.toolkit==1,"old job completes once")
	sim.advance(30);check(sim.snapshot().inventory.toolkit==1,"no duplicate old output");sim.free()
	v3=Ground.migrate(v2);v3.state.region="rust";v3.state.ship.mode="flying";v3.state.ship.position=[0.0,0.0];v3.state.ship.target=[10.0,0.0]
	for unit: Dictionary in v3.state.crew.values():unit.assignment="aboard";unit.position=[0.0,0.0];unit.target=[0.0,0.0]
	check(V3.validate(v3).is_empty(),"legacy flying fixture valid")
	sim=load_fixture(v3,"v3 flight");check(sim.snapshot().ship.seats.pilot=="ida" and sim.snapshot().ship.seats.gunner=="jaro","legacy roles preserved as actual seats");sim.advance(1);check(sim.snapshot().ship.position[0]>0,"legacy flight remains movable");sim.free()
	v3=Ground.migrate(v2);v3.state.crew.ida.position=[10.0,3.0];v3.state.crew.ida.target=[10.0,3.0]
	check(V3.validate(v3).is_empty(),"old free point now furniture fixture valid")
	sim=load_fixture(v3,"v3 new obstacle");check(sim.snapshot().crew.ida.position!=[10.0,3.0],"blocked old position relocated");check(sim.snapshot().inventory==v3.state.inventory.merged({"backpack":0,"multitool":0,"mining_attachment":0,"salvage_attachment":0,"medgun":0,"med_charge":0,"repair_attachment":0}),"no old inventory lost");sim.free()
	# The old paid v1 career retains unlocks, discovery and rejection receipts.
	var paid:=base_v1();paid.state.credits=440;paid.state.contract.status="claimed";paid.state.blueprints.append("cutter")
	check(V1.validate(paid).is_empty(),"independent paid v1 valid")
	sim=load_fixture(paid,"paid v1");check(sim.snapshot().base.workbench_tier==2 and sim.snapshot().blueprints.has("cutter") and sim.snapshot().discovery.satellite_found,"paid v1 unlocks retained");sim.free()
	v2=Stage.migrate(base_v1());v2.state.inventory.scrap-=2;v2.state.inventory.parts-=1
	v2.state.work={"active":true,"unit_id":"ida","recipe_id":"toolkit","remaining":6.0,"total":6.0,"phase":"walking","reserved":{"scrap":2,"parts":1}}
	v2.state.crew.ida.assignment="work";v2.state.crew.ida.target=preload("res://scripts/core/legacy_catalog_v2.gd").interaction_point("base","workbench")
	check(V2.validate(v2).is_empty(),"independent active v2 valid")
	sim=load_fixture(v2,"active v2");sim.advance(30);check(sim.snapshot().inventory.toolkit==1,"v2 job completes once");sim.free()
	v3=Ground.migrate(Stage.migrate(base_v1()));v3.state.region="rust";v3.state.ship.position=Old.landmarks("rust").shuttle;v3.state.ship.target=v3.state.ship.position.duplicate()
	for unit: Dictionary in v3.state.crew.values():unit.position=[0.0,0.0];unit.target=[0.0,0.0]
	v3.state.discovery.radar_scanned=true;v3.state.discovery.signals=Old.radar_contacts();v3.state.discovery.signals[1].identified=true;v3.state.discovery.signals[1].kind="mining_site";v3.state.discovery.signals[1].label="Erzvorkommen"
	v3.state.crew.ida.assignment="gather";v3.state.crew.ida.position=Old.interaction_point("rust","mining_site");v3.state.crew.ida.target=v3.state.crew.ida.position.duplicate()
	var duration: float=8.0/Old.skill_effects(v3.state.crew.ida).gather_multiplier
	v3.state.ground.activity={"active":true,"unit_id":"ida","site_id":"mining_site","remaining":duration,"total":duration,"phase":"working"}
	check(V3.validate(v3).is_empty(),"old toolless extraction valid")
	sim=load_fixture(v3,"v3 active extraction");sim.advance(10);check(sim.snapshot().cargo.ore==3,"old tool-less job grandfathered")
	check(not sim.submit({"type":"gather","unit_id":"ida","site_id":"mining_site","request_id":"new-tool-gate"}).ok,"new extraction needs new tool");sim.free()
	v3=Ground.migrate(Stage.migrate(base_v1()));v3.state.travel={"active":true,"from":"base","to":"rust","remaining":5.0,"total":5.0,"phase":"boarding","kind":"intermap","encounter_decided":true,"encounter_roll":99}
	for unit: Dictionary in v3.state.crew.values():unit.assignment="boarding";unit.target=v3.state.ship.position.duplicate()
	check(V3.validate(v3).is_empty(),"old accepted boarding travel valid")
	sim=load_fixture(v3,"v3 accepted trip");sim.advance(5.1);check(sim.snapshot().region=="rust" and sim.snapshot().ship.mode=="flying" and sim.snapshot().crew.ida.assignment=="aboard","legacy trip arrives airborne without exit");sim.free()
	print("N4_MIGRATION ",checks," checks, ",failures," failures");quit(1 if failures else 0)
