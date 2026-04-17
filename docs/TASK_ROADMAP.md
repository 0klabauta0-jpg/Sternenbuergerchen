# TASK_ROADMAP

## Zweck
Diese Roadmap definiert die Reihenfolge der Tasks fuer das Projekt.

Ziel:
- kontrollierter Aufbau der Architektur
- klare Trennung von Daten, Simulation und Darstellung
- schrittweiser Uebergang von Struktur -> Integration -> sichtbares Verhalten

Diese Datei ist verbindlich fuer Codex.
Tasks duerfen nicht in anderer Reihenfolge umgesetzt werden, ausser es ist explizit angegeben.

---

# Arbeitsregeln

## Reihenfolge
- Tasks muessen strikt in der angegebenen Reihenfolge umgesetzt werden
- keine Tasks ueberspringen
- keine Tasks zusammenziehen, ausser im Batch-Mode erlaubt

## Branch-Regel
Vor jedem Task:

```bash
git checkout integration/core-foundation
git checkout -b task/<task-name>

Bei Batch-Arbeit:

git checkout integration/core-foundation
git checkout -b batch/<batch-name>
Phase 0 – Fundament (abgeschlossen)
TASK_006 Workflow Setup
TASK_001 RuntimeLeader
TASK_002 EventRouter
TASK_003 SimulationRoot
TASK_004 Registries
TASK_005 UpdateManager
Phase 1 – Integration (abgeschlossen)
TASK_007 RuntimeLeader Integration Test
TASK_008 Unit Stub + Registry Test
TASK_009 Minimaler Command-Flow
TASK_010 Tick-Verarbeitung in SimulationRoot
TASK_011 Unit-Target Command
TASK_012 Team-/FTL-Command
Phase 2 – Datenmodelle (abgeschlossen)
TASK_013 CommanderCommand
TASK_014 FTLTask
TASK_015 Command -> FTLTask Translator
Phase 3 – FTL-Datenfluss vervollstaendigen
TASK_016 – FTLTask im RuntimeLeader annehmen

Ziel:

RuntimeLeader kann FTLTask empfangen
minimaler Nachweis
keine Ausfuehrung
TASK_017 – FTLTask-Queue im RuntimeLeader

Ziel:

RuntimeLeader verwaltet Tasks
aktueller Task + Queue
keine KI
TASK_018 – FTL-State-Modell minimal

Ziel:

States definieren:
idle
moving
holding
engaging
retreating
keine echte Wirkung
TASK_019 – FTLTask -> RuntimeStatus

Ziel:

Task fuehrt zu einfachem Statuswechsel
keine Bewegung
Phase 4 – Unit-Ebene anbinden
TASK_020 – UnitCommand-Stub

Ziel:

einfache Unit-Kommandos als Daten
TASK_021 – TestUnit Runtime-Status

Ziel:

Unit hat Zustandsmodell:
idle
assigned
pending_move
holding
TASK_022 – FTLTask -> Unit-Zuweisung

Ziel:

FTL referenziert Units korrekt
keine Aktion
TASK_023 – mehrere Units pro FTL

Ziel:

2–3 Units pro Team
nur Datenfluss
Phase 5 – erste sichtbare Reaktion
TASK_024 – Missions-Testszene

Ziel:

einfache Szene mit:
FTL
Units
Ziel
TASK_025 – Move-Target als Daten

Ziel:

Zielposition speichern
keine Navigation
TASK_026 – minimaler Move im SimulationRoot

Ziel:

einfache Positionsaenderung erlaubt
kein Pathfinding
TASK_027 – erster sichtbarer Flow

Ziel:
Commander -> FTL -> SimulationRoot -> Unit

Phase 6 – taktische Grundsysteme
TASK_028 – Line of Sight minimal
TASK_029 – Fog of War minimal
TASK_030 – Treffer-/Damage-Modell minimal
TASK_031 – Down-/Bleedout-Zustaende
TASK_032 – Friendly Fire
Phase 7 – Meta-Layer
TASK_033 – Heimatbasis
TASK_034 – FOB
TASK_035 – Teamtransfer
TASK_036 – Respawn-Logik
TASK_037 – Rover/Frachter minimal
Phase 8 – Vertical Slice
TASK_038 – Fireteam-Aufteilung
TASK_039 – Phasen-Wirkung
TASK_040 – Take-Befehl und Objective
TASK_041 – Siegbedingung
TASK_042 – Respawn-Timer-Anzeige
Phase 9 – Erweiterung (spaeter)
Skillsystem
soziale Dynamik
persistente Teams
Multiplayer
Map Editor
Fahrzeuge
komplexe Taktik
Batch-Empfehlung

Codex soll Tasks in kleinen Gruppen bearbeiten:

Batch 1
TASK_016–019
Batch 2
TASK_020–023
Batch 3
TASK_024–027

Nach jedem Batch:

Godot starten
Fehler pruefen
ggf. Integrationsbranch aktualisieren
Definition of Done

Ein Task ist fertig, wenn:

Code kompiliert / Godot startet
Scope eingehalten wurde
keine unerlaubten Nebenumbauten
IMPLEMENTATION_STATUS.md aktualisiert
Commit + Push erfolgt
Wichtig

Diese Roadmap ist verbindlich.

Wenn ein Task:

groesser wird als erwartet
neue Architektur erfordert
bestehenden Code massiv veraendert

Dann:

stoppen
Problem melden
nicht improvisieren