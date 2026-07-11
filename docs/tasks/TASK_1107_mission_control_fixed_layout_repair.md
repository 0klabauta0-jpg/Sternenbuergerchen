# TASK_1107 - Mission Control Fixed Layout Repair

## Status: IMPLEMENTIERT

## Ziel / Problem
Der letzte offene Befund des Fixed-Window-Audits betrifft `#18 Mission Control`: Das reale Panelrechteck entspricht nach Szenenstart nicht dem zentralen Full-HD-Layoutvertrag `(1552,808,344,248)`.

## Sinnhaftigkeit / Ursache
Mission Control ist Teil des festen Bottom-Docks und muss neben Command Matrix und Selected Fireteam stabil bleiben. Container-Minimum-Sizes, Top-Level-Positionierung und spaete kompakte HUD-Anpassungen duerfen das Panel nicht aus seinem Contract-Rechteck druecken.

## Umfang
- Soll-/Ist-Rechteck ueber mehrere UI-Frames messen.
- Abweichenden Positionierungs- oder Minimum-Size-Pfad reparieren.
- ScrollContainer und sichtbaren Mission-Control-Status erhalten.
- Fixed-Layout-Metadaten und zentralen Contract beibehalten.

## Nicht-Ziele
- Keine Aenderung an Missions-, Combat- oder Multiplayer-Wahrheit.
- Kein Umbau der Mission-Control-Inhalte.
- Kein manueller Sichttest.
- Keine allgemeine Bottom-Dock-Neugestaltung.

## Relevante Contracts / Dokumente
- `scripts/meta/drop_light_layout_contract.gd`
- `docs/tasks/TASK_1106_coop_lobby_layout_hardening.md`
- `docs/reports/playability_layout_clipping_scrollbar_report.md`

## Akzeptanzkriterien
- Mission Control entspricht nach Initialisierung und spaeten Frames exakt `Rect2(1552,808,344,248)`.
- Command Matrix und Selected Fireteam bleiben auf ihren bestehenden Contract-Rechtecken.
- Mission-Control-Scrollbereich bleibt nutzbar.
- TASK_258 ist 71/71 gruen.
- Keine Commands, Effects oder Multiplayer-Mutationen durch den Layoutpfad.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1107_mission_control_fixed_layout_repair.gd`
- gegebenenfalls `scenes/tests/mission_reactivity_test.tscn`
- Status-, Roadmap- und HTML-Arbeitsreport-Dokumentation

## Lokale Pruefung
- TASK_1107 Verifier
- TASK_258 kompletter Fixed-Window-Audit
- Mission-HUD-/Command-Feedback-Regressionen
- Multiplayer-Mission-Smoke
- `git diff --check`

## Risiken / offene Punkte
Das Missionscontroller-Skript besitzt historisch viele UI-Polish-Pfade. Die Reparatur muss am zentralen Layout-Handoff ansetzen und darf keine weitere konkurrierende Geometriequelle einfuehren.

## Ergebnis
TASK_835 setzte auf dem sichtbaren Mission-Control-Statuslabel eine Mindestbreite von 420 Pixeln. Mit den Panel-Innenraendern wuchs `#18 Mission Control` dadurch von 344 auf 448 Pixel. Die Statuszeile hat nun keine konkurrierende Mindestbreite mehr, behaelt aber 84 Pixel Mindesthoehe, Smart-Wrap, Outline und Farbe. Der alte TASK_835-Area-Check nutzt bei noch ungelayoutetem Meta-Layer-Deep-Link die reale Scrollbreite oder die zentrale Contract-Innenbreite von 316 Pixeln. TASK_1107 ist 9/9, TASK_258 71/71 und TASK_835 28/28 gruen.
