extends SceneTree
## Small isolated Supply-domain check, not an actual campaign/mission playtest.
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const COMMANDS = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
var checks := 0
var failures := 0
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)
func command(state, operation: String, payload: Dictionary, id: String, context: Dictionary = {"at_home": true, "campaign_authorized": true}) -> Dictionary:
	return state.apply_command(COMMANDS.build_command(operation, payload, id), context)
func reward(state, id: String) -> void:
	var jobs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/jobs.json"))
	var job: Dictionary = jobs[id]
	var receipt := {"completion_id": id + ":completed", "job_id": id, "scenario_id": job.scenario_id, "runtime_verified": true, "reward": job.reward}
	check(command(state, "apply_reward", {"completion_id": receipt.completion_id}, "reward:" + id, {"completion_receipt": receipt}).ok, "Trusted fixture receipt uses unchanged job definition " + id)
func run() -> void:
	var state = SUPPLY.new()
	check(state.configure(["probe"]).ok, "Existing supply config loads")
	state.configure_inventory([], ["probe"], true)
	state.configure_start_inventory("campaign")
	var legacy := state.export_state()
	legacy.erase("research_receipts")
	var old = SUPPLY.new()
	check(old.restore_state(legacy).ok and old.get_research_snapshot().developed_ids.is_empty(), "Old save without research restores empty progress")
	var initial := state.get_supply_snapshot()
	check(not command(state, "campaign_research", {"research_id": "workshop_research"}, "locked").ok and state.get_supply_snapshot().credits == initial.credits, "Workshop blocked before real uploaded-chip receipt without charge")
	reward(state, "satellite_recovery")
	reward(state, "outpost_chip_recovery")
	check(not command(state, "campaign_research", {"research_id": "workshop_research"}, "remote", {"campaign_authorized":true,"at_home":false}).ok, "Development requires home")
	check(not command(state, "campaign_research", {"research_id": "workshop_research"}, "untrusted", {"at_home":true}).ok, "Development requires campaign authority")
	var before: int = state.get_supply_snapshot().credits
	var workshop := command(state, "campaign_research", {"research_id": "workshop_research"}, "workshop")
	check(workshop.ok and workshop.cost == 180 and state.get_supply_snapshot().credits == before - 180, "Workshop development pays once from existing credits")
	check(command(state, "campaign_research", {"research_id": "workshop_research"}, "workshop").get("replayed", false) and state.get_supply_snapshot().credits == before - 180, "Identical request replays without charge")
	check(not command(state, "campaign_research", {"research_id": "research_medium"}, "workshop").ok, "Conflicting request ID rejected")
	check(command(state, "campaign_research", {"research_id": "workshop_research"}, "workshop-again").cost == 0 and state.get_supply_snapshot().credits == before - 180, "A second development request cannot double-charge")
	check(not command(state, "campaign_research", {"research_id": "research_medium"}, "medium-locked").ok, "Medium requires an actually fabricated light armor")
	check(not command(state, "campaign_fabricate", {"blueprint_id": "medium_armor"}, "medium-craft-locked").ok, "Blueprint does not precede development")
	check(command(state, "campaign_fabricate", {"blueprint_id": "light_armor"}, "craft-light").ok, "Existing light recipe remains 20 credits")
	check(command(state, "campaign_research", {"research_id": "research_medium"}, "medium").ok, "Medium unlocks after workshop plus actual light fabrication")
	check(state.get_supply_snapshot().blueprints.has("medium_armor") and not state.get_supply_snapshot().item_quantities.has("armor_medium"), "Development unlocks recipe without free equipment")
	check(command(state, "campaign_fabricate", {"blueprint_id": "medium_armor"}, "craft-medium").ok and state.get_supply_snapshot().item_quantities.armor_medium == 1, "Medium separately fabricated into existing storage")
	check(command(state, "campaign_research", {"research_id": "research_heavy"}, "heavy").ok and command(state, "campaign_fabricate", {"blueprint_id": "heavy_armor"}, "craft-heavy").ok, "Heavy follows medium development and separate fabrication")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.export_state()))
	var restored = SUPPLY.new()
	check(restored.restore_state(saved).ok and restored.get_supply_snapshot().blueprints.has("heavy_armor"), "JSON save restores all developed recipes")
	var bad := saved.duplicate(true)
	bad.research_receipts.research_medium.cost = 1
	check(not restored.restore_state(bad).ok, "Tampered development cost rejected")
	bad = saved.duplicate(true)
	bad.research_receipts.erase("workshop_research")
	check(not restored.restore_state(bad).ok, "Missing development prerequisite rejected")
	bad = saved.duplicate(true)
	bad.requests.erase("craft-light")
	check(not restored.restore_state(bad).ok, "Missing fabrication evidence rejected")
	bad = saved.duplicate(true)
	bad.research_receipts = {}
	check(not restored.restore_state(bad).ok, "Research requests cannot survive a missing ledger")
	check(restored.get_supply_snapshot().blueprints.has("heavy_armor"), "Failed restore preserves existing valid state")
	print("CAMPAIGN_RESEARCH_SLICE ", checks, " passed/checked, ", failures, " failed")
	quit(0 if failures == 0 else 1)
