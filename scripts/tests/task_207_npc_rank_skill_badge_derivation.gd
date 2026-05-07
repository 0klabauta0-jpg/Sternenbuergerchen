extends SceneTree

const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const META_UNIT_PROFILE_BUILDER_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile_builder.gd")
const NPC_COMPACT_CARD_SCRIPT: GDScript = preload("res://scripts/meta/npc_compact_card.gd")
const NPC_META_CARD_SCRIPT: GDScript = preload("res://scripts/meta/npc_meta_card.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const RANK_CATALOG_PATH: String = "res://data/rank_particle_asset_catalog.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_207 NPC Rank Skill Badge Derivation ===")
	_test_catalog_badge_assets_are_loadable()
	_test_top_three_badge_derivation_is_deterministic()
	_test_role_weapon_and_skill_badges()
	await _test_ui_badge_binding_and_missing_asset_fallback()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_catalog_badge_assets_are_loadable() -> void:
	var catalog: Dictionary = _load_json(RANK_CATALOG_PATH)
	_assert(not catalog.is_empty(), "Rank particle catalog is loadable")
	var badge_ids: PackedStringArray = PackedStringArray()
	for badge_variant in Array(catalog.get("badges", [])):
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		var badge_id: String = String(badge.get("id", "")).strip_edges()
		if badge_id.is_empty():
			continue
		badge_ids.append(badge_id)
		_assert(ResourceLoader.exists(String(badge.get("path", ""))), "Badge asset is loadable: %s" % badge_id)
	for required_id in ["badge_role_medic", "badge_role_rifle", "badge_role_heavy", "badge_role_pilot", "badge_role_engineer", "badge_role_ftl"]:
		_assert(badge_ids.has(required_id), "Catalog exposes %s" % required_id)


func _test_top_three_badge_derivation_is_deterministic() -> void:
	var profile = _build_profile({
		"unit_id": "badge_top3",
		"display_name": "Top Three",
		"role_id": "combat_medic",
		"role_name": "Combat Medic",
		"weapon_1": "medictool",
		"weapon_2": "rail_gun",
		"skill_accuracy": 0.92,
		"skill_leadership": 0.88,
		"is_fireteam_lead": true,
	})
	var badges_a: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", profile))
	var badges_b: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", profile))
	_assert(badges_a.size() == 3, "Resolver caps primary badges at three")
	_assert(_badge_keys(badges_a) == _badge_keys(badges_b), "Badge selection is deterministic")
	_assert(_has_badge_key(badges_a, "medic"), "Medic role/loadout yields Medic badge")
	_assert(_has_badge_key(badges_a, "leader"), "Fireteam lead/leadership yields Leader badge")
	_assert(_has_badge_key(badges_a, "heavy"), "Heavy weapon yields Heavy badge")
	_assert(_all_badges_have_paths(badges_a), "Derived badges carry catalog asset paths")


func _test_role_weapon_and_skill_badges() -> void:
	var sniper_profile = _build_profile({
		"unit_id": "badge_sniper",
		"role_id": "marksman",
		"role_name": "Marksman",
		"weapon_1": "sniper",
		"skill_accuracy": 0.91,
	})
	var sniper_badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", sniper_profile))
	_assert(_has_badge_key(sniper_badges, "shooter"), "Sniper/rifle loadout yields Shooter badge")

	var pilot_profile = _build_profile({
		"unit_id": "badge_pilot",
		"role_id": "security_guard",
		"role_name": "Deck Pilot",
		"dropship_piloting": 0.91,
		"weapon_1": "smg",
	})
	var pilot_badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", pilot_profile))
	_assert(_has_badge_key(pilot_badges, "pilot"), "Strong platform value yields Pilot badge")

	var engineer_profile = _build_profile({
		"unit_id": "badge_engineer",
		"role_id": "combat_engineer",
		"role_name": "Combat Engineer",
		"weapon_1": "rifle",
	})
	var engineer_badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", engineer_profile))
	_assert(_has_badge_key(engineer_badges, "engineer"), "Engineer source role yields Engineer badge even after normalized role mapping")

	var enemy_profile = _build_profile({
		"unit_id": "badge_enemy",
		"team_id": "team_bravo",
		"role_id": "security_guard",
		"weapon_1": "rifle",
	})
	var enemy_badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", enemy_profile))
	_assert(_has_badge_key(enemy_badges, "enemy"), "Enemy team receives a small enemy readability badge")


func _test_ui_badge_binding_and_missing_asset_fallback() -> void:
	var profile = _build_profile({
		"unit_id": "badge_ui",
		"display_name": "Badge UI",
		"role_id": "combat_medic",
		"role_name": "Combat Medic",
		"weapon_1": "medictool",
		"weapon_2": "rifle",
	})

	var compact_card := NPC_COMPACT_CARD_SCRIPT.new() as Control
	root.add_child(compact_card)
	compact_card.call("setup_from_profile", profile, {"compact_mode": true, "drag_enabled": false})
	await process_frame
	_assert(_count_nodes_with_prefix(compact_card, "RankBadge_") > 0, "FOB/#17 compact card renders derived badge icons")

	var meta_card := NPC_META_CARD_SCRIPT.new() as Control
	root.add_child(meta_card)
	meta_card.call("setup_from_profile", profile)
	await process_frame
	_assert(_count_nodes_with_prefix(meta_card, "RankBadge_") > 0, "Homebase/roster meta card renders derived badge icons")

	var host := VBoxContainer.new()
	root.add_child(host)
	CHARACTER_SHEET_VIEW_SCRIPT.call("render", host, profile)
	await process_frame
	_assert(_count_nodes_with_prefix(host, "RankBadge_") > 0, "Character sheet renders derived badge icons")

	var missing_profile = META_UNIT_PROFILE_SCRIPT.new({
		"unit_id": "missing_badge_ui",
		"display_name": "Missing Badge",
		"rank_badges": [{
			"badge_key": "missing",
			"badge_id": "badge_missing_probe",
			"label": "Missing",
			"path": "res://Assets/curated/kenney/ranks/missing_badge_probe.png",
			"reason": "diagnostic fallback",
		}],
	})
	var missing_card := NPC_COMPACT_CARD_SCRIPT.new() as Control
	root.add_child(missing_card)
	missing_card.call("setup_from_profile", missing_profile, {"compact_mode": true, "drag_enabled": false})
	await process_frame
	_assert(_count_nodes_with_meta(missing_card, "missing_rank_badge_asset") == 1, "Missing badge asset renders a diagnostic fallback node")

	compact_card.queue_free()
	meta_card.queue_free()
	host.queue_free()
	missing_card.queue_free()
	await process_frame


func _build_profile(data: Dictionary):
	return META_UNIT_PROFILE_BUILDER_SCRIPT.call("build_from_identity_config", data)


func _badge_keys(badges: Array) -> PackedStringArray:
	var result: PackedStringArray = []
	for badge_variant in badges:
		if typeof(badge_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(badge_variant).get("badge_key", "")))
	return result


func _has_badge_key(badges: Array, badge_key: String) -> bool:
	return _badge_keys(badges).has(badge_key)


func _all_badges_have_paths(badges: Array) -> bool:
	for badge_variant in badges:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			return false
		var badge: Dictionary = Dictionary(badge_variant)
		var path: String = String(badge.get("path", "")).strip_edges()
		if path.is_empty() or not ResourceLoader.exists(path):
			return false
	return true


func _count_nodes_with_prefix(node: Node, prefix: String) -> int:
	var count: int = 1 if String(node.name).begins_with(prefix) else 0
	for child in node.get_children():
		count += _count_nodes_with_prefix(child, prefix)
	return count


func _count_nodes_with_meta(node: Node, meta_name: String) -> int:
	var count: int = 1 if node.has_meta(meta_name) else 0
	for child in node.get_children():
		count += _count_nodes_with_meta(child, meta_name)
	return count


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
