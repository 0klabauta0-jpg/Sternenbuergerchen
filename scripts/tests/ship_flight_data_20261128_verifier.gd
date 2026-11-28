extends SceneTree
## Flugdaten fuer Transporter und Frachter (28.11.2026, Paket RE Punkt 6, Entscheidung 8): Valkyrie und Vanguard (Transporter),
## Hercules (Frachter) haben ein vollstaendiges Flugprofil und eine gueltige Standardbestueckung; Cutlass und Buccaneer bleiben unveraendert.
const CATALOG = preload("res://scripts/mission/space_component_catalog.gd")
const WARP = preload("res://scripts/mission/ship_equipment_catalog.gd")
const NEW_MODELS := ["valkyrie", "vanguard", "hercules"]
var checks := 0
var failures := 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)
	else:
		print("PASS: ", label)
func _positive(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) > 0.0
func _run() -> void:
	check(not CATALOG.definition().is_empty() and not WARP.definition().is_empty(), "Beide Flugdaten-Dateien lassen sich lesen")
	for model_id: String in NEW_MODELS + ["cutlass", "buccaneer"]:
		var profile: Dictionary = WARP.flight_profile(model_id)
		var complete := true
		for key in ["mass", "main_thrust", "reverse_thrust", "side_thrust", "turn_acceleration", "thrust_fraction"]:
			if not _positive(profile.get(key)): complete = false
		check(complete and float(profile.get("thrust_fraction", 2.0)) <= 1.0, "%s: Flugprofil vollstaendig und gueltig" % model_id)
		var footprint: Array = Array(profile.get("footprint_hexes", []))
		check(not footprint.is_empty() and footprint.size() <= 64 and footprint.has([0, 0]), "%s: Footprint enthaelt den Ursprung" % model_id)
		var loadout: Dictionary = CATALOG.default_loadout(model_id)
		check(CATALOG.validate_loadout(model_id, loadout).get("ok", false), "%s: Standardbestueckung ist gueltig" % model_id)
		var inputs: Dictionary = CATALOG.flight_inputs(model_id, loadout)
		check(inputs.get("ok", false) and _positive(inputs.get("mass")) and float(Dictionary(inputs.get("power", {})).get("thrust_fraction", 0.0)) > 0.0, "%s: Flugwerte aus Bestueckung ableitbar" % model_id)
		var stats: Dictionary = CATALOG.effective_stats(model_id, loadout)
		check(stats.get("ok", false) and not Array(stats.get("weapons", [])).is_empty(), "%s: Kampfwerte ableitbar" % model_id)
	# Vorhandene Werte bleiben unveraendert (nur angehaengt).
	var cutlass: Dictionary = WARP.flight_profile("cutlass")
	check(is_equal_approx(float(cutlass.mass), 1.0) and is_equal_approx(float(cutlass.main_thrust), 2.0) and is_equal_approx(float(cutlass.reverse_thrust), 1.0) and is_equal_approx(float(cutlass.side_thrust), 1.2) and is_equal_approx(float(cutlass.turn_acceleration), 0.6), "Cutlass-Flugwerte unveraendert")
	var buccaneer: Dictionary = WARP.flight_profile("buccaneer")
	check(is_equal_approx(float(buccaneer.mass), 1.0) and is_equal_approx(float(buccaneer.main_thrust), 2.8) and is_equal_approx(float(buccaneer.turn_acceleration), 1.1), "Buccaneer-Flugwerte unveraendert")
	var cutlass_slots: Dictionary = CATALOG.default_loadout("cutlass")
	check(cutlass_slots.size() == 6 and String(cutlass_slots.get("power", "")) == "power_s2" and is_equal_approx(float(Dictionary(CATALOG.definition().models.cutlass).flight_demand), 1.0), "Cutlass-Bestueckung unveraendert")
	# Orientierung: Transporter/Frachter sind traeger als die Buccaneer (Jaeger), der Frachter traegt am meisten.
	check(float(WARP.flight_profile("hercules").mass) > float(WARP.flight_profile("valkyrie").mass) and float(WARP.flight_profile("valkyrie").main_thrust) < float(buccaneer.main_thrust), "Frachter schwerer als Transporter, Transporter traeger als der Jaeger")
	print("SHIP_FLIGHT_DATA checks=%d failures=%d passed=%d" % [checks, failures, checks - failures])
	quit(1 if failures else 0)
