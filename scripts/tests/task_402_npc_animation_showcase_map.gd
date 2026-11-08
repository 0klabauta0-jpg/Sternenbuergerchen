extends SceneTree

const SHOWCASE_SCENE: PackedScene = preload("res://scenes/tests/npc_animation_showcase_map.tscn")
const NPC_UNIT_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const EXPECTED_ANIMATIONS: PackedStringArray = [
	"attack",
	"crouch",
	"crouchIdle",
	"crouchWalk",
	"death",
	"idle",
	"interactGround",
	"interactStanding",
	"jump",
	"kick",
	"punch",
	"racingIdle",
	"racingLeft",
	"racingRight",
	"run",
	"shoot",
	"walk",
]
const EXPECTED_COMBAT_CASES: Dictionary = {
	"standShoot": {
		"base_animation": "shoot",
		"upper_body_pose_animation": "shoot",
		"pose_track_scope": "shoot_upper_body",
	},
	"walkShoot": {
		"base_animation": "walk",
		"upper_body_pose_animation": "shoot",
		"pose_track_scope": "shoot_upper_body",
	},
	"runShoot": {
		"base_animation": "run",
		"upper_body_pose_animation": "shoot",
		"pose_track_scope": "shoot_upper_body",
	},
	"crouchShoot": {
		"base_animation": "crouchIdle",
		"upper_body_pose_animation": "shoot",
		"pose_track_scope": "shoot_upper_body",
	},
	"crouchWalkShoot": {
		"base_animation": "crouchWalk",
		"upper_body_pose_animation": "shoot",
		"pose_track_scope": "shoot_upper_body",
	},
	"crouchRunShoot": {
		"base_animation": "crouchWalk",
		"upper_body_pose_animation": "shoot",
		"pose_track_scope": "shoot_upper_body",
	},
}

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_402 NPC Animation Showcase Map ===")
	_test_mapping_lists_all_showcase_animations()
	await _test_showcase_scene_builds_all_animation_slots()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_mapping_lists_all_showcase_animations() -> void:
	var mapping: Dictionary = _load_mapping()
	_assert(not mapping.is_empty(), "NPC visual mapping loads")
	var showcase_paths: Dictionary = Dictionary(mapping.get("animation_showcase_paths", {}))
	_assert(showcase_paths.size() == EXPECTED_ANIMATIONS.size(), "Animation showcase mapping lists exactly 17 clips")
	for animation_id in EXPECTED_ANIMATIONS:
		var animation_path: String = String(showcase_paths.get(animation_id, "")).strip_edges()
		_assert(not animation_path.is_empty(), "Showcase mapping contains %s" % animation_id)
		_assert(ResourceLoader.exists(animation_path), "Showcase animation resource exists for %s" % animation_id)
	var combat_cases: Dictionary = Dictionary(mapping.get("animation_combat_cases", {}))
	_assert(combat_cases.size() == EXPECTED_COMBAT_CASES.size(), "Animation combat mapping lists six imported-clip combat cases")
	for combat_case_id in EXPECTED_COMBAT_CASES.keys():
		var expected_case: Dictionary = Dictionary(EXPECTED_COMBAT_CASES[combat_case_id])
		var combat_case: Dictionary = Dictionary(combat_cases.get(combat_case_id, {}))
		_assert(not combat_case.is_empty(), "Combat mapping contains %s" % combat_case_id)
		var base_animation_id: String = String(combat_case.get("base_animation", "")).strip_edges()
		var upper_animation_id: String = String(combat_case.get("upper_body_pose_animation", "")).strip_edges()
		var pose_track_scope: String = String(combat_case.get("pose_track_scope", "")).strip_edges()
		_assert(base_animation_id == String(expected_case.get("base_animation", "")), "Combat case %s has expected base animation" % combat_case_id)
		_assert(upper_animation_id == String(expected_case.get("upper_body_pose_animation", "")), "Combat case %s has expected shoot overlay animation" % combat_case_id)
		_assert(pose_track_scope == String(expected_case.get("pose_track_scope", "")), "Combat case %s has expected shoot pose track scope" % combat_case_id)
		_assert(showcase_paths.has(base_animation_id), "Combat case %s base animation uses imported showcase clip" % combat_case_id)
		if not upper_animation_id.is_empty():
			_assert(showcase_paths.has(upper_animation_id), "Combat case %s upper-body pose uses imported showcase clip" % combat_case_id)


func _test_showcase_scene_builds_all_animation_slots() -> void:
	var scene := SHOWCASE_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)
	_assert(scene.has_method("get_showcase_snapshot"), "Showcase scene exposes a render/test snapshot")
	var snapshot: Dictionary = Dictionary(scene.call("get_showcase_snapshot")) if scene.has_method("get_showcase_snapshot") else {}
	_assert(int(snapshot.get("expected_animation_count", 0)) == EXPECTED_ANIMATIONS.size(), "Showcase snapshot expects all 17 animations")
	_assert(int(snapshot.get("expected_combat_case_count", 0)) == EXPECTED_COMBAT_CASES.size(), "Showcase snapshot expects six combat animation cases")
	_assert(int(snapshot.get("entry_count", 0)) == EXPECTED_ANIMATIONS.size() + EXPECTED_COMBAT_CASES.size(), "Showcase scene creates raw clips plus combat animation cases")
	var entries: Array = Array(snapshot.get("entries", []))
	for animation_id in EXPECTED_ANIMATIONS:
		var entry: Dictionary = _find_entry(entries, "animation_id", animation_id)
		_assert(not entry.is_empty(), "Showcase snapshot has %s entry" % animation_id)
		_assert(bool(entry.get("animation_loaded", false)), "Showcase entry loads %s into an AnimationPlayer" % animation_id)
		_assert(String(entry.get("label_text", "")) == animation_id, "Showcase entry labels %s directly" % animation_id)
		_assert(String(entry.get("case_type", "")) == "raw", "Showcase entry marks %s as raw imported clip" % animation_id)
		var slot := scene.find_child("AnimationSlot_*_%s" % _sanitize_node_name(animation_id), true, false)
		_assert(slot != null, "Showcase scene has a node for %s" % animation_id)
		if slot != null:
			var label := slot.find_child("AnimationLabel", true, false) as Label3D
			var player := _find_showcase_animation_player(slot)
			_assert(label != null and label.text == animation_id, "Showcase label renders %s" % animation_id)
			_assert(player != null and player.has_animation(animation_id), "Showcase AnimationPlayer owns %s clip" % animation_id)
			_assert(player != null and String(player.current_animation) == animation_id, "Showcase AnimationPlayer plays %s" % animation_id)
	for combat_case_id in EXPECTED_COMBAT_CASES.keys():
		var expected_case: Dictionary = Dictionary(EXPECTED_COMBAT_CASES[combat_case_id])
		var entry: Dictionary = _find_entry(entries, "animation_id", String(combat_case_id))
		_assert(not entry.is_empty(), "Showcase snapshot has combat case %s entry" % combat_case_id)
		_assert(bool(entry.get("animation_loaded", false)), "Showcase combat case %s loads into an AnimationPlayer" % combat_case_id)
		_assert(String(entry.get("label_text", "")) == String(combat_case_id), "Showcase combat case %s label renders directly" % combat_case_id)
		_assert(String(entry.get("case_type", "")) == "combat_case", "Showcase entry marks %s as combat case" % combat_case_id)
		_assert(String(entry.get("base_animation_id", "")) == String(expected_case.get("base_animation", "")), "Showcase combat case %s reports expected base animation" % combat_case_id)
		var expected_upper: String = String(expected_case.get("upper_body_pose_animation", ""))
		var expected_scope: String = String(expected_case.get("pose_track_scope", ""))
		_assert(String(entry.get("upper_body_pose_animation_id", "")) == expected_upper, "Showcase combat case %s reports expected upper-body pose animation" % combat_case_id)
		_assert(String(entry.get("pose_track_scope", "")) == expected_scope, "Showcase combat case %s reports expected pose track scope" % combat_case_id)
		if not expected_upper.is_empty():
			_assert(int(entry.get("shoot_pose_track_override_count", 0)) > 0, "Showcase combat case %s bakes imported shoot pose tracks into the base clip" % combat_case_id)
	_assert(scene.get_node_or_null("SimulationRoot") == null, "Showcase map has no SimulationRoot gameplay authority")
	scene.queue_free()
	await _wait_frames(2)


func _load_mapping() -> Dictionary:
	if not ResourceLoader.exists(NPC_UNIT_VISUAL_MAPPING_PATH):
		return {}
	var file := FileAccess.open(NPC_UNIT_VISUAL_MAPPING_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _find_showcase_animation_player(node: Node) -> AnimationPlayer:
	if node == null:
		return null
	if node is AnimationPlayer and String(node.name) == "ShowcaseAnimationPlayer":
		return node as AnimationPlayer
	for child in node.get_children():
		var found: AnimationPlayer = _find_showcase_animation_player(child)
		if found != null:
			return found
	return null


func _find_entry(entries: Array, key: String, value: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get(key, "")) == value:
			return entry
	return {}


func _sanitize_node_name(value: String) -> String:
	var sanitized: String = value.strip_edges()
	for token in [" ", ".", "/", "\\", ":", ";", ",", "(", ")", "[", "]"]:
		sanitized = sanitized.replace(token, "_")
	return sanitized


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
