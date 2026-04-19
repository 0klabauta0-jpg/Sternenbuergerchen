# TASK_076 – Meta-Layer: Graue Kenney-UI-Rahmen

## Ziel
Homebase und anschliessend FOB sollen visuell auf eine einheitliche graue Meta-UI mit vorhandenen Kenney-Assets umgestellt werden, damit die Fenster nicht mehr wie rohe Default-Controls wirken.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_074_homebase_layout_neuordnung.md`
- Lies `docs/tasks/TASK_075_homebase_tooltips_charakterbogen_polish.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_075 muss implementiert sein.
- Die vorhandenen Assets unter `res://Assets/kenney_ui-pack/PNG/Grey/` und `res://Assets/kenney_ui-pack-space-expansion/PNG/Grey/` sollen genutzt werden.

## Ist-Zustand (nach TASK_075)
- Die Homebase-Struktur und Textdichte sind bereits verbessert.
- Die Fenster und Controls wirken aber noch weitgehend wie rohe Godot-Standard-Container.

## Aufgabe

### 1. Graue Fensterrahmen aufbauen
- Nutze vorhandene graue Kenney-UI-Assets fuer Fenster, Panels oder Box-Hintergruende.
- Mindestens Homebase soll damit klar gerahmte Fenster erhalten:
  - Missionsinfo
  - Roster
  - Transfer
  - Charakterbogen
- Wenn sinnvoll, den Pfad so vorbereiten, dass FOB dieselbe Stilbasis direkt wiederverwenden kann.

### 2. CTA- und Interaktionsstil angleichen
- Nutze passende graue Kenney-Elemente fuer Buttons oder button-aehnliche Container.
- `Send to FOB` soll klar als primarer Button lesbar bleiben, auch wenn die erste Theme-Stufe komplett grau bleibt.

### 3. Keine UI-Fork-Architektur bauen
- Falls ein kleiner gemeinsamer Styling-Helfer oder Theme-Pfad noetig ist, soll er Homebase und FOB gemeinsam bedienen.
- Keine zweite visuelle Implementierung pro Screen einfuehren.

### 4. Erste graue Meta-UI bewusst neutral halten
- Die erste Fassung bleibt komplett grau.
- Keine farblichen Team- oder Alarmzustaende vorziehen, ausser wenn minimale Lesbarkeit es unbedingt verlangt.

## Architekturhinweise
- Reine Darstellungsaufgabe, keine neue Gameplay- oder Datenlogik.
- Bestehende Meta-Screens sollen vorhandene Komponenten weiterverwenden statt visuell komplett neu erfunden zu werden.
- Keine aufwendige Skinning-Engine oder globale Theme-Revolution einfuehren.

## Nicht-Ziele
- keine bunte Teamfarb-Logik
- keine neue Audio-/Animationsebene
- keine neue Asset-Pipeline
- keine vollstaendige UI-Politur des gesamten Spiels

## Akzeptanzkriterien
- Homebase nutzt sichtbare graue Kenney-Fenster-/Panel-Elemente statt nur Default-Container.
- Die neue Fensteroptik basiert auf den vorhandenen Assets aus den beiden Kenney-UI-Packs.
- Der Stil ist so aufgebaut, dass FOB dieselbe Optik ohne UI-Fork wiederverwenden kann.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Apply grey Kenney meta UI styling (TASK_076)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren