# Combat Loop Authority Contract

## Zweck
TASK_162 trennt den multiplayer-relevanten Vertrag des Combat-Loops vom monolithischen Driver. `MissionCombatLoopDriver` orchestriert weiter die bestehende Mission, aber Snapshot-Keys, Mission-Result-Payloads, read-only UI-Events und erlaubte autoritative Effect-Typen liegen jetzt unter `scripts/mission/`.

## Produktive Komponenten
- `scripts/mission/mission_combat_authority_contract.gd`
  - dokumentiert Playability-, Objective-, Contact- und Mission-Result-Keys.
  - baut Playability-Snapshots und Mission-Result-Dictionaries.
  - listet erlaubte `SimulationRoot`-Effect-Typen.
- `scripts/mission/mission_combat_remote_event_bridge.gd`
  - baut Combat-Remote-Events als `read_only`-Payloads.
  - wendet empfangene Events nur auf lokale Anzeige/Eventtexte an.

## Autoritative Mutationen
Diese Effect-Typen gehoeren in den autoritativen `SimulationRoot`-Pfad:
- `damage`
- `heal`
- `bleedout`
- `respawn`
- `dropship_embark_unit`
- `dropship_deploy_unit`
- `apply_loadout_modifiers`

Read-only UI-Events wie `combat_ui_event` sind keine Effects und duerfen keinen Gameplay-State committen.

## Snapshot-Grenzen
- Playability-Snapshot: kompakter Zustand fuer UI/2.5D-View, inklusive Combat-State, Objective-State, Mission-Result und Zaehlern.
- Objective-State: kommt aus `SimulationRoot.get_objective_status()` und wird nur gespiegelt.
- Contact-State: kommt aus dem bestehenden `ContactTracker` und bleibt read-only fuer UI/Overlay.
- Mission-Result: wird vom Combat-Loop gebaut, aber nicht von UI-Skripten mutiert.

## Lokale Pruefung
```powershell
godot_console.exe --headless --path . --script scripts/tests/task_162_combat_authority_contract_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/task_119_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/task_118_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd
```

## TASK_495 Boundary-Follow-up
Der aktuelle `MissionCombatLoopDriver` bleibt vorerst der Tick-Orchestrator, darf aber nicht wieder zur fachlichen Sammelstelle fuer neue Combat- und Mission-Regeln werden.

Bereits ausgelagerte Entscheidungsschichten sind:
- `CombatFireDecisionResolver` fuer Ziel-/Feuerentscheidung und Damage-Effect-Payload.
- `MedicSupportResolver` fuer Medic-Zielwahl, Tool-Gates und Support-Actions.
- `OverwatchController` fuer Overwatch-Schussentscheidungen.
- `ContactTracker` fuer read-only Kontaktstatus und Relay.
- `FlankVulnerabilityResolver` fuer Flanken-/Morale-Modifikatoren.
- `MissionCombatAuthorityContract` und `MissionCombatRemoteEventBridge` fuer Snapshots, Mission-Result und read-only UI-Events.

Naechste Grenzen:
- Registry-Zugriff und Elimination-Hotfix vor struktureller Extraktion.
- Objective-/Mission-Result-Aufloesung in einen kleinen Resolver/Contract-Helfer.
- Enemy-Behavior-Orchestrierung aus dem Driver herausloesen, ohne Command-/Effect-Authority aus `SimulationRoot` zu verschieben.
- Readability-Labels, Kontaktlinie und Eventtexte in einen Presenter verschieben, der nur Snapshots/Events liest.

Nicht erlaubt:
- UI-/Presenter-Code darf keinen Combat-State besitzen.
- Neue Resolver duerfen keine direkten Damage-, Heal-, Respawn- oder Movement-Mutationen an Units ausfuehren.
- Snapshot-Key-Umbenennungen brauchen einen eigenen Contract-/Migrationstask.
