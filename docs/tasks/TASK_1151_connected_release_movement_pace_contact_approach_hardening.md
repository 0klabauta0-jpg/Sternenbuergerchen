# TASK_1151 - Connected Release Movement Pace and Contact Approach Hardening

## Ziel / Problem
Im echten Zwei-EXE-Lauf werden Blue- und Gold-Moves autoritativ angenommen und auf korrekte Map-Marker geroutet, erreichen aber innerhalb von 180 Sekunden keinen Kontakt. Die sichtbare Einsatzbewegung ist fuer den erwarteten zuegigen Commander-Flow zu langsam.

## Umfang
- Wall-Time, Sim-Ticks, Physics-FPS, Fireteam-Anchor-Fortschritt und Zielreststrecke im Release-Trace messen.
- Single-EXE und Zwei-EXE-Pace vergleichen.
- Klaeren, ob niedrige Prozess-FPS, doppelte Tick-Drosselung, Terrain-Speed, Formation-/Avoidance-Warten oder Command-Lifecycle die Rate begrenzt.
- Die gefundene Ursache im bestehenden Movement-/Tick-Vertrag korrigieren.
- TASK_1150 First-Contact-Release-Lauf erneut ausfuehren.

## Nicht-Ziele
- Keine Teleports.
- Keine Gegner nur fuer das Gate naeher setzen.
- Kein Ignorieren von Terrain, Formation, LOS oder Multiplayer-Autoritaet.
- Kein pauschaler globaler Speed-Multiplikator ohne Messbeleg.

## Akzeptanzkriterien
- Blue und Gold zeigen kontinuierlichen, host-autoritativen Fortschritt ohne Snapback oder Randverteilung.
- Zwei Release-Prozesse erreichen den vorgesehenen Contact-Approach in einer spielbaren Zeitspanne; Zielbudget zunaechst 45 bis 75 Sekunden nach Contact-Advance.
- Host und Client beobachten mindestens einen gemeinsamen Kontakt und dasselbe erste Fire-Event.
- TASK_1116, TASK_1117, TASK_1148, TASK_1150 und TASK_222 bleiben gruen beziehungsweise TASK_1150 wird durch den echten Recapture gruen.

## Betroffene Dateien
- voraussichtlich Fireteam-Movement-/Tick-Pfade nach Messbefund
- `scripts/ui/multiplayer_lobby_screen.gd` nur fuer read-only Timing-Evidence
- fokussierte Verifier und Release-Harness
- Status, Roadmap und HTML-Handbuch

## Risiken / offene Punkte
Der synthetische Performance-Gate kann gruen sein, waehrend zwei sichtbare Release-Prozesse zu wenig reale Simulationsfortschritte pro Sekunde liefern. Die Korrektur muss deshalb Wall-Time und autoritative Sim-Ticks gemeinsam betrachten.

## Zwischenstand 2026-07-12
- Der First-Contact-Trace schreibt sekuendlich Wall-Time, Sim-Ticks, FPS, Start-/Ziel-/Istposition, Fortschritt und Restdistanz.
- Der alte 180-Sekunden-Befund enthielt einen eingefrorenen Frueh-Snapshot; aktuelle Traces zeigen kontinuierliche Bewegung.
- Dekorative `spawn_enemy_*`-Marker waren keine Runtime-Gegnerwahrheit. Ein read-only ContactApproachResolver nutzt registrierte Gegner beziehungsweise den gemeinsamen `spawn_bravo`-Proxy, A* und LOS.
- Der Resolver prueft den Formation-Footprint statt nur den Ankerpunkt.
- Profilbefund: Der direkte Combat-Tick kostete etwa 17 ms, davon rund 13 ms Overwatch. Teure Tactical Decisions laufen jetzt mit 20 Hz; Detection und Contact-Tracking bleiben pro Sim-Tick aktiv.
- Echter Effekt: Host-Durchsatz stieg von rund 18,5 auf 30,3 autoritative Ticks pro Sekunde. TASK_1117 bleibt mit gemeinsamem Kontakt, First Fire und identischen Vitalwerten 15/15 gruen.
- Standalone Network Intents besitzen jetzt einen eigenen Lifecycle und werden nicht mehr durch fehlende UI-Plans beendet. Ein expliziter Spielerbefehl verwirft ausstehende automatische Post-Drop-Security und deren tokenisierte Altbefehle.
- Der periodische Missions-HUD-Refresh trennt schnelle Statusdaten von schweren Runtime-/Strategieoberflaechen. Direkte Spieleraktionen behalten den sofortigen kompletten Refresh.
- Contact-Approaches pruefen neben LOS auch die Erreichbarkeit der gesamten Formation. Der Release-Anflug nutzt `engage`, weil ein normaler Travel-Move Waffen und Wahrnehmung absichtlich absenkt.
- Abschlussbeleg: Der echte Zwei-EXE-Lauf ist nach 73,2 Sekunden gruen. Host und Client bleiben aktiv, Deployment und First Decision konvergieren, Kontakt entsteht rund 16 Sekunden nach Engage, und beide sehen dasselbe erste Fire-Event.
- Restbefund: Der schwere Host-HUD-Refresh kostet im gemessenen Vollpfad weiterhin rund 266 ms. Das blockiert TASK_1151 nicht mehr, ist aber die naechste klar abgegrenzte Performance-Arbeit.

## Abschluss
- Status: implementiert und im exportierten Release verifiziert.
- Verifier: TASK_1151 64/64, TASK_1117 15/15, TASK_1043 14/14, TASK_1044 15/15, TASK_479 25/25, TASK_399 9/9.
- Release-Artefakt: `tmp/release_host_client_first_contact_playtest.json`, Gate `pass`.
