# Player Roster Save Contract

## Zweck
TASK_234 speichert das lokal erzeugte Start-Roster dauerhaft unter `user://profiles/...`. Das Save gehoert zum lokalen Spielerprofil und ist keine Gameplay-Wahrheit fuer Multiplayer-Peers.

## Speicherort
- Default-Profil: `local_player`
- Default-Pfad: `user://profiles/local_player/roster_v1.json`
- Tests und spaetere Profile duerfen eigene Profil-IDs nutzen.
- Profil-IDs werden auf ASCII-Buchstaben, Zahlen, `_` und `-` begrenzt.

## Format V1
Top-Level-Felder:
- `schema_version`: aktuell `1`
- `store_id`: `player_roster_store_v1`
- `profile_id`: lokales Profil
- `saved_at_unix_time`: Schreibzeitpunkt
- `generator_id`: Generatorkennung aus TASK_232
- `generator_seed`: Seed des aktuellen Rosters
- `roster_size`: Anzahl gespeicherter Units
- `roster`: vollstaendiger Roster-Snapshot inklusive NPC-Profilen
- `multiplayer_boundary`: lokale Profilgrenze

Unit-Felder bleiben als `MetaUnitProfile`-Dictionary erhalten, inklusive:
- `unit_id`, `display_name`, `callsign`
- `portrait_id`, `portrait_path`
- `role_id`, `role_name`, `roster_role_category`
- `skill_values`, `trait_ids`, `rank_badges`
- `status_text` und kuenftige Recovery-/History-Felder, wenn vorhanden

## Laden
`PlayerRosterStore.ensure_roster()` versucht zuerst zu laden. Falls der Save fehlt oder ungueltig ist, wird ein neuer TASK_232/TASK_233-Roster erzeugt und am gleichen Pfad gespeichert. Fehler werden als Diagnosen gemeldet, nicht still verschluckt.

## Reset
`reset_roster()` erzeugt nur nach expliziter Bestaetigung ein neues Team. Vorhandene Saves werden unter `user://profiles/<profile>/archive/` archiviert, bevor der neue Save geschrieben wird.

Scheitert das angeforderte Archiv eines vorhandenen Saves, bricht der Reset vor
Generation und Schreiben mit `ok = false`, `created = false` und
`reason = active_archive_failed` ab. Die aktiven Savebytes bleiben unveraendert;
der Store liefert das weiterhin lesbare alte Roster samt Diagnose zurueck.
Ohne vorherigen Save ist kein Archiv erforderlich. Ein explizites
`archive_existing = false` behaelt sein bisheriges Verhalten.

Das Hauptmenue uebernimmt ein Reset-Roster erst nach erfolgreichem Store-Ergebnis.
Bei Fehler bleiben sichtbares Team, Loaded-/Created-Status und Editorzustand
erhalten; die fehlgeschlagene Operation wird angezeigt. Erst ein erfolgreicher
Reset verbraucht eine neue Resetgeneration. Eine ausstehende Bestaetigung bleibt
fuer einen erneuten Versuch verfuegbar.

## Multiplayer-Grenze
- Singleplayer/Homebase nutzt das lokale Profil.
- Host kann das eigene Profil oder ein explizites Szenario-Roster nutzen.
- Joiner behalten ihr lokales Profil privat; ein voller privater Roster wird nicht automatisch in Snapshots veroeffentlicht.
- Boundary-Name fuer Tests und Snapshots: `local_player_profile`.
- Runtime-Wahrheit bleibt bei `SimulationRoot`; der Store ist Meta-/Profilzustand.

## Fehlerfaelle
- Fehlender Save: neuer Roster wird generiert.
- Falsche `schema_version`: Save wird abgelehnt und Fallback erzeugt.
- Ungueltiger Roster: Save wird abgelehnt und diagnostiziert.
- Schreibfehler: UI bekommt `ok = false`; das In-Memory-Roster bleibt sichtbar, ist aber nicht als persistiert markiert.
