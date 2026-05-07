# Asset Audio Background Playability Smoke

Stand: 2026-05-07
Status: TASK_250 implementiert

## Ziel
Dieser Abschluss-Smoke verbindet Main menu, Settings, Multiplayer-Lobby, Mission-Visuals, Button sounds, Movement, Impact, Explosion, Backgrounds, FoW-Sichtbarkeit, Projektlokalitaet und Performance-Gates in einem pruefbaren End-to-End-Paket.

## Headless Smoke
- Main menu: Routen zu Singleplayer, Multiplayer, Editor und Settings bleiben vorhanden; Background und feste Full-HD-Schiene bleiben stabil.
- Settings: Audio-Werte werden gespeichert; UI-Klick und UI-Bestaetigung laufen ueber `AudioEventBus`.
- Multiplayer: Host-/Join-Flaechen bleiben erreichbar; die Lobby dupliziert ohne Aktion keine Audio-Events; Host-ready Start erzeugt genau eine Mission-Start-Anfrage.
- Mission: Friendly/Enemy-Registry, Unit-Proxies, Visual-Loadouts, Weapon-Attachments, Muzzle-Flash, Schuss-SFX, Movement-Step, Impact und Explosion werden in einer kleinen Mission geprueft.
- FoW: Ein sichtbares Fire-Event erzeugt VFX/SFX; ein verstecktes Fire-Event bleibt ausgeblendet.
- Backgrounds: Katalogpfade bleiben `res://`, screen-on-demand und unter dem UI-Texturbudget.

## Abschlussgates
- TASK_247 prueft Projektlokalitaet und externe Pfadreste.
- TASK_249 prueft Audio-/Visual-Performance nach Background-, VFX- und SFX-Integration.
- `git diff --check` bleibt der abschliessende Whitespace-/Patch-Gate.

## Lokaler Lauf
- `task_250_asset_audio_background_playability_smoke.gd`: 102/0.
- `task_247_used_asset_project_locality_audit_gate.gd`: 27/0.
- `task_249_post_audio_visual_performance_optimization_pass.gd`: 39/0.
- `git diff --check`: sauber.

## Manuell Offen
- Manueller Hoer-/Sichtcheck nach `docs/manual_checks/asset_audio_background_playability_checklist.md`.
- Finaler Mix, Background-Lesbarkeit und Attachment-Sitz brauchen weiterhin Augen/Ohren im laufenden Godot-Fenster.
