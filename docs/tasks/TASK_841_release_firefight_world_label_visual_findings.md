# TASK_841 - Release Firefight World Label Visual Findings

## Ziel / Problem
TASK_840 hat den echten First-GO-Firefight nach dem TASK_839-Declutter gecaptured. Der Screenshot ist sichtbar ruhiger als vor dem Declutter, aber noch nicht als Befund ausgewertet.

Ziel ist ein kleiner, maschinenlesbarer Findings-Schnitt: Was ist akzeptabel, was stoert noch, und welcher konkrete naechste Polish-Task macht das Spiel angenehmer und schoener?

## Sinnhaftigkeit / Ursache
Der Spielerblick entscheidet hier. Headless beweist nur den Vertrag; TASK_840 beweist nur, dass ein echtes Bild vorliegt. TASK_841 uebersetzt diesen Blick in konkrete, nachvollziehbare Folgearbeit, ohne Gameplay-Wahrheit in UI oder Review-Artefakte zu verschieben.

## Umfang
- Neuer read-only Analyzer `ReleaseFirefightWorldLabelVisualFindings`.
- Auswertung des TASK_840-Manifests und der manuellen Sichtnotizen.
- Positive Findings: weniger Welttext-Dichte, HUD-Details bleiben lesbar, Command-Matrix bleibt bedienbar.
- Offene Findings:
  - `insertion_residue_world_labels`: Approach-/ETA-Texte und gruene Dropship-Route bleiben im Firefight als Insertionsreste sichtbar.
  - `first_firefight_no_fire_contact`: Der Capture zeigt `NO FIRE LOS/RANGE`, also Entscheidungsfeedback, aber noch keinen eigentlichen Schusswechsel.
  - `map_text_near_units_crowded`: Resttexte nahe der oberen Einheitengruppe sitzen zu nah am Bewegungs-/Kontaktbereich.
- JSON-Manifest unter `tmp/release_firefight_world_label_visual_findings.json`.
- Folgeempfehlung: TASK_842 - Release Firefight Insertion Residue Declutter.

## Nicht-Ziele
- Keine automatische Pixelbewertung.
- Kein Code-Polish an World-Labels in diesem Task.
- Kein neues Combat-/Contact-/Movement-Verhalten.
- Kein Markieren der gesamten Release-Firefight-Optik als final.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_840_release_firefight_world_label_real_window_recapture.md`
- `docs/tasks/TASK_839_release_firefight_world_label_declutter.md`

## Akzeptanzkriterien
- Snapshot nennt Schema `sternenbuergerchen.release_firefight_world_label_visual_findings.v1` und `task_id = TASK_841`.
- Snapshot bleibt `read_only=true` und `ui_sets_gameplay_truth=false`.
- TASK_840-Manifest mit `review_ready`, `release_firefight_declutter` und TASK_839-Style-ID erzeugt keine technischen Blocker.
- Findings nennen `insertion_residue_world_labels` als primaeres offenes Polish-Problem.
- Findings nennen `first_firefight_no_fire_contact` als Warnung fuer spaetere Combat-Framing-Folgearbeit.
- Manifest nennt `recommended_next_task = TASK_842 - Release Firefight Insertion Residue Declutter`.

## Betroffene Dateien
- `scripts/mission/release_firefight_world_label_visual_findings.gd`
- `scripts/tests/task_841_release_firefight_world_label_visual_findings.gd`
- `docs/tasks/TASK_841_release_firefight_world_label_visual_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_841_release_firefight_world_label_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_840_release_firefight_world_label_real_window_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_841 ist bewusst ein Befund-Task. Die eigentliche Verbesserung am Bild folgt in TASK_842, damit der Code-Eingriff klein und zielgerichtet bleibt.
