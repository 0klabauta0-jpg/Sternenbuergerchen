# TASK_078 – Meta-Layer: Navigation und Map-Ansicht

## Ziel
Zwischen Homebase, FOB und einer neuen read-only Map-Ansicht soll direkt im Meta-Layer umgeschaltet werden koennen, ohne den bestehenden Homebase -> FOB -> Mission -> Debrief-Flow aufzubrechen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_074_homebase_layout_neuordnung.md`
- Lies `docs/tasks/TASK_076_meta_ui_kenney_grau.md`
- Lies `docs/tasks/TASK_077_fob_fireteam_auswahl.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_077 muss implementiert sein.
- Mission und Debrief duerfen durch die neue Navigation nicht regressieren.

## Ist-Zustand (nach TASK_077)
- MetaLayer kennt Homebase, FOB, Mission und Debrief.
- Es gibt keine dauerhafte Umschaltleiste zwischen Meta-Ansichten.
- Eine eigenstaendige Map-Ansicht existiert noch nicht.

## Aufgabe

### 1. Meta-Navigation einfuehren
- Fuehre eine kleine Umschaltleiste mit Buttons fuer `Homebase`, `FOB` und `Map` ein.
- Die Navigation bleibt auf Meta-Screens beschraenkt und soll nicht die laufende Missionsszene ueberblenden.

### 2. Map-Ansicht als read-only Meta-Screen hinzufuegen
- Fuehre einen kleinen Meta-Screen fuer die Map ein.
- Die Map-Ansicht soll mindestens aktuelle Missions-/Map-Informationen und den aktuellen Meta-Vorbereitungsstand lesbar zusammenfassen.
- Keine neue frei navigierbare Karten- oder Editor-Logik einfuehren.

### 3. Bestehenden Flow kontrolliert anbinden
- Wechsel zwischen Homebase, FOB und Map darf den bestehenden Auswahl- und FOB-Staging-Zustand nicht versehentlich verlieren.
- Missionstart und Debrief bleiben weiterhin ueber den bestehenden Flow getrieben.

## Architekturhinweise
- UI bleibt read-only bzw. staging-first.
- Keine neue Persistenz oder globale Meta-State-Architektur erfinden.
- Die Navigation soll bestehende Screen-Instanzen wiederverwenden statt Screens staendig neu zu instanziieren.

## Nicht-Ziele
- kein frei scrollbarer Taktik- oder Editor-Map-Screen
- keine neue Missionsplanung mit Gameplay-Commit
- keine neue globale Router- oder Autoload-Struktur

## Akzeptanzkriterien
- Zwischen Homebase, FOB und Map kann per Button umgeschaltet werden.
- Der Wechsel behaelt den laufenden Meta-Vorbereitungsstand.
- Die neue Map-Ansicht zeigt den aktuellen Missions-/Meta-Kontext lesbar an.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add meta navigation and map overview screen (TASK_078)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren