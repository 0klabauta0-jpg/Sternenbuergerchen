# TASK_200 - Enemy Team Tactics Contract and Editor Config

## Ziel
Feindteams sollen einen expliziten Taktikvertrag bekommen, der im Editor konfigurierbar ist und spaeter von Runtime, Mission Map und Multiplayer-Snapshots identisch gelesen wird.

Der Task legt noch nicht die komplette KI um, sondern definiert die Profile, Datenfelder und Editor-Bedienung, auf denen TASK_201 bis TASK_208 aufbauen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_160 - Tactical Mission Playability Smoke
- TASK_186 - Mission Map Unit Presence and Registry Audit
- TASK_187 - NPC Minimum Spacing and Multiplayer Authority
- TASK_188 - Fireteam Advance Styles Map Readability
- TASK_193 - Asset Source Inventory and Availability Matrix

## Kontext
Aktuell koennen Gegner laufen, patrouillieren, angreifen und nach Schaden Deckung suchen. Was fehlt, ist ein klares Feindteam-Modell: Welche Gruppe haelt, welche geht aggressiv vor, welche sichert 360 Grad, welche schaut in eine Gefechtsrichtung, welche Waffenreichweiten und Sichtlinien gelten, und wie wird das im Editor eingestellt?

Dieser Task verhindert, dass diese Regeln spaeter in UI, Testsetup und Combat-Loop verstreut werden.

## Umfang
1. Taktikprofile definieren:
   - Stabile Profil-IDs, z. B. `guard_hold`, `patrol_probe`, `aggressive_push`, `defensive_cover`, `sniper_watch`.
   - Pro Profil: bevorzugte Haltung, Deckungsverhalten, Sicherungsmodus, Gefechtsrichtung, Advance-Stil, erlaubte Waffenrollen und Sicht-/Kontaktverhalten.
   - Profile bleiben Daten, nicht versteckte Node-Logik.
2. Editor-Konfiguration:
   - Enemy-Gruppen/Waves im Editor koennen ein Taktikprofil auswaehlen.
   - Optional: Facing/Gefechtsrichtung, Security-Modus, Patrol-/Hold-Area, Weapon-Profile und Visual-Archetyp setzen.
   - Defaults muessen fuer schnelle 32x32- und 64x64-Standardmaps brauchbar sein.
3. Datenvertrag:
   - Enemy-Team-Konfiguration wird in Map-/Missiondaten gespeichert.
   - Keine absoluten lokalen Pfade.
   - Keine Gameplay-Wahrheit in Editor-UI oder Mission-HUD.
   - Runtime liest nur validierte, kleine Dictionaries oder Resource-Daten.
4. Diagnose:
   - Fehlt ein Profil, wird ein sichtbarer Default genutzt und diagnostiziert.
   - Verifier prueft unbekannte IDs, fehlende Felder und Roundtrip Save/Load.
5. Dokumentation:
   - Kurzes Dev-Dokument fuer Enemy-Team-Taktikfelder, Defaultwerte und Folge-Tasks.

## Nicht-Ziele
- Keine komplette Enemy-KI.
- Keine neue Pathfinding-Architektur.
- Keine Waffenbalance ausser Defaults und Profilfelder.
- Keine Asset-Importe.
- Kein Multiplayer-Netcode-Umbau.

## Akzeptanzkriterien
- [x] Enemy-Taktikprofile sind als stabile Datenstruktur dokumentiert.
- [x] Der Editor kann fuer Enemy-Gruppen mindestens ein Profil, Security-Modus und Facing/Gefechtsrichtung speichern.
- [x] 32x32- und 64x64-Maps haben sinnvolle Defaultprofile.
- [x] Map-/Mission-Save/Load erhaelt die Enemy-Taktikfelder.
- [x] Runtime-Glue liest die Felder, erzeugt aber noch keine grossen KI-Nebenwirkungen.
- [x] Ein TASK_200-Verifier prueft Profilvalidierung, Editor-Roundtrip und Defaults.

## Erwartete Dateien
- `docs/dev/enemy_team_tactics_contract.md`
- `scripts/tactical/enemy_team_tactics_profile.gd`
- `scripts/editor/map_editor.gd`
- `scripts/terrain/terrain_map_data.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/tests/task_200_enemy_team_tactics_contract_and_editor_config.gd`
- `docs/tasks/TASK_200_enemy_team_tactics_contract_and_editor_config.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_200_enemy_team_tactics_contract_and_editor_config.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_186_mission_map_unit_presence_registry_audit.gd`
- [ ] Editor manuell: Enemy-Gruppe setzen, Profil/Facing speichern, Map neu laden.
- [x] `git diff --check`

## Risiken
- Wenn Profilfelder direkt in mehrere Runtime-Klassen kopiert werden, wird Balancing spaeter schwer.
- Editor-Konfiguration darf keine SimulationRoot-Wahrheit ersetzen.
- Zu viele Profile am Anfang verwirren mehr als sie helfen; wenige klare Defaults reichen.

## Naechster Schritt
Nach TASK_200 kann TASK_201 die Waffenreichweiten auf denselben Profilvertrag beziehen.
