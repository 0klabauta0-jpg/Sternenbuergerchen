extends RefCounted
## Context UI for shared crew resource sites, lifts and ground attacks.
const Regions=preload("res://scripts/core/regions.gd")
const Catalog = preload("res://scripts/core/catalog.gd")

static func build(hud:Node,id:String)->bool:
	if Catalog.resource_sites().has(id):
		hud._worker.visible = true
		hud._add_command("gather","Material gewinnen","gather",{"site_id":id},true)
		hud._add_command("cancel_gather","Arbeit abbrechen","cancel_gather")
		return true
	if id in ["bunker_entry","elevator"]:
		hud._button("Crew zum Aufzug",func():hud.action_requested.emit("rally_elevator",{"object_id":id}),hud._context_actions,48)
		hud._add_command("use_elevator","Aufzug benutzen","use_elevator")
		return true
	var enemies:Dictionary=hud._state.get("ground",{}).get("enemies",{}).get(str(hud._state.get("region","")),{})
	if enemies.has(id):
		hud._add_command("attack","Angreifen","attack",{"target_id":id},true)
		hud._add_command("stop_attack","Angriff einstellen","attack",{"target_id":""},true)
		return true
	return false

static func present(hud:Node,id:String)->bool:
	var s:Dictionary=hud._state
	var actor:Dictionary=s.crew.get(hud.selected_unit,{})
	var activity:Dictionary=s.get("ground",{}).get("activity",{})
	if Catalog.resource_sites().has(id):
		var site:Dictionary=Catalog.resource_sites()[id]
		var remaining:int=int(s.get("resources",{}).get(id,{}).get("remaining",0))
		hud._context_title.text=str(site.get("label",site.get("name",Catalog.item_name(str(site.get("item",""))))))
		if hud._context_title.text.is_empty():hud._context_title.text=id.replace("_"," ").capitalize()
		hud._context_text.text="[b]Noch %d Einheiten[/b]\nDie gewählte Person geht zur Fundstelle und arbeitet dort.\n\nFracht: %d / %d" % [remaining,hud._cargo_used(),int(s.ship.capacity)]
		var active:bool=bool(activity.get("active",false))
		var equipment:Dictionary=actor.get("equipment",{})
		var tool:String=str(equipment.get("tool",""))
		var attachment:String=str(equipment.get("attachment",""))
		var tool_blocked:String=""
		if id=="mining_site" and not (tool=="multitool" and attachment=="mining_attachment"):
			tool_blocked="Mining erfordert ein angelegtes Multi-Tool mit Mining-Aufsatz."
		elif Regions.object_base(id) in ["derelict","distribution_wreck"] and not (tool=="cutter" or (tool=="multitool" and attachment=="salvage_attachment")):
			tool_blocked="Wrackbergung erfordert einen Schneider oder ein Multi-Tool mit Berge-Aufsatz."
		hud._disable("gather",remaining<=0 or active or not tool_blocked.is_empty() or not hud._owns(hud.selected_unit) or actor.get("assignment","idle")!="idle" or str(s.ship.get("mode","landed"))=="flying")
		hud._disable("cancel_gather",not active or not hud._owns(str(activity.get("unit_id",""))))
		if active:hud._show_progress(activity,"Materialgewinnung")
		hud._worker.disabled=active
		hud._hint.text="Technik und ausgerüstetes Werkzeug verkürzen die Arbeit.\nDer gemietete Geier liefert am Schiffswrack mehr Material."
		if not active and not tool_blocked.is_empty():hud._hint.text=tool_blocked+"\nAusrüstung im Crew-Dossier anlegen."
		return true
	if id in ["bunker_entry","elevator"]:
		hud._context_title.text="Bunkeraufzug"
		hud._context_text.text="[b]%s[/b]\n\nVersammelt die Crew am Aufzug. Beide Commander dürfen den Wechsel auslösen; das Ziel ist eine eigene Karte." % ("Zur unterirdischen Anlage" if not Regions.underground(s.region) else "Zur Oberfläche")
		hud._disable("use_elevator",bool(s.get("travel",{}).get("active",false)))
		hud._hint.text="Im Koop könnt ihr beide die gesamte Crew zum Aufzug führen."
		return true
	var enemies:Dictionary=s.get("ground",{}).get("enemies",{}).get(str(s.region),{})
	if enemies.has(id):
		var enemy:Dictionary=enemies[id]
		hud._context_title.text=str(enemy.get("name","Gegner"))
		hud._context_text.text="[b]%d / %d Zustand[/b]\n\n%s" % [int(enemy.get("health",0)),int(enemy.get("max_health",1)),"Flak bedroht nahe fliegende Schiffe. Entfernt landen und am Boden vorgehen." if enemy.get("kind","")=="aa" else "Ein einfacher Wachposten. Die gewählte Figur nähert sich und feuert bei freier Schusslinie."]
		hud._disable("attack",bool(enemy.get("defeated",false)) or not hud._owns(hud.selected_unit) or int(actor.get("health",100))<=0 or str(s.ship.get("mode","landed"))=="flying")
		hud._disable("stop_attack",not hud._owns(hud.selected_unit) or str(actor.get("attack_target","" )).is_empty())
		hud._hint.text="Geschützkenntnis wirkt auch am Boden. Rüstung reduziert eingehenden Schaden."
		return true
	return false
