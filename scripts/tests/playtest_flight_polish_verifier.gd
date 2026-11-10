extends SceneTree
const FLIGHT = preload("res://scripts/terrain/mission_flight_visual.gd")
var failures := 0
var checks := 0
func _init() -> void:
	call_deferred("_run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _run() -> void:
	var visual := FLIGHT.new()
	root.add_child(visual)
	visual.configure_cutlass_ref03()
	visual.set_flight_phase("inbound")
	check(visual.get_child_count() == 8, "Four nozzles need luminous core and fading outer jet")
	visual.advance_visual(0.1)
	for child in visual.get_children():
		if child is MeshInstance3D:
			var nozzle_tip: Vector3 = child.position + child.basis.y * (child.mesh.height * 0.5)
			check(nozzle_tip.distance_to(child.get_meta("nozzle_anchor", Vector3.INF)) < 0.001, "Pulsing must stay attached to nozzle mouth")
	check(visual.has_method("sample_maneuver"), "Expose shared read-only landing/departure curve")
	if visual.has_method("sample_maneuver"):
		var lift: Dictionary = visual.sample_maneuver("departing", 0.2)
		check(float(lift.route_fraction) == 0.0 and float(lift.clearance) > 0.5, "Departure lifts clear before forward acceleration")
		var final: Dictionary = visual.sample_maneuver("landing", 0.8)
		check(float(final.route_fraction) == 1.0 and float(final.clearance) > 0.03, "Landing stabilizes over pad before final descent")
		for phase in ["landing", "departing"]:
			var previous: Dictionary = visual.sample_maneuver(phase, 0.0)
			for i in range(1,101):
				var sample: Dictionary = visual.sample_maneuver(phase, float(i)/100.0)
				check(float(sample.route_fraction) >= float(previous.route_fraction), "No reversal in %s" % phase)
				check(absf(float(sample.clearance)-float(previous.clearance)) < 0.3, "Continuous height in %s" % phase)
				previous = sample
	visual.free()
	print("FLIGHT_POLISH %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
