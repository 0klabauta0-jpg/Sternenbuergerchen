# TASK_866 - Release Fire Exchange Runtime Text Status Recapture

## Ziel / Problem
TASK_865 hat die Release-Fire-Exchange-Persistenz von einer 60-FPS-Frame-Annahme auf echte Millisekunden umgestellt. Damit ist der wahrscheinlichste Grund fuer den alten 38s-Fensterbefund korrigiert, aber der Spielerblick ist noch nicht neu bewiesen.

TASK_866 erzeugt deshalb einen frischen echten Release-Fenster-Capture nach TASK_865 und prueft, ob #17 Selected Fireteam und #18 Mission Control im aktiven Exchange-Fenster nun CONTACT FIRE als erste Lesung zeigen.

## Sinnhaftigkeit / Ursache
Die vorherigen Recaptures waren technisch sauber, zeigten aber weiterhin `NEXT LOS/RANGE KORRIGIEREN` / `Kampf NO FIRE NO_LOS` vor CONTACT FIRE. Nach der Zeitbasis-Korrektur reicht ein Headless-Verifier nicht: Der echte Release-Fensterblick muss erneut festgehalten werden.

## Umfang
- Eigenes TASK_866-Capture-Tool fuer neue Manifest-/Screenshot-Pfade.
- Bestehenden TASK_863-Recapture-Pfad wiederverwenden.
- Read-only Analyzer und Verifier fuer TASK_866.
- Release exportieren und mit `--release-singleplayer-first-go-firefight` capturen.
- Doku, Roadmap, Status und Zwischenbericht synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands, Navigation oder Multiplayer-Wahrheit.
- Keine neue UI-Polish-Aenderung in diesem Task.
- Kein Shortcut- oder Taskleisten-Umbau.
- Kein automatischer Ersatz fuer den menschlichen Sichtentscheid.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_865_release_fire_exchange_runtime_text_visible_status_polish.md`
- `docs/tasks/TASK_863_release_fire_exchange_runtime_text_recapture.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Capture-Manifest nennt TASK_866, TASK_865, TASK_863 und TASK_862.
- Fenster- und Desktop-Screenshot werden unter eigenen TASK_866-Pfaden kopiert.
- Manifest bleibt read-only und deklariert keine Gameplay-Mutation.
- Verifier akzeptiert einen `review_ready`-Capture und blockt fehlende Screenshots/Schema-/Style-Fehler.
- Manueller Sichtreview bleibt offen und wird als TASK_867-Findings vorbereitet, falls das Bild weiter Reibung zeigt.

## Betroffene Dateien
- `scripts/tools/capture_release_fire_exchange_runtime_text_status_recapture.ps1`
- `scripts/mission/release_fire_exchange_runtime_text_status_recapture.gd`
- `scripts/tests/task_866_release_fire_exchange_runtime_text_status_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_fire_exchange_runtime_text_status_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 38`
- `godot_console.exe --headless --path . --script scripts/tests/task_866_release_fire_exchange_runtime_text_status_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_865_release_fire_exchange_runtime_text_visible_status_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_866 erzeugt den technischen und visuellen Nachweis, ersetzt aber keinen menschlichen Sichtentscheid. Der lokale TASK_866-Capture ist `review_ready`, zeigt aber weiter `NEXT LOS/RANGE KORRIGIEREN` / `Kampf NO FIRE NO_LOS` und `CONTACT PRESSURE: Position korrigieren`. TASK_867 sollte deshalb nicht erneut nur HUD-Text erzwingen, sondern klaeren, ob der Release-First-Exchange echte FireEvent-/LOS-Evidence liefern muss oder ob der korrekte Spielertext CONTACT PRESSURE statt CONTACT FIRE ist.
