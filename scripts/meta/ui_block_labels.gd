class_name UIBlockLabels
extends RefCounted

const HOMEBASE_MISSION_BRIEF: String = "#01 MISSION BRIEF"
const HOMEBASE_AVAILABLE_OPERATORS: String = "#02 AVAILABLE OPERATORS"
const HOMEBASE_TRANSFER_TEAM: String = "#03 TRANSFER TEAM"
const HOMEBASE_INBOUND_TO_FOB: String = "#04 INBOUND TO FOB"
const HOMEBASE_FLIGHT_DECK: String = "#05 FLIGHT DECK"
const HOMEBASE_DECK_ACTIVITY: String = "#06 DECK ACTIVITY"
const HOMEBASE_CHARACTER_SHEET: String = "#07 CHARACTER SHEET"

const FOB_MISSION_BRIEF: String = "#08 FOB MISSION BRIEF"
const FOB_AVAILABLE_OPERATORS: String = "#09 AVAILABLE OPERATORS"
const FOB_FIRETEAMS: String = "#10 FIRETEAMS"
const FOB_LOADOUT_STAGING: String = "#11 LOADOUT STAGING"
const FOB_RESPAWN: String = "#12 FOB RESPAWN"
const FOB_LOADOUT: String = "#13 LOADOUT"
const FOB_DROPSHIP_WAIT_ZONE: String = "#14 DROPSHIP WAIT ZONE"

const MISSION_LIVE_TACTICAL_GRID: String = "#15 LIVE TACTICAL GRID"
const MISSION_COMMAND_MATRIX: String = "#16 COMMAND MATRIX"
const MISSION_SELECTED_FIRETEAM: String = "#17 SELECTED FIRETEAM"
const MISSION_CONTROL: String = "#18 MISSION CONTROL"

const SHARED_TRANSPORT_CARD_PREFIX: String = "#19"
const CHARACTER_OVERLAY: String = "#20 CHARACTER OVERLAY"


static func prefixed_transport_title(title_text: String) -> String:
	var cleaned_title: String = title_text.strip_edges()
	if cleaned_title.begins_with("%s " % SHARED_TRANSPORT_CARD_PREFIX):
		return cleaned_title
	if cleaned_title.is_empty():
		return SHARED_TRANSPORT_CARD_PREFIX
	return "%s %s" % [SHARED_TRANSPORT_CARD_PREFIX, cleaned_title]
