extends SceneTree
## Flugdeck-Aufbau v2 (20261125): von links Schiffsdetail, Schiffsleiste, Liste Personal, Liste Trupps, Vorschau.
var checks := 0
var failures := 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)
	else:
		print("PASS: ", label)
func _settle(presenter: Node) -> void:
	presenter.refresh()
	for i in 6: await process_frame

func _snapshot_craft(screen: Node, id: String) -> Dictionary:
	for craft in Array(screen.call("get_operations_snapshot").get("crafts", [])):
		if String(Dictionary(craft).id) == id: return Dictionary(craft)
	return {}

## Sitzplaetze im Schiffsdetail: Passagierplaetze nach Kapazitaet, Ziehen auf Pilotplatz und Passagierplaetze.
func _seats(screen: Node, presenter: Node) -> void:
	var crafts: Array = Array(screen.call("get_operations_snapshot").get("crafts", []))
	var small := ""
	var big := ""
	# Startschiff wie im Kampagnenstart: Entermesser = Cutlass, 1 Pilot + 1 Turmschuetze (gesperrt) + 6 Passagierplaetze.
	var starter: Dictionary = _snapshot_craft(screen, "dropship_1")
	if not starter.is_empty():
		screen.request_operation("craft", {"craft_id": "dropship_1"})
		await _settle(presenter)
		var starter_detail: Node = presenter.find_child("ShipDetail", true, false)
		var starter_seats := starter_detail.find_children("TroopSlot_*", "", true, false).size()
		check(int(starter.get("crew_capacity", 0)) == 8 and String(starter.get("model_id", "")) == "cutlass", "dropship_1: Kapazitaet 8, Modell cutlass (%s)" % str([starter.get("crew_capacity"), starter.get("model_id")]))
		check(starter_detail.find_child("PilotSlot", true, false) != null and (starter_detail.find_child("GunnerSlot", true, false) as Control).visible and starter_seats == 6, "dropship_1: Pilotplatz, gesperrter Turmschuetzenplatz, 6 Passagierplaetze (%d)" % starter_seats)
		check(starter_detail.find_child("TroopNote", true, false) == null, "dropship_1: 'Keine Passagierplaetze' fehlt")
	else:
		check(false, "dropship_1 fehlt in der Kampagnenstart-Welt")
	for craft_variant in crafts:
		var craft: Dictionary = Dictionary(craft_variant)
		screen.request_operation("craft", {"craft_id": String(craft.id)})
		await _settle(presenter)
		var detail: Node = presenter.find_child("ShipDetail", true, false)
		var seats := 0
		for node in detail.find_children("TroopSlot_*", "", true, false): seats += 1
		var layout: Dictionary = load("res://scripts/ui/components/ship_detail_panel.gd").seat_layout(craft)
		check(seats == int(layout.passengers) and int(layout.passengers) + int(layout.gunner) == maxi(int(craft.crew_capacity) - 1, 0), "Passagierplaetze %d + Turmschuetze %d == Kapazitaet %d - Pilot (%s)" % [seats, int(layout.gunner), int(craft.crew_capacity), craft.id])
		check(detail.find_child("GunnerSlot", true, false).visible == (int(layout.gunner) > 0), "Turmschuetzenplatz nur bei Schiffen mit solchem Platz (%s)" % craft.id)
		if int(craft.crew_capacity) <= 1 and small.is_empty(): small = String(craft.id)
		if int(craft.crew_capacity) > 1 and big.is_empty(): big = String(craft.id)
	if big.is_empty():
		big = String(Dictionary(crafts[0]).id)  # Testwelt ohne Schiff mit Sitzen: Baustein wird unten allein geprueft
	screen.request_operation("craft", {"craft_id": big})
	await _settle(presenter)
	var detail: Node = presenter.find_child("ShipDetail", true, false)
	var pilot_slot: Node = detail.find_child("PilotSlot", true, false)
	var snapshot: Dictionary = screen.call("get_operations_snapshot")
	var selected: Dictionary = Dictionary(snapshot.selected_craft)
	var person := ""
	for option in Array(selected.pilot_options):
		if not String(Dictionary(option).id).is_empty(): person = String(Dictionary(option).id)
	check(not person.is_empty(), "Person fuer den Pilotplatz vorhanden")
	var unit_payload := {"type": "homebase_unit_card", "unit_id": person, "label": "x"}
	check(not pilot_slot.call("_can_drop_data", Vector2.ZERO, {"type": "homebase_unit_card", "unit_id": "nobody"}), "PilotSlot lehnt unbekannte Person ab")
	check(not pilot_slot.call("_can_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": "ft1"}), "PilotSlot lehnt Trupp ab")
	check(pilot_slot.call("_can_drop_data", Vector2.ZERO, unit_payload), "PilotSlot nimmt Person an")
	pilot_slot.call("_drop_data", Vector2.ZERO, unit_payload)
	await _settle(presenter)
	check(String(_snapshot_craft(screen, String(selected.id)).get("pilot_id", "")) == person, "Person auf PilotSlot gezogen -> Pilot gesetzt")
	# Baustein allein, Schiff mit 8 Sitzen (Cutlass-Kapazitaet): Plaetze, Ziehen, volles Schiff.
	var solo: Node = load("res://scripts/ui/components/ship_detail_panel.gd").new()
	root.add_child(solo)
	var free := [6]
	solo.set("fireteam_check", func(id: String) -> String: return "" if free[0] >= 4 else "Nicht genug Plätze: Trupp hat 4, frei sind %d." % free[0])
	solo.set("pilot_validator", func(id: String) -> bool: return id == "u1")
	var dropped: Array = []
	var unboarded: Array = []
	solo.connect("fireteam_dropped", func(id: String): dropped.append("team:" + id))
	solo.connect("pilot_dropped", func(id: String): dropped.append("pilot:" + id))
	solo.connect("pilot_cleared", func(): dropped.append("pilot_cleared"))
	solo.connect("unboard_requested", func(id: String): unboarded.append(id))
	var cutlass := {"name": "Cutlass", "model_id": "cutlass", "crew_capacity": 8, "payload_names": ["Anna", "Ben"], "seat_team_ids": ["ft_a", "ft_a"], "pilot_name": ""}
	solo.call("update_craft", cutlass, {})
	var solo_seats := solo.find_children("TroopSlot_*", "", true, false)
	check(solo_seats.size() == 6, "Baustein Cutlass: 8 Sitze -> 6 Passagierplaetze")
	var gunner: Control = solo.find_child("GunnerSlot", true, false)
	check(gunner.visible and gunner.tooltip_text.contains("noch nicht besetzbar") and not gunner.call("_can_drop_data", Vector2.ZERO, {"type": "homebase_unit_card", "unit_id": "u1"}), "Baustein Cutlass: Turmschuetzenplatz sichtbar, gesperrt, nimmt nichts an")
	var small_craft := cutlass.duplicate()
	small_craft["model_id"] = "buccaneer"
	small_craft["crew_capacity"] = 4
	solo.call("update_craft", small_craft, {})
	check(solo.find_children("TroopSlot_*", "", true, false).size() == 3 and not (solo.find_child("GunnerSlot", true, false) as Control).visible, "Baustein anderes Schiff: 3 Passagierplaetze, kein Turmschuetze")
	solo.call("update_craft", cutlass, {})
	var s0: Node = solo.find_child("TroopSlot_0", true, false)
	var s2: Node = solo.find_child("TroopSlot_2", true, false)
	check(s0.find_child("SeatName", true, false).text == "Anna" and not s0.find_child("Hatch", true, false).visible, "Baustein: belegter Platz zeigt Namen, keine Schraffur")
	check(s2.find_child("SeatName", true, false).text == "Passagier" and s2.find_child("Hatch", true, false).visible, "Baustein: leerer Platz grau schraffiert mit 'Passagier'")
	var team_ok := {"type": "fob_fireteam_card", "fireteam_id": "ft_a"}
	check(s2.call("_can_drop_data", Vector2.ZERO, team_ok), "Baustein: Trupp auf Passagierplatz erlaubt")
	s2.call("_drop_data", Vector2.ZERO, team_ok)
	check(dropped == ["team:ft_a"] and not (solo.find_child("SeatMessage", true, false) as Control).visible, "Baustein: passender Trupp sendet Befehl, keine Meldung " + str(dropped))
	free[0] = 3
	s2.call("_drop_data", Vector2.ZERO, team_ok)
	var message: Label = solo.find_child("SeatMessage", true, false)
	check(dropped == ["team:ft_a"] and message.visible and message.text == "Nicht genug Plätze: Trupp hat 4, frei sind 3.", "Baustein: zu grosser Trupp abgelehnt mit Meldung '" + message.text + "'")
	var person_drop := {"type": "homebase_unit_card", "unit_id": "u1"}
	check(s2.call("_can_drop_data", Vector2.ZERO, person_drop), "Baustein: Person lichtet den Platz auf (wird mit Hinweis verworfen)")
	s2.call("_drop_data", Vector2.ZERO, person_drop)
	check(dropped == ["team:ft_a"] and message.text == "Einzelpersonen bitte als Trupp einsteigen lassen.", "Baustein: Einzelperson auf Passagierplatz -> Hinweis, kein Befehl")
	solo.call("_drop_fireteam", Vector2.ZERO, team_ok)
	check(dropped == ["team:ft_a"] and message.text.begins_with("Nicht genug"), "Baustein: Ablegen auf das Schiffsdetail prueft ebenso")
	var pilot_slot_solo: Node = solo.find_child("PilotSlot", true, false)
	pilot_slot_solo.call("_drop_data", Vector2.ZERO, person_drop)
	check(dropped == ["team:ft_a", "pilot:u1"], "Baustein: Person auf Pilotplatz sendet Pilot " + str(dropped))
	check(not pilot_slot_solo.call("_can_drop_data", Vector2.ZERO, {"type": "homebase_unit_card", "unit_id": "u2"}), "Baustein: Pilotplatz lehnt nicht erlaubte Person ab")
	check(solo.find_child("PilotName", true, false).text == "Pilot" and solo.find_child("PilotSlot", true, false).find_child("Hatch", true, false).visible and not (solo.find_child("PilotClear", true, false) as Control).visible, "Baustein: leerer Pilotplatz schraffiert, ohne Knopf")
	var with_pilot := cutlass.duplicate()
	with_pilot["pilot_name"] = "Kai"
	solo.call("update_craft", with_pilot, {})
	var clear: Button = solo.find_child("PilotClear", true, false)
	check(solo.find_child("PilotName", true, false).text == "Kai" and clear.visible, "Baustein: belegter Pilotplatz zeigt Namen und Knopf")
	clear.pressed.emit()
	(solo.find_child("SeatClear_0", true, false) as Button).pressed.emit()
	check(dropped.back() == "pilot_cleared" and unboarded == ["ft_a"], "Baustein: Knoepfe leeren Pilot und setzen Trupp ab")
	await _seat_cards(solo, dropped, presenter)
	solo.queue_free()
	if presenter.find_child("TroopSlot_0", true, false) == null: return
	# Trupp auf einen Passagierplatz.
	snapshot = screen.call("get_operations_snapshot")
	var team_id := ""
	for team_variant in Array(snapshot.fireteams):
		var team: Dictionary = Dictionary(team_variant)
		if not Array(team.members).is_empty() and not bool(team.busy): team_id = String(team.id)
	if team_id.is_empty():
		var other := ""
		for unit_variant in Array(snapshot.roster):
			var unit: Dictionary = Dictionary(unit_variant)
			if not bool(unit.busy) and String(unit.id) != person and other.is_empty(): other = String(unit.id)
		team_id = String(Dictionary(Array(snapshot.fireteams)[0]).id)
		var assigned: Dictionary = screen.request_operation("assign", {"unit_id": other, "fireteam_id": team_id})
		print("ASSIGN ", assigned)
		await _settle(presenter)
	var team_payload := {"type": "fob_fireteam_card", "fireteam_id": team_id, "label": "t"}
	var slot0: Node = presenter.find_child("TroopSlot_0", true, false)
	check(slot0 != null and slot0.call("_can_drop_data", Vector2.ZERO, team_payload), "Passagierplatz nimmt Trupp an")

	# Das Einsteigen laeuft im Spiel ueber den Basis-Laufweg (Personen gehen zum Schiff): sofort steht nichts an Bord.
	# Geprueft wird deshalb der Befehl: das Ablegen sendet `board` fuer diesen Trupp und dieses Schiff, ohne Ablehnungsmeldung.
	var board_calls: Array = []
	var detail_node: Node = presenter.find_child("ShipDetail", true, false)
	detail_node.connect("fireteam_dropped", func(id: String): board_calls.append(id))
	slot0.call("_drop_data", Vector2.ZERO, team_payload)
	for i in 30: await process_frame
	check(board_calls == [team_id] and not (presenter.find_child("SeatMessage", true, false) as Control).visible, "Trupp-Karte auf Passagierplatz abgelegt -> Befehl board fuer den Trupp, keine Ablehnung " + str(board_calls))
	check(String(presenter.get("_craft_id")) == String(selected.id) and not String(presenter.get("_fireteam_id")).is_empty(), "board geht an das gewaehlte Schiff")
	# Volles Schiff: ein Trupp, der nicht mehr passt, wird abgelehnt.
	if not small.is_empty():
		screen.request_operation("craft", {"craft_id": small})
		await _settle(presenter)
		var small_detail: Node = presenter.find_child("ShipDetail", true, false)
		check(not small_detail.call("_can_drop_fireteam", Vector2.ZERO, team_payload), "Schiff ohne freien Platz lehnt Trupp ab")
		check(not small_detail.call("_can_drop_fireteam", Vector2.ZERO, team_payload) and small_detail.find_children("TroopSlot_*", "", true, false).is_empty(), "Schiff mit einem Sitz hat keine Passagierplaetze")

## fs1 (20261125): Pilot nicht doppelt, Platzbedarf, Ablegen ohne Pilot, Ziehen vom Passagierplatz, Wartezustand, Karten, Trupp-Streifen.
func _seat_cards(solo: Node, dropped: Array, presenter: Node) -> void:
	var units := [
		{"id": "u_kai", "name": "Kai", "role": "Pilot", "status": "Boarding"},
		{"id": "u_anna", "name": "Anna", "role": "Sanität", "status": "An Bord"},
		{"id": "u_ben", "name": "Ben", "role": "Schütze", "status": "Boarding"},
		{"id": "u_cleo", "name": "Cleo", "role": "Technik", "status": "An Bord"}]
	var rich := {"name": "Cutlass", "model_id": "cutlass", "crew_capacity": 8, "pilot_name": "Kai", "pilot_id": "u_kai", "pilot_aboard": false,
		"pilot_unit": {"id": "u_kai", "name": "Kai", "role": "Pilot", "status": "Nicht an Bord · Pilot"},
		"payload_names": ["Kai", "Anna", "Ben", "Cleo"], "payload_unit_ids": ["u_kai", "u_anna", "u_ben", "u_cleo"],
		"seat_team_ids": ["ft_a", "ft_a", "ft_a", "ft_b"], "seat_units": units, "payload_aboard": [false, true, false, true]}
	solo.call("update_craft", rich, {})
	var seat_names: Array = []
	for node in solo.find_children("SeatName", "Label", true, false): seat_names.append((node as Label).text)
	check(solo.find_child("PilotName", true, false).text == "Kai" and not seat_names.has("Kai") and seat_names.has("Anna") and seat_names.has("Ben") and seat_names.has("Cleo"), "Pilot im Trupp steht nur im Pilotplatz, nicht zusaetzlich auf einem Passagierplatz " + str(seat_names))
	var anna: Node = solo.find_child("TroopSlot_0", true, false)
	var ben: Node = solo.find_child("TroopSlot_1", true, false)
	var cleo: Node = solo.find_child("TroopSlot_2", true, false)
	check(anna.find_child("SeatName", true, false).text == "Anna" and ben.find_child("SeatName", true, false).text == "Ben" and cleo.find_child("SeatName", true, false).text == "Cleo", "Passagierplaetze ruecken ohne den Piloten auf")
	# Karte wie unter Personal: Portraet, Name, Statuszeile (Pilot: Portraet, Name, Rolle und Status).
	check(anna.find_child("SeatPortrait", true, false) != null and anna.find_child("SeatName", true, false) != null and (anna.find_child("SeatStatus", true, false) as Label).text == "An Bord", "belegter Passagierplatz zeigt Portraet, Name und Statuszeile")
	var pilot_card: Control = solo.find_child("PilotCard", true, false)
	check(solo.find_child("PilotPortrait", true, false).visible and (solo.find_child("PilotInfo", true, false) as Label).text == "Pilot · Nicht an Bord · Pilot", "belegter Pilotplatz zeigt Portraet, Name, Rolle und Status")
	# Wartezustand: zugewiesen, aber nicht an Bord = gedimmt und pulsierend; an Bord = Vollfarbe.
	var anna_card: Control = anna.find_child("SeatCard", true, false)
	var ben_card: Control = ben.find_child("SeatCard", true, false)
	check(bool(pilot_card.get_meta("waiting", false)) and pilot_card.modulate.a < 0.71 and pilot_card.get("_tween") != null, "Pilot zugewiesen, nicht an Bord: Karte gedimmt und blinkend")
	check(bool(ben_card.get_meta("waiting", false)) and ben_card.modulate.a < 0.71 and ben_card.get("_tween") != null, "Passagier unterwegs zum Schiff: Karte gedimmt und blinkend")
	check(not bool(anna_card.get_meta("waiting", false)) and is_equal_approx(anna_card.modulate.a, 1.0) and anna_card.get("_tween") == null, "Passagier an Bord: Vollfarbe ohne Blinken")
	await create_timer(0.35).timeout
	check(ben_card.modulate.a >= 0.34 and ben_card.modulate.a <= 0.71, "Blinken bleibt im Bereich 0,35 bis 0,7 (%s)" % ben_card.modulate.a)
	var arrived := rich.duplicate(true)
	arrived["pilot_aboard"] = true
	arrived["payload_aboard"] = [true, true, true, true]
	solo.call("update_craft", arrived, {})
	pilot_card = solo.find_child("PilotCard", true, false)
	ben_card = solo.find_child("TroopSlot_1", true, false).find_child("SeatCard", true, false)
	check(is_equal_approx(pilot_card.modulate.a, 1.0) and pilot_card.get("_tween") == null and is_equal_approx(ben_card.modulate.a, 1.0), "Pilot und Passagier an Bord: Vollfarbe")
	solo.call("update_craft", rich, {})
	# Trupp-Streifen: gleiche Farbe je Trupp, andere Farbe fuer anderen Trupp, leere Plaetze ohne Streifen.
	anna = solo.find_child("TroopSlot_0", true, false)
	ben = solo.find_child("TroopSlot_1", true, false)
	cleo = solo.find_child("TroopSlot_2", true, false)
	var stripes: Array = []
	for slot in [anna, ben, cleo]: stripes.append(slot.find_child("TeamStripe", true, false))
	check(not stripes.has(null) and (stripes[0] as ColorRect).color == (stripes[1] as ColorRect).color and (stripes[0] as ColorRect).color != (stripes[2] as ColorRect).color, "Plaetze desselben Trupps haben denselben Streifen, anderer Trupp eine andere Farbe")
	check(solo.find_child("TroopSlot_3", true, false).find_child("TeamStripe", true, false) == null, "leerer Platz ohne Trupp-Streifen")
	# Ziehen vom Passagierplatz auf den Pilotplatz.
	var drag: Dictionary = Dictionary(anna.get("drag_payload"))
	check(String(drag.get("type", "")) == "homebase_unit_card" and String(drag.get("unit_id", "")) == "u_anna", "belegter Passagierplatz ist ziehbar mit Personen-Zieh-Daten " + str(drag))
	check(solo.find_child("TroopSlot_3", true, false).get("drag_payload").is_empty(), "leerer Platz ist nicht ziehbar")
	var pilot_slot: Node = solo.find_child("PilotSlot", true, false)
	var before: int = dropped.size()
	solo.set("pilot_validator", func(id: String) -> bool: return id == "u_anna")
	check(pilot_slot.call("_can_drop_data", Vector2.ZERO, drag), "Pilotplatz nimmt Person vom Passagierplatz an")
	pilot_slot.call("_drop_data", Vector2.ZERO, drag)
	check(dropped.size() == before + 1 and dropped.back() == "pilot:u_anna", "Ablegen auf dem Pilotplatz sendet pilot mit der richtigen Kennung " + str(dropped.back()))
	solo.set("pilot_validator", func(id: String) -> bool: return false)
	var ben_drag: Dictionary = Dictionary(ben.get("drag_payload"))
	pilot_slot.call("_drop_data", Vector2.ZERO, ben_drag)
	var message: Label = solo.find_child("SeatMessage", true, false)
	check(dropped.size() == before + 1 and message.visible and message.text == "Ben kann nicht Pilot werden.", "nicht pilotfaehige Person: Meldung statt Befehl '" + message.text + "'")
	solo.set("pilot_validator", func(id: String) -> bool: return id == "u1")
	# Platzbedarf und Ablegen ohne Pilot (Presenter-Regel): Trupp mit N Mitgliedern braucht N-1 Plaetze, wenn der Pilot dazugehoert.
	var saved_craft: Variant = presenter.get("_detail_craft")
	var saved_teams: Variant = presenter.get("_detail_fireteams")
	var seven: Array = []
	for i in 7: seven.append({"id": "m%d" % i})
	presenter.set("_detail_fireteams", [{"id": "big", "members": seven, "busy": false}, {"id": "duo", "members": [{"id": "m0"}, {"id": "m1"}], "busy": false}])
	presenter.set("_detail_craft", {"model_id": "cutlass", "crew_capacity": 8, "pilot_id": "m0", "payload_unit_ids": [], "payload_names": [], "busy": false})
	check(String(presenter.call("_fireteam_drop_message", "big")) == "", "Trupp mit 7 Mitgliedern inkl. Pilot braucht 6 Plaetze: passt auf Cutlass")
	presenter.set("_detail_craft", {"model_id": "cutlass", "crew_capacity": 8, "pilot_id": "other", "payload_unit_ids": [], "payload_names": [], "busy": false})
	check(String(presenter.call("_fireteam_drop_message", "big")).begins_with("Nicht genug Plätze: Trupp hat 7, frei sind 6"), "derselbe Trupp ohne Pilot im Trupp braucht 7 Plaetze: abgelehnt")
	presenter.set("_detail_craft", {"model_id": "cutlass", "crew_capacity": 8, "pilot_id": "", "payload_unit_ids": [], "payload_names": [], "busy": false})
	check(String(presenter.call("_fireteam_drop_message", "duo")) == "", "Ablegen eines Trupps ohne zugewiesenen Piloten wird nicht abgelehnt")
	presenter.set("_detail_craft", {"model_id": "cutlass", "crew_capacity": 8, "pilot_id": "m0", "payload_unit_ids": ["m0", "x1", "x2", "x3", "x4"], "payload_names": ["a", "b", "c", "d", "e"], "busy": false})
	check(String(presenter.call("_fireteam_drop_message", "duo")) == "" , "bereits eingestiegener Pilot zaehlt bei den belegten Plaetzen nicht mit (4 belegt, 2 frei)")
	presenter.set("_detail_craft", saved_craft)
	presenter.set("_detail_fireteams", saved_teams)

## fs1 Punkt 7: Mitgliederzeile in der Trupp-Spalte ist ziehbar; Ablegen auf Personal loest "aus Trupp entfernen" aus.
func _team_drag(screen: Node, presenter: Node) -> void:
	var snapshot: Dictionary = screen.call("get_operations_snapshot")
	var unit_id := ""
	for team_variant in Array(snapshot.fireteams):
		for member_variant in Array(Dictionary(team_variant).members):
			# Bevorzugt ein Mitglied, das nicht die Kampagnenfuehrung ist; in der Testwelt gibt es oft nur diese.
			if bool(Dictionary(member_variant).can_remove) and (unit_id.is_empty() or unit_id == "campaign_leader"):
				unit_id = String(Dictionary(member_variant).id)
	check(not unit_id.is_empty(), "Testwelt hat ein entfernbares Truppmitglied (%s)" % unit_id)
	if unit_id.is_empty(): return
	var member_row: Node = presenter.find_child("TeamMember_" + unit_id.validate_node_name(), true, false)
	check(member_row != null and member_row.is_visible_in_tree(), "Trupp-Spalte zeigt eine Mitgliederzeile je Mitglied")
	if member_row == null: return
	var drag: Dictionary = Dictionary(member_row.get("drag_payload"))
	check(String(drag.get("type", "")) == "homebase_unit_card" and String(drag.get("unit_id", "")) == unit_id, "Mitgliederzeile ist ziehbar mit Personen-Zieh-Daten " + str(drag))
	check(presenter.find_child("RemoveFromTeam", true, false) != null or presenter.get("_remove_member") != null, "Knopf 'Aus Trupp entfernen' bleibt erhalten")
	var roster_row: Node = Dictionary(presenter.get("_rows"))[unit_id].root
	check(not roster_row.call("_can_drop_data", Vector2.ZERO, {"type": "homebase_unit_card", "unit_id": unit_id, "source_context": "operations"}), "Personal-Zeile lehnt Personen aus der Personal-Liste selbst ab")
	check(roster_row.call("_can_drop_data", Vector2.ZERO, drag), "Personal-Spalte nimmt die gezogene Mitgliederzeile an")
	var landed: Array = []
	roster_row.connect("payload_dropped", func(payload: Dictionary): landed.append(String(payload.get("unit_id", ""))))
	roster_row.call("_drop_data", Vector2.ZERO, drag)
	await _settle(presenter)
	var after_drop := _in_team(screen, unit_id)
	check(landed == [unit_id], "Ablegen auf der Personal-Zeile meldet die gezogene Person " + str(landed))
	print("REMOVE-RUECKMELDUNG nach Ablegen: ", String((presenter.get("_feedback") as Label).text) if presenter.get("_feedback") != null else "-", " | noch im Trupp: ", after_drop)
	# Gleiche Aktion wie der Knopf: derselbe Befehl `remove` fuer dieselbe Person liefert denselben Zustand (nicht erneut im Trupp noetig).
	if after_drop:
		presenter.set("_focused_id", unit_id)
		(presenter.get("_remove_member") as Button).pressed.emit()
		await _settle(presenter)
		check(_in_team(screen, unit_id) == after_drop, "Knopf 'Aus Trupp entfernen' liefert fuer dieselbe Person dasselbe Ergebnis wie das Ablegen (%s bleibt im Trupp)" % unit_id)
	else:
		check(presenter.find_child("TeamMember_" + unit_id.validate_node_name(), true, false) == null, "Ablegen auf Personal entfernt die Person aus dem Trupp; Mitgliederzeile verschwindet")

func _in_team(screen: Node, unit_id: String) -> bool:
	for team_variant in Array(screen.call("get_operations_snapshot").fireteams):
		for member_variant in Array(Dictionary(team_variant).members):
			if String(Dictionary(member_variant).id) == unit_id: return true
	return false

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	screen.request_operation("navigate", {"mode": "mission"})
	var presenter: Node = screen.get("_operations_presenter")
	var specs := {Vector2i(1920, 1080): [400, 240, 330, 250], Vector2i(1280, 720): [340, 200, 280, 220]}
	for resolution in specs:
		root.size = resolution
		(screen as Control).set_deferred("size", Vector2(resolution))
		await process_frame
		if (screen as Control).size != Vector2(resolution): (screen as Control).size = Vector2(resolution)
		for i in 24: await process_frame
		presenter.refresh()
		for i in 4: await process_frame
		var tag := "%s" % resolution
		var columns: Dictionary = presenter.get("_columns")
		var order: Array = ["equipment", "flight", "squad", "roster"]
		var spec: Array = specs[resolution]
		var previous_end := -1.0
		var in_order := true
		for index in order.size():
			var column: Control = columns[order[index]]
			check(column.visible, "column %s visible %s" % [order[index], tag])
			var rect := column.get_global_rect()
			if rect.position.x < previous_end - 0.5: in_order = false
			previous_end = rect.end.x
			print("WIDTH %s %s=%d" % [tag, order[index], int(rect.size.x)])
			if rect.size.x > float(spec[index]) + 1.0:
				for node in column.find_children("*", "Control", true, false):
					if (node as Control).get_combined_minimum_size().x > float(spec[index]) - 30.0: print("MINWIDE ", node.get_path(), " ", (node as Control).get_combined_minimum_size())
			check(rect.size.x <= float(spec[index]) + 1.0, "column %s width <= %d %s" % [order[index], spec[index], tag])
			if resolution.x == 1920: check(absf(rect.size.x - float(spec[index])) <= 1.0, "column %s width is %d at 1920" % [order[index], spec[index]])
		check(in_order, "columns run equipment, flight, squad (Trupps), roster (Personal) from the left %s" % tag)
		var workspace: Control = presenter.get("_workspace")
		print("WORKSPACE %s=%s flow=%s" % [tag, workspace.size, (flow as Control).size if flow is Control else "-"])
		check(columns.roster.get_global_rect().end.x <= workspace.get_global_rect().end.x + 1.0, "columns fit the workspace %s" % tag)
		check(columns.squad.get_global_rect().end.x <= columns.roster.get_global_rect().position.x + 1.0, "Trupps links von Personal %s" % tag)
		check(not (presenter.get("_team_selector") as Control).visible, "Trupp-Auswahlliste unsichtbar, Knoten bleibt %s" % tag)
		var stage: Control = presenter.get("_reference_stage")
		print("STAGE %s visible=%s rect=%s" % [tag, stage.visible, Rect2(stage.position, stage.size)])
		var preview: Rect2 = presenter.get("_preview_layout_rect")
		var base_node: Control = presenter.get("_base")
		if resolution.x == 1920:
			check(preview.size.x >= 280.0 and (stage.visible or base_node.is_visible_in_tree()), "preview present and >= 280 wide %s" % tag)
			check(preview.position.x >= columns.roster.position.x + columns.roster.size.x - 1.0, "preview right of the lists %s" % tag)
		else:
			check(preview.size.x == 0.0 and not stage.visible, "preview hidden when narrow %s" % tag)
		var flight: Control = columns.flight
		for button_name in ["BoardFireteam", "UnboardFireteam", "StartMission"]:
			var button: Button = presenter.find_child(button_name, true, false)
			check(button != null, "button %s exists %s" % [button_name, tag])
			if button == null: continue
			check(button.size.x <= 200.0 and button.size.y <= 40.0, "button %s is small %s" % [button_name, tag])
			check(button.mouse_filter != Control.MOUSE_FILTER_IGNORE and button.pressed.get_connections().size() > 0, "button %s clickable %s" % [button_name, tag])
			if button.is_visible_in_tree():
				check(flight.get_global_rect().grow(1).encloses(button.get_global_rect()), "button %s inside flight column %s" % [button_name, tag])
		# Nichts ragt seitlich ueber den Spaltenrand.
		for key in order:
			var column: Control = columns[key]
			var edge := column.get_global_rect().grow(1)
			var overflow := 0
			for node in column.find_children("*", "Control", true, false):
				var control: Control = node
				if not control.is_visible_in_tree() or control.size.x <= 0.0: continue
				var rect := control.get_global_rect()
				if rect.position.x < edge.position.x or rect.end.x > edge.end.x:
					overflow += 1
					printerr("OVERFLOW ", key, " ", control.get_path(), " ", rect)
			check(overflow == 0, "nothing sticks out of column %s %s" % [key, tag])
		var snapshot: Dictionary = screen.call("get_operations_snapshot")
		var crafts: Array = Array(snapshot.get("crafts", []))
		var selected: Dictionary = Dictionary(snapshot.get("selected_craft", {}))
		check(crafts.size() > 0, "snapshot has ships %s" % tag)
		var gold := 0
		for craft_variant in crafts:
			var craft: Dictionary = Dictionary(craft_variant)
			var card: Node = presenter.find_child("ShipCard_" + String(craft.id).validate_node_name(), true, false)
			check(card != null, "ShipCard for %s %s" % [craft.id, tag])
			if card != null and bool(card.get_meta("selected", false)):
				gold += 1
				check(String(craft.id) == String(selected.get("id", "")), "highlighted card is the selected ship %s" % tag)
		check(gold == 1, "exactly one ship card highlighted %s" % tag)
		var detail: Control = presenter.find_child("ShipDetail", true, false)
		check(detail != null and detail.is_visible_in_tree() and columns.equipment.is_ancestor_of(detail), "ShipDetail shown in the equipment column %s" % tag)
		if detail != null:
			check(detail.find_child("PilotSlot", true, false) != null, "ShipDetail has PilotSlot %s" % tag)
			check(detail.find_child("Cargo", true, false) != null, "ShipDetail has Cargo %s" % tag)
			var wanted := int(load("res://scripts/ui/components/ship_detail_panel.gd").seat_layout(selected).passengers)
			var troop := 0
			for node in detail.find_children("TroopSlot_*", "", true, false): troop += 1
			check(troop == wanted, "TroopSlot count %d == %d %s" % [troop, wanted, tag])
		for team_variant in Array(snapshot.get("fireteams", [])):
			var team: Dictionary = Dictionary(team_variant)
			var row: Node = presenter.find_child("TeamRow_" + String(team.id).validate_node_name(), true, false)
			check(row != null and row.is_visible_in_tree(), "TeamRow for %s %s" % [team.id, tag])
			if row != null and not Array(team.members).is_empty():
				check(row.find_child("LeaderStar", true, false) != null, "TeamRow %s shows leader star %s" % [team.id, tag])
			if row != null:
				var drag: Dictionary = Dictionary(row.get("drag_payload"))
				check(String(drag.get("type", "")) == "fob_fireteam_card" and String(drag.get("fireteam_id", "")) == String(team.id), "Trupp-Karte %s ist ziehbar mit Trupp-Zieh-Daten %s" % [team.id, tag])
				check((row.find_child("TeamTitle", true, false) as Label).text.contains("%d / 4 Mitglieder" % Array(team.members).size()), "Trupp-Karte %s zeigt 'n / 4 Mitglieder' %s" % [team.id, tag])
		var roster_rows: Dictionary = presenter.get("_rows")
		check(roster_rows.size() == Array(snapshot.get("roster", [])).size() and roster_rows.size() > 0, "Personal list holds the whole roster %s" % tag)
		check(columns.roster.visible and presenter.find_child("ReturnPersonToRoster", true, false) != null, "Personal list reachable %s" % tag)
	await _seats(screen, presenter)
	await _team_drag(screen, presenter)
	flow.queue_free()
	await process_frame
	print("FLUGDECK_LAYOUT_V2 passed=%d failed=%d" % [checks - failures, failures])
	quit(1 if failures else 0)
