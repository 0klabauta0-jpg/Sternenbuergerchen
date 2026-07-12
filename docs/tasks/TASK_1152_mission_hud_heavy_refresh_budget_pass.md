# TASK_1152 - Mission HUD Heavy Refresh Budget Pass

## Ziel / Problem
Der echte TASK_1151-Zwei-EXE-Lauf erreicht First Contact und First Fire, misst auf dem Host aber weiterhin rund 266 ms fuer einen kompletten Missions-HUD-Refresh. Der direkte Simulationstick liegt dagegen nur bei etwa 0,4 bis 1,3 ms. Der sichtbare Host-Pfad soll fluessiger werden, ohne Eingabefeedback oder Gameplay-Wahrheit zu verzögern.

## Ursache / Sinnhaftigkeit
Der periodische Refresh baut trotz vorhandener Delta-Guards weiterhin teure Strategietexte, Craft-Control-Zustaende, Primary-Status und Fireteam-Card-Snapshots. TASK_1151 hat leichte und schwere Cadence getrennt; TASK_1152 soll nun unveraenderte schwere Teilflaechen anhand stabiler Signaturen ueberspringen.

## Umfang
- Die teuersten schweren HUD-Teilflaechen einzeln messen und ihre Eingabedaten bestimmen.
- Read-only Signaturen beziehungsweise Dirty-Flags fuer unveraenderte Strategietexte, Craft Controls, Primary Status und Fireteam Cards einsetzen.
- Direkte Spieleraktionen und relevante Runtime-Events duerfen weiterhin sofort einen vollstaendigen Refresh ausloesen.
- Den echten Zwei-EXE-First-Contact-Lauf erneut messen.

## Nicht-Ziele
- Keine Gameplay-State-Verlagerung in die UI.
- Keine Abschaltung sichtbarer Missionselemente.
- Keine pauschale FPS-Behauptung aus einem einzelnen Frame-Snapshot.
- Kein Combat-, Movement- oder Netzwerk-Rewrite.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_1151_connected_release_movement_pace_contact_approach_hardening.md`
- `docs/performance/ui_hud_comic_bubble_profile_report.md`

## Akzeptanzkriterien
- Unveraenderte schwere HUD-Teilflaechen werden nicht erneut vollstaendig berechnet.
- Direkte Eingaben aktualisieren die betroffenen Flaechen im selben Bedienereignis.
- Der gemessene komplette beziehungsweise amortisierte Host-HUD-Pfad sinkt deutlich gegenueber dem TASK_1151-Befund von rund 266 ms.
- TASK_1043, TASK_1044, TASK_399, TASK_479, TASK_1150, TASK_1151 und TASK_222 bleiben gruen.
- Der Zwei-EXE-Release-Lauf erreicht weiterhin gemeinsamen Kontakt und First Fire.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- fokussierter TASK_1152-Verifier
- Status, Roadmap und HTML-Handbuch

## Lokale Pruefung
- Godot-Headless-Verifier fuer TASK_1152 und bestehende HUD-Hotpath-Gates.
- `scripts/tests/run_task_222_performance_gate.ps1`.
- echter exportierter Host-/Client-First-Contact-Lauf mit Performance-Evidence.
- `git diff --check` und Release-Startcheck.

## Risiken / offene Punkte
Ein Signatur-Guard darf keine echte Zustandsaenderung verschlucken. Deshalb muessen Signaturen aus den gelesenen Runtime-Snapshots entstehen und direkte Eventpfade weiterhin einen erzwungenen Refresh ausloesen koennen.
