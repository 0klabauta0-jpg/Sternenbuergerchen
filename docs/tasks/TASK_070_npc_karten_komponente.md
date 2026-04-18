# TASK_070 – NPC-Karten-Komponente

## Ziel
Ein wiederverwendbarer, menuegetriebener NPC-Kartenbaustein fuer den Meta-Layer soll eingefuehrt werden, damit Heimatbasis und FOB dieselben Unit-Informationen konsistent darstellen koennen, ohne eigene Spezial-UI pro Screen aufzubauen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_033 (minimaler Meta-Layer) muss vorhanden sein.
- TASK_046 (Unit-Skill-Werte) muss vorhanden sein.
- TASK_048 (Persoenlichkeitsmerkmale) muss vorhanden sein.
- TASK_049 (Homebase-Unit-Uebersicht mit Skills und Traits) muss vorhanden sein.
- TASK_070 ist die Grundlage fuer TASK_071 und TASK_072.

## Ist-Zustand (nach TASK_049)
- Die Heimatbasis zeigt Units als reine Checkbox-Textzeilen.
- Die Detailtexte werden indirekt ueber unsichtbare `TestUnit`-Preview-Nodes erzeugt.
- Die FOB zeigt das Team als reine ID- bzw. Textliste.
- Es gibt keinen gemeinsamen UI-Baustein fuer Unit-Karten im Meta-Layer.

## Aufgabe

### 1. Kleine read-only Meta-Profilaufbereitung
- Fuehre einen kleinen expliziten Datenpfad fuer Meta-UI ein, der vorhandene Unit-Identitaetsdaten in einer read-only Darstellung zusammenfasst.
- Die Daten sollen mindestens enthalten:
  - `unit_id`
  - `display_name`
  - Skill-Kurzwerte oder direkt nutzbare Skill-Daten
  - Trait-Tags oder direkt nutzbare Trait-Daten
  - optional `fireteam_id`
  - optional einen einfachen Status- oder Sekundaertext fuer spaetere FOB-Nutzung
- Kein neues globales Registry-System einfuehren.
- Kein Gameplay-State in UI-Strukturen verschieben.

### 2. Wiederverwendbare NPC-Karte als eigene UI-Komponente
- Lege eine eigene `Control`-Szene plus Script fuer eine einzelne NPC-Karte an.
- Die Karte soll mindestens darstellen:
  - Anzeigename
  - kompakte Skill-Zusammenfassung
  - Trait-Tags
  - optional eine kleine zweite Zeile oder Badge fuer Statushinweise
- Die Komponente soll einfache visuelle Zustaende unterstuetzen:
  - neutral
  - selectable
  - selected
  - disabled
- Die Karte darf Signale fuer Klick oder Auswahl emittieren, aber keine `MetaLayerFlow`-Logik enthalten.

### 3. Reuse fuer mehrere Meta-Screens vorbereiten
- Die Komponente muss so aufgebaut sein, dass Heimatbasis und FOB sie spaeter ohne Fork oder zweite Karten-Implementierung wiederverwenden koennen.
- Eine leichte Konfiguration per Setup-Methode oder Flags ist erlaubt, z. B. fuer:
  - Auswahlrahmen an/aus
  - Statuszeile an/aus
  - deaktivierter Start-/Rueckflusszustand

## Architekturhinweise
- UI bleibt Anzeige, nicht Gameplay-Wahrheit.
- Keine neue Simulationslogik im Meta-Layer einfuehren.
- Keine versteckten Hotpath-Suchen oder SceneTree-Vollscans fuer Kartenaufbau.
- Wenn eine kleine Datenaufbereitung noetig ist, soll sie explizit und screen-lokal oder komponentennah bleiben.

## Nicht-Ziele
- keine Portrait-Pipeline
- keine Charakterbogen-Vollansicht
- keine Loadout-, Rollen- oder Dropship-Logik
- keine Persistenz
- keine Drag-and-Drop-Teamverwaltung

## Akzeptanzkriterien
- Eine eigenstaendige NPC-Karten-Komponente existiert als eigene Szene/Script-Kombination.
- Die Karte kann vorhandene Unit-Daten aus dem Meta-Layer sauber darstellen.
- Die Karte kann optional einen kleinen Statushinweis anzeigen, ohne an `SimulationRoot` gekoppelt zu sein.
- Die Karte ist so vorbereitet, dass TASK_071 und TASK_072 sie direkt wiederverwenden koennen.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add reusable NPC card component task spec (TASK_070)"`
- `git push`
- `docs/TASK_ROADMAP.md` aktualisieren, falls die Reihenfolge angepasst wurde
- ´docs\IMPLEMENTATION_STATUS.md´ aktualisieren