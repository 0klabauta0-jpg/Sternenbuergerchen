# TASK_783 - Station Reentry Firefight Command Surface Polish

## Ziel / Problem
TASK_782 kann belegen, dass Folgezeile, primaerer Griff, Quick-Actions oder No-Auto-Command-Grenze im sichtbaren Command-Surface-Lauf unklar sind. TASK_783 macht daraus eine stabile, kompakte Surface-Struktur fuer den ersten Firefight-Folgegriff.

## Sinnhaftigkeit / Ursache
Der Spieler darf nach dem ersten Feuerwechsel nicht im HUD suchen muessen. Der naechste Griff muss als kurze Reihenfolge lesbar sein: `NEXT`, primaerer Button, Quick-Action-Rail und Guard-Zeile. Gleichzeitig darf die Anzeige keine zweite Command-Wahrheit werden und keine Befehle automatisch ausfuehren.

## Umfang
- Read-only Polish-Contract fuer TASK_782-Findings und TASK_780-Interaction-Polish.
- Stabile Surface-Struktur:
  - `interaction_line`
  - `primary_action`
  - `quick_action_rail`
  - `guard_line`
- Guard-Zeile benennt `NO AUTO CMD` und `EXISTING BUTTONS`.
- TASK_783 behandelt nur belegte Surface-Reibung:
  - fehlende/unklare Folgezeile
  - unklarer Primary-Action-Fokus
  - versteckte Quick-Actions
  - unklare Auto-Command-Grenze
  - zu dichte Surface
- Externe Befunde wie Host/Client-Abweichung, Hold-Fire-Systemluecken, Selected-Fireteam-Mismatch oder Performance-Stutter werden gezielt auf ihre eigenen Tasks geroutet.

## Nicht-Ziele
- Kein neues Command-UI-System.
- Kein Ausfuehren von HOLD/FLANK/SUP/HOLD FIRE.
- Keine Combat-, Damage-, Navigation- oder Multiplayer-Authority-Mutation.
- Kein automatischer Screenshot-/Sichtentscheid.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_782_station_reentry_firefight_command_surface_findings.md`
- `docs/tasks/TASK_780_station_reentry_firefight_interaction_polish.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`
- `scripts/mission/station_reentry_firefight_command_surface_polish.gd`

## Akzeptanzkriterien
- `StationReentryFirefightCommandSurfacePolish.build_snapshot()` liefert ein stabiles TASK_783-Schema.
- Fehlende oder offene TASK_782-Findings blockieren und routen zurueck auf sichtbaren Review.
- Gruene TASK_782-Findings plus gruener TASK_780-Interaction-Polish erzeugen `ready_for_command_surface_polish_review`.
- Surface enthaelt vier stabile Zeilen: Interaction, Primary, Quick-Action-Rail, Guard.
- Guard-Zeile nennt No-Auto-Command und bestehende Buttons.
- In-Scope-Issue-Flags werden als `polished_issue_ids` markiert.
- Externe Issue-Flags routen auf passende Folge-Tasks statt still im Polish zu verschwinden.
- Der Snapshot bleibt read-only und erzeugt keine Navigation, Commands, FireEvents oder DamageEvents.
- Der HTML-Bericht exportiert TASK_783-Manifestpfad und Polish-Readiness.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_command_surface_polish.gd`
- `scripts/tests/task_783_station_reentry_firefight_command_surface_polish.gd`
- `docs/tasks/TASK_783_station_reentry_firefight_command_surface_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_783_station_reentry_firefight_command_surface_polish.gd`
- Regression: TASK_782, TASK_781, TASK_780
- `git diff --check`

## Risiken / offene Punkte
TASK_783 poliert die Surface-Struktur als Contract/Presenter. Der echte sichtbare Fensterentscheid bleibt weiterhin ein Playtest-/Recapture-Schritt; externe Findings duerfen nicht in TASK_783 versteckt werden.
