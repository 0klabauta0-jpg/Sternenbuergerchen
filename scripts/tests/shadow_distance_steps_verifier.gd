extends SceneTree
## Schattenweite der Bodenkarten: Stufen zur Kameragroesse mit Hysterese, eine
## Kaskade, kleiner Bias. Kopflos, rechnend.

const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
const HELPER := "shadow_distance_for_size"
const REACH_FACTOR := 2.1
const SWEEP_MAX := 300.0

var _probe = PROFILE.new()
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + label)
		print("FAIL ", label)


func _width(size: float, previous: float) -> float:
	if not _probe.has_method(HELPER):
		return -1.0
	return float(_probe.call(HELPER, size, previous))


func _sizes() -> Array:
	# Genau die Groessen, die das Mausrad erreicht: Start am Minimum, Schritt CAMERA_ZOOM_STEP.
	var sizes: Array = []
	var s: float = VIEW.CAMERA_MIN_SIZE
	while s <= SWEEP_MAX:
		sizes.append(s)
		s += VIEW.CAMERA_ZOOM_STEP
	return sizes


func _run() -> void:
	check(_probe.has_method(HELPER), "Hilfsfunktion %s existiert" % HELPER)
	_check_sweep()
	_check_light()
	_check_view()
	print("SHADOW_DISTANCE_STEPS passed=%d failed=%d" % [checks - failures, failures])
	quit(1 if failures > 0 else 0)


func _check_sweep() -> void:
	var sizes := _sizes()
	var up_state: Array = []
	var previous := 0.0
	var up_changes := 0
	var widths := {}
	for s in sizes:
		var w := _width(s, previous)
		if previous > 0.0 and w != previous:
			up_changes += 1
		previous = w
		up_state.append(w)
		widths[w] = true
	var stage_count := widths.size()
	var reach_ok := true
	for i in sizes.size():
		if up_state[i] < REACH_FACTOR * sizes[i]:
			reach_ok = false
			check(false, "Aufwaerts: Weite %s < 2,1 x S bei S=%s" % [up_state[i], sizes[i]])
			break
	check(reach_ok, "Aufwaerts: Weite >= 2,1 x S fuer alle Radschritte")
	check(stage_count >= 3, "mindestens drei Stufen im Bereich (%d)" % stage_count)
	check(up_changes <= stage_count, "Aufwaerts: Wechsel %d <= Stufen %d" % [up_changes, stage_count])
	var down_state: Array = []
	down_state.resize(sizes.size())
	previous = up_state[sizes.size() - 1]
	var down_changes := 0
	var down_reach_ok := true
	for i in range(sizes.size() - 1, -1, -1):
		var w := _width(sizes[i], previous)
		if w != previous:
			down_changes += 1
		previous = w
		down_state[i] = w
		if w < REACH_FACTOR * sizes[i]:
			down_reach_ok = false
	check(down_reach_ok, "Abwaerts: Weite >= 2,1 x S fuer alle Radschritte")
	check(down_changes <= stage_count, "Abwaerts: Wechsel %d <= Stufen %d" % [down_changes, stage_count])
	# Hysterese: ein Schritt weg und zurueck aendert die Weite hoechstens beim Hinweg.
	var bounce_ok := true
	for i in sizes.size():
		for direction in [1, -1]:
			var j: int = i + direction
			if j < 0 or j >= sizes.size():
				continue
			var start: float = up_state[i] if direction == 1 else down_state[i]
			var out := _width(sizes[j], start)
			var back := _width(sizes[i], out)
			if back != out:
				bounce_ok = false
				check(false, "Hysterese: Wechsel beim Zurueck bei S=%s -> %s -> %s (%s, %s, %s)" % [sizes[i], sizes[j], sizes[i], start, out, back])
	check(bounce_ok, "Hin und zurueck ueber eine Stufengrenze wechselt die Weite nur einmal")
	# Innerhalb einer Stufe aendert sich die Weite nie: gleiche Eingaben, gleiche Weite, egal wie oft.
	var steady := _width(20.0, 0.0)
	for k in 10:
		steady = _width(20.0, steady)
	check(is_equal_approx(steady, _width(20.0, 0.0)), "gleiche Groesse bleibt auf gleicher Weite")
	var table := ""
	for stage in widths.keys():
		table += " %s" % stage
	print("STUFEN_WEITEN", table)


func _check_light() -> void:
	for homebase in [false, true]:
		var profile = PROFILE.new()
		profile.homebase_palette = homebase
		var light := DirectionalLight3D.new()
		profile.apply_light(light)
		var tag := "Licht (homebase=%s)" % homebase
		check(light.directional_shadow_mode == DirectionalLight3D.SHADOW_ORTHOGONAL, tag + ": eine Kaskade")
		check(is_equal_approx(light.directional_shadow_fade_start, 0.95), tag + ": fade_start 0,95")
		check(is_equal_approx(light.shadow_normal_bias, 0.25), tag + ": Normal-Bias 0,25")
		check(is_equal_approx(light.shadow_bias, 0.04), tag + ": Bias 0,04")
		light.free()
	var quiet = PROFILE.new()
	quiet.quiet_tactical_surface = true
	var quiet_light := DirectionalLight3D.new()
	quiet.apply_light(quiet_light)
	check(is_equal_approx(quiet_light.shadow_normal_bias, 0.25), "Licht (ruhige Taktikflaeche): Normal-Bias 0,25")
	quiet_light.free()


func _check_view() -> void:
	root.size = Vector2i(1280, 720)
	for homebase in [true, false]:
		var host := Node2D.new()
		root.add_child(host)
		var view = VIEW.new()
		view.name = "Primary3DView"
		host.add_child(view)
		view.set_process(false)
		view.call("set_frontier_art_enabled", true)
		if homebase:
			view.call("set_homebase_visuals_enabled", true)
		var tag := "Ansicht (Heimatbasis=%s)" % homebase
		# Erst klein (Stufe 60), dann Heimatbasis-Groesse 26: bleibt in Stufe 60.
		view.set("_camera_size", 20.0)
		view.call("_update_camera_transform")
		view.set("_camera_size", 26.0)
		view.call("_update_camera_transform")
		var light := _view_light(view)
		check(light != null, tag + ": Licht vorhanden")
		if light == null:
			host.free()
			continue
		check(light.directional_shadow_mode == DirectionalLight3D.SHADOW_ORTHOGONAL, tag + ": Licht mit einer Kaskade")
		var near_width: float = light.directional_shadow_max_distance
		check(near_width >= REACH_FACTOR * 26.0, tag + ": Weite bei S 26 reicht (%s)" % near_width)
		check(is_equal_approx(near_width, _width(26.0, _width(20.0, 0.0))), tag + ": Weite bei S 26 = Hilfsfunktion (%s)" % near_width)
		var steps := -(100.0 - 26.0) / VIEW.CAMERA_ZOOM_STEP
		view.zoom_camera(steps)
		var far_size: float = view.get_camera_size()
		var far_width: float = light.directional_shadow_max_distance
		check(far_size > 90.0, tag + ": weit herausgezoomt (S=%s)" % far_size)
		check(far_width >= REACH_FACTOR * far_size, tag + ": Weite weit draussen reicht (%s bei S=%s)" % [far_width, far_size])
		check(far_width > near_width, tag + ": Weite waechst beim Herauszoomen")
		check(is_equal_approx(far_width, _width(far_size, near_width)), tag + ": Weite weit draussen = Hilfsfunktion")
		view.zoom_camera(-steps)
		var back_width: float = light.directional_shadow_max_distance
		check(back_width >= REACH_FACTOR * view.get_camera_size(), tag + ": Weite nach Rueckzoom reicht")
		host.free()


func _view_light(view) -> DirectionalLight3D:
	var world_root = view.get("_world_root")
	if world_root == null:
		return null
	return world_root.get_node_or_null(VIEW.LIGHT_NAME) as DirectionalLight3D
