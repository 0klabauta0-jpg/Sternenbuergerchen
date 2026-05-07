# Playability Coverage Matrix

## Purpose
This matrix defines which player-facing screens, routes, buttons, fixed windows, overflow areas and state transitions must be covered by automated playability checks. It separates hard automation from manual judgement so future tasks can add coverage without hiding open risks.

## Status Values
| Status | Meaning |
| --- | --- |
| `automated` | Covered by a headless verifier or shared harness check. |
| `manual` | Requires a visible Godot/editor play check. |
| `blocked` | Cannot be checked until a named prerequisite exists. |
| `not_applicable` | Deliberately out of scope for this screen. |

## Screen Coverage
| Screen ID | Surface | Required Buttons / Inputs | Required Windows / Areas | Required Routes / State | Status | Current Coverage |
| --- | --- | --- | --- | --- | --- | --- |
| `main_menu` | Main Menu Shell | Singleplayer, Multiplayer, Editor, Settings, New Roster | Menu rail, background, status line | Routes expose scene metadata; settings opens locally; roster reset needs confirmation | `automated` | TASK_199, TASK_226, TASK_232, TASK_250 |
| `settings` | Main Menu Settings Panel | Apply, Reset, Cancel, option controls, sliders, toggles | Display, Audio, Input, Gameplay sections | Apply persists draft; Cancel discards draft; Reset restores defaults | `automated` | TASK_226, TASK_223, TASK_211 |
| `singleplayer_setup` | App shell to Meta Layer | Start/continue route, roster creation, mission setup route | Shell handoff area, status feedback | Main menu to meta flow keeps generated roster available | `automated` | TASK_231, TASK_241, TASK_261 |
| `multiplayer_lobby` | Host / Join Lobby | Host, Join, Ready, Start Mission, Disconnect, Back, roster mode, map accept/reject | Lobby panel, host/join grid, session row, map consent panel | Host/client ready flow; unknown map requires consent; back returns to main menu | `automated` | TASK_227, TASK_228, TASK_240 |
| `map_editor` | Map Editor | Palette, paint tools, height tools, save/load, mission config controls | Palette panel, map viewport, property/editor panels, scrollable config areas | Editor save/load roundtrip; map manifest handoff; fixed controls reachable | `automated` | TASK_183, TASK_229 |
| `homebase` | Homebase Meta Screen | Navigation, roster/team transfer actions, character sheet focus, flightdeck read actions | Topbar, Mission Brief, Roster, Transfer Team, Flightdeck, Character Sheet | Roster selection and transfer staging survive screen refresh | `automated` | TASK_179, TASK_241 |
| `fob` | FOB Meta Screen | Fireteam selection, Board, Send, loadout selectors, disabled template actions | Topbar, Fireteams, Loadout, Flightdeck, Boarding Status, Actions | Board/Send keep existing callbacks; disabled template buttons stay non-authoritative | `automated` | TASK_178, TASK_181, TASK_176 |
| `character_sheet` | Character Sheet / Roster Profile | Close/back, roster switch, loadout/profile tabs where present | Sheet body, stat blocks, relationship/progression sections | Switching units must not drop selected roster state | `automated` | TASK_235, TASK_241, TASK_259, TASK_260, TASK_261 |
| `loadout` | FOB / Character Loadout | SMG, Medictool, role slots, preview selectors, None | Fixed `#13 LOADOUT`, preview slots, member rows | Decorative weapon previews do not mutate combat truth; weight remains consistent | `automated` | TASK_176, TASK_190, TASK_260 |
| `mission_hud` | Mission HUD | Command Matrix, LZ/drop controls, phase/order controls, selected fireteam actions | Mission Identity, Topnav, BottomDock, `#16`, `#17`, `#18` | HUD issues commands through existing controllers; no direct SimulationRoot state writes | `automated` | TASK_180, TASK_188, TASK_191 |
| `debrief` | Debrief / Mission Result | Continue/back, roster/result acknowledgement where present | Result summary, XP/morale/frustration changes | Mission result returns to meta layer without losing roster progression | `automated` | TASK_237, TASK_241, TASK_259, TASK_261 |

## Flow Contract
| Flow ID | Required Path | Preserved State | Status |
| --- | --- | --- | --- |
| `flow_main_to_settings` | Main Menu -> Settings -> Cancel/Apply -> Main Menu | Draft settings do not leak on cancel; applied settings persist | `automated` |
| `flow_main_to_multiplayer_lobby` | Main Menu -> Multiplayer Lobby -> Back | Main menu route metadata and lobby back path remain valid | `automated` |
| `flow_host_join_ready` | Lobby host/join -> ready -> start mission request | Session snapshot, roster authority and map consent state remain explicit | `automated` |
| `flow_main_to_meta_to_fob` | Main Menu -> Meta Layer -> FOB | Generated roster and fireteam assignment survive screen transitions | `automated` |
| `flow_fob_to_mission_to_debrief` | FOB -> Mission HUD -> Debrief -> Homebase/FOB | Mission result, XP, morale/frustration and roster state survive return | `automated` |
| `flow_editor_to_lobby_map_transfer` | Editor save -> multiplayer manifest -> consent/download | Map manifest hash/version and user consent remain explicit | `automated` |

## Contextual Help Coverage
| Help Area ID | Surface | Required Contract | Status | Current Coverage |
| --- | --- | --- | --- | --- |
| `main_menu.primary_routes` | Main Menu Shell | Compact route help; no saved-state mutation from help. | `automated` | TASK_263 |
| `settings.contextual_help_mode` | Settings Panel | Off/compact/expanded modes documented and visual-only. | `automated` | TASK_263 |
| `settings.fog_of_war_mode` | Settings Panel | Help references FoW contract, not UI-side visibility truth. | `automated` | TASK_263 |
| `shell.global_help_button` | App Shell / HUD | Small global help button with stable `help_id`. | `automated` | TASK_263 |
| `help_global_button` | App Shell / HUD | Toggle contract for current-screen help inspection. | `automated` | TASK_263 |
| `homebase.roster` | Homebase Roster | Roster help explains selection without duplicating roster state. | `automated` | TASK_263 |
| `homebase.transfer_team` | Homebase Transfer Team | Transfer help stays read-only until existing flow confirms. | `automated` | TASK_263 |
| `fob.fireteams` | FOB Fireteams | Fireteam help preserves stable unit IDs and order. | `automated` | TASK_263 |
| `fob.flightdeck` | FOB Flightdeck | Craft and pad help are visual/read-only. | `automated` | TASK_263 |
| `loadout.weight` | FOB / Character Loadout | Weight help points to loadout resolver and weapon data. | `automated` | TASK_263 |
| `character_sheet.core_values` | Character Sheet | Character values come from roster/profile data. | `automated` | TASK_263 |
| `mission_hud.command_matrix` | Mission HUD | Command help routes through existing command controllers. | `automated` | TASK_263 |
| `mission_hud.mission_control` | Mission HUD | Help must not cover active command buttons when avoidable. | `automated` | TASK_263 |
| `mission.command.*` | Mission HUD | Move, defend/hold, take, area orders, GO, stance, advance, security, overwatch and medic rule help. | `automated` | TASK_266 |
| `map_editor.height_tool` | Map Editor | Height help follows terrain hill rules and save/load truth. | `automated` | TASK_263 |
| `map_editor.save_load` | Map Editor | Save/load help keeps map manifest consent explicit. | `automated` | TASK_263 |
| `editor.*` | Map Editor | Palette, brush, height, slope, cliff, surface, object, save/load and playtest help. | `automated` | TASK_266 |
| `editor.back` | Map Editor | Back-route help is tracked as `todo` until a visible Back control exists. | `manual` | TASK_266 |
| `multiplayer_lobby.host_join` | Multiplayer Lobby | Lobby help explains host/join without bypassing authority. | `automated` | TASK_263 |
| `multiplayer.*` | Multiplayer Lobby | Host, join, ready, start, disconnect, map download and roster ownership help. | `automated` | TASK_266 |
| `settings.display_audio_input_gameplay` | Settings Panel | Display, audio, input and gameplay settings have compact help. | `automated` | TASK_266 |
| `settings.fog_of_war.*` | Settings Panel | FoW mode copy explains off, known terrain and blackout behavior. | `automated` | TASK_266 |
| `debrief.character_updates` | Debrief | Debrief help reads applied progression only. | `automated` | TASK_263 |
| `mission.command.roe_fire_rules` | Mission HUD | ROE/fire-rule help remains `todo` until TASK_271 adds visible controls. | `manual` | TASK_266 |
| `help_catalog_schema` | Help Data | Catalog schema, required fields, IDs and length limits. | `automated` | TASK_263 |
| `help_timing_contract` | Help Overlay | Compact/detail delays and focus fallback documented. | `automated` | TASK_263 |
| `help_layout_contract` | Help Overlay | Max width, viewport clamp and overflow behavior documented. | `automated` | TASK_263 |
| `help_coverage_layout_gate` | Help Overlay | Visible `help_id` coverage, catalog text limits, popup clamping, timing modes and global help button behavior. | `automated` | TASK_267 |

## Layout Contract
| Check ID | Rule | Status |
| --- | --- | --- |
| `layout_fixed_windows` | Drop Light fixed windows must match their contract rectangles at Full HD. | `automated` |
| `layout_button_reachability` | Visible enabled buttons must be inside the viewport or a reachable ScrollContainer. | `automated` |
| `layout_scroll_overflow` | Long lists require a ScrollContainer or a documented fixed-size overflow rule. | `automated` |
| `layout_text_clipping` | Critical button text and primary labels must not be clipped. | `manual` |
| `layout_visual_feel` | Final art scale, readability and player comfort require visible inspection. | `manual` |

## Harness Contract
The shared harness lives at `scripts/tests/playability/playability_test_harness.gd` and must provide:
- screen instantiation helpers for PackedScene paths;
- button discovery by node name, visible text, `action_id`, route or icon metadata;
- button descriptors with enabled/visible/callback state;
- safe test pressing that rejects missing, hidden or disabled buttons;
- layout helpers for viewport bounds, fixed rectangles, clipping and ScrollContainer discovery;
- report helpers that separate hard failures, warnings and manual items.

## Report Format
Future playability verifiers should report:
- `screen_id`;
- failed required control IDs;
- dead or disabled buttons that should be active;
- clipped controls and missing ScrollContainers;
- route/state preservation failures;
- manual checks still required.

## Maintenance Rules
- New screens, visible primary buttons or player routes must add or update a matrix row.
- A check may be `manual`, but it must name what a human should inspect.
- UI tests may click existing UI callbacks, but must not invent gameplay truth or mutate `SimulationRoot` state directly.
- Follow-up tasks should reuse the shared harness instead of copying recursive NodeTree scans.

## Gate Coverage Summary
| Gate Task | Coverage Area | Status | Hard Failure Rule |
| --- | --- | --- | --- |
| TASK_256 | Harness and matrix contract | `automated` | Missing/invalid matrix or harness helper exits non-zero. |
| TASK_257 | Button reachability | `automated` | Missing, hidden, disabled, covered or disconnected required button exits non-zero. |
| TASK_258 | Fixed windows, clipping and scrollbars | `automated` | Fixed-window mismatch or critical overflow exits non-zero. |
| TASK_259 | Character card and roster switching | `automated` | Lost unit, stale card identity or broken transfer exits non-zero. |
| TASK_260 | Loadout, decorative weapons and weight | `automated` | Visual-only selectable weapon, hidden active weapon or inconsistent weight exits non-zero. |
| TASK_261 | Cross-screen state loss | `automated` | Lost roster IDs, stale settings, duplicate start/audio event or broken return path exits non-zero. |
| TASK_267 | Contextual help coverage/layout gate | `automated` | Missing visible help IDs, missing catalog entries, bad text limits, popup overflow or wrong help timing exits non-zero. |
| TASK_268 | Post-help playability smoke | `automated` | Help off/compact/expanded causing blocked controls, moved fixed windows or broken report links exits non-zero. |
