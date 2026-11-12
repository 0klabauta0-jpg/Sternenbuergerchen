extends SceneTree
const ADAPTER = preload("res://scripts/mission/air_support_ground_adapter.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")

class Actor extends Node2D:
	var id := ""
	func get_unit_id() -> String: return id
	func apply_damage(_amount: int, _context: Dictionary = {}) -> bool: return true

func _initialize() -> void:
	var terrain := TERRAIN.new(); root.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO, 64, 32, "hex_axial_v1")
	terrain.register_tile(TILE.new({"tile_id":"origin", "grid_position":Vector2i.ZERO, "explicit_hex_ramps":true}))
	var units := UNITS.new(); root.add_child(units)
	var first := Actor.new(); first.id = "b"; root.add_child(first); units.register_unit(first.id, first)
	var second := Actor.new(); second.id = "a"; root.add_child(second); units.register_unit(second.id, second)
	assert(ADAPTER.registry(false, null, terrain) == terrain)
	assert(ADAPTER.unit_grid(first, terrain) == Vector2i.ZERO)
	assert(ADAPTER.occupant(Vector2i.ZERO, terrain, units).unit_id == "a")
	second.set_meta("dropship_embarked", true)
	assert(ADAPTER.occupant(Vector2i.ZERO, terrain, units).unit_id == "b")
	first.position = Vector2(100000, 100000)
	assert(ADAPTER.unit_grid(first, terrain) == null and ADAPTER.occupant(Vector2i.ZERO, terrain, units).unit_id.is_empty())
	first.free(); second.free(); units.free(); terrain.free()
	print("AIR_SUPPORT_LEGACY_GROUND_ADAPTER passed")
	quit()
