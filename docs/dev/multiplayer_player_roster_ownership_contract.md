# Multiplayer Player Roster Ownership Contract

## Ziel
Multiplayer darf Character-Gameplay nutzen, ohne lokale Saves oder private Roster-Daten anderer Spieler zu replizieren. Die Mission bleibt host-authoritative; UI und Clients zeigen nur freigegebene Identitaets- und Ownership-Daten.

## Roster-Modi
- `host_roster`: Der Host stellt alle spielbaren NPCs. Clients steuern zugewiesene Fireteams, besitzen aber keine privaten NPC-Profile.
- `player_rosters`: Jeder Peer bringt sein eigenes lokales Roster fuer seine Fireteams mit. Der Host bleibt Runtime-Authority und darf nur oeffentliche Preview-Daten plus berechnete Mission-Snapshots replizieren.
- `scenario_roster`: Map oder Szenario stellt fixe NPCs. Ownership liegt beim Szenario, nicht bei einem Spielerprofil.

## Ownership-Felder
Jede Unit, die ueber Multiplayer-Snapshots oder Lobby-Previews sichtbar wird, muss strukturell einordbar sein:
- `owner_peer_id`: Besitzer-Peer. `1` ist Host, `0` ist Szenario.
- `roster_source`: `host`, `player` oder `scenario`.
- `roster_mode`: einer der validierten Modus-IDs.
- `roster_public_ref`: stabile oeffentliche Referenz ohne Save-Pfad oder Token.
- `character_gameplay_authority`: aktuell immer `host_server`.

## Datenfreigabe
Oeffentlich fuer Lobby/Preview:
- `unit_id`, `display_name`, `callsign`
- `role_id`, `role_name`, `roster_role_category`
- `portrait_id` mit Missing-Fallback
- `fireteam_id`
- grobe `rank_badges` ohne Asset-Pfade

Privat und lokal:
- Progression, XP, Moral-/Frustdetails
- Beziehungen, Relationship-Links und Relationship-Pairs
- Save-Seed, Generator-Seed, Profile-ID
- Biografie, Status-/Recovery-Details, interne Personnel-Events
- Skill-Werte und Asset-Pfade

Mission-relevant:
- Nur berechnete Modifikatoren, Bubble-Kontext und Snapshot-Felder duerfen repliziert werden.
- Der `CharacterGameplayResolver` laeuft authority-seitig. Clients empfangen daraus nur public-safe Snapshots.

## Lobby-Regeln
Der Host waehlt den Roster-Modus vor Missionsstart. Joiner sehen anhand des Lobby-Snapshots, ob ihr lokales Roster genutzt wird. Die Lobby darf keine vollstaendigen Roster-Saves oder privaten Profile anzeigen.

## Snapshot-Regeln
Unit-Snapshots enthalten Ownership-Felder, aber keine vollstaendigen Roster-Profile. Snapshot-Normalisierung muss private Felder ignorieren, selbst wenn ein Aufrufer sie versehentlich mitgibt.

## Implementierung
- `scripts/multiplayer/multiplayer_roster_contract.gd` validiert Modus-IDs, baut Peer-Ownership und public-safe Roster-Previews.
- `scripts/multiplayer/multiplayer_session.gd` fuehrt `roster_mode`, Peer-Roster-Assignments und Lobby-Snapshot.
- `scripts/multiplayer/multiplayer_snapshot_contract.gd` normalisiert `owner_peer_id`, `roster_source`, `roster_mode` und `character_gameplay_authority`.
- `scripts/meta/player_roster_store.gd` bleibt Save-Owner fuer lokale Profile und erzeugt nur public-safe Previews fuer Multiplayer.
