# Rank and Particle Asset Inventory

Datum: 2026-05-06
Status: TASK_196 implementiert

## Zweck
Dieses Inventar beschreibt das kleine kuratierte Rank-/Role-Badge- und Particle-Subset. Beide Assetgruppen sind reine Anzeige. Gameplay-State, Health, Suppression, Damage, Heal, Objective-Fortschritt und Multiplayer-Authority bleiben in den bestehenden Runtime-Systemen.

## Quellen
| Source ID | Lokale Quelle | Projektpfad | Lizenz | Import |
| --- | --- | --- | --- | --- |
| `kenney_ranks_pack` | `%USERPROFILE%/Pictures/Sternenbuerger/kenney_ranks-pack` | `res://Assets/curated/kenney/ranks/` | Creative Commons Zero, CC0 | 10 PNG + `License.txt` |
| `kenney_particle_pack` | `%USERPROFILE%/Pictures/Sternenbuerger/kenney_particle-pack` | `res://Assets/curated/kenney/particles/` | Creative Commons Zero, CC0 | 12 transparente PNG + `License.txt` |

## Regeln
1. PNG-only, keine SVG/SWF/Unity-Package-Importe.
2. Strenger V1-Cap: maximal 12 Rank-PNGs und maximal 12 Particle-PNGs.
3. Alle Runtime-Referenzen nutzen `res://Assets/curated/kenney/...`.
4. Badges sind Rollen-/Status-Hinweise, keine Rollen- oder Health-Wahrheit.
5. Particles sind Visual-Feedback, keine SimulationRoot-Effects und keine Damage-/Heal-Logik.

## Badge IDs
| ID | Datei | Quelle | Zweck | Zielscreen |
| --- | --- | --- | --- | --- |
| `badge_role_ftl` | `res://Assets/curated/kenney/ranks/badge_role_ftl.png` | `PNG/Default size/Silver/rank000.png` | Fireteam-Leader-Lesbarkeit | NPC-Karten, #17 |
| `badge_role_medic` | `res://Assets/curated/kenney/ranks/badge_role_medic.png` | `PNG/Default size/Silver/rank007.png` | Medic-Lesbarkeit | NPC-Karten, #17 |
| `badge_role_rifle` | `res://Assets/curated/kenney/ranks/badge_role_rifle.png` | `PNG/Default size/Silver/rank014.png` | Rifle/Assault-Lesbarkeit | Mission-Map-Snapshots |
| `badge_role_heavy` | `res://Assets/curated/kenney/ranks/badge_role_heavy.png` | `PNG/Default size/Silver/rank021.png` | Heavy/Special-Lesbarkeit | Loadout, #17 |
| `badge_role_pilot` | `res://Assets/curated/kenney/ranks/badge_role_pilot.png` | `PNG/Default size/Silver/rank028.png` | Pilot-/Transport-Kontext | FOB Flightdeck |
| `badge_role_engineer` | `res://Assets/curated/kenney/ranks/badge_role_engineer.png` | `PNG/Default size/Silver/rank035.png` | Engineer-/Objective-Kontext | Objectives |
| `badge_role_enemy` | `res://Assets/curated/kenney/ranks/badge_role_enemy.png` | `PNG/Default size/Gold/rank042.png` | Enemy-Contact-Lesbarkeit | Mission Contacts |
| `badge_state_down` | `res://Assets/curated/kenney/ranks/badge_state_down.png` | `PNG/Default size/Black/rank049.png` | Down-State-Hinweis | NPC-Karten, #17 |
| `badge_state_ready` | `res://Assets/curated/kenney/ranks/badge_state_ready.png` | `PNG/Default size/Gold/rank056.png` | Ready-State-Hinweis | Homebase/FOB |
| `badge_state_suppressed` | `res://Assets/curated/kenney/ranks/badge_state_suppressed.png` | `PNG/Default size/Bronze/rank063.png` | Suppressed-Hinweis | Selected Fireteam |

## Particle IDs
| ID | Datei | Quelle | Zweck | Zielscreen |
| --- | --- | --- | --- | --- |
| `particle_lz_drop` | `res://Assets/curated/kenney/particles/particle_lz_drop.png` | `PNG (Transparent)/flare_01.png` | LZ-/Dropship-Visual | Mission Map |
| `particle_contact_ping` | `res://Assets/curated/kenney/particles/particle_contact_ping.png` | `PNG (Transparent)/spark_05.png` | Neuer Kontakt | Mission Contacts |
| `particle_suppression_smoke` | `res://Assets/curated/kenney/particles/particle_suppression_smoke.png` | `PNG (Transparent)/smoke_04.png` | Suppression-Feedback | Mission Status |
| `particle_objective_marker` | `res://Assets/curated/kenney/particles/particle_objective_marker.png` | `PNG (Transparent)/star_04.png` | Objective-Aufmerksamkeit | Objectives |
| `particle_hit_flash` | `res://Assets/curated/kenney/particles/particle_hit_flash.png` | `PNG (Transparent)/muzzle_01.png` | Hit-Feedback | Combat Visualizer |
| `particle_heal_pulse` | `res://Assets/curated/kenney/particles/particle_heal_pulse.png` | `PNG (Transparent)/magic_03.png` | Heal-Feedback | Medic Visualizer |
| `particle_warning_glow` | `res://Assets/curated/kenney/particles/particle_warning_glow.png` | `PNG (Transparent)/light_01.png` | Warnhinweis | Mission HUD |
| `particle_trace_line` | `res://Assets/curated/kenney/particles/particle_trace_line.png` | `PNG (Transparent)/trace_03.png` | Schusslinie/Trace | Combat Visualizer |
| `particle_fire_burst` | `res://Assets/curated/kenney/particles/particle_fire_burst.png` | `PNG (Transparent)/fire_01.png` | Impact-Burst | Combat Visualizer |
| `particle_dust_kick` | `res://Assets/curated/kenney/particles/particle_dust_kick.png` | `PNG (Transparent)/dirt_02.png` | Bewegung/Landung | Mission Map |
| `particle_scorch_mark` | `res://Assets/curated/kenney/particles/particle_scorch_mark.png` | `PNG (Transparent)/scorch_01.png` | temporärer Impact-Marker | Mission Map |
| `particle_command_ping` | `res://Assets/curated/kenney/particles/particle_command_ping.png` | `PNG (Transparent)/circle_04.png` | Command-Acknowledge | Command Feedback |

## Folgepfad
TASK_197 darf diese IDs in den zentralen kuratierten Asset-Katalog uebernehmen. Erst spaetere UI-/Visual-Slices verdrahten konkrete Verwendung in Controls oder Effekt-Layern.
