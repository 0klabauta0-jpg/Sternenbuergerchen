# BUGFIX - Homebase Parallel Direct Dropship Fireteam Catalog Guard

## Ziel / Problem
Beim parallelen Homebase-Direct-Dropship-Workflow konnte nach dem ersten `Send` ein weiteres Fireteam nicht mehr zuverlaessig auf ein zweites Dropship gestaged werden. Die Homebase kannte in diesem Zwischenzustand nur noch die aktive Missionsauswahl statt den vollstaendigen Fireteam-Katalog.

## Sinnhaftigkeit / Ursache
`HomebaseScreen.set_fireteam_context()` ersetzte den gesamten Fireteam-Katalog mit dem vom MetaLayer aktuell gelieferten Kontext. Nach dem ersten Direct-Launch enthielt dieser Kontext nur das bereits gestartete Fireteam. Danach filterte die Homebase das zweite Fireteam als "ohne Mitglieder" aus, obwohl die Fireteam-Definition die Mitglieder weiter kannte.

## Umfang
- Fireteam-Definitionen in der Homebase werden additiv gemerged statt still ersetzt.
- `_get_member_unit_ids_for_fireteam()` nutzt die aktive Auswahl zuerst, faellt aber auf `member_unit_ids` aus der Fireteam-Definition zurueck.
- Der bestehende Direct-Dropship-Verifier prueft jetzt, dass ein zweites Fireteam vor dem zweiten Launch wirklich auf sein eigenes Dropship gestaged ist.

## Nicht-Ziele
- Kein neues Dropship-Gameplay.
- Kein Aendern von Boarding-Zeiten, Pilotzuweisung, Payload-Capacity oder Mission-Start-Authority.
- Kein zweiter Gameplay-State im UI; die Homebase bleibt Presenter/Staging-Schicht.

## Relevante Contracts / Dokumente
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/tasks/TASK_393_direct_dropship_independence_lz_vector.md`
- `docs/tasks/TASK_842_release_firefight_insertion_residue_declutter.md`

## Akzeptanzkriterien
- Nach dem ersten Homebase-Direct-Launch bleibt ein zweites Fireteam in der Homebase als gueltige Definition erhalten.
- Das zweite Fireteam kann auf ein zweites Dropship gestaged und gestartet werden.
- Die Mission behaelt beide Dropship-Cards getrennt, inklusive unabhaengigem Transit-/Arrival-State.
- Bestehender normaler `Einzelspieler -> Homebase`-Start bleibt actionfähig.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_393_direct_dropship_independence_lz_vector.gd`
- `docs/tasks/BUGFIX_homebase_parallel_direct_dropship_fireteam_catalog_guard.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_393_direct_dropship_independence_lz_vector.gd`
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_release_singleplayer_normal_click_homebase_guard.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Fix haelt Fireteam-Definitionen additiv in der Homebase. Spaetere echte Fireteam-Loeschfunktionen sollten einen eigenen expliziten Entfernen-Pfad haben, statt ueber unvollstaendige Kontext-Refreshes zu loeschen.
