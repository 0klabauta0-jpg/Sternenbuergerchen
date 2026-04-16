# AGENTS.md

## Zweck
Diese Datei gibt verbindliche Arbeitsregeln fuer Codex und andere Agenten in diesem Repository vor.

Das Ziel ist:
- kontrollierte, nachvollziehbare Entwicklung
- keine Architektur-Drift
- keine stillen Scope-Erweiterungen
- kleine, integrierbare Schritte
- saubere Git-Historie

Dieses Repository ist kein Sandkasten.  
Aendere nur das, was fuer den aktuellen Task noetig ist.

---

# 1. Projektkontext

## Engine
- Godot 4.6.1

## Lokales Projekt
- `C:\dev\SternenBuergerchen`

## Architekturgrundsatz
Das Projekt basiert auf einer klar getrennten Architektur:

- `RuntimeLeader` / FTL als Laufzeitkomponente
- `EventRouter` als Signal-Drehscheibe
- `SimulationRoot` als autoritative Simulationsstelle
- `UnitRegistry` / `FTLRegistry` fuer Lookup
- `UpdateManager` fuer kontrollierte Dirty-/Batch-Updates

UI ist nicht die Wahrheit.
Gameplay-Zustand wird nicht in UI-Skripten verwaltet.

---

# 2. Immer zuerst lesen

Vor jeder nicht-trivialen Aenderung muessen folgende Dateien gelesen werden:

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`

Wenn vorhanden und relevant:
- `docs/TASK_ROADMAP.md`
- konkrete Task-Datei unter `docs/tasks/...`

Nicht mit der Arbeit beginnen, bevor diese Dateien gelesen wurden.

---

# 3. Branch-Regeln

## Niemals direkt auf `main` arbeiten
## Niemals direkt auf alten Task-Branches weiterarbeiten, wenn ein Integrationsbranch vorgegeben ist

Aktuelle Arbeitsbasis ist in der Regel:
- `integration/core-foundation`

Vor einem neuen Task:

```bash
git checkout integration/core-foundation
git checkout -b task/<task-name>

4. Git-Regeln

Nach jedem abgeschlossenen Task zwingend:

relevante Dateien aendern
docs/IMPLEMENTATION_STATUS.md aktualisieren
Godot-/Syntax-Pruefung durchfuehren
git add .
git commit -m "<praezise commit message>"
git push

Wenn ein Branch noch keinen Upstream hat:

git push -u origin <branch-name>

Keine Sammel-Commits fuer mehrere unabhaengige Tasks ohne ausdrueckliche Vorgabe.

5. Was nicht getan werden darf
Verboten
keine neue Architektur einfuehren
keine globalen SceneTree-Suchen fuer Laufzeitlogik
kein get_tree().get_nodes_in_group(...)
kein find_child(...)
kein find_children(...)
keine Gameplay-Logik in UI
keine versteckten Kopplungen zwischen Systemen
keine grossen Refactors ausserhalb des Task-Scope
keine stillen Dateiverschiebungen
keine Scope-Erweiterung „weil es gerade passt“
keine neue Infrastruktur ohne klare Notwendigkeit
keine komplette Spiellogik bauen, wenn nur Datenmodell oder Integrationsnachweis gefragt ist
Besonders vermeiden
FTL-Logik, Combat, Navigation, Mission Flow und UI in einem Task zusammenziehen
SimulationRoot zu einem Alles-Skript machen
Registries mit Spiellogik befuellen
RuntimeLeader direkt fremde Systeme mutieren lassen
Editor-/Cache-Dateien versionieren
6. Godot-spezifische Regeln
Ignorieren / nicht versionieren
*.uid
.godot/
.import/
Export-Artefakte und temporäre Dateien
Keine Annahmen ueber Main Scene

Wenn fuer den Task noetig:

Main Scene nur minimal und gezielt setzen
keine unnoetigen Projektsettings aendern
Nodes / Skripte
nur klare, sprechende Namen
keine unnötige Verschachtelung
keine riesigen All-in-one-Skripte
lieber kleine, getrennte Skripte mit klarer Verantwortung
7. Architekturregeln im Code
SimulationRoot
ist die autoritative Stelle fuer zustandsveraendernde Simulation
andere Systeme liefern Daten, Events oder Commands
andere Systeme committen keinen finalen Gameplay-State ausserhalb ihrer klaren Verantwortung
EventRouter
ist Signal-Drehscheibe
ist kein grosses Logiksystem
RuntimeLeader
ist FTL-Komponente
nimmt Commands / Tasks an
fuehrt keine versteckte globale Steuerung aus
Registries
sind Lookup- und Verwaltungsstellen
enthalten keine Spiellogik
UpdateManager
verarbeitet Dirty-/Batch-Updates
ersetzt keine Simulation
8. Task-Disziplin

Jeder Task muss klein bleiben.

Ein Task ist fertig, wenn:

der definierte Scope umgesetzt ist
Godot ohne neue offensichtliche Fehler startet
IMPLEMENTATION_STATUS.md aktualisiert ist
keine unerlaubten Nebenumbauten passiert sind
der Branch gepusht ist

Wenn ein Task groesser wird als gedacht:

stoppen
Problem benennen
keine improvisierte neue Architektur bauen
9. Umgang mit Unsicherheit

Wenn unklar ist, wie ein Task im bestehenden System sauber umgesetzt werden kann:

Nicht raten.
Nicht grossflächig umbauen.
Nicht kreativ „verbessern“.

Stattdessen:

minimalen, sicheren Schritt waehlen
Risiken offen benennen
bei Blockade sauber stoppen und den Grund ausgeben
10. Bevorzugte Arbeitsweise
Bevorzugt
kleine additive Aenderungen
klare APIs
Guard-Checks
minimaler Glue-Code
nachvollziehbare Datenmodelle
explizite Aktualisierung von IMPLEMENTATION_STATUS.md
Nicht bevorzugt
Magie
automatische globale Verdrahtung
versteckte Seiteneffekte
„ich habe gleich noch X mitgemacht“
11. Test- und Nachweispflicht

Nach jedem Task mindestens logisch/manuell pruefen:

laedt das Projekt / die Testszene ohne offensichtliche Fehler?
ist der Task-Scope sichtbar umgesetzt?
wurden keine verbotenen globalen Suchmuster eingebaut?
wurden keine fremden Systeme unnötig umgebaut?

Wenn moeglich:

kleine Integrationsnachweise bevorzugen
keine aufgeblasenen Test-Frameworks fuer Mini-Tasks
12. Pflicht fuer Statuspflege

Nach jedem Task muss docs/IMPLEMENTATION_STATUS.md aktualisiert werden mit:

Status
Stand
Offene Punkte
Risiken
Naechster Schritt

Keine Ausnahme.

13. Erwartetes Antwortformat von Codex

Wenn ein Task umgesetzt wurde, liefere strukturiert:

Problem
Ursache
Aenderung
betroffene Dateien
Risiken / offene Punkte
Testbeschreibung

Wenn in einem Batch mehrere Tasks bearbeitet werden:

diesen Block fuer jeden Task einzeln liefern
zusaetzlich Gesamtstand nennen
14. Batch-Regel

Wenn mehrere Tasks in einem Batch abgearbeitet werden:

strikt nacheinander
nach jedem Task commit + push
nach jedem Task IMPLEMENTATION_STATUS.md aktualisieren
bei erstem groesseren Fehler stoppen
keinen spaeteren Task anfangen, wenn der fruehere instabil ist
15. Aktueller Entwicklungsgrundsatz

Aktuell ist das Projekt noch im Architektur- und Prototyp-Fundament.

Prioritaet:

Datenfluss
Runtime-Struktur
Integrationsnachweise
minimale sichtbare Reaktion
erst spaeter echte Taktik, Combat, Meta und Multiplayer

Das bedeutet:

lieber kleine, beweisbare Schritte
keine Feature-Explosion
keine Politur vor Funktion

---

