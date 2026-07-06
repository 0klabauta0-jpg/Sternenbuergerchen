# TASK_827 - Release Homebase Save Override Guard

## Ziel / Problem
Der exportierte Release kann nach `Einzelspieler` sichtbar wieder in einem alten Homebase-FOB-Transfer-Zustand landen: Mission `FOB Transfer`, Mission slots `0 / 3`, Flightdeck leer und Readiness-Blocker wie `STOP Team`, `STOP Dropship`, `STOP Pilot`, `STOP Boarding`.

## Sinnhaftigkeit / Ursache
Die bisherigen Guards reparieren leere Payloads und spaete `fob_transfer`-Missionsauswahl. Ein lokaler Save kann aber zusaetzlich die alte `mission_drop_source = fob` wieder in den sichtbaren Homebase-Pfad tragen. Dann passen Missionsauswahl, Homebase-Direct-Bootstrap und sichtbare Transportlogik nicht mehr zusammen.

## Umfang
- Der Singleplayer-Release-Bootstrap behandelt `grid_sweep` und `homebase_direct` als zusammengehoerigen Startvertrag.
- Alte oder leere Drop-Quellen werden fuer den Release-Start auf `homebase_direct` normalisiert.
- Der sichtbare Homebase-Actionability-Guard repariert Missionsauswahl und Drop-Quelle gemeinsam, bevor Payload/Readiness bewertet werden.
- Der Bootstrap-Snapshot zeigt `mission_drop_source`, `drop_source_repaired` und die vorherige Drop-Quelle.

## Nicht-Ziele
- Kein Entfernen des FOB-Transfer-Workflows.
- Kein neues Save-System.
- Keine Aenderung an Dropship-, Boarding- oder Missions-Handoff-Wahrheit ausserhalb des Release-Bootstrap-Pfads.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/BUGFIX_singleplayer_release_homebase_start_bootstrap.md`
- `docs/tasks/BUGFIX_singleplayer_release_mission_selection_guard.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`

## Akzeptanzkriterien
- Ein stale Save-Zustand mit `selected_mission_id = fob_transfer` und `mission_drop_source = fob` wird sichtbar zur `grid_sweep`-Homebase-Direct-Sortie repariert.
- Homebase zeigt danach wieder ein Dropship, Payload-Operatoren, geboardete Fireteam-Mitglieder und `Start Mission`.
- Die sichtbare Readiness enthaelt keine `STOP Team`-, `STOP Dropship`-, `STOP Pilot`- oder `STOP Boarding`-Blocker mehr.
- Der Guard mutiert keine Gameplay-Wahrheit im HUD, sondern normalisiert den MetaLayer-Release-Startvertrag vor dem Handoff.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_827_release_homebase_save_override_guard.gd`
- `docs/tasks/TASK_827_release_homebase_save_override_guard.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_827_release_homebase_save_override_guard.gd`
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Guard macht den Release-Start robust gegen alte lokale Save-Fragmente. Der echte EXE-Fensterlauf bleibt trotzdem Pflicht, weil Taskleistenpfad, laufende Altprozesse und lokale Godot-Userdaten ausserhalb der Headless-Fixture liegen.
