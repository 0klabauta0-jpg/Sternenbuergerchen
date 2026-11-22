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
## Smoke must sit between 60 % and 100 % of the model's height range (below the top, inside the upper part); prints measured values.
func _exit_ok(holder: Node3D, label: String) -> bool:
	var found: Array = []
	_find(holder, "WreckSmoke_grey", found)
	if found.size() != 1: return false
	var smoke: Node3D = found[0]
	var parent: Node3D = smoke.get_parent()
	var lo := INF; var hi := -INF
	var model: Node = null
	for c in parent.get_children():
		if c == smoke: continue
		if "satellite_wreck" in String(c.scene_file_path): model = c; break
		if model == null and label == "wreck": model = c
	if model == null: return false
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.mesh != null and not (n is CPUParticles3D) and not smoke.is_ancestor_of(n):
			var t := Transform3D.IDENTITY; var w: Node = n
			while w != null and w != parent:
				if w is Node3D: t = (w as Node3D).transform * t
				w = w.get_parent()
			var box: AABB = t * n.mesh.get_aabb()
			lo = minf(lo, box.position.y); hi = maxf(hi, box.end.y)
		for c in n.get_children(): stack.append(c)
	print("EXIT_HEIGHT ", label, " smoke_y=", snappedf(smoke.position.y, 0.01), " model_y=[", snappedf(lo, 0.01), ", ", snappedf(hi, 0.01), "]")
	return hi > lo and smoke.position.y <= hi and smoke.position.y >= lo + 0.6 * (hi - lo)
func _behaviour(smoke, rules: Dictionary) -> void:
	for id in ["grey", "black"]:
		var node: Node3D = smoke.build(id, rules)
		var parts: CPUParticles3D = node.get_child(0)
		var mat := parts.mesh.material as StandardMaterial3D
		check(parts.direction.y > 0.9 and parts.gravity.y >= 0.0, id + " rises upward, gravity not downward")
		check(mat != null and mat.billboard_mode == BaseMaterial3D.BILLBOARD_PARTICLES and mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, id + " material billboard unshaded alpha")
		check(mat != null and mat.vertex_color_use_as_albedo and mat.vertex_color_is_srgb, id + " vertex colours are sRGB")
		var rise: float = float(rules.presets[id].speed) * float(rules.presets[id].lifetime)
		check(rise >= (2.0 if id == "grey" else 4.0) and rise <= (3.0 if id == "grey" else 5.0), id + " rise height in range (%.2f)" % rise)
		node.free()
	check(smoke.build("kaputt", {"presets": {"kaputt": {"amount": 5}}}) == null, "incomplete preset returns null")
	check(smoke.load_rules("res://data/fx/gibt_es_nicht.json").is_empty(), "missing rules file gives empty dictionary")
	var bad := FileAccess.open("user://wreck_smoke_bad.json", FileAccess.WRITE); bad.store_string("{ kaputt"); bad.close()
	check(smoke.load_rules("user://wreck_smoke_bad.json").is_empty(), "broken rules file gives empty dictionary")
	var parent := Node3D.new(); var model := Node3D.new(); model.position = Vector3(3, 0, 4); parent.add_child(model)
	var box := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(1, 2, 1); box.mesh = bm; box.position = Vector3(0, 1, 0); model.add_child(box)
	var attached: Node3D = smoke.attach_to(model, parent, "grey")
	check(attached != null and attached.get_parent() == parent and attached.name == "WreckSmoke_grey", "attach_to hangs smoke under parent")
	if attached != null:
		check(attached.position.y >= 1.6 and attached.position.y <= 2.0, "smoke exits just below model top (y=%.2f)" % attached.position.y)
		check(absf(attached.position.x - 3.0) < 0.01 and absf(attached.position.z - 4.0) < 0.01, "smoke centred over model")
	var empty := Node3D.new(); empty.position = Vector3(1, 0, 2); parent.add_child(empty)
	var fb: Node3D = smoke.attach_to(empty, parent, "grey")
	check(fb != null and absf(fb.position.y - 1.2) < 0.01 and absf(fb.position.x - 1.0) < 0.01, "meshless model uses fallback height")
	check(smoke.attach_to(model, parent, "grey", "user://wreck_smoke_bad.json") == null, "attach_to with broken data returns null")
	check(smoke.attach_to(model, parent, "gibtsnicht") == null, "attach_to unknown preset returns null")
	parent.free()
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
	_behaviour(smoke, rules)
	# Real builders: resource wreck and satellite prop each get exactly one grey smoke, also after rebuilds.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/location_resources.json"))
	var site: Dictionary = data.satellite_crash.freighter_wreck_01
	var ore: Dictionary = data.satellite_crash.get("iron_ridge_01", {})
	for round in 2:
		var visual: Node3D = load("res://scripts/terrain/location_resource_visuals.gd").build(site)
		check(_count(visual, "WreckSmoke_grey") == 1, "resource wreck has exactly one smoke, build %d" % (round + 1))
		check(_exit_ok(visual, "wreck"), "resource wreck smoke exits at model top, build %d" % (round + 1))
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
		check(_exit_ok(built.root, "satellite"), "satellite smoke exits at model top, build %d" % (round + 1))
		stage.free()
	await process_frame
	print("WRECK_SMOKE passed=", passed, " failed=", failed)
	quit(1 if failed else 0)
