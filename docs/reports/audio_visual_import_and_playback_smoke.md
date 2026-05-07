# Audio Visual Import and Playback Smoke

Datum: 2026-05-07
Status: TASK_248 Smoke implementiert

## Ergebnis
Der Smoke prueft importierte Audio-, Background-, Particle-, UI-, NPC- und Weapon-Visual-Samples gemeinsam. Headless-Audio wird indirekt ueber `AudioEventBus`-Playback-Resultate, Player-Pool-Diagnosen und Event-Zaehler validiert.

Lokaler Lauf:
- `godot_console.exe --headless --path . --import` lief ohne Fehler.
- `task_248_audio_visual_import_and_playback_smoke.gd`: 93 Checks, 0 Fehler.
- `task_160_tactical_playability_verifier.gd`: 20 Checks, 0 Fehler.

## Playback Events
- UI click: `ui_click` wird ueber `emit_ui_action("click")` abgespielt.
- Combat shot: `combat_sniper_shot` wird ueber `emit_weapon_fire("sniper")` abgespielt.
- Movement step: `movement_footstep_rock` und ein Missionsschritt auf Sand werden abgespielt.
- Impact: `impact_metal_heavy` wird ueber Bus und Mission-Driver getestet.
- Explosion: `explosion_large` wird ueber Bus und Rocket-Impact getestet.

## Visual Loads
- Backgrounds: `main_menu_shell` und `multiplayer_lobby_hangar` werden per `BackgroundImageCatalog` geladen und in ihren Szenen instanziiert.
- Muzzle/Particles: `muzzle_flash_05` und kuratierte Particle-/UI-Samples bleiben `ResourceLoader`-sichtbar.
- NPC/Weapon visuals: `characterMedium.fbx`, Sniper-GLB und Rocket-Launcher-GLB besitzen Import-Metadaten und bleiben loadfaehig.

## Gameplay Boundary
- Snapshot-Fire-Events erzeugen read-only Shot-Audio und Muzzle-VFX.
- Bewegungsschritt, Impact und Explosion laufen ueber bestehende Audio-/Visual-Hooks.
- `SimulationRoot.command_queue` und `SimulationRoot.effects_queue` bleiben im Smoke unveraendert.

## Missing Diagnostics
Missing probes are isolated:
- Ein separater AudioBus prueft `missing_audio_id`, ohne die primaeren Playback-Zaehler zu verschmutzen.
- Ein fehlender Background-ID-Probe liefert `missing_background_id`.
- Ein fehlender Curated-Asset-Probe liefert eine Resolver-Diagnose.
- Primaere Playback-Diagnosen melden 0 missing audio IDs und 0 missing audio resources.

## Follow-Up
TASK_249 misst danach die Performance-Wirkung von Audio-Polyphony, Resource-Load, Background-VRAM und VFX-Stutter.
