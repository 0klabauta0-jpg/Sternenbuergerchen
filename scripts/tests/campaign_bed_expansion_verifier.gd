extends SceneTree
var built := 0
var available := true
func _build(count: int) -> Dictionary:
	if not available: return {"ok":false,"reason":"no_room"}
	if count != built + 1: return {"ok":false,"reason":"wrong_count"}
	built = count
	return {"ok":true,"housing_count":count}
func _init() -> void: call_deferred("_run")
func _fail(message: String) -> void: printerr("FAIL: " + message); quit(1)
func _run() -> void:
	var owner = load("res://scripts/core/singleplayer_supply_state.gd").new()
	var contract = load("res://scripts/mission/singleplayer_supply_command_contract.gd")
	if not owner.configure().ok: _fail("configure"); return
	owner._credits = 1000
	var ctx := {"at_home":true,"campaign_authorized":true,"campaign_housing_builder":Callable(self,"_build")}
	var command: Dictionary = contract.build_command("campaign_build_housing", {}, "build-house-1")
	available = false
	if owner.apply_command(command, ctx).get("ok", false) or owner.get_supply_snapshot().credits != 1000 or built != 0: _fail("failed build mutates state"); return
	available = true
	var result: Dictionary = owner.apply_command(command, ctx)
	if not result.get("ok", false) or result.get("housing_count") != 1 or owner.get_supply_snapshot().credits != 500 or owner.get_campaign_bed_count() != 4: _fail("housing payment and beds"); return
	if not owner.apply_command(command, ctx).get("replayed", false) or owner.get_supply_snapshot().credits != 500 or built != 1: _fail("replay duplicates build"); return
	var saved: Dictionary = owner.export_state()
	var restored = load("res://scripts/core/singleplayer_supply_state.gd").new()
	if not restored.restore_state(saved).get("ok", false) or restored.get_campaign_bed_count() != 4: _fail("restore"); return
	var bad: Dictionary = saved.duplicate(true); bad.requests["build-house-1"].result.cost = 0
	if restored.restore_state(bad).get("ok", false): _fail("tampered housing accepted"); return
	var legacy = load("res://scripts/core/singleplayer_supply_state.gd").new(); legacy.configure()
	var signature := JSON.stringify({"operation":"campaign_build_bed","payload":{}}, "", true)
	legacy._requests["old-bed-1"] = {"signature":signature,"result":{"ok":true,"operation":"campaign_build_bed","request_id":"old-bed-1","bed_count":3,"cost":100}}
	var old_save: Dictionary = legacy.export_state()
	var migrated = load("res://scripts/core/singleplayer_supply_state.gd").new()
	if not migrated.restore_state(old_save).get("ok", false) or migrated.get_campaign_housing_count() != 1 or migrated.get_campaign_bed_count() != 4: _fail("legacy bed migration"); return
	print("CAMPAIGN_HOUSING_PAYMENT_MIGRATION_PASS")
	quit(0)
