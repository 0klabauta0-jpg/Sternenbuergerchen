# TASK_697 - Door Interaction Multiplayer Authority Check

## Ziel / Problem
Door-Breach ist lokal bedienbar und visuell lesbar, aber der Host/Client-Authority-Pfad muss pruefbar machen, dass Clients keine Door-Wahrheit setzen und der Host die Door nur ueber den bestehenden Command-/Producer-Pfad oeffnet.

## Sinnhaftigkeit / Ursache
TASK_694 bis TASK_696 haben Hook, HUD und Visualstate aufgebaut. Fuer Multiplayer-Faehigkeit braucht der Door-Use-Pfad jetzt einen klaren Authority-Check: Button/Shortcut/GO duerfen nur Commands anstossen, waehrend Door-Runtime-State, Collision und LOS vom Server-/Runtime-Pfad kommen.

## Umfang
- Door-Breach-Hook wird in einen netzwerkvertraeglichen Commander-`take`-Command projiziert.
- Host-/Peer-Rechte werden ueber den bestehenden `SimulationRoot`/`MultiplayerCommandContract` validiert.
- Falsches Team und Client-State-Mutation werden explizit abgelehnt.
- Door-Runtime-Producer bleibt die einzige Quelle fuer effektive Walkability/LOS-Overrides.
- Command-Feedback exportiert einen read-only Authority-Snapshot fuer Reports und Verifier.

## Nicht-Ziele
- Kein neues Multiplayer-Transportprotokoll.
- Kein echter Zwei-Fenster-Manuallauf.
- Kein neuer Door-Gameplay-State im UI.
- Kein Rewrite des bestehenden Command-Contracts.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/multiplayer_authority_command_contract.md`
- `docs/dev/tactical_multiplayer_authority_snapshot.md`
- `docs/tasks/TASK_694_door_use_breach_command_hook.md`
- `docs/tasks/TASK_695_door_interaction_hud_button_shortcut.md`
- `docs/tasks/TASK_696_door_runtime_visual_animation_asset_swap.md`

## Akzeptanzkriterien
- Host/Authority akzeptiert den Door-Breach-Netzwerkcommand fuer das eigene Team.
- Ein Peer mit falschem Team wird fuer denselben Door-Command abgelehnt.
- Ein Payload, der Door-Runtime-State direkt setzen will, wird abgelehnt.
- Nach serverseitigem Runtime-Progress erzeugt der Door Runtime State Producer den offenen Override.
- Snapshot und Command-Feedback bleiben read-only und setzen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/mission_interaction_door_multiplayer_authority.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_697_door_interaction_multiplayer_authority_check.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_697_door_interaction_multiplayer_authority_check.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_696_door_runtime_visual_animation_asset_swap.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_166_multiplayer_authority_command_contract_verifier.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte menschliche Host/Client-Klicklauf bleibt separat offen.
- Der Snapshot beweist den technischen Authority-Pfad, nicht die Bedienbarkeit im Zwei-Fenster-Fensterlayout.
