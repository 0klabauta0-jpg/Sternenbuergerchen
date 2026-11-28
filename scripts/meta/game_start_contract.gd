extends RefCounted
## One-shot UI-to-Flow request; contains no gameplay or checkpoint state.
const META_KEY: StringName = &"game_start_request_v1"
const POINTS = preload("res://scripts/meta/skirmish_points_catalog.gd")
const SKIRMISH_CONFIG = preload("res://scripts/meta/skirmish_start_configuration.gd")

static func clear_start(tree: SceneTree) -> void:
	if tree != null and tree.root != null and tree.root.has_meta(META_KEY):
		tree.root.remove_meta(META_KEY)

static func request_start(tree: SceneTree, mode: String, action: String = "new", preset_id: String = "", points_draft: Dictionary = {}, map_path: String = "") -> Dictionary:
	clear_start(tree)
	if tree == null or tree.root == null:
		return {"ok": false, "reason": "missing_tree"}
	if mode not in ["campaign", "skirmish"] or action not in ["new", "continue", "continue_home"] or (mode == "skirmish" and action != "new"):
		return {"ok": false, "reason": "invalid_start"}
	if not preset_id.is_empty() and (mode != "skirmish" or preset_id not in ["early", "mid", "late"]):
		return {"ok":false,"reason":"invalid_skirmish_preset"}
	if not map_path.is_empty() and (mode != "skirmish" or not SKIRMISH_CONFIG.is_playable_map(map_path)):
		return {"ok": false, "reason": "invalid_skirmish_map"}
	var request := {"mode": mode, "action": action}
	if not preset_id.is_empty(): request["preset_id"] = preset_id
	if not map_path.is_empty(): request["map_path"] = map_path
	if not points_draft.is_empty():
		if mode != "skirmish" or not preset_id.is_empty():
			return {"ok": false, "reason": "invalid_skirmish_points_start"}
		var purchase := POINTS.evaluate(points_draft)
		if not purchase.ok:
			return purchase
		request["points_draft"] = points_draft.duplicate(true)
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
	if mode not in ["campaign", "skirmish"] or action not in ["new", "continue", "continue_home"] or (mode == "skirmish" and action != "new"):
		return fallback
	var result := {"mode": mode, "action": action}
	if value.has("preset_id"):
		if mode != "skirmish" or typeof(value.preset_id) != TYPE_STRING or value.preset_id not in ["early", "mid", "late"]:
			return fallback
		result["preset_id"] = value.preset_id
	if value.has("map_path"):
		if mode != "skirmish" or typeof(value.map_path) != TYPE_STRING or not SKIRMISH_CONFIG.is_playable_map(value.map_path):
			return fallback
		result["map_path"] = value.map_path
	if value.has("points_draft"):
		if mode != "skirmish" or value.has("preset_id") or not value.points_draft is Dictionary or not POINTS.evaluate(value.points_draft).ok:
			return fallback
		result["points_draft"] = value.points_draft.duplicate(true)
	return result
