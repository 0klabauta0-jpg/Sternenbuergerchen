# TASK_270 - Commander to Fireteam Leader Delegation Contract

## Ziel
Der Spieler soll als Commander nicht einzelne NPCs direkt mikromanagen, sondern Fireteam-Leader fuehren. Der Task definiert den Vertrag: Commander-Befehl -> Fireteam-Intent -> FTL-Ausfuehrungsplan -> Unit-Aktionen -> Feedback.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_097 - Datenmodelle, engage und Ad-hoc-Vertraege
- TASK_100 - PhaseController und globale Plan-Ausfuehrung
- TASK_105 - Leader-Nachfolge, Lead-Rueckgabe und UI-Synchronisierung
- TASK_120 - Teamqualitaet als FTL-Ausfuehrungsfaktor
- TASK_191 - Command Chain Selection and Area Feedback Pass
- TASK_269 - Tactical Doctrine Source Review Game Abstraction

## Kontext
Der Kern des Spiels soll sein, dass der Commander Absichten und Regeln setzt. Der FTL uebersetzt diese Absicht in Bewegung, Sicherung, Feuerverhalten und kleine Ausbrueche. Dadurch fuehlen sich Teams lebendig an, ohne dass der Spieler jeden Schritt klickt.

## Umfang
1. Command-Ebenen:
   - CommanderIntent: Ziel, Area, Prioritaet, Tempo, Feuerregel, Risiko, Synchronisationswunsch.
   - FireteamExecutionPlan: Movement Style, Security, Cover Priority, Route Bias, Communication State.
   - UnitAction: autoritative Runtime-Commands fuer einzelne NPCs.
2. FTL-Verantwortung:
   - FTL plant innerhalb erlaubter Regeln.
   - FTL darf bei definierten Ausbruechen reagieren.
   - FTL-Skill beeinflusst Planqualitaet, Timing, Kommunikation und Zusammenhalt.
3. Grenzen:
   - Kein UI-Code erzeugt direkte Unit-Wahrheit.
   - SimulationRoot bleibt autoritativ.
   - Multiplayer muss Commander-/FTL-/Unit-Ebene serialisieren koennen.
4. Status:
   - Jeder Fireteam-Befehl bekommt Plan-ID, Phase, erwartete Dauer, Ziel, Ausfuehrungsmodus.
   - FTL meldet `copy`, `cannot`, `adapting`, `complete`, `needs orders`.
5. Datenvertrag:
   - Dokument und kleine Datenklassen/Dictionary-Konventionen.
   - Backward-kompatibel zu Move/Defend/Take/Engage.

## Nicht-Ziele
- Keine neue Pathfinding-Engine.
- Keine vollstaendige autonome KI.
- Kein Entfernen bestehender Commands.
- Kein Multiplayer-Netcode-Umbau jenseits von Vertragsfeldern.

## Akzeptanzkriterien
- [x] CommanderIntent, FireteamExecutionPlan und UnitAction sind getrennt dokumentiert.
- [x] FTL darf nur innerhalb definierter Regeln eigenstaendig reagieren.
- [x] Bestehende Move/Defend/Take/Engage-Ablaeufe koennen auf den Vertrag gemappt werden.
- [x] FTL-Skill ist als Einflussfaktor vorgesehen, aber nicht als UI-Wahrheit.
- [x] Snapshot/Feedback-Felder fuer Plan-ID, Status und FTL-Antworten sind definiert.
- [x] Ein Verifier prueft Beispiel-Commands und keine direkte UI-Unit-Mutation.

## Erwartete Dateien
- `docs/dev/commander_fireteam_delegation_contract.md`
- `scripts/command/commander_intent.gd`
- `scripts/tactical/fireteam_execution_plan.gd`
- `scripts/tests/task_270_commander_to_fireteam_leader_delegation_contract.gd`
- `docs/tasks/TASK_270_commander_to_fireteam_leader_delegation_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_270_commander_to_fireteam_leader_delegation_contract.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_191_command_chain_selection_area_feedback_pass.gd`
- [x] `git diff --check`

## Risiken
- Wenn FTL-Planung zu frei wird, wirkt der Commander machtlos. Wenn sie zu eng ist, wirkt das Team tot.
- Der Vertrag darf nicht zur zweiten SimulationRoot werden.

## Naechster Schritt
Nach TASK_270 kann TASK_271 konkrete Befehlsmodi und Feuerregeln als Commander-Regeln definieren.
