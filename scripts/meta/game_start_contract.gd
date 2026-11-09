extends RefCounted
## One-shot UI-to-Flow request; contains no gameplay or checkpoint state.
const META_KEY: StringName = &"game_start_request_v1"

static func clear_start(tree: SceneTree) -> void:
	if tree != null and tree.root != null and tree.root.has_meta(META_KEY):
		tree.root.remove_meta(META_KEY)

static func request_start(tree: SceneTree, mode: String, action: String = "new") -> Dictionary:
	clear_start(tree)
	if tree == null or tree.root == null:
		return {"ok": false, "reason": "missing_tree"}
	if mode not in ["campaign", "skirmish"] or action not in ["new", "continue"] or (mode == "skirmish" and action != "new"):
		return {"ok": false, "reason": "invalid_start"}
	tree.root.set_meta(META_KEY, {"mode": mode, "action": action})
	return {"ok": true}

static func consume_start(tree: SceneTree) -> Dictionary:
	var fallback: Dictionary = {"mode": "skirmish", "action": "new"}
	if tree == null or tree.root == null:
		return fallback
	var value: Variant = tree.root.get_meta(META_KEY, {})
	clear_start(tree)
	if not value is Dictionary:
		return fallback
	var mode: Variant = value.get("mode")
	var action: Variant = value.get("action")
	if not mode is String or not action is String:
		return fallback
	if mode not in ["campaign", "skirmish"] or action not in ["new", "continue"] or (mode == "skirmish" and action != "new"):
		return fallback
	return {"mode": mode, "action": action}
