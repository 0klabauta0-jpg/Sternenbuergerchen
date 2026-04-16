class_name DropshipTestScreen
extends Control

signal launch_completed()

var _timer: Timer
var _progress: float = 0.0


func _ready() -> void:
	var launch_button: Button = get_node("Panel/Margin/VBox/LaunchButton")
	if not launch_button.pressed.is_connected(_on_launch_button_pressed):
		launch_button.pressed.connect(_on_launch_button_pressed)

	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.one_shot = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)


func _on_launch_button_pressed() -> void:
	var launch_button: Button = get_node("Panel/Margin/VBox/LaunchButton")
	launch_button.disabled = true
	_timer.start()
	_update_status()


func _on_timer_timeout() -> void:
	_progress += 1.0
	_update_status()
	if _progress >= 3.0:
		_timer.stop()
		launch_completed.emit()


func _update_status() -> void:
	var status_label: Label = get_node("Panel/Margin/VBox/StatusLabel")
	var progress_bar: ProgressBar = get_node("Panel/Margin/VBox/ProgressBar")
	progress_bar.value = _progress

	if _progress < 1.0:
		status_label.text = "Preparing dropship for launch..."
	elif _progress < 2.0:
		status_label.text = "Loading team..."
	elif _progress < 3.0:
		status_label.text = "Final checks..."
	else:
		status_label.text = "Launch complete!"