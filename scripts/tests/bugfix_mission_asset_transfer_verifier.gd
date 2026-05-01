extends SceneTree

const LIVE_MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_fireteam_dev_test.tscn")
const FRIENDLY_UNIT_MODEL_PATH: String = "res://Assets/kenney_space-kit/Models/GLTF format/astronautA.glb"
const ENEMY_UNIT_MODEL_PATH: String = "res://Assets/kenney_space-kit/Models/GLTF format/astronautB.glb"
const DROPSHIP_MODEL_PATH: String = "res://Assets/kenney_space-kit/3d/craft_speederB.glb"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Mission Asset Transfer Bugfix Verifier ===")
	await _test_live_mission_uses_character_models_for_units()
	await _test_live_dropship_uses_mapping_scale()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_live_mission_uses_character_models_for_units() -> void:
	var scene := LIVE_MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var snapshot: Dictionary = Dictionary(bridge.call("sync_runtime_visuals")) if bridge != null else {}
	var units: Dictionary = Dictionary(snapshot.get("units", {}))
	var friendly_snapshot: Dictionary = Dictionary(units.get("unit_alpha", {}))
	var enemy_snapshot: Dictionary = Dictionary(units.get("enemy_delta", {}))
	var friendly_visual := bridge.get_node_or_null("RuntimeVisual3D/UnitVisuals3D/Unit_unit_alpha") as MeshInstance3D if bridge != null else null
	var enemy_visual := bridge.get_node_or_null("RuntimeVisual3D/UnitVisuals3D/Unit_enemy_delta") as MeshInstance3D if bridge != null else null
	var friendly_model := friendly_visual.get_node_or_null("CharacterModel/Model") as Node3D if friendly_visual != null else null
	var enemy_model := enemy_visual.get_node_or_null("CharacterModel/Model") as Node3D if enemy_visual != null else null
	var friendly_head := friendly_visual.get_node_or_null("Head") as MeshInstance3D if friendly_visual != null else null
	_assert(bool(friendly_snapshot.get("uses_character_model", false)), "Friendly unit snapshot uses the calibrated character model path")
	_assert(String(friendly_snapshot.get("character_model_path", "")) == FRIENDLY_UNIT_MODEL_PATH, "Friendly unit uses astronautA.glb instead of the primitive body")
	_assert(friendly_visual != null and friendly_visual.mesh == null and friendly_model != null, "Friendly unit body is a GLB model, not the old capsule mesh")
	_assert(friendly_head != null and not friendly_head.visible, "Primitive placeholder head is hidden when the character model is active")
	_assert(bool(enemy_snapshot.get("uses_character_model", false)), "Enemy unit snapshot uses a character model")
	_assert(String(enemy_snapshot.get("character_model_path", "")) == ENEMY_UNIT_MODEL_PATH, "Enemy unit uses astronautB.glb instead of the primitive body")
	_assert(enemy_visual != null and enemy_visual.mesh == null and enemy_model != null, "Enemy unit body is a GLB model, not the old capsule mesh")
	scene.queue_free()
	await process_frame


func _test_live_dropship_uses_mapping_scale() -> void:
	var scene := LIVE_MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var lz_marker := scene.get_node_or_null("LZMarker") as CanvasItem
	var dropship_marker := scene.get_node_or_null("DropshipPlanMarker") as CanvasItem
	if lz_marker != null:
		lz_marker.visible = true
		lz_marker.set_meta("task_150_legacy_2d_overlay_visible", true)
		(lz_marker as Node2D).global_position = Vector2(320.0, 180.0)
	if dropship_marker != null:
		dropship_marker.visible = true
		dropship_marker.set_meta("task_150_legacy_2d_overlay_visible", true)
		(dropship_marker as Node2D).global_position = Vector2(180.0, 90.0)
	var snapshot: Dictionary = Dictionary(bridge.call("sync_runtime_visuals")) if bridge != null else {}
	var strategic: Dictionary = Dictionary(snapshot.get("strategic_markers", {}))
	var dropship: Dictionary = Dictionary(strategic.get("dropship", {}))
	var dropship_visual := bridge.get_node_or_null("RuntimeVisual3D/MarkerVisuals3D/Dropship_dropship_marker") as Node3D if bridge != null else null
	var dropship_model := dropship_visual.get_node_or_null("Model") as Node3D if dropship_visual != null else null
	_assert(bool(dropship.get("visible", false)) and dropship_visual != null and dropship_visual.visible, "Live mission still renders the 3D dropship marker")
	_assert(String(dropship.get("model_path", "")) == DROPSHIP_MODEL_PATH, "Dropship marker uses the curated Speeder-B GLB from the 3D mapping")
	_assert(float(dropship.get("scale", 0.0)) >= 1.4, "Dropship marker uses mapping scale instead of the tiny marker scale")
	_assert(dropship_model != null and is_equal_approx(float(dropship_model.get_meta("visual_scale", 0.0)), float(dropship.get("scale", 0.0))), "Dropship model node receives the mapped visual scale")
	scene.queue_free()
	await process_frame


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
