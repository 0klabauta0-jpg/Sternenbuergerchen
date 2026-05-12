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
- Godot 4.6.2

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
