extends SceneTree
## Task 6a (Ausfall und Rueckzug): Gefallenenliste im Kampagnen-Checkpoint.
## Teil A: Adapter ohne Szene (record_fallen, get_fallen). Teil B: echte Meta-Szene,
## echter Payload, validate_payload, Speichern und Laden.

const ADAPTER := preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const STORE := preload("res://scripts/meta/campaign_checkpoint_store.gd")
const TEST_PATH := "user://campaigns/t6a_fallen_test.json"

var _passed := 0
var _failed := 0

func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_adapter_part()
	await _scene_part()
	print("CAMPAIGN_CASUALTY_FALLEN passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _entry(id: String) -> Dictionary:
	return {"unit_id": id, "display_name": "Name " + id, "job_id": "job_" + id, "location_id": "loc_" + id}

func _adapter_part() -> void:
	var adapter: Node = ADAPTER.new()
	_check(adapter.has_method("record_fallen") and adapter.has_method("get_fallen"), "A: Adapter hat record_fallen und get_fallen")
	if not (adapter.has_method("record_fallen") and adapter.has_method("get_fallen")):
		adapter.free()
		return
	_check(adapter.get_fallen() == [], "A: neue Liste ist leer")
	var res: Dictionary = adapter.record_fallen(_entry("a"))
	_check(res == {"ok": true}, "A: gueltiger Eintrag liefert {ok:true}")
	var list: Array = adapter.get_fallen()
	_check(list.size() == 1 and list[0] == _entry("a"), "A: Eintrag steht in der Liste")
	_check(list[0].keys().size() == 4 and list[0].has("unit_id") and list[0].has("display_name") and list[0].has("job_id") and list[0].has("location_id"), "A: genau vier Schluessel")
	res = adapter.record_fallen(_entry("a"))
	_check(res == {"ok": true, "unchanged": true} and adapter.get_fallen().size() == 1, "A: gleiche unit_id noch einmal: unchanged, Laenge bleibt 1")
	var changed := _entry("a")
	changed.display_name = "Anderer Name"
	res = adapter.record_fallen(changed)
	_check(res.get("unchanged", false) and adapter.get_fallen()[0].display_name == "Name a", "A: gleiche unit_id mit anderem Namen aendert nichts")
	var no_id := _entry("x")
	no_id.erase("unit_id")
	res = adapter.record_fallen(no_id)
	_check(res == {"ok": false, "reason": "invalid_fallen_entry"} and adapter.get_fallen().size() == 1, "A: ohne unit_id abgelehnt, Liste unveraendert")
	var empty_id := _entry("x")
	empty_id.unit_id = ""
	res = adapter.record_fallen(empty_id)
	_check(res == {"ok": false, "reason": "invalid_fallen_entry"} and adapter.get_fallen().size() == 1, "A: leere unit_id abgelehnt, Liste unveraendert")
	var number_name := _entry("x")
	number_name.display_name = 5
	res = adapter.record_fallen(number_name)
	_check(res == {"ok": false, "reason": "invalid_fallen_entry"} and adapter.get_fallen().size() == 1, "A: Zahl als display_name abgelehnt, Liste unveraendert")
	var number_id := _entry("x")
	number_id.unit_id = 7
	res = adapter.record_fallen(number_id)
	_check(res == {"ok": false, "reason": "invalid_fallen_entry"} and adapter.get_fallen().size() == 1, "A: Zahl als unit_id abgelehnt")
	res = adapter.record_fallen({})
	_check(res == {"ok": false, "reason": "invalid_fallen_entry"}, "A: leeres Dictionary abgelehnt")
	var extra := _entry("b")
	extra["secret"] = "x"
	extra["hp"] = 3
	res = adapter.record_fallen(extra)
	var stored_b: Dictionary = adapter.get_fallen()[1] if adapter.get_fallen().size() > 1 else {}
	_check(res.get("ok", false) and stored_b == _entry("b") and not stored_b.has("secret") and not stored_b.has("hp"), "A: zusaetzliche Schluessel werden verworfen")
	var no_job := {"unit_id": "c", "display_name": "Name c", "location_id": "loc_c"}
	res = adapter.record_fallen(no_job)
	var stored_c: Dictionary = adapter.get_fallen()[2] if adapter.get_fallen().size() > 2 else {}
	_check(res.get("ok", false) and stored_c.get("job_id", null) == "" and stored_c.get("unit_id") == "c" and stored_c.keys().size() == 4, "A: fehlender job_id wird zu leerem String")
	var only_id := {"unit_id": "d"}
	adapter.record_fallen(only_id)
	_check(adapter.get_fallen()[3] == {"unit_id": "d", "display_name": "", "job_id": "", "location_id": ""}, "A: nur unit_id: die drei anderen Schluessel sind leer")
	var ids: Array = []
	for item in adapter.get_fallen(): ids.append(item.unit_id)
	_check(ids == ["a", "b", "c", "d"], "A: Reihenfolge der Aufnahme bleibt")
	# Kopie
	var copy: Array = adapter.get_fallen()
	copy[0].display_name = "veraendert"
	copy.append(_entry("z"))
	copy.pop_front()
	_check(adapter.get_fallen().size() == 4 and adapter.get_fallen()[0].display_name == "Name a", "A: get_fallen liefert eine tiefe Kopie")
	# Eingabe-Dictionary wird nicht geteilt
	var input := _entry("e")
	adapter.record_fallen(input)
	input.display_name = "spaeter geaendert"
	_check(adapter.get_fallen()[4].display_name == "Name e", "A: Aufgenommener Eintrag teilt kein Dictionary mit dem Aufrufer")
	adapter.free()

func _scene_part() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var runtime: Node = flow.get("_singleplayer_runtime")
	_check(runtime != null and runtime.has_method("get_fallen"), "B: Laufzeit-Adapter der Kampagne vorhanden")
	if runtime == null or not runtime.has_method("get_fallen") or not runtime.has_method("record_fallen"):
		flow.queue_free()
		await process_frame
		return
	_check(runtime.get_fallen() == [], "B: neue Kampagne startet mit leerer Liste")
	var start: RefCounted = flow.get("_campaign_start")
	var base_capture: Dictionary = start.capture_home_checkpoint(flow, runtime)
	_check(base_capture.get("ok", false), "B: echter Heimat-Payload wird gebaut")
	if not base_capture.get("ok", false):
		flow.queue_free()
		await process_frame
		return
	var base_payload: Dictionary = base_capture.payload
	_check(base_payload.has("fallen") and base_payload.fallen == [], "B: Payload ohne Gefallene traegt fallen als leere Liste")
	# validate_payload
	var plain: Dictionary = base_payload.duplicate(true)
	plain.erase("fallen")
	_check(STORE.validate_payload(plain).get("ok", false), "V: Payload ohne fallen bleibt gueltig")
	var variant: Dictionary = base_payload.duplicate(true)
	variant["fallen"] = []
	_check(STORE.validate_payload(variant).get("ok", false), "V: fallen leer gueltig")
	variant = base_payload.duplicate(true)
	variant["fallen"] = [_entry("a")]
	_check(STORE.validate_payload(variant).get("ok", false), "V: fallen mit gueltigem Eintrag gueltig")
	variant = base_payload.duplicate(true)
	variant["fallen"] = [{"unit_id": "a"}]
	_check(STORE.validate_payload(variant).get("ok", false), "V: Eintrag nur mit unit_id gueltig")
	var bad_cases := {
		"fallen: String": "x",
		"fallen: [1]": [1],
		"fallen: [{}]": [{}],
		"fallen: [unit_id leer]": [{"unit_id": ""}],
		"fallen: [display_name Zahl]": [{"unit_id": "a", "display_name": 5}],
		"fallen: [job_id Zahl]": [{"unit_id": "a", "job_id": 5}],
		"fallen: [location_id null]": [{"unit_id": "a", "location_id": null}],
		"fallen: [unit_id Zahl]": [{"unit_id": 3}],
		"fallen: Dictionary": {"unit_id": "a"},
		"fallen: null": null,
	}
	for label in bad_cases:
		variant = base_payload.duplicate(true)
		variant["fallen"] = bad_cases[label]
		var verdict: Dictionary = STORE.validate_payload(variant)
		_check(not verdict.get("ok", true) and verdict.get("reason", "") == "invalid_fallen", "V: %s abgelehnt mit invalid_fallen" % label)
	# Speichern und Laden
	_check(runtime.record_fallen(_entry("a")).get("ok", false) and runtime.record_fallen(_entry("b")).get("ok", false), "S: zwei Gefallene aufgenommen")
	var captured: Dictionary = start.capture_home_checkpoint(flow, runtime)
	_check(captured.get("ok", false) and captured.payload.get("fallen", []) == [_entry("a"), _entry("b")], "S: Payload traegt beide Eintraege in Reihenfolge")
	if captured.get("ok", false):
		var saved: Dictionary = STORE.save_checkpoint(captured.payload, TEST_PATH)
		_check(saved.get("ok", false), "S: Checkpoint wird geschrieben")
		var loaded: Dictionary = STORE.load_checkpoint(TEST_PATH)
		_check(loaded.get("ok", false) and loaded.payload.get("fallen", []) == [_entry("a"), _entry("b")], "S: Datei enthaelt beide Eintraege in Reihenfolge")
		if loaded.get("ok", false):
			var fresh: Node = ADAPTER.new()
			_check(fresh.get_fallen() == [], "S: frischer Adapter ist leer")
			fresh.restore_fallen_from_checkpoint(loaded.payload)
			_check(fresh.get_fallen() == [_entry("a"), _entry("b")], "S: geladener Adapter hat dieselben zwei Eintraege in derselben Reihenfolge")
			# Stand ohne fallen
			var old_state: Dictionary = loaded.payload.duplicate(true)
			old_state.erase("fallen")
			_check(STORE.validate_payload(old_state).get("ok", false), "S: Stand ohne fallen ist gueltig")
			fresh.restore_fallen_from_checkpoint(old_state)
			_check(fresh.get_fallen() == [], "S: Stand ohne fallen laedt mit leerer Liste (ersetzt die alte)")
			# Ersetzen statt Mischen
			fresh.record_fallen(_entry("p"))
			fresh.record_fallen(_entry("q"))
			var other: Dictionary = loaded.payload.duplicate(true)
			other["fallen"] = [_entry("r")]
			fresh.restore_fallen_from_checkpoint(other)
			_check(fresh.get_fallen() == [_entry("r")], "S: Stand mit anderem Eintrag ersetzt die bisherige Liste, keine Mischung")
			fresh.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	flow.queue_free()
	await process_frame
