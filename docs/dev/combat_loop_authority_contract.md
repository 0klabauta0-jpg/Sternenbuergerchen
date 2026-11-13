# Combat Loop Authority Contract

## Erweiterung 13.11.2026: normalisierte Ownerwürfe
Disziplin und Fehlidentifikation verwenden den vorhandenen Combat-PCG des
autoritativen SimulationRoot. Readouts und Replikate würfeln nicht. Die unabhängigen
Raum-/Luftzustände werden gemeinsam mit Combat gespeichert und bei Prepare/Commit
auf Frische geprüft. Details, Seeds, Legacydefaults und Gates:
[Produktive Hexwege und Zufallsdomänen](productive_hex_rollout_contract.md).

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

Kontakt-/Feuerdiagnosen sind reine Projektionen. `can_unit_attack_for_readout`
liest aktuelle Bereitschaft und vorhandene Return-Fire-Fenster, wuerfelt aber
keinen Disziplinbruch und schreibt weder Cooldown noch Ereignis. Ein bereits
gebauter Damage-Effect belegt die erfolgte Entscheidung fuer seine Diagnose.
Nur die wirkliche Feuerentscheidung verwendet weiterhin `can_unit_attack`
mit dem bisherigen autoritativen Disziplinpfad. Auch beim ersten Auftauchen
eines Gegners darf ein HUD-Read weder globalen noch Root-RNG verbrauchen.

## Simulationstick und Decision-Kadenz
Discipline-, Misidentification- und Medic-Support-Cooldowns laufen pro aktivem
autoritativen Simulationstick weiter, auch wenn dieser Tick die teuren Combat-
Entscheidungsscans auslaesst. Die teuren Decision-Scans bleiben auf jeden dritten
Simulationstick begrenzt; Cooldowns von 10, 15 bzw. 12 Ticks werden dadurch nicht
verlaengert. Return-Fire
behaelt seine absolute Tickgrenze. Authority-, Missionsende-, fehlender-Root-
und Startup-Grace-Gates gelten weiterhin vor der Cooldown-Verarbeitung;
Renderframes oder eine pausierte Simulation verbrauchen keine Cooldowns.

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
