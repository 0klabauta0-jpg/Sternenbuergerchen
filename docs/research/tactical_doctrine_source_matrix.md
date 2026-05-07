# Tactical Doctrine Source Matrix

Status: TASK_269

## Purpose
This matrix captures public doctrine and game-UX sources as inspiration for Sternenbuergerchen. It is a game abstraction, not a training guide, does not copy national doctrine into the game, and must not be used to describe real step-by-step combat procedures. In short: no real step-by-step combat procedures.

The output is a neutral game vocabulary for command intent, Fireteam Leader execution, controlled breakouts and readable player feedback.

## Source Matrix
| Source | Level Reviewed | Relevant Concepts | Game Abstraction | Do Not Adopt |
| --- | --- | --- | --- | --- |
| US Army ATP 3-21.8 Infantry Rifle Platoon and Squad, January 2024 / Change 1 2025. Official ArmyPubs PDF: https://armypubs.army.mil/epubs/DR_pubs/DR_a/ARN44065-ATP_3-21.8-001-WEB-3.pdf | Platoon, squad, team leaders. | Non-prescriptive doctrine, commander intent, subordinate leaders, fire control, movement, security, reporting, ROE awareness. | Commander sets intent and constraints. FTL owns route, tempo, security posture and contact response within those constraints. | No battle drills, no formation recipes, no real-world fire control procedures, no legal ROE modelling. |
| US Maneuver Center ATP 3-21.8 doctrine supplement: https://www.benning.army.mil/Infantry/DoctrineSupplement/ATP3-21.8/chapter_01/section_01/page_0010/index.html | Publication context and command chain. | Publication is a guide, not a prescriptive sequence; leaders plan, prepare, execute and assess. | Treat all doctrine as patterns for game states and feedback, not exact procedure. | No claim that the game teaches or represents US doctrine. |
| Bundeswehr Heer overview: https://www.bundeswehr.de/de/organisation/heer | Army-level public capability overview. | Combined arms cooperation, light forces, difficult terrain, urban and challenging terrain contexts. | Terrain, air mobility and support assets should be exposed as game constraints that change risk and tempo. | No national framing, no rank copy, no modern German task procedures. |
| Bundeswehr Truppengattungen PDF: https://www.bundeswehr.de/resource/blob/5102420/3c1af53099e8eba00ffabcb473c63ab6/truppengattungen-der-bundeswehr-data.pdf | Public branch overview for infantry types. | Jaeger, Fallschirmjaeger and Gebirgsjaeger emphasize light infantry, difficult terrain, mobility and protection tasks. | Convert into neutral roles: probe team, security team, support team, reserve team, LZ security. | No direct faction templates named after real forces. |
| Bundeswehr Karriere Gebirgsjaeger public role page: https://www.bundeswehrkarriere.de/soldatin-soldat-der-gebirgsjaegertruppe-398 | Individual role public page. | Teamwork, physical terrain challenge, difficult environment, broad infantry tasks. | Skills can affect FTL timing, cohesion, terrain adaptation and communication quality. | No career/training detail, no real qualification path. |
| Armee de Terre / CCF RFT 3.2.1 Precis de tactique generale: https://www.terre.defense.gouv.fr/ccf/nos-publications/documents-fondateurs/rft-321-precis-tactique-generale | General tactical thought and command levels. | Combined arms thinking, initiative, maneuver, action principles, adaptation to environment, theory as guide rather than fixed answer. | Make Sternenbuergerchen tactics about intent, effects, tempo, initiative and readable adaptation. | No French doctrine vocabulary as in-game labels, no tactical method reproduction. |
| Armee de Terre infantry overview: https://www.defense.gouv.fr/terre/armes/linfanterie | Public infantry role overview. | Infantry takes and controls terrain through close contact. | Objectives should read as secure/control/hold/probe rather than abstract capture meters only. | No real assault method, no population/contact doctrine. |
| 13e DBLE public page: https://www.terre.defense.gouv.fr/legion-etrangere/13e-demi-brigade-legion-etrangere | Public dismounted-combat and vehicle-supported role. | Dismounted combat after vehicle approach, contact zone, holding terrain, transport relationship. | Dropship/freighter insertion should create visible LZ security and transport-risk objectives. | No unit identity, no specific organization or procedures. |
| Bohemia Interactive Arma 3 Field Manual - Commanding: https://community.bohemia.net/wiki/Arma_3:_Field_Manual_-_Commanding | Game command UX. | Command categories, quick commands, combat mode, formation, team selection, command responses, current-order readout. | #16 should group verbs and rules. #17/#18 should show short responses like copy, cannot, adapting, complete. | No keyboard-menu cloning, no one-to-one Arma command tree. |
| Bohemia Interactive Arma 3 Field Manual - Infantry Controls: https://community.bohemia.net/wiki/Arma_3:_Field_Manual_-_Infantry_Controls | Game movement and posture UX. | Stance, cover, combat pace, slow/fast movement and player-readable body states. | Tactical rules become compact game toggles: tempo, stance, spread, security, contact response. | No simulation of body controls or per-NPC micromanagement. |

## Neutralization Rules
- Do not use national force names as in-game role labels.
- Convert doctrine terms into purpose-first game labels: `secure`, `probe`, `support`, `hold`, `advance`, `withdraw`.
- Keep command text short and fictional. The player commands small space teams, not real units.
- Avoid legal or political terms. The game uses `fire_rule`, not real ROE.
- Avoid step-by-step real procedures. Only represent game state, intent, risk and feedback.

## Useful Design Signals
| Signal | Cross-Source Pattern | Sternenbuergerchen Use |
| --- | --- | --- |
| Intent beats micromanagement | Sources separate leader intent from subordinate execution. | Commander gives goal, priority and constraints; FTL resolves execution. |
| Terrain matters | German and French public sources emphasize environment and combined effects; US source treats terrain and enemy as variable. | Terrain, cover, hills, LZs and air threats alter FTL plan quality and risk. |
| Initiative is bounded | Leaders adapt, but within rules and mission purpose. | FTL can auto-adapt for low-risk issues, must report or request orders for high-risk changes. |
| Feedback is critical | Arma shows current order, health, ammo, behavior and responses. | #17/#18, map markers and bubbles need short status labels, not doctrine prose. |
| Transport changes the fight | French dismounted/vehicle approach and current game dropships point to LZ security. | Air assets become tactical context in TASK_277/TASK_279, not just set dressing. |

## Not Used As Source
- Classified, restricted, or training-only material.
- Community claims without clear provenance.
- Real tactical drills, weapon employment details, or live-procedure checklists.
- Direct national organization charts or rank structures.

## Follow-Up Links
- TASK_270 turns this source review into the CommanderIntent -> FireteamExecutionPlan -> UnitAction contract.
- TASK_271 defines game-safe tactical rules and fire rules.
- TASK_272 adds multi-fireteam coordinated plans.
- TASK_273 uses FTL skill as execution quality, timing and communication.
- TASK_274 turns status and reports into bubbles/radio feedback.
- TASK_276 defines breakout and exception behavior.
- TASK_277 to TASK_279 cover air-asset risk, LZ security and recovery loops.
- TASK_280 and TASK_281 cover editor authoring and multiplayer snapshots.
- TASK_282 closes the tactical-overhaul playability/performance/help gate.
