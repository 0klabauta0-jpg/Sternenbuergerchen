# TASK_275 - Command Button Hierarchy Arrangement Overhaul

## Ziel
Die Befehlsknoepfe sollen nach Ebenen und Kontext neu geordnet werden: Commander-Intent, Fireteam-Regeln, Area-Ziele, Ausfuehrung/GO, Ausbruch/Rueckfrage und Air-/Dropship-Aktionen. Der Spieler soll schneller verstehen, was er gerade befiehlt.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_180 - Mission Drop Light Fixed HUD Layout
- TASK_191 - Command Chain Selection and Area Feedback Pass
- TASK_257 - Button Reachability and Interaction Verifier
- TASK_258 - Fixed Window Clipping Scrollbar Playability Audit
- TASK_264 - Contextual Help Popup Component Settings Toggle
- TASK_271 - Tactical Command Modes ROE Fire Rules
- TASK_274 - Tactical Communication Feedback Layer

## Kontext
Mehr Taktikoptionen duerfen nicht einfach als weitere Buttons in #16 landen. Die UI braucht Gruppierung: Was ist Ziel? Was ist Regel? Was ist Ausfuehrung? Was ist Sonder-/Air-Command? Was ist nur Status?

## Umfang
1. Command-Gruppen:
   - Zielbefehle: Move, Take, Defend, Engage, Secure, Recon, Withdraw.
   - Regeln: Tempo, Feuerregel, Kontakt, Deckung, Security.
   - Plan: Rollenvorschlag, Rollen tauschen, Preview, GO.
   - Air/LZ: Dropship halten/rufen/abbrechen, LZ secure, Evac/Recover.
   - Ausbrueche: Confirm, Override, Abort, Regroup.
2. UI-Anordnung:
   - #16 Command Matrix fuer kurze Actions.
   - #17 Fireteam Details fuer aktive Regeln/Plan.
   - #18 Mission Control fuer Gesamtplan, GO, Air, critical warnings.
   - Keine langen Erklaertexte in Buttons.
3. Erreichbarkeit:
   - Button-Verifier aus TASK_257 erweitern.
   - Feste Fenster bleiben nach TASK_180/TASK_181.
   - Help-Popups fuer neue Button-Gruppen.
4. Kontextlogik:
   - Nur relevante Gruppen aktiv.
   - Disabled-Gruende sichtbar.
   - Multi-Selection und Single-Fireteam klar getrennt.
5. Report:
   - Vorher/Nachher-Button-Matrix und offene UX-Fragen.

## Nicht-Ziele
- Kein neues visuelles Theme.
- Kein Wegwerfen bestehender Command-Controller.
- Kein Responsive-Layout fuer Hauptfenster.
- Kein Tutorial.

## Akzeptanzkriterien
- [x] Command-Buttons sind nach Ziel, Regel, Plan, Air und Ausbruch gruppiert.
- [x] #16/#17/#18 haben klare Rollen und widersprechen sich nicht.
- [x] Alle Pflichtbuttons bleiben sichtbar, erreichbar und haben Disabled-Gruende.
- [x] Multi-Fireteam- und Single-Fireteam-Kontext sind unterscheidbar.
- [x] Help-Popups erklaeren neue Gruppen knapp.
- [x] Verifier prueft Buttonmatrix, Clipping, Signals und Kontextaktivierung.

## Erwartete Dateien
- `docs/dev/mission_command_button_hierarchy.md`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/ui/...`
- `scripts/tests/task_275_command_button_hierarchy_arrangement_overhaul.gd`
- `docs/tasks/TASK_275_command_button_hierarchy_arrangement_overhaul.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_275_command_button_hierarchy_arrangement_overhaul.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_257_button_reachability_and_interaction_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `git diff --check`

## Risiken
- Mehr Ordnung darf nicht mehr Klicks fuer Standardbefehle erzeugen.
- Air-/Ausbruch-Buttons duerfen normale Missionsbefehle nicht verdraengen.

## Naechster Schritt
Nach TASK_275 kann TASK_276 definieren, wie Fireteams bei Kontakt, Blockade oder Risiko eigenstaendig ausbrechen duerfen.
