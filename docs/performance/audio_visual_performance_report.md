# Audio Visual Performance Report

Stand: 2026-05-07
Status: TASK_249 implementiert

## Ziel
Dieser Bericht ist der Nachlauf zu Audio-, Background-, VFX- und Alignment-Integration. Er prueft, ob die neuen Pfade die bestehenden TASK_222-Budgets weiter einhalten und ob zusaetzliche Audio-/Visual-spezifische Grenzen noetig sind.

## Before
- TASK_222-Budgets aus `data/performance_budget_contract.json` bleiben die Projektgrenze.
- TASK_220 hatte Asset-VRAM, GLB-Groesse, Pipeline-Snapshots und Warmup-Kandidaten bereits breit gemessen.
- TASK_248 bestaetigte Playback und Resource-Ladung, aber noch ohne zusaetzlichen Performance-Fokus.

## After
- Neuer Budgetabschnitt `project_budget.audio_visual` begrenzt Audio-Pool, aktive Stimmen, Missing-Zaehler, Background-VRAM, Muzzle-Texturen und Weapon-Fire-VFX-Count.
- TASK_249-Verifier misst Audio-Polyphony, Dedupe, Background-Crop/VRAM, VFX-Burst und den bestehenden Asset-Harness.
- Budgets unchanged: Bestehende TASK_222-Budgets wurden nicht angehoben; der neue Abschnitt ist eine zusaetzliche engere Diagnose fuer Audio/Visuals.

## Audio polyphony
- AudioEventPlayerPool bleibt begrenzt.
- Wiederholte Rifle-/Movement-Spam-Events erzeugen Polyphony-Suppression statt ungebremster Stimmen.
- Wiederholte Sniper-Fire-Events mit gleichem Dedupe-Key erzeugen Dedupe-Suppression.
- Missing-ID und Missing-Resource-Zaehler bleiben im Performance-Pass bei 0.

## Background VRAM
- Background-Katalog bleibt `screen_on_demand`; es gibt keine parallele Vollvorladung aller Screen-Backgrounds.
- Katalogmaessige VRAM-Schaetzung bleibt unter 32 MiB fuer die vorbereiteten Backgrounds.
- Maximaldimension bleibt unter 2048 px.

## VFX
- Muzzle-Flash-Katalog bleibt unter dem V1-Limit von 8 Texturen.
- Ein 10-Fire-Event-Burst bleibt unter dem Weapon-Fire-VFX-Visual-Budget von 12 Eintraegen.
- VFX und Audio bleiben read-only und erzeugen keine Gameplay-Commands oder Effects.

## Optimierungen
- Keine Runtime-Optimierung war noetig.
- Kein Preload wurde ergaenzt; Backgrounds bleiben screenweise lazy.
- Warmup bleibt auf bestehende kleine, haeufige Kandidaten beschraenkt und side-effect-free.

## Lokaler Lauf
- `task_249_post_audio_visual_performance_optimization_pass.gd`: 39/0.
- `task_222_performance_regression_gate_and_manual_profile_checklist.gd`: 82/0.
- `run_task_222_performance_gate.ps1`: 82/0 und keine geblockten RID-/ObjectDB-Leakmuster.
- `git diff --check`: sauber.

## Manuell offen
- Godot Profiler, Visual Profiler und Video-RAM-Tab nach `docs/dev/performance_manual_profile_checklist.md` bleiben fuer sichtbare GPU-/Mix-/Stutter-Bewertung offen.
