# TASK_1045 - Mission First Contact End-to-End Timing Trace

## Ziel / Problem

TASK_542 prueft den echten Spielerweg von Homebase bis zum ersten Kontakt, erreicht nach den HUD-Fixes aber selbst nach 244 Sekunden keinen Abschluss. Das externe Timeout sagt nicht, welcher Lebenszyklus-Abschnitt wartet oder zu viel Arbeit ausloest.

## Ursache

Der bisherige Test liefert Ausgabe erst am Ende und hat keine interne Zeitmarkierung. Dadurch ist nicht unterscheidbar, ob Mission-Auswahl, Homebase-Refresh, Missionserzeugung, LZ-/Drop-Phase, erster Move oder Kontakt-Refresh den Durchlauf bindet.

## Umfang

- Einen bounded, headless Trace fuer dieselben First-Contact-Spielerphasen erstellen.
- Pro Stage Laufzeit, Framezahl, Abschluss und Budgetstatus ausgeben.
- Bei ueberschrittenem Stage-Budget sauber mit dem Namen der letzten/betreffenden Stage beenden.
- Nur vorhandene Test-/Runtime-Hooks nutzen; keine neue Mission, Transport-, Combat- oder Multiplayer-Wahrheit erzeugen.

## Nicht-Ziele

- Kein Fix auf Verdacht in diesem Task.
- Kein Ersatz von TASK_542; er bleibt der vollstaendige Regressionstest nach dem belegten Fix.
- Kein Tuning-Limit als universelle Spieler-Framerate.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_542_mission_first_contact_readability_pass.md`
- `docs/tasks/TASK_1043_mission_hud_hotpath_event_log_guard.md`
- `docs/tasks/TASK_1044_mission_hud_runtime_surface_guard.md`

## Akzeptanzkriterien

- Der Trace benennt jede erreichte Stage inklusive Laufzeit und Framezahl.
- Ein langsamer Abschnitt wird intern mit Stage-ID und Budgetstatus beendet, ohne auf das Shell-Timeout angewiesen zu sein.
- Trace-Evidence ist explizit read-only und erzeugt keine Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.
- Der naechste Fix wird aus dem gemessenen langsamsten Abschnitt abgeleitet.

## Betroffene Dateien

- `scripts/tests/task_1045_mission_first_contact_end_to_end_timing_trace.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task1043_mission_hud_hotpath_2026_07_10.html`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script res://scripts/tests/task_1045_mission_first_contact_end_to_end_timing_trace.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1044_mission_hud_runtime_surface_guard.gd`
- `git diff --check`

## Risiken / offene Punkte

Der Trace beweist eine lokale Ursachenreihenfolge, keine allgemeingueltige Hardware-Grenze. Seine Daten bleiben im Testprozess und duerfen nicht als Runtime-HUD- oder Gameplay-State verwendet werden.
