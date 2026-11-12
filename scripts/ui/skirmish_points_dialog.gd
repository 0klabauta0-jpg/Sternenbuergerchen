extends AcceptDialog

signal start_requested(draft: Dictionary)


func _ready() -> void:
	title = "Skirmish · Startbudget"
	ok_button_text = "Zurück"
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(580, 180)
	content.add_theme_constant_override("separation", 16)
	add_child(content)
	var description := Label.new()
	description.text = "Starte an deiner Basis. Kaufe dort Personal, Ausrüstung, Schiffe und Gebäude mit deinem Punktebudget."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 22)
	content.add_child(description)
	for budget: int in [1000, 1500]:
		var button := Button.new()
		button.name = "StartBudget%d" % budget
		button.text = "%s Punkte · Basis aufbauen" % ("1.000" if budget == 1000 else "1.500")
		button.custom_minimum_size.y = 54
		button.add_theme_font_size_override("font_size", 22)
		content.add_child(button)
		button.pressed.connect(func(): start_requested.emit({"budget": budget, "base_setup": true, "people": [], "ships": []}))
