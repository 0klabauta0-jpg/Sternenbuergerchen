# TASK_122 - Defend Area Semantik

## Ziel
Ein `defend`-Gebiet soll anders funktionieren als ein einzelner Defend-Wegpunkt: Das Fireteam verteilt sich innerhalb des markierten Bereichs, sucht sinnvolle Haltepositionen, richtet Sicherungssektoren aus und bleibt dort bis zu einem neuen GO oder Ad-hoc-Befehl.

## Status: IMPLEMENTIERT

## Voraussetzung
- `TASK_121 - Area Order Marker`

## Kontext
- `FireteamSecurityController` kann bereits Sicherungssektoren und Overwatch-Zustaende modellieren.
- `FireteamMovementController` kann Fireteams als Gruppe bewegen, aber noch nicht innerhalb eines Gebietes verteilen.
- `#17 SELECTED FIRETEAM` zeigt bereits aktuellen Wegpunkt, Befehl, Status und Bewegungsstil.

## Umfang
1. Defend-Area-Ausfuehrung aus Area Order ableiten.
2. Fireteam waehlt pro fittem Mitglied eine Halteposition im Gebiet:
   - bevorzugt walkable Tiles
   - bevorzugt Tiles mit Cover, falls Cover-Daten verfuegbar
   - keine Mehrfachbelegung desselben Zieltiles, wenn vermeidbar
3. FTL bleibt nachvollziehbar als Anker:
   - in der Naehe des Zentrums oder an einer guten Fuehrungs-/Coverposition
4. Security-State wird auf das Gebiet bezogen:
   - 360 Grad bei unbekannter Bedrohung
   - directional bei bestaetigtem Kontakt oder zuletzt bekannter Feindrichtung
5. Defend Area geht nach Erreichen in `WARTET AUF GO` / `HALTET GEBIET`.

## Nicht-Ziele
- Keine komplexe Gebaeuderaum-KI.
- Keine echte Fortifikation.
- Keine langfristige Munitions-/Morale-Simulation.

## Architekturregeln
- Die Auswahl von Haltepositionen gehoert in einen Resolver/Controller, nicht in UI-Code.
- Bewegungsbefehle bleiben autoritativ ueber `SimulationRoot.enqueue_command()`.
- Security/Overwatch bleibt vom Damage-System getrennt.

## Akzeptanzkriterien
- [x] Defend Area verteilt mindestens 2-3 Fireteam-Mitglieder auf unterschiedliche Zielpositionen.
- [x] Das Fireteam klebt nicht als Klumpen auf dem Area-Zentrum.
- [x] FTL bleibt Teil der Formation und nicht dauerhaft am Startpunkt.
- [x] Nach Erreichen zeigt #17 einen klaren Defend-Area-Status.
- [x] Security-Snapshot bezieht sich auf die Area.
- [x] Headless-Verifier prueft Positionsverteilung, Status und Security-Aktivierung.

## Ergebnis
- `AreaOrderResolver` waehlt fuer `defend`-Gebiete pro fittem Fireteam-Mitglied eine Halteposition.
- Die Auswahl bevorzugt vorhandene Terrain-Tiles, meidet nicht-walkable Tiles und nutzt Cover-Werte als Score, wenn eine `TerrainRegistry` verfuegbar ist.
- Der FTL wird als Teil der Formation in Zentrumsnaehe oder auf einer guten Coverposition eingeplant.
- `MissionTacticalSandboxController` startet Defend-Area-Ausfuehrung per GO, enqueued Bewegungsbefehle ueber `SimulationRoot` und schaltet nach Erreichen auf `WARTET AUF GO | HALTET GEBIET`.
- `FireteamSecurityController` kann Area-Kontext konsumieren; der Security-Snapshot enthaelt `area_order_id`, `area_center_position` und nutzt das Gebiet als Anchor.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_122_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_121_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_111_verifier.gd`

## Dateien (voraussichtlich)
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tactical/fireteam_security_controller.gd`
- ggf. `scripts/tactical/area_order_resolver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_122_verifier.gd`

## Risiken
- Zu viel Intelligenz in einem ersten Task wuerde das System schwer testbar machen.
- Cover-Auswertung nur nutzen, wenn die vorhandenen Terrain-Daten stabil genug sind.
