# TASK_1116 - Connected Post-Deboard Fireteam Command Handoff

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Ziel / Problem
Nach dem verbundenen Deboarding muessen BLUE und GOLD sofort ihren ersten Bodenbefehl planen und per GO hostautoritativ ausfuehren koennen. Normale Move-/Defend-Orders duerfen nicht in der lokalen Client-Queue stecken bleiben.

## Sinnhaftigkeit / Ursache
Der spezielle Missionsinteraktions-GO besitzt bereits einen RPC-Handoff. Der allgemeine Fireteam-GO startet jedoch den lokalen MovementController. Auf einem verbundenen Client wird dessen Simulation absichtlich nicht getickt; dadurch bleibt der Befehl lokal wirkungslos.

## Umfang
- Client projiziert den naechsten geplanten Fireteam-Waypoint als `commander_intent`.
- Host validiert Team und Fireteam-Zuweisung.
- `SimulationRoot` committed den Intent im autoritativen Tick.
- Host-Controller startet danach den bestehenden FireteamMovementController mit Pathfinding, Formation und Taktikprofil.
- Per-Fireteam Pending verhindert Doppel-GO.
- Host-OK/Blocked bleibt read-only sichtbar.
- BLUE und GOLD koennen parallel unterschiedliche Ziele befehlen.

## Nicht-Ziele
- Kein neuer Movement- oder Pathfinding-Resolver.
- Keine Replikation lokaler Planungs-UI.
- Kein Prediction-/Rollback-System.
- Kein Combat-Rewrite.

## Akzeptanzkriterien
- BLUE- und GOLD-Client senden je genau einen Intent.
- Client-GO erzeugt keine lokalen Commands oder Effects.
- Host startet beide vorhandenen Fireteam-Movement-Pfade.
- Fremd-Fireteam-Intent wird abgewiesen.
- Clients erhalten menschliches Host-Feedback und Positionssnapshots.
- Singleplayer-GO bleibt unveraendert.

## Betroffene Dateien
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1116_connected_post_deboard_fireteam_command_handoff.gd`
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1116 Drei-Peer-Handoff
- TASK_1115 Parallel Drop/Deboard/RTB
- TASK_501 Movement Lifecycle
- TASK_475 Pathfinding/Avoidance
- TASK_399 Dropship-Hotpath
- TASK_1104 Drei-Peer-Produktlauf
- `git diff --check`

## Risiken / offene Punkte
Der Netzwerkpfad darf nur Intent-Daten transportieren. Host-Taktik, Formation, Pathfinding und Unit-Commands bleiben bestehende autoritative Systeme.

## Ergebnis
- Verbundene Clients legen Move-/Defend-Ziele als lokale Preview-Waypoints an; erst GO sendet einen `commander_intent`.
- `SimulationRoot` committed den Intent im Host-Tick und emittiert ihn an den Mission-Controller.
- Nur der Host startet den vorhandenen FireteamMovementController mit Taktikprofil, Pathfinding, Formation und Unit-Commands.
- Per-Fireteam Pending blockiert Doppel-GO; Host-OK und Blocked bleiben read-only sichtbar.
- `commander_intent` verlangt jetzt explizit die Peer-Fireteam-Zuweisung. TASK_281 wurde auf Own-Accept/Foreign-Reject aktualisiert.
- TASK_1116 besteht 16/16 inklusive sichtbarer Positionskonvergenz fuer BLUE und GOLD ohne lokale Client-Commands oder Effects.
- TASK_281 34/34, TASK_501 10/10, TASK_475 17/17, TASK_1094 6/6, TASK_1115 25/25 und TASK_1104 31/31 bleiben gruen.
