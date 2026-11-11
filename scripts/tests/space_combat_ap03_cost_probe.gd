extends SceneTree
## Bounded cost observation, not an FPS or performance acceptance.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const NAV = preload("res://scripts/tactical/space_navigation_resolver.gd")

func _initialize() -> void:
	var failed := 0
	for kind in ["light", "large"]:
		var footprint: Array = [Vector2i.ZERO] if kind == "light" else [Vector2i.ZERO, Vector2i(1,0), Vector2i(2,0)]
		var start := GRID.HEX.axial_to_plane(Vector2(100,100))
		var actors: Array[Dictionary] = [{"craft_id":kind,"position_plane":start,"heading_rad":0.0,"footprint_hexes":footprint}]
		var moves: Array[Dictionary] = [{"craft_id":kind,"position_plane":start + Vector2(0.05,0.0),"heading_rad":0.05}]
		var samples: Array[int] = []
		for i in range(25):
			var started := Time.get_ticks_usec()
			var result: Dictionary = NAV.resolve_motion(actors, moves, {})
			samples.append(Time.get_ticks_usec() - started)
			if not result.get("ok",false) or not result.accepted.has(kind): failed += 1
		samples.sort()
		print("SPACE_SWEEP_COST ", kind, " p50_us=", samples[12], " p95_us=", samples[23], " max_us=", samples[24])
	print("SPACE_COMBAT_AP03_COST failed=", failed)
	quit(1 if failed else 0)
