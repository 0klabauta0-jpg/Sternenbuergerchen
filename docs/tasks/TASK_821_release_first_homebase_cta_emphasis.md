# TASK_821 - Release First Homebase CTA Emphasis

## Ziel / Problem
Nach dem sauberen Release-Launch ist der erste Singleplayer-Homebase-Bildschirm technisch bereit, aber der naechste Spielergriff muss staerker als primaere Handlung sichtbar werden. Der Screenshot-Befund war nicht nur ein Blocker, sondern auch ein Lesbarkeitsproblem: viel Flaeche, kleine Hinweise, unklare Prioritaet.

## Sinnhaftigkeit / Ursache
TASK_810 prueft den CTA technisch. Fuer einen angenehmeren, spielbaren ersten Eindruck braucht der fertige Zustand eine klar priorisierte, visuell messbare Fuehrung: `Start Mission` ist der primaere Griff, und derselbe Next-Step-Hinweis muss am Startbutton und im Readiness-Cue haengen.

## Umfang
- Pre-Mission-Readiness-Cue bekommt einen dedizierten Emphasis-Style.
- Cue wird etwas groesser und hoeher, ohne einen neuen Bedienpfad zu erzeugen.
- `Start Mission` traegt denselben Release-Next-Step-Hinweis als Tooltip/Meta.
- Neuer read-only Snapshot `get_release_candidate_first_homebase_cta_emphasis_snapshot()`.
- Headless-Verifier fuer den echten `Einzelspieler`-Pfad.

## Nicht-Ziele
- Kein neuer Startbutton.
- Kein automatischer Missionstart.
- Kein Screenshot-/Pixeltest.
- Keine Gameplay-, Mission-, UI- oder Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_810_station_reentry_release_candidate_first_mission_cta_visual_smoke.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- `Einzelspieler` oeffnet Homebase und liefert den TASK_821-Snapshot.
- Snapshot ist read-only.
- TASK_810-CTA-Smoke bleibt gruen.
- CTA meldet `task_821_release_first_homebase_cta_v1`.
- CTA-Prioritaet ist `primary`.
- CTA-Font und Mindesthoehe sind gegen den alten kompakten Readout angehoben.
- `Start Mission` traegt denselben Cue-Text wie der Readiness-Cue.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_821_release_first_homebase_cta_emphasis.gd`
- `docs/tasks/TASK_821_release_first_homebase_cta_emphasis.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_821_release_first_homebase_cta_emphasis.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_810_station_reentry_release_candidate_first_mission_cta_visual_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte Fensterblick bleibt weiterhin noetig, weil Font, Kontrast und Blickfuehrung erst im sichtbaren Release-Fenster final bewertet werden koennen.
- Das ist bewusst ein kleiner First-Screen-Polish und kein Homebase-Layout-Rewrite.
