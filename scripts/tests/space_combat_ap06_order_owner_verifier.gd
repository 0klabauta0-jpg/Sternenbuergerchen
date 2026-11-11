extends SceneTree
const OWNER = preload("res://scripts/core/space_wing_state.gd")

func _initialize() -> void:
	var state = OWNER.new()
	var context := {"authorized":true, "actor_id":"player", "phase":"tactical", "owned_crafts":["a", "b"], "craft_pilots":{"a":"p1", "b":"p2"}}
	var failed := 0
	for pair in [["w1", "a"], ["w2", "b"]]:
		if not _apply(state, context, "wing_create", {"wing_id":pair[0]}, "create-" + pair[0]).get("ok", false): failed += 1
		if not _apply(state, context, "wing_assign", {"wing_id":pair[0], "craft_id":pair[1]}, "assign-" + pair[0]).get("ok", false): failed += 1
	var issue := {"contract_category":"space_combat", "operation":"order_issue", "request_id":"order-1", "expected_revision":4, "payload":{"wing_ids":["w1", "w2"], "verb":"secure", "target_hex":Vector2i(10,10), "contact_response":"avoid", "fire_rule":"hold"}}
	if not state.apply_command(issue, context).get("ok", false): failed += 1
	var wings: Dictionary = state.get_snapshot().wings
	if wings.w1.order != wings.w2.order or wings.w1.order.contact_response != "avoid" or wings.w1.order.fire_rule != "hold": failed += 1
	if not state.apply_command(issue, context).get("replayed", false) or state.get_snapshot().revision != 5: failed += 1
	var invalid := issue.duplicate(true)
	invalid.request_id = "invalid"
	invalid.expected_revision = 5
	invalid.payload.wing_ids = ["w1", "unknown"]
	if state.apply_command(invalid, context).get("ok", false) or state.get_snapshot().revision != 5: failed += 1
	if _apply(state, context, "order_cancel", {"wing_id":"w1", "order_id":"wrong"}, "cancel-wrong").get("ok", false): failed += 1
	if not _apply(state, context, "order_cancel", {"wing_id":"w1", "order_id":"order-1"}, "cancel").get("ok", false): failed += 1
	wings = state.get_snapshot().wings
	if not wings.w1.order.is_empty() or wings.w2.order.order_id != "order-1": failed += 1
	if not _apply(state, context, "wing_create", {"wing_id":"empty"}, "empty").get("ok", false): failed += 1
	var before: Dictionary = state.get_snapshot()
	if _apply(state, context, "order_issue", {"wing_ids":["w2", "empty"], "verb":"move", "target_hex":Vector2i(11,10)}, "mixed").get("ok", false) or state.get_snapshot() != before: failed += 1
	print("SPACE_COMBAT_AP06_ORDER_OWNER passed=", 13 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _apply(state: RefCounted, context: Dictionary, op: String, payload: Dictionary, request: String) -> Dictionary:
	return state.apply_command({"contract_category":"space_combat", "operation":op, "request_id":request, "expected_revision":state.get_snapshot().revision, "payload":payload}, context)
