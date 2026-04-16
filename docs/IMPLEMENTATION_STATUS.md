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

### TASK_016 – erster FTLTask-Durchlauf im RuntimeLeader
- Status: implementiert
- Stand: ein leichtgewichtiges `FTLTask`-Modell unter `res://scripts/ftl/ftl_task.gd` wurde als notwendige Basis ergaenzt; `RuntimeLeader` kann jetzt einen einzelnen gueltigen FTLTask ueber `assign_ftl_task(...)` annehmen und ihn ueber `process_current_ftl_task()` minimal als verarbeitet bestaetigen.
- Offene Punkte: keine FTLTask-Queue, kein Runtime-State-Modell, keine Status-Uebergaenge und keine Ausfuehrungslogik.
- Risiken: Der erste Durchlauf ist bewusst nur ein einzelner Single-Task-Pfad; spaetere Queue- und Statuslogik muss darauf aufsetzen, ohne Signalvertraege oder Datenvertrag zu brechen.
- Naechster Schritt: eine kleine FTLTask-Queue im `RuntimeLeader` einfuehren.

### TASK_017 – FTLTask-Queue im RuntimeLeader
- Status: implementiert
- Stand: `RuntimeLeader` verwaltet jetzt eine kleine FIFO-`FTLTask`-Queue; gueltige Tasks koennen ueber `enqueue_ftl_task(...)` eingereiht und ueber `process_next_queued_ftl_task()` in den bestehenden Single-Task-Pfad uebernommen und verarbeitet werden.
- Offene Punkte: kein Runtime-State-Modell, keine Runtime-Status-Uebergaenge und keine Ausfuehrungslogik.
- Risiken: Die Queue ist bewusst schlicht und arbeitet in stabiler Einfuegereihenfolge; spaetere Priorisierung oder Parallelitaet muss separat und explizit eingefuehrt werden.
- Naechster Schritt: ein minimales FTL-State-Modell fuer den Laufzeitstatus ergaenzen.

### TASK_018 – minimales FTL-State-Modell
- Status: implementiert
- Stand: `FTLRuntimeStatus` unter `res://scripts/ftl/ftl_runtime_status.gd` formalisiert jetzt einen kleinen Laufzeitstatus fuer FTLs mit den erlaubten Werten `idle`, `seeking_cover`, `moving_to_area`, `engaging_in_area`, `holding_position` und `retreating` sowie einem einfachen Dictionary-Roundtrip.
- Offene Punkte: noch keine RuntimeLeader-Anbindung, keine Status-Uebergaenge aus FTLTasks und keine Ausfuehrungslogik.
- Risiken: Das Modell ist bewusst klein und statuszentriert; spaetere Erweiterungen sollten keine versteckte Gameplay-Logik in den Datentraeger ziehen.
- Naechster Schritt: einen minimalen Uebergang von `FTLTask` zu `FTLRuntimeStatus` im `RuntimeLeader` abbilden.
