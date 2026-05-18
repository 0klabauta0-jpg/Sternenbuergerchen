# TASK 474: Fireteam Down VFX Performance Stabilization

## Ziel / Problem

Der Fireteam-Drill ist nach TASK_473 funktionaler, aber im sichtbaren Playtest noch zu schwer lesbar: Down-/Respawn-Zustaende wechseln optisch zu schnell in `RESPAWN`, Muzzle-Flash wird nicht als kurzer Schussimpuls erkannt, und bei Feuerkontakt bricht die Performance ein.

## Sinnhaftigkeit / Ursache

- Downed Units werden im CombatLoop sofort in Bleedout/Respawn weitergeschoben. Dadurch bleibt kaum Zeit, die Down-Pose wahrzunehmen.
- `respawning` wird visuell wieder aufrecht dargestellt, obwohl der Respawn-Timer noch laeuft.
- Das 3D-Order-Overlay baut bei Fire-Events grosse Payload-Signaturen und Visuals zu haeufig neu auf.
- Der aktuelle Muzzle-Impuls ist so klein/nah an Trace und Modell, dass er im Godot-Fenster kaum auffaellt.

## Umfang

- Down-State fuer ein kurzes Mindestfenster sichtbar halten, bevor Bleedout/Respawn startet.
- Respawning-Units bis zum echten Respawn weiterhin als down/liegend darstellen.
- Muzzle-Feedback als kleinen, hellen Stern/Impuls am Waffenpunkt sichtbar machen, ohne wieder grosse Flaechen zu erzeugen.
- Combat-Visual-Sync throttlen und Signaturen fuer dynamische Fire-/Bubble-/Communication-Listen begrenzen.
- Verifier fuer Down-Linger, Respawn-Pose, VFX-Lesbarkeit und Visual-Sync-Throttle ergaenzen.

## Nicht-Ziele

- Keine finale Medic-Rolle.
- Keine finale Death-/Ragdoll-Animation.
- Keine neue Combat-Balance.
- Keine komplette Renderarchitektur.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_473_fireteam_combat_feedback_runtime_overhaul.md`
- `docs/tasks/TASK_472_fireteam_contact_perf_bubble_card_readability.md`
- `docs/tasks/TASK_471_fireteam_weapon_fire_vfx_hit_feedback_perf.md`

## Akzeptanzkriterien

- Eine Unit bleibt nach `down` mindestens ein paar Sekunden im Down-/Liege-Visual, bevor Respawn startet.
- `respawning` zeigt im 3D-Proxy weiterhin eine Down-Pose und einen Respawn-Countdown, bis die echte Respawn-Effect-Position angewendet wird.
- Weapon-Fire-VFX enthaelt einen sichtbaren kurzen Muzzle-Flare und bleibt trotzdem gecappt.
- Wiederholte Combat-Visual-Refreshes werden gebuendelt statt mehrfach pro Tick/Schuss den kompletten 3D-Order-Layer neu aufzubauen.
- `git diff --check` und ein TASK_474-Verifier laufen sauber.

## Betroffene Dateien

- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/npc/test_unit.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_474_fireteam_down_vfx_performance_stabilization.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_474_fireteam_down_vfx_performance_stabilization.gd`
- Relevante TASK_471/TASK_472/TASK_473-Regressionen.
- `git diff --check`.

## Risiken / offene Punkte

- Das Mindest-Down-Fenster ist ein Playtest-/Lesbarkeitswert. Die finale Respawn-Kette kann spaeter nach Gameplay-Tuning laenger oder kuerzer werden.
- Das VFX bleibt ein Debug-/Prototype-Feedback. Ein spaeterer Art-Pass sollte echte Muzzle-/Impact-Particles ersetzen.
