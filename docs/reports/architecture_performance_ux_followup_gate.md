# Architecture Performance UX Followup Gate

## Summary
TASK_337 schliesst die Follow-up-Serie TASK_330 bis TASK_336 mit einem gemeinsamen Gate ab. Der Gate ist bewusst ein Pruef- und Dokumentationsschnitt: Er repariert keine neuen Sammelprobleme, sondern bestaetigt die Architekturgrenzen, die Performance-Vertraege und die UI-/UX-Grundbedienbarkeit oder macht kleine Folge-Tasks sichtbar.

## Ergebnis
- Status: implementiert im Arbeitsstand.
- Automatisierter Abschluss-Gate: `scripts/tests/task_337_architecture_performance_ux_followup_gate.gd`.
- Zusaetzliche Pflicht-Gates bleiben: TASK_222 Performance Regression Gate, TASK_282 Tactical Overhaul Gate und TASK_286 UI Feedback Truth Regression Review.
- Findings: keine kritische automatisierte Regression im Abschluss-Gate. Offene Punkte bleiben manuelle Sicht-/Spielgefuehlchecks und werden nicht im Sammelpatch repariert.

## Architektur
- `docs/ARCHITECTURE.md` und `docs/CODEX_RULES.md` bestaetigen weiter die Grenze: Gameplay-Wahrheit liegt nicht im UI, State-Mutationen laufen ueber `SimulationRoot`, Kommunikation bevorzugt EventRouter/Signale, Dirty-/Batch-Updates bleiben Aufgabe von `UpdateManager`.
- TASK_330: Produktive Mission-Runtime-Skripte liegen in `scripts/mission/`; die Mission-Szene referenziert fuer Setup, Flow, Combat, Controller, Objective View, Respawn Overlay, Enemy Waves und Phase Controller keine produktiven `scripts/tests`-Pfade mehr.
- TASK_331 und TASK_335: Command-Feedback kommt aus Snapshot-/Contract-Pfaden. UI liest `command_hierarchy`, `command_buttons` und `command_clarity`, speichert aber keine Gameplay-Wahrheit.
- TASK_336: Der Combat-Tick ist als explizite Phasenliste mit `phase_records`, `phase_catalog` und `SimulationRoot`-Autoritaet sichtbar. Every-N- oder Balance-Aenderungen bleiben eigene Folgearbeit.

## Performance
- TASK_222 bleibt das breite Performance-Regression-Gate fuer Render, Navigation, Simulation, UI, Assets und Snapshot.
- TASK_332 reduziert frame-live Terrain-/Proxy-Arbeit durch getrennte Motion-/Visibility-/Badge-Syncs, Dirty-Diagnose und kompakte Order-Signaturen.
- TASK_333 richtet Navigation-Fallbacks am Budget-Contract aus: ein neuer Path-Query-Budgetwert pro Tick, ein Fallback-Pfadversuch pro Request und sichtbare Fallback-Diagnosen.
- TASK_336 macht Combat-Hotpath-Phasen und lokale Dauerwerte sichtbar, ohne Tick-Ausduennung oder Balancing im selben Task einzufuehren.
- Der Abschluss-Gate prueft, dass die Performance-Budget-Sektionen `render`, `navigation`, `simulation`, `ui`, `assets` und `snapshot` weiter vorhanden sind und keine TASK_330-336-Reports kritische Regressionen markieren.

## UI/UX
- TASK_334 bestaetigt den unveraenderten FullHD-Vertrag `full_hd` und das kompakte Profil `compact_720` fuer 1280x720.
- Der Abschluss-Gate instanziiert die Mission lokal in 1920x1080 und 1280x720, prueft das gesetzte Drop-Light-Profil und zentrale Command-/Mission-Control-Buttons.
- TASK_335 bestaetigt Disabled-Reasons fuer Kernaktionen: fehlende Fireteam-Auswahl, fehlende/ungueltige Tile-Auswahl, fehlende LZ, fehlendes Drop-Team, Cooldown und blockierte Air Lane.
- Der Live-Smoke liest Command-Feedback und bestaetigt, dass der Readback keine `SimulationRoot`-Commands oder Effects enqueued.

## Serienstatus
| Task | Gate-Beitrag | Ergebnis |
| --- | --- | --- |
| TASK_330 | Mission Runtime Scripts Productization Followup | Produktive Mission-Pfade aus `scripts/tests` geloest |
| TASK_331 | Mission Tactical Controller Adapter Split First Slice | Command-Feedback-Snapshot delegiert |
| TASK_332 | Terrain Map Frame Budget Proxy Sync Pass | Proxy-/Order-Hotpaths budgetierbarer |
| TASK_333 | Navigation Fallback Budget Contract Alignment | Fallbacks am Contract und Diagnose sichtbar |
| TASK_334 | Drop Light Layout Profiles Compact Resolution | FullHD plus 1280x720-Profil abgesichert |
| TASK_335 | Tactical Feedback Truth Command Clarity Pass | Disabled-Reasons und UI-Wahrheitsgrenze sichtbar |
| TASK_336 | Combat Loop Tick Budget System Split | Combat-Phaseninventar und Timing sichtbar |

## Manuelle Checks
Die manuelle Checkliste liegt unter `docs/manual_checks/architecture_performance_ux_followup_checklist.md`.

Zu pruefen bleiben:
- FullHD-Sichtcheck in Godot fuer Homebase, FOB und Mission-HUD.
- 1280x720-Kompaktprofil mit Fokus auf Lesbarkeit, Scrollbereiche und erreichbare Command-Buttons.
- Mission-Command-Flow mit Auswahl, Tile-Ziel, Plan, Go, Hold/Take/Clear und sichtbaren Disabled-Reasons.
- Dropship/LZ-Flow mit Set LZ, Approach, Call Dropship, Air-Lane-Block und zweitem Craft.
- Zwei lokale Instanzen fuer Host/Client und die Grenzen echter Internet-/UPnP-Erreichbarkeit.

## Risiken
- Headless-Gates koennen Layoutrechtecke, Snapshot-Grenzen und Button-Erreichbarkeit pruefen, aber nicht finale optische Balance oder Stress-Lesbarkeit.
- Die TASK_330-336-Serie senkt Drift-Risiken, ersetzt aber keinen Playtest-Balance-Pass.
- Neue Findings duerfen nicht in TASK_337 gesammelt repariert werden. Sie sollen als kleine Folge-Tasks mit engem Scope beschrieben werden.
