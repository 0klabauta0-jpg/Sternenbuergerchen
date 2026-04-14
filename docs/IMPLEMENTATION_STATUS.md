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
- Status: offen
- Stand: noch nicht implementiert
- Offene Punkte: Signale definieren
- Risiken: Systemkopplung
- Naechster Schritt: TASK_002_event_router.md

### Registries
- Status: implementiert
- Stand: `UnitRegistry` und `FTLRegistry` als zentrale Lookup- und Verwaltungsstellen fuer Units bzw. FTLs mit Guard-Checks, stabilen ID-Team-ID-Lookups und Ausgabe aller registrierten Eintraege eingefuehrt.
- Offene Punkte: kein `TileRegistry`, keine Autoload-Einbindung, keine Umstellung weiterer Systeme auf Registry-Nutzung.
- Risiken: Die Registry-Vertraege stehen, spaetere Laufzeitsysteme muessen Registrierungen konsistent pflegen, damit keine veralteten Referenzen liegen bleiben.
- Naechster Schritt: Registries minimal in kommende Laufzeitsysteme integrieren, sobald deren Verkabelung benoetigt wird.

### SimulationRoot
- Status: implementiert
- Stand: `SimulationRoot` als eigene `Node`-Komponente mit Command- und Effects-Queues, deterministischer Tick-Verarbeitung in `_physics_process()`, Guard-Checks, Stub-Apply-Methoden und `tick_processed`-Signal eingefuehrt.
- Offene Punkte: keine Gameplay-Mechanik, keine Missionslogik, keine Registry- oder UpdateManager-Anbindung, keine Zustandsmutation an fremden Nodes.
- Risiken: Die autoritative Verarbeitungsstruktur steht, die spaetere Befehls- und Effektsemantik muss strikt innerhalb von `SimulationRoot` bleiben.
- Naechster Schritt: konkrete Command- und Effect-Typen einfuehren, sobald die Folgesysteme definiert sind.
