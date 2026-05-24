# TASK_498 - Runtime Script Layout Alignment

## Ziel / Problem
Das Verzeichnis `scripts/simulation/` enthaelt aktuell keine produktiven Simulationsskripte, waehrend zentrale Runtime-Dateien wie `simulation_root.gd`, `damage_model.gd`, `objective_status.gd`, `respawn_manager.gd`, `event_router.gd` und `update_manager.gd` unter `scripts/core/` liegen.

Ziel ist eine klare, nicht brechende Entscheidung: Entweder bleibt `scripts/core/` der definierte Runtime-Kernpfad und die Doku benennt das sauber, oder es wird ein schrittweiser Migrationsplan nach `scripts/simulation/` vorbereitet.

## Sinnhaftigkeit / Ursache
Die Architektur spricht von `SimulationRoot` und autoritativer Simulation, der leere `scripts/simulation/`-Ordner suggeriert aber eine andere Ordnergrenze. Das verursacht Orientierungsschuld und laedt zu falschen neuen Ablagen ein.

## Umfang
- Aktuelle Runtime-/Simulation-Dateien unter `scripts/core/`, `scripts/mission/`, `scripts/tactical/` und `scripts/tests/` inventarisieren.
- Entscheiden, ob `scripts/core/` offiziell der Runtime-Kern bleibt oder ob eine risikoarme Pfadmigration sinnvoll ist.
- Doku und Task-Regeln auf den entschiedenen Pfad korrigieren.
- Falls Migration empfohlen wird: nur Plan und Kompatibilitaetsstrategie festhalten, keine Massenverschiebung in diesem Task.

## Nicht-Ziele
- keine sofortige Massenumbenennung von `res://`-Pfaden
- keine Szenenpfad-Brechung
- kein Autoload-/ClassName-Rewrite
- keine Aenderung an Gameplay-Verhalten

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_003_simulationroot.md`
- `docs/tasks/TASK_162_combat_loop_authority_split.md`

## Akzeptanzkriterien
- Ein Runtime-Script-Layout-Contract oder Doku-Nachtrag beschreibt eindeutig, wo autoritative Simulation, Mission-Orchestrierung und Tactical-Resolver liegen.
- Neue Tasks wissen, ob sie in `scripts/core/`, `scripts/mission/`, `scripts/tactical/` oder `scripts/tests/` schreiben sollen.
- `scripts/simulation/` ist entweder entfernt/erklaert oder als geplanter Zielpfad mit Migrationsregeln dokumentiert.
- Keine bestehenden `res://`-Referenzen werden ohne Verifier-Absicherung verschoben.

## Betroffene Dateien
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- ggf. neuer Contract unter `docs/dev/`
- ggf. `scripts/simulation/.gitkeep`

## Lokale Pruefung
- `rg`-Inventar der aktuellen `res://scripts/core`, `res://scripts/mission`, `res://scripts/tactical` und `res://scripts/tests`-Referenzen.
- Falls nur Doku: `git diff --check`.
- Falls Pfade beruehrt werden: Godot headless Import/Compile und betroffene Regressionen.

## Risiken / offene Punkte
- Eine echte Pfadmigration ist breit und riskant, weil Godot-Szenen und Skripte viele `res://`-Referenzen halten.
- Wahrscheinlich ist kurzfristig eine Doku-Entscheidung besser als eine mechanische Verschiebung.
