# TASK_893 - Release First Exchange Fire Direction Impact Real Window Recapture

## Ziel / Problem
TASK_892 hat Schussrichtung, Impact und Zielbezug fuer den bestaetigten CONTACT-FIRE-Moment im Primary3D-Snapshot verstaerkt. Es fehlt aber noch der echte nicht-headless Fensterbeweis, ob ein Spieler Quelle -> Schussrichtung -> Ziel -> Treffer als eine Aktion lesen kann.

## Sinnhaftigkeit / Ursache
Der letzte belegte Engpass ist nicht mehr CONTACT-FIRE-Wahrheit, sondern visuelle Lesbarkeit im Weltbild. Headless-Snapshots reichen hier nicht als Abschluss, weil Dichte, Timing und Blickfuehrung erst im echten Release-Fenster sichtbar werden.

## Umfang
- Eigenen TASK_893-Recapture-Contract und Analyzer anlegen.
- Bestehenden TASK_890-HUD-Density-Recapture-Pfad wiederverwenden, statt einen neuen Capture-Stack zu bauen.
- Eigene Manifest-/Screenshotpfade unter `tmp/release_first_exchange_fire_direction_impact_real_window_recapture*` schreiben.
- Erwartete TASK_892-Schema-/Style-ID sowie TASK_889-HUD-Density-Quelle festhalten.
- Manuelle Pflichtchecks fuer Direction Arrow, Impact-Relationship-Anchor, Target-Endcap und Quelle-Ziel-Bezug definieren.
- Status, Roadmap, Contract und Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen Commands, FireEvents, DamageEvents, Movement-, Contact-, UI- oder Multiplayer-Wahrheiten.
- Kein automatisches Akzeptieren eines PNGs ohne menschlichen Sichtbefund.
- Kein Shortcut-/Taskleisten-Update.
- Kein weiterer HUD-Text-Polish in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_892_release_first_exchange_fire_direction_impact_clarity_polish.md`
- `docs/tasks/TASK_890_release_first_exchange_hud_density_real_window_recapture.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09.html`

## Akzeptanzkriterien
- `capture_release_first_exchange_fire_direction_impact_real_window_recapture.ps1` ruft den bestehenden TASK_890-Capture-Pfad auf und schreibt ein eigenes TASK_893-Manifest.
- Das Manifest nennt TASK_892 als Source, TASK_889 als HUD-Density-Quelle, TASK_887/TASK_879/TASK_883/TASK_880/TASK_876 als zugrunde liegende Belegkette und `--release-singleplayer-first-go-firefight` als Startargument.
- Das Manifest enthaelt eigene Desktop-/Window-Screenshotpfade und bleibt `manual_review_required = true`, `manual_review_done = false`.
- `ReleaseFirstExchangeFireDirectionImpactRealWindowRecapture.build_snapshot()` trennt `review_ready` von `accepted`.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement-, Navigation-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_893_release_first_exchange_fire_direction_impact_real_window_recapture.md`
- `scripts/mission/release_first_exchange_fire_direction_impact_real_window_recapture.gd`
- `scripts/tools/capture_release_first_exchange_fire_direction_impact_real_window_recapture.ps1`
- `scripts/tests/task_893_release_first_exchange_fire_direction_impact_real_window_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_893_release_first_exchange_fire_direction_impact_real_window_recapture.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_fire_direction_impact_real_window_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`
- `godot_console.exe --headless --path . --script scripts/tests/task_892_release_first_exchange_fire_direction_impact_clarity_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_893 erzeugt die Belegbasis und den Pflichtcheck-Rahmen. Ob der Screenshot wirklich schon angenehm genug ist, bleibt absichtlich ein nachgelagerter Sichtbefund. Der erwartete Folgepunkt ist ein read-only Findings-Schnitt statt ein blindes Weiterpolieren.

## Naechster Schritt
TASK_894 - Release First Exchange Fire Direction Impact Visual Findings.
