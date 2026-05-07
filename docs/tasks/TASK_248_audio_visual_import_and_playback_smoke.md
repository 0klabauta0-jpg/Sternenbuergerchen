# TASK_248 - Audio Visual Import and Playback Smoke

## Ziel
Die neuen Audio-, Background- und Visual-Asset-Pfade sollen in einem zusammenhaengenden Smoke getestet werden: Import, Resource-Ladung, Audio-Playback, UI-Klick, Schuss, Schritt, Explosion, Background-Anzeige und Missing-Asset-Diagnose.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_242 - Audio SFX Source Inventory and Curated Import
- TASK_243 - Audio Event Contract and Bus Setup
- TASK_244 - Combat Movement UI SFX Integration
- TASK_245 - Background Image Catalog and Screen Usage
- TASK_246 - Visual Scale Alignment Asset Pass
- TASK_247 - Used Asset Project Locality Audit Gate

## Kontext
Einzelne Katalog- und Verifier-Tasks koennen gruene Checks liefern, obwohl der erste echte Missions- oder Menuefluss noch fehlende Imports, falsche Pfade oder nicht abgespielte Events hat. Dieser Smoke ist bewusst praktisch: einmal laden, einmal ausloesen, Diagnose ansehen.

## Umfang
1. Godot-Import:
   - `--import` fuer neue Audio-, Bild-, Particle- und Model-Ressourcen.
   - Importfehler als harte Fehler.
2. Audio-Playback:
   - UI-click, combat shot, movement step, impact, explosion.
   - Settings-Mute und Volume-Multiplikator testen.
   - Fehlende IDs und fehlende Dateien zaehlen.
3. Visual-Load:
   - Background-Katalog laden.
   - Mindestens ein Menue-/Lobby-/Setup-Background instanziieren.
   - Muzzle-Flash/Particle-Resource laden.
   - NPC-/Weapon-Visuals aus TASK_246 weiter pruefen.
4. Mission-Snapshot:
   - Kleine Testmission oder Sandbox-Snapshot mit Friendly/Enemy.
   - Schuss, Schritt und Explosion ausloesen, ohne SimulationState durch Audio/Visuals zu veraendern.
5. Report:
   - Kurzer Smoke-Bericht mit Event-Zaehlern, fehlenden Ressourcen, aktiven Audio-Stimmen und geladenen Backgrounds.

## Nicht-Ziele
- Kein kompletter Performance-Pass; der folgt in TASK_249.
- Kein finaler Hoer-/Mix-Review.
- Kein vollstaendiger Multiplayer-Zwei-Client-Test.

## Akzeptanzkriterien
- [x] Godot importiert die neuen Ressourcen ohne Fehler.
- [x] Mindestens je ein UI-, Combat-, Movement-, Impact- und Explosion-Event wird erfolgreich abgespielt oder als headless-playbackfaehig validiert.
- [x] Backgrounds aus dem Katalog laden projektlokal.
- [x] Muzzle-Flash/Particle- und Weapon-/NPC-Visuals bleiben resource-loadfaehig.
- [x] Audio/Visual-Smoke mutiert keine Gameplay-Wahrheit.
- [x] Missing-Asset-/Missing-Audio-Zaehler stehen bei 0 oder sind begruendet dokumentiert.

## Erwartete Dateien
- `scripts/tests/task_248_audio_visual_import_and_playback_smoke.gd`
- `docs/reports/audio_visual_import_and_playback_smoke.md`
- `docs/tasks/TASK_248_audio_visual_import_and_playback_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_248_audio_visual_import_and_playback_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `git diff --check`

## Umsetzung
- `scripts/tests/task_248_audio_visual_import_and_playback_smoke.gd` fuehrt einen kombinierten Headless-Smoke fuer Import-Samples, Audio-Playback, Settings-Mute, Background-Instanzen, VFX/Weapon/NPC-Visuals, Mission-Snapshot, Movement-Step, Impact, Explosion und isolierte Missing-Diagnosen aus.
- `docs/reports/audio_visual_import_and_playback_smoke.md` dokumentiert Eventfamilien, geladene Visuals, Gameplay-Grenze und Missing-Diagnosen.
- Primaere Playback-Diagnosen bleiben bei 0 missing audio IDs und 0 missing audio resources; Missing-Probes laufen in isolierten Resolvern/Bussen.

## Risiken
- Headless-Audio kann Playback nur indirekt pruefen; ein manueller Hoercheck bleibt sinnvoll.
- Ein grosser Smoke lokalisiert Fehler schlechter als die Einzelverifier.
- Zu viele parallel geladene Backgrounds oder Sounds koennen erst in TASK_249 als Performance-Problem auffallen.

## Naechster Schritt
Nach TASK_248 fuehrt TASK_249 den Performance- und Optimierungs-Pass ueber die neuen Audio-/Visual-Pfade aus.
