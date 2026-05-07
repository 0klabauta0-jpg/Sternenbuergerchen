# Audio SFX Inventory and Curated Import

## Source
Local source: `%USERPROFILE%/Pictures/Kenney Game Assets All-in-1 3.4.0/Audio`

All checked packs include `License.txt` with Creative Commons Zero (CC0). License copies for the imported packs are stored under `Assets/used/audio/kenney_all_in_one/licenses/`.

## Source Inventory
| Pack | OGG count | License | Decision |
|---|---:|---|---|
| Casino Audio | 55 | CC0 | Not imported; card/chip sounds are not planned gameplay feedback. |
| Digital Audio | 62 | CC0 | Small combat zap candidate imported. |
| Foley Sounds | 85 | CC0 | Rock-step placeholders imported from rocks subset. |
| Impact Sounds | 130 | CC0 | Footsteps and impact candidates imported. |
| Interface Sounds | 100 | CC0 | Confirm/cancel/warning UI candidates imported. |
| Music Jingles | 85 | CC0 | Not imported; music is out of scope. |
| Music Loops | 29 | CC0 | Not imported; loops are out of scope. |
| Retro Sounds 1 | 34 | CC0 | Not imported for this slice. |
| Retro Sounds 2 | 65 | CC0 | Not imported for this slice. |
| RPG Audio | 51 | CC0 | Reviewed; no import for sci-fi V1 subset. |
| Sci-Fi Sounds | 73 | CC0 | Laser, explosion and short ambient candidates imported. |
| Synth Voice 1 | 100 | CC0 | Not imported; voice packs are out of scope. |
| Synth Voice 2 | 225 | CC0 | Not imported; voice packs are out of scope. |
| UI Audio | 51 | CC0 | Click, hover and switch imported. |
| Voiceover Pack | 94 | CC0 | Not imported; voiceover is out of scope. |
| Voiceover Pack Fighter | 47 | CC0 | Not imported; voiceover is out of scope. |

Existing project UI sounds remain available under `Assets/kenney_ui-pack/Sounds/`, but TASK_242 catalogues the new All-in-1 subset under `Assets/used/audio/kenney_all_in_one/`.

## Imported Subset
Target root: `Assets/used/audio/kenney_all_in_one/`

| Category | Imported files | Planned use |
|---|---:|---|
| `ui` | 6 | click, hover, confirm, cancel, switch, warning |
| `combat` | 6 | blaster, SMG laser, sniper zap, heavy laser |
| `movement` | 6 | neutral steps, soft/sand placeholder, rock placeholder |
| `impact` | 5 | generic and metal impact variants |
| `explosion` | 3 | small crunch and larger low-frequency explosion |
| `ambient_short` | 3 | short terminal, forcefield and thruster cues |

## Catalog
`data/audio_sfx_catalog.json` contains stable `audio_id` values, category, planned event, `res://` project path, source pack/file, duration, loop flag, default volume and pitch-randomization guidance.

## Import Rules
- Runtime data uses only `res://` project paths.
- No `%USERPROFILE%`, `C:/Users`, `file://` or source-folder paths are allowed in runtime data.
- Short one-shots use `import_hint = sample`.
- Five-second short ambiences use `import_hint = stream`, not music-loop treatment.
- Music, long voiceover and full pack imports are explicitly out of scope.

## Known Placeholders
- The source has no dedicated sand footsteps in the reviewed packs. `footstep_snow_*` is marked as a temporary soft/sand placeholder.
- Rock steps use short rock-hit foley placeholders until a dedicated movement set is selected.
- No code hooks are added in TASK_242; TASK_243/TASK_244 will decide event routing and playback.
