# TASK_258 - Fixed Window Clipping Scrollbar Playability Audit

## Ziel
Alle wichtigen Screens sollen automatisiert auf feste Fenster, abgeschnittene Inhalte, fehlende Scrollbars, ueberlaufende Texte, verdeckte Controls und unbrauchbare Innenlayouts geprueft werden.

Die Hauptfenster bleiben fest. Scrollbars sind dort erlaubt und erwuenscht, wo Inhalte laenger als das feste Fenster sind.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_177 - Drop Light Fixed UI Layout Contract
- TASK_181 - Drop Light Fixed Window Audit Patch
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_229 - Map Editor Usability Authoring Pass
- TASK_256 - Automated Playability Coverage Contract
- TASK_257 - Button Reachability and Interaction Verifier

## Kontext
Der User will feste Fenster, aber keine abgeschnittene Bedienung. Das bedeutet: Top-Level-Fenster duerfen nicht responsive wegrutschen, aber Innenbereiche muessen bei langen Listen, Texten, Roster, Loadout, Editor-Palette und Character Sheets korrekt scrollen.

## Umfang
1. Feste Fenster:
   - Hauptfenster gegen Layout-Vertrag pruefen.
   - Keine Stretch-Ratio oder nachbarabhaengige Groesse fuer Hauptfenster.
   - Backgrounds/Images duerfen keine Fenster verschieben.
2. Clipping:
   - Text, Buttons, Icons, Badges, Portraits und Previews liegen innerhalb ihres Containers.
   - Lange Namen/Traits/Loadout-Texte erzeugen keine unlesbaren Ueberlaeufe.
   - Buttons werden nicht halb abgeschnitten.
3. Scrollbars:
   - Lange Roster/Listen/Character Cards/Editor-Paletten liegen in ScrollContainern.
   - ScrollContainer sind bedienbar und zeigen bei Bedarf Scrollbars.
   - Pflichtaktionen bleiben erreichbar, auch wenn Listen lang sind.
4. Viewport-Profile:
   - Primaer 1920x1080 als Zielvertrag.
   - Optional 1280x720 als Warnprofil, wenn ein Screen dort bewusst nicht final unterstuetzt ist.
   - Keine variable Hauptfensterlogik als Fix.
5. Testdaten:
   - Lange NPC-Namen.
   - Viele Roster-Eintraege.
   - Viele Loadout-Optionen inklusive dekorativer/nicht waehbarer Waffen.
   - Lange Editor-Palette.
6. Report:
   - Abgeschnitten, fehlender Scrollcontainer, offscreen, overlap, zu kleines Fenster, unerwartet variable Hauptfenstergroesse.

## Nicht-Ziele
- Kein neuer Designstil.
- Kein Umbau auf responsive Layouts.
- Kein Pixel-perfect Screenshot-Test.
- Keine Kuerzung von Gameplay-Texten ohne eigenen Textpass.

## Akzeptanzkriterien
- [x] Alle Top-Level-Hauptfenster bleiben fest nach Vertrag.
- [x] Pflichtcontrols und Pflichttexte sind nicht abgeschnitten.
- [x] Lange Inhalte haben Scrollbereiche oder werden als Defekt gemeldet.
- [x] Roster, Character Sheet, Loadout und Editor-Palette bleiben bei langen Daten bedienbar.
- [x] Ein Report nennt konkrete Node-Pfade und Screen-Namen fuer Clipping/Scrollbar-Probleme.
- [x] Kein Fix fuehrt variable Hauptfenstergroessen ein.

## Umsetzung
- `scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd` prueft Main Menu, Multiplayer Lobby, Homebase, FOB, Mission-HUD und Map Editor gegen feste Fenster, Viewport-Clipping, ScrollContainer, lange Testdaten und kritische Text-/Button-Ueberlaeufe.
- Homebase, FOB und Mission nutzen lange deterministische Testdaten fuer Roster, Transfer-/Loadout-Listen, Shipcards und HUD-Inhalte, ohne Hauptfenster dynamisch zu vergroessern.
- `docs/reports/playability_layout_clipping_scrollbar_report.md` dokumentiert die automatisierte Abdeckung und `docs/manual_checks/playability_layout_remaining_visual_checklist.md` haelt die verbleibenden visuellen Full-HD-/1280x720-Pruefpunkte fest.

## Erwartete Dateien
- `scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- `docs/reports/playability_layout_clipping_scrollbar_report.md`
- `docs/manual_checks/playability_layout_remaining_visual_checklist.md`
- `scripts/tests/playability/playability_test_harness.gd`
- `docs/tasks/TASK_258_fixed_window_clipping_scrollbar_playability_audit.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd` (67/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_181_drop_light_fixed_window_audit_verifier.gd` (43/0)
- [x] Manueller Full-HD-Sichtcheck nur fuer gemeldete offene Punkte dokumentiert.
- [x] `git diff --check`

## Risiken
- Headless kann Text-Clipping nur ueber Control-Rect- und Font-Metrik-Naeherrungen pruefen.
- Einige gewollte Clips, z. B. Portrait-Masks, muessen als erlaubte Ausnahmen markiert werden.

## Naechster Schritt
Nach TASK_258 prueft TASK_259 Charakterkarten, Roster-Wege und Umstellungen ueber mehrere Screens.
