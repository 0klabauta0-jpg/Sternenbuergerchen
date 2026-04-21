# TASK_098 – TacticalInputController und Fireteam-Auswahl

## Ziel
Die Mission bekommt einen echten `TacticalInputController` fuer Fireteam-Selektion, Multiselect, Leader-Lasso und visuelle Auswahlmarkierung. Einzelne Units bleiben weiterhin nicht direkt steuerbar.

## Status: OFFEN

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_097_taktische_befehlsdatenmodelle_und_vertraege.md](docs/tasks/TASK_097_taktische_befehlsdatenmodelle_und_vertraege.md)
- Pruefe den Git-Status

## Kontext
- Der neue Auswahlzustand liegt ausschliesslich im `TacticalInputController`.
- Leader-Units bleiben die Auswahlanker fuer Box-Selektion.
- Auswahl ist reiner UI- und Planungszustand; keine Gameplay-Wahrheit wird in die Units geschrieben.

## Aufgabe

### 1. Einzel- und Mehrfachauswahl
- Linksklick auf eine Unit waehlt ihr Fireteam.
- `STRG + Linksklick` fuegt weitere Fireteams hinzu.
- Linksklick auf leeres Terrain hebt die Auswahl auf, wenn kein Drag aktiv war.

### 2. Leader-Lasso
- Linksklick-Drag auf leerem Terrain erzeugt ein Rechteck-Lasso.
- Selektiert werden alle Fireteams, deren aktuelle Leader-Unit im Rechteck liegt.

### 3. Visuelles Feedback
- Ausgewaehlte Fireteams werden ueber Outlines oder gleichwertige Markierung hervorgehoben.
- Markierungen gelten fuer alle Members des Fireteams.

### 4. Integrationspfad
- Bestehende Missions-UI und bestehende Button-/Hotkey-Pfade werden an den neuen Auswahlzustand gekoppelt.
- Keine direkte Manipulation von `TestUnit` aus dem Input-Controller.

## Nicht-Ziele
- keine Wegpunkte
- keine Plan-Ausfuehrung
- keine Ad-hoc-Befehle
- keine Suppression

## Akzeptanzkriterien
- Klick, `STRG + Klick`, Lasso und Leeren der Auswahl funktionieren.
- Nur Fireteams, nie Einzel-NPCs, werden als Auswahlzustand gehalten.
- Ausgewaehlte Fireteams sind sichtbar markiert.
- Der Auswahlzustand existiert nur im `TacticalInputController`.
