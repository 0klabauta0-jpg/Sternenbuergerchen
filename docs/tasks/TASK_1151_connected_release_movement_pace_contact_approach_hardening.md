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
