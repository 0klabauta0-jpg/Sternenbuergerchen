# REVIEW7 - Sieben Performance-/Architekturbefunde, 2026-11-03

## Ziel und Ursache
Die sieben auf Main `668423dcf` reproduzierten P2-Befunde beheben. Nutzerauftrag:
mit den kommentierten Befunden weiterarbeiten. Getrennte Fehlergrenzen:
Terrain-Kanten bei Separation, Multiplayer-Mapfreigabe, Versus-Seiten,
Reconnectidentitaet, FoW-Jobinvalidierung, Erstkontaktkamera und Animationsredraw.

## Umfang und Nicht-Ziele
Gezielte Korrekturen bestehender Runtime-/Visualpfade mit Regressionstests.
Keine Architektur-Neuerfindung, Assetaenderung, Release- oder FPS-Abnahme.
Task-Branch auf aktuellem Main; keine Main-Integration in diesem Auftrag.
Fremde unversionierte Dateien und echte Nutzerdaten bleiben unangetastet.

## Relevante Dokumente
- `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`, `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/terrain_height_hill_rules.md`, `docs/dev/hex_grid_v1_contract.md`
- `docs/dev/multiplayer_editor_map_transfer_contract.md`
- `docs/tasks/TASK_1101_connected_interaction_reconnect_state_recovery.md`
- `docs/tasks/TASK_1189_fow_dirty_region_fanout.md`
- `docs/tasks/TASK_1122_connected_mission_world_camera_exposure_contact_cluster_readability.md`
- `docs/tasks/TASK_1125_connected_first_contact_local_team_contact_cluster_readability.md`
- Reviewdiagnostik `.godot/review7_20261103/verification_summary.json` (lokal, ignoriert)

## Akzeptanzkriterien
1. Separation kann weder gesperrte Hoehenkanten noch gesperrte Zwischen-/Diagonal-
   Uebergaenge kreuzen; gleiche Hoehe, legale Haenge und terrainloser Betrieb bleiben.
2. Eingehende Host-Manifeste werden geprueft. Abgelehnte, fehlende, abweichende oder
   ungueltige Maps starten keine Clientmission; bekannte/akzeptierte Maps bleiben startbar.
3. Versus weist dem Client die Gegenseite der gewaehlten Hostseite zu und verweigert
   Start bei gleichen Seiten. Cooperative-Verhalten bleibt erhalten.
4. Verbundene Clients behalten nach Missionsabschluss ihre Reconnectidentitaet;
   echter ENet-Rejoin funktioniert auch in der zweiten Mission. Sessionreset raeumt auf.
5. Reine Gegnerbewegung verwirft keinen Terrain-FoW-Job. Targetsicht bleibt aktuell;
   Beobachter-/Terrain-/Modusaenderungen invalidieren korrekt und publizieren atomar.
6. Derselbe bewegte Kontakt ueberschreibt nach Erstkontakt keine manuelle Kamera.
   Neuer Missions-/Kontaktkontext kann weiterhin initial geframt werden.
7. Laufende sichtbare Animationen invalidieren den UPDATE_ONCE-Viewport auch ohne
   Clipwechsel; inaktive/unsichtbare Animationen verursachen keine Dauerredraws.

## Betroffene Dateien
- `scripts/tactical/local_avoidance_resolver.gd`
- `scripts/multiplayer/multiplayer_session.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/ui/multiplayer_lobby_screen.gd` (echter Consent-/Maplaunch-Consumer)
- Neue gezielte `scripts/tests/review7_*`-Regressionen, Testmanifest und Ergebnisdoku.

## Lokale Pruefung
Regressionen vor Produktfix ausfuehren (RED), danach GREEN und passende bestehende
Nachbargates. Ausschliesslich unveraenderter `run_review2_isolated.py`, frischer
Baseline-/Sicherungsstand der Originalrosterdatei, synchroner Userpfadguard und
Canary. Engine-Laeufe seriell. Abschliessend gemeinsamer Manifestlauf und
unabhaengiges Diffreview. Bekannter TASK839-Altfehler bleibt sichtbar.

## Risiken und offene Punkte
Terrain-Segmentpruefung muss Square/Hex und Mehrtilekorrekturen abdecken.
Map-Consent darf weder implizit zustimmen noch unveraenderte Ablehnung zuruecksetzen.
Der echte Payloadtransport bleibt wie in TASK228 ausserhalb V1: der Acceptbutton
wartet auf Payload; die bestehende explizite Payload-API validiert und speichert.
Kein neuer RPC-Download und keine Scenario-/Assetsynchronisation in diesem Fix.
FoW publiziert vollstaendige Positionsstichproben unter ihrer urspruenglichen
Anfragesignatur. Laufende Beobachterbewegung wird fuer den naechsten 100-ms-Aufruf
zusammengefasst, ohne den Job staendig zu verwerfen. Terrain-/Modus-/Team-/aktive
Observer-/Sichtaenderungen invalidieren dagegen vor dem naechsten Arbeitsschritt.
Die letzte abgeschlossene Terrainrevision bleibt waehrend Pending sichtbar;
im Initialzustand ist sie leer. Der echte View behaelt Mesh und Cursor auch bei
fortlaufenden Deltas waehrend des Erstaufbaus. Revisionsluecken bauen sicher neu.
Die initiale Vollkarte kann mehrere Sekunden brauchen; die 350-ms-Dirty-Grenze
aus TASK1189 ist keine Zusage fuer den initialen Vollscan. Redrawkorrektheit
kann CPU-/Renderarbeit erhoehen; Headless-Strukturnachweis ersetzt keine Pixel-
oder native Framerate-Abnahme. Die begrenzten finalen Nachweise stehen unten.

## Umsetzung und Gegenpruefung
Alle sieben Befunde reproduziert und Regressionen vor jeweiligem Fix rot gesehen.
Zusaetzliche Gegenreview-Korrekturen: echte FoW-View darf bei Zielupdates nicht neu
aufbauen; kontinuierliche Observerbewegung behaelt Jobfortschritt und aktuelle
Target-LOS; Kartenaktionen fuer alte Angebote bleiben wirkungslos; reale Lobby
zeigt Consent und laedt die verifizierte Map vor Szenenstart.
Abschlussmatrix und unabhaengiges Nachreview sind im Ergebnisindex protokolliert.
Zusaetzlich nativer D3D12-/Forward+-Verifier mit erzwungenem GPU-Pufferruecklesen
und drei echten PNGs. Headless-Dummy unterstuetzt dieses Ruecklesen nicht;
die Struktur-/Zustandsassertionen bleiben dort zwingend, GPU-Assertions laufen nativ.

## Abschluss
Sieben Befunde behoben, unabhaengig APPROVED. 11 neue Gates 699/699 Assertions;
frischer gemeinsamer Abschluss 103 Gates, davon 100 PASS /3588 Assertions.
Drei reproduzierte Original-Main-Altfehler bleiben sichtbar: TASK839 29/2,
TASK1122 9/2, Lobby-/Assetfollowup 35/3. Exklusiver nativer Folgelauf 39/39,
GPU-Pufferruecklesen erzwungen und drei echte PNGs geprueft. TASK1188 p99
3918us <8000us. Insgesamt 259 eindeutige isolierte Prueflaeufe, Originalroster
gleich, 114 Quellfingerprints unveraendert. Details im Index
`output/review7_fixes_20261103/verification_summary.json` und README.
Gepruefte Produktcommits: `1fc8a7709`, `e3e4483c9`, `ac63f662a`.
Task-Branch; keine Main-Integration. Endgueltiger Pushstatus im Git-Handoff.
