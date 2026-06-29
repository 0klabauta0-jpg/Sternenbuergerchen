# TASK_578 - Suppress Fire Visual Polish Findings

## Ziel / Problem
TASK_577 hat die `SUP AREA`-Preview reproduzierbar belegt. Das Manifest zeigte aber auch den naechsten kleinen Visual-Fund: `render_preview_visual_count = 0`, obwohl Pfad und `SUP AREA`-Text vorhanden waren. Der Suppress-Bereich war damit im Render-Snapshot nicht als eigene Flaeche belegbar.

## Sinnhaftigkeit / Ursache
`SUP` soll vor `GO` als taktische Flächenentscheidung lesbar sein. Ein reiner Text im Order-Panel reicht dafuer nur bedingt; der Zielbereich muss im 3D-/F6-Blick als read-only Preview-Marker sichtbar und messbar werden.

## Umfang
- `suppress_preview` read-only an bestehende Waypoint-Intent-Preview-Entries haengen.
- Primary3D zeichnet eine flache orange Suppress-Area am Ghost-Ziel.
- Render-Snapshot meldet `waypoint_intent_preview_suppress_area_count` und Entry-Metadaten.
- TASK_577-Evidence bleibt kompatibel und darf den neuen Count im Manifest aufnehmen.
- HTML-Zwischenbericht auf TASK_578 aktualisieren.

## Nicht-Ziele
- Keine echte Suppression-Wirkung.
- Kein Ammo-Verbrauch.
- Keine Combat-/Movement-Mutation.
- Kein neues Command-System und kein GO-Commit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_577_suppress_fire_visual_evidence_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Bei aktiver Fire-Rule `suppress` und geplantem Move meldet Primary3D mindestens eine Suppress-Area.
- Die Suppress-Area-Entry enthaelt Zielposition, Radius, Pressure-State, `visual_key = suppress_area_v1` und `read_only = true`.
- Die Preview fuehrt keinen `GO` aus und mutiert keine Command-Queue.
- TASK_576/TASK_577 bleiben gruen.
- Der HTML-Zwischenbericht nennt TASK_578 als erledigten Polish und TASK_579 als naechsten sinnvollen Anschluss.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_578_suppress_fire_visual_polish_findings.gd`
- `docs/tasks/TASK_578_suppress_fire_visual_polish_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_578_suppress_fire_visual_polish_findings.gd`
- `godot_console.exe --path . --script scripts/tests/task_577_suppress_fire_visual_evidence_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_576_suppress_fire_preview_readability_spike.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Area ist eine Preview-Fläche, keine Gameplay-Wirkzone.
- Der finale menschliche F6-Sichttest muss weiter entscheiden, ob Farbe, Alpha und Groesse angenehm sind.
- Echte Suppression-Wirkung, Munitionsverbrauch und AAR-Messwerte bleiben Folgearbeit.
