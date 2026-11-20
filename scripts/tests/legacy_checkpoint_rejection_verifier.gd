extends SceneTree
## Einsatz-Zwischenstaende im alten Format (legacy_ground_positions.v1) werden seit
## 20.11.2026 abgelehnt. Eingabe: die echten alten Dateien unter docs/qa (nur gelesen,
## Kopien nur nach user:// des Wegwerf-Profils). Gegenprobe: das echte Hex-Paar.
const HOME = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const ACTIVE = preload("res://scripts/meta/campaign_active_checkpoint_store.gd")
const BOOTSTRAP = preload("res://scripts/mission/campaign_active_bootstrap_validation.gd")
const OLD_DIR := "res://docs/qa/review_completion_20261113/legacy_source_pair/"
const HEX_DIR := "res://docs/qa/review_completion_20261113/return_source_pair/"
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		print("FAIL: ", label)
	return ok

func _install(dir: String) -> bool:
	for pair in [[dir + "checkpoint_v1.json", HOME.DEFAULT_PATH], [dir + "active_checkpoint_v1.json", ACTIVE.DEFAULT_PATH]]:
		if not FileAccess.file_exists(pair[0]): return false
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pair[1]).get_base_dir())
		var file := FileAccess.open(pair[1], FileAccess.WRITE)
		if file == null: return false
		file.store_buffer(FileAccess.get_file_as_bytes(pair[0]))
		file.close()
	return true

func _ground_schema(dir: String) -> String:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + "active_checkpoint_v1.json"))
	if parsed is Dictionary and parsed.get("components") is Dictionary and parsed.components.get("ground") is Dictionary:
		return String(parsed.components.ground.get("schema", ""))
	return ""

func _run() -> void:
	if OS.get_environment("POLISA_TEST_PROFILE").is_empty():
		printerr("isolated test profile required (POLISA_TEST_PROFILE and redirected APPDATA)")
		quit(1)
		return
	_check(_ground_schema(OLD_DIR) == "legacy_ground_positions.v1", "Eingabe ist wirklich ein Zwischenstand im alten Format")
	_check(_ground_schema(HEX_DIR) == "hex_mission_ground.v1", "Gegenprobe-Eingabe ist ein Hex-Zwischenstand")
	# Alter Zwischenstand: Basisstand passt (Home-Hash), Einsatzstand wird abgelehnt.
	if _check(_install(OLD_DIR), "altes Paar im Wegwerf-Profil installiert"):
		var home_bytes := FileAccess.get_file_as_bytes(HOME.DEFAULT_PATH)
		var active_bytes := FileAccess.get_file_as_bytes(ACTIVE.DEFAULT_PATH)
		var home_before: Dictionary = HOME.load_checkpoint()
		var loaded: Dictionary = ACTIVE.load_checkpoint(BOOTSTRAP.validate)
		_check(not loaded.get("ok", true) and loaded.get("reason") == "unsupported_ground_schema", "alter Einsatzstand wird frueh abgelehnt, Grund unsupported_ground_schema (war: " + str(loaded.get("reason")) + ")")
		# Die Dateien vom 13.11. sind fuer den Basisstand heute veraltet (stale_campaign_definitions),
		# deshalb wird nur belegt, dass die Ablehnung am Ladeergebnis des Basisstands nichts aendert.
		_check(HOME.load_checkpoint() == home_before, "Ablehnung des Einsatzstands aendert das Ladeergebnis des Basisstands nicht (" + str(home_before.get("reason", "ok")) + ")")
		_check(FileAccess.get_file_as_bytes(HOME.DEFAULT_PATH) == home_bytes and FileAccess.get_file_as_bytes(ACTIVE.DEFAULT_PATH) == active_bytes, "beide Dateien bleiben Byte fuer Byte unveraendert")
	# Gegenprobe mit dem echten Hex-Paar (Basisstand ist veraltet, daher keine Annahme moeglich).
	if _check(_install(HEX_DIR), "Hex-Paar im Wegwerf-Profil installiert"):
		var loaded_hex: Dictionary = ACTIVE.load_checkpoint(BOOTSTRAP.validate)
		# Das Hex-Paar scheitert heute an veralteten Ortsdaten des Basisstands, aber NICHT am Zwischenstandsformat.
		_check(loaded_hex.get("reason") != "unsupported_ground_schema", "Hex-Einsatzstand wird nicht wegen des Formats abgelehnt (Ergebnis: " + str(loaded_hex.get("reason", "ok")) + "); echte Annahme: mission_ground_actor_transaction_verifier")
		# Im Speicher gebaut: derselbe Hex-Umschlag, nur das ground-Schema (bzw. ground selbst) weicht ab.
		# Die Ablehnung kommt vor dem Laden des Basisstands, deshalb ist sie hier erreichbar.
		var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HEX_DIR + "active_checkpoint_v1.json"))
		_check(BOOTSTRAP.validate(base.duplicate(true)).get("reason") != "unsupported_ground_schema", "unveraenderter Hex-Umschlag: Grund ist nicht unsupported_ground_schema")
		var format_only: Dictionary = base.duplicate(true)
		format_only.components.ground.schema = "legacy_ground_positions.v1"
		var checked: Dictionary = BOOTSTRAP.validate(format_only)
		_check(not checked.get("ok", true) and checked.get("reason") == "unsupported_ground_schema", "nur das ground-Schema weicht ab: Grund genau unsupported_ground_schema (war: " + str(checked.get("reason")) + ")")
		var no_ground: Dictionary = base.duplicate(true)
		no_ground.components.erase("ground")
		checked = BOOTSTRAP.validate(no_ground)
		_check(not checked.get("ok", true) and checked.get("reason") == "unsupported_ground_schema", "ground fehlt: Grund genau unsupported_ground_schema (war: " + str(checked.get("reason")) + ")")
		var null_ground: Dictionary = base.duplicate(true)
		null_ground.components.ground = null
		checked = BOOTSTRAP.validate(null_ground)
		_check(not checked.get("ok", true) and checked.get("reason") == "unsupported_ground_schema", "ground ist null: Grund genau unsupported_ground_schema (war: " + str(checked.get("reason")) + ")")
	print("RESULTS: %d passed, %d failed" % [passed, failed])
	if failed == 0: print("LEGACY_CHECKPOINT_REJECTION_PASS")
	quit(0 if failed == 0 else 1)
