extends SceneTree
const OWNER = preload("res://scripts/core/space_wing_state.gd")

func _initialize() -> void:
	var state = OWNER.new()
	var failed := 0
	var pilots := {"fighter":"p1", "cutlass":"p2", "unpiloted":""}
	var owned := ["fighter", "cutlass", "unpiloted"]
	var empty: Dictionary = state.get_snapshot()
	var preview: Dictionary = state.preview_flying_wings("player", ["cutlass", "fighter"], owned, pilots)
	if not preview.get("ok", false) or state.get_snapshot() != empty: failed += 1
	var result: Dictionary = state.ensure_flying_wings("player", ["cutlass", "fighter"], owned, pilots)
	if not result.get("ok", false): failed += 1
	if preview.get("wing_by_craft") != result.get("wing_by_craft"): failed += 1
	var snap: Dictionary = state.get_snapshot()
	if snap.wings.size() != 2 or result.wing_by_craft.cutlass == result.wing_by_craft.fighter: failed += 1
	if snap.wings[result.wing_by_craft.cutlass].craft_ids != ["cutlass"]: failed += 1
	var repeat: Dictionary = state.ensure_flying_wings("player", ["fighter", "cutlass"], owned, pilots)
	if not repeat.get("ok", false) or repeat.get("changed", true) or state.get_snapshot() != snap: failed += 1
	var rejected: Dictionary = state.ensure_flying_wings("player", ["unpiloted", "foreign"], owned, pilots)
	if rejected.get("ok", false) or state.get_snapshot() != snap: failed += 1
	var no_pilot: Dictionary = state.ensure_flying_wings("player", ["unpiloted"], owned, pilots)
	if not no_pilot.get("ok", false) or state.get_snapshot().wings[no_pilot.wing_by_craft.unpiloted].active: failed += 1
	var before: Dictionary = state.get_snapshot()
	if state.ensure_flying_wings("other", ["fighter"], ["fighter"], pilots).get("ok", false) or state.get_snapshot() != before: failed += 1
	var duplicate = OWNER.new()
	if duplicate.ensure_flying_wings("player", ["fighter", "cutlass"], owned, {"fighter":"p1", "cutlass":"p1"}).get("ok", false) or not duplicate.get_snapshot().wings.is_empty(): failed += 1
	if state.ensure_flying_wings("player", ["fighter", "fighter"], owned, pilots).get("ok", false): failed += 1
	var context := {"authorized":true, "actor_id":"player", "phase":"tactical", "owned_crafts":owned, "craft_pilots":pilots, "flying_crafts":["fighter"]}
	var removal := {"contract_category":"space_combat", "operation":"wing_remove", "request_id":"remove-flying", "expected_revision":state.get_snapshot().revision, "payload":{"wing_id":result.wing_by_craft.fighter, "craft_id":"fighter"}}
	var before_remove: Dictionary = state.get_snapshot()
	if state.apply_command(removal, context).get("reason") != "craft_flying" or state.get_snapshot() != before_remove: failed += 1
	var stale: Dictionary = state.ensure_flying_wings("player", ["fighter"], owned, pilots, 0)
	if stale.get("reason") != "stale_revision" or state.get_snapshot() != before_remove: failed += 1
	print("SPACE_COMBAT_AP04_FLYING_WING passed=", 13 - failed, " failed=", failed)
	quit(1 if failed else 0)
