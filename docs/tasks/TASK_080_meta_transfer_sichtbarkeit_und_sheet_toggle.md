# TASK_080 – Meta-Layer: Transfer-Sichtbarkeit, Pool-DnD und Charakterbogen-Toggle

## Ziel
Der Meta-Layer soll den Transfer zwischen Homebase und FOB klarer als echte Verschiebung abbilden: uebertragene Operators verschwinden aus der Homebase, in der FOB zeigt die Available-Spalte nur noch unzugewiesene Personen, und der Charakterbogen soll gezielt per Doppelklick oeffnen sowie wieder schliessbar sein.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_078_meta_navigation_map_ansicht.md`
- Lies `docs/tasks/TASK_079_fob_fireteam_staging_ausbau.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_079 muss implementiert sein.
- Die bestehende Homebase -> FOB -> Mission -> Debrief-Kette darf funktional erhalten bleiben.

## Ist-Zustand (nach TASK_079)
- Homebase und FOB teilen sich noch zu direkt dieselbe Rosterbasis.
- In der FOB bleiben bereits zugewiesene Operators noch in der Available-Spalte sichtbar.
- Der Charakterbogen ist in der Homebase nicht mehr gezielt oeffnend/schliessbar.

## Aufgabe

### 1. Transfer sichtbar als Pool-Wechsel abbilden
- Wenn Operators von Homebase zur FOB bestaetigt werden, sollen sie in der Homebase verschwinden.
- Die Homebase soll weiterhin nur mit ihrem verbleibenden lokalen Roster arbeiten.
- Die FOB soll nur die bereits dorthin uebertragenen Operators kennen.

### 2. Available-/Fireteam-Pools in der FOB sauber trennen
- In der Available-Spalte duerfen nur unzugewiesene FOB-Operators sichtbar sein.
- Wenn ein Operator einem Fireteam zugeordnet wird, verschwindet er aus Available.
- Wenn ein Operator wieder geloest wird, soll er zur Available-Spalte zurueckkehren.
- Die Rueckfuehrung soll auch per Drag-and-Drop moeglich sein.

### 3. Fireteam- und Charakterbogen-Interaktion polieren
- Fireteam-Karten sollen kompakter und textlich verdichteter werden.
- Der FOB-Respawnblock soll in den Header neben den Start-Mission-Button wandern.
- In der Homebase soll Doppelklick auf eine NPC-Karte den Charakterbogen oeffnen.
- Der Charakterbogen soll wieder explizit schliessbar sein.

## Architekturhinweise
- Der Pool-Wechsel bleibt Meta-State und keine Gameplay-Wahrheit.
- Keine neue Persistenz oder Inventararchitektur einfuehren.
- Drag-and-Drop bleibt UI-Interaktion; keine versteckten Missions-Commits daraus ableiten.

## Nicht-Ziele
- keine tiefe Inventar- oder Equipment-Simulation
- keine neue Kampagnenpersistenz
- keine neue globale UI-State-Architektur ausserhalb des bestehenden Meta-Layers

## Akzeptanzkriterien
- Nach `Send to FOB` sind die uebertragenen Operators in der Homebase nicht mehr sichtbar.
- Die FOB-Available-Spalte zeigt nur unzugewiesene Operators.
- Rueckfuehrung zwischen Available und Fireteam ist auch per Drag-and-Drop moeglich.
- Doppelklick oeffnet in der Homebase den Charakterbogen, und `Close` blendet ihn wieder aus.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Polish meta transfer visibility and character sheet toggle (TASK_080)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren