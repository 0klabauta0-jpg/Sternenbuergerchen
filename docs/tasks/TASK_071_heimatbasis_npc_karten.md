# TASK_071 – Heimatbasis: NPC-Karten und Auswahlfokus

## Ziel
Die Heimatbasis soll von der bisherigen Textlisten-Darstellung auf echte NPC-Karten umgestellt werden, damit Teamzusammenstellung sichtbar, lesbar und nachvollziehbar wird.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_070_npc_karten_komponente.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_070 (NPC-Karten-Komponente) muss vorher implementiert sein.
- TASK_033 (Heimatbasis / FOB Minimal-Flow) muss vorhanden sein.
- TASK_049 (Unit-Uebersicht mit Skills und Traits) ist funktionale Vorstufe und soll nicht regressieren.

## Ist-Zustand (nach TASK_070)
- Die Heimatbasis besitzt bereits eine minimale Teamzusammenstellung.
- Die verfuegbaren Units, Skills und Traits sind datenmaessig vorhanden.
- Die bisherige UI ist aber weiterhin listen- und textzeilenorientiert.
- Die Teambestaetigung ueber `MetaLayerFlow` funktioniert bereits und darf nicht gebrochen werden.

## Aufgabe

### 1. Roster-Liste auf NPC-Karten umstellen
- Ersetze die bisherige Checkbox-Zeilenliste in der Heimatbasis durch eine Liste oder ein Grid aus NPC-Karten.
- Jede verfuegbare Unit wird als eigene Karte dargestellt.
- Die Auswahl muss weiterhin klar sichtbar und per Klick/Tap/Toggle moeglich bleiben.
- Die bestehende Teambestaetigung darf semantisch unveraendert bleiben: Die Heimatbasis liefert weiter nur die ausgewaehlten `unit_id`s an den Flow.

### 2. Auswahlfokus in der Heimatbasis ergaenzen
- Ergaenze neben oder ueber der Kartenliste einen kleinen Fokusbereich fuer die aktuell markierte oder zuletzt angewaehlte Unit.
- Der Fokusbereich soll die vorhandenen Daten lesbarer zeigen als die kompakte Kartenansicht, z. B.:
  - Name
  - Skill-Zusammenfassung
  - Trait-Tags
  - optional Team-/Fireteam-Hinweis, falls schon verfuegbar
- Dieser Fokusbereich bleibt rein lesend und menuegetrieben.

### 3. Teamzusammenstellung sichtbar halten
- Die Heimatbasis soll jederzeit klar zeigen, welche Units aktuell im ausgewaehlten Team sind.
- Ein kleiner Zusammenfassungsbereich ist erlaubt, z. B.:
  - `Selected team: 2 Units`
  - Liste der ausgewaehlten Namen
  - bestaetigender CTA zum Weitergehen zur FOB
- Keine neue Meta-Simulation oder Barracks-Logik einfuehren.

### 4. Bestehenden Datenhack abbauen, wenn moeglich
- Falls TASK_070 einen expliziteren Meta-Datenpfad bereitstellt, soll die Heimatbasis diesen nutzen statt unsichtbare Preview-Nodes nur fuer die Anzeige aufzubauen.
- Keine neue globale Datenhaltung als Ersatz erfinden.

## Architekturhinweise
- Heimatbasis bleibt menuegetrieben und nicht simulierend.
- Keine Gameplay-Wahrheit in UI-Callbacks verstecken.
- `MetaLayerFlow` bleibt der uebergeordnete Ablaufpfad; die Screen-UI soll ihn nur bedienen.
- Keine neuen Autoloads oder schwergewichtigen UI-Frameworks einfuehren.

## Nicht-Ziele
- keine Sortierung oder Filterung
- keine Drag-and-Drop-Teambildung
- keine Skill- oder Trait-Bearbeitung
- keine tiefe Charakterbogen-Seite
- keine Persistenz oder Barracks-Simulation

## Akzeptanzkriterien
- Die Heimatbasis zeigt verfuegbare Units als NPC-Karten statt als reine Textliste.
- Die Auswahl ueber die Karten funktioniert stabil und bleibt fuer `MetaLayerFlow` kompatibel.
- Ein kleiner Fokus- oder Detailbereich verbessert die Lesbarkeit der aktuell betrachteten Unit.
- Der bestehende Flow Heimatbasis -> FOB funktioniert weiterhin ohne Regression.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Define homebase NPC card integration task (TASK_071)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren