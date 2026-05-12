# TASK_355 - Homebase Direct UX Payload Truth

## Ziel
Die Homebase-UI soll klar unterscheiden, welche Fireteams nur im Homebase-Team/Loadout-Kontext liegen und welche wirklich im Flightdeck-Dropship fuer den Missionsstart sitzen.

## Status: GEPLANT

## Problem
Nach dem FOB-Bypass liegen Fireteam-Auswahl, Loadout und Flightdeck direkt in der Homebase. Fuer Spieler kann aber unklar sein, ob ein Fireteam nur in `#10 FIRETEAMS` / `#13 LOADOUT` bearbeitet wird oder bereits im Dropship sitzt und beim Start wirklich mitfliegt.

## Ursache
Die Gameplay-Kette braucht einen harten Payload-Scope (TASK_351). Die UI sollte diese Wahrheit sichtbar machen, damit falsche Starts nicht nur technisch verhindert, sondern auch verstaendlich werden.

## Umfang
- In Homebase sichtbare Status-/Badge-Logik fuer Fireteams:
  - `Staged in Homebase`
  - `Loadout editing`
  - `Boarded / Flightdeck`
  - `Blocked: no dropship / busy craft / not at homebase`
- Startbutton- und Flightdeck-Status sollen die Anzahl wirklich embarkter Operators zeigen.
- Nicht-embarkte Fireteams duerfen nicht so aussehen, als wuerden sie beim Missionstart mitfliegen.
- Keine neue Marketing-/Tutorial-Flache; kurze, dichte UI-Signale in vorhandenen Panels.

## Akzeptanzkriterien
- [ ] Spieler kann auf einen Blick sehen, welche Fireteams im Dropship sitzen.
- [ ] Startstatus nennt die wirkliche Payload-Anzahl, nicht nur die Homebase-Auswahl.
- [ ] Blockertexte bleiben sichtbar und passend zu TASK_349.
- [ ] UI-Snapshot-/Verifier prueft die relevanten Labels oder Metadaten.
- [ ] Keine Ueberlappung/Clipping-Regression in Homebase-Drop-Light-Layout.

## Erwartete Dateien
- `scripts/meta/homebase_screen.gd`
- ggf. `scripts/meta/fob_fireteam_card.gd`
- ggf. `scripts/meta/meta_ui_skin.gd`
- `scripts/tests/task_355_homebase_direct_ux_payload_truth.gd`
- ggf. `scripts/tests/task_346_homebase_direct_staging_character_popup.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_355_homebase_direct_ux_payload_truth.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Der Task soll UI-Wahrheit sichtbar machen, nicht neue Gameplay-Wahrheit in UI-Callbacks erzeugen.
- Dichte Homebase-Panels duerfen durch neue Statuslabels nicht wieder clippen; FullHD-Sichtcheck bleibt sinnvoll.
