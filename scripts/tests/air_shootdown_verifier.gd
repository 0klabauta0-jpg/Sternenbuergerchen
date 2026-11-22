extends SceneTree
## LC2b: Abschuss im Einsatz. Rumpf 0 durch Bodenbeschuss -> ein Wurf (air_crash_rules) -> Notlandung, Bruchlandung oder Explosion.
## Teil 1: Baustein ground_fire_vs_air.gd (Rumpf darf 0 erreichen, genau ein Abschuss-Ereignis).
## Nur ueber den isolierten Testlauf (Wegwerfprofil) starten.

const GFA = preload("res://scripts/combat/ground_fire_vs_air.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")

var passed := 0
var failed := 0


class Roller extends RefCounted:
	var values: Array = []
	var used := 0
	func next() -> float:
		var value: float = float(values[mini(used, values.size() - 1)]) if not values.is_empty() else 0.5
		used += 1
		return value


func _fid(unit) -> String: return String(unit.id)
func _fweapon(unit) -> String: return String(unit.weapon)
func _ffit(unit) -> bool: return bool(unit.fit)
func _fcontact(unit) -> bool: return bool(unit.contact)
func _fsees(unit, _target) -> Dictionary: return {"visible": bool(unit.visible), "range_tiles": float(unit.dist)}


func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s" % label)
		push_error(label)


func _run() -> void:
	_test_step_shootdown()
	await process_frame
	print("AIR_SHOOTDOWN passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _unit(id: String, weapon: String) -> Dictionary:
	return {"id": id, "weapon": weapon, "fit": true, "contact": false, "visible": true, "dist": 6.0}


func _target(craft_type: String, integrity: int = 100, state: String = "intact") -> Dictionary:
	return {"craft_id": "viper", "display_name": "Viper", "pilot_skill": 0.5, "position": Vector2(10, 10), "cell": Vector2i.ZERO,
		"approach_style": "aggressiv", "craft_type": craft_type,
		"status": {"asset_id": "viper", "asset_type": "fighter", "state": state, "integrity": integrity, "max_integrity": 100}}


func _ctx(tick: int, targets: Array, shooters: Array, roller: Roller) -> Dictionary:
	return {"tick": tick, "targets": targets, "shooters": shooters, "id_of": Callable(self, "_fid"), "weapon_of": Callable(self, "_fweapon"),
		"is_fit": Callable(self, "_ffit"), "has_ground_contact": Callable(self, "_fcontact"), "sees": Callable(self, "_fsees"), "roll": Callable(roller, "next")}


## Leichter Jaeger, Raketenwerfer: zwei Treffer (je 50 %) holen ihn herunter; genau EIN Abschuss-Ereignis, auch wenn weitere Schuetzen und Takte folgen.
func _test_step_shootdown() -> void:
	var gfa = GFA.new()
	var roller := Roller.new()
	roller.values = [0.0]
	var shooters: Array = [_unit("g1", "rocket_launcher"), _unit("g2", "rocket_launcher")]
	var target := _target("fighter")
	gfa.step(_ctx(0, [target], shooters, roller))
	var status: Dictionary = target.status
	var tick: int = GFA.lock_ticks("rocket_launcher")
	var after: Array = []
	var shootdowns := 0
	var shot_events := 0
	var last_update: Dictionary = {}
	for i in range(6):
		target.status = status
		var result: Dictionary = gfa.step(_ctx(tick, [target], shooters, roller))
		shootdowns += Array(result.get("shootdowns", [])).size()
		shootdowns += result.events.filter(func(e): return e.type == "shootdown").size()
		for shot in result.events.filter(func(e): return e.type == "shot"):
			shot_events += 1
			if bool(shot.hit): after.append(int(shot.integrity_after))
		if result.updates.has("viper"):
			status = result.updates.viper.snapshot
			last_update = result.updates.viper
		tick += GFA.lock_ticks("rocket_launcher")
	_check(after == [50, 0] or after == [0], "Rumpf faellt auf 0 (Treffer-Folge %s)" % [str(after)])
	_check(int(status.integrity) == 0 and String(status.state) in ["crashed", "destroyed"], "Zustand nach dem zweiten Treffer: Rumpf 0 und Endzustand (%s)" % [str(status.get("state"))])
	_check(shootdowns == 2, "genau ein Abschuss: ein Ereignis und ein Eintrag in der Liste (gezaehlt %d)" % shootdowns)
	var entry: Dictionary = {}
	var fresh = GFA.new()
	var roller2 := Roller.new()
	roller2.values = [0.0]
	var t2 := _target("fighter", 50, "damaged")
	fresh.step(_ctx(0, [t2], [_unit("g1", "rocket_launcher")], roller2))
	var killing: Dictionary = fresh.step(_ctx(GFA.lock_ticks("rocket_launcher"), [t2], [_unit("g1", "rocket_launcher")], roller2))
	if not Array(killing.get("shootdowns", [])).is_empty(): entry = killing.shootdowns[0]
	_check(String(entry.get("craft_id", "")) == "viper" and is_equal_approx(float(entry.get("pilot_skill", -1.0)), 0.5), "Eintrag der Liste: Schiff und Pilotenwert (%s)" % [str(entry)])
	_check(not last_update.is_empty(), "das Ergebnis traegt den Endstand des Rumpfs")
