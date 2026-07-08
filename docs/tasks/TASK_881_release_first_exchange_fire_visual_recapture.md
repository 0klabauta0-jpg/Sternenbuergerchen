# TASK_881 - Release First Exchange Fire Visual Recapture

## Ziel / Problem
TASK_880 hebt FireTrace, Impact, Target-Fokus und das kurze HIT/MISS/FIRE-Label fuer den belegten First-Exchange an. Der naechste notwendige Beweis ist ein frischer echter Release-Fensterblick: Der Spieler muss im Window-Handle-Screenshot sofort verstehen, dass CONTACT FIRE passiert, wer wohin schiesst und wo Ziel/Impact liegen.

## Sinnhaftigkeit / Ursache
Nach TASK_879 ist der exportierte Statusquellenpfad belegt und nach TASK_880 sind die Visual-Parameter headless angehoben. Was noch fehlt, ist die menschliche Sichtpruefung des echten Fensters. Ohne diesen Recapture wuerden wir nur behaupten, dass der Polish im Bild reicht.

## Umfang
- Eigener Capture-Wrapper fuer TASK_881.
- Wiederverwendung des TASK_879 Exported-Status-Source-Trace-Pfads, der wiederum den TASK_877 Real-Window-Recapture nutzt.
- Eigene Manifest- und Screenshot-Pfade fuer den TASK_881-Befund.
- Read-only Analyzer fuer Acceptance/Manual-Review-Status.
- Verifier fuer Dokumentation, Manifest-Schema, Pflichtchecks und read-only-Grenzen.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen Commands, FireEvents, DamageEvents, Movement-Events oder Multiplayer-Wahrheit.
- Kein UI-Text-Override.
- Keine Shortcut-, Startmenue- oder Taskleisten-Aenderung.
- Kein automatischer Pixelentscheid; der menschliche Sichtentscheid bleibt als manueller Review markiert.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_880_release_first_exchange_fire_visual_polish.md`
- `docs/tasks/TASK_879_release_first_exchange_exported_status_source_trace.md`
- `docs/tasks/TASK_877_release_first_exchange_visible_status_recapture.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Das TASK_881-Manifest nennt TASK_880 als Visual-Polish-Quelle und TASK_879/TASK_877 als Trace-/Capture-Quellen.
- Der Capture laeuft ueber `--release-singleplayer-first-go-firefight`.
- Screenshotpfade sind eigene TASK_881-Pfade.
- Pflichtchecks nennen CONTACT FIRE, FireTrace, Impact, Target-Fokus, #17/#18/#19-Konsistenz und weiter bedienbare Command-Flaechen.
- Der Analyzer blockiert fehlende/manipulierte Manifestdaten, bleibt aber read-only.
- Der Analyzer erzeugt keine Commands, FireEvents, DamageEvents, Movement oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_881_release_first_exchange_fire_visual_recapture.md`
- `scripts/tools/capture_release_first_exchange_fire_visual_recapture.ps1`
- `scripts/mission/release_first_exchange_fire_visual_recapture.gd`
- `scripts/tests/task_881_release_first_exchange_fire_visual_recapture.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_fire_visual_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`
- `godot_console.exe --headless --path . --script scripts/tests/task_881_release_first_exchange_fire_visual_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_880_release_first_exchange_fire_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_881 erzeugt nur den frischen Beweis und eine Acceptance-Schale. Wenn der echte Screenshot weiter nicht sofort lesbar ist, folgt als naechster enger Schritt TASK_882 - Release First Exchange Fire Visual Findings.
