# TASK 049 – Heimatbasis: Unit-Uebersicht mit Skills und Traits

## Ziel
Die Homebase-UI zeigt jetzt Skills und Traits der verfuegbaren Units an, damit der Spieler informierte Entscheidungen bei der Teamzusammenstellung treffen kann.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_046 (Unit-Skill-Werte) muss vorher implementiert sein.
- TASK_048 (Persoenlichkeitsmerkmale) muss vorher implementiert sein.

## Ist-Zustand (nach TASK_048)
- `HomebaseTestScreen` zeigt eine Checkbox-Liste mit Unit-IDs und einfacher Toggle-Selektion.
- Units haben Skills und Traits, aber die Homebase zeigt diese Informationen nicht.
- Der Spieler hat keine Grundlage fuer informierte Teamzusammenstellung.

## Aufgabe

### 1. Unit-Detailanzeige in der Homebase
- Neben jeder Unit-Checkbox in der Homebase wird eine kompakte Detailzeile angezeigt:
  - Skills als Kurzwerte: `A:0.6 S:0.4 L:0.2 T:0.5`
  - Traits als Tags: `[AGG] [CALM]`
- Format pro Zeile: `☐ unit_alpha | A:0.6 S:0.4 L:0.2 T:0.5 | [AGG] [CALM]`

### 2. Unit-Daten aus Registry lesen
- `HomebaseTestScreen` liest die Skill- und Trait-Daten aus den `TestUnit`-Instanzen, die im Szenenbaum oder ueber eine Referenzliste verfuegbar sind.
- Keine neue Registry noetig – die Units sind als Szenen-Children direkt referenzierbar.

### 3. Farbcodierung (optional, wenn einfach)
- Skills ueber 0.6: gruen
- Skills unter 0.3: rot
- Sonst: weiss/default

## Nicht-Ziele
- keine Drag-and-Drop-Teamzusammenstellung
- keine Sortierung oder Filterung
- keine Vergleichsansicht
- keine Skill-Veraenderungs-UI
- keine tiefe Unit-Detailseite

## Akzeptanzkriterien
- In der Homebase sind Skills und Traits jeder Unit sichtbar
- Der Spieler kann anhand der angezeigten Werte eine informierte Auswahl treffen
- Die bestehende Checkbox-Selektion und Team-Bestaetigung funktioniert weiterhin
- Keine Regression im Meta-Layer-Flow (Homebase -> FOB -> Mission)

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Show unit skills and traits in homebase UI (TASK_049)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
