extends Node

## Test-only autoload, injected into an isolated project before other autoloads.
## Fail synchronously: queueing quit() could still allow a later startup save.
static func require_isolated_user_data() -> bool:
	var expected: String = OS.get_environment("SB_REVIEW2_USER_DIR").replace("\\", "/").simplify_path().trim_suffix("/")
	var actual: String = OS.get_user_data_dir().replace("\\", "/").simplify_path().trim_suffix("/")
	var app_name: String = String(ProjectSettings.get_setting("application/config/name", ""))
	var localized: String = ProjectSettings.globalize_path("user://").replace("\\", "/").simplify_path().trim_suffix("/")
	if expected.is_empty() or not app_name.begins_with("SB-Codex-Review2-") or actual.to_lower() != expected.to_lower() or localized.to_lower() != expected.to_lower():
		push_error("REVIEW2_ISOLATION_REFUSED: test requires a separate verified user:// directory")
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
