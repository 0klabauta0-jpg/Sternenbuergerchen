extends SceneTree
class Terrain extends Node:
	func get_grid_topology() -> String: return "hex_axial_v1"
	func get_revision() -> int: return 1
	func is_walkable(_p: Vector2i) -> bool: return true
	func get_tile_at_grid(_p: Vector2i): return Tile.new()
	func get_legal_hex_neighbors(_p: Vector2i) -> Array: return []
class Tile extends RefCounted:
	func is_valid() -> bool: return true
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var access = load("res://scripts/mission/polisa_globe_access.gd")
	if access == null: printerr("FAIL: access helper missing"); quit(1); return
	var terrain := Terrain.new()
	var ground := {"units_by_id":{},"occupant_by_grid":{},"terrain_revision":1}
	var anchor := Vector2i(35,-69)
	if not access.has_method("find_spawn"): printerr("FAIL: resident spawn finder missing"); terrain.free(); quit(1); return
	var resident: Dictionary = access.find_spawn(anchor, terrain, ground)
	if not resident.ok or not resident.spawn_grid is Vector2i: printerr("FAIL: resident spawn"); terrain.free(); quit(1); return
	var denied: Dictionary = access.resolve("other", anchor, [{"unit_id":"a","grid":anchor,"fit":true}], terrain, ground)
	if denied.ok: printerr("FAIL: wrong location"); quit(1); return
	var accepted: Dictionary = access.resolve("polisa", anchor, [{"unit_id":"a","grid":anchor,"fit":true}], terrain, ground)
	if not accepted.ok or accepted.unit_id != "a" or not accepted.spawn_grid is Vector2i: printerr("FAIL: expected local candidate"); quit(1); return
	var hex = load("res://scripts/terrain/hex_grid.gd")
	if hex.distance(accepted.spawn_grid, anchor) < 3: printerr("FAIL: spawn must clear the globe"); quit(1); return
	if access.resolve("polisa", anchor, [{"unit_id":"a","grid":anchor + Vector2i(20,0),"fit":true}], terrain, ground).ok: printerr("FAIL: distant candidate"); quit(1); return
	if access.resolve("polisa", anchor, [{"unit_id":"a","grid":anchor,"fit":false}], terrain, ground).ok: printerr("FAIL: unfit candidate"); quit(1); return
	terrain.free()
	print("PASS: globe access gates")
	quit(0)
