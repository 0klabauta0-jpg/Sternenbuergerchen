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

UI ist nicht die Wahrheit. Gameplay-Zustand wird nicht in UI-Skripten verwaltet.

## Wahrheit und Besitz
- Gameplay-Wahrheit liegt bei `SimulationRoot`, Runtime-Komponenten, Datenmodellen und den dafuer vorgesehenen Contracts.
- Registries sind die Lookup-/Index-Wahrheit fuer Runtime-Objekte. Nutze sie statt SceneTree-Vollscans, aber mache sie nicht zu versteckten Gameplay-Mutatoren.
- UI, HUD, Editorpanels und Visuals lesen State, zeigen Feedback und senden Commands. Sie speichern keine zweite Mission-, Unit-, Loadout-, Transport- oder Combat-Wahrheit.
- Wenn ein UI- oder Visual-Pfad scheinbar "State" braucht, erst den bestehenden Runtime-/Contract-/Registry-Pfad suchen und wiederverwenden.
- Neue Zielverhalten, die aus manuellen Playtests stabil werden, gehoeren in `docs/dev/*_contract.md` oder in eine konkrete Task-Datei, nicht als Feature-Regeln direkt in diese Datei.

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
- relevante Contracts unter `docs/dev/...`
- relevante Reviews unter `docs/reviews/...`
- relevante QA-/Performance-Dokumente unter `docs/qa/...` und `docs/performance/...`

Nicht mit der Arbeit beginnen, bevor diese Dateien gelesen wurden. Wenn keine konkrete Task-Datei existiert und die Aenderung nicht trivial ist, zuerst eine kleine Task-Datei anlegen.

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
```

Wenn der aktuelle Arbeitsstand bewusst auf einem noch nicht integrierten Task aufbaut, muss das im finalen Status klar benannt werden.

---

# 4. Task- und Doku-Hygiene

Jede neue oder aktualisierte Task-Datei soll enthalten:

- Ziel / Problem
- Sinnhaftigkeit oder Ursache
- Umfang und Nicht-Ziele
- relevante Contracts / Dokumente
- Akzeptanzkriterien
- betroffene Dateien
- lokale Pruefung
- Risiken / offene Punkte

Bei Tasks aus Reviews gilt:
- Review-Befunde erst gegen den aktuellen Code pruefen.
- Nur sinnvolle, aktuelle Befunde in Tasks uebernehmen.
- Keine Review-Vorschlaege blind implementieren, wenn der Code inzwischen anders geloest ist.

Bei manuellen Playtest-Erkenntnissen gilt:
- Gewuenschtes Verhalten knapp als Contract oder Task-Akzeptanz festhalten.
- Danach erst Code aendern.
- Bestehende funktionierende Bedienlogik durch Regressionstests absichern.

## HTML-Arbeitsreports

Wenn Codex eine neue HTML-Datei unter `docs/reports/` erstellt oder einen bestehenden Report groesser umbaut, soll sie als interaktive Workbench nach `docs/dev/html_report_workbench_contract.md` aufgebaut werden, ausser der User verlangt ausdruecklich eine rein statische Seite.

Solche Reports sollen:
- einen klaren Uebersichts-, Test-/Entscheidungs- und Notizbereich haben
- lokale Bedienfelder fuer Playtest-Status, Entscheidungen, Parameter und Kommentare anbieten
- einen sichtbaren Button `JSON exportieren` enthalten
- den Export lokal per `file://` ohne Server und ohne externe Abhaengigkeiten erzeugen
- aus `docs/reports/_html_workbench_template.html` abgeleitet werden, wenn keine passendere bestehende Workbench als Vorlage dient

---

# 5. Performance- und Hotpath-Regeln

- Keine SceneTree-Vollscans im Runtime-Hotpath.
- Keine per-frame Komplett-Rebuilds von HUD, Kartenlisten oder grossen Control-Trees.
- Dirty-Flags, Caches, Throttles und `UpdateManager` bevorzugen.
- Progress- und Feedbackanzeigen duerfen getaktet aktualisieren; Simulation und Gameplay-State laufen weiterhin autoritativ.
- Performance-Aenderungen brauchen mindestens einen kleinen Verifier oder eine dokumentierte manuelle Profiler-Pruefung.
