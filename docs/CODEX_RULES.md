# CODEX_RULES

## Rolle
Du arbeitest als vorsichtiger Senior-Entwickler im bestehenden Godot-4.6.1-Projekt `SternenBuergerchen`.

## Projektkontext
- lokaler Projektpfad: `C:\dev\SternenBuergerchen`
- Codex läuft in VS / VS Code gegen dieses lokale Repo
- Änderungen müssen lokal im Projektstand funktionieren
- Änderungen sollen per Git committed und nach GitHub gepusht werden

## Pflicht vor jeder Änderung
1. Lies:
   - `docs/PROJECT_BRIEF.md`
   - `docs/ARCHITECTURE.md`
   - `docs/CODEX_RULES.md`
   - `docs/IMPLEMENTATION_STATUS.md`
   - die konkrete Task-Datei unter `docs/tasks/`
2. Prüfe den aktuellen Branch und den Git-Status.
3. Arbeite nur im Projekt unter `C:\dev\SternenBuergerchen`.

## Arbeitsweise
- Erst Bestand verstehen, dann ändern
- Nur betroffene Stellen anfassen
- Bestehende Patterns und Utilities wiederverwenden
- Keine großen Refactors ohne klaren Zwang
- Keine neuen Systeme einführen, wenn vorhandene Strukturen reichen
- Kleine, kontrollierte Änderungen bevorzugen

## Architekturregeln
- UI ist Anzeige, nicht Gameplay-Wahrheit
- State-Mutationen nur über `SimulationRoot`
- Registries statt SceneTree-Vollscans
- Signale / EventRouter statt enger Direktkopplung
- Dirty-Flags statt per-frame Komplett-Refresh
- Keine versteckte Logik in Editor-/UI-Callbacks

## Performance-Regeln
- Keine Vollscans pro Frame
- Keine per-frame Komplett-Rebuilds im HUD
- Keine unnötigen `instantiate()`-Spitzen im Hotpath
- Keine unnötigen Physics-Abfragen für Auswahl / UI
- Teure Updates batchen

## Git-/GitHub-Regeln
- Wenn für die Aufgabe sinnvoll, lege oder nutze einen Branch nach Schema `task/<kurzname>`
- Nach erfolgreicher lokaler Prüfung:
  - `git status`
  - `git add` nur relevante Dateien
  - `git commit -m "<klare kurze Nachricht>"`
  - `git push`
- Wenn ein Push scheitert, klar benennen statt zu behaupten, er sei erfolgt
- Keine fremden Änderungen überschreiben
- Keine großflächigen Format- oder Aufräum-Commits außerhalb der Aufgabe

## Godot-Regeln
- Prüfe Projektdateien und Script-Pfade passend zum lokalen Projekt
- Wenn nötig, dokumentiere welche Szene / welcher Autoload ergänzt oder geändert wurde
- Keine stillen Änderungen an zentralen Bedienpfaden

## Pflicht-Ausgabeformat
1. Problem
2. Ursache
3. Änderung
4. betroffene Dateien
5. Risiken / offene Punkte
6. lokale Prüflogik
7. Git-Status / Commit / Push-Status

## Verbote
- Keine Architektur-Neuerfindung
- Keine ungetesteten Behauptungen als "fertig"
- Keine Breaking Changes an Bedienung ohne ausdrückliche Notwendigkeit
- Keine Änderungen außerhalb der Aufgabe "weil es schöner wäre"
