# TASK_228 - Multiplayer Editor Map Manifest Download Consent

## Ziel
Multiplayer soll Editor-Maps sauber vorbereiten: Wenn der Host eine Map nutzt, die der Join-Client nicht kennt, bekommt der Client eine Anfrage und kann die unbekannte Map herunterladen oder ablehnen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_064 - Mission Terrain aus JSON
- TASK_158 - Editor to Live Mission Scenario
- TASK_167 - Multiplayer Session and Lobby Extraction
- TASK_168 - Multiplayer Snapshot Replication Contract
- TASK_199 - Main Menu Shell and Background Image
- TASK_227 - Main Menu Multiplayer Host Join Lobby Flow

## Kontext
Langfristig sollen Spieler Maps im Editor bauen und im Multiplayer nutzen koennen. Der Host kann dann eine Map starten, die der Join-Client lokal nicht hat. Das braucht Manifest, Hash, Versions-/Kompatibilitaetscheck, Download-Consent und sicheren Speicherort.

## Umfang
1. Map-Manifest:
   - Map-ID, Name, Author/Source optional.
   - Hash/Checksum.
   - Format-Version.
   - benoetigte Scenario-Datei oder Mission-Metadaten.
2. Lobby-Abgleich:
   - Host sendet Manifest vor Missionsstart.
   - Client prueft lokale Map-Registry.
   - Bei unbekannter oder anderer Hash-Version: Prompt.
3. Download-Consent:
   - Client sieht Name, Groesse/Hash falls bekannt, Host-Hinweis.
   - Buttons: Download/Annehmen, Ablehnen/Zurueck.
   - Kein automatischer Download ohne Zustimmung.
4. Speicherung:
   - Heruntergeladene Maps unter einem sicheren Projekt-/User-Pfad, z. B. `user://downloaded_maps/`.
   - Keine Ueberschreibung lokaler Editor-Maps ohne explizite Versionierung.
   - JSON validieren, Pfad-Traversal blockieren.
5. Multiplayer-Grenze:
   - Map-Transfer ist Lobby/Pre-Mission.
   - Laufende Mission-Snapshots transportieren nicht dauernd komplette Mapdaten.
6. Verifier:
   - Known Map -> kein Prompt.
   - Unknown Map -> Prompt.
   - Download accepted -> Cache/Registry.
   - Download rejected -> kein Missionsstart fuer Client.
   - Manipulierter Pfad/Hash -> abgelehnt.

## Nicht-Ziele
- Kein grosser Mod-Browser.
- Kein Online-Workshop.
- Kein automatischer Upload ins Internet.
- Keine Asset-Pack-Synchronisation, nur Map/Scenario-JSON V1.
- Kein Savegame-Transfer.

## Akzeptanzkriterien
- [x] Host kann ein Map-Manifest fuer Editor-Maps erzeugen.
- [x] Client erkennt unbekannte oder abweichende Maps.
- [x] Download/Accept-Prompt ist vor Missionsstart sichtbar.
- [x] Client kann ablehnen, ohne kaputten Session-State.
- [x] Angenommene Maps werden validiert und sicher gespeichert.
- [x] Ein TASK_228-Verifier prueft Manifest, Hash, Consent, Cache und Sicherheitsgrenzen.

## Erwartete Dateien
- `scripts/multiplayer/multiplayer_map_manifest.gd`
- `scripts/multiplayer/multiplayer_session.gd`
- `scripts/ui/multiplayer_lobby_screen.gd`
- `scripts/terrain/terrain_map_data.gd`
- `scripts/tests/task_228_multiplayer_editor_map_manifest_download_consent.gd`
- `docs/dev/multiplayer_editor_map_transfer_contract.md`
- `docs/tasks/TASK_228_multiplayer_editor_map_manifest_download_consent.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_228_multiplayer_editor_map_manifest_download_consent.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_167_multiplayer_session_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_227_main_menu_multiplayer_host_join_lobby_flow.gd`
- [ ] Manueller Host/Join-Test mit unbekannter Editor-Map.
- [x] `git diff --check`

## Risiken
- Map-Download ist ein Sicherheitsrand. Pfade, Hashes und JSON muessen strikt validiert werden.
- Zu fruehe Asset-Pack-Synchronisation wuerde den Task sprengen.
- Der echte Kartenpayload-Transport bleibt ausserhalb dieses V1; die Lobby zeigt Consent an und blockiert den Start, waehrend Tests den sicheren Accept-Pfad direkt pruefen.

## Naechster Schritt
Nach TASK_228 kann TASK_229 die Editor-Bedienbarkeit fuer solche Maps gezielt verbessern.
