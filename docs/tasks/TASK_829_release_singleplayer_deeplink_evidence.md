# TASK_829 - Release Singleplayer Deep-Link Evidence

## Ziel / Problem
Der sichtbare Release-Test muss den Singleplayer-Homebase-Pfad reproduzierbar erreichen koennen. Externe Maus-/Fenster-Injektion ist fuer den exportierten Windows-Build zu fragil und liefert keine stabile Evidenz, wenn der echte Spielerpfad visuell blockiert wirkt.

## Sinnhaftigkeit / Ursache
TASK_827 und TASK_828 reparieren Release-Homebase-Startdaten und Ultrawide-Canvas. Fuer QA fehlt aber ein stabiler, explicit opt-in Startpfad, der den gleichen Singleplayer-Button-Pfad ausloest, ohne im normalen Spielerstart neue Gameplay-Wahrheit zu erzeugen.

## Umfang
- Main Menu akzeptiert den expliziten User-Commandline-Parameter `--release-singleplayer`.
- Der Parameter routet deferred ueber den bestehenden Singleplayer-Button-Pfad nach `res://scenes/meta/meta_layer_test.tscn`.
- Der Release-Launcher kann optionale Startargumente an die EXE weitergeben und im Manifest ausweisen.
- Ein Verifier prueft Contract, Launcher-Argumente und read-only-Snapshot.

## Nicht-Ziele
- Kein neuer Singleplayer-Flow.
- Keine Aenderung an Homebase-, Mission-, Simulation- oder Save-Wahrheit.
- Kein automatischer Deep-Link im normalen Spielerstart ohne expliziten Parameter.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_827_release_homebase_save_override_guard.md`
- `docs/tasks/TASK_828_release_ultrawide_canvas_stretch.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`

## Akzeptanzkriterien
- `get_release_singleplayer_deeplink_snapshot()` nennt Argument, Zielroute, read-only-Grenze und Task-ID.
- Ohne `--release-singleplayer` bleibt der normale Main-Menu-Pfad unveraendert.
- Mit `--release-singleplayer` wird derselbe Singleplayer-Handler genutzt wie beim Button.
- `scripts/tools/start_release_runtime_checked.ps1` unterstuetzt `-LaunchArguments`.

## Betroffene Dateien
- `scripts/ui/main_menu_screen.gd`
- `scripts/tools/start_release_runtime_checked.ps1`
- `scripts/tests/task_829_release_singleplayer_deeplink_evidence.gd`
- `docs/tasks/TASK_829_release_singleplayer_deeplink_evidence.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_829_release_singleplayer_deeplink_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_823_release_singleplayer_visible_findings_polish.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/start_release_runtime_checked.ps1 -MaxAgeHours 999 -Launch -LaunchArguments "--release-singleplayer"`
- `git diff --check`

## Risiken / offene Punkte
- Der Deep-Link ist ein QA-Haken. Fuer echte Spieler muss der sichtbare Button weiter verstaendlich und klickbar bleiben.
- Der eigentliche sichtbare Fenstertest bleibt notwendig, weil lokale Saves, Taskleistenpfade und Fensterzustand ausserhalb der Headless-Fixtures liegen.
