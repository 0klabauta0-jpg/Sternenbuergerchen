# IMPLEMENTATION_STATUS

## Template
### Bereich
- Status:
- Relevante Docs/Contracts:
- Stand:
- Offene Punkte:
- Risiken:
- Lokale Pruefung:
- Naechster Schritt:

### TASK_585 - Mini AAR Debrief Screen Stub
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_585_mini_aar_debrief_screen_stub.md`, `docs/tasks/TASK_584_mini_aar_combat_metrics_shell.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: `MissionTacticalSandboxController.get_mini_aar_debrief_screen_snapshot()` baut aus dem TASK_584-Mini-AAR-Snapshot eine kleine read-only Debrief-Screen-Struktur mit Titel, Untertitel, Summary, Metrik-Rows, Chips und Grenztext.
- Stand: Der Grenztext benennt bewusst: keine XP, keine Ammo und keine echte Suppression. Der Stub mutiert weder MissionResult noch Combat-, Ammo-, XP- oder Skill-State.
- Stand: Der laufende HTML-Zwischenbericht benennt TASK_585 als erledigten Arbeitsstand und TASK_586 als naechsten moeglichen Return-to-Homebase-Handoff.
- Risiken/offen: Noch kein navigierbarer Debriefing-Screen und kein Ruecksprung in den Homebase-/Meta-Loop. Echte Mission-Result-Visualisierung, XP, Skillentwicklung, Ammo und Suppression-Wirkung bleiben eigene Tasks.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_585_mini_aar_debrief_screen_stub.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_584_mini_aar_combat_metrics_shell.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_583_suppress_fire_aar_report_panel_readability.gd`, `git diff --check`.
- Naechster Schritt: `TASK_586 - Debrief Return To Homebase Handoff`, wenn der Debrief-Stub nach Missionsende sauber in den Homebase-/Meta-Loop fuehren soll.

### TASK_584 - Mini AAR Combat Metrics Shell
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_584_mini_aar_combat_metrics_shell.md`, `docs/tasks/TASK_583_suppress_fire_aar_report_panel_readability.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: `MissionTacticalSandboxController.get_mini_aar_combat_metrics_snapshot()` sammelt vorhandene FireEvents, Hit-/Miss-Zaehler, Friendly-Fire-Event/Risk-Felder, TASK_583-SUP-Panel-Werte und Fireteam-Member-Status in einer kleinen read-only Mini-AAR-Schale.
- Stand: Der Snapshot liefert kompakte Summary- und Row-Daten fuer eine spaetere Debriefing-Oberflaeche, ohne MissionResult, Combat, Ammo, Suppression, XP oder Skills zu mutieren.
- Stand: Der laufende HTML-Zwischenbericht benennt TASK_584 als erledigten Arbeitsstand und TASK_585 als naechsten sinnvollen Debrief-Screen-Stub.
- Risiken/offen: Noch kein vollstaendiger Debriefing-Screen; TASK_585 stellt nur einen kleinen sichtbaren Stub bereit. `extracted_count` bleibt 0, solange kein konkretes Extract-Result-Feld geliefert wird. Echte Suppression-Wirkung, Ammo-Verbrauch, XP und Skillentwicklung bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_584_mini_aar_combat_metrics_shell.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_583_suppress_fire_aar_report_panel_readability.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_582_suppress_fire_outcome_aar_diagnostic_stub.gd`, `git diff --check`.
- Naechster Schritt: durch `TASK_585 - Mini AAR Debrief Screen Stub` erledigt; naechster Anschluss ist `TASK_586 - Debrief Return To Homebase Handoff`.

### TASK_583 - Suppress Fire AAR Report Panel Readability
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_583_suppress_fire_aar_report_panel_readability.md`, `docs/tasks/TASK_582_suppress_fire_outcome_aar_diagnostic_stub.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: `MissionTacticalSandboxController.get_suppress_fire_aar_report_panel_snapshot()` baut aus dem TASK_582-Zaehler ein kompaktes read-only Report-Panel-Snapshot mit Titel, Summary, Chips und Fireteam-Zeilen.
- Stand: Der Panel-Detailtext nennt explizit die Grenze: keine Ammo, keine echte Suppression und kein Damage-Mod. Damit bleibt der AAR-Wert ehrlich lesbar, ohne Gameplay-Wahrheit in UI/Report zu verschieben.
- Stand: Der Verifier prueft den integrierten Missionspfad bis SUP-Fire, liest das Report-Panel zweimal und bestaetigt, dass weder Command-Queue noch SUP-Count durch Snapshot-Lesezugriffe mutieren.
- Risiken/offen: Noch kein vollstaendiger Debriefing-Screen; allgemeine AAR-Kampfmetriken sind durch TASK_584 als Mini-Schale vorbereitet. Echte Suppression-Wirkung und Munitionsverbrauch bleiben eigene Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_583_suppress_fire_aar_report_panel_readability.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_582_suppress_fire_outcome_aar_diagnostic_stub.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_581_suppress_fire_intent_outcome_smoke.gd`, `git diff --check`.
- Naechster Schritt: durch `TASK_584 - Mini AAR Combat Metrics Shell` erledigt; naechster Anschluss ist `TASK_585 - Mini AAR Debrief Screen Stub`.

### TASK_582 - Suppress Fire Outcome AAR Diagnostic Stub
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_582_suppress_fire_outcome_aar_diagnostic_stub.md`, `docs/tasks/TASK_581_suppress_fire_intent_outcome_smoke.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: SUP-Contact-Decisions werden jetzt als deduplizierter read-only AAR-/Debug-Stub zaehlbar, sobald der Combat-Pfad tatsaechlich einen `fired`-Outcome mit `suppress_pressure_intent` meldet.
- Stand: `MissionCombatLoopDriver.get_suppress_fire_outcome_aar_diagnostic_snapshot()` liefert Schema, Gesamtcount, Count pro Fireteam, letzten SUP-Outcome und explizite No-Ammo-/No-Suppression-/No-Damage-Flags.
- Stand: `MissionTacticalSandboxController.get_suppress_fire_outcome_aar_diagnostic_snapshot()` prueft die integrierte Grenze und bestaetigt, dass Snapshot-Lesezugriffe keine Command-Queue und keinen SUP-Count mutieren.
- Risiken/offen: Noch kein echtes Debriefing-Panel, kein Ammo-Verbrauch und keine echte Suppression-Wirkung; der Stub ist nur der messbare Anker fuer Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_582_suppress_fire_outcome_aar_diagnostic_stub.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_581_suppress_fire_intent_outcome_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_580_suppress_fire_visual_tuning_findings.gd`, `git diff --check`.
- Naechster Schritt: durch `TASK_583 - Suppress Fire AAR Report Panel Readability` erledigt; naechster Anschluss ist `TASK_584 - Mini AAR Combat Metrics Shell`.

### TASK_581 - Suppress Fire Intent Outcome Smoke
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_581_suppress_fire_intent_outcome_smoke.md`, `docs/tasks/TASK_580_suppress_fire_visual_tuning_findings.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: `SUP` wird nach der Preview im Combat-/Resolver-Pfad als read-only `suppress_pressure_intent` diagnostisch sichtbar.
- Stand: `CombatFireDecisionResolver.build_fire_rule_outcome_diagnostic()` liefert einen stabilen Fire-Rule-Outcome-Snapshot; `MissionCombatLoopDriver` haengt ihn an Contact-Decision-Diagnostics; Mission-Control-/Combat-HUD-Text kann `SUP` kurz nennen.
- Stand: `get_suppress_fire_intent_outcome_snapshot()` prueft die integrierte Grenze: SUP-Intent sichtbar, aber keine Suppression-Effect-Payloads, kein Ammo-Verbrauch, keine Damage-Modifikation und keine UI-seitige Gameplay-Wahrheit.
- Risiken/offen: Echte Suppression-Wirkung, Munitionsverbrauch, Treffer-/Damage-Tuning und AAR-Messwerte bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_581_suppress_fire_intent_outcome_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_580_suppress_fire_visual_tuning_findings.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_570_hold_fire_discipline_mission_bridge.gd`, `git diff --check`.
- Naechster Schritt: durch `TASK_582 - Suppress Fire Outcome AAR Diagnostic Stub` und `TASK_583 - Suppress Fire AAR Report Panel Readability` erledigt; naechster Anschluss ist `TASK_584 - Mini AAR Combat Metrics Shell`.

### TASK_580 - Suppress Fire Visual Tuning Findings
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_580_suppress_fire_visual_tuning_findings.md`, `docs/tasks/TASK_579_suppress_fire_manual_f6_review.md`, `docs/tasks/TASK_578_suppress_fire_visual_polish_findings.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Die lokale SUP-F6-Evidence zeigte, dass die transparente Suppress-Area im dichten Raster/Stationsbild zu schwach als eigenstaendiger Zielbereich lesbar war.
- Stand: `TerrainMap3DView` nutzt jetzt `suppress_area_v2` mit staerkerer transparenter Fuellung, Overlay-Hoehe, Outline-Ring, zwei Achsenlinien, Boundary-Ticks und Snapshot-Metadaten fuer Fill/Outline/Hoehe/Line-/Marker-Counts.
- Stand: Der laufende HTML-Zwischenbericht nennt TASK_580 als erledigten Tuning-Slice und haelt die Grenze zu echter Suppression-/Ammo-/Combat-Wirkung weiter offen.
- Risiken/offen: Der finale menschliche Spielgefuehl-Test bleibt offen; echte Suppression-Wirkung, Munitionsverbrauch und AAR-Messwerte bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_580_suppress_fire_visual_tuning_findings.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_579_suppress_fire_manual_f6_review.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_578_suppress_fire_visual_polish_findings.gd`, `git diff --check`.
- Naechster Schritt: Vorschlag nach diesem Slice: ein kleiner Suppression-Intent-Outcome-Smoke, der ohne echtes Ammo-System prueft, ob `SUP` im Combat-Resolver nur als Disziplin-/Druckabsicht diagnostisch sichtbar bleibt.

### TASK_579 - Suppress Fire Manual F6 Review
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_579_suppress_fire_manual_f6_review.md`, `docs/tasks/TASK_578_suppress_fire_visual_polish_findings.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/html_report_workbench_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Der laufende HTML-Zwischenbericht enthaelt jetzt einen exportierbaren SUP-Area-F6-Sichtreview fuer Screenshotpfad, Viewport, Pflichtchecks, Farbe/Alpha, Groesse/Ueberdeckung, Statussprache, naechste Prioritaet und Freitextnotizen.
- Stand: Der Contract haelt fest, dass der Manual-Review read-only bleibt und keine Gameplay-Wahrheit, kein `GO`, keine Suppression-Wirkung und keinen Ammo-/Combat-State erzeugt.
- Risiken/offen: Das visuelle Tuning selbst ist noch nicht angewendet; TASK_580 soll nur belegte Sichtbefunde aus Screenshot/Playtest umsetzen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_579_suppress_fire_manual_f6_review.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_578_suppress_fire_visual_polish_findings.gd`, `git diff --check`.
- Naechster Schritt: `TASK_580 - Suppress Fire Visual Tuning Findings`, wenn konkrete F6-Sichtnotizen aus dem Report vorliegen.

### TASK_578 - Suppress Fire Visual Polish Findings
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_578_suppress_fire_visual_polish_findings.md`, `docs/tasks/TASK_577_suppress_fire_visual_evidence_pass.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/tactical_decision_clarity_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Die bestehende Waypoint-Intent-Preview traegt bei aktiver Fire-Rule `suppress` jetzt ein read-only `suppress_preview`-Dictionary in den Preview-Entries.
- Stand: `TerrainMap3DView` zeichnet daraus eine flache orange Suppress-Area am Ghost-Ziel und meldet `waypoint_intent_preview_suppress_area_count` plus Entry-Metadaten mit `visual_key = suppress_area_v1`.
- Stand: TASK_577 schreibt den neuen Suppress-Area-Count in das lokale Manifest; der HTML-Zwischenbericht nennt TASK_578 als erledigten belegten Polish.
- Risiken/offen: Die Area ist nur Preview und keine echte Wirkzone. Farbe, Alpha und Groesse brauchen weiter einen menschlichen F6-Sichtreview.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_578_suppress_fire_visual_polish_findings.gd`, `godot_console.exe --path . --script scripts/tests/task_577_suppress_fire_visual_evidence_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_576_suppress_fire_preview_readability_spike.gd`, `git diff --check`.
- Naechster Schritt: `TASK_579 - Suppress Fire Manual F6 Review`, wenn Farbe, Alpha und Groesse im echten Spielbild bewertet werden sollen.

### TASK_577 - Suppress Fire Visual Evidence Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_577_suppress_fire_visual_evidence_pass.md`, `docs/tasks/TASK_576_suppress_fire_preview_readability_spike.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/tactical_decision_clarity_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Der TASK_577-Capture-Smoke erzeugt eine lokale SUP-F6-/Visual-Evidence unter `tmp/suppress_fire_visual_evidence.png` und `tmp/suppress_fire_visual_evidence.json`.
- Stand: Das Manifest meldet SUP-Preview-Gate, Threat-Preview-Gate, `SUP AREA`-Text, Fire-Rule, Pressure-State, Radius, Primary3D-Preview-Zaehler und Viewport-Readback-/Evidence-Board-Status.
- Stand: Der laufende HTML-Zwischenbericht nennt die neuen Artefaktpfade und haelt den manuellen Review bewusst offen.
- Risiken/offen: Echte Suppression-Wirkung, Ammo-Verbrauch, AAR-Messwerte und finaler menschlicher Spielgefuehl-Test bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --path . --script scripts/tests/task_577_suppress_fire_visual_evidence_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_576_suppress_fire_preview_readability_spike.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_575_fire_rule_evidence_polish_findings.gd`, `git diff --check`.
- Naechster Schritt: `TASK_578 - Suppress Fire Visual Polish Findings`, wenn die Evidence konkrete Lesbarkeitsprobleme zeigt.

### TASK_576 - Suppress Fire Preview Readability Spike
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_576_suppress_fire_preview_readability_spike.md`, `docs/tasks/TASK_575_fire_rule_evidence_polish_findings.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/tactical_decision_clarity_contract.md`, `docs/dev/tactical_command_rules_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Bei aktiver Fire-Rule `suppress` und geplantem Move erzeugt der bestehende Waypoint-Intent-Preview-Pfad jetzt einen kompakten `SUP AREA`-Preview-Text im Selected-Fireteam-Ordertext.
- Stand: `get_suppress_fire_preview_readability_snapshot()` meldet Fire-Rule, Zielbereich, Radius, Pressure-State, Preview-Text und Read-only-Grenze, ohne GO oder Command-Queue-Mutation.
- Stand: Ohne `suppress` verschwindet der `SUP AREA`-Text wieder; `SUP` bleibt weiter ein kleiner Preview-/Regelzustand und kein grosses Ammo-/Suppression-System.
- Risiken/offen: Echte Suppression-Wirkung, Ammo-Verbrauch, AAR-Messwerte und ein realer F6-Sichttest bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_576_suppress_fire_preview_readability_spike.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_575_fire_rule_evidence_polish_findings.gd`, `git diff --check`.
- Naechster Schritt: `TASK_577 - Suppress Fire Visual Evidence Pass`, wenn `SUP AREA` im echten F6-/Visual-Blick geprueft werden soll.

### TASK_575 - Fire Rule Evidence Polish Findings
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_575_fire_rule_evidence_polish_findings.md`, `docs/tasks/TASK_574_fire_rule_real_f6_screenshot_review_pass.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Der belegte TASK_574-Folgepunkt ist umgesetzt: Der aktive ROE-/Fire-Rule-Button bekommt einen staerkeren, maschinell pruefbaren visuellen Affordance-State.
- Stand: `get_fire_rule_f6_readability_snapshot()` meldet jetzt Affordance-Zaehler, aktive Style-ID und Visual-Weight; TASK_574 schreibt diese Daten in das lokale Manifest.
- Stand: Der HTML-Zwischenbericht ist weiter als laufende Arbeits-Workbench aktualisiert und nennt TASK_576 als naechsten kleinen Anschluss.
- Risiken/offen: Der echte menschliche F6-/Hover-Spielgefuehl-Test bleibt offen; `suppress` bleibt bis zu einem eigenen Slice ein Fire-Rule-/Diagnosezustand.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_575_fire_rule_evidence_polish_findings.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_572_fire_rule_f6_readability_smoke.gd`, `godot_console.exe --path . --script scripts/tests/task_574_fire_rule_real_f6_screenshot_review_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_576 - Suppress Fire Preview Readability Spike`, wenn der `suppress`-Button als naechstes nicht nur Regelzustand, sondern vor GO als lesbare Suppress-Area-Preview vorbereitet werden soll.

### TASK_574 - Fire Rule Real F6 Screenshot Review Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_574_fire_rule_real_f6_screenshot_review_pass.md`, `docs/tasks/TASK_573_fire_rule_manual_screenshot_notes_pass.md`, `docs/tasks/TASK_572_fire_rule_f6_readability_smoke.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Der TASK_574-Capture-Smoke erzeugt eine Fire-Rule-/ROE-F6-Evidence unter `tmp/fire_rule_f6_real_review.png` und `tmp/fire_rule_f6_real_review.json`.
- Stand: Das Manifest meldet Readability-Gate, aktive Rule, Button-Labels, aktive Button-Regeln, Viewport-Readback-Status und markiert den menschlichen Review weiterhin als offen.
- Stand: Der HTML-Zwischenbericht nennt PNG/Manifest und zieht den naechsten Schritt auf belegte Fire-Rule-Evidence-Polish-Findings.
- Risiken/offen: Ein echter User-/Playtest-Geschmackstest bleibt offen; TASK_574 liefert Evidence, aber behauptet keinen abgeschlossenen Hover-/Tasteindruck. Sichtbarer Folgepunkt fuer TASK_575: aktive ROE darf im Bild staerker hervorgehoben werden, wenn der Screenshot-/Workbench-Befund das bestaetigt.
- Lokale Pruefung: `godot_console.exe --path . --script scripts/tests/task_574_fire_rule_real_f6_screenshot_review_pass.gd` (26 passed, 0 failed; `viewport_readback_available=true`), `godot_console.exe --headless --path . --script scripts/tests/task_573_fire_rule_manual_screenshot_notes_pass.gd` (32 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_572_fire_rule_f6_readability_smoke.gd` (28 passed, 0 failed), `git diff --check` (Exit 0).
- Naechster Schritt: `TASK_575 - Fire Rule Evidence Polish Findings`, wenn konkrete Befunde aus Screenshot/Manifest/Workbench-Export angewendet werden sollen.

### TASK_573 - Fire Rule Manual Screenshot Notes Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_573_fire_rule_manual_screenshot_notes_pass.md`, `docs/tasks/TASK_572_fire_rule_f6_readability_smoke.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/html_report_workbench_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Der laufende HTML-Zwischenbericht enthaelt jetzt einen exportierbaren Fire-Rule-/ROE-Screenshot-/Spielgefuehl-Notizblock.
- Stand: Exportiert werden Screenshotpfad, Viewport, aktive Rule, Button-/Tooltip-/Command-Flow-/Threat-Preview-Checks, Ratings, konkrete Follow-up-Prioritaet und freie ROE-Notizen.
- Stand: Der Bericht markiert den echten manuellen Screenshot bewusst nicht als erledigt; die Daten bleiben Playtest-/Arbeitsnotizen und keine Gameplay-Wahrheit.
- Risiken/offen: Der echte F6-Fire-Rule-Screenshot-/Hover-Sichttest muss weiterhin manuell ausgefuehrt und exportiert werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_573_fire_rule_manual_screenshot_notes_pass.gd` (32 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_572_fire_rule_f6_readability_smoke.gd` (28 passed, 0 failed), `git diff --check` (Exit 0).
- Naechster Schritt: `TASK_574 - Fire Rule Real F6 Screenshot Review Pass`, wenn echte ROE-Screenshot-/Spielgefuehl-Evidence aufgenommen und ausgewertet werden soll.

### TASK_572 - Fire Rule F6 Readability Smoke
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_572_fire_rule_f6_readability_smoke.md`, `docs/tasks/TASK_571_fire_rule_controls_readability_polish.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: `get_fire_rule_f6_readability_snapshot()` prueft die vier Fire-Rule-Controls im FullHD-HUD-Kontext read-only.
- Stand: Der Snapshot misst Sichtbarkeit, FullHD-/Command-Panel-Bounds, kompakte Button-Gruppe, Overlap gegen #17/#18, aktive Rule, kurze Labels sowie Tooltip-/Help-Metadaten.
- Stand: Der TASK_572-Verifier baut die Missionsszene in 1920x1080 auf, setzt ein Fireteam auf `hold` und prueft die neue F6-Lesbarkeit ohne Commands oder Combat-State zu mutieren.
- Risiken/offen: Der automatisierte Smoke ersetzt keinen menschlichen Screenshot-/Spielgefuehl-Test; `suppress` bleibt weiterhin ein Rule-/Diagnosezustand.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_572_fire_rule_f6_readability_smoke.gd` (28 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_571_fire_rule_controls_readability_polish.gd` (32 passed, 0 failed), `git diff --check` (Exit 0).
- Naechster Schritt: `TASK_573 - Fire Rule Manual Screenshot Notes Pass`, wenn echte Sichtnotizen/Spielgefuehl aus dem F6-Fenster strukturiert in den HTML-Bericht sollen.

### TASK_571 - Fire Rule Controls Readability Polish
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_571_fire_rule_controls_readability_polish.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/tactical_command_rules_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Das Missions-Command-Grid erzeugt vier kompakte Fire-Rule-Controls (`HF`, `RF`, `FW`, `SUP`) als bestehende HUD-Buttons statt als neue UI-Wahrheit.
- Stand: Die Controls nutzen den vorhandenen `set_selected_fireteams_fire_rule()`-Pfad, sind ohne Auswahl deaktiviert und spiegeln die eindeutige Fire-Rule der aktuellen Auswahl als aktiven Button.
- Stand: Command-Hierarchy-Metadaten, Help-IDs, Slotmarker und `get_fire_rule_controls_readability_snapshot()` machen die Bedienung pruefbar.
- Risiken/offen: Der finale menschliche FullHD-F6-Sichttest bleibt Folgearbeit; `suppress` bleibt weiterhin Rule-/Diagnosezustand bis zu einem spaeteren Suppression-/Ammo-Slice.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_571_fire_rule_controls_readability_polish.gd` (32 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_570_hold_fire_discipline_mission_bridge.gd` (46 passed, 0 failed), `git diff --check` (Exit 0).
- Naechster Schritt: `TASK_572 - Fire Rule F6 Readability Smoke`, wenn die neue Bedienung im echten F6-Blick auf Spielgefuehl, Textdichte und Panelplatz geprueft werden soll.

### TASK_570 - Hold Fire Discipline Mission Bridge
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_570_hold_fire_discipline_mission_bridge.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/tactical_command_rules_contract.md`, `docs/dev/tactical_decision_clarity_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Fireteams koennen jetzt explizite Fire-Rules (`hold`, `return`, `free`, `suppress`) als Mission-Command-Kontext erhalten, ohne dass UI/Preview Gameplay-Wahrheit speichern.
- Stand: Explizite Fire-Rules werden ueber Behavior-Metadaten und `FireteamMovementController` in `UnitCommand.fire_rule` und den Command-Dict geschrieben; ohne explizite Rule bleibt der alte Command-Pfad erhalten.
- Stand: `CombatFireDecisionResolver` blockiert `hold`, erlaubt `return` nur ueber ein Incoming-Fire-Fenster und behandelt `free`/`suppress` als feuerbereit; die Contact-Diagnostik nennt Fire-Rule, Fire-Status und Return-Fire-Fenster.
- Risiken/offen: Sichtbare Fire-Rule-Controls im Command-Panel sind Folgearbeit; `suppress` ist noch kein Ammo-/Suppression-System, sondern ein sauber durchgereichter Rule-Zustand.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_570_hold_fire_discipline_mission_bridge.gd` (46 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_569_frontier_probe_threat_preview_visual_review.gd` (31 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_568_frontier_probe_risky_contact_preview_fixture.gd` (30 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd` (32 passed, 0 failed), `git diff --check` (Exit 0).
- Naechster Schritt: `TASK_571 - Fire Rule Controls Readability Polish`, wenn die neuen Rules direkt im Missions-HUD bedienbar und lesbarer werden sollen.

### TASK_569 - Frontier Probe Threat Preview Visual Review
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_569_frontier_probe_threat_preview_visual_review.md`, `docs/tasks/TASK_568_frontier_probe_risky_contact_preview_fixture.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/tactical_decision_clarity_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Die Waypoint-Intent-Preview faerbt Threat-Linien in 2D und Primary3D jetzt nach Risk-State, ohne Blocked-/Friendly-Fire-/Overwatch-Rollen zu verlieren.
- Stand: `TerrainMap3DView.get_render_snapshot()` liefert Risk-State-, Line-Role- und Line-Color-Key-Zaehler fuer die Preview.
- Stand: Die Frontier-Probe-Fixture prueft `risky` als gelbe/risky Linie und `suicidal` als rote/suicidal Linien, waehrend die Line-Rollen weiter diagnostizierbar bleiben.
- Risiken/offen: Die Messbarkeit ersetzt keinen finalen menschlichen FullHD-Spielgefuehl-Test fuer Kontrast, Linienlaenge und Labeldichte.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_569_frontier_probe_threat_preview_visual_review.gd` (31 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_568_frontier_probe_risky_contact_preview_fixture.gd` (30 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd` (24 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd` (34 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_561_frontier_probe_multiplayer_manual_visual_review_guide.gd` (49 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd` (38 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_563_frontier_probe_multiplayer_f6_evidence_report_preview.gd` (49 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_564_frontier_probe_multiplayer_apply_visual_polish_findings.gd` (46 passed, 0 failed), `git diff --check` (Exit 0).
- Naechster Schritt: `TASK_570 - Hold Fire Discipline Mission Bridge`, wenn Feuerdisziplin als naechster spielbarer Taktikhebel an die lesbare Preview anschliessen soll.

### TASK_568 - Frontier Probe Risky Contact Preview Fixture
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_568_frontier_probe_risky_contact_preview_fixture.md`, `docs/tasks/TASK_567_frontier_probe_first_move_threat_preview_readability_pass.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/tactical_decision_clarity_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Die Frontier-Probe-Mission-Fixture setzt echte ContactTracker-Kontakte und prueft damit die bestehende First-Move-Threat-Preview gegen bekannte Feindpositionen.
- Stand: Ein einzelner bekannter Kontakt muss vor `GO` `RISKY` im Order-Text, mindestens eine Exposure und passende Threat-Line-Zaehler liefern.
- Stand: Drei bekannte klare Kontakte muessen vor `GO` `SUICIDAL`, mindestens drei Exposures und passende Threat-Line-Zaehler liefern.
- Risiken/offen: Die Fixture belegt die Daten-/Preview-Kette, ersetzt aber keinen manuellen FullHD-Sichttest fuer Farben, Linienlaenge und HUD-Lesbarkeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_568_frontier_probe_risky_contact_preview_fixture.gd` (28 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd` (32 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd` (24 passed, 0 failed), `git diff --check` (Exit 0).
- Naechster Schritt: `TASK_569 - Frontier Probe Threat Preview Visual Review`, wenn die Threat-Linien/Risk-Labels im echten F6-/FullHD-Blick bewertet und ggf. poliert werden sollen.

### TASK_567 - Frontier Probe First Move Threat Preview Readability Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_567_frontier_probe_first_move_threat_preview_readability_pass.md`, `docs/tasks/TASK_540_mission_first_move_decision_readability_pass.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/tactical_decision_clarity_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Die erste Move-Preview nennt im Selected-Fireteam-/Order-Text nun neben Distanz und ETA auch eine kompakte Risikozeile (`SAFE`, `RISKY`, `SUICIDAL` oder `RISK ?`).
- Stand: `get_frontier_probe_first_move_threat_preview_readability_snapshot()` fasst TASK_540, Waypoint-Intent-Preview, Command-Feedback und Primary3D-Render-Zahlen zusammen und prueft Risk-State, Grund, Ghost/Pfad und Threat-Line-Zaehler read-only.
- Stand: Ohne bekannte Kontakte bleibt die Preview ehrlich `unknown`, nennt aber `no_threat_context`/`no contact intel`, statt die Gefahr still zu verschweigen.
- Risiken/offen: Der integrierte Frontier-Probe-First-Move-Pfad erzeugt vor Sichtkontakt weiter keine kuenstlichen Threat-Lines. Ein naechster Fixture-Slice kann riskante/suizidale Kontaktlagen sichtbar im echten Flow anlegen.
- Risiken/offen: Der alte TASK_540-Meta-Homebase-Flow erreicht in diesem Arbeitslauf die Doku-Pruefung und haengt danach im integrierten Homebase/Mission-Startpfad; TASK_567 nutzt deshalb die stabile Mission-Fixture und prueft den First-Move-Snapshot dort. Das ist als separate Meta-Flow-Testhygiene zu behandeln.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd` (32 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd` (24 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd` (32 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_561_frontier_probe_multiplayer_manual_visual_review_guide.gd` (45 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd` (34 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_563_frontier_probe_multiplayer_f6_evidence_report_preview.gd` (43 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_564_frontier_probe_multiplayer_apply_visual_polish_findings.gd` (40 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_565_frontier_probe_multiplayer_real_f6_screenshot_review_pass.gd` (22 passed, 0 failed), `godot_console.exe --headless --path . --script scripts/tests/task_566_frontier_probe_multiplayer_f6_hover_panel_polish_pass.gd` (33 passed, 0 failed), `git diff --check` (Exit 0).
- Naechster Schritt: `TASK_568 - Frontier Probe Risky Contact Preview Fixture`, wenn die Preview als naechstes mit echter riskanter/suizidaler Kontaktlage im Frontier-Probe-Flow sichtbar gemacht werden soll.

### TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_566_frontier_probe_multiplayer_f6_hover_panel_polish_pass.md`, `docs/tasks/TASK_565_frontier_probe_multiplayer_real_f6_screenshot_review_pass.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Der sichtbare Mission-Teamchip nutzt nun kompakte Owner-/Spawn-Tokens (`Host`, `P2`, `A-LZ`, `B-LZ`), damit #18 Mission Control im echten F6-Fenster nicht mehr unruhig ueber mehrere Zeilen bricht.
- Stand: Tooltip und `status_text` behalten die vollstaendigen Multiplayer-Daten (`Host Peer 1`, `Peer 2`, `spawn_alpha`, `spawn_bravo`); die UI verschiebt keine Gameplay-Wahrheit.
- Stand: `get_frontier_probe_multiplayer_f6_hover_panel_polish_snapshot()` prueft Teamchip-Hover, sichtbare Textlaenge, Tooltip-Volltext, Einzeilen-Konfiguration, Panel-Bounds und Bottom-HUD-Weltverdeckung read-only.
- Risiken/offen: Native Tooltip-Position bleibt engine-seitig; TASK_566 prueft Hoverbarkeit und geschätzte Panel-/Weltverdeckung, ersetzt aber keinen finalen Spielgefuehl-Test.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_566_frontier_probe_multiplayer_f6_hover_panel_polish_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_560_frontier_probe_multiplayer_teamchip_tooltip_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_565_frontier_probe_multiplayer_real_f6_screenshot_review_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_567 - Frontier Probe First Move Threat Preview Readability Pass`, damit die erste Bewegungsentscheidung wieder staerker in Richtung taktischer Entscheidungsklarheit geht.

### TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_565_frontier_probe_multiplayer_real_f6_screenshot_review_pass.md`, `docs/tasks/TASK_562_frontier_probe_multiplayer_f6_visual_evidence_capture.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: TASK_562 wurde ohne `--headless` ausgefuehrt und erzeugt in dieser Umgebung einen echten FullHD-F6-Viewport-Readback mit `viewport_readback_available = true` und `generated_evidence_board = false`.
- Stand: Der reale Screenshot zeigte eine konkrete Reibung: #17 Selected Fireteam meldete `keine Einheiten aktiv`, obwohl sichtbare Member-Cards im Panel standen.
- Stand: `_build_fireteam_status_text()` nutzt nun denselben Fireteam-Unit-Fallback wie die sichtbaren Member-Cards, wenn die normale Selection-Liste leer laeuft.
- Risiken/offen: Der echte Hover-Teil bleibt manuell; TASK_565 behebt den ersten belegten Screenshot-Widerspruch und behauptet keinen abgeschlossenen Hover-Test.
- Lokale Pruefung: `godot_console.exe --path . --script scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_565_frontier_probe_multiplayer_real_f6_screenshot_review_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`, `git diff --check`.
- Naechster Schritt: TASK_566 ist umgesetzt; danach `TASK_567 - Frontier Probe First Move Threat Preview Readability Pass`.

### TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_564_frontier_probe_multiplayer_apply_visual_polish_findings.md`, `docs/tasks/TASK_562_frontier_probe_multiplayer_f6_visual_evidence_capture.md`, `docs/tasks/TASK_563_frontier_probe_multiplayer_f6_evidence_report_preview.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Der belegte Polish aus TASK_562/TASK_563 ist umgesetzt: Das Headless-Evidence-Board bekommt Region-Outlines, Raster und Swatch-Leiste.
- Stand: Das Manifest enthaelt `evidence_board_regions` und `evidence_board_region_count`; der HTML-Bericht zeigt eine Farblegende fuer Teamchip, Mission Control, Selected Fireteam, Strategic Panel, Fireteam Panel und Tooltip-Probe.
- Stand: Roadmap, Status, Contract und Verifier sind auf TASK_564 als erledigten Evidence-Polish und TASK_565 als naechsten echten F6-Screenshot-/Hover-Review-Slice weitergezogen.
- Risiken/offen: Der echte menschliche F6-/Hover-Sichttest bleibt offen; TASK_564 verbessert die automatische Review-Evidence und vermeidet geratenes HUD-Redesign.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_564_frontier_probe_multiplayer_apply_visual_polish_findings.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_563_frontier_probe_multiplayer_f6_evidence_report_preview.gd`, `git diff --check`.
- Naechster Schritt: TASK_565 nutzt den echten Viewport-Readback und behebt den ersten belegten #17-Widerspruch; danach `TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass`.

### TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_563_frontier_probe_multiplayer_f6_evidence_report_preview.md`, `docs/tasks/TASK_562_frontier_probe_multiplayer_f6_visual_evidence_capture.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/html_report_workbench_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Der laufende HTML-Zwischenbericht zeigt die TASK_562-Evidence direkt als Preview ueber `../../tmp/frontier_probe_mp_f6_visual_evidence.png`.
- Stand: Der Bericht exportiert PNG-Pfad, Manifest-Pfad, Viewport, Readability-Gate, Teamchip-Tooltip-Gate, Viewport-Readback-Status, Evidence-Board-Status und den weiterhin offenen manuellen Review-Status.
- Stand: Roadmap, Status, Contract und bestehende Manual-/Capture-Verifier sind auf TASK_563 als erledigten Report-Slice und TASK_564 als naechsten Apply-Polish-Slice weitergezogen.
- Risiken/offen: Wenn `tmp/` geloescht wurde, muss TASK_562 erneut laufen, damit die Preview im Browser ein Bild findet; der echte menschliche F6-/Hover-Sichttest bleibt offen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_563_frontier_probe_multiplayer_f6_evidence_report_preview.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_561_frontier_probe_multiplayer_manual_visual_review_guide.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd`, `git diff --check`.
- Naechster Schritt: TASK_564 macht das Evidence-Board selbst lesbarer; danach `TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass`.

### TASK_562 - Frontier Probe Multiplayer F6 Visual Evidence Capture
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_562_frontier_probe_multiplayer_f6_visual_evidence_capture.md`, `docs/tasks/TASK_557_frontier_probe_multiplayer_f6_readability_pass.md`, `docs/tasks/TASK_560_frontier_probe_multiplayer_teamchip_tooltip_polish.md`, `docs/tasks/TASK_561_frontier_probe_multiplayer_manual_visual_review_guide.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: Der neue Capture-Smoke baut den 1920x1080-Frontier-Probe-MP-F6-Zustand mit Host Peer 1 Alpha und Peer 2 Bravo reproduzierbar auf.
- Stand: Der Smoke prueft TASK_557-Readability und TASK_560-Teamchip-Tooltip weiter und schreibt `tmp/frontier_probe_mp_f6_visual_evidence.png` plus `tmp/frontier_probe_mp_f6_visual_evidence.json`; im Headless-Dummy ist das PNG ein markiertes Evidence-Board aus Snapshot-Rects.
- Stand: Das Manifest enthaelt PNG-Pfad, Viewport, Readback-/Evidence-Board-Status, Gate-Status, Teamchip-Text, Tooltip-Laenge und markiert den manuellen Review weiterhin als offen.
- Risiken/offen: Der Capture liefert Bildbeweis, ersetzt aber keinen menschlichen Hover-/Lesbarkeitsentscheid.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_561_frontier_probe_multiplayer_manual_visual_review_guide.gd`, `git diff --check`.
- Naechster Schritt: TASK_563 haengt die Evidence in den Bericht; danach `TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings`, sobald Screenshot/Manifest oder exportierte Review-Notizen konkrete Reibung nennen.

### TASK_561 - Frontier Probe Multiplayer Manual Visual Review Guide
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_561_frontier_probe_multiplayer_manual_visual_review_guide.md`, `docs/tasks/TASK_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.md`, `docs/tasks/TASK_560_frontier_probe_multiplayer_teamchip_tooltip_polish.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Der MP-F6-Reviewblock im Rolling-HTML-Bericht fuehrt die manuelle Sichtpruefung jetzt mit Detailchecks fuer Teamchip-Hover, Tooltip-Owner/Spawn, Objective/Cargo, Selected Fireteam, Dropship-Cards und Weltziel-Sichtbarkeit.
- Stand: Der Bericht exportiert Ratings fuer Teamchip, Objective/Cargo, Selected Fireteam, Paneldichte, Weltverdeckung und eine explizite naechste Polish-Prioritaet.
- Stand: Der bestehende TASK_558-Verifier wird auf die aktuelle TASK_562-Follow-up-Kette korrigiert; TASK_561 bekommt einen eigenen statischen Verifier.
- Risiken/offen: Der Guide ersetzt keinen echten manuellen F6-Screenshot-/Hover-Sichttest und wertet noch keine User-Notizen aus.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_561_frontier_probe_multiplayer_manual_visual_review_guide.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_562 - Frontier Probe Multiplayer F6 Visual Evidence Capture`, damit ohne geratenen Stilpolish zuerst eine reproduzierbare Bildbasis entsteht.

### TASK_560 - Frontier Probe Multiplayer Teamchip Tooltip Polish
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_560_frontier_probe_multiplayer_teamchip_tooltip_polish.md`, `docs/tasks/TASK_557_frontier_probe_multiplayer_f6_readability_pass.md`, `docs/dev/mission_command_feedback_contract.md`, `scripts/mission/mission_team_chip_presenter.gd`, `scripts/tests/mission_tactical_sandbox_controller.gd`
- Stand: `MissionTeamChipPresenter` liefert jetzt zusaetzlich einen kurzen Tooltip-Text fuer die bestehende Alpha/Bravo-Owner-/Spawn-Zuordnung.
- Stand: Das Mission-Teamchip-Label im F6-Mission-Control-Bereich bleibt sichtbar kompakt, ist aber hoverbar, nutzt einen Help-Cursor und traegt stabile Tooltip-Style-/Task-Metadaten.
- Stand: `get_frontier_probe_multiplayer_teamchip_tooltip_snapshot()` prueft den Tooltip read-only gegen den bestehenden TASK_557-F6-Readability-Snapshot.
- Risiken/offen: Der Tooltip-Polish ersetzt weiterhin keinen echten manuellen MP-F6-Screenshot-/Hover-Sichttest.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_560_frontier_probe_multiplayer_teamchip_tooltip_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_561 - Frontier Probe Multiplayer Manual Visual Review Guide`, damit der naechste echte MP-F6-Sichttest konkrete Ratings und Prioritaet exportiert.

### TASK_559 - Factory Colormap UID Loader Guard
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_559_factory_colormap_uid_loader_guard.md`, `docs/tasks/TASK_524_export_warning_noise_cleanup.md`, `docs/tasks/TASK_557_frontier_probe_multiplayer_f6_readability_pass.md`, `scripts/terrain/terrain_map_3d_view.gd`
- Stand: `TerrainMap3DView` registriert vor Factory-GLB-Loads die deterministische ResourceUID fuer `res://Assets/curated/kenney/factory/models/Textures/colormap.png`, damit Godot nicht mehr bei jedem Load auf den Textpfad-Fallback warnen muss.
- Stand: Der Guard greift nur fuer Modelle unter `res://Assets/curated/kenney/factory/models/` und veraendert keine Assetquellen, Katalogdaten, UI- oder Gameplay-Wahrheit.
- Stand: Der Verifier prueft die UID-Registrierung und die zuvor lauten Factory-Modelle `detail-tank`, `building-a`, `chimney-medium` und `building-d`.
- Risiken/offen: Weitere externe GLB-Texturen mit aehnlichen UID-Luecken waeren ein eigener Asset-Hygiene-Slice.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_559_factory_colormap_uid_loader_guard.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_560 - Frontier Probe Multiplayer Teamchip Tooltip Polish`, um eine kleine, sichere MP-F6-Hover-Lesbarkeit aus den vorhandenen Snapshot-Daten umzusetzen.

### TASK_558 - Frontier Probe Multiplayer Manual Screenshot Notes Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.md`, `docs/tasks/TASK_557_frontier_probe_multiplayer_f6_readability_pass.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/html_report_workbench_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: Der Rolling-HTML-Bericht enthaelt jetzt einen exportierbaren TASK_558-Notizblock fuer den manuellen Frontier-Probe-MP-F6-Screenshot-/Hover-Check.
- Stand: Exportiert werden Screenshotpfad, Viewport, Host/Client-Kontext, Teamchip-/Objective-/Cargo-/Selected-Fireteam-Lesbarkeit, Panel-Ueberlappung, Ergebnisentscheidung sowie Hover-, Stil- und Follow-up-Notizen.
- Stand: Der Bericht markiert den manuellen Screenshot bewusst nicht als erledigt; die Daten bleiben Playtest-/Arbeitsnotizen und keine Gameplay-Wahrheit.
- Risiken/offen: Der echte F6-MP-Screenshot-/Hover-Sichttest muss weiterhin manuell ausgefuehrt und exportiert werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_560 - Frontier Probe Multiplayer Teamchip Tooltip Polish`, als kleiner sicherer Hover-Polish fuer die vorhandene MP-F6-Teamchip-Lesbarkeit.

### TASK_557 - Frontier Probe Multiplayer F6 Readability Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_557_frontier_probe_multiplayer_f6_readability_pass.md`, `docs/tasks/TASK_549_combat_hud_f6_visual_audit.md`, `docs/tasks/TASK_555_frontier_probe_multiplayer_objective_ownership_smoke.md`, `docs/tasks/TASK_556_frontier_probe_host_client_objective_handoff_smoke.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_frontier_probe_multiplayer_f6_readability_snapshot()` fuer den sichtbaren FullHD-F6-Missionsmoment des Frontier-Probe-Multiplayer-Slice.
- Stand: Der Smoke kombiniert TASK_555-Ownership, relevante TASK_549-F6-Layoutchecks, Command-Feedback, Mission-Team-Chip und Control-Bounds, ohne UI oder Bericht zur Gameplay-Wahrheit zu machen.
- Stand: Geprueft werden sichtbarer Teamchip mit Host Peer 1, Peer 2, `spawn_alpha`, `spawn_bravo`, Mission-Control-Kontext fuer AA/COM/OBJ/CARGO, Selected-Fireteam-Kontext sowie FullHD-Bounds und kritische Panel-Ueberlappungen.
- Stand: Der Rolling-HTML-Bericht ist auf TASK_557 aktualisiert und bleibt als laufender Zwischenbericht gepflegt.
- Risiken/offen: Der Smoke ersetzt keinen echten manuellen Screenshot-/Hover-Sichttest im F6-Fenster.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_556_frontier_probe_host_client_objective_handoff_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_555_frontier_probe_multiplayer_objective_ownership_smoke.gd`, `git diff --check`.
- Naechster Schritt: `TASK_558 - Frontier Probe Multiplayer Manual Screenshot Notes Pass`, damit der echte F6-MP-Blick als Sichttest/Notiz im HTML-Bericht festgehalten wird.

### TASK_556 - Frontier Probe Host Client Objective Handoff Smoke
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_556_frontier_probe_host_client_objective_handoff_smoke.md`, `docs/tasks/TASK_555_frontier_probe_multiplayer_objective_ownership_smoke.md`, `docs/tasks/TASK_169_multiplayer_two_client_playability_smoke.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: `FrontierProbeHostClientHandoffContract` bewertet read-only, ob der Frontier-Probe-Objective-Slice ueber Session-Assignments, `SimulationRoot.submit_network_command_for_peer()` und Multiplayer-Snapshot-Replikation konsistent bleibt.
- Stand: Der Smoke prueft Host/Client-Readiness, Mission-Start-Assignments, Alpha Host Peer 1, Bravo Peer 2, erlaubten Bravo-Client-Move, abgelehnten Alpha-Fremdteam-Move, abgelehnte State-Mutation sowie Objective-/MissionResult-Replikation zum Client.
- Stand: TASK_555-Ownership bleibt Teil des Handoff-Snapshots und muss gruen bleiben.
- Stand: Der Rolling-HTML-Bericht ist auf TASK_556 aktualisiert und nennt TASK_557 als naechsten visuellen Multiplayer-Anschluss.
- Risiken/offen: Der Smoke nutzt Host-/Client-Testharnesses und keinen echten LAN-/Zwei-Prozess-Socket.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_556_frontier_probe_host_client_objective_handoff_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_555_frontier_probe_multiplayer_objective_ownership_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_169_multiplayer_two_client_playability_smoke.gd`, `git diff --check`.
- Naechster Schritt: `TASK_557 - Frontier Probe Multiplayer F6 Readability Pass`, damit die MP-Ownership-/Objective-Lesbarkeit sichtbar im FullHD-Missionslayout geprueft wird.

### TASK_555 - Frontier Probe Multiplayer Objective Ownership Smoke
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_555_frontier_probe_multiplayer_objective_ownership_smoke.md`, `docs/tasks/TASK_554_frontier_probe_integrated_objective_playthrough_smoke.md`, `docs/tasks/TASK_520_multiplayer_team_ownership_smoke.md`, `docs/tasks/TASK_526_mission_hud_team_chip_polish.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_frontier_probe_multiplayer_objective_ownership_snapshot()` fuer Alpha/Bravo-Ownership im integrierten Frontier-Probe-Objective-Slice.
- Stand: Der Smoke kombiniert TASK_554, `MissionMultiplayerTeamOwnershipContract`, Mission-Team-Chip und Scenario-Daten, ohne UI- oder Test-Code zur Gameplay-Wahrheit zu machen.
- Stand: Geprueft werden Alpha als player-assignable attacker, Bravo als solo NPC-defender und PvP-assignable Peer-Team, Mission-Team-Chip-Owner/Spawns, Alpha-Computer-/Cargo-Pfad und Bravo-AA-Threat.
- Stand: Der Rolling-HTML-Bericht ist auf TASK_555 aktualisiert und nennt TASK_556 als naechsten echten Host/Client-Handoff-Smoke.
- Risiken/offen: Der Smoke setzt Peer-Zuweisungen in einer Headless-Testszene; ein echter Zwei-Prozess-Host/Client-Lauf bleibt Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_555_frontier_probe_multiplayer_objective_ownership_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_554_frontier_probe_integrated_objective_playthrough_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_526_mission_hud_team_chip_polish.gd`, `git diff --check`.
- Naechster Schritt: `TASK_556 - Frontier Probe Host Client Objective Handoff Smoke`, damit derselbe Slice in einem echten Host/Client-Setup geprueft wird.

### TASK_554 - Frontier Probe Integrated Objective Playthrough Smoke
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_554_frontier_probe_integrated_objective_playthrough_smoke.md`, `docs/tasks/TASK_553_mission_cargo_extract_readability_pass.md`, `docs/tasks/TASK_552_mission_objective_interaction_readability_pass.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_frontier_probe_integrated_objective_playthrough_snapshot()` fuer den kompletten AA-/Computer-/Cargo-Abschlussblick.
- Stand: Der Smoke prueft in der echten Mission-Testszene: Objective von Alpha, AA-Gate komplett, Computer-Gate komplett, Cargo ready noch nicht komplett, Cargo departed komplettiert alle Gates.
- Stand: Mission Control muss AA/COM/OBJ und CARGO im selben finalen Statusbild zeigen; Primary3D behaelt Objective-Status sichtbar und entfernt aktive Cargo-Visuals nach Departure.
- Stand: Der Rolling-HTML-Bericht ist auf TASK_554 aktualisiert und nennt TASK_555 als naechsten spielbaren Multiplayer-Anschluss.
- Risiken/offen: Der Smoke setzt kontrollierte Scenario-Zustaende und ersetzt noch keinen menschlichen F6-Playtest oder echten Host/Client-Lauf.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_554_frontier_probe_integrated_objective_playthrough_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_553_mission_cargo_extract_readability_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_552_mission_objective_interaction_readability_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_555 - Frontier Probe Multiplayer Objective Ownership Smoke`, damit Alpha/Bravo-/NPC-/Peer-Besitz im integrierten Objective-Slice abgesichert wird.

### TASK_553 - Mission Cargo Extract Readability Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_553_mission_cargo_extract_readability_pass.md`, `docs/tasks/TASK_522_cargo_touchdown_visual_polish.md`, `docs/tasks/TASK_519_cargo_touchdown_runtime_bridge.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: Mission Control zeigt jetzt eine kompakte `CARGO ...`-Zeile fuer blocked/inbound/hold/ready/departing/departed.
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_mission_cargo_extract_readability_snapshot()` fuer CargoBridge, Cargo-Gate, Hold-Fortschritt, Mission-Control-Zeile, Primary3D-Cargo-Visual und Completion-Konsistenz.
- Stand: Der Verifier prueft `landed/ready` und danach `departed`, sodass Hold-Fortschritt nicht versehentlich schon als Missionsabschluss gilt und `departed` Bridge plus Scenario-Gates komplettiert.
- Stand: Der Rolling-HTML-Bericht ist auf TASK_553 aktualisiert und nennt TASK_554 als naechsten spielbaren Anschluss.
- Risiken/offen: TASK_553 prueft Headless-Snapshots/Render-Zaehler, keinen menschlichen F6-Sichttest und noch keinen kompletten AA-Computer-Cargo-Playthrough-Smoke.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_553_mission_cargo_extract_readability_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_552_mission_objective_interaction_readability_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_522_cargo_touchdown_visual_polish.gd`, `git diff --check`.
- Naechster Schritt: `TASK_554 - Frontier Probe Integrated Objective Playthrough Smoke`, damit AA, Computer und Cargo als zusammenhaengender Missionsablauf geprueft werden.

### TASK_552 - Mission Objective Interaction Readability Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_552_mission_objective_interaction_readability_pass.md`, `docs/tasks/TASK_518_mission_scenario_runtime_gates.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_mission_objective_interaction_readability_snapshot()` fuer die erste Objective-/Computer-/Gebaeude-Interaktion nach Insertion, Move, Contact und Combat.
- Stand: Mission Control zeigt eine kompakte `AA | COM | OBJ`-Zeile aus bestehenden ObjectiveStatus- und ScenarioRuntimeGate-Daten.
- Stand: Der Snapshot prueft Take-Control, Objective-Tile, ObjectiveState, Scenario-Gates, Computer-Hold und Primary-3D-Objective-Visual, ohne Gameplay-Wahrheit in der UI zu setzen.
- Stand: Der Rolling-HTML-Bericht ist auf TASK_552 aktualisiert und nennt TASK_553 als naechsten spielbaren Anschluss.
- Risiken/offen: TASK_552 macht die Computer-/Objective-Interaktion sichtbar, aber der Cargo-Touchdown-/Extract-Flow ist noch nicht als eigener Spielerblick abgesichert.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_552_mission_objective_interaction_readability_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_551_combat_hud_tooltip_style_polish.gd`, `git diff --check`.
- Naechster Schritt: `TASK_553 - Mission Cargo Extract Readability Pass`, damit der Frachter-Anflug, Touchdown-Hold und Abflug nach AA/Computer ebenfalls als spielbarer Ablauf lesbar werden.

### TASK_551 - Combat HUD Tooltip Style Polish
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_551_combat_hud_tooltip_style_polish.md`, `docs/tasks/TASK_550_combat_hud_manual_screenshot_notes_pass.md`, `docs/tasks/TASK_549_combat_hud_f6_visual_audit.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: Die Combat-HUD-Tooltip-Labels in #17 Selected Fireteam und #18 Mission Control tragen jetzt eine gemeinsame dezente Style-Signatur.
- Stand: Beide Labels bleiben hoverbar, clippen Text, nutzen Help-Cursor, Tactical-UI-Akzentfarbe, 10px-HUD-Schrift und Outline fuer besseren Kontrast.
- Stand: `get_combat_hud_f6_visual_audit_snapshot()` exportiert die Style-Metadaten read-only und prueft, dass beide Panels denselben Tooltip-Style-Hinweis tragen.
- Stand: Der Rolling-HTML-Bericht ist auf TASK_551 aktualisiert und nennt TASK_552 als naechsten spielbaren Anschluss.
- Risiken/offen: Der Task prueft Style-/Theme-Daten headless; ein menschlicher FullHD-Sichttest bleibt fuer finales Hover-Gefuehl und optische Gewichtung sinnvoll.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_551_combat_hud_tooltip_style_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_549_combat_hud_f6_visual_audit.gd`, `git diff --check`.
- Naechster Schritt: `TASK_552 - Mission Objective Interaction Readability Pass`, damit nach Insertion, Move, Contact und Combat auch die erste Objective-/Computer-/Gebaeude-Interaktion lesbar wird.

### TASK_550 - Combat HUD Manual Screenshot Notes Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_550_combat_hud_manual_screenshot_notes_pass.md`, `docs/tasks/TASK_549_combat_hud_f6_visual_audit.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/html_report_workbench_contract.md`
- Stand: Der Rolling-HTML-Bericht enthaelt einen exportierbaren TASK_550-Block fuer Combat-HUD-Screenshot-/Hover-Review.
- Stand: Erfasst werden Screenshotpfad, Viewport, Hover-Checks fuer #17/#18, Ergebnisentscheidung, Hover-Notizen, Stilnotizen, Follow-up und freie Review-Notiz.
- Stand: Der Bericht markiert den manuellen Screenshot bewusst nicht als erledigt; die Daten sind Arbeitsnotizen und keine Runtime-Wahrheit.
- Stand: Ein statischer Verifier prueft, dass TASK_550-Berichtsfelder, Contract, Status und TASK_551-Follow-up vorhanden bleiben.
- Risiken/offen: Der Task fuehrt keinen echten F6-Screenshot aus. Die naechste sichtbare UI-Aenderung sollte aus exportierten Playtest-Notizen oder einem echten Screenshot abgeleitet werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_550_combat_hud_manual_screenshot_notes_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_551 - Combat HUD Tooltip Style Polish`, sobald Screenshot-/Hover-Notizen eine konkrete optische Korrektur nahelegen.

### TASK_549 - Combat HUD F6 Visual Audit
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_549_combat_hud_f6_visual_audit.md`, `docs/tasks/TASK_548_combat_hud_visual_detail_tooltip_pass.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_combat_hud_f6_visual_audit_snapshot()` fuer Combat-HUD-Tooltip-Lesbarkeit im 1920x1080-Missionslayout.
- Stand: #17 Selected Fireteam und #18 Mission Control werden auf sichtbare, hover-faehige Labels, identische Tooltip-Payload, FullHD-Bounds und Panel-Nichtueberlappung geprueft.
- Stand: Die Combat-HUD-Labels clippen sichtbaren Headertext und behalten den nativen Godot-Tooltip als Detailhilfe, ohne die kompakte HUD-Zeile aufzublaehen.
- Stand: Der Rolling-HTML-Bericht ist als laufender Zwischenbericht auf TASK_549 aktualisiert und nennt den naechsten sinnvollen Anschluss.
- Risiken/offen: Der Task prueft automatisierte Layout-/Tooltip-Bounds und behauptet keinen menschlichen Screenshot. Der echte Hover-/Stil-Eindruck im Godot-Fenster bleibt als manueller Sichttest sinnvoll.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_549_combat_hud_f6_visual_audit.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_548_combat_hud_visual_detail_tooltip_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_550 - Combat HUD Manual Screenshot Notes Pass`, damit der automatisierte Audit mit einem echten F6-Screenshot-/Notizdurchlauf fuer Stil, Hover-Gefuehl und Lesbarkeit abgeglichen wird.

### TASK_548 - Combat HUD Visual Detail Tooltip Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_548_combat_hud_visual_detail_tooltip_pass.md`, `docs/tasks/TASK_547_multi_fireteam_combat_hud_consistency_smoke.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_combat_hud_visual_detail_tooltip_snapshot()` fuer die Detailhilfe zur kompakten Combat-HUD-Zeile.
- Stand: #17 Selected Fireteam und #18 Mission Control erhalten denselben Tooltip-Text aus bestehenden ContactDecision-, Cover- und FireEvent-Snapshots.
- Stand: Der Tooltip erklaert Fire-State, Angreifer/Ziel, Waffe/Outcome falls vorhanden sowie Cover, Range, LOS und Flank-Kontext, waehrend die kompakte HUD-Zeile im TASK_546-Budget bleibt.
- Stand: Der Rolling-HTML-Bericht ist als laufender Zwischenbericht auf TASK_548 aktualisiert und nennt den naechsten sichtbaren Anschluss.
- Risiken/offen: Der Task prueft Headless-Snapshots und Control-Tooltips, keinen menschlichen F6-/Screenshot-Sichttest des Hover-Verhaltens im Fenster.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_548_combat_hud_visual_detail_tooltip_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_547_multi_fireteam_combat_hud_consistency_smoke.gd`, `git diff --check`.
- Naechster Schritt: `TASK_549 - Combat HUD F6 Visual Audit`, damit die neue Detailhilfe im echten 1920x1080-Missionsfenster sichtbar auf Lesbarkeit, Position und Ueberlagerungen geprueft wird.

### TASK_547 - Multi-Fireteam Combat HUD Consistency Smoke
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_547_multi_fireteam_combat_hud_consistency_smoke.md`, `docs/tasks/TASK_546_mission_combat_feedback_hud_density_polish.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_multi_fireteam_combat_hud_consistency_snapshot()` fuer Multi-Fireteam-Auswahl, Mission-Dropship-Cards, Fireteam-Statuskarten und die kompakte Combat-HUD-Zeile.
- Stand: Der Smoke baut eine kontrollierte Mission mit zwei Fireteams, zwei Dropship-Cards und einem reproduzierbaren Combat-Kontext.
- Stand: Geprueft wird, dass Mission Control und Selected Fireteam dieselbe kompakte Combat-Zeile behalten, waehrend Dropship-Payload und Fireteam-Auswahl getrennt lesbar bleiben.
- Stand: Der Rolling-HTML-Bericht ist als laufender Zwischenbericht auf TASK_547 aktualisiert und nennt den naechsten sinnvollen Anschluss.
- Risiken/offen: Der Task prueft Headless-Snapshots, keinen echten Netzwerk-Peer und keinen manuellen F6-/Screenshot-Sichttest.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_547_multi_fireteam_combat_hud_consistency_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_546_mission_combat_feedback_hud_density_polish.gd`, `git diff --check`.
- Naechster Schritt: `TASK_548 - Combat HUD Visual Detail Tooltip Pass`, damit die verdichtete HUD-Zeile bei Bedarf wieder Detailgruende zeigen kann, ohne das Panel vollzuschreiben.

### TASK_546 - Mission Combat Feedback HUD Density Polish
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_546_mission_combat_feedback_hud_density_polish.md`, `docs/tasks/TASK_545_mission_fire_cover_integrated_flow_smoke.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: `MissionTacticalSandboxController` verdichtet ContactDecision-, Cover- und FireEvent-Snapshots zu einer kurzen Combat-HUD-Zeile fuer Mission Control und Selected Fireteam.
- Stand: `get_mission_combat_feedback_hud_density_snapshot()` prueft read-only Verhalten, Zeichenbudget, Fire-/Wait-/No-Fire-/Contact-State sowie Cover-/LOS-/Range-Kontext.
- Stand: Der integrierte Smoke nutzt den echten Homebase-Dropship-Mission-Engagement-Pfad und prueft danach, dass beide HUD-Panels die kompakte Zeile anzeigen.
- Stand: Der Rolling-HTML-Bericht ist als laufender Zwischenbericht auf TASK_546 aktualisiert und nennt den naechsten sinnvollen Anschluss.
- Risiken/offen: Der Task prueft Headless-Snapshots und keinen menschlichen F6-/Screenshot-Sichttest. Die sichtbare Panel-Wirkung im Godot-Fenster bleibt als kurzer manueller Check sinnvoll.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_546_mission_combat_feedback_hud_density_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_544_mission_fire_cover_visual_polish_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_547 - Multi-Fireteam Combat HUD Consistency Smoke`, damit die kompakte Combat-Lesbarkeit auch bei mehreren Fireteams/Dropships konsistent bleibt.

### TASK_545 - Mission Fire Cover Integrated Flow Smoke
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_545_mission_fire_cover_integrated_flow_smoke.md`, `docs/tasks/TASK_544_mission_fire_cover_visual_polish_pass.md`, `docs/tasks/TASK_543_mission_first_engagement_feedback_pass.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: Der integrierte Smoke startet den echten Homebase-zu-Mission-Pfad, boarded ein Fireteam, setzt LZ, deployed, plant/fuehrt die erste Move-Order aus, erzeugt Kontakt und stoesst die bestehende Combat-Entscheidung an.
- Stand: Danach prueft der Smoke `get_mission_fire_cover_visual_polish_snapshot()` auf FireTrace, Ziel-Fokus, Fire-Label, Unit-Badge-Text/Farbe/Style, Cover-/LOS-/Range-Kontext und read-only Verhalten.
- Stand: Der Rolling-HTML-Bericht ist auf TASK_545 aktualisiert und nennt den naechsten spielbaren Anschluss ohne behaupteten manuellen Sichttest.
- Risiken/offen: Der Smoke ist bewusst lang und ersetzt keinen menschlichen Screenshot. Er beweist aber, dass die TASK_544-Visual-Politur durch den echten Flow bis in den Render-Snapshot gelangt.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_545_mission_fire_cover_integrated_flow_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_544_mission_fire_cover_visual_polish_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_546 - Mission Combat Feedback HUD Density Polish`, damit die jetzt integrierte Combat-Lesbarkeit in den Panels kompakter und angenehmer scannbar wird.

### TASK_544 - Mission Fire And Cover Visual Polish Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_544_mission_fire_cover_visual_polish_pass.md`, `docs/tasks/TASK_543_mission_first_engagement_feedback_pass.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: `TerrainMap3DView` rendert FireEvents jetzt mit zusaetzlichem Ziel-Fokusmarker und kompaktem Fire-Statuslabel (`FIRE`, `HIT`, `MISS`, `FF`) am Impact.
- Stand: Unit-Statusbadges schreiben Text, Farb-Hexwert und Style in den Render-Snapshot, damit Contact/Engage/Covering-Zustaende ohne Pixelraten regressionsfest pruefbar bleiben.
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_mission_fire_cover_visual_polish_snapshot()` fuer FireTrace, Ziel-Fokus, Fire-Label, Badge-Lesbarkeit und weiterhin vorhandenen Cover-/LOS-/Range-Kontext.
- Stand: Der Rolling-HTML-Bericht ist als laufender Zwischenbericht auf TASK_544 aktualisiert und nennt den naechsten Anschluss.
- Risiken/offen: Der Task prueft Headless-Render-Snapshots und keinen menschlichen F6-/Screenshot-Sichttest. Die echte optische Wirkung im Godot-Fenster bleibt als naechste kurze Sichtpruefung sinnvoll.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_544_mission_fire_cover_visual_polish_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_543_mission_first_engagement_feedback_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_545 - Mission Fire Cover Integrated Flow Smoke`, damit die Headless-Politur im echten Homebase-Dropship-Mission-Engagement-Pfad ankommt.

### TASK_543 - Mission First Engagement Feedback Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_543_mission_first_engagement_feedback_pass.md`, `docs/tasks/TASK_542_mission_first_contact_readability_pass.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/runtime_script_layout_contract.md`
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_mission_first_engagement_feedback_snapshot()` fuer FireEvents, ContactDecision-Diagnostics, Ziel-/Angreifer-/Waffenfelder, Cooldown-/Blockgruende, Cover-/Range-/LOS-Kontext und Mission-Control-/Command-Feedback.
- Stand: Der Smoke startet den Homebase-zu-Mission-Pfad, setzt LZ, dropped/deboarded das Fireteam, plant und fuehrt den ersten Move aus, erzeugt reproduzierbaren Kontakt und stoesst die bestehende Combat-Entscheidung an.
- Stand: Der Rolling-HTML-Bericht nennt TASK_543 als erledigten Zwischenstand und verschiebt den naechsten Anschluss auf sichtbare Fire-/Cover-Visual-Politur.
- Risiken/offen: Der Task prueft Headless-Snapshots und keinen menschlichen Pixel-Sichttest. Der naechste spielbare Reibungspunkt ist, ob FireTrace, Ziel-/Deckungsanzeige und Statuschips im Godot-Fenster angenehm lesbar aussehen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_543_mission_first_engagement_feedback_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_542_mission_first_contact_readability_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_544 - Mission Fire And Cover Visual Polish Pass`, damit die nun pruefbare Engagement-Wahrheit im sichtbaren Missionsbild schicker und schneller lesbar wird.

### TASK_542 - Mission First Contact Readability Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_542_mission_first_contact_readability_pass.md`, `docs/tasks/TASK_541_mission_first_move_execution_feedback_pass.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/runtime_script_layout_contract.md`
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_mission_first_contact_readability_snapshot()` fuer ausgewaehlte Fireteam-Kontakte, Detection-State, Last-Known-Position, Confidence/Report-Text, ContactMapOverlay-/Primary3D-Spiegelung, Tactical-Communication/Eventlog und Security-/Cover-/Contact-Diagnostics-Kontext.
- Stand: Der Smoke startet eine Homebase-Direktmission, setzt LZ, dropped/deboarded das Fireteam, plant und fuehrt die erste Move-Order aus, positioniert einen Gegner reproduzierbar in Kontaktreichweite und prueft danach Contact-Readability.
- Stand: Der Rolling-HTML-Bericht nennt TASK_542 als erledigten Zwischenstand und bleibt als laufender Arbeitsbericht mit erledigt/offen/naechster Schritt gepflegt.
- Risiken/offen: Der Task prueft Headless-Snapshots und keinen menschlichen Pixel-Sichttest. Der naechste spielbare Reibungspunkt ist, ob aus dem ersten Kontakt auch Feuer-/Deckungsreaktion und Zielprioritaet klar lesbar werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_542_mission_first_contact_readability_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_541_mission_first_move_execution_feedback_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_543 - Mission First Engagement Feedback Pass`, damit nach dem ersten Kontakt Feuerstatus, Zielwahl, Deckungsreaktion und Blockgruende nachvollziehbar werden.

### TASK_541 - Mission First Move Execution Feedback Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_541_mission_first_move_execution_feedback_pass.md`, `docs/tasks/TASK_540_mission_first_move_decision_readability_pass.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/runtime_script_layout_contract.md`
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_mission_first_move_execution_feedback_snapshot()` fuer GO-Feedback, aktive Phase-Execution, aktiven Movement-State, OrderPlan-/Waypoint-Trace und Runtime-Execution-Path.
- Stand: Der Smoke startet eine Homebase-Direktmission, setzt LZ, dropped/deboarded das Fireteam, plant eine erste Move-Order, fuehrt GO ueber `execute_selected_fireteam_orders()` aus und prueft Ausfuehrungslesbarkeit.
- Stand: Der Rolling-HTML-Bericht nennt TASK_541 als erledigten Execution-Feedback-Slice und verschiebt den naechsten Anschluss auf First-Contact-Readability.
- Risiken/offen: Der Task prueft Headless-Snapshots und keine menschliche Pixelwirkung. Der naechste spielbare Reibungspunkt ist, ob Feindkontakt/Threat waehrend oder nach der Bewegung klar genug sichtbar wird.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_541_mission_first_move_execution_feedback_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_540_mission_first_move_decision_readability_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_542 - Mission First Contact Readability Pass`, damit Sichtkontakt, Bedrohung und Feuer-/Deckungsfeedback nach der ersten Bewegung lesbar werden.

### TASK_540 - Mission First Move Decision Readability Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_540_mission_first_move_decision_readability_pass.md`, `docs/tasks/TASK_539_mission_insertion_first_order_readability_pass.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/runtime_script_layout_contract.md`
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_mission_first_move_decision_readability_snapshot()` fuer deployed/aktive Fireteams, geplante Waypoints, Waypoint-Intent-Preview, visualisierte Waypoints und GO-Bereitschaft.
- Stand: Der Smoke startet eine Homebase-Direktmission, setzt LZ, dropped/deboarded das Fireteam, plant eine erste Move-Order ueber den bestehenden Right-Click-Pfad und prueft Preview/GO-Lesbarkeit.
- Stand: Der Rolling-HTML-Bericht nennt TASK_540 als erledigten First-Move-Decision-Slice und verschiebt den naechsten Anschluss auf GO-Ausfuehrungs-/Ankunftsfeedback.
- Risiken/offen: Der Task prueft die Entscheidung vor GO, aber nicht die tatsaechliche Move-Ausfuehrung bis zur Ankunft. Das bleibt der naechste sinnvolle spielbare Slice.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_540_mission_first_move_decision_readability_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_539_mission_insertion_first_order_readability_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_541 - Mission First Move Execution Feedback Pass`, damit GO, Bewegung, Fortschritt und Ankunft direkt nach der ersten Entscheidung lesbar werden.

### TASK_539 - Mission Insertion First Order Readability Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_539_mission_insertion_first_order_readability_pass.md`, `docs/tasks/TASK_538_homebase_to_mission_launch_handoff_smoke.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/runtime_script_layout_contract.md`
- Stand: `MissionTacticalSandboxController` expose't einen read-only `get_mission_insertion_first_order_readability_snapshot()` fuer Dropship-Payload, Card-UI, LZ-Status, Drop-Blockade/-Bereitschaft, ausgewaehltes Fireteam und erste Order-Kontrollen.
- Stand: Der Smoke startet eine Homebase-Direktmission, zeigt die Mission, prueft den Zustand vor LZ, setzt eine LZ ueber den bestehenden Card-Flow und prueft danach Render-LZ plus Drop-Bereitschaft.
- Stand: Der Rolling-HTML-Bericht bleibt als laufender Zwischenbericht gepflegt und nennt TASK_539 als erledigten Missions-Insertion-Lesbarkeitsslice.
- Risiken/offen: Der Task prueft Headless-Snapshots und Render-Zaehler, aber keinen menschlichen Pixel-Sichttest. Der naechste spielbare Anschluss ist die erste echte Move-/GO-Entscheidung nach Deboarding.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_539_mission_insertion_first_order_readability_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_538_homebase_to_mission_launch_handoff_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_396_mission_dropship_lz_drop_hotfix.gd`, `git diff --check`.
- Naechster Schritt: `TASK_540 - Mission First Move Decision Readability Pass`, damit nach dem Drop die erste echte Bewegungs-/GO-Entscheidung ebenso klar wird.

### TASK_538 - Homebase To Mission Launch Handoff Smoke
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_538_homebase_to_mission_launch_handoff_smoke.md`, `docs/tasks/TASK_537_pre_mission_f6_screenshot_visual_audit.md`, `docs/tasks/TASK_534_pre_mission_readiness_checklist.md`, `docs/dev/mission_briefing_contract.md`
- Stand: `MetaLayerFlow` expose't einen read-only `get_homebase_to_mission_handoff_snapshot()` fuer Mission-Auswahl, Planning-State, MissionSetup, TacticalController und Timer.
- Stand: Der Smoke startet eine Homebase-Direktmission ueber den bestehenden `request_mission_start()`-Pfad und prueft Unit-IDs, Fireteam-IDs, Dropship, Scenario/Map, Member-Loadouts und Handoff-Checks.
- Stand: Der Rolling-HTML-Bericht nennt TASK_538 als erledigten Zwischenstand und verschiebt den naechsten Anschluss auf Mission-Insertion-/First-Order-Readability.
- Risiken/offen: Der Handoff ist jetzt pruefbar; die erste Insertion, LZ-Wahl und erste Commander-Befehlsrunde im Missionsbild bleiben der naechste spielerische Lesbarkeits-Slice.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_538_homebase_to_mission_launch_handoff_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_537_pre_mission_f6_screenshot_visual_audit.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_536_startflow_icon_status_color_polish.gd`, `git diff --check`.
- Naechster Schritt: `TASK_539 - Mission Insertion First Order Readability Pass`, damit die gestartete Mission die erste LZ-/Insertion-/Befehlsentscheidung gut lesbar macht.

### TASK_537 - Pre-Mission F6 Screenshot Visual Audit
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_537_pre_mission_f6_screenshot_visual_audit.md`, `docs/tasks/TASK_536_startflow_icon_status_color_polish.md`, `docs/tasks/TASK_535_pre_mission_fullhd_startflow_visual_pass.md`, `docs/dev/mission_briefing_contract.md`
- Stand: `HomebaseTestScreen` expose't einen read-only `get_pre_mission_visual_audit_snapshot()` fuer Startflow-Layout, Readiness-Chips, Kontrast und Startbutton-Konsistenz.
- Stand: Readiness-Chip-Snapshots enthalten jetzt zusaetzlich `text_color_hex`, damit Statusfarbe und Textkontrast regressionsfest pruefbar bleiben.
- Stand: Der Audit markiert den manuellen F6-/Screenshot-Sichttest weiterhin als offen, behauptet also keinen menschlichen Sichtcheck.
- Stand: Der Rolling-HTML-Bericht nennt TASK_537 als erledigten Zwischenstand und verschiebt den naechsten Anschluss auf den Homebase-zu-Mission-Handoff.
- Risiken/offen: Kein echter Fenster-Screenshot in diesem Task. Der Audit prueft Layout-/Kontrast-Vertraege, aber nicht die tatsaechliche Pixelwirkung im Godot-Fenster.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_537_pre_mission_f6_screenshot_visual_audit.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_536_startflow_icon_status_color_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_535_pre_mission_fullhd_startflow_visual_pass.gd`, `git diff --check`.
- Naechster Schritt: Siehe `TASK_538 - Homebase To Mission Launch Handoff Smoke`.

### TASK_536 - Startflow Icon And Status Color Polish
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_536_startflow_icon_status_color_polish.md`, `docs/tasks/TASK_535_pre_mission_fullhd_startflow_visual_pass.md`, `docs/tasks/TASK_534_pre_mission_readiness_checklist.md`, `docs/dev/mission_briefing_contract.md`
- Stand: `HomebaseTestScreen` rendert Pre-Mission-Readiness-Items als farbige Chips mit Status-Indikator, Icon-Text, Label und detailreichem Tooltip.
- Stand: `get_pre_mission_readiness_snapshot()` expose't `rendered_item_visuals` mit Item-ID, State, Icon, Farbe, Text und Tooltip fuer Regressionen.
- Stand: Der Startbutton expose't `pre_mission_readiness_color_hex` und spiegelt dieselbe Readiness-Farbe im Startflow-Snapshot.
- Stand: Der Rolling-HTML-Bericht nennt TASK_536 als erledigten Zwischenstand und verschiebt den naechsten Anschluss auf einen echten F6-/Screenshot-Sichttest.
- Risiken/offen: Die Chips nutzen Godot-Control-Farben und ASCII-Icon-Text, aber noch keine finalen Texture-Icons. Manueller FullHD-Sichttest bleibt offen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_536_startflow_icon_status_color_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_535_pre_mission_fullhd_startflow_visual_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_534_pre_mission_readiness_checklist.gd`, `git diff --check`.
- Naechster Schritt: Siehe `TASK_537 - Pre-Mission F6 Screenshot Visual Audit`.

### TASK_535 - Pre-Mission FullHD Startflow Visual Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_535_pre_mission_fullhd_startflow_visual_pass.md`, `docs/tasks/TASK_534_pre_mission_readiness_checklist.md`, `docs/dev/mission_briefing_contract.md`, `docs/tasks/TASK_528_rolling_html_status_report.md`
- Stand: `DropLightLayoutContract.get_homebase_layout()` reserviert fuer die Homebase jetzt ein echtes 568px-Mission-Deck und setzt Roster, Fireteams und Flightdeck darunter.
- Stand: `HomebaseTestScreen` rendert Briefing, Minimap, Loadout-Empfehlungen und Readiness kompakter und expose't einen read-only `get_pre_mission_startflow_visual_snapshot()`.
- Stand: Der Startbutton bleibt an `can_request_mission_start()` gebunden, zeigt aber anhand des Readiness-Snapshots `Start blockiert`, `Start pruefen` oder `Start Mission` plus Tooltip.
- Stand: Der Rolling-HTML-Bericht nennt TASK_535 als erledigten Zwischenstand und verschiebt den naechsten Anschluss auf Statusfarben/Icon-Polish.
- Risiken/offen: Kein echter F6-Screenshot in diesem Task. Die Statussprache ist noch ASCII-/Label-basiert; visuelle Icon-/Farbsprache bleibt Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_535_pre_mission_fullhd_startflow_visual_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_534_pre_mission_readiness_checklist.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `git diff --check`.
- Naechster Schritt: Siehe `TASK_536 - Startflow Icon And Status Color Polish`.

### TASK_534 - Pre-Mission Readiness Checklist
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_534_pre_mission_readiness_checklist.md`, `docs/tasks/TASK_533_recommended_loadout_selection_bridge.md`, `docs/dev/mission_briefing_contract.md`, `docs/tasks/TASK_528_rolling_html_status_report.md`
- Stand: `PreMissionReadinessPresenter` baut aus vorhandenen Briefing-, Loadout-, Aircraft- und Homebase-Dropship-Snapshots eine read-only Checkliste.
- Stand: `HomebaseTestScreen` rendert die Checkliste als kompakten `PreMissionReadinessPanel`-Block unter dem Briefing und expose't Summary/Items im Snapshot.
- Stand: Der bestehende Start-Guard `can_request_mission_start()` bleibt die Startwahrheit; die Checkliste zeigt ihn nur an.
- Stand: Der Rolling-HTML-Bericht nennt TASK_534 als erledigten Zwischenstand und verschiebt den naechsten Anschluss auf FullHD-/Startflow-Visual-Polish.
- Risiken/offen: Cargo ist aktuell optional lesbar; missionsspezifische Cargo-Pflichten brauchen spaeter Szenario-Gate-Daten. Manueller FullHD-Sichttest bleibt offen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_534_pre_mission_readiness_checklist.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_533_recommended_loadout_selection_bridge.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_382_homebase_direct_mission_flightdeck_display.gd`, `git diff --check`.
- Naechster Schritt: Siehe `TASK_535 - Pre-Mission FullHD Startflow Visual Pass`.

### TASK_533 - Recommended Loadout Selection Bridge
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_533_recommended_loadout_selection_bridge.md`, `docs/tasks/TASK_532_briefing_background_loadout_recommendation_polish.md`, `docs/dev/mission_briefing_contract.md`, `docs/tasks/TASK_528_rolling_html_status_report.md`
- Stand: `MissionBriefingPanelPresenter` liefert pro Empfehlung stabile `recommendation_id`-Felder, Waffen-IDs und eine read-only `loadout_patch_preview`.
- Stand: `HomebaseTestScreen` rendert Briefing-Empfehlungen als auswählbare Karten mit separatem Apply-Button und Statuslabel.
- Stand: Der Apply schreibt erst nach Bestaetigung in den bestehenden Homebase-Member-Loadout-Sync und veraendert keinen Missionsruntime-State.
- Stand: Der Rolling-HTML-Bericht nennt TASK_533 als aktuellen Zwischenstand und haelt offene naechste Schritte sichtbar.
- Risiken/offen: Die Anwendung ist homogen fuer gestagte Operatoren; rollenfeine Verteilung und manueller FullHD-Sichttest bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_533_recommended_loadout_selection_bridge.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_532_briefing_background_loadout_recommendation_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_531_briefing_minimap_visual_renderer.gd`, `git diff --check`.
- Naechster Schritt: Siehe `TASK_534 - Pre-Mission Readiness Checklist`.

### TASK_532 - Briefing Background / Loadout Recommendation Polish
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_532_briefing_background_loadout_recommendation_polish.md`, `docs/tasks/TASK_531_briefing_minimap_visual_renderer.md`, `docs/tasks/TASK_530_briefing_panel_renderer_mvp.md`, `docs/dev/mission_briefing_contract.md`, `docs/tasks/TASK_528_rolling_html_status_report.md`
- Stand: `MissionBriefingPanelPresenter` expose't `background_image_exists`, `background_image_status_text` und strukturierte `loadout_card_entries`, ohne Loadout-Commands zu erzeugen.
- Stand: `HomebaseTestScreen` rendert das Briefing-Bild als `TextureRect` und empfohlene Loadouts als kompakte Card-Zeilen im bestehenden Briefing-Panel.
- Stand: Der Rolling-HTML-Bericht nennt TASK_532 als erledigten Zwischenstand und verschiebt den naechsten sinnvollen Schritt auf eine bestaetigte Loadout-/Startworkflow-Bruecke.
- Risiken/offen: Empfehlungen bleiben bewusst passiv. Eine spaetere Apply-/Preview-Bruecke braucht eine eigene Bestaetigungs-UX, damit UI keine Loadout-Wahrheit erfindet.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_532_briefing_background_loadout_recommendation_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_531_briefing_minimap_visual_renderer.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_530_briefing_panel_renderer_mvp.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_529_mission_hud_team_icon_polish.gd`, `git diff --check`.
- Naechster Schritt: Siehe `TASK_533 - Recommended Loadout Selection Bridge`.

### TASK_531 - Briefing Minimap Visual Renderer
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_531_briefing_minimap_visual_renderer.md`, `docs/tasks/TASK_530_briefing_panel_renderer_mvp.md`, `docs/tasks/TASK_527_briefing_minimap_team_spawn_overlay.md`, `docs/dev/mission_briefing_contract.md`, `docs/tasks/TASK_528_rolling_html_status_report.md`
- Stand: `MissionBriefingMinimapVisualPresenter` baut einen read-only Visual-Snapshot mit grob gesampelten Terrain-Zellen, Overlay-Entries, Legende, Sample-Stride und Markerzaehlern.
- Stand: `MissionBriefingMinimapVisual` zeichnet den Snapshot im Homebase-Briefing-Panel als kompaktes Minimap-Control mit Terrainfarben, Danger-/Objective-/Route-Markern und Alpha/Bravo-Team-Spawns.
- Stand: `MissionBriefingPanelPresenter` reicht den Visual-Snapshot weiter; `HomebaseTestScreen` expose't die gerenderten Minimap-Zaehler fuer Regressionen.
- Risiken/offen: Die Minimap ist ein performanter Preview-Renderer, keine finale Tileset-/Zoom-/Hover-/Annotation-Painting-Loesung. TASK_532 ergaenzt Bild und Empfehlungskarten.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_531_briefing_minimap_visual_renderer.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_530_briefing_panel_renderer_mvp.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_529_mission_hud_team_icon_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_527_briefing_minimap_team_spawn_overlay.gd`, `git diff --check`.
- Naechster Schritt: Siehe `TASK_532 - Briefing Background / Loadout Recommendation Polish`.

### TASK_530 - Briefing Panel Renderer MVP
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_530_briefing_panel_renderer_mvp.md`, `docs/tasks/TASK_529_mission_hud_team_icon_polish.md`, `docs/tasks/TASK_527_briefing_minimap_team_spawn_overlay.md`, `docs/dev/mission_briefing_contract.md`, `docs/tasks/TASK_528_rolling_html_status_report.md`
- Stand: `MissionBriefingPanelPresenter` baut aus `MissionScenarioData`, `TerrainMapData` und `MissionBriefingMinimapOverlayPresenter` einen read-only Panel-Snapshot fuer Titel, Summary, Ziele, Risiken, Team-Spawns und Loadout-Empfehlungen.
- Stand: `HomebaseTestScreen` rendert fuer Szenario-Missionen einen kompakten `MissionBriefingPanel`-Block im bestehenden Mission-Brief-Fenster und expose't den gerenderten Zustand fuer Regressionen.
- Stand: Der Rolling-HTML-Bericht nennt TASK_530 als erledigten Zwischenstand und verschiebt den naechsten sinnvollen Schritt auf visuelle Briefing-Minimap-/Loadout-Brueckenarbeit.
- Risiken/offen: Das Panel war textbasiert; TASK_531 ergaenzt die erste echte Minimap-Zeichnung. Hintergrundbild und interaktive Annotationen bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_530_briefing_panel_renderer_mvp.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_529_mission_hud_team_icon_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_527_briefing_minimap_team_spawn_overlay.gd`, `git diff --check`.
- Naechster Schritt: Siehe `TASK_531 - Briefing Minimap Visual Renderer`.

### TASK_529 - Mission HUD Team Icon Polish
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_529_mission_hud_team_icon_polish.md`, `docs/tasks/TASK_528_rolling_html_status_report.md`, `docs/tasks/TASK_527_briefing_minimap_team_spawn_overlay.md`, `docs/tasks/TASK_526_mission_hud_team_chip_polish.md`, `docs/dev/mission_briefing_contract.md`
- Stand: `MissionTeamChipPresenter` liefert pro Team kompakte ASCII-sichere Symbolfelder (`icon_text`, `spawn_icon_text`, `compact_text`, `icon_tooltip`, `visual_priority`) und weiterhin die ausfuehrlichen Legacy-Felder.
- Stand: Das Mission-HUD liest `compact_status_text` fuer das sichtbare Label, waehrend `status_text` weiter die vollstaendigen Owner-/Spawnmarker-Daten fuer Regressionen und Debug enthaelt.
- Stand: `MissionBriefingMinimapOverlayPresenter` gibt dieselben kompakten Icon-/Label-Felder fuer generierte `team_spawn`-Overlays aus, ohne Briefing- oder Terrain-Daten zu duplizieren.
- Risiken/offen: Die Symbole sind bewusst ASCII-Text und noch keine finalen Texture-/Icon-Controls. Der eigentliche visuelle Minimap-Renderer bleibt Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_529_mission_hud_team_icon_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_526_mission_hud_team_chip_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_527_briefing_minimap_team_spawn_overlay.gd`, `git diff --check`.
- Naechster Schritt: Siehe `TASK_530 - Briefing Panel Renderer MVP`.

### TASK_528 - Rolling HTML Status Report
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_528_rolling_html_status_report.md`, `docs/dev/html_report_workbench_contract.md`, `docs/tasks/TASK_527_briefing_minimap_team_spawn_overlay.md`, `docs/TASK_ROADMAP.md`
- Stand: Der bestehende Gesamt-Review-Report bleibt die laufende HTML-Workbench fuer Zwischenstaende, erledigte Blocks, offene Reibungen, lokale Checks und priorisierte naechste Schritte.
- Stand: Der Report nennt TASK_528 als Berichtspflege, verschiebt Mission-HUD-Team-Icon-Polish auf TASK_529 und Briefing-Panel-Renderer auf TASK_530.
- Stand: Der JSON-Export enthaelt weiterhin `recommended_next_tasks`, `recently_completed_tasks`, Report-Metadaten und jetzt auch offene Risiken fuer die naechste Arbeitsauswahl.
- Risiken/offen: Der Bericht ersetzt keinen manuellen FullHD-/F6-Sichttest. Der naechste echte Spielbarkeitsfortschritt sollte wieder UI-/Mission-Polish statt weitere Reportpflege sein.
- Lokale Pruefung: `git diff --check`, HTML-Struktur-/Export-Sanity per Textcheck.
- Naechster Schritt: `TASK_529 - Mission HUD Team Icon Polish`, wenn Teamchips/Briefing-Overlays von Text zu klareren Symbolen wachsen sollen.

### TASK_527 - Briefing Minimap Team Spawn Overlay
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_527_briefing_minimap_team_spawn_overlay.md`, `docs/tasks/TASK_526_mission_hud_team_chip_polish.md`, `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`, `docs/dev/mission_briefing_contract.md`, `docs/dev/html_report_workbench_contract.md`
- Stand: `MissionBriefingMinimapOverlayPresenter` kombiniert bestehende `briefing.annotations` mit automatisch abgeleiteten `team_spawn`-Eintraegen aus `vertical_slice.team_slots`.
- Stand: Die Team-Spawn-Overlays lesen Markerpositionen aus `TerrainMapData`, liefern Weltposition und normalisierte Minimap-UVs und setzen `ui_sets_gameplay_truth` auf `false`.
- Stand: `frontier_probe_vertical_slice` kann Alpha/Bravo-Spawnpunkte fuer Briefing-Minimap-Renderer expose'n, ohne Marker, Tiles oder Patrols ins Briefing zu duplizieren.
- Stand: Der laufende HTML-Reviewbericht war auf TASK_527 aktualisiert; TASK_528 fuehrt ihn als Rolling-Status weiter.
- Risiken/offen: Es gibt noch kein finales Briefing-Panel, das diese Overlays sichtbar rendert. Icon-/Art-Polish und ein echter FullHD-Sichttest bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_527_briefing_minimap_team_spawn_overlay.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_526_mission_hud_team_chip_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_517_mission_scenario_vertical_slice.gd`, `git diff --check`.
- Naechster Schritt: Siehe `TASK_528 - Rolling HTML Status Report`; danach `TASK_529 - Mission HUD Team Icon Polish`.

### TASK_526 - Mission HUD Team Chip Polish
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_526_mission_hud_team_chip_polish.md`, `docs/tasks/TASK_525_team_badge_spawn_readability_polish.md`, `docs/tasks/TASK_523_pvp_team_readability_ui_pass.md`, `docs/tasks/TASK_520_multiplayer_team_ownership_smoke.md`, `docs/dev/multiplayer_session_lobby.md`, `docs/dev/html_report_workbench_contract.md`
- Stand: `MissionMultiplayerTeamOwnershipContract` liefert den Alpha/Bravo-Default-Team-Slice jetzt als shared Contract, damit Lobby und Mission denselben read-only Ownership-Vertrag lesen.
- Stand: `MissionTeamChipPresenter` baut aus `SimulationRoot.get_network_command_contract_snapshot()` kompakte Teamchips fuer Alpha/Bravo, Owner und Spawnmarker, ohne UI-Gameplay-Wahrheit zu erzeugen.
- Stand: Das laufende Mission-HUD zeigt die Teamchips im bestehenden Strategic-HUD und exposed Text plus Snapshot in `get_command_feedback_snapshot()`.
- Stand: Der laufende HTML-Reviewbericht ist als Zwischenbericht auf TASK_526 aktualisiert und nennt TASK_527 als naechsten Anschluss.
- Risiken/offen: Die Teamchips sind noch textuell. Briefing-Minimap-Spawn-Overlays, Icon-Sprache und manueller Zwei-Instanzen-LAN-Sichttest bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_526_mission_hud_team_chip_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_525_team_badge_spawn_readability_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_523_pvp_team_readability_ui_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_527 - Briefing Minimap Team Spawn Overlay`, wenn Alpha/Bravo-Spawnpunkte auch im Briefing sichtbar werden sollen.

### TASK_525 - Team Badge / Spawn Readability Polish
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_525_team_badge_spawn_readability_polish.md`, `docs/tasks/TASK_523_pvp_team_readability_ui_pass.md`, `docs/tasks/TASK_520_multiplayer_team_ownership_smoke.md`, `docs/dev/multiplayer_session_lobby.md`, `docs/dev/mission_briefing_contract.md`, `docs/dev/html_report_workbench_contract.md`
- Stand: `MissionMultiplayerTeamOwnershipContract` liefert zusaetzlich `badge_text`, `spawn_chip_text` und `spawn_marker_id` in den read-only Team-Readability-Eintraegen.
- Stand: Die produktive Multiplayer-Lobby rendert Alpha/Bravo aus dem Team-Readability-Snapshot als farbige Badges mit Owner und Spawn-Marker.
- Stand: `get_lobby_ui_snapshot()` expose't Badge-Text, Badge-Anzahl und Badge-Daten fuer Verifier und spaetere UI-Polish-Slices.
- Stand: Der laufende HTML-Reviewbericht ist als Zwischenbericht auf TASK_525 aktualisiert und nennt TASK_526 als naechsten Anschluss.
- Risiken/offen: Die Badges sind Label-basiert und noch keine finalen Icons. Briefing-Minimap-Overlays und Mission-HUD-Teamchips bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_525_team_badge_spawn_readability_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_523_pvp_team_readability_ui_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_520_multiplayer_team_ownership_smoke.gd`, `git diff --check`.
- Naechster Schritt: `TASK_526 - Mission HUD Team Chip Polish`, wenn Alpha/Bravo-Besitz auch im laufenden Missionsbild als kompakte Teamchips sichtbar werden soll.

### TASK_524 - Export Warning Noise Cleanup
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_524_export_warning_noise_cleanup.md`, `docs/tasks/TASK_511_export_runtime_package_hygiene.md`, `docs/dev/html_report_workbench_contract.md`, `data/export_runtime_package_contract.json`
- Stand: Das inaktive `godot-open-rts`-Referenzpaket behaelt seine upstream Projektdatei nur noch als `project.godot.reference`, damit Godot den Ordner nicht mehr als verschachteltes Projekt erkennt.
- Stand: Die Referenzpaket-Doku warnt explizit davor, die Datei ohne eigenen Integration-Task wieder zu `project.godot` umzubenennen.
- Stand: Der TASK_524-Verifier prueft Factory-GLBs, Factory-Colormap-Import, Export-Excludes und lokalen Godot-Filesystem-Cache auf die alte `uid://dsxohkhemn17r`-Warnquelle.
- Stand: Der laufende HTML-Reviewbericht ist als Zwischenbericht auf TASK_524 aktualisiert und nennt TASK_525 als naechsten Anschluss.
- Risiken/offen: Die Bereinigung deckt die aktuell bekannten Warnquellen ab. Neue Importwarnungen aus spaeteren Asset-Paketen brauchen eigene kleine Hygiene-Tasks.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_524_export_warning_noise_cleanup.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_511_export_runtime_package_hygiene.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_523_pvp_team_readability_ui_pass.gd`, `git diff --check`.
- Naechster Schritt: `TASK_525 - Team Badge / Spawn Readability Polish`, wenn Alpha/Bravo-Teamfarben und Spawnpunkte im Briefing/Mission-HUD sichtbarer werden sollen.

### TASK_523 - PvP Team Readability UI Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_523_pvp_team_readability_ui_pass.md`, `docs/tasks/TASK_520_multiplayer_team_ownership_smoke.md`, `docs/dev/multiplayer_session_lobby.md`, `docs/dev/multiplayer_player_roster_ownership_contract.md`, `docs/dev/html_report_workbench_contract.md`
- Stand: `MissionMultiplayerTeamOwnershipContract` liefert zusaetzlich read-only Anzeige-Felder fuer Teamfarbe, Kurzlabel, Owner-/Control-Text, UI-Chip und Team-Readability-Summary.
- Stand: `MultiplayerSession` haengt einen kompakten Team-Readability-Snapshot an Session-Snapshots, ohne Team-Assignments oder Gameplay-State im UI zu mutieren.
- Stand: Produktive Multiplayer-Lobby und Lobby-Testscreen zeigen die Summary sichtbar an und expose'n sie fuer Verifier-Snapshots.
- Stand: Der laufende HTML-Reviewbericht ist als Zwischenbericht auf TASK_523 aktualisiert und nennt TASK_524 als naechsten Anschluss.
- Risiken/offen: Die Anzeige ist noch textuell; Team-Badges, Spawnkarten und Mission-HUD-Teamchips bleiben Folgearbeit. Echter Zwei-Instanzen-LAN-Test bleibt manuell.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_523_pvp_team_readability_ui_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_520_multiplayer_team_ownership_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_167_multiplayer_session_verifier.gd`, `git diff --check`.
- Naechster Schritt: `TASK_524 - Export Warning Noise Cleanup`, wenn der Warn-Laerm aus Factory-UIDs und Referenzprojekt-Scan weiter reduziert werden soll.

### TASK_522 - Cargo Touchdown Visual Polish
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_522_cargo_touchdown_visual_polish.md`, `docs/tasks/TASK_519_cargo_touchdown_runtime_bridge.md`, `docs/tasks/TASK_518_mission_scenario_runtime_gates.md`, `docs/dev/air_asset_threat_damage_contract.md`, `docs/dev/html_report_workbench_contract.md`
- Stand: `MissionTacticalSandboxController` baut aus dem read-only `MissionCargoTouchdownBridge`-Snapshot einen Cargo-Air-Visual-Eintrag fuer blocked/pending/inbound/landed/departing.
- Stand: `TerrainMap3DView` rendert Cargo-Zielmarker, Anfluglinie, Frachterkoerper und Statuslabel im bestehenden Air-Visualpfad und meldet Cargo-spezifische Snapshot-Zaehler.
- Stand: Der laufende HTML-Reviewbericht nennt TASK_522 jetzt als aktuellen Zwischenstand und exportiert ihn in den Workbench-Metadaten.
- Risiken/offen: Der Frachter nutzt noch den bestehenden Air-/Dropship-Renderer als Visual-Proxy. Finales Cargo-Modell, Sound und manueller FullHD-Sichtcheck bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_522_cargo_touchdown_visual_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_519_cargo_touchdown_runtime_bridge.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_518_mission_scenario_runtime_gates.gd`, `git diff --check`.
- Naechster Schritt: `TASK_523 - PvP Team Readability UI Pass`, wenn Team-/Peer-/NPC-Besitz im Slice sichtbar werden soll.

### TASK_521 - Builder Drag Preview Visual Polish
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_521_builder_drag_preview_visual_polish.md`, `docs/dev/map_editor_asset_workflow_contract.md`, `docs/tasks/TASK_491_map_editor_runtime_builder_workbench.md`, `docs/tasks/TASK_492_map_editor_network_drag_snap_tools.md`, `docs/tasks/TASK_516_editor_builder_ux_pass.md`
- Stand: Der Map-Editor kann mit `preview_runtime_network_path_for_authoring(...)` einen read-only Network-Drag-Pfad fuer Pipe/Wall/Cliff/Road/Rail anzeigen, ohne Tile- oder Gameplay-Wahrheit zu mutieren.
- Stand: `MapEditor` spiegelt den bestehenden Network-Preview-Snapshot an die Primary3DView; Apply, Toolwechsel, Palette-Auswahl und explizites Clear entfernen die Preview wieder.
- Stand: `TerrainMap3DView` rendert aktive Network-Drag-Previews als farbige 3D-Linien mit Start-/Zielmarkern und meldet Art, Pfadlaenge, Segmentzahl und Markerzahl im Render-Snapshot.
- Risiken/offen: Der Headless-Test prueft Snapshot/Node-Zaehler und keine finale FullHD-Art-Direction. Segmentnummern, Handles und Icon-Polish bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_521_builder_drag_preview_visual_polish.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_516_editor_builder_ux_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_492_map_editor_network_drag_snap_tools.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_491_map_editor_runtime_builder_workbench.gd`, `git diff --check`.
- Naechster Schritt: `TASK_523 - PvP Team Readability UI Pass`, wenn der Fokus wieder auf Missions-/Multiplayer-Lesbarkeit wechselt.

### TASK_520 - Multiplayer Team Ownership Smoke
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_520_multiplayer_team_ownership_smoke.md`, `docs/dev/multiplayer_session_lobby.md`, `docs/dev/multiplayer_player_roster_ownership_contract.md`, `docs/dev/combat_loop_authority_contract.md`, `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`
- Stand: `frontier_probe_vertical_slice` unterscheidet jetzt Default-NPC-Besitz und `player_assignable_modes`, sodass Bravo solo/coop NPC bleibt, im `multiplayer_pvp` aber einem Peer zuweisbar ist.
- Stand: `scripts/mission/mission_multiplayer_team_ownership_contract.gd` baut einen read-only Team-Ownership-Snapshot aus Vertical-Slice-Team-Slots und MultiplayerSession-Assignments.
- Stand: Der Smoke prueft Host/Alpha, Peer2/Bravo, Scenario-owned NPC-Teams und ungueltige Peer-Zuweisungen auf nicht assignable NPC-Teams.
- Stand: `MultiplayerRosterContract` und `MultiplayerSession` fallen wieder auf `host_roster` als privacy-sicheren Default zurueck; `player_rosters` bleibt explizit waehlbar.
- Risiken/offen: Der echte Zwei-Instanzen-LAN-Test bleibt manuell; sichtbare PvP-Teamfarben, Spawn-/Ownership-Anzeige und Mission-UI-Polish sind Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_520_multiplayer_team_ownership_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_517_mission_scenario_vertical_slice.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_167_multiplayer_session_verifier.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_240_multiplayer_player_roster_ownership_contract.gd`, `git diff --check`.
- Naechster Schritt: `TASK_522 - Cargo Touchdown Visual Polish` ist umgesetzt; danach bietet sich `TASK_523 - PvP Team Readability UI Pass` an.

### TASK_519 - Cargo Touchdown Visual/Runtime Bridge
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_519_cargo_touchdown_runtime_bridge.md`, `docs/tasks/TASK_518_mission_scenario_runtime_gates.md`, `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`, `docs/dev/air_asset_threat_damage_contract.md`, `docs/dev/combat_loop_authority_contract.md`
- Stand: `scripts/mission/mission_cargo_touchdown_bridge.gd` bildet den Cargo-Frachter als read-only Runtime-Snapshot mit `blocked`, `inbound`, `landed`, `departing` und `departed` ab.
- Stand: `MissionCombatLoopDriver` konfiguriert die Cargo-Bridge aus Scenario-Dateien, spiegelt sie in `get_mission_cargo_touchdown_snapshot()` und reicht `cargo_state`/`cargo_hold_seconds` an die Runtime-Gates weiter.
- Stand: `get_playability_snapshot()` enthaelt `mission_cargo_touchdown`, ohne UI/Overlay zur Gameplay-Wahrheit zu machen; der alte `set_mission_scenario_cargo_state(...)`-Pfad bleibt kompatibel.
- Risiken/offen: Sichtbare Frachter-VFX/Map-Animation ist noch Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_519_cargo_touchdown_runtime_bridge.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_518_mission_scenario_runtime_gates.gd`, `git diff --check`.
- Naechster Schritt: Siehe `TASK_520 - Multiplayer Team Ownership Smoke`.

### TASK_518 - Mission Scenario Runtime Gates
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_518_mission_scenario_runtime_gates.md`, `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`, `docs/dev/mission_briefing_contract.md`, `docs/dev/air_asset_threat_damage_contract.md`, `docs/dev/combat_loop_authority_contract.md`
- Stand: `scripts/mission/mission_scenario_runtime_gates.gd` wertet `vertical_slice.flow_steps` als read-only Runtime-Gates fuer AA-Shutdown, Computer-Hold und Cargo-Touchdown/Extract aus.
- Stand: `MissionCombatLoopDriver` kann Scenario-Gates aus der Scenario-Datei konfigurieren, liefert `get_mission_scenario_runtime_gate_snapshot()`, spiegelt den Computer-Hold-Countdown in `ObjectiveStatus` und laesst den Szenario-Slice erst gewinnen, wenn alle Gates abgeschlossen sind.
- Stand: `MissionTestSetup` reicht Scenario-Dateien an die Gate-Bridge weiter; alte map-only Missionen bleiben davon unberuehrt.
- Risiken/offen: Die echte Frachter-Lande-/Abflug-Animation und PvP-Team-Ownership bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_518_mission_scenario_runtime_gates.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_517_mission_scenario_vertical_slice.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_505_frontier_probe_large_map_playtest_hotfix.gd`, `git diff --check`.
- Naechster Schritt: Siehe `TASK_519 - Cargo Touchdown Visual/Runtime Bridge`.

### TASK_517 - Mission Scenario Vertical Slice
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`, `docs/dev/mission_briefing_contract.md`, `docs/dev/air_asset_threat_damage_contract.md`, `docs/tasks/TASK_482_mission_briefing_data_contract.md`, `docs/tasks/TASK_500_gameflow_spine_hardening.md`, `docs/tasks/TASK_504_startmap_expansion_performance_pass.md`
- Stand: `data/mission_scenarios/frontier_probe_vertical_slice.json` beschreibt den naechsten spielbaren Mission-Slice auf `res://maps/station_outpost_192x192.json`: Luftabwehr ausschalten, Stationscomputer halten und Cargo-Touchdown/Extract decken.
- Stand: `scripts/mission/mission_scenario_vertical_slice_contract.gd` normalisiert und validiert den read-only `vertical_slice`-Payload fuer Play-Modes, Team-Slots und Flow-Steps, ohne Runtime-/UI-Gameplay-State zu mutieren.
- Stand: Der Homebase-Katalog bietet `frontier_probe_vertical_slice` mit Scenario-Datei an; die bestehende `frontier_probe` bleibt absichtlich map-only fuer alte Contracts.
- Stand: Das Briefing nutzt terrain-only Minimap, AA-/Computer-/Cargo-Ziele und kanonische `WeaponData`-Loadout-Empfehlungen (`sniper`, `rocket_launcher`, `rail_gun`, `medictool`).
- Risiken/offen: Echte Runtime-Gates fuer AA aus, Computer-Hold und Cargo-Abflug sind Folgearbeit; PvP braucht danach Team-/NPC-Besitz und Lobby-Smoke.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_517_mission_scenario_vertical_slice.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_504_startmap_expansion_performance_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_482_mission_briefing_data_contract.gd`, `git diff --check`.
- Naechster Schritt: `TASK_518 - Mission Scenario Runtime Gates` fuer AA-Shutdown, Computer-Hold und Cargo-Touchdown/Extract als autoritativen Runtime-Pfad schneiden.

### TASK_516 - Editor Builder UX Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_516_editor_builder_ux_pass.md`, `docs/dev/map_editor_asset_workflow_contract.md`, `docs/tasks/TASK_491_map_editor_runtime_builder_workbench.md`, `docs/tasks/TASK_492_map_editor_network_drag_snap_tools.md`, `docs/tasks/TASK_493_map_editor_station_builder_focus.md`
- Stand: Der Runtime-Map-Editor hat eine Palette-Suche, session-lokale Favoriten/Recent-Assets und Scale-Preset-Buttons fuer 0.5, 1.0, 1.6 und 2.0.
- Stand: Normale Palette-Auswahl, Quick-Brushes und Network-Tools pflegen die Recent-Liste, ohne Tile- oder Gameplay-State zu veraendern.
- Stand: Palette- und Builder-Snapshots melden Suchbegriff, Favoriten, Recent, Preview-Groessen, Scale-Presets und eine kompakte Network-Drag-Preview-Zusammenfassung.
- Risiken/offen: Favoriten/Recent sind noch nicht persistent. Eine sichtbare 3D-Drag-Linie fuer Pipe/Wall/Cliff bleibt ein eigener Visual-Polish-Slice.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_516_editor_builder_ux_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_493_map_editor_station_builder_focus.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_492_map_editor_network_drag_snap_tools.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_491_map_editor_runtime_builder_workbench.gd`, `git diff --check`.
- Naechster Schritt: Entweder sichtbare 3D-Drag-Preview fuer Pipe/Wall/Cliff oder `TASK_517 - Mission Scenario Vertical Slice`.

### TASK_515 - Combat Readability Presenter
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_515_combat_readability_presenter.md`, `docs/dev/combat_loop_authority_contract.md`, `docs/dev/runtime_script_layout_contract.md`, `docs/tasks/TASK_495_mission_combat_driver_boundary_review.md`, `docs/tasks/TASK_514_enemy_behavior_orchestrator.md`
- Stand: `scripts/tactical/combat_readability_presenter.gd` erzeugt und verwaltet die Legacy-Readability-Nodes fuer Combat-Kontaktlinie, Eventlabel, Winnerlabel und Statuslabel-Text.
- Stand: `MissionCombatLoopDriver` behaelt Tick-Reihenfolge, Remote-Event-Broadcast, Unit-`set_contact_state()` und Combat-Snapshots, delegiert aber Readability-Node-Erzeugung, Label-Formatierung, Sichtbarkeit und Kontaktlinienzeichnung an den Presenter.
- Stand: Der Presenter ist read-only gegen Gameplay-Authority: keine Commands, keine Effects, keine `SimulationRoot`-Referenz und keine Unit-Kontaktstatus-Mutation.
- Risiken/offen: Der Combat-Driver bleibt weiterhin Legacy-Bridge fuer Combat-State, Unit-Signale, Respawn/Bleedout, Remote-Events und Tick-Orchestrierung. Ein Folge-Slice sollte entweder Editor-UX sichtbar verbessern oder Enemy-/Combat-State-Aufbereitung weiter entflechten.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_515_combat_readability_presenter.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_192_mission_map_npc_behavior_playability_smoke.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`, `git diff --check`.
- Naechster Schritt: Sichtbar spielbare Politur priorisieren: Editor Builder UX Pass oder ein kleines Mission Scenario Vertical Slice.

### TASK_514 - Enemy Behavior Orchestrator
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_514_enemy_behavior_orchestrator.md`, `docs/dev/combat_loop_authority_contract.md`, `docs/dev/runtime_script_layout_contract.md`, `docs/tasks/TASK_495_mission_combat_driver_boundary_review.md`, `docs/tasks/TASK_513_mission_combat_resolution_boundary.md`
- Stand: `scripts/tactical/enemy_behavior_orchestrator.gd` baut die Command-Payloads fuer Enemy-Team-Tactics, Patrol, Fallback-Advance, Limbo-Cover/Hold und Damage-Reposition.
- Stand: `MissionCombatLoopDriver` behaelt Tick-Reihenfolge, LimboAI-Auswertung, Patrol-Indizes, Cooldowns und den autoritativen `SimulationRoot.enqueue_command()`-Aufruf, delegiert aber Payload-Building an den taktischen Orchestrator.
- Stand: Der Orchestrator hat keine SceneTree-Abhaengigkeit, enqueued keine Commands/Effects und fuehrt keinen Unit-State direkt mutierend aus.
- Risiken/offen: Enemy-Security-State, Team-Tactics-State-Building und LimboAI-Auswahl bleiben noch im Driver. Ein Folge-Slice kann diese State-Aufbereitung weiter in Tactical-Resolver verschieben.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_514_enemy_behavior_orchestrator.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_513_mission_combat_resolution_boundary.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`, `git diff --check`.
- Naechster Schritt: Combat Readability Presenter oder Editor Builder UX Pass schneiden, je nachdem ob der naechste Fokus technische Entflechtung oder sichtbare Bedienbarkeit ist.

### TASK_513 - Mission Combat Resolution Boundary
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_513_mission_combat_resolution_boundary.md`, `docs/dev/combat_loop_authority_contract.md`, `docs/tasks/TASK_495_mission_combat_driver_boundary_review.md`, `docs/reviews/mission_combat_driver_boundary_review_2026_05_24.md`
- Stand: `scripts/mission/mission_combat_resolution_resolver.gd` kapselt die read-only Entscheidung fuer Zeitlimit-Defeat, Victory-Conditions, Friendly-Defeat, Objective-/Time-Countdown und MissionResult-Payload.
- Stand: `MissionCombatLoopDriver` bleibt Tick-/Event-/RPC-Orchestrator, delegiert aber Resolution-Entscheidung, Victory-Condition-Check, Countdown-Source und MissionResult-Building an den Resolver.
- Stand: Der Resolver hat keine SceneTree-Abhaengigkeit, enqueued keine Commands/Effects und behaelt die bestehenden MissionResult-/Snapshot-Keys bei.
- Risiken/offen: Enemy-Behavior, Readability-UI und Remote-Event-Reste bleiben im Driver. Naechste Review-Slices bleiben Enemy Behavior Orchestrator oder Combat Readability Presenter.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_513_mission_combat_resolution_boundary.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_496_mission_combat_registry_and_elimination_hotfix.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`, `git diff --check`.
- Naechster Schritt: Enemy-Behavior-Orchestrator als TASK_514 schneiden oder sichtbarere Spiel-/Editor-UX-Politur priorisieren, wenn der Fokus gerade Bedienbarkeit ist.

### TASK_512 - Mission Controller Boundary Slice
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_512_mission_controller_boundary_slice.md`, `docs/dev/runtime_script_layout_contract.md`, `docs/dev/combat_loop_authority_contract.md`, `docs/reports/project_review_status_2026_06_28.html`
- Stand: `scripts/mission/mission_fireteam_runtime_state.gd` kapselt den lesenden Fireteam-Dropship-/Runtime-Status fuer embarked, deployed, ground-filtered, displayable und runtime-active.
- Stand: `MissionTacticalSandboxController` behaelt seine privaten Kompatibilitaetsmethoden, delegiert die Statusberechnung aber an den Mission-Helper. Die Mini-Card-Displayable-Liste gruppiert Kandidaten-Units einmal statt pro Fireteam wiederholt zu scannen.
- Stand: Der Helper hat keine SceneTree-Abhaengigkeit und enqueued keine Commands/Effects; Gameplay-Mutationen bleiben weiter bei `SimulationRoot` und den bestehenden Dropship-Effect-Adaptern.
- Risiken/offen: Der grosse Mission-Controller bleibt Legacy-Bridge. Gute Folge-Slices sind Dropship-Mission-State, Fireteam-Execution-Adapter und Mission-Combat-Result-Boundary.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_512_mission_controller_boundary_slice.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_503_mission_dropship_fireteam_hud_truth.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`, `git diff --check`.
- Naechster Schritt: TASK_513 als Mission Combat Resolution Boundary schneiden oder vorher eine kleine sichtbare UX-Politur an Editor/Fireteam-HUD aus dem Review priorisieren.

### TASK_511 - Export Runtime Package Hygiene
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_511_export_runtime_package_hygiene.md`, `docs/dev/export_runtime_package_contract.md`, `docs/performance/performance_regression_gate.md`
- Stand: `data/export_runtime_package_contract.json` definiert die Runtime-Export-Excludes fuer Editor-/Authoring-/Docs-/Test-/Tool-Pfade, ohne Runtime-Addons wie `limboai`, `terrain_3d`, `netfox` oder `netfox.internals` auszuschliessen.
- Stand: `scripts/tools/export_runtime_release.ps1` patcht den lokal ignorierten `export_presets.cfg` nur temporaer, fuehrt den Windows-Release-Export aus und stellt den lokalen Preset danach wieder her.
- Stand: Der neue Verifier prueft Contract, Script, Exclude-Patterns, Runtime-Addon-Allowlist und Doku-/Roadmap-Anbindung.
- Stand: Echter Release-Export ueber das Script laeuft mit `EXPORT_EXIT=0`; `Sternenbuergerchen_rel.pck` liegt bei `194203876` Bytes statt `242312564` Bytes im vorherigen breiten Roh-Export.
- Stand: Pack-Log-Stichprobe zeigt keine gespeicherten Editor-/Authoring-/Docs-/Test-/Tool-Pfade aus dem Contract; die verbleibende Godot-Meldung ist eine Scanwarnung fuer das zweite `project.godot` im ausgeschlossenen Referenzprojekt.
- Risiken/offen: Der lokale `export_presets.cfg` bleibt absichtlich untracked. Die Referenzprojekt-Scanwarnung kann spaeter durch Umzug/Deaktivierung des Referenz-Addons weiter bereinigt werden, ist aber kein Release-Abbruch.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_511_export_runtime_package_hygiene.gd`, `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1 -SkipExport`, `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`, `git diff --check`.
- Naechster Schritt: Full-Review-Report aktualisieren und danach entscheiden, ob die verbleibende Editor-Scanwarnung separat als Plugin-/Referenzprojekt-Hygiene-Task geschnitten wird.

### TASK_510 - Contact Report Upgrade
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_510_contact_report_upgrade.md`, `docs/dev/contact_report_contract.md`, `docs/dev/tactical_decision_clarity_contract.md`
- Stand: `ContactTracker` liefert Contact Reports mit `enemy_type`, `approximate_position`, `confidence`, `confidence_level`, `report_state`, Sichtungsalter, Unsicherheit und `report_text`; UI-Felder bleiben read-only und setzen keine Gameplay-Wahrheit.
- Stand: Mission-Combat reicht den aktuellen Tick und grobe Gegner-Typen in den Tracker; der TacticalController reichert die Meldungen mit FTL-Reportqualitaet an und speist deduplizierte `contact_report`-Eintraege in den bestehenden Tactical-Event-Log-Adapter.
- Stand: 2D-ContactMapOverlay und Primary-3D-View unterscheiden aktuelle, last-known und stale Kontakte sichtbar und expose die neuen Report-Felder in ihren Snapshots.
- Risiken/offen: Enemy-Typisierung und Gruppierung sind MVP; aggregierte Meldungen wie "2 Gegner, vermutlich Riflemen" bleiben ein spaeterer Politur-Slice. Manueller F6-Sichttest wurde auf Wunsch uebersprungen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_510_contact_report_upgrade.gd`, `task_112_verifier.gd`, `task_506_tactical_decision_clarity_contract.gd`, `git diff --check`.
- Naechster Schritt: TASK_511 AI Intent Bubble Debug Toggle oder kleiner Sicht-/UX-Polish fuer Contact-Report-Gruppierung.
### TASK_506-TASK_509 - Tactical Decision Clarity Block
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_506_tactical_decision_clarity_contract.md`, `docs/tasks/TASK_507_order_preview_ghosts_mvp.md`, `docs/tasks/TASK_508_line_of_fire_threat_analyzer_mvp.md`, `docs/tasks/TASK_509_combined_preview_overlay.md`, `docs/dev/tactical_decision_clarity_contract.md`, `docs/tasks/TASK_375_waypoint_intent_preview.md`, `docs/dev/runtime_script_layout_contract.md`
- Stand: Der bestehende `waypoint_intent_preview` wurde zum Tactical-Decision-Clarity-Payload erweitert: Ghost-Pfad, ETA, Risk-State, Threat-Analyse, Cover-State, Enemy-Exposure und Line-of-Fire-Eintraege bleiben ein read-only Preview-Snapshot vor `GO`.
- Stand: `TacticalDecisionThreatAnalyzer` bewertet uebergebene Enemy-/Contact-Snapshots mit `LineOfSightSystem`, Terrain-Cover und Friendly-Fire-Korridor. Ohne Contact-/Threat-Kontext bleibt das Risiko bewusst `unknown`, statt Gegnerwissen zu erfinden.
- Stand: `FireteamOrderVisualizer` und `TerrainMap3DView` zeichnen den kombinierten Preview-Payload mit Gruen/Gelb/Rot/Grau/Orange und melden Primary-View-Zaehler fuer Ghost-, Pfad- und Threat-Linien.
- Risiken/offen: Die Klassifikation ist ein grober MVP fuer Entscheidungslesbarkeit. Contact-Report-UI, AI-Intent-Bubbles, Squad-Spacing-Modi, Hold-Fire-Disziplin, Command-Kosten und Mini-AAR bleiben Folge-Tasks.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd`, `task_375_waypoint_intent_preview.gd`, `task_456_wall_segment_los_and_tile_truth_inspector.gd`, `git diff --check`.
- Naechster Schritt: F6-Sichttest in der Mission: Move-Ziel klicken, Ghost/Pfad/Threat-Linien vor `GO` lesen und danach TASK_510 Contact Report Upgrade schneiden.
### TASK_504 - Startmap Expansion Performance Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_504_startmap_expansion_performance_pass.md`, `docs/dev/terrain_truth_visual_audit_contract.md`, `docs/dev/map_editor_asset_workflow_contract.md`, `docs/tasks/TASK_494_station_outpost_64_map.md`, `docs/tasks/TASK_500_gameflow_spine_hardening.md`
- Stand: `maps/station_outpost_192x192.json` erweitert die bisherige 64x64-Startmap als 3x3-Stempelkarte; der bisherige Startbereich bleibt exakt im mittleren Sektor erhalten.
- Stand: Die Aussen-Sektoren nutzen gedrehte/leicht variierte Kopien mit Station-, Factory-, Pipe-, Cliff-, Hoehen- und Nature-Content, waehrend Marker und Patrol-Routen nur einmalig in den mittleren Sektor verschoben werden.
- Stand: `frontier_probe` nutzt im Homebase-Missionskatalog die neue getrackte `res://maps/station_outpost_192x192.json`; der Verifier prueft zusaetzlich das 2.5D-Visual-Streaming fuer die grosse Map.
- Risiken/offen: Die 192x192-Map ist eine grosse Playtest-Startkarte, aber noch kein final balanciertes Szenario. Spaeter kann ein Sparse-/Chunk-Mapformat sinnvoll werden, falls JSON-Groesse oder Editor-Speichern spuerbar werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tools/generate_station_outpost_192x192.gd`, `task_504_startmap_expansion_performance_pass.gd`, `task_494_station_outpost_64_map.gd`, `task_500_gameflow_spine_hardening.gd`, `git diff --check`.
- Naechster Schritt: Sichttest in der Mission und danach entscheiden, ob Aussen-Sektoren manuell weitergebaut oder als eigenes Szenario balanciert werden.

### TASK_501 - Integrated Movement Command Lifecycle Hardening
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_501_integrated_movement_command_lifecycle_hardening.md`, `docs/dev/runtime_script_layout_contract.md`, `docs/dev/tactical_command_doctrine_game_abstraction.md`, `docs/dev/terrain_truth_visual_audit_contract.md`, `docs/dev/combat_loop_authority_contract.md`
- Stand: `SimulationRoot` verwirft unaufloesbare oder token-stale Move-Commands jetzt ohne Requeue und legt dazu eine read-only Discard-Diagnose mit Reason, Unit, Token, Zielposition und Count ab.
- Stand: `TASK_192` folgt dem aktuellen Movement-Contract: normale Move-Wegpunkte duerfen als kompakte Rush-/Gruppenbewegung sichtbar sein, waehrend Bounding/Caterpillar weiter fuer passende Taktikpfade gueltig bleibt. Der Medic-Smoke sucht eine echte walkable Nah-/Zwei-Tile-Fixture statt an einer zu engen Objective-Naheinstellung zu haengen.
- Stand: `TASK_127` nutzt ein Ausfuehrungsfenster, das die aktuellen Unit-Speed-/Surface-Vertraege beruecksichtigt, ohne HPA-Pfadaufbau oder Traversal-Regeln zu lockern.
- Risiken/offen: Die grossen Mission-Controller bleiben Legacy-Bridge unter `scripts/tests/`; dieser Task behebt den Lifecycle-Guard und die roten Gates, ersetzt aber keine strukturelle Extraktion.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_501_integrated_movement_command_lifecycle_hardening.gd`, `task_127_verifier.gd`, `task_192_mission_map_npc_behavior_playability_smoke.gd`, `task_160_tactical_playability_verifier.gd`, `task_475_fireteam_pathfinding_avoidance_stability_pass.gd`, `task_479_fireteam_runtime_hotpath_guards.gd`, `task_500_gameflow_spine_hardening.gd`, `git diff --check`.
- Naechster Schritt: Bei Bedarf die grosse Mission-Controller-Extraktion als separaten Folge-Task schneiden.

### TASK_500 - Gameflow Spine Hardening
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_500_gameflow_spine_hardening.md`, `docs/dev/runtime_script_layout_contract.md`, `docs/dev/terrain_truth_visual_audit_contract.md`, `docs/dev/homebase_direct_dropship_flow_contract.md`, `docs/dev/flight_altitude_layer_contract.md`
- Stand: Outbound-Dropships behalten die zuletzt genutzte LZ wieder als Terrain-Field-Marker in der 2.5D-Missionsansicht, waehrend Touchdown/Deboarding den geplanten LZ-/Approach-Marker weiter ausblendet.
- Stand: Der alte Multi-Dropship-Regressionstest folgt jetzt dem aktuellen nummerierten LZ-Labelvertrag (`LZ1/LZ2` plus Dropship-Displayname), ohne die per-craft Payload-/LZ-Besitzchecks aufzuweichen.
- Stand: `task_399_dropship_flow_contract_performance_pass.gd` prueft seine Dropship-Hotpath-Zaehler in einer gemeinsamen Missionsinstanz statt mit drei Vollszenen-Instanzierungen und laeuft wieder lokal durch.
- Stand: `frontier_probe` nutzt im Homebase-Missionskatalog eine getrackte Station-Outpost-Map statt der lokalen Editor-Arbeitsdatei `res://maps/new_map.json`; TASK_504 erweitert diese Startkarte auf `res://maps/station_outpost_192x192.json`.
- Risiken/offen: Die grossen Mission-Controller bleiben Legacy-Bridge unter `scripts/tests/`; die eigentliche Extraktion bleibt Folgearbeit. `TASK_160` ist gruen, meldet aber weiter bekannte SimulationRoot-Warnungen fuer nicht aufloesbare Move-Command-Ziele.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`, `task_160_tactical_playability_verifier.gd`, `bugfix_mission_multi_dropship_cards.gd`, `task_393_direct_dropship_independence_lz_vector.gd`, `task_396_mission_dropship_lz_drop_hotfix.gd`, `task_399_dropship_flow_contract_performance_pass.gd`, `task_499_review_followup_architecture_cleanup.gd`, `git diff --check`.
- Naechster Schritt: Kleinen Folgetask fuer die Move-Command-Warnungen oder fuer die erste Mission-Controller-Extraktion schneiden.

### TASK_499 - Review Followup Architecture Cleanup
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_499_review_followup_architecture_cleanup.md`, `docs/dev/runtime_script_layout_contract.md`, `docs/dev/audio_event_contract.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`
- Stand: Die unreferenzierte `scenes/main.tscn` ohne Script-Zuweisungen ist entfernt; `project.godot` startet weiter in `res://scenes/ui/main_menu.tscn`.
- Stand: `SimulationRoot._resolve_audio_event_bus()` nutzt nur noch exportierten NodePath, direkten Child-Node oder direkten Parent-Sibling und cached den Treffer; der Deep-SceneTree-Scan ist aus dem Snapshot-Audiopfad entfernt.
- Stand: Die Homebase-Katalogeintraege `frontier_probe` und `wall_breach` markieren map-only Missionen explizit mit `NO_SCENARIO_FILE_PATH`, und `show_npc_thoughts` hat im Projekt eine T-Defaultbindung.
- Risiken/offen: Weitere Audio-Deep-Scans in UI-/Visual-/Legacy-Pfaden und die `scripts/tests/`-Produktionspfad-Extraktion bleiben Folgearbeit. Der offene `frontier_probe`-Map-Verweis wurde in TASK_500 auf eine getrackte Karte umgebogen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_499_review_followup_architecture_cleanup.gd`, `git diff --check`.
- Naechster Schritt: Eigenen Folgetask fuer AudioEventBus-Resolver-Vereinheitlichung oder fuer die MissionCombatLoopDriver-Extraktion schneiden.

### TASK_498 - Runtime Script Layout Alignment
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_498_runtime_script_layout_alignment.md`, `docs/dev/runtime_script_layout_contract.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`, `docs/tasks/TASK_003_simulation_root.md`, `docs/tasks/TASK_162_combat_loop_authority_split.md`
- Stand: `scripts/core/` ist dokumentiert als aktueller Runtime-Kernpfad fuer `SimulationRoot`, `DamageModel`, `ObjectiveStatus`, `RespawnManager`, `EventRouter`, `UpdateManager`, LOS/Fog-of-War und gemeinsame Runtime-Lesedaten.
- Stand: `scripts/mission/`, `scripts/tactical/` und `scripts/tests/` haben klare Schreibgrenzen fuer Mission-Contracts/Adapter, Tactical-Resolver/Controller und Verifier/Harnesses.
- Stand: `scripts/simulation/` ist als inaktiver/reservierter Pfad erklaert; die alte `.gitkeep` ist durch eine README mit Migrationshinweis ersetzt.
- Risiken/offen: Keine Runtime-Pfade wurden verschoben. Eine echte Migration nach `scripts/simulation/` bleibt ein eigener, breiter Godot-`res://`-Kompatibilitaets-Task.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_498_runtime_script_layout_alignment.gd`, `git diff --check`.
- Naechster Schritt: Die Mission-Combat-Driver-Extraktionen weiter in kleinen Boundary-Slices schneiden, ohne neue produktive Logik in `scripts/tests/` oder `scripts/simulation/` abzulegen.

### TASK_497 - Mission TestSetup Reference Cleanup
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_497_mission_test_setup_reference_cleanup.md`, `docs/tasks/TASK_064_mission_terrain_aus_json.md`, `docs/tasks/TASK_159_2_5d_editor_and_mission_primary_view.md`, `docs/tasks/TASK_494_station_outpost_64_map.md`, `docs/dev/terrain_truth_visual_audit_contract.md`
- Stand: `MissionTestSetup` nutzt `simulation_root_path` als exportierten Setup-Contract und loest den Root ueber `_get_simulation_root()` auf.
- Stand: Die alte Terrain-Hardcode-Fallbacklogik ist als `LEGACY_FALLBACK_*`-Fixture-Datenstruktur gebuendelt, waehrend JSON-TerrainMapData fuer 64x64-Maps weiter direkt in die TerrainRegistry registriert wird.
- Stand: Der ungenutzte `_find_tile_sprite_at()`-Nearest-Sprite-Suchhelper ist entfernt; der neue Verifier deckt Source-Contract, Szenen-NodePath, JSON-Prioritaet und Legacy-Fallbackwerte ab.
- Risiken/offen: Der Fix aendert keine Terrain-Wahrheit, LOS-Regeln oder 2.5D-Rendering. `TASK_159` ist lokal bei 2.5D-Visual-Checks rot; `TASK_160` bleibt lokal beim bekannten LZ-Terrain-Field-Marker-Check rot.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_497_mission_test_setup_reference_cleanup.gd`, TASK_494-Regression und `git diff --check` gruen; `TASK_159` lokal rot bei Field-Border-/Kenney-Ground-/Unit-Facing-/Dropship-Facing-Checks, `TASK_160` lokal rot bei `2.5D primary view shows the LZ as a terrain field marker`.
- Naechster Schritt: `TASK_498 - Runtime Script Layout Alignment` oder separater LZ-Terrain-Field-Marker-Fix.

### TASK_496 - Mission Combat Registry and Elimination Hotfix
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_496_mission_combat_registry_and_elimination_hotfix.md`, `docs/tasks/TASK_495_mission_combat_driver_boundary_review.md`, `docs/dev/combat_loop_authority_contract.md`, `docs/tasks/TASK_041_siegbedingung.md`, `docs/tasks/TASK_479_fireteam_runtime_hotpath_guards.md`
- Stand: `SimulationRoot` bietet mit `get_unit_registry()` einen oeffentlichen lesenden Registry-Zugriff, und der `MissionCombatLoopDriver` ruft den privaten Root-Helper `_get_unit_registry()` nicht mehr von aussen auf.
- Stand: `_is_enemy_team_eliminated()` prueft pending Enemy-Waves und pending Enemy-Respawns zuerst; wenn danach keine aktiven Enemy-Units mehr vorhanden sind, gilt die Eliminierung als erreicht.
- Stand: Der neue Verifier deckt oeffentlichen Registry-Zugriff, entfernten privaten Driver-Aufruf, leere aktive Enemy-Listen, pending Waves, pending Respawns, downed Enemies und fitte aktive Enemies ab.
- Risiken/offen: Der Fix aendert nur die Elimination-Wincondition; Objective-Capture und Objective-Defense bleiben unveraendert. Die groessere Driver-Entflechtung bleibt Folgearbeit aus TASK_495. `TASK_160` faellt lokal weiterhin am LZ-Terrain-Field-Marker-Check aus, obwohl der Missionsfluss bis Victory gruen bleibt.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_496_mission_combat_registry_and_elimination_hotfix.gd`, TASK_479-/TASK_473-Regressionen und `git diff --check` gruen; `TASK_160` lokal rot bei `2.5D primary view shows the LZ as a terrain field marker`.
- Naechster Schritt: Objective-/Mission-Result-Boundary als kleiner Folgeslice oder `TASK_497 - Mission TestSetup Reference Cleanup`.

### TASK_495 - Mission Combat Driver Boundary Review
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_495_mission_combat_driver_boundary_review.md`, `docs/reviews/mission_combat_driver_boundary_review_2026_05_24.md`, `docs/dev/combat_loop_authority_contract.md`, `docs/tasks/TASK_118_combat_entscheidungen_aus_mission_driver_herausloesen.md`, `docs/tasks/TASK_162_combat_loop_authority_split.md`
- Stand: Der aktuelle `MissionCombatLoopDriver` wurde als 3845-Zeilen-Orchestrator mit Tick-Reihenfolge, Combat, Enemy-Behavior, Objective-/Mission-Result, Respawn/Bleedout, UI-Readability und Remote-Events gegen die bestehenden Resolver/Contracts abgeglichen.
- Stand: Bereits produktiv ausgelagerte Grenzen (`CombatFireDecisionResolver`, `MedicSupportResolver`, `OverwatchController`, `ContactTracker`, `FlankVulnerabilityResolver`, `MissionCombatAuthorityContract`, `MissionCombatRemoteEventBridge`) sind dokumentiert; veraltete Review-Befunde wie `roll_override: 0.4` und duplizierter Bleedout-Code sind als obsolete markiert.
- Stand: Die Folge-Reihenfolge ist festgelegt: zuerst `TASK_496` fuer Registry/Elimination, danach Objective-/Mission-Result-Boundary, Enemy-Behavior-Orchestrator, Readability-Presenter und Remote-Event-Bridge-Completion.
- Risiken/offen: Keine Runtime-Codeaenderung in diesem Task. Der Driver bleibt gross; die eigentliche Entflechtung muss in kleinen Folge-Slices passieren.
- Lokale Pruefung: `rg`/Code-Lektuere gegen Driver-Funktionen und vorhandene Resolver/Contracts, `git diff --check`.
- Naechster Schritt: `TASK_496 - Mission Combat Registry and Elimination Hotfix`.

### TASK_494 - Station Outpost 64x64 Map
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_494_station_outpost_64_map.md`, `docs/dev/map_editor_asset_workflow_contract.md`, `docs/tasks/TASK_493_map_editor_station_builder_focus.md`
- Stand: `maps/station_outpost_64x64.json` ist eine 64x64-Authoring-/Playtest-Map mit Station-Komplex, Door-States, Hoehenruecken, Cliff-Assets, Factory-Yard, Pipes, Cover und Markern.
- Stand: `scripts/tools/generate_station_outpost_64x64.gd` erzeugt die Map reproduzierbar aus bestehenden Terrain-/Station-/Factory-/Pipe-Katalog-IDs.
- Stand: Der Verifier prueft Groesse, Katalog-IDs, Station-/Factory-/Pipe-/Door-Mix, Hoehen, Cliffs, Nature-Cover, Marker und Patrol-Routen.
- Risiken/offen: Die Map ist noch kein balanciertes Missionsszenario; sichtbarer F6-Test und manuelles Feintuning von Asset-Groessen/Rotationen bleiben sinnvoll.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tools/generate_station_outpost_64x64.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_494_station_outpost_64_map.gd`, `git diff --check`.
- Naechster Schritt: Map im Runtime-Editor laden und sichtbare Station-/Huegel-/Pipe-Details manuell nachziehen.

### TASK_493 - Map Editor Station Builder Focus
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_493_map_editor_station_builder_focus.md`, `docs/dev/map_editor_asset_workflow_contract.md`, `docs/tasks/TASK_492_map_editor_network_drag_snap_tools.md`
- Stand: Die sichtbare Runtime-Builder-Leiste fokussiert den aktuellen Station-/Outpost-Workflow: Pipe-Line, Wall-Line, Cliff-Line, Factory, Space-Floor und Space-Station-Tueren.
- Stand: Road-Line und Rail-Line bleiben als vorbereitete Backend-Pfade testbar, sind aber nicht mehr als Hauptbuttons in der linken Builder-Leiste sichtbar.
- Stand: Door-Wall, Door-Closed, Door-Half und Door-Open nutzen vorhandene Space-Station-Katalog-IDs; der Usability-Snapshot beschreibt Closed/Half/Open fuer Single- und Double-Doors als Authoring-Contract.
- Risiken/offen: Tueranimation, Naehebedienung und Computer-/Pipeline-Gameplay sind weiterhin Folge-Contracts.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_493_map_editor_station_builder_focus.gd`, TASK_492-/TASK_491-Regressionen und `git diff --check`.
- Naechster Schritt: Sichttest per F6 und danach Door-/Computer-Interaction-Contract schneiden.

### TASK_492 - Map Editor Network Drag Snap Tools
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_492_map_editor_network_drag_snap_tools.md`, `docs/dev/map_editor_asset_workflow_contract.md`, `docs/tasks/TASK_491_map_editor_runtime_builder_workbench.md`
- Stand: Die Runtime-Builder-Leiste bietet Linienwerkzeuge fuer Road, Rail, Pipe, Wall und Cliff sowie Quick-Brushes fuer Factory und Modular-/Space-Floor.
- Stand: `apply_runtime_network_path_for_authoring` setzt orthogonale Pfade als einen Undo-Schritt und waehlt End-, Straight-, Corner-, Split- und Cross-Varianten anhand der lokalen Nachbarn.
- Stand: Der Grundstrassensatz nutzt die Space-Kit-Road-Surface-Varianten, Rails/Pipes bleiben Object-Layer-Assets, und Factory-/SpaceKit-/StationSet-/Modular-/Wall-/Cliff-Prefixe sind fuer Placement-Scale-Korrekturen freigeschaltet.
- Risiken/offen: Bruecken, Rampen, Gruenstrassen, Hoch-/Runter-Strassen sowie Door-/Computer-/Pipeline-Gameplay brauchen eigene Folgeslices.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_492_map_editor_network_drag_snap_tools.gd`, TASK_491-/TASK_483-/TASK_485-Regressionen und `git diff --check`.
- Naechster Schritt: Sichttest per F6 in `res://scenes/editor/map_builder_workbench.tscn`, dann Drag-Preview/Icons und Door-/Computer-Interaction-Contract schneiden.

### SPIKE - Unity Commander Flow Prototype
- Status: erweitert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/SPIKE_unity_commander_flow.md`, `docs/PROJECT_BRIEF.md`, `docs/DESIGN_NOTES.md`, `docs/User-Handbuch.md`, `docs/GDD_STATUS.md`
- Stand: Das Unity-6000.4.1f1-Sidecar-Projekt liegt lokal ausserhalb des Godot-Repositories unter `C:\dev\SternenBuergerchen_UnityCommanderFlow` und enthaelt eine spielbare `CommanderFlowSpike`-Szene.
- Stand: Das Godot-Repository trackt keine Unity-Projektdateien, Unity-Assets, Unity-Caches oder Unity-Builds mehr; `spikes/unity_commander_flow` ist entfernt und ignoriert.
- Stand: Der Spike bildet den Kernfluss ab: Homebase-Roster, Fireteam-Bildung, Loadout-/Armor-Auswahl, Dropship-Zuweisung, parallele Missionsstarts und isometrische 3D-Missionsansicht.
- Stand: Die Missionen nutzen jetzt ein kleines CC0-Quaternius-Asset-Subset fuer Infanterie, Dropships, Gegner, Waffen und Sci-Fi-Props. Commands laufen als Fireteam-Auftraege (`Move`, `Defend`, `Take`, `Engage`, `Flank`) und werden ueber ein kleines C#-Simulationsmodell verarbeitet.
- Stand: Ein Runtime-Missionseditor im Play-Mode schreibt Kacheltypen, LZ, Objective und Gegner-Spawns in den MissionCatalog; beim Missionsstart wird daraus ein stabiler MissionState kopiert.
- Risiken/offen: Das ist keine Engine-Migration und kein Produktions-UI. Editor-Persistenz, echtes Save/Load, Balancing und finales Terrain bleiben offen. Der externe Unity-Ordner ist lokale Arbeitsablage und wird nicht durch dieses Git-Repository versioniert. Ein manueller Sicht-/Klicktest im Unity-Play-Mode bleibt als Spielgefuehl-Check sinnvoll.
- Lokale Pruefung: `dotnet run --project C:\dev\SternenBuergerchen_UnityCommanderFlow\Verifier\SpikeVerifier.csproj`, Unity-Batch `SternenBuergerUnitySpike.Editor.SpikeSceneBuilder.Build`, Unity-Batch `SternenBuergerUnitySpike.Editor.SpikeFlowVerifier.Run`, Unity-Batch `SternenBuergerUnitySpike.Editor.SpikePlayerBuilder.BuildWindows`.
- Naechster Schritt: Im Unity-Editor per Vulkan-Starter Play druecken, Alpha/Bravo parallel testen und den Runtime-Editor einmal Kacheln/LZ/OBJ/Enemy-Spawns malen lassen.

### TASK_491 - Map Editor Runtime Builder Workbench
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_491_map_editor_runtime_builder_workbench.md`, `docs/dev/map_editor_asset_workflow_contract.md`, `docs/dev/map_builder_tooling_spike_contract.md`
- Stand: Der primaere Baufluss liegt wieder im Sternenbuergerchen-Map-Editor: `map_editor.tscn` erzeugt links eine Runtime-Builder-Toolleiste fuer Select, Terrain, Road, Asset, Erase, Height, Marker, Patrol und Rotation.
- Stand: Die Builder-Quick-Tools nutzen bestehende Map-Editor-Kommandos (`set_authoring_tool`, `set_palette_type_for_authoring`) und schreiben keine zweite Gameplay-Wahrheit.
- Stand: `map_builder_workbench.tscn` startet im sichtbaren F6-Spielmodus direkt den Runtime-Map-Editor; headless bleibt der alte Workbench-/Compile-Pfad fuer Verifier verfuegbar.
- Risiken/offen: Auto-Snapping/Auto-Rotation fuer Strassen, Waende, Tueren und Cliffs sowie echte Icon-Politur bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_491_map_editor_runtime_builder_workbench.gd`, relevante TASK_490-/TASK_488-Regressionen und `git diff --check`.
- Naechster Schritt: Sichttest per F6 auf `res://scenes/editor/map_builder_workbench.tscn`, danach Road-/Wall-Drag-Tool als eigener Runtime-Editor-Slice.

### TASK_490 - Map Builder Paint Tools MVP
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_490_map_builder_paint_tools_mvp.md`, `docs/tasks/TASK_489_map_builder_workbench_editor_entry.md`, `docs/dev/map_builder_tooling_spike_contract.md`
- Stand: Das `Map Builder`-Dock hat jetzt eine Manifest-Palette mit Kategorie-Filter, Auswahl-Label, Rotation, Hoehenwert und Scale.
- Stand: Paint/Erase/Rotate laufen als echte Editor-Werkzeuge: Linksklick im 3D-Viewport setzt GridMap-Tiles oder legt Prop-Nodes unter `AssetPlacerProps` mit `sb_*`-Metadaten an; Q/E drehen die Platzierung.
- Stand: Die Workbench bietet pruefbare APIs `place_grid_item`, `erase_grid_cell` und `place_prop`, damit der funktionale Editor-Pfad headless gegen den Compile nach `TerrainMapData` abgesichert ist.
- Risiken/offen: Sichtbarer Viewport-Test in Godot bleibt offen; Auto-Tiling fuer Strassen/Waende und Drag-Paint-Politur sind Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_490_map_builder_paint_tools_mvp.gd`, TASK_489-/TASK_488-Regressionen und `git diff --check`.
- Naechster Schritt: Im sichtbaren Editor eine kleine Map mit Paint/Erase/Rotate bauen und dann Auto-Road-/Wall-Snapping als naechsten Bedien-Slice schneiden.

### TASK_489 - Map Builder Workbench Editor Entry
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_489_map_builder_workbench_editor_entry.md`, `docs/tasks/TASK_488_map_builder_workbench_meshlibrary_mvp.md`, `docs/dev/map_builder_tooling_spike_contract.md`
- Stand: Das Projekt aktiviert ein eigenes Godot-Editor-Plugin `Map Builder Workbench` unter `addons/map_builder_workbench`.
- Stand: Das Dock sitzt links und nutzt eine kompakte Icon-Leiste fuer Workbench oeffnen, MeshLibrary vorbereiten, GridMap auswaehlen, AssetPlacerProps auswaehlen und nach Mission-JSON kompilieren.
- Stand: F6 zeigt in der Workbench jetzt einen Hinweis, dass die Scene nur Vorschau ist und der Baufluss ueber das Editor-Dock laeuft.
- Risiken/offen: Der sichtbare Bediencheck in Godot steht noch aus: Editor neu starten, Dock `Map Builder` suchen, `GridMap` auswaehlen und einmal sichtbar kompilieren.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_489_map_builder_workbench_editor_entry.gd`, TASK_488-Regression, `godot_console.exe --headless --path . --import` und `git diff --check`.
- Naechster Schritt: Sichttest der linken Icon-Leiste gegen den echten Godot-Editor-Workflow, danach erst weitere Palette-/Placement-Politur.

### TASK_488 - Map Builder Workbench MeshLibrary MVP
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_488_map_builder_workbench_meshlibrary_mvp.md`, `docs/dev/map_builder_tooling_spike_contract.md`, `docs/dev/map_editor_asset_workflow_contract.md`
- Stand: `scenes/editor/map_builder_workbench.tscn` ist als kleiner Godot-Builder-Arbeitsplatz angelegt: GridMap/MeshLibrary fuer 15 Kernitems und ein `AssetPlacerProps`-Root fuer freie Gebaeude-/Fahrzeug-/Technik-Props.
- Stand: `data/map_builder_workbench_manifest.json` bindet Boden, Strassen, Wasser, Modular-Walls/Tueren und Space-Station-Teile an bestehende `TerrainTileCatalog`-Type-IDs und reale GLB/GLTF-Assets.
- Stand: `MapBuilderSceneImporter` kompiliert GridMap-Zellen und Asset-Placer-kompatible Nodes in einem Lauf nach `TerrainMapData`; Road-/Water-Surfaces bleiben beim Layern mit Props erhalten, GridMap-Yaw wird als Rotation uebernommen.
- Risiken/offen: Die Workbench braucht noch den sichtbaren Godot-Editor-Test mit GridMap-Palette und Asset-Placer-Dock; eine dauerhaft gespeicherte Team-`MeshLibrary.tres` und echte Door-/Computer-Interactions bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_488_map_builder_workbench_meshlibrary_mvp.gd`, CLI-Compile-Runner mit `--output=user://task_488_cli_workbench_output.json`, TASK_486-/TASK_487-Regressionen, `godot_console.exe --headless --path . --import` und `git diff --check`.
- Naechster Schritt: In Godot `res://scenes/editor/map_builder_workbench.tscn` oeffnen, 10-20 Tiles/Props setzen, dann per Compile-Runner nach Mission-JSON speichern.

### TASK_487 - Install Godot Asset Placer
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_487_install_godot_asset_placer.md`, `docs/dev/map_builder_tooling_spike_contract.md`, `docs/dev/map_editor_asset_workflow_contract.md`
- Stand: Godot Asset Placer 1.4.0 ist als Editor-Plugin unter `addons/asset_placer` installiert, mit MIT-Lizenz im Addon und aktivem `project.godot`-Eintrag.
- Stand: Eine lokale headless EditorDock-Kompatibilitaetsbremse verhindert den Godot-4.6.2-Crash bei Asset-Placer-Dock-/Panel-Aufbau in `--headless --import`; sichtbare Editor-Sessions behalten den `EditorDock`-Pfad.
- Stand: Die Installation bleibt Authoring-Tooling fuer den naechsten Godot-Editor-Sichttest; Asset-Placer-Collections, Docks und `user://asset_library.json` sind keine Gameplay-Wahrheit.
- Risiken/offen: Der manuelle Editor-Test steht noch aus: Godot starten, Asset-Placer-Dock oeffnen, Asset-Folder synchronisieren, eine kleine 3D-Authoring-Szene bauen und per TASK_486-Importer kompilieren.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_487_install_godot_asset_placer.gd`, TASK_486-Regression, `godot_console.exe --headless --path . --import` und `git diff --check`.
- Naechster Schritt: In Godot das Dock `Asset Placer` pruefen und einen kleinen Test mit 5-10 Kernassets gegen den Map-Builder-Importer fahren.

### TASK_486 - Map Builder Tooling Spike
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_486_map_builder_tooling_spike.md`, `docs/dev/map_builder_tooling_spike_contract.md`, `docs/dev/map_editor_asset_workflow_contract.md`
- Stand: Der Spike empfiehlt GridMap/MeshLibrary fuer modulare Terrain-/Road-/Wall-Teile, einen Asset-Placer-artigen Godot-Workflow fuer Props und unseren eigenen Importer als Gameplay-Compiler nach `TerrainMapData`.
- Stand: `MapBuilderSceneImporter` kann Dictionary-Placements, Node-Metadaten und Godot-`GridMap`-Zellen in bestehende Tile-Wahrheit uebersetzen. Road-/Water-Surfaces bleiben beim Layern mit Gebaeuden erhalten; Rotation und Scale werden aus Authoring-Daten normalisiert.
- Risiken/offen: Es wurde bewusst kein externes Plugin vendored. Der echte Godot-Editor-Sichttest mit GridMap/MeshLibrary und Godot Asset Placer bleibt der naechste Entscheidungspunkt.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_486_map_builder_tooling_spike.gd`, TASK_485/TASK_484/TASK_483 und `git diff --check`.
- Naechster Schritt: Kleines Godot-Editor-Projektsetup bauen: MeshLibrary aus 10-15 Kernassets, Godot Asset Placer testweise installieren, dann eine Testkarte per Importer kompilieren.

### TASK_485 - Map Editor Save As and Modular Scale Fix
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_485_map_editor_saveas_modular_scale_fix.md`, `docs/dev/map_editor_asset_workflow_contract.md`
- Stand: Der Map-Editor-`Save As`-Dialog ist wieder ein JSON-Save-Dialog im Projektressourcenbereich und startet bei `res://maps`, statt als Userdaten-Directory-Dialog auf einem fremden Pfad zu landen.
- Stand: Projekt-absolute Save-As-Pfade werden intern zu `res://...` normalisiert; Pfade ohne `.json` bekommen die Endung.
- Stand: Die Kenney-Modular-Space-Kit-Modelle nutzen im 3D-Asset-Mapping `0.25`, damit ein 4er-Quellmodul einer 3D-Zelle entspricht und Modular Wall/Gate/Corner nicht mehr uebergross auf der Karte stehen.
- Stand: Space-Kit-Strassenplatten sind Terrain-/Surface-Varianten mit `surface_type = road`, liegen mit der Oberkante auf Bodenhoehe und bewahren vorhandene Objekt-Layer; `nature_ground_dirt_river_tile` ist als Wasser-/Flussplatte mit `surface_type = water` fuer Hafen-/Kai-Authoring nutzbar.
- Risiken/offen: Der Branch baut auf dem noch nicht integrierten TASK_484/TASK_483-Arbeitsstand auf. Finaler Sichtcheck der Modular-, Strassen- und Wasser-Assets im Editor bleibt offen; spezielle Dock-/Kai-Walkability bleibt Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_485_map_editor_saveas_modular_scale_fix.gd`, TASK_484, TASK_483 und `git diff --check`.
- Naechster Schritt: Manuell im Editor `Save As` oeffnen und Modular Wall/Gate/Floor sowie Strassen-/Wasserplatten gegen eine kleine Testplatte pruefen.

### TASK_484 - Map Editor Palette Browser Layout
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_484_map_editor_palette_browser_layout.md`, `docs/dev/map_editor_asset_workflow_contract.md`
- Stand: Der sichtbare Palette-Browser aus dem Editor-Screenshot ist korrigiert: Kategorien sind in einem kompakten Scrollbereich, die Asset-Liste bekommt mehr Platz und nutzt groessere 72px-Previews.
- Stand: Die Asset-Liste nutzt einen zweispaltigen Icon-Browser mit Top-Icons; der alte `PaletteGroups/PaletteGroup_*`-Pfad bleibt fuer bestehende Verifier als versteckter Kompatibilitaetspfad erhalten.
- Stand: Sichtbare Asset-Eintraege laden jetzt echte Katalog-Preview-Texturen statt generierter Platzhalter-Quadrate, damit Factory-/Fahrzeug-/Kit-Assets erkennbar sind.
- Risiken/offen: Der Branch baut auf dem noch nicht integrierten TASK_483-Arbeitsstand auf. Floor-/Asset-Hoehenalignment bleibt separater Follow-up.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_484_map_editor_palette_browser_layout.gd`, TASK_483, TASK_296, Asset-Rotation-Bugfix, TASK_132, TASK_258, TASK_295 und `git diff --check`.
- Naechster Schritt: Floor-/Asset-Hoehenalignment als separaten Follow-up wieder aufnehmen.

### TASK_483 - Map Editor Asset Workflow Polish
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_483_map_editor_asset_workflow_polish.md`, `docs/dev/map_editor_asset_workflow_contract.md`, `docs/dev/map_editor_module_split.md`, `docs/dev/terrain_truth_visual_audit_contract.md`
- Stand: Der Asset-Authoring-Hotspot hat jetzt groessere Palette-Vorschauen, sortierte Gruppenansicht, Selected-Asset-Preview, Platzierungs-Scale und per-Tile-`object_scale`.
- Stand: `object_scale` wird in `TerrainTileData`, Save/Load, Undo, Snapshots, Terrain-Truth-Audit sowie 2D-/3D-Visuals gefuehrt; Mapping-Scale und Tile-Scale bleiben getrennt.
- Stand: Wand-/Cliff-Ziehen, Auto-Snapping, Door-Open-Logik und Preset-Speicher bleiben bewusst Folgearbeit, damit keine UI-Sonderwahrheit entsteht.
- Risiken/offen: Der Branch baut auf den noch nicht integrierten TASK_481/TASK_482-Arbeitsstaenden auf.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_483_map_editor_asset_workflow_polish.gd`, TASK_295, TASK_296, `bugfix_map_editor_asset_rotation_context_menu.gd`, TASK_298 und `git diff --check`.
- Naechster Schritt: TASK_484 als Wand-/Cliff-Ziehwerkzeug mit Auto-Rotation/Snapping und klarer Segment-Preview schneiden.

### TASK_482 - Mission Briefing Data Contract
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_482_mission_briefing_data_contract.md`, `docs/dev/mission_briefing_contract.md`, `docs/dev/loadout_playability_rules.md`
- Stand: `MissionScenarioData` speichert und normalisiert ein `briefing`-Payload fuer Pre-Mission-Lagebild, Hintergrundbild, terrain-only Minimap-Modus, Ziele, Bedrohungen, Empfehlungen und vorbereitete Annotationen.
- Stand: Briefing-Loadout-Empfehlungen nutzen kanonische `WeaponData`-IDs; visuelle Loadout-IDs werden nicht als Gameplay-Waffen uebernommen und Empfehlungen mutieren keine Loadouts.
- Stand: Der Map Editor hat schlanke Authoring-API-Haken, damit der naechste UI-Task Bildauswahl und Briefing-Felder ohne neuen Save/Load-Pfad anbinden kann.
- Stand: Leere optionale Air-Risk-Threat-Zone-Felder werden beim Serialisieren ausgelassen, damit alte Guards weiter zwischen Player-LZ und Bedrohungsmarker unterscheiden koennen.
- Risiken/offen: Sichtbares Briefing-Panel, Bildauswahl, Minimap-Rendering und Painting bleiben Folgearbeit.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_482_mission_briefing_data_contract.gd`, relevante Mission-Scenario-Regressionen und `git diff --check`.
- Naechster Schritt: TASK_483 als Map-Editor-Briefing-Panel mit Hintergrundbild-Auswahl und erster terrain-only Minimap-Vorschau schneiden.

### TASK_481 - Loadout Heavy Weapon Selection
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_481_loadout_heavy_weapon_selection.md`, `docs/dev/loadout_playability_rules.md`
- Stand: Homebase- und FOB-Loadouts behalten das erweiterte Weapon-Set mit `sniper`, `rocket_launcher`, `rail_gun`, `medictool`, `rifle`, `smg` und `none` dort, wo der Contract es erlaubt.
- Stand: `WeaponData` schaerft Sniper als laengere Praezisionswaffe und Rocket Launcher als schweren Anti-Armor-Pick; `LoadoutModifierResolver` spiegelt die Gewichte/Tempoauswirkungen.
- Stand: FOB-Weapon-Previews lesen den Preview-Pfad jetzt aus `WeaponData`, statt Sniper/Rocket erneut im FOB-Skript zu duplizieren. Die vorhandenen Sniper-/Rocket-Preview-Texturen und GLB-Visual-Loadouts sind per Verifier abgesichert.
- Risiken/offen: Der finale optische Sitz/Groesseneindruck von Sniper/Rocket an den 2.5D-Unit-Proxies braucht weiter einen manuellen Sichtcheck.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_481_loadout_heavy_weapon_selection.gd`, TASK_176/TASK_353/TASK_175, `scripts/tests/test_weapon_data.gd` und `git diff --check`.
- Naechster Schritt: Im naechsten Vertical-Slice-Playtest pruefen, ob Sniper/Rocket-Auswahl im Loadout spuerbar genug ist und ob das Rocket-Visual fuer AA-/Outpost-Ziele gross genug wirkt.

### TASK_480 - Mission UI Hotpath Feedback Guard
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_480_mission_ui_hotpath_feedback_guard.md`, `docs/tasks/TASK_399_dropship_flow_contract_performance_pass.md`, `docs/dev/loadout_playability_rules.md`
- Stand: Parallel-Dropship-Bewegungsframes aktualisieren Welt-Overlay und Dropship-Panel leichtgewichtig, statt bei jedem Frame Planning-Emit und vollen `_update_ui()` zu erzwingen.
- Stand: Event-Log-Panel-Refresh und die uebrigen Runtime-HUD-Surfaces sind getrennt. Ein fehlendes optionales Event-Log blockiert Selected Cards, Mini Cards, World Overlays oder Dynamic Buttons nicht mehr.
- Stand: Fireteam-Mini-Cards behalten den konfigurierten Lead-Summary-Text und zeigen darunter weiter Live-Status. Die Loadout-Doku nennt `rail_gun` wieder als selektierbare kanonische Weapon-ID.
- Risiken/offen: Die verbleibenden Mission-UI-SceneTree-Helper bleiben Folgearbeit fuer einen Cache-/Registry-Slice.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_399_dropship_flow_contract_performance_pass.gd`, `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_fireteam_fob_payload_and_bubbles.gd`, TASK_479-Regression und `git diff --check`.
- Naechster Schritt: Mission-F6/Playtest mit zwei Dropships und sichtbarer Mini-Card pruefen. Erwartet: kein UI-Flackern durch parallel laufende Dropships, Lead bleibt auf der Fireteamkarte lesbar.

### TASK_479 - Fireteam Runtime Hotpath Guards
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_479_fireteam_runtime_hotpath_guards.md`, `docs/tasks/TASK_470_fireteam_combatloop_unit_bridge_recovery.md`, `docs/tasks/TASK_478_fireteam_soft_completion_final_stage_guard.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Der `MissionCombatLoopDriver` trennt aktive registrierte Runtime-Units jetzt von kampffaehigen Combat-Kandidaten und cached diese Listen ticklokal fuer Contact-/Fire-/Overwatch-Hotpaths.
- Stand: Presence- und Hotpath-Audits melden aktive, inaktive und kampffaehige Unit-IDs sowie Pair-/LOS-Zaehler, damit Drop-/Staging-Filter, Down-/Respawn-Zustaende und Scan-Kosten sichtbar werden.
- Stand: Die Review-Idee wird bewusst ohne neue per-Unit-KI, ohne Unit-`Area2D`-Scanner und ohne NavigationServer-/NavigationAgent-Umbau umgesetzt.
- Risiken/offen: Das ist noch keine finale Spatial-Bucket-Zielsuche. Wenn spaeter sehr viele aktive Units laufen, sollte ein separater Bucket-/Budget-Task auf diesen Audits aufsetzen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_479_fireteam_runtime_hotpath_guards.gd`, relevante TASK_470/TASK_473/TASK_477/TASK_478-Regressionen und `git diff --check`.
- Naechster Schritt: F6-Drill erneut mit aktiven/down/respawnenden Einheiten beobachten. Erwartet: Combat-Loop schiesst nur mit/auf fitte registrierte Kandidaten, waehrend Respawn-/Bleedout-Logik Down-Units weiter kennt.

### TASK_478 - Fireteam Soft Completion Final Stage Guard
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_478_fireteam_soft_completion_final_stage_guard.md`, `docs/tasks/TASK_462_fireteam_auto_defend_completion_release.md`, `docs/tasks/TASK_463_fireteam_auto_defend_guard_enemy_model_visibility.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Die weiche Movement-Zielslot-Completion prueft jetzt zusaetzlich, ob der aktuelle Movement-Anchor bereits am finalen Wegpunktziel liegt. Zwischen-Bounds, Take-/Engage-Vorrueckpositionen und Cover-/Stage-Ziele koennen dadurch nicht mehr den ganzen Waypoint abschliessen.
- Stand: Auto-`DEF 360` bleibt nach echtem letztem Zielabschluss aktiv, wird aber nicht mehr durch soft-reached Zwischenziele ausgeloest.
- Risiken/offen: Wenn der finale Stage selbst schlecht gesetzt ist, kann der Auftrag weiterhin nach finaler Zielnaehe korrekt abschliessen. Das bleibt ein Zielslot-/Formationsthema.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_478_fireteam_soft_completion_final_stage_guard.gd`, relevante TASK_462/TASK_463/TASK_477-Regressionen und `git diff --check`.
- Naechster Schritt: F6-Drill mit `Take`/`Engage` in C/N erneut testen. Erwartet: Zwischenhalt/Buddy-Bound bleibt im aktiven Befehl, Auto-DEF erst nach finalem Zielabschluss.

### TASK_477 - Fireteam Contact Cover Decision V1
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_477_fireteam_contact_cover_decision_v1.md`, `docs/tasks/TASK_467_fireteam_engage_contact_halt_fire.md`, `docs/tasks/TASK_476_fireteam_corridor_lane_cover_navigation.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Engage-Contact-Halt entscheidet jetzt pro Mitglied zwischen `take_cover` und `fire_now`. C/N/A steuert Suchradius, noetigen Deckungsgewinn und wie stark Feuer jetzt gegen Deckung gewinnt.
- Stand: Cover-Move-Commands bleiben im bestehenden Fireteam-/SimulationRoot-Pfad: `move_to_position`, `source_command_type = engage`, `fire_at_will`, Aim-Posture und die TASK_476-Navigation-Metadaten.
- Stand: Der Movement-Snapshot meldet `contact_cover_decision_active`, Modus, Assignment-/Fire-Now-Zaehler und per-Unit-Diagnose.
- Risiken/offen: V1 validiert die neue Deckungsposition noch nicht erneut gegen LOS/Waffenwirkung. Das ist der naechste sinnvolle Feinschnitt, sobald der Playtest zeigt, ob die Auswahl lesbar genug ist.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_477_fireteam_contact_cover_decision_v1.gd`, TASK_476/TASK_467-Regressionen und `git diff --check`.
- Naechster Schritt: F6-Drill mit Engage C/N/A gegen Gegnergruppe testen: C sollte sichtbarer Deckung nehmen, A eher wirken, #18/#17 sollten die Entscheidung nachvollziehbar zeigen.

### TASK_476 - Fireteam Corridor Lane Cover Navigation
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_476_fireteam_corridor_lane_cover_navigation.md`, `docs/tasks/TASK_475_fireteam_pathfinding_avoidance_stability_pass.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Fireteam Move/Engage/Take/Defend-Movement-Commands tragen jetzt Korridor-, Lane-, Cover-/Exposure- und Blocker-Clearance-Metadaten. Der Movement-Snapshot meldet die per Unit erzeugte Navigation-Diagnose.
- Stand: `SimulationRoot` normalisiert die Command-Felder in Grid-Optionen fuer den bestehenden Terrain-/HPA-Pathfinder.
- Stand: `TerrainPathfinder` bewertet Korridor-Abweichung, Buddy-Lane-Abweichung und blocker-nahe Schritte zusaetzlich zu Surface-/Cover-/Exposure-Kosten.
- Risiken/offen: Noch keine finale Bottleneck-Reservierung und keine Enemy-Gefahrenkarte ohne Kontaktkontext. Bei echten Engstellen braucht es spaeter vermutlich eine Zeit-/Reservierungslogik.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_476_fireteam_corridor_lane_cover_navigation.gd`, TASK_475/TASK_460/TASK_461-Regressionen und TASK_129 Cover-aware-Navigation.
- Naechster Schritt: F6-Drill gegen Move/Engage/Take beobachten: weniger Gaensemarsch auf dem Weg, weniger blocker-nahe Klemmer, weiterhin brauchbare Deckungsnaehe bei C/N.

### TASK_475 - Fireteam Pathfinding Avoidance Stability Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_475_fireteam_pathfinding_avoidance_stability_pass.md`, `docs/tasks/TASK_460_fireteam_movement_avoidance_stability.md`, `docs/tasks/TASK_461_fireteam_engage_visual_stuck_hotfix.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: `FireteamMovementController` prueft walkable-normalisierte Movement-Zielslots jetzt gegen bereits vergebene Zielslots. Wenn mehrere Mitglieder auf dieselbe Grid-Zelle oder zu dicht fallen, werden nahe, walkable Ersatzslots links/rechts der Marschachse gesucht.
- Stand: Die reparierten Zielslots sind die einzige Grundlage fuer UnitCommands und Completion-State. Der Movement-Snapshot meldet Reparaturzaehler, Konflikte, unresolved Slots, Mindestabstand und kurze Slot-Diagnosen.
- Stand: `SimulationRoot` konsumiert `local_avoidance_repath_requested` jetzt als Repath-Signal. Ein Avoidance-Deadlock kann dadurch einen alten Terrain-Pfad verwerfen, statt denselben Pfad weiter abzulaufen.
- Risiken/offen: Dieser Pass ist noch keine Deckungssuche und keine finale Bottleneck-Reservierung. Echte Engstellen koennen spaeter weitere Reservierungs-/Sequenzlogik brauchen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_475_fireteam_pathfinding_avoidance_stability_pass.gd`, relevante TASK_460/TASK_461-Regressionen und `git diff --check`.
- Naechster Schritt: F6-Drill erneut mit `Move -> Engage/Take` beobachten. Erwartet: weniger Zielslot-Kollaps/Gaensemarsch am Ziel, klarere Diagnose bei Slot-Reparatur oder weiterem Haenger.

### TASK_474 - Fireteam Down VFX Performance Stabilization
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_474_fireteam_down_vfx_performance_stabilization.md`, `docs/tasks/TASK_473_fireteam_combat_feedback_runtime_overhaul.md`, `docs/tasks/TASK_471_fireteam_weapon_fire_vfx_hit_feedback_perf.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Der CombatLoop haelt frisch gedownte Units jetzt fuer ein kurzes Mindestfenster sichtbar im Down-Zustand, bevor Bleedout/Respawn enqueued wird. Damit kippt ein Treffer nicht mehr im naechsten Tick unsichtbar direkt in Respawn weiter.
- Stand: `respawning` bleibt optisch liegend: 2D-TestUnits und 3D-Proxies richten sich erst beim echten Respawn-Effekt wieder auf.
- Stand: Weapon-Fire-VFX bleibt gecappt, hat aber neben der kurzen Muzzle-Line jetzt einen kleinen hellen Flare-Cross am Waffenpunkt, damit Schuesse im Drillfenster lesbarer sind.
- Stand: Combat-Visual-Refreshes werden gedrosselt und gepuffert; dynamische Fire-/Bubble-/Communication-Signaturen werden nur noch gecappt ausgewertet, statt jedes Mal komplette Payloads zu serialisieren.
- Risiken/offen: Die Performance sollte im F6-Fenster deutlich ruhiger sein, muss aber noch manuell mit echtem Feuerkontakt beobachtet werden. Die finale Death-/Ragdoll-/Medic-Logik bleibt ein eigener Gameplay-Pass.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_474_fireteam_down_vfx_performance_stabilization.gd`, relevante TASK_471/TASK_472/TASK_473-Regressionen und `git diff --check`.
- Naechster Schritt: F6-Drill erneut mit `Move -> Engage` testen. Erwartet: sichtbarer kleiner Muzzle-Impuls, Treffer lassen Units kurz liegen, Respawn bleibt liegend mit Countdown und #18/Visuals triggern nicht mehr bei jedem Schuss mehrere Voll-Rebuilds.

### TASK_473 - Fireteam Combat Feedback Runtime Overhaul
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_473_fireteam_combat_feedback_runtime_overhaul.md`, `docs/tasks/TASK_472_fireteam_contact_perf_bubble_card_readability.md`, `docs/tasks/TASK_471_fireteam_weapon_fire_vfx_hit_feedback_perf.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: `SimulationRoot` normalisiert Cover-Werte jetzt vor der Trefferrechnung und meldet zu jedem Damage-Effekt ein autoritatives `damage_effect_resolved`-Outcome mit Hit/Miss, Trefferchance, Roll, Schaden, Cover-Ratio, Ziel-HP und Vital-State.
- Stand: `MissionCombatLoopDriver` verbindet Fire-Events mit diesem Outcome, sodass #18/Visuals nicht mehr nur melden, dass geschossen wurde, sondern ob der Schuss traf, verfehlte oder Schaden erzeugte.
- Stand: Suppression ist in leichte Hemmung und schweren Pinned-Zustand getrennt. Leichte Suppression bremst und verschlechtert Aim/Angriff, bricht aber nicht mehr sofort GO/Engage ab; nur schwere Suppression blockt Recovery wie ein echter Unterbrechungszustand.
- Stand: #16 zeigt Ad-Hoc-/Recovery-Kommandos nur noch bei echtem Recovery-Kontext statt bei jedem Kampfkontakt. #17 bekommt laengere, aber gleich breite Member-Karten und lesbarere Statuszeilen fuer Befehl, Bewegung, Sicherung, Flank und Lead.
- Stand: Weapon-Fire-VFX ist weiter gecappt, nutzt kurze gelbe Muzzle-Impulse und zusaetzlich kleine Impact-Marker am Ziel, damit der sichtbare Schuss nicht wie eine riesige gelbe Wand wirkt.
- Risiken/offen: Treffer-/Suppression-Werte bleiben Prototype-Balancing. Der F6-Drill muss visuell gegen echte Frames geprueft werden: Gegner sollten HP/Down zeigen, #16 darf nicht flackern und #17 darf trotz Mehrtext nicht in Ein-Buchstaben-Zeilen fallen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_473_fireteam_combat_feedback_runtime_overhaul.gd`, relevante TASK_471/TASK_472-Regressionen und `git diff --check`.
- Naechster Schritt: F6-Drill mit `Move -> Engage` testen. Erwartet: Fire-Events erzeugen sichtbare Hit/Miss-/Damage-Outcomes, leichte Suppression haelt die Teams nicht im alten Recovery-Flicker fest und schwere Suppression ist klar als `PINNED` erkennbar.

### TASK_472 - Fireteam Contact Performance Bubble Card Readability
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_472_fireteam_contact_perf_bubble_card_readability.md`, `docs/tasks/TASK_471_fireteam_weapon_fire_vfx_hit_feedback_perf.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Der dynamische 3D-Order-Refresh raeumt jetzt auch HUD-Sprechblasen ab, bevor die aktive Bubble neu aufgebaut wird. Dadurch bleibt oben links nur eine Leader-Bubble statt eines Stapels alter Befehlsblasen.
- Stand: Kontakt-/Fire-Visuals sind im Drill guenstiger: weniger gleichzeitige Weapon-Fire-VFX, weniger Map-Communication-Marker und ein langsamerer dynamischer Visual-Refresh. Der Muzzle-Flash ist weiter klein, aber mit gelbem Tip/Bloom sichtbarer.
- Stand: Flank-Vulnerability ist fuer die aktuelle Baseline per Default deaktiviert. Engage/Defend-Feuer wird damit nicht mehr durch unfertige Flanking-Ansagen oder Flank-Mali/-Boni ueberlagert.
- Stand: Die #17-Unit-Karten bleiben 156px breit, werden fuer Missionsmitglieder aber nach unten laenger und wrappen Laufzeit-, Kontakt- und Posture-Text ueber mehrere kurze Zeilen.
- Risiken/offen: Flanking muss spaeter als eigener expliziter Behavior-Pass wieder aktiviert und getestet werden. Die Performance-Bremse reduziert Debug-Dichte; falls spaeter mehr Trefferfeedback noetig ist, sollte es gezielt und gecappt dazu.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_472_fireteam_contact_perf_bubble_card_readability.gd`, relevante TASK_471/TASK_435-Regressionen und `git diff --check`.
- Naechster Schritt: F6-Drill im Kontakt erneut ansehen. Erwartet: deutlich weniger Bubble-/Marker-Stapel, keine automatische `Flanking!`-Ansage, #17 zeigt erklaerenden Umbruchtext.

### TASK_471 - Fireteam Weapon Fire VFX Hit Feedback Perf
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_471_fireteam_weapon_fire_vfx_hit_feedback_perf.md`, `docs/tasks/TASK_470_fireteam_combatloop_unit_bridge_recovery.md`, `docs/tasks/TASK_466_fireteam_live_defend_contact_fire_damage.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Weapon-Fire-VFX nutzt im 3D-View jetzt eine kleine gelbe, gerichtete Muzzle-Impulse-Line plus kleinen Bloom. Die grosse Texture-Card wird im Debug-/Drill-Pfad bewusst unterdrueckt, damit kein gelber Wand-Flash entsteht.
- Stand: Der 3D-View rendert nur noch die neuesten Weapon-Fire-Events bis zu einem festen Limit. Das verhindert, dass lange Feuerwechsel unbounded alte Flash-/Trace-Geometrie aufbauen.
- Stand: Unit-Proxies melden HP, letzten Damage-Kontext, Damage-Visual-Status und Down-Pose im Render-Snapshot. Fit-Units mit Schaden zeigen eine HP-Badge, Down-/Bleedout-Units kippen im Proxy sichtbar in einen Down-Zustand.
- Risiken/offen: Das ist eine lesbare Debug-/Prototype-Loesung, keine finale Muzzle-Particle- oder Death-Animation. Ob Gegner schnell genug sterben, bleibt Combat-Balancing; die Sichtbarkeit von Treffer/HP/Down ist jetzt separat pruefbar.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_471_fireteam_weapon_fire_vfx_hit_feedback_perf.gd`, relevante TASK_432/TASK_435/TASK_436/TASK_438/TASK_461/TASK_466/TASK_470-Regressionen und `git diff --check`.
- Naechster Schritt: F6-Drill erneut mit `Move -> Engage` testen. Erwartet: kleiner gelber Muzzle-Impuls statt grosser Flaeche, rote Trace bleibt lesbar, Gegner zeigen HP/Down statt nur `IDLE`.

### TASK_470 - Fireteam CombatLoop Unit Bridge Recovery
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_470_fireteam_combatloop_unit_bridge_recovery.md`, `docs/tasks/TASK_469_fireteam_f6_drill_combat_config.md`, `docs/tasks/TASK_468_fireteam_engage_live_command_conflict_audit.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Der CombatLoop nutzt konfigurierte NodePaths weiterhin zuerst, faellt bei leeren Listen aber auf die `UnitRegistry` zurueck. Damit darf #18 im F6-Drill nicht mehr `F0/E0` melden, wenn registrierte Friendlies/Enemies sichtbar aktiv sind.
- Stand: Fruehe Startup-Defeats werden verhindert, solange der Loop noch nie aktive Friendlies gesehen hat. Ein bereits gesetzter Startup-Defeat kann recovern, sobald aktive Friendlies registriert sind.
- Stand: Contact-Diagnosen werden beim Lesen mit aktuellen Presence-Daten aufgefrischt, und Overwatch-Fire schreibt ebenfalls eine `fired`-Diagnose fuer #18.
- Stand: Die Fireteam-Command-Drill-Scene enthaelt jetzt vier explizite Enemy-Nodes und vier CombatLoop-Enemy-Pfade. Der F6-Start haengt dadurch nicht mehr davon ab, dass das Scenario spaeter zwei Gegner dupliziert.
- Risiken/offen: Wenn danach weiter kein Feuer sichtbar ist, ist der naechste Diagnosepunkt jetzt LOS/Range/Detection/FireStatus/Damage-VFX, nicht mehr Unit-Presence.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_470_fireteam_combatloop_unit_bridge_recovery.gd`, relevante TASK_469/TASK_468/TASK_467/TASK_466-Regressionen und `git diff --check`.
- Naechster Schritt: F6-Drill neu starten, `Move -> Engage` in die rechte Gegnergruppe spielen und #18 pruefen. Erwartet: aktive Counts statt `F0/E0`, danach `CONTACT FIRE` oder konkreter Blockgrund.

### TASK_469 - Fireteam F6 Drill Combat Config
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_469_fireteam_f6_drill_combat_config.md`, `docs/tasks/TASK_468_fireteam_engage_live_command_conflict_audit.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Das Fireteam-Drill-Szenario traegt jetzt eine eigene `win_condition = elimination`. `MissionTestSetup` uebertraegt diesen Wert beim direkten Szenenstart auf den `CombatLoopDriver`, damit geerbtes `objective_capture` den CombatLoop nicht mehr im Behavior-Drill beendet.
- Stand: Der Meta-Missionskatalog setzt fuer `fireteam_command_drill` ebenfalls `elimination`, damit Meta-Start und F6-Start dieselbe Combat-Regel benutzen.
- Stand: Ein neuer TASK_469-Verifier prueft den Szenario-Import, den direkten F6-Drill-Start und die Basisszene mit injiziertem Drill-Szenario auf aktive Friendlies/Enemies im CombatLoop.
- Risiken/offen: Dieser Slice repariert die F6-Combat-Konfiguration und den F0/E0-Pfad. Falls danach weiter kein Feuer entsteht, muss #18 konkret LOS/Range/Detection/FireStatus ausweisen statt leerer Unit-Counts.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_469_fireteam_f6_drill_combat_config.gd`, relevante TASK_468/TASK_467/TASK_466-Regressionen und `git diff --check`.
- Naechster Schritt: Godot-Szene neu starten, dann im Drill `Move -> Engage` gegen die rechte Gegnergruppe testen. Erwartet: #18 zeigt aktive Counts und bei LOS/Reichweite `CONTACT FIRE` oder einen konkreten Blockgrund.

### TASK_468 - Fireteam Engage Live Command Conflict Audit
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_468_fireteam_engage_live_command_conflict_audit.md`, `docs/tasks/TASK_467_fireteam_engage_contact_halt_fire.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Der Engage-Contact-Halt nutzt jetzt einen eigenen `contact_halt`-Command-Token. Alte requeueende Stage-Move-/Engage-Commands koennen den Halt dadurch nicht mehr als gueltigen alten Token erkennen und den Unit-Command wieder ueberschreiben.
- Stand: Die Fireteam-Command-Drill-Map ueberschreibt die geerbte Objective-Capture-Wincondition auf `elimination`. Damit beendet ein Objective-Defeat den Combat-Loop nicht mehr waehrend des Behavior-Playtests; Kontakttracking, Fire-Decision, Damage und Muzzle-/Fire-Events bleiben aktiv.
- Stand: Der rote Contact-Marker in der 3D-View ist jetzt ein flacher Bodenmarker statt eines hohen Zylinders ueber der Unit. Gegner-Modelle werden dadurch nicht mehr vom roten Marker verdeckt.
- Stand: Ein neuer TASK_468-Verifier prueft den Live-Pfad auf zwei Dinge: stale Stage-Requeue darf Contact-Halt nicht ueberschreiben, und ein echter Engage-Drill-Tick kann ohne manuelles `_try_enqueue_attacks()` ein Fire-Event erzeugen.
- Risiken/offen: Gegner-Proxy-Lesbarkeit und finale Cover-/Area-Taktik bleiben eigene Follow-ups. Dieser Slice repariert den Befehlskampf und den toten Combat-Loop in der Drill-Map.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_468_fireteam_engage_live_command_conflict_audit.gd`, relevante TASK_467/TASK_466/TASK_465-Regressionen und `git diff --check`.
- Naechster Schritt: Im Drillfenster neu starten und `Move -> Engage N/A in Gegnernaehe` testen. Erwartet: kein Rueckfall durch alte Move-Requeues, kein Objective-Defeat-Stop, Fire-Event/Muzzle bei LOS/Reichweite oder konkrete NO-FIRE-Diagnose.

### TASK_467 - Fireteam Engage Contact Halt Fire
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_467_fireteam_engage_contact_halt_fire.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/tasks/TASK_465_fireteam_engage_resume_contact_progress.md`, `docs/tasks/TASK_466_fireteam_live_defend_contact_fire_damage.md`
- Stand: Aktives `Engage` prueft vor der Waypoint-Completion sichtbare Kontakte auf LOS/Waffenreichweite. Wenn ein Kontakt attackierbar ist, pausiert der MovementController den Marsch und gibt allen Mitgliedern `hold_position` mit `source_command_type = engage`, `fire_at_will`, Overwatch/Aim und den aktuellen Stance-Modifikatoren.
- Stand: `_update_active_phase_execution()` behandelt diesen Zustand als `contact_halt`, setzt den Wegpunkt nicht fertig und loest dadurch nicht sofort Auto-`DEF 360` aus.
- Stand: Der Movement-Snapshot meldet `contact_halt_active`, `contact_halt_unit_ids` und `contact_halt_context`, damit #17/#18 den Haltegrund nachvollziehen koennen.
- Stand: Der TASK_466-Live-Verifier merkt sich den letzten freundlichen `fired`-Snapshot, damit Damage-Apply-Timing nicht faelschlich als `cooldown`-Fehler gewertet wird.
- Risiken/offen: Das ist noch keine finale Cover-Wahl. Die Regel entscheidet aktuell "halt and fire" bei attackierbarem Kontakt; ob ein nahes Cover besser ist als sofortiges Feuer bleibt ein eigener Doctrine-/Cover-Slice.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_467_fireteam_engage_contact_halt_fire.gd`, TASK_465/TASK_466-Regressionen und `git diff --check`.
- Naechster Schritt: Im Drill `Move -> Engage vor Gegner -> Engage in Gegnergruppe` erneut testen. Erwartet ist kein Durchlaufen durch Gegner: bei sichtbarem Kontakt muss #17/#18 Contact-Halt/Feuerstatus zeigen und danach ein Fire-Event/Muzzle-Trace entstehen.

### TASK_466 - Fireteam Live Defend Contact Fire Damage
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_466_fireteam_live_defend_contact_fire_damage.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/tasks/TASK_458_fireteam_contact_decision_diagnostics.md`, `docs/tasks/TASK_464_fireteam_contact_scan_fire_feedback_readability.md`, `docs/tasks/TASK_465_fireteam_engage_resume_contact_progress.md`
- Stand: Der neue Verifier prueft den echten Live-Tick-Pfad ohne forcierte Detection: `DEF 360` und `Engage` erkennen einen nahen Gegner, erzeugen `CONTACT FIRE`, schreiben einen Fire-Event und Damage erreicht das Ziel ueber `SimulationRoot`.
- Stand: Die Mission-Control-Diagnose bleibt in #18 sichtbar. Das card-bound Layout versteckt weiter die grossen alten Action-/Approach-Flaechen, aber nicht mehr `StrategicStatusLabel`, damit `CONTACT FIRE`, `CONTACT WAIT` oder `NO FIRE <Grund>` im Playtest lesbar bleibt.
- Stand: Der Test unterscheidet friendly fire on enemy von gegnerischem Gegenfeuer und akzeptiert Damage erst, wenn ein freundlicher Angreifer den Enemy tatsaechlich getroffen hat.
- Risiken/offen: Treffer/Down-State existiert datenbasiert ueber HP und `vital_state = down`; eine gut sichtbare Umfall-/Hit-Animation ist nicht Teil dieses Slices. Wenn im Fenster weiter keine Schuesse sichtbar sind, ist #18 jetzt der erste Diagnosepunkt fuer `no_los`, `out_of_range`, `cooldown` oder Detection-State.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_466_fireteam_live_defend_contact_fire_damage.gd` plus relevante TASK_458/TASK_464/TASK_465-Regressionen und `git diff --check`.
- Naechster Schritt: Im Drill `Move -> Engage -> Auto DEF` erneut testen und #18 lesen. Erwartet ist entweder sichtbares `CONTACT FIRE` mit Fire-Event/Damage oder ein konkreter `NO FIRE`-Grund.

### TASK_465 - Fireteam Engage Resume Contact Progress
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_465_fireteam_engage_resume_contact_progress.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/tasks/TASK_462_fireteam_auto_defend_completion_release.md`, `docs/tasks/TASK_463_fireteam_auto_defend_guard_enemy_model_visibility.md`, `docs/tasks/TASK_464_fireteam_contact_scan_fire_feedback_readability.md`
- Stand: Aktive Move-/Engage-/Take-/Defend-Movement-Executions zwingen die Security jetzt in ein directional Moving-Security-Bild aus der aktuellen Movement-Richtung. Ein vorheriges Auto-`DEF 360` bleibt damit nicht als sichtbarer 360-Defense-Zustand auf einem neuen Engage-Befehl liegen.
- Stand: #17 zeigt fuer aktive Movement-Security `SEC MOV <Richtung>` statt `SEC DEF 360`; echtes Auto-Defend nach Zielabschluss bleibt weiter `DEF 360`.
- Stand: Der neue Verifier stellt `Auto-DEF -> Engage in Kontakt` nach und prueft aktive Engage-Movement-State-Uebernahme, Bound-Fortschritt und Close-Contact-FireEvent.
- Risiken/offen: Der Slice repariert den Security-/Resume-Uebergang und deckt Close-Contact-Fire ab. Wenn im Fenster weiter nicht geschossen wird, muss die sichtbare Contact-Diagnose konkret nach `no_los`, `out_of_range`, `cooldown` oder Detection-/Contact-State ausgewertet werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_465_fireteam_engage_resume_contact_progress.gd` sowie relevante TASK_462-464-Regressionen und `git diff --check`.
- Naechster Schritt: Im Drill genau den User-Ablauf testen: Move/Engage vor Gegner, Auto-DEF, dann Engage direkt in Gegnergruppe. Erwartet: `SEC MOV <Richtung>`, weiterlaufende Bounds und sichtbares Feuer/Muzzleflash bei LOS/Reichweite.

### TASK_464 - Fireteam Contact Scan Fire Feedback Readability
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_464_fireteam_contact_scan_fire_feedback_readability.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/tasks/TASK_458_fireteam_contact_decision_diagnostics.md`, `docs/tasks/TASK_459_fireteam_engage_orientation_enemy_proxy_fix.md`, `docs/tasks/TASK_463_fireteam_auto_defend_guard_enemy_model_visibility.md`
- Stand: Der Combat-Loop behandelt Canvas-/FOW-Sichtbarkeit nicht mehr als Gameplay-Zielwahrheit. Registrierte, fitte Gegner bleiben aktive Ziele, auch wenn ihre 2D-Canvas-Darstellung lokal unsichtbar ist.
- Stand: Security-Facing mit aktivem Scan gewinnt im 3D-Facing gegen alte statische `facing_angle`/`map_facing_angle`-Metadaten; der Defend-Sweep ist sichtbar breiter.
- Stand: Hostile Team-Bases sind flacher, tiefer und transparenter und werden im Render-Snapshot mit Radius/Hoehe/Alpha/Y dokumentiert.
- Stand: #17 Unit-Karten zeigen ausgeschriebene Runtime-Infos: Command, Feuerstatus, Haltung, Weapon-/Movement-Posture und Aim-Bereitschaft.
- Risiken/offen: Der Slice behebt Zielfilter, Scan-Lesbarkeit und Kartenfeedback. Wenn im Fenster weiter nicht geschossen wird, muss die nun sichtbare Contact-Diagnose konkret nach LOS/Range/Cooldown/Engage-Ready ausgewertet werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_464_fireteam_contact_scan_fire_feedback_readability.gd`, TASK_458/TASK_459/TASK_463 und `git diff --check`.
- Naechster Schritt: Im Drill `Engage A/N/C` zwischen die rechte Gegnergruppe laufen lassen und #17/#18 gegen `Feuer frei`, Aim-Up, rote Fire-Linie und Muzzleflash pruefen.

### TASK_463 - Fireteam Auto Defend Guard And Enemy Model Visibility
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_463_fireteam_auto_defend_guard_enemy_model_visibility.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/tasks/TASK_462_fireteam_auto_defend_completion_release.md`, `docs/tasks/TASK_461_fireteam_engage_visual_stuck_hotfix.md`
- Stand: Die weiche Waypoint-Completion ist jetzt als Guard geschuetzt: aktive Movement-Executions duerfen nur nach einer Mindestlaufzeit ueber aktuelle Zielslots weich abschliessen. Anchor-/Center-Fallbacks greifen nicht mehr waehrend ein MovementController-Auftrag aktiv ist.
- Stand: Auto-`DEF 360` bleibt der Abschlusszustand nach echtem Zielabschluss, richtet Hold-Commands aber sichtbar vom aktuellen Teamzentrum nach aussen aus und bewegt die Units dafuer nicht durch neue Zielslots.
- Stand: Die Drill-Enemy-IDs `enemy_delta`, `enemy_echo`, `enemy_foxtrot` und `enemy_golf` nutzen explizite, groessere Enemy-Animated-Character-Modelle. Der Render-Snapshot meldet die Modellskala pro Proxy.
- Risiken/offen: Der Slice verhindert den zu fruehen Auto-Defend-Rueckfall und verbessert Enemy-Lesbarkeit. Wenn Units danach weiter haengen, bleibt das ein eigener Zielslot-/Pathfinding-/Avoidance-Befund.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_463_fireteam_auto_defend_guard_enemy_model_visibility.gd`, TASK_462/TASK_461/TASK_438 und `git diff --check`.
- Naechster Schritt: Im Drillfenster Move/Engage/Take erneut laufen lassen: Befehl darf nicht nach 0.5s in `DEF 360` kippen; danach Gegnergruppe visuell gegen vier klare Modelle pruefen.

### TASK_462 - Fireteam Auto Defend Completion Release
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_462_fireteam_auto_defend_completion_release.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/tasks/TASK_461_fireteam_engage_visual_stuck_hotfix.md`, `docs/tasks/TASK_422_go_continue_fireteam_hud_cleanup.md`
- Stand: Aktive Fireteam-Wegpunkte nutzen zusaetzlich zum harten MovementController-Finish eine weiche Abschlusspruefung auf die aktuellen Movement-Zielslots. Dadurch kann ein sichtbar erreichtes Ziel freigegeben werden, auch wenn ein Slot minimal ausserhalb des harten Radius klebt.
- Stand: GO-Continue nutzt denselben Abschlussentscheid und kann einen weich erreichten aktiven Auftrag weiterfuehren, statt `ACTIVE` zu melden.
- Stand: Wenn nach einem abgeschlossenen Wegpunkt kein weiterer Waypoint/Area-Auftrag existiert, wird automatisch `DEF 360` angewendet. Die Hold-Commands tragen `source_task_type = auto_defend`, `security_mode = 360` und verteilte Facing-Winkel.
- Risiken/offen: Der Slice ist eine Completion-/Default-Defense-Stabilisierung. Echte Pfad-Engstellen, schlechte Zielslot-Auswahl oder Enemy-Kontaktentscheidungen bleiben eigene Follow-ups.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_462_fireteam_auto_defend_completion_release.gd`, TASK_422/TASK_461 und `git diff --check`.
- Naechster Schritt: Im Drill Move/Engage bis zum letzten Wegpunkt laufen lassen und pruefen, dass das Fireteam danach sichtbar `DEF 360` statt `MOVE/ENGAGE ACTIVE` zeigt.

### TASK_461 - Fireteam Engage Visual Stuck Hotfix
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_461_fireteam_engage_visual_stuck_hotfix.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/tasks/TASK_459_fireteam_engage_orientation_enemy_proxy_fix.md`, `docs/tasks/TASK_460_fireteam_movement_avoidance_stability.md`
- Stand: Fireteam-Movement-Zielslots werden vor dem Enqueue auf walkable Terrain-Ziele normalisiert. Der MovementController nutzt dieselben Zielpositionen fuer Completion, damit ein blockierter Originalslot Engage/Take nicht dauerhaft aktiv haelt.
- Stand: Aim-/Facing-Visuals priorisieren aktiven Kontakt und Bewegungs-/Zielrichtung vor altem Security-Facing. Security bleibt Fallback, wenn keine aktuelle Bewegung, kein Ziel und kein Kontakt anliegt.
- Stand: Hostile Proxies bekommen einen staerkeren Body-Readability-Core mit groesserem Radius und hoeherer Opazitaet, damit Gegner im Drillfenster nicht nur als `IDLE`/Base lesbar sind.
- Stand: Weapon-Fire-VFX erzeugt Bloom und Trace auch dann, wenn die Muzzle-Textur fehlt; fehlende Textur wird im VFX-Snapshot markiert.
- Risiken/offen: Dieser Slice stabilisiert sichtbare Engage-Haenger und Fire-Lesbarkeit, ersetzt aber keine spaetere Engstellen-/Sequenzdiagnose und keine finale Enemy-Art.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_461_fireteam_engage_visual_stuck_hotfix.gd`, TASK_438/TASK_459/TASK_460 und `git diff --check`.
- Naechster Schritt: Im Drill erneut `Engage A/N/C` gegen die rechte Gegnergruppe testen: Gegnerkoerper, rote Fire-/Trace-Linien, Muzzle/Bloom und GO-Fortsetzung nach einem Engage-Haenger pruefen.

### TASK_460 - Fireteam Movement Avoidance Stability
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_460_fireteam_movement_avoidance_stability.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/tasks/TASK_459_fireteam_engage_orientation_enemy_proxy_fix.md`, `docs/tasks/TASK_446_fireteam_workbench_spacing_runtime_pass.md`
- Stand: Fireteam-Move/Engage/Take-Bewegungscommands tragen jetzt command-lokal `local_avoidance_enabled = true` plus eine sichtbare Source-ID. Hold-/Cover-Commands bleiben reine Haltecommands.
- Stand: `SimulationRoot` kann den Local-Avoidance-Resolver fuer command-lokales Opt-in vorbereiten, auch wenn der globale Root-Schalter aus ist. Der Debug-Snapshot markiert `command_local_avoidance_enabled`.
- Stand: Der Avoidance-Pfad erhaelt eine kleine Mindest-Vorwaertsbewegung, damit Ausweichkorrekturen den Zielabschluss nicht dauerhaft verhindern.
- Risiken/offen: Dieser Slice aktiviert und stabilisiert den vorhandenen Avoidance-Pfad, ersetzt aber keine spaetere Terrain-Engstellen-, Zielslot- oder Sequenzdiagnose. Enemy-Patrouille und Body-Rendering bleiben angrenzende Follow-ups.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_460_fireteam_movement_avoidance_stability.gd`, TASK_423/TASK_446 und `git diff --check`.
- Naechster Schritt: Im Drill Move/Engage/Take erneut gegen die rechte Gegnergruppe laufen lassen und pruefen, ob weniger Gaensemarsch/Haenger entstehen; verbleibende Haenger dann nach Terrain-Path, Zielslot oder Sequenz trennen.

### TASK_459 - Fireteam Engage Orientation Enemy Proxy Fix
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_459_fireteam_engage_orientation_enemy_proxy_fix.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/tasks/TASK_458_fireteam_contact_decision_diagnostics.md`, `docs/tasks/TASK_438_fireteam_contact_visibility_attack_visuals.md`
- Stand: Die 3D-View priorisiert bei Aim-/Facing-Berechnung jetzt aktive Fire-Events und bestaetigte/spotted Kontakte vor altem Security-/Move-/Target-Facing. Dadurch soll `SEC DEF 360` einen laufenden Engage-Kontakt visuell nicht mehr nach hinten ueberstimmen.
- Stand: Hostile Unit-Proxies bekommen immer einen sichtbaren `UnitBodyReadabilityCore`, falls der eigentliche Body/Animated-Model-Pfad im Fenster nicht lesbar ist. Damit sollen Gegner nicht nur als `IDLE`/Base-Marker sichtbar sein.
- Risiken/offen: Dieser Slice behebt sichtbare Orientierung und Body-Lesbarkeit. Haenger durch Pathfinding, Zielslot-Auswahl oder Local Avoidance bleiben ein separater Slice, wenn sie nach diesem Test weiter auftreten.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_459_fireteam_engage_orientation_enemy_proxy_fix.gd`, TASK_438/TASK_457/TASK_458 und `git diff --check`.
- Naechster Schritt: Im Drill `Engage A/N/C` gegen die rechte Gegnergruppe pruefen: schauen die Waffen/Koerper zum Kontakt und sind vier Gegnerkoerper sichtbar?

### TASK_458 - Fireteam Contact Decision Diagnostics
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_458_fireteam_contact_decision_diagnostics.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/tasks/TASK_457_fireteam_contact_engage_runtime_pass.md`, `docs/tasks/TASK_438_fireteam_contact_visibility_attack_visuals.md`, `docs/tasks/TASK_440_enemy_limbo_contact_diagnostics.md`
- Stand: Der Mission-Combat-Loop exportiert einen read-only Kontakt-/Fire-Decision-Diagnosesnapshot mit Reason, Status, Angreifer, Ziel, Waffe, Kontaktstatus, LOS, Range, Cooldown, Fire-Event und aktiven Friendly-/Enemy-Zaehlern.
- Stand: `no_contact_pair`, `cooldown`, `no_damage_effect`, `invalid_contact_pair` und `fired` werden als letzte Combat-Entscheidung sichtbar. Fuer `no_contact_pair` wird ein erster Kandidat mit Blockgrund wie `attacker_not_engage_ready`, `no_los` oder `out_of_range` mitgeliefert.
- Stand: Mission Control (#18) und der Command-Feedback-Snapshot lesen diese Diagnose kompakt als Text, ohne Gameplay-State in der UI zu mutieren.
- Risiken/offen: Die Diagnose erklaert die Entscheidung, repariert aber nicht automatisch Pathing, LOS-Geometrie oder KI-Verhalten. Ein angezeigtes `no_los`/`out_of_range` muss bei Bedarf als separater Runtime-Slice geloest werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_458_fireteam_contact_decision_diagnostics.gd`, TASK_457/TASK_438/TASK_440 und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster Engage/Take gegen Gegner laufen lassen und #18/Feedback gezielt nach `CONTACT FIRE`, `CONTACT WAIT` oder `NO FIRE <Grund>` lesen.

### TASK_457 - Fireteam Contact Engage Runtime Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_457_fireteam_contact_engage_runtime_pass.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/tasks/TASK_452_fireteam_runtime_baseline_visual_contact_pass.md`, `docs/tasks/TASK_438_fireteam_contact_visibility_attack_visuals.md`
- Stand: `aim_readiness_percent` wirkt jetzt nicht nur im 3D-Posture-Snapshot, sondern auch auf die erste Kontakt-/Zielverzoegerung im Mission-Combat-Loop. Hohe Aim-Bereitschaft verkuerzt die Detection-Zeit, niedrige verlaengert sie.
- Stand: Weapon-Fire-Events bleiben fuer ein kurzes Debug-Fenster im Fire-Event-Snapshot, damit Muzzleflash und rote Schusslinie im manuellen Fenster nicht sofort wieder verschwinden.
- Stand: Ein per GO abgeschlossener Engage-Area-Befehl startet bei vorhandenem pending Waypoint zuerst diesen Wegpunkt, statt sofort die naechste Area/default Area zu aktivieren.
- Stand: Der 3D Unit-Proxy-Snapshot exportiert Aim-Readiness und den sichtbaren Aim-Override, damit #17/#18/Dev-Diagnosen erkennen koennen, warum die Waffe oben ist.
- Risiken/offen: Der Slice ist noch kein finaler Animations-Blend und keine neue Gegner-KI. Wenn Gegner im manuellen Fenster weiter nur teilweise sichtbar sind, muss der naechste Pass den konkreten FOW-/Proxy-/Szenariozustand im Fenster inspizieren.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_457_fireteam_contact_engage_runtime_pass.gd`, TASK_438/TASK_440/TASK_452 und `git diff --check`.
- Naechster Schritt: Manueller Godot-Sichtcheck fuer Engage Area -> Take/Move, vier Gegner, rote Kontaktlinie und Muzzleflash; danach erst weitere Behavior-Feinheiten schneiden.

### TASK_455 - Terrain Truth Editor Overlay Visibility
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_455_terrain_truth_editor_overlay_visibility.md`, `docs/dev/terrain_truth_visual_audit_contract.md`, `docs/tasks/TASK_454_terrain_truth_visual_audit.md`
- Stand: Der Terrain-Truth-Audit ist im bestehenden MapEditor-DBG-Overlay sichtbar: kompakte Labels (`W1`, `WT`, `OBJ H1`, `LOS`, `Cxx`, `Hxx`), gelbe Wandsegment-Kanten und Draw-Node-Metadaten fuer spaetere Dev-Panels.
- Stand: Der Slice bleibt visual-only. Er schaltet Combat-/Mission-LOS nicht auf Segment-LOS um und veraendert keine Fireteam-/Pathfinding-Regeln.
- Risiken/offen: Die kompakte Tile-Beschriftung ersetzt kein vollstaendiges Detailpanel; fuer spaetere Playtests bleibt ein selektierter Tile-Inspector sinnvoll.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_455_terrain_truth_editor_overlay_visibility.gd`, `task_454_terrain_truth_visual_audit.gd`, `task_379_mapeditor_tile_property_grid_overlay.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Im Godot-Fenster den MapEditor-DBG-Overlay visuell gegen die Drillmap/Props ansehen; danach entscheiden, ob zuerst ein Tile-Detailpanel oder Runtime-Segment-LOS geschnitten wird.

### TASK_456 - Wall Segment LOS And Tile Truth Inspector
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_456_wall_segment_los_and_tile_truth_inspector.md`, `docs/dev/terrain_truth_visual_audit_contract.md`, `docs/tasks/TASK_454_terrain_truth_visual_audit.md`, `docs/tasks/TASK_455_terrain_truth_editor_overlay_visibility.md`
- Stand: Die vorbereitete Wandsegmentregel ist im zentralen `LineOfSightSystem` aktiv. Sichtlinien, die ein Wandsegment schneiden, blocken; Sicht entlang derselben Wandseite bleibt frei. Nicht-Wand-Blocker bleiben Whole-Tile-Blocker.
- Stand: Mission-/Fire-Sector-LOS-Debug nutzt dieselbe Segmententscheidung fuer sichtbare Blockerlinien, damit Anzeige und Runtime-Entscheidung nicht auseinanderlaufen.
- Stand: Der MapEditor zeigt fuer selektierte Tiles einen read-only Terrain-Truth-Inspector mit Label, Layer-State, Blocker-Art, Segmentanzahl und Runtime-LOS-Policy.
- Risiken/offen: Segment-LOS nutzt weiterhin die bestehende Grid-Line-Auswahl; fuer spaetere Spezialgeometrie kann ein feinerer Raycaster noetig werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_456_wall_segment_los_and_tile_truth_inspector.gd` laeuft gruen; TASK_455/TASK_454/TASK_379/Hill-Mechanics-Regressionen laufen gruen; `git diff --check` laeuft gruen.
- Naechster Schritt: Im Godot-Fenster gezielt eine Wandkante ansehen: Fireteam/Gegner auf derselben Wandseite vs. echte Kreuzung, dazu selektierten Tile-Inspector gegen DBG-Overlay vergleichen.

### TASK_454 - Terrain Truth Visual Audit
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_454_terrain_truth_visual_audit.md`, `docs/dev/terrain_truth_visual_audit_contract.md`, `docs/tasks/TASK_453_fireteam_terrain_los_sequence_direction_audit.md`
- Stand: `TerrainTruthAudit` liefert eine kleine, read-only Diagnose fuer Tile-/Map-Wahrheit: Terrain-Autoritaet, Terrain3D-Rolle, Dev-UI-Felder, Objektlayer, Blocker-Art und Wandsegment-Kandidaten.
- Stand: Die gewuenschte Mauerregel ist als pruefbarer Segment-Helfer vorbereitet: paralleles Entlangsehen blockt nicht, echter Segment-Schnitt blockt, reiner Eckpunkt-Touch blockt nicht automatisch.
- Stand: `MapEditorTilePropertyOverlay` exportiert die dauerhaft gewuenschten Dev-UI-Felder im Tile-Eintrag und Overlay-Snapshot, bleibt aber visual-only und schreibt keine Gameplay-Wahrheit.
- Risiken: Der aktive `LineOfSightSystem`-Pfad nutzt weiterhin ganze Tile-Blocker. Die Segmentregel ist bewusst Audit-/Contract-Vorbereitung und noch kein Combat-LOS-Umbau.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_454_terrain_truth_visual_audit.gd`; `git diff --check`.
- Naechster Schritt: Den Terrain-Truth-Audit im Godot-Fenster sichtbar verdrahten oder gezielt die Drillmap/Visuals gegen die neuen Auditwerte pruefen.

### TASK_453 - Fireteam Terrain LOS Sequence Direction Audit
- Status: dokumentiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_453_fireteam_terrain_los_sequence_direction_audit.md`, `docs/reports/fireteam_terrain_los_sequence_audit.html`, `docs/dev/html_report_workbench_contract.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Eine neue interaktive HTML-Workbench trennt Terrain-/LOS-Wahrheit, Terrain3D-Rolle, statische Formation und zeitabhaengige Fireteam-Sequenzen.
- Stand: Die Empfehlung ist festgehalten: `TerrainRegistry`, Tile-Daten, LOS-System, Pathfinder und Combat Resolver bleiben Gameplay-Wahrheit. Terrain3D wird vorerst nur als Visual-/Authoring-Kandidat betrachtet.
- Stand: Die Seite beschreibt, warum raupenartiges Vorgehen, ueberschlagendes Vorgehen, Bounding, Fireline, Regroup und Kontaktpausen nicht in die statische Formation-Workbench gehoeren, sondern eine eigene Doctrine-/Sequence-Workbench brauchen.
- Stand: User-Entscheidungen sind nachgetragen: Area-Clearing spaeter, Terrain3D spaeter als Visual-Prototyp auf Drillmap-Kopie, Sequence-Workbench erst als Doku-JSON, Dev-UI mit dauerhaften Terrain-/LOS-Debugwerten.
- Stand: Die Mauer-/LOS-Frage ist als Zielregel dokumentiert: Mauern sollen nicht als ganze Tile-Blocker behandelt werden, sondern als Kanten-/Segment-Blocker, damit Sicht entlang von Mauern moeglich bleibt und diagonale Blockade nur bei echtem Segment-Schnitt entsteht.
- Stand: Die Workbench bietet Tabs fuer Uebersicht, Terrain/LOS, Sequenzen, naechsten Slice und Notizen sowie `JSON exportieren`, Ordner-Export, Kopie und Import.
- Risiken: Der Slice aendert keine Runtime. Die naechste technische Arbeit muss entweder Terrain-Truth-Visual-Audit oder Sequence-Workbench-Contract werden, nicht beides gleichzeitig.
- Lokale Pruefung: HTML-Datei angelegt; `git diff --check`.
- Naechster Schritt: TASK_454 als Terrain Truth Visual Audit schneiden, damit Bodenplatten, Props, Hoehen, LOS-Blocker und Reichweiten sichtbar gegen die Tile-Daten geprueft werden.

### TASK_452 - Fireteam Runtime Baseline Visual Contact Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_452_fireteam_runtime_baseline_visual_contact_pass.md`, `docs/tasks/TASK_451_fireteam_workbench_runtime_import.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: `FireteamMovementController` hat jetzt Runtime-Startpresets fuer `Take C`, `Take N` und `Defend C/N/A`. Diese Kombinationen melden Preset-Key, Quelle und vier Zielslots statt in den alten Fallback zu fallen.
- Stand: `UnitRuntimeStatus` transportiert `aim_readiness_percent`. `TestUnit.assign_unit_command()` uebernimmt den Wert aus `UnitCommand`, und der 3D-Visualpfad liest ihn in den Runtime-Posture-Snapshot.
- Stand: Hohe Aim-Bereitschaft kann im Visualpfad eine sonst gesenkte Waffe sichtbar auf `aimed` heben. Niedrige Werte bleiben gesenkt; damit bleibt `Move N/A` ohne hohen Aim-Wert visuell unten.
- Stand: Area-Defense- und Area-Attack-Commands setzen Kontakt-Initiative, Aim-Bereitschaft und Team-Zielhilfe schon vor dem `assign_unit_command()`, damit Unit-Runtime und Simulation dieselbe Command-Wahrheit sehen.
- Stand: Bestehende Kontakt-/Enemy-Visualtests bestaetigen rote Kontaktlinien, sichtbaren Muzzleflash, vier sichtbare Gegner und laufende Limbo-Kontaktdiagnose.
- Risiken: Die neuen Take-/Defend-Formationen sind Startwerte, keine finalen Workbench-Exporte. Aim-Bereitschaft ist sichtbar angebunden, aber noch keine fein abgestufte Animationstiming-Formel.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_452_fireteam_runtime_baseline_visual_contact_pass.gd`, TASK_451/TASK_446/TASK_438/TASK_440/TASK_432-Regressionen und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster Take C/N und Defend C/N/A gegen die neue Baseline ansehen und bei Bedarf als echte Workbench-Presets exportieren.

### TASK_451 - Fireteam Workbench Runtime Import
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_451_fireteam_workbench_runtime_import.md`, `docs/tasks/TASK_450_fireteam_stance_command_preset_workbench.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Der Workbench-Export `fireteam_formation_tuning_2026-05-17T08-46-56-746Z_05` ist als erste Runtime-Baseline im `FireteamMovementController` hinterlegt.
- Stand: Move C/N/A, Engage C/N/A und Take A nutzen die gespeicherten Workbench-Zielslots statt der aelteren Abstandskonstanten. Take C/N und Defend C/N/A bleiben bewusst auf der vorhandenen Runtime-Baseline, bis dafuer eigene Workbench-Exporte vorliegen.
- Stand: Die globalen C/N/A-Stance-Werte aus `_05` wirken im Runtime-Befehlspfad auf Speed, Sicht, Deckungsprioritaet, Aim-Bereitschaft, Kontakt-Initiative und Team-Zielhilfe.
- Stand: `UnitCommand` transportiert `contact_initiative_seconds`, `aim_readiness_percent` und `team_target_support_percent`. `team_target_support_percent` wirkt im `CombatFireDecisionResolver` als Trefferchancen-Hook, `contact_initiative_seconds` wirkt im Mission-Combat-Loop auf die Kontaktverzoegerung.
- Stand: Movement-Snapshots melden `formation_preset_key`, `formation_slot_source` und `formation_leader_slot`, damit UI/Debug erkennen koennen, ob Workbench `_05` aktiv ist.
- Risiken: `aim_readiness_percent` ist aktuell transportiert und diagnostiziert, aber noch keine finale Animations-/Aim-Timing-Formel. Defend- und Take-C/N-Formationen brauchen noch bewusste Workbench-Exporte.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_451_fireteam_workbench_runtime_import.gd`, TASK_429/TASK_446-Regressionen und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster Move/Engage/Take A gegen Workbench `_05` pruefen und danach Defend sowie Take C/N als eigene Formations-Exporte festziehen.

### TASK_447 - Fireteam Contact Initiative Rules
- Status: dokumentiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_447_fireteam_contact_initiative_rules.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/html_report_workbench_contract.md`
- Stand: Der Behavior-Contract definiert `Kontakt-Initiative` als Zeit vom sichtbaren/suspekten Kontakt bis zum ersten koordinierten Schuss. Die Regel trennt diese Reaktionszeit bewusst von Waffen-Feuerrate und Trefferchance.
- Stand: `contact_initiative_seconds` und `team_target_support_percent` haben erste Startwerte fuer FOV-Lage, Waffen-/Sichtdistanz, Buddyteams, lose Wolke und Command/Stance-Bewegung.
- Stand: Die Formation-Workbench zeigt Sekunden bis erster koordinierter Schuss, Kontaktentfernung, FOV-Lage, Buddy-Effekt und Team-Zielhilfe und exportiert die Modifikatoren als JSON-Diagnose.
- Stand: Character-Sheet-Hilfetexte nennen jetzt Kontakt-Initiative und Team-Zielhilfe als spaetere Wirkung von Awareness, Recognition, Initiative, Leadership, Speech Quality und Accuracy.
- Risiken: Die Formel ist noch ein Tuningmodell und keine Runtime-Wahrheit. Die spaetere Combat-Anbindung muss ueber CombatFireDecisionResolver, Kontaktstatus und Character-Sheet-Hooks laufen.
- Lokale Pruefung: HTML-Script-Syntax der Formation-Workbench und `git diff --check`.
- Naechster Schritt: Im Playtest Zielmarker/Facing/FOV mit Buddyteams und loser Wolke vergleichen; danach entscheiden, welche Werte in den Runtime-Contact-Resolver wandern.

### TASK_448 - Fireteam Workbench Profile Clarity
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_448_fireteam_workbench_profile_clarity.md`, `docs/dev/html_report_workbench_contract.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Die Formation-Workbench koppelt Sicht-% und FOV gegenlaeufig: breiteres FOV senkt Sicht-%, hoehere Sicht-% schmalert FOV.
- Stand: Command/C/N/A zeigen jetzt eine Profilzusammenfassung mit Speed, Sicht, FOV, Deckung und kurzer Verhaltensbeschreibung. Manuelle Profilslider deaktivieren die Auto-Profil-Anzeige.
- Stand: Sicherungs- und Formationsspeicher beziehen sich sprachlich auf das aktuelle Command/CNA. Benannte Formationen koennen in einer kleinen Workbench-Bibliothek gespeichert, geladen, geloescht und exportiert/importiert werden.
- Stand: Basis-Sicht ist als Meterwert erklaert; Waffenreichweite zeigt WeaponData-Tiles plus Design-Meter-Schaetzung mit 1,5m pro Tile.
- Risiken: Die Kopplung und Bibliothek bleiben Workbench-/Exportmodell und schreiben keine Runtime-Wahrheit.
- Lokale Pruefung: HTML-Script-Syntax der Formation-Workbench und `git diff --check`.
- Naechster Schritt: Im Browser die Bedienung einmal durchgehen: FOV/Sicht koppeln, benannte Formation speichern/laden, Command/CNA-Regel speichern und JSON exportieren.

### TASK_449 - Fireteam Distance CNA Workbench Rules
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_449_fireteam_distance_cna_workbench_rules.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/html_report_workbench_contract.md`
- Stand: Der Behavior-Contract definiert ein gemeinsames Distanz-C/N/A-Profil. Move, Engage, Take und Defend nutzen fuer dieselbe Haltung dieselben Distanz-Mali und Distanz-Boni.
- Stand: Die Formation-Workbench hat im Kontakt-Initiative-Bereich einen aufklappbaren Editor fuer Distanz-C/N/A. Die Werte steuern Nahbereich, gute Feuerdistanz, Randbereich, ausser Waffenreichweite und ausser Sicht.
- Stand: Die Kontakt-Initiative liest die aktiven Distanzwerte aus dem gemeinsamen Profil statt aus hart kodierten Command-Distanzwerten.
- Stand: JSON-Export und JSON-Import enthalten `distance_profile_by_stance` und `active_distance_profile`.
- Risiken: Die Werte sind weiterhin Workbench-/Contract-Tuning und noch keine Runtime-Wahrheit. Die Uebernahme in CombatFireDecisionResolver bleibt ein separater Slice.
- Lokale Pruefung: HTML-Script-Syntax der Formation-Workbench und `git diff --check`.
- Naechster Schritt: In der Workbench C/N/A-Distanzwerte gegeneinander testen und danach entscheiden, welche Startwerte in den Runtime-Contact-Resolver wandern.

### TASK_450 - Fireteam Stance Command Preset Workbench
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_450_fireteam_stance_command_preset_workbench.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/html_report_workbench_contract.md`
- Stand: Die Formation-Workbench trennt jetzt globale Stance-Grundwerte von statischer Command/CNA-Formation und Sicherung.
- Stand: C/N/A-Grundwerte fuer Speed, Sicht, Deckung, Aim-Bereitschaft, Kontaktzeit und Zielhilfe koennen in einem aufklappbaren Editor geaendert werden. Bei aktivem Auto-Profil wirken sie live auf die sichtbaren Profilwerte.
- Stand: Charakterbogen-Hooks werden als sortierte, exportierbare Checkliste vorgemerkt, ohne Runtime- oder Character-Sheet-Wahrheit zu schreiben.
- Stand: Zeitabhaengige Begriffe wie raupenartig, ueberschlagend, Bounding und Fireline sind aus der statischen Formationsebene herausgenommen. Die Workbench speichert nur Standbild und Blickrichtung; echte Ablaufsequenzen brauchen einen eigenen Slice.
- Stand: Stance- und Distanz-Editoren nutzen jetzt einspaltige Reglerzeilen mit eigener Label-/Wert-Zeile, damit Werte in der schmalen Sidebar nicht mehr auf Beschriftungen oder aus dem Panel laufen.
- Stand: Die Editor-Seite gibt der rechten Tuning-Spalte mehr Breite und zeigt die drei C/N/A-Stance-Karten auf breiten Viewports nebeneinander; die Kartenflaeche wird dafuer kleiner.
- Stand: Leader-Position markiert jetzt die gewaehlte Positionsnummer als FTL. Es werden keine Slots mehr getauscht; das Sternchen wandert auf Position 1-8.
- Stand: Leader-Position ist keine Layout-Aenderung mehr. Eine manuell gezogene Formation bleibt stehen, wenn nur der FTL-Stern auf eine andere Positionsnummer gesetzt wird; beim Ziehen einzelner Positionen springt die Leader-Auswahl nicht mehr auf `auto`.
- Stand: Nach Drag-and-drop verformen `Buddy`, `Teamabstand` und `Reihe` die bestehende manuelle Formation proportional, statt die Positionen auf das Formationspreset zurueckzusetzen.
- Stand: Freie Klicks auf die Formation-Map setzen kein neues Ziel mehr. Ziel, Teamanker, Member und Blickrichtungen aendern sich nur beim Ziehen ihrer sichtbaren Griffe.
- Stand: Speichern oder JSON-Export merkt den aktuellen Workbench-Stand lokal im Browser als Reload-Standard; `Zuruecksetzen` loescht diesen lokalen Workbench-Standard.
- Stand: Die zuletzt exportierte Formationssammlung aus `_05` ist als eingebauter Workbench-Startsatz hinterlegt: Move C/N/A, Engage C/N/A und Take A sind beim Reload ohne JSON-Import vorhanden.
- Stand: Die in `_05` gespeicherten Sicherungsbilder fuer Engage C/N/A und Take A sind ebenfalls als eingebauter Startsatz hinterlegt.
- Stand: Die zuletzt bewusst getunten C/N/A-Stance-Grundwerte sind ebenfalls als eingebauter Workbench-Startsatz hinterlegt. Ein lokaler Reload-Standard mit den alten Reset-Defaults wird beim Laden auf diese Werte migriert.
- Stand: Buddyteams sind in der Workbench fest als 1+2, 3+4, 5+6, 7+8 benannt. Der Reihenabstand kann bis 900 Welt-Einheiten eingestellt werden.
- Stand: Speicher-/Loeschbuttons nennen jetzt die konkrete Kombination, z.B. `Formation fuer Move C speichern`.
- Stand: JSON-Export enthaelt `stance_profile_by_stance`, `active_stance_profile`, `command_stance_preset_overrides` und `character_sheet_hook_locks`.
- Risiken: Die Workbench bleibt ein Tuning-/Exportwerkzeug. Runtime-Uebernahme und Sequenzlogik sind bewusst nicht Teil dieses Slices.
- Lokale Pruefung: HTML-Script-Syntax der Formation-Workbench, Browser-Smoke und `git diff --check`.
- Naechster Schritt: Stance-Werte und statische Sicherungsbilder im Browser abstimmen; danach eigene Sequenz-Workbench fuer raupenartig/ueberschlagend entscheiden.

### TASK_446 - Fireteam Workbench Spacing Runtime Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_446_fireteam_workbench_spacing_runtime_pass.md`, `docs/tasks/TASK_445_html_report_workbench_standard.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: Die neuesten Formation-Workbench-Exporte unter `docs/reports/fireteam_formation_tuning_*.json` wurden als Playtest-Input ausgewertet. Move C/N/A und Engage C/N/A bestaetigen groessere Abstaende, Buddy-Zweierteams, schmale FOV-/Waffenreichweiten-Diagnose und maximal 1 Einheit pro Tile als Zielbild.
- Stand: `FireteamMovementController` nutzt fuer direkte Move-/Fireline-Zielslots jetzt symmetrische laterale Slots statt der alten einseitigen Slotreihe. Move C/N verwendet 80 Welt-Einheiten, Move A 112, Engage A 121; Engage/Take-Bounds nutzen groessere Slot-Abstaende und mehr Paar-Reihenversatz.
- Stand: Der Movement-Snapshot exportiert `formation_slot_spacing_world` und `formation_parallel_spacing_world`, damit #17/Debug und Tests erkennen koennen, welche Runtime-Baseline aktiv ist.
- Risiken: Dieser Slice setzt die gewollten Zielslots, ersetzt aber nicht Terrain-Pathing oder Local Avoidance. Wenn Units trotzdem im Engpass einfaedeln, muss der naechste Slice dort ansetzen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_446_fireteam_workbench_spacing_runtime_pass.gd`, TASK_442/TASK_443-Regressionen und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster Move C/N/A und Engage C/N/A gegen die exportierten Formationen testen; danach Local-Avoidance/Pathing nur anfassen, wenn die Zielslots korrekt sind, aber die Laufwege wieder zusammenfallen.

### TASK_445 - HTML Report Workbench Standard
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_445_html_report_workbench_standard.md`, `docs/dev/html_report_workbench_contract.md`, `AGENTS.md`
- Stand: Neue oder groesser ueberarbeitete HTML-Arbeitsreports unter `docs/reports/` sollen ab jetzt als interaktive Workbench mit Uebersicht, Tests/Entscheidungen, Notizen und sichtbarem `JSON exportieren`-Button entstehen.
- Stand: `docs/reports/_html_workbench_template.html` liefert eine lokale Vorlage mit Tabs, Statusfeldern, Choice-Buttons, Notizen, JSON-Export, Kopierfunktion und optionalem JSON-Import.
- Stand: `docs/reports/fireteam_formation_tuning_workbench.html` ist als erstes nutzbares Tool angelegt: Fireteam/Ziel verschiebbar, Slider fuer Speed/Sicht/Abstaende/Reihenversatz, Formation-/Sektorvorschau und JSON-Export der eingestellten und berechneten Werte.
- Stand: Die Formation-Workbench erlaubt jetzt direktes Ziehen einzelner Teammember. Aus den Member-Positionen werden Buddy-Abstand, Buddy-Team-Abstand und Reihenversatz in die Regler zurueckgerechnet; Buddy-Teams sind als Zweierteams sichtbar und im Export enthalten.
- Stand: Zusaetzliche Regler fuer Formationstyp, Sicherungssektor, Cohesion-Radius und Deckungsprioritaet sind im Tool und im JSON-Export enthalten.
- Stand: Die Parameter wurden fuer den Playtest klarer benannt: `FOV` fuer Sichtfeldbreite, `Waffen-RW` fuer Waffenreichweite, `Tile-Gr.` fuer sichtbare Rastergroesse und `Cohesion` fuer den Zusammenhaltsradius. Buddy/Team/Reihe haben groessere Wertebereiche.
- Stand: Teammember haben jetzt einen gelben Drehgriff fuer Blick-/Waffenrichtung; manuell gesetzte Facing-Winkel werden im Export als `facing_degrees` gespeichert.
- Stand: Template und Formation-Workbench bieten jetzt einen optionalen `Reports-Ordner verbinden`-Pfad. Wenn der Browser lokalen Schreibzugriff erlaubt, schreibt `JSON exportieren` mehrere eindeutige Zeitstempel-Dateien in den verbundenen Ordner; sonst bleibt der Browser-Download plus Textfeld aktiv.
- Stand: In der Formation-Workbench ist `Sicherung` aus dem Command-Block herausgezogen, damit Command und Blick-/Waffenverteilung klar getrennt sind.
- Stand: Die Formation-Workbench trennt jetzt `Grundformation`, `Sicherung` und `Abgeleitete Werte`: Waffenreichweite kommt aus der gewaehlten WeaponData-Waffe, Sicht wird als Meter-/Tile-Diagnose gerechnet und FOV bleibt ein Command-/Stance-Profilwert.
- Stand: Ein neuer `C/N/A Matrix`-Tab zeigt Move, Engage, Take und Defend jeweils als drei kompakte Vergleichsbilder, damit die Presets ohne Umklicken gegeneinander geprueft werden koennen.
- Stand: Command-/Stance-Automatik und Grundformation sind jetzt getrennt schaltbar. Exporte enthalten einen benannten `formation_candidate`, die Leader-Position und die Information, dass die JSON erst nach bewusster Uebernahme Runtime-Wahrheit wird.
- Stand: FOV ist in der Workbench auf 10-90 Grad begrenzt; engere FOVs erzeugen nur als Tuning-Diagnose einen kleinen Sicht-Fokusfaktor.
- Stand: Die Formation-Workbench unterstuetzt jetzt Fireteam-Groessen 2/4/6/8 mit nummerierten Positionen 1-8. Buddy-Paare koennen sequenziell, gekreuzt oder aussen/innen gebildet werden.
- Stand: Sicherungsbilder koennen ueber die Drehgriffe manuell gesetzt und fuer den aktuellen Command/Stance als Override exportiert werden; Area-Regeln bleiben bewusst ausserhalb dieses Workbench-Slices.
- Stand: Grundformationen koennen jetzt ebenfalls fuer den aktuellen Command/Stance als Override gemerkt, aktiviert/deaktiviert und exportiert werden. Buddyteams lassen sich abschalten, dann zeigt die Workbench eine lose Wolke ohne feste Zweierteams.
- Stand: Die Leader-Position ist jetzt eine Positionsnummer 1-8; spaetere Roster-/NPC-Zuordnung bleibt getrennt von diesen Formationsplaetzen.
- Risiken: Der Export ist nur Playtest-/Doku-Kommunikation und keine Gameplay-Wahrheit. Die Formation-Workbench ist ein Tuningmodell und noch nicht direkt an Runtime-Konstanten gebunden.
- Lokale Pruefung: Template lokal im Browser oeffnen, Formation-Workbench bedienen, JSON exportieren/kopieren/importieren und `git diff --check`.
- Naechster Schritt: Den naechsten Fireteam-Runtime-Fix mit dieser Workbench abstimmen: weniger Gaensemarsch, bessere Buddy-Abstaende, directional Security beim Vorruecken und sichtbare Enemy-/Leader-Visuals.

### TASK_444 - Fireteam Behavior Playtest Workbench HTML
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_444_fireteam_behavior_playtest_workbench_html.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/tasks/TASK_442_fireteam_engage_behavior_control.md`, `docs/tasks/TASK_443_fireteam_take_behavior_control.md`
- Stand: `docs/reports/fireteam_behavior_playtest_workbench.html` fasst Move, Engage, Take und Defend als bedienbare Playtest-Arbeitsseite mit Formationsbildern, C/N/A-Werten, Testmatrix, offenen Entscheidungen und JSON-Export zusammen.
- Stand: Die Seite trennt klar zwischen umgesetztem Runtime-Stand und offenen manuellen Pruefungen. Defend ist als vorhandene Baseline, aber noch nicht final neu geschnittener Behavior-Slice markiert.
- Risiken: Die HTML-Seite ist Doku/Playtest-Hilfe und fuehrt keine Runtime-Wahrheit ein. Defend-Regeln sind Vorschlag fuer den naechsten Implementierungsschritt.
- Lokale Pruefung: HTML lokal oeffnen und `git diff --check`.
- Naechster Schritt: Defend-Regeln entscheiden und danach als eigenen Runtime-Slice mit Tests umsetzen.

### TASK_443 - Fireteam Take Behavior Control
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_443_fireteam_take_behavior_control.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/tasks/TASK_442_fireteam_engage_behavior_control.md`
- Stand: `Take` wird im `FireteamMovementController` nicht mehr wie eine direkte Baseline-Bewegung behandelt. C und N laufen als Buddy-Bounds; A laeuft als gemeinsame Sturm-/Fireline-Bewegung.
- Stand: Take-Commands tragen Diagnosefelder fuer Doktrin, Advance-Mode, Zielpolitik, Buddy-Teams, Area-Control-Pflicht und technische Optimalreichweite.
- Stand: `UnitCommand` transportiert `engagement_range_policy` und `engagement_range_factor`; der Combat-Fire-Resolver begrenzt Attackability damit fuer Take auf die technische Optimalreichweite.
- Stand: Area-Take-Kommandos aus `MissionTacticalSandboxController` nutzen dieselbe Take-Doktrin und Range-Policy wie Waypoint-Take.
- Risiken: Die Optimalreichweiten-Faktoren sind erste technische Startwerte. "Wenn beschossen, frueher feuern" und feinere Raum-Clearing-Schritte bleiben eigene Folge-Slices.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_443_fireteam_take_behavior_control.gd`, relevante TASK_442/TASK_432/TASK_429/TASK_123-Regressionen und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster `Take Area` in C/N/A testen: Anmarsch, Feuerdistanz, Area-Besetzung, Secured-State und danach Defend/Security-Lesbarkeit.

### TASK_442 - Fireteam Engage Behavior Control
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_442_fireteam_engage_behavior_control.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/tasks/TASK_432_fireteam_muzzle_flash_and_baseline_attack_movement.md`, `docs/tasks/TASK_441_fireteam_map_tool_drill_rebuild.md`
- Stand: `Engage` wird im `FireteamMovementController` nicht mehr wie ein generischer Baseline-Move in `rush` gezwungen. C und N laufen als Buddy-Bounds; A laeuft als gemeinsame Fireline/Rush-Bewegung.
- Stand: Engage-Commands tragen Diagnosefelder fuer Doktrin, Advance-Mode, Zielpolitik, Buddy-Teams und Waffenreichweiten-Feuer.
- Stand: Der Combat-Loop nutzt fuer Engage-Kontakt-Los mindestens die Waffenreichweite, damit sichtbarer Engage-Kontakt nicht am alten kurzen Contact-Range-Gate haengen bleibt.
- Stand: `Take` bleibt fuer diesen Slice bewusst Baseline und ist als naechste eigene Kontrollmatrix abgegrenzt.
- Risiken: Grosse Engage-Areas nutzen weiterhin die bestehende Area-State-Maschine; feinere Crawl-/Bound-Phasen innerhalb der Area brauchen einen Folge-Task.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_442_fireteam_engage_behavior_control.gd`, relevante TASK_432/TASK_429/TASK_123-Regressionen und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster `Engage Area` in C/N/A testen: Zielwahl, rote Schusslinie, Muzzle Flash und ob die Buddy-Bounds auf der Drillmap lesbar sind.

### TASK_441 - Fireteam Map Tool Drill Rebuild
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_441_fireteam_map_tool_drill_rebuild.md`, `docs/tasks/TASK_416_fireteam_command_drill_map.md`, `docs/tasks/TASK_439_fireteam_runtime_map_flow_limbo_review.md`, `docs/tasks/TASK_440_enemy_limbo_contact_diagnostics.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/enemy_team_tactics_contract.md`
- Stand: Der MapEditor-Patrol-Selector liest jetzt Enemy-IDs, Binding-IDs und Patrol-Route-IDs aus dem geladenen Szenario und der Karte, statt nur alte Platzhalter zu zeigen.
- Stand: Patrol-Edits und Waypoint-Zaehler loesen eine Gegnerreferenz wie `enemy_foxtrot` auf die gebundene Route `enemy_drill_foxtrot_route` auf. Damit ist die aktuelle Drillmap im Tool mit allen vier Gegnern bearbeitbar.
- Stand: `docs/reports/fireteam_map_tool_drill_rebuild_status.html` fasst den Map-Tool-Stand zusammen und benennt Engage/Take/Defend als vorhandene, aber weiter zu kontrollierende Baseline.
- Risiken: Der MapEditor prueft Authoring-Konsistenz, nicht finales Combat-Verhalten. Engage, Take und Defend brauchen als naechsten Schritt eine Runtime-Matrix fuer Tile/Area, C/N/A und Kontaktlagen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_441_fireteam_map_tool_drill_rebuild.gd`, `git diff --check`
- Naechster Schritt: Engage, Take und Defend gezielt als Matrix kontrollieren: Tile vs. Area, kein Kontakt vs. sichtbarer Kontakt, C/N/A und Abschluss/Auto-Defend.

### TASK_440 - Enemy Limbo Contact Diagnostics
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_440_enemy_limbo_contact_diagnostics.md`, `docs/tasks/TASK_439_fireteam_runtime_map_flow_limbo_review.md`, `docs/tasks/TASK_434_limboai_enemy_behavior_adapter_smoke.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/enemy_team_tactics_contract.md`
- Stand: `EnemyLimboBehaviorAdapter` liefert zu ausgewaehlten oder nicht ausgewaehlten Branches einen Diagnosegrund und spiegelt Kontakt-/Patrol-/Cover-Flags im Result.
- Stand: `MissionCombatLoopDriver` speichert pro Enemy den letzten Limbo-Entscheid als Snapshot und setzt Action/Source/Reason-Meta fuer Unit-Snapshots.
- Stand: Enemy-Limbo-Cover- und Contact-Hold-Commands tragen explizit `fire_at_will`, `enemy_bt_action` und `enemy_bt_reason`, bleiben aber normale Command-Dictionaries fuer `SimulationRoot`.
- Stand: `MissionTacticalSandboxController.get_command_feedback_snapshot()` reicht den Enemy-Limbo-Snapshot als `enemy_limbo_behavior` fuer #18/Dev-Diagnose weiter.
- Risiken: Der Snapshot erklaert Entscheidungen, ersetzt aber nicht LOS, Pathing, Damage oder Combat-Fire-Resolver.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_440_enemy_limbo_contact_diagnostics.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_434_limboai_enemy_behavior_adapter_smoke.gd`, `git diff --check`
- Naechster Schritt: Im Godot-Fenster pruefen, ob Gegner bei sichtbarem Kontakt jetzt mit nachvollziehbarem Limbo-Grund in #18/Feedback auftauchen und ob der Schuss weiter am Combat-Fire-Resolver haengt.

### TASK_439 - Fireteam Runtime Map Flow Limbo Review
- Status: dokumentiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_439_fireteam_runtime_map_flow_limbo_review.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/enemy_team_tactics_contract.md`, `docs/tasks/TASK_434_limboai_enemy_behavior_adapter_smoke.md`, `docs/tasks/TASK_438_fireteam_contact_visibility_attack_visuals.md`
- Stand: `docs/reports/fireteam_runtime_map_flow_limbo_review.html` beschreibt den aktiven Pfad von Input/GO ueber FireteamMovementController, SimulationRoot, CombatLoop und TerrainMap3DView.
- Stand: Erwartetes Verhalten fuer Move/Defend/Take/Engage, Waypoint-Abschluss, Kontakt, Muzzle Flash und Debug-Feedback ist zusammengefasst.
- Stand: User-Antworten sind als Arbeitsannahmen eingearbeitet: Produktionspfad fuer MissionTacticalSandboxController, Skills erstmal aus, Flanking spaeter paarweise, Sicherungsrichtungen stark sichtbar, Schusslinie bis Waffenreichweite, Sichtlinie als erster 100-m-/67-Tile-Wert plus LOS-Blocker.
- Stand: LimboAI ist nach lokalem und offiziellem Doku-Blick als ernsthafter Hybrid-Kandidat bewertet: sinnvoll fuer Gegnerabsichten und Debug-Gruende, nicht fuer direkte Unit-/Damage-/Visual-Wahrheit; Full-Low-Level-Umstieg bleibt nicht empfohlen.
- Risiken: Die HTML ist eine Debug- und Entscheidungsreferenz; Codezeilen koennen driften und ersetzen keine Contracts.
- Lokale Pruefung: `git diff --check`
- Naechster Schritt: Kontakt-/Enemy-Angriffsverhalten mit sichtbaren Debug-Gruenden und kleinem LimboAI-Hybrid-Verifier stabilisieren.

### TASK_437 - Fireteam Selection Patrol Contact Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_437_fireteam_selection_patrol_contact_pass.md`, `docs/tasks/TASK_436_fireteam_sight_security_visuals.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: Selected-Unit-Marker im 3D-Overlay sind gelb und flacher/bodennah; ausgewaehlte Fireteam- und #17-Member-Cards nutzen gelbe Auswahlrahmen.
- Stand: Normale Move-Zielslots sind breiter/parallel gesetzt, und Move-Commands bleiben `fire_at_will`, damit Kontaktfeuer nicht mehr durch den Bewegungsbefehl selbst blockiert wird.
- Stand: Die Drill-Gegner starten als vier aktive NPCs in einer Wave. Patrol-Bindings werden nach Wave-Aktivierung initialisiert und vor alten Team-Tactics ausgefuehrt, solange kein Kontakt Cover/Hold erzwingt.
- Risiken: Kontaktfeuer auf Move ist jetzt eine Baseline-Regel; spaetere ROE-/Skill-Regeln muessen das explizit wieder einschraenken, statt still ueber Legacy-Hold-Fire zu blockieren.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_437_fireteam_selection_patrol_contact_pass.gd`, relevante TASK_423/TASK_424/TASK_432/TASK_435/TASK_436-Regressionen und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster Move auf Feindkontakt, gelbe Auswahl und rote Patrol sichtbar gegen den aktuellen Playtest pruefen.

### TASK_438 - Fireteam Contact Visibility Attack Visuals
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_438_fireteam_contact_visibility_attack_visuals.md`, `docs/tasks/TASK_437_fireteam_selection_patrol_contact_pass.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: Sichtbare Fire-Lines wechseln bei `spotted`/`confirmed` Kontakt auf Rot; Live-Combat-Fire-Events synchronisieren den Primary-3D-View sofort, damit Muzzle Flash und roter Trace nicht erst auf einen spaeteren UI-Refresh warten.
- Stand: Hostile 3D-Proxies tragen eine kleine Body-Readability-Core unter dem animierten Modell und rebuilden, wenn sich die Visual-Archetype/Loadout-Signatur nach Wave-/Tactics-Aktivierung aendert.
- Stand: Drill-Buesche werden mit zusaetzlichem Objekt-Y-Offset ueber der Ground-Tile-Oberflaeche gerendert.
- Risiken: Der rote Trace ist bewusst nur eine sichtbare Kontakt-/Schussdiagnose; Trefferwahrscheinlichkeit, Suppression und spaetere KI-Skillregeln bleiben unveraendert.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_438_fireteam_contact_visibility_attack_visuals.gd`, relevante TASK_435/TASK_436/TASK_437-Regressionen und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster testen, ob Gegner bei Sichtkontakt nun sichtbar schiessen, alle vier Koerper erkennbar sind und Buesche sichtbar auf den Tiles stehen.

### TASK_436 - Fireteam Sight Security Visuals
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_436_fireteam_sight_security_visuals.md`, `docs/tasks/TASK_435_fireteam_manual_visual_regression_pass.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`
- Stand: Friendly Sight-/Fire-Linien starten im 3D-Overlay am Head-Socket bzw. Head-Fallback und werden sichtbar auf eine lesbare Waffenreichweiten-Laenge begrenzt.
- Stand: Directional Defense verteilt vier Mitglieder als zwei Front-Sicherer plus linke/rechte Flanke; `360` bleibt kardinal. Security-Assignments schreiben sichtbares Facing-Meta auf die Units, und die Fireteam-Mini-Card zeigt eine kleine Coverage-Bar.
- Stand: HUD-FTL-Bubbles sind oben/linksbuendig und umbrechen eher in kurze Zeilen. Muzzle Flash, Bloom und Trace sind im Render-Snapshot groesser/lesbarer.
- Stand: Die Drillmap setzt Buesche wieder als `nature_bush_cover`-Objekte auf normale Ground-Tiles; alle vier Gegner haben Patrol-Bindings und groessere Spawn-Abstaende.
- Risiken: Die Coverage-Bar ist zunaechst eine kompakte Diagnose-Anzeige, kein neues Security-Datenmodell. Patrol ist nur Drillmap-Playtest-Hilfe.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_436_fireteam_sight_security_visuals.gd`, relevante TASK_401/TASK_424/TASK_429/TASK_431/TASK_435-Regressionen und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster Defense 360/Front/Flanken, Muzzle Flash und Gegner-Patrol einmal sichtbar gegen die Screenshots pruefen.

### TASK_435 - Fireteam Manual Visual Regression Pass
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_435_fireteam_manual_visual_regression_pass.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_431_fireteam_aim_pose_and_card_ui_hotfix.md`, `docs/tasks/TASK_432_fireteam_muzzle_flash_and_baseline_attack_movement.md`
- Stand: Eine kombinierte Drillmap-Regression prueft den sichtbaren Baseline-Pfad mit vier eigenen und vier gegnerischen 3D-Proxies, Ground-Auswahlmarkern, Cautious-Move-Aim, C/N/A-Livewechsel, Muzzle Flash und Engage-Area-zu-Take-Area-Folge.
- Stand: 3D-Unit-Snapshots liefern jetzt das sichtbare Status-Badge mit; aktive `move`-/`engage`-Befehle gewinnen vor generischen `HOLD`-Labels.
- Stand: Area-Feedback benennt `engage` explizit als `ENGAGE`, damit `#17` und FTL-Bubbles nicht auf generisches `ATTACK` zurueckfallen.
- Risiken: Die Regression deckt die wichtigsten Fenster-Signale headless ab, ersetzt aber nicht den finalen Blick auf Kamera-Framing und Lesbarkeit im Godot-Fenster.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_435_fireteam_manual_visual_regression_pass.gd`, relevante TASK_424/TASK_425/TASK_426/TASK_431/TASK_432-Regressionen und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster einen kurzen manuellen Durchlauf `C -> Move -> GO`, `A/N live`, Feuerkontakt und `Engage Area -> GO -> Take Area` machen; danach erst wieder neue Taktiklogik schneiden.

### TASK_434 - LimboAI Enemy Behavior Adapter Smoke
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_434_limboai_enemy_behavior_adapter_smoke.md`, `docs/tasks/TASK_433_install_third_party_godot_plugins.md`, `docs/dev/enemy_team_tactics_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `AGENTS.md`, `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`, `docs/TASK_ROADMAP.md`
- Stand: `EnemyLimboBehaviorAdapter` baut einen programmgesteuerten LimboAI-BehaviorTree mit Selector/Sequence-Zweigen fuer `seek_cover`, `contact_hold` und `patrol`.
- Stand: `MissionCombatLoopDriver` ruft den Adapter nur nach expliziten Enemy-Team-Tactics und vor altem Patrol/Fallback auf; Aktionen enqueueen weiter normale Dictionaries ueber `SimulationRoot.enqueue_command()`.
- Stand: Cover-Suche nutzt die bestehende `TerrainRegistry.get_walkable_cover_tiles_in_radius()`-Datenquelle mit Cooldown und schreibt keine eigene Enemy-Wahrheit.
- Risiken: Der BT ist bewusst ein Smoke-Slice, noch kein editorbares BehaviorTree-Asset und kein vollstaendiges Enemy-AI-Authoring.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_434_limboai_enemy_behavior_adapter_smoke.gd`, `godot_console.exe --headless --path . --quit` und `git diff --check`.
- Naechster Schritt: Den BT-Slice im Godot-Fenster sichtbar gegen eine kleine Patrol/Kontakt/Cover-Szene pruefen und danach entscheiden, ob die naechste Iteration auf `.tres`-Trees oder weitere Blackboard-Daten geht.

### TASK_433 - Install Third Party Godot Plugins
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_433_install_third_party_godot_plugins.md`, `AGENTS.md`, `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`, `docs/TASK_ROADMAP.md`
- Stand: `Terrain3D` liegt als Release `v1.0.1` unter `addons/terrain_3d/` und ist als EditorPlugin aktiviert.
- Stand: `LimboAI` liegt als Release `v1.7.0` / `gdextension-4.6` unter `addons/limboai/`; die GDExtension wird ueber `addons/limboai/bin/limboai.gdextension` geladen.
- Stand: `netfox` liegt als aktuelle Repo-Version `1.43.4` unter `addons/netfox/` und `addons/netfox.internals/`; die stabile Release-Version `v1.35.3` wurde verworfen, weil sie im Godot-4.6.2-Headless-Import nicht sauber kompiliert.
- Stand: `godot-open-rts` ist unter `addons/godot_open_rts_reference/` nur als per `.gdignore` deaktiviertes Referenzpaket eingebunden, weil upstream ein Godot-4.3-Beispielprojekt ohne `plugin.cfg` ist.
- Risiken: Die Plugins sind installiert, aber nicht fachlich in Terrain-, AI-, RTS- oder Multiplayer-Gameplay integriert. netfox fuegt eigene Autoloads hinzu; jede Gameplay-Nutzung braucht einen separaten Architektur-/Authority-Task.
- Lokale Pruefung: `godot_console.exe --version`, `godot_console.exe --headless --path . --import`, `godot_console.exe --headless --path . --quit` und fokussiertes `git diff --check` laufen erfolgreich. Der Import meldet nur, dass das `godot-open-rts`-Referenzprojekt wegen eigenem `project.godot` ignoriert wird; der Headless-Start zeigt eine netfox-Debugzeile.
- Naechster Schritt: Vor echter Nutzung je Plugin einen kleinen Integrations-Task schneiden, damit keine zweite Terrain-, KI-, RTS- oder Multiplayer-Wahrheit neben den bestehenden Runtime-Vertraegen entsteht.

### TASK_432 - Fireteam Muzzle Flash And Baseline Attack Movement
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_432_fireteam_muzzle_flash_and_baseline_attack_movement.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/tasks/TASK_429_fireteam_behavior_modes_runtime.md`, `docs/tasks/TASK_431_fireteam_aim_pose_and_card_ui_hotfix.md`
- Stand: Muzzle-Flash-Visuals werden aus bestehenden Fire-Events groesser geclamped und erhalten einen sichtbaren Bloom-Marker, ohne Combat-Wahrheit in die Visualschicht zu verschieben.
- Stand: `Move`, `Engage`, `Take`, `Defend` und `Hold` laufen im sichtbaren Mission-Tactical-Pfad als direkte Baseline-Gruppenbewegung; Ziel-Fidelity-Offsets bleiben nur fuer explizites `flank`.
- Stand: Autonome Leader-Flanks sind fuer diese Basisrunde deaktiviert. `Engage Area` bleibt Kampf ohne Besitzpflicht, waehrend `Take Area` weiterhin besetzt und sichert.
- Stand: Enemy-Spawn-Offsets der Drill-Szene verteilen vier Gegner lesbarer; Legacy-2D-Auswahlringe werden nach Auswahlwechseln erneut unterdrueckt.
- Risiken: Flank ist damit bewusst ausgeklammert und muss spaeter als explizit koordinierter Befehl neu aufgebaut werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_432_fireteam_muzzle_flash_and_baseline_attack_movement.gd`, relevante TASK_205/TASK_424/TASK_426/TASK_429/TASK_431-Regressionen und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster `Engage Area -> GO -> Take Area` und Feuerkontakt sichtpruefen; danach Flank separat kontrolliert designen.

### TASK_431 - Fireteam Aim Pose And Card UI Hotfix
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_431_fireteam_aim_pose_and_card_ui_hotfix.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_426_cautious_move_parallel_aim.md`, `docs/tasks/TASK_427_fireteam_decision_feedback_aim_pose.md`
- Stand: Aim-Hold nutzt nicht mehr den ersten Shoot-Key, sondern einen mittleren Sample-Key; Upper-Body-Shoot-Overlays werden als statische Hold-Pose gebacken.
- Stand: Fireteam-Mini-Cards werden wiederverwendet, damit C/N/A-Buttons beim Refresh nicht flackern. Loadout-Text und runder FTL-Gauge sind aus der Mini-Card entfernt; Readiness und Member-Portraits sitzen unten.
- Stand: FTL-Befehlssprechblasen ersetzen einander; #16.20 ist als `WP-`-Alias fuer Wegpunkt-/Order-Loeschen belegt.
- Risiken: Der Aim-Sample bleibt ein Workaround, bis eigene Aim-Idle-Clips vorhanden sind.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_431_fireteam_aim_pose_and_card_ui_hotfix.gd`, `scripts/tests/task_422_go_continue_fireteam_hud_cleanup.gd`, `scripts/tests/task_427_fireteam_decision_feedback_aim_pose.gd`, `scripts/tests/task_403_runtime_animation_combat_cases.gd` und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster `C -> Move -> GO` sichtpruefen: Waffen bleiben oben, C/N/A klickt ohne Flackern, und nur eine Bubble bleibt stehen.

### TASK_430 - Fireteam Task Corruption Repair
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_430_fireteam_task_corruption_repair.md`, `docs/tasks/TASK_429_fireteam_behavior_modes_runtime.md`, `docs/dev/fireteam_behavior_modes_contract.md`
- Stand: NUL-korrupte TASK_429-Dateien wurden wiederhergestellt: Security-Controller, Drill-Generator, Scenario, Reports, Contract und Verifier.
- Stand: `MissionScenarioData` und `TerrainMapData` erkennen leere/NUL-Dateien vor `JSON.parse_string()` und flushen nach dem Speichern.
- Stand: Der Drill-Generator validiert Map und Scenario direkt nach dem Schreiben; der Mission-Controller fragt fehlende Controller-Methoden defensiv ab.
- Risiken: Ein harter Rechnerabbruch kann weiterhin jede Datei treffen; ein spaeterer Atomic-Write-Pass waere robuster als nur Flush.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`, `scripts/tests/task_429_fireteam_behavior_modes_runtime.gd`, `scripts/tests/task_424_fireteam_drill_enemy_visibility_grounding.gd`, `scripts/tests/task_427_fireteam_decision_feedback_aim_pose.gd`, `scripts/tests/task_416_fireteam_command_drill_map.gd` und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster die Drillmap einmal laden und pruefen, dass kein JSON-/Security-Stacktrace mehr erscheint.

### TASK_429 - Fireteam Behavior Modes Runtime
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_429_fireteam_behavior_modes_runtime.md`, `docs/dev/fireteam_behavior_modes_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/reports/fireteam_behavior_control_checklist.html`
- Stand: `FireteamMovementController` stellt gemeinsame C/N/A-Modifikatoren fuer `Move`, `Engage`, `Take` und `Defend` bereit. Runtime-Commands tragen Speed-, Sicht-, Cover-, Attack- und Posture-Werte plus `behavior_*`-Diagnose.
- Stand: Abgeschlossene Waypoints werden entfernt; ohne Folgeauftrag startet automatisch `Defend`. `defend` blockiert nicht mehr als dauerhaft wartender Waypoint.
- Stand: Sichtbare Security nutzt `DEF 360` oder `DEF <Richtung>`. 360-Defense verteilt Mitglieder auf eigene Hauptsektoren und scannt leicht links/rechts.
- Stand: Mission-Tactical-Befehle `move`, `defend`, `take` und `engage` fallen bei Startfehlern nicht still in alte Flow-Driver-Ausfuehrung zurueck, sondern melden `BEHAVIOR ERROR`.
- Stand: Die Drillmap setzt Busch-Cover nach TASK_436 wieder als Objekt-Cover auf normalen Ground-Tiles, damit die Pflanzen nicht als Bodenersatz Luecken erzeugen.
- Risiken: Die Werte sind erste Runtime-Konstanten; spaetere Charakterbogen-/Skill-Paesse muessen explizit entscheiden, wie sie diese Faktoren skalieren.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_429_fireteam_behavior_modes_runtime.gd`, relevante TASK_421/TASK_424/TASK_425/TASK_426/TASK_427-Regressionen und `git diff --check`.
- Naechster Schritt: Im Godot-Fenster Move/Engage/Take/Defend mit C/N/A auf der Drillmap durchklicken und danach Charakterbogen-Werte einzeln pruefen.

### TASK_428 - Fireteam Behavior Control List
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_428_fireteam_behavior_control_list.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`, `docs/tasks/TASK_423_normal_move_parallel_spacing.md`, `docs/tasks/TASK_427_fireteam_decision_feedback_aim_pose.md`
- Stand: `docs/reports/fireteam_behavior_control_checklist.html` fasst als Review-Grundlage zusammen, wie `Engage`, `Take` und `Defend` in C/N/A funktionieren sollen.
- Stand: Die Liste trennt `Take` als Besitz/Kontrolle, `Engage` als Kampf ohne Besitzpflicht und `Defend` als outward Defense von Punkt/Area.
- Stand: `Flank` bleibt bewusst ausgeklammert; sichtbare Basis-Security wird als `DEF 360`/`DEF Richtung` statt `OVW` beschrieben.
- Stand: Buddy-Team-Bildung, Abstandsprinzipien, Tile-vs-Area-Unterschiede und offene Reviewfragen sind dokumentiert.
- Risiken: Die Prozentwerte wurden in TASK_429 als erste Runtime-Konstanten umgesetzt und muessen bei weiterem Balancing bewusst angepasst werden.
- Lokale Pruefung: `git diff --check`.
- Naechster Schritt: Liste im Browser gegenlesen und danach zuerst einen kleinen Contract-/Implementierungs-Task fuer `Defend` ableiten.

### TASK_427 - Fireteam Decision Feedback Aim Pose
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_427_fireteam_decision_feedback_aim_pose.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`, `docs/tasks/TASK_425_live_move_stance_update.md`, `docs/tasks/TASK_426_cautious_move_parallel_aim.md`
- Stand: `#17` und `get_command_feedback_snapshot()` zeigen einen kompakten Entscheidungsreadout wie `MOVE NE 5F C Aim`, inklusive Richtung, Distanz, Tile/Area-Kontext und Haltung.
- Stand: GO-/FTL-Bubbles koennen den tatsaechlich aktiven Folgeauftrag anzeigen, statt nur eine generische Bestaetigung auszugeben.
- Stand: Die neue HTML-Referenz `docs/reports/fireteam_command_decision_reference.html` erklaert Move/Defend/Take/Engage, C/N/A, Tile-vs-Area und OVW.
- Risiken: Die Readouts sind bewusst Feedback-/UI-Schicht und duerfen keine Gameplay-Wahrheit duplizieren oder mutieren.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_427_fireteam_decision_feedback_aim_pose.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_426_cautious_move_parallel_aim.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_425_live_move_stance_update.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_403_runtime_animation_combat_cases.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Im Godot-Fenster `C -> Move -> GO` sichtpruefen; falls die Pose trotz aktivem Render-Snapshot zu dezent wirkt, als naechsten UI-/Visual-Polish den Aim-Kontrast erhoehen.

### TASK_426 - Cautious Move Parallel Aim
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_426_cautious_move_parallel_aim.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`, `docs/tasks/TASK_423_normal_move_parallel_spacing.md`, `docs/tasks/TASK_425_live_move_stance_update.md`
- Stand: `FireteamBehaviorResolver` mappt `Move` jetzt immer auf direkten Gruppen-Travel (`rush`); `cautious` bleibt Haltung und steuert Aim/Speed/Sicht, aber erzeugt keine Hold-/Deckungsgruppe mehr.
- Stand: Explizite `bounding`-/`creep`-Profile im `FireteamMovementController` bleiben moeglich; die Aenderung betrifft den sichtbaren `Move`-Resolverpfad.
- Risiken: Aeltere Smokes, die `cautious Move` als Shortcut fuer Bounding/Caterpillar benutzt haben, sind fachlich ueberholt und brauchen spaeter einen expliziten Advance-Style-Bedienpfad.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_426_cautious_move_parallel_aim.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_421_move_stance_posture_speed_sight.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_425_live_move_stance_update.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_109_verifier.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_423_normal_move_parallel_spacing.gd` und `git diff --check` laufen gruen. Zusaetzlich ausgefuehrt: `scripts/tests/task_101_verifier.gd` faellt weiterhin auf einer alten `cohesion_threshold`-Erwartung im Flank-Fall, nicht im Move-/Cautious-Pfad.
- Naechster Schritt: Im Godot-Fenster `C -> Move -> GO` pruefen: alle vier laufen, keine `HOLD`-Labels, Waffen sichtbar im Aim.

### TASK_425 - Live Move Stance Update
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_425_live_move_stance_update.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`, `docs/tasks/TASK_423_normal_move_parallel_spacing.md`, `docs/tasks/TASK_424_fireteam_drill_enemy_visibility_grounding.md`
- Stand: `FireteamMovementController.update_tactical_stance()` schreibt C/N/A live in aktive `Move`-Executions und reissued den aktuellen Stage mit neuer Command-Revision.
- Stand: Command-Tokens enthalten jetzt `command_revision`, sodass alte requeue-Move-Commands nach einer Live-Haltungsumstellung stale werden und die neue Haltung nicht mehr ueberschreiben.
- Stand: Die Mission-UI ruft beim C/N/A-Wechsel fuer aktive Move-Executions den Runtime-Controller auf; `cautious` hebt die Waffe in Aim, `normal` setzt Travel/lowered, `aggressive` Run/lowered.
- Risiken: Die Live-Umstellung aendert nur Haltung/Speed/Sicht des aktiven Move-Stages; Advance-Style-Wechsel bleibt eine separate Befehlsentscheidung.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_425_live_move_stance_update.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_421_move_stance_posture_speed_sight.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_422_go_continue_fireteam_hud_cleanup.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_109_verifier.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_423_normal_move_parallel_spacing.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: `Move` starten, waehrend des Laufens C/N/A klicken und im Godot-Fenster Waffenhaltung sowie Geschwindigkeit sichtbar pruefen.

### TASK_424 - Fireteam Drill Enemy Visibility Grounding
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_424_fireteam_drill_enemy_visibility_grounding.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_416_fireteam_command_drill_map.md`, `docs/tasks/TASK_423_normal_move_parallel_spacing.md`
- Stand: Die Drill-Map nutzt Busch-Cover nach TASK_436 wieder als `nature_bush_cover`-Objekte auf sauberen `ground_flat`-Tiles mit Cover-Wert; `nature_deco_logs` bleiben ebenfalls auf sauberen Ground-Tiles.
- Stand: Die Objective-Flaeche nutzt keine `station_set_floor_panel`-Tiles mehr; gameplay-seitig bleibt die komplette Drill-Karte auf `height_level == 0`.
- Stand: Enemy-Proxies werden im Render-Snapshot pro Unit mit `uses_animated_character_model` und farbiger `unit_team_base_visible`-Diagnose gemeldet; die sichtbare Team-Basis macht gegnerische NPCs im Playtest besser lesbar.
- Risiken: Die Korrektur verbessert die Drill-Map und Unit-Lesbarkeit, ohne Terrain-Asset-Bedeutungen fuer andere Karten umzudeuten.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_424_fireteam_drill_enemy_visibility_grounding.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_416_fireteam_command_drill_map.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Im Godot-Fenster kurz sichtpruefen, ob die roten Enemy-Basen und flache Objective-Flaeche so lesbar sind.

### TASK_423 - Normal Move Parallel Spacing
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_423_normal_move_parallel_spacing.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_404_fireteam_movement_posture_bridge.md`, `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`, `docs/tasks/TASK_422_go_continue_fireteam_hud_cleanup.md`
- Stand: Normales `Move` erzeugt weiterhin fuer alle fitten Mitglieder parallele Rush-/Travel-Commands im selben Stage.
- Stand: Die kompakte Move-Formation nutzt jetzt stabile seitliche Zielslots mit Mindestabstand, statt mehrere Mitglieder auf praktisch denselben Zielpunkt zu ziehen.
- Stand: Die Completion-Pruefung nutzt die bereits ausgegebenen Stage-Ziele, damit die finale Formation nicht aus der aktuellen Leader-Position neu driftet.
- Risiken: Die Formation ist funktional breiter, aber noch kein finaler visueller Formation-Polish.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_423_normal_move_parallel_spacing.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_421_move_stance_posture_speed_sight.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_404_fireteam_movement_posture_bridge.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Im Godot-Fenster ein Vierer-Fireteam mit normalem `Move` auf der Drill-Karte beobachten; alle vier sollten gleichzeitig anlaufen und nicht am Zielpunkt ineinander schieben.

### TASK_422 - GO Continue Fireteam HUD Cleanup
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_422_go_continue_fireteam_hud_cleanup.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_418_fireteam_mini_card_suppression_explainer.md`, `docs/tasks/TASK_419_go_next_action_and_npc_speed.md`, `docs/tasks/TASK_420_waypoint_completion_area_followup_hotfix.md`
- Stand: `GO` erkennt einen erreichten aktiven Move-Wegpunkt als Fortsetzung, entfernt ihn aus dem Plan und aktiviert den naechsten Wegpunkt.
- Stand: Der sichtbare `PlanCommandMatrixButton` wird entfernt; Slot `16.20` bleibt Reserve. Der `#17`-Ready/Plan/SUPP-Statusblock wird nicht mehr erzeugt, waehrend C/N/A und Member-Karten erhalten bleiben.
- Stand: Die Fireteam-Mini-Karte rendert Suppression zusaetzlich als sichtbaren `MiniSuppressionBar` direkt in der Karte.
- Risiken: Der interne Return-to-Plan-Pfad bleibt fuer Ad-hoc/Suppression erhalten, ist aber bewusst nicht mehr als dauerhafter Button sichtbar.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_422_go_continue_fireteam_hud_cleanup.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_420_waypoint_completion_area_followup_hotfix.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_418_fireteam_mini_card_suppression_explainer.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_419_go_next_action_and_npc_speed.gd`, `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_fire_sector_overlay.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Im Godot-Fenster `Move -> Move` per GO und die Mini-Karten-SUPP-Bar bei Kontakt einmal sichtbar pruefen.

### TASK_421 - Move Stance Posture Speed Sight
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_404_fireteam_movement_posture_bridge.md`, `docs/tasks/TASK_419_go_next_action_and_npc_speed.md`, `docs/tasks/TASK_420_waypoint_completion_area_followup_hotfix.md`
- Stand: `FireteamMovementController` setzt fuer `Move` jetzt die C/N/A-Haltung auf Command-Ebene: cautious = `aimed`, Speed x0.65, Sicht x1.2; normal = `travel`/`lowered`, Speed x1.0, Sicht x1.0; aggressive = `run`/`lowered`, Speed x1.2, Sicht x0.65.
- Stand: `UnitCommand`, `UnitRuntimeStatus`, `TestUnit`, `SimulationRoot`-Snapshots und `TerrainMap3DView` geben `sight_range_factor` weiter. Fog-of-War nutzt den Faktor pro Observer fuer Tile- und Dynamic-Target-Sichtbarkeit.
- Risiken: `run` ist ein Runtime-/Diagnose-Posture und faellt visuell auf vorhandene Run-/Walk-Clips zurueck, falls fuer ein Asset kein eigener Run-Clip existiert. Waffen-/Combat-Reichweiten bleiben unveraendert.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_421_move_stance_posture_speed_sight.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_404_fireteam_movement_posture_bridge.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_420_waypoint_completion_area_followup_hotfix.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_419_go_next_action_and_npc_speed.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Im Godot-Fenster die Drill-Karte mit Move cautious/normal/aggressive einmal sichtbar durchspielen und auf FOW-/Kontaktwirkung achten.

### TASK_420 - Waypoint Completion Area Followup Hotfix
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_420_waypoint_completion_area_followup_hotfix.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_417_fireteam_waypoint_completion_cleanup.md`, `docs/tasks/TASK_419_go_next_action_and_npc_speed.md`
- Stand: Der letzte abgeschlossene Waypoint entfernt jetzt auch den leeren Plan-Eintrag aus `_order_plans_by_key`.
- Stand: Wenn nach dem letzten Waypoint eine AreaOrder wartet, startet der Controller zuerst Defend-/Attack-AreaOrder und faellt erst danach auf Default-Hold zurueck.
- Risiken: Die gemischte Reihenfolge bleibt weiterhin implizit: Waypoints werden zuerst abgearbeitet, anschliessend pending AreaOrders. Eine explizite gemischte Queue bleibt ein separater UI-/Datenmodell-Task.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_420_waypoint_completion_area_followup_hotfix.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_417_fireteam_waypoint_completion_cleanup.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_419_go_next_action_and_npc_speed.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Im Godot-Fenster `Move -> Move` und `Move -> Defend Area` auf der Drill-Karte einmal sichtbar durchspielen.

### TASK_419 - GO Recovery Action And NPC Speed
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_419_go_next_action_and_npc_speed.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/tasks/TASK_417_fireteam_waypoint_completion_cleanup.md`, `docs/tasks/TASK_418_fireteam_mini_card_suppression_explainer.md`
- Stand: `GO` erkennt jetzt Recovery-Kontexte aus Ad-hoc-Ausfuehrung, Suppression-Interrupt und unterbrochenem Plan und ruft Return-to-Plan ohne sichtbaren `Plan`-Button auf.
- Stand: Gepinnte oder suppressed Fireteams werden nicht zwangsweise per GO in den Plan zurueckgeschoben; der Command-Text meldet `PINNED`.
- Stand: `SimulationRoot.MOVE_SPEED_PER_SECOND` liegt bei `80.0` statt `120.0`, sodass normale NPC-Move-Commands ein Drittel langsamer laufen. Fireteam-Stil-Multiplikatoren bleiben unveraendert.
- Risiken: Der `Plan`-Button bleibt vorerst als Fallback sichtbar. Ein manueller Godot-Fenster-Check sollte bestaetigen, dass GO-Recovery, Mini-Karte und Wegpunkt-Loeschung im Playtest zusammen rund wirken.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_419_go_next_action_and_npc_speed.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_418_fireteam_mini_card_suppression_explainer.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_417_fireteam_waypoint_completion_cleanup.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Im echten Godot-Fenster ein Fireteam unterbrechen, GO druecken und pruefen, dass Recovery nur bei nicht gepinntem Team startet.

### TASK_418 - Fireteam Mini Card Suppression Explainer
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_418_fireteam_mini_card_suppression_explainer.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/tasks/TASK_416_fireteam_command_drill_map.md`, `docs/tasks/TASK_417_fireteam_waypoint_completion_cleanup.md`
- Stand: Die Fireteam-Mini-Karte oben links zeigt Suppression jetzt als kompaktes `SUPP xx%` in der Statuszeile und als kleinen Balken direkt auf der Karte.
- Stand: `get_fireteam_status_card_snapshot()` meldet Suppression-Wert, Schwelle, Prozent, Status und read-only Kontext. Die Anzeige liest `_suppression_state_by_fireteam` und erzeugt keine neue Gameplay-Wahrheit.
- Stand: `docs/reports/fireteam_mini_card_explainer.html` zeigt ein schematisches Abbild der Fireteam-Mini-Karte und erklaert Member-Chips, FTL-Readiness, Stance, SUPP, GO und den aktuellen `Plan`-Button als Return-/Recovery-Funktion.
- Risiken: Die Mini-Karte bleibt bewusst kompakt. Ein manueller Godot-Fenster-Check bleibt sinnvoll, um Clipping bei mehreren Fireteams zu pruefen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_418_fireteam_mini_card_suppression_explainer.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_369_fireteam_status_card_enhancement.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_417_fireteam_waypoint_completion_cleanup.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Im echten Godot-Fenster die Mini-Karte mit Kontakt/Suppression pruefen; danach entscheiden, ob `Plan` als sichtbarer Button in `Return` umbenannt oder nur bei Recovery sichtbar wird.

### TASK_417 - Fireteam Waypoint Completion Cleanup
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_417_fireteam_waypoint_completion_cleanup.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_415_fireteam_runtime_execution_path_switch.md`, `docs/tasks/TASK_416_fireteam_command_drill_map.md`
- Stand: Der Mission-Tactical-Pfad entfernt einen erreichten und ausgefuehrten Waypoint jetzt aus `FireteamOrderPlan.waypoints`, statt ihn nur als `completed` im Plan stehen zu lassen.
- Stand: Die Folgeaktivierung nutzt nach dem Entfernen den verschobenen Waypoint-Index. Leere Plaene werden abgeschlossen und nicht mehr in Order-Visuals serialisiert.
- Stand: Die bestehende Defend-/Hold-Freigabe per GO bleibt erhalten; beim Freigeben wird der gehaltene Waypoint entfernt, bevor der naechste Waypoint startet oder der Plan abgeschlossen wird.
- Risiken: Der Headless-Verifier prueft Planliste, Indexverschiebung und Snapshot-Serialisierung. Ein manueller Godot-Fenster-Check bleibt sinnvoll, um Marker, Linien und Command-Bubbles visuell zu bestaetigen.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_417_fireteam_waypoint_completion_cleanup.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_416_fireteam_command_drill_map.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_415_fireteam_runtime_path_switch.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Im echten Godot-Fenster auf der Drill-Karte zwei Move-Waypoints setzen und pruefen, dass der erste Marker beim Abschluss verschwindet und der zweite sofort weiterlaeuft.

### TASK_416 - Fireteam Command Drill Map
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_416_fireteam_command_drill_map.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/commander_fireteam_delegation_contract.md`, `docs/dev/multi_fireteam_plan_contract.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_404_fireteam_movement_posture_bridge.md`, `docs/tasks/TASK_415_fireteam_runtime_execution_path_switch.md`
- Stand: `maps/fireteam_command_drill_24x24.json` ist eine kleine 24x24-Drill-Karte mit Spawn, offener Move-Lane, Defend-/Rally-Area, Contact-Line, Nord-/Sued-Flank-Alternativen, Objective und einer gegnerischen Fireteam-Position.
- Stand: `data/mission_scenarios/fireteam_command_drill_24x24.json` validiert mit genau einem gegnerischen Fireteam zu vier Units. `scenes/tests/fireteam_command_drill_map.tscn` startet dazu ein Friendly-Fireteam `drill` mit vier Mitgliedern.
- Stand: `docs/reports/fireteam_command_drill_decision_guide.html` erklaert, wann Move/Rush, Bounding, Caterpillar, Defend, Flank und Take/Engage zu welchen Entscheidungen fuehren und welche Alternativen zum Testen sinnvoll sind.
- Stand: Der Meta-Missionskatalog enthaelt `Operation: Fireteam Command Drill` mit vier Slots und dem neuen Szenario.
- Risiken: Die Fixture ist ein reproduzierbarer Drill- und Sichtcheck, kein Balancing-Nachweis. Gegnerverhalten bleibt bewusst beim bestehenden Enemy-Team-Tactics-Pfad.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_416_fireteam_command_drill_map.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_415_fireteam_runtime_path_switch.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Im echten Godot-Fenster die Szene starten und Move normal/aggressiv, Move vorsichtig, Defend Area, Flank Nord/Sued und Take Objective einmal visuell durchspielen.

### TASK_415 - Fireteam Runtime Execution Path Switch
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_415_fireteam_runtime_execution_path_switch.md`, `docs/dev/fireteam_runtime_execution_path_contract.md`, `docs/dev/commander_fireteam_delegation_contract.md`, `docs/dev/multi_fireteam_plan_contract.md`, `docs/dev/fireteam_leader_tactical_progression.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_404_fireteam_movement_posture_bridge.md`, `docs/tasks/TASK_414_fireteam_overview_html.md`
- Stand: Der sichtbare Fireteam-Ausfuehrungspfad ist jetzt als Mission-Tactical-Pfad festgelegt: `MissionTacticalSandboxController` verwaltet Auswahl, Waypoints, AreaOrders und Phasen; taktische Resolver liefern Profil/Plan; `FireteamMovementController` erzeugt pro Mitglied `UnitCommand`-Dictionaries; `SimulationRoot.enqueue_command()` bleibt die autoritative Queue.
- Stand: `FireteamRuntimeExecutionPathContract` liefert den maschinenlesbaren Contract mit `active_path_id = mission_tactical`, `legacy_policy = compatibility_adapter_only`, `runtime_authority = SimulationRoot`, `ui_sets_unit_truth = false` und `snapshots_are_truth = false`.
- Stand: `MissionTacticalSandboxController.get_fireteam_runtime_execution_path_snapshot()` ist der neue Headless-Pruefpunkt fuer den aktiven Pfad und meldet zusaetzlich Auswahl-, Plan-, AreaOrder- und Execution-Zaehler.
- Risiken: `MissionTacticalSandboxController` liegt historisch noch unter `scripts/tests`. Fuer groesseren Runtime-Ausbau bleibt die Extraktion in einen Produktionspfad offen; `RuntimeLeader`/`FTLTask` wird nicht geloescht, sondern vorerst auf Compatibility/Adapter/Basistests begrenzt.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_415_fireteam_runtime_path_switch.gd`, `godot_console.exe --headless --path . --script scripts/tests/task_404_fireteam_movement_posture_bridge.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Naechste Fireteam-Gameplay-Slices direkt am Mission-Tactical-Pfad anhaengen und erst vor groesserem Ausbau den Controller aus `scripts/tests` herausziehen.

### TASK_414 - Fireteam Overview HTML
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_414_fireteam_overview_html.md`, `docs/dev/commander_fireteam_delegation_contract.md`, `docs/dev/multi_fireteam_plan_contract.md`, `docs/dev/fireteam_leader_tactical_progression.md`, `docs/dev/mission_command_feedback_contract.md`, `docs/tasks/TASK_404_fireteam_movement_posture_bridge.md`
- Stand: `docs/reports/fireteam_overview.html` dokumentiert den aktuellen Fireteam-Datenfluss ueber Meta-Staging, Mission-HUD, taktische Resolver und Runtime. Die Uebersicht trennt den Legacy-`RuntimeLeader`/`FTLTask`-Pfad vom aktuellen Mission-Tactical-Pfad ueber `FireteamMovementController` und `SimulationRoot`.
- Stand: Die HTML nennt konkrete Informationsquellen fuer Fireteam-Zuordnung, Definitionen, Lead/FTL, Loadout, Dropship-Payload, Mission-Auswahl, Readiness, Bewegung, Security und Runtime-Unit-State.
- Risiken: Die Datei ist eine Bestandsaufnahme, kein neuer Contract. Auffaellig bleiben Fireteam-ID/Team-ID-Ueberlagerungen in alten FTL-Pfaden und Mission-HUD-Abfragen ueber Friendly-Node-Sammlungen.
- Lokale Pruefung: `Get-Item docs/reports/fireteam_overview.html`, `Select-String -Path docs/reports/fireteam_overview.html -Pattern "<!doctype html>","Fireteam Ueberblick","Informationsquellen"` und `git diff --check` laufen gruen.
- Naechster Schritt: Beim eigentlichen Fireteam-Refactor zuerst entscheiden, ob der sichtbare Mission-Pfad staerker an `RuntimeLeader`/`FTLRegistry` angebunden oder bewusst als taktischer Controller-Pfad dokumentiert bleibt.

### TASK_413 - Terrain Theme Packs und Ground Mission 128
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_413_terrain_theme_packs_ground_mission_variant.md`, `docs/dev/terrain_height_hill_rules.md`, `docs/dev/nature_terrain_prop_rules.md`, `docs/tasks/TASK_412_large_map_streaming_and_incremental_hpa.md`, `docs/performance/large_map_scale_profile_report.md`
- Stand: `TerrainMapData` laedt und speichert jetzt eine optionale `terrain_visual_theme_id`. Alte Maps ohne Theme-ID bleiben auf der bisherigen Root-Default-Surface-Zuordnung und veraendern ihr Bodenbild nicht automatisch.
- Stand: `TerrainMap3DView` liest die Map-Theme-ID nur fuer visuelle Surface-/Tile-Modellaufloesung. Der Render-Snapshot meldet `terrain_visual_theme_id`, ob ein Theme aktiv ist und wie viele Theme-Packs im Katalog vorhanden sind. Gameplay-Wahrheit bleibt bei `surface_type`, `height_level`, `edge_type`, `object_type_id`, Cover, LOS und Walkability.
- Stand: `terrain_surface_visual_theme_catalog.json` enthaelt jetzt explizite Theme-Packs: `space_default_v1`, `nature_classic_dirt_v1` und `ground_mission_mixed_v1`. Die bestehende Root-Zuordnung bleibt fuer Kompatibilitaet auf `ground_flat`.
- Stand: `Ground_Mission02_128x128.json` ist als erste grosse Content-Map erzeugt: 16384 Tiles, Nature-Boden-Theme, Roads, H1/H2-Hoeheninseln, Slopes/Cliffs, Station-/Modular-Zielbereich, Nature-Cover-Props, Space-Kit-Turrets, Patrol-Routen und Ground-Mission-aehnliche Markerstruktur.
- Stand: `ground_mission02_128x128` definiert drei feindliche Gruppen zu je vier NPCs inklusive Patrol-, Defense- und Air-Defense-Team mit `watch_warning`-Air-Asset-Risk.
- Risiken: Die 128x128-Karte ist headless strukturell gruen, braucht aber noch einen manuellen Godot-Fenster-Sichtcheck fuer Lesbarkeit, Framing, Materialwirkung und Interaktion. 256x256 bleibt weiterhin nicht als voll sichtbare Content-Map freigegeben.
- Lokale Pruefung: `generate_ground_mission02_128x128.gd`, `task_413_terrain_theme_packs_ground_mission_variant.gd`, `task_253_nature_ground_surface_editor_palette_pass.gd`, `task_255_nature_kit_hill_playability_visual_performance_smoke.gd`, `task_412_large_map_streaming_incremental_hpa.gd`, `task_344_ground_mission_default_enemy_visuals.gd`, `task_407_static_tile_visual_batching_completion.gd`, `task_408_static_nature_prop_multimesh_batching.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Ground Mission 02 im echten Fenster starten, Kamera/Overlays/LZ-Setzen auf 128x128 pruefen und erst danach die Karte als Playtest-Default verdrahten.

### TASK_412 - Large Map Streaming und inkrementelles HPA
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_412_large_map_streaming_and_incremental_hpa.md`, `docs/tasks/TASK_411_large_map_scale_profile.md`, `docs/performance/large_map_scale_profile_report.md`, `docs/performance/navigation_pathfinding_los_profile_report.md`
- Stand: `TerrainMap3DView` aktiviert fuer Karten oberhalb von 4096 Tiles automatisch Visual-Streaming. Die MapData-/Registry-Wahrheit bleibt vollstaendig; gerendert werden nur aktive 8x8-Chunk-Fenster um den Kamerafokus.
- Stand: Render-Snapshots unterscheiden jetzt `total_tile_count` und `rendered_tile_count` und melden `visual_streaming_active`, Chunk-Groesse, Radius, aktive Chunks, uebersprungene Tiles und Streaming-Refreshes. Kamera-Fokuswechsel ueber Chunk-Grenzen queued einen gezielten Visual-Refresh.
- Stand: `TerrainRegistry` trackt Dirty-Grids neben der Revision. `HPANavigationGraph.rebuild_dirty_clusters_from_registry()` repariert geaenderte Cluster plus angrenzende Portal-Cluster, reindiziert Portale und meldet `incremental`, Dirty-/Rebuild-Clusterzahlen und Portal-/Komponentenwerte.
- Stand: `SimulationRoot` nutzt bei gleicher Registry und gleicher Tile-Anzahl den bestehenden HPA-Graphen fuer Dirty-Cluster-Rebuilds statt einen neuen Full-Graphen zu erzeugen. Die Runtime-Diagnose markiert `runtime_rebuild_mode` als `full` oder `incremental`.
- Risiken: Visual-Streaming ist ein Headless-/Struktur-Gate, kein Ersatz fuer den manuellen Godot-Profiler im echten Fenster. 256x256 bleibt als komplett aktive Vollansicht erst nach Fenster-/Viewport-Sichtcheck freigegeben.
- Lokale Pruefung: `task_412_large_map_streaming_incremental_hpa.gd`, `task_410_hpa_profile_visibility_and_registry_revision.gd`, `task_411_large_map_scale_profile.gd`, `task_409_terrain_registry_lookup_hpa_audit.gd`, `task_405_terrain_ground_multimesh_batching.gd`, `task_407_static_tile_visual_batching_completion.gd`, `task_408_static_nature_prop_multimesh_batching.gd`, `task_216_2_5d_rendering_node_draw_budget_pass.gd` und `task_217_navigation_pathfinding_los_performance_pass.gd` laufen gruen.
- Naechster Schritt: 128x128 im echten Godot-Fenster als grosse Playtest-Karte pruefen; danach 256x256 mit aktivem Streaming und Visual-Profiler gegen Draw Calls, Materials, Labels und Editor-Interaktion messen.

### TASK_411 - Large Map Scale Profile 128 und 256
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_411_large_map_scale_profile.md`, `docs/performance/large_map_scale_profile_report.md`, `docs/tasks/TASK_407_static_tile_visual_batching_completion.md`, `docs/tasks/TASK_408_static_nature_prop_multimesh_batching.md`, `docs/tasks/TASK_410_hpa_profile_visibility_and_registry_revision.md`
- Stand: `task_411_large_map_scale_profile.gd` erzeugt 128x128- und 256x256-Profilkarten in-memory mit Surface-Mix, Hoeheninseln, Slopes/Cliffs, Nature-Props, Station-/Modular-Zonen, FoW und einer kurzen Runtime-Unit-Navigation.
- Stand: Die Logikprofile sind gruen: 128x128 meldet 16384 Tiles, 256 HPA-Cluster und 10506 Portale; 256x256 meldet 65536 Tiles, 1024 HPA-Cluster und 43308 Portale. FoW scannt beide Groessen vollstaendig und Runtime-Navigation spiegelt HPA-Diagnosen im `SimulationRoot`.
- Stand: Der erste Full-Render-Probe fuer 256x256 lief in den 10-Minuten-Headless-Timeout. Der automatisierte TASK_411-Gate laesst grosse Full-Render-Karten deshalb bewusst aus und dokumentiert 64x64 als aktuell voll gerenderten sicheren Automationsbereich. 128x128/256x256 gelten damit logisch als erreichbar, aber noch nicht als voll gerenderte Produktionskarten.
- Stand: `HPANavigationGraph` sortiert Portale jetzt einmal nach dem Portal-Build und sortiert anschliessend Portal-Buckets, statt die komplette Portal-Liste bei jedem Insert neu zu sortieren. Dadurch laufen 128/256-HPA-Builds in Sekunden statt in den Timeout.
- Risiken: 256x256 braucht fuer echte Missionen weiterhin Viewport-/Editor-Profiling, sicht-/kameranahe Chunk-Aktivierung oder Streaming. Der neue Test ist ein gezielter Heavy-Smoke und kein schneller Standard-Regressionstest.
- Lokale Pruefung: `task_411_large_map_scale_profile.gd`, `task_410_hpa_profile_visibility_and_registry_revision.gd`, `task_126_verifier.gd`, `task_409_terrain_registry_lookup_hpa_audit.gd`, `task_217_navigation_pathfinding_los_performance_pass.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: 128x128 als erste grosse Playtest-Zielkarte nutzen; 256x256 erst nach Renderer-/Editor-Chunking oder manuellem Visual-Profiler-Lauf fuer voll aktive Missionen freigeben.

### TASK_410 - HPA Profile Visibility und Registry Revision
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_410_hpa_profile_visibility_and_registry_revision.md`, `docs/tasks/TASK_409_terrain_registry_lookup_hpa_audit.md`, `docs/tasks/TASK_217_navigation_pathfinding_los_performance_pass.md`, `docs/performance/navigation_pathfinding_los_profile_report.md`
- Stand: `TerrainRegistry` fuehrt jetzt eine monotone Revision und stellt `notify_tile_data_changed()` fuer explizite in-place Terrain-Aenderungen bereit. `SimulationRoot` cached HPA-Graphen nach Registry, Tile-Anzahl und Registry-Revision statt nur nach Tile-Anzahl.
- Stand: `get_navigation_debug_snapshot()` spiegelt HPA-Diagnosen unter `hpa_navigation`: Graph-Verfuegbarkeit, Cluster-Groesse, Tile-Anzahl, Registry-Revision, Build-Count, Cache-Hits und die letzten Graph-Build-Stats.
- Stand: `navigation_benchmark_harness.gd` meldet pro Profilkarte `hpa_graph_build_stats`, und die Summary markiert `has_hpa_build_stats`. Die 64x64-Profilkarten belegen weiterhin 4096 Tiles und 64 HPA-Cluster.
- Stand: Der TASK_410-Verifier haelt fest, dass `map_editor.gd` keinen eigenen HPA-Full-Rebuild-Pfad besitzt. HPA-Kosten werden damit aktuell im Runtime-/Benchmark-Pfad gemessen, nicht im Editor-Painting.
- Risiken: TASK_412 baut auf diesem Invalidierungs- und Diagnoseanker auf und ergaenzt Dirty-Cluster-Rebuilds. Editor-Painting braucht weiterhin einen echten Sicht-/Profilerlauf, falls grosse Authoring-Sessions stocken.
- Lokale Pruefung: `task_410_hpa_profile_visibility_and_registry_revision.gd`, `task_409_terrain_registry_lookup_hpa_audit.gd`, `task_126_verifier.gd`, `task_184_gameplay_hill_semantics_verifier.gd`, `task_131_verifier.gd`, `task_217_navigation_pathfinding_los_performance_pass.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Dirty-Cluster-Rebuilds mit grossen Editor-Paint-Strokes beobachten und nur bei Bedarf weiter in echte Tile-/Portal-Micro-Patches zerlegen.

### TASK_409 - TerrainRegistry Lookup und HPA Build Audit
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_409_terrain_registry_lookup_hpa_audit.md`, `docs/tasks/TASK_126_hpa_navigation_foundation.md`, `docs/tasks/TASK_127_hpa_pathfinder_integration.md`, `docs/tasks/TASK_184_gameplay_hill_semantics_patch.md`
- Stand: `TerrainRegistry` fuehrt jetzt einen Tile-ID-Index, entfernt ersetzte Grid-Eintraege beim Re-Register und faellt bei in-place geaenderten Tile-IDs sauber auf den Live-Registry-Scan zurueck.
- Stand: `get_nearest_walkable_grid()` behaelt das deterministische Distanz-/Grid-Tie-Breaking, sortiert aber nicht mehr pro Anfrage die komplette Tile-Liste. `get_sorted_tiles()` nutzt einen invalidierten Cache und gibt Kopien aus, damit Aufrufer den internen Cache nicht veraendern.
- Stand: `HPANavigationGraph` speichert pro Build Diagnosewerte fuer Erfolg, Cluster-Groesse, Tile-, Cluster-, Komponenten- und Portalanzahl sowie Build-Dauer. Der neue Verifier belegt fuer 64x64 bei 8x8-Clustern 4096 Tiles und 64 Cluster.
- Risiken: Die nearest-walkable-Suche ist weiterhin ein exakter linearer Scan ueber aktuelle Tiles. Das entfernt die Sortierkosten, ersetzt aber noch keinen spatial nearest-neighbor Index. HPA ist weiterhin Full-Rebuild; die neuen Stats sind die Messbasis fuer einen spaeteren inkrementellen Editor-Task.
- Lokale Pruefung: `task_409_terrain_registry_lookup_hpa_audit.gd`, `task_126_verifier.gd`, `task_184_gameplay_hill_semantics_verifier.gd`, `task_125_verifier.gd`, `task_224_fog_of_war_tile_visibility_height_cover_runtime.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: HPA-Build-Stats in einem Editor-/grossen-Karten-Profilinglauf beobachten; inkrementelle Cluster-Rebuilds erst bauen, wenn der Full-Rebuild dort messbar stoert.

### TASK_408 - Static Nature Prop MultiMesh Batching
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_408_static_nature_prop_multimesh_batching.md`, `docs/tasks/TASK_254_nature_trees_rocks_vegetation_cover_props.md`, `docs/tasks/TASK_294_nature_prop_scale_cover_visibility_repair.md`, `docs/tasks/TASK_407_static_tile_visual_batching_completion.md`, `docs/performance/2_5d_rendering_profile_report.md`, `docs/dev/nature_terrain_prop_rules.md`
- Stand: `TerrainMap3DView` batcht jetzt die fuenf sicheren Nature-Prop-Typen (`nature_tree_blocker`, `nature_rock_cover`, `nature_bush_cover`, `nature_cactus_cover`, `nature_deco_logs`) pro Modell, Rotation und 8x8-Karten-Chunk als `MultiMeshInstance3D`.
- Stand: Die Gameplay-Wahrheit bleibt unveraendert in `TerrainTileData` und `TerrainRegistry`. `nature_prop_model_count`, Rollenverteilung und `nature_prop_visual_entries` bleiben Coverage-/Diagnosedaten pro Prop; neue Snapshot-Zaehler `static_prop_individual_model_count`, `static_prop_multimesh_instance_count` und `static_prop_multimesh_model_count` trennen Batch- und Einzelmodellpfade.
- Stand: Wände, Struktur-Layer, Space-Station-Interieur, Fahrzeuge, Units, Dropships, Skeletons, Labels und UI bleiben bewusst im bestehenden Pfad. Nicht freigegebene oder nicht eindeutig extrahierbare Objektmodelle werden nicht pauschal gebatcht.
- Risiken: MultiMesh reduziert Node-/Instance-Druck fuer prop-dichte Nature-Karten, ersetzt aber keinen echten Godot-Profiler-Lauf auf sehr grossen Karten. Weitere Objektklassen brauchen eigene Sicht-/Interaktionspruefung, weil einige Tests und Editor-Workflows konkrete Einzelobjekt-Nodes erwarten.
- Lokale Pruefung: `task_408_static_nature_prop_multimesh_batching.gd`, `task_254_nature_trees_rocks_vegetation_cover_props.gd`, `task_294_nature_prop_scale_cover_visibility_repair.gd`, `task_255_nature_kit_hill_playability_visual_performance_smoke.gd`, `task_216_2_5d_rendering_node_draw_budget_pass.gd`, `task_298_editor_terrain_visual_playability_smoke.gd`, `task_407_static_tile_visual_batching_completion.gd`, `task_185_hill_visuals_edge_lines_verifier.gd` und `bugfix_map_editor_station_floor_structure_undo.gd` laufen gruen.
- Offener Hinweis: Der alte breite `task_159_verifier.gd` ist als Batching-Gate nicht mehr aktuell; er sucht teilweise konkrete Ground-Einzel-Nodes und meldet zusaetzlich bestehende Unit-/Dropship-Ausrichtungschecks rot. Die aktuellen spezialisierten Render-/Batching-Gates sind fuer diesen Arbeitsstand massgeblich.
- Naechster Schritt: Falls weitere Objektklassen gebatcht werden sollen, zuerst pro Klasse pruefen, ob Editor-Interaktion, Rotation, Materialpfad und Tests ohne Einzelnode-Abhaengigkeit funktionieren.

### TASK_407 - Static Tile Visual Batching Completion
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_407_static_tile_visual_batching_completion.md`, `docs/tasks/TASK_405_terrain_ground_multimesh_batching.md`, `docs/tasks/TASK_216_2_5d_rendering_node_draw_budget_pass.md`, `docs/tasks/TASK_255_nature_kit_hill_playability_visual_performance_smoke.md`, `docs/tasks/TASK_298_editor_terrain_visual_playability_smoke.md`, `docs/performance/2_5d_rendering_profile_report.md`, `docs/dev/terrain_height_hill_rules.md`, `docs/dev/editor_terrain_visual_recovery_contract.md`
- Stand: `TerrainMap3DView` batcht jetzt die sicheren statischen Tile-Layer: Space-/Nature-Ground, Space-Station-Floor, Modular-Floor inklusive `modular_floor_raised`, Surface-Tints und Single-Mesh-Height-Edges. Die Batches werden pro Modell, Material bzw. Surface-Farbe und 8x8-Karten-Chunk als `MultiMeshInstance3D` gerendert.
- Stand: Coverage-Zaehler bleiben fachlich pro Tile/Edge erhalten (`ground_mesh_count`, `surface_tint_count`, `height_edge_model_count`, `asset_model_count`). Neue Snapshot-Zaehler trennen gebatchte Tiles/Edges von Einzelmodell-Fallbacks: `ground_individual_model_count`, `ground_multimesh_instance_count`, `ground_multimesh_tile_count`, `surface_tint_multimesh_instance_count`, `surface_tint_batched_tile_count`, `height_edge_individual_model_count`, `height_edge_multimesh_instance_count` und `height_edge_multimesh_model_count`.
- Stand: Height-Edges und Surface-Tints behalten ihre Diagnoseeintraege (`height_edge_visual_entries`, `surface_tint_visual_entries`), damit Anchor-, Hoehen- und Surface-Verifier nicht mehr an Einzelnode-Namen haengen. Nicht eindeutig extrahierbare Height-Edge-Modelle fallen weiter auf den alten Einzelmodellpfad zurueck.
- Stand: Render-Budget-Zaehler beruecksichtigen Materialien von `MultiMeshInstance3D`; TASK_216 und die neuen TASK_407-Smokes pruefen, dass Ground-/Tint-/Height-Edge-Coverage im Budget sichtbar bleibt.
- Risiken: MultiMesh senkt Node-/Instance-Druck, ersetzt aber keinen spaeteren echten Godot-Profiler-Lauf fuer sehr grosse Karten und Material-/Culling-Verhalten. Props, Units, Labels, UI, Skeletons und komplexe mehrteilige Objekte bleiben bewusst ausserhalb dieses Tile-Batching-Slices.
- Lokale Pruefung: `task_407_static_tile_visual_batching_completion.gd`, `task_405_terrain_ground_multimesh_batching.gd`, `task_216_2_5d_rendering_node_draw_budget_pass.gd`, `task_255_nature_kit_hill_playability_visual_performance_smoke.gd`, `task_298_editor_terrain_visual_playability_smoke.gd`, `task_185_hill_visuals_edge_lines_verifier.gd`, `task_253_nature_ground_surface_editor_palette_pass.gd`, `task_296_map_editor_palette_taxonomy_space_station_assets.gd`, `bugfix_map_editor_station_floor_structure_undo.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Wenn groessere Karten kommen, mit echtem Godot-Profiler Chunk-Groesse, Materialvielfalt und verbleibende Prop-/Objekt-Hotspots messen, statt weitere Objektklassen pauschal zu batchen.

### TASK_405 - Terrain Ground MultiMesh Batching
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_405_terrain_ground_multimesh_batching.md`, `docs/tasks/TASK_216_2_5d_rendering_node_draw_budget_pass.md`, `docs/tasks/TASK_255_nature_kit_hill_playability_visual_performance_smoke.md`, `docs/performance/2_5d_rendering_profile_report.md`, `docs/dev/terrain_height_hill_rules.md`, `docs/dev/editor_terrain_visual_recovery_contract.md`
- Stand: `TerrainMap3DView` sammelt batchbare Ground-Modelle pro Modell, Material, Rotation und 8x8-Karten-Chunk und rendert sie als `MultiMeshInstance3D`. Der bestehende Einzelmodellpfad bleibt als Fallback fuer komplexe oder nicht eindeutig batchbare Ground-Assets erhalten.
- Stand: `ground_mesh_count` bleibt als per-Tile-Ground-Coverage bestehen. Neue Snapshot-Zaehler melden `ground_individual_model_count`, `ground_multimesh_instance_count` und `ground_multimesh_tile_count`, damit Performance-Gates nicht mehr Ground-Coverage mit Einzel-MeshInstances verwechseln.
- Stand: Space-Kit-`ground_flat` sowie die vorhandenen Nature-Ground-Modelle (`nature_ground_dirt`, `nature_ground_grass_patch`, `nature_ground_dirt_river_tile`) koennen gebatcht werden. Surface-Visual-Entries und Nature-Ground-Zaehler bleiben pro Tile erhalten; Gameplay-, Hoehen-, LOS-, Cover- und Walkability-Daten werden nicht veraendert.
- Stand: Der Render-Budget-Zaehler erfasst Materialien von `MultiMeshInstance3D`, und TASK_216 prueft jetzt, dass Ground-Coverage ueber Einzelmodelle plus MultiMesh-Tiles abgedeckt ist.
- Risiken: Station-/Modular-Floor-Bodenvarianten bleiben in diesem Slice bewusst ungebatcht, weil ihre Material-, Rotation- und Mehrmesh-Faelle einen eigenen Sicht-/Asset-Pass brauchen. Die dauerhafte Kit-Entscheidung fuer Desert/Nature/Prototype-Boden bleibt ein separater Theming-Task.
- Lokale Pruefung: `task_405_terrain_ground_multimesh_batching.gd`, `task_216_2_5d_rendering_node_draw_budget_pass.gd`, `task_255_nature_kit_hill_playability_visual_performance_smoke.gd`, `task_298_editor_terrain_visual_playability_smoke.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Asset-Theming-Plan schneiden: Default-Ground, Nature-/Prototype-/Desert-Hoehenbloecke, Station-/SpaceKit-Sonderassets und weiteres Batching fuer Height-Edges/Props getrennt bewerten.

### TASK_406 - Mission LZ Click Input Guard
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_406_mission_lz_click_input_guard.md`, `docs/tasks/TASK_311_dropship_lz_target_pick_accuracy_contract.md`, `docs/tasks/TASK_312_dropship_command_matrix_lz_go_layout.md`, `docs/tasks/TASK_313_dropship_arrival_visibility_feedback_smoke.md`, `docs/tasks/TASK_394_per_craft_shipcard_commands.md`, `docs/tasks/TASK_395_manual_dropship_parallel_flow.md`, `docs/tasks/TASK_396_mission_dropship_lz_drop_hotfix.md`
- Stand: Der Mission-Input-Guard prueft Pointer-over-Control jetzt gegen die konkrete Klickposition. Stale Hover-Control-Zustand oder ein vorheriger LZ-Button-Hover blockiert damit keinen Kartenklick mehr.
- Stand: LZ- und Target-Pick werden im linken Klickpfad vor normaler Selection/Waypoint-Logik behandelt, bleiben aber blockiert, wenn der Klick wirklich ueber einem UI-Control liegt. Die Planning-/Per-Craft-Dropship-Wahrheit bleibt unveraendert.
- Stand: `task_406_mission_lz_click_input_guard.gd` deckt den echten `_unhandled_input()`-Pfad ab: Card-LZ armt Placement, ein Klick auf ein Primary3DView-Tile setzt scalar LZ-State und speichert die LZ am ausgewaehlten Dropship-Card-State.
- Risiken: Headless kann echte Maus-Hover-Zustaende nur naeherungsweise abbilden; der Fix ist deshalb bewusst klein und positionsbasiert.
- Lokale Pruefung: `task_406_mission_lz_click_input_guard.gd`, `task_394_per_craft_shipcard_commands.gd`, `task_395_manual_dropship_parallel_flow.gd`, `task_396_mission_dropship_lz_drop_hotfix.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Manueller Mission-Sichtcheck: Dropship-Card `LZ` anklicken, Karte anklicken, Marker muss stehenbleiben und `Drop` aktiv werden.

### TASK_403 - Runtime-NPC-Animationen und Kampf-Cases
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_403_runtime_animation_combat_cases.md`, `docs/dev/unit_facing_visual_contract.md`, `data/npc_unit_visual_mapping.json`
- Stand: `TerrainMap3DView` laedt fuer Runtime-Unit-Proxies die importierten Animated-Characters-Rohclips aus dem Visual-Mapping und baut die sechs `animation_combat_cases` in denselben `UnitVisualAnimationPlayer`.
- Stand: `walkShoot`, `runShoot`, `crouchShoot`, `crouchWalkShoot` und `crouchRunShoot` uebernehmen weiterhin importierte `shoot.fbx`-Oberkoerper-/Arm-Rotationstracks auf importierte Basisclips. `aimed` ist damit eine gehaltene Anschlag-/Shoot-Pose ohne automatisch erzeugtes Fire-Event.
- Stand: `UnitCommand` und `UnitRuntimeStatus` akzeptieren jetzt `crouch`, `crouch_walk` und `crouch_run`, damit spaetere Taktiken diese Clips autoritativ ueber Runtime-Postures anfordern koennen.
- Stand: `TerrainMap3DView` waehlt aus `movement_posture`, `weapon_posture` und Movement-State die passende Animation: stationary aim nutzt `standShoot`, engage aim beim Gehen `walkShoot`, travel aim `runShoot`, Crouch-Varianten die entsprechenden Crouch-Shoot-Cases.
- Risiken: `crouchRunShoot` bleibt bewusst `crouchWalk` plus `shoot`-Oberkoerper, weil das Asset-Bundle keinen dedizierten Crouch-Run-Clip liefert. Wann Taktiken Walk/Run/Crouch nutzen, bleibt ein eigener Gameplay-Task.
- Lokale Pruefung: `task_403_runtime_animation_combat_cases.gd`, `task_401_facing_sightline_debug_map.gd`, `task_402_npc_animation_showcase_map.gd`, `task_345_npc_standard_movement_posture_policy.gd`, `task_344_ground_mission_default_enemy_visuals.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Wegfindung, Taktik und Fireteam-Verhalten koennen jetzt Postures statt Visual-Sonderlogik setzen.

### TASK_404 - Fireteam Movement Posture Bridge
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_404_fireteam_movement_posture_bridge.md`, `docs/dev/commander_fireteam_delegation_contract.md`, `docs/dev/unit_facing_visual_contract.md`, `docs/tasks/TASK_110_fireteammovementcontroller_und_bewegungsmuster.md`
- Stand: `FireteamMovementController` setzt auf seinen bestehenden `UnitCommand`s jetzt explizite Runtime-Postures. Die Autoritaet bleibt beim Command-/SimulationRoot-Pfad; UI und Visuals erzeugen keine Unit-Wahrheit.
- Stand: Rush-Move wird als `travel/lowered` ausgegeben und kann im Runtime-Visualpfad als schneller Lauf gelesen werden. Bounding-Mover werden als `engage/aimed`, Bounding-Deckung als `overwatch/aimed` ausgegeben.
- Stand: Caterpillar-Mover nutzen `crouch_walk/aimed`, damit das vorsichtige Einzelvorruecken sichtbar von normalem Walk/Run getrennt ist; Deckungsmitglieder bleiben `overwatch/aimed`.
- Stand: Der Live-GO-Snapback-Guard im `FireteamMovementController` verhindert Rueckwaerts-Reissue-Ziele innerhalb eines aktiven Bounds, ohne Ziele hinter den finalen Anchor zu verschieben. Der TASK_110-Verifier misst diesen Fortschritt jetzt entlang der geplanten Fireteam-Route statt per Luftlinie, damit Terrain-Umwege nicht als Snapback gewertet werden.
- Risiken: Die genaue Gameplay-Balance fuer Crouch/Walk/Run bleibt spaeteren Taktikregeln ueberlassen. Dieser Task verbindet nur bestehende Fireteam-Muster mit den neuen Runtime-Animationen.
- Lokale Pruefung: `task_404_fireteam_movement_posture_bridge.gd`, `task_110_verifier.gd`, `task_403_runtime_animation_combat_cases.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Fireteam-Wegfindung und Taktik koennen jetzt auf sichtbare Posture-Zustaende aufsetzen.

### TASK_402 - NPC Animation Showcase Map
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_402_npc_animation_showcase_map.md`, `docs/dev/unit_facing_visual_contract.md`, `data/npc_unit_visual_mapping.json`
- Stand: `scenes/tests/npc_animation_showcase_map.tscn` ist ein beschrifteter Visual-Pruefstand fuer alle 17 importierten Animated-Characters-Clips.
- Stand: `scripts/tests/npc_animation_showcase_map.gd` baut je Animation einen CharacterMedium-NPC, legt die Astro-Skin auf, laedt den jeweiligen FBX-Clip in einen lokalen `ShowcaseAnimationPlayer` und spielt ihn geloopt ab.
- Stand: `data/npc_unit_visual_mapping.json` listet die 17 importierten Rohclips unter `animation_showcase_paths`; seit TASK_403 laedt der Runtime-Visualpfad diese Clips ebenfalls fuer Unit-Proxies, damit Showcase und Spiel dieselbe Asset-Basis verwenden.
- Stand: `animation_combat_cases` verankert die sichtbaren Kampf-Kombinationen `standShoot`, `walkShoot`, `runShoot`, `crouchShoot`, `crouchWalkShoot` und `crouchRunShoot`. Diese Cases verwenden importierte Basisclips und, wo noetig, fallweise importierte `shoot`-Posespuren statt handgebauter Zielposen.
- Stand: `walkShoot`, `runShoot` und die Crouch-Shoot-Cases uebernehmen den importierten `shoot`-Oberkoerper auf ihre jeweiligen Basisbewegungen. Der rechte-Waffenarm-only-Mix fuer Crouch wurde verworfen, weil der Arm im Sichtcheck nach hinten kippte.
- Stand: Der Showcase zeigt damit 23 beschriftete Prueffaelle: 17 Rohclips plus sechs Combat-Cases. `crouchRunShoot` ist bewusst als `crouchWalk` plus `shoot`-Oberkoerper dokumentiert, weil das Asset-Bundle keinen eigenen `crouchRun`-Clip liefert.
- Risiken: Die Szene ist ein Visual-/Asset-Pruefstand und erzeugt keine Gameplay-Kommandos. Welche Clips spaeter echte Runtime-Postures, Gesten oder Kampfhandlungen treiben, bleibt ein separater Design-/Runtime-Schnitt.
- Lokale Pruefung: `task_402_npc_animation_showcase_map.gd` laeuft gruen.
- Naechster Schritt: Manueller Sichtcheck in Godot: `res://scenes/tests/npc_animation_showcase_map.tscn` oeffnen und die 23 Labels/Clips optisch bewerten.

### TASK_401 - Facing Sightline Debug Map
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `docs/tasks/TASK_401_facing_sightline_debug_map.md`, `docs/dev/unit_facing_visual_contract.md`, `docs/tasks/TASK_364_mission_fireteam_orientation_indicators.md`, `docs/tasks/TASK_371_fire_sector_security_arc_overlay_toggle.md`, `docs/tasks/TASK_372_mission_los_debug_overlay_toggle.md`
- Stand: `maps/facing_sightline_debug_12x12.json` und `data/mission_scenarios/facing_sightline_debug_12x12.json` liefern eine kleine 12x12-Mission-Fixture mit sichtbaren Nord/Ost/Sued/West-Kompassmarkern und zwei Friendly-NPC-Slots in der Kartenmitte.
- Stand: `scenes/tests/facing_sightline_debug_map.tscn` nutzt die vorhandene Mission-Testszene, `MissionTestSetup`, `TacticalController`, `SimulationRoot` und `Primary3DView`; `facing_sightline_debug_fixture_setup.gd` setzt nur bestehende Unit-Facing-Metadaten und Runtime-Posture (`aimed` fuer beide Debug-NPCs) und aktiviert die vorhandenen Overlays.
- Stand: `TerrainMap3DView` rendert Corner-Kompassmarker jetzt optional mit den authored Full-Text-Labels statt nur N/E/S/W, bleibt dabei aber im bestehenden Marker-Visualpfad.
- Stand: Nach Playtest-Korrektur stehen die Debug-NPCs weiter auseinander; der obere NPC faced nach Nord, der untere nach Sued. Die Fire-Sector-/Weapon-Linie ist an die sichtbare Blick-/Facing-Richtung gebunden, nutzt bei angelegter Waffe den sichtbaren Waffenanker und vermeidet separate Target-Drift.
- Stand: Die sichtbare Blaster-Mesh-Ausrichtung nutzt die bestehende `visual_rotation_degrees`-Attachment-Schicht fuer eine 180-Grad-Korrektur, damit Griff/Magazin/Schussrichtung im manuellen Sichtcheck plausibler liegen, ohne den `RightHandSocket`-Root zu verschieben.
- Stand: Der blaue Selected-Unit-Marker nutzt einen eigenen Boden-Offset und liegt an den Fuessen statt auf Huefthoehe.
- Stand: Map-NPC-Klicks selektieren nur noch und veraendern den Primary-View-Fokus nicht. Das Zentrieren bleibt am bestehenden linken Fireteam-Kartenpfad; die Fireteam-Mini-Karten liegen explizit vor dem read-only Tactical-Event-Log, damit auch die untere Karte klickbar bleibt.
- Stand: Proxy- und Weapon-Pose priorisieren explizites Facing sowie Runtime-Movement-/Target-Facing vor Fire-Event-/Target-Fallbacks. Dadurch bleibt die Standrichtung nach Movement wieder an der autoritativen Unit-Facing-Metadatenquelle.
- Stand: Die Runtime-Animationseinbindung entfernt beim `walk`-Clip die importierten `HipsCtrl`- und `Hips`-Heading-Rotationsspuren. Damit bleibt Proxy-/Model-Root-Facing der einzige Richtungsanker fuer laufende NPCs; Waffen-/Socket-Follow bleibt im bestehenden Visualpfad.
- Stand: Unit-Proxies nutzen eine eigene model-forward-kalibrierte Grid-zu-3D-Yaw-Uebersetzung statt der allgemeinen World-Yaw-Formel. Damit stimmen Skeleton-Forward, Facing/Sichtlinie und Weapon-/Shot-Linie auch fuer Ost/West und Iso-Diagonalen waehrend echter Move-Commands ueberein.
- Stand: Aim-/Ready-Posture verschiebt den Waffenroot nicht mehr aus dem Socket. Die Anschlag-/Ready-Darstellung bleibt im vorhandenen Rotations-/Child-Yaw-Pfad, damit SMG, Medic-Tool und Enemy-Waffen beim Loslaufen und Feuern am Handanker bleiben. Fuer `weapon_posture = aimed` uebernimmt `TerrainMap3DView` die Oberkoerper-/Arm-Bone-Rotationen aus der importierten `shoot.fbx`; Idle/Walk bleiben Basisanimationen.
- Stand: Die 3D-Fireteam-Orientation bleibt im bestehenden Anchor-Payload-Pfad, liest bei gueltigem Anchor aber aktuelle Unit-Position und aktuelles Unit-Facing live aus `_unit_nodes`; der Dynamic-Refresh-Signature-Pfad beobachtet diese Live-Daten auch fuer nicht selektierte Fireteams.
- Stand: `data/npc_unit_visual_mapping.json` korrigiert die importierte Character-Forward-Achse auf `rotation_degrees_y = 270.0`, damit das Modell selbst mit der vorhandenen Proxy-/Facing-Rotation uebereinstimmt.
- Stand: `docs/dev/unit_facing_visual_contract.md` dokumentiert den verbindlichen Friendly-/Enemy-/Plan-/Fire-Event-Pfad: Runtime-Facing bleibt Unit-Wahrheit, Primary3DView liest live, Unit-Yaw ist model-forward-kalibriert und Waffenroots bleiben am Socket.
- Risiken: Der Headless-Verifier prueft Datenfluss, Render-Snapshot und Labeltexte; die finale optische Pfeil-/Label-Lesbarkeit im echten Godot-Fenster bleibt ein kurzer manueller Sichtcheck.
- Lokale Pruefung: `task_401_facing_sightline_debug_map.gd`, `task_171_npc_model_replacement_verifier.gd`, `task_190_weapon_visual_loadout_expansion_and_scale.gd`, `task_344_ground_mission_default_enemy_visuals.gd`, `task_345_npc_standard_movement_posture_policy.gd`, `task_202_enemy_security_direction_and_los_patch.gd`, `task_364_mission_fireteam_orientation_indicators.gd`, `bugfix_mission_fire_sector_overlay.gd`, `bugfix_mission_right_click_order_flow.gd`, `task_371_fire_sector_security_arc_overlay_toggle.gd`, `task_372_mission_los_debug_overlay_toggle.gd` und `git diff --check` laufen gruen.
- Offener Hinweis: `task_174_character_helmet_blaster_attachment_verifier.gd` hat einen stale Live-Node-Namen-Teil (`UnitProxy_unit_alpha`/`UnitProxy_enemy_delta`); Mapping-/Socket-/Attachment-Zaehler laufen, aber der alte Direkt-Node-Abschnitt bleibt rot.
- Offener Hinweis: `task_246_visual_scale_alignment_asset_pass_verifier.gd` faellt weiterhin an zwei Multiplayer-Lobby-Panel-Abmessungen; kein Bezug zu NPC-Facing, Weapon-Posture oder Fire-Sector-Visuals.

### TASK_400 - Agent Rules Doc Refresh
- Status: implementiert im Arbeitsstand
- Relevante Docs/Contracts: `AGENTS.md`, `docs/CODEX_RULES.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_TASK_PROMPT_TEMPLATE.md`
- Stand: Die Arbeitsregeln trennen jetzt klar zwischen Arbeitsanweisungen und Feature-Contracts. `AGENTS.md` betont Wahrheit/Besitz, Registry-Lookups, relevante Docs vor Taskstart, Task-Hygiene und Hotpath-Regeln.
- Stand: `docs/CODEX_RULES.md` beschreibt explizit Wahrheitsquellen, Registry-Grenzen, Doku-Hygiene und die Pflicht, relevante Contracts/Reviews/QA-Dokumente bei Tasks zu lesen.
- Stand: Die Task-Prompt-Vorlage fordert nun `AGENTS.md`, Roadmap, Implementation Status und relevante Contracts/Reviews/Performance-Dokumente an und erinnert an Simulation-/Registry-/UI-Grenzen.
- Risiken: Diese Doku-Aenderung erzwingt keine automatische Tool-Pruefung. Die Regeln wirken nur, wenn neue Tasks sie tatsaechlich lesen und relevante Contracts in Taskdateien nennen.
- Lokale Pruefung: `git diff --check` laeuft gruen.
- Naechster Schritt: Bei den naechsten neuen Tasks die Sektion `Relevante Contracts / Dokumente` konsequent ausfuellen.

## Aktueller Startzustand

### TASK_344 - Ground Mission Default Enemy Visuals
- Status: implementiert im Arbeitsstand
- Stand: `Ground_Mission01_32x32.json` ist die Standardkarte fuer den Meta-/Einzelspieler-Flow. Die Homebase-/FOB-Kontexte zeigen die Ground-Map, und die Standardmission uebergibt `ground_mission01_default` als Szenario an `MissionTestSetup`.
- Stand: Das neue Szenario definiert zwei feindliche Fireteams zu je vier NPCs. `red_patrol_team` nutzt `patrol_probe` plus `ground_patrol_route`; `red_objective_defense` haelt den Objective-Bereich mit `defensive_cover`/`cover_arc`.
- Stand: `MissionTestSetup` erweitert bei Szenarien mit mehr Enemy-IDs die vorhandenen Enemy-Templates zur Laufzeit und uebergibt die erzeugten Paths an den CombatLoop, ohne alte direkte Testszenen ohne Szenario pauschal umzubauen.
- Stand: Fire-Events speichern das Angreifer-Facing. `TerrainMap3DView` nutzt aktive Fire-Events fuer Proxy-Drehung, wenn keine explizite Facing-/Movement-Richtung vorliegt, uebernimmt fuer Aimed die Oberkoerper-/Arm-Rotationen aus `shoot.fbx` und nutzt weiter das kuratierte Kenney-Muzzle-Subset fuer Muzzle-Flash. Enemy-Security-Facing fliesst ebenfalls in die 2.5D-Ausrichtung ein.
- Stand: Fog-of-War-Dim-Layer ist dunkler (`known` 0.28 Alpha, `explored` 0.62 Alpha). Neue Portrait-PNGs unter `Assets/Char` werden ueber Godot-Imports und Portrait-Inventar mitgezaehlt.
- Risiken: Finale optische Balance der Ground-Spawnpunkte, Fireteam-Verteilung und Waffenlesbarkeit bleibt ein manueller Playtest-Punkt.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_344_ground_mission_default_enemy_visuals.gd`, `task_233_portrait_identity_catalog_and_roster_presentation.gd`, `task_205_weapon_fire_vfx_muzzle_flash_particles.gd`, `task_201_weapon_range_scale_and_tile_distance_patch.gd`, `task_186_mission_map_unit_presence_registry_audit.gd`, `task_202_enemy_security_direction_and_los_patch.gd` und `git diff --check` laufen gruen.

### TASK_345 - NPC Standard Movement Posture Policy
- Status: implementiert im Arbeitsstand
- Stand: Enemy-Team-Tactics-Profile tragen jetzt eine `movement_posture_policy` samt Ready-Distanz und Speed-Faktoren. Die Default-Policies decken `travel_until_threat`, `always_ready`, `hold_ready`, `aggressive_ready` und `overwatch` ab.
- Stand: `UnitCommand` und `UnitRuntimeStatus` fuehren `movement_posture`, `weapon_posture` und `posture_policy_id`. `SimulationRoot` weist Move-/Hold-Kommandos autoritativ an Units zu, bevor Bewegung ausgefuehrt wird.
- Stand: Der CombatLoop erzeugt fuer Patrouillen Travel/Lowered, nahe Threats Tactical/Ready, Defense Overwatch/Ready und Fire-Events Engage/Aimed inklusive Facing zum Ziel. `move_speed_factor` kommt dabei aus der Posture-Policy statt nur aus `advance_style`.
- Stand: `TerrainMap3DView` liest die Runtime-Posture nur fuer Darstellung und Snapshot. Ready nutzt einen leichten Blaster-Ready-Offset, Fire-Events uebersteuern visuell auf Aimed und bleiben kompatibel mit TASK_344-Muzzle-/Aim-Visuals.
- Stand: `ground_mission01_default` setzt die Patrol-Fireteam-Policy auf `travel_until_threat` und die Defense-Fireteam-Policy auf `hold_ready`.
- Stand: Drei neue Portrait-PNGs aus `Assets/Char` sind importiert und als `char_portrait_040` bis `char_portrait_042` im Portrait-Katalog erfasst.
- Risiken: Die Zahlen fuer Travel/Ready/Aim-Speed und `ready_distance_world = 640.0` sind V1-Spielgefuehlwerte und brauchen manuellen Mission-Playtest.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_345_npc_standard_movement_posture_policy.gd`, `task_344_ground_mission_default_enemy_visuals.gd`, `task_202_enemy_security_direction_and_los_patch.gd`, `task_201_weapon_range_scale_and_tile_distance_patch.gd`, `task_204_enemy_tactics_multiplayer_authority_snapshot_patch.gd`, `task_208_enemy_team_tactics_playability_smoke.gd`, `task_200_enemy_team_tactics_contract_and_editor_config.gd`, `task_233_portrait_identity_catalog_and_roster_presentation.gd` und `git diff --check` laufen gruen.

### TASK_346 - Homebase Direct Staging Character Popup
- Status: implementiert im Arbeitsstand
- Stand: Das Homebase-Drop-Light-Layout hat kein dauerhaftes rechtes `character_sheet`-Fenster mehr. Der frei gewordene Bereich wird fuer `#10 FIRETEAMS`, `#13 LOADOUT` und ein breiteres Homebase-Flightdeck genutzt.
- Stand: Homebase erzeugt direkte Fireteam-, Loadout- und Dropship-Staging-Panels ueber den bestehenden `FOBDropPanel`-/`FOBFireteamCard`-Vertrag. Fireteam-Zuweisungen bleiben im Meta-Flow erhalten und ein direktes Homebase-Payload kann als FOB-artiger Drop-State in die Missionsplanung laufen.
- Stand: Character Sheets starten geschlossen und oeffnen per Doppelklick auf NPC-/Operator-Karten als frei schwebendes Popup ausserhalb der nummerierten Fenster. Oeffnen/Schliessen verschiebt die festen Fenster nicht.
- Risiken: Das Homebase-Loadout ist ein kompakter Staging-Editor und noch kein vollstaendiges Redesign des FOB-Loadout-Fensters. Ein manueller FullHD-Sichtcheck bleibt sinnvoll, weil die neuen Homebase-Proportionen enger sind als das alte Character-Sheet-Layout.
- Lokale Pruefung: `task_346_homebase_direct_staging_character_popup.gd`, `task_316_fob_fireteam_staging_migration.gd`, `task_314_fob_npc_pool_window_left_of_fireteams.gd`, `task_310_fob_flightdeck_fireteam_userology_smoke.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd` und `git diff --check` laufen gruen.

### TASK_347 - Homebase Direct Staging Start Guard
- Status: implementiert im Arbeitsstand
- Stand: `HomebaseTestScreen` nutzt `can_request_mission_start()` als gemeinsame Startbereitschaft fuer Button, Snapshot und `request_mission_start()`.
- Stand: Direct-Homebase-Payloads emittieren jetzt `mission_start_requested`; leerer Homebase-State bleibt blockiert und der bestehende `_mission_launch_ready`-Pfad bleibt erhalten.
- Lokale Pruefung: `task_347_homebase_direct_staging_start_guard.gd`, `task_346_homebase_direct_staging_character_popup.gd` und `git diff --check` laufen gruen.

### TASK_348 - Homebase FOB Payload State Isolation
- Status: implementiert im Arbeitsstand
- Stand: Der Mission-Drop-Sync im Meta-Flow nimmt jetzt eine explizite Payload-Quelle entgegen. FOB-/Map-/Return-Syncs lesen `fob`, Homebase-Start bevorzugt `homebase_direct` und faellt nur bewusst auf FOB zurueck, wenn kein Direct-Payload existiert.
- Stand: Der Planning-State markiert die angewendete Quelle mit `mission_drop_source`, sodass Konfliktfaelle zwischen Homebase-Direct und FOB-Dropship nachvollziehbar bleiben.
- Stand: Wenn Homebase einen bereits wartenden FOB-Payload startet, werden auch `_selected_unit_ids` und `_selected_fireteam_ids` aus dem FOB-Quellenpfad synchronisiert.
- Lokale Pruefung: `task_348_homebase_fob_payload_state_isolation.gd`, `task_347_homebase_direct_staging_start_guard.gd`, `task_346_homebase_direct_staging_character_popup.gd`, `task_316_fob_fireteam_staging_migration.gd`, `bugfix_mission_multi_dropship_cards.gd` und `git diff --check` laufen gruen.
- Hinweis: `task_316_fob_fireteam_staging_migration.gd` meldet beim Headless-Exit bestehende RID-Leak-Warnungen, aber alle Assertions laufen gruen.

### TASK_349 - Homebase Direct Staging Real Flightdeck Craft Gate
- Status: implementiert im Arbeitsstand
- Stand: Homebase-Direct-Staging ist jetzt an ein echtes ausgewaehltes Homebase-Dropship-Craft gekoppelt. Ohne geeignetes Craft bleibt `drop_ship_staged` false und der synthetische `homebase_dropship` wird nicht mehr als Mission-Drop-Craft exportiert.
- Stand: Der Flightdeck-Dropbereich bleibt sichtbar und meldet Blocker fuer fehlendes Craft, Cargo-/nicht-Dropship-Craft, Transit, laufende Flightdeck-Arbeit und unavailable Air Assets.
- Stand: Direct-Staging-Regressionen aus TASK_346 bis TASK_348 erzeugen nun explizit ein echtes Homebase-Dropship, wenn sie einen launch-ready Direct-Payload erwarten.
- Lokale Pruefung: `task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`, `task_347_homebase_direct_staging_start_guard.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `task_346_homebase_direct_staging_character_popup.gd`, `task_348_homebase_fob_payload_state_isolation.gd` und `git diff --check` laufen gruen.
- Offener Balance-Punkt: Ob Direct-Staging auch einen zugewiesenen Piloten als harte Startbedingung braucht, bleibt als eigener Folgeentscheid sinnvoll.

### TASK_350 - Homebase Loadout Contract Export
- Status: implementiert im Arbeitsstand
- Stand: Homebase-Loadout nutzt jetzt denselben Member-Contract wie FOB (`armor`, `weapon_1`, `weapon_2`). Alte UI-Alias-Werte werden beim Lesen normalisiert, aber nicht mehr als Export-Wahrheit weitergereicht.
- Stand: `build_homebase_direct_drop_state()` exportiert `member_loadouts`, `selected_fireteam_definitions` und `selected_team_unit_configs`. `MetaLayerFlow` bevorzugt diese Homebase-Direct-Felder beim Missionsstart und faellt fuer FOB weiter auf den bestehenden FOB-Contract zurueck.
- Stand: Die Homebase-Loadout-Dropdowns verwenden nur FOB-/Mission-kompatible Werte; der Headless-Verifier prueft eine geaenderte Member-Auswahl bis in `MissionSetup`.
- Risiken: Ein gemeinsamer Loadout-Contract-Helper ist noch nicht extrahiert; FOB und Homebase normalisieren vorerst lokal auf denselben Wertebereich.
- Lokale Pruefung: `task_350_homebase_loadout_contract_export.gd`, `task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`, `task_348_homebase_fob_payload_state_isolation.gd`, `task_347_homebase_direct_staging_start_guard.gd`, `task_346_homebase_direct_staging_character_popup.gd`, `task_316_fob_fireteam_staging_migration.gd`, `bugfix_mission_fireteam_fob_payload_and_bubbles.gd`, `medic_support_verifier.gd` und `git diff --check` laufen gruen. `task_316` meldet beim Headless-Exit bestehende RID-Leak-Warnungen, aber keine Assertion-Fehler.

### TASK_351 - Homebase Direct Payload Scope Contract
- Status: implementiert
- Stand: Homebase-Direct exportiert die Missionsfelder `selected_unit_ids`, `selected_fireteam_ids`, `selected_team_unit_configs`, `selected_fireteam_definitions` und `member_loadouts` jetzt payload-only aus den wirklich im Flightdeck-Dropship gestagten Fireteams.
- Stand: Die volle Homebase-Team-Auswahl bleibt separat fuer UI/Debug erhalten: `homebase_team_unit_ids`, `homebase_team_fireteam_ids`, `homebase_team_unit_configs` und `homebase_fireteam_definitions`.
- Stand: `MetaLayerFlow` uebernimmt beim `homebase_direct`-Start nur die payload-only Auswahl fuer MissionSetup und Friendly-Paths, behaelt den Homebase-Team-Kontext aber getrennt.
- Lokale Pruefung: `task_351_homebase_direct_payload_scope_contract.gd`, `task_350_homebase_loadout_contract_export.gd`, `task_348_homebase_fob_payload_state_isolation.gd`, `task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd` und `git diff --check` laufen gruen.

### TASK_352 - Homebase Loadout Defaults Preserve Unit Profiles
- Status: implementiert
- Stand: Homebase-Member-Loadouts werden jetzt mit Unit-spezifischen Defaults aus Roster-/Profil-Daten normalisiert. `unit_bravo` behaelt ohne Spieleraktion `smg` + `medictool` bis in `MissionSetup` und in den `LoadoutModifierResolver`.
- Stand: Bewusste Homebase-Overrides gewinnen weiter vor Profilwerten; Fireteam-Lead- und Armor-Felder bleiben im Export erhalten.
- Lokale Pruefung: `task_352_homebase_loadout_defaults_preserve_unit_profiles.gd`, `task_350_homebase_loadout_contract_export.gd`, `task_351_homebase_direct_payload_scope_contract.gd`, `medic_support_verifier.gd` und `git diff --check` laufen gruen.

### TASK_353 - Shared Loadout Contract Helper
- Status: implementiert
- Stand: `scripts/command/loadout_contract.gd` ist der gemeinsame Loadout-Contract fuer Armor-/Weapon-Normalisierung, Member-Loadouts, UI-Optionen, Labels und Default-Strategien.
- Stand: Homebase und FOB verwenden den Helper fuer `armor`, `weapon_1`, `weapon_2`; Homebase behaelt `medium/rifle/none` als Default-Strategie, FOB `medium/smg/smg`.
- Stand: `special`, `sonderwaffe` und `support_lmg` normalisieren fuer UI/Export bewusst auf den kanonischen `WeaponData`-Wert `rail_gun`. `LoadoutModifierResolver` mappt `rail_gun` explizit weiter auf den bestehenden internen Balance-Formula-Key `special`.
- Lokale Pruefung: `task_353_shared_loadout_contract_helper.gd`, `task_350_homebase_loadout_contract_export.gd`, `task_316_fob_fireteam_staging_migration.gd`, `medic_support_verifier.gd`, `task_107_verifier.gd` und `git diff --check` laufen gruen.

### TASK_354 - Homebase Direct Loadout Regression Matrix
- Status: implementiert
- Stand: `task_354_homebase_direct_loadout_regression_matrix.gd` prueft Homebase-Direct mit zwei Fireteams, nur einem Flightdeck-Payload, separat editiertem Nicht-Payload-Fireteam und UI-naher `OptionButton`-Loadout-Auswahl.
- Stand: Die Matrix sichert ab, dass `unit_bravo` ohne Spieleraktion `smg` + `medictool` bis `MissionSetup` und in `unit_loadout_modifiers_by_unit_id` behaelt, waehrend UI-Overrides fuer `unit_alpha` korrekt in Member-Loadouts und Modifier laufen.
- Stand: Ein gleichzeitiger FOB-Start bleibt isoliert: FOB-Member-Loadouts erreichen `MissionSetup`, Homebase-Direct-Loadouts lecken dabei nicht in den FOB-Pfad.
- Lokale Pruefung: `task_354_homebase_direct_loadout_regression_matrix.gd`, `task_350_homebase_loadout_contract_export.gd`, `task_351_homebase_direct_payload_scope_contract.gd`, `task_352_homebase_loadout_defaults_preserve_unit_profiles.gd` und `git diff --check` laufen gruen.

### TASK_355 - Homebase Direct UX Payload Truth
- Status: implementiert
- Stand: Homebase-Direct-Fireteam-Karten, Loadout-Status, Flightdeck-Status und Mission-Startbereich zeigen jetzt dieselbe Payload-Wahrheit: Homebase-only, Loadout editing, Boarded / Flightdeck oder blockierte Flightdeck-Queue.
- Stand: Startbutton, Mission-Transferlabel, Aircraft-Snapshot und Direct-Staging-Snapshot tragen Payload-Operatorcount, Payload-Fireteamcount, Boarded/Blocked-Status und Blockgruende als Metadaten bzw. Snapshot-Felder.
- Stand: Ein Fireteam zaehlt sichtbar erst als `Boarded / Flightdeck`, wenn ein echter Homebase-Dropship-Craft stagebar ist. Ohne Craft bleibt es als blockierte Queue mit Operatorcount und TASK_349-Blockertext sichtbar, aber nicht als embarked Payload.
- Lokale Pruefung: `task_355_homebase_direct_ux_payload_truth.gd`, `task_346_homebase_direct_staging_character_popup.gd`, `task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd` und `git diff --check` laufen gruen.

### TASK_356 - MapEditor Lazy Terrain Texture Catalog
- Status: implementiert
- Stand: `TerrainTextureCatalog` ist der zentrale Lazy-Cache fuer gemeinsame Terrain-, Cliff-, Wall-, Ramp- und Rock-Texture-Pfade. Der Cache laedt pro `res://`-Pfad erst bei Zugriff und zaehlt Cache-/Load-Zustand fuer Verifier.
- Stand: `TerrainTileCatalog` speichert beim JSON-Katalogaufbau nur noch Texture-Pfade. `get_texture()` loest die Resource lazy ueber den gemeinsamen Cache auf; fehlende Pfade fallen auf `terrain_SW.png` zurueck.
- Stand: `MapEditor` und `TerrainMapRenderer` halten keine eigenen Terrain-/Corridor-/Rock-Texture2D-Preloads mehr. Palette-Previews erzeugen beim Start generierte Icons und laden echte Thumbnails erst, wenn die Texture bereits genutzt/gecached ist.
- Stand: Der 2.5D-Modulate-Pfad behandelt fehlende Texture-Pfade konsistent mit dem 2D-Renderer, damit Fallback-Tiles weiter sicher getinted werden.
- Lokale Pruefung: `task_356_mapeditor_lazy_terrain_texture_catalog.gd`, `task_298_editor_terrain_visual_playability_smoke.gd`, `task_229_map_editor_usability_authoring_pass.gd`, `wall_direction_mapping_verifier.gd` und `git diff --check` laufen gruen.

### TASK_357 - MapEditor Height Cliff Dirty Neighborhood Cache
- Status: implementiert
- Stand: Brush-, Height- und Property-Operationen sammeln geaenderte Grid-Positionen und fuehren Cliff-/Wall-/Object-Overlay-Refreshes gesammelt und dedupliziert aus.
- Stand: Height-Reconciliation refreshed die betroffenen Tile-Sprites erst nach Edge-/Lower-Cliff-Abgleich und aktualisiert danach eine stabile, sortierte Dirty-Nachbarschaft. Die Terrain-Wahrheit bleibt in `TerrainMapData`.
- Stand: `get_dirty_neighborhood_debug_snapshot()` meldet Seed-Anzahl, Rohkandidaten, deduplizierte Cliff-/Wall-Kandidaten, Object-Kandidaten und Refresh-Zaehler fuer Verifier.
- Lokale Pruefung: `task_357_mapeditor_height_cliff_dirty_neighborhood_cache.gd`, `task_292_editor_hill_cliff_grid_depth_repair.gd`, `task_298_editor_terrain_visual_playability_smoke.gd`, `task_229_map_editor_usability_authoring_pass.gd` und `git diff --check` laufen gruen.

### TASK_358 - MapEditor Undo Stroke Transactions
- Status: implementiert im Arbeitsstand
- Stand: MapEditor-Undo nutzt explizite Transaktionen fuer Brush-, Height-, Eraser-, Rotate- und Property-Patch-Aktionen. Zusammenhaengende Tile-Aenderungen landen als ein Undo-Eintrag im Stack.
- Stand: Height-Tools erfassen automatisch erzeugte Cliff-/Edge-/Lower-Neighbor-Aenderungen in derselben Transaktion. Empty-Transactions werden verworfen, und das Undo-Limit gilt auf Transaktionsebene.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_358_mapeditor_undo_stroke_transactions.gd`; `godot_console.exe --headless --path . --script scripts/tests/bugfix_map_editor_station_floor_structure_undo.gd`; `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`; `git diff --check`.

### TASK_359 - MapEditor Dirty UI Refresh Batching
- Status: implementiert im Arbeitsstand
- Stand: MapEditor-UI-Refreshes fuer Selection, Properties, Tool-State, Hover und Scenario-Panel laufen ueber eine deferred Dirty-Queue mit Diagnose-Snapshot.
- Stand: Paint-, Height-, Eraser-, Area-Selection-, Undo-/Dirty- und Hover-Motion-Pfade coalescen mehrere UI-Requests in einen Flush. Die bestehende 3D-Refresh-Queue bleibt separat.
- Lokale Pruefung: `godot_console.exe --headless --path . --script scripts/tests/task_359_mapeditor_dirty_ui_refresh_batching.gd`; `godot_console.exe --headless --path . --script scripts/tests/task_295_map_editor_paint_toolbar_tools_polish.gd`; `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`; `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`; `git diff --check`.

### TASK_360 - MapEditor Mission Scenario Panel Extraction
- Status: implementiert im Arbeitsstand
- Stand: `MapEditorMissionScenarioPanel` uebernimmt Aufbau, Signalverbindungen, Refresh, Sync und Control-Lookups der Mission-Scenario-Authoring-UI. `MapEditor.gd` delegiert diese Pfade und bleibt Koordinator fuer Map-Daten, ScenarioData-Besitz, Save/Load, Dirty-State, Validierung und Live-Test.
- Stand: Der neue Verifier prueft Controller-Ownership, bestehende Node-Pfade, UI-Sync, JSON-Save-Vertrag und Live-Test-Szenenpfad.
- Lokale Pruefung: `task_360_mapeditor_mission_scenario_panel_extraction.gd`, `task_280_tactical_profile_editor_scenario_authoring.gd`, `task_298_editor_terrain_visual_playability_smoke.gd`, `task_229_map_editor_usability_authoring_pass.gd` und `git diff --check` laufen gruen.
- Hinweis: `task_158_verifier.gd` wurde ausgefuehrt und endet mit Exitcode 0, meldet aber 15 bestehende Assertion-Fails. Der erste Fail tritt vor dem Editor-Load beim generischen `lz`-Key-Check von `MissionScenarioData.to_dict()` auf.

### TASK_361 - NPCCompactCard Readonly Profile Reference Contract
- Status: implementiert
- Stand: `NPCCompactCard.setup_from_profile()` hat jetzt einen kompatiblen Copy-Default und einen expliziten Readonly-Anzeigemodus ueber `copy_profile = false`.
- Ergebnis: Homebase, FOB und Transport-Craft-Pilotkarten nutzen fuer reine Anzeige Profilreferenzen. Kontexttexte werden ueber `secondary_text_override` dargestellt, ohne Profilkopien zu mutieren.
- Vertrag: `get_profile()` bleibt copy-safe fuer Signale, Doubleclick-Character-Sheet und externe Verbraucher; `get_profile_reference_for_readonly_display()` ist der klare Diagnose-/Anzeigegetter.
- Lokale Pruefung: `task_361_npc_compact_card_readonly_profile_reference_contract.gd`, `task_346_homebase_direct_staging_character_popup.gd`, `task_316_fob_fireteam_staging_migration.gd`, `task_301_npc_card_drag_zorder_badges_tooltips.gd`, `task_233_portrait_identity_catalog_and_roster_presentation.gd` und `git diff --check` laufen gruen.

### TASK_362 - Homebase Aircraft State Manager Extraction
- Status: implementiert
- Stand: `scripts/meta/aircraft_manager.gd` besitzt jetzt den Homebase-Aircraft-State fuer Definitions, ausgewaehltes Craft, Pilotenzuordnung, Craft-Location, Cargo-Auswahl/-Load, Pilotentransfers und Cargo-Load-Activity.
- Stand: `HomebaseScreen.gd` rendert Shipcards und Panels weiter selbst, delegiert aber State-Lookups, Pilot-/Cargo-Mutationen, Remove-/Send-/Load-Validation und Homebase-Direct-Craft-Gates an den Manager.
- Vertrag: Der Manager ist ein reiner `RefCounted` ohne UI-Rendering-Ownership, SimulationRoot-Commands oder neue Mission-Wahrheit. `get_aircraft_manager_contract_snapshot()` und `aircraft_manager_contract` im Panel-Snapshot sichern die Grenze ab.
- Lokale Pruefung: `task_362_homebase_aircraft_state_manager_extraction.gd`, `task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`, `task_346_homebase_direct_staging_character_popup.gd`, `bugfix_dropship_mission_flow_verifier.gd`, `task_355_homebase_direct_ux_payload_truth.gd`, `task_354_homebase_direct_loadout_regression_matrix.gd` und `git diff --check` laufen gruen.
- Hinweis: Der erste Lauf von `bugfix_dropship_mission_flow_verifier.gd` lief ueber 180 Sekunden und wurde mit hoeherem Timeout wiederholt. Der erfolgreiche Lauf meldet nur bestehende Headless-RID-/ObjectDB-Warnungen am Exit.

### TASK_363 - Homebase Roster Card Pool Incremental Refresh
- Status: implementiert
- Stand: `scripts/meta/homebase_card_pool.gd` fuehrt einen kleinen Card-Pool fuer Homebase-NPC-Karten ein. Der Pool reconciled stabile Keys gegen einen Container, haelt vorhandene Nodes, reordered sie nach Bedarf und retired entfernte Karten sauber.
- Stand: `HomebaseScreen.gd` nutzt den Pool fuer Roster-Karten (`roster|unit_id`) und gestagte Teamkarten (`staged|unit_id`). Transfer-Ghost-Karten bleiben bewusst ausserhalb des Pools und werden separat aufgebaut.
- Stand: `get_homebase_card_pool_snapshot()` meldet aktive Keys, Create-/Reuse-/Retire-Zaehler und Dictionary-Counts. Der Verifier simuliert 60 Roster-Units, Selection-Aenderungen, Profil-/Badge-Refresh und Doppelklick-Popup auf wiederverwendeten Staging-Karten.
- Lokale Pruefung: `task_363_homebase_roster_card_pool_incremental_refresh.gd`, `task_361_npc_compact_card_readonly_profile_reference_contract.gd`, `task_346_homebase_direct_staging_character_popup.gd`, `task_355_homebase_direct_ux_payload_truth.gd`, `task_362_homebase_aircraft_state_manager_extraction.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Fireteam- und Loadout-Memberkarten sind noch nicht gepoolt; dieser Task deckt den risikoarmen ersten Homebase-Roster/Staging-Schnitt ab.

### TASK_364 - Mission Fireteam Orientation Indicators
- Status: implementiert
- Stand: `mission_tactical_sandbox_controller.gd` liefert einen read-only Orientation-Snapshot pro Fireteam und erweitert bestehende Fireteam-Anker um `heading_direction`, `heading_angle` und `heading_source`.
- Stand: `fireteam_order_visualizer.gd` zeichnet kompakte Richtungspfeile an vorhandenen 2D-Fireteam-Markern. `terrain_map_3d_view.gd` nutzt denselben Payload fuer Primary-3D-Order-Visuals und meldet `fireteam_orientation_visual_count` fuer Verifier.
- Stand: Invalid-Headings werden in 2D und 3D gefiltert; der Visual-Refresh erzeugt keine `SimulationRoot` Commands oder Effects.
- Lokale Pruefung: `task_364_mission_fireteam_orientation_indicators.gd`, `task_286_ui_feedback_truth_regression_review.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Manuelle Sichtpruefung im echten HUD bleibt sinnvoll, sobald weitere Visual-Slices Event-Log, Readiness und Debug-Layer ergaenzen.

### TASK_365 - Tactical Event Log Data Layer
- Status: implementiert
- Stand: `scripts/tactical/tactical_event_log.gd` ist ein read-only `RefCounted`-History-Adapter fuer bestehende `TacticalCommunicationEvent`-Snapshots. Er normalisiert Event-ID, Event-Typ, Kategorie, Severity, Zeit, Fireteam, Text, Channels und optionale Positionsanker.
- Stand: Die History ist bounded (`DEFAULT_MAX_ENTRIES = 100`), dedupliziert stabile Event-IDs und kann newest-first oder oldest-first abgefragt werden.
- Stand: `mission_tactical_sandbox_controller.gd` speist den Adapter aus dem bestehenden Tactical-Communication-Pfad und exposed `tactical_event_log`, `tactical_event_log_count` und `tactical_event_log_contract` im Command-Feedback-Snapshot.
- Lokale Pruefung: `task_365_tactical_event_log_data_layer.gd`, `task_274_tactical_communication_feedback_layer.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: TASK_366 kann darauf ein HUD-Panel bauen; der Log selbst rendert bewusst nichts.

### TASK_366 - Tactical Event Log HUD Panel
- Status: implementiert
- Stand: `scripts/ui/tactical_event_log_panel.gd` zeigt TASK_365-Eintraege newest-first als kompaktes Mission-HUD-Panel mit ScrollContainer, Zeitlabel, kurzer Meldung und dezenter Severity-Farbe fuer `critical`, `warning`, `tactical` und `info`.
- Stand: `mission_reactivity_test.tscn` haengt das Panel links unter die Fireteam-Miniuebersicht. Dieser Platz kollidiert nicht mit #16 Command Matrix, #17 Selected Fireteam, #18 Mission Control oder dem rechten Dropship-Stack.
- Stand: `mission_tactical_sandbox_controller.gd` speist das Panel aus dem bestehenden Command-Feedback-Snapshot. Der Selected-Fireteam-Filter liest nur `selected_fireteam_ids` und erzeugt keine SimulationRoot-Commands oder neue Gameplay-Wahrheit.
- Stand: `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` wurde auf den aktuellen Homebase-Direct-Vertrag nachgezogen und prueft nun auch das Mission-Event-Log als fixed, scrollbares HUD-Fenster.
- Lokale Pruefung: `task_366_tactical_event_log_hud_panel.gd`, `task_258_fixed_window_clipping_scrollbar_playability_audit.gd`, `task_365_tactical_event_log_data_layer.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Manuelle Sichtpruefung der Lesbarkeit im echten Gefecht bleibt sinnvoll, sobald weitere HUD-Widgets aus TASK_367+ dazukommen.

### TASK_367 - FTL Public Readiness Snapshot Contract
- Status: implementiert
- Stand: `scripts/tactical/ftl_readiness_snapshot_contract.gd` normalisiert bestehende `ftl_public_snapshot`-/Profilwerte zu einem kleinen HUD-Snapshot mit Fireteam-ID, Leader-Name, Reaction Delay, Morale, Plan Quality, Execution Label, Availability-Flags und dokumentierten Wertebereichen.
- Stand: Fehlende Leader-/FTL-Daten werden explizit als unavailable markiert. Fehlende Metriken bleiben `null`; es werden keine 0.5-Fallbackwerte als Wahrheit ausgegeben.
- Stand: `mission_tactical_sandbox_controller.gd` exposes `get_ftl_readiness_snapshot()` und spiegelt `ftl_readiness`, `ftl_readiness_count` und `ftl_readiness_contract` im Command-Feedback-Snapshot. Der Pfad ist read-only und erzeugt keine `SimulationRoot` Commands oder Effects.
- Lokale Pruefung: `task_367_ftl_public_readiness_snapshot_contract.gd`, `task_273_fireteam_leader_skill_tactical_progression.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: TASK_368 baut daraus die kompakte Readiness-Gauge.

### TASK_368 - FTL Readiness Gauge
- Status: implementiert
- Stand: `scripts/ui/ftl_readiness_gauge.gd` stellt den TASK_367-Readiness-Snapshot als kompaktes, read-only HUD-Control dar. Planqualitaet und Moral werden als Ringe gezeichnet, Reaktionszeit als kleine Balken; unavailable-Werte bleiben neutral und werden nicht durch Fake-Fallbacks ersetzt.
- Stand: `mission_tactical_sandbox_controller.gd` bettet pro Fireteam-Mini-Karte eine feste `FTLReadinessGauge` im Header ein und speist sie aus dem bestehenden Readiness-Snapshot. Die Karte bleibt kompakt und erzeugt keine neue Gameplay-Wahrheit.
- Stand: `get_gauge_snapshot()` liefert nur Test-/Diagnosemetadaten wie Display-State, Availability und fixe Groesse, damit Headless-Gates high/medium/low/unavailable ohne visuelle Heuristik pruefen koennen.
- Lokale Pruefung: `task_368_ftl_readiness_gauge.gd`, `task_367_ftl_public_readiness_snapshot_contract.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Manuelle HUD-Lesbarkeit bleibt mit TASK_369+ zu pruefen, wenn weitere Fireteam-Statusdetails neben der Gauge sichtbar werden.

### TASK_369 - Fireteam Status Card Enhancement
- Status: implementiert
- Stand: `mission_tactical_sandbox_controller.gd` baut pro Fireteam einen read-only Status-Card-Snapshot aus vorhandenen Behavior-, Contact-, Movement-, Position-, Health- und TASK_367-Readiness-Daten.
- Stand: Die Fireteam-Mini-Karte nutzt ihre bestehenden kompakten Zeilen weiter: `StageLabel` zeigt Loadout/Movement/Position, `MemberLabel` zeigt Execution/Readiness/Contact/Health. Dadurch bleibt die Kartenhoehe im festen Mission-HUD stabil.
- Stand: `get_command_feedback_snapshot()` spiegelt `fireteam_status_cards` und `fireteam_status_card_count`; die Karte legt denselben Snapshot als Metadatum ab. UI bleibt Anzeige, nicht Autoritaet.
- Stand: `task_369_fireteam_status_card_enhancement.gd` prueft zwei Fireteams mit unterschiedlichem Contact-/Readiness-Kontext, Selection-Meta, Card-Zeilen und kompakte Hoehe.
- Lokale Pruefung: `task_369_fireteam_status_card_enhancement.gd`, `task_258_fixed_window_clipping_scrollbar_playability_audit.gd`, `task_286_ui_feedback_truth_regression_review.gd`, `task_368_ftl_readiness_gauge.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Manuelle HUD-Lesbarkeit bleibt mit TASK_370+ zu pruefen, sobald Member-Health-Zeilen oder weitere Debuglayer sichtbar werden.

### TASK_370 - Fireteam Member Health Status Row
- Status: implementiert
- Stand: `scripts/ui/fireteam_member_status_row.gd` stellt eine feste Chip-Zeile fuer Fireteam-Member-Status dar. Sie visualisiert `fit`, `wounded`, `down`, `suppressed`, `busy` und neutrale/unbekannte Daten ohne neue Asset-Imports.
- Stand: `mission_tactical_sandbox_controller.gd` baut den Member-Row-Snapshot aus vorhandenen Unit-Vital-, Health-, Runtime- und Fireteam-Suppression-Daten. Die Row selbst bleibt read-only und erzeugt keine Loadout-, Rollen- oder Gameplay-Wahrheit.
- Stand: Die Row wird unten in der Mission-Fireteam-Mini-Card verankert, ohne in deren VBox-Layout Hoehe zu addieren. Dadurch bleiben TASK_368/TASK_369-Kompaktheit und FullHD-Layout-Audit gruen.
- Stand: `get_command_feedback_snapshot()` spiegelt `fireteam_member_status_rows` und `fireteam_member_status_row_count`; Card-Metadaten enthalten denselben Row-Snapshot.
- Lokale Pruefung: `task_370_fireteam_member_health_status_row.gd`, `task_369_fireteam_status_card_enhancement.gd`, `task_368_ftl_readiness_gauge.gd`, `task_258_fixed_window_clipping_scrollbar_playability_audit.gd`, `task_286_ui_feedback_truth_regression_review.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Manuelle Sichtpruefung der Farblesbarkeit bleibt sinnvoll, wenn weitere HUD-Layer aus TASK_371+ dazukommen.

### TASK_371 - Fire Sector Security Arc Overlay Toggle
- Status: implementiert
- Stand: `FireteamOrderVisualizer` zeichnet Security-/Fire-Sektoren nur noch bei aktivem Overlay-Toggle und liefert `get_security_overlay_snapshot()` mit sichtbaren Entries, Selection-Filter, 360-/Sector-/Overwatch-Counts und Contact/FoW-Policy.
- Stand: `mission_tactical_sandbox_controller.gd` synchronisiert `_fire_sector_overlay_enabled` in den 2D-Visualizer, spiegelt den Fire-Sector-Overlay-Snapshot im Command-Feedback und reicht den bestehenden 3D-LOS-Line-Modus weiter an `Primary3DView`.
- Stand: 360-Sektoren werden im Visualizer als Kreis statt als volles TAU-Polygon gezeichnet, damit Godot keine Polygon-Triangulation-Warnungen ausgibt.
- Lokale Pruefung: `task_371_fire_sector_security_arc_overlay_toggle.gd`, `bugfix_mission_fire_sector_overlay.gd`, `task_286_ui_feedback_truth_regression_review.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Enemy-In-Sector-Hervorhebung bleibt an Contact/FoW-Sichtbarkeit gebunden und sollte erst mit den Contact-/LOS-Layern aus TASK_372+ weiter vertieft werden.

### TASK_372 - Mission LOS Debug Overlay Toggle
- Status: implementiert
- Stand: `TerrainMap3DView` zeichnet bei aktivem `los_debug_overlay_enabled` begrenzte LOS-Debug-Linien zwischen ausgewaehlten Friendly-Units und bekannten Contact-/Last-Known-Eintraegen. Das Overlay nutzt den bestehenden Grid-LOS-Blockerpfad der Fire-Sector-Visuals und erzeugt keine Gameplay-Kommandos.
- Stand: Render-Snapshots melden `mission_los_debug_line_count`, Clear-/Blocked-Zaehler, Blocker-Marker, Source-/Contact-Counter, Sample-Limit, bounded Skips und FoW-hidden Contacts. Eintraege tragen `line_state`, `blocker_grid` und `fow_last_known`.
- Stand: `mission_tactical_sandbox_controller.gd` stellt `set_los_debug_overlay_enabled()`, Hotkey `L`, Command-Feedback und Primary3D-Payload bereit. Das Overlay bleibt standardmaessig aus und liest nur Contact/FoW/Terrain-Snapshots.
- Lokale Pruefung: `task_372_mission_los_debug_overlay_toggle.gd`, `task_202_enemy_security_direction_and_los_patch.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Spieler-permanente LOS-Hinweise brauchen eigenes Design/FoW-Balancing; dieser Slice bleibt Debug-/Optional-Layer.

### TASK_373 - Cover Effectiveness Readout
- Status: implementiert
- Stand: `CombatFireDecisionResolver.build_cover_effectiveness_readout()` liefert einen read-only Diagnose-Snapshot fuer Cover, Range, LOS, Flank-Preview und qualitative Angriffsguete, ohne eine zweite UI-Trefferformel einzufuehren.
- Stand: `FlankVulnerabilityResolver.preview_attack()` stellt Flank-Bonus, Cover-Override und Richtung bereit, ohne den laufenden Flank-State zu mutieren.
- Stand: `MissionCombatLoopDriver` und `mission_tactical_sandbox_controller.gd` veroeffentlichen Contact-/Tile-Readouts im Command-Feedback. Unsichtbare Contacts bleiben auf `unknown/contact_not_visible`; Selected-Tile-Werte sind als terrain-only `estimated` markiert.
- Lokale Pruefung: `task_373_cover_effectiveness_readout.gd`, `task_286_ui_feedback_truth_regression_review.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Eine sichtbare HUD-Komponente kann auf diesem Snapshot aufbauen; dieser Task etabliert zuerst den Wahrheitspfad und die FoW-Sanitization.

### TASK_374 - Objective Countdown Indicator
- Status: implementiert
- Stand: `ObjectiveStatus` besitzt jetzt einen optionalen Countdown-Vertrag mit Seconds, Gesamtzeit, State, Source, Label, Urgency und Sichtbarkeit.
- Stand: `MissionCombatLoopDriver` schreibt vorhandene `mission_time_limit_seconds` und Objective-Defense-Hold-Timer in diesen Vertrag. Szenarien ohne Timer bleiben ohne Countdown.
- Stand: `SimulationRoot` und `MultiplayerSnapshotContract` replizieren die Timer-Felder im Objective-Snapshot; Clients wenden sie wieder auf `ObjectiveStatus` an.
- Stand: `MissionObjectiveStatusView` zeigt den Timer nur bei gueltiger Quelle kompakt in der bestehenden zweizeiligen HUD-Anzeige und liefert einen testbaren View-Snapshot.
- Lokale Pruefung: `task_374_objective_countdown_indicator.gd`, `task_279_lz_security_air_asset_tactical_playability_smoke.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Weitere Szenario-Timer wie Exfil-Fenster koennen denselben Vertrag nutzen, muessen aber als eigene Objective-/Scenario-Quelle modelliert werden.

### TASK_375 - Waypoint Intent Preview
- Status: implementiert
- Stand: `WaypointIntentPreviewResolver` baut read-only Ghost-Pfad-, Richtung-, Distanz- und ETA-Preview-Eintraege aus bestehenden Order-Plans, Fireteam-Ankern und Speed-Schaetzungen der Fireteam-Mitglieder.
- Stand: `mission_tactical_sandbox_controller.gd` veroeffentlicht `waypoint_intent_preview` im Command-Feedback und reicht denselben Payload an `FireteamOrderVisualizer` sowie den Primary3D-Order-Payload weiter.
- Stand: `FireteamOrderVisualizer` zeichnet den fertigen Payload als Ghost-Pfad/Ghost-FTL-Position und trifft keine Pathfinding- oder Movement-Entscheidung. Risiko bleibt `unknown`, solange keine echten Moral-/Fatigue-Daten existieren.
- Lokale Pruefung: `task_375_waypoint_intent_preview.gd`, `task_315_mission_grid_tile_selection_command_gate.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Ein spaeterer Path-Resolver kann den Preview-Vertrag ersetzen/erweitern; dieser Slice bleibt bewusst Straight-Line-Estimate.

### TASK_376 - Command Validation Bubble
- Status: implementiert
- Stand: `FireteamleaderFeedbackBubbleResolver` mappt bestehende Controller-/Reject-Details wie `no_tile` und `failed` auf kurze Validation-Keys und Texte (`select_tile_first`, `blocked_route`) und haengt sie als Visual-only-Felder an die bestehenden Command-Feedback-Bubbles.
- Stand: `ComicBubbleRuntimeGate` dedupliziert pro Unit/Fireteam, Action und Validation-Key. Geblockte Validation-Bubbles erhalten hoehere Prioritaet als normale Command-Flavor-Bubbles.
- Stand: `mission_tactical_sandbox_controller.gd` nutzt weiter den vorhandenen FTL-Bubble-Pfad, schuetzt aktive Blocker aber beim Max-Active-Cap vor niedriger priorisierten Bubbles.
- Lokale Pruefung: `task_376_command_validation_bubble.gd`, `task_315_mission_grid_tile_selection_command_gate.gd`, `task_286_ui_feedback_truth_regression_review.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Finale optische Position/Lesbarkeit der HUD-Bubbles bleibt ein manueller Mission-HUD-Sichtcheck.

### TASK_377 - Contact Density Heat Map Layer
- Status: implementiert
- Stand: `ContactDensityOverlay` aggregiert erlaubte Contact-Snapshots bounded in Heat-Zellen. Kontakte werden pro Target dedupliziert und nach World-Cell gebucketed.
- Stand: `FogOfWarSystem.filter_contact_density_sources_for_team()` liefert nur sichtbare aktuelle Kontakte plus aufgezeichnete Last-Known-Kontakte und gibt versteckte Kontakte nur als Count aus.
- Stand: `TerrainMap3DView` zeichnet den optionalen Heatmap-Layer in einem separaten Root, nutzt ein Update-Intervall statt Frame-Rebuilds und exportiert Heat-Cell-, Source-, Last-Known- und FoW-Hidden-Zaehler im Render-Snapshot.
- Stand: `mission_tactical_sandbox_controller.gd` reicht den read-only Toggle an die Primary3D-Order-Payload weiter und meldet den Heatmap-Snapshot im Command-Feedback.
- Lokale Pruefung: `task_377_contact_density_heat_map_layer.gd`, `task_286_ui_feedback_truth_regression_review.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Manueller Sichtcheck fuer Lesbarkeit/Overload bleibt offen; der Layer bleibt default aus.

### TASK_378 - MapEditor Patrol Route Preview
- Status: implementiert
- Stand: `MapEditorPatrolPreview` loest Patrol-Preview-Referenzen read-only aus `TerrainMapData.get_patrol_path()` und Scenario-Patrol-Bindings auf. Direkte Patrol-IDs, Binding-IDs und Target-/Spawn-IDs fuehren auf denselben Preview-Vertrag.
- Stand: `MapEditor` hebt die aktive Patrol-Route im 2D-Overlay mit staerkerer Linie, Waypoint-Nummern und Richtungspfeilen hervor. Hover-Wechsel laufen ueber die Dirty-UI-Batching-Queue und ersetzen stale Preview-Routen.
- Stand: Die Primary-3D-View erhaelt nur die aktive Preview-Path-ID und zeichnet die zugehoerigen Patrol-Segmente in Preview-Farbe. Der Preview-Snapshot markiert `visual_only` und setzt keine Editor- oder Gameplay-Wahrheit.
- Lokale Pruefung: `task_378_mapeditor_patrol_route_preview.gd`, `task_360_mapeditor_mission_scenario_panel_extraction.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Manueller Editor-Sichtcheck fuer genaue Pfeil-/Label-Lesbarkeit bleibt sinnvoll, besonders bei langen oder eng gekreuzten Patrol-Routen.

### TASK_379 - MapEditor Tile Property Grid Overlay
- Status: implementiert
- Stand: `MapEditorTilePropertyOverlay` berechnet die Tile-Property-Farben und kompakten Labels read-only aus bestehenden Tile-Daten. Rollen sind `walkable`, `blocked`, `los_block`, `cover` und `height`.
- Stand: `MapEditor` hat einen `DBG`-Toggle in der Topbar. Aktiv zeichnet er ein 2D-Debug-Overlay mit farbigen Diamond-Zellen und kurzen Labels fuer nicht-default Properties; inaktiv bleiben Draw-Zellen leer.
- Stand: Tile-Aenderungen aktualisieren das Overlay ueber die bestehenden Dirty-/Tile-Refresh-Pfade pro betroffenem Grid. Der Debug-Snapshot meldet aktive/inaktive Zaehler, Farbroles, Rebuilds und Dirty-Refreshes.
- Lokale Pruefung: `task_379_mapeditor_tile_property_grid_overlay.gd`, `task_298_editor_terrain_visual_playability_smoke.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Manueller Sichtcheck fuer Farb-/Label-Dichte auf grossen 64x64-Maps bleibt sinnvoll.

### TASK_380 - Terrain Adjacency Solver Indicator
- Status: implementiert
- Stand: Der Dirty-Neighborhood-Snapshot aus TASK_357 enthaelt jetzt neben Counts auch Seed-, Neighborhood- und Object-Gridlisten. Diese Daten bleiben reine Diagnose und veraendern den Solver nicht.
- Stand: `MapEditorAdjacencyDebugOverlay` baut daraus visuelle Rollen fuer Seed-, Neighbor- und Object-Kandidaten. `MapEditor` zeigt sie per `ADJ`-Toggle als gelb/cyan/orange Debug-Overlay und leert den Layer bei ausgeschaltetem Toggle.
- Stand: Der Overlay-Snapshot spiegelt die bestehenden Dirty-Neighborhood-Counts, meldet Draw-/Role-Zaehler und bleibt `visual_only`.
- Lokale Pruefung: `task_380_terrain_adjacency_solver_indicator.gd`, `task_357_mapeditor_height_cliff_dirty_neighborhood_cache.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Manueller Editor-Sichtcheck fuer Ueberlagerung mit TASK_379-Property-Overlay und Patrol-Preview bleibt sinnvoll.

### TASK_381 - Homebase Fireteam Loadout Flightdeck Polish
- Status: implementiert
- Stand: #10 FIRETEAMS rendert pro Fireteam-Mitglied kompakte Armor-/Primary-/Secondary-Dropdowns. Diese schreiben in denselben Member-Loadout-State wie #13 LOADOUT und aktualisieren beide Panels.
- Stand: Flightdeck-Shipcards sind Fireteam-Drop-Ziele fuer Homebase Direct Staging. Ein Drop auf eine Shipcard waehlt das Ziel-Craft und nutzt den bestehenden Dropship-Payload-State.
- Stand: Homebase-Character-Popup rendert das Character Sheet zweispaltig wie der Editor/FOB-Overlay-Pfad; die feste rechte Character-Karte bleibt deaktiviert.
- Stand: Kontext-Hilfe-Popups sind schmaler (220 px compact, 260 px detail), und die Fireteam-Drag-Preview hat eine feste Mindestbreite gegen Ein-Buchstabe-Zeilen.
- Lokale Pruefung: `task_381_homebase_fireteam_loadout_flightdeck_polish.gd`, `task_346_homebase_direct_staging_character_popup.gd`, `task_355_homebase_direct_ux_payload_truth.gd`, `task_354_homebase_direct_loadout_regression_matrix.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `task_263_contextual_help_popup_ux_contract.gd`, `task_267_contextual_help_coverage_layout_verifier.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Manueller Sichtcheck fuer die neue Dichte in #10 FIRETEAMS bleibt sinnvoll.

### TASK_382 - Homebase Direct Mission Flightdeck Display
- Status: implementiert
- Stand: Homebase #13 LOADOUT ist als sichtbares Fixed-Layout-Fenster entfernt; der Legacy-Node bleibt versteckt fuer Kompatibilitaet. Der frei gewordene Platz geht an #10 FIRETEAMS und #05 FLIGHTDECK.
- Stand: Homebase-Direct-Payloads merken sich die konkrete Dropship-Craft-ID. Ein auf eine Shipcard gedropptes Fireteam wird direkt auf dieser Dropship-Karte als Payload-Zeile mit Operatorcount angezeigt.
- Stand: Shipcards haben eine `Mission`-Checkbox. Aktiv startet `Send` den bestehenden Homebase-Direct-Missionsstart, inaktiv bleibt `Send` der historische FOB-Transferpfad.
- Lokale Pruefung: `task_382_homebase_direct_mission_flightdeck_display.gd`, `task_381_homebase_fireteam_loadout_flightdeck_polish.gd`, `task_354_homebase_direct_loadout_regression_matrix.gd`, `task_346_homebase_direct_staging_character_popup.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` und `git diff --check` laufen gruen.
- Offene Folgearbeit: Multi-Dropship-Payloads in der Homebase brauchen spaeter einen echten per-Craft-Payload-Store, falls mehrere Homebase-Dropships gleichzeitig beladen werden sollen.

### TASK_383 - Homebase Flightdeck Fireteam Card Single Owner
- Status: implementiert
- Stand: Homebase-Fireteams, die in den Direct-Flightdeck-Payload gezogen wurden, verschwinden aus `#10 FIRETEAMS`. Entfernen aus dem Dropship bringt die Karte wieder in `#10` zurueck.
- Stand: Dropship-Shipcards rendern Payload-Fireteams wieder als kompakte Fireteam-Karte statt nur als Textzeile. Die Karte zeigt Boarding-/Payload-Status, Member-Zeilen und Progressbars; der bestehende Homebase-Direct-Staging-State bleibt die einzige Datenwahrheit.
- Lokale Pruefung: `task_383_homebase_flightdeck_fireteam_card_single_owner.gd`, `task_382_homebase_direct_mission_flightdeck_display.gd`, `task_381_homebase_fireteam_loadout_flightdeck_polish.gd`, `task_355_homebase_direct_ux_payload_truth.gd` und `git diff --check` laufen gruen.

### TASK_384 - Homebase Flightdeck Boarding Hotfix
- Status: implementiert
- Stand: Homebase-Direct-Boarding laeuft automatisch und sequentiell. Direct-Mission-Start und Drop-State werden erst launch-ready, wenn alle Payload-Operator geboardet sind.
- Stand: Dropship-Payload-Fireteam-Karten zeigen Mini-Portraets, Boarding-/Member-Fortschritt und Boarded-Counts, aber keine Loadout-Editor-Controls und keine Loadout-Statuszeile.
- Stand: Homebase-Shipcards sind kompakter, in Zweier-Reihen gerendert und zeigen Payload-/Boarded-Counts im oberen Shipcard-Bereich.
- Lokale Pruefung: `task_384_homebase_flightdeck_boarding_hotfix.gd`, `task_383_homebase_flightdeck_fireteam_card_single_owner.gd`, `task_382_homebase_direct_mission_flightdeck_display.gd`, `task_381_homebase_fireteam_loadout_flightdeck_polish.gd`, `task_355_homebase_direct_ux_payload_truth.gd`, `task_354_homebase_direct_loadout_regression_matrix.gd`, `task_350_homebase_loadout_contract_export.gd`, `task_351_homebase_direct_payload_scope_contract.gd`, `task_352_homebase_loadout_defaults_preserve_unit_profiles.gd`, `task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`, `task_348_homebase_fob_payload_state_isolation.gd`, `task_347_homebase_direct_staging_start_guard.gd`, `task_346_homebase_direct_staging_character_popup.gd`, `task_362_homebase_aircraft_state_manager_extraction.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` und `git diff --check` laufen gruen.

### TASK_385 - Homebase Direct Return Isolation
- Status: implementiert
- Stand: Homebase-Direct-Return-Events werden anhand `mission_drop_source = homebase_direct` als `to_homebase`-Transfer behandelt. Das Dropship bleibt waehrend des Rueckflugs mission-side und wird nach Abschluss wieder in der Homebase sichtbar, ohne eine FOB-Transportkarte zu erzeugen.
- Stand: FOB-Refreshs werden waehrend aktiver Homebase-Direct-Missionen isoliert. Direct-Payload-Fireteams werden dadurch nicht in FOB `#10 FIRETEAMS` gespiegelt, und Direct-Returns rufen kein `clear_mission_boarded_payload()` auf der FOB auf.
- Stand: Homebase-Start faellt weiterhin auf den alten FOB-Launch-Ready-Pfad zurueck, wenn kein Direct-Payload existiert. Ein vorhandener, aber noch nicht fertig geboardeter Direct-Payload blockiert diesen Fallback.
- Stand: Homebase-Direct-Boardingdauer wird pro Operator aus Speed und Discipline berechnet. Durchschnittliche Werte ergeben ca. 4 Sekunden, bessere Werte kuerzen und schlechtere Werte verlaengern das sequentielle Boarding.
- Lokale Pruefung: `task_385_homebase_direct_return_isolation.gd`, `task_348_homebase_fob_payload_state_isolation.gd`, `task_384_homebase_flightdeck_boarding_hotfix.gd`, `task_383_homebase_flightdeck_fireteam_card_single_owner.gd`, `task_382_homebase_direct_mission_flightdeck_display.gd`, `task_381_homebase_fireteam_loadout_flightdeck_polish.gd`, `task_362_homebase_aircraft_state_manager_extraction.gd`, `bugfix_dropship_mission_flow_verifier.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` und `git diff --check` laufen gruen.

### TASK_386 - Homebase Flightdeck Member Portraits
- Status: implementiert
- Stand: Die Dropship-Payload-Fireteamkarte im Homebase-Flightdeck rendert Mini-Portraets jetzt direkt in jeder Operator-Zeile links neben dem Namen. Die separate Portrait-Leiste ueber den Namen wurde entfernt, wodurch die Karte etwas kompakter bleibt.
- Stand: Bestehende Boarding-/Payload-Metadaten bleiben erhalten; die Payload-Karte zeigt weiterhin genau ein Mini-Portraet pro Operator.
- Lokale Pruefung: `task_386_homebase_flightdeck_member_portraits.gd`, `task_384_homebase_flightdeck_boarding_hotfix.gd`, `task_383_homebase_flightdeck_fireteam_card_single_owner.gd`, `task_382_homebase_direct_mission_flightdeck_display.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` und `git diff --check` laufen gruen.

### TASK_387 - Homebase Flightdeck Payload Polish
- Status: implementiert im Arbeitsstand
- Stand: Homebase-Direct-Boarding erzwingt jetzt einen letzten UI-Refresh, wenn der letzte Operator exakt am Ende des Boarding-Intervals fertig wird.
- Stand: Dropship-Payload-Fireteamkarten bleiben Drag-Quellen und koennen zurueck auf `#10 FIRETEAMS` gedroppt werden; das entfernt sie aus dem Dropship und stellt die Fireteam-Karte wieder in `#10` dar.
- Stand: Homebase-Inline-Loadout-Dropdowns nutzen kleine gecachte Waffen-/Kit-Preview-Icons aus `WeaponData`, begrenzt auf die kompakte Dropdown-Groesse. Die Icons sind reine UI-Preview und aendern den Loadout-Contract nicht.
- Stand: Dropship-Payload-Karten blenden Editor-/Debug-Labels wie Lead/Members/Loadout/Kit-/Launch-Payload aus. Die sichtbaren Shipcard-Top-Aktionen `Send` und `Clear` sind entfernt; Destination-Toggle, Pilot, Payload und Shipcard-Remove bleiben erhalten.
- Stand: Das separate `DirectDropshipFireteamPanel` bleibt als Compatibility-/Status-Knoten bestehen, ist aber sichtbar eingeklappt; Direct-Staging wird auf den jeweiligen Dropship-Karten dargestellt.
- Risiken: TASK_388 fuehrt den lokalen Shipcard-Send-Button wieder ein; der TASK_387-Vertrag bleibt auf saubere Payload-Karten, Mini-Portraits und gefaltetes Direct-Staging begrenzt.
- Lokale Pruefung: `task_387_homebase_flightdeck_payload_polish.gd`, `task_386_homebase_flightdeck_member_portraits.gd`, `task_384_homebase_flightdeck_boarding_hotfix.gd`, `task_383_homebase_flightdeck_fireteam_card_single_owner.gd`, `task_382_homebase_direct_mission_flightdeck_display.gd`, `task_381_homebase_fireteam_loadout_flightdeck_polish.gd`, `task_347_homebase_direct_staging_start_guard.gd`, `task_346_homebase_direct_staging_character_popup.gd`, `task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`, `task_355_homebase_direct_ux_payload_truth.gd`, `task_354_homebase_direct_loadout_regression_matrix.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` und `git diff --check` laufen gruen.

### TASK_388 - Homebase Fireteam Roster Shipcard Polish
- Status: implementiert im Arbeitsstand
- Stand: Homebase-Fireteamkarten blenden Loadout-/Lead-/Members-/Kit-/Payload-/Top-Operator-Hilfstexte aus. Die Fireteam-Assign-/Clear-Aktionsreihe bleibt als Kompatibilitaetsknoten vorhanden, ist aber nicht sichtbar.
- Stand: Direct-Homebase-Payloads sind jetzt pro Dropship gespeichert. Fireteam 1 bleibt in Dropship 1 sichtbar, waehrend Fireteam 2 in Dropship 2 gezogen wird; Fireteamkarten kehren erst durch explizites Herausziehen bzw. Remove zurueck nach `#10 FIRETEAMS`.
- Stand: Assigned-Pilot-Karten in Shipcards bleiben Drag-Quellen und koennen auf `Available Operators` zurueckgelegt werden. Das Roster hat eine kompakte Sortierung fuer Leader/Tutor/Pilot hoch/niedrig, XP und Name.
- Stand: Mission-Slots zeigen die echte Nutzung inklusive Piloten ohne Limit-Clamp, und Shipcards haben wieder einen lokalen `Send`-Button fuer Mission- oder FOB-Ziel.
- Risiken: `Tutor Score` ist ein UI-Ranking aus bestehenden Profilwerten, bis ein eigener Tutor-Wert existiert. Der lokale Shipcard-Send nutzt weiter den bestehenden Homebase-Direct-Startpfad und fuehrt keine zweite Missionswahrheit ein.
- Lokale Pruefung: `task_388_homebase_fireteam_roster_shipcard_polish.gd`, `task_387_homebase_flightdeck_payload_polish.gd`, `task_386_homebase_flightdeck_member_portraits.gd`, `task_384_homebase_flightdeck_boarding_hotfix.gd`, `task_383_homebase_flightdeck_fireteam_card_single_owner.gd`, `task_382_homebase_direct_mission_flightdeck_display.gd`, `task_381_homebase_fireteam_loadout_flightdeck_polish.gd`, `task_355_homebase_direct_ux_payload_truth.gd`, `task_354_homebase_direct_loadout_regression_matrix.gd`, `task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`, `task_347_homebase_direct_staging_start_guard.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` und `git diff --check` laufen gruen.

### TASK_389 - Homebase Card Wide Drop Targets
- Status: implementiert im Arbeitsstand
- Stand: `#10 FIRETEAMS` besitzt jetzt explizite Operator-Drop-Zonen fuer Fireteam-Header und Member-Bloecke. Header-Drops fuegen den Operator hinzu und setzen ihn als Lead; Member-Drops fuegen hinzu bzw. verschieben in dasselbe Fireteam.
- Stand: Das bisherige Member-Card-Drop-Signal wird mit eigener Signatur behandelt, sodass Drops auf vorhandene NPC-Karten nicht mehr am alten Zwei-Parameter-Handler haengen.
- Stand: Homebase-Dropship-Shipcards markieren Root, Titel-/Statusflaechen und bestehende Pilot-/Payload-Zonen als Fireteam-Drop-Ziele. Drops auf diese Flaechen nutzen weiter den bestehenden Direct-Payload-/Boarding-State.
- Risiken: Header-Drop ist bewusst Lead-Setzen; falls spaeter getrennte Add-/Lead-Zielzonen gewuenscht sind, braucht das eine sichtbare Zielmarkierung. Die breiteren Drop-Zonen bleiben UI-Eingabe und fuehren keine zweite Gameplay-Wahrheit ein.
- Lokale Pruefung: `task_389_homebase_card_wide_drop_targets.gd`, `task_388_homebase_fireteam_roster_shipcard_polish.gd`, `task_387_homebase_flightdeck_payload_polish.gd`, `task_384_homebase_flightdeck_boarding_hotfix.gd`, `task_383_homebase_flightdeck_fireteam_card_single_owner.gd`, `task_381_homebase_fireteam_loadout_flightdeck_polish.gd` und `git diff --check` laufen gruen.

### TASK_390 - Homebase Direct Mission Transit Cards
- Status: implementiert im Arbeitsstand
- Stand: Homebase-Direct-`Send` erzeugt jetzt einen source-getaggten `to_mission`-Transfer, statt die Mission sofort auf `waiting` zu setzen. Der Mission-Planning-State und die `mission_drop_cards` bekommen waehrend des Timers Fortschritt/ETA und werden in die laufende Mission gespiegelt.
- Stand: Die Mission-Dropship-Karte bleibt waehrend des Direct-Anflugs ausgegraut, zeigt den Fortschrittsbalken und listet die geboardeten Fireteam-Passagiere. Nach Ankunft wechselt sie auf `waiting`; der Payload bleibt bis zum echten LZ-Drop embarked und wird erst danach als aktive Infanterie sichtbar.
- Stand: `mission_drop_source` ist jetzt Teil des Tactical-Planning-Roundtrips, damit Direct-Returns auch aus echten Mission-Events heraus nach Homebase statt in die FOB gehen. Source-getaggte Direct-Transfers bleiben aus FOB-Transportkarten heraus.
- Risiken: Homebase-Shipcards bekommen in diesem Slice noch keine eigene Mission-Transit-Progressanzeige; die Fensternummern-Kollision um Eventlog/Dropship bleibt ein separater Benennungs-/Layout-Task.
- Lokale Pruefung: `task_390_homebase_direct_mission_transit_cards.gd`, `task_385_homebase_direct_return_isolation.gd`, `bugfix_dropship_mission_flow_verifier.gd` laufen gruen. `bugfix_dropship_mission_flow_verifier.gd` meldet am Prozessende bekannte Godot-RID-Leak-Warnungen, aber 116/116 Checks sind gruen.

### TASK_391 - Global Escape Menu and Button SFX
- Status: implementiert im Arbeitsstand
- Stand: `GlobalEscapeMenu` ist als Autoload registriert und faengt Escape global per `_input` ab. Das Shell-Menue bietet Weiter, Einstellungen, Mission speichern/laden, Hauptmenue und Spiel beenden.
- Stand: Buttons ausserhalb der bereits manuell vertonten Hauptmenue-/Lobby-Screens bekommen automatisch denselben UI-Klicksound ueber den bestehenden `AudioEventBus`; dynamisch erzeugte Buttons werden ueber `node_added` nachverdrahtet.
- Stand: Das Escape-Menue speichert Einstellungen ueber `GameSettingsContract` und aktualisiert den AudioEventBus. Das Hauptmenue zeigt Mission speichern/laden und nutzt denselben Shell-Slot.
- Risiken: Der Save/Load-Slice wird zunaechst nur ein Szenenpfad-Shell-Slot, kein vollstaendiges SimulationRoot-/Mission-State-Savegame.
- Lokale Pruefung: `task_391_global_escape_menu_button_sfx.gd`, `task_244_combat_movement_ui_sfx_integration_verifier.gd`, `task_226_main_menu_settings_shell_display_audio_input_gameplay.gd` laufen gruen.

### TASK_392 - Parallel Boarding Transit Feedback
- Status: implementiert im Arbeitsstand
- Stand: Homebase-Direct-Boarding bleibt pro Dropship parallel. Fireteam 1 kann in Dropship 1 weiter boarden, waehrend Fireteam 2 sofort in Dropship 2 startet; beide Payload-Karten bleiben in ihrer jeweiligen Shipcard.
- Stand: Homebase-Shipcards erhalten den vollstaendigen Meta-Transport-Craft-State. Direct-to-Mission-Dropships bleiben waehrend `to_mission` im Flightdeck sichtbar, ausgegraut und mit Fortschrittsbalken; nach Ankunft verschwinden sie aus Homebase und sind in der Mission wieder vollfarbig.
- Stand: Mission-Dropshipkarten unterscheiden jetzt unbedienbaren Transfer von Map-Aktivitaet. `to_mission`/Return-Transit bleibt grau, LZ-Inbound und Deboarding auf der Map bleiben zugaenglich. Embarked Fireteams werden als kompakte Payload-Karten mit Mini-Portraits gerendert.
- Stand: Deboarding nutzt den bestehenden `DROP_UNLOAD_INTERVAL_SECONDS`-Takt, zeigt Progress und meldet `Touchdown`/`Trupp ab` als Card-Feedback statt Touchdown-Bubbles auf noch versteckten Units.
- Risiken: Deboarding-Timing ist ein V1-Wert; spaetere Speed-/Disziplin- oder Dropship-Typ-Varianten sollten als eigener Balancing-Task folgen.
- Lokale Pruefung: `task_392_parallel_boarding_transit_feedback.gd`, `task_390_homebase_direct_mission_transit_cards.gd`, `task_388_homebase_fireteam_roster_shipcard_polish.gd`, `task_385_homebase_direct_return_isolation.gd`, `bugfix_dropship_mission_flow_verifier.gd` und `git diff --check` laufen gruen. `bugfix_dropship_mission_flow_verifier.gd` meldet bekannte Godot-RID-Leak-Warnungen am Prozessende, aber 116/116 Checks sind gruen.

### TASK_393 - Direct Dropship Independence LZ Vector
- Status: implementiert im Arbeitsstand
- Stand: Homebase-Direct exportiert Drop-State jetzt craft-spezifisch. Ein zweiter `Send` aktualisiert die aktive Mission, statt sie zu ersetzen, und bestehende Direct-`mission_drop_cards` werden pro Craft erhalten und gemerged.
- Stand: Direct-Transit-ETA und Fortschritt werden fuer alle aktiven Homebase-Direct-Dropships synchronisiert. Fireteam-Payloadkarten im Dropship aktualisieren sich sichtbar, wenn Operatoren aus `Available Operators` direkt auf die bereits geboardete Fireteamkarte gelegt werden.
- Stand: Mission-LZ-Marker sind groesser, verschwinden nach Touchdown/Deboarding und zeigen vorher einen breiten, halbtransparenten Anflugvektor. TASK_395 wandelt diesen Vektor in eine Pfeilform aus dem geplanten Approach-Ursprung zur LZ um. Friendly-Payload-Lookups finden verschachtelte Unit-Nodes fuer Direct-Drops zuverlaessig.
- Risiken: Der Anflugvektor ist ein breiter transparenter Pfeil; eine gestrichelte Shader-/Materialvariante bleibt optionaler Visual-Polish.
- Lokale Pruefung: `task_393_direct_dropship_independence_lz_vector.gd`, `task_392_parallel_boarding_transit_feedback.gd`, `task_390_homebase_direct_mission_transit_cards.gd`, `task_388_homebase_fireteam_roster_shipcard_polish.gd`, `task_385_homebase_direct_return_isolation.gd`, `bugfix_mission_multi_dropship_cards.gd`, `bugfix_mission_dropship_plans_and_facing.gd` und `git diff --check` laufen gruen.

### TASK_394 - Per Craft Shipcard Commands
- Status: implementiert im Arbeitsstand
- Stand: Homebase-Shipcard-`Send` uebergibt jetzt ein craft-spezifisches Direct-Craft an `MetaLayerFlow`. Der erste Send startet bzw. aktualisiert die aktive Mission im Hintergrund und laesst die Homebase sichtbar, damit andere Dropships sofort weiter boarden oder senden koennen.
- Stand: Direct-`to_mission`-Transfers bleiben pro Craft getrennt: Homebase-Shipcards bleiben waehrend des Flugs grau mit eigenem Fortschritt, Mission-`mission_drop_cards` behalten eigene ETA/Progress/Payloads, und ein zweiter Send ersetzt den ersten nicht.
- Stand: Mission-Dropshipkarten besitzen eigene kleine `LZ`-, `NW/NE/SW/SE`- und `Drop`-Buttons. LZ-Arming speichert das Ziel-Craft bis zum Map-Klick; Card-`Drop` startet nur dieses Craft und blockiert andere wartende Dropships nicht ueber einen globalen Cooldown.
- Stand: Die alten `#18 Mission Control`-Dropship-Controls bleiben als versteckter Kompatibilitaetspfad im Szenenbaum, sind aber nicht mehr die sichtbare Spielersteuerung. Mini-Fireteam-Stance-Toggles nutzen einen eigenen Meta-Key, damit der HUD-Layout-Contract weiterhin die grossen Stance-Buttons prueft.
- Risiken: Eine neue Nutzung des freigeraeumten `#18`-Fensters bleibt ein Folge-Polish. Die versteckten Legacy-Buttons sollten erst entfernt werden, wenn alte Command-/Help-Contracts umgezogen sind.
- Lokale Pruefung: `task_394_per_craft_shipcard_commands.gd`, `task_393_direct_dropship_independence_lz_vector.gd`, `task_392_parallel_boarding_transit_feedback.gd`, `bugfix_mission_multi_dropship_cards.gd`, `task_390_homebase_direct_mission_transit_cards.gd`, `task_180_mission_drop_light_fixed_hud_layout_verifier.gd` und `git diff --check` laufen gruen.

### TASK_395 - Manual Dropship Parallel Flow Stabilization
- Status: implementiert im Arbeitsstand
- Stand: Homebase-Boarding simuliert weiter, aber Flightdeck-/Shipcard-Rebuilds werden waehrend eines aktiven GUI-Drags aufgeschoben. Dadurch bleibt das Dropship-2-Dropziel stabil, waehrend Dropship 1 noch boardet.
- Stand: Homebase-Direct-`Send` aktiviert den `TransportTimer` sofort nach dem Anlegen des craft-spezifischen `to_mission`-Transfers. Homebase- und Mission-Karten koennen dadurch ohne Mission-Map-Navigationsklick weiter Progress anzeigen.
- Stand: Mission-Dropshipkarten seed-en LZ-Scalar-Felder bei mehreren Karten nur noch aus echten positiven LZ-Daten. Eine neue Alpha-LZ loescht Beta-LZ/Approach nicht mehr, und Alpha/Beta koennen parallel inbound gehen.
- Stand: Der 3D-Anflugvektor wird als breite Pfeilform aus dem geplanten Approach-Ursprung zur LZ gerendert. Render-Snapshots melden `dropship_approach_vector_shape = wide_arrow` und `dropship_approach_arrow_count`.
- Risiken: Der Drag-Refresh-Guard verzögert nur die visuelle Rebuild-Aktualisierung waehrend des Drags; Boarding-State laeuft weiter. Die finale Pfeilbreite/-Form bleibt ein manueller FullHD-Sichtcheck.
- Lokale Pruefung: `task_395_manual_dropship_parallel_flow.gd`, `task_394_per_craft_shipcard_commands.gd`, `task_393_direct_dropship_independence_lz_vector.gd`, `task_392_parallel_boarding_transit_feedback.gd`, `task_390_homebase_direct_mission_transit_cards.gd` und `git diff --check` laufen gruen.

### TASK_396 - Mission Dropship LZ Drop Hotfix
- Status: implementiert im Arbeitsstand
- Stand: Homebase-Direct-MissionSetup wird bei spaeter gesendeten Dropships aus dem neuen Payload plus bestehenden Mission-Drop-Karten zusammengezogen. Dadurch bleiben bereits gestartete Payloads erhalten und Beta-/Folge-Dropships finden ihre Friendly-Units in der aktiven Mission.
- Stand: `MissionTestSetup` kann den Friendly-Slot-Vertrag nach Missionsstart nachziehen, ohne die UI zur Gameplay-Wahrheit zu machen. Die eigentliche Sichtbarkeit/Runtime-Aktivierung bleibt beim bestehenden Drop-/Presence-Pfad.
- Stand: Mission-Dropshipkarten zeigen Fortschritt auch fuer `inbound` und `landed`, markieren aktive Approach-Buttons und liefern blockierende Tooltips fuer LZ/Drop. LZ-Labels werden als kurze `LZ1`/`LZ2`-Labels exportiert.
- Stand: Friendly Dropship-LZ-Planmarker bleiben auch bei aktivem Fog-of-War sichtbar; eigene geplante LZs sind Spielerbefehle und duerfen nicht durch die Sichtfilterung verschwinden.
- Risiken: Die finale Label-Groesse und Pfeil-/Marker-Lesbarkeit bleiben ein manueller FullHD-Sichtcheck. Der Runtime-Selection-Refresh ist bewusst auf Friendly-Slots und Direct-Payloads begrenzt.
- Lokale Pruefung: `task_396_mission_dropship_lz_drop_hotfix.gd`, `task_395_manual_dropship_parallel_flow.gd`, `task_394_per_craft_shipcard_commands.gd`, `task_393_direct_dropship_independence_lz_vector.gd`, `task_351_homebase_direct_payload_scope_contract.gd` und `git diff --check` laufen gruen.

### TASK_397 - Mission Dropship UX Hotfix
- Status: implementiert im Arbeitsstand
- Stand: Mission-Dropshipkarten rendern die `NW`/`NE`/`SW`/`SE`-Approach-Buttons wieder als kompaktes 2x2-Feld, damit die Kartenseite weniger sperrig wirkt.
- Stand: Der Anflugvektor ist wieder klarer als gruener Streifen/Pfeil lesbar: breiter, deckender und mit kleinerem Pfeilkopf statt einem kaum sichtbaren Linienrest.
- Stand: Ein zweites Dropship kann seinen Drop starten, waehrend das erste bereits im Deboarding ist; der Test sichert Alpha `unloading` plus Beta `inbound` als getrennte Live-Sequenzen ab.
- Stand: Legacy-2D-Unit-CanvasItems werden in der Primary-2.5D-Ansicht nach Runtime-Selection-Refresh und Drop-Presence-Updates erneut ausgeblendet, damit alte Kenney-NPC-Sprites nicht mitzoomen.
- Risiken: Die finale Proportion der rechten Dropshipkarten und des gruenen Streifens bleibt ein manueller FullHD-Sichtcheck.
- Lokale Pruefung: `task_397_mission_dropship_ux_hotfix.gd`, `task_396_mission_dropship_lz_drop_hotfix.gd`, `task_395_manual_dropship_parallel_flow.gd`, `task_394_per_craft_shipcard_commands.gd` und `git diff --check` laufen gruen.

### TASK_398 - Mission Dropship Outbound Command Hotfix
- Status: implementiert im Arbeitsstand
- Stand: `outbound` ist wieder eine aktive Map-Flugphase: die Dropshipkarte bleibt nicht grau, solange das Schiff sichtbar zum Exit-/Approach-Rand fliegt. Erst danach wechselt die Karte in `to_fob` oder bei Homebase-Direct in `to_homebase`.
- Stand: Der automatische Meta-Return wird nicht mehr beim Start der Outbound-Phase angefordert, sondern erst ueber den Transit-Card-State nach dem sichtbaren Abflug. Damit bleibt das Schiff waehrend des Abflugs als Missionsobjekt erhalten.
- Stand: Dropship-Command-Buttons koennen direkt aus unselektierten Karten gedrueckt werden; der Card-Selection-Handler ignoriert echte Command-Button-Hitboxes.
- Stand: Approach-Buttons sind etwas groesser und nutzen dieselbe Schriftgroesse wie LZ/Drop. Embarked Fireteams werden links nicht mehr als normale Ground-Fireteam-/Memberkarten dupliziert, solange sie noch im Dropship sitzen.
- Risiken: Air-Asset-Abschuss selbst bleibt ein separater Combat-/Gameplay-Task; dieser Task stellt nur die korrekte aktive Outbound-UI-Phase sicher.
- Lokale Pruefung: `task_398_mission_dropship_outbound_command_hotfix.gd`, `task_397_mission_dropship_ux_hotfix.gd`, `task_396_mission_dropship_lz_drop_hotfix.gd`, `task_395_manual_dropship_parallel_flow.gd`, `task_394_per_craft_shipcard_commands.gd` und `git diff --check` laufen gruen.

### TASK_399 - Dropship Flow Contract Performance Pass
- Status: implementiert im Arbeitsstand
- Stand: `docs/dev/homebase_direct_dropship_flow_contract.md` haelt den gewuenschten Homebase-Direct-Dropship-Ablauf als Contract fest: FOB umgehen, Fireteamkarten mit einzelner Wahrheit, paralleles Boarding/Send/Drop, per-Craft-LZ/Approach und aktive Outbound-Map-Phase.
- Stand: Mission-Dropship-Runtime-Feedback nutzt jetzt einen kurzen Throttle, damit Unloading- und Parallel-Drop-Sequenzen nicht mehr bei jedem Simulationsschritt komplette HUD-Rebuilds und Planning-State-Emits erzwingen.
- Stand: Parallele Dropships aktualisieren weiterhin ihre Card- und World-Overlay-Daten pro Bewegungsschritt, flushen teures UI-/Planning-Feedback aber nur getaktet oder bei wichtigen Phasen-/Unit-Wechseln.
- Stand: Die rekursive Legacy-2D-Unit-Suppression wird im normalen HUD-Refresh gecacht. Explizite Suppression und Drop-Presence-Updates koennen alte Sprite-Kinder weiter ausblenden.
- Risiken: Falls die Vorschau weiter schwer wirkt, braucht es danach einen echten Godot-Profiler-Task. Mission-Dropship-Card-Pooling bleibt separat.
- Lokale Pruefung: `task_399_dropship_flow_contract_performance_pass.gd`, `task_398_mission_dropship_outbound_command_hotfix.gd`, `task_397_mission_dropship_ux_hotfix.gd`, `task_396_mission_dropship_lz_drop_hotfix.gd`, `task_395_manual_dropship_parallel_flow.gd`, `task_394_per_craft_shipcard_commands.gd` und `git diff --check` laufen gruen.

### TASK_329 - Manual Playtest Stabilization GDD Godot Fix Pass
- Status: implementiert im Arbeitsstand
- Stand: Dropship-Visuals bauen ihre Dirty-Signatur wieder fehlerfrei, geplante LZs bleiben auch bei offmap/hidden Craft sichtbar, und Multi-Dropship-Payloads werden aus dem rohen Mission-Card-State statt aus stale Selected-Card-State uebernommen.
- Stand: Aktive Drop-Sequenzen sind an ihr Craft, ihre LZ, ihren Approach und ihre Payload-Fireteam-IDs gebunden. Mission Control kann waehrend Dropship 1 inbound ist Dropship 2 auswaehlen und dessen LZ/Approach bearbeiten; ein weiterer Drop wird bei belegter Air Lane sichtbar geblockt statt als versteckte Queue zu laufen.
- Stand: Geplante LZs werden pro Dropship benannt (`LZ Dropship X`). Eine neu gesetzte LZ ersetzt nur die alte LZ desselben Dropships; aktive Deploy-/Presence-Effects verwenden weiter die Sequenz-LZ des ausfuehrenden Crafts.
- Stand: Wartende Mission-Dropships bleiben offscreen; sie werden ueber Karte/Status/Plan-LZ gefuehrt, aber nicht mehr als wartendes Modell bei der Dropshipkarte oder an der Map-Kante geparkt.
- Stand: RMB-Testziele werden nicht mehr doppelt auf Tile-Mitten verschoben, Feedback-Bubbles werden erst nach Visual-Tauglichkeit dedupliziert, und der FOB-Loadout zeigt kompakte Name/Portrait-Karten als Character-Sheet-Oeffner.
- Stand: Multiplayer-Lobby bleibt in einem festen Panel mit internem Scrollbereich. Die Map-Editor-Palette behaelt Gruppierung und bietet zusaetzlich `Alle` als vollstaendige Langliste.
- Stand: Godot 4.6.2 ist in AGENTS/Projektregeln/Decisions und Performance-Budget-Contract vereinheitlicht. `sternenbuerger-gdd.docx` ist als Alt-GDD/Inspiration und Migrationsquelle dokumentiert, nicht als bindende zweite Wahrheit.
- Risiken: Manueller FullHD-Sichtcheck und echte UPnP-/Router-Erreichbarkeit bleiben ausserhalb der Headless-Gates. DOCX-Ideen duerfen erst nach Markdown-Migration bindend werden.
- Lokale Pruefung: `task_258_fixed_window_clipping_scrollbar_playability_audit.gd`, `bugfix_multiplayer_lobby_setup_and_asset_catalog_followup.gd`, `task_259_character_card_roster_switching_playability.gd`, `bugfix_character_team_editor_usability_pass.gd`, `task_310_fob_flightdeck_fireteam_userology_smoke.gd`, `bugfix_mission_multi_dropship_cards.gd`, `bugfix_mission_dropship_plans_and_facing.gd`, `task_313_dropship_arrival_visibility_feedback_smoke.gd`, `task_279_lz_security_air_asset_tactical_playability_smoke.gd`, `bugfix_mission_right_click_order_flow.gd`, `bugfix_mission_fire_sector_overlay.gd`, `task_158_verifier.gd`, `task_160_tactical_playability_verifier.gd`, `task_186_mission_map_unit_presence_registry_audit.gd`, `task_192_mission_map_npc_behavior_playability_smoke.gd`, `task_250_asset_audio_background_playability_smoke.gd`, `task_286_ui_feedback_truth_regression_review.gd`, `bugfix_dropship_mission_flow_verifier.gd` und `task_222_performance_regression_gate_and_manual_profile_checklist.gd` laufen gruen.

### TASK_320 - Manual Playtest Dropship Cards Per-Craft Dispatch and Return
- Status: implementiert
- Stand: Homebase `#05 FLIGHT DECK` rendert Shipcards kompakter ohne horizontalen Scrollbalken. Das Dropship-Visual ist im kleineren Sichtfenster nach links/oben eingerueckt, damit transparente Asset-Raender weniger Leerraum erzeugen und die Pilotenkarte mehr Breite bekommt.
- Stand: FOB-Dropship-Karten zeigen Fireteam-/Insassenreferenzen jetzt auch fuer nicht selektierte Dropships. Ein voll/boarded Dropship kann einzeln zur Mission Map geschickt werden, ohne auf ein zweites Dropship oder dessen Auswahlzustand zu warten.
- Stand: Mission-Dropship-Karten behalten pro Craft die eigene Payload und LZ-/Approach-Planung. Waiting-Karten haben einen `FOB`-Button fuer direkte Rueckkehr; Dropships fliegen nach erfolgreichem Drop weiter automatisch zur FOB zurueck. Manuelle Rueckkehr mit noch sitzenden Truppen loescht die Payload nicht, der automatische Leer-Rueckflug nach Drop dagegen schon.
- Stand: Beim Absetzen meldet der Drop-Flow `TOUCHDOWN`; beim Aussteigen sagen die Units kurz `AB`.
- Risiken: Der finale FullHD-Sichtcheck der Homebase-Shipcard-Proportionen bleibt manuell sinnvoll, weil Headless-Tests Clipping und Statusvertraege, aber nicht die exakte optische Balance bewerten.
- Lokale Pruefung: `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `bugfix_mission_multi_dropship_cards.gd`, `bugfix_dropship_mission_flow_verifier.gd`, `bugfix_fob_second_dropship_assignment_and_scale.gd`, `task_308_compact_flightdeck_dropship_occupants_actions.gd`, `task_312_dropship_command_matrix_lz_go_layout.gd`, `task_313_dropship_arrival_visibility_feedback_smoke.gd`, `task_180_mission_drop_light_fixed_hud_layout_verifier.gd`, `task_316_fob_fireteam_staging_migration.gd` und `git diff --check` laufen gruen.

### TASK_321 - Manual Playtest Map Editor Station Floor Layering Undo
- Status: implementiert
- Stand: `station_floor_panel` ist jetzt eine Terrain-/Surface-Variante statt ein Object-Layer-Prop. In der 3D-Ansicht wird es als top-anchored Boden gerendert; Station-Wall-Tiles nutzen darunter ebenfalls das Station-Floor-Panel, damit Station-Gebaeude einen passenden Boden behalten.
- Stand: `station_wall` und `station_wall_door` liegen auf einer Structure-Schicht. Station-Props wie Med Bed, Computer oder Cargo koennen dadurch zusaetzlich auf demselben Tile in `object_type_id` liegen, ohne die Wand zu verdraengen. Der Eraser entfernt zuerst das Prop und erst im zweiten Pass die Struktur.
- Stand: Der Map Editor hat einen 32-Schritt-Undo-Stack, textgrosse Preview-Icons in allen Palette-Gruppen, einen etwas klareren Panel-Skin und blockt Patrol-Waypoints ausserhalb echter Map-Tiles.
- Stand: Ground-Surface-Modelle koennen jetzt einen eigenen `surface_top_y_offset` melden. Das `station_floor_panel` nutzt dadurch den Mapping-Offset und sitzt mit seiner sichtbaren Oberkante auf derselben Hoehe wie die Station-Floor-Unterlagen der Waende.
- Risiken: Das Datenmodell bleibt bei Terrain/Structure/Object in zwei gespeicherten Type-Feldern; ein echtes drittes Floor-Feld gibt es noch nicht. Fuer Station-Waende wird der passende Floor deshalb ueber den 3D-Surface-Override erzeugt.
- Lokale Pruefung: `bugfix_map_editor_station_floor_structure_undo.gd`, `task_229_map_editor_usability_authoring_pass.gd`, `task_295_map_editor_paint_toolbar_tools_polish.gd`, `task_296_map_editor_palette_taxonomy_space_station_assets.gd`, `task_298_editor_terrain_visual_playability_smoke.gd`, `editor_height_edge_surface_anchor_verifier.gd`, `hill_mechanics_16x16_testmap_verifier.gd`, `task_292_editor_hill_cliff_grid_depth_repair.gd`, `task_253_nature_ground_surface_editor_palette_pass.gd`, `task_183_editor_hill_authoring_verifier.gd`, `task_254_nature_trees_rocks_vegetation_cover_props.gd`, `task_132_verifier.gd` und `git diff --check` laufen gruen.

### TASK_319 - Manual Playtest FOB Second Dropship Assignment and Scale
- Status: implementiert
- Stand: `#14 FLIGHTDECK` speichert die FOB-Boarding-/Staging-Queue jetzt pro Transport-Craft-ID. Ein Fireteam, das auf `Dropship 2` gedroppt wird, bleibt damit auf `Dropship 2` und rutscht nicht mehr automatisch in die Queue von `Dropship 1`.
- Stand: Transport-Craft-Karten im FOB sind klickbar/selectable, behalten dedizierte Drop-Ziele wie `dropship|dropship_2` und rendern das Dropship-Bild groesser mit Covered-Crop gegen transparente Asset-Raender.
- Stand: FOB-Transportkarten erlauben Pilot-Drag-and-Drop: ein Pilot kann in den PC-Pool zurueckgezogen, ein anderer PC auf die Shipcard gedroppt und der alte Pilot beim Swap automatisch in den Pool zurueckgelegt werden.
- Risiken: Der Patch bleibt im FOB-UI-/Meta-Staging-State und macht keine SimulationRoot-Gameplay-Wahrheit daraus. Manueller Sichtcheck in FullHD bleibt fuer finale Proportionen der Shipcards sinnvoll.
- Lokale Pruefung: `bugfix_fob_second_dropship_assignment_and_scale.gd`, `task_316_fob_fireteam_staging_migration.gd`, `task_308_compact_flightdeck_dropship_occupants_actions.gd`, `task_310_fob_flightdeck_fireteam_userology_smoke.gd`, `bugfix_dropship_mission_flow_verifier.gd` und `git diff --check` laufen gruen.

### TASK_318 - Manual Playtest Debrief Background and Main Menu Team Library
- Status: implementiert
- Stand: `DebriefTestScreen` nutzt jetzt den katalogisierten Background `debrief_desert_explosion_base` mit Dim-Shade und dokumentierter Readability-Policy. Das bleibt rein visuell und erzeugt keinen Gameplay-State.
- Stand: Das Hauptmenue zeigt unter Teamname/Neues Team eine Liste der erstellten Teams aus aktuellem Roster-Save plus archivierten Reset-Saves. Das aktive Team ist sichtbar ausgewaehlt; Archivteams koennen markiert und geloescht werden, waehrend das aktive Team gegen versehentliches Loeschen geschuetzt bleibt.
- Risiken: Es gibt weiterhin nur ein aktives lokales Roster pro Profil; die Liste ist eine UI auf Current-Save plus Reset-Archive, kein neues Kampagnen- oder Multiplayer-Teamslot-System.
- Lokale Pruefung: `bugfix_debrief_background_and_main_menu_team_library.gd`, `task_245_background_image_catalog_and_screen_usage_verifier.gd`, `task_234_persistent_player_roster_save_and_reset.gd` und `git diff --check` laufen gruen.

### TASK_317 - Manual Playtest Mission Fireteam FOB Payload and Bubbles
- Status: implementiert
- Stand: MissionStart uebergibt jetzt neben Unit-/Fireteam-IDs auch die FOB-Unit-Konfigurationen an `MissionTestSetup`. Die Mission spiegelt damit die in der FOB zusammengestellten Fireteam-Mitglieder, Namen, Profile und Portraits statt auf generische Preset-Fallbacks zu fallen.
- Stand: `MissionTestSetup` priorisiert Fireteam-Definitionen fuer Mitgliedschaft und Lead-Markierung. `#17 SELECTED FIRETEAM` und die Fireteam-Mini-Karte zeigen dadurch den konfigurierten FOB-Fireteam-Lead inklusive Portrait.
- Stand: HUD-Sprechblasen an Fireteam-Mini-Karten sind kleiner, starten rechts neben der Karte und werden vertikal versetzt, wenn mehrere Bubbles sonst uebereinander liegen wuerden.
- Risiken: Manueller FullHD-Sichtcheck der genauen Bubble-Optik bleibt sinnvoll; der Patch veraendert keine SimulationRoot- oder Combat-Wahrheit.
- Lokale Pruefung: `bugfix_mission_fireteam_fob_payload_and_bubbles.gd`, `task_210_fireteamleader_command_feedback_bubbles.gd`, `task_087_verifier.gd`, `task_160_tactical_playability_verifier.gd`, `task_316_fob_fireteam_staging_migration.gd`, `bugfix_dropship_mission_flow_verifier.gd` und `git diff --check` laufen gruen.

### TASK_322 - Manual Playtest Map Editor Asset Import Rotation Context Menu
- Status: implementiert im Arbeitsstand
- Stand: Factory Kit, isometrische Space-Interior-/Space-Kit-Ergaenzungen und weitere Kenney-Assets sind projektlokal in die Editor-Kataloge/Mappings aufgenommen. Die Asset-Pfade bleiben `res://...`-basiert.
- Stand: Rotierbare Station-/Modular-/Factory-Assets koennen ueber die Editor-UI gedreht werden; das Kontextmenue wird erst auf rechter-Maus-Release geoeffnet, damit Area-Markierung mit rechter Maus nicht sofort abbricht.
- Stand: Palette-Previews und Help-Anker wurden fuer neue Assetgruppen, Marker und Settings nachgezogen.
- Risiken: Einzelne Previews und Asset-Scales brauchen weiter manuellen Sichtcheck; importierte Deko darf nicht unbemerkt Gameplay-Blocker werden.
- Lokale Pruefung: `bugfix_map_editor_asset_rotation_context_menu.gd`, `bugfix_editor_hill_marker_asset_import.gd`, `task_251_nature_kit_classic_source_inventory_and_subset_import.gd`, `run_task_247_asset_locality_scan.ps1`, `task_296_map_editor_palette_taxonomy_space_station_assets.gd` und `git diff --check` laufen gruen.

### TASK_323 - Manual Playtest Mission Command Visuals Fire Sector Dropships
- Status: implementiert im Arbeitsstand
- Stand: Mission-Fire-Sector-Visuals sind tile-aligned und melden sichtbare Tiles, LOS-Blocker und Facing/Aim getrennt im Render-Snapshot. Der Scan ist auf den Waffenradius begrenzt, nutzt einen LOS-Blocker-Cache und begrenzt Debug-Linien, damit das Overlay nicht pro Tick ueber die ganze Map frisst.
- Stand: Die Blick-/Sichtbereichsrichtung folgt der sichtbaren 3D-Proxy-Drehung der NPCs, damit Facing-Linie, Sichtkegel und Modellrotation zusammenlaufen.
- Stand: Dropship-Karten auf der Mission Map koennen das aktive Craft fuer Mission-Control-LZ-/Drop-Kommandos setzen. Waiting-Dropships bleiben als kommandierbare Karten sichtbar; Offmap-Inbound/RTB zeigt Karten-Progress, rendert aber kein Schiff neben der Karte.
- Stand: Nach dem Absetzen wird ein outbound Dropship in den RTB-Kartenstatus uebergeben, damit ein zweites Dropship den naechsten Drop starten kann, waehrend das erste weiter zur FOB verfolgt wird.
- Stand: Command-Matrix-/Plan-/Go-Verhalten ist fuer den aktuellen Arbeitsstand dokumentiert; die alte fachliche Unklarheit zwischen Plan/Go/Ready bleibt als Folgeentscheidung fuer Command-Hierarchy-Politur sichtbar.
- Risiken: Fire-Sector-Winkel, Facing-Lesbarkeit und die genaue Bedeutung von Move/Take/Hold/Flag/Target/Clear brauchen weiter manuelle Mission-Abnahme und ggf. einen separaten Folge-Task.
- Lokale Pruefung: `bugfix_mission_fire_sector_overlay.gd`, `bugfix_mission_multi_dropship_cards.gd`, `bugfix_dropship_mission_flow_verifier.gd`, `task_313_dropship_arrival_visibility_feedback_smoke.gd`, `task_180_mission_drop_light_fixed_hud_layout_verifier.gd`, `task_315_mission_grid_tile_selection_command_gate.gd`, `task_230_flight_altitude_layer_and_air_visibility_audit.gd` und `git diff --check` laufen gruen.

### TASK_324 - Manual Playtest Team Editor Character Overlay Usability
- Status: implementiert im Arbeitsstand
- Stand: Team-Erstellung und Teambearbeitung sind als eigene Editor-Ansicht dokumentiert, statt grosse Portrait-/Editorflaechen direkt in den Hauptscreen zu legen. Bestehende Teams koennen zur Bearbeitung geoeffnet werden.
- Stand: Character-Overlay/Team-Editor erlauben Name-/Portrait-Anpassung, Plus-/Minus-Wertbearbeitung, Live-Aktualisierung abgeleiteter Werte, Punktebudget und Help-Popups fuer Werte, Traits, Rollen und Skills.
- Stand: Die alten 6er-/9er-Tabs sind entfernt; der Team-Editor bleibt in der Blatt-Ansicht. Wertaenderungen senden nur noch kleine Daten-Payloads statt zyklischer UI-/Budget-Zeilen und loesen keinen sofortigen Full-Refresh im laufenden Signal mehr aus.
- Stand: Kurzbeschreibung ist aus dem Vordergrund genommen; letzte Ausruestung wandert nach unten. Zusaetzliche Flug-/Pilotenwerte sind als fachlicher Bedarf fuer gute Dropshippiloten notiert.
- Risiken: Punktebudget und Flugwerte sind noch Rookie-/Authoring-Vertraege, kein finales Progressionsbalancing. Teamgroesse und Multiplayer-Grenzen brauchen spaeter eigene Balance-Entscheidung.
- Lokale Pruefung: `bugfix_character_team_editor_usability_pass.gd`, `task_235_character_sheet_roster_gameplay_expansion.gd`, `task_259_character_card_roster_switching_playability.gd`, `task_265_character_sheet_loadout_help_content_pass.gd` und `git diff --check` laufen gruen.

### TASK_325 - Manual Playtest Documentation Backfill
- Status: implementiert
- Stand: Die Playtest-Aenderungen der letzten Stunden sind als `TASK_317` bis `TASK_324` nachdokumentiert. `docs/reports/manual_playtest_session_backfill_2026_05_10.md` fasst den Arbeitsblock zusammen.
- Stand: `docs/TASK_ROADMAP.md` enthaelt die neue Backfill-Phase `18ZD`; der Playtest-Audit reserviert seine empfohlenen Folgepatches jetzt ab `TASK_326`, damit keine Nummernkollision entsteht.
- Risiken: Der Backfill ersetzt keine manuelle Abnahme; er macht den aktuellen Branch-Stand nachvollziehbar.
- Lokale Pruefung: `rg "TASK_317|TASK_318|TASK_319|TASK_320|TASK_321|TASK_322|TASK_323|TASK_324|TASK_325" docs` und `git diff --check` laufen gruen.

### TASK_326 - Manual Playtest Multiplayer Setup Asset Catalog Floor Followup
- Status: implementiert im Arbeitsstand
- Stand: Die Multiplayer-Lobby hat jetzt Spielername, lokalen Roster, Spielerseite, Teammodus, Map-Auswahl und Verbindungsmodus. Die Session fuehrt `lobby_setup` in Snapshot und Start-Assignments mit.
- Stand: Direct-IP-Internet wird nicht mehr als LAN-only beschrieben: Der Screen nennt UDP-Portfreigabe/Firewall/Router oder VPN als Voraussetzung; Relay/UPnP bleibt Folgearbeit.
- Stand: Importierte Space-/Station-/Modular-/Factory-Assets werden im Editor dynamisch in vorhandene Palette-Gruppen einsortiert. Crater/Meteor/Rock landen bei Crater/Felsen, Walls/Doors/Gates bei Waende.
- Stand: Nature-Boden rendert als flushes Ground-Surface-Visual statt als erhoehter Detail-Layer. Station-Set-Floor-Panel-Varianten sowie `station_set_floor_corner`, `station_set_floor_detail` und `modular_floor_raised` sind Terrain-/Surface-Varianten und werden top-anchored gerendert; Terrain-Surface-Modelle respektieren jetzt ihre Mapping-Scale, damit Modular-Floors nicht mehr in der falschen Groesse erscheinen.
- Risiken: Direct-IP funktioniert ueber Internet nur bei erreichbarem Host-UDP-Port oder VPN. Die Kit-Einsortierung ist namensbasiert und kann fuer einzelne Spezialassets noch manuell nachjustiert werden.
- Lokale Pruefung: `bugfix_multiplayer_lobby_setup_and_asset_catalog_followup.gd`, `task_231_app_shell_game_setup_integration_and_open_items_review.gd`, `task_253_nature_ground_surface_editor_palette_pass.gd`, `task_255_nature_kit_hill_playability_visual_performance_smoke.gd`, `hill_mechanics_16x16_testmap_verifier.gd`, `bugfix_map_editor_station_floor_structure_undo.gd`, `task_266_command_mission_editor_settings_help_content_pass.gd` laufen gruen.

### TASK_327 - Manual Playtest Right Click Orders Tactics Dropship Visibility
- Status: implementiert im Arbeitsstand
- Stand: Rechtsklick auf der Mission Map setzt jetzt den naechsten Befehl und ersetzt ohne Shift die vorherige pending Waypoint-/Area-Order des Fireteams. `Shift+RMB` haengt bewusst einen Folgebefehl an. Rechtsklick-Drag baut eine Tile-Area-Vorschau auf und oeffnet das Area-Kontextmenue erst beim Loslassen.
- Stand: Abgeschlossene Waypoints werden in der Primary-3D-Order-Schicht nicht mehr weiter als Route/Tile angezeigt. Nach abgearbeiteter Kette faellt das Fireteam ueber den bestehenden Default-Hold wieder in Sicherung.
- Stand: Post-Drop-Sicherung richtet sich an Objective/benachbarten Fireteams aus, laesst maximal eine Rueckwaertsicherung entstehen und sucht fuer die Sicherungspositionen bevorzugt nahe Deckung. Facing-Metadaten treiben jetzt die Sicht-/Feuersektoren, damit Modellrotation und Blickrichtung nicht links/rechts auseinanderlaufen.
- Stand: Dropship-Planvisuals koennen LZ und Approach-Linie pro Craft anzeigen, auch wenn das Craft selbst offmap/inbound als Modell verborgen bleibt. Approach-Wechsel aktualisieren die geplante Linie des selektierten Dropships sofort.
- Stand: Ein lokaler ENet-Connectivity-Smoke prueft Host/Client ueber `127.0.0.1`; echte Internet-Erreichbarkeit bleibt Router/Firewall/VPN-abhaengig.
- Risiken: Echte NAT-/Router-Verbindung kann lokal nicht voll abgenommen werden. Die exakte taktische Sektorbreite und Cover-Auswahl brauchen weiter manuelles Spielgefuehl-Balancing.
- Lokale Pruefung: `bugfix_mission_right_click_order_flow.gd`, `bugfix_mission_dropship_plans_and_facing.gd`, `bugfix_multiplayer_enet_connectivity_smoke.gd`, `bugfix_mission_multi_dropship_cards.gd`, `bugfix_dropship_mission_flow_verifier.gd`, `bugfix_mission_fire_sector_overlay.gd` und `git diff --check` laufen gruen.

### TASK_328 - Manual Playtest Marker Help Roster UPnP Followup
- Status: implementiert im Arbeitsstand
- Stand: Mission-Auswahl- und Bewegungsgruppenmarker werden auf gueltige Map-Tiles gesnappt. Offmap-Positionen werden aus der Auswahl und aus den Movement-Group-Markern entfernt, damit keine versetzten gelben Rauten neben der Karte stehen bleiben.
- Stand: Charakter-/Team-Hilfen wurden fuer Werte, Plattformwerte, abgeleitete Funktionswerte und Rang-Badges erweitert. Badges wie Shooter, Leader und Pilot tragen dynamische Hover-Daten mit Quelle, Schwelle und Score-Zusammensetzung; dieselben Metadaten sind in Homebase/FOB-Karten verfuegbar.
- Stand: Multiplayer verwendet standardmaessig lokale Spieler-Roster, die Lobby waehlt den aktiven lokalen Roster vor und bietet UPnP als Verbindungsmodus. Beim Hoststart versucht die Session eine UDP-Portfreigabe am Gateway und meldet den Mapping-Status im Snapshot.
- Risiken: UPnP ist router-/firewallabhaengig und kann lokal nicht als echte Internet-Erreichbarkeit bewiesen werden. Tooltip-Formeln muessen bei zukuenftigen Badge-Balancing-Aenderungen synchron gehalten werden.
- Lokale Pruefung: `bugfix_character_team_editor_usability_pass.gd`, `bugfix_mission_dropship_plans_and_facing.gd`, `bugfix_multiplayer_lobby_setup_and_asset_catalog_followup.gd` sowie Check-only-Laeufe fuer die betroffenen Terrain-, Meta-, UI- und Multiplayer-Skripte laufen gruen.

### TASK_177 - Drop Light Fixed UI Layout Contract
- Status: implementiert
- Stand: `scripts/meta/drop_light_layout_contract.gd` definiert den gemeinsamen `drop_light`-Vertrag fuer feste Full-HD-Screens, 8-px-Raster, maximal 6-px-Panelradius, quadratische Action-Buttons, erlaubte Projektassets und feste Panel-Rechtecke fuer FOB, Homebase und Mission-HUD.
- Stand: FOB ist fuer TASK_178 konkret vorbereitet: `#14 FLIGHTDECK` ist breiter als `#13 LOADOUT`, `#13 LOADOUT` bleibt bewusst schmaler, Boarding Status und Actions liegen unten als feste Fenster. Mission ist explizit HUD-only; TerrainMap3DView, SimulationRoot und weitere Runtime-Ziele sind als verbotene Mission-Umbauziele dokumentiert.
- Offene Punkte: Der Vertrag ist umgesetzt; sichtbare Folgearbeiten fuer Homebase und Mission-HUD bleiben eigene Tasks.
- Risiken: Wenn Folgetasks nur den Skin statt feste Fenster umsetzen, bleibt das Layoutziel unerfuellt. Mission-HUD und Mission-Map duerfen weiterhin nicht vermischt werden.
- Lokale Pruefung: `task_177_drop_light_fixed_ui_layout_contract_verifier.gd`, `task_164_ui_theme_component_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Manueller Sichtcheck fuer FOB/Homebase und danach TASK_180 fuer das Mission-HUD.

### TASK_178 - FOB Drop Light Fixed FullHD Layout
- Status: implementiert
- Stand: `FOBTestScreen` wendet den `DropLightLayoutContract` als feste FullHD-UI-Schicht an. Die Runtime-Node-Pfade bleiben stabil; Gameplay-Wahrheit bleibt weiter in den bestehenden Meta-/Mission-State-Pfaden.
- Stand: Die FOB-Hauptaufteilung folgt jetzt `#10 FIRETEAMS`, `#13 LOADOUT` und einem breiteren `#14 FLIGHTDECK`. TASK_314 reaktiviert die alte Available-Operators-Spalte als festes `#09 NPC POOL` links neben `#10`, damit unzugewiesene FOB-NPCs wieder sichtbar in Fireteams gezogen werden koennen.
- Stand: `#14 FLIGHTDECK` rendert Transport-Craft-Karten mit vorhandenen Kenney-Space-Kit-Assets. Die Transport- und unteren Actionbuttons sind quadratisch. Eine feste Bottom-Row zeigt Boarding Status und Actions; Board/Send rufen nur vorhandene FOB-Callbacks auf und speichern keinen eigenen Gameplay-State.
- Offene Punkte: Manueller Godot-Sichtcheck in FullHD bleibt fuer finale optische Einrueckung, Lesbarkeit und Flightdeck-Proportionen offen.
- Risiken: Die Umsetzung nutzt bewusst eine Layout-Schicht ueber den bestehenden Containern. Falls spaeter pixelgenaue absolute Positionierung gebraucht wird, sollte das als kleiner Folgetask erfolgen, ohne die Meta-State-Pfade umzubauen.
- Lokale Pruefung: `task_178_fob_drop_light_fixed_fullhd_layout_verifier.gd`, `task_176_fob_loadout_weapon_preview_selector_verifier.gd`, `task_096_recovery_verifier.gd`, `task_114_meta_recovery_verifier.gd`, `bugfix_dropship_mission_flow_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Manuellen FOB-Sichtcheck ausfuehren; danach TASK_180 fuer das Mission-HUD.

### TASK_179 - Homebase Drop Light Fixed FullHD Layout
- Status: implementiert
- Stand: `HomebaseTestScreen` setzt Topbar, Mission Brief, Roster, Transfer Team, Flightdeck und Character Sheet als echte feste FullHD-Fenster. Der Verifier prueft nach mehreren Frames `global_position` und `size` gegen den `DropLightLayoutContract`.
- Stand: `#05 FLIGHT DECK` besitzt jetzt eine read-only Visual-Buehne mit Pad-/Craft-/Stack-Darstellung aus bestehenden Transportdaten. Die Buehne nimmt keinen Input an und speichert keinen eigenen Vehicle- oder Transfer-State.
- Stand: Homebase nutzt fuer Flightdeck/Shipcards Projektassets unter `res://Assets/kenney_space-kit/Isometric/...`; der Frachterpfad wurde auf die isometrische Projektgrafik umgestellt.
- Offene Punkte: Manueller Godot-Sichtcheck in FullHD bleibt fuer finale Lesbarkeit, Einrueckung und die optische Wirkung der top-level-Fenster offen.
- Risiken: Die Hauptfenster sind bewusst fest positioniert, waehrend lange Inhalte weiterhin ueber gezielte Scrollbereiche laufen. Weitere Homebase-Politur darf Pilot-/Cargo-/Transferfluesse nicht in UI-State duplizieren.
- Lokale Pruefung: `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `task_177_drop_light_fixed_ui_layout_contract_verifier.gd`, `task_178_fob_drop_light_fixed_fullhd_layout_verifier.gd`, `task_096_recovery_verifier.gd`, `task_114_meta_recovery_verifier.gd`, `bugfix_dropship_mission_flow_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Manuellen Homebase-Sichtcheck ausfuehren; danach TASK_180 fuer das Mission-HUD nach `d_mission.svg`.

### TASK_180 - Mission Drop Light Fixed HUD Layout
- Status: implementiert
- Stand: Das Mission-HUD nutzt den `DropLightLayoutContract` jetzt HUD-only als feste Full-HD-Schicht. Mission Identity, Topnav, Fireteam-Mini, BottomDock, `#16 COMMAND MATRIX`, `#17 SELECTED FIRETEAM` und `#18 MISSION CONTROL` werden als echte feste Controls mit `global_position` und `size` gegen den Contract gesetzt.
- Stand: Command-, LZ-/Drop- und Approach-Buttons bleiben an den vorhandenen `TacticalController`-Callbacks, sind aber quadratisch nach Contract. Deaktivierte Phase-Template-Controls werden im festen Mission-HUD ausgeblendet, statt als aktive Fake-Actions sichtbar zu bleiben.
- Stand: Der TASK_180-Verifier prueft echte Panelrechtecke nach mehreren Frames, die bekannten Blocklabels, quadratische Buttons samt bestehenden Signalpfaden, passive BottomDock-Hosts fuer Karteninput und dass ein reiner HUD-Stylingpass keine `SimulationRoot`-Commands, Effects oder Snapshot-Anwendung erzeugt.
- Offene Punkte: Manueller Full-HD-Sichtcheck bleibt fuer finale Lesbarkeit und optische Einrueckung offen.
- Risiken: Die HUD-Panels sind bewusst fest fuer 1920x1080 gesetzt. Weitere Mission-Politur darf TerrainMap3DView, SimulationRoot, Combat, Pathfinding, LZ-/Dropship-Wahrheit und 2.5D-Gameplay nicht beruehren.
- Lokale Pruefung: `task_180_mission_drop_light_fixed_hud_layout_verifier.gd`, `task_164_ui_theme_component_verifier.gd`, `task_096_recovery_verifier.gd`, `task_160_tactical_playability_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Manuellen Mission-HUD-Sichtcheck ausfuehren oder TASK_181 als Drop-Light-Fenster-Audit starten.

### TASK_181 - Drop Light Fixed Window Audit Patch
- Status: implementiert
- Stand: `scripts/tests/task_181_drop_light_fixed_window_audit_verifier.gd` prueft FOB, Homebase und Mission-HUD nach mehreren Frames auf echte `global_position`/`size` der Drop-Light-Hauptfenster gegen den `DropLightLayoutContract`. Der Audit akzeptiert keine reine Mindestgroesse oder Metadaten mehr.
- Stand: FOB wurde nachgezogen: Topbar, `#10 FIRETEAMS`, `#13 LOADOUT`, `#14 FLIGHTDECK`, Boarding Status und Actions werden als echte feste Fenster gesetzt. Innenlisten und Scrollbereiche bleiben containerbasiert innerhalb dieser festen Fenster.
- Stand: Der FOB-Topbar-Contract nutzt jetzt 72 px Hoehe im 8er-Raster, damit die vorhandene kompakte Nav-/Header-Zeile ohne Ueberlappung als echtes Fixed Window sitzt. Alte FOB-Statuszeilen in der Topbar sind im festen Layout ausgeblendet; Status bleibt in den bestehenden Fensterinhalten und der Bottom-Row gespiegelt.
- Offene Punkte: Manueller Full-HD-Sichtcheck fuer FOB, Homebase und Mission-HUD bleibt offen.
- Risiken: Weitere visuelle Politur darf den festen Hauptfenster-Vertrag nicht wieder durch Stretch-Ratios oder Nachbarfensterabhaengigkeit aufweichen. Innenlayouts duerfen weiter flexibel sein.
- Lokale Pruefung: `task_181_drop_light_fixed_window_audit_verifier.gd`, `task_177_drop_light_fixed_ui_layout_contract_verifier.gd`, `task_178_fob_drop_light_fixed_fullhd_layout_verifier.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `task_180_mission_drop_light_fixed_hud_layout_verifier.gd`, `task_096_recovery_verifier.gd`, `task_114_meta_recovery_verifier.gd`, `bugfix_dropship_mission_flow_verifier.gd`, `task_160_tactical_playability_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Manuellen Full-HD-Sichtcheck der Drop-Light-Screens ausfuehren; danach Politur oder Gameplay-Slices separat schneiden.

### TASK_182 - Terrain Hill Rules Contract
- Status: implementiert
- Stand: `docs/dev/terrain_height_hill_rules.md` ist der gemeinsame Huegelvertrag fuer Editor, Runtime, Save/Load, Legacy-2D und 2.5D. Der Vertrag trennt `height_level` als Gelaendehoehe von `object_height` als Objekt-/Blockerhoehe, setzt `height_level + object_height` fuer LOS und sichtbare Objektpositionen fest und haelt fest, dass `surface_type` auf jeder Hoehe weiter gilt.
- Stand: `edge_type = slope` ist die begehbare Hoehentransition, `edge_type = cliff` ist als harte Klippenblockade entschieden, und `edge_type = none` ist nur fuer gleiche Hoehe bzw. Plateau-Innenbereiche gueltig. Huegellinien werden aus Nachbarhoehen abgeleitet; die hoehere Kachel bestimmt Richtung und Kantenart.
- Stand: Bestehende Abweichungen sind bewusst nicht gepatcht, sondern als Folgeaufgaben markiert: TASK_183 fuer Editor-Authoring, TASK_184 fuer A*/HPA/LOS/Cover/Combat und TASK_185 fuer 2.5D-/Legacy-Visuals.
- Risiken: Die Zielregel fuer harte Klippen aendert die bisherige alte TASK_058-Semantik (`height_diff <= 1` bei Cliff war begehbar). TASK_184 muss bestehende Testkarten und HPA-Caches entsprechend absichern.
- Lokale Pruefung: `task_182_terrain_hill_rules_contract_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_183 umsetzen, damit Editor-Authoring und Save/Load den Vertrag einhalten.

### TASK_183 - Editor Hill Authoring Patch
- Status: implementiert
- Stand: `TerrainTileCatalog` hat jetzt den expliziten Vertrag `preserves_hill_fields_when_applied()`. Waende, Felsen, Cliff-/Slope-Visualtypen und bestehende Objekt-Layer setzen beim Platzieren nur die katalogbezogenen Objekt-/Blockerfelder und erhalten `height_level`, `surface_type` und `edge_type`.
- Stand: Der Map-Editor nutzt beim Brush-Painting von Katalogtypen keinen Sonderpfad mehr, der umgebende Cliff-/Slope-Tiles in Hoehenpatches umdeutet. Surface-Patches erhalten Struktur-`type_id`s wie `wall_*` und `rock_*`; stale Ground-Base-Types unter `object_type_id` werden weiter geloescht, damit Sand/Road/Rock sichtbar bleiben.
- Stand: `scripts/tests/task_183_editor_hill_authoring_verifier.gd` prueft Hoehenwerkzeug, Katalogplatzierung auf Huegeln, Surface-Patches im Editor, Save/Load fuer Sandhang, Sandklippe, Plateau-Innenbereich, Wand auf Huegel und Fels auf Huegel sowie Editor-Refresh ohne `SimulationRoot`.
- Offene Punkte: Manueller Editor-Sichtcheck bleibt offen: Huegel malen, Sand setzen, Mauer/Fels platzieren, speichern und neu laden.
- Risiken: Cliff-/Slope-Paletteintraege sind nun hill-preserving Visual-/Blocker-Platzierung; echte Gameplay-Schrittregeln fuer Klippe/Hang folgen erst in TASK_184.
- Lokale Pruefung: `task_183_editor_hill_authoring_verifier.gd`, `task_159_verifier.gd`, `task_158_verifier.gd`, `task_132_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_184 umsetzen, damit A*, HPA, LOS, Cover und Combat den Vertrag gameplay-seitig einhalten.

### TASK_184 - Gameplay Hill Semantics Patch
- Status: implementiert
- Stand: `TerrainPathfinder` folgt jetzt dem TASK_182-Hoehenvertrag: Hoehenwechsel sind nur ueber `edge_type = slope` begehbar; `cliff` und `none` blockieren Hoehendifferenzen und liefern fuer direkte Schritt-Kosten `INF`.
- Stand: A* und HPA teilen dieselbe Step-Entscheidung, weil HPA-Komponenten, Portale, lokale Pfade und Portal-Kosten ueber den zentralen TerrainPathfinder laufen. Diagonale Schritte pruefen weiter die orthogonalen Nachbarschritte, damit harte Klippen- und Wand-Ecken nicht geschnitten werden.
- Stand: Surface-Kosten bleiben Ziel-Tile-basiert, wodurch Sandhang teurer/langsamer als Ground-Hang bleibt. Die cover-aware Grid-LOS im Pathfinder nutzt wie `LineOfSightSystem` die effektive Blockerhoehe `height_level + object_height`; Combat-Hoehenbonus und Cover lesen weiter aus der `TerrainRegistry`.
- Stand: `scripts/tests/task_184_gameplay_hill_semantics_verifier.gd` deckt Hangkosten, Sandhang, Klippenblockade, A*/HPA-Konsistenz, Diagonal-Corner-Cutting, LOS-Hoehe, Cover, Combat-Hoehe und Fallbacks ohne TerrainRegistry ab.
- Offene Punkte: Manueller Missionslauf mit Huegel-/Klippen-Testkarte bleibt sinnvoll, weil harte Klippen gegenueber alter TASK_058-Semantik Pfade sichtbar aendern koennen.
- Risiken: Bestehende Karten, die Klippen bisher als begehbare 1-Level-Uebergaenge genutzt haben, brauchen bewusste `slope`-Tiles statt stiller Runtime-Ausnahme.
- Lokale Pruefung: `task_184_gameplay_hill_semantics_verifier.gd`, `task_160_tactical_playability_verifier.gd`, `task_096_recovery_verifier.gd`, `bugfix_dropship_mission_flow_verifier.gd`, `task_126_verifier.gd`, `task_125_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_185 umsetzen, damit 2.5D-/Legacy-Visuals die gleiche Huegelwahrheit anzeigen.

### TASK_185 - Hill Visuals and Edge Lines Patch
- Status: implementiert
- Stand: `TerrainMap3DView` rendert Hoehenkanten im strikten 3D-Pfad jetzt aus der TASK_182-Kantenregel als GLB-Modelle. `edge_type = slope` erzeugt Hangmodelle, `edge_type = cliff` erzeugt Klippenmodelle, `edge_type = none` erzeugt kein Kantenvisual und wird bei Hoehendifferenz als Authoring-Konflikt gezaehlt.
- Stand: Nicht-Ground-Surfaces bekommen im 3D-Pfad eine eigene Top-Surface-Tint-Schicht, damit Sand, Rock und Road auch auf H=1/H=2 lesbar bleiben, ohne die Kenney-Ground-Materialien zu ueberschreiben.
- Stand: Marker, Patrol-/Waypoint-Linien, Contact-/Objective-/Dropship-Overlays, Unit-Proxies und Missing-Asset-Marker lesen die Tile-Oberseite als visuellen Anker. Waende, Felsen und Objekt-Fallbacks sitzen weiterhin auf `height_level * height_step`.
- Stand: `TerrainMapRenderer` nutzt dieselbe Hoehenkantenregel ohne Objekt-Tile-Ausnahmen und erkennt Objektplatzierung ueber `object_type_id`, damit Wand und Fels auf Huegeln im Legacy-2D-Pfad sichtbar bleiben.
- Stand: `scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd` prueft eine kleine Plateau-/Sandhang-/Klippen-/Wand-/Fels-Fixture inklusive 3D-Edge-Modellen, Surface-Tints, Overlay-Hoehenankern, Legacy-Kantenregel und Missing-Mapping-Marker auf H=2.
- Offene Punkte: Manueller 2.5D-Sichtcheck mit Rotation, Zoom und Pitch bleibt offen.
- Risiken: Die neuen Surface-Tints und Edge-Modelle sind Visuals; sie duerfen keine Terrain-Daten, Gameplay-Walkability oder LOS/Combat-Wahrheit setzen. Bestehende Karten mit vielen Hoehenkanten erzeugen jetzt bewusst mehr 3D-Edge-Nodes.
- Lokale Pruefung: `task_185_hill_visuals_edge_lines_verifier.gd`, `task_159_verifier.gd`, `task_160_tactical_playability_verifier.gd` laufen gruen. Zusatzcheck `task_170_performance_warning_gate_verifier.gd` lief mit 60 passed / 2 failed bei Live-Dropship-GLB- und Mission-Result-Spiegelchecks, nicht bei den neuen Huegel-/Mapping-Zaehlern.
- Naechster Schritt: Manuellen Huegel-Sichtcheck ausfuehren; danach TASK_186 fuer Mission-Map-Unit-Presence starten.

### TASK_186 - Mission Map Unit Presence and Registry Audit
- Status: implementiert
- Stand: Die Mission Map hat jetzt einen expliziten Unit-Presence-Audit. `SimulationRoot` und `MultiplayerSnapshotContract` transportieren `team_id`/`fireteam_id` in Unit-Snapshots, waehrend TacticalController, CombatLoopDriver und MissionTestSetup Presence-Audit-Snapshots fuer Registry-, Friendly-, Enemy- und Wave-Zustand liefern.
- Stand: `TerrainMap3DView` exportiert pruefbare Proxy-Diagnostik mit allen Proxy-IDs, sichtbaren Proxy-IDs, Missing-Unit-Model-IDs und Proxy-State pro Unit-ID. Dadurch kann der Audit Visual-only, UI-only und doppelte Proxy-Zustaende erkennen.
- Stand: `scripts/tests/task_186_mission_map_unit_presence_registry_audit.gd` prueft initialen Enemy-Spawn, Dropship-Deploy der blauen Friendlys, zweiten Enemy-Wave-Start, FTLRegistry-Aktivierung, UnitRegistry, Tactical-/Combat-/2.5D-/Multiplayer-Snapshots und Proxy-Duplizierung.
- Offene Punkte: Manueller 2.5D-Sichtcheck bleibt sinnvoll, weil der Audit Sichtbarkeit und IDs prueft, aber keine kuenstlerische Lesbarkeit bewertet.
- Risiken: Die neuen Audit-Snapshots sind Diagnosepfade; Gameplay-Wahrheit bleibt bei `SimulationRoot`, `UnitRegistry`, `FTLRegistry` und Combat/Runtime-Komponenten.
- Lokale Pruefung: `task_186_mission_map_unit_presence_registry_audit.gd` (46/0), `task_160_tactical_playability_verifier.gd` (20/0) und `task_168_multiplayer_snapshot_contract_verifier.gd` (20/0) laufen gruen.
- Naechster Schritt: TASK_187 fuer Mindestabstand und Multiplayer-Authority auf dem gesicherten Presence-Vertrag umsetzen.

### TASK_187 - NPC Minimum Spacing and Multiplayer Authority
- Status: implementiert
- Stand: `SimulationRoot` erzwingt nach jedem autoritativen Command-/Effect-Tick einen zentralen Unit-Mindestabstand fuer registrierte Runtime-Units. Die Korrektur laeuft vor Objective-Auswertung und Snapshot-Build, damit Multiplayer-Snapshots bereits getrennte Positionen spiegeln.
- Stand: `LocalAvoidanceResolver` liefert dafuer eine deterministische Positions-Separation mit Unit-ID-Sortierung, TerrainRegistry-Walkability-Schutz, blockierten Paar-Diagnosen und gleichem Raumvertrag fuer fit, downed, bleedout und respawning Units.
- Stand: Der TASK_187-Verifier prueft Spawn-Cluster, Dropship-Deploy, Enemy-Wave-Cluster, kreuzende Friendlys, Friendly/Enemy-Kontaktstop, Downed-Units, Respawn und Snapshot-Positionen.
- Offene Punkte: Enge echte Kartenengpaesse koennen weiterhin blockierte Paar-Diagnosen erzeugen; das ist bewusst sichtbar statt ein stiller Teleport auf nicht-walkable Tiles.
- Risiken: Der Abstand ist autoritativ und kann sehr enge Bewegungen leicht auseinanderziehen. Folge-Tasks fuer Formation/Advance-Stile duerfen darauf aufsetzen, aber keine rein visuellen Gegenoffsets einfuehren.
- Lokale Pruefung: `task_187_npc_minimum_spacing_and_multiplayer_authority.gd` (16/0), `task_130_verifier.gd` (9/0), `task_160_tactical_playability_verifier.gd` (20/0) und `task_168_multiplayer_snapshot_contract_verifier.gd` (20/0) laufen gruen.
- Naechster Schritt: TASK_188 fuer lesbare Advance-Stile auf dem gesicherten Abstandspfad umsetzen.

### TASK_188 - Fireteam Advance Styles Map Readability
- Status: implementiert
- Stand: `FireteamMovementController` liefert jetzt fuer `rush`, `bounding` und `caterpillar` strukturierte Readability-Snapshots mit Style-Code, Bewegungsgruppe, Deckungsgruppe, Bound-/Group-Fortschritt, Bound-Ziel, Multi-Tile-Markierung und kompakter Statuszeile.
- Stand: `MissionTacticalSandboxController` nutzt diese Statuszeile in #17 Selected Fireteam und spiegelt die Movement-Snapshots in den Legacy-Visualizer sowie den 2.5D-Primary-View-Payload. `TerrainMap3DView` rendert daraus kompakte Kartenmarker und exportiert pruefbare Movement-Style-Eintraege, ohne Gameplay-State zu mutieren.
- Stand: `scripts/tests/task_188_fireteam_advance_styles_map_readability.gd` deckt Controller-Snapshots, Mission-Map-Snapshot fuer alle drei Stile, Area-Order-Lesbarkeit und die #17/Map-Phasenkonsistenz ab.
- Offene Punkte: Manueller Mission-Map-Sichtcheck fuer Rush/Bounding/Caterpillar bleibt offen.
- Risiken: Die neuen Kartenlabels sind bewusst kompakt; Detailtext gehoert weiter nach #17. Folgearbeiten duerfen keine Bewegungslogik im Visualizer nachbauen.
- Lokale Pruefung: `task_188_fireteam_advance_styles_map_readability.gd`, `task_110_verifier.gd`, `task_111_verifier.gd`, `task_124_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Manuellen Sichtcheck der Mission Map ausfuehren; danach TASK_189 fuer Medic-Adjacency starten.

### TASK_189 - Medic Adjacent Tile Healing Rule
- Status: implementiert
- Stand: `MedicSupportResolver` nutzt jetzt standardmaessig `tile_range = 1`; direkte Heilung greift damit nur noch auf orthogonal benachbartem Terrain-Tile. Der World-Fallback ist auf ein Tile reduziert, damit alte 2-Tile-Heals nicht ueber Distanz weiterlaufen.
- Stand: Move-to-heal bleibt fuer weiter entfernte eigene Ziele aktiv und waehlt bei vorhandener TerrainRegistry ein begehbares Nachbar-Tile des Patienten als Zielposition. Teamfremde Ziele werden im Resolver verworfen; `medictool` bleibt Voraussetzung fuer Heal und Move-Support.
- Stand: `medic_support_verifier.gd` ist auf den 1-Tile-Vertrag umgestellt. `scripts/tests/task_189_medic_adjacent_tile_healing_rule.gd` prueft Adjacent-Heal, 2-Tile-Move, Heal-Effect-Metadaten, Medictool-Pflicht und Teamfilter.
- Offene Punkte: Manueller Sichtcheck bleibt sinnvoll, weil Medics in Live-Missionen nun haeufiger laufen statt sofort zu heilen.
- Risiken: Sehr enge Kartenstellen koennen den Move-to-heal-Pfad blockieren; das ist bewusst sichtbarer als ein zu weiter Sofort-Heal.
- Lokale Pruefung: `task_189_medic_adjacent_tile_healing_rule.gd` (17/0), `medic_support_verifier.gd` (30/0), `task_160_tactical_playability_verifier.gd` (20/0) und `task_176_fob_loadout_weapon_preview_selector_verifier.gd` (24/0) laufen gruen.
- Naechster Schritt: TASK_190 fuer weitere Waffenvisuals und Loadout-Skalierung umsetzen.

### TASK_190 - Weapon Visual Loadout Expansion and Scale
- Status: implementiert
- Stand: `WeaponData` kennt jetzt die stabilen IDs `sniper` und `rocket_launcher` mit Preview-Pfad, Visual-Loadout-ID, Rolle und kleinen bestehenden Combat-/Modifier-Werten. Deutsche/kurze Aliase wie `panzerfaust`, `raketenwerfer`, `rocketlauncher`, `sniper_rifle`, `scharfschuetzengewehr` und `praezisionsgewehr` normalisieren auf die internen IDs.
- Stand: Aus dem Kenney `Weapon Pack (1.0)` ist nur ein kleines Subset nach `Assets/used/npc/weapon_pack/` kopiert: `sniper.glb`, `rocketlauncherModern.glb`, die zwei Render-Previews und die CC0-Lizenz. `docs/assets/weapon_visuals_inventory.md` dokumentiert Quelle, Lizenz und Runtime-Vertrag.
- Stand: #13 LOADOUT bietet jetzt kompakt `SMG`, `Rifle`, `Sniper`, `Rocket` und `Medictool` mit Projektpfad-Previews. `TerrainMap3DView` normalisiert Waffen-IDs fuer Visual-Loadouts; `sniper_rifle` haengt am `RightHandSocket`, `rocket_launcher` am `BackSocket`, beide mit expliziten Scale-/Rotation-/Offset-Werten.
- Offene Punkte: Manueller 2.5D-Sichtcheck fuer den finalen Sitz von Sniper und Rocket Launcher bleibt offen; Headless prueft Resource-Ladung, Socket-Metadaten und Scale-Grenzen.
- Risiken: Rocket Launcher ist in TASK_190 nur sichtbares Loadout/Visual und keine Splash-Damage- oder Munitionsmechanik. Folge-Balancing muss separat bleiben.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_190_weapon_visual_loadout_expansion_and_scale.gd` (48/0), `task_176_fob_loadout_weapon_preview_selector_verifier.gd` (30/0), `task_175_npc_loadout_attachment_verifier.gd` (38/0) und `test_weapon_data.gd` (24/0) laufen gruen.
- Naechster Schritt: Manuellen Sichtcheck fuer Waffen-Sitz ausfuehren; danach TASK_191 fuer Befehlskette und Mission-Feedback umsetzen.

### TASK_191 - Command Chain Selection and Area Feedback Pass
- Status: implementiert
- Stand: `MissionTacticalSandboxController.get_command_feedback_snapshot()` liefert jetzt einen kompakten Headless-Pruefpunkt fuer Auswahl, #16-Command-Buttons, #17/#18-Texte, Waypoint-/Area-Zaehler, visualisierte Orders und aktive Area-Snapshots.
- Stand: `TerrainMap3DView.get_render_snapshot()` spiegelt `order_selected_fireteam_ids` und `order_phase_index`, sodass Map-Auswahl und UI-Auswahl gegeneinander verifiziert werden koennen.
- Stand: `docs/dev/mission_command_feedback_contract.md` dokumentiert Datenfluss und Rollen von #16 Command Matrix, #17 Selected Fireteam, #18 Mission Control und Mission Map. `task_191_command_chain_selection_area_feedback_pass.gd` prueft Auswahlwechsel, Multi-Selection, Move/Defend/Take-Waypoints, Take-/Engage-Areas, kompakte Texte und Map-Snapshot-Konsistenz.
- Offene Punkte: Manueller Mission-Map-Sichtcheck fuer Auswahl, Take Area, GO, Fortschritt und Kontakt bleibt offen.
- Risiken: Der neue Snapshot darf Diagnose bleiben und keine UI-seitige Gameplay-Wahrheit werden.
- Lokale Pruefung: `task_191_command_chain_selection_area_feedback_pass.gd` (24/0), `task_121_verifier.gd` (13/0), `task_122_verifier.gd` (15/0), `task_123_verifier.gd` (28/0), `task_124_verifier.gd` (21/0) und `task_160_tactical_playability_verifier.gd` (20/0) laufen gruen.
- Naechster Schritt: TASK_192 als zusammenfassenden Playability-Smoke fuer die NPC-/Command-Feedback-Reihe umsetzen.

### TASK_192 - Mission Map NPC Behavior Playability Smoke
- Status: implementiert
- Stand: `scripts/tests/task_192_mission_map_npc_behavior_playability_smoke.gd` startet die Live-Testmission, staged das Dropship, deployed BLUE, aktiviert die zweite Enemy-Wave und auditiert UnitRegistry, Tactical-/Combat-Presence, 2.5D-Proxies und Multiplayer-Snapshots in einem zusammenhaengenden Run.
- Stand: Der Smoke baut Move/Defend/Take-Waypoints plus Engage-/Defend-Areas, fuehrt GO mit cautious-Stance aus und prueft Bounding/Caterpillar-Readability, kompakte Map-Labels, Contact-Marker, aktive Area-Snapshots und #16/#17/#18-Feedback.
- Stand: Der Medic-Fall laeuft innerhalb derselben Mission: benachbarter Patient erzeugt Heal, ein zwei Tiles entfernter Patient erzeugt nur Move-to-neighbor-Tile. Zwei Live-Friendlys werden temporaer auf `sniper` und `rocket_launcher` gesetzt, damit der TASK_190-Visualpfad im Missionskontext mitgeprueft wird.
- Offene Punkte: Manueller Mission-Map-Sichtcheck des gesamten Ablaufs bleibt offen; der Headless-Smoke bewertet keine finale optische Lesbarkeit von Waffensitz, NPC-Abstaenden und Overlays.
- Risiken: Der Smoke lokalisiert Fehler schlechter als Einzelverifier; er bleibt Abschluss-Gate und ersetzt die Verifier aus TASK_186 bis TASK_191 nicht.
- Lokale Pruefung: `task_192_mission_map_npc_behavior_playability_smoke.gd` (65/0), `task_160_tactical_playability_verifier.gd` (20/0), `task_168_multiplayer_snapshot_contract_verifier.gd` (20/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_193 fuer Asset Source Inventory and Availability Matrix umsetzen.

### TASK_193 - Asset Source Inventory and Availability Matrix
- Status: implementiert
- Stand: `docs/assets/asset_source_availability_matrix.md` listet alle neun Pflichtquellen mit Source-ID, lokaler Quelle, Projektpfad, CC0-Lizenzlage, Dateitypen/Groesse, Importstatus, Maximalmenge, Verbrauchsort und Folge-Task.
- Stand: Vorhandene Projektkopien sind als `reuse existing project copy` markiert: UI-Pack, Sci-Fi-UI-Pack, Space-Kit, Keyboard-&-Mouse-Input-Prompts und Cursor-Pixel-Pack. Fehlende Subsets sind nur Folgeaufgaben zugeordnet: Modular/Space Station zu TASK_194, Ranks/Particles zu TASK_196.
- Stand: Alte absolute `C:/Users/...`-Quellhinweise in Runtime-Mapping-Daten wurden zuerst normalisiert und im TASK_198-Gate endgueltig aus `data/*.json` entfernt; Runtime-Daten enthalten jetzt Projektpfade oder Doku-Verweise statt lokaler Pictures-Quellen.
- Offene Punkte: Keine binaeren Assets wurden importiert. Die konkreten Subsets bleiben TASK_194 bis TASK_196 vorbehalten.
- Risiken: Die Matrix darf nicht als Freigabe fuer Pack-Komplettimporte gelesen werden. Jede spaetere Datei braucht weiter Quelle, Lizenz, Zielpfad und Verbrauchsort im passenden Manifest.
- Lokale Pruefung: `task_193_asset_source_inventory_availability_verifier.gd` (71/0), `task_176_fob_loadout_weapon_preview_selector_verifier.gd` (30/0), `task_177_drop_light_fixed_ui_layout_contract_verifier.gd` (63/0), `task_178_fob_drop_light_fixed_fullhd_layout_verifier.gd` (22/0), `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd` (25/0), `task_190_weapon_visual_loadout_expansion_and_scale.gd` (48/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_194 fuer kuratierte Space-/Station-Setpiece-Subsets umsetzen.

### TASK_194 - Space Modular and Station Setpiece Import
- Status: implementiert
- Stand: Aus `Modular Space Kit` wurden 10 GLB-Setpieces nach `Assets/curated/kenney/modular_space/models/` importiert; aus `Space Station Kit` wurden 12 GLB-Setpieces nach `Assets/curated/kenney/space_station/models/` importiert. Je Kit liegen `License.txt`, README und die benoetigte shared `models/Textures/colormap.png` bei.
- Stand: `docs/assets/space_setpiece_inventory.md` dokumentiert Quelle, Lizenz, Projektpfad, Kategorie, Einsatzort und Scale-Hinweis. `data/space_setpiece_catalog.json` stellt die Setpieces Visual-only per ID fuer spaetere UI-/Editor-/Preview-Pfade bereit.
- Stand: `kenney_space-kit` wurde nicht doppelt kopiert, sondern bleibt als vorhandene Projektkopie referenziert. Es wurden keine FBX/OBJ/MTL/DAE/STL-Duplikate importiert.
- Offene Punkte: Manueller Godot-Sichtcheck einer spaeteren Preview-/Staging-Szene bleibt offen; TASK_194 legt selbst keine Szene und kein Layout um.
- Risiken: Setpieces bleiben Visuals und duerfen keine Terrain-, Kollisions-, Walkability- oder Gameplay-Wahrheit werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_194_space_modular_station_setpiece_import_verifier.gd` (160/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_195 fuer UI/Input/Cursor-Availability-Pass umsetzen.

### TASK_195 - UI Input and Cursor Asset Availability Pass
- Status: implementiert
- Stand: `docs/assets/ui_input_cursor_availability.md` dokumentiert die vorhandenen Projektkopien fuer UI-Pack, Space-UI-Expansion, Keyboard-&-Mouse-Prompts und Cursor-Pixel-Pack als `reuse existing`.
- Stand: `data/ui_asset_catalog.json` definiert stabile Visual-only-IDs fuer Panel-/Button-/Icon-/Crosshair-Assets, LMB/RMB, Shift/Ctrl, Q/E/R/F/G/Space/Escape sowie Cursor-Zustaende fuer Select, Move, Attack, Defend, Take, Area-Drag, Editor-Brush, Height, Marker und Patrol.
- Stand: Es wurden keine Assets nach `Assets/curated` kopiert. Der Katalog ersetzt keine Theme- oder Eingabelogik; TASK_164 bleibt die UI-Komponentenbasis.
- Offene Punkte: Manueller Sichtcheck fuer Tooltips/Cursor bleibt erst relevant, wenn ein spaeterer UI-Slice die IDs sichtbar nutzt.
- Risiken: Katalog darf keine zweite Theme-Wahrheit neben TASK_164 werden; Prompts und Cursor bleiben Anzeige, nicht Gameplay-Input-State.
- Lokale Pruefung: `task_195_ui_input_cursor_asset_availability_verifier.gd` (171/0), `task_164_ui_theme_component_verifier.gd` (15/0), `task_181_drop_light_fixed_window_audit_verifier.gd` (43/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_196 fuer Rank- und Particle-Subset-Import umsetzen.

### TASK_196 - Rank and Particle Asset Subset Import
- Status: implementiert
- Stand: `Assets/curated/kenney/ranks/` enthaelt ein kleines 10-PNG-Subset fuer Rollen-/Status-Badges: FTL, Medic, Rifle/Assault, Heavy/Special, Pilot, Engineer, Enemy, Down, Ready und Suppressed.
- Stand: `Assets/curated/kenney/particles/` enthaelt ein kleines 12-PNG-Subset fuer LZ/Drop, Contact, Suppression, Objective, Hit, Heal, Warning, Trace, Impact, Movement/Dust, Scorch und Command-Ping.
- Stand: `data/rank_particle_asset_catalog.json` und `docs/assets/rank_particle_inventory.md` dokumentieren stabile IDs, `res://`-Pfade, Quell-Relativpfade, Zielscreen, Lizenz und Visual-only-Grenzen.
- Offene Punkte: Keine konkrete UI- oder Effekt-Layer-Nutzung in diesem Task; TASK_197 darf die IDs zentral zusammenfuehren.
- Risiken: Particles duerfen keine SimulationRoot-Effects ersetzen; Badges duerfen NPC-Karten nicht ueberladen und bleiben Statusanzeige statt Statuswahrheit.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_196_rank_particle_asset_subset_import_verifier.gd` (225/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_197 fuer zentralen kuratierten Asset-Katalog und Usage-Mapping umsetzen.

### TASK_197 - Curated Asset Catalog and Usage Mapping
- Status: implementiert
- Stand: `data/curated_asset_catalog.json` bindet die bestehenden Fachkataloge fuer UI/Input/Cursor, Rank/Particle und Space-Setpieces explizit ein und fuegt zentrale Eintraege fuer Weapon-Visuals und bestehende Terrain-Visuals hinzu.
- Stand: `scripts/assets/curated_asset_catalog.gd` stellt einen read-only Resolver bereit, der keine Projektordner scannt, alle Eintraege als stabile IDs mit `res://`-Pfaden sammelt und fehlende IDs/Pfade mit Diagnosewerten statt stillen Fallbacks meldet.
- Stand: `docs/assets/asset_usage_mapping.md` dokumentiert Kategorie-Mapping, Zielsysteme und Resolver-Vertrag fuer `ui`, `input_prompt`, `cursor`, `rank_badge`, `particle`, `setpiece`, `weapon_visual` und `terrain_existing`.
- Offene Punkte: Der Katalog wird noch nicht in UI-/Visualizer-Code konsumiert; TASK_198 nutzt ihn zunaechst als Gate/Smoke-Einstieg.
- Risiken: Der Katalog darf keine Gameplay- oder Renderer-Wahrheit werden; er stellt nur Pfade und Metadaten bereit.
- Lokale Pruefung: `task_197_curated_asset_catalog_usage_mapping_verifier.gd` (799/0), `task_195_ui_input_cursor_asset_availability_verifier.gd` (171/0), `task_196_rank_particle_asset_subset_import_verifier.gd` (225/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_198 fuer Asset-Import-Gate und Visual-Smoke umsetzen.

### TASK_198 - Asset Import Gate and Visual Smoke
- Status: implementiert
- Stand: `scripts/tests/task_198_asset_import_gate_visual_smoke.gd` prueft den zentralen Asset-Katalog, Pflichtkategorien, Godot-Importmetadaten, Import-Maximalmengen, Texture-/PackedScene-Loadbarkeit, Mesh-Grundsignal fuer GLB-Samples und Missing-Asset-Diagnosen.
- Stand: `docs/manual_checks/asset_expansion_visual_smoke.md` dokumentiert den manuellen Sichtcheck fuer FOB/Homebase/Mission-HUD-Icons, Input/Cursor, Rank-Badges, Particles, Setpieces, Weapon-Visuals und Terrain-Referenzen.
- Stand: `data/terrain_3d_asset_mapping.json`, `data/npc_unit_visual_mapping.json` und `data/rank_particle_asset_catalog.json` enthalten keine lokalen Pictures-Quellen mehr; Quelle bleibt in Docs/Inventaren, Runtime-Daten bleiben projektlokal.
- Offene Punkte: Der manuelle GUI-Sichtcheck aus der Checkliste ist dokumentiert, aber nicht interaktiv ausgefuehrt.
- Risiken: Der Smoke ersetzt die Einzelverifier nicht; bei zu grossem Import-Diff wird Review und Fehlersuche unuebersichtlich.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_198_asset_import_gate_visual_smoke.gd` (167/0), `task_193_asset_source_inventory_availability_verifier.gd` (71/0), `task_196_rank_particle_asset_subset_import_verifier.gd` (225/0), `task_197_curated_asset_catalog_usage_mapping_verifier.gd` (799/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_199 fuer Main-Menu-Shell und Hintergrundbild vorbereiten.

### TASK_199 - Main Menu Shell and Background Image
- Status: implementiert
- Stand: Das vom User bereitgestellte Bild liegt als `Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg` im Projekt und wird von `scenes/ui/main_menu.tscn` als vollflaechiger `TextureRect`-Hintergrund genutzt.
- Stand: `scripts/ui/main_menu_screen.gd` stellt den App-Shell-Einstieg mit `Einzelspieler`, `Multiplayer`, `Editor` und `Einstellungen` bereit. Einzelspieler routet auf den bestehenden Meta-Flow, Multiplayer bewusst auf den TASK_167-Lobby-Adapter, Editor auf `res://scenes/editor/map_editor.tscn`, Einstellungen auf ein lokales Panel.
- Stand: `project.godot` startet jetzt in `res://scenes/ui/main_menu.tscn`. Das Settings-Panel bietet Master-Audio, Vollbild-Schalter und Zurueck ohne Persistenzversprechen.
- Offene Punkte: Manueller GUI-Sichtcheck fuer Lesbarkeit, Buttonklicks und Settings-Panel ist offen.
- Risiken: Das Hintergrundbild wurde FullHD-first per Covered-Crop eingebunden; andere Seitenverhaeltnisse brauchen spaeter einen eigenen visuellen Check. Multiplayer ist noch der bestehende Lobby-Testadapter, aber explizit markiert.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_199_main_menu_shell_background_image_verifier.gd` (50/0), `task_167_multiplayer_session_verifier.gd` (22/0), `task_164_ui_theme_component_verifier.gd` (15/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_200 fuer Enemy-Team-Tactics-Contract und Editor-Konfiguration umsetzen.

### TASK_200 - Enemy Team Tactics Contract and Editor Config
- Status: implementiert
- Stand: `scripts/tactical/enemy_team_tactics_profile.gd` definiert stabile Enemy-Team-Profile `guard_hold`, `patrol_probe`, `aggressive_push`, `defensive_cover` und `sniper_watch` mit Security-Modus, Facing, Haltung, Cover-Verhalten, Advance-Stil, Sicht-/Kontaktverhalten, Waffenrollen, Weapon-Profile und Visual-Archetyp.
- Stand: `MissionScenarioData` speichert `enemy_groups[].tactics`, `TerrainMapData` speichert `enemy_team_configs`, und der Map-Editor kann Profil, Security-Modus und Facing fuer die primaere Enemy-Gruppe authoren und speichern. 32x32-Maps defaulten auf `guard_hold`, 64x64-Maps auf `patrol_probe`.
- Stand: `MissionTestSetup` und `EnemyWaveController` lesen normalisierte Taktik-Dictionaries und legen sie nur als Enemy-Unit-Metadaten ab; es gibt noch keine neue KI- oder Combat-Nebenwirkung.
- Offene Punkte: Manueller Editor-Sichtcheck bleibt offen: Enemy-Gruppe setzen, Profil/Facing speichern und neu laden.
- Risiken: Folge-Tasks duerfen den Profilvertrag auswerten, aber keine zweite Taktik-Wahrheit in UI, Mission-HUD oder Combat-Loop duplizieren.
- Lokale Pruefung: `task_200_enemy_team_tactics_contract_and_editor_config.gd` (116/0), `task_186_mission_map_unit_presence_registry_audit.gd` (46/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_201 fuer Waffenreichweiten auf dem neuen Profilvertrag umsetzen.

### TASK_201 - Weapon Range Scale and Tile Distance Patch
- Status: implementiert
- Stand: `WeaponData` liefert jetzt `effective_tile_range` und daraus abgeleitete Weltreichweiten. Defaults: SMG 10 Tiles, Support/`rail_gun` 20 Tiles, Rifle 25 Tiles, Sniper 40 Tiles, Medictool 1 Tile; `support_lmg`/`lmg` normalisieren auf den bestehenden Support-Waffenpfad.
- Stand: Combat-Fire-Entscheidungen und Overwatch nutzen die aktive Waffenreichweite des Angreifers. `contact_range` bleibt Wahrnehmung/Detection mit Stealth-Fallback und ersetzt keine Waffenreichweite mehr.
- Stand: Multiplayer-Snapshots normalisieren `active_weapon_id`, `weapon_tile_range` und `weapon_range_world` nur als Anzeige-/Diagnosefelder; clientseitige Range-Entscheidungen werden nicht uebernommen. FOB-Loadout-Optionen zeigen die Tile-Reichweite kompakt im Label.
- Offene Punkte: Manuelle Balancepruefung auf echten 32x32-/64x64-Missionen bleibt offen; die Werte sind Startwerte, keine finale Waffenbalance.
- Risiken: Folge-Tasks duerfen `contact_range` nicht wieder als Waffenreichweite verwenden. Sniper-Range ist bewusst lang, aber nicht als globale Map-Wahrheit gedacht.
- Lokale Pruefung: `task_201_weapon_range_scale_and_tile_distance_patch.gd` (34/0), `task_092_verifier.gd` (12/0), `task_111_verifier.gd` (16/0), `task_168_multiplayer_snapshot_contract_verifier.gd` (20/0) und `task_176_fob_loadout_weapon_preview_selector_verifier.gd` (30/0) laufen gruen.
- Naechster Schritt: TASK_202 fuer Enemy-Security-Richtung und LOS auf der neuen Waffenrange umsetzen.

### TASK_202 - Enemy Security Direction and LOS Patch
- Status: implementiert
- Stand: `MissionCombatLoopDriver` baut pro Enemy-Gruppe eigene Security-Snapshots mit `security_mode`, Facing-/Direction-Angle, Sector Width, Member-Assignments, Waffenreichweite und `watched_unit_ids`. Defaults kommen aus den TASK_200-Tactics-Metadaten; `360` bleibt explizit und directional Profile richten sich an Facing, Kontakt/Fokus oder Objective aus.
- Stand: Enemy-Watch wird durch Winkel, LOS und TASK_201-Waffenrange begrenzt. `resolve_flank_attack()` kann jetzt auch Enemy-Ziele gegen deren Security-State pruefen: directional Gegner sind seitlich/rear flankierbar, 360 blockt den Flankbonus.
- Stand: `TerrainMap3DView` rendert enemy-seitige Security knapp als orangefarbenen Richtungsmarker und exportiert pruefbare `enemy_security_entries`; `MissionTacticalSandboxController` spiegelt den Combat-Snapshot in den Primary-View-Payload.
- Offene Punkte: Manueller 2.5D-Sichtcheck fuer Enemy-Facing/Sektorlesbarkeit bleibt offen; die Headless-Pruefung deckt Snapshot und kompakte Map-Diagnose ab.
- Risiken: Enemy-Security darf nicht in UI-State auswandern. Folge-Tasks sollten auf dem Snapshot lesen, nicht eigene Gegner-Wahrheit in HUD/Renderer aufbauen.
- Lokale Pruefung: `task_202_enemy_security_direction_and_los_patch.gd` (24/0), `task_111_verifier.gd` (16/0), `task_113_verifier.gd` (26/0), `task_184_gameplay_hill_semantics_verifier.gd` (30/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_203 fuer Enemy-Cover-Advance und Team-Tactics auf Security/Range umsetzen.

### TASK_203 - Enemy Cover Advance and Team Tactics Patch
- Status: implementiert
- Stand: `MissionCombatLoopDriver` baut jetzt pro explizit konfigurierter Enemy-Gruppe einen Team-Tactics-Snapshot mit Advance-Style (`hold`, `probe`, `push`, `bounding`), Moving-/Covering-Gruppen, kleinen Rollenlabels, Zielpositionen und kompaktem `tactic_label`.
- Stand: Cover-orientierte Profile bewerten walkable Cover-Tiles nach Coverwert, LOS zum Fokus, TASK_201-Waffenrange, Hoehe und Bewegungskosten. Zielslots werden verteilt und halten den TASK_187-Mindestabstand, statt mehrere Gegner auf denselben Punkt zu ziehen.
- Stand: Explizite Enemy-Profile steuern die Movement-Commands: `guard_hold` bleibt ohne Objective-Rush im Sektor, `aggressive_push` bewegt mehrere Units ueber mehrere Tile-Distanzen, `defensive_cover` nutzt bounding-/coverartige Slots. `TerrainMap3DView` und `MissionTacticalSandboxController` spiegeln kurze Enemy-Tactics-Labels in den Primary-View-Snapshot.
- Offene Punkte: Manueller Mission-Map-Sichtcheck fuer Enemy-Push/Hold bleibt offen; Headless prueft Snapshot und Map-Diagnose.
- Risiken: Die Tactics-Entscheidung bleibt autoritativ im Combat-Driver. Renderer und UI duerfen nur Snapshot-Felder anzeigen und keine Enemy-KI nachrechnen.
- Lokale Pruefung: `task_203_enemy_cover_advance_and_team_tactics_patch.gd` (16/0), `task_089_verifier.gd` (7/0), `task_187_npc_minimum_spacing_and_multiplayer_authority.gd` (16/0), `task_188_fireteam_advance_styles_map_readability.gd` (37/0), `task_200_enemy_team_tactics_contract_and_editor_config.gd` (116/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_204 fuer Multiplayer-Authority-Snapshots der Enemy-Taktiken umsetzen.

### TASK_204 - Enemy Tactics Multiplayer Authority Snapshot Patch
- Status: implementiert
- Stand: `MissionCombatLoopDriver` veroeffentlicht Enemy-Security, Enemy-Team-Tactics und Fire-Events ueber den bestehenden `set_multiplayer_snapshot_context()`-Authority-Pfad. Fire-Events bekommen stabile IDs mit Tick/Sequenz und enthalten Weapon-/Range-/Positionsdaten fuer spaetere VFX.
- Stand: `MultiplayerSnapshotContract` normalisiert `enemy_security`, `enemy_team_tactics`, `fire_events` sowie enemy-seitige Unit-Diagnosefelder (`enemy_facing_angle`, Security-/Tactics-Gruppe, Profil, Rolle, Label). Clientseitige Rechenfelder werden verworfen.
- Stand: `SimulationRoot` nimmt die neuen Context-Felder in den Tick-State auf und kopiert Enemy-Metadaten nur als Anzeige-/Diagnosedaten in Unit-Snapshots. Snapshot-Apply speichert die Daten, erzeugt aber keine Commands oder Effects.
- Offene Punkte: Echte Netzwerkverbindung/Prediction bleiben ausser Scope; TASK_205 kann Muzzle-VFX nun an `fire_events` haengen.
- Risiken: Folgearbeiten duerfen Fire-Events nur anzeigen. Schaden, Trefferwurf und Enemy-Bewegung bleiben authority-seitig.
- Lokale Pruefung: `task_204_enemy_tactics_multiplayer_authority_snapshot_patch.gd` (20/0), `task_168_multiplayer_snapshot_contract_verifier.gd` (20/0), `task_187_npc_minimum_spacing_and_multiplayer_authority.gd` (16/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_205 fuer Weapon-Fire-VFX und Muzzle-Flash-Partikel umsetzen.

### TASK_205 - Weapon Fire VFX Muzzle Flash Particles
- Status: implementiert
- Stand: Fuenf Muzzle-Flash-PNGs aus dem Kenney Particle Pack liegen projektlokal unter `Assets/curated/kenney/particles/muzzle/` inklusive CC0-Lizenz und Godot-Imports.
- Stand: `data/weapon_fire_vfx_catalog.json` und `docs/assets/weapon_fire_vfx_inventory.md` dokumentieren stabile VFX-IDs, Quellen, Weapon-Zuordnung und Barrel-Offsets.
- Stand: `TerrainMap3DView` rendert kurze Muzzle-Flash-Tokens plus Trace-Linie aus `fire_event_dicts`; Friendly- und Enemy-Events laufen ueber denselben Snapshot-/Eventpfad und erzeugen keine Commands, Damage-Entscheidungen oder Effects.
- Stand: `MissionTacticalSandboxController` leitet autoritative Fire-Events an die primaere 2.5D-Ansicht weiter.
- Offene Punkte: Manueller 2.5D-Sichtcheck fuer SMG/Rifle/Enemy-Schuss bleibt offen.
- Risiken: Folgearbeiten muessen die VFX weiter als reine Anzeige behandeln; Combat-Wahrheit bleibt im Combat-System.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_205_weapon_fire_vfx_muzzle_flash_particles.gd` (33/0), `task_204_enemy_tactics_multiplayer_authority_snapshot_patch.gd` (20/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_206 fuer Enemy-Faction-Archetypen und orange Raumanzug-Lesbarkeit umsetzen.

### TASK_206 - Enemy Visual Faction Archetypes Orange Suit
- Status: implementiert
- Stand: `astroFemaleB.png` und `astroMaleB.png` sind aus dem Kenney Animated Characters Bundle projektlokal importiert und bilden den produktiven Enemy-Archetyp `enemy_space_suit_orange`.
- Stand: `data/npc_unit_visual_mapping.json` definiert `friendly_space_suit_white`, `enemy_space_suit_orange` sowie vorbereitete IDs `enemy_robot`, `enemy_alien`, `enemy_zombie` und `enemy_soldier` mit Fallback auf Orange. Team Bravo und `enemy_delta`/`enemy_echo` nutzen orange B-Skins; Team Alpha/default bleibt hell.
- Stand: `TerrainMap3DView` loest `visual_archetype_id` und `enemy_visual_archetype_id` rein visuell auf, setzt pruefbare Proxy-Metadaten und faellt fuer geplante Archetypen auf den orange Enemy-Anzug zurueck.
- Stand: Enemy-Team-Tactics-Profile referenzieren die stabile Archetyp-ID `enemy_space_suit_orange`; Multiplayer-Unit-Snapshots transportieren `enemy_visual_archetype_id` als Anzeige-/Diagnosedatum.
- Offene Punkte: Manueller 2.5D-Sichtcheck Friendly vs. Enemy bleibt offen.
- Risiken: Spaetere Robot/Alien/Zombie/Soldier-Imports duerfen die Fallback-ID nicht als produktiven Import missverstehen.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_206_enemy_visual_faction_archetypes_orange_suit.gd` (48/0), `task_175_npc_loadout_attachment_verifier.gd` (38/0), `task_172_npc_animation_scale_helmet_enemy_verifier.gd` (47/0), `task_171_npc_model_replacement_verifier.gd` (26/0), `task_204_enemy_tactics_multiplayer_authority_snapshot_patch.gd` (20/0), `task_200_enemy_team_tactics_contract_and_editor_config.gd` (116/0; bekannte Godot-Leak-Warnung beim Editor-Exit) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_207 fuer Rank-/Skill-Badges pro NPC umsetzen.

### TASK_207 - NPC Rank Skill Badge Derivation
- Status: implementiert
- Stand: `scripts/meta/npc_rank_badge_resolver.gd` leitet maximal drei Primaerbadges deterministisch aus Rolle, Loadout, Skills, Plattformwerten, Team und Fireteam-Lead-Status ab. Unterstuetzt sind Medic, Shooter, Pilot, Engineer, Leader, Heavy und Enemy.
- Stand: `MetaUnitProfileBuilder` erzeugt Badge-Eintraege aus vorhandenen Profil-/Unitdaten; `MetaUnitProfile` transportiert diese Anzeige-Daten ohne Gameplay-Wahrheit zu speichern.
- Stand: `NPCCompactCard` zeigt Badges in FOB und #17 Selected Fireteam, `NPCMetaCard` in Homebase/Roster und `CharacterSheetView` im Character Sheet. Fehlende Badge-Assets erzeugen einen diagnostischen Fallback-Knoten statt UI-Bruch.
- Offene Punkte: Manueller Sichtcheck Homebase/FOB/#17 fuer Badge-Lesbarkeit bleibt offen.
- Risiken: Spaetere manuelle Badge-Felder duerfen nicht zur autoritativen Wahrheit werden; Resolver bleibt die Quelle fuer Anzeige-Badges.
- Lokale Pruefung: `task_207_npc_rank_skill_badge_derivation.gd` (31/0), `task_196_rank_particle_asset_subset_import_verifier.gd` (225/0), `task_176_fob_loadout_weapon_preview_selector_verifier.gd` (30/0), `task_164_ui_theme_component_verifier.gd` (15/0), `task_178_fob_drop_light_fixed_fullhd_layout_verifier.gd` (22/0), `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd` (25/0), `task_180_mission_drop_light_fixed_hud_layout_verifier.gd` (54/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_208 als integrierter Enemy-Team-Tactics Playability-Smoke.

### TASK_208 - Enemy Team Tactics Playability Smoke
- Status: implementiert
- Stand: `maps/enemy_tactics_smoke_32x32.json` stellt eine kompakte 32x32-Fixture mit Sand, Hoehe/Slope, Cliff, walkable Cover, Alpha-Spawn, Enemy-Hold, Enemy-Push und Objective bereit.
- Stand: `scripts/tests/task_208_enemy_team_tactics_playability_smoke.gd` prueft Editor-Roundtrip, MissionTestSetup-Konfigurationslesung, Hold/Cover/Push-Taktiken, Enemy-Security/Facing, Reichweitenbegrenzung, Mindestabstand, Fire-Events, Muzzle-Flash-VFX, orange Enemy-/weisse Friendly-Archetypen, Rank-/Skill-Badges und Multiplayer-Snapshot-Side-Effects in einem integrierten Pass.
- Stand: `docs/dev/enemy_team_tactics_manual_smoke_checklist.md` dokumentiert den verbleibenden manuellen 2.5D-Sichtcheck.
- Offene Punkte: Manueller Mission-Map-Sichtcheck anhand der Checkliste bleibt offen; die optionale 64x64-Range-Fixture wurde nicht angelegt, weil der 32x32-Smoke die geforderten Range-Grenzen bereits automatisiert abdeckt.
- Risiken: Der Smoke ersetzt die Einzelverifier nicht; bei Fehlern muss weiter in TASK_200 bis TASK_207 lokalisiert werden.
- Lokale Pruefung: `task_208_enemy_team_tactics_playability_smoke.gd` (57/0), `task_160_tactical_playability_verifier.gd` (20/0), `task_168_multiplayer_snapshot_contract_verifier.gd` (20/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_209 fuer den Comic-Bubble-Asset-Katalog starten.

### TASK_209 - Comic Bubble Asset Catalog and Visual Contract
- Status: implementiert
- Stand: `data/comic_bubble_asset_catalog.json` katalogisiert `comic-1.png` bis `comic-10.png` mit stabilen Runtime-IDs, Purpose, Anchor, Tail-Offset, Text-Inset, Maximalgroesse und z-Order. `preview.png` ist als Inventar-/Doku-Preview dokumentiert und kein Runtime-Bubble.
- Stand: `scripts/ui/comic_bubble_visual_contract.gd` validiert den Katalog, liefert Runtime-IDs und baut reine Display-Payloads mit Textkuerzung auf maximal zwei Zeilen.
- Stand: `docs/assets/comic_bubble_inventory.md` dokumentiert Quelle, Purpose-IDs, Runtime-IDs, Textregeln und Folgepfad.
- Offene Punkte: Noch keine Fireteamleader-Dialoglogik, NPC-Gedankenlogik oder Settings/Toggles; das ist Folgeumfang ab TASK_210.
- Risiken: Bubbles koennen die Mission Map schnell unruhig machen; die Groessen-, Text- und Aktivitaetsgrenzen muessen in den Folge-Tasks respektiert werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_209_comic_bubble_asset_catalog_and_visual_contract.gd` (132/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_210 fuer Fireteamleader-Command-Feedback-Bubbles umsetzen.

### TASK_210 - Fireteamleader Command Feedback Bubbles
- Status: implementiert
- Stand: `FireteamleaderFeedbackBubbleResolver` baut kurze visual-only Comic-Bubble-Payloads fuer angenommene, laufende, blockierte, Kontakt-, Deckungs- und Objective-Rueckmeldungen. Die Payloads nutzen stabile TASK_209-Bubble-IDs und speichern nur Anzeige-Kontext wie `feedback_action`, `feedback_state`, Skill-Tier und Anchor.
- Stand: `MissionTacticalSandboxController` haengt die Bubbles an bestehende Command-Pfade fuer `move`, `defend`, `flank`, `take` und `GO`, ohne SimulationRoot, Command-Ergebnis oder Flow-Driver-Wahrheit zu veraendern. Ein zentraler Toggle leert die Visual-Payloads, laesst Befehle aber weiter durchlaufen.
- Stand: `TerrainMap3DView` rendert die Feedback-Bubbles im 2.5D-Order-Layer und spiegelt `feedback_bubble_visual_count` plus Entries im Render-Snapshot.
- Offene Punkte: Manueller Mission-Map-Sichtcheck fuer finale Position, Lesbarkeit und Stoerfaktor bleibt offen. Cooldowns, Modi und Hold-Settings sind bewusst TASK_211.
- Risiken: Ohne TASK_211 koennen schnelle Befehlsfolgen noch haeufige Bubbles erzeugen; die aktuelle Umsetzung begrenzt nur aktive Payloads pro FTL.
- Lokale Pruefung: `task_210_fireteamleader_command_feedback_bubbles.gd` (27/0), `task_191_command_chain_selection_area_feedback_pass.gd` (24/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_211 fuer Toggles, Cooldowns und Anzeige-Modi umsetzen.

### TASK_211 - Comic Bubble Toggles Cooldowns and Settings
- Status: implementiert
- Stand: `ComicBubbleSettings` definiert sichere Defaults, Modi `off`, `minimal`, `normal`, optional `debug`, Kategorien, Maximalzahlen, Cooldowns, Persistenz per `ConfigFile` und den InputMap-Fallback `show_npc_thoughts`.
- Stand: `ComicBubbleRuntimeGate` filtert visual-only Bubble-Payloads nach Modus, Kategorie, Cooldown, Prioritaet und Maximalzahl. NPC-Gedanken werden nur durch Hold-to-Peek freigegeben.
- Stand: `MissionTacticalSandboxController` nutzt das Gate fuer Fireteamleader-Feedback; `off` erzeugt keine Payloads und keine 2.5D-Visual-Nodes, ohne den Command-Flow zu blockieren. Das Main-Menu-Settingspanel kann den Bubble-Modus `Aus`/`Minimal`/`Normal` persistent setzen.
- Offene Punkte: Manueller Settings-/Mission-Sichtcheck fuer Off/Minimal/Normal und Hold-Taste bleibt offen.
- Risiken: TASK_212 muss Gedankeninhalte weiter visual-only halten; das Gate erlaubt die Anzeige, erzeugt aber keine Textlogik.
- Lokale Pruefung: `task_211_comic_bubble_toggles_cooldowns_and_settings.gd` (25/0), `task_210_fireteamleader_command_feedback_bubbles.gd` (27/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_212 fuer NPC-Gedanken-Hold-to-Peek umsetzen.

### TASK_212 - NPC Thought Bubble Hold to Peek Overlay
- Status: implementiert
- Stand: `NPCThoughtBubbleResolver` erzeugt kurze visual-only Gedanken aus vorhandenen NPC-Daten: Health/Vital-State, Rolle, Fireteamlead-Flag und aktuellem Befehl/Status. Die Payloads nutzen `bubble_npc_*`-IDs und markieren `spoiler_safe`.
- Stand: `MissionTacticalSandboxController` zeigt Gedanken nur ueber `ComicBubbleRuntimeGate`, also nur bei aktivem `show_npc_thoughts`-Hold, nicht im Modus `off`, fuer das ausgewaehlte Fireteam oder sichtbare Friendlys und mit hartem Maximalwert.
- Stand: `TerrainMap3DView` rendert dieselben visual-only Payloads im bestehenden Bubble-Layer und spiegelt Source, Kategorie, Purpose und Thought-Kind im Render-Snapshot.
- Offene Punkte: Manueller Mission-Map-Sichtcheck mit gehaltener Taste bleibt offen.
- Risiken: TASK_213 muss die Textauswahl zentralisieren, damit FTL- und NPC-Texte stilistisch nicht auseinanderlaufen.
- Lokale Pruefung: `task_212_npc_thought_bubble_hold_to_peek_overlay.gd` (19/0), `task_211_comic_bubble_toggles_cooldowns_and_settings.gd` (25/0), `task_210_fireteamleader_command_feedback_bubbles.gd` (27/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_213 fuer den zentralen skill-/rollenbasierten Textresolver umsetzen.

### TASK_213 - Skill Based Bubble Text Resolver and Content Pass
- Status: implementiert
- Stand: `ComicBubbleTextResolver` und `data/comic_bubble_text_catalog.json` liefern jetzt zentral die kurzen deutschen Texte fuer FTL-Rueckmeldungen und NPC-Gedanken. Die Auswahl ist deterministisch und haengt an stabilen Keys fuer Command-Status, Health/Recovery, Order, Leader, Medic, Shooter, Pilot, Engineer und Heavy/Support.
- Stand: Leadership/Communication, rollenrelevante Skills und Situation beeinflussen nur Text-Tier und Informationsgrad. Fehlende Skilldaten fallen auf `neutral` zurueck; niedrige Skills aendern kein Command-Ergebnis und erzeugen keine Gameplay-Payloads.
- Stand: FTL- und NPC-Bubble-Payloads tragen `text_source`, `text_key`, `skill_tier`, Rollen-/Situationsdiagnose und bleiben `visual_only`. `TerrainMap3DView` spiegelt diese Diagnosefelder im Bubble-Snapshot fuer Tests.
- Offene Punkte: Manueller Mission-Map-Sichtcheck fuer Ton, Lesbarkeit und Stoerfaktor bleibt offen.
- Risiken: Weitere Textpolitur muss die TASK_209-Laengengrenzen und den visual-only-Vertrag beibehalten; keine versteckten Gegnerinformationen in NPC-Gedanken.
- Lokale Pruefung: `task_213_skill_based_bubble_text_resolver_and_content_pass.gd` (31/0), `task_210_fireteamleader_command_feedback_bubbles.gd` (27/0), `task_212_npc_thought_bubble_hold_to_peek_overlay.gd` (19/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_214 als abschliessenden Bubble-Feedback-Playability-Smoke umsetzen.

### TASK_214 - Comic Bubble Feedback Playability Smoke
- Status: implementiert
- Stand: `scripts/tests/task_214_comic_bubble_feedback_playability_smoke.gd` prueft die Bubble-Reihe integriert ueber `MissionTacticalSandboxController`, `ComicBubbleRuntimeGate`, `TerrainMap3DView` und `SimulationRoot`: Normal/Minimal/Off, akzeptierte und blockierte FTL-Befehle, Cooldown, Maximalzahl, NPC-Gedanken per Hold, skillbasierte Texte und 2.5D-Snapshot-Diagnose.
- Stand: Der Smoke bestaetigt, dass Off/Minimal/Normal nur Sichtbarkeit steuern, Befehle weiter denselben Return-Wert behalten, NPC-Gedanken nur waehrend Hold erscheinen und Viewer-/Snapshot-Pfade keine `SimulationRoot`-Commands oder Effects erzeugen.
- Stand: `docs/dev/comic_bubble_manual_smoke_checklist.md` dokumentiert den manuellen Sichtcheck fuer Lesbarkeit, Timing, Nervfaktor, Kamera/Zoom und Abschaltbarkeit.
- Offene Punkte: Manueller Mission-Map-Sichtcheck anhand der Checkliste bleibt offen.
- Risiken: Headless prueft Timing-/Maximalgrenzen und Snapshot-Vertrag, aber nicht den subjektiven Stoerfaktor im echten Viewport. Falls Bubbles im Sichtcheck zu dominant wirken, sollte ein kleiner Opacity-/Duration-Polish folgen.
- Lokale Pruefung: `task_214_comic_bubble_feedback_playability_smoke.gd` (34/0), `task_160_tactical_playability_verifier.gd` (20/0), `task_168_multiplayer_snapshot_contract_verifier.gd` (20/0) und `git diff --check` laufen gruen.
- Naechster Schritt: Manuellen Bubble-Sichtcheck ausfuehren oder TASK_215 Performance Deep Pass starten.

### TASK_215 - Performance Deep Pass Baseline and Research
- Status: implementiert
- Stand: `scripts/tests/performance_deep_pass_harness.gd` misst Homebase, FOB, Live Mission 2.5D, Render Spike, Navigation und Multiplayer-Snapshot-Roundtrip. Der Harness nutzt `Performance.get_monitor()` und `Time.get_ticks_usec()` und aggregiert `Median`, `P95`, `P99`, `min`, `max` und `count`.
- Stand: `docs/performance/performance_baseline_report.md` dokumentiert Godot-Version, lokale Testfenster, Szenenmatrix, TASK_170-Ankerwerte und die manuelle Profiler-/Visual-Profiler-Checkliste. Der letzte TASK_170-Lauf war 62/0 gruen; lokal beobachtet wurden Live/Render-Spike je 36 ms und Open-HPA ca. 2642.25 usec.
- Stand: `docs/dev/performance_deep_pass_research_notes.md` enthaelt den Godot-Doku-/Forum-Abgleich und den TASK_215-Messrahmen; Forumshinweise bleiben explizit Hypothesen.
- Offene Punkte: Manueller Godot-Profiler-/Visual-Profiler-Lauf bei fester Viewportgroesse bleibt offen.
- Risiken: Performancewerte sind maschinenabhaengig und Headless ersetzt keinen echten Viewport-/GPU-Sichtcheck. Folge-Tasks duerfen erst nach messbarem Befund optimieren.
- Lokale Pruefung: `task_215_performance_deep_pass_baseline_and_research.gd` (32/0), `task_170_performance_warning_gate_verifier.gd` (62/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_216 fuer den 2.5D-Rendering-Node- und Draw-Budget-Pass umsetzen.

### TASK_216 - 2.5D Rendering Node and Draw Budget Pass
- Status: implementiert
- Stand: `TerrainMap3DView.get_render_snapshot()` enthaelt jetzt vertiefte Renderbudgets: Kategoriezaehler fuer Map, Marker, Patrol, Selection, Unit, Order, Contact, Drop und Status sowie Summen fuer Nodes, MeshInstances, MultiMeshInstances, Sprite3D, Label3D, Material- und Transparenzzaehler.
- Stand: Zusaetzliche Snapshots erfassen Transparenz-/Overlay-Budget, Draw-Monitorwerte und Pipeline-Compilation-Monitorwerte ueber dynamische `Performance`-Monitor-Keys. Bestehende TASK_170-Fallback-Zaehler bleiben erhalten.
- Stand: `docs/performance/2_5d_rendering_profile_report.md` priorisiert Kostenkategorien, bewertet MultiMesh-/Instancing-Kandidaten, dokumentiert Transparenz-/VFX-/Label-Budgets, Pipeline-Stutter-Kandidaten und den manuellen Visual-Profiler-Ablauf.
- Offene Punkte: Manueller Visual-Profiler-Lauf in Godot bei 1920x1080 bleibt offen.
- Risiken: Die neuen Zaehler sind Diagnose. MultiMesh-/Warmup-/Materialoptimierungen bleiben Folgeaufgaben und duerfen erst nach messbarem Befund erfolgen.
- Lokale Pruefung: `task_216_2_5d_rendering_node_draw_budget_pass.gd` (23/0), `task_170_performance_warning_gate_verifier.gd` (62/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_217 fuer Navigation, Pathfinding und LOS Performance umsetzen.

### TASK_217 - Navigation Pathfinding LOS Performance Pass
- Status: implementiert
- Stand: `scripts/tests/navigation_benchmark_harness.gd` deckt jetzt offene 32x32-/64x64-Karten, 32x32-Huegel/Deckung, 64x64-Engpass/Deckung, eine isolierte LOS-/Cover-Probe und Query-Flood-Staggering ab.
- Stand: Path-Batches liefern `query_time_usec` und `path_length_stats` mit `Median`, `P95`, `P99`, `min`, `max`, `avg` und `count`. `TerrainPathfinder` zaehlt optional `exposure_score_calls`, `los_check_count` und `cover_check_count`.
- Stand: Cache-Diagnose ist bewusst als aktueller No-Cache-Befund sichtbar (`path_cache_supported: false`, Hits 0, Misses = Queries), damit ein spaeterer Cache eine explizite Invalidation-Diagnose braucht. Die Avoidance-Probe nutzt einen direkten, reproduzierbaren Crossing-Step und die bestehenden Deadlock-/Neighbor-Diagnosen.
- Stand: `docs/performance/navigation_pathfinding_los_profile_report.md` dokumentiert Matrix, breite Startbudgets, LOS/Cover-Zaehler, Cache-Befund, Avoidance und Staggering.
- Offene Punkte: Performancewerte bleiben lokale Startbaselines; ein echter Path-Cache waere ein eigener Folge-Task.
- Risiken: LOS und Cover duerfen nicht durch schnelle, aber falsche Approximationen kaputtoptimiert werden. Der neue Diagnosepfad darf keine Gameplay-Wahrheit in Tests oder UI verschieben.
- Lokale Pruefung: `task_217_navigation_pathfinding_los_performance_pass.gd` (51/0), `task_131_verifier.gd` (21/0), `task_184_gameplay_hill_semantics_verifier.gd` (30/0), `task_187_npc_minimum_spacing_and_multiplayer_authority.gd` (16/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_218 fuer Simulation, Combat und AI Tick-Budgets umsetzen.

### TASK_218 - Simulation Combat AI Tick Budget Pass
- Status: implementiert
- Stand: `SimulationRoot.get_runtime_tick_budget_debug_snapshot()` liefert bei aktivem Debug Tick-Gesamtzeit, Scopezeiten fuer Command Queue, Effect Queue, Local Avoidance, Minimum Spacing, Objective Capture, Snapshot Broadcast und Tick-Signal sowie Queue-, Unit-, Navigation- und Spacing-Zaehler.
- Stand: `MissionCombatLoopDriver.get_combat_tick_budget_debug_snapshot()` liefert Scopezeiten fuer Contact Tracking, Enemy Security, Enemy Team Tactics, Medic Support, Enemy Advance, Friendly Standard Behavior, Overwatch/Security, Combat Fire Decision, Combat Resolution und Multiplayer-Snapshot-Kontext.
- Stand: `scripts/tests/simulation_combat_ai_tick_budget_harness.gd` misst kleine Mission, zwei Fireteams gegen Enemy-Team und vier Fireteams mit Medic/Downed/Tactics-Druck. Alle Szenarien liefern Median/P95/P99 fuer Simulation- und Combat-Ticks sowie Scope-Statistiken.
- Stand: `docs/performance/simulation_combat_ai_tick_profile_report.md` dokumentiert Scopes, Scale-Matrix, Hotpath-Audit, Authority-Grenze und breite Startbudgets.
- Offene Punkte: Zeitbudgets bleiben bewusst breit und sollten nach echten lokalen Profiling-Laeufen geschaerft werden.
- Risiken: Die Debug-Snapshots sind Diagnose und duerfen keine neue Gameplay-Wahrheit werden. Combat-/AI-Optimierungen muessen weiter authority-seitig bleiben.
- Lokale Pruefung: `task_218_simulation_combat_ai_tick_budget_pass.gd` (81/0), `task_160_tactical_playability_verifier.gd` (20/0), `task_162_combat_authority_contract_verifier.gd` (23/0), `task_187_npc_minimum_spacing_and_multiplayer_authority.gd` (16/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_219 fuer UI, HUD, Meta-Screens und Comic-Bubble-Performance umsetzen.

### TASK_219 - UI HUD Meta Comic Bubble Performance Pass
- Status: implementiert
- Stand: `scripts/tests/ui_hud_comic_bubble_performance_harness.gd` zaehlt Nodes, Controls, sichtbare Controls, Labels, RichTextLabels, TextureRects, Buttons, Panels, ScrollContainer und Tiefe fuer Homebase, FOB, Mission-HUD und Main Menu bei fester Drop-Light-Zielgroesse.
- Stand: `TacticalUITheme.build_flat_stylebox()` nutzt einen kleinen Parameter-Cache fuer wiederverwendete `StyleBoxFlat`-Ressourcen. Der Verifier prueft gleiche Parameter als gleiche Instanz und unterschiedliche Varianten als getrennte StyleBoxes.
- Stand: `ComicBubbleRuntimeGate.build_filter_performance_snapshot()` liefert eine read-only Probe fuer Input, Emits, Rejections, Cooldown-Key-Restore und Filterzeit. Off/Minimal/Normal sowie Thought-Hold werden gegen `TerrainMap3DView.get_render_snapshot()` geprueft.
- Stand: `docs/performance/ui_hud_comic_bubble_profile_report.md` dokumentiert Screen-Matrix, Theme-Reuse, Bubble-Budgets, Fixed-Window-Stabilitaet und den offenen manuellen Profiler-Lauf.
- Offene Punkte: Manueller Profiler-Lauf auf Homebase/FOB/Mission-HUD bleibt offen.
- Risiken: StyleBox-Reuse setzt voraus, dass gecachte StyleBoxes nicht nachtraeglich pro Control mutiert werden. Staerkeres Bubble-Pooling bleibt ein Folgeentscheid nach echten Messwerten.
- Lokale Pruefung: `task_219_ui_hud_meta_comic_bubble_performance_pass.gd` (48/0), `task_181_drop_light_fixed_window_audit_verifier.gd` (43/0), `task_214_comic_bubble_feedback_playability_smoke.gd` (34/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_220 fuer Asset-Import, VRAM und Shader-/Pipeline-Stutter umsetzen.

### TASK_220 - Asset Import VRAM Shader Pipeline Stutter Pass
- Status: implementiert
- Stand: `data/curated_asset_catalog.json`, `data/weapon_fire_vfx_catalog.json` und `data/comic_bubble_asset_catalog.json` enthalten jetzt TASK_220-`performance_budget`-Metadaten fuer `res://`-Runtime-Pfade, grobe Groessen-/VRAM-Grenzen und verdeckte Warmup-Policy.
- Stand: `scripts/tests/asset_vram_shader_pipeline_harness.gd` misst 98 Runtime-Assetpfade aus den Katalogen, davon 70 Texturen und 28 GLB-/PackedScene-Ressourcen. Texturen erhalten Dateigroesse, Dimensionen und `width * height * 4` als konservative VRAM-Schaetzung; GLBs erhalten Datei-, Node-, Mesh-, Surface- und Materialzaehler.
- Stand: Die Pipeline-Probe instanziert `scenes/tests/mission_map_3d_render_spike.tscn` und liest Draw-Budget, Transparenzbudget und Pipeline-Compilation-Zaehler aus `TerrainMap3DView.get_render_snapshot()`. Warmup laedt eine begrenzte Auswahl verdeckt und bleibt side-effect-frei.
- Stand: `docs/performance/asset_vram_shader_pipeline_report.md` dokumentiert Messumfang, Ampel, Warmup-Kandidaten, `res://`-Grenzen und offene Video-RAM-/Visual-Profiler-Sichtpruefung.
- Offene Punkte: Manueller Godot Video-RAM-/Visual-Profiler-Check bleibt offen, weil GPU-/Driverwerte lokal unterschiedlich sind.
- Risiken: Pipeline-Stutter ist hardwareabhaengig; Importkompression darf den Pixel-/Comic-Stil nicht sichtbar beschaedigen. Warmup darf keine Combat-, Bubble-, Objective- oder andere Gameplay-Events erzeugen.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_220_asset_import_vram_shader_pipeline_stutter_pass.gd` (399/0), `task_198_asset_import_gate_visual_smoke.gd` (170/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_221 fuer Multiplayer-Snapshot-Serialisierung und Payload-Kosten umsetzen.

### TASK_221 - Multiplayer Snapshot Serialization Performance Pass
- Status: implementiert
- Stand: `MultiplayerSnapshotContract` normalisiert Units, Vital-Updates, Contacts, Enemy-Security, Enemy-Team-Tactics, Fire-Events und neue `feedback_bubbles` stabil. Fire-/Muzzle-/Bubble-/Textreferenzen bleiben IDs (`weapon_id`, `muzzle_id`, `bubble_id`, `text_key`) statt Texture-, Pfad- oder Raw-Text-Payloads.
- Stand: `build_serialization_metrics()` liefert JSON-Byte-Schaetzung, Dictionary-/Array-/Scalar-Zaehler, Feldzaehler, ID-only-Offender und kanonische JSON-Diagnose. `SimulationRoot` reicht `feedback_bubbles` aus dem Snapshot-Kontext als reine Anzeige-/Snapshotdaten weiter.
- Stand: `scripts/tests/multiplayer_snapshot_performance_harness.gd` misst 8-, 32- und 96-Unit-Szenarien auf Build-/Apply-Zeit, JSON-Groesse, Dictionary-Anzahl, Event-/Bubble-/Enemy-Tactics-Zaehler, deterministische Sortierung und side-effect-freies Client-Apply.
- Stand: `docs/performance/multiplayer_snapshot_performance_report.md` dokumentiert Build/Apply/JSON-Messung, ID-only-Payload, Frequenzplan, Apply-Grenze und den offenen Network-Profiler-Lauf.
- Offene Punkte: Manueller Godot Network-Profiler-Lauf mit zwei Instanzen bleibt offen.
- Risiken: JSON-Bytes sind nur eine Schaetzung fuer das spaetere Wire-Format. Delta-Kompression bleibt bewusst ein Folgeentscheid nach echten Profilingdaten.
- Lokale Pruefung: `task_221_multiplayer_snapshot_serialization_performance_pass.gd` (63/0), `task_168_multiplayer_snapshot_contract_verifier.gd` (20/0), `task_169_multiplayer_two_client_playability_smoke.gd` (15/0), `task_204_enemy_tactics_multiplayer_authority_snapshot_patch.gd` (20/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_222 fuer Performance-Regression-Gate und manuelle Profiling-Checkliste umsetzen.

### TASK_222 - Performance Regression Gate and Manual Profile Checklist
- Status: implementiert
- Stand: `data/performance_budget_contract.json` trennt lokale Baseline, breite Projektbudgets, Warning-Gate-Regeln und manuelle Checks. Die Budgets decken render, navigation, simulation, UI, assets und snapshot ab und starten bewusst tolerant.
- Stand: `scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd` laeuft als zusammenfassendes Headless-Gate ueber Render-Spike, Navigation, Simulation/Combat, UI/Bubbles, Asset/VRAM/Pipeline und Multiplayer-Snapshot. Fehlertexte nennen Bereich, Messwert und Budget.
- Stand: `scripts/tests/run_task_222_performance_gate.ps1` fuehrt das Gate aus und blockiert echte RID-/ObjectDB-/Resource-Leak-Muster in der Godot-Ausgabe. TASK_170 bleibt als eigenes Warning-/Render-Gate erhalten und wird von TASK_222 referenziert.
- Stand: `docs/performance/performance_regression_gate.md` dokumentiert Budgetvertrag, Headless-Gate, TASK_170-Integration und Pflege-Regeln. `docs/dev/performance_manual_profile_checklist.md` ist auf Godot 4.6 Profiler, Visual Profiler, Monitors, Video RAM, Network Profiler und Stutter-Tests ausgerichtet.
- Offene Punkte: Manueller Profiling-Lauf nach Checkliste bleibt offen.
- Risiken: Headless-Werte ersetzen keine GPU-/Netzwerk-Sichtmessung. Budgets muessen nach mehreren echten lokalen Laeufen geschaerft werden, nicht aus Bauchgefuehl.
- Lokale Pruefung: `task_222_performance_regression_gate_and_manual_profile_checklist.gd` (82/0), `run_task_222_performance_gate.ps1`, `task_170_performance_warning_gate_verifier.gd` (62/0) und `git diff --check` laufen gruen.
- Naechster Schritt: Ab TASK_223 neue Gameplay-/UI-/Asset-Patches wieder gegen TASK_222 absichern.

### TASK_223 - Fog of War Modes Contract and Settings
- Status: implementiert
- Stand: `scripts/core/fog_of_war_mode_contract.gd` definiert die stabilen Modi `off`, `known_terrain` und `unexplored_blackout`, Default `known_terrain`, Settings-Normalisierung und Team-State-Snapshots mit getrenntem `terrain_knowledge`, `current_visibility` und `last_known_contacts`.
- Stand: `FogOfWarSystem` behaelt die alte boolesche Ziel-Sichtbarkeit pro Team/Target bei und ergaenzt Team-Modus, aktuelle Tile-/Event-Sicht, erkundete Tiles, letzte bekannte Kontakte sowie Peer-Team-Snapshots.
- Stand: `scripts/ui/game_settings_contract.gd` bereitet `fog_of_war_mode` als Gameplay-Settings-Wert vor. `MainMenuScreen.get_settings_snapshot()` meldet den Gameplay-/FoW-Settings-Snapshot mit.
- Stand: `docs/dev/fog_of_war_modes_contract.md` dokumentiert Mode-Verhalten, Settings, Multiplayer-Grenze und 32x32/64x64-Beispiele.
- Offene Punkte: Keine Visualisierung in diesem Task; TASK_224/TASK_225 setzen Tile-Runtime und 2.5D-Overlay um.
- Risiken: UI darf FoW-Zustand nur lesen. Terrain-Walkability, LOS, Cover und Combat-Wahrheit bleiben ausserhalb des FoW-View-Vertrags.
- Lokale Pruefung: `task_223_fog_of_war_modes_contract_and_settings.gd` (39/0), `task_092_verifier.gd` (12/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_224 fuer Tile-Sicht, Hoehenlinien, Deckung und LOS umsetzen.

### TASK_224 - Fog of War Tile Visibility Height Cover Runtime
- Status: implementiert
- Stand: `FogOfWarSystem.update_tile_visibility_for_team()` aktualisiert aktuelle und erkundete Tiles pro Team aus Observern, TerrainRegistry und `LineOfSightSystem`. Die Update-Diagnose meldet Tile-Anzahl, Observer, sichtbare Tiles, Checks, Dauer und die Policy `on_movement_command_tick_budget_or_relevant_state_change`.
- Stand: `known_terrain` haelt Terraininformationen lesbar, ohne hidden Dynamic Targets zu zeigen. `unexplored_blackout` trennt `visible`, `explored` und `unknown`; unbekannte Tiles liefern keine Cover-/Height-Infos.
- Stand: `get_known_tile_info()` liefert Cover, Height, Object Height, Surface, Edge Type und LOS-Blocker nur fuer bekannte Tiles. Wand-/Object-Blocker, Klippen-Infos und Hoehenblick werden ueber den bestehenden Terrain-/LOS-Vertrag gelesen.
- Stand: `filter_dynamic_entries_for_team()` liefert FoW-sichere dynamische Snapshotdaten: aktuell sichtbare Eintraege plus separate letzte bekannte Kontakte, aber keine Hidden-IDs als aktuelle Client-View.
- Stand: `TerrainRegistry` hat Lookup-Helfer fuer `tile_id` und sortierte Tile-Iteration.
- Offene Punkte: Finale 2.5D-Overlay-Darstellung bleibt TASK_225.
- Risiken: Tile-Sicht darf nur bei Bewegung, Command, Tick-Budget oder relevanten Statechanges aktualisiert werden; keine per-frame Raycast-Flut.
- Lokale Pruefung: `task_224_fog_of_war_tile_visibility_height_cover_runtime.gd` (25/0), `task_184_gameplay_hill_semantics_verifier.gd` (30/0), `task_217_navigation_pathfinding_los_performance_pass.gd` (51/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_225 fuer 2.5D-FoW-Overlay und Contacts umsetzen.

### TASK_225 - Fog of War 2.5D Visual Overlay and Contacts
- Status: implementiert
- Stand: `TerrainMap3DView` hat jetzt `set_fog_of_war_state()`/`set_fog_of_war_visual_state()` als reinen 2.5D-Visual-Eingang fuer die Modi `off`, `known_terrain` und `unexplored_blackout`. `off` erzeugt kein Overlay; `known_terrain` dimmt nicht sichtbare bekannte Tiles; `unexplored_blackout` trennt sichtbare, explored und unbekannte Tiles.
- Stand: Die FoW-Overlays werden als batched `MultiMeshInstance3D`-Layer gebaut, statt pro Tile eigene Nodes zu erzeugen. Der Render-Snapshot meldet Modus, Team, visible/known-dim/explored/unknown/Overlay-Tile-Zaehler und Overlay-Rebuilds; ein gleicher State baut nicht erneut.
- Stand: Dynamische 2.5D-Daten werden FoW-sicher gefiltert: Enemy-Security, Enemy-Tactics, Muzzle/VFX, Comic-Bubbles, Contacts und Enemy-Unit-Proxies erscheinen nur bei aktueller Tile-/Target-/Event-Sicht oder als eigener erlaubter letzter bekannter Contact.
- Stand: `FogOfWarSystem.build_team_visual_state_snapshot()` liefert Visual-Counter fuer sichtbare, explored, known und unknown Tiles, ohne die UI zur Gameplay-Wahrheit zu machen.
- Offene Punkte: Manueller 2.5D-Sichtcheck fuer die drei Modi bleibt offen, weil Headless nur Material, Counter und Node-Vertrag prueft.
- Risiken: Die Blackout-Abdeckung ist bewusst ein V1-Visual-Layer; spaeterer Shader-Polish darf die FoW-Daten nicht in Gameplay- oder UI-State duplizieren.
- Lokale Pruefung: `task_225_fog_of_war_2_5d_visual_overlay_and_contacts.gd` (33/0), `task_160_tactical_playability_verifier.gd` (20/0), `task_216_2_5d_rendering_node_draw_budget_pass.gd` (23/0), `task_223_fog_of_war_modes_contract_and_settings.gd` (39/0), `task_224_fog_of_war_tile_visibility_height_cover_runtime.gd` (25/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_226 fuer Settings-Shell und FoW-Auswahl im Hauptmenue umsetzen.

### TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- Status: implementiert
- Stand: `GameSettingsContract` speichert jetzt Display-, Audio- und Gameplay-Settings zentral: Resolution-Preset, Window Mode (`windowed`, `borderless`, `fullscreen`), VSync, Master/Music/SFX und `fog_of_war_mode`. Der alte FoW-Top-Level-Snapshot bleibt kompatibel.
- Stand: `MainMenuScreen` baut im vorhandenen Settings-Panel eine V1-Shell mit sichtbaren Sektionen fuer Anzeige, Audio, Eingabe und Gameplay. Apply/Cancel/Reset arbeiten ueber Draft-Settings; Menue-Oeffnen speichert nichts und erzeugt keinen Gameplay-State.
- Stand: Comic-Bubble-Settings bleiben im TASK_211-Vertrag, werden aber im Gameplay-Bereich angezeigt und zusammen mit Apply/Reset gespeichert. `scripts/ui/settings_screen.gd` kapselt kleine UI-/Snapshot-Helfer fuer Sektionen, Labels und OptionButton-Metadaten.
- Offene Punkte: Manueller Hauptmenue-Settings-Sichtcheck bleibt offen, vor allem fuer Aufloesung/Vollbild/Borderless auf echter lokaler Anzeige.
- Risiken: Display-Apply ist bewusst strukturell und Headless-sicher; echte Monitor-/Fullscreen-Eigenheiten muessen manuell geprueft werden.
- Lokale Pruefung: `task_226_main_menu_settings_shell_display_audio_input_gameplay.gd` (31/0), `task_199_main_menu_shell_background_image_verifier.gd` (50/0), `task_223_fog_of_war_modes_contract_and_settings.gd` (39/0), `task_211_comic_bubble_toggles_cooldowns_and_settings.gd` (25/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_227 fuer Multiplayer-Host/Join-Lobby-Flow aus dem Hauptmenue umsetzen.

### TASK_227 - Main Menu Multiplayer Host Join Lobby Flow
- Status: implementiert
- Stand: Das Hauptmenue routet `Multiplayer` jetzt auf `res://scenes/ui/multiplayer_lobby.tscn` und markiert den Pfad als produktiven Lobby-Flow statt als alten Testscreen-Adapter.
- Stand: `MultiplayerLobbyScreen` stellt Host-Port, Join-Adresse/-Port, Ready, host-only Start, Disconnect, Zurueck, Peer-Liste, Assignments und eine FoW-Settings-Zusammenfassung dar. Die UI spiegelt ausschliesslich `MultiplayerSession.get_session_snapshot()`.
- Stand: Host/Join/Ready/Start/Disconnect laufen ueber die bestehende `MultiplayerSession`. Start bleibt server-authoritativ ueber `request_start_mission()`; Client-Testzustand sieht keinen Start-Button und kann nicht starten.
- Stand: `MultiplayerSession._has_active_peer()` behandelt den Godot-Offline-Peer als inaktiv, damit idle Lobby-Snapshots nicht faelschlich als verbundene Session gelten.
- Offene Punkte: Manueller Zwei-Instanzen-Host/Join-Test bleibt offen.
- Risiken: Echter ENet-LAN-Test bleibt lokaler und portabhaengiger als der Headless-State-Verifier; Map-Download/Consent folgt erst in TASK_228.
- Lokale Pruefung: `task_227_main_menu_multiplayer_host_join_lobby_flow.gd` (27/0), `task_167_multiplayer_session_verifier.gd` (22/0), `task_169_multiplayer_two_client_playability_smoke.gd` (15/0), `task_199_main_menu_shell_background_image_verifier.gd` (50/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_228 fuer Multiplayer-Editor-Map-Manifest und Download-Consent vorbereiten.

### TASK_228 - Multiplayer Editor Map Manifest Download Consent
- Status: implementiert
- Stand: `scripts/multiplayer/multiplayer_map_manifest.gd` erzeugt und validiert V1-Editor-Map-Manifeste mit sicherer Map-ID, SHA-256-Hash, Groesse, optionalen Scenario-Metadaten und striktem Pfad-/JSON-Schutz.
- Stand: `MultiplayerSession` spiegelt Host-Map-Manifest und Map-Transfer-Zustand im Lobby-Snapshot. Clients erkennen bekannte, fehlende, abweichende oder ungueltige Maps und setzen Consent-/Startfaehigkeitsstatus, ohne Mapdaten in laufende Mission-Snapshots zu packen.
- Stand: `MultiplayerLobbyScreen` zeigt bei unbekannter oder abweichender Host-Map einen Consent-Prompt, blockiert den Client-Missionsstart bis zur Annahme und laesst Ablehnung ohne kaputten Session-State im Lobby-State.
- Stand: Angenommene Map-JSONs werden gegen Hash, Groesse, Grundstruktur und verbotene Pfadfelder validiert und nur unter `user://downloaded_maps/` mit versioniertem Dateinamen gespeichert.
- Offene Punkte: Echter Host/Join-Test mit unbekannter Editor-Map und spaeterer Payload-Transport bleiben manuell bzw. Folgethema.
- Risiken: Map-Download bleibt ein Sicherheitsrand; Asset-Pack-Synchronisation und Workshop-/Mod-Browser bleiben bewusst ausser Scope.
- Lokale Pruefung: `task_228_multiplayer_editor_map_manifest_download_consent.gd` (27/0), `task_167_multiplayer_session_verifier.gd` (22/0), `task_168_multiplayer_snapshot_contract_verifier.gd` (20/0), `task_227_main_menu_multiplayer_host_join_lobby_flow.gd` (27/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_229 fuer Editor-Bedienbarkeit, Validierungsdiagnosen und Multiplayer-Manifest-Vorbereitung umsetzen.

### TASK_229 - Map Editor Usability Authoring Pass
- Status: implementiert
- Stand: Der Map Editor zeigt jetzt ein kompaktes `Authoring Status`-Panel mit aktivem Werkzeug, Brushradius, selektiertem Tile, Validierungszaehlern und Multiplayer-Map-Manifeststatus.
- Stand: `get_map_editor_usability_snapshot()` und `get_authoring_validation_snapshot()` liefern pruefbare Tool-, Tile-, Marker-, Patrol-, Scenario-, Hoehen-, Walkability-, FoW- und Manifestdiagnosen, ohne Gameplay-State zu erzeugen.
- Stand: `build_multiplayer_map_manifest_preview()` bereitet Manifeste nur aus gespeicherten Mapdaten vor und diagnostiziert ungespeicherte oder fehlende Mapdateien. `create_live_test_scene_from_current_scenario()` bleibt aus dem Editor erreichbar.
- Stand: `get_authoring_action_contract_snapshot()` dokumentiert den aktuellen Single-Tile-Patch-Scope fuer Undo/Redo-Folgearbeiten, ohne ein grosses Undo-System in diesen Task zu ziehen.
- Offene Punkte: Manueller Editor-Sichtcheck nach `docs/manual_checks/map_editor_usability_authoring_checklist.md` bleibt offen.
- Risiken: Die neuen Snapshots sind Diagnose- und Bedienbarkeitsoberflaeche; Map-, Scenario- und Gameplay-Wahrheit bleiben in TerrainMapData, MissionScenarioData und Runtime-Systemen.
- Lokale Pruefung: `task_229_map_editor_usability_authoring_pass.gd` (31/0), `task_163_map_editor_module_split_verifier.gd` (17/0), `task_183_editor_hill_authoring_verifier.gd` (66/0), `task_158_verifier.gd` (42/0), `task_200_enemy_team_tactics_contract_and_editor_config.gd` (116/0), `task_228_multiplayer_editor_map_manifest_download_consent.gd` (27/0) und `git diff --check` laufen gruen. TASK_200 meldet nach Erfolg bekannte Headless-Ressourcenwarnungen beim Exit.
- Naechster Schritt: TASK_230 fuer Flight Altitude Layer und Air Visibility Audit umsetzen.

### TASK_230 - Flight Altitude Layer and Air Visibility Audit
- Status: implementiert
- Stand: `docs/dev/flight_altitude_layer_contract.md` trennt `mission_air` klar von Terrain-`height_level`: Air-Visuals setzen keine Walkability, Cover, LOS oder Objekt-Hoehe und veraendern Gameplay nur ueber autoritative SimulationRoot-Events.
- Stand: `TerrainMap3DView` normalisiert Dropship-Payloads auf einen expliziten Air-Layer, setzt eine Mindest-Clearance ueber der lokalen Terrainoberflaeche und exportiert Air-Diagnosen im Render-Snapshot.
- Stand: FoW blendet LZ-/Approach-Surface-Marker aus, wenn deren Tile nicht sichtbar ist. Friendly Dropship bleibt fuer das eigene Team sichtbar; Enemy-/Air-Contacts folgen weiter der bestehenden FoW-/Contact-Regel.
- Stand: `MultiplayerSnapshotContract` normalisiert Dropship-Air-Felder read-only (`air_layer`, `flight_altitude_clearance`, `terrain_height_independent`, `reveals_unknown_terrain`) und Clients wenden sie an, ohne Commands zu enqueuen.
- Offene Punkte: Manueller Mission-Map-Sichtcheck mit Huegeln, Waenden und Dropship bleibt offen.
- Risiken: Air-Layer ist weiterhin Darstellung/Missionsstatus, keine neue Flugphysik und kein LZ-Regelwechsel.
- Lokale Pruefung: `task_230_flight_altitude_layer_and_air_visibility_audit.gd` (27/0), `task_160_tactical_playability_verifier.gd` (20/0), `task_225_fog_of_war_2_5d_visual_overlay_and_contacts.gd` (33/0), `task_168_multiplayer_snapshot_contract_verifier.gd` (20/0), `task_185_hill_visuals_edge_lines_verifier.gd` (30/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_231 fuer App-Shell Game Setup Integration und Open Items Review umsetzen.

### TASK_231 - App Shell Game Setup Integration and Open Items Review
- Status: implementiert
- Stand: `docs/reviews/app_shell_game_setup_open_items_review.md` fasst Hauptmenue, Singleplayer, Multiplayer-Lobby, Settings, Editor, Map-Consent, FoW und `mission_air` als zusammenhaengenden App-Einstieg zusammen.
- Stand: `docs/manual_checks/app_shell_full_flow_checklist.md` beschreibt den manuellen Full-Flow-Sichtcheck fuer Hauptmenue, Einzelspieler, Multiplayer, Editor und FoW/Air.
- Stand: `scripts/tests/task_231_app_shell_game_setup_integration_and_open_items_review.gd` prueft Routing, Settings-Persistenz, FoW-/Bubble-Uebergabe, Lobby-Consent, Host/Client-Startgrenzen, Editor-Manifest-/Live-Test-Vorbereitung und Air/FoW-Unknown-Boundary.
- Offene Punkte: Manueller Full-Flow-Sichtcheck, echter Zwei-Instanzen-LAN-Test, echter Peer-Payload-Transport fuer Editor-Maps und vollstaendiges Editor-Undo/Redo bleiben bewusst als kleine Folgepunkte dokumentiert.
- Risiken: TASK_231 ist ein Review-/Smoke-Slice; Folgearbeiten duerfen keine zweite Gameplay-Wahrheit in UI-, Editor- oder Visual-Skripten erzeugen.
- Lokale Pruefung: `task_231_app_shell_game_setup_integration_and_open_items_review.gd`, `task_199_main_menu_shell_background_image_verifier.gd`, `task_227_main_menu_multiplayer_host_join_lobby_flow.gd`, `task_225_fog_of_war_2_5d_visual_overlay_and_contacts.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_232 fuer den Start-Roster-Generation-Contract umsetzen.

### TASK_232 - Start Roster Generation Contract
- Status: implementiert
- Stand: `scripts/meta/start_roster_generator.gd` erzeugt seeded, reproduzierbar 20 bis 30 Start-NPCs, default 24, als gueltige `MetaUnitProfile`-Daten mit Namen, Callsigns, Portraitpfaden, Rollenmix, Skills, Traits und TASK_207-Rank-Badges.
- Stand: Der Generator liefert Fireteam-Vorschlaege mit `balanced_not_optimal`-Policy und dokumentiert die Multiplayer-Grenze `player_profile_local`, ohne private volle Roster ungefragt in Snapshots zu veroeffentlichen.
- Stand: `MainMenuScreen` erzeugt beim ersten Start ein In-Memory-Roster und stellt einen Button `Neues Team generieren` bereit, der ein vorhandenes Roster erst nach Bestaetigung ersetzt. Persistenz bleibt TASK_234.
- Stand: `docs/dev/character_roster_generation_contract.md` dokumentiert Generator, Rollenmix, Fireteam-Vorschlaege, Main-Menu-Grenze und Multiplayer-Ownership.
- Offene Punkte: Portrait-Katalog/Identity-Asset-Zuordnung folgt in TASK_233. Persistenter Roster-Store, Save/Load und Reset-Archivierung folgen in TASK_234.
- Risiken: Der V1-Generator ist bewusst ein Contract- und Spielstart-Slice; weitere Roster-Lebensdauer, Progression oder Recruiting duerfen nicht im Main Menu gespeichert werden.
- Lokale Pruefung: `task_232_start_roster_generation_contract.gd`, `task_207_npc_rank_skill_badge_derivation.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_233 fuer Portrait Identity Catalog und Roster Presentation umsetzen.

### TASK_233 - Portrait Identity Catalog and Roster Presentation
- Status: implementiert
- Stand: `data/portrait_identity_catalog.json` katalogisiert 30 Start-Roster-Kandidaten aus `res://Assets/Char/` mit stabilen `char_portrait_*`-IDs, `res://`-Pfaden, Bildgroessen, Tags und Diagnosen fuer grosse Quellen.
- Stand: `docs/assets/portrait_identity_inventory.md` dokumentiert den Scan von 88 PNG-Dateien, die Aufloesungsverteilung und feste Zielgroessen fuer Character Sheet, Roster-Karten und Compact-Karten.
- Stand: `scripts/meta/portrait_identity_catalog.gd` validiert den Katalog, laedt Texturen, setzt feste `TextureRect`-Vertraege und liefert deterministische Seed-Zuweisungen fuer 20 bis 30 Start-NPCs. `MetaUnitProfile` traegt nun `portrait_id` neben `portrait_path`.
- Stand: `StartRosterGenerator` weist Portrait-ID und Runtime-Pfad deterministisch zu; `CharacterSheetView` und `NPCCompactCard` laden Portraits ueber den Katalog-Helper, ohne Layoutgroessen aus grossen Original-PNGs abzuleiten.
- Offene Punkte: Manueller Sichtcheck fuer Character Sheet, Homebase-Roster und FOB-Karten bleibt offen; ein spaeterer Crop-/Thumbnail-Pass kann die uneinheitlichen Ausschnitte kuenstlerisch nachziehen.
- Risiken: Der Katalog nutzt bewusst Original-PNGs mit festen UI-Rechtecken statt physische Thumbnail-Dateien. Falls Scroll-Performance sichtbar leidet, sollte ein eigener Import-/Thumbnail-Slice folgen.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_233_portrait_identity_catalog_and_roster_presentation.gd`, `task_232_start_roster_generation_contract.gd`, `task_207_npc_rank_skill_badge_derivation.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd` und `task_176_fob_loadout_weapon_preview_selector_verifier.gd` laufen gruen.
- Naechster Schritt: TASK_234 fuer persistente Player-Roster-Saves und sicheren New-Team-Reset umsetzen.

### TASK_234 - Persistent Player Roster Save and Reset
- Status: implementiert
- Stand: `scripts/meta/player_roster_store.gd` speichert und laedt V1-Roster unter `user://profiles/<profile>/roster_v1.json` mit `schema_version`, `store_id`, `profile_id`, `generator_seed`, `roster_size`, vollstaendigem Roster-Snapshot und dokumentierter Multiplayer-Grenze.
- Stand: Fehlende oder ungueltige Saves erzeugen einen sicheren TASK_232/TASK_233-Fallback. Reset/New-Team archiviert den alten Save unter `user://profiles/<profile>/archive/`, bevor ein neuer Seed geschrieben wird.
- Stand: `MainMenuScreen` nutzt den Store fuer First-Start, Load und bestaetigten Reset; Testpfade koennen isoliert gesetzt werden. `MetaLayerFlow` uebernimmt ein gueltiges `local_player`-Save fuer Homebase/FOB und faellt sonst auf `UnitRosterPresets` zurueck.
- Stand: `docs/dev/player_roster_save_contract.md` dokumentiert Speicherort, Format V1, Unit-Felder inklusive `portrait_id`/Traits, Reset-Archiv und lokale Multiplayer-Profilgrenze.
- Offene Punkte: Manueller Start/Reset-Sichtcheck bleibt offen; echte Recovery-/Mission-Folgefelder werden erst von spaeteren Character-Gameplay-Tasks fachlich befuellt.
- Risiken: Der V1-Store schreibt Original-Roster-Dictionaries. Schema-Migrationen sollten ab jetzt explizit versioniert werden, statt Felder still umzubenennen.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_234_persistent_player_roster_save_and_reset.gd`, `task_232_start_roster_generation_contract.gd`, `task_231_app_shell_game_setup_integration_and_open_items_review.gd`, `task_226_main_menu_settings_shell_display_audio_input_gameplay.gd`, `task_233_portrait_identity_catalog_and_roster_presentation.gd` und `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd` laufen gruen.
- Naechster Schritt: TASK_235 fuer Character Sheet und Roster Gameplay Expansion umsetzen.

### TASK_235 - Character Sheet Roster Gameplay Expansion
- Status: implementiert
- Stand: `MetaUnitProfile` traegt jetzt optionale V1-Character-Gameplay-Felder fuer Verfuegbarkeit, Recovery, Relationship-Zusammenfassung, Relationship-Links, Fireteam-Historie, Mission-Historie und Progression.
- Stand: `StartRosterGenerator` initialisiert aktive Status-/Progress-Fallbacks, damit neue gespeicherte Roster schon stabile Felder fuer Folge-Tasks besitzen, ohne Gameplaywirkung zu behaupten.
- Stand: `CharacterSheetFormatter` und `CharacterSheetView` zeigen neben Identity, Portrait, Traits, Kernwerten und Badges nun kurze Sektionen fuer Rolle/Loadout, Status/Recovery, Teamfit und Progress.
- Stand: Homebase-Rosterkarten bleiben bei 20 bis 30 NPCs kompakt und zeigen Status plus Standort in einer Kurzzeile. Homebase und FOB akzeptieren denselben Profil-Payload.
- Offene Punkte: Manueller Homebase/FOB-Sichtcheck mit 24+ NPCs bleibt offen; echte Relationship- und Progressionswerte folgen fachlich in TASK_236 und TASK_237.
- Risiken: Die neuen Felder sind Darstellungs- und Speicherfelder. Gameplaywirkung darf erst durch eigene Resolver-/Simulation-Tasks entstehen.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_235_character_sheet_roster_gameplay_expansion.gd`, `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`, `task_176_fob_loadout_weapon_preview_selector_verifier.gd`, `task_207_npc_rank_skill_badge_derivation.gd`, `task_234_persistent_player_roster_save_and_reset.gd` und `task_232_start_roster_generation_contract.gd` laufen gruen.
- Naechster Schritt: TASK_236 fuer Fireteam Relationship, Affinity und Cohesion umsetzen.

### TASK_236 - Fireteam Relationship Affinity and Cohesion
- Status: implementiert
- Stand: `RosterRelationshipModel` verwaltet pairwise Affinity, Relationship-Tags und symmetrische V1-Links fuer NPC-Paare.
- Stand: `StartRosterGenerator` erzeugt deterministisch milde Startbeziehungen und schreibt `relationship_pairs` sowie Unit-`relationship_links`; `PlayerRosterStore` validiert und speichert diese Daten im Roster-Payload.
- Stand: `FireteamCohesionResolver` berechnet Fireteam-Cohesion aus Affinity, bekannter Paarzahl, Fireteam-Historie und Leadership und gibt kleine zentrale Gameplay-Modifikatoren fuer Morale, Communication, Coordination und Advance-Readability zurueck.
- Stand: Character Sheet zeigt Teamfit, beste Beziehung und groesste Spannung; die FOB-Fireteam-Card zeigt eine kurze Cohesion-/Teamfit-Zeile.
- Offene Punkte: Kein Dialog-/Drama-System; echte Progressionsveraenderungen aus Missionsergebnissen folgen in TASK_237.
- Risiken: Relationship-Werte bleiben absichtlich mild, damit Skills, Loadout und taktische Entscheidungen nicht entwertet werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_236_fireteam_relationship_affinity_and_cohesion.gd`, `task_235_character_sheet_roster_gameplay_expansion.gd`, `task_234_persistent_player_roster_save_and_reset.gd`, `task_232_start_roster_generation_contract.gd`, `task_176_fob_loadout_weapon_preview_selector_verifier.gd`, `task_178_fob_drop_light_fixed_fullhd_layout_verifier.gd` und `task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd` laufen gruen.
- Naechster Schritt: TASK_237 fuer Mission Progression, XP, Morale und Frustration umsetzen.

### TASK_237 - Mission Progression XP Morale Frustration
- Status: implementiert
- Stand: `MissionProgressionResolver` wertet Missionsergebnisse, Unit-Events, Team-State und Fireteam-Cohesion zentral aus und erzeugt kleine XP-, Skill-, Rollen-, Morale-, Frustration-, Mission-History- und Fireteam-History-Updates.
- Stand: Downed Units gehen in Recovery; Relationship-/Cohesion-Drift bleibt pro Mission bewusst klein und basiert auf den TASK_236-Relationship-Daten.
- Stand: `MetaLayerFlow` wendet Progression beim Combat-Resolve auf den lokalen Player-Roster an und speichert den aktualisierten Roster ueber `PlayerRosterStore`; der Save-Payload traegt `progression_schema_version`.
- Stand: `DebriefTestScreen` zeigt bis zu fuenf knappe Character-Updates neben Missionsergebnis und Rueckkehrstatus.
- Offene Punkte: Kein Skilltree, keine Perks und kein Permadeath. Personalereignisse aus Frust/Morale folgen in TASK_238.
- Risiken: Die Formeln sind absichtlich klein und clampen Morale/Frustration/Skill-Gains, damit eine einzelne Mission die Balance nicht sprengt.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_237_mission_progression_xp_morale_frustration.gd`, `task_096_recovery_verifier.gd`, `task_160_tactical_playability_verifier.gd`, `task_236_fireteam_relationship_affinity_and_cohesion.gd` und `task_234_persistent_player_roster_save_and_reset.gd` laufen gruen.
- Naechster Schritt: TASK_238 fuer Personalereignisse, Recruiting und Entlassen vorbereiten.

### TASK_238 - Personnel Events Recruit Leave Dismiss Notifications
- Status: implementiert
- Stand: `PersonnelEventModel` definiert stabile Event-IDs, Payloads und Nachrichten fuer `recruit_available`, `joins_roster`, `leaves_roster`, `dismissed`, `unavailable`, `returns` und `requests_change`.
- Stand: `PersonnelEventResolver` erzeugt V1-Events nach mehreren Missionen, hohem Frust und Recovery/Unavailable-Status, baut Recruit-Kandidaten aus dem Start-Roster-Generator und erzwingt Dismiss nur ueber Bestaetigungs-Events.
- Stand: `MetaLayerFlow` laesst Personalereignisse nach der Mission-Progression laufen und speichert sie im Player-Roster; `PlayerRosterStore` validiert die Eventliste beim Save/Load.
- Stand: Homebase und Debrief zeigen knappe Personnel-Nachrichten, ohne Gameplay-Zustand in UI-Skripte zu verschieben.
- Offene Punkte: Kein HR-/Markt-/Storydeck-System; echte Player-UI-Aktionen fuer Recruit-Annahme und Dismiss koennen spaeter separat polishen.
- Risiken: Event-Haeufigkeit muss nach Playtests feinjustiert werden, damit Nachrichten nicht willkuerlich wirken.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_238_personnel_events_recruit_leave_dismiss_notifications.gd`, `task_237_mission_progression_xp_morale_frustration.gd`, `task_236_fireteam_relationship_affinity_and_cohesion.gd`, `task_234_persistent_player_roster_save_and_reset.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_239 fuer Character Gameplay Bubble Mission Integration umsetzen.

### TASK_239 - Character Gameplay Bubble Mission Integration
- Status: implementiert
- Stand: `CharacterGameplayResolver` fasst Unit- und Fireteam-Character-State zentral zusammen und liefert kleine, clampte Modifikatoren fuer Communication, Coordination, Advance-Readability und FTL-Clarity.
- Stand: FTL-Feedback-Bubbles bekommen Character-Kontext aus Leadership/Communication/Cohesion; NPC-Thought-Bubbles koennen bei Frust, niedriger Morale und Teamfit-Hinweisen kurze Character-Texte ausgeben, ohne Command- oder Combat-Effekte zu setzen.
- Stand: `MissionCombatLoopDriver` stellt einen public Character-Gameplay-Snapshot aus Mission-Units bereit; `SimulationRoot` und `MultiplayerSnapshotContract` transportieren nur Fireteam-ID, Cohesion-/Morale-/Frust-Status und Member-Count, keine privaten Roster-Details.
- Stand: Der Resolver dokumentiert die Summary-Grenze (`summarized_context_not_per_frame`) und vermeidet neue direkte Relationship-/Frust-Looks in UI-Hotpaths.
- Offene Punkte: Kein komplexes Persoenlichkeitssystem und keine grossen Combat-Boni; weitere Textpolitur und echte Player-Sichtchecks koennen spaeter separat erfolgen.
- Risiken: Weitere Character-Gameplay-Erweiterungen muessen den zentralen Resolver respektieren, damit Combat/AI lesbar bleiben.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_239_character_gameplay_bubble_mission_integration.gd`, `task_213_skill_based_bubble_text_resolver_and_content_pass.gd`, `task_218_simulation_combat_ai_tick_budget_pass.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_240 fuer Multiplayer Player Roster Ownership Contract umsetzen.

### TASK_240 - Multiplayer Player Roster Ownership Contract
- Status: implementiert
- Stand: `MultiplayerRosterContract` dokumentiert und validiert `host_roster`, `player_rosters` und `scenario_roster`; Peer- und Unit-Ownership liefern `owner_peer_id`, `roster_source`, `roster_mode`, `roster_public_ref` und `character_gameplay_authority`.
- Stand: `MultiplayerSession` fuehrt einen Host-waehlbaren `roster_mode`, `peer_rosters` in den Start-Assignments und einen Lobby-Snapshot mit Public-/Private-Field-Policy.
- Stand: `MultiplayerSnapshotContract` normalisiert Ownership-Felder fuer Unit-Snapshots und ignoriert private Roster-Profile; `PlayerRosterStore` erzeugt public-safe Roster-Previews ohne Progression, Beziehungen, Seeds oder Asset-Pfade.
- Stand: Die Multiplayer-Lobby zeigt den Roster-Modus strukturell an und kann ihn als Host vor Missionsstart wechseln.
- Offene Punkte: Noch kein Account-/Cloud-Sync und kein echter Cross-Client-Save-Transfer; das bleibt bewusst ausserhalb des Vertrags.
- Risiken: Spaetere Multiplayer-Features muessen diesen Public-/Private-Vertrag einhalten, sonst leaken Character-Save-Daten schnell in Snapshot- oder Lobby-Pfade.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_240_multiplayer_player_roster_ownership_contract.gd`, `task_168_multiplayer_snapshot_contract_verifier.gd` und `task_227_main_menu_multiplayer_host_join_lobby_flow.gd` laufen gruen.
- Naechster Schritt: TASK_241 fuer Character Gameplay Playability Smoke umsetzen.

### TASK_241 - Character Gameplay Playability Smoke
- Status: implementiert
- Stand: `task_241_character_gameplay_playability_smoke.gd` prueft den kompletten Character-Gameplay-Datenfluss: First-start-Roster erzeugen, speichern, laden, Character Sheet rendern, Homebase-/FOB-Karten speisen, Fireteam-Cohesion berechnen, Mission-Progression anwenden, Debrief und Personnel-Event anzeigen.
- Stand: Der Smoke prueft FTL-Feedback-Bubbles und NPC-Gedanken gegen Character-State sowie den public Character-Gameplay-Snapshot ohne private Roster-Felder.
- Stand: Multiplayer-Grenze wird im selben Flow mit public Roster Preview und Unit-Snapshot-Ownership aus TASK_240 geprueft.
- Stand: `docs/manual_checks/character_gameplay_playability_checklist.md` und `docs/reviews/character_gameplay_balance_and_open_items_review.md` halten Sichtcheck und Balance-/Open-Items fest.
- Offene Punkte: Manueller Character-Gameplay-Sichtcheck ist vorbereitet, aber im Headless-Lauf nicht ausgefuehrt.
- Risiken: Der Integrationssmoke findet Zusammenspiel, lokalisiert Fehler aber grober als Einzelverifier; echte Balance bleibt Playtest-Arbeit.
- Lokale Pruefung: `task_241_character_gameplay_playability_smoke.gd`, `task_160_tactical_playability_verifier.gd` und `task_214_comic_bubble_feedback_playability_smoke.gd` laufen gruen.
- Naechster Schritt: TASK_244 fuer Combat Movement UI SFX Integration umsetzen.

### TASK_242 - Audio SFX Source Inventory and Curated Import
- Status: implementiert
- Stand: Die Kenney-All-in-1-Audioquelle wurde inventarisiert und als kleines projektlokales SFX-Subset unter `Assets/used/audio/kenney_all_in_one/` importiert. `data/audio_sfx_catalog.json` beschreibt 29 stabile Audio-IDs fuer UI, Combat, Movement, Impact, Explosion und kurze Sci-Fi-Ambiences.
- Offene Punkte: Finale Soundmischung und Runtime-Hooks folgen in TASK_243 und TASK_244.
- Risiken: Movement-Sand/Rock nutzt vorerst bewusst markierte Platzhalter; spaetere Integration muss Event-Spam und FoW-Audio-Leaks vermeiden.
- Naechster Schritt: TASK_243 baut den Audio-Event-Vertrag und die Bus-/Player-Schicht.

### TASK_243 - Audio Event Contract and Bus Setup
- Status: implementiert
- Stand: `AudioEventContract` laedt `data/audio_sfx_catalog.json` und normalisiert stabile Event-IDs, Bus-Routing, Spatial/Non-Spatial, Cooldowns, Polyphony, Pitch-Ranges und Read-only-Multiplayer-Kontext.
- Stand: `AudioEventBus` richtet die Busse `SFX`, `UI`, `Combat`, `Movement`, `Ambient` und `Music` ein, routet Kategorie-Busse in `SFX`, wendet Master/SFX/UI/Combat/Movement/Ambient-Settings an und liefert Diagnosewerte fuer Stimmen, fehlende IDs/Ressourcen und unterdrueckte Events.
- Stand: `AudioEventPlayerPool` begrenzt und wiederverwendet 2D-/3D-Player. Headless-Tests simulieren Playback, damit Verifier sauber ohne Audio-Playback-Leaks laufen; normale Fensterlaeufe nutzen echte `play()`-Aufrufe.
- Offene Punkte: UI-, Combat-, Movement-, Impact- und Explosion-Hooks folgen in TASK_244.
- Risiken: Der Bus ist Darstellung; Folgearbeiten duerfen ihn nicht als Gameplay-Wahrheit oder versteckte FoW-/Multiplayer-Informationsquelle nutzen.
- Naechster Schritt: TASK_244 bindet die Events an Spiel- und UI-Ablaeufe an.

### TASK_244 - Combat Movement UI SFX Integration
- Status: implementiert
- Stand: `AudioEventBus` besitzt jetzt Integrations-Helfer fuer UI-Aktionen, Waffenfeuer, Movement-Steps, Impacts und Explosionen. Diagnose-Snapshots zaehlen Events nach Kategorie/Event sowie Dedupe-, Cooldown-, Polyphony-, Settings- und Visibility-Unterdrueckung.
- Stand: Hauptmenue und Multiplayer-Lobby melden zentrale Click/Confirm/Switch/Cancel/Warning-Aktionen ueber projektlokale UI-Audio-Events. Slider-/Draft-Audio-Aenderungen loesen bewusst keine Dauer-SFX aus.
- Stand: `TerrainMap3DView` spielt sichtbare Fire-Events am Muzzle-Flash-Kontext und sichtbare bewegte Unit-Steps mit per-Unit-Rate-Limit. `MissionCombatLoopDriver` meldet Impacts und Rocket-Explosionen aus autoritativem Damage-Kontext.
- Stand: `SimulationRoot` leitet Fire-Events aus akzeptierten Multiplayer-Snapshots read-only an einen vorhandenen Audio-Bus weiter; Fire-Event-IDs dienen als Dedupe-Key, damit lokale und Snapshot-Ausgabe nicht doppeln.
- Offene Punkte: Manueller Fenster-Hoercheck nach `docs/manual_checks/audio_sfx_playability_checklist.md` bleibt offen; finale Mischung bleibt spaeterer Politur vorbehalten.
- Risiken: SFX-Integration bleibt Darstellung. Folgearbeiten duerfen Audio nicht als Gameplay-Wahrheit, FoW-Sensorik oder versteckten Multiplayer-State verwenden.
- Lokale Pruefung: `task_244_combat_movement_ui_sfx_integration_verifier.gd`, `task_160_tactical_playability_verifier.gd`, `task_168_multiplayer_snapshot_contract_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_245 fuer Background Image Catalog and Screen Usage umsetzen.

### TASK_245 - Background Image Catalog and Screen Usage
- Status: implementiert
- Stand: Die vier gelieferten Apr-18-Backgrounds liegen mit stabilen ASCII-Dateinamen unter `Assets/used/backgrounds/ai_generated/` und sind als Godot-Texturen importiert.
- Stand: `data/background_image_catalog.json` katalogisiert die neuen Bilder plus das bestehende TASK_199-Main-Menu-Bild mit stabilen Background-IDs, `res://`-Pfaden, Screen-Hints, Crop-Ankern, Dimming und UI-Texture-Budget.
- Stand: `BackgroundImageCatalog` kapselt Katalogladen, `TextureRect`-Anwendung und Screen-Assignment-Diagnose. Das Main Menu nutzt den Katalog fuer `main_menu_shell`; die Multiplayer-Lobby nutzt `multiplayer_lobby_hangar` mit dunklem Shade hinter dem bestehenden Panel.
- Offene Punkte: Manueller Full-HD-Sichtcheck nach `docs/manual_checks/background_screen_readability_checklist.md` bleibt offen; Mission-Select/Loading/Debrief nutzen die vorbereiteten IDs erst, wenn diese Screens als eigene Shells umgesetzt werden.
- Risiken: Backgrounds bleiben visual-only. Folgearbeiten duerfen keine lokalen User-Pfade einbauen und keine Backgrounds im Gameplay-Hotpath vorladen.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_245_background_image_catalog_and_screen_usage_verifier.gd`, `task_199_main_menu_shell_background_image_verifier.gd`, `task_227_main_menu_multiplayer_host_join_lobby_flow.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_246 fuer Visual Scale Alignment Asset Pass umsetzen.

### TASK_246 - Visual Scale Alignment Asset Pass
- Status: implementiert
- Stand: `docs/reviews/asset_scale_alignment_matrix.md` dokumentiert den gemeinsamen Alignment-Vertrag fuer Friendly-/Enemy-NPCs, Helme, Standard-/Compact-/Medic-/Heavy-Blaster, Sniper, Rocket, Muzzle-Flash, Audio-Anker, Background-Crops und Terrain-Hoehenanker.
- Stand: `scripts/tests/task_246_visual_scale_alignment_asset_pass_verifier.gd` prueft Resource-Ladung, Skala, Sockets, Weapon-Visual-Loadouts, VFX-Katalog, Muzzle-/Audio-/Impact-Kompatibilitaet, Background-Metadaten und feste Main-Menu-/Lobby-Fenster. `scripts/tests/task_174_character_helmet_blaster_attachment_verifier.gd` akzeptiert jetzt die seit TASK_190 erweiterte 6er Weapon-Visual-Mapping-Liste bei weiterhin 4 Blaster-Kit-Import-GLBs.
- Offene Punkte: Manueller 2.5D-/Full-HD-Sichtcheck nach `docs/manual_checks/visual_scale_alignment_checklist.md` bleibt offen.
- Risiken: Visuelle Offsets duerfen Gameplay-Hoehe, LOS, Cover oder Tile-Wahrheit nicht veraendern; Performance-Wirkung von VFX, Audio und Backgrounds wird erst in TASK_249 gemessen.
- Lokale Pruefung: `task_246_visual_scale_alignment_asset_pass_verifier.gd`, `task_174_character_helmet_blaster_attachment_verifier.gd` und `task_190_weapon_visual_loadout_expansion_and_scale.gd` laufen gruen.
- Naechster Schritt: TASK_247 fuer Used Asset Project Locality Audit Gate umsetzen.

### TASK_247 - Used Asset Project Locality Audit Gate
- Status: implementiert
- Stand: `scripts/tests/task_247_used_asset_project_locality_audit_gate.gd` prueft die genutzten Audio-, Background-, Comic-Bubble-, Curated-, NPC-, Portrait-, Rank-/Particle-, Setpiece-, Terrain-, UI- und Weapon-VFX-Kataloge sowie Runtime-`res://`-Referenzen aus Scenes/Scripts/Maps.
- Stand: `scripts/tests/run_task_247_asset_locality_scan.ps1` scannt Textdateien auf lokale User-/Source-Pfade und trennt Runtime-Verstoesse von Guard-Literalen, Test-Harness und Dokumentations-/Source-Notes.
- Stand: `docs/reviews/used_asset_project_locality_audit.md` dokumentiert Scope, erlaubte Ausnahmen, ResourceLoader-Gate und lokalen Lauf: 10536 Textdateien, 0 Runtime-Verstoesse, 19 Guard-Literale, 71 Dokumentations-/Source-Notes.
- Offene Punkte: Keine Runtime-Korrektur erforderlich; kuenftige Asset-Imports sollen das Gate erneut laufen lassen.
- Risiken: Dynamische Runtime-Prefixe und beschreibbare Szenario-Zielpfade sind bewusst vom Asset-Resource-Gate getrennt; neue echte Asset-Pfade muessen katalogisiert oder als konkrete `res://`-Resource pruefbar gemacht werden.
- Lokale Pruefung: `task_247_used_asset_project_locality_audit_gate.gd` und `run_task_247_asset_locality_scan.ps1` laufen gruen.
- Naechster Schritt: TASK_248 fuer Audio Visual Import and Playback Smoke umsetzen.

### TASK_248 - Audio Visual Import and Playback Smoke
- Status: implementiert
- Stand: `scripts/tests/task_248_audio_visual_import_and_playback_smoke.gd` prueft Import-Samples, `AudioEventBus`-Playback fuer UI click, Combat shot, Movement step, Impact und Explosion, Settings-Mute, Background-Instanzen, Muzzle-/Particle-/Weapon-/NPC-Visuals, Snapshot-Fire-Events und isolierte Missing-Diagnosen.
- Stand: `docs/reports/audio_visual_import_and_playback_smoke.md` dokumentiert den lokalen Lauf: `--import` ohne Fehler, TASK_248-Smoke 93/0 und TASK_160 20/0.
- Offene Punkte: Manueller Hoer-/Mixcheck bleibt sinnvoll; Performance folgt erst in TASK_249.
- Risiken: Headless prueft Hoereindruck nur indirekt; der Smoke beweist Zaehler, Routing und Resource-Ladung, aber nicht finalen Mix.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_248_audio_visual_import_and_playback_smoke.gd` und `task_160_tactical_playability_verifier.gd` laufen gruen.
- Naechster Schritt: TASK_249 fuer Post Audio Visual Performance Optimization Pass umsetzen.

### TASK_249 - Post Audio Visual Performance Optimization Pass
- Status: implementiert
- Stand: `data/performance_budget_contract.json` enthaelt einen zusaetzlichen `project_budget.audio_visual`-Abschnitt fuer Audio-Pool, aktive Stimmen, Missing-Zaehler, Background-VRAM, Muzzle-Texturen und Weapon-Fire-VFX-Count.
- Stand: `scripts/tests/task_249_post_audio_visual_performance_optimization_pass.gd` misst Audio-Spam/Polyphony/Dedupe, Background-Loadpolicy/VRAM, VFX-Burst und den bestehenden Asset-Harness; der Lauf endet mit 39/0.
- Stand: `docs/performance/audio_visual_performance_report.md` dokumentiert Before/After, Budgetentscheidung und lokale TASK_222-Ergebnisse; bestehende TASK_222-Budgets wurden nicht angehoben.
- Offene Punkte: Manueller Godot-Profiler-, Visual-Profiler- und Video-RAM-Check bleibt fuer sichtbare GPU-/Mix-/Stutter-Bewertung offen.
- Risiken: Performancewerte sind lokal maschinenabhaengig; der neue Audio-/Visual-Abschnitt ist deshalb Diagnosegrenze, keine Plattformfreigabe.
- Lokale Pruefung: `task_249_post_audio_visual_performance_optimization_pass.gd`, `task_222_performance_regression_gate_and_manual_profile_checklist.gd`, `run_task_222_performance_gate.ps1` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_250 als End-to-End Asset Audio Background Playability Smoke umsetzen.

### TASK_250 - Asset Audio Background Playability Smoke
- Status: implementiert
- Stand: `scripts/tests/task_250_asset_audio_background_playability_smoke.gd` prueft Main-Menu-/Settings-/Lobby-Pfade, UI-Audio, feste Fenster, projektlokale Backgrounds, Mission-Unit-Visuals, Weapon-VFX, Schuss-, Schritt-, Impact- und Explosion-SFX sowie FoW-Filterung fuer Fire-Events.
- Stand: `docs/manual_checks/asset_audio_background_playability_checklist.md` dokumentiert den offenen manuellen Hoer-/Sichtcheck; `docs/reports/asset_audio_background_playability_smoke.md` dokumentiert den lokalen Lauf.
- Offene Punkte: Manueller End-to-End-Hoer-/Sichtcheck bleibt offen; finaler Mix, Background-Lesbarkeit und Attachment-Sitz sind headless nur indirekt bewertbar.
- Risiken: Der End-to-End-Smoke verbindet viele Pfade und lokalisiert Fehler weniger fein als die Einzeltests; er ersetzt TASK_247/TASK_249 nicht, sondern laesst sie als Abschlussgates mitlaufen.
- Lokale Pruefung: `task_250_asset_audio_background_playability_smoke.gd` (102/0), `task_247_used_asset_project_locality_audit_gate.gd` (27/0), `task_249_post_audio_visual_performance_optimization_pass.gd` (39/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_251 fuer Nature Kit Classic Source Inventory and Subset Import starten.

### TASK_251 - Nature Kit Classic Source Inventory and Subset Import
- Status: implementiert
- Stand: `docs/assets/nature_kit_classic_inventory.md` dokumentiert Quelle, CC0-Lizenz, Source-Audit und die bewusste Entscheidung fuer ein kleines glTF-Subset statt Komplettimport.
- Stand: 25 kuratierte glTF-Modelle plus gleichnamige `.bin` liegen unter `Assets/used/terrain/nature_kit_classic/` in `cliffs`, `ground`, `rocks`, `vegetation` und `props`; `License.txt`, `Preview.png` und `Sample.png` sind projektlokal fuer Lizenz/Doku kopiert.
- Stand: `data/nature_kit_asset_catalog.json` enthaelt stabile Asset-IDs, Kategorie, Projektpfad, `.bin`-Abhaengigkeit, geplanten Verbrauchsort und Gameplay-Rollenhinweis.
- Offene Punkte: Die Assets sind noch nicht in das Terrain-Mapping eingebunden; das folgt in TASK_252 bis TASK_254.
- Risiken: Nature-Kit-Visuals bleiben reine Darstellung und duerfen Walkability, LOS, Cover oder SimulationRoot-Wahrheit nicht still veraendern.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_251_nature_kit_classic_source_inventory_and_subset_import.gd` (316/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_252 fuer Nature Cliff Hill Edge Visual Mapping umsetzen.

### TASK_252 - Nature Cliff Hill Edge Visual Mapping
- Status: implementiert
- Stand: `data/terrain_3d_asset_mapping.json` mappt die aktiven Height-Edge-Keys `cliff_straight`, `cliff_corner` und `slope` auf projektlokale Nature-Kit-Classic-Cliff-/Step-Modelle. Brown ist fuer V1 die aktive Hoehenkanten-Theme; Grey-Varianten bleiben als ladbare Kandidaten fuer Rock-/Asteroid-Folgearbeit dokumentiert.
- Stand: `TerrainMap3DView` meldet im Render-Snapshot Nature-Kit-Cliff-Modelle, Nature-Slope-Step-Modelle, Theme-Zaehler und konkrete Height-Edge-Visual-Eintraege. Diese Diagnose bleibt rein visuell und schreibt keine Gameplay-Wahrheit.
- Stand: Der TASK_252-Verifier prueft Mapping, Resource-Ladung, Runtime-Edge-Zaehler, Step-vs-Cliff-Rollen, Plateau-Innenbereiche, Missing-Mapping-Diagnose und die unveraenderte TASK_182-Bewegungssemantik.
- Offene Punkte: Manueller 2.5D-Sichtcheck mit Rotation, Zoom und Pitch bleibt offen; Headless prueft Pivot-/Lesbarkeitswirkung nur indirekt.
- Risiken: Falsche Corner-Pivots oder Theme-Wahl koennen taktische Lesbarkeit verschlechtern, auch wenn die Gameplay-Regeln korrekt bleiben.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_252_nature_cliff_hill_edge_visual_mapping.gd` (58/0), `task_185_hill_visuals_edge_lines_verifier.gd` (30/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_253 Ground-/Surface-Visuals und Editor-Palette fuer Nature-Kit-Bodenvarianten vorbereiten.

### TASK_253 - Nature Ground Surface Editor Palette Pass
- Status: implementiert
- Stand: `data/terrain_surface_visual_theme_catalog.json` definiert die aktive Nature-Classic-Dirt-Theme, Projektpfade, Surface-Default-Zuordnung und den Vertrag, dass `surface_type` die Gameplay-Wahrheit bleibt. TASK_485 erweitert diesen Vertrag spaeter um den expliziten Surface-Typ `water`.
- Stand: `TerrainMap3DView` nutzt Nature-Kit-Ground-Modelle fuer 2.5D-Top-Surfaces und meldet Surface-Visual-Eintraege, Nature-Surface-Zaehler und Theme-Verteilung im Render-Snapshot. Sand/Rock/Road behalten die bestehenden Surface-Tints fuer taktische Lesbarkeit.
- Stand: `terrain_tile_catalog.json` enthaelt die neue Palette `Nature Boden`. `TerrainTileCatalog` behandelt diese Eintraege als visuelle Surface-Varianten: `type_id` und `surface_type` koennen wechseln, waehrend `height_level`, `edge_type`, `object_type_id`, Cover, Walkable und LOS erhalten bleiben.
- Offene Punkte: Manueller Editor-/Mission-Sichtcheck bleibt offen; Headless prueft Overlays und Ressourcenzuordnung, aber nicht die finale optische Wirkung.
- Risiken: Viele Ground-Modelle koennen Node-/Draw-Budget belasten; TASK_255 misst die Nature-Kit-Integration als Abschluss-Gate.
- Lokale Pruefung: `task_253_nature_ground_surface_editor_palette_pass.gd` (67/0), `task_183_editor_hill_authoring_verifier.gd` (66/0), `task_185_hill_visuals_edge_lines_verifier.gd` (30/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_254 Baeume, Felsen und Vegetation als platzierbare Objekte mit sauberer Gameplay-Rolle integrieren.

### TASK_254 - Nature Trees Rocks Vegetation Cover Props
- Status: implementiert
- Stand: `data/terrain_object_catalog.json` dokumentiert die ersten Nature-Prop-Rollen und bindet Gameplay ausdruecklich an `TerrainTileData` statt an Mesh-Groessen. Die Objektpalette `Nature Props` enthaelt Tree-Blocker, Rock-Cover, Bush-Cover, Cactus-Cover und Deco-Logs.
- Stand: `terrain_3d_asset_mapping.json` mappt diese Props auf projektlokale Nature-Kit-Modelle. `TerrainMap3DView` meldet Nature-Prop-Modelle, Rollen-Zaehler und konkrete Visual-Eintraege im Render-Snapshot.
- Stand: `docs/dev/nature_terrain_prop_rules.md` beschreibt Gameplay Truth, Rollen, Editor-Platzierung und visuelle Anker. Deko-Logs sind explizit walkable, ohne LOS-Block und ohne Cover.
- Offene Punkte: Manueller Editor-/Mission-Sichtcheck bleibt offen; finale Groessenwirkung und taktische Lesbarkeit sind headless nur indirekt bewertet.
- Risiken: Vegetation kann trotz korrekter Daten optisch zu dominant sein; TASK_255 misst die gesamte Nature-Kit-Integration mit Playability-/Performance-Smoke.
- Lokale Pruefung: `task_254_nature_trees_rocks_vegetation_cover_props.gd` (100/0), `task_184_gameplay_hill_semantics_verifier.gd` (30/0), `task_185_hill_visuals_edge_lines_verifier.gd` (30/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_255 als Nature-Kit-Hill-Playability- und Performance-Abschluss-Gate umsetzen.

### TASK_255 - Nature Kit Hill Playability Visual Performance Smoke
- Status: implementiert
- Stand: `scripts/tests/task_255_nature_kit_hill_playability_visual_performance_smoke.gd` baut eine 32x32-Nature-Fixture mit H0/H1/H2, harten Klippen, begehbarem Slope-Einstieg, Sand/Rock/Road/Ground, Tree/Rock/Bush/Cactus/Deco-Props und Marker. Save/Load, Pathfinding, LOS und Cover pruefen dieselbe Terrain-Wahrheit wie die Mission.
- Stand: Der 2.5D-Smoke rendert dieselbe Fixture ueber `TerrainMap3DView` und prueft Nature-Ground, Cliff-/Slope-Modelle, Props, Surface-Tints, Selection, Marker, LZ, Waypoint, Area-Order, FoW, fehlende Asset-Mappings, Texturfallbacks, Renderdauer, Node-Budget und gebundene Prop-Anzahl.
- Stand: `docs/reports/nature_kit_hill_playability_visual_performance_smoke.md` und `docs/manual_checks/nature_kit_hill_playability_visual_checklist.md` dokumentieren Abschlussbefund und offene Sichtcheck-Punkte.
- Offene Punkte: Manueller Editor-/Mission-Sichtcheck bleibt offen fuer finale Kunst-/Scale-Beurteilung, Kamera-Rotation/Zoom/Pitch und laengere echte Bewegung um dichte Nature-Props.
- Risiken: Groessere Biome-Karten mit deutlich mehr Nature-Props koennen spaeter Instancing, Batching oder strengere Editor-Budgets brauchen; der kuratierte Smoke bleibt bewusst klein.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_255_nature_kit_hill_playability_visual_performance_smoke.gd` (183/0), `task_247_used_asset_project_locality_audit_gate.gd` (27/0), `task_249_post_audio_visual_performance_optimization_pass.gd` (39/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_256 fuer den gemeinsamen Automated-Playability-Coverage-Vertrag starten.

### TASK_256 - Automated Playability Coverage Contract
- Status: implementiert
- Stand: `docs/qa/playability_coverage_matrix.md` definiert die gemeinsame QA-Matrix fuer Main Menu, Settings, Singleplayer-Setup, Multiplayer-Lobby, Editor, Homebase, FOB, Character Sheet, Loadout, Mission-HUD und Debrief. Automatisierte, manuelle, blockierte und nicht anwendbare Checks sind explizit getrennt.
- Stand: `scripts/tests/playability/playability_test_harness.gd` liefert wiederverwendbare Headless-Helfer fuer Scene-Instanzierung, Button-Suche per Name/Text/Metadaten, Callback-Diagnose, sicheres Test-Pressing, feste Rechtecke, Viewport-Clipping, ScrollContainer und strukturierte Screen-Reports.
- Stand: Der TASK_256-Verifier prueft Matrix-Pflichtabschnitte, relevante Screen-/Flow-/Layout-IDs und Harness-Basisfunktionen an Main-Menu- und synthetischen Controls.
- Offene Punkte: Die Folgetasks muessen die Matrix jetzt screenweise gegen echte UI-Oberflaechen auswerten; finale Text-/Art-Clipping- und Spielgefuehlpunkte bleiben bewusst manuell markiert.
- Risiken: Die Matrix darf nicht zur Wunschliste anwachsen. Neue Reihen sollen nur echte Spielerwege, Pflichtcontrols oder begruendete manuelle Restpunkte aufnehmen.
- Lokale Pruefung: `task_256_automated_playability_coverage_contract.gd` (50/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_257 fuer Button-Reachability und Interaktion gegen die Matrix umsetzen.

### TASK_257 - Button Reachability and Interaction Verifier
- Status: implementiert
- Stand: `scripts/tests/task_257_button_reachability_and_interaction_verifier.gd` inventarisiert Pflichtcontrols in Main Menu, Settings, Multiplayer Lobby, Map Editor, Homebase, FOB, Mission-HUD und Debrief. Geprueft werden Existenz, Sichtbarkeit, Viewport-Erreichbarkeit, Vollverdeckung, Signalbindung, Fokus auf Kernbuttons und dokumentierte Disabled-/Hidden-Gruende.
- Stand: Sichere Kernklicks sind abgedeckt: Settings oeffnen/schliessen, Lobby-Start bleibt vor Ready disabled und erzeugt nach Host-Ready genau einen Mission-Start-Request.
- Stand: Der gemeinsame `PlayabilityTestHarness` kann nun neben Button-Suche auch generische Signalverbindungen, Control-Deskriptoren und eine einfache Full-Cover-Heuristik pruefen. `docs/reports/playability_button_reachability_report.md` dokumentiert abgedeckte Screens und manuelle Restpunkte.
- Offene Punkte: Echte Hover-/Fokuswirkung, lokalisierte Textlesbarkeit und tiefer FOB->Mission->Debrief-Playthrough bleiben manuelle Playability-Punkte.
- Risiken: Kontextabhaengige Buttons duerfen nicht durch starre Aktivierungsannahmen zu false positives werden; der Verifier verlangt deshalb jeweils einen dokumentierten Grund.
- Lokale Pruefung: `task_257_button_reachability_and_interaction_verifier.gd` (427/0), `task_181_drop_light_fixed_window_audit_verifier.gd` (43/0), `task_256_automated_playability_coverage_contract.gd` (50/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_258 fuer fixed-window Clipping, Scrollbars und Overflow-Pruefung umsetzen.

### TASK_258 - Fixed Window Clipping Scrollbar Playability Audit
- Status: implementiert
- Stand: `scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd` prueft Main Menu, Multiplayer Lobby, Homebase, FOB, Mission-HUD und Map Editor gegen feste Fenster, Viewport-Clipping, ScrollContainer, lange Testdaten und kritische Text-/Button-Ueberlaeufe.
- Stand: Homebase, FOB und Mission werden mit langen Roster-, Transfer-/Loadout-, Shipcard- und HUD-Inhalten aufgebaut, waehrend Top-Level-Fenster weiter dem DropLight-Fixed-Window-Vertrag folgen.
- Stand: `docs/reports/playability_layout_clipping_scrollbar_report.md` dokumentiert die automatisierte Abdeckung; `docs/manual_checks/playability_layout_remaining_visual_checklist.md` haelt die verbleibenden visuellen Full-HD-/1280x720-Pruefpunkte fest.
- Offene Punkte: Echte Pixel-Clips, Hover-/Fokuswirkung und leserische Qualitaet langer lokalisierter Texte bleiben manuelle Playability-Punkte.
- Risiken: Headless kann visuelles Clipping nur naeherungsweise pruefen; gewollte Masken brauchen erlaubte Ausnahmen.
- Lokale Pruefung: `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` (67/0), `task_181_drop_light_fixed_window_audit_verifier.gd` (43/0) und `git diff --check` laufen gruen.
- Naechster Schritt: Nach TASK_258 Charakter- und Rosterfluesse gegen lange Daten pruefen.

### TASK_259 - Character Card Roster Switching Playability
- Status: implementiert
- Stand: `scripts/tests/task_259_character_card_roster_switching_playability.gd` prueft Character-Card-Zugriff in Homebase-Roster, Homebase-Transfer-Team, FOB-Fireteams, FOB-Loadout-Slots, Mission-Selected-Fireteam und Debrief-Progression ueber bestehende Card-Signale und Screen-APIs.
- Stand: Abgedeckt sind Pool -> Team, Team -> Pool, Fireteam -> Fireteam, Clear-to-Pool, Pool -> Fireteam, blockierte Duplikate/ungueltige Umstellungen, Character-Sheet-Synchronitaet, Save/Load und Mission-Progression ohne Unit-Verlust.
- Stand: `docs/reports/playability_character_card_roster_switching_report.md` dokumentiert Screens, State-Integrity-Regeln, automatische Findings und manuelle Restpunkte.
- Offene Punkte: Echte Drag-and-drop-Haptik, Hover-State und Portrait-by-Portrait-Sichtkontrolle bleiben manuelle Playability-Punkte.
- Risiken: Drag-and-drop ist headless schwerer zu pruefen und wird deshalb von direkten Signal-/API-Pfaden getrennt.
- Lokale Pruefung: `task_259_character_card_roster_switching_playability.gd` (51/0), `task_241_character_gameplay_playability_smoke.gd` (34/0) und `git diff --check` laufen gruen.
- Naechster Schritt: Nach TASK_259 Loadout und Gewicht als durchgehenden Playability-Pfad pruefen.

### TASK_260 - Loadout Selection Decorative Weapons Weight Playability
- Status: implementiert
- Stand: `scripts/tests/task_260_loadout_selection_decorative_weapons_weight_playability.gd` prueft spielbare Loadout-IDs gegen Visual-only-IDs, blockierte Dekor-Selections, `none`, Gewichte, FOB-Selector/Preview, Character-Overlay, Combat-Active-Weapon, Simulation-Snapshot und 3D-Weapon-Visuals.
- Stand: `WeaponData` fuehrt `none` als explizites leeres Loadout ohne Schaden, Preview, Visual-Loadout und Gewicht; `LoadoutModifierResolver` serialisiert `loadout_weight` und bleibt frei von Preview-/Socket-/Modelldaten.
- Stand: `SimulationRoot` faellt bei leerem Active-Weapon-Rueckgabewert nicht mehr auf Rifle zurueck; `TerrainMap3DView` behandelt zwei `none`-Slots als absichtlich waffenlos und haengt kein Default-Blaster-Visual an.
- Stand: `docs/reports/playability_loadout_weight_report.md` und `docs/dev/loadout_playability_rules.md` dokumentieren Befund, Regeln und manuelle Restpunkte.
- Offene Punkte: Live-Dropdown-Haptik und Balancing-Zahlen bleiben manuelle/fachliche Folgepunkte, sobald echte Unlock-/Inventarlisten existieren.
- Risiken: Visual-only-IDs duerfen auch in Folgearbeiten nicht zu Gameplay-IDs werden, ausser sie werden bewusst in `WeaponData` aufgenommen.
- Lokale Pruefung: `task_260_loadout_selection_decorative_weapons_weight_playability.gd` (72/0), `task_176_fob_loadout_weapon_preview_selector_verifier.gd` (30/0), `task_190_weapon_visual_loadout_expansion_and_scale.gd` (48/0), `test_weapon_data.gd` (24/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_261 prueft Screenwechsel und Rueckwege auf State-Loss.

### TASK_261 - Cross Screen State Loss Playability Smoke
- Status: implementiert
- Stand: `scripts/tests/task_261_cross_screen_state_loss_playability_smoke.gd` fuehrt Main Menu/Settings, Homebase, FOB, Mission, Debrief, Editor und Multiplayer-Lobby nacheinander mit stabilen Preset-Unit-IDs aus.
- Stand: Geprueft werden Routen, Settings-Persistenz, Homebase-Transfer, FOB-Fireteam-/Loadout-Uebergabe, Mission-Registry, Mission-Loadout-Gewicht, Debrief-Identitaet, Rueckkehr nach Homebase, Editor-Save/Load und Multiplayer Host/Client/Disconnect.
- Stand: Der Smoke prueft zusaetzlich, dass Settings-, Editor- und Lobby-Wege keinen unerwarteten `SimulationRoot` erzeugen, idle UI-Audio nicht duplizieren und den selektierten Unit-State nicht mutieren.
- Stand: `docs/reports/playability_cross_screen_state_loss_report.md` dokumentiert Hauptflow, Editorflow, Multiplayer-Vorbereitung, State-Invarianten und offene manuelle Punkte.
- Offene Punkte: Echte Drag-and-drop-Haptik, visuelle Screen-Transitionen und Zwei-Client-Netzwerkverhalten bleiben manuelle bzw. eigene Smoke-Pfade.
- Risiken: Der lange Smoke lokalisiert Fehler grober als die Einzelverifier; er soll deshalb als Gate-Ergaenzung laufen, nicht als Ersatz.
- Lokale Pruefung: `task_261_cross_screen_state_loss_playability_smoke.gd` (67/0), `task_241_character_gameplay_playability_smoke.gd` (34/0), `task_250_asset_audio_background_playability_smoke.gd` (102/0) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_262 fasst die Playability-Smokes in ein wiederholbares Regression-Gate zusammen.

### TASK_262 - Playability Regression Gate and Manual Open Items
- Status: implementiert
- Stand: `scripts/tests/run_task_262_playability_gate.ps1` fuehrt TASK_256 bis TASK_261 in Reihenfolge aus und laesst anschliessend `git diff --check` laufen. Der lokale Gate-Lauf war mit allen sechs Tasks gruen.
- Stand: `scripts/tests/task_262_playability_regression_gate_and_manual_open_items.gd` prueft den Gate-Vertrag, die Reihenfolge, Report-Referenzen, Matrix-Abdeckung und die kurze manuelle Restcheckliste.
- Stand: `docs/reports/playability_regression_gate_report.md` trennt Hard Failures, Warnings, Manual Items, Coverage Matrix und Standardbefehle. `docs/manual_checks/playability_manual_open_items.md` haelt nur subjektive/manuelle Restpunkte fest.
- Stand: `docs/qa/playability_coverage_matrix.md` ist um die Gate Coverage Summary erweitert und markiert die durch TASK_259 bis TASK_261 automatisierten Character-/Debrief-/Meta-Flows.
- Offene Punkte: Das Gate ersetzt keine sichtbare Zwei-Client- und Drag-and-drop-Haptikpruefung; diese Punkte bleiben kurz in der manuellen Liste.
- Risiken: Der Gate-Lauf ist bewusst grob und soll Fehler priorisieren. Einzelverifier bleiben fuer Diagnose und Reparatur massgeblich.
- Lokale Pruefung: `task_262_playability_regression_gate_and_manual_open_items.gd` (60/0), `run_task_262_playability_gate.ps1` (TASK_256 50/0, TASK_257 427/0, TASK_258 67/0, TASK_259 51/0, TASK_260 72/0, TASK_261 67/0, `git diff --check`) und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_263 startet den Kontext-Hilfe-Popup-UX-Vertrag.

### TASK_263 - Contextual Help Popup UX Contract
- Status: implementiert
- Stand: `docs/dev/contextual_help_popup_ux_contract.md` definiert den gemeinsamen UX-Vertrag fuer Hilfe-Popups mit `none`, `compact` und `detail`, Hover-/Fokus-Timing, Touch-/Controller-Fallback, Maximalbreiten, Viewport-Clamp, Settings-Modi `off`/`compact`/`expanded` und globalem Hilfe-Button `shell.global_help_button`.
- Stand: `data/contextual_help_catalog.json` legt das Katalogschema mit stabilen `help_id`s, Pflichtfeldern, erlaubten Statuswerten, Pflichtbereichen und Laengenregeln an. Die ersten Draft-/Planned-Eintraege decken Main Menu, Settings, Homebase, FOB, Loadout, Character Sheet, Mission HUD, Map Editor, Multiplayer Lobby und Debrief ab.
- Stand: `docs/qa/playability_coverage_matrix.md` enthaelt eine eigene Contextual-Help-Coverage-Sektion fuer Pflichtscreens, Katalogschema, Timing, Layout und globalen Help-Button. `scripts/tests/task_263_contextual_help_popup_ux_contract.gd` prueft Dokumentabschnitte, Katalogschema, Pflichtbereiche, stabile IDs und Textlaengen.
- Offene Punkte: TASK_264 muss daraus die Runtime-Komponente mit Settings-Anbindung und globalem Help-Button bauen; TASK_265/TASK_266 fuellen und verdrahten konkrete Screen-Inhalte.
- Risiken: Hilfe bleibt bewusst UI-only. Folgearbeiten duerfen keine Gameplay-Werte im Hilfesystem nachrechnen oder Help-Popups als zweite Command-/State-Schicht nutzen.
- Lokale Pruefung: `task_263_contextual_help_popup_ux_contract.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_264 fuer Popup-Komponente, Settings-Toggle und globale Help-Taste umsetzen.

### TASK_264 - Contextual Help Popup Component Settings Toggle
- Status: implementiert
- Stand: `scripts/ui/contextual_help_service.gd` laedt `data/contextual_help_catalog.json`, normalisiert die Modi `off`/`compact`/`expanded`, trennt Kurz- und Detailhilfe, setzt die TASK_263-Timing-Regeln um und diagnostiziert fehlende IDs, leere Texte, deaktivierte Requests und registrierte Controls.
- Stand: `scripts/ui/contextual_help_popup.gd` ist eine wiederverwendbare Panel-Komponente mit Titel, kompakten Wrap-Zeilen, optionalem Detailbereich, Maximalbreiten, Maximalhoehe und Viewport-Clamp. Die Komponente verschiebt keine festen Fenster und bleibt reine Overlay-Darstellung.
- Stand: `GameSettingsContract`, `SettingsScreen` und `MainMenu` unterstuetzen `contextual_help_mode`. Das Main Menu bereitet den kleinen globalen Help-Button `shell.global_help_button`, eine Help-Popup-Instanz, Help-IDs fuer App-Shell-/Settings-Ziele und einfache Hover-/Fokus-Verzoegerung vor.
- Offene Punkte: TASK_265/TASK_266 muessen die konkreten Character-, Loadout-, Mission-, Editor- und Settings-Hilfeinhalte verbreitern und weitere Controls registrieren.
- Risiken: Die Runtime-Schicht ist absichtlich UI-only. Folgearbeiten duerfen keine SimulationRoot-Commands, Loadout-Werte oder Character-State aus Hilfe-Popups ableiten.
- Lokale Pruefung: `task_264_contextual_help_popup_component_settings_toggle.gd`, `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_265 fuer Character Sheet und Loadout Help Content Pass umsetzen.

### TASK_265 - Character Sheet Loadout Help Content Pass
- Status: implementiert
- Stand: `data/contextual_help_catalog.json` enthaelt jetzt Hilfe-Copy fuer Character-Sheet-Identitaet, Rolle, Fireteam, Badges, Traits, Status/Recovery, Morale/Frustration, Teamfit, Progress, Kernwerte, Kommunikation, Plattform-Skills, abgeleitete Werte, Verhalten sowie Loadout-Gewicht, Armor, Waffenoptionen, No Weapon, Visual-only, Preview und Disabled-Gruende.
- Stand: `CharacterSheetFormatter` liefert `help_id`s pro relevanter Zeile; `CharacterSheetView` setzt diese IDs auf Header, Labels, Balken, Portrait und Badges. `FOBScreen` markiert Loadout-Panel, Member Rows, Armor Select, Weapon Slots, Previews, Empty Slot, Weight und Clear-Fokus mit stabilen IDs.
- Stand: `docs/content/character_sheet_loadout_help_copy.md` dokumentiert die Copy- und Source-Regeln: Character-State aus `MetaUnitProfile`, Badges aus `NPCRankBadgeResolver`, Waffen aus `WeaponData`, Gewicht aus `LoadoutModifierResolver`.
- Offene Punkte: TASK_266 muss Mission-HUD, Befehle, Editor, Multiplayer und Settings mit Help-Copy und IDs ausstatten.
- Risiken: LMG ist bewusst als `planned` markiert, solange `WeaponData` keinen echten Gameplay-Eintrag hat. Hilfe darf weiterhin keine finalen Balanceformeln behaupten.
- Lokale Pruefung: `task_265_character_sheet_loadout_help_content_pass.gd`, `task_259_character_card_roster_switching_playability.gd`, `task_260_loadout_selection_decorative_weapons_weight_playability.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_266 fuer Command-, Mission-, Editor-, Multiplayer- und Settings-Hilfe umsetzen.

### TASK_266 - Command Mission Editor Settings Help Content Pass
- Status: implementiert
- Stand: `data/contextual_help_catalog.json` enthaelt jetzt gruppierte Help-Copy fuer Mission Commands, Area Orders, Fireteam-Status, Settings, FoW-Modi, Multiplayer Host/Join/Ready/Map Transfer und Editor-Werkzeuge. `editor.back` und `mission.command.roe_fire_rules` bleiben bewusst als `todo` fuer Folgearbeiten markiert.
- Stand: Main Menu Settings, Multiplayer Lobby, Map Editor und Mission Sandbox setzen stabile `help_id`-Metadaten auf sichtbare Controls, dynamisch erzeugte Mission Panels und relevante Popup-/Menu-Knoten, ohne Gameplay-State aus der UI abzuleiten.
- Stand: `docs/content/command_mission_editor_settings_help_copy.md`, die Playability-Coverage-Matrix und `task_266_command_mission_editor_settings_help_content_pass.gd` dokumentieren und pruefen die neue Abdeckung.
- Offene Punkte: Ein sichtbarer Editor-Back-Flow und echte ROE-/Fire-Rule-Controls werden erst in den naechsten passenden Tasks verdrahtet.
- Risiken: Hilfe bleibt UI-only. Folgearbeiten duerfen keine Befehle ausloesen, Mission-State veraendern oder taktische UI bei Planung verdecken.
- Lokale Pruefung: `task_266_command_mission_editor_settings_help_content_pass.gd`, `task_257_button_reachability_and_interaction_verifier.gd`, `task_223_fog_of_war_modes_contract_and_settings.gd`, `task_263_contextual_help_popup_ux_contract.gd`, `task_264_contextual_help_popup_component_settings_toggle.gd`, `task_265_character_sheet_loadout_help_content_pass.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_267 fuer Help-Coverage, Layout-Clamping, Timing und Settings-Modi als zusammenhaengendes Gate umsetzen.

### TASK_267 - Contextual Help Coverage Layout Verifier
- Status: implementiert
- Stand: `scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd` prueft den Help-Katalog auf Pflichtfelder, stabile IDs, Textlaengen, wrappbare Zeilen, erlaubte Statuswerte und dokumentierte `todo`-Ausnahmen.
- Stand: Der Verifier rendert jede Katalog-ID in kompaktem und detailfaehigem Popup-Layout gegen mehrere Zielpositionen, prueft Viewport-Clamp, Maximalbreite, Maximalhoehe, Ziel-Control-Ueberdeckung, off/compact/expanded, Long-hover, Pin und globalen Help-Button.
- Stand: Main Menu, Multiplayer Lobby, Map Editor, Homebase, FOB, Debrief und Mission HUD werden headless instanziert und auf sichtbare `help_id`-Metadaten gegen den Katalog gescannt. Alte TASK_263-Kompatibilitaets-IDs wurden als reine UI-Metadaten nachgezogen.
- Stand: `docs/reports/contextual_help_coverage_layout_report.md` und `docs/qa/playability_coverage_matrix.md` dokumentieren Gate-Abdeckung, ungenutzte Fixture-IDs, manuelle Restpunkte und die Ausnahmen `editor.back` sowie `mission.command.roe_fire_rules`.
- Offene Punkte: Ready-IDs fuer konkrete Waffenoptionszeilen, FoW-Untermodi, Plattform-Skills und `mission.command.hold` sind im Katalog vorhanden, aber nicht in jedem Fixture sichtbar; der Verifier meldet sie als Warnung. `editor.back` und `mission.command.roe_fire_rules` bleiben echte Folgepunkte.
- Risiken: Der Gate prueft harte Layout-/Timingregeln headless; finales Copy-Reading und subjektive Lesbarkeit bleiben manuell.
- Lokale Pruefung: `task_267_contextual_help_coverage_layout_verifier.gd`, `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_268 als Post-Help-Playability-Smoke fuer Hilfe aus/kompakt/erweitert umsetzen.

### TASK_268 - Post Help Popup Playability Regression Smoke
- Status: implementiert
- Stand: `scripts/tests/task_268_post_help_popup_playability_regression_smoke.gd` prueft Hilfe `off`, `compact` und `expanded` gegen Main Menu/Settings, Multiplayer Lobby, Map Editor, Homebase, FOB, Mission HUD und Debrief.
- Stand: Der Smoke verknuepft TASK_262 und TASK_267 als Gates, prueft globale Hilfe, Popup-Viewport-Lage, input-transparente Popups, Pflichtbutton-Erreichbarkeit und dass Homebase-/FOB-/Mission-Fixed-Windows durch sichtbare Hilfe nicht verschoben werden.
- Stand: `ContextualHelpPopup` setzt jetzt auch seine inneren Margin-/VBox-/Label-Kinder auf `MOUSE_FILTER_IGNORE`, damit Hilfe nicht nur optisch overlayt, sondern auch in Coverage-/Input-Heuristiken keine Controls blockiert.
- Stand: `docs/reports/post_help_popup_playability_regression_report.md`, `docs/manual_checks/post_help_popup_manual_readability_checklist.md`, `scripts/tests/run_task_268_post_help_playability_gate.ps1` und die Matrix-Zeile dokumentieren das Post-Help-Gate.
- Offene Punkte: Finales Copy-Reading und subjektive Lesbarkeit bleiben manuell.
- Risiken: Der Smoke ist absichtlich ein Integrationscheck ueber die Help-Modi; die tiefen Button-/Layout-/Coverage-Checks bleiben bei TASK_262 und TASK_267.
- Lokale Pruefung: `task_268_post_help_popup_playability_regression_smoke.gd`, `task_262_playability_regression_gate_and_manual_open_items.gd`, `task_267_contextual_help_coverage_layout_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Hilfe als Standardanforderung fuer neue UI-, Character-, Loadout-, Mission- und Editor-Controls behandeln.

### TASK_269 - Tactical Doctrine Source Review Game Abstraction
- Status: implementiert
- Stand: `docs/research/tactical_doctrine_source_matrix.md` vergleicht US-, deutsche, franzoesische und Arma-/Game-Quellen als reine Game-Design-Inspiration. Die Matrix dokumentiert pro Quelle Ebene, relevante Konzepte, Sternenbuergerchen-Ableitung und klare Nicht-uebernehmen-Hinweise.
- Stand: `docs/dev/tactical_command_doctrine_game_abstraction.md` definiert den sicheren Spielvertrag fuer Commander-Intent, Fireteam-Leader-Ausfuehrung, Unit-Aktionen, taktische Regeln, Ausbrueche und #16/#17/#18-/Map-/Bubble-/Help-Feedback.
- Stand: Der Verifier `scripts/tests/task_269_tactical_doctrine_source_review_game_abstraction.gd` prueft Pflichtabschnitte, Quellenabdeckung, neutralisierte Begriffe, Sicherheitsnotiz, Folge-Task-Referenzen und Task-Status.
- Offene Punkte: Keine im TASK_269-Scope; die Umsetzung der Datenvertraege folgt bewusst erst ab TASK_270.
- Risiken: Folge-Tasks muessen die Dokumente als Spielabstraktion behandeln. Keine realen Schritt-fuer-Schritt-Taktiken, keine nationalen Ingame-Schubladen und keine UI-seitige Gameplay-Wahrheit.
- Lokale Pruefung: `task_269_tactical_doctrine_source_review_game_abstraction.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_270 baut darauf den Commander-zu-FTL-Delegationsvertrag.

### TASK_270 - Commander to Fireteam Leader Delegation Contract
- Status: implementiert
- Stand: `docs/dev/commander_fireteam_delegation_contract.md` definiert die Kette `CommanderIntent -> FireteamExecutionPlan -> UnitAction -> UnitCommand/SimulationRoot` samt Authority-Grenzen, Statusantworten, Snapshot-Feldern und UnitAction-Dictionary-Regeln.
- Stand: `scripts/command/commander_intent.gd` kapselt fireteam-scoped Commander-Absicht mit `command_id`, Verb, Ziel, Tempo, Fire Rule, Contact Response, Risiko und Legacy-Mapping fuer Move/Defend/Take/Engage/Flank. Direkte `unit_id`-Payloads werden nicht als Intent-Wahrheit serialisiert.
- Stand: `scripts/tactical/fireteam_execution_plan.gd` erzeugt aus CommanderIntent plus FTL-Skill einen plan-scoped FireteamExecutionPlan mit `plan_id`, `status_response`, Movement Style, Security, Cover Priority, Route Bias, Breakout-Klassen und UnitAction-Dictionaries. Die Klasse baut nur Runtime-Command-Dictionaries und enqueued nichts selbst.
- Stand: `scripts/tests/task_270_commander_to_fireteam_leader_delegation_contract.gd` prueft Dokument, Legacy-Command-Mapping, FTL-Skill-Einfluss, UnitAction-Planbindung und dass die neuen Vertragsklassen keine UI-/SceneTree-/SimulationRoot-Mutation ausfuehren.
- Offene Punkte: Keine im TASK_270-Scope; konkrete UI-Regeln und Fire-Rule-Controls folgen in TASK_271.
- Risiken: Folge-Tasks muessen die neuen Klassen als Vertrag nutzen, ohne daraus eine zweite SimulationRoot oder eine direkte UI-Unit-Steuerung zu machen.
- Lokale Pruefung: `task_270_commander_to_fireteam_leader_delegation_contract.gd`, `task_191_command_chain_selection_area_feedback_pass.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_271 definiert konkrete taktische Command Modes und Fire Rules.

### TASK_271 - Tactical Command Modes ROE Fire Rules
- Status: implementiert
- Stand: `scripts/tactical/tactical_command_rules.gd` definiert Tempo, Feuerregel, Kontaktverhalten, Deckungsprioritaet und Security als kleine Commander-Regelstruktur mit Katalog, Defaults, Help-IDs, Feedback-Snapshot und Konfliktnormalisierung. `CommanderIntent` transportiert die Regeln; `FireteamExecutionPlan` liest sie als Planvorgabe, ohne UI-Unit-Mutation. Der Vertrag steht in `docs/dev/tactical_command_rules_contract.md`.
- Offene Punkte: Keine im TASK_271-Scope; konkrete Mehr-Fireteam-Koordination folgt in TASK_272.
- Risiken: Folge-Tasks duerfen die Regeln nur als Planvorgaben verwenden und nicht als zweite Gameplay-Wahrheit neben SimulationRoot.
- Lokale Pruefung: `task_271_tactical_command_modes_roe_fire_rules.gd`, `task_109_verifier.gd`, `task_111_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_272 koordiniert mehrere Fireteams auf gemeinsame Area-Plaene.

### TASK_272 - Multi Fireteam Coordinated Area Plan
- Status: implementiert
- Stand: `scripts/tactical/multi_fireteam_plan_resolver.gd` erzeugt aus einem gemeinsamen `CommanderIntent` und Fireteam-Kontexten nachvollziehbare Rollenplaene mit Lead, Support, Security, Reserve und Recon. Der Vertrag steht in `docs/dev/multi_fireteam_plan_contract.md`.
- Stand: `CommanderIntent` kann koordinierte Fireteam-IDs transportieren; `FireteamExecutionPlan` spiegelt `coordination_plan_id` und `coordination_role`. Der Mission-Controller erzeugt fuer gemeinsame Multi-Fireteam-Area-Orders einen Pre-GO-Plan, zeigt #17/#18-Snapshots und reicht kompakte Rollenlabels an die Primary Map weiter.
- Offene Punkte: Keine im TASK_272-Scope; feinere Skill-Progression und Kommunikationsereignisse folgen in TASK_273/TASK_274.
- Risiken: Der Plan bleibt bewusst Vorschau/Delegation und darf nicht als neue Gameplay-Wahrheit neben SimulationRoot genutzt werden.
- Lokale Pruefung: `task_272_multi_fireteam_coordinated_area_plan.gd`, `task_188_fireteam_advance_styles_map_readability.gd`, `task_191_command_chain_selection_area_feedback_pass.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_273 bindet FTL-Skill und Teamfortschritt sichtbar in die Planqualitaet ein.

### TASK_273 - Fireteam Leader Skill Tactical Progression
- Status: implementiert
- Stand: `docs/dev/fireteam_leader_tactical_progression.md` definiert den FTL-Skillvertrag mit Leadership, Tactical Sense, Communication, Discipline, Initiative und Team Cohesion sowie fair begrenzten Effekten auf Planqualitaet, Kommunikation, Ausbruchsentscheidungen, Contact-Reports, Spacing und Tempo.
- Stand: `FireteamBehaviorResolver`, `MultiFireteamPlanResolver` und `FireteamExecutionPlan` nutzen den FTL-Snapshot deterministisch fuer Ausfuehrungsprofil, Rollen-Vorschlaege und Skill-Faktoren, ohne UI- oder Map-Code zur Gameplay-Wahrheit zu machen.
- Stand: `MissionProgressionResolver` schreibt langsame, gedeckelte FTL-Fortschritte nach Missionen in `progression.ftl_tactical`, erzeugt Debrief-Ereignisse und `CharacterSheetFormatter` zeigt die kompakte Zeile `FTL Impact` mit Help-ID `character_sheet.ftl_tactical_impact`.
- Stand: `MultiplayerSnapshotContract` normalisiert optionale `fireteam_tactical`-Eintraege als oeffentliche Kennzahlen und entfernt private Profil-, Beziehungs- und History-Daten.
- Offene Punkte: Sichtbare Kommunikationsereignisse fuer #17/#18, Bubbles und Map bleiben TASK_274.
- Risiken: Fortschritt ist bewusst klein und capped; Folgearbeiten duerfen aus FTL-Skill keine Trefferbonus- oder Super-KI-Schiene machen.
- Lokale Pruefung: `task_273_fireteam_leader_skill_tactical_progression.gd`, `task_237_mission_progression_xp_morale_frustration.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_274 baut die sichtbare taktische Kommunikationsschicht auf dem oeffentlichen FTL-Snapshot.

### TASK_274 - Tactical Communication Feedback Layer
- Status: implementiert
- Stand: `scripts/tactical/tactical_communication_event.gd` definiert visual-only Kommunikationsereignisse fuer Order-Ack, Rollen, Phasen, Kontakt, Ausbrueche, Blockaden, Objectives und Air-Asset-Bedrohung mit stabiler Event-ID, Fireteam-/Unit-ID, Prioritaet, Dauer und Kanaelen.
- Stand: `scripts/tactical/tactical_communication_resolver.gd` priorisiert kritische Meldungen, setzt Cooldowns gegen Bubble-/Status-Spam und nutzt `data/tactical_communication_copy.json`, damit FTL-Communication die Praezision der Texte beeinflusst, ohne neue Gameplay-Wahrheit einzufuehren.
- Stand: `MissionTacticalSandboxController` speist Multi-Fireteam-Planereignisse in #17/#18, FTL-Bubbles und die Primary-Map. `TerrainMap3DView` rendert kompakte Map-Marker und stellt reine Diagnose-Snapshots fuer die Ereignisse bereit.
- Offene Punkte: Audio bleibt als optionaler Kanal markiert; die eigentliche Air-Asset-Exception- und Recovery-Mechanik folgt in TASK_277/TASK_278.
- Risiken: Die Kommunikationsschicht ist bewusst Anzeige/Snapshot. Folgearbeiten duerfen daraus keine zweite Runtime-Wahrheit neben SimulationRoot machen.
- Lokale Pruefung: `task_274_tactical_communication_feedback_layer.gd`, `task_214_comic_bubble_feedback_playability_smoke.gd`, `task_191_command_chain_selection_area_feedback_pass.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_275 ordnet die Command-Buttons an die neuen Befehlsebenen an.

### TASK_275 - Command Button Hierarchy Arrangement Overhaul
- Status: implementiert
- Stand: `scripts/ui/mission_command_hierarchy_contract.gd` definiert eine visual-only Buttonhierarchie fuer Ziel, Regel, Plan, Air/LZ und Ausbruch inklusive #16/#17/#18-Rollen, Kontextgates und Disabled-Gruenden.
- Stand: `MissionTacticalSandboxController` haelt die alten Buttonpfade und Signalwege, ordnet #16 als kurze Goal-Matrix, versieht Pflichtbuttons mit Hierarchie-/Help-Metadaten und stellt `get_command_hierarchy_snapshot()` bereit.
- Stand: `docs/dev/mission_command_button_hierarchy.md` dokumentiert Vorher/Nachher-Matrix, Disabled-Reasons, Help-IDs und offene UX-Fragen.
- Offene Punkte: Echte Ausbruch- und Air-Exception-Aktionen bleiben bewusst fuer TASK_276 bis TASK_278 reserviert.
- Risiken: Die neue Hierarchie darf weiter nur UI-/Snapshot-Schicht bleiben; Folgearbeiten duerfen daraus keine zweite Gameplay-Wahrheit machen.
- Lokale Pruefung: `task_275_command_button_hierarchy_arrangement_overhaul.gd`, `task_257_button_reachability_and_interaction_verifier.gd`, `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_276 baut das taktische Ausbruchssystem auf den sichtbaren Rueckfrage-/Override-Slots auf.

### TASK_276 - Tactical Breakout and Exception Behavior
- Status: implementiert
- Stand: `data/tactical_breakout_catalog.json` definiert Ausbruchsklassen und Kerntrigger fuer Kontakt, Suppression, Medic/Casualty, Blockade, Reichweite, Ammo/Weapon, Leader down, Air-Asset und Regelkonflikte.
- Stand: `scripts/tactical/tactical_breakout_resolver.gd` normalisiert Trigger, erzwingt `FireteamExecutionPlan.allowed_breakout_classes`, bewertet FTL-Skill, erzeugt Event-IDs, Spieleroptionen, Feedbackstatus und Return-to-plan-Snapshots.
- Stand: `MissionTacticalSandboxController` kann Breakouts aufzeichnen, in TacticalCommunicationEvents fuer #17/#18/Map/Bubbles uebersetzen und Suppression-Ausbrueche beim Stabilisieren wieder als `returned_to_plan` markieren.
- Offene Punkte: Echte Air-Asset-Schadenslogik und Meta-Folgen bleiben TASK_277/TASK_278.
- Risiken: Der Resolver ist bewusst Vertrags-/Feedbackschicht; Folgearbeiten muessen Runtime-Mutationen weiter ueber bestehende Controller und SimulationRoot halten.
- Lokale Pruefung: `task_276_tactical_breakout_and_exception_behavior.gd`, `task_103_verifier.gd`, `task_189_medic_adjacent_tile_healing_rule.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_277 definiert Dropship-/Frachter-Bedrohung und Air-Asset-Schadensstatus.

### TASK_277 - Dropship Freighter Anti Armor Threat Contract
- Status: implementiert
- Stand: `scripts/mission/air_asset_status.gd` definiert Dropship-/Frachter-Zustaende von `intact` ueber `threatened`/`locked` und `hit`/`damaged` bis `destroyed`/`crashed` sowie `recovering`/`unavailable`; Snapshots deklarieren `runtime_authority = "SimulationRoot"` und `ui_sets_gameplay_truth = false`.
- Stand: `scripts/combat/air_asset_threat_resolver.gd` erlaubt nur definierte Anti-Armor-Waffen (`rocket_launcher`, `rail_gun`), respektiert Range/LOS/FoW/Hoehe, erzwingt eine Warnphase vor Hit/Destroy und berechnet LZ-/Enemy-AT-Risiko.
- Stand: `SimulationRoot` verarbeitet `air_asset_status_update`-Effects und stellt `get_air_asset_status_snapshot()` bereit; der Mission Controller spiegelt Status, VFX/SFX-Payload, TacticalCommunicationEvent und Breakout in seinen Snapshots.
- Offene Punkte: Dauerhafte Reparatur-/Ersatz- und Debrief-Folgen folgen in TASK_278.
- Risiken: Balancing der Risikowerte muss im Playability-Smoke gegen Frust geprueft werden; der Contract verhindert Sofortabschuesse ohne Warnung.
- Lokale Pruefung: `task_277_dropship_freighter_anti_armor_threat_contract.gd`, `bugfix_dropship_mission_flow_verifier.gd`, `task_160_tactical_playability_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_278 baut Meta-Folgen, Recovery und Softlock-Schutz auf dem AirAssetStatus auf.

### TASK_278 - Air Asset Loss Recovery Meta Loop
- Status: implementiert
- Stand: `scripts/meta/air_asset_recovery_state.gd` uebersetzt Mission-`AirAssetStatus` in Meta-Zustaende `craft_available`, `damaged_repairing` und `destroyed_replacement_pending` inklusive Pilotstatus, ETA, Softlock-Guard und Snapshot-Persistenz.
- Stand: `MetaLayerFlow` uebernimmt Air-Asset-Status ins Missionsergebnis, baut `air_asset_recovery`, haelt `get_air_asset_recovery_snapshot()`/`load_air_asset_recovery_snapshot()` bereit und laesst Reparatur/Ersatz ueber bestehenden Transport-Timer oder `advance_air_asset_recovery_time()` laufen.
- Stand: Debrief, Homebase-Flightdeck und FOB-Flightdeck zeigen Verlust/Reparatur/Ersatz-ETA; Boarding, Send und Missionsstart sind fuer nicht verfuegbare Air Assets blockiert.
- Offene Punkte: End-to-End-Balancing mit Enemy-AT/LZ-Sicherung folgt in TASK_279.
- Risiken: Die Zeitwerte sind Contract-/Balance-Defaults; finale Schwierigkeit gehoert in den Playability-Smoke.
- Lokale Pruefung: `task_278_air_asset_loss_recovery_meta_loop.gd`, `task_096_recovery_verifier.gd`, `task_261_cross_screen_state_loss_playability_smoke.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_279 prueft LZ-Sicherung, Air-Asset-Bedrohung, Verlust, Kommunikation und Meta-Folgen im zusammengesetzten Mission-Smoke.

### TASK_279 - LZ Security Air Asset Tactical Playability Smoke
- Status: implementiert
- Stand: `scripts/tests/task_279_lz_security_air_asset_tactical_playability_smoke.gd` prueft den zusammengesetzten LZ-/Air-Asset-Smoke mit zwei Fireteams, koordiniertem Take-Area-Plan, sicherem LZ-Warnfall, riskantem Enemy-AT-Warnfall, Air-Asset-Verlust und Meta-Roundtrip.
- Stand: `maps/test_lz_air_asset_threat_fixture.json` beschreibt eine kleine 32x32-Fixture mit `lz_secure`, `lz_risky`, `enemy_at_team` und `objective_point`; `docs/reports/lz_security_air_asset_playability_smoke.md` dokumentiert Success-, Threat-, Loss- und Meta-Pfad.
- Stand: Der Smoke prueft Role-/Breakout-/Air-Asset-Kommunikation, Explosion-VFX/SFX, `SimulationRoot`-Status, `MetaLayerFlow`-Recovery, Debrief/Homebase/FOB-Blockaden, `softlock_guard` und `ui_sets_gameplay_truth = false`.
- Offene Punkte: Manueller Mission-Sichtcheck bleibt sinnvoll, weil der Headless-Smoke Feedback- und Statusdaten prueft, aber nicht die finale visuelle Fairness beurteilt.
- Risiken: Der Smoke ist bewusst breit und kann Folgefehler nur auf die betroffene Integrationszone eingrenzen; Balancewerte fuer AT-Risiko bleiben weiter keine finalen Werte.
- Lokale Pruefung: `task_279_lz_security_air_asset_tactical_playability_smoke.gd`, `task_160_tactical_playability_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_280 macht Taktikprofile, Heavy-/AT-Rollen und Air-Asset-Risiko im Editor/Szenario authorbar.

### TASK_280 - Tactical Profile Editor Scenario Authoring
- Status: implementiert
- Stand: `MissionScenarioData` speichert validierte taktische Authoring-Daten inklusive Enemy-Taktikprofil, Security/Facing, Heavy-/AT-Rolle, optionaler LZ-Threat-Zone, Air-Asset-Risk-Profile und Kommunikationsintensitaet mit sicheren Defaults fuer alte Szenarien.
- Stand: `MapEditor` bietet kompakte Auswahlfelder, Help-Metadaten und Warnungen; `data/tactical_profile_catalog.json` dokumentiert Profile, Rollen, Risiko-Stufen und sichere Defaults.
- Stand: `MissionTestSetup` reicht die validierten Daten an Runtime-Controller weiter; Editor-UI bleibt keine Gameplay-Wahrheit.
- Offene Punkte: Manuelle Editor-UX bleibt als Nachpolitur sinnvoll, weil der Verifier Roundtrip/Fallback/Glue prueft, nicht Lesetempo im echten Editor.
- Risiken: Profilkombinationen koennen spaeter Balance-Tuning brauchen; Validierung verhindert zunaechst nur unvollstaendige oder unfaire Grundkonfigurationen.
- Lokale Pruefung: `task_280_tactical_profile_editor_scenario_authoring.gd`, `task_156_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_281 sichert Multiplayer-Authority und Snapshot-Vertrag fuer taktische Planung ab.

### TASK_281 - Tactical Command Multiplayer Authority Snapshot
- Status: implementiert
- Stand: `MultiplayerCommandContract` whitelisted CommanderIntent, Breakout-Response, AirAsset-Commands und Host-only Role-Override; taktische State-Mutationsfelder wie `air_asset_status`, `breakout_state`, `communication_events`, `vfx_events` und `sfx_events` werden hart abgelehnt.
- Stand: `MultiplayerSnapshotContract` spiegelt `commander_intents`, `fireteam_plan_status`, `communication_events`, `tactical_rules`, `breakout_states` und `air_asset_status` als kleine, stabil sortierte read-only Payloads.
- Stand: `SimulationRoot` publiziert den autoritativen AirAssetStatus mit und wendet Tactical-Snapshots clientseitig nur als Spiegelung an; Commands und Effects bleiben beim Snapshot-Apply leer.
- Offene Punkte: Echter LAN-Zwei-Instanzen-Sichtcheck bleibt manuell, der Headless-Smoke prueft Vertrag, Deduplizierung und Apply-Grenzen.
- Risiken: Weitere taktische Snapshot-Felder muessen ueber denselben Contract laufen, damit Netzlast und Privacy kontrollierbar bleiben.
- Lokale Pruefung: `task_281_tactical_command_multiplayer_authority_snapshot.gd`, `task_168_multiplayer_snapshot_contract_verifier.gd`, `task_169_multiplayer_two_client_playability_smoke.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_282 schliesst die Tactical-Overhaul-Reihe mit Playability-, Performance- und Help-Gate ab.

### TASK_282 - Tactical Overhaul Playability Performance Help Gate
- Status: implementiert
- Stand: `scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd` prueft die Tactical-Overhaul-Kette von TASK_269 bis TASK_281 plus TASK_268, baut eine kompakte Zwei-Fireteam-Tactical-Payload und validiert CommanderIntent, Fireteam-Planstatus, TacticalRules, CommunicationEvents, BreakoutState und AirAssetStatus.
- Stand: Das Gate verweist auf TASK_279 als End-to-End-LZ/AirAsset-Smoke, TASK_268 als UI/Help/Playability-Gate, TASK_281 als Multiplayer-Authority-Smoke und TASK_222/TASK_249 als Performance-/Audio-Visual-Budgetbasis.
- Stand: `docs/reports/tactical_overhaul_playability_performance_help_gate.md` dokumentiert automatisierte Abdeckung, Multiplayer-/Performance-Grenzen, Balance-Open-Items und manuelle Restpunkte; `docs/manual_checks/tactical_overhaul_manual_playability_checklist.md` haelt den Full-HD-/LAN-/Spielgefuehl-Check fest.
- Offene Punkte: Echter Zwei-Instanzen-LAN-Test, Full-HD-Sichtcheck und Balance-Gefuehl bleiben manuell.
- Risiken: Der Gate schuetzt Integration und Authority, ersetzt aber keinen finalen Kampagnenbalance-Pass.
- Lokale Pruefung: `task_282_tactical_overhaul_playability_performance_help_gate.gd`, `task_268_post_help_popup_playability_regression_smoke.gd`, `task_281_tactical_command_multiplayer_authority_snapshot.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_283 prueft Doku-Konsistenz nach der Tactical-Overhaul-Reihe.

### TASK_283 - Post Tactical Docs Consistency Audit
- Status: implementiert
- Stand: `docs/reviews/post_tactical_docs_consistency_audit.md` prueft TASK_269 bis TASK_282, Roadmap, Implementation Status, Dev-Dokumente, Reports, Linkziele, Kernbegriffe und Quellen-/Design-Drift.
- Stand: Ein Cleanup-Befund wurde direkt korrigiert: `docs/reports/contextual_help_coverage_layout_report.md` bezeichnet `mission.command.roe_fire_rules` nicht mehr als bis TASK_271 offen.
- Stand: `scripts/tests/task_283_post_tactical_docs_consistency_audit.gd` verifiziert Task-Status, Roadmap-/Status-Abgleich, eindeutige Taskdateien, lokale Linkziele, Begriffsanker und Game-Abstraktionsgrenzen.
- Offene Punkte: Folgeaudits TASK_284 bis TASK_288 pruefen Code-Authority, Branch-Integritaet, UI-Truth, Editor/Multiplayer-Grenzen und Coverage-Gaps.
- Risiken: Dieser Audit schuetzt Dokumentwahrheit, nicht jede Laufzeitentscheidung.
- Lokale Pruefung: `task_283_post_tactical_docs_consistency_audit.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_284 prueft Architekturgrenzen und Gameplay-Wahrheit im Code.

### TASK_284 - Gameplay Truth Architecture Boundary Audit
- Status: implementiert
- Stand: `docs/reviews/gameplay_truth_architecture_boundary_audit.md` dokumentiert die Authority-Linien fuer UI, Visualizer, Help, Editor, Multiplayer, Tactical-Daten, AirAssetStatus, Loadout/Gewicht und Character Card. Der Audit fand keine Blocker; zwei wichtige Restrisiken bleiben als Monitor-Punkte dokumentiert: clientseitige Snapshot-Mirror-Fallbacks und der breite historische `MissionTacticalSandboxController`.
- Stand: `scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd` scannt UI-/Meta-/Editor-/Visualizer-Dateien auf verbotene Runtime-Mutationsmuster, prueft Multiplayer-State-Key-Guards und smoke-testet Help-Popup sowie Tactical-Snapshot-Apply ohne neue `SimulationRoot`-Commands oder Effects.
- Offene Punkte: Keine grossen Fixes im Audit-Scope. Folgeaudits TASK_285 bis TASK_288 pruefen Entscheidungszweige, UI-Feedback, Editor/Save/Multiplayer-Vertraege und Coverage-Gaps.
- Risiken: Statische Suche kann weiterhin False Positives oder bewusst erlaubte Adapter uebersehen; der neue Guard schuetzt die bekannten Boundary-Risiken, ersetzt aber keine Code-Review fuer neue Runtime-Adapter.
- Lokale Pruefung: `task_284_gameplay_truth_architecture_boundary_audit.gd`, `run_task_284_truth_boundary_scan.ps1`, `task_166_multiplayer_authority_command_contract_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_285 prueft Entscheidungslogiken auf tote, doppelte oder widerspruechliche Zweige.

### TASK_285 - Tactical Decision Branch Integrity Review
- Status: implementiert
- Stand: `docs/dev/tactical_decision_priority_matrix.md` dokumentiert die aktuellen Decision Tables fuer CommanderIntent, TacticalRules, FireteamExecutionPlan, MultiFireteamPlan, BreakoutState, TacticalCommunicationEvent, EnemyProfile und AirAssetThreat. Konfliktprioritaeten sind als feste Gewinnerreihenfolge beschrieben.
- Stand: `docs/reviews/tactical_decision_branch_integrity_review.md` nennt keine Blocker. CommanderIntent-Fallbacks haben inzwischen `normalization_warnings`, und `security_mode`/`cover_priority` werden nur noch bei expliziter Wahl serialisiert, damit `take -> sector` und Risk-/Tempo-Cover-Fallbacks wieder erreichbar sind. AirAssetStatus-State-Fallbacks sind diagnostiziert; Cleanup-Befunde betreffen leere Breakout-Ergebnisse ohne blocked_reason.
- Stand: `scripts/tests/task_285_tactical_decision_branch_integrity_review.gd` prueft CommanderIntent-Aliase, TacticalRules-Konflikte, ExecutionPlan-Mapping, Multi-Fireteam-Rollen/Statusprioritaet, Breakout-Downgrades, AirAssetThreat-Gates und EnemyProfile-Diagnostics.
- Offene Punkte: Die Befunde sind bewusst nicht in diesem Review-Task gepatcht; kleine Folgepatches koennen in TASK_289 priorisiert werden.
- Risiken: Die Matrix pinnt Verhalten und kann bei spaeterem Balancing bewusst angepasst werden muessen; sie soll dann zusammen mit dem Verifier aktualisiert werden.
- Lokale Pruefung: `task_285_tactical_decision_branch_integrity_review.gd`, `task_272_multi_fireteam_coordinated_area_plan.gd`, `task_276_tactical_breakout_and_exception_behavior.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_286 prueft UI-/Feedback-Schicht auf Wahrheits-Rueckfaelle und stale State.

### TASK_286 - UI Feedback Truth Regression Review
- Status: implementiert
- Stand: `docs/reviews/ui_feedback_truth_regression_review.md` dokumentiert keine Blocker, aber wichtige UI-Truth-Risiken: Selection darf nicht pro Panel dupliziert werden, Disabled-Reasons muessen spezifisch bleiben, Comic-Bubble-Cooldowns sind nur Presentation-State und Charakter-/Bubble-Modifier duerfen nicht als Combat-Wahrheit gelesen werden.
- Stand: `scripts/tests/task_286_ui_feedback_truth_regression_review.gd` prueft statisch UI-/Meta-/Editor-/Visualizer-Grenzen, gleicht Mission-Selektion zwischen `get_command_feedback_snapshot()`, Command-Hierarchy und `TerrainMap3DView.get_render_snapshot()` ab und kontrolliert Help/Bubbles ohne `SimulationRoot`-Side-Effects.
- Stand: Map-Feedback-Filter werden gegen nicht-visuelle Bubble- und TacticalCommunicationEvent-Payloads geprueft. Character Card, FOB-Loadout und Editoranzeigen bleiben Display-/Authoringpfade ohne direkte Runtime-Mutation.
- Offene Punkte: Die Befunde sind Review-Feststellungen; kleine Folgepatches koennen in TASK_289 priorisiert werden, falls neue UI-Panels Selection oder Disabled-Reasons erweitern.
- Risiken: UI braucht weiterhin legitimen Fokus-/Hover-/Layout-State. Dieser State ist erlaubt, solange er nicht in taktische Wahrheit, Combat-Werte oder Command-Verfuegbarkeit umgedeutet wird.
- Lokale Pruefung: `task_286_ui_feedback_truth_regression_review.gd`, `task_257_button_reachability_and_interaction_verifier.gd`, `task_267_contextual_help_coverage_layout_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_287 prueft Editor-, Save/Load- und Multiplayer-Grenzen im Zusammenspiel.

### TASK_287 - Editor Save Multiplayer Contract Regression Review
- Status: implementiert
- Stand: `docs/reviews/editor_save_multiplayer_contract_regression_review.md` prueft Scenario/Editor, Local Roster Save, Settings, AirAssetMeta, Multiplayer-Commands, Snapshot-Privacy und Downloaded-Map-Grenzen nach den Tactical-/AirAsset-Erweiterungen.
- Stand: `GameSettingsContract` persistiert nur noch bekannte Settings-Keys; unbekannte Roster-/Map-/Runtime-Felder werden beim Normalisieren verworfen.
- Stand: `MultiplayerMapManifest.validate_map_json_text()` prueft Download-Payloads rekursiv auf `script`, `resource_path` und `absolute_path` und validiert `enemy_team_configs` gegen `EnemyTeamTacticsProfile`.
- Stand: `scripts/tests/task_287_editor_save_multiplayer_contract_regression_review.gd` deckt Scenario-Runtime-Bleed, Settings-/Roster-/Meta-Trennung, Client-Command-Rejects, Snapshot-Privacy und Downloaded-Map-Rejects ab.
- Offene Punkte: Keine im TASK-287-Scope; TASK_288 gleicht die Regression-Gates gegen diese Risiken ab.
- Risiken: Neue Save-/Settings-/Download-Felder muessen weiter ueber die jeweiligen Contracts laufen, statt unbekannte Payloads blind zu serialisieren.
- Lokale Pruefung: `task_287_editor_save_multiplayer_contract_regression_review.gd`, `task_281_tactical_command_multiplayer_authority_snapshot.gd`, `task_228_multiplayer_editor_map_manifest_download_consent.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_288 prueft Testabdeckung und Gate-Luecken.

### TASK_288 - Regression Gate Coverage Gap Audit
- Status: implementiert
- Stand: `docs/qa/regression_gate_coverage_crosswalk.md` ordnet Performance, Asset-Lokalitaet, Playability, Help, Tactical, Multiplayer, Gameplay-Truth, UI-Feedback-Truth, Editor/Save/Multiplayer und Doku-Truth jeweils einem Gate/Test, Report, harten Fehlern, Warning-only-Anteilen und Manual-Rest zu.
- Stand: `docs/reviews/regression_gate_coverage_gap_audit.md` dokumentiert keine Blocker, trennt Gate-Qualitaet nach harten Fehlern/Warnungen/Manual-Rest und priorisiert P1-Gaps fuer TASK_289: CommanderIntent-Normalisierungswarnungen und AirAssetStatus-Fallback-Diagnosen.
- Stand: `scripts/tests/task_288_regression_gate_coverage_gap_audit.gd` prueft Crosswalk-Pflichtbereiche, Dateilinks, High-Risk-Automation, Patch-Backlog und Post-Tactical-Patch-Run-List.
- Offene Punkte: Keine im TASK-288-Scope; TASK_289 entscheidet, welche kleinen Diagnose-/Review-Patches tatsaechlich umgesetzt werden.
- Risiken: Statische Gate-Listen muessen bei neuen Runtime-APIs, UI-Panels und Snapshot-Feldern weiter gepflegt werden.
- Lokale Pruefung: `task_288_regression_gate_coverage_gap_audit.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_289 fuehrt die finale Sneaky-Code-Review mit Patchqueue aus.

### TASK_289 - Final Sneaky Code Review Patch Queue
- Status: implementiert
- Stand: `docs/reviews/final_sneaky_code_review_patch_queue.md` fuehrt Findings zuerst, dokumentiert keine P0-Blocker, zwei in TASK_289 gefixte P1-Diagnosebefunde und eine kleine P2/P3-Patchqueue.
- Stand: `CommanderIntent` sammelt `normalization_warnings` fuer unbekannte Verb-/Tempo-/FireRule-/Contact-/Risk-Fallbacks und synchronisiert sie in Metadata/Dict/Snapshot.
- Stand: `AirAssetStatus` sammelt `normalization_warnings` fuer unbekannte State-Fallbacks in `from_dict()`, `apply_threat()` und lethal `apply_damage()` und spiegelt sie in Metadata/Snapshot.
- Stand: `MultiplayerSnapshotContract` uebernimmt diese Diagnose-IDs kompakt fuer CommanderIntent- und AirAssetStatus-Snapshots; `scripts/tests/task_289_final_sneaky_code_review_patch_queue.gd` prueft Reportform, Diagnose-Fixes, Snapshot-Kompaktheit und Patchqueue.
- Offene Punkte: P2/P3 fuer Breakout-Diagnosen, Boundary-Tokenpflege und manuelle LAN-/Full-HD-/Balance-Smokes. Der explizite Cover-/Security-Default-Fix in `CommanderIntent` ist umgesetzt.
- Risiken: Die neuen Diagnosefelder aendern keine Fallback-Semantik, muessen aber bei UI/Debug-Anzeigen als Diagnose und nicht als Gameplay-Befehl behandelt werden.
- Lokale Pruefung: `task_289_final_sneaky_code_review_patch_queue.gd`, relevante TASK_285/TASK_277/TASK_281/TASK_288-Gates und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_290 schreibt das User-Handbuch und markiert die verbleibenden P2/P3-Punkte als bekannte Einschraenkungen/manuelle Pruefungen.

### TASK_290 - User Handbuch Weekly Closeout
- Status: implementiert
- Stand: `docs/User-Handbuch.md` ist als Spielerhandbuch erstellt und deckt Hauptmenue, Singleplayer, Multiplayer, Editor, Einstellungen, Homebase/FOB, Mission Map, Fireteam-Befehle, NPC-Verhalten, Waffen/Loadout, Medic-Regeln, Terrain/Huegel, Fog of War, Audio, Feedback, Help-Popups, Troubleshooting und Glossar ab.
- Stand: Der Abschnitt "Noch in Arbeit / bekannte Einschraenkungen" markiert die verbleibenden manuellen LAN-/Full-HD-/Balance-/Audio-/VFX-/Drag-and-drop-Smokes sowie kleine P2/P3-Folgepunkte, ohne sie als final poliertes Verhalten zu verkaufen.
- Stand: `scripts/tests/task_290_user_handbuch_weekly_closeout.gd` prueft Pflichtabschnitte, Spielerperspektive, UI-Truth-Grenze, interne Task-ID-Abwesenheit, Kernthemen, bekannte Einschraenkungen und Markdown-Linkaufloesung.
- Offene Punkte: Keine im TASK-290-Scope; kuenftige spielbare Features muessen das Handbuch im selben Patch mitpflegen.
- Risiken: Das Handbuch kann bei neuen Gameplay-, Multiplayer-, Editor- oder Settings-Slices driften, wenn der Pflegehinweis nicht beachtet wird.
- Lokale Pruefung: `task_290_user_handbuch_weekly_closeout.gd`, Markdown-Link-/Pfadcheck und `git diff --check` laufen gruen.
- Naechster Schritt: Bei neuen Features `docs/User-Handbuch.md` aktualisieren und den TASK_290-Gate erneut ausfuehren.

### TASK_160 - Tactical Mission Playability Smoke
- Status: implementiert
- Stand: Der 2.5D-Live-Missionspfad zeigt jetzt Objective-Capture-Zone, Capture-Fortschritt, Missionsergebnis und kompakte Unit-State-Badges direkt in `TerrainMap3DView`. Move-/Defend-/Take-Wegpunkte, Attack-/Defend-Areas, Contacts, LZ und Dropship sind im 2.5D-Snapshot regressionssicher sichtbar. Frei schwebende alte 2D-Combat-/Wave-/Objective-Labels werden im 2.5D-Pfad unterdrueckt, damit sie nicht wieder ueber der Karte liegen.
- Stand: `scripts/tests/task_160_tactical_playability_verifier.gd` spielt den kompakten Loop LZ -> Dropship -> Deploy -> Move/Defend/Take -> Area Orders -> Contact -> Objective Capture -> Victory durch. Der Dropship-Bugfix-Verifier akzeptiert jetzt den 2.5D-Dropship-Marker als sichtbaren Primaerpfad statt den alten `DropshipPlanMarker` zu verlangen.
- Offene Punkte: Manuelle Sichtpruefung bleibt fuer Lesbarkeit der neuen 3D-Labels, Sprite-Sortierung und Kameragefuehl sinnvoll.
- Risiken: Die 3D-Statusanzeigen sind bewusst Snapshot-Spiegelungen; Gameplay-Wahrheit bleibt in SimulationRoot/TacticalController/CombatLoop.
- Naechster Schritt: Manuelle Godot-Pruefung des Playability-Loops und danach gezielte Politur fuer Badge-Lesbarkeit oder taktische UX, falls sie im Bild zu laut ist.

### TASK_159 Follow-up - 2.5D Mission Load/Offset Fix
- Status: implementiert
- Stand: Der 2.5D-Primary-View-Pfad laedt Terrain-Daten wieder performant, weil `TerrainMapData.load_from_file()` den Tile-Katalog nur noch einmal pro Map laedt und `TerrainTileData.from_dict()` keine Script-Loads pro Tile mehr ausloest. Der rotierbare Editor-/Live-Pfad nutzt die kalibrierte Kenney-GLB-Mapping-Datei `data/terrain_3d_asset_mapping.json`: Boden wird aus dem Space-Kit-`terrain.glb` gerendert, Waende/Objekte/Runtime-Units/Dropship als kalibrierte 3D-Modelle. Der Live-2.5D-Pfad rendert die versteckte Legacy-2D-Karte nicht mehr parallel.
- Stand: Der vorherige Versuch mit Kenney-Isometric-PNGs als `Sprite3D`-Karten war der falsche Abzweig fuer eine frei rotierbare Kamera: die Karten wirkten zu klein/versetzt und zeigten beim Orbit weiterhin dieselbe Seite. Diese PNGs bleiben nur Legacy-Material oder Fallback fuer Betrieb ohne 3D-Mapping-Datei; der Primaerpfad ist die echte 3D-Kalibrierung.
- Stand: Die 3D-Mapping-Tabelle enthaelt jetzt auch die bisher noch in den Legacy-Fallback fallenden Familien `wall_corner`, `cliff_straight`, `cliff_corner`, `slope`, `rock_large` und `rock_small`. Dadurch bleiben GLB-Materialien/Farben erhalten; Wand-/Eckenrotationen folgen im 3D-Pfad wieder der kalibrierten GLB-Richtungskonvention. Fehlende 3D-Mappings erzeugen im Primaerpfad einen sichtbaren `MissingAsset_*`-Marker und einen Snapshot-Zaehler statt still auf PNG- oder Block-Fallbacks zu wechseln.
- Stand: Die 2.5D-View zeichnet wieder Feldraender ueber dem Kenney-Boden. LZ, Move-/Defend-/Take-Wegpunkte und Attack-/Defend-Areas werden als markierte Terrainfelder gespiegelt; LZ-Placement snappt auf das Feldzentrum. Gerade Waende folgen wieder der alten Kenney-Wandachse, Nord-/Sued-Mauerecken haben eigene 3D-Mapping-Offsets, weil Ost/West bereits korrekt waren. Unit-Proxies folgen der autoritativen 2D-Simulation nur visuell geglaettet, drehen sich in Ziel-/Marschrichtung und nutzen um 25 Prozent kleinere Astronaut-Modelle.
- Stand: Der Editor hat ein kleines `Hoehe`-Werkzeug in der Topbar. Es nutzt die vorhandene Brushgroesse fuer 1x1/3x3/5x5-Felder und kann Terrain anheben, absenken oder direkt auf H=0/H=1/H=2 setzen. Die Kantenwahl `Hang`/`Cliff`/`Keine` schreibt weiter nur in `TerrainMapData.edge_type`; Pathfinding/LOS bleiben dadurch bei den bestehenden Terrain-Systemen statt in der UI.
- Stand: Runtime-Unit- und Dropship-Visuals folgen jetzt ebenfalls dem strikten 2.5D-Primary-Vertrag: Wenn das erwartete GLB fehlt, zeigt die View einen `MissingAsset_*`-Marker und Snapshot-Zaehler statt still auf Unit-Texturkarten, Capsule- oder Box-Proxies auszuweichen.
- Offene Punkte: Die vorherigen Headless-RID-/ObjectDB-Exit-Warnungen aus den 2.5D-Verifiern sind behoben; verbleibend ist nur die manuelle Sichtpruefung fuer Kamera-Gefuehl und Lesbarkeit.
- Risiken: Die Simulation bleibt weiterhin auf den bestehenden `Node2D`-Runtime-Ankern. Die 3D-View ist Darstellung und Eingabeprojektion, nicht Gameplay-Wahrheit.
- Naechster Schritt: Manuelle Godot-Pruefung von Mission Start -> LZ setzen -> Dropship Call -> Attack Area mit sichtbarer kalibrierter 3D-Map.

### TASK_001 – RuntimeLeader / FTL
- Status: implementiert
- Stand: `RuntimeLeader` als eigene `Node`-Komponente mit `class_name`, Signalen fuer Promotion, Demotion, Assignment und Command-Weitergabe sowie der API `promote()`, `demote()`, `assign(entity)` und `command(order)` eingefuehrt.
- Offene Punkte: keine FTL-Ausfuehrungslogik, keine Befehlsinterpretation, keine EventRouter- oder SimulationRoot-Anbindung, keine Szenenverdrahtung.
- Risiken: Signalvertraege und Zustandsbasis stehen, die spaetere Einbindung in autoritative Gameplay-Systeme muss konsistent bleiben.
- Naechster Schritt: RuntimeLeader an EventRouter und SimulationRoot anbinden, sobald die Folgesysteme implementiert sind.

### TASK_002 – EventRouter
- Status: implementiert
- Stand: `EventRouter` als eigene `Node`-Komponente mit Signalen fuer Squad-Commands, Unit-Ausfaelle, Threat-Meldungen, Leader-Wechsel und Respawn-Anfragen sowie schlanken Routing-Methoden eingefuehrt.
- Offene Punkte: keine RuntimeLeader-Anbindung, keine Missionslogik, kein Autoload, keine SimulationRoot- oder Registry-Integration.
- Risiken: Die Signalvertraege stehen, die spaetere Einbindung muss ohne harte Direktkopplung zwischen Runtime-Systemen, UI und Autoritaetslogik erfolgen.
- Naechster Schritt: EventRouter an kommende Systeme anbinden, sobald SimulationRoot und weitere Laufzeitkomponenten existieren.

### TASK_003 – SimulationRoot mit Command- und Effects-Queues, deterministischer Tick-Verarbeitung in `_physics_process()`, Guard-Checks, Stub-Apply-Methoden und `tick_processed`-Signal eingefuehrt.
- Offene Punkte: keine Gameplay-Mechanik, keine Missionslogik, keine Registry- oder UpdateManager-Anbindung, keine Zustandsmutation an fremden Nodes.
- Risiken: Die autoritative Verarbeitungsstruktur steht, die spaetere Befehls- und Effektsemantik muss strikt innerhalb von `SimulationRoot` bleiben.
- Naechster Schritt: konkrete Command- und Effect-Typen einfuehren, sobald die Folgesysteme definiert sind.

### TASK_013 – Commander Command Model
- Status: implementiert
- Stand: `CommanderCommand` als leichtgewichtiges datenorientiertes Modell unter `res://scripts/command/commander_command.gd` eingefuehrt; formalisiert die aktuell bekannten Commander-Befehlstypen `move`, `take`, `defend` und `flank` sowie `priority`, `unit_id`, `team_id`, optional `target_position` und `phase`.
- Offene Punkte: keine echte Befehlsausfuehrung, keine FTL-Entscheidungslogik, keine UI-Bindings und keine tiefere Command-Semantik ueber den reinen Datenvertrag hinaus.
- Risiken: Der aktuelle Vertrag ist bewusst klein und Dictionary-kompatibel; spaetere Erweiterungen muessen die bestehende `"type"`-Kompatibilitaet zu RuntimeLeader/EventRouter/SimulationRoot erhalten.
- Naechster Schritt: das Modell bei Bedarf in kleine Integrationspfade einspeisen, ohne die bestehenden Runtime-Systeme von Dictionary-Vertraegen abrupt zu entkoppeln.

### TASK_014 – FTL Task Model
- Status: implementiert
- Stand: `FTLTask` als leichtgewichtiges datenorientiertes Modell unter `res://scripts/ftl/ftl_task.gd` eingefuehrt; formalisiert die minimalen FTL-Task-Typen `seek_cover`, `move_to_area`, `engage_in_area`, `hold_position` und `retreat` sowie `priority`, `unit_id`, `team_id`, optional `target_position`, `target_area_id`, `source_command_type` und `phase`.
- Offene Punkte: keine echte Task-Ausfuehrung, keine RuntimeLeader-AI, keine Uebersetzungslogik aus Commander-Befehlen und keine UI-Bindings.
- Risiken: Das Modell ist bewusst klein und dictionary-orientiert; spaetere Erweiterungen sollten diese Datenkompatibilitaet erhalten und keine versteckte Ausfuehrungslogik in das Modell ziehen.
- Naechster Schritt: bei Bedarf spaeter einen kleinen, expliziten Uebersetzungspfad von Commander-Commands zu FTL-Tasks ergaenzen, ohne die Modelle eng zu koppeln.

### TASK_015 – Command to FTLTask Translator
- Status: implementiert
- Stand: ein schlanker `CommandToFTLTaskTranslator` unter `res://scripts/command/command_to_ftltask_translator.gd` uebersetzt gueltige `CommanderCommand`-Daten in `FTLTask`-Daten.
- Offene Punkte: keine echte FTL-Entscheidungslogik, keine Task-Queue, keine RuntimeLeader-Erweiterung und keine Ausfuehrung in `SimulationRoot`.
- Risiken: Die V1-Abbildung ist bewusst einfach und statisch; spaetere feinere taktische Zerlegung von `take` und `flank` muss explizit und separat eingefuehrt werden.
- Naechster Schritt: spaeter Integration in RuntimeLeader / SimulationRoot, ohne neue Kopplungen aufzubauen.
### TASK_018 – FTL-State-Modell minimal
- Status: implementiert
- Stand: `FTLRuntimeStatus` unter `res://scripts/ftl/ftl_runtime_status.gd` formalisiert jetzt einen kleinen Laufzeitstatus fuer FTLs mit den erlaubten Werten `idle`, `seeking_cover`, `moving_to_area`, `engaging_in_area`, `holding_position` und `retreating` sowie einem einfachen Dictionary-Roundtrip.
- Offene Punkte: noch keine RuntimeLeader-Anbindung, keine Status-Uebergaenge aus FTLTasks und keine Ausfuehrungslogik.
- Risiken: Das Modell ist bewusst klein und statuszentriert; spaetere Erweiterungen sollten keine versteckte Gameplay-Logik in den Datentraeger ziehen.
- Naechster Schritt: einen minimalen Uebergang von `FTLTask` zu `FTLRuntimeStatus` im `RuntimeLeader` abbilden.

### TASK_019 – minimaler FTLTask -> RuntimeStatus Uebergang
- Status: implementiert
- Stand: `RuntimeLeader` erzeugt jetzt beim minimalen Verarbeiten eines gueltigen `FTLTask` einen passenden `FTLRuntimeStatus`; dabei werden `seek_cover`, `move_to_area`, `engage_in_area`, `hold_position` und `retreat` auf die entsprechenden Laufzeitstatus abgebildet und ueber `runtime_status_changed(...)` signalisiert.
- Offene Punkte: keine tiefere Statusmaschine, keine Task-Abschlusslogik, keine Ausfuehrung und keine Rueckuebergaenge nach `idle`.
- Risiken: Der Uebergang ist bewusst rein datenbasiert und einseitig; spaetere komplexere Statuswechsel muessen explizit auf diesem einfachen Mapping aufbauen.
- Naechster Schritt: spaetere Statuswechsel und Task-Lebenszyklen nur dann ergaenzen, wenn dafuer ein klarer eigener Task vorliegt.

### TASK_020 – minimaler UnitCommand-Stub
- Status: implementiert
- Stand: `UnitCommand` unter `res://scripts/npc/unit_command.gd` formalisiert jetzt minimale Unit-Kommandos als Datenmodell mit den Typen `move_to_position`, `hold_position`, `engage_area`, `retreat` und `seek_cover` sowie kleinem Dictionary-Roundtrip.
- Offene Punkte: keine TestUnit-Anbindung, keine Ausfuehrung, keine Navigation und keine Runtime-Integration.
- Risiken: Das Modell ist bewusst nur ein Datentraeger; spaetere Unit-Logik muss darauf aufsetzen, ohne versteckte Wirkung in das Modell zu verlagern.
- Naechster Schritt: ein minimales Runtime-Status-Modell fuer `TestUnit` ergaenzen.

### TASK_021 – TestUnit Runtime-Status
- Status: implementiert
- Stand: `UnitRuntimeStatus` unter `res://scripts/npc/unit_runtime_status.gd` formalisiert die minimalen Unit-Zustaende `idle`, `assigned`, `pending_move` und `holding`; `TestUnit` unter `res://scripts/npc/test_unit.gd` traegt jetzt einen solchen Laufzeitstatus und signalisiert Statuswechsel ueber `runtime_status_changed(...)`.
- Offene Punkte: noch keine FTLTask-Zuweisung, keine UnitCommand-Anbindung und keine Ausfuehrungslogik.
- Risiken: Der Unit-Zustand ist bewusst klein und datenbasiert; spaetere Command- oder Simulationslogik darf diesen Datentraeger nicht still zur Gameplay-Wahrheit ausbauen.
- Naechster Schritt: einen minimalen FTLTask -> Unit-Zuweisungspfad ergaenzen.

### TASK_022 – FTLTask -> Unit-Zuweisung
- Status: implementiert
- Stand: `RuntimeLeader` kann den aktuell gehaltenen `FTLTask` jetzt minimal auf die aktuell referenzierte `TestUnit` abbilden; dafuer wird ein einfacher `UnitCommand` erzeugt und ueber `assign_current_ftl_task_to_unit()` an die Unit uebergeben.
- Offene Punkte: noch keine Mehrfach-Unit-Verteilung, keine Registry-Anbindung und keine Ausfuehrungslogik.
- Risiken: Die Abbildung bleibt bewusst direkt und lokal; spaetere komplexere Verteilung oder feinere Unit-Kommandosemantik muss explizit in eigenen Tasks folgen.
- Naechster Schritt: mehrere Units pro FTL als reinen Datenfluss ergaenzen.

### TASK_023 – mehrere Units pro FTL
- Status: implementiert
- Stand: `RuntimeLeader` kann jetzt mehrere unit-aehnliche Referenzen ueber `add_unit_member(...)` halten und den aktuellen `FTLTask` ueber `assign_current_ftl_task_to_all_units()` minimal an 2–3 Units als reine Datenzuweisung verteilen.
- Offene Punkte: keine Registry-Nutzung, keine differenzierte Verteilung pro Unit und keine Ausfuehrungslogik.
- Risiken: Die Mehrfachverteilung ist bewusst identisch fuer alle gehaltenen Units; spaetere feinere Aufteilung oder Priorisierung muss explizit und separat eingefuehrt werden.
- Naechster Schritt: den Batch abschliessen und erst im naechsten Batch sichtbare Reaktion oder Missionsszenen ergaenzen.



### TASK_024 – minimale Missions-Testszene
- Status: implementiert
- Stand: eine minimale Start- und Testszene unter `res://scenes/tests/mission_reactivity_test.tscn` haelt jetzt `SimulationRoot`, `EventRouter`, `UnitRegistry`, `FTLRegistry`, `UpdateManager`, einen `RuntimeLeader`, drei `TestUnit`-Instanzen und einen einfachen Zielmarker zusammen; ein kleiner Setup-Node registriert Units und FTL ueber direkte Referenzen.
- Offene Punkte: noch keine Move-Daten, keine sichtbare Reaktion, keine echte Missionslogik und keine autoritative Positionsveraenderung.
- Risiken: die Szene ist bewusst nur ein kontrolliertes Integrationsfeld; spaetere sichtbare Reaktion muss weiter ohne globale SceneTree-Suchen und ohne verdeckte Logik im Setup-Glue folgen.
- Naechster Schritt: eine minimale Zielposition als Daten an die Unit-Ebene haengen.

### TASK_025 – Move-Target als Daten
- Status: implementiert
- Stand: `UnitRuntimeStatus` und `TestUnit` koennen jetzt optional eine `target_position` als reinen Datenwert halten; bei einem `UnitCommand` mit Zielposition wird dieser Wert in den Runtime-Status der Unit uebernommen.
- Offene Punkte: noch keine autoritative Bewegung, keine Navigation und keine sichtbare Reaktion in der Szene.
- Risiken: die Zielposition ist bewusst nur vorbereitende Datenhaltung; spaetere Bewegung darf weiterhin nur ueber `SimulationRoot` committen.
- Naechster Schritt: einen minimalen autoritativen Move-Pfad im `SimulationRoot` ergaenzen.

### TASK_026 â€“ minimaler Move im SimulationRoot
- Status: implementiert
- Stand: `SimulationRoot` kann jetzt einen minimalen `move_to_position`-Command ueber direkte `UnitRegistry`-Referenz verarbeiten und eine `TestUnit` als `Node2D` in kleinen Schritten pro Physics-Tick Richtung `target_position` bewegen.
- Offene Punkte: keine Navigation, keine Kollisionslogik, kein Pathfinding, keine Formationen und keine Abschlusslogik bei Zielerreichung.
- Risiken: die Bewegung ist bewusst nur ein sehr kleiner Testpfad; spaetere echte Fortbewegung darf nicht durch versteckte Nebenlogik ausserhalb von `SimulationRoot` wachsen.
- Naechster Schritt: den ersten sichtbaren Commander -> FTL -> Unit-Flow ueber diesen Move-Pfad integrieren.

### TASK_027 â€“ erster sichtbarer Commander -> FTL -> Unit-Flow
- Status: implementiert
- Stand: ein kleiner `MissionCommandFlowDriver` erzeugt jetzt einen `CommanderCommand`, leitet ihn ueber `RuntimeLeader.command(...)` und `EventRouter` in den bestehenden `CommandToFTLTaskTranslator`, laesst den resultierenden `FTLTask` im `RuntimeLeader` in einen `UnitCommand` uebergehen und enqueued diesen anschliessend in `SimulationRoot`; in der Testszene reagiert `UnitAlpha` dadurch sichtbar mit Bewegung Richtung Zielmarker.
- Offene Punkte: keine Formation, keine Taktiklogik, keine Mehrfachverteilung ueber den Commander-Pfad und keine Missionsmechanik.
- Risiken: der sichtbare Flow ist bewusst ein einzelner Happy Path fuer `move`; spaetere Kommandotypen und Team-Flows muessen explizit und separat folgen.
- Naechster Schritt: nach Batch-Abschluss Godot-Start und Integrationsstand erneut pruefen, bevor weitere sichtbare Systeme folgen.

### TASK_028 – minimales LOS-System
- Status: implementiert
- Stand: `LineOfSightSystem` unter `res://scripts/core/los_system.gd` liefert jetzt einen sehr kleinen geometriebasierten Sichtliniennachweis zwischen zwei Punkten, einer `Node2D` und einer Zielposition oder zwei `Node2D`-Referenzen auf Basis einer einfachen Distanzgrenze.
- Offene Punkte: keine Hindernispruefung, keine Raycasts, keine Performance-Optimierung und keine Kopplung an spaetere Combat- oder FOW-Systeme.
- Risiken: der Sichtkontakt ist bewusst nur ein Distanz- und Referenznachweis; spaetere echte Deckungs- oder Blockerlogik muss explizit und separat folgen.
- Naechster Schritt: eine minimale Fog-of-War-Sichtbarkeit auf diesem LOS-Nachweis aufbauen.

### TASK_029 – minimales Fog of War
- Status: implementiert
- Stand: `FogOfWarSystem` unter `res://scripts/core/fog_of_war_system.gd` verwaltet jetzt einen kleinen booleschen Sichtbarkeitszustand pro `team_id` und `target_id` und kann diesen direkt aus dem bestehenden `LineOfSightSystem` aktualisieren.
- Offene Punkte: keine Darstellung, keine Shader, keine Mehrbeobachter-Aggregation und kein finales FOW-System.
- Risiken: das System ist bewusst nur ein datenbasierter Sichtbarkeitscontainer; spaetere echte FOW-Darstellung oder Kartenlogik muss separat und explizit darauf aufsetzen.
- Naechster Schritt: einen minimalen Treffer-/Damage-Pfad auf dem bestehenden Test- und Simulationsaufbau ergaenzen.

### TASK_030 – minimales Treffer-/Damage-Modell
- Status: implementiert
- Stand: `DamageModel` unter `res://scripts/core/damage_model.gd` liefert jetzt einen kleinen datenbasierten Treffer- und Schadenspfad; `SimulationRoot` kann `damage`-Effects minimal autoritativ anwenden und `TestUnit` haelt dafuer einfache Health- und Hit-Daten.
- Offene Punkte: keine Waffenlogik, keine Projektilsimulation, keine Ballistik und noch keine Down-/Bleedout-Zustaende.
- Risiken: der Pfad ist bewusst klein und testorientiert; spaetere Combat-Erweiterungen muessen weiterhin ueber `SimulationRoot` laufen und sollten diesen Utility-Charakter nicht zu einem grossen Framework aufblasen.
- Naechster Schritt: den minimalen Zustandsfluss `fit -> down -> bleedout` auf dem neuen Damage-Pfad ergaenzen.

### TASK_031 – Down-/Bleedout-Zustände
- Status: implementiert
- Stand: `UnitVitalStatus` unter `res://scripts/npc/unit_vital_status.gd` formalisiert jetzt die minimalen Zustände `fit`, `down` und `bleedout`; `TestUnit` wechselt bei tödlichem Schaden von `fit` nach `down`, und `SimulationRoot` kann diesen Zustand über einen kleinen `bleedout`-Effect weiter nach `bleedout` schieben.
- Offene Punkte: keine Revive-Mechanik, keine Sanitätslogik, keine Evakuierung und keine komplexen Down-State-Regeln.
- Risiken: der Zustandsfluss ist bewusst nur ein sehr kleiner Testpfad; spätere Combat- und Support-Systeme müssen diese Minimalzustände explizit erweitern statt sie implizit zu überladen.
- Naechster Schritt: einen minimalen Friendly-Fire-Fall im bestehenden Damage-Pfad berücksichtigen.
### TASK_032 – Friendly Fire
- Status: implementiert
- Stand: `SimulationRoot` beruecksichtigt jetzt bei `damage`-Effects einen minimalen Friendly-Fire-Fall auf Basis von `attacker_team_id`, Ziel-`team_id` und `allow_friendly_fire`; gleiche Teams koennen damit gezielt blockiert oder als erlaubter Friendly-Fire-Treffer im Hit-Kontext markiert werden.
- Offene Punkte: keine komplexe Teamlogik, keine Projektile, keine Deckungs- oder Identifikationsregeln und keine weitergehende Combat-Auswertung.
- Risiken: der Pfad bleibt bewusst klein und regelbasiert; spaetere echte Kampf- oder Teammechaniken muessen diesen Minimalfall explizit erweitern statt ihn still zu verkomplizieren.
- Naechster Schritt: Batch abschliessen, Godot-Start pruefen und danach erst mit Meta-Layer oder erweiterten Taktiksystemen weitermachen.
### Minimal Combat Loop Test (Phase 6 – Zwischen-Implementierung)
- Status: implementiert
- Stand: die Missions-Testszene enthaelt jetzt zwei Gegner-`TestUnit`-Instanzen mit eigener Team-ID; ein kleiner `MissionCombatLoopDriver` prueft direkten LOS-Kontakt zwischen Friendly- und Enemy-Units, enqueued darauf basierend minimale `damage`- und `bleedout`-Effects in `SimulationRoot` und markiert den Fight als beendet, sobald alle Gegner nicht mehr `fit` sind.
- Offene Punkte: keine Gegen-KI, keine Waffenvielfalt, keine Deckungslogik, keine Respawn- oder Eliminierungsmechanik und keine komplexe Team-Auswertung.
- Risiken: der Combat-Loop ist bewusst ein kleiner Integrationspfad fuer die Testszene; spaetere echte Combat-Systeme muessen den Glue-Code explizit ersetzen, statt ihn still auszubauen.
- Naechster Schritt: bei Bedarf den symmetrischen Gegnerpfad oder eine spaetere Eliminierungsstufe in eigenen Tasks aufbauen, ohne die autoritative Rolle von `SimulationRoot` aufzuweichen.

### Minimal Combat Control Behavior (Phase 6 – Zwischen-Implementierung)
- Status: implementiert
- Stand: `UnitCommand`, `UnitRuntimeStatus` und `TestUnit` tragen jetzt einen kleinen datenbasierten Feuerstatus mit `fire_at_will` und `hold_fire`; `engage_area` fuehrt auf einen expliziten `engaging`-Zustand, waehrend `move_to_position` als `pending_move` mit `hold_fire` erhalten bleibt. `RuntimeLeader` leitet diesen Status minimal aus dem aktuellen FTL-Task ab, und der bestehende `MissionCombatLoopDriver` erlaubt Angriffe nur noch bei `fire_at_will` plus engage-/holding-aehnlichem Zustand.
- Offene Punkte: keine groessere Combat-Logik, keine Rules-of-Engagement-Varianten, keine komplexe Zielwahl und keine Gegner-Ausweitung ueber den bestehenden Testpfad hinaus.
- Risiken: die Steuerung bleibt bewusst testpfadbezogen; spaetere echte Kampfsteuerung sollte diese Minimalregeln explizit ablösen statt sie still zu verkomplizieren.
- Naechster Schritt: bei Bedarf spaeter weitere Commander-/FTL-Befehlstypen mit klarer Feuerregel abbilden und nur dann eine komplexere Zielwahl ergaenzen, wenn dafuer ein eigener Task vorliegt.
### TASK_033 – Minimal Meta Layer (Heimatbasis + FOB)
- Status: implementiert
- Stand: ein kleiner menuegetriebener Meta-Layer startet jetzt ueber `res://scenes/meta/meta_layer_test.tscn`; ein `HomebaseTestScreen` zeigt die verfuegbaren Friendly-TestUnits und erlaubt eine einfache Teamzusammenstellung, ein `FOBTestScreen` zeigt das uebertragene Team und startet daraus die bestehende Missions-Testszene. Die Auswahl wird ueber einen schlanken `MetaLayerFlow` ohne Autoload oder neue grosse Szenenarchitektur an die Missionsszene weitergereicht.
- Offene Punkte: keine Persistenz, keine Skill-/Loadout-/Soziallogik, keine Reise- oder Meta-Simulation und kein Rueckweg aus der Mission in den Meta-Layer.
- Risiken: der Datenfluss ist bewusst klein und screen-getrieben; spaetere echte Meta-Systeme muessen diesen Testpfad explizit erweitern statt ihn still zu einer grossen UI- oder Persistenzschicht auszubauen.
- Naechster Schritt: spaeter nur bei eigenem Task weitere Meta-Funktionen wie Respawn-/Transferlogik oder einfache Missionsauswertung anhaengen.
### TASK_034 – Minimal Mission Return Flow (FOB-Rueckfluss)
- Status: implementiert
- Stand: der bestehende `MetaLayerFlow` bindet jetzt das Missionsende aus dem `MissionCombatLoopDriver` direkt an den Meta-Layer an, sammelt den minimalen Teamzustand der eingesetzten Friendly-Units ein und zeigt daraus einen kleinen Debrief-Screen mit Ergebnis und Rueckgabeoptionen. Die FOB kann den letzten Missionsausgang samt Teamzustand anzeigen, und sowohl der Rueckweg Debrief -> FOB als auch Debrief -> Homebase sind minimal moeglich.
- Offene Punkte: keine Persistenz, keine Nachsorge-/Heilungslogik, keine Kampagnenauswertung und kein Rueckfluss tieferer Missionsmetriken.
- Risiken: der Rueckfluss ist bewusst klein und screen-getrieben; spaetere echte Meta- oder Kampagnenlogik sollte diesen Glue-Code explizit erweitern statt ihn still zu einer grossen Ergebnisarchitektur auszubauen.
- Naechster Schritt: spaeter bei Bedarf nur in eigenen Tasks weitere Meta-Rueckfluesse wie Respawn-/Zeitlogik oder einfache Ergebnisfolgen anhaengen.

### TASK_035 – Minimal Tactical Order Behavior
- Status: implementiert
- Stand: `RuntimeLeader` leitet jetzt fuer `defend`, `move` und `flank` kleine taktische Unterschiede in `UnitCommand` und `UnitRuntimeStatus` ab: `defend`/`hold` bleibt in Position, traegt erhoehten `cover_score` und darf feuern, `move` bleibt bei `hold_fire`, und `flank` bekommt einen seitlichen Zieloffset sowie einen kleinen `attack_bonus`. `SimulationRoot` beruecksichtigt diese Minimalwerte im bestehenden Damage-Pfad, und die Missions-Testszene zeigt jetzt drei parallele Friendly-Orders mit unterscheidbarem Verhalten.
- Offene Punkte: keine komplexe Deckungsarchitektur, keine echte Taktik-KI, keine Formation, keine Navigation und keine ausgebaute Zielpriorisierung ueber den kleinen Testpfad hinaus.
- Risiken: die Unterschiede bleiben bewusst daten- und testszenenbasiert; spaetere echte Taktiksysteme sollten diese Minimalableitungen explizit ersetzen statt sie still weiter aufzublasen.
- Naechster Schritt: spaeter nur bei eigenem Task feinere Deckungs-, Zielwahl- oder Rollenregeln ergaenzen und dabei die autoritative Rolle von `SimulationRoot` beibehalten.

### Minimal Tactical Readability (Phase 6/7 – Zwischen-Implementierung)
- Status: implementiert
- Stand: `TestUnit` zeigt in der Missions-Testszene jetzt kleine direkt an die Unit geheftete Status- und Event-Texte fuer `MOVE`, `DEFEND`, `FLANK`, `ENGAGE`, `DOWN` und `BLEEDOUT` sowie `HF` / `FAW` und sichtbaren LOS-Kontakt. `MissionCombatLoopDriver` erzeugt zusaetzlich eine kleine Kontaktlinie, eine kompakte Event-Anzeige, einen klaren Siegerhinweis und ein leicht entschleunigtes Angriffstempo, damit Treffer, Down/Bleedout und Combat-Ende beobachtbarer bleiben.
- Offene Punkte: keine groessere HUD-/Debug-Architektur, keine Politur, keine Animationen und keine komplexe Zeitsteuerung.
- Risiken: die Lesbarkeitshilfen bleiben bewusst testszenenbezogen; spaetere echte UI- oder Debug-Systeme sollten diesen kleinen Pfad explizit ersetzen statt ihn still zu einer grossen Overlay-Schicht auszubauen.
- Naechster Schritt: spaeter nur bei eigenem Task weitere gezielte Beobachtbarkeit wie einfache Threat-/Objective-Hinweise ergaenzen, ohne die Szene in eine Debug-Framework-Struktur zu ziehen.

### Minimal Tactical Input UI (Phase 6/7 – Zwischen-Implementierung)
- Status: implementiert
- Stand: die Missions-Testszene startet jetzt neutral ohne automatische Initial-Orders; drei kleine Unit-gebundene `MissionCommandFlowDriver` koennen wiederholt genutzt werden, und ein schlanker `MissionTacticalSandboxController` ergaenzt Hotkeys plus vier kleine Buttons fuer `move`, `defend`, `flank` und `take`. Die finalen Tasten sind jetzt klar: `LMB = Zielmarker setzen`, `1 = move`, `2 = defend`, `3 = flank`, `4 = take`, `Q/E = Fireteam ALL/BLUE/GOLD`, `R/F = Phase APPROACH/ASSAULT/HOLD`. Linksklick setzt den bestehenden Zielmarker direkt ueber die Canvas-/World-Koordinaten um; UI-Klicks werden ignoriert und freie Klicks auf den sichtbaren Weltbereich begrenzt. Friendly-Units nutzen in der Testszene `astronautA_SW`, Enemy-Units `astronautB_SW` statt Polygon-Placeholdern.
- Offene Punkte: die Fireteam- und Phase-Umschaltung bleibt bewusst szenenlokal; es gibt keine grosse Commander-UI, keine Auswahlarchitektur und noch keine tiefere Phase-Wirkung im Combat-Loop.
- Risiken: der UI-Pfad darf keine Gameplay-Wahrheit uebernehmen; er bleibt ein leichter Command-Ausloeser fuer den bestehenden Commander -> FTL -> Unit -> SimulationRoot-Flow. Spaetere echte Commander- oder HUD-Systeme sollten diesen kleinen Szenen-Controller explizit ersetzen statt ihn still auszubauen.
- Naechster Schritt: nur bei eigenem Task gezielt weiter verfeinern, etwa Marker-/Objective-Lesbarkeit oder spaetere echte Fireteam-/Phasenwirkung, ohne neue UI- oder Input-Architektur aufzubauen.

### Iso Map V2 Layout (Phase 5/6 – Zwischen-Implementierung)
- Status: implementiert
- Stand: die Missions-Testszene nutzt weiter `res://scenes/maps/iso_map_v2_layout.tscn`, aber die Bodenform wurde jetzt wieder explizit zu einer klaren grossen Iso-Raute aufgebaut statt zu einer asymmetrischen Freiform. Die sichtbare Bodenbasis besteht weiterhin ausschliesslich aus wiederholten `terrain_SW.png`-Kacheln; es gibt keine Gebaeude, keine Cliff-Stufen und keine zweite Hoehe. Die Richtungs-Konvention bleibt fuer diesen Pfad verbindlich: obere Kante = `N`, untere Kante = `S`, linke Kante = `W`, rechte Kante = `E`, obere linke Ecke = `NW`, obere rechte Ecke = `NE`, untere linke Ecke = `SW`, untere rechte Ecke = `SE`. `terrain_SW.png` bleibt unveraendert die Referenzkachel fuer `SW` = unten links / southwest; es wurde nichts frei gedreht. Friendly- und Enemy-Spawn sowie `objective_point` wurden in dieser klaren Rautenflaeche weiter auseinander und weniger direkt achsig gesetzt, damit die Karte ruhiger lesbar und als Testflaeche laenger beobachtbar bleibt. `MissionTestSetup` liest die Marker weiterhin direkt aus der Map-Szene und richtet Friendlies, Enemies und den Zielmarker daran aus.
- Offene Punkte: die Map ist weiterhin nur Struktur und Marker, keine Gameplay-Wahrheit; es gibt noch keine Terrain-Metadaten fuer `walkable`, `blocks_los`, `cover` oder `orientation`, keine Hindernis- oder Hoehenlogik und keine spaetere Fireteam-Flanknutzung der optionalen Flank-Anker.
- Risiken: die Karte verbessert Iso-Lesbarkeit, Spacing und Beobachtungszeit, aber LOS und Combat bleiben auf dem bestehenden Slice weiter rein systemseitig und nicht terrainbasiert. Spaetere Terrain-Daten oder feineres Encounter-Tuning sollten explizit als eigene Daten- bzw. Balancing-Tasks folgen, statt still in die Szene hineinzuwachsen.
- Naechster Schritt: nur bei eigenem Task gezielt weitere Terrain-Daten oder eine spaetere feine Layout-Iteration ergaenzen, ohne ein grosses Tile-/Registry-System vorzuziehen.

### TASK_036 – Respawn-Logik
- Status: implementiert
- Stand: `UnitVitalStatus` kennt jetzt den Zustand `respawning`; `TestUnit` hat eine `respawn(spawn_position)`-Methode, die eine Unit von `down`/`bleedout` zurueck auf `fit` setzt, Health auf Maximum zuruecksetzt und die Unit an die uebergebene Spawn-Position verschiebt. `SimulationRoot` verarbeitet jetzt einen `respawn`-Effect autoritativ. Ein neuer `RespawnManager` unter `res://scripts/core/respawn_manager.gd` verwaltet timerbasierte Respawns pro Unit mit konfigurierbarem Spawn-Typ (Rover: 30s, FOB: 150s, Homebase: 270s). `MissionCombatLoopDriver` fordert automatisch Respawns fuer eliminierte Units an und setzt den Bleedout-Tracker bei erfolgreichem Respawn zurueck. Friendlies und Enemies koennen jetzt beide bleedouten und respawnen.
- Offene Punkte: keine Respawn-Limitierung, keine Respawn-Warteschlange, keine sichtbare Timer-Anzeige und keine differenzierte Spawn-Punkt-Auswahl.
- Risiken: der Respawn-Pfad ist bewusst klein und timerbasiert; spaetere echte Respawn-Mechaniken (begrenzte Leben, Sanitaeter, Evakuierung) muessen diesen Minimalpfad explizit erweitern.
- Naechster Schritt: bei Bedarf spaeter Respawn-Timer-Anzeige oder differenzierte Spawn-Punkte in eigenen Tasks ergaenzen.

### TASK_037 – Rover/Frachter Respawn-Punkte
- Status: implementiert
- Stand: `RespawnManager` unterstuetzt jetzt drei Spawn-Typen mit den V1-Zeitwerten: `rover` (30s), `fob` (150s) und `homebase` (270s). Spawn-Positionen werden pro `team_id` gesetzt und von `MissionTestSetup` aus den bestehenden Map-Markern (`spawn_alpha`, `spawn_bravo`) automatisch uebernommen. Die Missions-Testszene nutzt standardmaessig `rover`-Respawn fuer schnelle Testzyklen.
- Offene Punkte: keine sichtbaren Spawn-Punkt-Marker in der Szene, keine Fahrzeug-Darstellung, keine Spawn-Punkt-Auswahl durch den Spieler und keine unterschiedlichen Spawn-Punkte pro Typ.
- Risiken: die Spawn-Punkte sind bewusst nur Positionsdaten ohne eigene Nodes oder Darstellung; spaetere Rover-/Frachter-Mechaniken muessen als eigene sichtbare Szenenelemente folgen.
- Naechster Schritt: spaeter bei eigenem Task sichtbare Spawn-Punkt-Marker oder Fahrzeug-Stubs in der Missionsszene ergaenzen.

### Symmetrischer Gegner-Kampfpfad (Phase 6/7 – Zwischen-Implementierung)
- Status: implementiert
- Stand: `MissionCombatLoopDriver` erlaubt jetzt bidirektionalen Kampf; Enemies koennen Friendlies angreifen, wenn sie `fit` sind und LOS-Kontakt haben. Friendlies koennen ebenfalls downed und bleedout werden, mit anschliessendem Respawn ueber den `RespawnManager`.
- Offene Punkte: keine echte Gegner-KI, keine Positionierung, keine Deckungssuche und keine Gegner-Befehlskette.
- Risiken: der Gegnerpfad ist bewusst nur ein symmetrischer Angriffspfad ohne eigene taktische Logik; spaetere Gegner-KI muss explizit und separat folgen.

### TASK_106 – Dropship-LZ, Insertion und verzoegerte Aktivierung
- Status: implementiert
- Stand: `MissionTestSetup` kann Friendly-Units jetzt standardmaessig bis zur Insertion aus `UnitRegistry`/`FTLRegistry` fernhalten (`defer_friendly_runtime_activation = true`) und blendet sie bis zum Einflug aus. `MissionTacticalSandboxController` registriert Units erst beim Deboarding autoritativ in `UnitRegistry`, bindet sie an `RuntimeLeader`/`FTLRegistry` und startet fuer das frisch eingeflogene Fireteam den aktiven Phase-Plan erst ab diesem Aktivierungszeitpunkt. Direkte Commands, Ad-hoc-Orders, Default-Behavior und Cover-Hold-Ausgaben sind vor Insertion fuer nicht aktive Fireteams gesperrt. `MissionCombatLoopDriver` verarbeitet nur Units, die in `UnitRegistry` aktiv sind, damit nicht eingeflogene Teams nicht vorzeitig am Gefecht teilnehmen.
- Offene Punkte: keine eigene Insertion-Warteschlange fuer mehrere zeitversetzte Transporter und keine erweiterte Missionsanzeige mit explizitem Aktivierungs-Timer pro Fireteam.
- Risiken: der Aktivierungspfad ist bewusst auf den bestehenden Dropship-Sequencer im Tactical-Sandbox-Controller begrenzt; spaetere echte Multi-Transport- oder Netzwerk-Synchronisierung sollte diesen Pfad explizit erweitern.
- Naechster Schritt: TASK_107 (LoadoutModifierResolver + initiale Missions-Effects) auf den jetzt zeitlich korrekten Insertion-Aktivierungszeitpunkt aufsetzen.

### TASK_107 – LoadoutModifierResolver und initiale Missions-Effects
- Status: implementiert
- Stand: Neuer `LoadoutModifierResolver` uebersetzt FOB-`member_loadouts` (`weapon_1`, `weapon_2`, `armor`) in `UnitLoadoutModifiers` pro Unit inklusive Alias-Normalisierung (`rail_gun`/`sonderwaffe` -> `special`) und fester Formeln fuer Waffen und Armor. `MissionTestSetup` baut die Modifikator-Dictionaries beim Missionsaufbau und enqueued fuer bereits aktive Friendlies initiale `apply_loadout_modifiers`-Effects. Fuer verzoegert eingeflogene Friendlies enqueued der `MissionTacticalSandboxController` denselben Effekt beim Runtime-Insert. `SimulationRoot` verarbeitet den neuen autoritativen Effect-Typ und delegiert an `TestUnit.apply_loadout_modifiers(...)`; `TestUnit` integriert die Modifikatoren in Hit-/Speed-/Damage-Taken-Effekte sowie in den effektiven Cover-Score.
- Offene Punkte: keine tiefe Distanzklassenlogik im Combat-Loop (range_class ist vorerst Datenvertrag) und keine gestaffelte Waffen-Slot-Gewichtung ueber den eingefuehrten Secondary-Weight hinaus.
- Risiken: die additive Formel ist bewusst klein und datengetrieben; spaetere Balancing-Runden sollten die Faktoren explizit feinjustieren statt implizit in Einzelpfade einzugreifen.
- Naechster Schritt: Folge-Tasks koennen `range_class` und weitere Loadout-Effekte gezielt im Combat-Resolver auswerten.

### TASK_108 – PatrolEditorTool und Pre-Contact-Patrol
- Status: implementiert
- Stand: `TerrainMapData` traegt jetzt einen Patrol-Datenvertrag (`patrol_paths`) als Dictionary `spawn_id -> waypoint[]` mit JSON-Load/Save. Der interne `MapEditor` hat ein kleines `Patrol`-Tool mit Spawn-Auswahl, sichtbarer Reihenfolge/Overlay, Hinzufuegen per Klick, Verschieben per Drag und Entfernen via `Ctrl+Klick`; Speicherung laeuft ueber die bestehende Map-JSON-Pipeline. `MissionTestSetup` uebergibt Patrol-Pfade aus der geladenen Karten-JSON an den `EnemyWaveController`. `MissionCombatLoopDriver` nutzt diese Pfade fuer pre-contact Bewegung: Enemies folgen Waypoints, bis `enemy_should_hold_position` erstmals Kontaktlage meldet, danach greifen wieder die bestehenden reaktiven Combat-Pfade.
- Offene Punkte: kein separates Patrol-Tempo pro Segment und keine erweiterten Patrol-Modi (pause/look-at), nur zyklischer Waypoint-Follow.
- Risiken: Patrol-Follow bleibt bewusst klein und nutzt den bestehenden `move_to_position`-Commandpfad; spaetere KI-Ausbauten sollten diesen Hook gezielt ersetzen statt parallel eine zweite Bewegungslogik zu bauen.
- Naechster Schritt: bei Bedarf spaetere Awareness-/Stealth-Tasks auf den vorhandenen pre-contact Patrol-Zustand aufsetzen.

### TASK_102 – Ad-hoc-Orders und Return-to-Plan
- Status: implementiert
- Stand: Ein neuer `AdHocOrderController` verwaltet laufende Sofortbefehle pro Fireteam (`flank`, `disengage`, `fall_back`, `focus_fire`, `hold_till_last_man`) ausserhalb der geplanten `FireteamOrderPlan`-Wegpunkte. Der `TacticalInputController` kann diese Befehle nur bei aktivem Kontakt ausloesen, unterbricht dabei laufende Plan-Ausfuehrung, visualisiert Ad-hoc-Orders als getrennten Overlay-Pfad und fuehrt nach Abschluss oder manuellem `Return to Plan` wieder zum naechsten pending-Wegpunkt zurueck.
- Offene Punkte: kein separates Suppression-System, keine dedizierte Beschuss-Heuristik ausser Kontaktstatus und keine komplexe Priorisierungslogik zwischen mehreren gleichzeitig konkurrierenden Sofortbefehlen.
- Risiken: die Gefechtsfreigabe basiert aktuell bewusst auf dem bestehenden Kontaktzustand pro Unit; spaetere feinere Trigger (z. B. suppressive fire ohne direkten Kontakt) muessen explizit in eigenen Tasks folgen.
- Naechster Schritt: TASK_103 fuer inter-fireteam Koordination ueber EventRouter und erweiterten Return-to-Plan-Glue umsetzen.

### TASK_103 – Suppression, Interruption und Return-to-Plan
- Status: implementiert
- Stand: `TacticalInputController` fuehrt jetzt einen laufenden Suppression-Container pro Fireteam mit Treffer-/Nahmiss-Zuwachs und trait-/leadership-abhaengigem Decay. Bei aktiver Suppression werden Fireteams in den Status `interrupted` ueberfuehrt, erhalten temporaere Malus-Werte (`move_speed_factor`, `attack_bonus`, `semi_disciplined` Fire-Discipline) und priorisieren Cover-Halten gegenueber Wegpunkt-Fortschritt; `hold_till_last_man` bleibt von Suppression ausgenommen. Nach Stabilisierung erfolgt automatisch ein Ruecksprung auf den naechsten `pending`-Wegpunkt, und ein manueller Return-to-Plan ist ueber ein neues `FireteamStatusPanel` verfuegbar.
- Offene Punkte: keine tiefe Morale-/Panik-Kaskade, keine separate Ballistik-/Munitionslogik und keine ausgebauten Mehrstufen-Reaktionen jenseits des aktuellen Suppression-Slices.
- Risiken: Suppression basiert aktuell auf Kontakt plus Health-Deltas im Testszenen-Controller; spaetere echte Gefechtsinstrumentierung sollte diese Trigger explizit in Runtime-/Combat-Systeme ueberfuehren, statt sie still im UI-nahen Glue wachsen zu lassen.
- Naechster Schritt: falls noetig, inter-fireteam Koordination ueber dedizierte EventRouter-Consumer weiter ausbauen (z. B. flankierende Entlastungsreaktionen).

### TASK_104 – Inter-Fireteam-Koordination und Leader-initiiertes Flankieren
- Status: implementiert
- Stand: Ein neuer `FireteamCoordinationManager` erkennt enge Zielraeume auf Plan-/Fireteam-Ebene und erzeugt Bounding-Zuweisungen, bei denen das Fireteam mit hoeherem `leadership` zuerst vorrueckt und das andere in Cover/Hold bleibt. `TacticalInputController` integriert diese Koordination in den aktiven Phasenlauf, rotiert Rollen nach `fireteam_ready_to_advance` und behandelt Ad-hoc-Unterbrechungen als temporaere Pause mit Rueckkehr in den Koordinationsfluss. Zusaetzlich kann ein aggressiver/reckless Leader mit `leadership > 0.7` bei aktivem Kontakt und verfuegbarem Terrainfenster autonom einen Ad-hoc-`flank` ausloesen. Alle Koordinations-/Flank-Ereignisse werden ueber erweiterte `EventRouter`-Signale kommuniziert.
- Offene Punkte: keine globale Multi-Fireteam-KI, keine persistente Koordinationshistorie und keine tiefere Gruppen-Taktik ueber den Bounding-Slice hinaus.
- Risiken: Die aktuelle Koordination bleibt bewusst leichtgewichtig und testszenenlokal; spaetere komplexere Team-Taktik sollte den Signalvertrag explizit weiterfuehren statt den Controller still zu ueberladen.
- Naechster Schritt: Falls notwendig, in Folge-Tasks dedizierte EventRouter-Consumer fuer Entlastungs-/Unterstuetzungsreaktionen zwischen Fireteams ausbauen.

### TASK_105 – Leader-Nachfolge, Lead-Rueckgabe und UI-Synchronisierung
- Status: implementiert
- Stand: `MissionCombatLoopDriver` verwaltet jetzt pro Fireteam Original-Lead, Acting-Lead und Mitgliederliste. Faellt der urspruengliche Lead aus, uebernimmt automatisch das fitte Mitglied mit dem hoechsten `leadership`, bei Gleichstand entscheidet `toughness`. Sobald der Original-Lead durch Respawn oder spaetere Insertion wieder `fit` ist, geht die Fuehrung in derselben Mission automatisch an ihn zurueck. `TacticalInputController` bindet Lead-Anzeigen und Verhaltensableitungen an den jeweils aktuellen Acting-Lead; dadurch wechseln Lead-Stern, Ad-hoc-/Koordinationsentscheidungen und Fireteam-Karten synchron mit.
- Offene Punkte: keine dauerhafte Meta-Persistenz der Missions-Nachfolge ausserhalb der laufenden Mission und keine separate manuelle Lead-Uebersteuerung.
- Risiken: die Lead-Synchronisierung bleibt bewusst missionslokal und haengt an den bestehenden Friendly-/Respawn-Pfaden; spaetere Netzwerk- oder Meta-Synchronisierung sollte diesen Vertrag explizit uebernehmen statt parallele Lead-Wahrheiten aufzubauen.
- Naechster Schritt: TASK_106 auf dem jetzt stabilen Lead-/Respawn-Pfad fuer verzoegerte Runtime-Aktivierung und LZ-Insertion aufsetzen.

### TASK_038 - Fireteam-Aufteilung
- Status: implementiert
- Stand: `TestUnit` traegt jetzt eine eigene `fireteam_id`, spiegelt diese in `UnitRuntimeStatus` und zeigt sie in der Missions-Testszene als kleinen farbigen `BLUE`-/`GOLD`-Text direkt neben dem bestehenden Statuslabel an. `MissionTestSetup` weist Alpha und Bravo fest `blue` sowie Charlie fest `gold` zu, ohne die bestehende Driver- oder Hotkey-Logik im `MissionTacticalSandboxController` umzubauen.
- Offene Punkte: keine dynamische Fireteam-Zuweisung zur Laufzeit, keine weitergehende Fireteam-UI und noch keine Nutzung der neuen Fireteam-Daten ausserhalb der bestehenden Testszene und des Runtime-Status.
- Risiken: die Fireteam-Wirkung bleibt fuer diesen Slice bewusst auf die bestehende Auswahl-/Driver-Filterung plus sichtbare Unit-Zuordnung begrenzt; spaetere Fireteam-Mechaniken muessen die neue Datenbasis explizit nutzen, statt Logik still in UI oder Szene-Glue zu verstecken.
- Naechster Schritt: mit TASK_039 die bestehende Phasenwahl in eine kleine echte Laufzeitwirkung ueberfuehren, ohne die Commander-/Driver-Architektur zu verbiegen.

### TASK_039 - Phasen-Wirkung
- Status: implementiert
- Stand: `CommanderCommand`, `UnitCommand` und `UnitRuntimeStatus` tragen jetzt eine kleine echte Phasenwirkung. `RuntimeLeader` leitet `APPROACH`, `ASSAULT` und `HOLD` in minimale Unterschiede fuer `fire_status`, `move_speed_factor` und `cover_score` ueber, `SimulationRoot` respektiert den neuen Geschwindigkeitsfaktor autoritativ bei Bewegung, und `TestUnit` zeigt die aktive Phase als kleines zusaetzliches Label direkt an der Unit an.
- Offene Punkte: keine tiefere Combat-Loop-Interpretation jenseits der kleinen Ableitungen, keine erweiterten Rules of Engagement und keine Phase-KI fuer Gegner.
- Risiken: die Wirkung bleibt bewusst klein und datenorientiert; spaetere komplexere Phasenlogik sollte explizit auf den neuen Feldern aufbauen statt versteckte Sonderfaelle in UI oder Drivern zu sammeln.
- Naechster Schritt: den `take`-Befehl an ein echtes Objective mit Capture-Zustand anbinden.

### TASK_040 - Take-Befehl und Objective
- Status: implementiert
- Stand: ein neues `ObjectiveStatus`-Datenmodell haengt jetzt am `SimulationRoot`; pro Tick wird autoritativ geprueft, welche `fit`-Units im Capture-Radius stehen, contested-Zustaende blockieren Fortschritt und bei vollem Fortschritt wechselt der Besitzer. `MissionTestSetup` erstellt den Objective-Zustand aus dem bestehenden `objective_point`-Marker, `take` snappt den Zielmarker auf diesen Punkt, `engage_area` bewegt Units nun auch zum Objective, und ein kleines `MissionObjectiveStatusView` zeigt Besitzer und Capture-Fortschritt direkt an der Szene an.
- Offene Punkte: weiterhin nur ein Objective gleichzeitig, keine komplexere Zonen-Geometrie, keine Gegner-Capture-Orders und keine Besitzer-Boni.
- Risiken: der Objective-Pfad ist bewusst ein einzelner, leichter Vertical-Slice ohne grosse Objective-Architektur; spaetere Missionssysteme sollten den Datenvertrag explizit erweitern statt ihn still im Szenen-Glue wachsen zu lassen.
- Naechster Schritt: aus dem neuen Objective-Zustand eine echte Sieg-/Niederlagenlogik fuer den bestehenden Debrief-Flow ableiten.

### TASK_041 - Siegbedingung
- Status: implementiert
- Stand: `MissionCombatLoopDriver` unterstuetzt jetzt die Siegbedingungstypen `elimination`, `objective_capture` und `objective_defense`, prueft zusaetzlich eine Niederlage bei gleichzeitig komplett nicht mehr `fit`en Friendlies und liefert ein erweitertes `mission_result` mit `result`, `win_condition_type`, `objective_captured` und `duration_seconds`. Die Missions-Testszene nutzt standardmaessig `objective_capture`, und `MetaLayerFlow` plus `DebriefTestScreen` reichen das reichere Ergebnis bis in den bestehenden Debrief-/FOB-Rueckfluss weiter.
- Offene Punkte: keine mehrstufigen Missionsziele, keine Zeitlimit-Niederlage und keine gegnerische Objective-Logik.
- Risiken: die Missionsauswertung bleibt bewusst klein und testszenenbezogen; spaetere Kampagnen- oder Multi-Objective-Systeme muessen darauf explizit aufbauen statt den Combat-Driver schleichend zu ueberladen.
- Naechster Schritt: die bestehende Respawn-Logik fuer den Spieler sichtbar machen.

### TASK_042 - Respawn-Timer-Anzeige
- Status: implementiert
- Stand: `RespawnManager` stellt jetzt `get_pending_respawns()` und `get_remaining_time(unit_id)` bereit. Ein neues `MissionRespawnOverlay` zeigt in der Missions-Testszene aktuell laufende Respawns unter dem Command-Feedback an, waehrend `TestUnit` bei `respawning` den verbleibenden Countdown direkt im Unit-Statuslabel anzeigt. `MissionTestSetup` verdrahtet dazu den `RespawnManager` explizit an die Units.
- Offene Punkte: keine Queue-Ansicht, keine Fortschrittsbalken, keine Spawn-Punkt-Auswahl und keine groessere HUD-Struktur.
- Risiken: die Anzeige bleibt bewusst ein kleiner Polling-Overlay-Pfad fuer die Testszene; spaetere echte HUD-Systeme sollten diese Minimalanzeige explizit ersetzen statt sie still auszubauen.
- Naechster Schritt: den Vertical Slice gegen die naechsten Gegner-Tasks absichern und erst dann weitere Gegnerlogik aufsetzen.

### TASK_043 - Einfache Gegner-Positionierung
- Status: implementiert
- Stand: `MissionCombatLoopDriver` hat jetzt einen kleinen Enemy-Vormarschpfad mit `enemy_advance_enabled`, `enemy_advance_speed_factor` und `enemy_engage_distance`. `fit`e, aktive Enemy-Units enqueueen pro Tick ueber `SimulationRoot` einen `move_to_position`-Command Richtung Objective, stoppen aber bei LOS-Kontakt in Kampfdistanz und bleiben damit im bestehenden Combat-Loop feuersauber eingebettet. Nach Respawn oder Wellenaktivierung greifen dieselben Regeln automatisch erneut.
- Offene Punkte: keine Pfadplanung, keine Deckungssuche, keine Gegner-Befehlskette und keine feinere Zielwahl ueber den bestehenden Contact-Check hinaus.
- Risiken: die Bewegung bleibt bewusst ein sehr einfacher Objective-Marsch; spaetere KI- oder Terrain-Systeme muessen diesen Slice explizit ersetzen oder erweitern, statt Logik schleichend im Combat-Driver anzusammeln.
- Naechster Schritt: auf eingehenden Schaden eine kleine Repositionierung fuer Enemies aufsetzen.

### TASK_044 - Gegner-Reaktion auf Kontakt
- Status: implementiert
- Stand: `MissionCombatLoopDriver` reagiert jetzt auf eingehenden Schaden von Enemy-Units mit einer kleinen Repositionierung ueber den bestehenden `SimulationRoot.enqueue_command()`-Pfad. Die Zielposition wird bevorzugt weg vom bekannten Angreifer aufgebaut, faellt sonst auf einen zufaelligen Offset zurueck und ist ueber `enemy_reposition_*`-Exports fuer Distanz, Cooldown und Bewegungsgeschwindigkeit klein konfigurierbar.
- Offene Punkte: keine echte Deckungssuche, keine Retreat-Logik, keine Gruppenreaktion und keine taktische Bewertung des neuen Standorts.
- Risiken: der Reaktionspfad ist bewusst ein lokaler, eventgetriebener Minimal-Offset; spaetere Gegnerlogik sollte darauf explizit aufbauen statt viele Sonderfaelle in den Hit-Callback zu schieben.
- Naechster Schritt: Enemy-Spawns in einfache Wellen staffeln, damit die Mission zeitlich getragen wird.

### TASK_045 - Gegner-Wellen
- Status: implementiert
- Stand: ein neuer `EnemyWaveController` unter `res://scripts/tests/enemy_wave_controller.gd` staffelt Enemy-Units jetzt in konfigurierbare Wellen mit `wave_count`, `units_per_wave`, `wave_delay_seconds` und `first_wave_delay_seconds`. Noch nicht gestartete Units bleiben unsichtbar und aus dem `UnitRegistry` abgemeldet; beim Wellenstart werden sie an ihre Spawn-Position gesetzt, sichtbar, wieder registriert und vom bestehenden Enemy-Vormarsch uebernommen. Ein kleines Szenenlabel zeigt `WAVE x/y`, und der `MissionCombatLoopDriver` laesst Elimination-Sieg erst nach letzter Welle und ohne ausstehende Enemy-Respawns zu.
- Offene Punkte: keine dynamische Wellenzusammenstellung, keine verschiedenen Gegnertypen, keine Spawn-Richtungswahl und kein eigener Reinforcement-UI-Flow ausser der kleinen Szenenlesbarkeit.
- Risiken: der Wave-Controller bleibt bewusst ein leichter Testszenen-Node; spaetere Missions- oder Encounter-Systeme sollten ihn explizit ablösen oder erweitern statt Wellenlogik verteilt ueber Setup, Combat-Driver und Szene zu verstecken.
- Naechster Schritt: individuelle Skill-Werte an Units haengen, bevor diese das Gameplay beeinflussen.

### TASK_046 - Unit-Skill-Werte
- Status: implementiert
- Stand: `UnitSkills` unter `res://scripts/npc/unit_skills.gd` formalisiert jetzt `accuracy`, `speed`, `leadership` und `toughness` mit kleinem Dictionary-Roundtrip. `TestUnit` traegt dazu exportierte Skillwerte, baut daraus beim Initialisieren ein `UnitSkills`-Objekt und zeigt einen kompakten Skill-Hinweis direkt im bestehenden Debug-Label an. `MissionTestSetup` weist Friendlies und Enemies ueber `UnitRosterPresets` feste, leicht unterschiedliche Presets zu.
- Offene Punkte: noch keine Laufzeitentwicklung der Werte, keine Balancing-Arbeit und noch keine direkte Leadership-Wirkung.
- Risiken: die Skills sind bewusst kleine statische Unit-Daten; spaetere Progression oder Balancing-Systeme muessen diese Datenbasis explizit erweitern statt sie still in Szene-Properties zu zerstreuen.
- Naechster Schritt: die neuen Skillwerte in Trefferchance, Bewegung und Schadensreduktion einspeisen.

### TASK_047 - Skill-Wirkung im Combat
- Status: implementiert
- Stand: `SimulationRoot` leitet Trefferchance, Bewegungstempo und Schadensreduktion jetzt direkt aus den individuellen Unit-Skills ab. `accuracy` skaliert die `hit_chance` der angreifenden Unit mit Clamp auf 0.95, `speed` multipliziert den bestehenden `move_speed_factor`, und `toughness` reduziert den finalen Schaden nach einer einfachen, nachvollziehbaren Formel. `leadership` wird weiter mitgefuehrt, hat in diesem Slice aber noch keine eigene Wirkung.
- Offene Punkte: kein tieferes Balancing, keine situationsabhaengigen Modifikatoren und keine Fuehrungsqualitaets-Logik.
- Risiken: die Formeln sind bewusst einfach und testszenenfreundlich; spaetere Kampf- oder AI-Systeme sollten klare Erweiterungsschritte waehlen statt diese Minimalformeln still zu ueberladen.
- Naechster Schritt: einfache Persoenlichkeitsmerkmale auf die Skillbasis aufsetzen.

### TASK_048 - Einfache Persoenlichkeitsmerkmale
- Status: implementiert
- Stand: `UnitTrait` unter `res://scripts/npc/unit_trait.gd` liefert jetzt eine kleine Trait-Factory fuer `aggressive`, `cautious`, `steady`, `reckless` und `calm` samt Skill-Modifikatoren und Kurz-Tags. `TestUnit` kann ueber `trait_ids` bis zu zwei Traits laden, die effektiven Skills beim Initialisieren anpassen und ihre Tags im Debug-Label anzeigen. `UnitRosterPresets` vergibt dazu unterschiedliche Trait-Kombinationen an die Friendly-Units; Enemies bleiben im V1-Pfad traitlos.
- Offene Punkte: keine sozialen Beziehungen, keine Synergie-Effekte, keine Laufzeitveraenderung und kein Trait-Balancing.
- Risiken: Traits bleiben bewusst ein leichter Skill-Modifikator ohne eigene Gameplay-Subsysteme; spaetere Charakter- oder Squad-Systeme muessen diese kleine Datenbasis explizit weiterdenken statt versteckte Nebenlogik in `TestUnit` zu sammeln.
- Naechster Schritt: die neuen Unit-Details in der Homebase sichtbar machen.

### TASK_049 - Heimatbasis: Unit-Uebersicht mit Skills und Traits
- Status: implementiert
- Stand: `HomebaseTestScreen` zeigt in der Checkbox-Liste jetzt pro verfuegbarer Unit eine kompakte Detailzeile mit Skill-Kurzform und Trait-Tags. Die Daten werden bewusst aus `TestUnit`-Instanzen im Szenenbaum gelesen: dafuer baut der Screen einen kleinen unsichtbaren Preview-Root mit `TestUnit`-Kindern aus den `UnitRosterPresets` auf und liest daraus die gleichen Summary-Methoden wie in der Missionsszene. `MetaLayerFlow` bezieht die verfuegbaren Homebase-Units jetzt direkt aus denselben Presets.
- Offene Punkte: keine Sortierung, keine Vergleichsansicht, keine tiefe Detailseite und keine optionale Farbcodierung.
- Risiken: der Homebase-Pfad bleibt bewusst eine kleine Listenlesbarkeit ohne neue Registry oder Persistenzschicht; spaetere Meta-UI sollte diesen Preview-Ansatz explizit ersetzen, wenn ein echtes Daten-/Roster-System eingefuehrt wird.
- Naechster Schritt: den Slice lokal gegen Mission und Meta-Layer pruefen und dann fuer die naechsten Netzwerk-/Terrain-Aufgaben stabilisieren.

### TASK_050 - Server-autoritativer SimulationRoot
- Status: implementiert
- Stand: `SimulationRoot` besitzt jetzt `is_server_authoritative`, eine RPC-faehige `request_command()`-Einspeisung, Peer-zu-Team-Mapping und einen vorbereiteten Tick-Broadcast. Im Multiplayer-Modus verarbeitet nur noch der Server Commands und Effects lokal; Clients speichern den letzten Server-Snapshot und erhalten zusaetzlich zuverlaessige Vital-Updates. Ohne aktiven Peer oder bei deaktivierter Authority bleibt der bisherige Singleplayer-Pfad unveraendert.
- Offene Punkte: keine Latenz-Kompensation, keine Ownership-Uebertragung und keine generische Netzwerk-Abstraktionsschicht ausserhalb dieses Testslices.
- Risiken: der Authority-Pfad bleibt bewusst klein und direkt an der Missions-Testszene orientiert; spaetere groessere Multiplayer-Systeme sollten den Datenvertrag explizit erweitern, statt versteckte Sonderlogik neben `SimulationRoot` wachsen zu lassen.
- Naechster Schritt: eine minimale Host/Join-Lobby auf die neue Autoritaetsbasis setzen.

### TASK_051 - Host/Join mit Testteams
- Status: implementiert
- Stand: unter `res://scenes/tests/lobby_test.tscn` gibt es jetzt einen kleinen `LobbyTestScreen` mit `Host`, `Join` und host-only `Start Mission`. Host und Joiner verbinden sich lokal ueber `ENetMultiplayerPeer` auf Port `7777`, sehen denselben Status und starten dieselbe Missionsszene; `SimulationRoot` wird dabei server-autoritativ initialisiert. Bei Disconnect oder Verbindungsfehler wird sauber in die Lobby zurueckgekehrt.
- Offene Punkte: nur localhost/LAN-V1, keine Teamauswahl, kein Matchmaking, kein Session-Browser und kein reconnect.
- Risiken: die Lobby ist bewusst ein sehr kleiner Testszenen-Flow ohne Meta-Layer-Integration; spaetere echte Multiplayer-Menues sollten diesen Pfad explizit ersetzen statt ihn still auszubauen.
- Naechster Schritt: die bestehende Befehlskette ueber RPC an den Server umleiten.

### TASK_052 - Befehlsuebertragung ueber Netzwerk
- Status: implementiert
- Stand: `MissionCommandFlowDriver` schickt `UnitCommand`-Dictionaries im server-autoritativen Modus jetzt nicht mehr direkt an `enqueue_command()`, sondern an `SimulationRoot.request_command()` bzw. per `rpc_id(1, ...)` an den Host. `SimulationRoot` validiert Command-Typ, `unit_id` und Team-Zugehoerigkeit gegen das Peer-Mapping. `MissionCombatLoopDriver`, `RespawnManager` und `EnemyWaveController` fuehren ihre autoritativen Simulationsteile im Multiplayer nur noch auf dem Server aus; der Joiner bleibt in V1 Beobachter und bekommt keine lokale Command-Eingabe mehr.
- Offene Punkte: noch kein zweiter aktiver Commander, keine komplexere Autorisierung und keine Client-Prediction.
- Risiken: die Servervalidierung bleibt bewusst schlank und testszenenbezogen; spaetere PvP- oder Koop-Ausbaustufen sollten diese Checks explizit verstaerken statt sie ad hoc in UI oder Drivern zu verteilen.
- Naechster Schritt: den autoritativen Zustand sichtbar auf den Joiner spiegeln.

### TASK_053 - Synchronisierte Spielzustandsanzeige
- Status: implementiert
- Stand: `SimulationRoot` broadcastet jetzt pro Tick einen kompakten Snapshot fuer aktive Units (`unit_id`, Position, Runtime-/Vital-Kernstatus) plus Objective-Fortschritt an Clients; `TestUnit` kann diese Remote-Snapshots direkt anwenden und zeigt dadurch Bewegungen, Vital-Status und Respawn-Momente auch als Joiner korrekt an. `MissionCombatLoopDriver` synchronisiert Missionsresultat und Event-Feedback (`HIT`, `DOWN`, `BLEEDOUT`, `RESPAWNING`, Wellenhinweise) per RPC, sodass beide Peers denselben Debrief sehen.
- Offene Punkte: keine Snapshot-Pufferung, keine Lag-Kompensation, keine FoW-Differenzierung und keine feingranulare Kontakt-/Linien-Synchronisation.
- Risiken: der Sync bleibt bewusst ein einfacher V1-Snapshot-Pfad; spaetere groessere Multiplayer-Loops sollten diesen Datenstrom explizit weiterentwickeln statt mit immer mehr Einzelfeldern zu ueberladen.
- Naechster Schritt: nach dem Multiplayer-Prototyp den Terrain-Block gemaess Roadmap wieder lokal und datenorientiert ausbauen.

### TASK_054 - Terrain-Tile-Datenmodell und Registry
- Status: implementiert
- Stand: `TerrainTileData` unter `res://scripts/terrain/terrain_tile_data.gd` und `TerrainRegistry` unter `res://scripts/terrain/terrain_registry.gd` bilden jetzt ein kleines datenbasiertes Terrain-System mit `walkable`, `blocks_los`, `cover_value`, `height_level` und `surface_type`. Die Missions-Testszene besitzt einen eigenen `TerrainRegistry`-Node, und `MissionTestSetup` liest die bestehenden 64 Iso-Tiles aus `MapRoot/Terrain`, konfiguriert die Iso-Grid-Konvertierung passend zur bestehenden Karte und registriert alle Tiles mit Default- bzw. Szenenwerten.
- Offene Punkte: noch kein Editor fuer Terrain-Daten, keine separate Tile-Registry ueber mehrere Karten und keine Gameplay-Wirkung ausser den folgenden Terrain-Tasks.
- Risiken: die Grid-Konvertierung ist bewusst auf die bestehende 8x8-Iso-Testkarte zugeschnitten; spaetere Kartenvarianten sollten diese kleine Konfiguration explizit erweitern statt still neue Koordinatenannahmen in Mission-Glue zu streuen.
- Naechster Schritt: die neuen Tile-Daten fuer Bewegung ueber A*-Pfadsuche auswerten.

### TASK_055 - Walkability und einfaches A*-Pathfinding
- Status: implementiert
- Stand: `TerrainPathfinder` unter `res://scripts/terrain/terrain_pathfinder.gd` fuehrt jetzt eine kleine A*-Suche auf dem Iso-Grid aus und beruecksichtigt `walkable`, Hoehenunterschiede sowie vorbereitete Surface-Kosten. `SimulationRoot` nutzt die `TerrainRegistry` jetzt optional fuer `move_to_position`: wenn Terrain-Daten vorhanden sind, wird ein Wegpunktpfad aufgebaut und tile-basiert abgegangen; ohne Registry bleibt der bisherige Geradlinien-Fallback erhalten. `MissionTestSetup` markiert einige Tiles als nicht begehbar, damit der Pfad sichtbar um die Blocker fuehrt.
- Offene Punkte: keine lokale Kollisionsvermeidung zwischen Units, keine Pfad-Neuberechnung bei dynamischen Aenderungen und keine feinere Optimierung ueber den kleinen 64-Tile-Testfall hinaus.
- Risiken: der Pfad wird bewusst klein und command-lokal gespeichert; spaetere groeßere Karten oder dynamische Hindernisse sollten einen expliziten Recompute-Pfad bekommen statt diese V1-Logik still zu ueberladen.
- Naechster Schritt: Sichtlinien an die Terrain-Tiles binden.

### TASK_056 - LOS ueber Terrain-Tiles
- Status: implementiert
- Stand: `LineOfSightSystem` unterstuetzt jetzt optionale Terrain-Registries und prueft per einfachem Tile-Stepping, ob `blocks_los`-Tiles zwischen Quelle und Ziel liegen. Dabei wird die vorbereitete Hoehenregel direkt beruecksichtigt: hoehere Einheiten koennen ueber niedrigere Hindernisse hinwegsehen. `MissionCombatLoopDriver` gibt die `TerrainRegistry` an alle LOS-Aufrufe weiter, sodass Contact und Enemy-Hold-Checks auf der Testkarte jetzt von Terrain-Blockern beeinflusst werden.

### Wall-Overlay-System im Map-Editor
- Status: implementiert
- Stand: Der Map-Editor unterstuetzt jetzt individuelle Wand- und Eckenstuecke als Overlay-Sprites ueber dem Terrain.

#### Tile-Katalog (`data/terrain_tile_catalog.json`)
9 Eintraege: `ground_flat`, 4 gerade Mauern (`wall_straight_se/sw/ne/nw`), 4 Ecken (`wall_corner_se/sw/ne/nw`).
Wand-Tiles haben kein eigenes `texture_path` — der Boden zeigt `terrain_SW.png`, die Mauer wird als Overlay daruebergelegt.

#### Namenskonvention
- **Gerade Mauern**: `wall_straight_XX` — XX ist die Laufrichtung der Mauer (SE = Mauer laeuft von NW nach SE).
- **Ecken**: `wall_corner_XX` — XX ist die Grid-Richtung, `display_name` zeigt die visuelle Position:
  - `wall_corner_se` = "Ecke Ost" (rechts)
  - `wall_corner_sw` = "Ecke Sued" (unten)
  - `wall_corner_ne` = "Ecke Nord" (oben)
  - `wall_corner_nw` = "Ecke West" (links)

#### Kenney-Sprite-Zuordnung
Die Kenney `corridor_wallCorner_XX.png`-Dateien benennen die Innenseite der Kurve. Im Code werden sie daher gegenlaefig gemappt:
- `wall_corner_se` -> `WALL_CORNER_NW` (corridor_wallCorner_NW.png)
- `wall_corner_sw` -> `WALL_CORNER_NE` (corridor_wallCorner_NE.png)
- `wall_corner_ne` -> `WALL_CORNER_SW` (corridor_wallCorner_SW.png)
- `wall_corner_nw` -> `WALL_CORNER_SE` (corridor_wallCorner_SE.png)

#### Sprite-Platzierung
- Alle Sprites: `centered = false`, Position = `world_position - KENNEY_DIAMOND_CENTER`
- `KENNEY_DIAMOND_CENTER = Vector2(256, 315)` — Diamant-Mitte aller Kenney 512x512-Sprites
- `WallContainer` hat `y_sort_enabled = true` und `z_index = -13` — suedlichere Mauern ueberdecken noerdlichere korrekt

#### Tile-Datenfelder — aktuelle Semantik und Grenzen

| Feld | Typ | Aktuell | Gameplay-Wirkung |
|------|-----|---------|-----------------|
| `surface_type` | String | Pro Tile, nicht pro Objekt | Beeinflusst Bewegungsgeschwindigkeit und Pfadkosten (`road`=1.4x, `sand`=0.6x, `rock`=0.8x) |
| `walkable` | bool | Ganzes Tile blockiert | Pathfinder lehnt Tile komplett ab — keine Richtungsinformation |
| `blocks_los` | bool | Ganzes Tile blockiert | LOS-System prueft pro Tile — keine Richtungsinformation |
| `cover_value` | int 0-100 | Pro Tile | Combat: -0.35 Hit-Chance fuer Ziel, +0.05 fuer Angreifer, -0.2 Schaden (max 80) |
| `height_level` | int 0-2 | Terrainhoehe (Gelaende) | Pathfinding: max 1 Level Differenz bei Cliff, +0.5 Kosten pro Level. Combat: +0.1 Accuracy-Bonus pro Level ueber Ziel |
| `object_height` | int 0-3 | Objekthoehe (Mauer, Fels) | LOS: Blocker-Hoehe = `height_level + object_height`. Pathfinding: nicht verwendet |
| `edge_type` | String | "cliff" oder "slope" | Cliff: blockiert Bewegung bei height_diff > 1, Overlay mit `terrain_sideCliff_*.png`. Slope: immer begehbar, +1.0 Kosten pro Level, Overlay mit `terrain_side_*.png` |

#### Objekt-Typen im Katalog

| type_id | display_name | object_height | cover | blocks_los | Beschreibung |
|---------|-------------|--------------|-------|------------|-------------|
| `rock_small` | Fels klein | 1 | 30 | nein | Kleiner Fels, bietet Deckung aber blockiert nicht LOS |
| `rock_large` | Fels gross | 2 | 50 | ja | Grosser Fels, blockiert LOS und bietet starke Deckung |
| `wall_straight_*` | Mauer XX | 2 | 0 | ja | Gerade Mauerstuecke |
| `wall_corner_*` | Ecke XX | 2 | 0 | ja | Eckverbindungen |

**Bekannte Design-Luecken:**
- `walkable` und `blocks_los` sind nicht richtungsabhaengig. Eine Mauer SW blockiert aktuell das ganze Tile statt nur die NW-SE-Kante. Fuer feingranulare Wandmechanik muesste ein edge-basiertes System (`blocked_edges: ["nw-se"]`) eingefuehrt werden.
- `surface_type` beschreibt aktuell den Boden unter der Mauer (z.B. "rock"), nicht das Mauerobjekt selbst.
- Offene Punkte: keine Raycasts, keine partielle Deckung, keine feingranulare Sichtkanal- oder FOW-Regel pro Spieler.
- Risiken: der LOS-Pfad bleibt bewusst grob tile-basiert; spaetere komplexere Hindernisse oder echte FoW-Systeme muessen diesen einfachen Sichtpfad explizit erweitern statt ihn nebenbei auszutauschen.
- Naechster Schritt: Terrain-Cover mit der bestehenden Command-/Phase-Coverlogik kombinieren.

### TASK_057 - Cover aus Terrain-Tiles
- Status: implementiert
- Stand: `SimulationRoot` addiert jetzt Terrain-Cover vom Tile der Ziel-Unit auf den bestehenden `cover_score` aus Command und Phase und klemmt den effektiven Cover-Wert auf maximal 80. `MissionTestSetup` versieht mehrere Tiles mit leichter oder mittlerer Deckung, und `TestUnit` zeigt den aktuellen effektiven Deckungswert direkt im Debug-Label als `COV:x` an.
- Offene Punkte: keine richtungsabhaengige Deckung, keine zerstoerbaren Cover-Objekte und keine Deckungssuche-KI.
- Risiken: Terrain-Cover bleibt bewusst symmetrisch und tile-zentriert; spaetere echte Deckungssysteme sollten diesen V1-Wert explizit differenzieren statt Command- und Terrain-Cover still zu vermischen.
- Naechster Schritt: Hoehenstufen auch fuer Bewegung und Trefferqualitaet auswerten.

### TASK_058 - Hoehenstufen
- Status: implementiert
- Stand: die Testkarte besitzt jetzt mehrere Tiles mit `height_level` 1 und 2; `MissionTestSetup` moduliert diese Tiles leicht heller, damit Hoehenzonen sichtbar bleiben. `TerrainPathfinder` blockiert Bewegungen ueber Cliffs mit Hoehenunterschied > 1, `LineOfSightSystem` nutzt Hoehen fuer Blockadeentscheidungen, und `SimulationRoot` gibt Angreifern auf hoeherem Terrain einen Accuracy-Bonus bzw. bei Hoehennachteil eine kleine Penalty. `TestUnit` zeigt die aktuelle Hoehenstufe als `H:x` direkt im Debug-Label.
- Offene Punkte: keine Rampen-/Treppenlogik, keine echte Iso-Stack-Darstellung und keine weiteren Hoehenfolgen wie Fallschaden.
- Risiken: die Hoehenzonen bleiben bewusst eine leichte 2D-Modulation ueber dem bestehenden Kartensprite; spaetere Karten sollten diese Datenbasis behalten, statt Hoehen still in separate Spezialpfade aufzuteilen.
- Naechster Schritt: verschiedene Oberflaechentypen auf Bewegung und Pfadkosten anwenden.

### TASK_059 - Strassen und Oberflaechen
- Status: implementiert
- Stand: `TerrainTileData` kennt jetzt die Oberflaechentypen `ground`, `road`, `sand` und `rock` samt Speed- und Pfadkostenfaktoren. `SimulationRoot` multipliziert das Bewegungstempo mit dem aktuellen Surface-Speed-Faktor des Tiles unter der Unit, `TerrainPathfinder` bevorzugt dadurch Strassen und meidet Sand oder Fels, und `MissionTestSetup` markiert mehrere Strassen-, Sand- und Felszonen mit passender Farbmodulation direkt auf der Testkarte. `TestUnit` zeigt den aktuellen Surface-Code samt Speed-Faktor, z.B. `RD:1.4`, im Debug-Label.
- Offene Punkte: keine Audio-/Sichtbarkeitsfolgen, keine fahrzeugspezifischen Terrain-Regeln und keine dynamischen Oberflaechenveraenderungen.
- Risiken: die Oberflaechenwirkung bleibt bewusst ein einfacher Bewegungs- und Kostenmodifikator; spaetere Systeme fuer Wetter, Fahrzeuge oder Spezialeinheiten sollten diese Daten explizit erweitern statt neue, parallele Terrain-Kategorien einzufuehren.
- Naechster Schritt: den Terrain-Slice lokal stabil halten und erst danach den spaeteren Multiplayer-Block gemaess Roadmap angehen.


### TASK_060 - Terrain-Daten als JSON-Datei
- Status: implementiert
- Stand: `TerrainMapData` unter `res://scripts/terrain/terrain_map_data.gd` laedt und speichert Terrainkarten unter `res://maps/` als JSON-Root mit `map_name`, `grid_size`, `tile_size`, `grid_origin` und serialisierten Tile-Eintraegen. Beim Laden werden die JSON-Daten in `TerrainTileData`-Instanzen ueberfuehrt; mit `create_empty(...)` existiert zusaetzlich ein kontrollierter Default-Pfad fuer neue Karten.
- Offene Punkte: keine separate Schema-Versionierung oder Migrationslogik fuer aeltere Kartenformate.
- Risiken: `TerrainMapData` ist inzwischen gemeinsamer Datenvertrag fuer Editor, Mission und Meta-Map; spaetere JSON-Erweiterungen duerfen deshalb keine stillen Breaking Changes fuer bestehende Karten einfuehren.
- Naechster Schritt: den JSON-Vertrag kontrolliert im Editor und in `MissionTestSetup` konsumieren.

### TASK_061 - Map-Editor-Szene: Tile-Auswahl und Anzeige
- Status: implementiert
- Stand: `res://scenes/editor/map_editor.tscn` plus `res://scripts/editor/map_editor.gd` bilden eine eigenstaendige Editor-Szene mit Kartenaufbau aus `TerrainMapData`, `Camera2D`-basierter Pan-/Zoom-Steuerung, Tile-Auswahl per Klick, visueller Outline sowie seitlichem Property- und Palette-Panel.
- Offene Punkte: keine separate read-only-Ansicht; spaetere Workflow- und Palette-Erweiterungen laufen in den Folgetasks.
- Risiken: die Szene bleibt bewusst editorlokal; Auswahl- und Anzeigezustand duerfen nicht in Runtime- oder Missionspfade auslaufen.
- Naechster Schritt: editierbare Tile-Properties auf denselben lokalen Map-Zustand legen.

### TASK_062 - Map-Editor: Tile-Properties bearbeiten
- Status: implementiert
- Stand: Das Property-Panel kann die Terrain-Eigenschaften des selektierten Tiles lokal auf `TerrainMapData` anwenden und die Visualisierung sofort aktualisieren; dazu gehoeren `walkable`, `blocks_los`, `cover_value`, `height_level`, `surface_type` und spaeter erweitert auch `edge_type`. Ein kleiner Undo-Pfad fuer den zuletzt gesicherten Tile-Zustand ist vorhanden.
- Offene Punkte: kein ausgebauter Mehrschritt-Undo-Stack und keine grossen Massenoperationen jenseits spaeterer Brush-/Selection-Erweiterungen.
- Risiken: Property-Patches bleiben bewusst editorlokal; spaetere Runtime-Regeln muessen weiterhin aus den serialisierten Tile-Daten statt aus UI-Zustand abgeleitet werden.
- Naechster Schritt: Speichern/Laden und New-Workflow auf denselben lokalen Zustand aufsetzen.

### TASK_063 - Map-Editor: Speichern und Laden
- Status: implementiert
- Stand: Der Editor kann Karten ueber `TerrainMapData.save_to_file()` speichern, ueber FileDialogs laden, neue Karten erzeugen und einen Dirty-Status im Titel fuehren; `Save`, `Load` und `New` sind an die bestehende Editor-UI angebunden, inklusive Warn-Dialog bei ungesicherten Aenderungen. Spaetere Workflow-Politur hat diesen Pfad um `Save As` und frei waehlbare Kartengroessen erweitert.
- Offene Punkte: keine Versionsverwaltung oder komplexe Dateibrowser-Logik ueber den lokalen Ressourcenpfad hinaus.
- Risiken: der Dateipfad bleibt bewusst editorgetrieben; spaetere Tooling- oder Import-Pipelines sollten denselben `TerrainMapData`-Vertrag nutzen statt parallele Speicherrouten einzufuehren.
- Naechster Schritt: `MissionTestSetup` kontrolliert auf denselben JSON-Load-Pfad umstellen.

### TASK_064 - MissionTestSetup: Terrain aus JSON laden
- Status: implementiert
- Stand: `MissionTestSetup` nutzt `map_file_path`, laedt Terrain ueber `TerrainMapData.load_from_file(...)`, konfiguriert die `TerrainRegistry` aus JSON-Metadaten und registriert alle Tiles aus der Karte. Wenn keine gueltige Datei vorliegt, bleibt der Hardcode-Pfad als Fallback aktiv; sichtbares Kartenrendering und Marker-Spiegelung greifen auf denselben geladenen Map-Zustand zu.
- Offene Punkte: der Hardcode-Fallback bleibt nur fuer Alt- oder Fehlerszenarien erhalten und sollte nicht wieder zum primaeren Kartenpfad werden.
- Risiken: solange Fallback und JSON-Pfad parallel existieren, muessen Terrain-Aenderungen bewusst im JSON-Vertrag landen, damit Editor und Mission nicht erneut auseinanderdriften.
- Naechster Schritt: darauf die Editor-Workflow-Slices und den spaeteren gemeinsamen Terrain-Renderer aufbauen.

### TASK_065 - Tile-Typ-Katalog und Palette
- Status: implementiert
- Stand: `TerrainTileCatalog` unter `res://scripts/terrain/terrain_tile_catalog.gd` laedt Tile-Typ-Definitionen aus `res://data/terrain_tile_catalog.json`. Jeder Typ definiert einmalig `type_id`, `display_name`, `surface_type`, `walkable`, `blocks_los`, `cover_value` und `height_level`. Der Map-Editor zeigt links wieder eine einfache einzelne Liste mit allen verfuegbaren Tile-Typen. Bei Auswahl eines Typs wird automatisch der Brush-Modus aktiviert; Klick auf ein Tile uebertraegt alle Eigenschaften des Typs. Das Property-Panel zeigt bei selektiertem Tile den erkannten Typ-Namen oder `(custom)` an.
- Offene Punkte: keine Typ-Referenz in der Map-JSON (Tiles speichern weiterhin alle Eigenschaften inline), keine benutzerdefinierten Typen zur Laufzeit und kein Tile-Preview in der Palette.
- Risiken: der Katalog ist bewusst ein reiner Editor-Workflow; Runtime-Code hat keinen Katalog-Bezug und bleibt von Inline-Daten abhaengig.
- Naechster Schritt: bei Bedarf Map-JSON auf Typ-Referenzen umstellen und Katalog in Runtime-Loading einbinden.

### TASK_066 - Corridor-Wall Typen, Typ-Texturen und Auto-Cliff
- Status: implementiert
- Stand: Der Tile-Katalog (`terrain_tile_catalog.json`) enthaelt jetzt 14 Tile-Typen mit optionalem `texture_path` (ground, road haben eigene Texturen). Tile-Sprites zeigen die Typ-Textur wenn vorhanden, sonst Fallback mit Modulate-Farbe. Cliff-Overlays (`terrain_sideCliff_SE/SW/NE/NW.png`) werden automatisch an Kanten mit Hoehendifferenz gezeichnet; Cliff-Corner-Pieces an Ecken wo zwei Cliff-Kanten aufeinandertreffen. Wall-Overlays (`corridor_wall_SE/SW/NE/NW.png`) analog fuer Tiles mit `blocks_los=true` an Kanten zu Nicht-Wall-Nachbarn.
- Offene Punkte: Wall- und Cliff-Sprites sind Kenney-Assets die als vertikale Panels designed sind, nicht als ISO-Bodenplatten - die visuelle Passung ist naeherungsweise.
- Risiken: die Overlay-Logik ist eng an 4-Nachbar-Adjazenz gebunden; diagonale oder mehrlagige Overlays braeuchten eine erweiterte Kantenlogik.

### TASK_067 - Fix Map-Editor 64x64 Flat Ground
- Status: implementiert
- Stand: Der Map-Editor ist nicht mehr auf 8x8 begrenzt. Fehlende Karten fallen beim Laden weiterhin auf ein 64x64-Grid mit Zoom 0.3 zurueck. Neue Karten werden dagegen ueber einen Dialog mit frei waehlbarer Breite/Hoehe angelegt; der Dialog startet standardmaessig mit 32x32. `create_empty()` setzt `type_id="ground_flat"` als Default fuer neue Tiles, damit die Palette-Erkennung korrekt funktioniert.
- Offene Punkte: keine.

### TASK_068 - Zoom-Inversion und Auto-Wall-Overlays
- Status: implementiert
- Stand: Zoom-Richtung korrigiert (WHEEL_UP = hineinzoomen, WHEEL_DOWN = herauszoomen). Wall-Overlays werden jetzt korrekt bei `_rebuild_tile_sprites()` und `_refresh_tile_visual()` aktualisiert.
- Offene Punkte: keine.

### TASK_068b - Drag-Painting und Hover-Preview
- Status: implementiert
- Stand: Linksklick-Halten und Ziehen malt durchgehend Tiles im Brush-Modus (`_is_painting` Flag, Motion-Handler). Halbtransparentes Hover-Preview-Sprite zeigt den ausgewaehlten Tile-Typ an der Mausposition, solange Brush aktiv ist.
- Offene Punkte: keine.

### TASK_068c - Gitternetz-Overlay und Himmelsrichtungen
- Status: implementiert
- Stand: Die frueheren per-Tile-Gitterlinien wurden zugunsten einer leichten Checkerboard-Modulation direkt auf den Bodentiles ersetzt. `GridOverlay` dient jetzt nur noch fuer die Kompass-Labels `N/O/S/W` an den vier Kartenextremen; damit bleibt die Iso-Ausrichtung lesbar, ohne viele zusaetzliche Linien- oder `Line2D`-Nodes zu erzeugen. Richtungsmapping: Grid +x=SE, +y=SW (aus der Cliff-Overlay-Logik abgeleitet).
- Offene Punkte: kein separat zuschaltbares Debug-Gitter, keine groessere Grid-HUD-Konfiguration.
- Risiken: die Gitterlesbarkeit haengt jetzt an Tile-Modulation und Kontrast der Bodentexturen; spaetere Theme- oder Texture-Wechsel muessen das explizit mitpruefen.
- Naechster Schritt: nur bei Bedarf ein optional zuschaltbares Debug-Gitter ergaenzen.

### Fix - Cliff/Wall Overlay Separation und Corner-Replacement
- Status: implementiert
- Stand: Wall-Tiles (blocks_los) bekommen nur noch Wall-Overlays, keine Cliff-Overlays. Cliff-Kanten werden nicht zu Wall-Nachbarn gezeichnet. Corner-Pieces ersetzen die beiden geraden Panels (Wall und Cliff) statt sich darüberzustapeln. Drag-Painting funktioniert jetzt ohne vorherige Tile-Selektion (Guard von `_has_selected_tile()` auf `_has_selected_type()` geaendert).
- Offene Punkte: Wall-/Cliff-Corner-Zuordnung (welches Corner-Piece an welcher Ecke) muss visuell geprueft und ggf. korrigiert werden.
- Naechster Schritt: Wall-Richtungsmapping anhand der tatsaechlichen Sprite-Orientierung verifizieren und ggf. korrigieren.

### Edge-Type System (Cliff vs Slope)
- Status: implementiert
- Stand: Jedes Tile hat ein `edge_type` Feld (`cliff`, `slope`, `none`, Default: `cliff`). Im Map-Editor ist das ueber das `Kante:`-Dropdown als `Cliff`, `Hang` oder `Keine` waehlbar. Cliffs blockieren Bewegung bei `height_diff > 1` und rendern `terrain_sideCliff_*.png`. Slopes bleiben begehbar, kosten mehr und nutzen die grossen `terrain_rampLarge_*.png`-Sprites. `none` unterdrueckt die Kanten-Visualisierung komplett. Die Palette enthaelt zusaetzlich gerichtete Cliff- und Rampen-Typen fuer `SE`/`SW`/`NE`/`NW`.
- Offene Punkte: Inner-Corner-Pieces (`terrain_sideCornerInner_*.png`) noch nicht implementiert, Side-End-Pieces (`terrain_sideEnd_*.png`) noch nicht implementiert.
- Naechster Schritt: Inner Corners fuer komplexe Huegelformationen implementieren.

### Brush-Size System
- Status: implementiert
- Stand: Im TopBar neben dem Brush-Button ein BrushSize-Dropdown mit 1x1, 3x3 und 5x5. Gilt fuer beide Modi: Brush-Paint (Typ auf Karte malen) und Property-Panel-Aenderungen (Height, Edge-Type, Surface etc. auf selektiertes Tile + Radius anwenden). Radius 0/1/2 entspricht der jeweiligen Brush-Groesse.
- Offene Punkte: Kein visuelles Brush-Preview auf der Karte (nur Hover-Preview fuer 1x1). Undo speichert nur das Center-Tile.
- Naechster Schritt: Optional visuelles Brush-Preview, Multi-Tile-Undo.

### Fix - Map-Roundtrip, Property-Patching und Undo
- Status: implementiert
- Stand: Map-JSON-Roundtrips behalten jetzt auch `edge_type` und `object_height`, damit Speichern/Laden keine Tile-Daten mehr verliert. Echte Property-Aenderungen loesen die starre Typbindung eines Tiles (`type_id = ""`), damit geaenderte Felder korrekt als Custom-Zustand behandelt werden. Undo stellt die zuletzt gesicherte Tile-Version wieder vollstaendig her, inklusive `object_height`.
- Offene Punkte: Undo bleibt weiterhin auf das gespeicherte Center-Tile begrenzt; kein kompletter Mehrfeld- oder Mehrtile-Verlauf.
- Risiken: der Patch bleibt bewusst editorlokal; spaetere Format-Erweiterungen muessen beim Roundtrip explizit mitgezogen werden.
- Naechster Schritt: nur bei Bedarf ein explizites Multi-Tile-Undo und feinere Undo-Historie als eigene Aufgabe schneiden.

### Fix - Wall/Cliff/Ramp Sprite-Zuordnung und Offsets
- Status: implementiert
- Stand: Overlay- und Objekt-Sprites werden jetzt konsistent ueber `KENNEY_DIAMOND_CENTER` positioniert; mehrere Wall-/Corner-Richtungen und Offsets wurden visuell nachkorrigiert. Der Wall-Pfad ist tile-zentriert stabilisiert, Cliff-/Corner-Offsets wurden nachgezogen, und Rampen nutzen fuer ihre vier Richtungen jetzt die grossen `terrain_rampLarge_*`-Sprites statt der generischen Side-Sprites.
- Offene Punkte: Feintuning einzelner Offsets kann bei neuen Tile-Kombinationen weiter noetig sein.
- Risiken: die Zuordnung bleibt an die Kenney-Sprite-Semantik und die aktuelle Iso-Richtungsdefinition gebunden; spaetere Asset-Wechsel muessen diese Mapping-Schicht explizit neu pruefen.
- Naechster Schritt: nur bei Bedarf weitere Corner-/Offset-Korrekturen auf Basis konkreter visueller Problemfaelle ergaenzen.

### TASK_069 – Map-Editor: Auswahl, Save As und Workflow-Polish
- Status: implementiert
- Stand: Der Editor merkt sich die zuletzt gewaehlten Surface- und Kanten-Typen auch ohne aktive Tile-Selektion. `Escape` hebt die aktuelle Palette-Auswahl auf. Ein neuer `Select`-Button neben `Brush` schaltet in einen Auswahlmodus mit Ctrl+LMB-Multiselection und gemeinsamer Outline. `Ctrl+Save` oeffnet `Save As`, `New` oeffnet jetzt einen Groessen-Dialog fuer neue Karten (Default 32x32), und `maps/Test_mission_32x32.json` dient als neue 32x32-Vorlage. Die vier Wand-Ecktypen sind in der Palette jetzt eindeutig als `Mauer Ecke ...` benannt.
- Offene Punkte: keine Drag-Selection, keine Massenoperationen auf bestehende Mehrfachauswahl und kein Multi-Tile-Undo ueber den gesamten Brush-Radius.
- Risiken: die Erweiterungen bleiben bewusst editorlokal; Runtime- und Kartenformat bleiben kompatibel, solange neue UI-Komfortfunktionen keine versteckte Semantik in die gespeicherten Tile-Daten einfuehren.
- Naechster Schritt: nur bei Bedarf Bulk-Edit auf Mehrfachauswahl, Drag-Selection und erweitertes Undo in eigene Tasks schneiden.

### TASK_070 - NPC-Karten-Komponente
- Status: implementiert
- Stand: `MetaUnitProfile` und `MetaUnitProfileBuilder` unter `res://scripts/meta/` bilden jetzt einen kleinen expliziten read-only Datenpfad fuer Meta-UI aus vorhandenen Unit-Identitaetsdaten, inklusive effektiver Skill-Zusammenfassung und Trait-Tags nach derselben Modifikatorlogik wie in `TestUnit`. Eine neue `NPCMetaCard`-Komponente unter `res://scripts/meta/npc_meta_card.gd` plus `res://scenes/meta/components/npc_meta_card.tscn` stellt Name, Skill-Kurzform, Trait-Tags und optional eine Statuszeile dar und unterstuetzt die leichten visuellen Zustaende `neutral`, `selectable`, `selected` und `disabled`. `HomebaseTestScreen` nutzt fuer seine bestehende Textlistenanzeige jetzt bereits den neuen Profilpfad statt unsichtbarer `TestUnit`-Preview-Nodes.
- Offene Punkte: die Karte ist noch nicht in Heimatbasis oder FOB als eigentliche Listen-/Grid-Darstellung eingebaut; es gibt noch keinen Auswahlfokus und keine FOB-spezifische Statusabbildung.
- Risiken: der Profilpfad ist bewusst klein und read-only gehalten; spaetere Heimatbasis-/FOB-Integration sollte denselben Datenvertrag weiterverwenden statt wieder screen-spezifische Sonderpfade aufzubauen.
- Naechster Schritt: in TASK_071 die Heimatbasis von der Checkbox-Textliste auf echte NPC-Karten plus Auswahlfokus umstellen.

### TASK_071 - Heimatbasis: NPC-Karten und Auswahlfokus
- Status: implementiert
- Stand: `HomebaseTestScreen` rendert die verfuegbaren Units jetzt als echte `NPCMetaCard`-Instanzen statt als Checkbox-Textzeilen, verwaltet einen expliziten Fokuszustand und zeigt rechts einen kleinen Detailbereich mit fokussierter Karte, Team-/Fireteam-Metadaten und Transferhinweis. Die Homebase-Szene unter `res://scenes/meta/homebase_test_screen.tscn` wurde dafuer in eine zweispaltige Struktur mit scrollbarer Kartenliste, Fokuspanel und separater Teamzusammenfassung umgebaut. Die Auswahl bleibt weiter rein UI-lokal und liefert an den `MetaLayerFlow` unveraendert nur die selektierten `unit_id`s in stabiler Roster-Reihenfolge.
- Offene Punkte: noch keine feinere visuelle Politur fuer Hover/Keyboard-Fokus, keine Detailsektion fuer weitergehende Biografie-/Loadout-Daten und noch keine FOB-spezifische Kartenwiederverwendung.
- Risiken: der Fokus- und Auswahlzustand liegt weiterhin bewusst nur im Screen; spaetere Meta-Features duerfen daraus keine zweite Gameplay-Wahrheit oder einen versteckten globalen UI-State aufbauen.
- Naechster Schritt: in TASK_072 dieselbe Kartenbasis kontrolliert in die FOB-Ansicht uebernehmen und dort missions-/transferbezogene Statusinformationen ergaenzen.

### TASK_072 - FOB: Teamkarten und Einsatzstatus
- Status: implementiert
- Stand: `FOBTestScreen` nutzt jetzt dieselbe `NPCMetaCard`-Komponente und denselben `MetaUnitProfileBuilder`-Pfad wie die Heimatbasis, um das uebertragene Team als Kartenliste statt als rohe Textzeilen darzustellen. Der bestehende Missionsrueckfluss aus `mission_result.team_states` wird pro Unit in kompakte Kartenstatus wie `READY FOR MISSION`, `FIT`, `DOWN`, `BLEEDOUT`, `RESPAWNING` oder `UNKNOWN` uebersetzt; ergaenzend zeigt die FOB eine kleine Zusammenfassung mit Teamgroesse, letzter Mission und Zahl einsatzbereiter Units sowie einen Fokusbereich fuer die aktuell betrachtete Unit. `MetaLayerFlow` liefert dafuer explizit den verfuegbaren Roster-Kontext an die FOB, ohne den bestehenden Homebase->FOB->Mission->Debrief-Flow semantisch zu aendern.
- Offene Punkte: noch keine tiefergehende After-Action-Aufbereitung, keine Rollen-/Loadout-Ansicht und keine Politur fuer alternative Statusbadges jenseits der bestehenden Kartenstatuszeile.
- Risiken: die FOB bleibt bewusst ein read-only Staging-Screen; spaetere Komfortfunktionen duerfen daraus keine zweite Teamverwaltungslogik oder verdeckte Persistenzschicht machen.
- Naechster Schritt: nur bei eigenem Folgetask weitere FOB-spezifische Komfortelemente wie Rollenhinweise oder Transfer-CTA-Politur aufbauen, ohne die bestehende Kartenbasis zu forkieren.

### TASK_073 - Homebase: Charakterbogen und Drag-and-Drop-Teamstaging
- Status: implementiert
- Stand: `HomebaseTestScreen` und `res://scenes/meta/homebase_test_screen.tscn` bilden die Heimatbasis jetzt als klare Dreispalten-Ansicht ab: links ein read-only Charakterbogen mit Portrait, Callsign, Herkunft, Alter, Rolle, Spezialisierung, Skills, Traits, Loadout und Kurzbiografie; mittig ein Drag-and-Drop-Staging-Bereich fuer das aktuelle Transferteam; rechts ein scrollbarer Pool aus 12 kompakten Portrait-Karten. `NPCCompactCard` dient dabei als kleine Quell- und Staging-Karte mit Portrait, Name und zwei kompakten Datenpunkten; ein Klick fokussiert den Charakterbogen, Drag-and-Drop ueber `HomebaseTeamDropPanel` staged Operators bis zum bestehenden 3er-Limit, und Entfernen bleibt ueber einen klaren Remove-Pfad moeglich. Der bestehende Flow bleibt kompatibel: `MetaLayerFlow` uebergibt weiter nur selektierte `unit_id`s, `MissionTestSetup` mappt diese kontrolliert auf die drei vorhandenen Friendly-Slots, und FOB, Mission sowie Debrief arbeiten dadurch mit den tatsaechlich aus dem 12er-Roster gewaehlten NPC-IDs statt implizit mit festen Homebase-Defaults.
- Offene Punkte: noch keine Drag-Reihenfolge innerhalb des Staging-Bereichs, keine Sortierung oder Filterung im Roster und keine zusaetzliche visuelle Politur fuer Hover-/Keyboard-Navigation.
- Risiken: das Teamstaging bleibt bewusst rein UI-lokal; spaetere Komfortfunktionen duerfen daraus keine persistente Barracks- oder Teamverwaltungs-Wahrheit machen.
- Naechster Schritt: nur bei eigenem Folgetask weitere Roster-Komfortfunktionen wie Sortierung, Filter oder feinere Staging-Politur ergaenzen, ohne den bestehenden Meta-/Missionspfad aufzubrechen.

### TASK_074 - Homebase: Layout-Neuordnung und Missionsinfoleiste
- Status: implementiert
- Stand: `res://scenes/meta/homebase_test_screen.tscn` ordnet die Homebase jetzt gemaess Folgetask neu an: ein eigenes Missionsinfo-Fenster liegt ueber die volle Breite oberhalb der drei Hauptfenster, links der scrollbare Portrait-Karten-Pool, mittig das Transferfenster und rechts der lesende Charakterbogen. Im Transferfenster sitzt der bestaetigende CTA jetzt oben als `Send to FOB`, waehrend der darunterliegende Drag-and-Drop-Bereich unveraendert die selektierten `unit_id`s fuer den bestehenden Flow bildet. `HomebaseTestScreen` aktualisiert zusaetzlich kompakte Missionsinfo-Texte rein aus dem vorhandenen UI-/Roster-Kontext, und der Charakterbogen nutzt jetzt einen eigenen ScrollContainer, damit die drei Hauptfenster im sichtbaren Bereich bleiben und nicht horizontal aus dem Screen gedrueckt werden.
- Offene Punkte: die Fenster sind funktional neu angeordnet, aber noch nicht visuell verdichtet; kleinere Roster-Karten, Popup-Tooltips, reduzierte Erklaertexte und die inhaltliche Fokussierung des Charakterbogens folgen erst in TASK_075.
- Risiken: die Missionsinfoleiste ist bewusst rein read-only und screen-lokal; spaetere Briefing- oder Missionsdaten duerfen daraus keine zweite Missionswahrheit im UI machen.
- Naechster Schritt: in TASK_075 die Kartenverdichtung, Tooltip-Hilfe und den fokussierteren Charakterbogen kontrolliert nachziehen.

### TASK_075 - Homebase: Kartenverdichtung, Tooltip-Polish und Charakterbogen-Fokus
- Status: implementiert
- Stand: `NPCCompactCard` unterstuetzt jetzt ueber `compact_mode` zwei Dichten derselben Kartenlogik: links im Roster kompakter mit kleinerem Portrait, engeren Innenabstaenden und reduzierter Typografie; in einer Nachpolitur wurden diese kompakten Karten nochmals leicht angehoben und zugleich auch fuer das Transferfenster uebernommen, damit links und Mitte dieselbe Kartenoptik teilen. `HomebaseTestScreen` blendet die dauerhaft sichtbaren Hilfetexte in den Fensterkoerpern aus und ersetzt sie durch deutsche Popup-Tooltips an Missionsfenster, Roster, Transferfenster, Dropzone, Charakterbogen und `Send to FOB`; diese Tooltips wurden spaeter noch bewusst blockiger auf mehrere Zeilen umgestellt. Der Charakterbogen wurde zugleich fokussiert: Callsign, Herkunft und Alter werden dort nicht mehr gezeigt, Rolle und Spezialisierung bleiben sichtbar, und die Skills erscheinen ausgeschrieben untereinander als `Accuracy`, `Speed`, `Leadership` und `Toughness`. Zusaetzlich wurden Abstaende, Mindestgroessen und Schriftgroessen in der Homebase nochmals kontrolliert verdichtet, ohne den bestehenden Drag-and-Drop-Transferfluss oder die selektierten `unit_id`s semantisch zu aendern; der Drag-Preview-Pfad der kompakten Karten wurde dabei gegen den bisherigen Buchstabe-pro-Zeile-Wrap-Bug gehaertet.
- Offene Punkte: die gemeinsame graue Kenney-Fensteroptik fuer Meta-Screens fehlt noch; das folgt erst in TASK_076.
- Risiken: die neuen Tooltips sind bewusst lokal direkt an der Homebase verdrahtet; spaetere globale Tooltip- oder Lokalisierungssysteme sollten diesen Pfad explizit uebernehmen statt verdeckt zu ersetzen.
- Naechster Schritt: in TASK_076 die vorhandenen grauen Kenney-UI-Assets als gemeinsame Meta-Fensteroptik fuer Homebase und spaeter FOB aufbauen.

### TASK_076 - Meta-Layer: Graue Kenney-UI-Rahmen
- Status: implementiert
- Stand: mit `res://scripts/meta/meta_ui_skin.gd` gibt es jetzt einen kleinen gemeinsamen Stilpfad fuer den Meta-Layer, der graue Kenney-Assets aus beiden vorhandenen UI-Packs direkt auf bestehende Screens auflegt, statt eine zweite Screen-spezifische Visual-Architektur einzufuehren. Homebase nutzt darueber nun sichtbare graue Kenney-Rahmen fuer Root-Container, Missionsinfo, Roster, Transfer, Dropzone und Charakterbogen; der CTA `Send to FOB` sowie die dynamisch erzeugten `Remove`-Buttons erhalten ebenfalls einen daran angeglichenen Button-Stil. In einer spaeteren Nachpolitur wurde der Mission-Brief-Rahmen von `button_square_header_large_rectangle` auf `button_square_header_blade_rectangle_screws` umgestellt, und der FOB-Transfer-CTA sitzt jetzt rechts im Mission Brief mit einer farblichen Neutral-/Bereit-/Pressed-Staffelung ueber Kenney-Header-Assets. FOB ist bereits auf dieselbe Stilbasis verdrahtet: Root-Screen, Fokusfenster sowie `Back to Homebase` und `Start Mission` verwenden denselben gemeinsamen Skin-Pfad, sodass TASK_077 direkt auf derselben neutral-grauen Meta-Optik aufbauen kann.
- Offene Punkte: Kartenkomponenten und feinere Meta-Panel-Strukturen sind noch nicht vollstaendig auf dieselbe Kenney-Chrome-Sprache gezogen; die aktuelle Stufe konzentriert sich bewusst auf die grossen Fensterrahmen und CTA-Flaechen.
- Risiken: der Stil wird derzeit bewusst lokal per Skript auf konkrete Screen-Pfade gelegt; wenn spaeter eine globale Theme-Ressource eingefuehrt wird, sollte sie diesen kleinen gemeinsamen Pfad sauber ersetzen statt parallel weiterzulaufen.
- Naechster Schritt: in TASK_077 die Fireteam-Vorbereitung in der FOB auf dieser nun gemeinsamen Meta-UI-Basis einfuehren, ohne die Homebase erneut mit Auswahlverantwortung zu belasten.

### TASK_077 - FOB: Fireteam-Auswahl und Startvorbereitung
- Status: implementiert
- Stand: die Homebase bleibt jetzt rein beim Teamtransfer und greift nicht mehr in die Fireteam-Startentscheidung ein; `MetaLayerFlow` initialisiert nach Homebase-Bestaetigung bewusst eine leere, explizit vorbereitbare Fireteam-Auswahl parallel zu den selektierten `unit_id`s. Die FOB hat dafuer in `res://scenes/meta/fob_test_screen.tscn` einen kleinen Fireteam-Prep-Schritt erhalten: fuer die aktuell fokussierte transferierte Person kann direkt in der FOB zwischen `UNASSIGNED`, `BLUE` und `GOLD` gewechselt werden, waehrend eine Zusammenfassungszeile die Zuordnung fuer alle transferierten Operators lesbar macht. `FOBTestScreen` fuehrt diese Auswahl als geordneten, read-only stagingnahen UI-Zustand und gibt sie beim bestaetigenden `Start Mission` explizit weiter; `MetaLayerFlow` traegt die Fireteam-IDs kontrolliert bis in `MissionTestSetup`, und `MissionTestSetup` setzt `set_fireteam_id(...)` fuer Friendly-Slots jetzt bevorzugt aus der FOB-Vorbereitung statt starr aus den Roster-Presets.
- Offene Punkte: die aktuelle Vorbereitung bleibt bewusst minimal auf `UNASSIGNED`, `BLUE` und `GOLD` begrenzt; groessere Squad-/Loadout-Oberflaechen oder komplexere Rollenlogik sind weiterhin nicht Teil dieses Pfads.
- Risiken: die Fireteam-Zuordnung wird aktuell als zur Slot-Reihenfolge paralleles Array transportiert; spaetere groessere Teamgroessen oder frei sortierbare FOB-Listen sollten diesen kleinen Datenvertrag dann explizit auf einen robusteren Mapping-Pfad anheben.
- Naechster Schritt: den neuen FOB-Vorbereitungspfad bei Bedarf spaeter sichtbarer in Missions- oder Debrief-UI aufgreifen, ohne daraus eine neue globale Persistenz- oder Managementschicht zu machen.

### TASK_078 - Meta-Layer: Navigation und Map-Ansicht
- Status: implementiert
- Stand: der Meta-Layer besitzt jetzt einen direkten Wechsel zwischen `Homebase`, `FOB` und der echten Missionskartenansicht, aber die Navigation liegt nicht mehr als separate globale Leiste ueber dem Screen. Stattdessen sitzen die drei Umschaltbuttons jetzt in den jeweiligen Briefing-Headern von Homebase, FOB und der eingebetteten Missionsvorschau; der dritte Button ist fuer den Nutzer bewusst als `Mission` beschriftet. Der fruehere read-only `meta_map_screen`-Pfad wurde wieder entfernt; stattdessen hostet `MetaLayerFlow` in `MissionHost` direkt eine Preview-Instanz von `res://scenes/tests/mission_reactivity_test.tscn`, die dieselbe Kartenbasis, NPCs und den aktuellen FOB-/Planungszustand lesbar anzeigt. Wechsel zwischen den drei Meta-Ansichten verlieren dabei weder Teamauswahl noch FOB-Vorbereitungsstand, waehrend Mission und Debrief die Navigation bewusst ausblenden.
- Offene Punkte: die Map-Ansicht ist aktuell eine reine Text-/Statuszusammenfassung ohne grafische Kartenvorschau oder Missionsplanung.
- Risiken: der Map-Pfad nutzt bewusst den bestehenden Test-Missionsbezug und keine neue globale Planungsarchitektur; falls spaeter mehrere Missionskarten dynamisch waehlbar werden, sollte der aktuelle feste Map-Referenzpfad explizit auf einen kleinen Datenvertrag angehoben werden.
- Naechster Schritt: nur bei eigenem Task eine grafischere Kartenlesbarkeit oder einfache Objective-/Spawn-Hinweise ergaenzen, ohne die Map-Ansicht in einen Editor oder Taktikplaner umzubauen.

### TASK_079 - FOB: Fireteam-Management, Respawn-/Loadout-Staging und Dropship-Wartezone
- Status: implementiert
- Stand: `res://scenes/meta/fob_test_screen.tscn` wurde von der kompakten Prep-Ansicht zu einem klaren Vier-Spalten-Screen umgebaut: links die verfuegbaren uebertragenen Operators, daneben die Fireteam-Spalte, dann ein Respawn-/Loadout-Staging-Bereich und rechts die Dropship-Wartezone. In einer anschliessenden Politur wurden die Spaltenbreiten und Aussenabstaende nochmals reduziert, der Respawn-Anteil bewusst deutlich kleiner gehalten und der Loadout-Bereich vergroessert, damit die Seiten und die Unterkante im kleineren Editorfenster weniger leicht abgeschnitten werden. Die Meta-Navigation sitzt dabei weiter im FOB-Header statt in einer separaten globalen Leiste. `res://scripts/meta/fob_screen.gd` fuehrt explizite Fireteam-Definitionen mit editierbaren Labels, einem unverlierbaren `FT1`, anlegbaren weiteren Fireteams per `+` und loeschbaren Zusatzteams per `-`. Die Zuordnung bleibt staging-first, wurde aber von Button-only auf einen kleinen Drag-and-Drop-Pfad erweitert: Operator-Portraitkarten koennen jetzt aus der Verfuegbar-Spalte oder aus bestehenden Fireteam-Mitgliedslisten direkt auf Fireteam-Karten gezogen werden; Fireteam-Karten selbst sind ebenfalls draggable und koennen in eigene Drop-Zonen fuer Respawn bzw. Loadout gezogen werden. Neu hinzugekommen sind ausserdem ein expliziter Fireteam-Lead pro Team und ein individueller Member-Loadout-State: Armor kann weiter als schneller Team-Default (`LIGHT`, `MEDIUM`, `HEAVY`) gesetzt werden, waehrend im vergroesserten Loadout-Bereich jedes Fireteam-Mitglied zusaetzlich eigene Armor- und Waffenklassen (`Maschinenpistole`, `Sturmgewehr`, `Mischung`, `Sonderwaffen`) bekommt. Rechts simuliert die kleine Dropship-Wartezone weiter einen `inbound`- und anschliessenden Boarding-Zustand fuer die aktuell aktiven Fireteams, ohne daraus eine echte Fahrzeug- oder Gameplay-Simulation zu machen. `MetaLayerFlow` behaelt diesen FOB-Zustand ueber View-Wechsel hinweg bei und uebergibt weiterhin nur die expliziten Fireteam-IDs in den bestehenden Missionspfad.
- Offene Punkte: Loadout- und Respawn-Werte bleiben bisher bewusst FOB-Meta-State ohne tiefe Missionswirkung; die Dropship-Zone ist eine lesbare Meta-Timerdarstellung, keine echte Transportmechanik.
- Risiken: die Fireteam-Labels sind editierbar, aber fuer den Missionspfad wird weiterhin die interne Fireteam-ID (`ft1`, `ft2`, ...) transportiert; spaetere Systeme muessen diese Trennung zwischen lesbarem Label und stabilem Datenwert erhalten.
- Naechster Schritt: spaeter bei Bedarf einzelne FOB-Stagingwerte gezielt im Debrief oder Missionsstart sichtbarer machen, ohne daraus direkt ein grosses Loadout-, Inventar- oder Fahrzeugsystem wachsen zu lassen.

### TASK_080 - Meta-Layer: Transfer-Sichtbarkeit, Pool-DnD und Charakterbogen-Toggle
- Status: implementiert
- Stand: `res://scripts/meta/meta_layer_flow.gd` trennt jetzt sauber zwischen Homebase-Restpool, Homebase-Staging und bereits in die FOB uebertragenen Operators. Nach `Send to FOB` verschwinden uebertragene Personen aus der Homebase und werden nur noch im FOB-Pool gefuehrt. In `res://scripts/meta/homebase_screen.gd` zeigt das linke Roster nur noch aktuell nicht gestagte Homebase-Personen; Doppelklick auf eine NPC-Karte oeffnet den Charakterbogen, waehrend ein neuer `Close`-Button im Charakterbogen ihn wieder ausblendet. In der FOB zeigt `res://scripts/meta/fob_screen.gd` die Available-Spalte nur noch unzugewiesene Operators; Mitgliedskarten koennen per Drag-and-Drop auf Fireteams und wieder zurueck in den Available-Pool bewegt werden. Der FOB-Respawnblock sitzt jetzt nochmals staerker verdichtet im Header links neben `Start Mission`, redundante Brief-Statuszeilen wurden dort ausgeblendet, und die FOB-DnD-Pfade wurden gegen Control-Hierarchie-Probleme gehaertet, indem dynamisch erzeugte Operator-Karten in der FOB Drop-Hover per `MOUSE_FILTER_PASS` an ihre Eltern weiterreichen, statt Fireteam- oder Available-Drops lokal zu verschlucken.
- Offene Punkte: Der neue Pool-Wechsel bleibt weiterhin reiner Meta-State; es gibt noch keinen Ruecktransfer von der FOB zur Homebase ausserhalb spaeterer eigener Tasks.
- Risiken: Die Operator-Pools werden jetzt explizit getrennt gehalten; spaetere Persistenz oder Kampagnenlogik muss diese Trennung bewusst uebernehmen, statt wieder still dieselbe Liste fuer Homebase und FOB zu teilen.
- Naechster Schritt: Falls gewuenscht, spaeter gezielt einen expliziten Ruecktransfer- oder Homebase-Reintegration-Task einfuehren, ohne den aktuellen Meta-State-Pfad wieder aufzuweichen.

### TASK_080 – UI-Polish: Header, Loadout, Lead-Star und Drop-Panel-Styling
- Status: implementiert
- Stand: Die FOB-Oberflaeche wurde in mehreren Bereichen visuell ueberarbeitet:
  - **Nav-Buttons** (Homebase, FOB, Mission) auf ein Drittel der urspruenglichen Hoehe reduziert (custom_minimum_size 16px, font_size 8).
  - **Respawn-Anchor-Panel** auf doppelte Breite vergroessert (90 → 180px).
  - **Loadout-Drop-Panel** an den oberen Rand des Loadout-Bereichs verschoben, sodass der Drop-Bereich sofort sichtbar ist.
  - **Dropship-Drop-Panel** visuell an das Loadout-Drop-Panel angeglichen (gleiche Margins und Schriftgroesse).
  - **Loadout pro NPC**: Jedes Fireteam-Mitglied erhaelt jetzt einen Armor-Dropdown (Light/Medium/Heavy) und zwei separate Waffen-Slots (Maschinenpistole, Sturmgewehr, Sonderwaffe). Die fruehere "Mischung"-Option wurde entfernt; das Datenmodell nutzt `weapon_1` und `weapon_2` statt eines einzelnen `weapon`-Felds.
  - **Lead-Indikator**: Der bisherige separate Lead-Button unter der NPC-Karte wurde entfernt und durch einen Stern direkt in der `NPCCompactCard` ersetzt. Grauer Stern = kein Leader, gelber Stern = Leader. Der Stern ist klickbar und loest den Lead-Toggle aus, ohne eine separate Schaltflaeche zu benoetigen.
- Offene Punkte: Die Aenderungen sind rein visuell und betreffen nur die FOB-UI; das zugrunde liegende Meta-State-Modell bleibt unveraendert, abgesehen von der Erweiterung auf zwei Waffen-Slots.
- Risiken: Die Erweiterung auf `weapon_1`/`weapon_2` ist abwaertskompatibel; bestehende Daten mit einem einzelnen `weapon`-Feld werden beim Lesen automatisch auf `weapon_1` gemappt.
- Naechster Schritt: Weitere UI-Verfeinerungen oder Gameplay-Logik koennen auf dieser Grundlage aufbauen, ohne die bestehende Architektur zu veraendern.

### TASK_081 – Meta-Layer: UI-Harmonisierung fuer FOB, Homebase und Loadout
- Status: implementiert
- Stand: Homebase und FOB nutzen jetzt dieselben kompakten Header-Proportionen. Der FOB zeigt einen verdichteten Missionsbrief mit stabil rechts sitzendem `Start Mission`, waehrend Missionsname, Map und Slot-Kontext explizit aus `res://scripts/meta/meta_layer_flow.gd` kommen. In `res://scripts/meta/fob_screen.gd` wurde die Charaktereinsicht zu einem schliessbaren Overlay ausgebaut, das per Doppelklick auf kompakte NPC-Karten geoeffnet wird und Portrait, Rolle, Status, Skills, Traits, Bio sowie Loadout-Hinweise aus dem bestehenden Meta-State rendert. NPC-Karten und Charakterboegen zeigen dabei konsistente Meta-Orte an: Homebase fuer Roster/Transfer, FOB fuer Pool/Loadout/Respawn und Rover fuer Wait-Zone, Boarding und bereits verladenen Zustand. Der Loadout-Bereich arbeitet jetzt pro Fireteam-Mitglied mit kompakter NPC-Karte, Lead-Stern sowie direkten Selektoren fuer Armor, Slot 1 und Slot 2; derselbe mitgliedsbezogene Block wird auch im Respawn-Fenster gerendert.

  Parallel wurde in `res://scripts/meta/npc_compact_card.gd` die Drag-Preview stabilisiert: kompakte Karten behalten beim Ziehen ihre Geometrie und uebernehmen nicht mehr die expandierte Breite aus Fireteam- oder Loadout-Layouts. Loadout-, Respawn- und Dropship-Panels sind direkte Drop-Ziele; Fireteams werden zwischen diesen Fenstern als Move statt als Kopie verschoben. Die Staging-Zonen besitzen eigene sichtbare Fireteam-Karten-Hosts, rendern diese aber erst nach explizitem DnD. Der Fireteam-Pool links blendet bereits gestagte Teams konsequent aus und kann selbst wieder als Rueckgabe-Ziel genutzt werden. Fuer kleine Rueckwege existieren ein `Clear` im Loadout-Staging und ein gezieltes Entfernen des fokussierten Fireteams aus der Dropship-Wartezone. Die Wait-Zone rendert sichtbare Fireteam-Karten mit Portraits, Namen und individuellen Boarding-Fortschritten; nach der automatischen Dropship-Ankunft wechselt sie erst in `ready`, und `Start Boarding` startet die eigentlichen NPC-Boarding-Timer.

  Die Homebase-Flugdeckansicht startet jetzt leer. Das obere Dropdown waehlt nur noch den Typ `Dropship` oder `Frachter`; erst `+` erzeugt die jeweilige Shipcard im Flight Deck. Entfernen, Pilot-Slot, Cargo-Dropdown und `Load` sitzen lokal in der einzelnen Shipcard, sodass Auswahl, Laden und Startzustand pro Schiff zusammenbleiben. Das gestagte Team startet ueber `Send to FOB` direkt aus der Kopfzeile des Transferfensters; der Button sitzt nicht mehr im globalen Mission-Brief. Zusaetzlich besitzt die Homebase nun ein kompaktes Missions-Dropdown im Header, das Missions-/Map-Kontext fuer Homebase, FOB, Map-Overview und den Testmissionspfad gemeinsam umstellt, ohne die Header-Zeile aufzublaehen. In einer spaeteren Recovery-Nachpflege aktualisiert `MetaLayerFlow` Homebase, FOB und Map-Ansicht waehrend laufender Transfer-Timer jetzt pro Tick, sodass Transit-Zustaende nicht erst bei Ankunft sichtbar werden. Die nummerierten Fensterueberschriften in Homebase und FOB wurden dabei wiederhergestellt, und Pilot-NPC-Karten in Homebase-Shipcards sowie FOB-Transportkarten werden waehrend des Transits jetzt gemeinsam mit der jeweiligen Shipcard sichtbar deaktiviert bzw. ausgegraut.
- Offene Punkte: Der neue Charakter-Overlay, die Homebase-Flugdeckansicht und die Karten in der Dropship-Wartezone bleiben weiterhin reiner Meta-State ohne direkte Missions- oder Persistenzwirkung. Die Meta-Map spiegelt die per-Mitglied-Loadouts jetzt direkt auf den Preview-Fireteam-Karten und zeigt laufende Homebase->FOB-Transfers als eigene Route mit separaten Team-/Pilot-Markern; weitergehende Ruecktransfers oder mehrere unterschiedliche Flugkorridore bleiben weiterhin ausserhalb dieses kleinen V1-Scope.
- Risiken: Die Mission-Kontextdaten und die neuen Homebase-Transferdauern werden aktuell bewusst noch klein und fest aus dem bestehenden Testpfad gespeist; falls spaeter mehrere Missionen oder unterschiedliche Flieger dynamisch waehlbar werden, sollte daraus ein expliziter kleiner Datenvertrag werden statt weiterer UI-String-Glue. Die Homebase-Transportanzeige bleibt ein Meta-Orchestrierungspfad in `MetaLayerFlow` und ist keine tiefergehende Transport- oder Kampagnen-Simulation.
- Naechster Schritt: Falls gewuenscht, spaeter gezielt Ruecktransfers, mehrere unterschiedliche Flieger oder eine kleine Karten-/Debrief-Sicht auf laufende Homebase-Transfers ergaenzen, ohne den aktuellen kleinen Meta-Flow zu einer grossen Persistenz- oder Transportarchitektur aufzublasen.

### TASK_082 – Gemeinsamer Terrain-Renderer fuer Editor und Mission
- Status: implementiert
- Stand: Mit `res://scripts/terrain/terrain_map_renderer.gd` existiert jetzt ein kleiner gemeinsamer Renderpfad fuer JSON-basierte TerrainMapData. Der Editor nutzt diesen Renderer fuer den kompletten Kartenaufbau aus Tile-, Cliff- und Objekt-/Wall-Overlays, statt den Full-Rebuild weiterhin nur lokal in `map_editor.gd` zu halten. Die Missions-Testszene rendert dieselbe JSON-Karte jetzt ebenfalls ueber diesen Pfad; `MissionTestSetup` registriert die Tiles weiter in der `TerrainRegistry`, laesst die sichtbare Karte aber nicht mehr aus vorplatzierten Boden-Sprites plus Modulate entstehen. Zusaetzlich traegt `TerrainMapData` jetzt einen kleinen Marker-Datenvertrag, und die zentrale 32x32-Testmap speichert `spawn_alpha`, `spawn_bravo`, `objective_point` sowie die beiden Flank-Anker direkt in derselben JSON-Datei. `MissionTestSetup` uebernimmt diese Markerpositionen in die vorhandenen Szenen-Marker, sodass bestehende NodePath-Pfade weiter funktionieren, und die read-only Meta-Map zeigt dieselben Markerkoordinaten ebenfalls aus der Map-Datei an. `res://scenes/maps/iso_map_v2_layout.tscn` bleibt damit auf Render-Container plus Fallback-Marker reduziert. In einer spaeteren Recovery-Nachpflege speichert `TerrainMapData` zusaetzlich `mission_slot_count` direkt in der JSON, der Map-Editor bietet dafuer nun ein kleines Map-Settings-Panel samt Marker-Zuweisung fuer die festen Missionsmarker, und `MetaLayerFlow` kann die Missions-Slot-Kapazitaet bei Bedarf direkt aus der Map-Datei aufloesen statt nur aus statischen Missionsdefinitionen zu lesen.
- Offene Punkte: Die laufenden Editor-Einzelupdates fuer geaenderte Tiles nutzen weiterhin ihre bestehenden lokalen Update-Helfer; der gemeinsame Pfad ist aktuell der gemeinsame Full-Rebuild und der Runtime-Aufbau. Die offen gebliebenen Marker-Themen sind inzwischen explizit als `TASK_115` ausgelagert, statt weiter als unscharfer Restpunkt in `TASK_082` zu bleiben.
- Risiken: Die Missionsmarker werden weiter aus der Map-Datei in Szenen-Marker gespiegelt, solange andere Testpfade noch NodePaths auf diese Marker erwarten. `mission_slot_count` ist bewusst nur ein kleiner Map-Metadatenvertrag; spaetere Missions- oder Kampagnenlogik sollte diesen Wert explizit weiterreichen statt erneut separate Slot-Quellen einzufuehren.
- Naechster Schritt: Bei weiterem Marker-Bedarf gezielt `TASK_115` bearbeiten und erst danach groessere Terrain-Funktionen wie mehrere Missionskarten oder graphischere Meta-Map-Vorschauen darauf aufbauen.

### TASK_085 – Charakterbogen Combat-Integration (get_combat_effects)
- Status: implementiert
- Stand: `TestUnit` bietet jetzt `get_combat_effects() -> Dictionary`, das die combat_effects-Werte (`speed_multiplier`, `hit_modifier`, `evasion_modifier`, `damage_taken_multiplier`) direkt aus dem Charakterbogen-Bundle zurueckgibt, mit sicheren Defaults bei leerem Bundle.
- Offene Punkte: keine.
- Risiken: Rein additiv; bestehende Einzelgetter bleiben weiter verfuegbar.
- Naechster Schritt: Consumers koennen `get_combat_effects()` statt der Einzelmethoden nutzen.

### TASK_086 – Waffenmodell (WeaponData)
- Status: implementiert
- Stand: Neues `scripts/core/weapon_data.gd` als statische Waffen-Registry mit drei Typen: Maschinenpistole (smg, weapon_gun_*, schnell, niedrig), Sturmgewehr (rifle, weapon_rifle_*, balanciert), Schienenkanone (rail_gun, weapon_rifle_* in 2x, langsam, hoch). `TestUnit` traegt `weapon_1_id`/`weapon_2_id` als Exports und liefert `get_active_weapon_id()`. `MissionCombatLoopDriver` nutzt aktive Waffe des Angreifers fuer damage/hit_chance/ticks statt globaler Konstanten. In `fob_screen.gd` wurde "Sonderwaffe" zu "Schienenkanone" umbenannt und weapon-ID `special` zu `rail_gun` migriert (abwaertskompatibel).
- Offene Punkte: keine (Loadout-Pipeline durch TASK_087 geschlossen).
- Risiken: Globale combat-Exports (`damage_per_hit`, `base_hit_chance`, `ticks_between_attacks`) auf `MissionCombatLoopDriver` bleiben als Fallback-Defaults erhalten, werden aber im normalen Pfad nicht mehr genutzt.
- Naechster Schritt: keiner.

### TASK_087 – Loadout-Pipeline und Waffen-Sprites
- Status: implementiert
- Stand: `meta_layer_flow.gd` liest per `_build_fob_member_loadouts()` die `member_loadouts` und `lead_unit_id` aus allen Fireteam-Definitionen der FOB-UI, baut ein flaches `{unit_id: {weapon_1, weapon_2, armor, is_fireteam_lead}}` Dictionary und uebergibt es via `mission_setup.set("member_loadouts", ...)` an `MissionTestSetup`. `mission_test_setup.gd` hat neue Property `member_loadouts: Dictionary` und ruft nach dem Roster-Preset `_apply_fob_loadout_override()` auf, das `weapon_1_id`, `weapon_2_id`, `armor` und `is_fireteam_lead` via `apply_identity_config()` auf die Unit setzt. Nur Friendlies erhalten Overrides; Enemies bleiben unberuehrt. Ohne FOB-Daten greifen die Roster-Defaults. `test_unit.gd` rendert jetzt zusaetzlich ein `WeaponVisual`-`Sprite2D` als Child der bestehenden `Visual`-Sprite, leitet die Richtung aus der aktuellen Unit-Textur ab (Fallback `SE`), nutzt `WeaponData.get_asset_path()` und `WeaponData.get_sprite_scale()` fuer Textur und Skalierung und setzt kleine Kenney-kompatible Offsets pro Iso-Richtung. Dadurch ist die Schienenkanone visuell doppelt so gross wie das Sturmgewehr.
- Offene Punkte: keine.
- Risiken: keine.
- Naechster Schritt: keiner.

### TASK_088 – Leadership-Bonus auf Fireteam-Mitglieder
- Status: implementiert
- Stand: Leadership-Bonus-System mit automatischer Lead-Nachfolge implementiert. `test_unit.gd` hat `is_fireteam_lead`-Export, `_leadership_bonus`-Feld, `apply_leadership_bonus()`, `clear_leadership_bonus()`, `get_leadership_hit_modifier()`. Der Bonus fliesst ueber `get_combat_effects()` und `_extract_unit_hit_modifier()` in SimulationRoot in die Trefferberechnung ein. `mission_combat_loop_driver.gd` verwaltet pro Tick Fireteam-Leads: wenn Original-Lead down → Unit mit hoechstem Leadership uebernimmt automatisch; wenn Original-Lead respawnt → uebernimmt sofort zurueck. Bonus = `leadership * 0.15` auf alle Fireteam-Mitglieder (nicht Lead selbst).
- Offene Punkte: keine (durch TASK_087 wird `is_fireteam_lead` jetzt aus `lead_unit_id` der FOB-Daten gesetzt).
- Risiken: keine
- Naechster Schritt: keiner.

### TASK_089 – Enemy Cover-Seeking
- Status: implementiert
- Stand: `TerrainRegistry` um `get_walkable_cover_tiles_in_radius(world_center, radius)` erweitert. `_build_enemy_reposition_target()` in `mission_combat_loop_driver.gd` sucht jetzt Cover-Tiles im Reposition-Radius, filtert nach Mindestabstand, sortiert nach Cover-Score absteigend und waehlt das beste Tile. Fallback auf bisherige Zufalls-Reposition wenn keine Cover-Tiles vorhanden. Cooldown bleibt erhalten.
- Offene Punkte: keine
- Risiken: keine
- Naechster Schritt: TASK_090 differenzierte Enemy-Typen.

### TASK_090 – Differenzierte Enemy-Typen
- Status: implementiert
- Stand: 6 Enemy-Archetypen (Standard, Scout, Heavy, Sniper, Medic, Officer) als `ENEMY_ARCHETYPES`-Array in `unit_roster_presets.gd` definiert. Jeder Archetyp hat eigene Skills, Waffe und Traits. `get_preset()` fuer `team_bravo` waehlt Archetyp per Unit-ID-Hash automatisch. Lookup-Funktionen `get_enemy_archetype_for_unit()` und `get_enemy_archetype_by_id()` ergaenzt. Friendly-Roster bleibt unberuehrt.
- Offene Punkte: keine
- Risiken: keine
- Naechster Schritt: TASK_091 Awareness/Detection Delay.

### TASK_091 – Awareness: Detection-Delay
- Status: implementiert
- Stand: Detection-Delay basierend auf dem `awareness`-Wert einer Unit implementiert. `_detection_progress`-Dictionary in `mission_combat_loop_driver.gd` trackt pro Attacker-Target-Paar verbleibende Detection-Ticks. Formel: `(1.0 - awareness) * MAX_DETECTION_DELAY_TICKS` (15 Ticks). awareness=1.0 erkennt sofort, awareness=0.0 braucht 15 Ticks. Timer wird pro Tick dekrementiert und bei LOS-Verlust zurueckgesetzt. `get_awareness()` in `test_unit.gd` ergaenzt.
- Offene Punkte: keine
- Risiken: keine
- Naechster Schritt: TASK_092 Stealth/Sichtreichweite.

### TASK_092 – Stealth: Reduzierte Sichtreichweite
- Status: implementiert
- Stand: `_get_effective_range(target)` in `mission_combat_loop_driver.gd` berechnet effektive Sichtreichweite basierend auf dem `stealth`-Wert des Ziels. Formel: `contact_range * (1.0 - stealth * 0.5)`. stealth=0.0 ergibt volle Reichweite, stealth=1.0 halbiert sie. Alle drei LOS-Checks verwenden jetzt die effektive Reichweite. `get_stealth()` in `test_unit.gd` ergaenzt.
- Offene Punkte: keine
- Risiken: keine
- Naechster Schritt: TASK_093 Discipline/Hold-Fire.

### TASK_093 – Discipline: Hold-Fire-Disziplinbrueche
- Status: implementiert
- Stand: `_check_discipline_break(unit)` in `mission_combat_loop_driver.gd` wuerfelt pro Tick bei Hold-Fire ob Unit den Befehl bricht. Formel: `DISCIPLINE_BREAK_BASE_CHANCE (0.08) * (1.0 - discipline)`. discipline=1.0 → 0% Bruch, discipline=0.0 → 8% pro Tick. Cooldown (`DISCIPLINE_BREAK_COOLDOWN_TICKS=10`) verhindert Dauerfeuer. Bruch wird als Event sichtbar. `get_discipline()` in `test_unit.gd` ergaenzt.
- Offene Punkte: keine
- Risiken: keine
- Naechster Schritt: TASK_094 Recognition/Friendly-Fire.

### TASK_094 – Recognition: Friendly-Fire-Verwechslung
- Status: implementiert
- Stand: `_check_misidentification(attacker, attacker_id)` in `mission_combat_loop_driver.gd` wuerfelt pro Tick ob ein Friendly sein Ziel verwechselt. Formel: `MISIDENTIFICATION_BASE_CHANCE (0.03) * (1.0 - recognition)`. recognition=1.0 → 0% Verwechslung, recognition=0.0 → 3% pro Tick. Naechste eigene Unit wird als Ziel gewaehlt, Effect mit `allow_friendly_fire: true` gesendet. Cooldown (`MISIDENTIFICATION_COOLDOWN_TICKS=15`) verhindert Dauerfeuer auf Eigene. Nur Friendlies koennen verwechseln, Enemies nie.
- Offene Punkte: keine
- Risiken: keine

### TASK_095 – Combat Medic Support
- Status: implementiert
- Stand: `SimulationRoot` verarbeitet `heal`-Effects autoritativ ueber `_apply_heal_effect()`. `TestUnit` unterstuetzt dafuer `apply_heal(amount, heal_context)` und kann dadurch einen `down`-Zustand wieder nach `fit` anheben, solange der Heal vor einem `bleedout` greift. Combat-Medics brauchen nun zusaetzlich ein im Waffenslot ausgeruestetes `medictool`, das im FOB-Dropdown und Resolver-Pfad als eigener Slot-Gegenstand gefuehrt wird, genau 2 Kartenfelder Heal-Reichweite nutzt und visuell als rot eingefaerbtes Pistolenmodell auftaucht. `mission_combat_loop_driver.gd` erkennt Combat-Medics ueber `role_id`/`role_name`, waehlt bevorzugt `down`-Allies und danach den am staerksten verletzten `fit`-Ally in Reichweite, und laeuft fuer dringende Ziele ausserhalb der Heal-Reichweite aktiv an. Heal-/Patch-Events bleiben sichtbar; `scripts/tests/medic_support_verifier.gd` deckt jetzt Revive-vor-Bleedout, 2-Felder-Reichweite, Tool-Zwang, Dropdown-Support, Anlauf, Priorisierung und Cooldown ab.
- Offene Punkte: keine groessere Support-Architektur, keine echte Revive-Animation und keine allgemeine Verbrauchs- oder Nachschubkette jenseits des slotgebundenen `medictool`.
- Risiken: Der Supportpfad bleibt bewusst auf Combat-Medics und das konkrete `medictool` begrenzt. Falls spaeter weitere Support-Rollen oder Verbrauchsregeln hinzukommen, sollten sie diesen kleinen Pfad explizit erweitern statt eine zweite Utility-Wahrheit aufzubauen.
- Naechster Schritt: Falls gewuenscht, spaeter eigenstaendige Folge-Tasks fuer Verbrauchslogik, Revive-Animation oder weitere Support-Rollen schneiden.

### TASK_097 - Datenmodelle, engage und Ad-hoc-Vertraege
- Status: implementiert
- Stand: Die taktische Planungsschicht besitzt die leichten Dictionary-kompatiblen Modelle `FireteamWaypoint`, `FireteamOrderPlan`, `FireteamBehaviorProfile`, `PhaseState`, `AdHocOrder` und `UnitLoadoutModifiers`. `engage` ist im geplanten Commander-/Waypoint-Vertrag enthalten und wird in `engage_in_area` uebersetzt. Ad-hoc-Befehle bleiben ein getrennter Laufzeitvertrag mit standardmaessigem `resume_plan_after`.
- Offene Punkte: keine innerhalb dieses Datenmodell-Slices; Ausfuehrung, UI-Planung und Ad-hoc-Controller bleiben Folgeaufgaben.
- Risiken: Die Modelle sind bewusst reine Datentraeger. Spaetere Logik muss sie ueber die bestehenden Commander-/FTL-/SimulationRoot-Pfade konsumieren, statt Gameplay-Wahrheit in UI oder Visualisierung abzulegen.
- Lokale Pruefung: `task_097_verifier.gd` und `git diff --check` laufen gruen.

### TASK_098 - TacticalInputController und Fireteam-Auswahl
- Status: implementiert
- Stand: Der Missions-`TacticalInputController` haelt Fireteam-Auswahl als lokalen Planungszustand, unterstuetzt Linksklick, `STRG`+Linksklick, Lasso und Leeren der Auswahl. `FireteamSelectionAdapter` kapselt die Selection-Regeln; Units bekommen nur sichtbares `set_tactical_selected`-Feedback.
- Stand: Der `task_098_verifier.gd` prueft den aktuellen `Primary3DView`-Screen-/World-Pfad, damit die Auswahltests nicht mehr am alten Canvas-Projektionspfad haengen.
- Offene Punkte: keine innerhalb dieses Auswahl-Slices; Wegpunktplanung und Kontextmenue bleiben TASK_099.
- Risiken: Lasso-Auswahl bleibt reine UI-/Planungsschicht. Spaetere Gameplay-Systeme muessen weiter Commands/Effects verwenden und duerfen Selection nicht als Simulation-Wahrheit behandeln.
- Lokale Pruefung: `task_098_verifier.gd` und `git diff --check` laufen gruen.

### TASK_099 – Wegpunktplanung und Order-Visualisierung
- Status: implementiert
- Stand: Der `TacticalInputController` haelt jetzt pro Fireteam und Phase echte `FireteamOrderPlan`-Daten auf Basis der Task-97-Modelle. Rechtsklick setzt Wegpunkte fuer alle aktuell ausgewaehlten Fireteams, ein kontextsensitives Kurzmenue erlaubt direkt `move`, `defend`, `engage`, `flank` und `take`, und Wegpunkte koennen nachtraeglich per Drag verschoben oder per Delete entfernt werden. Ein schlanker `FireteamOrderVisualizer` rendert die Plaene rein lesend als Linien und Symbolmarker in der Missionsszene; beim Planen werden keine Commands an SimulationRoot oder Flow-Driver gesendet.
- Offene Punkte: keine Phasen-Ausfuehrung, keine Ad-hoc-Orders, keine Pathfinding-Auswertung entlang der Wegpunkte und keine ausgebaute Kontextmenue-/Polish-Schicht ueber den kurzen Missions-Testpfad hinaus.
- Risiken: Die Planungsdaten liegen bewusst lokal im bestehenden Mission-Planning-State-Bridge-Pfad; spaetere globale Plan-Ausfuehrung muss diese Daten explizit konsumieren, statt wieder direkte Sofort-Commands aus dem Input-Controller abzuleiten. Die Visualisierung ist absichtlich rein lesend und darf spaeter nicht zum versteckten Gameplay-Treiber werden.
- Lokale Pruefung: `task_099_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Task 100 kann auf diesem Slice aufsetzen, um einen globalen Phase-Controller und die tatsaechliche Plan-Ausfuehrung einzufuehren.

### TASK_100 – PhaseController und globale Plan-Ausfuehrung
- Status: implementiert
- Stand: Eine eigene `PhaseController`-Instanz verwaltet jetzt globale Missionsphasen getrennt vom UI-Bearbeitungskontext. Phase 0 bleibt Pre-Mission, Phase 1 existiert immer, `+ Phase` erweitert den globalen Phasenraum, und `Next Phase` ist der einzige globale Startpfad. Beim Weiterschalten startet der `TacticalInputController` alle Fireteam-Plaene der neuen Phase gleichzeitig, aktiviert Wegpunkte pro Fireteam nacheinander und erzeugt jeden Laufzeitbefehl weiter ueber `MissionCommandFlowDriver` -> Commander/FTL -> Unit -> `SimulationRoot.enqueue_command()`.
- Offene Punkte: keine Ad-hoc-Befehle, keine Suppression, keine Gegner-Phasen und keine ausgebaute Resume-/Interrupt-Logik fuer spaetere Task-101+-Verhaltensresolver.
- Risiken: Die Wegpunkt-Fertigmeldung haengt aktuell an einem schlanken Zielradius plus optionaler Haltezeit auf Fireteam-Ankerbasis. Falls spaeter echte Formations-/Suppression-/Kontaktlogik hinzukommt, muss diese Fertigbedingung bewusst erweitert werden statt still implizit zu kippen.
- Naechster Schritt: Task 101 kann jetzt auf dem globalen Phase- und Ausfuehrungsrahmen aufsetzen, um Standardverhalten und Resolver pro Fireteam sauber einzuschieben.

### TASK_101 – FireteamBehaviorResolver und Standardverhalten
- Status: implementiert
- Stand: `FireteamBehaviorResolver` leitet nun aus dem aktuellen Fireteam-Leader ein `FireteamBehaviorProfile` ab und mappt Traits, Leadership und Toughness auf Advance-Style, Cover-Prioritaet, Fire-Discipline, Cohesion und Suppression. Der `TacticalInputController` berechnet diese Profile zur Laufzeit fuer geplante Orders und Standard-Fallbacks, nutzt sie fuer leadergesteuertes `flank` mit konkreter Zielverfeinerung und sendet beim Start eines Flankierens `flank_initiated` ueber den `EventRouter`. Fireteams ohne aktive Orders fallen bei Phasenstart und nach Planende auf `hold_position` zurueck; `cautious` sucht bei Kontakt lokal Deckung.
- Offene Punkte: keine Suppression-Logik, keine Resume-/Interrupt-State-Machine und noch keine inter-fireteam Koordination ueber den Router jenseits des Flank-Startsignals.
- Risiken: Das Standardverhalten bleibt bewusst klein. `cautious` nutzt nur lokale Cover-Spruenge; spaetere Tasks muessen diesen Fallback explizit ausbauen statt daraus still eine vollstaendige KI zu machen.
- Naechster Schritt: Task 102 kann jetzt auf den aktiven Behavior-Profilen aufsetzen, um Ad-hoc-Orders und Rueckkehr in den Planfluss sauber zu implementieren.

### TASK_109 - TacticalStanceController und TacticalStancePanel
- Status: implementiert
- Stand: Ein neuer missionslokaler `TacticalStanceController` verwaltet fluechtige Stance-Anforderungen pro Fireteam (`cautious`, `normal`, `aggressive`) ausserhalb von `FireteamOrderPlan` und `PhaseState`. `MissionTacticalSandboxController` haengt diese Stances an den bestehenden `planning_state`-Bridge-Pfad, damit Preview- und aktive Missionsinstanz denselben missionslokalen Stance-Zustand teilen. `FireteamBehaviorResolver` erweitert `FireteamBehaviorProfile` um `tactical_stance` und verschiebt jetzt `advance_style`, `cover_priority` und `suppression_threshold` traitabhaengig entlang der vorhandenen `rush`/`bounding`/`creep`-Skala. In der Missions-UI gibt es ein neues `TacticalStancePanel` fuer Einzel- und Mehrfachauswahl; `FireteamStatusPanel`, Fireteam-Header und die Units selbst zeigen die aktuelle Stance als `C`/`N`/`A` bzw. `MIXED` an. Zusaetzlich liefert der Controller einen versionierten `tactical_stance_sync`-Stand fuer Preview-/Runtime-Bruecken und spaetere Multiplayer-Pfade; `SimulationRoot` nimmt die Badge-Daten direkt in die bestehenden Remote-Unit-Snapshots auf.
- Offene Punkte: keine weiteren innerhalb des TASK_109-Slices; spaetere echte Multiplayer-Eingabe fuer Stance-Aenderungen bleibt ein eigener Folgepfad oberhalb des jetzt vorhandenen Sync-Vertrags.
- Risiken: die Haltung bleibt bewusst ein fluechtiger Missionszustand im Tactical-Sandbox-Controller; spaetere tiefere Runtime- oder Netzwerkpfade sollten den vorhandenen `tactical_stance_sync`-Vertrag und die Snapshot-Felder explizit uebernehmen, statt eine zweite persistente Stance-Wahrheit aufzubauen.
- Naechster Schritt: TASK_110 auf dem jetzt vorhandenen `tactical_stance`-Feld der Behavior-Profile aufsetzen und die intra-Fireteam-Bewegungsmuster daraus konkret ausfuehren.

### TASK_110 - FireteamMovementController und Bewegungsmuster
- Status: implementiert
- Stand: Ein neuer `FireteamMovementController` fuehrt aktive Fireteam-Bewegung als eigene Laufzeit-Schicht ueber dem bestehenden Command-/Effect-Pfad aus. `MissionTacticalSandboxController` startet ihn pro geplantem oder ad-hoc-Wegpunkt mit dem bereits abgeleiteten `FireteamBehaviorProfile`, sodass `rush`, `bounding` und `caterpillar` nur noch aus dem Resolver konsumiert, aber nicht erneut berechnet werden. `rush` bewegt alle fit Members gleichzeitig und klemmt bei gerissener Kohaesion auf die langsameren Members. `bounding` bildet eine Bewegungs- und eine Deckungsgruppe, haelt den Lead standardmaessig in der Deckungsgruppe und rotiert ueber explizite `bound_complete`-Ereignisse. `caterpillar` nutzt dieselbe Laufzeitschicht fuer Einzelvorstoss mit Deckungsrestgruppe. Bei schweren Verlusten bricht der Controller koordinierte Muster kontrolliert auf `rush` herunter. Das Fireteam-Statuspanel zeigt den aktiven Bewegungsmodus als `MOVE RSH/BND/CAT`; der `EventRouter` erweitert den Vertrag um `fireteam_bound_complete`.
- Offene Punkte: Noch keine eigene In-World-Visualisierung einzelner Bound-Segmente und noch keine Nutzung bekannter Feindrichtungen fuer die Deckungsgruppe; das bleibt bei spaeteren Security-/Contact-Tasks.
- Risiken: Die Bewegungsmuster arbeiten bewusst als schlanke Laufzeit-Orchestrierung ueber `SimulationRoot.enqueue_command()`. Wenn spaetere Tasks tiefere Runtime-Status-Synchronisierung brauchen, sollte diese bewusst zentralisiert werden statt wieder verteilt in Bewegungs- oder UI-Skripten zu landen.
- Naechster Schritt: TASK_111 kann jetzt auf dem separaten Bewegungscontroller aufsetzen und Security-/Overwatch-Logik im Haltzustand ergaenzen, ohne intra-Fireteam-Movement erneut anfassen zu muessen.

### TASK_111 - FireteamSecurityController und Overwatch
- Status: implementiert
- Stand: Mit `FireteamSecurityController` gibt es jetzt einen separaten Fireteam-State fuer Sicherungssektoren im Haltzustand. `MissionTacticalSandboxController` aktualisiert diesen Zustand laufend aus aktivem Behavior-Profil, Bewegung, Suppression, Ad-hoc-Status und sichtbaren Gegnern. Fireteams waehlen nachvollziehbar zwischen `360` und `directional`, verteilen ihre fitten Members auf Sektoren und bauen bei ungesicherter Bedrohung leadership-abhaengig um. `OverwatchController` sitzt im `MissionCombatLoopDriver`, konsumiert die Security-Snapshots und enqueued vor der regulaeren Angriffsauswertung vorbereitete Reaktionsschuesse auf bewegte Feinde in beobachteten Sektoren. Die taktische Ansicht zeichnet Sicherungssektoren direkt im bestehenden `FireteamOrderVisualizer`; Statuspanel und Fireteam-Header zeigen `SEC 360`, `SEC DIR` bzw. `+OVW`.
- Offene Punkte: Noch keine tiefergehende Nutzung eines gemeinsamen Contact-Trackings oder persistenter Bedrohungsweitergabe zwischen Fireteams; das bleibt bei TASK_112. Flankenstrafen bleiben ebenfalls noch ausserhalb dieses Tasks.
- Risiken: Security und Overwatch bleiben bewusst schlanke Laufzeitschichten ueber bestehenden Combat-/LOS-Pfaden. Wenn spaetere Tasks feinere Waffen- oder Contact-Logik brauchen, sollten diese Daten zentral erweitert werden statt Overwatch zu einem zweiten Combat-System wachsen zu lassen.
- Naechster Schritt: TASK_112 kann jetzt das eigentliche Contact-Tracking und die Karten-Overlay-Intel-Schicht auf die bereits vorhandenen Security-/Overwatch-Zustaende aufsetzen.

### TASK_112 - ContactTracker und ContactMapOverlay
- Status: implementiert
- Stand: `scripts/tactical/contact_tracker.gd` fuehrt jetzt eine eigene missionslokale Kontaktlage pro Friendly-Fireteam mit `suspected`, `spotted`, `confirmed` und `lost`, inklusive letzter Position, Tick-Zeitstempel und leadership-skaliert verzogerter Weitergabe bestaetigter Kontakte. `MissionCombatLoopDriver` speist den Tracker aus bestehendem LOS und Detection-Delay, exponiert Kontakt-Snapshots und verwendet `spotted`/`confirmed` als Kontakt-Gate fuer Friendly-Feuerfreigabe; `spotted` erhaelt dabei den vorgesehenen Accuracy-Malus.
- Stand: `MissionTacticalSandboxController` reicht die Kontakt-Snapshots an `FireteamSecurityController` und ein neues `ContactMapOverlay` weiter. Das Overlay zeichnet `suspected`, `spotted`, `confirmed` und `lost` getrennt von Plan- und Security-Layern, bleibt rein lesend und aggregiert auf den aktuell ausgewaehlten Fireteam-Scope.
- Offene Punkte: Gegnerseitiges Contact-Tracking bleibt weiterhin ausserhalb dieses Scopes; der Tracker modelliert hier bewusst Friendly-Intel statt eine vollstaendige Wahrnehmungs-KI fuer beide Seiten.
- Risiken: Contact-Tracking, Security und Combat bleiben getrennte Schichten. Wenn spaetere Tasks tiefere Bedrohungslogik brauchen, sollte sie im Tracker oder Resolvern zentral erweitert werden statt erneut direkt in UI oder Overwatch auszuufern.
- Naechster Schritt: TASK_113 kann jetzt Flank-Penalties auf Basis der vorhandenen Security-Sektoren und der neuen Kontakt-/Bedrohungslage aufsetzen, ohne selbst noch Intel-Grundlagen nachbauen zu muessen.

### TASK_113 - FlankVulnerabilityResolver und Sektorstrafen
- Status: implementiert
- Stand: `scripts/tactical/flank_vulnerability_resolver.gd` fuehrt jetzt eine schmale Laufzeit-Auswertung ueber bestehende Security-Snapshots aus und erkennt Flanken ausschliesslich auf Basis von `security_mode`, `direction_angle` und `member_assignments`. Erfolgreiche Flankentreffer erzeugen einen klaren Modifier-Satz fuer Trefferchance, Schadensmultiplikator, Cover-Override und eine zeitlich begrenzte Absenkung des effektiven `suppression_threshold`, ohne selbst Security-, Contact- oder Damage-Wahrheit zu werden.
- Stand: Darauf sitzt jetzt ein kleiner Richtungs-/Morale-Folgepfad im selben Resolver: Flanken behalten die relative Angriffsrichtung (`left`, `right`, `rear`) als kurzes Richtungsgedaechtnis, und Fireteams koennen fuer wenige Sekunden `alerted` oder `shaken` bleiben. Ein Heckentreffer schaltet sofort auf `shaken`, wiederholte Seitenflanken koennen denselben Zustand nachziehen; der effektive Suppression-Schwellenwert sinkt in diesem Folgefenster weiter. `MissionCombatLoopDriver` gibt Richtung und Morale im bestehenden Flank-Payload sowie im Damage-Hit-Context weiter, `SimulationRoot` spiegelt diese Felder autoritativ durch den bestehenden Damage-Pfad, und `MissionTacticalSandboxController` zeigt Richtung, Restdauer und Morale-Kuerzel im Statusbereich.
- Offene Punkte: Gegnerseitige autonome Flankenreaktionen bleiben weiter ausserhalb dieses Scopes.
- Risiken: Flankenverwundbarkeit bleibt bewusst ein schmaler Resolver ueber vorhandene Security- und Combat-Daten. Wenn spaetere Tasks komplexere Richtungsdeckung oder groessere Morale-Ketten einfuehren, sollten sie diesen zentralen Modifier-Pfad erweitern statt zweite flank-spezifische Sonderlogik in UI, Overwatch oder DamageModel zu verteilen.
- Naechster Schritt: Die Reihe `109` bis `113` ist damit fachlich geschlossen; weitere Folgeschritte sollten nur aus neu definierten Tasks kommen statt diesen Batch still weiter auszubauen.

### TASK_115 - Gemeinsames Markersystem fuer Editor und Taktikkarte
- Status: implementiert
- Stand: `scripts/terrain/terrain_marker_catalog.gd` fuehrt jetzt einen kleinen gemeinsamen Marker-Typkatalog fuer Editor- und Mission-Marker mit Standardname, Farbe, Symbol, Kontext und Single-/Multi-Instance-Regel. `TerrainMapData` speichert Kartenmarker nicht mehr nur als nackte Positionen, sondern als Marker-Eintraege mit Typ, Name, Farbe, Symbol und Position; alte JSON-Dateien mit einfachem `x`/`y`-Markerformat bleiben rueckwaertskompatibel lesbar.
- Stand: Der Map-Editor besitzt jetzt eine echte Marker-Liste statt der alten festen Marker-Zeilen. Marker werden aus einer festen Typ-Liste angelegt, direkt auf der Karte platziert oder gezogen, per `DEL` geloescht, per Doppelklick umbenannt, auf Tile-Mitten eingerastet und auf demselben Feld nicht mehr gestapelt. Die festen Marker `spawn_alpha`, `spawn_bravo` und `objective_point` laufen ueber dieselbe Marker-Basis wie neue Editor-Typen wie `rally_point`, `danger_zone`, `loot_cache` und `recon_note`; die frueheren Flank-Anchors wurden spaeter entfernt.
- Stand: Die Taktikkarte konsumiert fuer Spielermarker denselben `mission_player`-Katalog. Das Wegpunkt-Kontextmenue wird daraus aufgebaut, neue oder verschobene Wegpunkte rasten auf Tile-Mitten ein, und `FireteamOrderVisualizer` nutzt dieselbe Symbolfamilie statt einer separaten Sondertabelle.
- Offene Punkte: Keine innerhalb des TASK-115-Slices; weitergehende Markerfamilien, echte Missionsmarker-Listen im Tactical-UI oder persistente Kampagnenmarker bleiben bewusst eigene Folgepfade.
- Risiken: Kartenmarker in `TerrainMapData` und spielerseitige Missionsmarker im Planning-State teilen jetzt Typkatalog und Symbolik, bleiben aber absichtlich getrennte Datenwahrheiten. Weitere Ausbaupfade sollten diesen Vertrag erweitern statt wieder separate Marker-Sonderlogik in Editor, Tactical-UI oder Meta-Map aufzubauen.
- Naechster Schritt: Nur bei Bedarf neue Folge-Tasks fuer zusaetzliche Marker-Typfamilien, tiefere Mission-Listenbearbeitung oder persistente Marker ueber Missionsgrenzen hinaus schneiden.

### TASK_116 - Runtime-Systeme aus scripts/tests herausloesen
- Status: implementiert
- Stand: Produktiv genutzte Tactical-/Runtime-Systeme liegen jetzt unter `scripts/tactical/` statt unter `scripts/tests`: `ad_hoc_order_controller.gd`, `contact_tracker.gd`, `fireteam_behavior_resolver.gd`, `fireteam_coordination_manager.gd`, `fireteam_movement_controller.gd`, `fireteam_security_controller.gd`, `flank_vulnerability_resolver.gd`, `overwatch_controller.gd` und `tactical_stance_controller.gd`.
- Stand: Rein lesende Visuals liegen unter `scripts/tactical/visuals/`: `contact_map_overlay.gd` und `fireteam_order_visualizer.gd`. `MissionTacticalSandboxController`, `MissionCombatLoopDriver` und die Verifier bleiben in `scripts/tests`, laden aber die produktiven Systeme aus den neuen Pfaden.
- Offene Punkte: Keine innerhalb dieses Pfad-Slices; die eigentliche Entflechtung von UI-/Driver-Gameplay-Wahrheit bleibt bewusst TASK_117 und TASK_118.
- Risiken: Der Task ist bewusst nur Move-/Import-Hygiene. Spaetere Runtime-Arbeiten sollten die neuen Produktivpfade verwenden und keine neuen produktiven Systeme unter `scripts/tests` anlegen.
- Naechster Schritt: TASK_117 kann Dropship-Deploys aus dem Tactical-Controller in autoritative `SimulationRoot`-Effects ueberfuehren.

### TASK_117 - Dropship-Deploy als SimulationRoot-Effects
- Status: implementiert
- Stand: `SimulationRoot` kennt jetzt die expliziten Effects `dropship_embark_unit` und `dropship_deploy_unit`. Bekannte, aber noch nicht in der `UnitRegistry` aktivierte Dropship-Passagiere koennen dadurch ueber `register_known_unit` positioniert, verborgen, sichtbar gemacht und beim Deboarding autoritativ in `UnitRegistry`, `RuntimeLeader` und `FTLRegistry` aktiviert werden.
- Stand: `MissionTacticalSandboxController` behaelt Dropship-Sequenz, UI-Texte, Marker und Preview-Visualisierung, enqueued in der Live-Mission aber nur noch Embark-/Deploy-/Presence-Effects. Direkte `global_position`-/`visible`-/Runtime-Status-Commits bleiben auf den non-authoritative Preview-Pfad begrenzt. Loadout-Modifier laufen nach dem Deploy weiter ueber den bestehenden Effect-Pfad.
- Offene Punkte: Die Dropship-Sequenz selbst ist weiterhin im Sandbox-Controller statt in einem eigenen produktiven Runtime-Modul gekapselt; ein tieferer Fahrzeug- oder Mission-Event-Controller bleibt bewusst ausserhalb dieses Tasks.
- Risiken: Der neue Effect-Vertrag ist V1-schmal und nimmt RuntimeLeader-/FTLRegistry-Pfade im Effect-Payload mit. Wenn spaeter echte Fahrzeug- oder Multiplayer-Flows entstehen, sollte dieser Vertrag zentral erweitert werden, statt wieder UI-nahe Sonderpfade fuer Deploy-Zustand einzufuehren.
- Naechster Schritt: TASK_118 kann Combat-Entscheidungen aus dem Mission-Driver herausloesen und damit den naechsten UI-/Testtreiber-Anteil aus der Gameplay-Wahrheit entfernen.

### TASK_118 - Combat-Entscheidungen aus MissionCombatLoopDriver herausloesen
- Status: implementiert
- Stand: `scripts/tactical/combat_fire_decision_resolver.gd` uebernimmt jetzt Zielwahl, Feuerfreigabe, Friendly-Contact-Gate und Damage-Effect-Payload-Aufbau. Der Resolver konsumiert vorhandene Callbacks fuer Detection, ContactTracker, Misidentification und FlankVulnerability, ohne selbst State zu committen.
- Stand: `scripts/tactical/medic_support_resolver.gd` uebernimmt Medic-Rollen-/Tool-Pruefung, Target-Priorisierung, Reichweitenentscheidung und Heal-/Move-Action-Auswahl. Der `MissionCombatLoopDriver` enqueued daraus weiter die autoritativen `heal`-Effects und Medic-Move-Commands.
- Offene Punkte: Enemy-Advance, Reposition-on-Damage, Bleedout-Queueing und Leadership-Nachfolge liegen weiterhin im Driver. Sie sind bewusst nicht in diesem ersten Struktur-Slice mitgezogen, damit Combat-Verhalten stabil bleibt.
- Risiken: Die Resolver arbeiten weiterhin mit Node-Referenzen und Driver-Callbacks, weil die bestehende Testmission noch keine vollstaendige produktive Combat-Context-Schicht besitzt. Spaetere Tasks sollten diese Context-Schnittstelle konsolidieren, statt neue Inline-Entscheidungen im Driver anzulegen.
- Naechster Schritt: TASK_119 kann auf dem ausgelagerten Fire-Decision-Payload aufsetzen und `roll_override`/RNG sauber deterministisch begrenzen.

### TASK_119 - Seeded Combat RNG und roll_override begrenzen
- Status: implementiert
- Stand: `SimulationRoot` besitzt jetzt einen kleinen seedbaren Combat-RNG (`combat_rng_seed`, `set_combat_rng_seed()`, `get_next_combat_roll()`) und zieht im autoritativen Damage-Pfad daraus den Trefferwurf, sobald ein Damage-Effect keinen expliziten `roll_override` mitbringt.
- Stand: Normale Fire-Decision-Payloads aus `CombatFireDecisionResolver` und Overwatch-Damage-Effects setzen keinen festen `roll_override` mehr. Der Override bleibt im Effect-Vertrag nur fuer gezielte Test-/Debug-Payloads erhalten, damit Verifier einzelne Treffer- oder Fehlschlagfaelle weiter exakt pruefen koennen.
- Offene Punkte: Kein Replay-/Rollback-Framework und keine Multiplayer-RNG-Synchronisierung jenseits des seedbaren autoritativen Pfads. Das bleibt bewusst ein spaeterer Netcode-/Server-Tick-Scope.
- Risiken: Der RNG sitzt jetzt an der richtigen autoritativen Stelle, aber die bestehende Testmission benutzt weiterhin Node-basierte Driver-/Resolver-Kontexte. Spaetere Multiplayer-Arbeit sollte den Seed-/Tick-Vertrag zentral erweitern, statt Zufallsquellen in Resolver oder UI zurueckzubringen.
- Naechster Schritt: TASK_120 kann Teamqualitaet/FTL-Ausfuehrungsfaktoren auf dem jetzt wieder probabilistischen Combat-Pfad modellieren, ohne feste Live-Rolls zu kaschieren.

### TASK_120 - Teamqualitaet als FTL-Ausfuehrungsfaktor
- Status: implementiert
- Stand: `FireteamBehaviorProfile` enthaelt jetzt einen kompakten Ausfuehrungsprofil-Satz (`order_fidelity`, `reaction_delay_seconds`, `execution_cohesion`, `execution_fire_discipline`, `contact_stability`, `initiative`, `execution_label`). `FireteamBehaviorResolver` leitet diese Werte aus vorhandenen Team-/Leaderdaten, Discipline, Recognition und Traits ab, ohne neue Persistenz oder Sozialdynamik einzufuehren.
- Stand: `FireteamMovementController` konsumiert das Ausfuehrungsprofil beim Start von Movement-/Order-Ausfuehrung. Niedrige Order Fidelity erzeugt einen kleinen deterministischen Ziel-Offset, niedrige Cohesion vergroessert Formationstreuung, und Initiative beeinflusst den Bewegungstempo-Multiplikator. Die Tactical UI zeigt diese Werte nur lesend als `EXEC`-Status mit Feedback wie `CLEAN EXEC`, `DELAY`, `SCATTER`, `LOW DISC` oder `STEADY`.
- Offene Punkte: Keine tiefere Teamchemie, keine Kampagnen-Persistenz und kein umfassendes Morale-/Social-System. Reaction Delay ist als Profilwert vorhanden, wird aber in diesem V1-Slice noch nicht als echte Startwartezeit getaktet.
- Risiken: Die Werte sind bewusst kleine Ausfuehrungsmodifikatoren. Spaetere Teamchemie sollte den vorhandenen Profilvertrag erweitern, statt UI- oder Driver-seitig neue Berechnungen einzufuehren.
- Naechster Schritt: Weitere Teamqualitaetswirkung nur als klarer Folge-Task, z.B. echte Tick-basierte Reaktionsverzoegerung oder breitere Contact-/Morale-Kopplung.

### TASK_121 - Area Order Marker
- Status: implementiert
- Stand: `AreaOrder` unter `scripts/command/area_order.gd` formalisiert den missionslokalen Datenvertrag fuer Gebietsmarker mit `area_order_id`, `fireteam_id`, `command_type`, Tile-/Polygon-Daten, `center_position`, `created_at_order_index` und `status`.
- Stand: `MissionTacticalSandboxController` haelt Area Orders getrennt von der Waypoint-Ausfuehrung im Planning-State-Feld `area_orders`. Spieler koennen per `SHIFT+Drag` einfache Rechteckgebiete aus Terrain-Tiles markieren; ohne TerrainRegistry wird ein Polygon-Fallback gespeichert. Das Kontextmenue klassifiziert Gebiete als `defend`, `engage`, `take` oder `flank`.
- Stand: `FireteamOrderVisualizer` zeichnet Area Orders als eigenen Layer getrennt von normalen Wegpunktlinien und stellt `get_visible_area_orders()` sowie Hit-Tests fuer das Area-Menue bereit. Bestehende Einzel-Wegpunkte bleiben unveraendert nutzbar.
- Offene Punkte: Keine echte Defend-/Attack-Semantik, keine Gegner-KI-Reaktion und keine Kampagnenpersistenz; diese Punkte bleiben bewusst Folge-Tasks 122+.
- Risiken: Die Area-Auswahl ist bewusst V1-schmal und rechteckbasiert. Spaetere Polygon-Editor-Funktionen sollten auf dem vorhandenen Datenvertrag aufsetzen, ohne Gameplay-Wahrheit in UI-Code zu verlagern.
- Naechster Schritt: TASK_122 kann Defend-Semantik auf Basis der gespeicherten Area Orders ergaenzen, ohne den Marker-/Planning-Roundtrip erneut zu bauen.

### TASK_122 - Defend Area Semantik
- Status: implementiert
- Stand: `scripts/tactical/area_order_resolver.gd` waehlt fuer `defend`-Area-Orders pro fittem Fireteam-Mitglied eine Halteposition. Der Resolver bevorzugt vorhandene Area-Tiles, meidet nicht-walkable Tiles ueber `TerrainRegistry`, nutzt Cover-Werte als Score und haelt den FTL in Zentrumsnaehe oder auf einer guten Coverposition.
- Stand: `MissionTacticalSandboxController` startet Defend-Area-Ausfuehrung per GO, enqueued Bewegungsbefehle ueber `SimulationRoot`, tracked den missionslokalen Area-Defense-State und schaltet nach Erreichen auf `WARTET AUF GO | HALTET GEBIET`. Ein weiterer GO kann die aktive Area-Defense wieder freigeben.
- Stand: `FireteamSecurityController` konsumiert optionalen Area-Kontext; Security-Snapshots enthalten jetzt `area_order_id`, `area_center_position` und `area_status` und nutzen das Gebiet als Anchor fuer Sektoren/Overwatch. #17 zeigt Defend-Area-Status und die Tactical-Statuszeile zaehlt offene Gebiete mit.
- Offene Punkte: Keine komplexe Gebaeuderaum-KI, keine Fortifikation und keine langfristige Munitions-/Morale-Simulation.
- Risiken: Der Pfad ist bewusst ein V1-Verteiler mit vorhandenen Terrain-/Cover-Daten. Spaetere Attack-/Take-Area-Semantik sollte den Resolver erweitern oder eigene Resolver nutzen, statt Area-Ausfuehrung in UI-Code zu verlagern.
- Naechster Schritt: TASK_123 kann `engage`/`take`-Area-Semantik auf dem vorhandenen Area-Order- und Resolver-Vertrag aufbauen.

### TASK_123 - Attack Area Semantik
- Status: implementiert
- Stand: `AreaOrderResolver` loest offensive `engage`-/`take`-/`flank`-Areas in Zielgebiet, Approach-Punkt und Fireteam-Approach-Formation auf. Der Approach entsteht auf der freundlichen Seite ausserhalb bzw. am Rand des Zielgebiets und kann ueber die vorhandene `TerrainRegistry` auf walkable Tiles geschnappt werden.
- Stand: `MissionTacticalSandboxController` startet Attack-Area-Ausfuehrung per GO, enqueued `engage_area`-UnitCommands ueber `SimulationRoot`, tracked den missionslokalen Attack-Area-State und schaltet nach Gebietssicherung auf `GESICHERT | WARTET AUF GO | HALTET GEBIET` mit Area-Security-Kontext.
- Stand: `MissionCombatLoopDriver` reicht den aktiven Attack-Area-Kontext an `CombatFireDecisionResolver` weiter. Der Resolver priorisiert Ziele innerhalb des markierten Zielgebiets, ohne die bestehende Damage-Formel oder den autoritativen Damage-Pfad zu veraendern.
- Offene Punkte: Keine Multi-Assault-Lanes, keine Smoke-/Breach-/Spezialausruestung und keine neue Gegner-KI in diesem Slice.
- Risiken: Attack Areas bleiben bewusst eine V1-Semantik ueber vorhandenen Movement-/Combat-/Security-Schichten. Spaetere Assault-Planung sollte den Resolver-Vertrag erweitern, statt ein zweites Combat- oder Bewegungssystem einzufuehren.
- Naechster Schritt: TASK_124 kann die Area-Zustaende in #17 lesbar zusammenfassen, ohne neue World-Debugtexte einzufuehren.

### TASK_124 - Area Feedback in #17 Selected Fireteam
- Status: implementiert
- Stand: #17 baut Area-Statuszeilen jetzt ueber eine gemeinsame Snapshot-Formatierung fuer geplante und aktive Defend-/Attack-/Take-/Flank-Areas. Die Anzeige enthaelt Area-Typ, Feldanzahl bzw. Take-Fortschritt, Ausfuehrungsmodus, Security-Kurzstatus, Contact-Status und GO-Wartezustand.
- Stand: Mehrfachauswahl bleibt kompakt, indem `_build_selected_waypoint_info_text()` weiter eine Zeile pro Fireteam ausgibt. Die Area-Zeilen ersetzen keine Gameplay-Wahrheit, sondern lesen nur vorhandene Area-, Security- und Contact-Snapshots.
- Stand: Das World-Overlay bleibt unveraendert reduziert; es wurden keine neuen langen NPC-Labels oder Debugzeilen ueber Figuren eingefuehrt.
- Offene Punkte: Keine neue Detailansicht, keine permanente Debug-Konsole und keine Charakterblattwerte in #17.
- Risiken: Statuszeilen koennen schnell zu dicht werden. Folgearbeiten sollten lieber kurze, spielnahe Worte ergaenzen statt rohe Debugfelder in #17 zu kippen.
- Naechster Schritt: TASK_125 kann Terrain-Blocker- und Walkability-Debugging pruefen, ohne #17 weiter auszubauen.

### TASK_125 - Terrain Blocker Debug und Walkability Tests
- Status: implementiert
- Stand: `TerrainRegistry.resolve_walkable_target()` loest Move-Zielpunkte jetzt mit Originalziel, Walkability, geblocktem Tile, stabilem Ersatz-Ziel und Blockergrund auf. `get_nearest_walkable_grid()` sortiert walkable Kandidaten deterministisch nach Distanz und Grid-Koordinaten, damit Ersatztiles bei Gleichstand nicht springen.
- Stand: `SimulationRoot` nutzt diese Zielauflosung vor dem Pfadbau. Nicht-walkable Ziele werden auf walkable Ersatzpunkte verschoben; bei nicht erreichbaren walkable Zielen gibt es keinen direkten Geradeaus-Fallback durch Blocker mehr, sondern einen stabilen erreichbaren walkable Fallback oder keinen Move-Pfad.
- Stand: Terrain-Move-Debugging ist abschaltbar in `SimulationRoot` verfuegbar und wird vom `MissionTacticalSandboxController` lesbar als Zeile mit Originalziel, Ersatz-Ziel, finalem Ziel und Grund exponiert. `task_125_verifier.gd` deckt Rock-Ziel, stabile Ersatzauflosung, Pfad um Blocker, unerreichbares Ziel ohne Tunneling und Debugtext ab.
- Offene Punkte: Kein neuer Navigation-Stack, keine Physics-Kollisionssimulation und keine Map-Editor-Ueberarbeitung. Diese Grenzen bleiben bewusst ausserhalb von TASK_125.
- Risiken: Der neue Fallback ist konservativ. Wenn ein Ziel nicht erreichbar ist, bleibt die Unit am naechsten stabil erreichbaren walkable Punkt statt optisch in Richtung Blocker weiterzudruecken.
- Naechster Schritt: Die Area-Order-Reihe 121-125 ist damit fachlich abgeschlossen; weitere Navigationsthemen sollten als eigener Task mit klarer Path-Follow- oder Nav-Stack-Zielsetzung geschnitten werden.

### TASK_126 - HPA Navigation Foundation
- Status: implementiert
- Stand: `scripts/terrain/hpa_navigation_graph.gd` baut aus der vorhandenen `TerrainRegistry` eine abgeleitete HPA-Grundlage mit deterministischen Clustern, walkable Tiles, lokalen Komponenten, Portalen und abstrakten Komponenten-Nachbarschaften.
- Stand: Portale nutzen dieselben Traversal-Regeln wie `TerrainPathfinder`, inklusive Diagonalbewegung ohne Corner-Cutting durch Blocker sowie Hoehen-/Slope-Regeln. `TerrainPathfinder` exposes dafuer eine kleine lesende API fuer Neighbor-Richtungen und Step-Pruefung.
- Stand: `scripts/tests/task_126_verifier.gd` deckt Graph-Aufbau, Cluster-Zuordnung, Blocker-Komponenten, walkable Portale, abstrakte Nachbarschaften und Diagonal-Corner-Regeln ab.
- Offene Punkte: HPA wird in diesem Task noch nicht fuer Live-Movement verwendet. Die Integration in `SimulationRoot` und lange Pfadqueries bleibt TASK_127.
- Risiken: Cluster-Groesse und Portal-Dichte sind V1-Parameter. Spaetere Performance-Arbeit sollte diese Werte ueber Messungen aus TASK_128 justieren.
- Naechster Schritt: TASK_127 kann den HPA-Graphen in einen hierarchischen Pathfinder ueberfuehren und optional im autoritativen Move-Pfad verwenden.

### TASK_127 - HPA Pathfinder Integration
- Status: implementiert
- Stand: `scripts/terrain/hpa_pathfinder.gd` setzt die HPA-Grundlage aus TASK_126 in konkrete Pfadqueries um. Same-Cluster-Wege laufen weiter direkt ueber `TerrainPathfinder`, Multi-Cluster-Wege werden ueber abstrakte Portalrouten gesucht und anschliessend aus lokalen Tile-Pfadsegmenten zusammengesetzt.
- Stand: `SimulationRoot` baut und cached den HPA-Graphen pro `TerrainRegistry` und nutzt den HPA-Pfadfinder im autoritativen Move-Pfad. Wenn Start und Ziel in unverbundenen HPA-Komponenten liegen, wird kein globaler Full-Map-Fallback gegen das unerreichbare Ziel gestartet; stattdessen wird ein stabiler walkable Fallback innerhalb der Start-Komponente gewaehlt.
- Stand: `HPANavigationGraph` exposed dafuer eine lesende `get_component_tiles()`-API. `scripts/tests/task_127_verifier.gd` deckt Same-Cluster-Pfade, Multi-Cluster-Portalpfade, disconnected early-fail, SimulationRoot-Ausfuehrung und unreachable-Fallback ab.
- Offene Punkte: Keine dynamischen Kartenupdates und keine Flow-Fields. Lokale Teilpfade nutzen weiterhin den bestehenden `TerrainPathfinder`, damit Walkability-, Hoehen- und Diagonalregeln identisch bleiben.
- Risiken: Der Graph-Cache invalidiert aktuell ueber Registry-Referenz und Tile-Anzahl, nicht ueber jede moegliche Walkability-Aenderung. Portalpfade koennen in V1 noch kantiger wirken als spaetere geglaettete Routen.
- Naechster Schritt: TASK_129 kann auf den Budget-/Debug-Messpunkten aufsetzen und deckungsbewusste Pfadkosten einfuehren.

### TASK_128 - Navigation Budgeting und Debug
- Status: implementiert
- Stand: `SimulationRoot` besitzt jetzt ein konfigurierbares Navigation-Budget fuer neue Pfadrequests pro Physics-Tick (`navigation_budget_enabled`, `navigation_max_new_path_queries_per_tick`). Wenn das Budget erschoepft ist, werden Move-Commands mit Delay-Grund deterministisch ueber die bestehende Prioritaets- und Queue-Reihenfolge in einen spaeteren Tick requeued.
- Stand: `get_navigation_debug_snapshot()` liefert lesende Metriken fuer neue Path-Requests, konkrete Pathfinder-Queries, Fallbacks, unreachable Queries, Delays, Pending Count, letzte Query-Records und die teuerste Query. Query-Records unterscheiden HPA, direkten A*, Fallback und Delay und enthalten grobe Kandidaten-/Expanded-Schaetzwerte.
- Stand: Contact-Recompute laeuft durch denselben Budgetpfad, sodass mehrere Units im Kontakt nicht mehr im selben Frame eine Pfadquery-Spitze erzeugen. `scripts/tests/task_128_verifier.gd` deckt Snapshot-Zaehler, Budget-Limit, deterministische Delay-Reihenfolge, Contact-Staffelung und unreachable-Debug ab.
- Offene Punkte: Keine Worker-Threads, keine UI-Pflichtanzeige und keine Multiplayer-Synchronisierung der Navigation-Metriken. Fallback-Kandidaten bleiben bewusst grob geschaetzt, bis TASK_129/130 echte Messdaten fuer neue Path-Schichten liefern.
- Risiken: Ein niedriges Budget kann sichtbare Startverzoegerungen bei grossen Sammelbefehlen erzeugen; der Snapshot macht diese Pending- und Delay-Gruende deshalb explizit sichtbar.
- Naechster Schritt: TASK_129 kann deckungsbewusste Pfadkosten aufsetzen, ohne CPU-Spitzen ungezaehlt zu lassen.

### TASK_129 - Deckungsbewusste Pfade mit HPA und Subgoal-Vorbereitung
- Status: implementiert
- Stand: `TerrainPathfinder` besitzt jetzt einen optionalen Cover-/Exposure-Kostenvertrag (`find_path_with_options`, `score_path`, `get_exposure_score`). Die Basisregeln fuer Walkability, Hoehen, Diagonalen und Corner-Cutting bleiben identisch; ohne Optionen laeuft der alte Pfad weiter.
- Stand: `HPAPathfinder` reicht Kostenoptionen in Same-Cluster- und lokale Portal-Segmente weiter. `HPANavigationGraph` annotiert Portale mit `mean_cover` und `min_cover`, damit spaetere Subgoal-/Portalentscheidungen bereits lesbare Cover-Metadaten besitzen.
- Stand: `SimulationRoot` kann Cover-aware Navigation ueber Export oder Command-Feld aktivieren, Hazard-Grids/-Positionen aus Commands ableiten und Risikogewichte nach `source_command_type` (`move`, `defend`, `take`/`engage`, `flank`, `rush`) setzen. Der Navigation-Debug-Snapshot enthaelt jetzt letzte Pfadmetriken wie `path_length_grid`, `exposure_sum`, `cover_sum`, Mittelwerte und `path_cost`.
- Offene Punkte: Keine echte Subgoal-Graph-Suche, keine dynamische Threat-Map aus dem Combat-Loop und keine UI-Pflichtanzeige. Threat-/Hazard-Positionen muessen in diesem Slice explizit ueber Command-Daten oder Tests kommen.
- Risiken: Hohe Exposure-/Cover-Gewichte koennen Umwege stark bevorzugen; deshalb bleiben Cover-aware Kosten standardmaessig deaktiviert und pro Command/Export steuerbar.
- Naechster Schritt: TASK_130 kann lokale Avoidance/ORCA-Light auf den resultierenden Wunschpfaden aufsetzen, ohne die globale Pfadkostenlogik zu ersetzen.

### TASK_130 - Lokale Unit-Avoidance mit ORCA/RVO-Light
- Status: implementiert
- Stand: `scripts/tactical/local_avoidance_resolver.gd` fuehrt eine kleine deterministische ORCA/RVO-Light-Schicht ein: registrierte Units werden pro Tick in einen Spatial-Grid gelegt, Nachbarn sortiert abgefragt und die lokale Wunschvelocity mit Separation-/Sidestep-Korrekturen geclippt.
- Stand: `SimulationRoot` integriert die Avoidance optional nach globalem Pfadbau und vor dem autoritativen Positions-Commit. Die Route bleibt HPA/A*, Avoidance veraendert nur die lokale Velocity zum naechsten Pathpoint. Nach jedem Move wird der Spatial-Grid aktualisiert, damit spaeter verarbeitete Commands aktuelle Positionen sehen.
- Stand: Terrain-Sicherheit prueft korrigierte Zielpositionen gegen `TerrainRegistry.is_walkable()`. Nicht-walkable Korrekturen werden verworfen oder bei komplett geblockter Bewegung auf `Vector2.ZERO` reduziert. `get_local_avoidance_debug_snapshot()` liefert Neighbor Count, Avoidance Velocity, Korrektur, Stuck-Zeit, Deadlock-Markierung, verworfene Korrekturen und Dauer.
- Offene Punkte: Kein vollstaendiger RVO2-/ORCA-LP-Solver, keine Formation-Slot-Swaps und keine tausende-Units-Optimierung. Die Schicht ist bewusst V1 und standardmaessig abschaltbar.
- Risiken: Zu starke lokale Korrekturen koennen Formationen optisch lockern; deshalb sind Radius, Nachbarschaft, Debug und Aktivierung explizit konfigurierbar.
- Naechster Schritt: Phase 17N ist damit lokal abgeschlossen; weitere Navigationserweiterungen sollten erst nach Spielgefuehl-/Performance-Review geschnitten werden.

### TASK_131 - Navigation Benchmark Harness
- Status: implementiert
- Stand: `scripts/tests/navigation_benchmark_harness.gd` fuehrt reproduzierbare Headless-Benchmarks fuer offene Pfadqueries, Korridor/Engpass-Queries, Cover-/Exposure-Routing, Navigation-Budget-Delays und lokale Avoidance-Ausfuehrung aus.
- Stand: `scripts/tests/task_131_verifier.gd` prueft, dass HPA/A*, Cover-aware HPA, Budgeting und Avoidance getrennt messbare Dictionary-Metriken liefern. Der Output enthaelt Query-Zeiten, Pfadlaengen, Exposure-/Cover-Summen, Delay-/Pending-Werte sowie Stuck-/Deadlock-Metriken.
- Offene Punkte: Keine produktive JPS-, D* Lite-, CBS- oder Reservierungslogik. Der Harness misst vorhandene Systeme und bleibt unter `scripts/tests`.
- Risiken: Benchmark-Szenarien sind kleine Laborkarten und ersetzen keine grossen Playtests in `mission_fireteam_dev_test.tscn`; sie schaffen aber eine stabile Basis fuer Folgeentscheidungen.
- Naechster Schritt: TASK_151 kann Engpass-Reservierung/MAPF-Light auf Basis der gemessenen Bottleneck- und Avoidance-Werte schneiden.

### TASK_151 - Engpass-Reservierung und MAPF-Light
- Status: implementiert
- Stand: `scripts/tactical/bottleneck_reservation_resolver.gd` erstellt kleine Bottleneck-Kandidaten aus HPA-Portalen, schmalen Korridorzellen oder expliziten Zellen und plant deterministische Zeitfenster fuer kleine Agentengruppen.
- Stand: Der Resolver sortiert nach Command-Prioritaet, Fireteam-ID, Unit-ID und Queue-Reihenfolge, prueft gleiche Zelle/Zeit sowie Gegenverkehr ueber dieselbe Kante und schreibt nur Command-Metadaten/Debug, keine direkte Unit-Bewegung.
- Stand: `SimulationRoot` hat eine standardmaessig deaktivierte Bottleneck-Reservation-Anbindung mit Debug-Snapshot. Lokale Avoidance, HPA/A* und Minimum-Spacing bleiben die bestehenden Bewegungssysteme.
- Offene Punkte: Keine im TASK-151-Scope; echte Missionskorridore sollten spaeter manuell auf Spielgefuehl und steife Wartefenster geprueft werden.
- Risiken: Zu aggressive Aktivierung kann Bewegung steif wirken lassen. Deshalb ist die Runtime-Anbindung optional und der Resolver fuer kleine Horizonte/Agentengruppen begrenzt.
- Lokale Pruefung: `task_151_verifier.gd`, `task_131_verifier.gd`, `task_130_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_152 fuer seedbares Cover-Placement-Lab umsetzen.

### TASK_152 - Seeded Cover Placement Lab
- Status: implementiert
- Stand: `scripts/terrain/cover_placement_lab.gd` erzeugt seedbare Cover-Vorschlaege aus walkable Terrain-Tiles. Das Scoring nutzt Threat-/LOS-Exposure, Objective-/Approach-Naehe, vorhandene Cover-Werte und einen winzigen seedbaren Tie-Breaker.
- Stand: Die Auswahl laeuft greedily mit Mindestabstand und gibt reine Terrain-Patch-Dictionaries mit `grid_position`, `cover_value` und optionalen `blocks_los`-/`walkable`-Feldern zurueck. Das Lab veraendert keine laufende Mission und ersetzt keine Designer-Platzierung.
- Stand: `scripts/tests/task_152_verifier.gd` prueft reproduzierbare Seeds, Mindestabstand, Walkability, LOS-/Threat-Scoring, Patchform und verbesserte Cover-aware Path-Metriken nach Anwendung auf eine Testkarte.
- Offene Punkte: Keine im TASK-152-Scope; Editor-Anwendung und kuenstlerische Cover-Verteilung bleiben separate UX-/Content-Slices.
- Risiken: Automatisch erzeugte Deckung kann spielerisch gleichfoermig wirken. Das Lab ist ein Fixture-/Authoring-Helfer, nicht die finale Encounter-Gestaltung.
- Lokale Pruefung: `task_152_verifier.gd`, `task_129_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_153 fuer 3D-Transparency-Material-Presets umsetzen.

### Editor Cleanup - Flank Anchor Marker
- Status: implementiert
- Stand: Die veralteten festen Mapmarker `flank_anchor_left` und `flank_anchor_right` sind aus Marker-Katalog, Editor-Festmarkerzeilen, Standardmap und Missions-Setup-Fallback entfernt. Der eigentliche `flank`-Befehl, Flank-Areas und die Flank-Vulnerability-Logik bleiben unveraendert.
- Offene Punkte: Alte externe Karten, die diese Marker noch enthalten, laden sie nach dem Entfernen aus dem Katalog als Custom-Marker, falls sie nicht vorher bereinigt werden.
- Risiken: Keine Runtime-Abhaengigkeit wurde gefunden; die Anchors waren nur noch Editor-/Map-Altlasten.
- Naechster Schritt: Bei Bedarf alte Karten einmal im Editor neu speichern, damit die Custom-Altmarker aus den JSON-Dateien verschwinden.

### Editor Slot Limit
- Status: implementiert
- Stand: Der Map-Editor erlaubt fuer `mission_slot_count` jetzt bis zu 50 Slots pro Seite statt der bisherigen 8er-Obergrenze. Die gespeicherten Map-Daten bleiben unveraendert ein einfacher `mission_slot_count`-Wert.
- Offene Punkte: Die Meta-/FOB-UI zeigt die hoehere Kapazitaet an, erzeugt dadurch aber noch keine 50 sichtbaren Missions-Unit-Nodes.
- Risiken: Das ist zunaechst eine Editor-/Kapazitaetsfreigabe; groessere Live-Teams brauchen weiterhin passende Spawn-/Roster-/Performance-Folgearbeit.
- Naechster Schritt: Bei Bedarf separate Tasks fuer 50er-Spawnverteilung und Meta-Roster-Skalierung schneiden.

### TASK_132 - Kenney Isometric Asset Palette Expansion
- Status: implementiert
- Stand: Der Tile-Katalog enthaelt jetzt 44 kuratierte Kenney-Isometric-Asset-Tile-Typen in acht neuen Palette-Gruppen: `deko`, `technik`, `gebaeude`, `plattformen`, `pipes`, `rails`, `crater` und `fahrzeuge`. Die Auswahl nutzt vollstaendige Richtungssaetze fuer Faesser, Generatoren, Satellitenschuesseln, Gebaeude, Plattformen, Rohre, Schienen, Krater und Speeder. Diese neuen Gruppen laufen als Objekt-Layer ueber `object_type_id`: der Bodentile bleibt in `type_id` erhalten, der Renderer zeichnet danach das Objekt-Overlay in einem eigenen `ObjectContainer`, und alte bereits gemalte Objekt-`type_id`s rendern weiterhin mit Boden darunter. Die Defaults bleiben konservativ: kleine Deko blockt keine LOS, grosse Technik-/Gebaeude-/Fahrzeugobjekte sind nicht begehbar und koennen LOS/Cover liefern, flache Plattform-/Rail-/Crater-Tiles bleiben begehbar. Die Editor-Palette zeigt Kataloggruppen nun als nicht auswaehlbare Header, damit die neue Asset-Menge scanbar bleibt.
- Offene Punkte: Kein automatischer Vollimport; weitere Kenney-Familien sollten weiterhin kuratiert und mit sichtbarer Editor-Pruefung ergaenzt werden.
- Risiken: Grosse Sprites koennen visuell noch spezifische Anchor-/Offset-Nacharbeit brauchen; Gameplay-Werte sind bewusst defensive V1-Defaults und werden aktuell noch als aggregierte Tile-Felder gespeichert, nicht als getrennte Objekt-/Boden-Gameplaywerte.
- Naechster Schritt: Bei Bedarf eine zweite Palette-Erweiterung fuer Gates, Turrets, Monorail oder Desks schneiden, nachdem die aktuelle Auswahl im Editor visuell geprueft wurde.

### TASK_153 - 3D Transparency Material Presets
- Status: implementiert
- Stand: `scripts/rendering/material_preset_factory.gd` erzeugt die drei Presets `cutout_scissor`, `dither_hash` und `true_blend` als `StandardMaterial3D`-Materialien mit dokumentiertem visual-only Vertrag.
- Stand: `scenes/tests/transparent_material_benchmark.tscn` nutzt `scripts/rendering/transparency_material_benchmark.gd`, um drei Quad-Previews nebeneinander fuer Scissor, Hash und Blend aufzubauen.
- Stand: `docs/rendering/3d_transparency_material_presets.md` beschreibt Einsatzregeln, Factory-Nutzung, Benchmark-Szene, Profiler-Hinweise und die Grenze zu Gameplay/LOS/Navigation.
- Offene Punkte: Manueller Godot-Sichtcheck der Beispielszene bleibt fuer echte Sortier-/Kanten-/Profilerbeurteilung offen.
- Risiken: Alpha Blend kann Overdraw und Sorting verschlechtern; deshalb bleibt `true_blend` als Ausnahme fuer echte Halbtransparenz dokumentiert.
- Lokale Pruefung: `task_153_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Bei neuen transparenten Assets zuerst diese Presets nutzen und die Beispielszene fuer Sicht-/Profilerchecks erweitern.

### Mission Editor Authoring Audit
- Status: dokumentiert
- Stand: `docs/mission_editor_authoring_audit.md` haelt fest, dass der bestehende Map-Editor Terrain, Marker, Mission-Slots und Patrol-Pfade authoren kann, aber noch keinen eigenen taktischen Missionsszenario-Vertrag besitzt. Die LZ bleibt bewusst ausserhalb des Editor-Scopes und wird immer vom Spieler im Missionsflow gesetzt.
- Offene Punkte: Szenario-Datenvertrag, Editor-MVP und Editor-to-Live-Validation sind implementiert; der manuelle GUI-Durchlauf bleibt fuer sichtbare UX/3D-primary Branches weiterhin sinnvoll.
- Risiken: Wenn TerrainMapData, Editor-UI oder Szenario-Dateien zu viel laufenden Gameplay-State aufnehmen, entsteht eine zweite Gameplay-Wahrheit neben SimulationRoot/TacticalController.
- Naechster Schritt: Nach Review koennen breitere Szenariovarianten oder produktive Meta-Katalog-Anbindung als eigene Tasks geschnitten werden.

### TASK_155 - Tactical Mission Test Presets
- Status: implementiert
- Stand: Unter `res://data/mission_presets/` existieren fuenf kleine taktische Presets: `attack_area_two_contacts`, `defend_area_contact_relay`, `patrol_contact_transition`, `dropship_insertion_first_contact` und `take_area_objective`. Sie referenzieren die vorhandene kleine Testkarte, Objective-Marker, bestehende Enemy-TestUnits, Wellenparameter, Patrol-Pfade und optionale Testnotizen.
- Stand: `scripts/tests/mission_preset_loader.gd` laedt und validiert die Presets, setzt `MissionTestSetup.map_file_path`, konfiguriert `EnemyWaveController`/Combat-Testparameter und injiziert Enemy-Positionen sowie Patrol-Pfade deterministisch in die Live-Mission. LZ-Felder werden rekursiv abgelehnt.
- Stand: `scripts/tests/task_155_verifier.gd` prueft Preset-Parsing, Map-Existenz, Live-Mission-Anwendung, sichtbare Objective-/Enemy-Setups, Patrol-Zuordnung, Attack-Area-Reproduzierbarkeit, Patrol-Stopp bei Kontaktbedingungen und Dropship-Preset ohne gespeicherte Spieler-LZ.
- Offene Punkte: Kein finaler Missionsszenario-Vertrag, keine Editor-UI und keine Meta-Katalog-Anbindung in diesem Task.
- Risiken: Die Presets duerfen nicht zur zweiten Missionsimplementierung wachsen; sie bleiben Test-/Authoringdaten und halten keinen laufenden Gameplay-State.
- Naechster Schritt: Die Presets koennen in TASK_157 als schnelle Testauswahl fuer den Editor-MVP dienen.

### TASK_156 - Mission Scenario Data Contract
- Status: implementiert
- Stand: `scripts/mission/mission_scenario_data.gd` definiert einen scene-unabhaengigen `MissionScenarioData`-Vertrag fuer Authoring-/Setupdaten vor Missionsstart. Der Vertrag enthaelt `scenario_id`, `display_name`, `map_file_path`, Zeitlimit, optionalen Slot-Override, Objective, Enemy-Groups, Wave-Config, Patrol-Bindings und Notizen.
- Stand: JSON-Load/Save nutzt ein `version`-Feld, robuste Defaults und einen kanonischen `to_dict()`-Roundtrip. Validierung meldet fehlende Maps, fehlende oder nicht aufloesbare Objectives, doppelte Gegner-IDs, fehlerhafte Wave-Parameter und Patrol-Bindings, die auf keine bekannten Gegner- oder Map-Spawn-/Patrol-IDs zeigen.
- Stand: LZ-nahe Felder werden rekursiv abgelehnt und nicht serialisiert. Die Szenario-Dateien unter `res://data/mission_scenarios/` spiegeln die TASK_155-Testfaelle als editornahe Authoringdaten, ohne Terrain, Marker, Patrol-Pfade oder laufenden Gameplay-State aus `TerrainMapData` zu duplizieren.
- Stand: `maps/task_156_contract_map.json` dient als kleine Contract-Fixture-Map mit `spawn_alpha`, `spawn_bravo` und `objective_point`, damit der Verifier schnell bleibt.
- Offene Punkte: Keine Editor-UI, keine automatische Meta-Katalog-Umstellung und noch keine Live-Mission-Loader-Umschaltung in diesem Task.
- Risiken: Der Vertrag darf spaeter nicht zum zweiten Missionskern werden; er bleibt Setup-/Authoringdaten vor dem Start, waehrend Runtime-Mutationen weiter ueber SimulationRoot und Controller laufen.
- Naechster Schritt: `TASK_158 - Editor-to-Live Mission Validation` kann den Vertrag mit weiteren Live-Szenariovarianten absichern.

### TASK_157 - Tactical Mission Editor MVP
- Status: implementiert
- Stand: Der bestehende Map-Editor besitzt jetzt ein schlankes Mission-Scenario-Panel. Es kann Scenario-Dateien laden/speichern, die aktuelle Map referenzieren, Objective-Marker oder Objective-Positionen setzen, Capture-Radius/Zeitlimit bearbeiten, Gegner-IDs/Gruppen, Spawn-Marker oder Spawn-Positionen, Wave-Parameter und Patrol-Bindings authoren.
- Stand: `MissionTestSetup` kann optional `scenario_file_path` laden und uebernimmt daraus Map, Objective-Regeln, Enemy-IDs/Spawn, Wave-Config und Patrol-Bindings in die Live-Testmission. Objective-Regeln werden weiter an `SimulationRoot.set_objective_status()` uebergeben; Patrols gehen an `EnemyWaveController`.
- Stand: `MissionScenarioData` serialisiert optionale `enemy_groups[].spawn_position` und validiert, dass Enemy-Groups Spawn-Marker oder Spawn-Position besitzen. LZ-Felder bleiben rekursiv verboten.
- Stand: `maps/task_157_editor_mvp_map.json`, `data/mission_scenarios/task_157_editor_mvp.json` und `scripts/tests/task_157_verifier.gd` decken Editor-Load/Edit/Save, Live-Teststart, Objective-Propagation, Wave-Propagation, Patrol-Bindings und fehlende gespeicherte Spieler-LZ ab.
- Offene Punkte: Der manuelle GUI-Durchlauf der Editor-UX bleibt offen; TASK_158 sollte mehr Editor-to-Live-Szenariovarianten und Fehlerfaelle pruefen.
- Risiken: Das Mission-Panel ist bewusst MVP und textbasiert fuer Patrol-Bindings; eine groessere Designer-UX sollte erst nach der Runtime-Validierung folgen.
- Naechster Schritt: `TASK_158 - Editor-to-Live Mission Validation`.

### TASK_157-158 - Tactical Mission Authoring
- Status: implementiert
- Stand: `TASK_157 - Tactical Mission Editor MVP` ist implementiert; `TASK_158 - Editor-to-Live Mission Validation` validiert den Editor-Szenario-Pfad gegen die Live-Mission.
- Stand: `data/mission_scenarios/editor_validation_smoke.json` liefert ein kleines Live-Smoke-Szenario ohne LZ mit Objective, zwei Enemy-Waves, Patrol-Bindings und kurzer Wave-Folge.
- Stand: `scripts/tests/task_158_verifier.gd` instanziiert den Editor, laedt/speichert das Szenario, startet die Live-Mission, setzt die LZ ueber den Controller-Pfad, prueft Dropship-Deploy, Attack Area, Contact Overlay, Objective-Fortschritt und sichtbare Unit-/Enemy-/Area-Visuals. `docs/manual_checks/editor_to_live_mission_checklist.md` dokumentiert den manuellen Durchlauf.
- Offene Punkte: Der getrackte Branch enthaelt inzwischen den TASK_159-2.5D-Primary-Pfad; verbleibende Risiken liegen vor allem in manueller Lesbarkeits-/Sprite-Sortierpruefung statt in fehlendem Bridge-Code.
- Risiken: Der Authoring-Pfad muss Karten-/Szenario-Daten strikt von laufendem Tactical-State trennen. Insbesondere darf die LZ nicht im Editor oder Szenario gespeichert werden.
- Naechster Schritt: Manuelle UX-Pruefung des Editor-Live-Testbuttons und danach bei Bedarf Meta-Katalog-Anbindung oder weitere Szenario-Smokes schneiden.

### TASK_159 - 2.5D Editor and Mission Primary View
- Status: implementiert
- Stand: `scripts/terrain/terrain_map_3d_view.gd` fuehrt eine gemeinsame 2.5D-Primary-View fuer Editor und Live-Mission ein. Die View nutzt `SubViewport`, `Node3D` und `Camera3D`, rendert `TerrainMapData` als kalibrierte 3D-Tile-/Objekt-/Marker-/Patrol-Ansicht und spiegelt Live-Units, LZ, Dropship, Area Orders und Contacts als 3D-Proxies.
- Stand: Boden, Kartenobjekte, Waende, Katalog-Objekte, Runtime-Units und Dropship verwenden im rotierbaren Primaerpfad Kenney-GLB-Modelle aus `data/terrain_3d_asset_mapping.json`. Der kurzzeitige PNG-`Sprite3D`-Primary-Pfad war die falsche Abzweigung, weil flache Karten bei Kamera-Rotation optisch dieselbe Seite zeigen und starke Grid-/Offset-Artefakte erzeugen.
- Stand: Isometric-PNGs bleiben Legacy-Material fuer den alten 2D-Pfad oder Fallback fuer Betrieb ohne 3D-Mapping-Datei; sie sind nicht die Wahrheit der rotierbaren 2.5D-Karte. Fehlende 3D-Mappings werden im Primaerpfad als `MissingAsset_*` sichtbar und im Snapshot gezaehlt.
- Stand: Die Hilfsszenen `mission_map_3d_calibration.tscn` und `mission_map_3d_render_spike.tscn` besitzen jetzt ihre Test-Scripts und laden die gemeinsame `TerrainMap3DView`, damit Godot sie ohne Missing-Dependency-Dialog oeffnen kann.
- Stand: `scripts/editor/map_editor.gd` deaktiviert die alte `Camera2D`, blendet die Legacy-2D-Kartencontainer aus und fuehrt WASD-Pan, Zoom, Q/E- bzw. Rechtsdrag-Rotation sowie Tile-/Marker-/Patrol-Picking ueber die 2.5D-View. Die Editor-Daten bleiben weiter `TerrainMapData`; die View wird nur bei Daten-/Auswahlupdates neu gespiegelt.
- Stand: `scripts/tests/mission_test_setup.gd`, `scripts/tests/mission_map_camera_controller.gd` und `scripts/tests/mission_tactical_sandbox_controller.gd` verdrahten dieselbe View in die Live-Mission. Alte Terrain-/Unit-Sprites, LZ- und Dropship-2D-Marker werden ausgeblendet, waehrend die `Node2D`-Runtime-Anker fuer Simulation, Registry, Dropship-Presence und Selection erhalten bleiben.
- Stand: `scripts/tests/task_159_verifier.gd` prueft Editor- und Live-Primary-View, deaktivierte 2D-Kameras, ausgeblendete Legacy-Sprites, Camera3D-Rotation, 3D-Picking, Feldraender, LZ-Snapping/Feldmarker, Attack-Area-Feldmarker, Kenney-`terrain.glb`-Boden, GLB-Asset-Modelle, fehlende-Mapping-Zaehler, Astronaut-Units, Dropship-Modelle und Render-Zeitgrenzen. `scripts/tests/task_158_verifier.gd` akzeptiert nun die 3D-Primary-View als Live-Visual-Bridge und prueft den kalibrierten Dropship-GLB-Pfad.
- Offene Punkte: Die 2D-Runtime-Anker sind bewusst noch vorhanden; eine echte `Node3D`-Simulation oder 3D-Navigation ist nicht Teil dieses Tasks. Der Headless-Test ersetzt keinen manuellen Godot-Run fuer Kamera-Gefuehl, Dropship-Groesse, Sprite-Sortierung und Asset-Lesbarkeit.
- Risiken: Wenn spaeter weitere Tactical-Overlays entstehen, muessen sie explizit in die 3D-View gespiegelt werden, statt unbemerkt wieder nur im 2D-Fallback sichtbar zu sein.
- Naechster Schritt: Manuelle Sichtpruefung von Editor und Mission; danach ggf. Asset-/Scale-Politur fuer Dropship, NPC-Proxies und Terrain-Materialien als eigener kleiner Follow-up.

### TASK_160 - Tactical Mission Playability Smoke
- Status: implementiert
- Stand: `TerrainMap3DView` spiegelt zusaetzlich Objective-Capture-Zone, Capture-Fortschritt, Missionsergebnis und kurze Unit-State-Badges. Move-/Defend-/Take-Wegpunkte werden im 2.5D-Snapshot gezaehlt, Area Orders und Contacts bleiben sichtbar.
- Stand: `MissionTacticalSandboxController` uebergibt einen read-only Playability-Snapshot aus dem CombatLoop an die 2.5D-View und unterdrueckt alte frei schwebende 2D-Combat-/Wave-/Objective-Labels, sobald die 2.5D-Primary-View aktiv ist.
- Stand: `scripts/tests/task_160_tactical_playability_verifier.gd` prueft einen kompakten Live-Loop von LZ ueber Dropship, Fireteam-Deploy, Move/Defend/Take, Area Orders, Contacts, Objective Capture und Victory. `bugfix_dropship_mission_flow_verifier.gd` wurde auf den 2.5D-Dropship-Marker als sichtbaren Primary-Pfad angepasst.
- Offene Punkte: Manuelle Lesbarkeitspruefung der neuen 3D-Labels bleibt noetig.
- Risiken: Die Badges duerfen nicht zur zweiten Gameplay-Wahrheit werden; sie lesen nur Unit-/Combat-/Objective-State.
- Naechster Schritt: Im manuellen Playtest pruefen, ob Unit-Badges zu laut sind und ggf. einen kleinen UX-Politur-Task schneiden.

### Strategic Review - UI-Assets und Multiplayer-Vorbereitung
- Status: dokumentiert
- Stand: `docs/reviews/strategic_review_ui_assets_multiplayer_2026_05_03.md` sammelt Code-Review-Befunde, Optimierungs- und Designvorschlaege, externe Godot-/Forum-/UI-/Asset-Recherche sowie lokale Asset-Vorschlaege aus `C:\Users\bjoer\Pictures\Sternenbürger`.
- Stand: Neue geplante Tasks `TASK_161` bis `TASK_170` bereiten Runtime-Grenzen, Combat-Authority, Editor-Schnitt, UI-Theme, lokale Asset-Kuratierung, Multiplayer-Command-Vertrag, Session/Lobby, Snapshot-Replikation, Zwei-Client-Smoke und Warnungs-/Performance-Gates vor.
- Offene Punkte: `TASK_161` bis `TASK_170` sind umgesetzt. Die manuellen Sichtpruefungen fuer Editor, Mission, UI und zwei lokale Multiplayer-Instanzen bleiben als Playtest-/Abnahme-Schritt offen.
- Risiken: Der Review darf nicht als Freigabe fuer einen Grossumbau gelesen werden. Jede Empfehlung ist als kleiner Task-Slice auszufuehren und muss die bestehende SimulationRoot-/UI-Trennung respektieren.
- Naechster Schritt: TASK_171 ist umgesetzt; als naechstes manuellen Sichtcheck der neuen 2.5D-Unit-Modelle und danach Commit/Push nach ausdruecklicher Freigabe.

### TASK_161 - Mission Runtime Boundary Cleanup
- Status: implementiert
- Stand: `MissionTacticalSandboxController` bleibt funktional an der bestehenden Missionstest-Szene, delegiert aber erste produktive Grenzrollen aus dem Testpfad heraus. `scripts/mission/mission_primary_view_bridge.gd` kapselt 2.5D-Primary-View-Picking, LZ-/Dropship-Visuals, Mission-Status, Order-/Contact-Payloads und das Unterdruecken alter 2D-Readability-Overlays.
- Stand: `scripts/mission/mission_dropship_effect_adapter.gd` baut und enqueued die bestehenden Dropship-Effects weiter ueber `SimulationRoot`, inklusive bekannter Unit-Registrierung, ohne neue Dropship-Semantik einzufuehren. `scripts/mission/mission_command_input_guard.gd` kapselt Host/Observer-Command-Erlaubnis und Planning-Editierbarkeit.
- Stand: `scripts/tactical/ui/fireteam_selection_adapter.gd` kapselt Fireteam-Klick-/Lasso-Auswahl und das visuelle Spiegeln des Selektionszustands an Units. Command-Dictionary-Vertraege, Szenenpfade und 2D-Runtime-Anker bleiben unveraendert.
- Offene Punkte: Der Tactical-Controller ist weiterhin gross; dieser Task ist ein erster Boundary-Schnitt und kein kompletter Controller-Split. `TASK_170 - Performance and Warning Budget Gate` ist inzwischen umgesetzt.
- Risiken: Die neuen Adapter liegen bewusst nah am bestehenden Vertrag. Spaetere Refactors duerfen daraus keine zweite Gameplay-Wahrheit neben `SimulationRoot` machen.
- Lokale Pruefung: `task_160_tactical_playability_verifier.gd`, `task_159_verifier.gd`, `task_158_verifier.gd` und `bugfix_dropship_mission_flow_verifier.gd` laufen gruen.

### TASK_170 - Performance and Warning Budget Gate
- Status: implementiert
- Stand: `TerrainMap3DView` liefert im Render-Snapshot jetzt reine Diagnosezaehler fuer Snapshot-Requests sowie Order-, Contact-, Dropship- und Mission-Status-Payload-Apply-Pfade. Die Zaehler sind read-only Messwerte der View und keine Gameplay-Wahrheit.
- Stand: `scripts/tests/task_170_performance_warning_gate_verifier.gd` fasst Live-Primary-View, Render-Spike und Navigation-Budget zusammen. Es prueft fehlende 3D-Mappings, alte Sprite3D-/Placeholder-Fallbacks, Renderdauer, Snapshot-/Apply-Zaehler und Navigation-Delay-Budget mit konkreten Counter-Ausgaben.
- Stand: `scripts/tests/run_task_170_warning_gate.ps1` blockiert lokale Headless-Laeufe bei bekannten Godot-Exit-Leak-Mustern wie `ObjectDB instances leaked`, `RID allocations ... leaked` und `Resources still in use at exit`. Die Policy und Budgetwerte sind in `docs/dev/performance_warning_gate.md` dokumentiert.
- Offene Punkte: Zeitbudgets bleiben bewusst breit und sollten nach mehreren lokalen Messreihen erst dann geschaerft werden, wenn die Werte stabil sind.
- Risiken: Godot-Warnungstexte koennen sich versionsabhaengig leicht aendern; das Wrapper-Gate nutzt deshalb robuste Muster, muss bei neuen Texten aber angepasst werden.
- Lokale Pruefung: `task_170_performance_warning_gate_verifier.gd`, `run_task_170_warning_gate.ps1`, `task_159_verifier.gd`, `task_160_tactical_playability_verifier.gd` und `task_131_verifier.gd` laufen gruen.
- Naechster Schritt: `TASK_169` ist umgesetzt; Warnungs-/Budgetwerte nach weiteren lokalen Messreihen bei Bedarf schaerfen.

### TASK_162 - Combat Loop Authority Split
- Status: implementiert
- Stand: Der Combat-Loop nutzt jetzt produktive Vertragskomponenten unter `scripts/mission/`. `mission_combat_authority_contract.gd` dokumentiert Playability-, Objective-, Contact- und Mission-Result-Keys sowie die erlaubten autoritativen `SimulationRoot`-Effect-Typen.
- Stand: `MissionCombatLoopDriver.get_playability_snapshot()` und `_build_mission_result()` delegieren an diesen Vertrag. Objective-State wird weiter aus `SimulationRoot.get_objective_status()` gespiegelt; UI und 2.5D-View lesen Snapshots und werden nicht zur Gameplay-Wahrheit.
- Stand: `mission_combat_remote_event_bridge.gd` kapselt Combat-Remote-Events als `read_only`-Payloads. Die bestehenden Driver-RPCs bleiben erhalten, sind aber klar auf Anzeige/Eventtext begrenzt und committen keinen Gameplay-State.
- Offene Punkte: Der Driver selbst bleibt gross und liegt weiterhin im historischen Testpfad; dieser Task zieht die multiplayer-relevante Runtime-Grenze sichtbar, ersetzt aber keinen kompletten Driver-Move.
- Risiken: Snapshot-Keys sind von UI und Verifiern genutzt und wurden deshalb nicht umbenannt. Spaetere Multiplayer-Tasks sollen den dokumentierten Vertrag erweitern statt ad hoc neue UI-Wahrheit einzufuehren.
- Lokale Pruefung: `task_162_combat_authority_contract_verifier.gd`, `task_160_tactical_playability_verifier.gd`, `task_119_verifier.gd`, `task_118_verifier.gd` und `bugfix_dropship_mission_flow_verifier.gd` laufen gruen.
- Naechster Schritt: Combat-Vertrag bei neuen Missions-/Multiplayer-Feldern gezielt erweitern.

### TASK_165 - Local Asset Curation and Import Plan
- Status: implementiert
- Stand: `docs/assets/local_asset_curation_import_plan.md` dokumentiert den lokalen Asset-Bestand aus dem `Pictures\Sternen*`-Ordner, die bereits im Projekt vorhandenen Asset-Packs, Deduplizierungsbefunde, Importregeln und priorisierte Kandidatenlisten.
- Stand: In diesem Task wurden keine neuen binaeren Assets importiert. Der Plan blockiert weitere Pack-Komplettimporte und empfiehlt stattdessen kleine Folge-Slices mit Maximalmengen, Quelle, Lizenz, Zielpfad und Verbrauchsort.
- Stand: `Space Kit` und `3d\Space Kit` wurden als strukturelle Duplikate bewertet: je 924 Dateien und 924 gleiche relative Pfade. Fuer neue 3D-Assets bleibt GLB das bevorzugte Format; FBX/OBJ/DAE/STL werden nicht parallel importiert.
- Stand: Bereits vorhandene UI-, Input-, Cursor-, Space-Kit- und Char-Assets sollen zuerst genutzt werden. Fehlende P1-Kandidaten sind Ranks-/Role-Badges, kleine Weapon-/Blaster-Previews und Valkyrie-Transportbilder.
- Offene Punkte: Noch keine Godot-Importpruefung, weil keine neuen Assets importiert wurden. Portraits brauchen vor weiterer Nutzung Naming-, Zuschnitt- und Quellenmetadaten.
- Risiken: Der Katalog darf nicht als Freigabe fuer Massenimporte gelesen werden. Jeder Folgeimport braucht einen eigenen kleinen Task und darf keine stillen Fallbacks im 2.5D-Primary-Pfad verstecken.
- Lokale Pruefung: Der lokale Bestand wurde per PowerShell aggregiert; `git diff --check` wird fuer den Abschlussdurchlauf ausgefuehrt.
- Naechster Schritt: Asset-Import nur ueber kleine Folge-Slices mit Quelle, Lizenz, Zielpfad und Verbrauchsort.

### TASK_163 - Map Editor Module Split
- Status: implementiert
- Stand: Der interne Map-Editor bleibt funktional in `scenes/editor/map_editor.tscn`, gibt aber erste klar abgegrenzte Verantwortlichkeiten an produktive Helfer unter `scripts/editor/` ab.
- Stand: `map_editor_primary_view_adapter.gd` kapselt 2.5D-Primary-View-Setup, Legacy-2D-Sichtbarkeit, View-Refresh, Selection-Spiegelung und Screen-to-World-Picking. `map_editor_height_tool.gd` kapselt die Height-/Edge-Patch-Regeln des Hoehenwerkzeugs.
- Stand: `map_editor_patrol_tool.gd` kapselt Patrol-Waypoint-Finden, Hinzufuegen, Verschieben und Entfernen auf `TerrainMapData`. `map_editor_marker_tool.gd` kapselt Marker-Hit-Test, belegte Markerpositionen und freie Markerpositionen.
- Offene Punkte: Scenario-Panel und File-Dialog/Load-Save bleiben bewusst im Editor-Skript und sollten erst in eigenen Folgeschnitten bewegt werden. Die manuelle Editor-Sichtpruefung nach `docs/manual_checks/editor_to_live_mission_checklist.md` wurde im Headless-Durchlauf nicht ausgefuehrt.
- Risiken: Die neuen Helfer sind absichtlich nah am bestehenden Vertrag; weitere Editor-Splits duerfen `TerrainMapData`, `MissionScenarioData` und die LZ-Regel nicht vermischen.
- Lokale Pruefung: `task_163_map_editor_module_split_verifier.gd`, `task_157_verifier.gd`, `task_158_verifier.gd` und `task_159_verifier.gd` laufen gruen.
- Naechster Schritt: Weitere Editor-Splits nur bei konkreter Editor-Arbeit schneiden.

### TASK_164 - UI Theme and Component Library
- Status: implementiert
- Stand: Unter `scripts/ui/` existiert jetzt eine kleine gemeinsame UI-Basis fuer taktische Karten, Status-Badges, Command-Buttons, Progress-Zeilen, Unit-Roster-Zeilen sowie ein Tooltip-/Icon-Helfer mit kuratiertem Kenney-Asset-Manifest.
- Stand: `scripts/ui/tactical_ui_theme.gd` definiert gemeinsame Farben, Statusfarben, Icon-Groessen und StyleBox-Helfer fuer Cards, Badges, Buttons und Progress Bars. Die Komponenten bleiben reine Anzeige-Controls und halten keine Gameplay-Wahrheit.
- Stand: Der erste sichtbare Screen-Slice ist das Missions-`FireteamStatusPanel`: Es nutzt jetzt `TacticalCard`, `StatusBadge`, `ProgressLine` und `CommandButton`, behaelt aber die bestehende `SuppressionLabel`-Zusammenfassung und den vorhandenen Return-to-Plan-Callback.
- Stand: Es wurden keine neuen Asset-Dateien importiert. `ui_tooltip_icon_helper.gd` verweist nur auf vorhandene Kenney-Dateien aus `kenney_ui-pack`, `kenney_ui-pack-space-expansion` und `kenney_cursor-pixel-pack`.
- Offene Punkte: Die manuelle Sichtpruefung von Homebase/FOB/Mission bleibt ausserhalb des Headless-Durchlaufs offen; weitere Screens sollen die Komponenten nur in kleinen Folge-Slices uebernehmen.
- Risiken: Die neue UI-Basis darf nicht zu einer zweiten Skinning- oder State-Maschine anwachsen. Fachliche Screen-Logik bleibt in den bestehenden Meta-/Mission-Pfaden.
- Lokale Pruefung: `task_164_ui_theme_component_verifier.gd`, `task_096_recovery_verifier.gd` und `task_160_tactical_playability_verifier.gd` laufen gruen. Die manuelle Homebase/FOB/Mission-Sichtpruefung wurde im Headless-Durchlauf nicht ausgefuehrt.
- Naechster Schritt: Gemeinsame UI-Komponenten in weiteren Screens nur in kleinen Folge-Slices uebernehmen.

### TASK_166 - Multiplayer Authority Command Contract
- Status: implementiert
- Stand: `scripts/multiplayer/multiplayer_command_contract.gd` definiert eine dokumentierte Whitelist fuer Unit-, Commander-, Area-, Ad-hoc- und Dropship-Commands. Der Vertrag lehnt Client-Payloads ab, die Damage-, Vital-, Objective-, Runtime-, Positions- oder Dropship-State als Wahrheit setzen wollen; LZ-Payloads aus Scenario-/Editor-Kontext werden explizit blockiert.
- Stand: `SimulationRoot.request_command()` validiert server-authoritative RPC-Payloads jetzt ueber diesen Vertrag, enqueued nur akzeptierte Commands und macht Ablehnungen ueber Zaehler sowie den letzten Reject-Grund testbar. Peer-Teams, Rollen und Fireteam-Zuweisungen sind als API fuer die kommende Session-/Lobby-Anbindung vorbereitet.
- Stand: `docs/dev/multiplayer_authority_command_contract.md` dokumentiert Rollen, Whitelist, harte Rejects und die Abgrenzung zur spaeteren Snapshot-Replikation.
- Offene Punkte: TASK_167 speist die vorbereitete Peer-Zuweisungs-API jetzt aus der Session-Schicht. TASK_168 definiert den Snapshot-Vertrag; TASK_169 prueft den Zwei-Client-State-Smoke.
- Risiken: Bestehende lokale Tests duerfen Netzwerk-Commands nicht als Freigabe fuer Client-State-Mutation missverstehen. Gameplay-Wahrheit bleibt bei `SimulationRoot`.
- Lokale Pruefung: `task_166_multiplayer_authority_command_contract_verifier.gd`, `task_160_tactical_playability_verifier.gd`, `task_117_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Command-Vertrag bei neuen Multiplayer-Command-Typen gezielt erweitern.

### TASK_167 - Multiplayer Session and Lobby Extraction
- Status: implementiert
- Stand: `scripts/multiplayer/multiplayer_session.gd` kapselt ENet-Host/Join, Disconnect, Peer-Liste, Ready-State, serverseitigen Missionsstart sowie einfache Team-/Rollen-/Fireteam-Zuweisungen. Die Komponente kennt keinen laufenden Gameplay-State und repliziert keine Gameplay-Snapshots.
- Stand: `scripts/tests/lobby_test_screen.gd` bleibt als Adapter-Screen bestehen, delegiert Host/Join/Ready/Start aber an die produktive Session-Komponente. `scenes/tests/lobby_test.tscn` enthaelt jetzt Ready- und Disconnect-Controls; Start Mission bleibt host-only.
- Stand: Beim Missionsstart uebergibt der Adapter die Session-Zuweisungen an `SimulationRoot` ueber `set_peer_team_assignments`, `set_peer_role` und `set_peer_fireteam_assignments`, damit TASK_166-Command-Rechte nicht mehr im Testscreen erfunden werden.
- Offene Punkte: Der echte Host/Join-LAN-Test mit zwei Godot-Instanzen bleibt manuell offen; TASK_169 dokumentiert die Checkliste und prueft den State-Smoke headless.
- Risiken: UDP-Port 7777 kann lokal belegt sein; die Session haelt den Port konfigurierbar. Joined Peers nutzen fuer den TASK_169-Smoke die Rolle `commander`; reine Observer-Runden koennen `client_role_id = spectator` setzen.
- Lokale Pruefung: `task_167_multiplayer_session_verifier.gd`, `task_166_multiplayer_authority_command_contract_verifier.gd` und `git diff --check` laufen gruen. Der manuelle Zwei-Instanzen-LAN-Test wurde nicht ausgefuehrt.
- Naechster Schritt: Manuellen Zwei-Instanzen-Test nach `docs/manual_checks/multiplayer_two_client_playability_smoke.md` ausfuehren.

### TASK_168 - Multiplayer Snapshot Replication Contract
- Status: implementiert
- Stand: `scripts/multiplayer/multiplayer_snapshot_contract.gd` definiert und normalisiert das V1-Snapshot-Schema mit `tick`, `units`, `vital_updates`, `objective`, `dropship`, `contacts` und `mission_result`.
- Stand: `SimulationRoot` baut State-Snapshots zentral ueber diesen Contract, sendet sie als `unreliable_ordered`, behaelt Vital-Deltas als `reliable` bei und stellt Snapshot-Debugwerte fuer letzten Tick, Apply-Count, Out-of-order-Count und fehlende Units bereit.
- Stand: Client-Anwendung ueber `apply_multiplayer_snapshot()` ignoriert alte oder doppelte Ticks, wendet Unit-/Objective-State nur als Spiegelung an und enqueued keine Commands oder Effects. `MissionCombatLoopDriver` speist Contacts/Mission-Result ein; `MissionTacticalSandboxController` speist Dropship-Anzeigezustand ein.
- Offene Punkte: Prediction, Rollback, Interest Management und dedizierter Server bleiben bewusst ausserhalb dieses Tasks. Der sichtbare Zwei-Instanzen-Test bleibt als manuelle Abnahme offen.
- Risiken: Snapshot-Felder muessen klein bleiben, damit die Kopplung nicht waechst; neue Felder sollen ueber den Contract laufen statt ad hoc in UI oder 3D-View.
- Lokale Pruefung: `task_168_multiplayer_snapshot_contract_verifier.gd`, `task_160_tactical_playability_verifier.gd` und `git diff --check` laufen gruen. Der manuelle Zwei-Instanzen-Smoke wurde nicht ausgefuehrt.
- Naechster Schritt: Snapshot-Felder erst erweitern, wenn ein konkreter Folge-Task sie benoetigt.

### TASK_169 - Multiplayer Two-Client Playability Smoke
- Status: implementiert
- Stand: `scripts/tests/task_169_multiplayer_two_client_playability_smoke.gd` prueft einen lokalen Host+Client-Commander-State-Smoke mit Peer-IDs `1` und `2`, ready Session, serverseitiger Command-Validation, Unit-Bewegung, Snapshot-Anwendung und Mission-Result-Spiegelung.
- Stand: `SimulationRoot.submit_network_command_for_peer()` kapselt den validierten Serverpfad fuer Test- und RPC-Einstieg: erlaubte Client-Commands werden gequeued, verbotene State-Mutations-Payloads werden mit sichtbarem Reject-Grund gezaehlt.
- Stand: Joined Peers nutzen im TASK-169-Smoke standardmaessig Rolle `commander`, Team `team_bravo` und Fireteam `red`; Observer-Runden koennen `client_role_id = spectator` konfigurieren.
- Stand: `docs/manual_checks/multiplayer_two_client_playability_smoke.md` beschreibt den manuellen Zwei-Instanzen-Ablauf mit konfigurierbarem Port, Debugwerten und erwarteter Trennung zwischen SimulationRoot-Wahrheit und UI-/2.5D-Anzeige.
- Offene Punkte: Der manuelle Zwei-Godot-Instanzen-Test wurde im Headless-Durchlauf nicht ausgefuehrt und bleibt als Sichtpruefung offen.
- Risiken: Der Headless-Smoke prueft bewusst State, Vertrag und Snapshot statt fragile Zwei-Prozess-UI-Steuerung. UI-Kommandowege duerfen spaeter nicht um den Serververtrag herum schreiben.
- Lokale Pruefung: `task_169_multiplayer_two_client_playability_smoke.gd`, `task_167_multiplayer_session_verifier.gd`, `task_166_multiplayer_authority_command_contract_verifier.gd`, `task_160_tactical_playability_verifier.gd` und `git diff --check` laufen gruen. Der TASK_166-Verifier erzeugt erwartete Reject-Warnungen fuer Negativfaelle.
- Naechster Schritt: Manuellen Zwei-Instanzen-Test und Sichtpruefung ausfuehren; danach Commit/Push nur nach ausdruecklicher Freigabe.

### TASK_171 - NPC Model Replacement Animated Characters
- Status: implementiert
- Stand: Das lokale `Animated Characters Bundle` wurde inventarisiert und die CC0-Lizenz dokumentiert. Ein kleines Subset liegt unter `Assets/used/npc/animated_characters/`: zwei Character-FBX, zwei Astro-Skins, Idle-/Walk-FBX als Import-Probes und die Lizenzdatei.
- Stand: `data/npc_unit_visual_mapping.json` mappt Team Alpha und Team Bravo explizit auf die neuen Character-Modelle. `TerrainMap3DView` nutzt dieses Mapping nur im 2.5D-Visual-Pfad, zaehlt animierte Unit-Modelle und zeigt Missing-Asset-Marker bei fehlenden Modellen oder Skins.
- Stand: `scripts/tests/task_171_npc_model_replacement_verifier.gd` prueft Import-Subset, Resource-Ladung, Live-2.5D-Unit-Proxies und dass der Visual-Refresh keine `SimulationRoot`-Commands oder -Effects enqueued.
- Offene Punkte: Manueller Sichtcheck in Godot bleibt offen, weil Headless-Smokes Modellgroesse, Lesbarkeit und Skinwirkung nicht final beurteilen.
- Risiken: Idle-/Walk-FBX sind nur Import-Probes. Echte Animation/Retargeting bleibt ein eigener Folge-Task, falls die Modelle visuell passen.
- Lokale Pruefung: `task_171_npc_model_replacement_verifier.gd`, `task_159_verifier.gd`, `task_160_tactical_playability_verifier.gd`, `task_170_performance_warning_gate_verifier.gd` und `run_task_170_warning_gate.ps1` laufen gruen.
- Naechster Schritt: Manuellen 2.5D-Sichtcheck der neuen Unit-Modelle ausfuehren und danach entscheiden, ob Animation/Retargeting als eigener Task folgt.

### TASK_172 - NPC Animation Scale Helmets and Enemy Visuals
- Status: implementiert
- Stand: Die TASK_171-Animated-Character-Unit-Visuals sind im 2.5D-Mapping von `0.66` auf `0.22` skaliert. Die Skalierung betrifft nur den Visual-Pfad; `Node2D`-Runtime-Anker, SimulationRoot-Positionen und Gameplay-State bleiben unveraendert.
- Stand: `TerrainMap3DView` uebernimmt `idle.fbx` und `walk.fbx` in einen rein visuellen `UnitVisualAnimationPlayer`. Stehende Proxies spielen `idle`, sichtbar bewegte Proxies wechseln auf `walk`; Animation entscheidet keine Bewegung.
- Stand: Als kleines Accessory-Subset wurden `astroHelmet.fbx` und `militaryHelmet.fbx` importiert. Helme werden als reine Darstellung per `BoneAttachment3D` am Kopf-Bone befestigt oder, falls kein stabiler Kopf-Bone vorhanden ist, an einen dokumentierten `HeadAnchor` gehaengt. Nach Sichtcheck nutzt der Helm-Pfad `fit_to_model` plus `max_scale: 0.016`, damit der bisher noch zu grosse Helm um ca. zwei Drittel kleiner wird.
- Stand: Gegner-IDs `enemy_delta` und `enemy_echo` haben explizite Enemy-Visual-Mappings und nutzen ebenfalls Animated-Character-Modelle mit Helm. Neue Snapshot-Zaehler melden AnimationPlayer, Animation-Errors, Helmet-Attachments, Helmet-Errors und Enemy-Animated-Modelle.
- Offene Punkte: Manueller Godot-Sichtcheck bleibt fuer finale Helm-Offsets, Clipping, Modellgroesse und Animationswirkung offen.
- Risiken: FBX-Retargeting kann bei weiteren Animations- oder Modellvarianten erneut Bone-/Track-Kalibrierung brauchen. Helme bleiben bewusst keine Loadout- oder Ruestungsmechanik.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_172_npc_animation_scale_helmet_enemy_verifier.gd`, `task_171_npc_model_replacement_verifier.gd`, `task_159_verifier.gd`, `task_160_tactical_playability_verifier.gd`, `task_170_performance_warning_gate_verifier.gd`, `run_task_170_warning_gate.ps1` und `git diff --check` laufen gruen.
- Naechster Schritt: Manuellen 2.5D-Sichtcheck von friendly und enemy Units mit Idle/Walk und Helm-Sitz ausfuehren.

### TASK_173 - NPC Animation Skeleton Socket Contract
- Status: implementiert
- Stand: Das bereits importierte Animated-Characters-Subset hat jetzt einen dokumentierten Skeleton-Vertrag fuer `characterMedium.fbx`, `characterSmall.fbx`, `idle.fbx` und `walk.fbx`. Alle vier Ressourcen nutzen die relevanten Kernbones `Hips`, `Spine`, `Head`, `LeftHand` und `RightHand`; fuer diesen Slice ist keine Retarget-Fallback-Schicht noetig.
- Stand: `data/npc_unit_visual_mapping.json` definiert `HeadSocket`, `RightHandSocket`, `LeftHandSocket` und `BackSocket` mit expliziten Bone-Kandidaten, Offsets und Fallback-Ankern. `TerrainMap3DView` erzeugt diese Sockets im 2.5D-Visual-Pfad bevorzugt als `BoneAttachment3D`; Fallback-Anker bleiben rein diagnostisch und werden gezaehlt.
- Stand: Der Render-Snapshot enthaelt neue Diagnosewerte fuer Skeletons, Socket-Anzahl, Socket-Fallbacks, Head-/RightHand-Sockets und Animation-Retarget-Fallbacks. Diese Werte sind read-only Visual-Diagnose und veraendern keinen Gameplay-State.
- Offene Punkte: Helm- und Waffen-Offsets sind bewusst nicht finalisiert; TASK_174 soll Helme und Blaster auf diesen Socket-Vertrag umhaengen und visuell kalibrieren.
- Risiken: Neue Character- oder Accessory-Assets koennen andere Bone-Namen oder lokale Achsen haben. Solche Varianten muessen das Mapping erweitern statt neue geratenen Code-Offsets einzufuehren.
- Lokale Pruefung: `task_173_npc_animation_skeleton_socket_verifier.gd`, `task_172_npc_animation_scale_helmet_enemy_verifier.gd`, `task_171_npc_model_replacement_verifier.gd`, `task_160_tactical_playability_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: TASK_174 - Helme und Blaster als echte Socket-Attachments kalibrieren.

### TASK_174 - Character Helmet and Blaster Attachment Visuals
- Status: implementiert
- Stand: Aus dem lokalen `Blaster Kit (2.1)` wurde ein kleines GLB-only-Subset nach `Assets/used/npc/blaster_kit/` importiert: `blaster-a.glb`, `blaster-f.glb`, `blaster-p.glb`, die gemeinsame `models/Textures/colormap.png`, eine Preview-PNG und die CC0-Lizenz. FBX-/OBJ-/MTL-Duplikate wurden nicht importiert.
- Stand: `TerrainMap3DView` haengt Helme jetzt bevorzugt an den TASK_173-`HeadSocket` und Blaster an `RightHandSocket`. Die alte Bone-/Anchor-Logik bleibt nur als Reserve fuer fehlende Sockets. Helm- und Blaster-Offset, Rotation und Scale liegen explizit im Visual-Mapping; der Blaster-Sichtbefund wurde mit kleinerem Hand-Scale (`0.014`) und nachgezogenem Griff-Visual-Offset kalibriert. Nach weiterem Sichtbefund bleiben Helm- und Blaster-Offsets auf dem Socket-Nullpunkt, weil lokale FBX-Skeleton-Offsets sonst unter die Karte bzw. aus der Hand rutschen. Die sichtbaren Meshes werden separat kalibriert: Helm lokal weiter angehoben; sichtbare Blaster-Laufachse (`-Z`) zeigt in Idle nach unten, Magazin-/Griffseite (`+Y`) nach hinten vom NPC; Blaster werden mit expliziter `colormap.png` texturiert.
- Stand: Die Runtime-Animationsauswahl bevorzugt namentlich passende `Idle`-/`Walk`-Clips und ignoriert importierte `0_Targeting Pose`-Clips, damit die Animated-Character-Proxies nicht in der statischen Targeting-/T-Pose bleiben.
- Stand: Friendly/default- und enemy-Visual-Mappings enthalten eigene Blaster-Pfade. Neue Snapshot-Zaehler melden `unit_blaster_attachment_count` und `unit_blaster_error_count`; fehlende Blaster erzeugen sichtbare Missing-Asset-Marker.
- Offene Punkte: Der Headless-Verifier prueft Socket-Eltern, Scales und Ressourcen; der finale optische Sitz von Helm und Blaster braucht weiter den manuellen Godot-Sichtcheck in der 2.5D-Kamera.
- Risiken: GLB-Achsen und Hand-Bone-Lokalachsen koennen trotz korrekter Socket-Anbindung noch visuelle Rotation-/Offset-Politur brauchen. Das bleibt Darstellung und darf nicht in Loadout- oder Combat-State auslaufen.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_174_character_helmet_blaster_attachment_verifier.gd`, `task_173_npc_animation_skeleton_socket_verifier.gd`, `task_172_npc_animation_scale_helmet_enemy_verifier.gd`, `task_160_tactical_playability_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Manueller 2.5D-Sichtcheck fuer Helm-Sitz, Blaster-Sitz und Idle-/Walk-Follow.

### TASK_175 - NPC Loadout Attachments
- Status: implementiert
- Stand: `data/npc_unit_visual_mapping.json` enthaelt jetzt einen kleinen Visual-Loadout-Vertrag mit `visual_loadouts`, `weapon_visual_loadouts` und `role_visual_loadouts`. Bestehende Team-/Unit-Visuals bleiben erhalten und waehlen Attachments ueber `visual_loadout_id`; Rollen- und Waffen-Mappings koennen Varianten wie `compact_blaster` oder `heavy_blaster` aufloesen.
- Stand: `TerrainMap3DView` merged Visual-Loadouts rein fuer den 2.5D-Darstellungspfad in den bestehenden Unit-Visual-Eintrag. Neue Snapshot-Zaehler melden `unit_visual_loadout_count` und `unit_visual_loadout_error_count`; fehlende Attachment-Ressourcen erzeugen weiter sichtbare Missing-Asset-Marker.
- Offene Punkte: Manuelle Sichtpruefung bleibt fuer kuenftige Rollen-/Waffenvarianten sinnvoll; TASK_175 fuehrt keine Combat-Werte, Inventar-UI oder echte Waffenmechanik ein.
- Risiken: Loadout-Visuals duerfen auch in Folgearbeiten nicht mit Schaden, Reichweite, Munition oder SimulationRoot-Wahrheit vermischt werden.
- Lokale Pruefung: `task_175_npc_loadout_attachment_verifier.gd`, `task_174_character_helmet_blaster_attachment_verifier.gd`, `task_160_tactical_playability_verifier.gd`, `task_171_npc_model_replacement_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Bei Bedarf kleine Folge-Tasks fuer weitere sichtbare Rollen- oder Waffenvarianten anlegen.

### TASK_176 - FOB Loadout Weapon Preview Selector
- Status: implementiert
- Stand: Fenster `#13 LOADOUT` zeigt in den pro-Mitglied-Slots jetzt nur noch `SMG` und `Medictool`. Die SMG-Option nutzt das bereits importierte Projekt-Asset `res://Assets/used/npc/blaster_kit/previews/blaster-a.png` als Icon und kleine Slot-Preview.
- Stand: `Medictool` bleibt als Loadout-Auswahl erhalten und nutzt jetzt `res://Assets/used/npc/blaster_kit/previews/blaster-b.png` als Preview. Das zugehoerige 2.5D-Visual-Loadout `medictool_blaster` nutzt `res://Assets/used/npc/blaster_kit/models/blaster-b.glb` und weiter die TASK_174-Groessen-, Textur- und Orientierungs-Kalibrierung am `RightHandSocket`.
- Stand: Alte `rifle`-/`rail_gun`-Werte werden in diesem FOB-UI-Slice auf die aktuelle SMG-Auswahl normalisiert; die bestehende Mission-/TestUnit-Waffenlogik bleibt getrennt. `TerrainMap3DView` laesst `medictool` die Team-Default-Waffe fuer die reine Darstellung uebersteuern, ohne Combat-Werte zu veraendern.
- Offene Punkte: Manueller Sichtcheck in `#13 LOADOUT`; weitere Blaster-Previews erst importieren, wenn sie als eigene Auswahl wirklich genutzt werden.
- Risiken: Preview-Bilder duerfen keine Combat-Werte oder SimulationRoot-Wahrheit werden. Genutzte Assets muessen aus lokalen Quellen ins Projekt kopiert und ausschliesslich per `res://...` referenziert werden.
- Lokale Pruefung: `godot_console.exe --headless --path . --import`, `task_176_fob_loadout_weapon_preview_selector_verifier.gd`, `task_087_verifier.gd`, `task_175_npc_loadout_attachment_verifier.gd`, `task_174_character_helmet_blaster_attachment_verifier.gd`, `medic_support_verifier.gd`, `task_096_recovery_verifier.gd`, `task_114_meta_recovery_verifier.gd` und `git diff --check` laufen gruen.
- Naechster Schritt: Manuellen FOB-Sichtcheck ausfuehren und danach weitere Blaster nur in eigenen kleinen Follow-ups anbinden.

### TASK_096 - Meta-Layer Recovery: Missionskarte, Dropship-LZ und Character-Sheet-Umbau
- Status: implementiert
- Stand: Der Meta-Layer fuehrt jetzt durchgaengig auf die echte eingebettete Missionskarte statt auf eine separate read-only Overview. Homebase, FOB und Mission teilen dieselbe kompakte Navigation, die Missions-Tactical-UI traegt direkt die gemeinsamen Block-Labels `#15` bis `#18`, und der Missionspfad bleibt auf dieselbe Kartenbasis, dieselben LZ-/Approach-Marker sowie denselben Dropship-Handoff verdrahtet wie die spaetere Live-Mission.
- Stand: Im FOB zeigen transitierende Operator-Karten ihren ETA-/Fortschrittszustand sichtbar ausgegraut mit Progress-Bar, Piloten zaehlen konsistent in die Missionsslot-Kapazitaet hinein, und der Character-Overlay rendert den deutschen TASK-096-Layoutblock ueber `CharacterSheetView` mit Kernwert-Balken. Die gemeinsame Dropship-Shipcard fuehrt im V1-Pfad nur noch die fachlich klaren Aktionen `Board` und `Send`; ein alter `tracked`-Button ist dort nicht mehr Teil des UI-Vertrags.
- Offene Punkte: Keine innerhalb des TASK-096-Scopes; spaetere Meta-Map-Folgearbeiten beschraenken sich jetzt auf optionale Politur wie Ruecktransfer-Varianten oder zusaetzliche Routenarten.
- Risiken: Die Meta-Ansichten bleiben bewusst Staging- und Read-Only-Schichten auf dem bestehenden Missions-/Transportzustand. Weitere Komfort- oder Kartenpolitur sollte darauf in kleinen Folge-Tasks aufsetzen, statt daraus eine zweite Missions- oder Fahrzeugwahrheit aufzubauen.
- Naechster Schritt: Nur bei Bedarf neue klar benannte Follow-up-Tasks fuer Meta-Map-Politur oder weitergehende Transfervisualisierung schneiden.

### TASK_291-TASK_298 - Editor Terrain Visual Recovery and Authoring UX
- Status: implementiert
- Stand: `docs/dev/editor_terrain_visual_recovery_contract.md` dokumentiert Diagnose, Hoehenkanon, Legacy-Space-Kit-Cliff-/Ramp-Referenz, Grid-Depth-Verhalten, Lichtwerte und die gemeinsame Referenzfixture `maps/editor_terrain_visual_recovery_reference.json`.
- Stand: `TerrainMap3DView` nutzt fuer das Editor-Grid wieder Depth-Test statt Always-Front-Overlay, exponiert Visual-Recovery- und Light-Snapshots, kalibriert Licht zentral und stellt einen Shadow-Debug-Hook bereit. Cliff-/Slope-Daten bleiben am hoeheren Tile, die sichtbaren Edge-Modelle werden aber auf dem niedrigeren Nachbartile bzw. bei Ecken auf dem diagonalen unteren Aussentile verankert. Nature-Props haben groessere, sichtbare Scale-Werte und melden Anchor-/Scale-Daten im Render-Snapshot.
- Stand: Der Map Editor hat eine kompakte Tool-Leiste mit Select, Brush, Eraser, Height, Marker/Patrol-Vertraegen; der Eraser leert nur die Objekt-Ebene und bewahrt Hoehe, Surface, Edge und Szenario-Daten. Die Palette ist gruppenfilterbar und enthaelt ein kleines projektlokales Space-Station-Subset.
- Stand: Der rechte Inspector kann Map Settings, Markers und Mission Scenario einzeln ein-/ausklappen, waehrend Tile Properties sichtbar bleiben. Der integrierte TASK_298-Smoke prueft Referenzmap, Toolbar, Palette, Inspector, Render-Snapshot und Missing-Asset-Gate.

### TASK_299-TASK_313 - Meta, FOB and Dropship Userology Contracts

- Stand: Teamnamen werden seeded generiert, im Player-Roster persistiert und im Main Menu editierbar/suggestbar gemacht. App-Shell-Ruecknavigation, NPC-Drag/Badge-Lesbarkeit, unified Transit-Ghosting, FOB-Unassigned-Pool, kompakte Flightdeck-/Dropship-Karten, Fireteam-Assignment-Frames und Dropship-LZ/Go/Feedback-Vertraege sind als Headless-Gates abgedeckt.
- Wichtig: UI bleibt Darstellung; Teamname/Transit/LZ-Resolved-State sind Daten-/Contract-Felder und ersetzen keine SimulationRoot-Wahrheit. Dropship requested/resolved LZ wird im 3D-Primary-View getrennt visualisiert.
- Verifier: `task_299` bis `task_313` laufen gruen; gemeinsame Smokes sind `task_306_meta_userology_playability_smoke.gd` und `task_310_fob_flightdeck_fireteam_userology_smoke.gd`.
- Offene Punkte: Manueller Godot-Screenshot-/Klickcheck fuer finale Art-Direction, Scroll-Komfort im rechten Inspector und Sichtvergleich gegen den User-Screenshot bleiben offen.
- Risiken: Multi-Tile-Space-Station-Strukturen sind bewusst noch nicht gesnappt; weitere Asset- oder Inspector-Politur soll in kleinen Folge-Tasks passieren.
- Lokale Pruefung: `task_291_editor_terrain_visual_recovery_coordinator.gd` bis `task_298_editor_terrain_visual_playability_smoke.gd` plus bestehende Regressionen werden im aktuellen Arbeitsblock ausgefuehrt.

### TASK_314 - FOB NPC Pool Window Left Of Fireteams
- Status: implementiert
- Stand: `DropLightLayoutContract.get_fob_layout()` enthaelt jetzt ein festes `unassigned_pool`-Fenster. `FOBTestScreen` zeigt es als `#09 NPC POOL` links neben `#10 FIRETEAMS`, statt den alten Available-Bereich im fixed Layout auszublenden.
- Stand: Der Pool nutzt weiter die bestehenden FOB-Drag/Drop-Pfade: unzugewiesene NPC-Karten wandern in Fireteams, Fireteam-Mitglieder koennen zurueck in den Pool geloest werden. `#14 FLIGHTDECK` bleibt breit; die zusaetzliche Spalte wird durch ein schmaleres `#13 LOADOUT` aufgefangen.
- Risiken: Das sichtbare Fenster zeigt nur FOB/VB-unassigned Operatoren und darf nicht als neues Homebase-Roster oder SimulationRoot-Wahrheit behandelt werden.
- Lokale Pruefung: `task_314_fob_npc_pool_window_left_of_fireteams.gd`, `task_178_fob_drop_light_fixed_fullhd_layout_verifier.gd`, `task_181_drop_light_fixed_window_audit_verifier.gd`, `task_307_fob_arrivals_unassigned_operator_pool.gd`, `task_309_fireteam_assignment_board_compact_frames.gd` und `git diff --check` laufen gruen.

### TASK_315 - Mission Grid Tile Selection Command Gate
- Status: implementiert
- Stand: `TerrainMap3DView` rendert das Mission-/Editor-Grid jetzt mit kontrastreichem Cyan-Highlight plus dunkler Schattenlinie, bleibt aber depth-tested und nah an der Tile-Oberflaeche. Der Render-Snapshot meldet Grid- und Selection-Farben sowie die sichtbare `selected_grid_positions`-Liste.
- Stand: `TacticalInputController` fuehrt eine explizite ausgewaehlte Tile-Planungsmarke. Beim Missionsstart wird das Objective-Tile selektiert; Linksklick auf freie Karte, Target-Pick und LZ-Pick aktualisieren die sichtbare Tile-Auswahl, ohne Fireteam-Auswahl oder SimulationRoot-Wahrheit zu ersetzen.
- Stand: Move, Take, Defend und Flank deklarieren im `MissionCommandHierarchyContract` `requires_tile_selection`. Ohne ausgewaehltes Tile sind die Buttons gesperrt und ein Command wird mit `SELECT TILE FIRST` geblockt; mit Tile wird die Tile-Weltposition an den bestehenden Flow-Driver uebergeben.
- Risiken: Die Tile-Auswahl ist UI-/Planungszustand und darf nicht als zweite Terrain- oder SimulationRoot-Wahrheit erweitert werden. Die staerkeren Grid-Linien brauchen noch den manuellen FullHD-Sichtcheck fuer finale Art-Direction.
- Lokale Pruefung: `task_315_mission_grid_tile_selection_command_gate.gd`, `task_292_editor_hill_cliff_grid_depth_repair.gd`, `task_160_tactical_playability_verifier.gd`, `task_275_command_button_hierarchy_arrangement_overhaul.gd` und `git diff --check` laufen gruen.

### TASK_316 - FOB Fireteam Staging Migration
- Status: implementiert
- Stand: Fireteam-Karten wandern jetzt zwischen `#10 FIRETEAMS`, `#12 FOB RESPAWN`, `#13 LOADOUT` und `#19 Dropship`, statt in `#10` sichtbar zu bleiben, waehrend sie bereits in einem Staging-Fenster referenziert werden.
- Stand: `#12` zeigt Verorten-Fortschritt pro Fireteam-Mitglied, `#13` behaelt kompakte Loadout-Reihen mit Rang-Badges und Dropdowns, und die Fireteam-Karten behalten ueberall die kompakte Breite inklusive sichtbarem Loadout.
- Stand: Kompakte NPC-Karten koennen per Doppelklick weiter das Character Sheet anfordern, auch wenn sie fuer Staging-/Transit-Zustaende optisch disabled sind.
- Risiken: Die FOB-UI bleibt Staging-/Darstellungsschicht; Transport-, Respawn- und Fireteam-Zustand duerfen nicht als zweite Gameplay-Wahrheit in den Karten landen. Der finale FullHD-Sichtcheck der kompakten Karten bleibt offen.
- Lokale Pruefung: `task_316_fob_fireteam_staging_migration.gd`, `task_309_fireteam_assignment_board_compact_frames.gd` und `git diff --check` laufen gruen.
