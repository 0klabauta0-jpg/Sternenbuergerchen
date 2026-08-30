extends SceneTree

const AUTOLOADS := {
	"NetworkTime": "res://addons/netfox/network-time.gd",
	"NetworkTimeSynchronizer": "res://addons/netfox/network-time-synchronizer.gd",
	"NetworkRollback": "res://addons/netfox/rollback/network-rollback.gd",
	"NetworkEvents": "res://addons/netfox/network-events.gd",
	"NetworkPerformance": "res://addons/netfox/network-performance.gd",
	"RollbackSimulationServer": "res://addons/netfox/servers/rollback-simulation-server.gd",
	"NetworkHistoryServer": "res://addons/netfox/servers/network-history-server.gd",
	"NetworkSynchronizationServer": "res://addons/netfox/servers/network-synchronization-server.gd",
	"NetworkIdentityServer": "res://addons/netfox/servers/network-identity-server.gd",
	"NetworkCommandServer": "res://addons/netfox/servers/network-command-server.gd",
	"RollbackLivenessServer": "res://addons/netfox/servers/rollback-liveness-server.gd",
}

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	var project_text := _read("res://project.godot")
	for autoload_name in AUTOLOADS:
		var expected_path: String = AUTOLOADS[autoload_name]
		var configured_value := _autoload_value(project_text, autoload_name)
		_check(configured_value == "*%s" % expected_path, "%s uses its stable res:// script path" % autoload_name)
		_check(ResourceLoader.exists(expected_path, "Script"), "%s script is loadable" % autoload_name)
	var runner_text := _read("res://scripts/tests/run_task_1182_clean_checkout_netfox_autoload_contract.ps1")
	_check(runner_text.contains("PreImport"), "Runner supports a pre-import clean-checkout phase")
	_check(runner_text.contains("PostImport"), "Runner supports a post-import smoke phase")
	_check(runner_text.contains("ls-files --error-unmatch"), "Runner proves each autoload script is tracked")
	_check(runner_text.contains("Unrecognized UID"), "Runner rejects UID resolution errors from the smoke log")
	_check(runner_text.contains("Failed to instantiate an autoload"), "Runner rejects autoload failures from the smoke log")
	_finish()


func _autoload_value(project_text: String, autoload_name: String) -> String:
	for line in project_text.split("\n"):
		if line.begins_with("%s=" % autoload_name):
			return line.get_slice("=", 1).strip_edges().trim_prefix("\"").trim_suffix("\"")
	return ""


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TASK_1182 PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("TASK_1182 FAIL: %s" % failure)
	quit(1)
