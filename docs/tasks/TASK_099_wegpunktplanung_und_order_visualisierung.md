# TASK_099 – Wegpunktplanung, Kontextmenue und Order-Visualisierung

## Ziel
Ausgewaehlte Fireteams koennen pro Phase beliebig viele Wegpunkte mit Befehlstypen planen, spaeter editieren und als zusammenhaengende Linien mit Symbolen auf der Karte sehen, ohne die Befehle sofort auszufuehren.

## Status: OFFEN

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_097_taktische_befehlsdatenmodelle_und_vertraege.md](docs/tasks/TASK_097_taktische_befehlsdatenmodelle_und_vertraege.md)
- Lies [docs/tasks/TASK_098_taktische_fireteam_auswahl_und_mehrfachselektion.md](docs/tasks/TASK_098_taktische_fireteam_auswahl_und_mehrfachselektion.md)
- Pruefe den Git-Status

## Aufgabe

### 1. Wegpunkt-Eingabe
- Rechtsklick auf beliebige Position setzt fuer alle aktuell ausgewaehlten Fireteams einen Wegpunkt in der aktiven Phase.
- Mehrere Rechtsklicks bauen eine geordnete Kette auf.
- Wegpunkte duerfen unabhaengig vom Terrain gesetzt werden; der echte Laufweg wird spaeter vom Pathfinder bestimmt.

### 2. Kontextsensitives Kurzmenue
- Direkt nach dem Setzen erscheint ein Kurzmenue zur Wahl von:
  - `move`
  - `defend`
  - `engage`
  - `flank`
  - `take`
- Default bleibt `move`.

### 3. Speicherung als Plan
- Jeder Fireteam-/Phasen-Slot wird als `FireteamOrderPlan` gehalten.
- Beim Planen werden keine Commands sofort an die Simulation gegeben.
- Es gibt kein Limit fuer Wegpunkte pro Phase.

### 4. Nachtraegliches Editieren
- Wegpunkte koennen per Drag verschoben werden.
- Einzelne Wegpunkte koennen gezielt geloescht werden.
- Reihenfolge und Visualisierung aktualisieren sich automatisch.

### 5. `FireteamOrderVisualizer`
- Geplante Orders werden als durchgezogene Linie mit Wegpunktsymbolen dargestellt.
- Die Darstellung bleibt lesend und nimmt keine Gameplay-Mutationen vor.

## Nicht-Ziele
- keine Phasen-Ausfuehrung
- keine Ad-hoc-Befehle
- keine Suppression
- keine Gegner-Patrouillen

## Akzeptanzkriterien
- Wegpunkte lassen sich pro Fireteam und Phase unbegrenzt anlegen.
- `engage` ist im Kurzmenue enthalten.
- Wegpunkte sind verschiebbar und loeschbar.
- Geplante Orders werden sichtbar als Linie mit Symbolen dargestellt.
- Beim Planen werden keine Befehle sofort ausgefuehrt.
