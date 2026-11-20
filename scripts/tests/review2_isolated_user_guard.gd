extends Node

## Test-only autoload, injected into an isolated project before other autoloads.
## Fail synchronously: queueing quit() could still allow a later startup save.
static func normalize_path(path: String) -> String:
	return path.replace("\\", "/").simplify_path().trim_suffix("/")


## Reine Entscheidung ohne Seiteneffekte. Zugelassen wird nur, wenn der erwartete
## Ordner gesetzt ist und user:// genau dort liegt UND entweder das Projekt eine
## umbenannte Review2-Kopie ist ODER der Ordner echt unterhalb des System-Temp-
## Verzeichnisses liegt. Der echte Spielstand liegt unter %APPDATA% und nie dort.
## user_profile_dir ist %USERPROFILE% (die APPDATA-Umleitung beruehrt ihn nicht); ein
## leerer Wert lehnt den Temp-Zweig ab. Alle sechs Werte sind Pflicht.
static func isolation_verdict(expected_dir: String, actual_dir: String, localized_dir: String, app_name: String, temp_dir: String, user_profile_dir: String) -> Dictionary:
	var expected: String = normalize_path(expected_dir).to_lower()
	var actual: String = normalize_path(actual_dir).to_lower()
	var localized: String = normalize_path(localized_dir).to_lower()
	if expected.is_empty():
		return {"ok": false, "reason": "SB_REVIEW2_USER_DIR is not set"}
	if actual != expected or localized != expected:
		return {"ok": false, "reason": "user:// does not resolve to SB_REVIEW2_USER_DIR"}
	if app_name.begins_with("SB-Codex-Review2-"):
		return {"ok": true, "reason": "renamed review2 project copy"}
	var temp: String = normalize_path(temp_dir).to_lower()
	# Ein nacktes Laufwerk oder Wurzelverzeichnis ist kein Temp-Ordner.
	if temp.is_empty() or not temp.contains("/") or temp.ends_with(":"):
		return {"ok": false, "reason": "no usable system temp directory"}
	if not expected.begins_with(temp + "/"):
		return {"ok": false, "reason": "user:// is neither a review2 project copy nor strictly below the system temp directory"}
	# TEMP/TMP wird nicht blind geglaubt. Der Temp-Zweig nimmt nur an, was alle Regeln erfuellt:
	# UNC-Pfade sind hier nie zugelassen (umgeleitetes Roaming liegt oft auf einer Freigabe).
	if expected.begins_with("//") or temp.begins_with("//"):
		return {"ok": false, "reason": "UNC paths are not accepted in the temp branch"}
	# Der echte Spielstand liegt unter APPDATA (Roaming).
	if (expected + "/").contains("/appdata/roaming/"):
		return {"ok": false, "reason": "user:// lies in an AppData/Roaming folder (the real save location)"}
	var profile: String = normalize_path(user_profile_dir).to_lower()
	if profile.is_empty():
		return {"ok": false, "reason": "USERPROFILE is not set, cannot rule out the real profile"}
	# Temp darf nie der Benutzerordner oder ein Vorfahre davon sein.
	if (profile + "/").begins_with(temp + "/"):
		return {"ok": false, "reason": "system temp directory is the user profile or one of its ancestors"}
	# Positive Kennung: der erste Ordner unterhalb von Temp ist ein sb_*-Wegwerf-Profil.
	# Pfade sind kleingeschrieben normalisiert, also gilt auch "SB_Test".
	var first_folder: String = expected.substr(temp.length() + 1).get_slice("/", 0)
	if not (first_folder.begins_with("sb_") and first_folder.length() > 3):
		return {"ok": false, "reason": "user:// is below temp but not inside an sb_* throwaway profile"}
	return {"ok": true, "reason": "user:// is strictly below the system temp directory"}


static func system_temp_dir() -> String:
	var temp: String = OS.get_environment("TEMP")
	if temp.is_empty():
		temp = OS.get_environment("TMP")
	return temp


## Sammelt die sechs Werte aus der Umgebung und entscheidet. Kein Abbruch.
static func verdict_from_environment() -> Dictionary:
	return isolation_verdict(
		OS.get_environment("SB_REVIEW2_USER_DIR"),
		OS.get_user_data_dir(),
		ProjectSettings.globalize_path("user://"),
		String(ProjectSettings.get_setting("application/config/name", "")),
		system_temp_dir(),
		OS.get_environment("USERPROFILE"))


static func require_isolated_user_data() -> bool:
	var verdict: Dictionary = verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		push_error("REVIEW2_ISOLATION_REFUSED: test requires a separate verified user:// directory (" + String(verdict.get("reason", "")) + ")")
		OS.kill(OS.get_process_id())
		OS.crash("Isolation guard could not terminate its own process")
		return false
	return true


func _init() -> void:
	if not require_isolated_user_data():
		return
	var canary := FileAccess.open("user://review2_isolation_canary.json", FileAccess.WRITE)
	if canary == null:
		push_error("REVIEW2_ISOLATION_REFUSED: cannot write isolated canary")
		OS.kill(OS.get_process_id())
		OS.crash("Isolation canary guard could not terminate its own process")
		return
	canary.store_string(JSON.stringify({"user_dir": OS.get_user_data_dir(), "project": ProjectSettings.get_setting("application/config/name")}))
	canary.close()
	print("REVIEW2_ISOLATED_USER_DATA ", OS.get_user_data_dir())
