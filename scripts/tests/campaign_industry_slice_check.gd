extends SceneTree
## Bounded industry/Supply-domain fixture, no mission, renderer or native UI.
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const COMMANDS = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
var checks := 0
var failures := 0
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)
func command(state, operation: String, payload: Dictionary, id: String, context: Dictionary = {"at_home":true,"campaign_authorized":true}) -> Dictionary:
	return state.apply_command(COMMANDS.build_command(operation, payload, id), context)
func run() -> void:
	var state = SUPPLY.new()
	check(state.configure(["probe"]).ok, "Existing Supply config loads")
	state.configure_inventory([], ["probe"], true)
	state.configure_start_inventory("campaign")
	check(not command(state,"campaign_research",{"research_id":"research_industry"},"before-workshop").ok, "Industry needs workshop development")
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	campaign.configure()
	var jobs: Dictionary = campaign.get_campaign_snapshot().jobs
	for id: String in ["satellite_recovery","outpost_recovery","benit_delivery","outpost_chip_recovery"]:
		var job: Dictionary = jobs[id]
		var receipt := {"completion_id":id+":completed","job_id":id,"scenario_id":job.scenario_id,"runtime_verified":true,"reward":job.reward}
		check(command(state,"apply_reward",{"completion_id":receipt.completion_id},"reward:"+id,{"completion_receipt":receipt}).ok, "Unchanged trusted job fixture "+id)
	check(command(state,"campaign_research",{"research_id":"workshop_research"},"workshop").ok, "Workshop uses existing uploaded-chip reward evidence")
	check(command(state,"buy",{"offer_id":"mining_tool_supply","quantity":1},"buy-mining",{"location_id":"trade_outpost","craft_id":"probe","craft_busy":false,"require_blueprints":true}).ok, "Existing mining-tool purchase remains available")
	var blocked := command(state,"campaign_research",{"research_id":"research_industry"},"purchased-only")
	check(not blocked.ok and String(blocked.message).contains("Hand-Mining-Tool"), "Purchased tool does not replace fabrication evidence; correct missing-tool text")
	check(command(state,"campaign_fabricate",{"blueprint_id":"mining_tool"},"craft-mining").ok, "Existing mining recipe fabricates for 30Cr")
	check(state.get_research_snapshot().nodes.research_industry.available, "Industry becomes available after actual mining fabrication")
	check(not command(state,"campaign_fabricate",{"blueprint_id":"salvage_tool"},"locked-salvage").ok, "Salvage recipe locked before development")
	check(not command(state,"campaign_research",{"research_id":"research_industry"},"remote",{"campaign_authorized":true,"at_home":false}).ok, "Industry development requires home")
	check(not command(state,"campaign_research",{"research_id":"research_industry"},"untrusted",{"at_home":true}).ok, "Industry development requires campaign authority")
	var before: int = state.get_supply_snapshot().credits
	var development := command(state,"campaign_research",{"research_id":"research_industry"},"industry")
	check(development.ok and development.cost == 160 and state.get_supply_snapshot().credits == before-160, "Development costs exactly 160Cr once")
	check(state.get_supply_snapshot().blueprints.has("salvage_tool") and int(state.get_supply_snapshot().item_quantities.get("salvage_tool",0)) == 0, "Development grants blueprint without free tool")
	check(command(state,"campaign_research",{"research_id":"research_industry"},"industry").get("replayed",false) and command(state,"campaign_research",{"research_id":"research_industry"},"industry-again").cost == 0 and state.get_supply_snapshot().credits == before-160, "Replay and second request cannot double charge")
	check(not command(state,"campaign_fabricate",{"blueprint_id":"salvage_tool"},"remote-craft",{"at_home":false}).ok, "Salvage fabrication requires home")
	var crafted := command(state,"campaign_fabricate",{"blueprint_id":"salvage_tool"},"craft-salvage")
	check(crafted.ok and crafted.item_id == "salvage_tool" and state.get_supply_snapshot().credits == before-200 and state.get_supply_snapshot().item_quantities.salvage_tool == 1, "Separate salvage fabrication costs40Cr into existing storage")
	check(command(state,"campaign_fabricate",{"blueprint_id":"salvage_tool"},"craft-salvage").get("replayed",false) and state.get_supply_snapshot().item_quantities.salvage_tool == 1, "Fabrication replay creates no duplicate")
	var resources: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/location_resources.json"))
	check(resources.satellite_crash.freighter_wreck_01.required_tool == crafted.item_id, "Fabricated item matches existing wreck collection contract")
	var restored = SUPPLY.new()
	var restoration: Dictionary = restored.restore_state(JSON.parse_string(JSON.stringify(state.export_state())))
	if not restoration.ok: print("RESTORE_DIAGNOSTIC ", restoration)
	check(restoration.ok and restored.get_supply_snapshot().blueprints.has("salvage_tool"), "Single industry ledger JSON roundtrip preserves recipe")
	print("CAMPAIGN_INDUSTRY_SLICE ", checks, " checked, ", failures, " failed")
	quit(0 if failures == 0 else 1)
