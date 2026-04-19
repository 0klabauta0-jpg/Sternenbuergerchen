# TASK_077 – FOB: Fireteam-Auswahl und Startvorbereitung

## Ziel
Die Fireteam-Zuordnung soll nicht mehr in der Homebase vorweggenommen werden, sondern erst in der FOB als eigener Vorbereitungsschritt vor dem Missionsstart erfolgen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_072_fob_teamkarten.md`
- Lies `docs/tasks/TASK_073_homebase_charakterbogen_dragdrop.md`
- Lies `docs/tasks/TASK_074_homebase_layout_neuordnung.md`
- Lies `docs/tasks/TASK_075_homebase_tooltips_charakterbogen_polish.md`
- Lies `docs/tasks/TASK_076_meta_ui_kenney_grau.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_076 muss implementiert sein.
- Der bestehende Homebase -> FOB -> Mission -> Debrief-Flow darf nicht regressieren.

## Ist-Zustand (nach TASK_076)
- Die Homebase stellt NPCs und Transferteam dar.
- Fireteam-Informationen koennen bereits in Profildaten existieren, sind aber fuer den neuen Flow nicht mehr Startpunkt der Auswahl.
- Die FOB zeigt Teamkarten und Missionsstatus, aber noch keinen expliziten Fireteam-Vorbereitungsschritt.

## Aufgabe

### 1. Homebase von Fireteam-Vorwegnahme entkoppeln
- Die Homebase soll keine Fireteam-Auswahl als fruehen Bedienpfad mehr darstellen.
- Falls Fireteam-Metadaten in Homebase-Karten oder im Charakterbogen auftauchen, sollen sie dort nicht mehr als auszuwaehlende Startentscheidung erscheinen.

### 2. Fireteam-Auswahl in der FOB einfuehren
- Fuehre in der FOB einen kleinen, klaren Vorbereitungsschritt fuer die selektierten Operators ein.
- Pro uebertragenem Operator soll mindestens eine Fireteam-Zuordnung vorbereitet werden koennen, z. B. `BLUE`, `GOLD` oder neutral/unassigned.
- Die Interaktion bleibt rein menugetrieben und read-only gegenueber Gameplay-Commit; sie bereitet nur den bestehenden Missionsstartpfad vor.

### 3. Missionsstart an FOB-Vorbereitung koppeln
- `Start Mission` bleibt in der FOB der bestaetigende Startpunkt.
- Der bestehende Missionsstart soll weiter mit den ausgewaehlten NPC-IDs arbeiten und zusaetzlich die vorbereiteten Fireteam-Zuordnungen kontrolliert mitnehmen, soweit der aktuelle Testpfad dies lesen kann.
- Falls der Missions-Testpfad die Fireteam-Zuordnung noch nicht sichtbar nutzt, soll der Datenfluss trotzdem explizit und kontrolliert hergestellt werden.

### 4. Kompatiblen Minimalpfad beibehalten
- Die aktuelle 3er-Teamgrenze bleibt bestehen.
- Keine grosse Commander-, Loadout- oder Squad-Management-Oberflaeche einfuehren.

## Architekturhinweise
- FOB bleibt ein staginggetriebener Meta-Screen, keine neue Gameplay-Wahrheit.
- Datenfluss bleibt explizit ueber den bestehenden Meta-/Missionspfad statt ueber globale Nebenkanal-States.
- Keine neue Registry oder Persistenzschicht fuer Fireteam-Zuordnungen einfuehren.

## Nicht-Ziele
- keine Formation- oder Rollenlogik mit Gameplay-Wirkung
- keine unbegrenzte Teamgroesse
- keine persistente Squad-Verwaltung
- keine neue Homebase-Squad-Management-Seite

## Akzeptanzkriterien
- Die Homebase ist nicht mehr der Ort der Fireteam-Auswahl.
- Die FOB bietet einen klaren Vorbereitungsschritt fuer Fireteam-Zuordnungen.
- `Start Mission` funktioniert weiterhin und bleibt kompatibel zum bestehenden Test-Missionspfad.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Move fireteam setup to FOB preparation flow (TASK_077)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren