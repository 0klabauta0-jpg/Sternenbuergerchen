# TASK_842 - Release Firefight Insertion Residue Declutter

## Ziel / Problem
TASK_841 hat den primaeren sichtbaren Restbefund benannt: Im ersten Release-Firefight bleiben Approach-/LZ-Weltlabels und die gruene Dropship-Approach-Route sichtbar, obwohl der Spieler jetzt Feuer-/Kontaktentscheidungen lesen soll.

Ziel: Diese Insertionsreste im aktiven Firefight-Declutter visuell ausblenden, ohne die LZ-/Drop-Lesbarkeit vor `GO` oder Cargo-/Freighter-Visuals zu verlieren.

## Sinnhaftigkeit / Ursache
TASK_839 reduziert bereits Routine-Weltlabels im Firefight. Dropship-LZ-Labels und Approach-Pfeile liegen aber in einem getrennten Drop-Visual-Pfad und wurden deshalb nicht vom World-Label-Declutter erfasst. Das fuehrt im echten Fenster zu einem alten Insertionsfokus, waehrend der eigentliche Firefight gelesen werden soll.

## Umfang
- `TerrainMap3DView` erhaelt eine messbare TASK_842-Visual-Policy fuer den bestehenden `release_firefight_declutter`-Modus plus den expliziten Payload-Schalter `release_firefight_insertion_residue_declutter`.
- Nicht-Cargo Dropship-LZ-Labels werden im Firefight-Declutter unterdrueckt.
- Nicht-Cargo Approach-Vektoren werden im Firefight-Declutter unterdrueckt.
- LZ-Marker, Dropship-Modelle und Cargo-/Freighter-Approach-Visuals bleiben erhalten.
- Der Drop-Visualpfad wird neu gebaut, wenn der explizite Insertion-Residue-Declutter ueber Order- oder Status-Payload wechselt.

## Nicht-Ziele
- Kein neues Dropship-Gameplay.
- Kein Aendern von LZ-Auswahl, Drop, Deboarding oder Cargo-Gates.
- Kein Entfernen von Pre-GO-LZ-Labels oder Approach-Pfeilen im Default-Modus.
- Kein Combat-Framing-Fix; `first_firefight_no_fire_contact` bleibt TASK_843.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_841_release_firefight_world_label_visual_findings.md`
- `docs/tasks/TASK_839_release_firefight_world_label_declutter.md`

## Akzeptanzkriterien
- Default-/Pre-GO-Drop-Visuals rendern weiter LZ-Label und Approach-Pfeil.
- Im `release_firefight_declutter`-Modus mit explizitem `release_firefight_insertion_residue_declutter=true` meldet der Render-Snapshot `release_firefight_insertion_residue_declutter_active=true`.
- Der Mission-Controller setzt den expliziten Schalter erst, wenn Einheiten deployed sind oder eine Drop-Sequenz in `unloading`, `complete` oder `outbound` ist.
- Im Firefight-Declutter sind nicht-Cargo LZ-Label und Approach-Pfeil unterdrueckt und als suppress-counts sichtbar.
- LZ-Marker und Dropship-Visual bleiben im Firefight-Declutter vorhanden.
- Cargo-/Freighter-Approach und Cargo-Status bleiben trotz Firefight-Declutter sichtbar.
- Snapshot bleibt read-only und erzeugt keine Commands, FireEvents, DamageEvents oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_842_release_firefight_insertion_residue_declutter.gd`
- `scripts/tests/task_393_direct_dropship_independence_lz_vector.gd`
- `docs/tasks/TASK_842_release_firefight_insertion_residue_declutter.md`
- `docs/tasks/BUGFIX_homebase_parallel_direct_dropship_fireteam_catalog_guard.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_842_release_firefight_insertion_residue_declutter.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_839_release_firefight_world_label_declutter.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_393_direct_dropship_independence_lz_vector.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_842 raeumt nur Insertionsreste aus dem Firefight-Bild. Ein echter erster Schusswechsel oder klarerer Contact-Pressure-Moment bleibt TASK_843.
