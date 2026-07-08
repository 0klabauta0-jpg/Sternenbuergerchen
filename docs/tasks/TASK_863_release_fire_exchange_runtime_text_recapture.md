# TASK_863 - Release Fire Exchange Runtime Text Recapture

## Ziel / Problem
TASK_862 beweist headless, dass #17 Selected Fireteam und #18 Mission Control im Runtime-Textpfad `CONTACT FIRE | ...` vor stale `NO FIRE`-/LOS-/Range-Zeilen setzen.

TASK_863 soll jetzt den echten Release-Fensterblick nach TASK_862 neu exportieren und capturen, damit sichtbar pruefbar ist, ob der Spieler im echten Fenster CONTACT FIRE als erste #17/#18-Lesung sieht.

## Sinnhaftigkeit / Ursache
Der vorherige TASK_860-Capture zeigte, dass Snapshot- und Source-Bindung allein nicht reichen, wenn der echte Label-Updatepfad spaeter stale Text zeigt. Nach TASK_862 muss deshalb wieder ein realer Screenshot her.

## Umfang
- Eigenes Capture-Tool fuer den TASK_863-Nachweis anlegen.
- Bestehenden Release-First-GO-Firefight-Capture-Pfad wiederverwenden.
- Eigenes Manifest und Screenshot-Pfade unter `tmp/` schreiben.
- Read-only Analyzer und Verifier fuer TASK_863 ergaenzen.
- Doku, Roadmap, Status und Zwischenbericht auf den neuen Nachweisstand bringen.

## Nicht-Ziele
- Keine neue Combat-, FireEvent-, Damage-, Movement-, Contact- oder Multiplayer-Wahrheit.
- Keine UI-Polish-Aenderung in diesem Task.
- Keine Shortcut- oder Taskleisten-Aenderung.
- Kein manueller Sichtentscheid als automatisch erledigt markieren.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_862_release_fire_exchange_real_window_primary_hud_runtime_text_polish.md`
- `docs/tasks/TASK_860_release_fire_exchange_real_window_contact_fire_recapture.md`

## Akzeptanzkriterien
- Capture-Manifest nennt TASK_863, TASK_862, TASK_860 und die erwartete TASK_862-Style-ID.
- Fenster- und Desktop-Screenshot werden, wenn der Release-Prozess sichtbar ist, unter eigenen TASK_863-Pfaden kopiert.
- Manifest bleibt read-only und deklariert keine Gameplay-Mutation.
- Verifier akzeptiert einen `review_ready`-Capture und blockt fehlende Screenshots/Schema-/Style-Fehler.
- Manueller Sichtreview bleibt offen.

## Betroffene Dateien
- `scripts/tools/capture_release_fire_exchange_runtime_text_recapture.ps1`
- `scripts/mission/release_fire_exchange_runtime_text_recapture.gd`
- `scripts/tests/task_863_release_fire_exchange_runtime_text_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_fire_exchange_runtime_text_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 38`
- `godot_console.exe --headless --path . --script scripts/tests/task_863_release_fire_exchange_runtime_text_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_862_release_fire_exchange_real_window_primary_hud_runtime_text_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_863 liefert den technischen und visuellen Nachweis, ersetzt aber keinen menschlichen Bildentscheid. Wenn der Screenshot noch nicht klar genug ist, folgt ein Findings-/Polish-Slice statt weiterer Architekturarbeit.
