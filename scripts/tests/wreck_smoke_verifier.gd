extends SceneTree
const SMOKE := "res://scripts/terrain/wreck_smoke.gd"
var passed := 0
var failed := 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)
func _find(node: Node, wanted: String, found: Array) -> void:
	if node.name == wanted: found.append(node)
	for child in node.get_children(): _find(child, wanted, found)
func _count(node: Node, wanted: String) -> int:
	var found: Array = []
	_find(node, wanted, found)
	return found.size()
func _run() -> void:
	var smoke = load(SMOKE)
	var rules: Dictionary = smoke.load_rules()
	var presets: Dictionary = rules.get("presets", {})
	check(presets.has("grey") and presets.has("black"), "both presets exist")
	var grey: Dictionary = presets.get("grey", {})
	var black: Dictionary = presets.get("black", {})
	check(int(black.get("amount", 0)) > int(grey.get("amount", 0)), "black has more particles than grey")
	check(float(black.get("size_end", 0)) > float(grey.get("size_end", 0)), "black has larger end size")
	var gb := Color(String(grey.get("color_base", "ffffff"))); var bb := Color(String(black.get("color_base", "ffffff")))
	check(bb.get_luminance() < gb.get_luminance(), "black base colour is darker than grey")
	check(int(grey.get("amount", 99)) <= 32 and int(black.get("amount", 99)) <= 64, "particle counts within caps 32 / 64")
	for id in ["grey", "black"]:
		var node: Node3D = smoke.build(id, rules)
		check(node != null and node.name == "WreckSmoke_" + id, "build " + id + " names node")
		var particles: CPUParticles3D = null
		if node != null:
			for child in node.get_children():
				if child is CPUParticles3D: particles = child
		check(particles != null and particles.amount == int(presets[id].amount) and particles.emitting, "build " + id + " has emitting particles with data count")
		if node != null: node.free()
	check(smoke.build("gibtsnicht", rules) == null, "unknown preset returns null")
	check(smoke.preset_for_crash_outcome("explosion") == "black" and smoke.preset_for_crash_outcome("crash") == "grey" and smoke.preset_for_crash_outcome("x") == "", "crash outcome mapping")
	# Real builders: resource wreck and satellite prop each get exactly one grey smoke, also after rebuilds.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/location_resources.json"))
	var site: Dictionary = data.satellite_crash.freighter_wreck_01
	var ore: Dictionary = data.satellite_crash.get("iron_ridge_01", {})
	for round in 2:
		var visual: Node3D = load("res://scripts/terrain/location_resource_visuals.gd").build(site)
		check(_count(visual, "WreckSmoke_grey") == 1, "resource wreck has exactly one smoke, build %d" % (round + 1))
		visual.free()
	if not ore.is_empty():
		var rock: Node3D = load("res://scripts/terrain/location_resource_visuals.gd").build(ore)
		check(_count(rock, "WreckSmoke_grey") == 0, "ore site has no smoke")
		rock.free()
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/satellite_crash_site.json")
	var presentation: Dictionary = map.get_place_presentation()
	for round in 2:
		var stage := Node3D.new(); root.add_child(stage)
		var built: Dictionary = load("res://scripts/terrain/place_reference_dressing.gd").build(stage, presentation)
		check(_count(built.root, "WreckSmoke_grey") == 1, "satellite dressing has exactly one smoke, build %d" % (round + 1))
		stage.free()
	await process_frame
	print("WRECK_SMOKE passed=", passed, " failed=", failed)
	quit(1 if failed else 0)
