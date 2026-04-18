# TASK_073 – Homebase: Charakterbogen und Drag-and-Drop-Teamstaging

## Ziel
Die Homebase soll von der bisherigen Karten-/Fokusansicht auf eine klarere Dreispalten-Struktur erweitert werden: rechts ein scrollbarer Pool aus kleinen NPC-Karten mit Portrait, Name und zwei kompakten Datenpunkten, in der Mitte ein Drag-and-Drop-Staging-Bereich fuer das aktuelle Transferteam und links ein vollstaendiger lesender Charakterbogen fuer den aktuell fokussierten NPC.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_070_npc_karten_komponente.md`
- Lies `docs/tasks/TASK_071_heimatbasis_npc_karten.md`
- Lies `docs/tasks/TASK_072_fob_teamkarten.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_070 (NPC-Karten-Komponente) muss implementiert sein.
- TASK_071 (Homebase NPC-Karten und Auswahlfokus) muss implementiert sein.
- TASK_072 (FOB Teamkarten und Einsatzstatus) muss implementiert sein.
- Der bestehende Homebase -> FOB -> Mission -> Debrief-Flow darf nicht regressieren.

## Ist-Zustand (nach TASK_072)
- Homebase und FOB nutzen bereits einen kleinen read-only Meta-Profilpfad.
- Die Homebase zeigt verfuegbare Units als Karten mit Fokusbereich, aber noch nicht als Portrait-Kleinkarten mit eigentlichem Charakterbogen.
- Teamauswahl laeuft aktuell klickbasiert statt ueber Drag-and-Drop-Staging.
- Der Missionspfad ist weiterhin auf drei Friendly-Testslots begrenzt.

## Aufgabe

### 1. Zwolf Beispiel-NPCs mit erweitertem Charakterbogen anlegen
- Erweitere den Homebase-Roster auf 12 Beispiel-NPCs.
- Jeder NPC soll zusaetzlich zu den vorhandenen Skill-/Trait-Daten kleine Charakterbogen-Felder erhalten, z. B.:
  - Portrait-Pfad
  - Callsign oder Alias
  - Rolle / Spezialisierung
  - Herkunft / Homeworld
  - Alter oder Dienstjahre
  - kurzer Freitext / Biografie
  - optional Loadout- oder Ausruestungshinweis
- Die Daten bleiben read-only und menugetrieben.

### 2. Homebase als Dreispalten-Staging-Screen aufbauen
- Linke Spalte: Infos / Charakterbogen der aktuell fokussierten Unit.
- Mittlere Spalte: aktuelles Transferteam als Staging-Bereich.
- Rechte Spalte: scrollbarer Pool aller verfuegbaren NPC-Kleinkarten.
- `Transfer Team to FOB` bleibt der bestaetigende CTA aus der Homebase.

### 3. Kleine Portrait-Karten fuer den NPC-Pool
- Jede kleine Karte rechts soll mindestens zeigen:
  - Portrait
  - Name
  - zwei kompakte Datenpunkte
- Ein Klick auf eine kleine Karte soll den vollen Charakterbogen links anzeigen.
- Die Karten sollen als Quelle fuer Drag-and-Drop in den mittleren Staging-Bereich dienen.

### 4. Drag-and-Drop ins Transferteam
- NPCs koennen per Drag-and-Drop aus dem rechten Pool in den mittleren Staging-Bereich gezogen werden.
- Der Staging-Bereich bildet die selektierten `unit_id`s fuer den bestehenden Transferpfad.
- Doppelte Eintraege duerfen nicht entstehen.
- Da die aktuelle Missions-Testszene nur drei Friendly-Slots hat, ist das Homebase-Staging fuer diesen Pfad auf maximal drei NPCs zu begrenzen.
- Entfernen aus dem Staging ist erlaubt, solange der Interaktionspfad klar bleibt.

### 5. Bestehenden Missionspfad fuer frei waehlbare NPCs stabilisieren
- Der Meta-/Missionspfad darf nicht mehr implizit an die festen IDs `unit_alpha`, `unit_bravo`, `unit_charlie` gebunden sein.
- Die selektierten NPC-Profile sollen beim Missionsstart kontrolliert auf die drei vorhandenen Friendly-Testslots gemappt werden.
- FOB, Mission und Debrief muessen weiter mit den tatsaechlich selektierten NPC-IDs arbeiten.

## Architekturhinweise
- Homebase bleibt rein UI- und staginggetrieben.
- Keine Gameplay-Wahrheit in der Homebase speichern.
- Keine neue globale Registry oder Persistenzschicht fuer Charakterboegen einfuehren.
- Wenn fuer die Portrait-Kleinkarten ein eigener UI-Baustein sinnvoll ist, soll er weiter auf dem bestehenden Meta-Profilpfad aufsetzen statt einen parallelen Datenpfad einzufuehren.

## Nicht-Ziele
- keine echte Barracks-Simulation
- keine Ausruestungs- oder Rollenlogik mit Gameplay-Wirkung
- keine persistente Rekrutierung
- keine unbegrenzte Missions-Teamgroesse
- keine neue freie Character-Editor-Oberflaeche

## Akzeptanzkriterien
- Die Homebase zeigt 12 Beispiel-NPCs als kleine Portrait-Karten im rechten Pool.
- Ein Klick auf eine kleine Karte oeffnet links den vollen lesenden Charakterbogen.
- NPCs koennen per Drag-and-Drop in den mittleren Staging-Bereich gezogen werden.
- `Transfer Team to FOB` uebergibt weiter die selektierten `unit_id`s an den bestehenden Flow.
- FOB, Mission und Debrief funktionieren weiter mit frei aus dem 12er-Roster ausgewaehlten NPCs innerhalb des aktuellen 3er-Missionslimits.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add homebase character sheet drag-and-drop staging (TASK_073)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren