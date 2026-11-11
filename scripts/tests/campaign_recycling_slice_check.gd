extends SceneTree
## Small Supply-domain fixture only: no renderer, mission or actor movement.
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const COMMANDS = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
const INVENTORY = preload("res://scripts/mission/inventory_transfer_contract.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, name: String) -> void:
	checks += 1
	failures += int(not ok)
	print("PASS: " if ok else "FAIL: ",name)
func command(state, operation: String, payload: Dictionary, id: String, context: Dictionary = {"at_home":true,"campaign_authorized":true}) -> Dictionary:
	return state.apply_command(COMMANDS.build_command(operation,payload,id),context)
func fingerprint(state) -> String: return JSON.stringify(state.export_state(),"",true)
func clone_state(saved: Dictionary):
	var state = SUPPLY.new()
	var result: Dictionary = state.restore_state(JSON.parse_string(JSON.stringify(saved)))
	if not result.ok: print("RESTORE_DIAGNOSTIC ",result)
	return state if result.ok else null
func run() -> void:
	var state = SUPPLY.new()
	state.configure(["probe"])
	# Reading before storage initialization must not cache unavailable fabrication.
	state.get_supply_snapshot()
	state.configure_inventory(["u"],["probe"],true)
	state.configure_start_inventory("campaign")
	check(INVENTORY.has_space(state.get_supply_snapshot().inventory["unit:u:backpack"],"satellite_chip",1),"Suit data slot still needs no backpack")
	check(not command(state,"campaign_research",{"research_id":"research_recycling"},"locked-initial").ok,"Recycling cannot precede industry")
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	campaign.configure()
	var setup_ok := true
	for id: String in ["satellite_recovery","outpost_recovery","benit_delivery","outpost_chip_recovery"]:
		var job: Dictionary = campaign.get_campaign_snapshot().jobs[id]
		var receipt := {"completion_id":id+":completed","job_id":id,"scenario_id":job.scenario_id,"runtime_verified":true,"reward":job.reward}
		setup_ok = command(state,"apply_reward",{"completion_id":receipt.completion_id},"reward:"+id,{"completion_receipt":receipt}).ok and setup_ok
	setup_ok = command(state,"campaign_research",{"research_id":"workshop_research"},"workshop").ok and setup_ok
	setup_ok = command(state,"campaign_fabricate",{"blueprint_id":"mining_tool"},"mining").ok and setup_ok
	setup_ok = command(state,"campaign_research",{"research_id":"research_industry"},"industry").ok and setup_ok
	check(setup_ok,"Existing normalized jobs and workshop/industry path remain usable")
	check(not command(state,"campaign_research",{"research_id":"research_recycling"},"tool-not-crafted").ok,"Actual salvage fabrication is required")
	check(command(state,"campaign_fabricate",{"blueprint_id":"salvage_tool"},"salvage-tool").ok,"Existing40Cr salvage tool recipe still works")
	var legacy: Dictionary = state.export_state()
	check(clone_state(legacy) != null and not legacy.requests.mining.result.has("materials_consumed"),"Legacy fabrication receipts without input fields restore")
	var credits: int = state.get_supply_snapshot().credits
	var developed := command(state,"campaign_research",{"research_id":"research_recycling"},"recycling")
	check(developed.ok and developed.cost==100 and state.get_supply_snapshot().credits==credits-100 and not state.get_supply_snapshot().item_quantities.has("backpack"),"100Cr development grants recipe and no free backpack")
	check(command(state,"campaign_research",{"research_id":"research_recycling"},"recycling").get("replayed",false) and state.get_supply_snapshot().credits==credits-100,"Development replay does not charge again")
	var before := fingerprint(state)
	check(not command(state,"campaign_fabricate",{"blueprint_id":"backpack_recycling"},"missing").ok and fingerprint(state)==before,"Missing materials leave every owner field unchanged")
	check(command(state,"campaign_cargo",{"container_id":"craft:probe","item_id":"salvage","amount":2},"salvage-delivery").ok,"Trusted fixture places real salvage identity into ship cargo")
	before = fingerprint(state)
	check(not state.preview_campaign_fabrication("backpack_recycling").ok and not command(state,"campaign_fabricate",{"blueprint_id":"backpack_recycling"},"ship-not-base").ok and fingerprint(state)==before,"Ship stock is not remote-accessible fabrication material")
	check(command(state,"inventory_transfer",{"source_container_id":"craft:probe","destination_container_id":"base:homebase","item_id":"salvage","amount":2},"unload",{"accessible_containers":["craft:probe","base:homebase"]}).ok,"Existing explicit transfer unloads salvage into base")
	var ready: Dictionary = state.export_state()
	check(state.get_supply_snapshot().research.fabrication.backpack_recycling.ok,"Revision-cached owner projection now permits fabrication")
	before = fingerprint(state)
	check(not command(state,"campaign_fabricate",{"blueprint_id":"backpack_recycling"},"away",{"at_home":false}).ok and fingerprint(state)==before,"Remote fabrication is rejected without mutations")
	credits = state.get_supply_snapshot().credits
	var made := command(state,"campaign_fabricate",{"blueprint_id":"backpack_recycling"},"recycle")
	check(made.ok and made.recipe_id=="backpack_recycling" and made.item_id=="backpack" and made.materials_consumed.size()==1 and int(made.materials_consumed.salvage)==2 and made.cost==20 and state.get_supply_snapshot().credits==credits-20 and not state.get_supply_snapshot().item_quantities.has("salvage") and state.get_supply_snapshot().item_quantities.backpack==1,"One atomic commit spends2salvage/20Cr and produces1backpack")
	before = fingerprint(state)
	check(command(state,"campaign_fabricate",{"blueprint_id":"backpack_recycling"},"recycle").get("replayed",false) and fingerprint(state)==before,"Fabrication replay cannot spend or create twice")
	check(not command(state,"campaign_fabricate",{"blueprint_id":"mining_tool"},"recycle").ok and fingerprint(state)==before,"Conflicting request ID cannot spend materials")
	var equipped := command(state,"inventory_equip",{"unit_id":"u","source_container_id":"base:homebase","item_id":"backpack","slot":"backpack"},"equip",{"unit_id":"u","accessible_containers":["base:homebase","unit:u:backpack"],"equipment_allowed":true,"loadout":{"armor":"suit"}})
	check(equipped.ok and state.get_supply_snapshot().inventory["unit:u:backpack"].capacity==INVENTORY.BACKPACK_CAPACITY,"Crafted backpack feeds the existing12Slot consumer")
	var saved: Dictionary = state.export_state()
	check(clone_state(saved) != null,"New material receipt and equipped output survive one JSON-domain roundtrip")
	for field: String in ["materials_consumed","cost","item_id","recipe_id"]:
		var changed: Dictionary = saved.duplicate(true)
		changed.requests.recycle.result[field] = {"salvage":1} if field=="materials_consumed" else (1 if field=="cost" else "mining_tool")
		var invalid = SUPPLY.new()
		check(not invalid.restore_state(JSON.parse_string(JSON.stringify(changed))).ok,"Tampered material receipt rejected: "+field)
	var missing: Dictionary = saved.duplicate(true)
	missing.requests.recycle.result.erase("materials_consumed")
	check(not SUPPLY.new().restore_state(JSON.parse_string(JSON.stringify(missing))).ok,"New material receipt cannot omit its spent inputs")
	var full = clone_state(ready)
	full.get("_inventory")["base:homebase"].capacity = INVENTORY.used(full.get("_item_quantities"))
	before = fingerprint(full)
	check(not command(full,"campaign_fabricate",{"blueprint_id":"mining_tool"},"full-legacy").ok and fingerprint(full)==before,"Full output blocks material-free legacy recipe without charges")
	check(command(full,"campaign_fabricate",{"blueprint_id":"backpack_recycling"},"full-recycle").ok and INVENTORY.used(full.get("_item_quantities")) < int(full.get("_inventory")["base:homebase"].capacity),"A full store can recycle2inputs into1output using final capacity")
	var poor: Dictionary = ready.duplicate(true)
	poor.credits = 0
	var broke = clone_state(poor)
	before = fingerprint(broke)
	check(not command(broke,"campaign_fabricate",{"blueprint_id":"backpack_recycling"},"poor").ok and fingerprint(broke)==before,"Insufficient credits do not consume available material")
	print("CAMPAIGN_RECYCLING_SLICE ",checks," checked, ",failures," failed")
	quit(0 if failures==0 else 1)
