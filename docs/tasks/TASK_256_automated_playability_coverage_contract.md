# TASK_256 - Automated Playability Coverage Contract

## Ziel
Es soll ein gemeinsamer Playability-Testvertrag entstehen, der festlegt, welche Screens, Wege, Buttons, Fenster, Scrollbereiche, Charakterkarten, Loadout-Faelle und State-Uebergaenge automatisiert geprueft werden muessen und welche Restpunkte bewusst manuell bleiben.

Der Fokus liegt darauf, die manuelle Testarbeit stark zu reduzieren und trotzdem sichtbar zu machen, welche Playability-Fragen noch offen sind.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_181 - Drop Light Fixed Window Audit Patch
- TASK_199 - Main Menu Shell and Background Image
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_227 - Main Menu Multiplayer Host Join Lobby Flow
- TASK_231 - App Shell Game Setup Integration and Open Items Review
- TASK_241 - Character Gameplay Playability Smoke
- TASK_250 - Asset Audio Background Playability Smoke

## Kontext
Viele Einzel-Smokes pruefen fachliche Pfade, aber nicht systematisch, ob der Spieler wirklich ueberall rankommt: Buttons koennen fehlen, deaktiviert sein, keinen Callback haben, abgeschnitten werden, in falschen Fenstern liegen, Scrollcontainer fehlen oder eine Umstellung kann unterwegs State verlieren. Dieser Task baut den gemeinsamen Rahmen fuer diese Pruefungen.

## Umfang
1. Coverage-Matrix:
   - Hauptmenue, Einstellungen, Einzelspieler, Multiplayer Host/Join, Editor, Homebase, FOB, Character Sheet, Loadout, Mission-HUD, Debrief.
   - Pro Screen: Pflichtbuttons, Pflichtfenster, Pflichtwege, Pflichtdaten, Scroll-/Overflow-Regeln.
   - Status pro Check: `automated`, `manual`, `blocked`, `not_applicable`.
2. Playability-Harness:
   - Gemeinsame Testhelfer fuer Screen-Instanzierung.
   - Button-Suche nach Node-Name, Text, Icon-Metadaten oder Action-ID.
   - Klick-/Signal-Helfer, ohne echte Gameplay-Wahrheit zu erfinden.
   - Layout-Helfer fuer feste Fenster, Viewport-Grenzen, Scrollcontainer und Clipping.
3. Screen-Flow-Vertrag:
   - Welche Wege der Spieler von A nach B gehen koennen muss.
   - Welche Rueckwege existieren muessen.
   - Welche Auswahl/State beim Wechsel erhalten bleiben muss.
4. Reportformat:
   - Markdown-Report fuer fehlende Controls, tote Buttons, abgeschnittene Elemente, fehlende Scrollbars, verlorenen State.
   - Kurze Liste der verbleibenden manuellen Sicht-/Gefuehlchecks.
5. Pflege-Regeln:
   - Neue Screens und neue Buttons muessen in die Matrix.
   - Nicht testbare Punkte brauchen eine begruendete manuelle Checkliste.

## Nicht-Ziele
- Kein kompletter Fix aller gefundenen Probleme.
- Kein visueller Pixelvergleich.
- Keine neue UI-Architektur.
- Kein Ersatz fuer finalen menschlichen Spielgefuehl-Check.

## Umsetzung
- `docs/qa/playability_coverage_matrix.md` definiert Screen-, Flow-, Layout-, Harness-, Report- und Pflegevertrag fuer die kommende Playability-QA-Serie.
- `scripts/tests/playability/playability_test_harness.gd` stellt wiederverwendbare Headless-Helfer fuer Scene-Instanzierung, Button-Findung, Button-Deskriptoren, sicheres Test-Pressing, Viewport-/Fixed-Rect-Pruefung, ScrollContainer-Findung, Clipping-Diagnose und Screen-Reports bereit.
- `scripts/tests/task_256_automated_playability_coverage_contract.gd` prueft Matrix-Pflichtabschnitte, relevante Screen-IDs, Flow-/Layout-IDs und die Basisfunktionen des Harness.

## Akzeptanzkriterien
- [x] `docs/qa/playability_coverage_matrix.md` listet alle relevanten Screens und Pflichtwege.
- [x] Automatisierbare und manuelle Checks sind getrennt markiert.
- [x] Ein gemeinsamer Playability-Testhelfer existiert.
- [x] Fehlende Testabdeckung wird als offen sichtbar, nicht still ignoriert.
- [x] Folge-Tasks koennen dieselbe Matrix und dieselben Helfer nutzen.
- [x] Ein TASK_256-Verifier prueft Matrix-Pflichtabschnitte und Harness-Basisfunktionen.

## Erwartete Dateien
- `docs/qa/playability_coverage_matrix.md`
- `scripts/tests/playability/playability_test_harness.gd`
- `scripts/tests/task_256_automated_playability_coverage_contract.gd`
- `docs/tasks/TASK_256_automated_playability_coverage_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_256_automated_playability_coverage_contract.gd` (50/0)
- [x] `git diff --check`

## Risiken
- Eine zu breite Matrix kann Pflegearbeit erzeugen, wenn sie unklar bleibt. Deshalb muessen Screen-Pflichtpunkte knapp und konkret sein.
- Zu viel Automatisierung ohne Bericht kann Fehler finden, aber schlecht erklaeren.

## Naechster Schritt
Nach TASK_256 kann TASK_257 alle Buttons und Interaktionen gegen diese Matrix pruefen.
