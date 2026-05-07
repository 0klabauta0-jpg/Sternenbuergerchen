# Command, Mission, Editor and Settings Help Copy

## Purpose
TASK_266 expands contextual help for command-heavy and authoring-heavy screens without adding tutorial UI or gameplay state. Every visible help target uses stable `help_id` metadata and resolves text from `data/contextual_help_catalog.json`.

## Mission IDs
- `mission.command_matrix`, `mission.selected_fireteam`, `mission.mission_control`
- `mission.command.move`, `mission.command.defend`, `mission.command.hold`, `mission.command.flank`, `mission.command.take`
- `mission.command.attack_area`, `mission.command.defend_area`, `mission.command.area_order`
- `mission.command.go_plan`, `mission.command.stance`, `mission.command.advance_style`
- `mission.command.overwatch`, `mission.command.security`, `mission.command.medic_adjacent`
- `mission.command.set_lz`, `mission.command.call_dropship`, `mission.command.approach`, `mission.command.clear_target`

## Settings IDs
- `settings.display`, `settings.audio`, `settings.input`, `settings.gameplay`
- `settings.fog_of_war_mode`
- `settings.fog_of_war.off`, `settings.fog_of_war.known_terrain`, `settings.fog_of_war.unexplored_blackout`
- `settings.contextual_help_mode`

## Multiplayer IDs
- `multiplayer.host`, `multiplayer.join`, `multiplayer.ready`, `multiplayer.start`
- `multiplayer.disconnect`, `multiplayer.map_download`, `multiplayer.roster_ownership`
- Existing compatibility ID: `multiplayer_lobby.host_join`

## Editor IDs
- `editor.tile_palette`, `editor.brush_size`, `editor.height_tool`
- `editor.edge.slope`, `editor.edge.cliff`, `editor.surface`, `editor.object`
- `editor.save`, `editor.load`, `editor.save_as`, `editor.playtest`
- `editor.back` is intentionally `todo` until the editor exposes a visible back route.
- Existing compatibility IDs: `map_editor.height_tool`, `map_editor.save_load`

## Source Rules
- Mission help may name command intent, but command execution remains in the existing tactical controller, command data and SimulationRoot paths.
- FoW help must refer to the FoW contract and runtime visibility, not UI-owned visibility truth.
- Lobby help may describe session, map consent and roster ownership, but cannot bypass host/server authority.
- Editor help may describe terrain and scenario authoring, but save/load, manifest and live-test behavior remain in their existing editor contracts.

## Copy Rules
- Compact copy answers what the control does in one to three short lines.
- Detail copy explains when to use it or which runtime boundary owns the result.
- Button text stays short; long explanations stay in the catalog.
- Help text must not contain local filesystem paths.

## Todo Coverage
| Help ID | Reason | Follow-up |
| --- | --- | --- |
| `editor.back` | The editor scene has no visible Back button yet. | Add a route/control or keep the coverage exception explicit. |
| `mission.command.roe_fire_rules` | ROE/fire-rule controls are planned for the tactical overhaul. | TASK_271 should provide ready copy and UI targets. |
