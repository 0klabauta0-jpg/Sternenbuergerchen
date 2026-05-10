# TASK_299 - Team Identity Name Generation Userology

## Ziel
Wenn ein neues Spielerteam oder Startteam erzeugt wird, muss es einen Namen bekommen koennen. Das Spiel soll einen passenden coolen Namen vorschlagen, der vom User direkt geaendert werden kann.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_232 - Start Roster Generation Contract
- TASK_234 - Persistent Player Roster Save and Reset
- TASK_240 - Multiplayer Player Roster Ownership Contract
- bestehende Team-/Roster-Datenmodelle

## Kontext
Der Startroster ist inzwischen mehr als eine lose NPC-Liste. Er braucht eine erkennbare Team-Identitaet. Beim neuen Team soll der User nicht vor einem leeren Pflichtfeld stehen, sondern einen brauchbaren, atmosphaerischen Vorschlag bekommen und ihn einfach ueberschreiben koennen.

## Umfang
1. Datenmodell:
   - `team_name` oder entsprechendes Feld im persistenten Player-Roster/Team-Profil.
   - Name gehoert zur Spieler-/Roster-Identitaet, nicht zu einer einzelnen Mission.
   - Multiplayer: Teamname ist owner-/peer-bezogen und darf nicht serverseitige Gameplay-Wahrheit ersetzen.
2. Name-Generator:
   - Kuratierte Namensbestandteile passend zu Sternenbuergerchen.
   - Seeded Vorschlag, damit Reset/Neu-Generieren nachvollziehbar bleibt.
   - Button fuer "neuen Vorschlag".
   - Keine albernen Platzhalter wie "Team 1", ausser als Fallback.
3. UI:
   - Beim ersten Team-Erstellen Name anzeigen und editierbar machen.
   - Name darf leer nicht gespeichert werden; dann wird automatisch ein Vorschlag gesetzt.
   - Teamname sichtbar in Homebase/FOB/Missionsvorbereitung, aber nicht als riesige Ueberschrift.
4. Persistenz:
   - Save/Load behaelt Teamnamen.
   - Reset/Neues Team erzeugt neuen Namen.
5. Verifier:
   - Generator liefert nicht-leere, stabile Namen.
   - Editierter Name persistiert.
   - Multiplayer-/Roster-Ownership-Felder bleiben getrennt.

## Nicht-Ziele
- Keine umfangreiche Heraldik/Logo-Erstellung.
- Keine Online-Namenspruefung.
- Keine Umbenennung einzelner NPCs in diesem Task.

## Akzeptanzkriterien
- [x] Neues Team bekommt automatisch einen passenden Namensvorschlag.
- [x] User kann den Namen vor dem Speichern aendern.
- [x] Name bleibt nach Save/Load erhalten.
- [x] Button fuer neuen Vorschlag funktioniert.
- [x] Verifier prueft Generator, Persistenz und Reset.

## Erwartete Dateien
- `scripts/meta/...`
- `data/...`
- optional `data/team_name_generator_catalog.json`
- `scripts/tests/task_299_team_identity_name_generation_userology.gd`
- `docs/tasks/TASK_299_team_identity_name_generation_userology.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_299_team_identity_name_generation_userology.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_232_start_roster_generation_contract.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_234_persistent_player_roster_save_and_reset.gd`
- [ ] `git diff --check`

## Risiken
- Teamname darf nicht mit Fireteam-Namen, Multiplayer-Team-ID oder Faction-ID vermischt werden.
- Der Generator soll atmosphaerisch sein, aber nicht zu viel UI-Aufwand erzeugen.

## Naechster Schritt
TASK_300 stellt sicher, dass alle Hauptbereiche sauber zum Hauptmenue zurueckfuehren.
