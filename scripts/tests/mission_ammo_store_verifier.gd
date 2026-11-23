extends SceneTree
## M6a (23.11.2026): Einsatz-Vorrat an Reservemagazinen fuer alle Einheiten ohne Kampagnen-Vorrat (Gegner, NPCs, Skirmish, Mehrspieler-Host).
## Reine Daten: Startmenge nach Fach der Ruestung (data/combat/ammo_rules.json), Entnehmen bis leer, Neustart leert,
## Kampagnen-Vorrat hat Vorrang (SimulationRoot-Anschluss).
## Schlusszeile: MISSION_AMMO_STORE passed=N failed=M
const STORE = preload("res://scripts/combat/mission_ammo_store.gd")
const SIMULATION_ROOT = preload("res://scripts/core/simulation_root.gd")
var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)


func _run() -> void:
	_start_part()
	_take_part()
	_unknown_part()
	_reset_part()
	_snapshot_part()
	_root_part()
	print("MISSION_AMMO_STORE passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)


func _start_part() -> void:
	var s = STORE.new()
	for pair in [["suit", 1], ["light", 3], ["medium", 5], ["heavy", 7], ["unbekannt", 5], ["", 5]]:
		var id: String = "u_%s" % String(pair[0])
		check(bool(s.ensure(id, String(pair[0]), "ammo_rifle")), "Start: %s wird angelegt" % id)
		check(int(s.count(id, "ammo_rifle")) == int(pair[1]), "Start: Ruestung '%s' -> %d Magazine (ist %d)" % [pair[0], pair[1], int(s.count(id, "ammo_rifle"))])
	check(int(s.count("u_heavy", "ammo_light")) == 0, "Start: nur die Sorte der ersten Waffe, andere Sorte 0")
	check(bool(s.has_unit("u_light")), "Start: has_unit wahr nach ensure")
	s.take("u_light", "ammo_rifle")
	s.ensure("u_light", "heavy", "ammo_light")
	check(int(s.count("u_light", "ammo_rifle")) == 2 and int(s.count("u_light", "ammo_light")) == 0, "Start: zweites ensure legt nicht neu an (Stand bleibt)")
	s.ensure("u_nahkampf", "heavy", "")
	check(bool(s.has_unit("u_nahkampf")) and int(s.count("u_nahkampf", "")) == 0 and int(s.count("u_nahkampf", "ammo_rifle")) == 0, "Start: Waffe ohne Munition braucht nichts (angelegt, aber leer)")


func _take_part() -> void:
	var s = STORE.new()
	s.ensure("g", "medium", "ammo_light")
	var taken := 0
	for i in 12:
		if bool(s.take("g", "ammo_light")): taken += 1
	check(taken == 5, "Entnehmen: mittlere Ruestung gibt genau 5 Magazine (ist %d)" % taken)
	check(int(s.count("g", "ammo_light")) == 0, "Entnehmen: danach 0, nie im Minus")
	check(not bool(s.take("g", "ammo_light")), "Entnehmen: leer -> false")
	check(not bool(s.take("g", "ammo_rifle")), "Entnehmen: andere Sorte -> false")


func _unknown_part() -> void:
	var s = STORE.new()
	check(int(s.count("x", "ammo_light")) == 0 and not bool(s.has_unit("x")), "Unbekannt: Einheit ohne Eintrag hat 0 und keinen Vorrat")
	check(not bool(s.take("x", "ammo_light")), "Unbekannt: Entnehmen ohne Eintrag -> false")
	check(not bool(s.ensure("", "medium", "ammo_light")), "Unbekannt: leere Kennung wird nicht angelegt")
	check(int(s.count("", "ammo_light")) == 0, "Unbekannt: leere Kennung zaehlt 0")
	s.ensure("w", "medium", "ammo_unbekannt")
	check(int(s.count("w", "ammo_light")) == 0, "Unbekannt: unbekannte Sorte gibt keinen Vorrat einer bekannten Sorte")


func _reset_part() -> void:
	var s = STORE.new()
	s.ensure("a", "heavy", "ammo_rifle")
	s.take("a", "ammo_rifle")
	s.reset()
	check(not bool(s.has_unit("a")) and int(s.count("a", "ammo_rifle")) == 0, "Neustart: reset leert alles")
	s.ensure("a", "heavy", "ammo_rifle")
	check(int(s.count("a", "ammo_rifle")) == 7, "Neustart: danach wieder volle Startmenge")


func _snapshot_part() -> void:
	var s = STORE.new()
	s.ensure("a", "heavy", "ammo_rifle")
	s.ensure("b", "light", "ammo_light")
	s.take("a", "ammo_rifle")
	s.take("a", "ammo_rifle")
	var snap: Dictionary = s.snapshot()
	var t = STORE.new()
	check(bool(t.restore(snap)), "Stand: restore nimmt den Schnappschuss an")
	check(int(t.count("a", "ammo_rifle")) == 5 and int(t.count("b", "ammo_light")) == 3, "Stand: Zahlen nach restore gleich")
	var u = STORE.new()
	u.ensure("z", "medium", "ammo_light")
	check(not bool(u.restore({"units": "kaputt"})) and bool(u.has_unit("z")), "Stand: kaputter Schnappschuss wird abgelehnt, Stand bleibt")
	check(bool(u.restore({})) and not bool(u.has_unit("z")), "Stand: leerer Schnappschuss leert (alter Stand ohne Feld -> volle Startmenge beim ersten Bedarf)")


func _root_part() -> void:
	var root = SIMULATION_ROOT.new()
	root.ensure_mission_ammo("e1", "medium", "ammo_rifle")
	check(bool(root.person_has_magazine_store("e1")) and int(root.get_person_magazine_count("e1", "ammo_rifle")) == 5, "Root: ohne Kampagne zaehlt der Einsatz-Vorrat (5)")
	check(bool(root.take_person_magazine("e1", "ammo_rifle")) and int(root.get_person_magazine_count("e1", "ammo_rifle")) == 4, "Root: Entnehmen ueber die Simulation")
	check(not bool(root.person_has_magazine_store("fremd")) and int(root.get_person_magazine_count("fremd", "ammo_rifle")) == 0, "Root: unbekannte Einheit hat nichts")
	var camp := _FakeSupply.new()
	root.bind_mission_magazine_supply(camp)
	root.ensure_mission_ammo("own", "medium", "ammo_rifle")
	check(int(root.get_person_magazine_count("own", "ammo_rifle")) == 2, "Root: Kampagnen-Vorrat hat Vorrang (2, nicht 5)")
	check(bool(root.take_person_magazine("own", "ammo_rifle")) and camp.taken == 1, "Root: Entnehmen geht an die Kampagne")
	check(int(root.get_person_magazine_count("e1", "ammo_rifle")) == 4, "Root: Person ohne Kampagnen-Vorrat bleibt beim Einsatz-Vorrat")
	root.release_mission_magazine_supply()
	root.reset_mission_ammo()
	check(int(root.get_person_magazine_count("e1", "ammo_rifle")) == 0 and not bool(root.person_has_magazine_store("e1")), "Root: reset_mission_ammo leert")
	root.free()


class _FakeSupply extends RefCounted:
	var taken := 0
	func person_has_magazine_store(unit_id: String) -> bool:
		return unit_id == "own"
	func person_magazine_count(unit_id: String, _ammo_class: String) -> int:
		return 2 - taken if unit_id == "own" else 0
	func take_person_magazine(unit_id: String, _ammo_class: String) -> bool:
		if unit_id != "own" or taken >= 2: return false
		taken += 1
		return true
