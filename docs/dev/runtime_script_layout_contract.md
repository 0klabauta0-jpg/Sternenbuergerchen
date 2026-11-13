# Runtime Script Layout Contract

## Zweck
Dieser Contract klaert die aktuelle Ordnergrenze fuer autoritative Runtime-, Mission- und Tactical-Skripte. Er verhindert, dass der leere Ordner `scripts/simulation/` als neue Wahrheit missverstanden wird.

## Entscheidung
`scripts/core/` bleibt kurzfristig und bis zu einem eigenen Migrations-Task der definierte Runtime-Kernpfad.

Eine mechanische Verschiebung nach `scripts/simulation/` findet in TASK_498 bewusst nicht statt. Godot-Szenen, Preloads und Tests referenzieren viele konkrete `res://`-Pfade; ein Pfadumzug waere ein breiter Refactor ohne Gameplay-Nutzen.

## Aktuelles Inventar
- `scripts/core/`: autoritative Runtime-Kernskripte wie `simulation_root.gd`, `damage_model.gd`, `objective_status.gd`, `respawn_manager.gd`, `event_router.gd`, `update_manager.gd`, LOS/Fog-of-War und Waffenlesedaten.
- `scripts/mission/`: mission-scope Contracts, Adapter und Bridges. Diese duerfen Mission-Payloads normalisieren, Commands/Effects bauen und Visual-/Input-Grenzen kapseln, aber keine zweite Gameplay-Wahrheit neben `SimulationRoot` erzeugen.
- `scripts/tactical/`: taktische Resolver, Controller und UI-/Visual-Adapter fuer Fireteam-Execution, Movement, Security, Combat-Entscheidung, Kommunikation und Overlays. Tactical-Code darf Command-Dictionaries und Snapshots bauen; autoritative Mutationen laufen weiter ueber `SimulationRoot`.
- `scripts/tests/`: Verifier, Harnesses und historisch gewachsene Szenen-Driver. Produktiv genutzte Komponenten duerfen dort nur als Legacy-Bridge verbleiben, bis ein kleiner Extraction-Task sie nach `scripts/mission/` oder `scripts/tactical/` verschiebt.
- `scripts/simulation/`: inaktiver, reservierter Pfad. Keine neuen produktiven Skripte hier ablegen, solange kein eigener Migration-Task die Pfadstrategie samt Kompatibilitaet festlegt.

## Schreibregeln fuer neue Tasks
- Autoritative State-Mutationen, Command-/Effect-Commit und globale Runtime-Kernlogik: `scripts/core/`.
- Mission-Setup, Mission-Snapshot-Vertraege, Dropship-/Briefing-/Result-Adapter und Mission-Input-Gates: `scripts/mission/`.
- Fireteam-, Enemy-, Movement-, Cover-, Contact-, Communication- und Order-Resolver: `scripts/tactical/`.
- Headless-Verifier, Harnesses und reine Test-Szenen-Helfer: `scripts/tests/`.
- Neue produktive Skripte duerfen nicht in `scripts/tests/` oder `scripts/simulation/` landen, ausser die zugehoerige Task-Datei begruendet die Ausnahme explizit.

## Migration-Regeln
Eine spaetere Migration nach `scripts/simulation/` braucht einen eigenen Task und muss mindestens enthalten:
- Inventar aller `res://scripts/core/...`-Referenzen in Szenen, Skripten, Tests und Doku.
- Kompatibilitaetsstrategie fuer bestehende Godot-Preloads und Szenenressourcen.
- Headless-Import/Compile und relevante Runtime-Regressionen.
- Kein gleichzeitiges Verhalten-Refactoring.

Bis dahin gilt: Ordnernamen sind Organisation, nicht Gameplay-Wahrheit. Die Wahrheit bleibt bei `SimulationRoot`, Runtime-Komponenten, Registries und den dokumentierten Contracts.

## Interaktionsautorität · Reviewabschluss 13.11.2026

`scripts/mission/mission_network_interaction_authority.gd` kapselt die
hostseitige Bindungsauflösung, die exklusive Pending-Use-Belegung und deren
Bedienzeit-/Abbruchlebenszyklus. Der CombatDriver besitzt genau eine Instanz;
seine bisherigen Signal-/Preflight- und Snapshot-Einstiegspunkte delegieren.
Die Komponente hält nur eine schwache Referenz auf den vorhandenen Driver.
Unit-/Marker-/Gate-/Completion-Fakten liest sie dort beziehungsweise bei den
bisherigen Registries; Ergebnisse gehen durch den bestehenden
`update_mission_interaction_runtime_progress`-Commit. Keine zweite Unit- oder
Missionswahrheit, keine zusätzliche Queue und kein SceneTree-Scan.

Die vorhandenen echten ENet-/Stations-/Paralleltrupp-/Türprüfungen sichern die
kompatible Schnittstelle. Ein Dateiumzug des gesamten Drivers gehört nicht zu
dieser klar abgegrenzten Extraction.
