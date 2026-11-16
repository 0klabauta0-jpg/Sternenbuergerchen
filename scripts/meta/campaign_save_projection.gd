extends RefCounted
## Read-only projection shared by entry and exit UI. Files are read only when
## requested; no timers, cached gameplay state, writes or fallback load actions.
const DISPLAY = preload("res://scripts/mission/campaign_display_catalog.gd")
const HOME = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const ACTIVE = preload("res://scripts/meta/campaign_active_checkpoint_store.gd")

static func inspect_saved(loaded_home: Variant = null) -> Dictionary:
	var home: Dictionary = HOME.load_checkpoint() if loaded_home == null else loaded_home
	var metadata := {"home_time":FileAccess.get_modified_time(HOME.DEFAULT_PATH) if FileAccess.file_exists(HOME.DEFAULT_PATH) else 0, "active_time":0, "active_present":FileAccess.file_exists(ACTIVE.DEFAULT_PATH), "active_retired":false}
	var active: Dictionary = {}
	if home.get("ok", false) and metadata.active_present:
		metadata.active_retired = FileAccess.get_sha256(ACTIVE.DEFAULT_PATH) == String(home.payload.get("retired_active_checkpoint_sha256", ""))
		if not metadata.active_retired:
			var bootstrap = load("res://scripts/mission/campaign_active_bootstrap_validation.gd")
			active = ACTIVE.load_checkpoint(bootstrap.validate)
			metadata.active_time = FileAccess.get_modified_time(ACTIVE.DEFAULT_PATH)
	var projection := project(home, active, metadata)
	return {"projection":projection, "home":home, "active":active}

static func project(home: Dictionary, active: Dictionary, metadata: Dictionary, live: Dictionary = {}) -> Dictionary:
	var home_ok: bool = bool(home.get("ok", false))
	var active_required: bool = home_ok and bool(metadata.get("active_present", false)) and not bool(metadata.get("active_retired", false))
	var blocked: bool = active_required and not active.get("ok", false) and active.get("reason") != "active_home_mismatch"
	var active_ok: bool = active_required and bool(active.get("ok", false))
	var kind := "mission" if active_ok else ("home" if home_ok and not blocked else "none")
	var home_payload: Dictionary = home.get("payload", {})
	var identity: Dictionary = Dictionary(active.get("payload", {})).get("components", {}).get("identity", {}) if active_ok else {}
	var location_id := String(identity.get("location_id", "homebase"))
	var locations: Dictionary = Dictionary(home_payload.get("campaign", {})).get("locations", {})
	var place := DISPLAY.location_name(location_id, Dictionary(locations.get(location_id, {})))
	if location_id == "homebase": place += " (Heimatbasis)"
	var stamp := int(metadata.get("active_time" if active_ok else "home_time", 0))
	var reason := "active_checkpoint_invalid" if blocked else ("" if home_ok else String(home.get("reason", "checkpoint_missing")))
	var summary := "%s · %s\nGespeichert: %s" % ["Einsatzstand" if active_ok else "Basisstand", place, time_text(stamp)]
	if blocked: summary = "Fortsetzen gesperrt: Einsatzstand ist nicht gültig.\nLetzter Basisstand: Heimathafen (Heimatbasis) · %s\n„Letzten Basisstand laden“ bietet eine ausdrückliche Wiederherstellung." % time_text(int(metadata.get("home_time", 0)))
	elif not home_ok: summary = "Noch kein gültiger Kampagnenstand vorhanden." if reason == "checkpoint_missing" else "Kampagnenstand kann nicht geladen werden. Vorhandene Dateien bleiben erhalten."
	return {"continue_available":home_ok and not blocked, "home_available":home_ok, "kind":kind, "location_id":location_id if kind != "none" else "", "location":place if kind != "none" else "", "saved_at_unix":stamp if kind != "none" else 0, "summary":summary, "blocked_reason":reason, "can_save":bool(live.get("can_save", false)), "save_blocked_reason":String(live.get("reason", "")), "save_blocked_text":blocked_text(String(live.get("reason", ""))), "has_unsaved_progress":bool(live.get("dirty", false))}

static func time_text(stamp: int) -> String:
	return Time.get_datetime_string_from_unix_time(stamp).replace("T", " ") + " UTC" if stamp > 0 else "Zeitpunkt unbekannt"

static func blocked_text(reason: String) -> String:
	if reason in ["checkpoint_pending_work","checkpoint_clock_unsynced","checkpoint_pending_setup","checkpoint_pending_selection"]:
		return "Speichern wartet auf laufende Befehle oder die Aufstellung. Danach erneut speichern."
	var messages := {"mission_planned_orders_unsupported":"Geplante Befehle zuerst ausführen oder entfernen.", "mission_movement_pending":"Speichern wartet, bis die Bewegung abgeschlossen ist.", "mission_lifecycle_busy":"Speichern wartet auf einen stabilen Einsatzstand.", "mission_combat_unsupported":"Während dieses Gefechts ist Speichern noch nicht verfügbar.", "away_from_checkpoint":"Während der Reise ist Speichern noch nicht verfügbar.", "world_active":"Während der Reise ist Speichern noch nicht verfügbar.", "mission_travel_mismatch":"Während der Reise ist Speichern noch nicht verfügbar.", "shuttle_active":"Speichern wartet auf den Abschluss des Shuttleflugs.", "shuttle_pending":"Speichern wartet auf den Shuttletransport.", "cargo_transfer_active":"Speichern wartet auf den Frachttransfer.", "recruitment_pending":"Speichern wartet auf die Anwerbung.", "preparation_in_progress":"Speichern wartet auf die Vorbereitung von Besatzung oder Fracht.", "home_hex_checkpoint_unsupported":"Der aktuelle Heimatbasisstand ist im Einsatz nicht vollständig speicherbar.", "multiple_locations_unsupported":"Speichern mit mehreren aktiven Orten wird noch nicht unterstützt.", "active_restore_pending":"Der Einsatz wird noch geladen.", "campaign_unavailable":"Die Kampagne ist noch nicht bereit.", "campaign_load_failed":"Die Kampagne konnte nicht geladen werden.",
		"mission_lifecycle_unsupported":"Im Einsatz kann gerade nicht gespeichert werden: Gegner sind aktiv, jemand ist verletzt oder ein Auftragsschritt läuft. Es gilt der zuletzt gespeicherte Stand.",
		"mission_fleet_unsupported":"Mit mehr als einem Schiff kann im Einsatz noch nicht gespeichert werden. Es gilt der zuletzt gespeicherte Stand, etwa der von der Basis.",
		"home_personnel_unsupported":"Im Einsatz kann nur gespeichert werden, wenn der ganze Kader dabei ist. Es gilt der zuletzt gespeicherte Stand, etwa der von der Basis.",
		"home_checkpoint_mismatch":"Im Einsatz kann gerade nicht gespeichert werden: Der Kader hat sich seit dem Speichern an der Basis geändert. Nach der Rückkehr dort speichern.",
		"checkpoint_recruit_presence_missing":"Ein angeworbenes Mitglied fehlt noch in der Basis. Bitte später erneut speichern.",
		"base_checkpoint_aboard_context":"Im Einsatz kann gerade nicht gespeichert werden: Jemand an Bord gehört zu keinem Trupp. Es gilt der zuletzt gespeicherte Stand.",
		"runtime_unavailable":"Die Basis kann gerade nicht gespeichert werden. Kurz warten, bis alle stehen; bleibt es so, hat jemand an Bord keinen Trupp."}
	if reason.is_empty(): return ""
	return String(messages.get(reason, "Dieser Zustand kann momentan nicht sicher gespeichert werden."))

static func equivalent(left: Dictionary, right: Dictionary, full_precision: bool = false) -> bool:
	# Compare the persisted numeric domain, independent of whitespace and int/float
	# representation after JSON restore. Home and active stores deliberately use
	# different JSON precision; compare using the selected store's actual format.
	var a: Variant = JSON.parse_string(JSON.stringify(left, "", true, full_precision))
	var b: Variant = JSON.parse_string(JSON.stringify(right, "", true, full_precision))
	return a == b
