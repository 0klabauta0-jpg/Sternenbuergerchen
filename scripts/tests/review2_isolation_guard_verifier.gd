extends SceneTree
## Belegt die Entscheidungsfunktion der Isolations-Sperre, ohne die Sperre selbst
## aufzurufen (sie wuerde den Prozess beenden). Zweck der Sperre: Kein Test darf
## in den echten Spielstand schreiben.

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const TEMP := "C:\\Users\\b\\AppData\\Local\\Temp"
const COPY_NAME := "SB-Codex-Review2-x"
const NORMAL := "SternenBuergerchen"

var _passed := 0
var _failed := 0


func _init() -> void:
	# Projektkopie wie bisher
	_expect("projektkopie_alle_gleich", "C:/x/Review2/user", "C:/x/Review2/user", "C:/x/Review2/user", COPY_NAME, "", true)
	_expect("projektkopie_mit_temp", "C:/x/Review2/user", "C:/x/Review2/user", "C:/x/Review2/user", COPY_NAME, TEMP, true)
	# Wegwerf-Profil unter Temp, gemischte Schraegstriche und Schreibweise
	var temp_dir := "C:/Users/b/AppData/Local/Temp/sb_profil/Godot/app_userdata/X"
	_expect("temp_profil_gemischt", "C:\\Users\\B\\AppData\\Local\\TEMP\\sb_profil\\Godot\\app_userdata\\X", temp_dir, temp_dir, NORMAL, TEMP, true)
	_expect("temp_profil_mit_abschlusstrenner", temp_dir + "/", temp_dir, temp_dir, NORMAL, TEMP + "\\", true)
	# Abgelehnt
	_expect("expected_leer", "", temp_dir, temp_dir, NORMAL, TEMP, false)
	var real_dir := "C:/Users/b/AppData/Roaming/Godot/app_userdata/X"
	_expect("echtes_profil_roaming", real_dir, real_dir, real_dir, NORMAL, TEMP, false)
	_expect("actual_abweichend", temp_dir, temp_dir + "_andere", temp_dir, NORMAL, TEMP, false)
	_expect("localized_abweichend", temp_dir, temp_dir, temp_dir + "_andere", NORMAL, TEMP, false)
	var near_dir := "C:/Users/b/AppData/Local/Temp2/x"
	_expect("temp2_ist_nicht_temp", near_dir, near_dir, near_dir, NORMAL, TEMP, false)
	_expect("ordner_ist_temp_selbst", TEMP, TEMP, TEMP, NORMAL, TEMP, false)
	_expect("temp_leer_name_normal", temp_dir, temp_dir, temp_dir, NORMAL, "", false)
	var dotdot := "C:/Users/b/AppData/Local/Temp/a/../../Roaming/x"
	_expect("punktpunkt_fuehrt_aus_temp_heraus", dotdot, dotdot, dotdot, NORMAL, TEMP, false)
	# Kopie-Name mit leerem expected bleibt abgelehnt
	_expect("projektkopie_expected_leer", "", "C:/x", "C:/x", COPY_NAME, TEMP, false)
	# Abgelehnt muss einen Grund nennen
	var verdict: Dictionary = GUARD.isolation_verdict(real_dir, real_dir, real_dir, NORMAL, TEMP)
	_check("ablehnung_nennt_grund", not String(verdict.get("reason", "")).is_empty())
	print("REVIEW2_ISOLATION_GUARD passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _expect(label: String, expected_dir: String, actual_dir: String, localized_dir: String, app_name: String, temp_dir: String, want_ok: bool) -> void:
	var verdict: Dictionary = GUARD.isolation_verdict(expected_dir, actual_dir, localized_dir, app_name, temp_dir)
	_check(label, bool(verdict.get("ok", not want_ok)) == want_ok)


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("FAIL ", label)
