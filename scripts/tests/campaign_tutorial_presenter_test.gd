extends SceneTree
class RuntimeProbe:
	extends Node
	var snapshot: Dictionary = {"mode":"campaign","onboarding":{"stage_index":0,"next_step_id":"base_ready","facts":{},"completed":false}}
	func get_snapshot() -> Dictionary:
		return snapshot.duplicate(true)
var failed: int = 0
var checks: int = 0
func _init() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed += 1
		print("FAIL " + message)
func run() -> void:
	var path := "res://scripts/meta/campaign_tutorial_presenter.gd"
	check(ResourceLoader.exists(path), "Tutorial presenter exists")
	if not ResourceLoader.exists(path):
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var runtime := RuntimeProbe.new()
	root.add_child(runtime)
	var presenter = load(path).new()
	root.add_child(presenter)
	presenter.set_help_mode("compact")
	presenter.configure(runtime, null)
	var service = load("res://scripts/ui/contextual_help_service.gd").new()
	check(service.load_catalog() == OK, "Actual help catalog loads")
	for id in ["main_menu.campaign", "campaign.job", "campaign.boarding", "campaign.movement", "campaign.use", "campaign.trade", "campaign.return", "campaign.complete"]:
		check(not service.get_help_payload(id, true).get("detail_lines", []).is_empty(), "Actual catalog contains detail help: " + id)
	check(presenter.get("_hover_timer").wait_time == 0.45, "Hover/focus delay follows existing contract")
	var original := runtime.get_snapshot()
	check(presenter.get_presentation_snapshot().step_id == "base_ready", "Configure reads owner state")
	var child_count: int = presenter.get_child_count()
	var count: int = presenter.get_presentation_snapshot().render_count
	presenter.refresh()
	check(presenter.get_presentation_snapshot().render_count == count, "Unchanged refresh does not rebuild")
	check(presenter.get_child_count() == child_count, "Refresh preserves the Control tree")
	presenter.get("_hide_button").pressed.emit()
	check(presenter.get_presentation_snapshot().hints_hidden, "Hide guidance")
	presenter.get_node("CampaignGuidance").find_child("CampaignHelpButton", true, false).pressed.emit()
	check(not presenter.get_presentation_snapshot().hints_hidden, "Visible help reopens guidance")
	check(presenter.get_presentation_snapshot().popup_visible, "Visible help shows existing popup component")
	var popup_rect: Rect2 = presenter.get("_popup").get_global_rect()
	check(popup_rect.end.x < root.size.x - 330, "Help stays left of the mission service card")
	presenter._end_hover()
	check(presenter.get("_hide_timer").is_stopped(), "Explicit pinned help survives pointer exit")
	check(runtime.get_snapshot() == original, "Hide/reopen never advances owner progress")
	var ids := {"base_ready":"campaign.boarding","satellite_completed":"campaign.movement","satellite_home":"campaign.return","trade_departed":"campaign.trade","trade_used":"campaign.use","bought":"campaign.trade","refueled":"campaign.trade","trade_home":"campaign.return","completed":"campaign.complete"}
	for step in ids:
		runtime.snapshot.onboarding.next_step_id = step
		runtime.snapshot.onboarding.stage_index = 3 if step == "completed" else (2 if step in ["trade_departed","trade_used","bought","refueled","trade_home"] else (0 if step == "base_ready" else 1))
		presenter.refresh()
		var view: Dictionary = presenter.get_presentation_snapshot()
		check(view.help_id == ids[step] and not String(view.guidance).is_empty(), "Runtime step maps to actionable help: " + step)
	presenter.set_help_mode("off")
	presenter.get_node("CampaignGuidance").find_child("CampaignHelpButton", true, false).pressed.emit()
	check(not presenter.get_presentation_snapshot().popup_visible, "Off setting blocks help popup")
	runtime.snapshot.mode = "skirmish"
	presenter.refresh()
	check(not presenter.visible, "Skirmish has no campaign tutorial")
	presenter.free()
	runtime.free()
	print("Campaign presenter: %d checks, %d failures" % [checks, failed])
	quit(1 if failed else 0)
