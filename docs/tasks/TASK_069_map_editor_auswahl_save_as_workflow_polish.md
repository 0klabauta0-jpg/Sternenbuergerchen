# TASK_069 – Map-Editor: Auswahl, Save As und Workflow-Polish

- Phase: 14 – Map-Editor-Workflow und Politur
- Status: implementiert
- Abhaengigkeiten: TASK_068c (Gitternetz-Overlay und Himmelsrichtungen)

## Ziel
Der Map-Editor soll fuer den taeglichen Workflow handlicher werden: Auswahlmodus, `Save As`, freiere New-Workflows und kleine Bedienpolitur statt reiner Brush-Einbahnstrasse.

## Anforderungen
1. Der Editor merkt sich die zuletzt gewaehlten Surface- und Kanten-Typen auch ohne aktive Tile-Selektion.
2. `Escape` hebt die aktuelle Palette-Auswahl auf.
3. Neben `Brush` soll ein expliziter `Select`-Modus mit Ctrl+LMB-Multiselection existieren.
4. `Ctrl+Save` soll `Save As` oeffnen koennen.
5. `New` soll den Groessen-Dialog fuer neue Karten nutzen statt einer starren Testgroesse.
6. Mehrdeutige Palettennamen wie Wand-Ecken sollen im UI eindeutig benannt sein.

## Akzeptanzkriterien
- Brush- und Select-Modus sind klar trennbar.
- Mehrfachauswahl per Ctrl+LMB funktioniert.
- `Save As` ist ueber Shortcut bzw. Workflow erreichbar.
- Neue Karten starten ueber den Groessen-Dialog.

## Nicht in diesem Task
- Drag-Selection-Rechteck
- vollstaendiges Multi-Tile-Undo ueber den gesamten Brush-Radius
- Massenoperationen auf beliebige Mehrfachauswahl jenseits des vorhandenen Workflows
