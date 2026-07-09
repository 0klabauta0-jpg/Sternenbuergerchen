# TASK_941 - Release First Exchange Final Tuning Playability Smoke Gate

## Ziel / Problem
TASK_940 entscheidet den Spielerblick nach dem TASK_938-Final-Tuning read-only. Noch fehlt der kleine Gate-Schnitt, der diesen Befund in eine belastbare naechste Aktion uebersetzt: Playability-Smoke starten, engen Folgefix bauen oder einen manuellen Fensterentscheid offen halten.

## Sinnhaftigkeit / Ursache
Ohne Gate wuerden Smoke-Run und Restpolish wieder im selben Satz stehen. TASK_941 macht den Uebergang explizit und testbar, damit der ausgelassene oder offene Sichtbefund nicht still als Spielbarkeitsfreigabe behandelt wird.

## Umfang
- TASK_940-Snapshot als Quelle pruefen.
- TASK_940-/TASK_939-/TASK_938-/TASK_937-/TASK_936-/TASK_935-Metadaten erhalten.
- `accepted_for_first_exchange_playability_smoke` plus `player_readability_ok` als einzige Smoke-Freigabe behandeln.
- `needs_manual_review` als manuellen Fensterentscheid ausgeben.
- `ready_for_followup_fix_player_polish_final_tuning_followup_fix` als engen Folgefix ausgeben.
- Required-Smoke-Checks fuer den spaeteren First-Exchange-Playability-Smoke sammeln.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Smoke-Run.
- Kein neuer Capture.
- Kein Visual-Polish.
- Keine neuen FireEvents, DamageEvents, Commands oder Movement-Entscheidungen.
- Keine neue UI-, Contact-, Mission- oder Multiplayer-Wahrheit.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_940_release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.md`
- `docs/tasks/TASK_939_release_first_exchange_followup_fix_player_polish_final_tuning_recapture.md`
- `docs/tasks/TASK_938_release_first_exchange_followup_fix_player_polish_final_tuning.md`
- `docs/tasks/TASK_937_release_first_exchange_followup_fix_player_polish_visual_findings.md`
- `docs/tasks/TASK_936_release_first_exchange_followup_fix_player_polish_recapture.md`
- `docs/tasks/TASK_935_release_first_exchange_followup_fix_player_polish.md`
- `docs/reports/spielstand_zwischenbericht_task939_ausblick_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFinalTuningPlayabilitySmokeGate.build_snapshot()` blockt fehlende oder falsche TASK_940-/TASK_939-/TASK_938-/TASK_937-/TASK_936-/TASK_935-Metadaten.
- Ohne akzeptierten TASK_940-Sichtbefund wird kein Smoke freigegeben.
- Bei `needs_manual_review` empfiehlt der Snapshot `TASK_942 - Release First Exchange Manual Window Review`.
- Bei `ready_for_followup_fix_player_polish_final_tuning_followup_fix` empfiehlt der Snapshot `TASK_942 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix`.
- Bei `accepted_for_first_exchange_playability_smoke` plus `player_readability_ok` empfiehlt der Snapshot `TASK_942 - Release First Exchange Playability Smoke Run`.
- Der Snapshot nennt die Smoke-Pflichtchecks fuer EXE-Start, Homebase-Direct-Sortie, Dropship/LZ/GO, erste Bewegung, CONTACT-FIRE-Anzeigen, Command-Surfaces, HUD-Truth-Grenze, Performance und Multiplayer-Snapshot-Grenze.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_941_release_first_exchange_final_tuning_playability_smoke_gate.md`
- `scripts/mission/release_first_exchange_final_tuning_playability_smoke_gate.gd`
- `scripts/tests/task_941_release_first_exchange_final_tuning_playability_smoke_gate.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task939_ausblick_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_941_release_first_exchange_final_tuning_playability_smoke_gate.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_940_release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_941 ist nur das Gate, nicht der Playability-Smoke selbst. Wenn TASK_940 nicht akzeptiert ist, bleibt das Gate gelb oder rot und der naechste spielbare Smoke muss weiter warten.

## Naechster Schritt
Bei `smoke_ready`: TASK_942 - Release First Exchange Playability Smoke Run.

Bei Restreibung: TASK_942 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix.

Bei offenem Sichtbefund: TASK_942 - Release First Exchange Manual Window Review.
