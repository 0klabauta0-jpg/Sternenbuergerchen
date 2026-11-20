extends SceneTree
## Belegt die Entscheidungsfunktion der Isolations-Sperre, ohne die Sperre selbst
## aufzurufen (sie wuerde den Prozess beenden). Zweck der Sperre: Kein Test darf
## in den echten Spielstand schreiben.

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const TEMP := "C:\\Users\\b\\AppData\\Local\\Temp"
const PROFILE := "C:\\Users\\b"
const COPY_NAME := "SB-Codex-Review2-x"
const NORMAL := "SternenBuergerchen"
const REAL := "C:/Users/b/AppData/Roaming/Godot/app_userdata/Sternenbuergerchen"
const TEMP_USERDIR := "C:/Users/b/AppData/Local/Temp/sb_profil/Godot/app_userdata/X"

var _passed := 0
var _failed := 0


func _init() -> void:
	# --- angenommen
	_same("projektkopie_ohne_temp", "C:/x/Review2/user", "", "", COPY_NAME, true, "review2 project copy")
	_same("projektkopie_mit_temp", "C:/x/Review2/user", TEMP, PROFILE, COPY_NAME, true, "review2 project copy")
	_expect("temp_profil_gemischt", "C:\\Users\\B\\AppData\\Local\\TEMP\\sb_profil\\Godot\\app_userdata\\X", TEMP_USERDIR, TEMP_USERDIR, NORMAL, TEMP, PROFILE, true, "strictly below")
	_expect("temp_profil_abschlusstrenner", TEMP_USERDIR + "/", TEMP_USERDIR, TEMP_USERDIR, NORMAL, TEMP + "\\", PROFILE + "\\", true, "strictly below")
	_same("gegenprobe_gueltiger_temp_fall", TEMP_USERDIR, TEMP, PROFILE, NORMAL, true, "strictly below")
	# --- grundlegende Ablehnungen
	_expect("expected_leer", "", TEMP_USERDIR, TEMP_USERDIR, NORMAL, TEMP, PROFILE, false, "not set")
	_expect("actual_abweichend", TEMP_USERDIR, TEMP_USERDIR + "_andere", TEMP_USERDIR, NORMAL, TEMP, PROFILE, false, "does not resolve")
	_expect("localized_abweichend", TEMP_USERDIR, TEMP_USERDIR, TEMP_USERDIR + "_andere", NORMAL, TEMP, PROFILE, false, "does not resolve")
	_expect("projektkopie_expected_leer", "", "C:/x", "C:/x", COPY_NAME, TEMP, PROFILE, false, "not set")
	_expect("projektkopie_actual_abweichend", "C:/x", "C:/y", "C:/x", COPY_NAME, TEMP, PROFILE, false, "does not resolve")
	# --- echtes Profil (Hauptfall) und Temp als Vorfahre davon
	_same("echtes_profil_plausibles_temp", REAL, TEMP, PROFILE, NORMAL, false, "neither")
	_same("echtes_profil_temp_ist_benutzerordner", REAL, "C:\\Users\\b", PROFILE, NORMAL, false, "AppData/Roaming")
	_same("echtes_profil_temp_ist_appdata", REAL, "C:\\Users\\b\\AppData", PROFILE, NORMAL, false, "AppData/Roaming")
	_same("echtes_profil_temp_ist_users", REAL, "C:\\Users", PROFILE, NORMAL, false, "AppData/Roaming")
	_same("echtes_profil_temp_ist_roaming", REAL, "C:\\Users\\b\\AppData\\Roaming", PROFILE, NORMAL, false, "AppData/Roaming")
	_same("echtes_profil_profil_leer", REAL, "C:\\Users\\b", "", NORMAL, false, "AppData/Roaming")
	# nur R-c haelt: kein Roaming-Pfad, aber Temp ist der Benutzerordner / Vorfahre
	_same("nur_rc_temp_ist_benutzerordner", "C:/Users/b/Dokumente/x", "C:\\Users\\b", PROFILE, NORMAL, false, "ancestors")
	_same("nur_rc_temp_ist_users", "C:/Users/b/Dokumente/x", "C:\\Users", PROFILE, NORMAL, false, "ancestors")
	# Profil-Ordner fehlt
	_same("profil_leer_sonst_gueltig", TEMP_USERDIR, TEMP, "", NORMAL, false, "USERPROFILE is not set")
	# --- Temp-Plausibilitaet
	_same("temp2_ist_nicht_temp", "C:/Users/b/AppData/Local/Temp2/x", TEMP, PROFILE, NORMAL, false, "neither")
	_same("ordner_ist_temp_selbst", TEMP, TEMP, PROFILE, NORMAL, false, "neither")
	_same("temp_leer_name_normal", TEMP_USERDIR, "", PROFILE, NORMAL, false, "no usable")
	for bad_temp in ["C:", "C:\\", "/", "\\", "tmp", ".", "a/b"]:
		_same("temp_unbrauchbar_" + bad_temp, TEMP_USERDIR, bad_temp, PROFILE, NORMAL, false, "")
	# --- ".." und Kurznamen
	_same("punktpunkt_fuehrt_aus_temp_heraus", "C:/Users/b/AppData/Local/Temp/a/../../Roaming/x", TEMP, PROFILE, NORMAL, false, "")
	_same("fuehrendes_punktpunkt_in_expected", "../Temp/x", TEMP, PROFILE, NORMAL, false, "")
	# simplify_path verwirft ".." an der Wurzel ("C:/../Users" -> "C:/Users"), wie Windows es aufloest:
	# der Pfad liegt dann wirklich unter Temp und ist zulaessig; fuehrt er zum echten Profil, bleibt er abgelehnt.
	_same("punktpunkt_an_der_wurzel_unter_temp", "C:/../Users/b/AppData/Local/Temp/x", TEMP, PROFILE, NORMAL, true, "strictly below")
	_same("punktpunkt_an_der_wurzel_echtes_profil", "C:/../Users/b/AppData/Roaming/x", TEMP, PROFILE, NORMAL, false, "neither")
	_same("punktpunkt_in_temp_zeigt_auf_profil", REAL, "C:\\Users\\b\\AppData\\Local\\Temp\\..\\..\\..", PROFILE, NORMAL, false, "")
	_same("punktpunkt_in_temp_nur_rc", "C:/Users/b/Dokumente/x", "C:\\Users\\b\\AppData\\Local\\Temp\\..\\..\\..", PROFILE, NORMAL, false, "ancestors")
	_same("kurzname_in_temp_gegen_langen_namen", "C:/Users/bjoer/AppData/Local/Temp/x", "C:\\Users\\BJOERN~1\\AppData\\Local\\Temp", "C:\\Users\\bjoer", NORMAL, false, "neither")
	_same("laufwerksbuchstabe_klein_gross", "c:/users/b/appdata/local/temp/x", TEMP, PROFILE, NORMAL, true, "strictly below")
	# --- UNC (tatsaechliches Ergebnis festgehalten)
	_same("unc_temp_unter_unc_temp", "//server/share/Temp/x", "\\\\server\\share\\Temp", PROFILE, NORMAL, true, "strictly below")
	_same("unc_wurzel_als_temp_roaming", "//server/share/users/b/AppData/Roaming/x", "\\\\server\\share", PROFILE, NORMAL, false, "AppData/Roaming")
	# --- Kopiename ist bewusst genau (Gross/Klein)
	_same("kopiename_klein_ausserhalb_temp", "C:/x/Review2/user", TEMP, PROFILE, "sb-codex-review2-x", false, "neither")
	_same("kopiename_klein_echtes_profil", REAL, TEMP, PROFILE, "sb-codex-review2-x", false, "neither")
	# --- Ablehnung nennt Grund
	var verdict: Dictionary = GUARD.isolation_verdict(REAL, REAL, REAL, NORMAL, TEMP, PROFILE)
	_check("ablehnung_nennt_grund", not String(verdict.get("reason", "")).is_empty())
	# --- system_temp_dir liest TEMP, faellt auf TMP zurueck
	_test_system_temp_dir()
	# --- Beobachtung: was macht simplify_path aus den Randfaellen
	for sample in ["../Temp/x", "C:/../Users/b", "C:/Users/b/AppData/Local/Temp/../../..", "//server/share/Temp/x", "\\\\server\\share\\Temp", "C:", ".", "/", "tmp"]:
		print("SIMPLIFY ", sample, " -> ", GUARD.normalize_path(sample))
	print("REVIEW2_ISOLATION_GUARD passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_system_temp_dir() -> void:
	var old_temp: String = OS.get_environment("TEMP")
	var old_tmp: String = OS.get_environment("TMP")
	OS.set_environment("TEMP", "C:\\a")
	OS.set_environment("TMP", "C:\\b")
	_check("systemtemp_temp_gewinnt", GUARD.system_temp_dir() == "C:\\a")
	OS.set_environment("TEMP", "")
	_check("systemtemp_faellt_auf_tmp_zurueck", GUARD.system_temp_dir() == "C:\\b")
	OS.set_environment("TMP", "")
	_check("systemtemp_beide_leer_ist_leer", GUARD.system_temp_dir() == "")
	OS.set_environment("TEMP", old_temp)
	OS.set_environment("TMP", old_tmp)
	_check("systemtemp_umgebung_zurueckgesetzt", OS.get_environment("TEMP") == old_temp and OS.get_environment("TMP") == old_tmp)


func _same(label: String, dir: String, temp_dir: String, profile: String, app_name: String, want_ok: bool, reason_part: String) -> void:
	_expect(label, dir, dir, dir, app_name, temp_dir, profile, want_ok, reason_part)


func _expect(label: String, expected_dir: String, actual_dir: String, localized_dir: String, app_name: String, temp_dir: String, profile: String, want_ok: bool, reason_part: String) -> void:
	var verdict: Dictionary = GUARD.isolation_verdict(expected_dir, actual_dir, localized_dir, app_name, temp_dir, profile)
	var reason := String(verdict.get("reason", ""))
	var ok: bool = bool(verdict.get("ok", not want_ok)) == want_ok and (reason_part.is_empty() or reason.contains(reason_part))
	if not ok:
		print("   got ok=", verdict.get("ok"), " reason=", reason)
	_check(label, ok)


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("FAIL ", label)
