# TASK_267 - Contextual Help Coverage Layout Verifier

## Ziel
Alle kontextuellen Hilfe-Popups sollen automatisiert auf Abdeckung, Textlaenge, Wrapping, Positionierung, Abschaltbarkeit, Hover-Timing und fehlende IDs geprueft werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_263 - Contextual Help Popup UX Contract
- TASK_264 - Contextual Help Popup Component Settings Toggle
- TASK_265 - Character Sheet Loadout Help Content Pass
- TASK_266 - Command Mission Editor Settings Help Content Pass
- TASK_258 - Fixed Window Clipping Scrollbar Playability Audit

## Kontext
Hilfe-Popups koennen selbst neue UI-Fehler erzeugen: sie koennen abschneiden, zu breit werden, andere Buttons verdecken, trotz ausgeschalteter Hilfe auftauchen oder wichtige Controls ohne Erklaerung lassen. Dieser Task macht daraus ein Gate.

## Umfang
1. Coverage:
   - Pflicht-Controls aus Playability-Matrix brauchen `help_id`, sofern nicht bewusst ausgenommen.
   - Katalog-IDs muessen existieren.
   - Unbenutzte oder verwaiste Hilfe-IDs reporten.
2. Textqualitaet:
   - Titel nicht leer.
   - Kurztext kompakt.
   - Detailtext optional, aber wenn vorhanden mit Zeilenumbruechen/Wrapping.
   - Keine extrem langen Einzeiler.
3. Layout:
   - Popup bleibt im Viewport.
   - Maximalbreite und Maximalhoehe werden eingehalten.
   - Detailhilfe ueberlaeuft nicht aus festen Fenstern.
   - Popup verdeckt das Ziel-Control nicht dauerhaft.
4. Settings:
   - Hilfe aus: keine Popups.
   - Kompakt: nur Kurzhilfe.
   - Erweitert/Long-hover: Detailhilfe erreichbar.
   - Globaler Help-Button wirkt sichtbar und testbar.
5. Timing:
   - Kein Popup sofort beim kurzen Ueberfahren.
   - Detailhilfe erst nach definierter laengerer Hover-Dauer oder Pin/Help-Modus.
6. Report:
   - Fehlende IDs, zu lange Texte, offscreen, Clipping, falscher Modus, Timing-Fehler.

## Nicht-Ziele
- Kein inhaltliches Lektorat aller Texte.
- Kein Screenshot-Pixelvergleich.
- Keine Accessibility-Zertifizierung.

## Akzeptanzkriterien
- [x] Pflichtcontrols haben Hilfe oder dokumentierte Ausnahme.
- [x] Keine Hilfe-Texte verletzen harte Laengen-/Wrapping-Regeln.
- [x] Popups bleiben im Viewport und sind nicht abgeschnitten.
- [x] Settings und globaler Help-Button schalten Verhalten korrekt.
- [x] Kurzhilfe und Detailhilfe haben unterscheidbare Timing-/Moduspfade.
- [x] Ein Report nennt alle offenen Help-Coverage- und Layout-Probleme.

## Erwartete Dateien
- `scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd`
- `docs/reports/contextual_help_coverage_layout_report.md`
- `docs/qa/playability_coverage_matrix.md`
- `data/contextual_help_catalog.json`
- `docs/tasks/TASK_267_contextual_help_coverage_layout_verifier.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `git diff --check`

## Risiken
- Manche visuelle Ueberdeckung ist subjektiv; der Verifier soll harte Fehler finden und unklare Faelle als manuelle Restpunkte markieren.
- Wenn jede Ausnahme erlaubt wird, verliert das Gate seinen Wert.

## Naechster Schritt
Nach TASK_267 kann TASK_268 einen End-to-End-Playability-Smoke nach der Hilfeintegration ausfuehren.
