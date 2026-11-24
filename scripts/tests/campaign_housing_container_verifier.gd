extends SceneTree
## Versorgungsebene des Wohncontainers: Kauf, Beleg, Kapazitaet, Laden. Der Bauer ist eine Attrappe.
const SUPPLY := "res://scripts/core/singleplayer_supply_state.gd"
var passed := 0
var failed := 0
var built := 0
var available := true
var asked: Array = []

func check(condition: bool, text: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		print("FAIL: " + text)

func _build(count: int) -> Dictionary:
	asked.append(count)
	if not available: return {"ok":false,"reason":"no_room","message":"Kein Platz"}
	if count != built + 1: return {"ok":false,"reason":"wrong_count"}
	built = count
	return {"ok":true,"housing_count":count}

func _init() -> void: call_deferred("_run")

func _owner(credits: int):
	var owner = load(SUPPLY).new()
	owner.configure()
	owner._credits = credits
	return owner

func _ctx(limit: int, container: bool = true) -> Dictionary:
	var ctx := {"at_home":true,"campaign_authorized":true,"campaign_housing_builder":Callable(self, "_build")}
	if container:
		ctx["campaign_housing_container"] = true
		ctx["campaign_housing_limit"] = limit
	return ctx

func _command(id: String) -> Dictionary:
	return load("res://scripts/mission/singleplayer_supply_command_contract.gd").build_command("campaign_build_housing", {}, id)

func _run() -> void:
	var cost: int = load(SUPPLY).CONTAINER_HOUSING_COST
	var beds: int = load(SUPPLY).CONTAINER_HOUSING_BEDS
	check(cost == 1000 and beds == 4, "benannte Konstanten: 1000 Credits, 4 Betten")
	# 1. Bauer lehnt ab: keine Abbuchung, kein Beleg
	var owner = _owner(3000)
	available = false
	var refused: Dictionary = owner.apply_command(_command("c-1"), _ctx(4))
	check(not refused.get("ok", false) and owner.get_supply_snapshot().credits == 3000 and built == 0 and owner.get_campaign_housing_count() == 0, "Bauer lehnt ab -> keine Abbuchung, kein Beleg")
	available = true
	# 2. Kauf: -1000, +4 Betten, ein Beleg
	var result: Dictionary = owner.apply_command(_command("c-1"), _ctx(4))
	check(result.get("ok", false) and int(result.get("cost", 0)) == 1000 and int(result.get("beds", 0)) == 4 and result.get("housing_count") == 1, "Kauf: Beleg traegt cost 1000, beds 4, housing_count 1")
	check(owner.get_supply_snapshot().credits == 2000 and owner.get_campaign_bed_count() == 6 and owner.get_campaign_housing_count() == 1, "Kauf: Credits -1000, Betten 2 -> 6")
	check(owner.get_campaign_housing_beds() == [4], "Betten je Gebaeude: [4]")
	# 3. Wiederholung derselben Request-ID
	var again: Dictionary = owner.apply_command(_command("c-1"), _ctx(4))
	check(again.get("replayed", false) and owner.get_supply_snapshot().credits == 2000 and built == 1 and owner.get_campaign_bed_count() == 6, "gleiche Request-ID bucht nicht doppelt")
	# 4. ohne Guthaben
	var poor = _owner(999)
	var broke: Dictionary = poor.apply_command(_command("p-1"), _ctx(4))
	var asked_before := asked.size()
	check(not broke.get("ok", false) and poor.get_supply_snapshot().credits == 999 and poor.get_campaign_bed_count() == 2 and poor.get_campaign_housing_count() == 0, "ohne Guthaben: Ablehnung ohne Aenderung")
	check(String(broke.get("message", "")).length() > 0 and asked.size() == asked_before, "ohne Guthaben: Text vorhanden, Bauer nicht gefragt")
	# 5. Speichern/Laden
	var saved: Dictionary = owner.export_state()
	var restored = load(SUPPLY).new()
	check(restored.restore_state(saved).get("ok", false) and restored.get_campaign_bed_count() == 6 and restored.get_campaign_housing_beds() == [4], "Laden: neuer Beleg = 4 Betten")
	# 6. alter 500er-Beleg ohne Angabe = 2 Betten; gemischt = Summe
	var old_owner = _owner(2000)
	built = 0
	var old_buy: Dictionary = old_owner.apply_command(_command("o-1"), _ctx(0, false))
	check(old_buy.get("ok", false) and int(old_buy.get("cost", 0)) == 500 and not old_buy.has("beds"), "Altpfad: 500 Credits, Beleg ohne beds")
	var old_saved: Dictionary = old_owner.export_state()
	var old_restored = load(SUPPLY).new()
	check(old_restored.restore_state(old_saved).get("ok", false) and old_restored.get_campaign_bed_count() == 4 and old_restored.get_campaign_housing_beds() == [2], "Laden: alter 500er-Beleg = 2 Betten")
	var mixed: Dictionary = old_owner.apply_command(_command("c-2"), _ctx(4))
	check(mixed.get("ok", false) and old_owner.get_campaign_bed_count() == 8 and old_owner.get_campaign_housing_beds() == [2, 4], "gemischt: 2 + 2 + 4 = 8 Betten")
	var mixed_restored = load(SUPPLY).new()
	check(mixed_restored.restore_state(old_owner.export_state()).get("ok", false) and mixed_restored.get_campaign_bed_count() == 8 and mixed_restored.get_campaign_housing_count() == 2, "gemischt laedt als Summe")
	# 7. manipulierte Belege
	var bad: Dictionary = saved.duplicate(true); bad.requests["c-1"].result.erase("beds")
	check(not load(SUPPLY).new().restore_state(bad).get("ok", false), "Beleg 1000 ohne Bettenangabe abgelehnt")
	bad = saved.duplicate(true); bad.requests["c-1"].result.beds = 6
	check(not load(SUPPLY).new().restore_state(bad).get("ok", false), "Beleg 1000 mit 6 Betten abgelehnt")
	bad = saved.duplicate(true); bad.requests["c-1"].result.cost = 500
	check(not load(SUPPLY).new().restore_state(bad).get("ok", false), "Beleg 500 mit 4 Betten abgelehnt")
	bad = saved.duplicate(true); bad.requests["c-1"].result.cost = 0
	check(not load(SUPPLY).new().restore_state(bad).get("ok", false), "Beleg mit Kosten 0 abgelehnt")
	bad = old_owner.export_state(); bad.requests["c-2"].result.housing_count = 1
	check(not load(SUPPLY).new().restore_state(bad).get("ok", false), "doppelte Gebaeudenummer abgelehnt")
	# 7b. Belege ueber die Stellplaetze hinaus (Altstand/Manipulation) bleiben gueltig, zaehlen aber nicht: nie mehr Betten als baubar.
	var many = _owner(100000)
	built = 0
	for number in range(1, 6): many.apply_command(_command("m-%d" % number), _ctx(9))
	check(many.get_campaign_housing_count() == 5 and many.get_campaign_bed_count() == 22, "ohne Grenze: fuenf Container = 22 Betten")
	var many_restored = load(SUPPLY).new()
	check(many_restored.restore_state(many.export_state()).get("ok", false), "Beleg mit fuenf Gebaeuden laedt (Stand bleibt gueltig)")
	many_restored.set_housing_site_limit(4)
	check(many_restored.get_campaign_housing_count() == 5 and many_restored.get_campaign_housing_beds() == [4, 4, 4, 4] and many_restored.get_campaign_bed_count() == 18, "Hex-Basis mit vier Stellplaetzen: Versorgung meldet 18 Betten, nicht 22")
	var old_many = _owner(100000)
	built = 0
	for number in range(1, 6): old_many.apply_command(_command("a-%d" % number), _ctx(0, false))
	var old_many_restored = load(SUPPLY).new()
	old_many_restored.restore_state(old_many.export_state())
	old_many_restored.set_housing_site_limit(4)
	check(old_many.get_campaign_bed_count() == 12 and old_many_restored.get_campaign_bed_count() == 10, "fuenf Alt-Gebaeude: 12 Betten ohne Grenze, 10 mit vier Stellplaetzen")
	# 8. Obergrenze
	var capped = _owner(10000)
	built = 0
	var ok_a: Dictionary = capped.apply_command(_command("k-1"), _ctx(2))
	var ok_b: Dictionary = capped.apply_command(_command("k-2"), _ctx(2))
	var credits_full: int = capped.get_supply_snapshot().credits
	var over: Dictionary = capped.apply_command(_command("k-3"), _ctx(2))
	check(ok_a.get("ok", false) and ok_b.get("ok", false) and capped.get_campaign_bed_count() == 10, "zwei Container bis zur Grenze gekauft: 10 Betten")
	check(not over.get("ok", false) and String(over.get("message", "")) == "Kein freier Stellplatz für einen weiteren Wohncontainer", "Obergrenze: klarer Text (%s)" % str(over.get("message", "")))
	check(capped.get_supply_snapshot().credits == credits_full and capped.get_campaign_housing_count() == 2 and built == 2, "Obergrenze: keine Aenderung")
	print("CAMPAIGN_HOUSING_CONTAINER passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
