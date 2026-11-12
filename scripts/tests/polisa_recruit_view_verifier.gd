extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var view_script = load("res://scripts/ui/polisa_recruitment_view.gd")
	if view_script == null:
		printerr("FAIL: recruitment view missing")
		quit(1)
		return
	var generator = load("res://scripts/meta/polisa_recruit_offers.gd")
	var view = view_script.new()
	root.add_child(view)
	var offers: Array = generator.build_offers("ui-test", {"unit_id":"recruiter", "skill_values":{"leadership":0.5}, "communication_values":{"speech_quality":0.5}}, {})
	view.show_offers(offers, 0, 1, 2, false)
	if view.get_card_count() != 4 or view.get_bed_warning().is_empty():
		printerr("FAIL: cards or bed warning")
		quit(1)
		return
	view.set_compared(offers[0].id, true)
	view.set_compared(offers[1].id, true)
	if view.get_comparison_count() != 2:
		printerr("FAIL: selected comparison")
		quit(1)
		return
	view.show_offers(offers, 0, 3, 2, true)
	if not view.get_bed_warning().is_empty():
		printerr("FAIL: available bed incorrectly warned")
		quit(1)
		return
	var first_card: Node = view._cards.get_child(0)
	var buttons: Array = first_card.find_children("*", "Button", true, false)
	var hire: Button = null
	for button: Button in buttons:
		if button.text == "Anwerben": hire = button
	if hire == null or not hire.disabled:
		printerr("FAIL: insufficient credits must disable hire")
		quit(1)
		return
	view.queue_free()
	print("PASS: offer cards, bed warning and comparison")
	quit(0)
