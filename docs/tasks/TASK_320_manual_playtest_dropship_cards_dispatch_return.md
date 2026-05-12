# TASK_320 - Manual Playtest Dropship Cards Per-Craft Dispatch and Return

## Ziel
Mehrere Dropships sollen unabhaengig sichtbar, planbar, sendbar, droppbar und zur FOB rueckrufbar sein.

## Status: IMPLEMENTIERT

## Kontext
Im manuellen Playtest wurden Dropships nur sichtbar, wenn sie ausgewaehlt waren. Ein Dropship konnte teilweise nicht einzeln losgeschickt werden, wenn ein anderes noch wartete. LZ-/Drop-Befehle mussten pro Schiff gelten und im Mission-Control-Kontext klar anzeigen, welches Schiff gemeint ist.

## Umfang
1. Per-Craft Mission Cards:
   - Mission-Dropship-Karten werden fuer alle inbound/waiting Crafts angezeigt.
   - Karten behalten Payload, Pilot und Status je Craft.
2. Per-Craft Dispatch:
   - Ein voll geboardetes Dropship kann einzeln gesendet werden.
   - Send wird blockiert, solange Boarding noch laeuft.
3. Mission Control:
   - LZ, Approach und Drop gelten fuer das aktuell ausgewaehlte Craft.
   - Dropship-Karten koennen das Craft fuer Mission-Control-Kommandos selektieren.
4. Rueckflug:
   - Dropships fliegen nach erfolgreichem Drop automatisch zur FOB zurueck.
   - Es gibt einen FOB-Button fuer manuelle Rueckkehr.
5. Feedback:
   - Beim Absetzen meldet der Flow `TOUCHDOWN`.
   - Beim Aussteigen melden die Units `AB`.

## Nicht-Ziele
- Kein abschiessbares Dropship.
- Keine neue Flight-Physics.
- Keine Server-authoritative Multiplayer-Transportlogik.

## Akzeptanzkriterien
- [x] Mehrere Dropships sind gleichzeitig in der Mission-Kartenliste sichtbar.
- [x] Auswahl eines Dropships steuert die Mission-Control-Zielplanung.
- [x] LZ/Drop wird pro Craft gespeichert.
- [x] Volle Dropships koennen einzeln losgeschickt werden.
- [x] Send blockiert bei laufendem Boarding.
- [x] Automatischer und manueller Rueckflug zur FOB sind vorhanden.

## Erwartete Dateien
- `scripts/meta/fob_screen.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- `scripts/tests/bugfix_mission_multi_dropship_cards.gd`
- `docs/tasks/TASK_320_manual_playtest_dropship_cards_dispatch_return.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `bugfix_mission_multi_dropship_cards.gd`
- [x] `bugfix_dropship_mission_flow_verifier.gd`
- [x] `bugfix_fob_second_dropship_assignment_and_scale.gd`
- [x] `task_308_compact_flightdeck_dropship_occupants_actions.gd`
- [x] `task_312_dropship_command_matrix_lz_go_layout.gd`
- [x] `task_313_dropship_arrival_visibility_feedback_smoke.gd`
- [x] `task_180_mission_drop_light_fixed_hud_layout_verifier.gd`
- [x] `task_316_fob_fireteam_staging_migration.gd`
- [x] `git diff --check`

## Risiken
- FullHD-Sichtcheck bleibt fuer Shipcard-Clipping, Statuslesbarkeit und Button-Balance offen.
