# IMPLEMENTATION_STATUS

## Template
### Bereich
- Status:
- Stand:
- Offene Punkte:
- Risiken:
- Nächster Schritt:

## Aktueller Startzustand
### RuntimeLeader / FTL
- Status: implementiert
- Stand: `RuntimeLeader` als eigene `Node`-Komponente mit `class_name`, Signalen fuer Promotion, Demotion, Assignment und Command-Weitergabe sowie der API `promote()`, `demote()`, `assign(entity)` und `command(order)` eingefuehrt.
- Offene Punkte: keine FTL-Ausfuehrungslogik, keine Befehlsinterpretation, keine EventRouter- oder SimulationRoot-Anbindung, keine Szenenverdrahtung.
- Risiken: Signalvertraege und Zustandsbasis stehen, die spaetere Einbindung in autoritative Gameplay-Systeme muss konsistent bleiben.
- Nächster Schritt: RuntimeLeader an EventRouter und SimulationRoot anbinden, sobald die Folgesysteme implementiert sind.

### EventRouter
- Status: offen
- Stand: noch nicht implementiert
- Offene Punkte: Signale definieren
- Risiken: Systemkopplung
- Nächster Schritt: TASK_002_event_router.md

### SimulationRoot
- Status: offen
- Stand: noch nicht implementiert
- Offene Punkte: Command Queue, Commit-Reihenfolge
- Risiken: deterministische Grundlage fehlt
- Nächster Schritt: TASK_003_simulation_root.md
