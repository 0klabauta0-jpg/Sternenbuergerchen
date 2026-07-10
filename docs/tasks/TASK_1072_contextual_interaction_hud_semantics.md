# TASK_1072 - Contextual Interaction HUD Semantics

## Ziel / Problem

Slot `16.8` plant seit TASK_1070 AA, Door, Computer und Cargo. Sein sichtbarer
Text wechselt korrekt, aber der nachgelagerte Command-Hierarchy-Pass kann
Tooltip, `help_id` und Metadaten wieder als statisches Door-Breach markieren.
Ein Spieler sieht dann etwa `AA->GO`, erhaelt beim Hover aber eine Breach-
Erklaerung samt Door-Kontext.

## Ursache / Sinnhaftigkeit

`_refresh_door_interaction_button_state()` setzt den dynamischen sichtbaren
Zustand. `_apply_command_hierarchy_metadata()` laeuft danach und nutzt den
historischen Katalogeintrag `breach_door` fuer denselben NodePath. Der
Katalogeintrag ist fuer echte Doors weiterhin korrekt, aber nicht fuer die
kontextuellen Nicht-Door-Interactions.

## Umfang

- Den sichtbaren Slot nach dem Command-Hierarchy-Pass an der aktiven
  Interaction ausrichten.
- AA und Computer als `take`/Interaction, Cargo als `defend`/Interaction
  beschreiben; kein Door-Hotkey vortaeuschen.
- Door behaelt `B`, `B->GO`, Breach-Hilfe und den vorhandenen Door-Hook.
- Read-only Button-/Command-Feedback exportiert denselben Kontext.

## Nicht-Ziele

- Kein neuer Interaction- oder Command-Authority-Pfad.
- Keine neue Taste fuer AA, Computer oder Cargo.
- Kein Umbau des historischen Door-Contracts oder Command-Katalogs.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_1070_station_route_aa_assault_door_transition.md`
- `docs/tasks/TASK_1071_station_route_full_victory_debrief_trace.md`
- `scripts/ui/mission_command_hierarchy_contract.gd`

## Akzeptanzkriterien

- AA-Buttontext, Tooltip, `help_id` und Command-Metadaten nennen AA/Take und
  niemals Breach oder Hotkey `B`.
- Door-Buttontext, Tooltip, `help_id` und Command-Metadaten bleiben Breach/
  `B->GO`/`B`.
- Der finale Sichtzustand wird erst nach `_apply_command_hierarchy_metadata()`
  geprueft.
- Die UI mutiert keine Interaction-, Gate- oder Mission-Wahrheit.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1072_contextual_interaction_hud_semantics.gd`
- `docs/dev/mission_interaction_point_contract.md`
- diese Task-Datei sowie Status, Roadmap und aktueller HTML-Bericht

## Lokale Pruefung

- TASK_1072 23/23; prueft AA und Door nach dem Hierarchy-Pass sowie nach
  weiteren UI-Frames, damit der Nicht-Door-Slot keinen alten B-Metawert
  zurueckerhaelt.
- TASK_1070 23/23, TASK_1071 47/47 und TASK_695 32/32.
- `git diff --check`.

## Risiken / offene Punkte

Der historische Command-Hierarchy-Katalog bleibt fuer Door-Kompatibilitaet
sichtbar. Der Task darf ihn nicht zu einer zweiten Missionswahrheit ausbauen;
er korrigiert nur die finale Darstellung des gemeinsam genutzten Slots.
