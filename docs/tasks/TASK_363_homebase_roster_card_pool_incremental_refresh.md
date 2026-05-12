# TASK_363 - Homebase Roster Card Pool Incremental Refresh

## Ziel
Homebase-Roster- und Staging-Karten sollen inkrementell aktualisiert oder wiederverwendet werden, statt bei jeder Roster-/Selection-Aenderung ganze Container neu aufzubauen.

## Status: GEPLANT

## Sinnhaftigkeitscheck
Der Review-Punkt ist fuer den aktuellen 12-Unit-Stand kein akuter Bug, aber als Skalierungs- und UI-Fluessigkeits-Task sinnvoll. Der Code erzeugt Karten in mehreren Panels neu und ruft danach direkte Refresh-Ketten auf. Bei 50+ Units oder vielen Staging-Kopien wird das spuerbarer.

## Problem
Roster-, Fireteam-, Loadout- und Flightdeck-Panels koennen bei kleinen State-Aenderungen mehr Karten neu instanziieren als noetig. Portraits, Rangbadges, Loadout-Icons und Tooltips werden dadurch wiederholt aufgebaut.

## Ursache
Panel-Refreshes arbeiten container-orientiert: leeren, Karten erzeugen, Profile setup'en, Signale verbinden. Es gibt noch keinen stabilen Card-Key, keinen Pool und keine Dirty-Update-Schicht.

## Umfang
- Stabile Card-Keys definieren, z. B. `context + unit_id + fireteam_id`.
- Card-Pool oder inkrementelle Update-Helfer fuer Homebase-Karten einfuehren.
- Nur geaenderte Karten neu konfigurieren; unveraenderte Karten behalten Node, Signalverbindungen und Portrait.
- Mit TASK_361 kompatibel sein: Readonly-Profilreferenzen fuer reine Anzeige bevorzugen.
- Initial nur Homebase-Roster/Direct-Staging abdecken; FOB-Panels nur anfassen, wenn gemeinsame Komponenten betroffen sind.

## Akzeptanzkriterien
- [ ] Eine einzelne Selection-/Focus-Aenderung baut nicht die komplette Roster-Liste neu auf.
- [ ] Sortierung, Drag/Drop, Doppelklick-Character-Sheet und Loadout-Badges bleiben erhalten.
- [ ] Karten fuer entfernte Units werden sauber aus dem Pool geloest oder recycled.
- [ ] Headless-Verifier simuliert ein groesseres Roster und prueft stabile Card-Anzahl bzw. Wiederverwendung.
- [ ] Keine stale Profil-, Portrait- oder Rank-Anzeige nach Promotion/Loadout-Aenderung.

## Erwartete Dateien
- `scripts/meta/homebase_screen.gd`
- ggf. `scripts/meta/npc_compact_card.gd`
- ggf. `scripts/meta/homebase_card_pool.gd`
- `scripts/tests/task_363_homebase_roster_card_pool_incremental_refresh.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_363_homebase_roster_card_pool_incremental_refresh.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_361_npc_compact_card_readonly_profile_reference_contract.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_355_homebase_direct_ux_payload_truth.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Pooling kann stale UI erzeugen, wenn Dirty-Signale fehlen. Der Task muss deshalb eher klein und testbar bleiben.
- Wenn die Umsetzung zu breit wird, zuerst nur Roster-Liste poolen und Staging-/Loadout-Panels als Folgetasks schneiden.
