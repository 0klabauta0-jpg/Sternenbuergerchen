# Lokalen Multiplayer heute pruefen, 05.11.2026

## Ziel / Problem
Den aktuellen normalen Host/Join-Pfad tatsaechlich lokal versuchen und
Verbindung, Start, Autoritaet und Kartenfreigabe getrennt belegen. Dieser
Untertask ist lesendes Audit plus konkreter Pruefbatch fuer Root; keine
Produkt-, Engine-, Firewall-, Git- oder Savedatenaktion durch den Auditor.

## Aktuell aus Code belegt
- Der beim Harnessbau gefundene GM01-Blocker (2.425.578-Byte-Karte gegen altes
  1-MiB-Limit) wurde von Root inzwischen reproduziert: gezieltes Gate 4 PASS /
  3 FAIL. Root korrigierte den eigenen MapManifest-Pfad/Contract auf begrenzte
  4 MiB, danach 7/7 gruen; 4-MiB-plus-eins bleibt abgelehnt, Consent unveraendert.
  Das Audit lockert selbst keine Produktgrenzen. Der Zwei-Prozess-Harness
  verlangt weiterhin den echten gepinnten GM01-Hash auf beiden Peers.
- MainMenu `_apply_release_deeplink()` fuehrt Host/Join-Argumente auf denselben
  `_on_multiplayer_pressed()`-Pfad wie der sichtbare Multiplayerbutton.
  Produktlobby: `scenes/ui/multiplayer_lobby.tscn`.
- `MultiplayerSession.start_host` / `join_session` verwenden echtes ENet,
  Default `127.0.0.1:7777`, zwei Spieler. Host startet erst bei genuegend
  verbundenen und bereiten Peers; Versus verlangt getrennte Seiten.
- Die Produktlobby besitzt Name, Roster, Team, Coop/Versus, Karte und
  LAN/Direct-WAN/UPnP-Auswahl. Privates lokales Roster bleibt Opt-in;
  Host-Roster ist der aktuelle Standard. Keine neue Rosterwahrheit noetig.
- `SimulationRoot.request_command` ist ein any_peer/reliable-Eingang, validiert
  am Authority-Owner und sendet bestaetigte Ergebnisse. Snapshot-RPCs sind
  authority-only. Roles/Teams/Fireteams begrenzen Clientbefehle.
- Mapmanifest prueft ID, SHA-256, Groesse und Format; missing/hash_mismatch
  verlangt Zustimmung. Start-RPC respektiert `can_start_client`. Zustimmung,
  Ablehnung, stale Offers und Rejoin besitzen bestehende Regressionen.
- **Konkrete V1-Grenze:** `_on_map_accept_pressed` setzt nur den Text
  `Waiting for host map payload...`. `accept_pending_map_download(payload)`
  existiert, ein Netzwerk-Payloadtransport fuer fremde Karten fehlt weiterhin
  absichtlich laut Contract. Heute fuer den realen Versuch auf beiden Seiten
  dieselbe gepinnte projektlokale GM01 verwenden; keinen Download behaupten.
- **Versionsbefund:** Im geprueften Session-/Lobby-/SimulationRoot-Pfad wurde
  kein expliziter App-Build-/Protokollversionshandshake gefunden. Kartenformat-
  und Snapshotschema-Versionen ersetzen das nicht. Der lokale Versuch bindet
  beide Prozesse an denselben eingefrorenen Quellstand und Godot 4.6.2.

## Vorhandene Evidenz richtig einordnen
TASK1147 beschreibt historische zwei echte Release-EXE-Prozesse bis
`mission_started`; das ist kein heutiger Sourcebeleg. Sein PowerShell-Harness
startet eine bestehende EXE, nutzt feste tmp-Namen und Fenstermodus und passt
daher nicht unveraendert zum heutigen isolierten Vollbildauftrag.
TASK1083 und TASK1104 erzeugen echte ENet-Peers mit getrennten MultiplayerAPIs
innerhalb eines Prozesses. Sie pruefen RPC/Ownership bzw. Produktlobby, ersetzen
aber keinen heutigen Zwei-Prozess- oder Zwei-Rechner-Nachweis.
Die drei frueheren Main-Baselinegates sind laut aktuellem
`LEGACY_GATES_2026_11_04.md` inzwischen korrigiert; den alten Review7-Rotstand
nicht als aktuellen Multiplayerfehler wiederverwenden.

## Konkreter kurzer Pruefbatch fuer Root
`PLAYTEST_2026_11_05_multiplayer_checks.json` enthaelt sieben vorhandene Gates:
ENet-Socket, Lobby-/Session-Consent, Versus, Rejoin nach Missionende, private
Rostergrenze und echte RPC-/ROE-Ownership. Alle muessen Exit0, ihren Marker,
numerische null FAILs, null Engine-/Leakdiagnostik und Isolationscanary liefern.

```powershell
python scripts/tests/run_review2_isolated.py --project C:\dev\SternenBuergerchen --manifest docs/tasks/PLAYTEST_2026_11_05_multiplayer_checks.json --baseline output/playtest_20261105/roster_baseline.json --output output/playtest_20261105/multiplayer_preflight --godot godot_console.exe
```

Root verwendet dabei seinen bereits verifizierten absoluten Enginepfad, falls
`godot_console.exe` nicht genau diese Engine bezeichnet. Ports der Gates sind
in den Testquellen festgelegt; seriell ausfuehren, keinen belegten Port durch
Beenden anderer Prozesse freiraeumen. Bei erstem reproduzierten Fehler gezielt
diagnostizieren, nicht die gesamte historische Multiplayer-Suite starten.

## Danach echte zwei aktuelle Sourceprozesse
Root-ausfuehrbarer neuer Harness:

```powershell
python scripts/tests/run_playtest_20261105_multiplayer.py --godot <Roots-absoluter-Godot-4.6.2-Pfad> --baseline output/playtest_20261105/roster_baseline.json --output output/playtest_20261105/multiplayer_pair --timeout 240 --port 28747 --resolution 3440x1440 --mode entry
```

Marker `MULTIPLAYER_PAIR_LAUNCHED`, `MULTIPLAYER_PAIR_STATE` und final
`MULTIPLAYER_PAIR_PASS` beziehungsweise `MULTIPLAYER_PAIR_FAIL`.
Pro Run: report.json, source_pins_before.json, getrennte Logs/stdio/Traces,
beobachtete Fenster-/Monitorgeometrie und zwei eigene Canarys.
`--mode drop` fordert konvergierte reale Deployed-IDs und akzeptierte erste
Entscheidung; `--port 0` waehlt einen freien lokalen Port.
Zwei bestehende create_overlay-Projekte, aktuelle Engine/MainScene, Engine-
version/-SHA, Harness-/Helper-SHA und alle GD-/Daten-/Karten-/Szenen-/Shaderpins
werden erfasst und nachher verglichen. Keine fremden Prozesse werden beendet.
WM_CLOSE geht nur an Fenster der eigenen Popen-PIDs, acht Sekunden Quitfrist,
danach nur diese PIDs per dokumentiertem Deadlinefallback. Erzwungener Exit
bleibt sichtbar und laesst das Gesamtgate scheitern. Die Sessionphase reserviert
15 Sekunden des maximal 240-Sekunden-Budgets fuer die Beendigung.

1. Alle Produktquellen fuer das Laufzeitfenster einfrieren und Pins/Engine-
   Version/Renderer aufnehmen. Original-Roster-Baseline vorher pruefen.
2. Den vorhandenen Pythonhelper `create_overlay` aus
   `scripts/tests/run_review2_isolated.py` zweimal mit verschiedenen frischen
   Run-IDs verwenden. Er teilt Ressourcen/Importcache, gibt jedem Projekt einen
   eigenen Appnamen, `user://`, tmp/output und vorangestellten Pfadguard.
   Pro Kindprozess `SB_REVIEW2_USER_DIR` auf genau dessen berechneten
   `%APPDATA%/Godot/app_userdata/SB-Codex-Review2-<id>` setzen. Canary muss passen.
3. Normalen Main-Scene-Einstieg des jeweiligen Overlayprojekts verwenden.
   Beide nativen Prozesse laufen gemaess aktuellem Auftrag im echten Vollbild
   auf dem aktiven 3440x1440-Display. Fuer Bilder jeden Prozess einzeln fokussieren.
   Vorhandene Engine-/Displayparameter aus Roots aktuellem Vollbildharness
   uebernehmen; keinen alten Compatibility-/Fenster-Override erben.
4. Freien lokalen UDP-Port, z.B. 28747, fuer beide verwenden. Unterschiedliche
   absolute Trace-/Logpfade im neuen Ausgabepaket setzen. Host zuerst starten,
   nach bestaetigtem Hosting Client; nie normalen Profilpfad gemeinsam benutzen.

Host-Userargs hinter `--`:
```text
--release-multiplayer-host --release-multiplayer-port=28747 --release-multiplayer-auto-start --release-multiplayer-trace=<absoluter neuer Hosttrace.json>
```
Client-Userargs hinter `--`:
```text
--release-multiplayer-join --release-multiplayer-address=127.0.0.1 --release-multiplayer-port=28747 --release-multiplayer-trace=<absoluter neuer Clienttrace.json>
```

5. Begrenzt bis 60 Sekunden beobachten: beide Traces muessen getrennte
   `session.local_peer_id`, `connected_count=2`, `ready_count=2`,
   `active_mission=true` und `stage=mission_started` zeigen. Produktlobby/
   Missionsbilder beider Prozesse aufnehmen, Port und tatsaechliche PIDs notieren.
   Kein Timeout mit erfundenem Ready-, Actor- oder Timerzustand reparieren.
6. Danach optional beide beim frischen Versuch zusaetzlich mit
   `--release-multiplayer-drop-decision` starten. Innerhalb bis 90 Sekunden
   `drop_decision.stage=first_decision_accepted`, dieselben real deployed Unit-IDs
   auf Host/Client und keine verbleibenden embarked IDs verlangen. Das ist der
   vorhandene befehlsgesteuerte LZ/Drop/GO-Pfad. FirstContact ist ein getrenntes,
   laengeres Gate (`--release-multiplayer-first-contact`), kein Startnachweis.
7. Logs/Traces/PIDs/Sourcepins/Canarys/Roster-vorher-nachher sichern. Nur selbst
   gestartete Prozesse ueber die normale Beendenroute schliessen. Originalroster
   muss in Bytes, Laenge und Schreibzeit unveraendert sein.

## Umfang / Nicht-Ziele und Risiken
Heute Loopback auf einem Rechner mit identischen Quellen. Kein LAN-/Internet-
oder Mehrrechnernachweis, kein automatischer fremder Kartendownload, kein
Versions-Mismatch-Beleg, keine aktuelle Export-/Releaseabnahme. Bei Firewall-
dialog keine Regeln blind veraendern; lokalen Versuch und Dialog getrennt erfassen.

## Relevante Quellen / betroffene Dateien
multiplayer_session_lobby, multiplayer_editor_map_transfer_contract,
multiplayer_authority_command_contract, multiplayer_snapshot_replication_contract,
multiplayer_player_roster_ownership_contract, main_menu_screen.gd,
multiplayer_lobby_screen.gd, multiplayer_session.gd, simulation_root.gd sowie
TASK1083/1104/1147 und die sieben konkreten Gatequellen. Schreibumfang dieses
Audits diese Task, das Checkmanifest und der neue Root-ausfuehrbare Python-
harness; Homebase/Portraetquellen frozen.

## Akzeptanz / lokaler Stand
Root hat den ersten aktuellen Zwei-Prozess-Dropversuch unter
`multiplayer_pair/20261105T075417Z-eb85b70a/report.json` ausgefuehrt:
beide `first_decision_accepted`, identische acht Deployed-IDs, embarked leer,
zwei ready Peers, GM01 `known` mit exakt gleichem Hash, keine Enginefehler.
Gesamtgate bleibt **FAIL**: beide Windowlisten leer, deshalb kein nativer
Vollbildnachweis und nur erzwungene eigene PID-Beendigung. Der gewaehlte
Console-Wrapper besitzt offenbar nicht das eigentliche GUIfenster; der
Harness hatte zusaetzlich CREATE_NO_WINDOW gesetzt. Bericht bleibt erhalten.

Korrektur nur im Harness: direkten GUIenginepfad verlangen, Console-Launcher
ablehnen, CREATE_NO_WINDOW entfernen und wie Roots andere native Laeufe
explizit `forward_plus` / `vulkan` verwenden. HWND-/PID-Abgleich nutzt die
64-Bit-argtypes fuer EnumWindows und alle Fensterabfragen. Root startet erneut:

```powershell
python scripts/tests/run_playtest_20261105_multiplayer.py --godot C:/Users/bjoer/AppData/Local/Programs/Godot/Godot_v4.6.2-stable_win64.exe --baseline output/playtest_20261105/roster_baseline.json --output output/playtest_20261105/multiplayer_pair --timeout 240 --port 0 --resolution 3440x1440 --mode drop
```

Audit abgeschlossen, sieben Scripts/Marker und aktiver CLI-Einstieg gelesen.
Keine Engine gestartet. Batch und aktueller Zwei-Prozess-Versuch sind Root-
Arbeit und bis zu ihren neuen Artefakten offen. Menschliches Multiplayer-
Spielgefuehl und gestalterisches Nutzerurteil bleiben separat offen.
