# TASK_844 - Release First Exchange Tension Tuning

## Ziel / Problem
Der erste Release-Firefight kann nach `--release-singleplayer-first-go-firefight` zwar als Kontaktmoment lesbar sein, endet aber noch zu oft nur als `CONTACT PRESSURE`. Fuer den ersten spielbaren Eindruck soll der Deep-Link reproduzierbar einen echten ersten Fire-Exchange zeigen.

## Sinnhaftigkeit / Ursache
TASK_843 rahmt blockierte oder wartende Combat-Entscheidungen korrekt. Die Ursache fuer zu ruhige Erstkontakte liegt aber im Release-Testpfad: Der erste Gegner wird bisher mit einem festen Offset neben das Fireteam gesetzt. Dieser Offset ist nicht gegen vorhandene LOS-, Range- und Combat-Readouts geprueft.

## Umfang
- Der Release-Deep-Link sucht eine nahe Gegnerposition, die mit dem bestehenden Combat-Readout attackable ist.
- Der echte Schusswechsel laeuft weiter ueber `MissionCombatLoopDriver._try_enqueue_attacks()` und `SimulationRoot.enqueue_effect()`.
- Ein neuer Snapshot belegt `fire_exchange`, FireEvent-Evidenz und read-only Grenzen.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine Aenderung am normalen Gegner-KI- oder Spawn-System.
- Keine neue UI-seitige Combat-Wahrheit.
- Keine Multiplayer-Autoritaets- oder Damage-Modell-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_843_release_first_firefight_contact_framing.md`
- `docs/tasks/TASK_832_release_first_go_firefight_deeplink_evidence.md`

## Akzeptanzkriterien
- `--release-singleplayer-first-go-firefight` positioniert den ersten Testgegner ueber vorhandene LOS-/Range-/Combat-Readouts.
- Der TASK_844-Snapshot meldet `framing_state = fire_exchange`.
- FireEvent-Evidenz ist sichtbar (`fire_event_count > 0` oder `first_fire_event_id` gesetzt).
- Der Snapshot erzeugt keine Commands, FireEvents oder DamageEvents selbst.
- TASK_843 bleibt als Fallback-Contract fuer `contact_pressure` erhalten.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_844_release_first_exchange_tension_tuning.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_844_release_first_exchange_tension_tuning.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_843_release_first_firefight_contact_framing.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_842_release_firefight_insertion_residue_declutter.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Task haertet bewusst nur den Release-/QA-Deep-Link. Echte Missionsbalance, Gegnerplatzierung und Encounter-Design bleiben eigene Folgearbeit.
