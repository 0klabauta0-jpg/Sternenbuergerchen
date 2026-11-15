extends SceneTree
## Task 7a (Ausfall und Rueckzug): Ausfallzeit zaehlen, beschreiben und Einsatzsperre.
## Ohne Meta-Szene: reine Rechenlogik plus BasePersonnelRuntime und Adapter mit Attrappen.
# Teil 7b: Meta-Szene, Checkpoint, Skirmish

const RECOVERY := preload("res://scripts/core/personnel_recovery_runtime.gd")
const BASE_OWNER := preload("res://scripts/core/base_personnel_runtime.gd")
const ADAPTER := preload("res://scripts/meta/singleplayer_runtime_adapter.gd")

class ScreenStub extends Node:
	var pilot := "pilot_1"
	var members := PackedStringArray(["crew_1"])
	var busy := false
	func _operations_craft_busy(_craft: String) -> bool: return busy
	func _operations_payload_craft_for_team(_team: String) -> String: return ""
	func _get_member_unit_ids_for_fireteam(_team: String) -> PackedStringArray: return members
	var payload_teams: Array = ["ft1"]
	func _get_assigned_pilot_id(craft: String) -> String: return pilot if craft == "c1" else ""
	func _get_homebase_direct_payload_fireteam_ids_for_craft_raw(craft: String) -> Array: return payload_teams if craft == "c1" else []

class FlowStub extends Node:
	var _aircraft_location_by_craft: Dictionary = {}
	func _find_pending_mission_craft_transfer(_craft: String) -> Dictionary: return {}
	func _find_homebase_aircraft_definition(craft: String) -> Dictionary: return {"craft_id": craft}

var _passed := 0
var _failed := 0

func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)

func _wounded(id: String, seconds: float, severity: String = "medium") -> Dictionary:
	return {"unit_id": id, "display_name": "Name " + id, "availability_status": "wounded", "status_text": "x",
		"recovery_state": {"severity": severity, "seconds_total": 1000.0, "seconds_remaining": seconds}}

func _init() -> void:
	_pure_part()
	_base_part()
	_adapter_part()
	# Teil 7b: Meta-Szene, Checkpoint, Skirmish
	print("CAMPAIGN_CASUALTY_RECOVERY passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _pure_part() -> void:
	var active := {"unit_id": "a", "availability_status": "active"}
	var before: Array = [_wounded("w", 900.0)]
	var res: Dictionary = RECOVERY.advance(before, 60.0)
	_check(is_equal_approx(float(res.units[0].recovery_state.seconds_remaining), 840.0) and bool(res.changed), "advance: 900 s minus 60 s ergibt 840 s")
	_check(is_equal_approx(float(before[0].recovery_state.seconds_remaining), 900.0), "advance: Eingabe bleibt unveraendert")
	_check(res.units[0].availability_status == "wounded" and res.recovered_unit_ids.is_empty(), "advance: noch verwundet, niemand genesen")
	res = RECOVERY.advance([_wounded("w", 30.0)], 60.0)
	_check(res.units[0].availability_status == "active" and res.units[0].recovery_state.is_empty() and res.units[0].status_text == "", "advance: Rest 30 s minus 60 s macht aktiv und leert Zustand und Text")
	_check(res.recovered_unit_ids == PackedStringArray(["w"]) and bool(res.changed), "advance: genesene Person steht in recovered_unit_ids")
	res = RECOVERY.advance([active], 60.0)
	_check(not bool(res.changed) and res.units[0] == active and res.recovered_unit_ids.is_empty(), "advance: aktive Person bleibt unberuehrt, changed false")
	res = RECOVERY.advance([_wounded("w", 100.0)], 0.0)
	_check(not bool(res.changed) and is_equal_approx(float(res.units[0].recovery_state.seconds_remaining), 100.0), "advance: delta 0 aendert nichts")
	res = RECOVERY.advance([_wounded("w", 100.0)], -5.0)
	_check(not bool(res.changed) and is_equal_approx(float(res.units[0].recovery_state.seconds_remaining), 100.0), "advance: negatives delta aendert nichts")
	res = RECOVERY.advance([_wounded("w", 10.0)], 10.0)
	_check(res.units[0].availability_status == "active", "advance: Rest genau 0 gilt als genesen")
	var legacy := {"unit_id": "old", "availability_status": "wounded", "status_text": "alt", "recovery_state": {}}
	res = RECOVERY.advance([legacy, {"unit_id": "bad", "availability_status": "wounded", "recovery_state": "kaputt"}], 1.0)
	_check(res.units[0].availability_status == "active" and res.units[0].recovery_state.is_empty() and res.units[0].status_text == "", "advance: wounded ohne recovery_state gilt als genesen")
	_check(res.units[1].availability_status == "active" and res.recovered_unit_ids == PackedStringArray(["old", "bad"]), "advance: kaputter recovery_state genesen, beide in recovered_unit_ids")
	var mixed: Dictionary = RECOVERY.advance([_wounded("w", 500.0), active], 10.0)
	_check(mixed.units.size() == 2 and mixed.units[1] == active, "advance: Reihenfolge und Anzahl bleiben erhalten")
	var as_text := _wounded("w", 0.0)
	as_text.recovery_state.seconds_remaining = "720"
	_check(RECOVERY.is_wounded(as_text) and RECOVERY.describe(as_text) == "Verwundet (mittel), noch 12:00", "Restzeit als Zahl im Text (\"720\") wird als 720 gelesen")
	res = RECOVERY.advance([as_text], 20.0)
	_check(res.units[0].availability_status == "wounded" and is_equal_approx(float(res.units[0].recovery_state.seconds_remaining), 700.0), "advance: Textzahl \"720\" minus 20 s ergibt 700 s")
	as_text.recovery_state.seconds_remaining = "abc"
	_check(not RECOVERY.is_wounded(as_text), "Restzeit als Text ohne Zahl zaehlt nicht als verwundet")
	_check(RECOVERY.is_wounded(_wounded("w", 5.0)), "is_wounded: wounded mit Rest > 0 ist true")
	_check(not RECOVERY.is_wounded(_wounded("w", 0.0)), "is_wounded: wounded mit Rest 0 ist false")
	_check(not RECOVERY.is_wounded(active), "is_wounded: active ist false")
	_check(RECOVERY.describe(_wounded("w", 750.0, "medium")) == "Verwundet (mittel), noch 12:30", "describe: mittel 750 s")
	_check(RECOVERY.describe(_wounded("w", 180.0, "light")) == "Verwundet (leicht), noch 3:00", "describe: leicht 180 s")
	_check(RECOVERY.describe(_wounded("w", 2400.0, "severe")) == "Verwundet (schwer), noch 40:00", "describe: schwer 2400 s")
	_check(RECOVERY.describe(_wounded("w", 59.9, "light")) == "Verwundet (leicht), noch 0:59", "describe: 59.9 s ergibt 0:59")
	_check(RECOVERY.describe(_wounded("w", 65.0, "xyz")) == "Verwundet (xyz), noch 1:05", "describe: unbekannte Stufe zeigt den Rohwert")
	_check(RECOVERY.describe(active) == "", "describe: nicht verwundet ergibt leeren Text")

func _make_base() -> Dictionary:
	var base: Node = BASE_OWNER.new()
	var screen := ScreenStub.new()
	var flow := FlowStub.new()
	root.add_child(flow)
	root.add_child(screen)
	root.add_child(base)
	base._flow = flow
	base._screen = screen
	for id in ["pilot_1", "crew_1"]:
		base._states[id] = {"unit_id": id, "name": "Name " + id, "status": "outside", "craft_id": "", "bed_id": "", "action": {}, "last_result": {}, "auto_rest_enabled": false}
	return {"base": base, "screen": screen, "flow": flow}

func _base_part() -> void:
	var rig := _make_base()
	var base: Node = rig.base
	var states_before: Dictionary = base._states.duplicate(true)
	base.set_unavailable_unit_reasons({"crew_1": "Name crew_1 ist verwundet"})
	var res: Dictionary = base.apply_operation("base_board", {"craft_id": "c1", "fireteam_id": "ft1"})
	_check(not bool(res.get("ok", true)) and str(res.get("reason", "")) == "unit_wounded", "Einschiffen Trupp mit gesperrter Person: reason unit_wounded")
	_check(str(res.get("message", "")).contains("Name crew_1"), "Einschiffen: Meldung enthaelt den Namen")
	_check(base._states == states_before and base._board_groups.is_empty(), "Einschiffen: Status, Position und Boardinggruppe unveraendert")
	base.set_unavailable_unit_reasons({"pilot_1": ""})
	res = base.apply_operation("base_board", {"unit_id": "pilot_1", "craft_id": "c1"})
	_check(str(res.get("reason", "")) == "unit_wounded" and str(res.get("message", "")) == "Person ist verwundet", "Einzelperson mit leerem Text: gesperrt, Standardmeldung")
	_check(base._states == states_before, "Einzelperson: Status unveraendert")
	base.set_unavailable_unit_reasons({})
	# Die Gegenprobe laeuft ueber ein belegtes Schiff: die Anfrage kommt an der Sperre vorbei
	# und scheitert erst am naechsten Grund, ohne dass die Attrappe Gelaende und Navigation braucht.
	rig.screen.busy = true
	res = base.apply_operation("base_board", {"unit_id": "pilot_1", "craft_id": "c1"})
	_check(str(res.get("reason", "")) == "craft_busy", "Sperrgruende geleert: Einzelperson kommt an der Sperre vorbei")
	base.set_unavailable_unit_reasons({"pilot_1": ""})
	res = base.apply_operation("base_board", {"unit_id": "pilot_1", "craft_id": "c1"})
	_check(str(res.get("reason", "")) == "unit_wounded", "Sperre gilt vor dem Belegt-Test des Schiffs")
	rig.flow.free()
	rig.screen.free()
	base.free()

func _adapter_part() -> void:
	var rig := _make_base()
	var base: Node = rig.base
	var adapter: Node = ADAPTER.new()
	adapter._base_personnel = base
	adapter._flow = rig.flow
	rig.flow._aircraft_location_by_craft = {"c1": "homebase", "c2": "homebase"}
	rig.screen.pilot = ""
	rig.screen.payload_teams = []
	base.set_unavailable_unit_reasons({"crew_1": "Name crew_1 ist verwundet"})
	base._states["crew_1"].status = "aboard"
	base._states["crew_1"].craft_id = "c1"
	var res: Dictionary = adapter.authorize_departure("c1")
	_check(not bool(res.get("ok", true)) and str(res.get("reason", "")) == "unit_wounded", "authorize_departure mit gesperrter Person an Bord: unit_wounded")
	_check(str(res.get("message", "")).contains("Name crew_1"), "authorize_departure: Meldung der Sperre")
	res = adapter.authorize_departure("c2")
	_check(str(res.get("reason", "")) != "unit_wounded", "authorize_departure anderes Schiff: nicht gesperrt")
	for place in ["mission", "starmap", "polisa", ""]:
		rig.flow._aircraft_location_by_craft["c1"] = place
		res = adapter.authorize_departure("c1")
		_check(str(res.get("reason", "")) != "unit_wounded", "Gesperrte Person an Bord, Schiff nicht an der Heimatbasis (%s): nicht unit_wounded" % place)
	rig.flow._aircraft_location_by_craft["c1"] = "homebase"
	res = adapter.authorize_departure("c1")
	_check(str(res.get("reason", "")) == "unit_wounded", "Gesperrte Person an Bord, Schiff wieder an der Heimatbasis: unit_wounded")
	base._states["crew_1"].status = "outside"
	base._states["crew_1"].craft_id = ""
	base.set_unavailable_unit_reasons({"crew_1": "Name crew_1 ist verwundet"})
	res = adapter.authorize_departure("c1")
	_check(str(res.get("reason", "")) != "unit_wounded", "Person abgesetzt: dieser Sperrgrund ist weg")
	base.set_unavailable_unit_reasons({"stranger": "Fremd"})
	res = adapter.authorize_departure("c1")
	_check(str(res.get("reason", "")) != "unit_wounded", "Gesperrte Person ohne Bezug zum Schiff: nicht gesperrt")
	rig.screen.pilot = "pilot_1"
	base.set_unavailable_unit_reasons({"pilot_1": "Name pilot_1 ist verwundet"})
	res = adapter.authorize_departure("c1")
	_check(str(res.get("reason", "")) == "unit_wounded", "Eingeteilter Pilot (nicht an Bord) sperrt den Abflug")
	res = adapter.authorize_departure("c2")
	_check(str(res.get("reason", "")) != "unit_wounded", "Eingeteilter Pilot sperrt nur sein eigenes Schiff")
	base.set_unavailable_unit_reasons({})
	res = adapter.authorize_departure("c1")
	_check(str(res.get("reason", "")) != "unit_wounded", "Ohne Sperrgruende verhaelt sich authorize_departure wie bisher")
	adapter.free()
	rig.flow.free()
	rig.screen.free()
	base.free()
