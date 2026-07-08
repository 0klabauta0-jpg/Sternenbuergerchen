# TASK_879 - Release First Exchange Exported Status Source Trace

## Ziel / Problem
Der TASK_878-Fensterbefund zeigt: TASK_876 ist headless gruen, aber der exportierte echte Fensterblick liest weiter `NEXT LOS/RANGE KORRIGIEREN`, `Kampf NO FIRE NO_LOS` und `CONTACT PRESSURE`.

TASK_879 soll im exportierten Runtime-Pfad tracebar machen, ob die TASK_876-Statusquelle:

- im Export ueberhaupt aktiviert wird,
- zu spaet ankommt,
- zu frueh auslaeuft,
- im `combat_hud_density`-/Event-Log-Pfad nicht konsumiert wird,
- oder von einem spaeteren HUD-/Decision-Refresh wieder ueberschrieben wird.

## Sinnhaftigkeit / Ursache
Ein weiterer kosmetischer CONTACT-FIRE-Text waere riskant, solange unklar ist, ob die vorhandene Statusquelle nicht ankommt oder nachtraeglich verloren geht. Der naechste Schritt muss deshalb Evidence erzeugen, nicht Gameplay-Wahrheit.

## Umfang
- Read-only Runtime-Trace fuer den Release-First-GO-Firefight-Deep-Link.
- Trace-Datei im Exportlauf, aktiviert nur ueber explizite Umgebungsvariable oder Capture-Tool.
- Capture-Wrapper, der den bestehenden TASK_877-Capture-Pfad nutzt und zusaetzlich die Runtime-Trace-Datei einsammelt.
- Analyzer/Verifier, der Aktivierung, spaete Ueberschreibung und Read-only-Grenzen auswertet.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein neuer HUD-Text als kosmetischer Override.
- Keine neuen Commands, FireEvents, DamageEvents oder Movement-Events.
- Keine Multiplayer-Wahrheit und keine Shortcut-Aenderungen.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_878_release_first_exchange_visible_status_visual_findings.md`
- `docs/tasks/TASK_876_release_first_exchange_visible_status_source_reconciliation.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Der exportierte Release-Deep-Link kann eine `tmp/release_first_exchange_exported_status_source_trace_runtime.json` schreiben.
- Die Trace-Datei enthaelt mehrere zeitliche Samples aus dem Deep-Link-/HUD-Refresh-Pfad.
- Der Snapshot meldet, ob TASK_876-Aktivierung beobachtet wurde.
- Der Snapshot meldet, ob der finale sichtbare Status wieder `NO_FIRE`/`NO_LOS`/`CONTACT_PRESSURE` liest.
- Der Snapshot gibt einen belegten naechsten Task aus, statt CONTACT FIRE blind weiter zu priorisieren.
- Alle Trace-Daten bleiben read-only und erzeugen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tools/capture_release_first_exchange_exported_status_source_trace.ps1`
- `scripts/mission/release_first_exchange_exported_status_source_trace.gd`
- `scripts/tests/task_879_release_first_exchange_exported_status_source_trace.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_exported_status_source_trace.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 38`
- `godot_console.exe --headless --path . --script scripts/tests/task_879_release_first_exchange_exported_status_source_trace.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_878_release_first_exchange_visible_status_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
Wenn der Trace zeigt, dass TASK_876 im Export nie aktiviert wird, muss TASK_880 den Export-/Deep-Link-Aktivierungspfad korrigieren. Wenn die Aktivierung beobachtet wird, der finale Fensterstatus aber wieder `NO_LOS`/`CONTACT_PRESSURE` liest, muss TASK_880 den konkreten HUD-/Decision-Refresh-Override korrigieren.
