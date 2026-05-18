# TASK_465 - Fireteam Engage Resume Contact Progress

## Ziel / Problem

Der manuelle Drill zeigt einen Regressionsfall im sichtbaren Mission-Tactical-Pfad:
Nach einem `Move` und einem ersten `Engage` kurz vor der Gegnergruppe faellt das Fireteam korrekt in Auto-`DEF 360`. Ein danach direkt in die Gegnergruppe gesetzter `Engage`-Befehl wirkt aber nur kurz oder bleibt bei `BND`/Security haengen. Die Einheiten kommen nicht sauber vorwaerts und es entsteht kein sichtbares Kontaktfeuer.

## Sinnhaftigkeit / Ursache

Der Fall verbindet drei bisher getrennt getestete Mechaniken:

- Auto-`DEF 360` als Abschlusszustand nach einem erreichten Ziel.
- Neuer `Engage`-Waypoint aus einem bestehenden Defense-Zustand.
- Kontakt-/Fire-Entscheidung waehrend Bounding-Bewegung in unmittelbarer Gegnernaehe.

Wenn einer dieser Pfade den naechsten ueberstimmt, wirkt das Team im Fenster eingefroren: `CMD ENGAGE ... FIRE` steht in der UI, waehrend Security/Movement/Combat nicht zusammenarbeiten.

## Umfang

- Reproduzierbarer Headless-Verifier fuer `Auto-DEF -> Engage in Kontakt`.
- Aktiver `Engage` darf nicht durch den vorherigen Defense-Security-Zustand in `DEF 360` zurueckgedrueckt werden.
- Moving-Engage-Security muss in Marsch-/Zielrichtung sichern statt als Defense-360 zu erscheinen.
- Kontaktfeuer muss bei LOS, Waffenreichweite, fitten Gegnern und `fire_at_will` moeglich sein oder eine klare Diagnose liefern.
- `Defend` bleibt Feuer-frei-Halten: Wenn ein Gegner sichtbar, fit, in LOS und in Waffenreichweite ist, darf das Fireteam auch aus `DEF 360` heraus schiessen.

## Nicht-Ziele

- Keine neue Engage-Doktrin.
- Kein Umbau auf LimboAI.
- Keine neue Gegner-KI oder Patrouillenlogik.
- Keine finale Area-Clearing-Regel.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_462_fireteam_auto_defend_completion_release.md`
- `docs/tasks/TASK_463_fireteam_auto_defend_guard_enemy_model_visibility.md`
- `docs/tasks/TASK_464_fireteam_contact_scan_fire_feedback_readability.md`

## Akzeptanzkriterien

- Nach Auto-`DEF 360` startet ein neuer `Engage`-Waypoint eine aktive Movement-Execution mit `command_type == "engage"`.
- Waehrend dieser aktiven Movement-Execution meldet die Security nicht mehr `DEF 360`, sondern ein directional Moving-Security-Bild in Ziel-/Marschrichtung.
- Ein Close-Contact-Engage mit sichtbarem, fittem Gegner erzeugt einen `fired`-Contact-Diagnoseeintrag und einen Fire-Event.
- Auto-`DEF 360` bleibt nach Zielabschluss feuerbereit; Defense bedeutet nicht Feuerverbot.
- Bestehende Auto-Defend-, Contact- und Movement-Regressionen bleiben gruen.

## Betroffene Dateien

- `scripts/tactical/fireteam_security_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_465_fireteam_engage_resume_contact_progress.gd`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_465_fireteam_engage_resume_contact_progress.gd`
- Relevante Regressionen aus TASK_462 bis TASK_464.
- `git diff --check`

## Risiken / offene Punkte

Wenn der Verifier `no_los` oder `out_of_range` meldet, ist der naechste Slice ein gezielter Terrain-/LOS-/Reichweitenbefund. Wenn er `candidate_pending_detection_or_contact_state` meldet, liegt der naechste Fix im ContactTracker-/Detection-Uebergang.
