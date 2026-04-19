# TASK_075 – Homebase: Kartenverdichtung, Tooltip-Polish und Charakterbogen-Fokus

## Ziel
Die Homebase soll textlich und visuell verdichtet werden: kleinere Portrait-Karten nur im linken Roster, unveraendert lesbare Karten im Transferfenster, deutsche Hilfetexte als Popup-Tooltips statt dauerhafter Erklaerzeilen und ein fokussierterer Charakterbogen mit ausgeschriebenen Skills.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_073_homebase_charakterbogen_dragdrop.md`
- Lies `docs/tasks/TASK_074_homebase_layout_neuordnung.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_074 muss implementiert sein.
- Der bestehende Transferpfad darf nicht regressieren.

## Ist-Zustand (nach TASK_074)
- Die Fensterreihenfolge und Missionsinfoleiste sind bereits angepasst.
- Die Portrait-Karten sind funktional, aber noch nicht fein zwischen Roster- und Transferdarstellung getrennt.
- Erklaertexte stehen teilweise noch direkt im Screen statt als kontextuelle Hilfe.

## Aufgabe

### 1. Portrait-Karten im Roster verdichten
- Verkleinere die Portrait-Karten im linken Roster auf etwa die Haelfte der bisherigen Hoehe bzw. visuellen Praesenz.
- Die Karten im Transferfenster sollen ihre bisherige bzw. groessere Lesegroesse behalten.
- Es darf keine zweite Datenlogik fuer dieselbe Karte eingefuehrt werden; leichte Varianten oder Konfigurationsflags sind erlaubt.

### 2. Bildschirmtexte reduzieren
- Entferne dauerhafte Erklaertexte innerhalb der Fensterkoerper.
- Auf den Fenstern sollen im Normalzustand nur die Ueberschriften sichtbar sein.
- Kontext-Hilfe soll ueber deutsche Popup-Tooltips erfolgen, z. B. fuer:
  - Missionsinfo-Fenster
  - Rosterfenster
  - Transferfenster
  - Charakterbogen
  - `Send to FOB`

### 3. Charakterbogen inhaltlich fokussieren
- Entferne im Charakterbogen die Felder:
  - Callsign
  - Age / Alter
  - Origin / Herkunft
- Stelle die Skills ausgeschrieben und untereinander dar, z. B.:
  - Accuracy
  - Speed
  - Leadership
  - Toughness
- Die Trait-, Loadout- und Biografie-Informationen bleiben read-only erhalten, sofern sie noch lesbar in den Screen passen.

### 4. Typografie und Dichte nachziehen
- Reduziere Schriftgroessen und Zeilenabstaende nochmals kontrolliert ueber alle Homebase-Fenster.
- Ziel ist eine deutlich dichtere, aber weiterhin lesbare Informationsdarstellung.

## Architekturhinweise
- Tooltips bleiben UI-Layer-Hilfe und tragen keine Gameplay-Wahrheit.
- Kein neuer separater Charakterbogen-Datenpfad; der bestehende Meta-Profilpfad bleibt fuehrend.
- Keine Fireteam-Auswahl in der Homebase vorziehen.

## Nicht-Ziele
- keine FOB-Fireteam-Auswahl in diesem Task
- keine neue Karten-Persistenz
- keine neue Lokalisierungsarchitektur
- keine Gameplay-Wirkung aus Skills oder Rollen

## Akzeptanzkriterien
- Die linken Portrait-Karten sind deutlich kompakter als die Karten im Transferfenster.
- Fensterkoerper enthalten keine dauerhaften Erklaertexte mehr; Hilfe erscheint als deutsche Popup-Tooltips.
- Der Charakterbogen zeigt keine Callsign-/Age-/Origin-Felder mehr.
- Skills stehen ausgeschrieben untereinander im Charakterbogen.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Polish homebase cards tooltips and character sheet (TASK_075)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren