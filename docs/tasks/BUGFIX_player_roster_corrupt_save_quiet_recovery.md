# BUGFIX - Player Roster Corrupt Save Quiet Recovery

## Ziel / Problem
Der Singleplayer-Start darf nicht mit Godot-JSON-Errors erschrecken oder in einem unklaren Homebase-Zustand landen, wenn der lokale Roster-Save leer oder beschaedigt ist.

## Ursache
`PlayerRosterStore._load_json()` hat lokale Roster-Dateien direkt per `get_as_text()` und `JSON.parse_string()` gelesen. Leere oder kaputte Dateien konnten dadurch Engine-Parse-Errors ausloesen, bevor `ensure_roster()` einen frischen Start-Roster erzeugt.

## Umfang
- Leere, nicht lesbare oder kaputte Roster-Saves werden als ungültiger Payload mit Diagnose gemeldet.
- `ensure_roster()` bleibt der Reparaturpfad und generiert bei ungueltigem Save neu.
- Keine Aenderung an Gameplay-, Loadout-, Dropship- oder Missionswahrheit.

## Nicht-Ziele
- Kein neues Savegame-System.
- Kein automatisches Loeschen oder Archivieren defekter Dateien.
- Kein UI-Redesign der Homebase.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Ein leerer Roster-Save erzeugt keine harte JSON-Parse-Ausgabe und liefert eine `load_empty`-Diagnose.
- Ein syntaktisch kaputter Roster-Save liefert eine `load_parse_failed`-Diagnose.
- `ensure_roster()` kann danach einen frischen Roster speichern.
- `list_roster_entries()` zeigt defekte aktive Eintraege als ungueltig statt den Startpfad zu brechen.

## Betroffene Dateien
- `scripts/meta/player_roster_store.gd`
- `scripts/tests/bugfix_player_roster_corrupt_save_quiet_recovery.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_player_roster_corrupt_save_quiet_recovery.gd`

## Risiken / offene Punkte
- Defekte Saves werden bewusst nicht geloescht. Wenn ein Spieler die Datei behalten will, bleibt sie diagnostizierbar.
