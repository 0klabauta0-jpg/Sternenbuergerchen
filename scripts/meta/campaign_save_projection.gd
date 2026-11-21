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
	return {"continue_available":home_ok and not blocked, "home_available":home_ok, "kind":kind, "location_id":location_id if kind != "none" else "", "location":place if kind != "none" else "", "saved_at_unix":stamp if kind != "none" else 0, "summary":summary, "blocked_reason":reason, "can_save":bool(live.get("can_save", false)), "save_blocked_reason":String(live.get("reason", "")), "save_blocked_text":blocked_text(String(live.get("reason", "")), String(live.get("detail", ""))), "has_unsaved_progress":bool(live.get("dirty", false))}

static func time_text(stamp: int) -> String:
	return Time.get_datetime_string_from_unix_time(stamp).replace("T", " ") + " UTC" if stamp > 0 else "Zeitpunkt unbekannt"

## Speichern, erster Teil / 21.11. (S0): Jeder Ablehnungsgrund an der Basis hat einen eigenen Satz, der sagt, WARUM gerade nicht gespeichert wird
## und WANN es wieder geht. detail trennt Faelle desselben Grundes: bei away_from_checkpoint "flight" (Schiff im Flug) von "place" (Schiff an
## einem anderen Ort), bei base_checkpoint_aboard_context "home" (an der Basis) von "mission" (im Einsatz, der bisherige Satz).
const AWAY_TEXTS := {
	"flight": "Das Schiff ist unterwegs. Gespeichert wird, sobald es an der Heimatbasis gelandet ist.",
	"place": "Ein Schiff steht noch an einem anderen Ort. Gespeichert wird, sobald alle Schiffe wieder zu Hause sind.",
	"": "Ein Schiff ist nicht an der Heimatbasis. Gespeichert wird, sobald alle Schiffe zu Hause sind.",
}
const BASE_TEXTS := {
	"checkpoint_clock_unsynced": "Speichern wartet auf den Spieltakt der Basis. Gleich noch einmal versuchen.",
	"checkpoint_pending_work": "Speichern wartet auf laufende Befehle. Gleich noch einmal versuchen.",
	"checkpoint_pending_selection": "Speichern wartet auf eine laufende Auswahl. Gleich noch einmal versuchen.",
	"checkpoint_pending_setup": "Speichern wartet auf die Aufstellung. Gleich noch einmal versuchen.",
	"checkpoint_pending_respawn": "Speichern wartet auf einen offenen Respawn. Danach erneut speichern.",
	"checkpoint_owner_unavailable": "Die Basiskarte ist gerade nicht erreichbar. Gleich noch einmal versuchen.",
	"ground_save_not_configured": "Die Basiskarte ist noch nicht eingerichtet. Gleich noch einmal versuchen.",
	"ground_save_terrain_revalidation_pending": "Die Basiskarte wird gerade neu bewertet. Gleich noch einmal versuchen.",
	"ground_save_pending_admission": "Eine Person wird gerade auf der Basiskarte aufgestellt. Gleich noch einmal versuchen.",
	"ground_save_topology_pending": "Die Wege der Basiskarte werden gerade berechnet. Gleich noch einmal versuchen.",
	"base_checkpoint_transport_pending": "Die Besatzung geht gerade an Bord. Danach erneut speichern.",
	"base_checkpoint_admission_pending": "Eine Person wird gerade in die Basis aufgenommen. Danach erneut speichern.",
	"movement_save_pending_stop": "Jemand bremst gerade noch ab. Gleich noch einmal versuchen.",
	"campaign_craft_count": "An der Basis ist kein Schiff eingetragen, deshalb kann nicht gespeichert werden.",
	"base_checkpoint_station_context": "Der Zustand einer Person passt gerade nicht zu ihrem Platz an der Basis. Gleich noch einmal versuchen.",
	"base_checkpoint_invalid_unit": "Eine Person an der Basis hat gerade keinen gültigen Zustand. Gleich noch einmal versuchen.",
	"base_checkpoint_ground_presence": "Eine Person ist an der Basis nicht auf der Karte zu finden. Gleich noch einmal versuchen.",
	"hex_checkpoint_api_unavailable": "Die Basiskarte kann gerade nicht gespeichert werden. Es gilt der zuletzt gespeicherte Stand.",
	"mission_identity_mismatch": "Dieser Ortsbesuch gehört zu keinem Auftrag und wird nicht als Einsatz gespeichert. Nach der Heimkehr zur Basis wird gespeichert.",
	"mission_scenario_mismatch": "Der Auftrag dieses Ortes läuft nicht mehr. Nach der Heimkehr zur Basis wird gespeichert.",
	"mission_crew_not_deployed": "Die Besatzung ist noch nicht ausgestiegen. Nach dem Aussteigen erneut speichern.",
}
const BASE_ABOARD_HOME_TEXT := "An der Basis kann gerade nicht gespeichert werden: Jemand an Bord gehört zu keinem Trupp. Kurz warten oder neu einteilen."
## Gruende, die vergehen, ohne dass der Spieler etwas tun muss: nur fuer sie merkt sich das Spiel einen Speicherwunsch.
const TRANSIENT_REASONS := [
	"away_from_checkpoint", "world_active", "preparation_in_progress", "cargo_transfer_active", "recruitment_pending", "shuttle_pending", "shuttle_active",
	"active_restore_pending", "checkpoint_pending_work", "checkpoint_clock_unsynced", "checkpoint_pending_setup", "checkpoint_pending_selection",
	"checkpoint_pending_respawn", "checkpoint_owner_unavailable", "ground_save_not_configured", "ground_save_terrain_revalidation_pending",
	"ground_save_pending_admission", "ground_save_topology_pending", "base_checkpoint_transport_pending", "base_checkpoint_admission_pending",
	"base_checkpoint_aboard_context", "movement_save_pending_stop", "checkpoint_recruit_presence_missing",
]
const PENDING_AWAY := {
	"flight": "Das Schiff ist unterwegs. Gespeichert wird, sobald es gelandet ist.",
	"place": "Ein Schiff steht noch an einem anderen Ort. Gespeichert wird nach der Heimkehr.",
	"": "Nicht alle Schiffe sind zu Hause. Gespeichert wird nach der Heimkehr.",
}
const PENDING_CAUSES := {
	"world_active": "Das Schiff ist auf Reise. Gespeichert wird nach der Landung.",
	"preparation_in_progress": "Besatzung oder Fracht werden noch vorbereitet. Gespeichert wird danach.",
	"cargo_transfer_active": "Der Frachttransfer läuft. Gespeichert wird danach.",
	"recruitment_pending": "Die Anwerbung läuft. Gespeichert wird danach.",
	"shuttle_pending": "Der Shuttletransport ist vorbereitet. Gespeichert wird danach.",
	"shuttle_active": "Der Shuttleflug läuft. Gespeichert wird nach dem Flug.",
	"active_restore_pending": "Der Einsatz wird noch geladen. Gespeichert wird danach.",
	"checkpoint_pending_work": "Befehle laufen noch. Gespeichert wird gleich.",
	"checkpoint_clock_unsynced": "Der Spieltakt der Basis wird abgeglichen. Gespeichert wird gleich.",
	"checkpoint_pending_setup": "Die Aufstellung läuft noch. Gespeichert wird gleich.",
	"checkpoint_pending_selection": "Eine Auswahl läuft noch. Gespeichert wird gleich.",
	"checkpoint_pending_respawn": "Ein Respawn läuft noch. Gespeichert wird danach.",
	"checkpoint_owner_unavailable": "Die Basiskarte wird noch aufgebaut. Gespeichert wird danach.",
	"base_checkpoint_transport_pending": "Die Besatzung geht an Bord. Gespeichert wird danach.",
	"base_checkpoint_admission_pending": "Eine Person wird in die Basis aufgenommen. Gespeichert wird danach.",
	"base_checkpoint_aboard_context": "Jemand an Bord gehört noch zu keinem Trupp. Gespeichert wird, sobald das geklärt ist.",
	"movement_save_pending_stop": "Jemand bremst noch ab. Gespeichert wird, sobald alle stehen.",
	"checkpoint_recruit_presence_missing": "Ein angeworbenes Mitglied fehlt noch in der Basis. Gespeichert wird, sobald es da ist.",
}

static func is_transient(reason: String) -> bool:
	return reason in TRANSIENT_REASONS

## Satz fuer die Rueckmeldung, wenn ein Speicherwunsch gemerkt wurde: "Speichern vorgemerkt: <Grund und Zeitpunkt>".
static func pending_text(reason: String, detail: String = "") -> String:
	var cause: String
	if reason == "away_from_checkpoint":
		cause = String(PENDING_AWAY.get(detail, PENDING_AWAY[""]))
	elif reason.begins_with("ground_save_"):
		cause = "Die Basiskarte wird noch aufgebaut. Gespeichert wird danach."
	else:
		cause = String(PENDING_CAUSES.get(reason, "Der Zustand ändert sich gerade. Gespeichert wird, sobald es geht."))
	return "Speichern vorgemerkt: " + cause

static func blocked_text(reason: String, detail: String = "") -> String:
	if reason == "away_from_checkpoint":
		return String(AWAY_TEXTS.get(detail, AWAY_TEXTS[""]))
	if reason == "base_checkpoint_aboard_context" and detail == "home":
		return BASE_ABOARD_HOME_TEXT
	if BASE_TEXTS.has(reason):
		return String(BASE_TEXTS[reason])
	var messages := {"mission_planned_orders_unsupported":"Geplante Befehle zuerst ausführen oder entfernen.", "mission_movement_pending":"Speichern wartet, bis die Bewegung abgeschlossen ist.", "mission_lifecycle_busy":"Speichern wartet auf einen stabilen Einsatzstand.", "mission_combat_unsupported":"Während dieses Gefechts ist Speichern noch nicht verfügbar.", "away_from_checkpoint":"Während der Reise ist Speichern noch nicht verfügbar.", "world_active":"Während der Reise ist Speichern noch nicht verfügbar.", "mission_travel_mismatch":"Während der Reise ist Speichern noch nicht verfügbar.", "shuttle_active":"Speichern wartet auf den Abschluss des Shuttleflugs.", "shuttle_pending":"Speichern wartet auf den Shuttletransport.", "cargo_transfer_active":"Speichern wartet auf den Frachttransfer.", "recruitment_pending":"Speichern wartet auf die Anwerbung.", "preparation_in_progress":"Speichern wartet auf die Vorbereitung von Besatzung oder Fracht.", "home_hex_checkpoint_unsupported":"Der aktuelle Heimatbasisstand ist im Einsatz nicht vollständig speicherbar.", "multiple_locations_unsupported":"Speichern mit mehreren aktiven Orten wird noch nicht unterstützt.", "active_restore_pending":"Der Einsatz wird noch geladen.", "campaign_unavailable":"Die Kampagne ist noch nicht bereit.", "campaign_load_failed":"Die Kampagne konnte nicht geladen werden.",
		"mission_lifecycle_unsupported":"Im Einsatz kann gerade nicht gespeichert werden: Gegner sind aktiv, jemand ist verletzt oder ein Auftragsschritt läuft. Es gilt der zuletzt gespeicherte Stand.",
		"mission_fleet_unsupported":"Mit mehr als einem Schiff kann im Einsatz noch nicht gespeichert werden. Es gilt der zuletzt gespeicherte Stand, etwa der von der Basis.",
		"home_personnel_unsupported":"Im Einsatz kann nur gespeichert werden, wenn der ganze Kader dabei ist. Es gilt der zuletzt gespeicherte Stand, etwa der von der Basis.",
		"home_checkpoint_mismatch":"Im Einsatz kann gerade nicht gespeichert werden: Der Kader hat sich seit dem Speichern an der Basis geändert. Nach der Rückkehr dort speichern.",
		"checkpoint_recruit_presence_missing":"Ein angeworbenes Mitglied fehlt noch in der Basis. Bitte später erneut speichern.",
		"base_checkpoint_aboard_context":"Im Einsatz kann gerade nicht gespeichert werden: Jemand an Bord gehört zu keinem Trupp. Es gilt der zuletzt gespeicherte Stand.",
		"runtime_unavailable":"Die Basis kann gerade nicht gespeichert werden. Kurz warten, bis Schiffe gelandet sind und alle stehen. Bleibt es so, hat jemand an Bord keinen Trupp."}
	if reason.is_empty(): return ""
	if messages.has(reason): return String(messages[reason])
	# Gruppen mit gemeinsamem Namensanfang (Personalstand der Basis, Bewegung, Basiskarte); bekannte Einzelgruende stehen oben.
	if reason.begins_with("base_checkpoint_"):
		return "Jemand an der Basis ist gerade mit Bett, Terminal oder einem Weg beschäftigt. Gleich noch einmal versuchen."
	if reason.begins_with("movement_save_"):
		return "Eine Person ist gerade in Bewegung. Gleich noch einmal versuchen."
	if reason.begins_with("ground_save_"):
		return "Die Basiskarte kann gerade nicht gespeichert werden. Gleich noch einmal versuchen."
	return "Dieser Zustand kann momentan nicht sicher gespeichert werden."

static func equivalent(left: Dictionary, right: Dictionary, full_precision: bool = false) -> bool:
	# Compare the persisted numeric domain, independent of whitespace and int/float
	# representation after JSON restore. Home and active stores deliberately use
	# different JSON precision; compare using the selected store's actual format.
	var a: Variant = JSON.parse_string(JSON.stringify(left, "", true, full_precision))
	var b: Variant = JSON.parse_string(JSON.stringify(right, "", true, full_precision))
	return a == b
