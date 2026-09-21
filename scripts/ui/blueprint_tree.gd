extends Window
## Read-only projection of the actual recipe catalogue and confirmed unlocks.
const Catalog=preload("res://scripts/core/catalog.gd")
var _body: RichTextLabel

func _ready() -> void:
	title="Baupläne & Entwicklung"
	size=Vector2i(820,620)
	close_requested.connect(hide)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	_body=RichTextLabel.new()
	_body.bbcode_enabled=true
	margin.add_child(_body)
	hide()

func open_tree(state: Dictionary) -> void:
	present(state)
	popup_centered(size)

func present(state: Dictionary) -> void:
	var unlocked: Array=state.get("blueprints",[])
	var tier:=int(state.get("base",{}).get("workbench_tier",1))
	var lines: Array[String]=["[font_size=26][color=#ffb35c]Baupläne & Entwicklung[/color][/font_size]", "Werkbank Stufe %d · %d vorhandene Baupläne" % [tier,unlocked.size()], "", "[b]Erste Bergung → Blackbox ins Basislager → Auftrag abgeben[/b]", "└ Schneider-Bauplan + 260 Credits", "   └ Werkbank Stufe 2 + Technik 3 + Material → Schneider", "", "[b]Vorhandene Rezepte und Voraussetzungen[/b]"]
	for id: String in Catalog.recipes():
		var recipe: Dictionary=Catalog.recipes()[id]
		var available: bool=id in unlocked or id=="upgrade_workbench"
		var materials: Array[String]=[]
		for item: String in recipe.materials:
			materials.append("%s %d/%d" % [Catalog.item_name(item),int(state.get("inventory",{}).get(item,0)),int(recipe.materials[item])])
		lines.append("\n[color=%s][b]%s · %s[/b][/color]" % ["#69d5c9" if available else "#a7b5bf",recipe.label,"Bauplan vorhanden" if available else "Bauplan fehlt"])
		lines.append("Werkbank %d · Technik %d · %s" % [int(recipe.get("tier",1)),int(recipe.min_skill),", ".join(materials)])
		if tier<int(recipe.get("tier",1)):lines.append("[color=#ffb35c]Zuerst Werkbank ausbauen.[/color]")
	lines.append("\n[b]Forschung · noch nicht spielbar[/b]\nForschungsraum, Forschungsaufträge und weiterführende Technologien sind geplant. Hier werden keine nicht vorhandenen Freischaltungen vorgetäuscht.\n\nHerstellung und Werkbankausbau erfolgen an der Werkbank mit einer verfügbaren Fachkraft.")
	_body.text="\n".join(lines)
