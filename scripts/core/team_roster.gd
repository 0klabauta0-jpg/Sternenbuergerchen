extends RefCounted
## Live authenticated peer membership. Never supplied by command payload ownership.
const TEAM_COUNT:=2
const COMMANDERS_PER_TEAM:=8
const MAX_PLAYERS:=TEAM_COUNT*COMMANDERS_PER_TEAM
var locked:=false
var _members:Dictionary={1:0}

func team_for(peer:int) -> int:return int(_members.get(peer,-1))
func members() -> Dictionary:return _members.duplicate()
func count(team:int) -> int:
	var total:=0
	for value:int in _members.values():
		if value==team:total+=1
	return total
func join(peer:int,team:int) -> String:
	if locked:return "Sitzung läuft. Der Host muss die Lobby für neue Teilnehmer öffnen."
	if peer<=1 or _members.has(peer):return "Verbindung ist bereits zugeordnet oder ungültig."
	if team<0 or team>=TEAM_COUNT:return "Unbekanntes Team."
	if count(team)>=COMMANDERS_PER_TEAM:return "Team ist voll (8 Commander)."
	_members[peer]=team
	return ""
func assign(sender:int,peer:int,team:int) -> String:
	if sender!=1:return "Nur der Host ordnet Teams zu."
	if locked:return "Teamwechsel nur in der Lobby."
	if not _members.has(peer) or team<0 or team>=TEAM_COUNT:return "Teilnehmer oder Team unbekannt."
	if team_for(peer)==team:return ""
	if count(team)>=COMMANDERS_PER_TEAM:return "Team ist voll (8 Commander)."
	_members[peer]=team
	return ""
func leave(peer:int) -> void:
	if peer!=1:_members.erase(peer)
