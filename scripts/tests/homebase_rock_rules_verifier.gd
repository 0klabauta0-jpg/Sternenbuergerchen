extends SceneTree
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const NAV = preload("res://scripts/meta/base_interior_navigation.gd")
const RULES = preload("res://scripts/terrain/homebase_rock_rules.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const LOS = preload("res://scripts/core/los_system.gd")
const COVER = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
var failed := 0
var passed := 0
func _init() -> void: call_deferred("run")
func check(value: bool, description: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS: " if value else "FAIL: ") + description)
func run() -> void:
	var coarse = MAP.load_from_file("res://maps/campaign_intro_base.json")
	RULES.apply_coarse(coarse)
	var fine = NAV.load_map("res://maps/campaign_intro_base.json")
	for group in RULES.formations():
		var center: Vector2i = group.center
		var high = coarse.get_tile_at_grid(center)
		check(not high.walkable and high.blocks_los and high.object_height == 2, "coarse central rock owns height and LOS %s" % center)
		var high_fine = fine.get_tile_at_grid(center * 4)
		check(not high_fine.walkable and high_fine.blocks_los and high_fine.object_height == 2, "fine center matches coarse %s" % center)
		for side: Vector2i in group.sides:
			var low = coarse.get_tile_at_grid(side)
			var low_fine = fine.get_tile_at_grid(side * 4)
			check(low.walkable and not low.blocks_los and low.object_height == 1 and low.cover_value == 60, "coarse side supplies partial cover %s" % side)
			check(low_fine.walkable and not low_fine.blocks_los and low_fine.cover_value == 60, "fine side supplies partial cover %s" % side)
		var registry: Node = REGISTRY.new()
		registry.configure_iso_grid(coarse.get_grid_origin(), 64.0, 32.0, "hex_axial_v1")
		for q in range(center.x - 4, center.x + 5):
			for r in range(center.y - 4, center.y + 5):
				var tile = coarse.get_tile_at_grid(Vector2i(q, r))
				if tile != null: registry.register_tile(tile)
		var los = LOS.new()
		check(not los.has_line_of_sight_between_points(registry.grid_to_world(center + Vector2i(0, -2)), registry.grid_to_world(center + Vector2i(0, 2)), -1.0, registry), "actual LOS blocks across central rock %s" % center)
		for side: Vector2i in group.sides:
			check(los.has_line_of_sight_between_points(registry.grid_to_world(side + Vector2i(0, -1)), registry.grid_to_world(side + Vector2i(0, 1)), -1.0, registry), "low side does not fully occlude LOS %s" % side)
		registry.free()
		var fine_registry: Node = REGISTRY.new()
		fine_registry.configure_iso_grid(fine.get_grid_origin(), 16.0, 8.0, "hex_axial_v1")
		var fine_center := center * 4
		for q in range(fine_center.x - 4, fine_center.x + 5):
			for r in range(fine_center.y - 4, fine_center.y + 5):
				var fine_tile = fine.get_tile_at_grid(Vector2i(q, r))
				if fine_tile != null: fine_registry.register_tile(fine_tile)
		check(not los.has_line_of_sight_between_points(fine_registry.grid_to_world(fine_center + Vector2i(0, -4)), fine_registry.grid_to_world(fine_center + Vector2i(0, 4)), -1.0, fine_registry), "fine runtime LOS blocks across central rock %s" % center)
		fine_registry.free()
	check(COVER._resolve_cover_state(60) == "partial_cover", "combat resolves neighbor cover as partial")
	print("HOMEBASE_ROCK_RULES: %d passed, %d failed" % [passed, failed])
	if failed == 0: print("HOMEBASE_ROCK_RULES_PASS")
	quit(0 if failed == 0 else 1)
