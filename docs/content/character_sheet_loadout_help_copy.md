# Character Sheet and Loadout Help Copy

## Purpose
This copy pass adds player-facing contextual help for character sheets and loadout editing. The text explains where values come from and what they are useful for without becoming a second balance document.

## Character Sheet IDs
Primary sections:
- `character_sheet.identity`
- `character_sheet.role_loadout`
- `character_sheet.traits`
- `character_sheet.status_recovery`
- `character_sheet.teamfit`
- `character_sheet.progression`
- `character_sheet.core_values`
- `character_sheet.communication`
- `character_sheet.platform_skills`
- `character_sheet.derived_badges`
- `character_sheet.behavior_profile`

Important row IDs:
- `character_sheet.role`
- `character_sheet.fireteam_assignment`
- `character_sheet.loadout_summary`
- `character_sheet.rank_badges`
- `character_sheet.status`
- `character_sheet.recovery`
- `character_sheet.morale`
- `character_sheet.frustration`
- `character_sheet.xp`
- `character_sheet.core.accuracy`
- `character_sheet.core.speed`
- `character_sheet.core.toughness`
- `character_sheet.core.awareness`
- `character_sheet.core.recognition`
- `character_sheet.core.stealth`
- `character_sheet.core.discipline`
- `character_sheet.core.leadership`

## Loadout IDs
Primary controls:
- `loadout.member_row`
- `loadout.armor`
- `loadout.weapon_slot`
- `loadout.weight`
- `loadout.weapon_preview`
- `loadout.weapon_none`
- `loadout.clear_selection`
- `loadout.empty_team_default`

Weapon help:
- `loadout.weapon.smg`
- `loadout.weapon.rifle`
- `loadout.weapon.sniper`
- `loadout.weapon.rocket_launcher`
- `loadout.weapon.medictool`
- `loadout.weapon.none`
- `loadout.weapon.lmg`
- `loadout.weapon_visual_only`
- `loadout.disabled_reason`

## Source Rules
- Character identity, traits, status, progression, relationships and skills come from `MetaUnitProfile`.
- Rank badges come from `NPCRankBadgeResolver`.
- Weapon names, attack classification, ranges and weights come from `WeaponData`.
- Combined loadout weight comes from `LoadoutModifierResolver`.
- The sheet and FOB loadout UI attach `help_id` metadata only; they do not calculate gameplay truth.

## Copy Rules
- Compact text stays at one to three lines.
- Detail text names the source or effect boundary.
- Visual-only weapon assets are described as presentation and not selectable gameplay items.
- "No Weapon" is explicit: zero weapon weight and no hidden fallback weapon.
- LMG is marked planned until `WeaponData` defines a real gameplay entry.
