# AP5 Bewegungskonsumenten: Gruppe und 3DProxy

Problem: Nach a66b84522 führt Root echte Hexziele aus, die Gruppenankunft liest
aber noch Pixeldistanz und der 3DProxy glättet Position und liest Rampenhöhe aus
dem aktuell überzeichneten Feld. Dadurch drohen Frühankunft und doppelte Glättung.

Umfang: schmaler Root-Ankunftsreader mit geprüftem Zielhex, Fireteam-Ankunft
über existierenden übergebenen Root und reine Proxyposition/-richtung/-bewegung
aus Rootmetadaten. Vorhandenes `_get_3d_height_step()` bleibt alleiniger
Darstellungsmaßstab, keine neue Höhe in Ground. Kein neuer Sandboxbesitz.
Verträge: hex_tactical_runtime_contract.md, explicit_hex_ramps_contract.md,
HEX_MOVE_COMMAND_ADAPTER_2026_11_11.md und AP5 des Arbeitsplans.

Akzeptanz:
- Frühe Renderposition am Ziel und finales Handoff ohne Segmentende beenden
  die Gruppe nicht; tatsächliche Ankunft tut es auch bei abweichender Darstellung.
- Unit-/Stage-Token und angefragtes Zielhex müssen passen; fehlende zugelassene
  Gruppenmitglieder oder fremde Ziele werden nicht als angekommen behandelt.
- Proxy verwendet stetige logische Rampenhöhe mit aktuellem Viewmaßstab,
  committete Richtung und Bewegungsphase, keine zweite Positionsglättung.
  Waffenpose darf weiterhin die vorhandenen Feuerevents darstellen.
- Legacy-Positionsglättung und Pixelankunft bleiben erhalten.

Dateien: SimulationRoot, FireteamMovementController, TerrainMap3DView, kleiner
hex_movement_consumers_verifier und isolierter Runner. Kein Eingriff in die
reservierten Kamera-/Raster-/Karten-/ShipCard-/Crew-/Meta-Bodies des anderen Chats.
Prüfung: kleiner tatsächlicher Root/Registry/Actor-/Controller-/Viewreaderfall,
Nachbarcase movement, frischer Review. Kein Renderer-/Assets-/Spielgefühltest.

Offen/Nichtziele: Türguard, Bewegungsschuss, Backoff, Lifecycle/Save/Netzwerk;
keine Karte aktivieren, keine große Szene oder Performancefreigabe. Risiko:
Metadaten sind ausschließlich abgeleitete Darstellung und müssen an Release/
Kontextende wie bereits im Rootadapter entfernt werden. Gruppenfortschritt
bleibt Planungszustand; Gameplayankunft wird allein beim Ortsroot gelesen.

Ergebnis: Rootreader, tatsächlicher Fireteam-Start/Update samt logischen
Start-/Formationsankern und Proxyanschluss implementiert. Abgeleitete Rootmeta
`hex_ground_facing_angle` isoliert den Körperwinkel von älteren kosmetischen
Facingwrites; Release/Kontextende räumen es zusammen mit Höhe/Phase auf.
Cover-Hold verlangt explizites endliches Ziel desselben Hex und passenden Token;
generischer Hold ohne Ziel ist gültiger Befehl, aber kein Zielankunftsbeweis.

Kleiner Consumer65/0 (einschließlich42 Grundprüfungen), Movement42/0 und
Security34/0; Guards grün, QA hex_move_consumers_20261111. Frischer Review
reproduzierte und schloss Renderanker bei mehreren Mitgliedern, große Metrik,
null-Holdziel und kosmetischen Winkelwrite. Keine native Darstellung abgenommen.
