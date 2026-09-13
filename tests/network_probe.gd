extends "res://tests/internet_process_probe.gd"
## Compatibility entry point: current N4 shared-crew probe over ENet.
func _initialize() -> void:
	lan = true
	super._initialize()
