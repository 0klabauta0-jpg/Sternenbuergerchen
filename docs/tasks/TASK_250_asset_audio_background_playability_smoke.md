# TASK_250 - Asset Audio Background Playability Smoke

## Ziel
Die Audio-/Background-/Asset-Reihe soll in einem spielbaren End-to-End-Smoke abgeschlossen werden: Hauptmenue, Settings, Multiplayer-Host/Join-Vorbereitung, Singleplayer-/Mission-Setup, Kampf-SFX, Bewegung, Explosion, Backgrounds, feste Fenster und Projektlokalitaet.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_242 - Audio SFX Source Inventory and Curated Import
- TASK_243 - Audio Event Contract and Bus Setup
- TASK_244 - Combat Movement UI SFX Integration
- TASK_245 - Background Image Catalog and Screen Usage
- TASK_246 - Visual Scale Alignment Asset Pass
- TASK_247 - Used Asset Project Locality Audit Gate
- TASK_248 - Audio Visual Import and Playback Smoke
- TASK_249 - Post Audio Visual Performance Optimization Pass

## Kontext
Die Reihe beruehrt viele sicht- und hoerbare Flaechen. Der Abschluss-Smoke soll zeigen, dass sich das Ganze als Spiel anfuehlt: Menue klickt, Screens haben passende Hintergruende, NPCs schiessen und laufen mit SFX, Explosionen wirken, Assets sind projektlokal, Fenster bleiben fest und Performance bleibt im Rahmen.

## Umfang
1. Main-Menu-Flow:
   - Hauptmenue oeffnen.
   - Einzelspieler, Multiplayer, Editor, Einstellungen als Wege pruefen.
   - Button-Klicks und Settings-Volume pruefen.
   - Background sichtbar und lesbar.
2. Multiplayer-Vorbereitung:
   - Host-/Join-Screen oeffnen.
   - UI-Sounds und Background pruefen.
   - Keine Gameplay-Snapshots oder Audio-Events ohne Aktion duplizieren.
3. Mission-/Singleplayer-Smoke:
   - Kleine Testmission starten.
   - Friendly und Enemy sichtbar.
   - Bewegungsschritte, Schuesse, Muzzle-Flash, Treffer/Impact und Explosion ausloesen.
   - FoW/Sichtbarkeit respektieren.
4. Asset- und Layout-Gates:
   - TASK_247-Lokalitaetsgate laufen lassen.
   - Feste Hauptfenster bleiben unveraendert.
   - Background-Aspect aendert keine Fenstergroessen.
5. Performance:
   - TASK_249 oder TASK_222-Gate als Abschlusspruefung.
   - Auffaellige Stutter/Missing-Asset-Zaehler blockieren Abschluss.
6. Manueller Check:
   - Kurze Hoer-/Sichtcheckliste fuer UI, Mission, Explosion, Background und Alignment.

## Nicht-Ziele
- Kein kompletter Balancing-Pass.
- Keine finale Soundmischung fuer alle Waffen.
- Kein vollstaendiger Online-Multiplayer-Test mit externer Verbindung.
- Keine neue Assetquelle.

## Akzeptanzkriterien
- [x] Hauptmenue/Settings/Multiplayer/Editor-Pfade bleiben bedienbar.
- [x] Button-Sounds und Volume-Settings funktionieren.
- [x] Backgrounds laden projektlokal und stoeren feste Fenster nicht.
- [x] Mission spielt Schuss-, Schritt-, Impact- und Explosion-SFX ab.
- [x] Friendly-/Enemy-Visuals, Waffen und VFX bleiben ausgerichtet.
- [x] TASK_247 und TASK_249/TASK_222 laufen als Abschlussgates.
- [x] Ein manueller Hoer-/Sichtcheck ist dokumentiert.

## Erwartete Dateien
- `scripts/tests/task_250_asset_audio_background_playability_smoke.gd`
- `docs/manual_checks/asset_audio_background_playability_checklist.md`
- `docs/reports/asset_audio_background_playability_smoke.md`
- `docs/tasks/TASK_250_asset_audio_background_playability_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_250_asset_audio_background_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_247_used_asset_project_locality_audit_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_249_post_audio_visual_performance_optimization_pass.gd`
- [ ] Manueller End-to-End-Hoer-/Sichtcheck.
- [x] `git diff --check`

## Umsetzung
- `scripts/tests/task_250_asset_audio_background_playability_smoke.gd` prueft Main-Menu-/Settings-/Lobby-Pfade, UI-Audio, feste Fenster, projektlokale Backgrounds, Mission-Unit-Visuals, Weapon-VFX, Schuss-, Schritt-, Impact- und Explosion-SFX sowie FoW-Filterung fuer Fire-Events.
- `docs/manual_checks/asset_audio_background_playability_checklist.md` dokumentiert den offenen manuellen Hoer-/Sichtcheck.
- `docs/reports/asset_audio_background_playability_smoke.md` fasst Smoke-Abdeckung und lokale Gate-Ergebnisse zusammen.

## Risiken
- Ein End-to-End-Smoke lokalisiert Fehler schlechter als Einzeltests.
- Headless kann Hoereindruck und visuelle Bildwirkung nur teilweise bewerten.
- Wenn alle Backgrounds/Sounds gleichzeitig vorgeladen werden, kann der Smoke erst nach TASK_249 gruene Werte liefern.

## Naechster Schritt
Nach TASK_250 kann ein Balance-/Politur-Slice entscheiden, welche Sounds, Backgrounds und Waffenvarianten final bleiben.
