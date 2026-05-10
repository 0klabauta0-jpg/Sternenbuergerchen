# TASK_312 - Dropship Command Matrix LZ Go Layout

## Ziel
Die Dropship-LZ-Steuerung soll in der Command Matrix sinnvoll angeordnet werden. LZ-Pick wirkt aktuell "aus der Reihe" und kann weiter links stehen. Der Go-Button soll aus seinem grossen einsamen Platz in Fenster 17 heraus und in Fenster 16, die Command Matrix, wandern.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_191 - Command Chain Selection and Area Feedback Pass
- TASK_270 - Commander to Fireteam Leader Delegation Contract
- TASK_271 - Tactical Command Modes ROE Fire Rules
- TASK_275 - Command Button Hierarchy Arrangement Overhaul
- TASK_302 - Dropship Flight Deck Boarding Rename Userology
- TASK_311 - Dropship LZ Target Pick Accuracy Contract

## Kontext
Der Go-Button steht aktuell zu allein und nimmt zu viel Platz in Fenster 17. Gleichzeitig gehoert die Entscheidung "LZ waehlen / Vorsichtig-Normal-Aggressiv / Go" fachlich in die Befehlsmatrix. Der User moechte den Go-Button in Fenster 16, Command Matrix, sehen.

## Umfang
1. Layout-Audit:
   - Bestehende Fenster 16 Command Matrix und Fenster 17 pruefen.
   - Dropship-spezifische Commands und Risiko-/Approach-Style finden.
   - LZ-Pick-Platzierung im Command-Flow erfassen.
2. Command Matrix:
   - Go-Button in Fenster 16 integrieren.
   - Go nur aktiv, wenn Ziel-LZ und benoetigte Transport-/Team-Voraussetzungen erfuellt sind.
   - Risiko-/Approach-Auswahl `vorsichtig`, `normal`, `aggressiv` bleibt sichtbar in der Naehe.
3. LZ-Pick:
   - LZ-Pick weiter links/naheliegender zum Karten- oder Zielauswahl-Flow.
   - LZ-Pick zeigt gewaehlte Ziel-LZ aus TASK_311.
   - Nicht nur Strich/Approach-Linie.
4. Fenster 17 entlasten:
   - Entfernten Go-Platz freigeben.
   - Fenster 17 nur noch fuer Status/Preview/Feedback nutzen, falls fachlich passend.
5. Verifier:
   - Go-Button existiert in Command Matrix.
   - Fenster 17 enthaelt keinen grossen einsamen Go-Button mehr.
   - Button-Aktivierung folgt LZ-/Team-/Dropship-State.
   - LZ-Pick liegt in der erwarteten UI-Gruppe.

## Nicht-Ziele
- Keine neue LZ-Abweichungslogik; die kommt aus TASK_311.
- Keine komplette Command-Matrix-Neugestaltung.
- Kein Entfernen anderer taktischer Befehle.

## Akzeptanzkriterien
- [x] Go-Button liegt in Fenster 16 Command Matrix.
- [x] Go-Button ist nur aktiv, wenn LZ/Team/Dropship-Zustand passt.
- [x] LZ-Pick ist logisch bei Ziel-/Kartenwahl eingeordnet und nicht aus der Reihe.
- [x] Fenster 17 verliert den uebergrossen einsamen Go-Platz.
- [x] Risiko-/Approach-Style bleibt neben dem Go-Flow lesbar.
- [x] Verifier prueft UI-Ort, Enable-State und Layout-Snapshot.

## Erwartete Dateien
- `scripts/ui/...`
- `scripts/mission/...`
- `scenes/...`
- `scripts/tests/task_312_dropship_command_matrix_lz_go_layout.gd`
- `docs/manual_checks/dropship_command_matrix_lz_go_layout.md`
- `docs/tasks/TASK_312_dropship_command_matrix_lz_go_layout.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_312_dropship_command_matrix_lz_go_layout.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_275_command_button_hierarchy_arrangement_overhaul.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_191_command_chain_selection_area_feedback_pass.gd`
- [ ] Manueller Command-Matrix-Sichtcheck.
- [ ] `git diff --check`

## Risiken
- Wenn Go zu weit vom LZ-Pick entfernt ist, wird der Flow weiter unklar.
- Wenn Go zu frueh aktiv wird, entstehen halbfertige Dropship-Commands.
- Fenster 16 darf nicht durch Dropship-Spezialfall ueberladen werden.

## Naechster Schritt
TASK_313 prueft Dropship-Sichtbarkeit/Feedback, gerade wenn das Dropship nicht kommt.
