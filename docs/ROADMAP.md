# ROADMAP

## Reihenfolge
1. RuntimeLeader / FTL
2. EventRouter
3. SimulationRoot
4. Registries
5. UpdateManager
6. erste Mission-Szene
7. Combat / Vision
8. Heimatbasis / FOB
9. Multiplayer-Prototyp V1

## Grundregel
Immer nur ein Task gleichzeitig.

## Definition of Done pro Task
- Code baut lokal im Projekt unter `C:\dev\SternenBuergerchen`
- relevante Godot-Szene / Autoload / Script ist integriert
- keine offensichtlichen Architekturverstöße
- `docs/IMPLEMENTATION_STATUS.md` ist aktualisiert
- Änderungen sind committed
- Änderungen sind auf GitHub gepusht

## Branch-Regel
- pro Task eigener Branch
- Branchname nach Schema: `task/<kurzname>`
- nach erfolgreichem Test Commit und Push

## Verifikation
- Godot-Projekt lokal öffnen
- betroffene Szene / Script / Autoload prüfen
- offensichtliche Fehler in Output und Debug-Konsole prüfen
