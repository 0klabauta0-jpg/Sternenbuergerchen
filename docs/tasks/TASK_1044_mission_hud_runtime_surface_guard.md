# TASK_1044 - Mission HUD Runtime Surface Guard

## Ziel / Problem

Nach TASK_1043 baut der wiederkehrende Mission-HUD das grosse Event-Log nicht mehr. Die lokale Frame-Probe zeigt aber weiter periodische 600-700-ms-Spitzen: Command-Matrix-Polish ca. 187 ms, Selected-Fireteam-Karten ca. 71 ms und Fireteam-Mini-Karten ca. 70 ms werden auch dann erneut geschrieben oder rekonstruiert, wenn sich ihr sichtbarer Zustand nicht geaendert hat.

## Ursache

`_update_ui()` ruft die betroffenen Oberflaechen im festen 0.35-Sekunden-Takt auf. Die Command-Matrix schreibt Styles und Metadaten erneut; Selected-Fireteam-Karten werden geleert und neu instanziiert; Mini-Karten laufen durch ihre umfangreiche Status-/Portrait-/Control-Konfiguration, obwohl der gleiche Fireteam-Zustand weiter angezeigt wird.

## Umfang

- Controller-lokale, read-only Visual-Fingerprints fuer Command Matrix, Selected Member Cards und Fireteam Mini Cards.
- Unveraenderte Fingerprints ueberspringen nur UI-Arbeit; der erste und jeder geaenderte Zustand aktualisiert sofort.
- Fingerprints enthalten nur bereits vorhandene Anzeigeeingaben: Auswahl, lokale Command-Moeglichkeit, ROE/GO, Fireteam-Mitgliedschaft, Health, Vital-State, Stance, Runtime-Command und Transportstatus.
- Diagnose-Snapshot mit Apply-/Skip-Zaehlern fuer den Verifier.

## Nicht-Ziele

- Keine Caching-Schicht fuer Gameplay-State.
- Kein Absenken der sichtbaren Datenaktualisierung auf ein blindes Zeitintervall.
- Kein Combat-, Movement-, Dropship- oder Multiplayer-Umbau.
- Strategic-Text bleibt nach dieser Teilaufgabe ein separater, gemessener Kandidat.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1043_mission_hud_hotpath_event_log_guard.md`
- `docs/tasks/TASK_480_mission_ui_hotpath_feedback_guard.md`

## Akzeptanzkriterien

- Zwei identische Refreshes behalten bestehende Selected- und Mini-Card-Nodes bei.
- Eine relevante Zustandsaenderung erzeugt wieder einen Apply-Durchlauf.
- Command-Matrix-Polish wird bei unveraendertem Visual-State nicht erneut angewandt.
- Der Guard-Snapshot ist read-only und setzt keine Gameplay-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.
- TASK_1044, TASK_1043, TASK_366 und bestehende Card-Regressionen sind gruen.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1044_mission_hud_runtime_surface_guard.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script res://scripts/tests/task_1044_mission_hud_runtime_surface_guard.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1043_mission_hud_hotpath_event_log_guard.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_366_tactical_event_log_hud_panel.gd`
- `godot_console.exe --headless --path . --script res://tmp/mission_reactivity_frame_probe.gd`
- `git diff --check`

## Risiken / offene Punkte

Ein zu schmaler Fingerprint kann Statusanzeigen stale machen. Der Verifier prueft deshalb sowohl den unveraenderten Skip als auch einen sichtbaren State-Wechsel. TASK_542 bleibt der anschliessende Gesamtflow-Nachweis.
