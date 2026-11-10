extends RefCounted
## One-shot UI-to-Flow request; contains no gameplay or checkpoint state.
const META_KEY: StringName = &"game_start_request_v1"

static func clear_start(tree: SceneTree) -> void:
	if tree != null and tree.root != null and tree.root.has_meta(META_KEY):
		tree.root.remove_meta(META_KEY)

static func request_start(tree: SceneTree, mode: String, action: String = "new", preset_id: String = "") -> Dictionary:
	clear_start(tree)
	if tree == null or tree.root == null:
		return {"ok": false, "reason": "missing_tree"}
	if mode not in ["campaign", "skirmish"] or action not in ["new", "continue"] or (mode == "skirmish" and action != "new"):
		return {"ok": false, "reason": "invalid_start"}
	if not preset_id.is_empty() and (mode != "skirmish" or preset_id not in ["early", "mid", "late"]):
		return {"ok":false,"reason":"invalid_skirmish_preset"}
	var request := {"mode": mode, "action": action}
	if not preset_id.is_empty(): request["preset_id"] = preset_id
	tree.root.set_meta(META_KEY, request)
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
	var result := {"mode": mode, "action": action}
	if value.has("preset_id"):
		if mode != "skirmish" or typeof(value.preset_id) != TYPE_STRING or value.preset_id not in ["early", "mid", "late"]:
			return fallback
		result["preset_id"] = value.preset_id
	return result
