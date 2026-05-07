# TASK_249 - Post Audio Visual Performance Optimization Pass

## Ziel
Nach Audio-, Background-, Particle- und Alignment-Integration soll ein erneuter Performance-Test pruefen, ob Projektgroesse, Startzeit, Framezeit, VRAM, Audio-Polyphony, Node-Anzahl und Resource-Ladeverhalten noch sauber sind.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_220 - Asset Import VRAM Shader Pipeline Stutter Pass
- TASK_222 - Performance Regression Gate and Manual Profile Checklist
- TASK_244 - Combat Movement UI SFX Integration
- TASK_245 - Background Image Catalog and Screen Usage
- TASK_248 - Audio Visual Import and Playback Smoke

## Kontext
Mehr Sounds, groessere Backgrounds, Particles und weitere Visual-Assets koennen unauffaellig Stutter, Speicherverbrauch oder laengere Ladezeiten erzeugen. Dieser Task ist der bewusste Nachlauf: messen, dokumentieren, optimieren, Budget aktualisieren.

## Umfang
1. Baseline wiederholen:
   - TASK_222-Gate erneut laufen lassen.
   - Vergleich gegen letzte bekannte Budgetwerte.
   - Abweichungen nach Bereich markieren.
2. Audio-Performance:
   - Aktive Stimmen und Polyphony-Limits.
   - AudioStreamPlayer-Poolgroesse.
   - One-Shot vs Stream-Entscheidungen pruefen.
   - Schritt-/Schuss-Spam in NPC-Szenen messen.
3. Background-/Texture-Performance:
   - Import-Compression, Max-Size, VRAM.
   - Startbildschirm, Lobby, Mission-Select, Loading/Debrief.
   - Keine parallele Vorladung ungenutzter Backgrounds.
4. VFX-/Particle-Performance:
   - Muzzle-Flash und Explosionen mit Gegnergruppen.
   - Node-/Draw-/Materialkosten beobachten.
   - Pooling oder Debounce anwenden, falls noetig.
5. Resource-Ladeverhalten:
   - Erstmaliges Schiessen/Explodieren darf nicht sichtbar stuttern.
   - Prewarm nur fuer kleine, haeufige Ressourcen.
   - Grosse Assets lazy oder screen-bezogen laden.
6. Optimierungsbericht:
   - Vorher/Nachher-Werte.
   - Budget-Anpassungen nur mit Begruendung.
   - Godot-Profiler-Checkliste aus TASK_222 nachziehen.

## Nicht-Ziele
- Kein genereller Rewrite der Render- oder Audioarchitektur.
- Keine finale Plattformoptimierung.
- Kein CI-Ausbau, falls nicht bereits vorhanden.

## Akzeptanzkriterien
- [x] TASK_222-Performance-Gate laeuft nach Audio-/Visual-Integration.
- [x] Audio-Polyphony, Player-Pools und Event-Spam sind gemessen und begrenzt.
- [x] Background-Texturen sind in VRAM/Startzeit vertretbar.
- [x] Muzzle-Flash-/Explosion-VFX verursachen keine bekannten Stutter-Regressionen.
- [x] `docs/performance/audio_visual_performance_report.md` enthaelt Vorher/Nachher und Optimierungen.
- [x] Budgetaenderungen sind begruendet oder bleiben unveraendert.

## Erwartete Dateien
- `docs/performance/audio_visual_performance_report.md`
- `data/performance_budget_contract.json`
- `scripts/tests/task_249_post_audio_visual_performance_optimization_pass.gd`
- optional `scripts/tests/run_task_249_audio_visual_perf_gate.ps1`
- `docs/tasks/TASK_249_post_audio_visual_performance_optimization_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_249_post_audio_visual_performance_optimization_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd`
- [x] `powershell -ExecutionPolicy Bypass -File scripts/tests/run_task_222_performance_gate.ps1`
- [ ] Manueller Godot-Profiler-Lauf nach Checkliste.
- [x] `git diff --check`

## Umsetzung
- `data/performance_budget_contract.json` enthaelt jetzt einen zusaetzlichen `project_budget.audio_visual`-Abschnitt fuer Audio-Pool, aktive Stimmen, Missing-Zaehler, Background-VRAM, Muzzle-Texturen und Weapon-Fire-VFX-Count.
- `scripts/tests/task_249_post_audio_visual_performance_optimization_pass.gd` misst Audio-Spam/Polyphony/Dedupe, Background-Loadpolicy/VRAM, VFX-Burst und den bestehenden Asset-Harness.
- `docs/performance/audio_visual_performance_report.md` dokumentiert Before/After, Budgetentscheidung und lokale Ergebnisse.

## Risiken
- Performancewerte sind maschinenabhaengig; Budget und Report muessen lokale Baseline und Projektbudget trennen.
- Zu aggressives Preloading kann Stutter reduzieren, aber Startzeit/VRAM verschlechtern.
- Zu harte Limits koennen Sound/VFX unnatuerlich abschneiden.

## Naechster Schritt
Nach TASK_249 schliesst TASK_250 die Reihe mit einem spielbaren End-to-End-Smoke fuer Menue, Backgrounds, Audio, Mission und Asset-Lokalitaet.
