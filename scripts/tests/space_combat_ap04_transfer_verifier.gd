extends SceneTree
const OWNER = preload("res://scripts/core/space_wing_state.gd")

func _initialize() -> void:
	var state = OWNER.new()
	var pilots := {"a":"p1", "b":"p2"}
	var context := {"authorized":true, "actor_id":"p", "phase":"orbit", "owned_crafts":["a","b"], "craft_pilots":pilots}
	var failed := 0
	for pair in [["w1", "a"], ["w2", "b"]]:
		if not _apply(state, context, "wing_create", {"wing_id":pair[0]}, "c" + pair[0]).get("ok", false): failed += 1
		if not _apply(state, context, "wing_assign", {"wing_id":pair[0], "craft_id":pair[1]}, "a" + pair[0]).get("ok", false): failed += 1
	var before: Dictionary = state.get_snapshot()
	if state.transfer_craft("other", "a", "w2", pilots).get("ok", false) or state.get_snapshot() != before: failed += 1
	if state.transfer_craft("p", "a", "missing", pilots).get("ok", false) or state.get_snapshot() != before: failed += 1
	if not state.transfer_craft("p", "a", "w2", pilots).get("ok", false): failed += 1
	var after: Dictionary = state.get_snapshot()
	if after.wings.has("w1") or after.wings.w2.craft_ids != ["b", "a"] or after.wings.w2.leader_craft_id != "b": failed += 1
	if state.transfer_craft("p", "a", "w2", pilots).get("reason") != "already_member" or state.get_snapshot() != after: failed += 1
	if state.transfer_craft("p", "missing", "w2", pilots).get("ok", false) or state.get_snapshot() != after: failed += 1
	var full = OWNER.new()
	var crafts: Array = []
	var many_pilots := {}
	for i in range(7):
		var craft := "ship%d" % i
		crafts.append(craft)
		many_pilots[craft] = "pilot%d" % i
	var created: Dictionary = full.ensure_flying_wings("p", crafts, crafts, many_pilots)
	var target: String = created.wing_by_craft.ship0
	for i in range(1, 6):
		if not full.transfer_craft("p", "ship%d" % i, target, many_pilots).get("ok", false): failed += 1
	var full_before: Dictionary = full.get_snapshot()
	if full.transfer_craft("p", "ship6", target, many_pilots).get("reason") != "wing_full" or full.get_snapshot() != full_before: failed += 1
	print("SPACE_COMBAT_AP04_TRANSFER passed=", 16 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _apply(state: RefCounted, context: Dictionary, op: String, payload: Dictionary, request: String) -> Dictionary:
	return state.apply_command({"contract_category":"space_combat", "operation":op, "request_id":request, "expected_revision":state.get_snapshot().revision, "payload":payload}, context)
