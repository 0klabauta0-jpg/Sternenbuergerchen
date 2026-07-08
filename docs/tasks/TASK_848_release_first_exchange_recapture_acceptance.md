# TASK_848 - Release First Exchange Recapture Acceptance

## Ziel / Problem
TASK_847 macht den ersten Fire-Exchange in den HUD-Surfaces laenger sichtbar. Bisher ist aber nur der Headless-/Snapshot-Pfad gruen. Fuer den Release-Spieler zaehlt der echte exportierte Fensterblick.

Ziel dieses Tasks ist ein frischer Release-Export plus ein neuer First-Exchange-Recapture nach TASK_847. Das Ergebnis wird als Acceptance-Paket dokumentiert: Screenshotpfade, Manifest, erwartete Sichtbarkeitsvertraege und offene manuelle Review-Checks.

## Sinnhaftigkeit / Ursache
Der vorherige TASK_845-Capture war vor TASK_847 entstanden und zeigte noch `CONTACT PRESSURE` / `NO FIRE`. Nach dem Sichtbarkeits-Fix muss der sichtbare Release-Pfad erneut belegt werden, bevor wir weiter in Visual-Polish oder Multiplayer-Slices gehen.

## Umfang
- Frischen Release-Export ueber `scripts/tools/export_runtime_release.ps1` erzeugen.
- TASK_845-Capture-Wrapper mit `--release-singleplayer-first-go-firefight` erneut ausfuehren.
- Acceptance-Snapshot/Manifest fuer TASK_848 erzeugen.
- HTML-Zwischenbericht, Status, Roadmap und Contract auf TASK_848 weiterziehen.
- Verifier prueft, dass das neue Acceptance-Paket auf TASK_847 aufsetzt und keine Gameplay-Wahrheit erzeugt.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein automatischer Pixel- oder OCR-Entscheid.
- Keine FireEvent-, Damage-, Command-, Movement-, Contact- oder Multiplayer-Mutation.
- Kein Shortcut-Update und kein Veraendern von lokalen Export-Presets im Repo.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_847_release_fire_exchange_visibility_persistence.md`
- `docs/tasks/TASK_845_release_first_exchange_real_window_recapture.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Manifest `tmp/release_first_exchange_recapture_acceptance.json` nennt Schema `sternenbuergerchen.release_first_exchange_recapture_acceptance.v1`, `task_id = TASK_848`, `source_task_id = TASK_845` und `source_visibility_task_id = TASK_847`.
- Frischer TASK_845-Recapture ist mindestens `review_ready` oder `manual_open`, ohne Hard-Failures.
- Manifest nennt erwartete TASK_847-Style-ID `task_847_release_fire_exchange_visibility_persistence_v1`.
- Pflichtchecks enthalten `contact_fire_or_fire_exchange_visible`, `event_log_contact_fire_or_exchange_detail_visible`, `selected_fireteam_next_why_mentions_contact_or_fire`, `mission_control_next_why_mentions_contact_or_fire`, `fire_event_trace_or_impact_visible` und `no_stale_contact_pressure_only_message`.
- Screenshotpfade fuer Desktop und Fenster werden festgehalten.
- Snapshot bleibt read-only: keine Gameplay-Wahrheit, keine Commands, keine FireEvents, keine DamageEvents, keine Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_exchange_recapture_acceptance.gd`
- `scripts/tests/task_848_release_first_exchange_recapture_acceptance.gd`
- `docs/tasks/TASK_848_release_first_exchange_recapture_acceptance.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_real_window.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 32`
- `godot_console.exe --headless --path . --script scripts/tests/task_848_release_first_exchange_recapture_acceptance.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_847_release_fire_exchange_visibility_persistence.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_848 kann nur beweisen, dass ein neuer Release-Capture vorliegt und alle manuellen Pflichtchecks vorbereitet sind. Die echte Bildbewertung bleibt ein menschlicher Sichtreview. Wenn der neue Screenshot weiter zu wenig FireTrace/Impact zeigt, folgt ein enger VFX-/World-Feedback-Findings-Task.
