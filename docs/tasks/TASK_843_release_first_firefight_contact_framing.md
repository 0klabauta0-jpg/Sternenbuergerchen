# TASK_843 - Release First Firefight Contact Framing

## Ziel / Problem
Nach TASK_842 ist das erste Release-Firefight-Bild ruhiger, aber der eigentliche Kontaktmoment kann noch wie ein technischer Blocker wirken: `NO FIRE LOS/RANGE` beschreibt zwar den Zustand, rahmt ihn aber nicht als taktischen Druck.

Ziel: Der erste Firefight soll im Release-Pfad als `fire_exchange` oder als klarer `contact_pressure`-Moment lesbar sein. Wenn noch kein echter Schusswechsel sichtbar ist, muss der Spieler trotzdem verstehen: Kontakt ist da, Feuer ist blockiert, und der naechste Griff ist LOS/Range/Position korrigieren.

## Sinnhaftigkeit / Ursache
Die bestehenden TASK_832-/TASK_813-Snapshots pruefen GO, Kontakt und Engagement-Status. Sie erlauben aber weiterhin einen gruenen Pfad, in dem `NO FIRE` dominiert. Fuer ein angenehmes Spielgefuehl braucht der sichtbare erste Kampfzustand einen menschlichen Rahmen, ohne Combat-, Damage- oder Zielerkennungslogik neu zu erfinden.

## Umfang
- Neuer read-only Snapshot fuer Release-First-Firefight-Contact-Framing.
- Framing-State:
  - `fire_exchange`, wenn vorhandene FireEvents oder fired-Diagnostics sichtbar sind.
  - `contact_pressure`, wenn Kontakt, Block-/Wait-/No-Fire-Entscheidung und Grund sichtbar sind.
  - `unclear`, wenn der Moment nicht belegbar ist.
- Event-Log-Fallback und HUD-Kontext nennen Contact Pressure statt nur technischen `NO FIRE`-Text.
- MetaLayer reicht den Snapshot fuer Release-/Deep-Link-Pruefungen weiter.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue Treffer-, LOS-, Range-, Damage- oder Zielerkennungsregel.
- Kein Erzwingen eines Schusses, wenn vorhandene Combat-Daten nur Contact Pressure belegen.
- Kein Multiplayer-Authority-Umbau.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_841_release_firefight_world_label_visual_findings.md`
- `docs/tasks/TASK_842_release_firefight_insertion_residue_declutter.md`
- `docs/tasks/TASK_832_release_first_go_firefight_deeplink_evidence.md`
- `docs/tasks/TASK_813_station_reentry_release_candidate_first_go_firefight_actionability_smoke.md`

## Akzeptanzkriterien
- Snapshot nennt Schema `sternenbuergerchen.release_first_firefight_contact_framing.v1` und `task_id = TASK_843`.
- Source-Gates aus First-GO-Firefight und Insertion-Residue-Declutter bleiben gruen.
- Snapshot klassifiziert den ersten Moment als `fire_exchange` oder `contact_pressure`, nicht als `unclear`.
- `framing_line` nennt `CONTACT FIRE` oder `CONTACT PRESSURE` und enthaelt einen kurzen naechsten Griff.
- Bei `contact_pressure` bleiben Blockgrund, LOS-/Range-Kontext und ausgewaehlter Fireteam-Kontakt sichtbar.
- Event-Log-Fallback benutzt im No-Fire-Fall `CONTACT PRESSURE` statt nur `NO FIRE`.
- Snapshot bleibt read-only und erzeugt keine Commands, Navigation, FireEvents, DamageEvents oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_843_release_first_firefight_contact_framing.gd`
- `docs/tasks/TASK_843_release_first_firefight_contact_framing.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_843_release_first_firefight_contact_framing.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_842_release_firefight_insertion_residue_declutter.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_832_release_first_go_firefight_deeplink_evidence.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_843 macht den Moment lesbar, nicht dramatisch final. Wenn der echte Fensterblick danach immer noch zu wenig Kampfspannung zeigt, ist der naechste sinnvolle Schritt ein echter First-Exchange-Tuning-Task oder ein kurzer Encounter-Framing-Playtest.
