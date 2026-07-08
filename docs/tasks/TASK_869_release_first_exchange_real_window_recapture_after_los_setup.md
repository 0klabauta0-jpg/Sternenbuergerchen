# TASK_869 - Release First Exchange Real Window Recapture After LOS Setup

## Ziel / Problem
TASK_868 hat den ersten Release-Fire-Exchange im Headless-/Deep-Link-Pfad wieder auf ein validiertes LOS-/Range-/Attackable-Zielpaar gebracht. Jetzt fehlt der echte Fensterbeweis: Der exportierte Release muss sichtbar zeigen, ob #17/#18/#19 nun als CONTACT FIRE / Fire-Exchange gelesen werden statt wieder `NO_LOS` / `CONTACT PRESSURE`.

## Sinnhaftigkeit / Ursache
Die vorherigen Recaptures haben mehrfach gezeigt, dass gruene Headless-Evidence allein nicht reicht. Der sichtbare Release-Fensterblick ist die Spielerwahrheit fuer Lesbarkeit. TASK_869 erzeugt deshalb nach TASK_868 ein neues Screenshot-/Manifest-Paket, ohne UI-Text zu erzwingen oder Combat-Wahrheit zu erzeugen.

## Umfang
- Frischen Release mit dem bestehenden Exportpfad erzeugen.
- `--release-singleplayer-first-go-firefight` ueber den bestehenden Recapture-Pfad starten.
- Eigenes TASK_869-Manifest und eigene Screenshotpfade schreiben.
- Expected Contracts fuer TASK_868 LOS-Setup, TASK_844 First-Exchange, TASK_866 Runtime-Text-Status und die sichtbaren CONTACT-FIRE-Pflichtchecks festhalten.
- Verifier fuer Manifest, Tool, Doku und read-only Grenzen.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein HUD-Text-Override.
- Kein automatischer Pixelentscheid als bestanden.
- Keine neue Command-, FireEvent-, Damage-, Movement-, Contact- oder Multiplayer-Wahrheit.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_868_release_first_exchange_los_setup_polish.md`
- `docs/tasks/TASK_866_release_fire_exchange_runtime_text_status_recapture.md`
- `docs/tasks/TASK_844_release_first_exchange_tension_tuning.md`

## Akzeptanzkriterien
- Capture-Tool schreibt `tmp/release_first_exchange_los_setup_real_window_recapture.json`.
- Manifest verlinkt TASK_868, TASK_866, TASK_844 und `--release-singleplayer-first-go-firefight`.
- Manifest erwartet `sternenbuergerchen.release_first_exchange_los_setup_polish.v1` und `task_868_release_first_exchange_los_setup_polish_v1`.
- Eigene Desktop-/Window-Screenshotpfade werden geschrieben oder als `manual_open`/Warnung markiert.
- Required Checks nennen #17/#18/#19 CONTACT FIRE, FireTrace/Impact, validiertes Zielpaar, vertrauenswuerdigen Fenster-Crop, kein stale `NO_LOS` / `CONTACT PRESSURE` als alleinige Erstlesung und manuelles Review.
- Snapshot/Manifest bleibt read-only und erzeugt keine Commands, FireEvents, DamageEvents oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tools/capture_release_first_exchange_los_setup_real_window_recapture.ps1`
- `scripts/tools/capture_release_singleplayer_visible_window.ps1`
- `scripts/tests/task_869_release_first_exchange_real_window_recapture_after_los_setup.gd`
- `docs/tasks/TASK_869_release_first_exchange_real_window_recapture_after_los_setup.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_los_setup_real_window_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 38`
- `godot_console.exe --headless --path . --script scripts/tests/task_869_release_first_exchange_real_window_recapture_after_los_setup.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_868_release_first_exchange_los_setup_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_869 erzeugt den Beweis, entscheidet aber nicht automatisch, ob die Spielerlesung gut genug ist. Wenn der Screenshot weiter `NO_LOS`, `CONTACT PRESSURE` oder unlesbare FireTrace/Impact-Signale zeigt, folgt TASK_870 als read-only Visual-Findings-/Polish-Schnitt.

Der erste echte TASK_869-Run hat zusaetzlich gezeigt, dass ein Desktop-Crop ohne erfolgreichen Fensterfokus ein fremdes Fenster als `review_ready` durchreichen kann. Der Capture-Pfad propagiert deshalb `window_crop_trusted`, `visible_window_gate`, Fokusstatus und Foreground-Prozess nach oben; ein nicht vertrauenswuerdiger Crop wird nur noch `manual_open`.
