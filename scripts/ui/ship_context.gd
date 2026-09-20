extends RefCounted
## Ship actions describe boarding, local flight and inter-map travel separately.

static func build(hud: Node) -> void:
	hud._button("Plätze & Einsteigen",func():hud.action_requested.emit("boarding_menu",{}),hud._context_actions,46)
	hud._button("Crew aussteigen",func():hud.action_requested.emit("disembark_selected",{}),hud._context_actions,46)
	hud._add_command("launch","Abheben","launch")
	hud._add_command("enter_orbit","In den Orbit","enter_orbit")
	hud._button("Reisekarte öffnen",func():hud.action_requested.emit("travel_chart",{}),hud._context_actions,46)
	hud._add_command("land","Hier landen","land")
	hud._button("Patrouille setzen",func():hud.action_requested.emit("flight_order",{"mode":"patrol"}),hud._context_actions,40)
	hud._button("Suchgebiet setzen",func():hud.action_requested.emit("flight_order",{"mode":"search"}),hud._context_actions,40)
	hud._add_command("ship_stop","Position halten","ship_order",{"mode":"stop"})
	hud._button("Fracht ansehen",func():hud.select_object("object","storage"),hud._context_actions,40)
	hud._worker.visible=true
	hud._add_command("field_repair","Feldreparatur","field_repair",{},true)
	if hud._state.get("rental",{}).get("active",false):hud._add_command("return_rental","Mietschiff zurückgeben","return_rental")

static func present(hud: Node) -> void:
	var s: Dictionary=hud._state
	var ship: Dictionary=s.ship
	var seats: Dictionary=ship.get("seats",{})
	var lines:=PackedStringArray()
	for seat: String in ["pilot","gunner","passenger_1","passenger_2"]:
		var id: String=str(seats.get(seat,""))
		var unit: Dictionary=s.crew.get(id,{})
		var label: String={"pilot":"Pilot","gunner":"Turm","passenger_1":"Passagier 1","passenger_2":"Passagier 2"}[seat]
		lines.append(label+": "+(str(unit.get("name",id))+(" · unterwegs" if unit.get("assignment","")=="boarding" else "") if not id.is_empty() else "frei"))
	hud._context_title.text=str(ship.get("name","Entersäbel"))
	hud._context_text.text="[b]%s · %d %% Zustand[/b]\nFracht: %d / %d\n\n%s" % ["Im Flug" if ship.mode=="flying" else "Gelandet",int(ship.condition),hud._cargo_used(),int(ship.capacity),"\n".join(lines)]
	var all_aboard:=true
	for unit: Dictionary in s.crew.values():
		if str(unit.get("assignment",""))!="aboard":all_aboard=false
	var busy: bool=bool(s.travel.active)
	hud._disable("field_repair",str(ship.mode)!="landed" or float(ship.condition)>=70.0)
	hud._disable("launch",busy or str(ship.mode)!="landed" or not all_aboard or str(seats.get("pilot","")).is_empty())
	hud._disable("enter_orbit",busy or str(ship.mode)!="flying" or str(s.region) in ["orbit","space"])
	hud._disable("land",busy or str(ship.mode)!="flying" or str(s.region) in ["orbit","space"])
	hud._disable("return_rental",str(s.region) not in ["base","station"] or str(ship.mode)!="landed")
	hud._hint.text="Rechtsklick: einsteigen, Plätze nach Fähigkeiten. Umschalt+Rechtsklick oder Plätze: Rollen selbst zuweisen. Abheben erst mit Crew an Bord."
	hud._context_text.text+="\n\nFeldreparatur: Multi-Tool + Reparatur-Aufsatz, 1 Bauteil im Rucksack, Nähe 6 m am Zugang. Bis 70 %; danach Werkstatt."
	if str(ship.mode)=="flying":hud._hint.text="Rechtsklick auf die Welt: lokales Flugziel. Neue Orte wählst du auf der Reisekarte im Orbit."
	if s.get("rental",{}).get("active",false):hud._context_text.text+="\n\nMiete: %d s verbleiben" % int(s.rental.remaining)

	var order: Dictionary=ship.get("order",{})
	if not order.is_empty():hud._context_text.text+="\nFlugauftrag: "+("Patrouille" if order.kind=="patrol" else "Suchraster")+" · Punkt %d / %d" % [int(order.index)+1,order.points.size()]
