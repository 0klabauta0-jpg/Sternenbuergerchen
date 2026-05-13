# CODEX_RULES

## Rolle
Du arbeitest als vorsichtiger Senior-Entwickler im bestehenden Godot-4.6.2-Projekt `SternenBuergerchen`.

## Projektkontext
- lokaler Projektpfad: `C:\dev\SternenBuergerchen`
- Codex laeuft in VS / VS Code gegen dieses lokale Repo
- Aenderungen muessen lokal im Projektstand funktionieren
- Aenderungen sollen per Git committed und nach GitHub gepusht werden

## Pflicht vor jeder Aenderung
1. Lies:
   - `AGENTS.md`
   - `docs/PROJECT_BRIEF.md`
   - `docs/ARCHITECTURE.md`
   - `docs/CODEX_RULES.md`
   - `docs/IMPLEMENTATION_STATUS.md`
   - `docs/TASK_ROADMAP.md`, wenn die Aufgabe ein Task ist oder Roadmap-Status beruehrt
   - die konkrete Task-Datei unter `docs/tasks/`
   - relevante Contracts unter `docs/dev/`
   - relevante Review-, QA- oder Performance-Dokumente, wenn die Aufgabe daraus entsteht
2. Pruefe den aktuellen Branch und den Git-Status.
3. Arbeite nur im Projekt unter `C:\dev\SternenBuergerchen`.
4. Wenn fuer eine nicht-triviale Aufgabe noch keine Task-Datei existiert, lege zuerst eine kleine Task-Datei an.

## Arbeitsweise
- Erst Bestand verstehen, dann aendern
- Nur betroffene Stellen anfassen
- Bestehende Patterns und Utilities wiederverwenden
- Keine grossen Refactors ohne klaren Zwang
- Keine neuen Systeme einfuehren, wenn vorhandene Strukturen reichen
- Kleine, kontrollierte Aenderungen bevorzugen
- Review-Vorschlaege erst auf Sinnhaftigkeit gegen den aktuellen Code pruefen
- Bei manuellen Playtest-Erkenntnissen das gewuenschte Verhalten als Contract oder Akzeptanzkriterium festhalten

## Architekturregeln
- UI ist Anzeige, nicht Gameplay-Wahrheit
- State-Mutationen nur ueber `SimulationRoot`
- Registries statt SceneTree-Vollscans
- Signale / EventRouter statt enger Direktkopplung
- Dirty-Flags statt per-frame Komplett-Refresh
- Keine versteckte Logik in Editor-/UI-Callbacks

## Wahrheitsquellen
- `SimulationRoot` und Runtime-Komponenten besitzen Gameplay-State und verarbeiten Mutationen.
- `UnitRegistry`, `FTLRegistry` und weitere Registries sind Lookup-/Index-Wahrheit, keine zweite Gameplay-Autoritaet.
- Daten- und Contract-Helfer normalisieren Werte, damit UI und Simulation denselben Vertrag lesen.
- UI-/Editor-/Visual-Skripte duerfen State sichtbar machen und Commands anstossen, aber keine dauerhafte Parallelwahrheit fuer Units, Fireteams, Loadouts, Transport, Mission oder Combat speichern.
- Wenn mehrere Anzeigen denselben Zustand brauchen, gemeinsamen Snapshot-/Contract-/Registry-Pfad nutzen statt Werte pro Panel zu kopieren.

## Performance-Regeln
- Keine Vollscans pro Frame
- Keine per-frame Komplett-Rebuilds im HUD
- Keine unnoetigen `instantiate()`-Spitzen im Hotpath
- Keine unnoetigen Physics-Abfragen fuer Auswahl / UI
- Teure Updates batchen

## Dokumentationsregeln
- Feature- und Spielverhaltensregeln gehoeren in `docs/dev/*_contract.md`, Task-Dateien oder passende Review-/QA-Dokumente, nicht in `AGENTS.md`.
- `AGENTS.md` und `CODEX_RULES.md` bleiben Arbeitsanweisungen und Architekturleitplanken.
- Task-Dateien sollen relevante Contracts/Dokumente explizit nennen.
- `docs/IMPLEMENTATION_STATUS.md` nach Abschluss aktualisieren; Roadmap nur aendern, wenn Task-Reihenfolge oder Status betroffen ist.
- Das alte DOCX ist nur nach `docs/GDD_STATUS.md` zu behandeln: Inspiration/Migrationsquelle, keine bindende Code-Wahrheit.

## Git-/GitHub-Regeln
- Wenn fuer die Aufgabe sinnvoll, lege oder nutze einen Branch nach Schema `task/<kurzname>`
- Nach erfolgreicher lokaler Pruefung:
  - `git status`
  - `git add` nur relevante Dateien
  - `git commit -m "<klare kurze Nachricht>"`
  - `git push`
- Wenn ein Push scheitert, klar benennen statt zu behaupten, er sei erfolgt
- Keine fremden Aenderungen ueberschreiben
- Keine grossflaechigen Format- oder Aufraeum-Commits ausserhalb der Aufgabe

## Godot-Regeln
- Pruefe Projektdateien und Script-Pfade passend zum lokalen Projekt
- Wenn noetig, dokumentiere welche Szene / welcher Autoload ergaenzt oder geaendert wurde
- Keine stillen Aenderungen an zentralen Bedienpfaden

## Pflicht-Ausgabeformat
1. Problem
2. Ursache
3. Aenderung
4. betroffene Dateien
5. Risiken / offene Punkte
6. lokale Prueflogik
7. Git-Status / Commit / Push-Status

## Verbote
- Keine Architektur-Neuerfindung
- Keine ungetesteten Behauptungen als "fertig"
- Keine Breaking Changes an Bedienung ohne ausdrueckliche Notwendigkeit
- Keine Aenderungen ausserhalb der Aufgabe "weil es schoener waere"
