# TASK_822 - Release Singleplayer Visible Window Findings

## Ziel / Problem
Nach dem Release-Export und dem Singleplayer-Dead-End-Fix brauchen wir einen kleinen, wiederholbaren Sichttest-Paketierer fuer das echte Release-Fenster. Der letzte Fehler war im exportierten Build sichtbar, aber headless nur indirekt belegbar.

## Sinnhaftigkeit / Ursache
TASK_818 bis TASK_821 pruefen Export, Start, Launch-Akzeptanz und den ersten Homebase-CTA. Was fehlt, ist ein read-only Findings-Paket fuer den laufenden Release-Prozess: Screenshot, Prozesspfad, Fensterdaten falls verfuegbar und eine klare Checkliste fuer den manuellen Singleplayer-Durchlauf.

## Umfang
- Read-only PowerShell-Helfer fuer den laufenden Release-Prozess.
- Desktop-Screenshot und optionaler Window-Crop.
- JSON-Manifest mit Prozess-, Export-, Screenshot- und manuellen Review-Feldern.
- Headless-Verifier fuer Task-Doku, Tool-Grenzen und Manifest-Schema.

## Nicht-Ziele
- Kein automatischer Singleplayer-Klickpfad.
- Kein Starten oder Beenden von Release-Prozessen.
- Keine Shortcut-Aenderung.
- Keine Gameplay-, UI- oder Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_818_station_reentry_release_candidate_playable_build_acceptance.md`
- `docs/tasks/TASK_819_release_runtime_checked_launcher.md`
- `docs/tasks/TASK_820_release_runtime_launch_acceptance_gate.md`
- `docs/tasks/TASK_821_release_first_homebase_cta_emphasis.md`
- `docs/tasks/BUGFIX_singleplayer_release_visible_homebase_deadend_guard.md`
- `docs/dev/export_runtime_package_contract.md`
- `data/export_runtime_package_contract.json`

## Akzeptanzkriterien
- Tool liest den Release-Export-Pfad aus dem Runtime-Package-Contract.
- Tool findet laufende Release-Prozesse ohne neue Prozesse zu starten.
- Tool bringt das erkannte Release-Fenster vor dem Screenshot nach vorn, damit keine fremden Vordergrundfenster als Spielfenster-Beleg gespeichert werden.
- Tool schreibt `tmp/release_singleplayer_visible_window_findings.json`.
- Desktop-Screenshot landet unter `tmp/release_singleplayer_visible_window_desktop.png`, wenn Capture moeglich ist.
- Window-Crop landet unter `tmp/release_singleplayer_visible_window.png`, wenn Windows ein Hauptfenster meldet.
- Manifest bleibt read-only und meldet `starts_processes=false`, `kills_processes=false`, `updates_shortcuts=false`, `ui_sets_gameplay_truth=false`.
- Manifest nennt die manuelle Singleplayer-Review-Checkliste.

## Betroffene Dateien
- `scripts/tools/capture_release_singleplayer_visible_window.ps1`
- `scripts/tests/task_822_release_singleplayer_visible_window_findings.gd`
- `docs/tasks/TASK_822_release_singleplayer_visible_window_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_singleplayer_visible_window.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_822_release_singleplayer_visible_window_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Screenshot beweist nicht automatisch, dass der Spieler den kompletten Pfad geklickt hat; `manual_review_done` bleibt deshalb bewusst `false`.
- Wenn Godot/Windows kein MainWindowHandle liefert, bleibt der Desktop-Screenshot die primaere Evidenz.
- Mit `-SkipFocusWindow` kann ein strikt nicht fokussierender Capture erzwungen werden, ist aber fuer Release-Fensterbelege weniger verlaesslich.
- Der naechste sinnvolle Schritt nach echten Sichtbefunden ist `TASK_823 - Release Singleplayer Visible Findings Polish`.
