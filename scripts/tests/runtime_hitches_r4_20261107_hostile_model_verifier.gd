extends SceneTree
## Real-resource presentation fixture. No physical combat, visibility or FPS claim.
const VIEW: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const UNIT: GDScript = preload("res://scripts/npc/test_unit.gd")
var passed := 0
var failed := 0

class MissingAssetView extends "res://scripts/terrain/terrain_map_3d_view.gd":
	func _get_unit_model_scene(_unit: Node, _entry: Dictionary) -> PackedScene:
		return null
	func _uses_strict_3d_asset_mapping() -> bool:
		return true

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view: Node = VIEW.new()
	root.add_child(view)
	var map_data: RefCounted = MAP.call("create_empty", "r4_hostile_identity", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2)
	view.call("configure_from_map", map_data)
	var units: Array = []
	for spec in [
		["enemy_delta", "team_bravo", ""],
		["ground_defense_01", "team_bravo", "enemy_space_suit_orange"],
		["r4_friendly_control", "team_alpha", "friendly_space_suit_white"],
	]:
		var unit: Node2D = UNIT.new()
		unit.name = String(spec[0])
		unit.set("unit_id", String(spec[0]))
		unit.set("display_name", String(spec[0]))
		unit.set("team_id", String(spec[1]))
		unit.set("weapon_1_id", "rifle")
		unit.set("weapon_2_id", "none")
		if not String(spec[2]).is_empty():
			unit.set_meta("visual_archetype_id", String(spec[2]))
		root.add_child(unit)
		unit.position = Vector2(96.0 + units.size() * 48.0, 128.0)
		units.append(unit)
	view.call("set_unit_nodes", units)
	await frames(12)
	var actor_before := actor_state(units)
	var identities := {}
	for unit in units:
		var id: String = String(unit.call("get_unit_id"))
		var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get(id) as Node3D
		check(proxy != null and bool(proxy.get_meta("uses_animated_character_model", false)), id + " resolves its actual animated character")
		if proxy == null:
			continue
		var model: Node3D = view.call("_find_unit_model_root", proxy) as Node3D
		var weapon: Node3D = view.call("_find_unit_blaster_visual_node", proxy) as Node3D
		check(model != null and model.is_visible_in_tree(), id + " keeps a real visible human model")
		check(weapon != null and bool(proxy.get_meta("unit_animation_player_available", false)), id + " retains its actual attachment and animation path")
		var core: Node3D = proxy.get_node_or_null("UnitBodyReadabilityCore") as Node3D
		check(core == null or not core.visible, id + " never overlays a successful human model with an upright pill core")
		check(bool(proxy.get_meta("unit_team_base_visible", false)) and float(proxy.get_meta("unit_team_base_radius", 0.0)) > 0.0, id + " retains its existing visible team ground ring")
		identities[id] = {"proxy": proxy.get_instance_id(), "model": model.get_instance_id() if model != null else 0, "weapon": weapon.get_instance_id() if weapon != null else 0}
	await frames(4)
	for unit in units:
		var id: String = String(unit.call("get_unit_id"))
		var proxy: Node3D = Dictionary(view.get("_unit_proxies_by_id")).get(id) as Node3D
		if proxy == null or not identities.has(id):
			continue
		var model: Node3D = view.call("_find_unit_model_root", proxy) as Node3D
		var weapon: Node3D = view.call("_find_unit_blaster_visual_node", proxy) as Node3D
		check(model != null and weapon != null and {"proxy": proxy.get_instance_id(), "model": model.get_instance_id(), "weapon": weapon.get_instance_id()} == identities[id], id + " reuses original model and weapon through ordinary visual sync")
	check(actor_state(units) == actor_before, "Visual sync preserves actor identity, position, health, vital state and runtime values")
	var missing: Node = MissingAssetView.new()
	root.add_child(missing)
	missing.call("configure_from_map", map_data)
	missing.call("set_unit_nodes", [units[0]])
	await frames(4)
	var fallback: Node3D = Dictionary(missing.get("_unit_proxies_by_id")).get("enemy_delta") as Node3D
	check(fallback != null and bool(fallback.get_meta("missing_unit_model", false)), "Explicit missing-model boundary keeps the diagnostic missing-model state")
	if fallback != null:
		check(fallback.find_child("MissingAsset_unit_model_*", true, false) != null, "Missing asset still has its existing visible diagnostic marker")
		var core: Node3D = fallback.get_node_or_null("UnitBodyReadabilityCore") as Node3D
		check(core != null and core.visible, "Explicit missing-model emergency readability remains separate from normal humanoids")
	check(actor_state(units) == actor_before, "Missing-asset presentation does not mutate real actor data")
	missing.queue_free()
	view.queue_free()
	for unit in units:
		unit.queue_free()
	await frames(2)
	print("R4_HOSTILE_MODEL: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_HOSTILE_MODEL_PASS")
	quit(1 if failed else 0)

func actor_state(units: Array) -> Dictionary:
	var result := {}
	for unit in units:
		result[String(unit.call("get_unit_id"))] = {"team": unit.call("get_team_id"), "position": unit.position, "health": unit.call("get_health"), "vital": unit.call("get_vital_state"), "runtime": unit.call("get_runtime_status").call("to_dict")}
	return result

func frames(count: int) -> void:
	for _frame in range(count):
		await process_frame

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", message)
