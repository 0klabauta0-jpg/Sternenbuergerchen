extends RefCounted

const BUDGETS := [1000, 1500]
const EXPERIENCE := {
	"junior": {"label": "Wenig erfahren", "cost": 70, "value": 0.4},
	"trained": {"label": "Mittelerfahren", "cost": 100, "value": 0.55},
	"veteran": {"label": "Gut erfahren", "cost": 145, "value": 0.72},
}
const ROLES := {
	"operator": {"label": "Schütze", "name": "Rifle Operator", "cost": 0},
	"medic": {"label": "Sanität", "name": "Combat Medic", "cost": 20},
	"engineer": {"label": "Technik", "name": "Combat Engineer", "cost": 15},
	"pilot": {"label": "Pilot", "name": "Dropship Pilot", "cost": 10},
}
const ARMOR := {
	"suit": {"label": "Anzug", "cost": 0},
	"light": {"label": "Leicht", "cost": 10},
	"medium": {"label": "Mittel", "cost": 25},
	"heavy": {"label": "Schwer", "cost": 45},
}
const WEAPONS := {
	"pistol": {"label": "Pistole", "cost": 5},
	"smg": {"label": "MP", "cost": 20},
	"rifle": {"label": "Sturmgewehr", "cost": 30},
	"sniper": {"label": "Scharfschützengewehr", "cost": 50},
}
const SHIPS := {
	"cutlass": {"label": "Cutlass · Truppentransport", "name": "Cutlass", "type": "dropship", "cost": 340},
	"buccaneer": {"label": "Buccaneer · Jäger", "name": "Buccaneer", "type": "fighter", "cost": 230},
}
const BUILDINGS := {
	"habitat": {"label": "Habitat · 2 Betten", "cost": 180, "limit": 1},
	"workshop": {"label": "Werkhalle", "cost": 120, "limit": 1},
	"bed": {"label": "Feldbett", "cost": 30, "limit": 30},
	"pad": {"label": "Landeplatz", "cost": 150, "limit": 6},
}
const EQUIPMENT := {
	"armor_light": {"label": "Leichte Rüstung", "cost": 10},
	"armor_medium": {"label": "Mittlere Rüstung", "cost": 25},
	"armor_heavy": {"label": "Schwere Rüstung", "cost": 45},
	"pistol": {"label": "Pistole", "cost": 5},
	"smg": {"label": "MP", "cost": 20},
	"rifle": {"label": "Sturmgewehr", "cost": 30},
	"sniper": {"label": "Scharfschützengewehr", "cost": 50},
	"medictool": {"label": "Sanitätswerkzeug", "cost": 20},
	"backpack": {"label": "Rucksack", "cost": 15},
}


static func get_person_cost(person: Dictionary) -> int:
	for key in ["role", "experience", "armor", "weapon"]:
		if typeof(person.get(key)) != TYPE_STRING:
			return -1
	if not ROLES.has(person.role) or not EXPERIENCE.has(person.experience) or not ARMOR.has(person.armor) or not WEAPONS.has(person.weapon):
		return -1
	var medical_equipment := int(EQUIPMENT.medictool.cost) if person.role == "medic" else 0
	return int(ROLES[person.role].cost) + int(EXPERIENCE[person.experience].cost) + int(ARMOR[person.armor].cost) + int(WEAPONS[person.weapon].cost) + medical_equipment


static func evaluate(draft: Dictionary) -> Dictionary:
	if typeof(draft.get("budget")) != TYPE_INT or not BUDGETS.has(draft.budget):
		return {"ok": false, "reason": "Wähle ein Startbudget."}
	if not draft.get("people") is Array or not draft.get("ships") is Array:
		return {"ok": false, "reason": "Die Einkaufsliste ist ungültig."}
	if draft.has("base_setup"):
		if typeof(draft.base_setup) != TYPE_BOOL or not draft.base_setup or not draft.people.is_empty() or not draft.ships.is_empty():
			return {"ok": false, "reason": "Der Basisstart beginnt mit freiem Budget."}
		return {"ok": true, "reason": "", "spent": 0, "remaining": int(draft.budget)}
	var spent := 0
	var pilots := 0
	for person in draft.people:
		var cost: int = get_person_cost(person) if person is Dictionary else -1
		if cost < 0:
			return {"ok": false, "reason": "Ein Personalpaket ist ungültig."}
		spent += cost
		pilots += int(person.role == "pilot")
	for ship in draft.ships:
		if typeof(ship) != TYPE_STRING or not SHIPS.has(ship):
			return {"ok": false, "reason": "Ein Schiff ist ungültig."}
		spent += int(SHIPS[ship].cost)
	var remaining: int = int(draft.budget) - spent
	var reason := ""
	if remaining < 0:
		reason = "Das Punktebudget ist überschritten."
	elif not draft.ships.has("cutlass"):
		reason = "Für den Bodentrupp brauchst du eine Cutlass."
	elif pilots != draft.ships.size():
		reason = "Plane je Schiff genau einen Piloten ein."
	elif draft.people.size() == pilots:
		reason = "Kaufe mindestens eine Person für den Bodentrupp."
	return {"ok": reason.is_empty(), "reason": reason, "spent": spent, "remaining": remaining}
