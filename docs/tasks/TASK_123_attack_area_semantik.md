# TASK_123 - Attack Area Semantik

## Ziel
Ein offensives Gebiet soll nicht wie ein stumpfer Move-Befehl funktionieren. Fireteams sollen ein markiertes Angriffsziel als Zielbereich behandeln: Annaehern, Kontakt suchen, Gegner im Gebiet priorisieren, bei Kontakt Feuer freigeben und vorhandene Movement-/Suppression-/Flank-Systeme nutzen.

## Status: ERLEDIGT

## Voraussetzung
- `TASK_121 - Area Order Marker`
- empfohlen: `TASK_122 - Defend Area Semantik`

## Kontext
- `CombatFireDecisionResolver`, `ContactTracker`, `OverwatchController` und `FlankVulnerabilityResolver` existieren bereits.
- Offensive Einzelmarker werden aktuell als rote Linien dargestellt, aber die taktische Bedeutung ist noch punktbasiert.
- Das Spielgefuehl soll indirekte Kontrolle bleiben: Spieler markiert WAS, FTL entscheidet WIE gut.

## Umfang
1. Attack-Area-Ausfuehrung fuer `engage`, `take` und offensive `flank`-Gebiete.
2. Fireteam bildet einen Approach-Punkt ausserhalb oder am Rand des Zielgebiets.
3. Beim Annaehern:
   - Bewegungstil aus BehaviorProfile verwenden
   - bei Kontakt Feuerfreigabe anpassen
   - ContactTracker mit Zielgebiet verknuepfen
4. Im Zielgebiet:
   - Gegner innerhalb des Gebiets priorisieren
   - Gegner ausserhalb nur nach vorhandenen Contact-/Threat-Regeln behandeln
   - nach Gebietssicherung optional in Defend-/Security-Zustand wechseln
5. Schlechte Teamqualitaet darf Zieloffset, Reaktionszeit und Formation weiter beeinflussen.

## Nicht-Ziele
- Keine vollwertige Zielplanung mit mehreren Assault-Lanes.
- Keine Rauchgranaten, Breaching oder Spezialausruestung.
- Keine neue Damage-Formel.

## Architekturregeln
- Offensive Area-Entscheidungen gehoeren in einen Resolver, der bestehende Combat-/Contact-Systeme konsumiert.
- Kein zweites Combat-System bauen.
- `SimulationRoot` bleibt die autoritative Stelle fuer Damage-/Move-/Heal-Effects.

## Akzeptanzkriterien
- [x] Attack Area erzeugt einen nachvollziehbaren Approach statt direktem Klumpenlauf ins Zentrum.
- [x] Fireteam priorisiert Kontakte im markierten Gebiet.
- [x] #17 zeigt Attack-Area-Zustand und Zielbereich.
- [x] Nach gesichertem Gebiet wechselt das Fireteam in einen Halt-/Security-Zustand.
- [x] Bestehende Einzel-Wegpunkt-Angriffe funktionieren weiter.
- [x] Headless-Verifier prueft Approach, Target-Priorisierung und Abschlusszustand.

## Umsetzung
- Offensive Area Orders (`engage`, `take`, `flank`) erzeugen zuerst einen Approach-Punkt am Rand/ausserhalb des Gebiets.
- `CombatFireDecisionResolver` fragt eine optionale Area-Prioritaet ab und bevorzugt Ziele im aktiven Angriffsfeld.
- Nach Erreichen des Approach wechselt das Fireteam in einen Security-Hold und wartet auf GO.

## Dateien (voraussichtlich)
- `scripts/tactical/combat_fire_decision_resolver.gd`
- `scripts/tactical/contact_tracker.gd`
- ggf. `scripts/tactical/area_order_resolver.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_123_verifier.gd`

## Risiken
- Attack Area kann schnell zu gross werden. V1 soll nur Zielbereich, Approach und Priorisierung liefern.
- Zu aggressive Auto-Entscheidungen koennen dem Commander-Gefuehl schaden.
