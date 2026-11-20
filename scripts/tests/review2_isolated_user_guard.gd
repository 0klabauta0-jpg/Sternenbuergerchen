extends Node

## Test-only autoload, injected into an isolated project before other autoloads.
## Fail synchronously: queueing quit() could still allow a later startup save.
static func normalize_path(path: String) -> String:
	return path.replace("\\", "/").simplify_path().trim_suffix("/")


## Reine Entscheidung ohne Seiteneffekte. Zugelassen wird nur, wenn der erwartete
## Ordner gesetzt ist und user:// genau dort liegt UND entweder das Projekt eine
## umbenannte Review2-Kopie ist ODER der Ordner echt unterhalb des System-Temp-
## Verzeichnisses liegt. Der echte Spielstand liegt unter %APPDATA% und nie dort.
static func isolation_verdict(expected_dir: String, actual_dir: String, localized_dir: String, app_name: String, temp_dir: String) -> Dictionary:
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
	if not expected.begins_with(temp + "/") or expected.length() <= temp.length() + 1:
		return {"ok": false, "reason": "user:// is neither a review2 project copy nor strictly below the system temp directory"}
	return {"ok": true, "reason": "user:// is strictly below the system temp directory"}


static func system_temp_dir() -> String:
	var temp: String = OS.get_environment("TEMP")
	if temp.is_empty():
		temp = OS.get_environment("TMP")
	return temp


static func require_isolated_user_data() -> bool:
	var verdict: Dictionary = isolation_verdict(
		OS.get_environment("SB_REVIEW2_USER_DIR"),
		OS.get_user_data_dir(),
		ProjectSettings.globalize_path("user://"),
		String(ProjectSettings.get_setting("application/config/name", "")),
		system_temp_dir())
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
