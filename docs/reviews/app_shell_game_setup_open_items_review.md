# App Shell Game Setup Open Items Review

## Stand
TASK_231 prueft den aktuellen App-Einstieg nach den Slices fuer Hauptmenue, Settings, FoW, Multiplayer-Lobby, Editor-Map-Manifest, Editor-Usability und Air-Layer.

## Gepruefte Pfade
- Hauptmenue -> Einzelspieler / Singleplayer: Route zeigt auf `res://scenes/meta/meta_layer_test.tscn`; die Szene ist als PackedScene ladbar.
- Hauptmenue -> Multiplayer -> Lobby: Route zeigt auf `res://scenes/ui/multiplayer_lobby.tscn`; Host/Join/Ready/Start bleiben in `MultiplayerSession` gekapselt.
- Hauptmenue -> Editor: Route zeigt auf `res://scenes/editor/map_editor.tscn`; Authoring-Snapshots liefern Tool-, Validation-, Live-Test- und Manifeststatus.
- Hauptmenue -> Settings: Display, Audio, Input, FoW und Comic-Bubbles sind im lokalen Settings-Panel erreichbar; Apply/Cancel/Reset bleiben ohne Gameplay-SimulationRoot.

## Settings-Integration
- FoW wird ueber `GameSettingsContract` gespeichert und als stabiler `fog_of_war_mode` in Lobby-Zusammenfassung und 2.5D-FoW-State uebergeben.
- Comic-Bubbles werden ueber `ComicBubbleSettings` gespeichert und vom Runtime-Gate des Mission-Tactical-Controllers gelesen.
- Display- und Audio-Werte werden im Settings-Vertrag getrennt von Gameplay gehalten. Der Headless-Smoke prueft, dass eine reine Display-/Audio-Aenderung den FoW- und Bubble-Modus nicht veraendert.

## Multiplayer-Map
- Host-Maps werden als Manifest mit `map_id`, `map_hash`, Groesse und Consent-Policy beschrieben.
- Ein Client mit lokal passender Map braucht keinen Prompt; unbekannte oder abweichende Maps erzwingen Consent.
- Der aktuelle V1-Pfad validiert und cached Payloads erst nach Zustimmung. Echter Map-Payload-Transport zwischen Peers bleibt ein kleiner Folgepunkt, nicht Teil von TASK_231.

## Editor und Live-Test
- Der Editor kann eine gespeicherte Map in ein Multiplayer-Manifest ueberfuehren.
- Marker, Patrols, Hoehen, Walkability, FoW-Diagnosen und Scenario-Felder sind strukturell validierbar.
- Live-Test ist aus dem Editor als Szene erzeugbar, solange Map und Scenario gespeichert und valid sind.

## FoW und Air
- FoW trennt Terrainwissen, aktuelle Sicht und letzte bekannte Kontakte.
- `mission_air` ist ein Visual-/Mission-Layer ueber Terrain-`height_level`, keine zweite Terrain- oder Gameplay-Wahrheit.
- Friendly Dropship darf fuer das eigene Team sichtbar bleiben; LZ- und Approach-Surface-Marker bleiben FoW-gebunden und verraten keine unknown Map.

## Konkrete offene Punkte
- Manueller Full-Flow-Sichtcheck nach `docs/manual_checks/app_shell_full_flow_checklist.md`.
- Echter Zwei-Instanzen-LAN-Test bleibt nach `docs/manual_checks/multiplayer_two_client_playability_smoke.md` offen.
- Echter Peer-Payload-Transport fuer Editor-Maps ist als spaeterer kleiner Multiplayer-Slice zu schneiden, sobald Host/Join visuell abgenommen ist.
- Vollstaendiges Editor-Undo/Redo bleibt ausserhalb dieses Reviews; aktuell dokumentiert der Editor nur den Single-Tile-Patch-Vertrag.
- Manuelle 2.5D-Sichtchecks fuer FoW, Huegel, Dropship und Kartenlesbarkeit bleiben offen, weil Headless-Tests keine finale visuelle Lesbarkeit bewerten.

## Naechster Schnitt
Die Roadmap kann nach TASK_231 mit TASK_232 in den Character-Gameplay-Roster-Block gehen. App-Shell-Follow-ups sollten nur als kleine Playability- oder Multiplayer-Transport-Slices angelegt werden.
