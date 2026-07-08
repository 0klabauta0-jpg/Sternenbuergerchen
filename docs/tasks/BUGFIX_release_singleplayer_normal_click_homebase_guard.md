# BUGFIX - Release Singleplayer Normal Click Homebase Guard

## Ziel / Problem
Im exportierten Build kann der sichtbare Pfad `EXE starten -> Einzelspieler klicken` in einem alten Homebase-Zustand landen: `Operation: FOB Transfer`, leeres Flightdeck, `Start blockiert` und Readiness-Blocker wie `STOP Team`, `STOP Dropship`, `STOP Pilot` und `STOP Boarding`.

## Sinnhaftigkeit / Ursache
Die bisherigen Release-Guards reparieren Bootstrap, stale Saves und Deep-Link-Pfade. Der gemeldete Screenshot zeigt aber den normalen sichtbaren Klickpfad. Deshalb muss der Guard direkt beim sichtbaren Homebase-Show erneut laufen und ein eigener Snapshot muss exakt diese Dead-End-Symptome pruefen.

## Umfang
- Homebase-Show fuehrt den bestehenden Singleplayer-Actionability-Guard sofort aus.
- Ein Snapshot `get_release_singleplayer_normal_click_homebase_guard_snapshot()` meldet Mission, Drop-Quelle, Flightdeck, Payload, Boarding, Readiness und Startbutton.
- Der normale Main-Menu-`Einzelspieler`-Klickpfad wird gegen die Screenshot-Blocker geprueft.

## Nicht-Ziele
- Kein neuer Singleplayer-Flow.
- Kein Entfernen des FOB-Transfer-Workflows fuer echte FOB-Tasks.
- Kein neues Save-System und keine UI-seitige Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_827_release_homebase_save_override_guard.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`

## Akzeptanzkriterien
- Der normale Main-Menu-`Einzelspieler`-Klick landet auf einer sichtbaren, startbaren Homebase.
- Mission ist `grid_sweep`, Drop-Quelle ist `homebase_direct`.
- Flightdeck zeigt ein Schiff, Payload hat Operatoren und ist geboardet.
- Readiness ist `ready`, `Start Mission` ist aktiv.
- Der sichtbare Readiness-Text enthaelt keine alten STOP-Blocker.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/bugfix_release_singleplayer_normal_click_homebase_guard.gd`
- `docs/tasks/BUGFIX_release_singleplayer_normal_click_homebase_guard.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`

## Lokale Pruefung
- `godot.exe --headless --path . --script scripts/tests/bugfix_release_singleplayer_normal_click_homebase_guard.gd`
- `godot.exe --headless --path . --script scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `godot.exe --headless --path . --script scripts/tests/task_827_release_homebase_save_override_guard.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Guard schuetzt den normalen Release-Klickpfad im Code. Ein echter Fenster-Sichttest bleibt noetig, weil ein alter laufender Prozess, ein stale Export oder manuelles Starten einer anderen EXE weiterhin wie derselbe Fehler aussehen kann.
