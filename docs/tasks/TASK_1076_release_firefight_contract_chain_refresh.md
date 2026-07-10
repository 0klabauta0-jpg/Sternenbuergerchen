# TASK_1076 - Release Firefight Contract Chain Refresh

## Ziel / Problem

Die historischen Release-Firefight-Verifier TASK_834 bis TASK_839 fallen
als Kette, obwohl die sichtbaren Polishes sowie TASK_833 und TASK_1074 gruen
sind. Dadurch kann der aktuelle Firefight-/Large-Map-Stand nicht als
zusammenhaengender Release-Flow geprueft werden.

## Ursache / Sinnhaftigkeit

TASK_1074 hat bewusst eine stabile sichtbare Prioritaet eingefuehrt:
`CONTACT FIRE` zuerst und direkt darunter `NEXT ... | WHY ...`. TASK_834
und der darauf aufbauende Bottom-Dock-Contract erwarten noch die alte
`NEXT/WHY`-zuerst-Reihenfolge. Ihre Quellen-Gates erklaeren damit einen
bewusst ersetzten Presentation-Mode zur Regression und kaskadieren bis
TASK_839. Der TASK_838-Fallback erwartete zusaetzlich noch den alten
Fallback-Namen, obwohl der bestehende TASK_847-Visibility-Presenter denselben
read-only Zweck mit einer expliziten Quelle uebernimmt.

## Umfang

- Historische TASK_834- bis TASK_839-Snapshot-Gates auf den bestehenden
  TASK_1074-Zwei-Zeilen-Contract ausrichten.
- Selected Fireteam und Mission Control pruefen jeweils `CONTACT FIRE`
  zuerst und die Decision-Line direkt darunter.
- Bestehende Style-, Read-only-, Event-Log- und World-Declutter-Pruefungen
  erhalten.
- Keine sichtbare UI, keine Combat-Logik und keinen Multiplayer-Transport
  veraendern.

## Nicht-Ziele

- Kein neuer Firefight-HUD-Stil.
- Kein Rebuild von Event-Log, Terrain-Labels oder Command Matrix.
- Kein Lockern von echten Style-, Count- oder Read-only-Gates.

## Relevante Contracts / Dokumente

- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1074_host_client_f6_contract_refresh.md`
- `docs/tasks/TASK_834_release_firefight_hud_real_window_polish.md`
- `docs/tasks/TASK_835_release_firefight_bottom_dock_density_polish.md`
- `scripts/tests/task_833_release_firefight_hud_readability_polish.gd`

## Akzeptanzkriterien

- TASK_834, TASK_835, TASK_836, TASK_838 und TASK_839 bestehen mit dem
  aktuellen `CONTACT FIRE`-dann-`NEXT/WHY`-Presentation-Mode.
- TASK_833 und TASK_1074-Host/Client-Readout bleiben gruen.
- Alle Snapshot-Gates bleiben read-only und besitzen keine Gameplay-
  Wahrheitsfelder.
- Der Event-Log-Fallback akzeptiert nur `release_firefight_event_log_fallback`
  oder `release_fire_exchange_visibility_persistence`.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_834_release_firefight_hud_real_window_polish.gd`
- `scripts/tests/task_835_release_firefight_bottom_dock_density_polish.gd`
- `scripts/tests/task_836_release_firefight_command_matrix_visual_polish.gd`
- `scripts/tests/task_838_release_firefight_real_window_findings_polish.gd`
- `scripts/tests/task_839_release_firefight_world_label_declutter.gd`
- Task-/Contract-/Status-/Roadmap-/Report-Dateien

## Lokale Pruefung

- TASK_834: 27/27 PASS.
- TASK_835: 28/28 PASS.
- TASK_836: 29/29 PASS.
- TASK_838: 28/28 PASS.
- TASK_839: 31/31 PASS.
- TASK_833: 23/23 PASS.
- TASK_505: PASS mit 36.864 Kartenkacheln, aktivem Chunk-Streaming und
  sichtbaren Badges nach Sieg.
- TASK_160: 22/22 PASS.
- TASK_607: 41/41 PASS fuer lokalen ENet-Host/Client, Authority,
  Snapshots und F6-Readout.
- `git diff --check`.

## Risiken / offene Punkte

Selected Fireteam und Mission Control koennen innerhalb eines Combat-Ticks
unterschiedliche Outcome-Worte wie `HIT` und `FIRED` lesen. Der Contract
fordert deshalb dieselbe Lesereihenfolge und dieselbe sichtbare
`NEXT/WHY`-Entscheidung, nicht kuenstlich identische kurzlebige Outcome-Texte.
