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

### UpdateManager
- Status: implementiert
- Stand: `UpdateManager` als eigene `Node`-Komponente mit separaten Dirty-Queues fuer AI- und HUD-Updates, begrenzter Batch-Verarbeitung pro Frame und optionalen Hook-Aufrufen fuer `ai_update()` bzw. `refresh_hud()` eingefuehrt.
- Offene Punkte: keine Einbindung in konkrete Laufzeitsysteme, keine erweiterten Scheduler-Regeln, keine Priorisierung zwischen Dirty-Eintraegen.
- Risiken: Der Manager selbst bleibt klein, spaetere aufrufende Systeme muessen Dirty-Markierungen konsistent setzen, damit keine unnoetigen oder fehlenden Folgeupdates entstehen.
- Naechster Schritt: `UpdateManager` bei Bedarf minimal an bestehende Laufzeitsysteme anschliessen, ohne Vollupdates einzufuehren.

### Core Foundation Test Scene
- Status: implementiert
- Stand: `res://scenes/main.tscn` als minimale Startszene mit `SimulationRoot`, `EventRouter`, `UnitRegistry`, `FTLRegistry`, `UpdateManager` und einer einfachen `RuntimeLeader`-Testinstanz angelegt und als Main Scene im Projekt gesetzt.
- Offene Punkte: keine echte Verkabelung zwischen den Systemen, keine Gameplay-Mechanik, keine UI, keine Missionslogik.
- Risiken: Die Szene prueft vor allem Startbarkeit und Script-Existenz; spaetere funktionale Integration der Systeme muss weiterhin bewusst und schrittweise erfolgen.
- Naechster Schritt: gezielte Integrationsschritte zwischen den Kernsystemen einfuehren, sobald deren Vertraege konkret benoetigt werden.
