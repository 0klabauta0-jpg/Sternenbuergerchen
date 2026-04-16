# IMPLEMENTATION_STATUS

## Template
### Bereich
- Status:
- Stand:
- Offene Punkte:
- Risiken:
- Naechster Schritt:

## Aktueller Startzustand

### RuntimeLeader / FTL
- Status: implementiert
- Stand: `RuntimeLeader` als eigene `Node`-Komponente mit `class_name`, Signalen fuer Promotion, Demotion, Assignment und Command-Weitergabe sowie der API `promote()`, `demote()`, `assign(entity)` und `command(order)` eingefuehrt.
- Offene Punkte: keine FTL-Ausfuehrungslogik, keine Befehlsinterpretation, keine EventRouter- oder SimulationRoot-Anbindung, keine Szenenverdrahtung.
- Risiken: Signalvertraege und Zustandsbasis stehen, die spaetere Einbindung in autoritative Gameplay-Systeme muss konsistent bleiben.
- Naechster Schritt: RuntimeLeader an EventRouter und SimulationRoot anbinden, sobald die Folgesysteme implementiert sind.

### EventRouter
- Status: implementiert
- Stand: `EventRouter` als eigene `Node`-Komponente mit Signalen fuer Squad-Commands, Unit-Ausfaelle, Threat-Meldungen, Leader-Wechsel und Respawn-Anfragen sowie schlanken Routing-Methoden eingefuehrt.
- Offene Punkte: keine RuntimeLeader-Anbindung, keine Missionslogik, kein Autoload, keine SimulationRoot- oder Registry-Integration.
- Risiken: Die Signalvertraege stehen, die spaetere Einbindung muss ohne harte Direktkopplung zwischen Runtime-Systemen, UI und Autoritaetslogik erfolgen.
- Naechster Schritt: EventRouter an kommende Systeme anbinden, sobald SimulationRoot und weitere Laufzeitkomponenten existieren.

### SimulationRoot
- Status: implementiert
- Stand: `SimulationRoot` als eigene `Node`-Komponente mit Command- und Effects-Queues, deterministischer Tick-Verarbeitung in `_physics_process()`, Guard-Checks, Stub-Apply-Methoden und `tick_processed`-Signal eingefuehrt.
- Offene Punkte: keine Gameplay-Mechanik, keine Missionslogik, keine Registry- oder UpdateManager-Anbindung, keine Zustandsmutation an fremden Nodes.
- Risiken: Die autoritative Verarbeitungsstruktur steht, die spaetere Befehls- und Effektsemantik muss strikt innerhalb von `SimulationRoot` bleiben.
- Naechster Schritt: konkrete Command- und Effect-Typen einfuehren, sobald die Folgesysteme definiert sind.

### Commander Command Model
- Status: implementiert
- Stand: `CommanderCommand` als leichtgewichtiges datenorientiertes Modell unter `res://scripts/command/commander_command.gd` eingefuehrt; formalisiert die aktuell bekannten Commander-Befehlstypen `move`, `take`, `defend` und `flank` sowie `priority`, `unit_id`, `team_id`, optional `target_position` und `phase`.
- Offene Punkte: keine echte Befehlsausfuehrung, keine FTL-Entscheidungslogik, keine UI-Bindings und keine tiefere Command-Semantik ueber den reinen Datenvertrag hinaus.
- Risiken: Der aktuelle Vertrag ist bewusst klein und Dictionary-kompatibel; spaetere Erweiterungen muessen die bestehende `"type"`-Kompatibilitaet zu RuntimeLeader/EventRouter/SimulationRoot erhalten.
- Naechster Schritt: das Modell bei Bedarf in kleine Integrationspfade einspeisen, ohne die bestehenden Runtime-Systeme von Dictionary-Vertraegen abrupt zu entkoppeln.


### FTL Task Model
- Status: implementiert
- Stand: `FTLTask` als leichtgewichtiges datenorientiertes Modell unter `res://scripts/ftl/ftl_task.gd` eingefuehrt; formalisiert die minimalen FTL-Task-Typen `seek_cover`, `move_to_area`, `engage_in_area`, `hold_position` und `retreat` sowie `priority`, `unit_id`, `team_id`, optional `target_position`, `target_area_id`, `source_command_type` und `phase`.
- Offene Punkte: keine echte Task-Ausfuehrung, keine RuntimeLeader-AI, keine Uebersetzungslogik aus Commander-Befehlen und keine UI-Bindings.
- Risiken: Das Modell ist bewusst klein und dictionary-orientiert; spaetere Erweiterungen sollten diese Datenkompatibilitaet erhalten und keine versteckte Ausfuehrungslogik in das Modell ziehen.
- Naechster Schritt: bei Bedarf spaeter einen kleinen, expliziten Uebersetzungspfad von Commander-Commands zu FTL-Tasks ergaenzen, ohne die Modelle eng zu koppeln.
