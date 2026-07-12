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

## Abschluss 2026-07-12
- Strategiestatus, Craft Controls und die Fireteam-Kartengruppe besitzen stabile periodische Signaturen. Direkte Bedienereignisse behalten `force_heavy_surfaces = true`.
- Dropship-Runtime-Feedback, autoritative Dropship-Snapshots und Flank-Feedback nutzen den guardierten Runtime-Pfad statt den Vollrefresh zu erzwingen.
- Der Release-Trace fuehrt Apply-/Skip-Zaehler fuer alle schweren Teilflaechen mit.
- Echter Zwei-EXE-Beleg: Gate `pass` nach 69,8 Sekunden, beide Prozesse aktiv, gemeinsamer Kontakt und First Fire.
- Gemessener periodischer Host-HUD-Pfad: rund 68 ms statt rund 266 ms im TASK_1151-Ausgangslauf, etwa 74 Prozent weniger.
- Host-Guard-Evidence: Craft Controls 56 Apply / 45 Skip, Strategiestatus 55 Apply / 46 Skip, Fireteam-Kartengruppe 84 Apply / 17 Skip.
- Client-FPS im vergleichbaren Zwei-EXE-Lauf: rund 30 statt zuvor rund 24. Der Host-FPS-Einzelwert bleibt wegen der Snapshot-Lage kein belastbarer Durchschnittswert.
- Verifier: TASK_1152 18/18, TASK_1043 14/14, TASK_1044 15/15, TASK_399 9/9, TASK_479 25/25, TASK_1150 18/18, TASK_1151 64/64, TASK_1117 15/15, TASK_222 82/82.

## Naechster Befund
Der leichte periodische Pfad kostet im gemessenen Host-Snapshot noch rund 68 ms, davon etwa 29 ms Primary Labels und 40 ms Mission Panels. Das ist der naechste klar abgegrenzte Performance-Slice.
