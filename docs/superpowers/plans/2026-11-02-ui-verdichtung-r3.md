# Native UI R3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Verbliebenen Leerraum und unklare Anzeigen im nativen UI konkret beseitigen.

**Architecture:** Bestehende Godot-Controls lesen vorhandene Owner und delegieren Commands unverändert. Inhaltsabhängige Layouts sind signal-/signaturgetrieben; Detailansichten bewahren Rohinformationen.

**Tech Stack:** Godot 4.6.2, GDScript, lokale HTML/JavaScript-Workbench, Python/Node für Nachweise.

**Spec:** `docs/tasks/TASK_UI_VERDICHTUNG_R3_20261102.md`, `docs/dev/ui_native_design_contract.md` und bestätigte Bildvorlagen.

## Global Constraints
- Kein zweiter Gameplay-/Transport-/Fortschrittszustand. Echtzeit ohne Pause.
- Keine per-frame Vollrebuilds/SceneTree-Scans/Layoutpolls. Schrift nicht zum Platzsparen verkleinern.
- R2 und Hauptcheckout bewahren; eigener R3-Nachweisordner, keine Mainintegration.
- Native Prüfgrößen 1920×1080 und 1280×720, fehlende Daten ehrlich darstellen.

## Review Focus
- Leere und volle Transportzustände: Arbeitsorte/Dropziele bleiben erreichbar.
- Reiner Fokuswechsel ohne Resize: keine alten Namen/Zustände im neuen Summary.
- Leeres, kurzes und umfangreiches Debrief: keine Fantasiefolgen, keine abgeschnittenen Rückwege.
- Pending/abgelehnte Missionsanfrage: niemals erfolgreiche Änderung vortäuschen.
- Detailöffnung/Schließen/Metawechsel: Eingabegrenzen, Kontext und Lebensdauer bleiben korrekt.

### Task 1: Vorbereitung verdichten
**Files:** `scripts/meta/homebase_screen.gd`, `scripts/meta/fob_screen.gd`, eigener `scripts/tests/ui_native_r3_preparation_verifier.gd`.
- [x] Aktuelle R2-Bilder/Owner lesen und konkrete sparse/populated-Kriterien festlegen.
- [x] Verifier für Größen, echte Aktionen/Dropziele und direkte Zustandswechsel anlegen; zentral RED prüfen.
- [x] Inhaltsabhängige Darstellung und verständliche Beschriftung implementieren; zentrale gezielte GREEN-Prüfung.

### Task 2: Ergebnis nach Datenumfang begrenzen
**Files:** `scripts/meta/debrief_screen.gd`, eigener `scripts/tests/ui_native_r3_debrief_verifier.gd`.
- [x] Empty/sparse/rich aus vorhandenen Resultatfeldern definieren; keine neu erfundenen Daten.
- [x] Vorher scheiternde Größen-/Text-/Rückwegchecks zentral ausführen.
- [x] Begrenzte Karten/Fenster und klare Texte implementieren, alte Daten-/Callbackpfade erhalten; GREEN prüfen.

### Task 3: Missionsanzeigen verständlich darstellen
**Files:** `scripts/ui/mission_a5_hud_layout.gd`, erforderliche Präsentationsanschlüsse in `scripts/tests/mission_tactical_sandbox_controller.gd`, eigener `scripts/tests/ui_native_r3_mission_readout_verifier.gd`.
- [x] Primärtext und Rohdetails gegen aktuelle Runtimequelle abgrenzen.
- [x] Leer-/Pending-/bestätigte Zustände mit identischen Ownern im RED/GREEN-Verifier prüfen.
- [x] Kompakte Summary-/Detaildarstellung implementieren; Eingabe-/Lebensdauergates behalten.

### Task 4: Vergleich und Übergabe
**Files:** Capturehelper, eigener `docs/qa/ui_native_r3_20261102/`, neue native R3-Workbench, kleiner aktueller Link in der alten Konzeptseite, Task/Status/Designvertrag.
- [x] Nur betroffene bestehende und neue Verifier sequenziell ausführen; Fehler gezielt korrigieren.
- [x] Echte native Captures in beiden Größen und repräsentativen Datenzuständen aufnehmen und ansehen.
- [x] Workbench aus vorhandener R2-Vorlage ableiten; alle sichtbaren/verdeckten Notizen samt JSON-Export offline prüfen.
- [x] Unabhängige Source-/Bildprüfung, Quellen-/Artefakthashes und Grenzen dokumentieren.
- [x] Nur Taskdateien committen und Task-Branch pushen; Hauptcheckout unverändert lassen.
