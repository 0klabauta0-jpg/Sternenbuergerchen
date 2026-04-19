# TASK_074 – Homebase: Layout-Neuordnung und Missionsinfoleiste

## Ziel
Die Homebase soll als klar lesbarer grauer Staging-Screen neu angeordnet werden: links der scrollbare Pool kompakter Portrait-Karten, in der Mitte das Transferfenster, rechts der lesende Charakterbogen und darueber eine eigenstaendige Missionsinfoleiste ueber die volle Breite.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_070_npc_karten_komponente.md`
- Lies `docs/tasks/TASK_071_heimatbasis_npc_karten.md`
- Lies `docs/tasks/TASK_072_fob_teamkarten.md`
- Lies `docs/tasks/TASK_073_homebase_charakterbogen_dragdrop.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_073 muss implementiert sein.
- Der bestehende Homebase -> FOB -> Mission -> Debrief-Flow darf nicht regressieren.

## Ist-Zustand (nach TASK_073)
- Die Homebase ist bereits ein Dreispalten-Screen mit Charakterbogen links, Transfer in der Mitte und Roster rechts.
- Das Layout ist funktional, aber noch nicht in der gewuenschten Fensterreihenfolge und Dichte.
- Es gibt noch keine eigenstaendige Missionsinfoleiste im oberen Bereich.

## Aufgabe

### 1. Fensterreihenfolge neu aufbauen
- Stelle die Fenster in dieser Reihenfolge dar:
  - links: scrollbarer Pool der Portrait-Karten
  - mitte: Transferfenster / Staging-Bereich
  - rechts: Charakterbogen
- Der Transferbereich bleibt der einzige Ort fuer Homebase-Staging-Interaktion.

### 2. Oberes Missionsinfo-Fenster einfuehren
- Fuehre im oberen Bereich ueber die volle Breite ein eigenes Missionsinfo-Fenster ein.
- Dieses Fenster soll etwa den oberen `1/8` des Homebase-Screens belegen.
- Der Inhalt bleibt read-only und kompakt, z. B.:
  - aktueller Einsatz / Missionsname
  - Teamlimit
  - Hinweis auf FOB-Transfer
  - optional kurze Status-/Briefing-Zeile
- Keine neue Missionslogik oder Gameplay-Wahrheit einfuehren.

### 3. Transferfenster mit klarer CTA-Struktur
- Platziere im Transferfenster oben einen klaren Button `Send to FOB`.
- Der bestaetigende Homebase-CTA bleibt inhaltlich derselbe bestaetigende Schritt wie bisher.
- Der darunterliegende Staging-Bereich bleibt Drag-and-Drop-faehig.

### 4. Sichtbarkeit und Layoutdichte verbessern
- Alle drei Hauptfenster muessen im sichtbaren Bereich liegen, ohne dass Inhalte horizontal aus dem Fenster gedrueckt werden.
- Reduziere Zeilenabstaende und Innenabstaende kontrolliert.
- Reduziere Grundschriftgroessen moderat, ohne die Lesbarkeit zu verlieren.
- Scrollbereiche sollen vertikal arbeiten statt das Gesamtlayout aufzublasen.

## Architekturhinweise
- Homebase bleibt rein UI- und staginggetrieben.
- Keine Gameplay-Wahrheit in Fenster-Callbacks speichern.
- Keine neue globale Layout- oder Theme-Architektur einfuehren, wenn die bestehende Meta-UI-Struktur reicht.

## Nicht-Ziele
- keine Fireteam-Auswahl in der Homebase
- keine neue Missionslogik
- keine neue Persistenz
- keine Loadout- oder Rollenlogik mit Gameplay-Wirkung

## Akzeptanzkriterien
- Links ist der Portrait-Karten-Pool, mittig das Transferfenster, rechts der Charakterbogen.
- Ein eigenes Missionsinfo-Fenster liegt oben ueber die volle Breite.
- `Send to FOB` sitzt oben im Transferfenster.
- Die Fenster bleiben im sichtbaren Bereich und sind ohne horizontales Abschneiden nutzbar.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Rework homebase layout and mission info bar (TASK_074)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren