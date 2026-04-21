# TASK_100 – PhaseController und globale Plan-Ausfuehrung

## Ziel
Ein globaler `PhaseController` ersetzt den alten losen Go-Pfad: Phasen werden zentral verwaltet, pro Fireteam und Phase liegen eigene Plaene vor, und `Next Phase` startet alle Plaene der neuen Phase gleichzeitig.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_039_phasen_wirkung.md](docs/tasks/TASK_039_phasen_wirkung.md)
- Lies [docs/tasks/TASK_099_wegpunktplanung_und_order_visualisierung.md](docs/tasks/TASK_099_wegpunktplanung_und_order_visualisierung.md)
- Pruefe den Git-Status

## Aufgabe

### 1. `PhaseController`
- Phase 0 bleibt Anflug/Pre-Mission und ist nicht interaktiv.
- Immer mindestens Phase 1 aktiv.
- `+ Phase` legt neue globale Phasen an.
- Die aktuell im UI gewaehlte Phase bestimmt nur den Bearbeitungskontext.

### 2. `PhaseControlPanel`
- Zeigt aktive Phase, vorhandene Phasen und `+ Phase`.
- Bietet `Next Phase` als einzigen globalen Startpfad.
- Ein separater `Go`-Button entfaellt vollstaendig.

### 3. Globale Ausfuehrung
- `Next Phase` startet gleichzeitig die Befehlsketten aller Fireteams fuer die neue Phase.
- Wegpunkte werden pro Fireteam sequentiell abgearbeitet.
- Ein Wegpunkt gilt als `completed`, wenn Zielradius und optionale Haltezeit erfuellt sind.

### 4. Bestehenden Runtime-Pfad wiederverwenden
- Die Aktivierung eines Wegpunkts erzeugt ueber den vorhandenen Commander-/FTL-/Unit-Pfad die noetigen Laufzeitbefehle.
- Keine Umgehung von `SimulationRoot.enqueue_command()`.

## Nicht-Ziele
- keine Ad-hoc-Befehle
- keine Suppression
- keine Gegner-Phasen
- keine neue direkte Unit-Steuerung

## Akzeptanzkriterien
- Globale Phasen lassen sich anlegen, auswaehlen und weiterschalten.
- `Next Phase` startet alle Plaene der neuen Phase zugleich.
- Wegpunkte werden pro Fireteam nacheinander abgearbeitet.
- Der alte Go-Sonderpfad ist entfernt oder stillgelegt.
