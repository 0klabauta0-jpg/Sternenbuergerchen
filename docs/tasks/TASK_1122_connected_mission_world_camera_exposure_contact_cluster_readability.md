# TASK_1122 - Connected Mission World Camera, Exposure and Contact Cluster Readability

## Ziel / Problem
Nach TASK_1121 ist die echte 3D-Missionswelt sichtbar. Der Produktcapture zeigt nun vier konkrete Lesbarkeitsprobleme: helle Stationsassets verlieren Flaechen und Kanten, der lokale Erstkontakt liegt am Bildrand, mehrere historische Fire-Labels ballen sich am selben Ziel und eine starre Dedupe-Bucket-Grenze kann zeitlich nahe Contact-Reports trennen.

## Sinnhaftigkeit / Ursache
Directional Light und Ambient Fill addieren sich ohne explizites Tonemapping. Die lokale Fireteam-Fokussierung kann vor dem deferred Primary-3D-Aufbau laufen und wird danach nicht wiederholt. Die Weltvisualisierung erhaelt bis zu drei globale Fire-Events, obwohl das verbundene HUD bereits lokal fireteambezogen ist. Die Event-Log-Gruppierung verwendet feste Fuenf-Sekunden-Buckets statt eines gleitenden Zeitabstands.

## Umfang
- Explizites Filmic-Tonemapping und moderate globale Helligkeitskorrektur in der zentralen Primary-3D-Environment-Konfiguration.
- Bounds-basiertes Einmal-Framing fuer lokale Fireteam-Anker und aktuelle Kontakte nach stabilem Primary-View-Aufbau.
- Verbundene aktive Perspektiven visualisieren nur das neueste Fire-Event ihres ausgewaehlten Fireteams; Spectator und Offlinepfade behalten den bisherigen begrenzten Verlauf.
- Contact-Report-Dedupe gruppiert semantisch gleiche unmittelbar aufeinanderfolgende Meldungen innerhalb von fuenf Sekunden gleitend.

## Nicht-Ziele
- Keine Aenderung an Combat, ContactTracker, Fire-Event-Retention oder Netzwerkpayload.
- Kein automatisches Kamera-Tracking pro Frame.
- Keine Einzelkorrektur an Assetmaterialien und kein weiteres historisches Polish-Flag.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1121_connected_first_contact_tactical_world_readability.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/ARCHITECTURE.md`
- `scripts/mission/mission_primary_view_bridge.gd`

## Akzeptanzkriterien
- Render-Snapshot exponiert Filmic-Tonemapping und eine begrenzte Helligkeitskorrektur.
- Eine kleine Fireteam-/Contact-Punktmenge wird sichtbar enger als die volle 32x32-Karte gerahmt.
- Der automatische Fokus laeuft nur bei neuem lokalen Contact-Signature, nicht pro Frame.
- GOLD sieht in der Welt nur das neueste GOLD-Fire-Event, BLUE entsprechend BLUE; Rohereignisse bleiben unveraendert.
- Contact-Reports bei 4,9s und 5,1s werden gemeinsam gruppiert.
- Keine Commands, Effects, Damage-, Movement- oder Multiplayer-Wahrheit entsteht.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1122_connected_mission_world_camera_exposure_contact_cluster_readability.gd`
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1122 headless.
- TASK_1120 und TASK_1121.
- TASK_1119 headless und Real-Window je BLUE/GOLD.
- TASK_293 Lighting-Regressionspfad.
- TASK_222 Performance-Gate.
- `git diff --check`.

## Risiken / offene Punkte
Das Framing darf manuelles Panning nicht wiederholt ueberschreiben. Tonemapping muss Forward+ und Compatibility verbessern. Spectators brauchen weiterhin einen globalen, aber hart begrenzten Weltueberblick.

## Ergebnis / Verifikation
- Die Primary-3D-Environment nutzt Filmic-Tonemapping sowie moderate Brightness-, Contrast- und Saturation-Korrektur. Helle Stationsteile behalten im Forward+- und Compatibility-Pfad erkennbare Flaechen und Kanten.
- `frame_world_positions()` rahmt eine Punktmenge read-only. Verbundene aktive Peers fokussieren bei neuer Contact-Signatur einmalig ihr lokales Fireteam und dessen Kontakt mit Camera-Size 24; manuelles Panning wird danach nicht erneut ueberschrieben.
- Der Client-Combat-Handoff aktualisiert Contact-Visuals nur bei geaenderter Contact-Signatur. BLUE und GOLD bestehen denselben Camera-/Contact-Vertrag.
- Verbundene aktive Perspektiven uebergeben je ausgewaehltem Fireteam nur das neueste Fire-Event an die Welt. Enemy-Security-, Tactic- und normale Fire-Status-Texte werden im `connected_contact`-Fokus unterdrueckt; Marker, Contact-Profil und Feuergeometrie bleiben.
- Die Display-Dedupe folgt nun einer kontinuierlichen Fuenf-Sekunden-Kette ueber feste Zeitgrenzen hinweg. Rohhistorie und Event-IDs bleiben vollstaendig.
- TASK_1122 11/11, TASK_1120 11/11, TASK_1121 8/8, TASK_293 17/17, TASK_1117 15/15, TASK_1119 23/23 headless und 24/24 je Real Window, TASK_1104 31/31, TASK_222 82/82.
- Sichtbare Folgearbeit: Fireteam-Proxies stehen am Kontakt noch zu stark in einer vertikalen Reihe; ein isolierter Assetblock ausserhalb des Kartenverbands konkurriert mit dem Fokus.
