# Einstieg am Schiff (L03) und Einzelsteuerung im Einsatz

Stand: 15.11.2026. Plan des Bedien-Strangs (Paket AP5 der Playtest-Überarbeitung). Den Plan schreibt der Hauptchat; Hilfsagenten arbeiten die Pakete einzeln ab. Abstimmung mit den anderen Strängen: Projektdokument `claude/Abstimmung-Bedienung-und-Grafik.md`.

## Ziel

1. **L03:** Personen bleiben beim Aufsitzen nicht mehr am Schiff hängen. Nach dem Absitzen nimmt der Trupp sofort Befehle an. Aufsitzen im Feld geht per Rechtsklick auf das Schiff.
2. **Einzelsteuerung** (Björns Entscheidung vom 15.11., `claude/Spielvision.md` Abschnitt 3): Im Zweifel lässt sich eine einzelne Person direkt steuern. Der Normalfall bleibt der Befehl an den Truppführer. Die bisherige Regel „keine Einzelsteuerung im Gefecht“ aus dem Arbeitsplan ist damit aufgehoben.

## Was die Erkundung ergeben hat (Stand `main` `9fe0b659b`)

`CTRL` = `scripts/tests/mission_tactical_sandbox_controller.gd` (der echte Missionscontroller), `SIM` = `scripts/core/simulation_root.gd`, `FMC` = `scripts/tactical/fireteam_movement_controller.gd`. Zeilennummern sind Näherungen.

- Auswahl: `CTRL._unhandled_input` (924) → `_begin_selection_interaction` / `_finish_selection_interaction` → `_apply_unit_click_selection` (20456). Ein Klick auf eine Person wählt immer den ganzen Trupp; eine gewählte Einzelperson gibt es im Einsatz nicht. Einheit unter dem Zeiger: `_find_selectable_unit_at_screen_position` (21240).
- Befehle: Rechtsklick → `_finish_right_order_context_interaction` (35619). Im Planmodus (Standard) öffnet er ein Menü und der Befehl läuft erst bei GO; ohne Planmodus `request_immediate_move_from_screen` (37735). Ausführung über `FMC.start_execution` → `_enqueue_unit_command` → `SIM.enqueue_command` mit `move_to_position` je Person.
- Zwischen zwei Befehlen zieht `FMC.update_execution` / `_reissue_current_stage` jede Person des Trupps wieder auf das Truppziel. Eine einzeln geschickte Person würde sofort zurückgeholt, solange sie Mitglied der laufenden Ausführung ist (`_build_member_records`, 1467; `hex_execution_scope`).
- Aufsitzen: Knopf „Aufsitzen“ → `CTRL.request_selected_team_boarding` (37677), Abfrage alle 0,25 s in `_advance_selected_team_boarding` (37689) über `request_campaign_crew_boarding` (14042). Alle lebenden Mitglieder müssen gleichzeitig näher als 128 an `get_campaign_ground_ship_access(craft).position` stehen. Nach 180 s gibt die Abfrage still auf.
- Absitzen: `request_campaign_crew_deployment` (14138). Danach sperren `_post_drop_security_pending_fireteam_ids` und `_runtime_activation_pending_fireteam_ids` neue Befehle („WAIT FOR INSERTION“), bis die Rundumsicherung ausgegeben wurde. Ein Zeitlimit dafür ist nicht zu erkennen.
- Vermutete Hänger (noch nicht nachgestellt): Aufsitzbefehl während eines laufenden Marschs wird nur hinten angestellt; `_campaign_ground_approach_radius` (37600) greift nur, wenn das Ziel auf 1,0 genau am Einstieg liegt; ein einzelnes Einstiegsfeld für alle; stilles Aufgeben nach 180 s; Sperrflaggen nach dem Absitzen bleiben stehen, wenn die Rundumsicherung nicht ausgegeben werden kann.
- Ein Rechtsklick auf das Schiff ist heute kein Aufsitzbefehl. Schiff unter dem Zeiger: Muster in `select_landed_craft_at_screen_position` (37548, 56 Pixel).
- Gezieltes Feuer auf einen bestimmten Gegner, Aufheben und Benutzen gibt es nur auf Truppebene (`create_selected_mission_interaction_use_intent`, 30302) oder gar nicht. Einzelbewegung per `move_to_position` mit `unit_id` gibt es schon.

## Grenzen für alle Pakete

- Nur im Worktree `C:\dev\SternenBuergerchen-worktrees\playtest-rework-impl-20261114` arbeiten, Branch `task/ap5-einstieg-einzelsteuerung-20261115`. Hauptordner und andere Worktrees nicht anfassen. Nicht nach `main` mergen; das macht der Hauptchat nach Prüfung.
- Vom Grafik-Strang belegt und deshalb tabu: `scripts/ui/mission_a5_hud_layout.gd`, `scripts/ui/mission_a5_dropship_presenter.gd`, `scripts/ui/components/approach_dial.gd`, in `CTRL` die Funktion `_apply_fireteam_mini_member_portrait_strip`.
- Keine Shader, Modelle, Karten. Keine neue Wahrheit neben den vorhandenen Besitzern: Zustand der Einzelsteuerung liegt in `CTRL`, Bewegung läuft weiter über `SIM`.
- Erst ein Prüfskript, das den Fehler oder die fehlende Funktion zeigt (rot), dann die Änderung (grün). Godot immer mit eigenem Profil starten (`$env:APPDATA` auf `<Worktree>\output\ap1-audit-profile`).
- Mehrspieler: Einzelsteuerung zuerst nur im Einzelspiel. Verbundene Clients bekommen eine klare Meldung statt eines halben Befehls.

## Paket A0: Aufsitzen und Absitzen nachstellen (nur Prüfskript, kein Produktcode)

Neues Prüfskript `scripts/tests/playtest_l03_boarding_repro_verifier.gd`, aufgebaut wie `compact_team_actual_boarding_verifier.gd`. Jede Szene protokolliert jede Sekunde: Abstand jeder Person zum Einstieg, den Grund aus der Aufsitzabfrage, Größe der beiden Sperrmengen, ob eine Aufsitzanfrage offen ist.

| Szene | Ablauf | Erwartung |
| --- | --- | --- |
| S1 | Landen, absitzen, warten bis Befehle frei, „Aufsitzen“ | alle an Bord, Zeit notieren |
| S2 | Marschbefehl etwa zehn Felder weit, eine Sekunde später „Aufsitzen“ | Trupp dreht sofort um, alle an Bord |
| S3 | „Aufsitzen“ unmittelbar nach dem Absitzen, solange die Sperrmengen noch gefüllt sind | klare Ablehnung oder Annahme; nie stilles Nichtstun |
| S4 | Trupp steht 15 Felder entfernt, dann „Aufsitzen“ | alle an Bord, bevor die Abfrage aufgibt |
| S5 | Rechtsklickbefehl in dem Augenblick, in dem das Absitzen fertig meldet | Trupp bewegt sich innerhalb von fünf Sekunden |

Ergebnis: Tabelle rot/grün je Szene mit den Messwerten und der wahrscheinlichen Ursache je roter Szene. Daraus legt der Hauptchat Paket A1 (die Korrekturen) fest.

## Paket B: Aufsitzen per Rechtsklick, Auswahl nach dem Absitzen

- Rechtsklick (ohne Ziehen) auf das eigene gelandete Schiff bei genau einem gewählten Trupp löst `request_selected_team_boarding` aus, im Planmodus wie ohne. Erkennung wie in `select_landed_craft_at_screen_position`.
- Nach abgeschlossenem Absitzen ist der abgesessene Trupp ausgewählt, wenn nichts anderes gewählt ist.
- Prüfskript: Rechtsklick auf das Schiff führt zum selben Ergebnis wie der Knopf; nach dem Absitzen ist der Trupp gewählt.

## Paket C1: Einzelsteuerung – auswählen, schicken, zurück zum Trupp

**Bedienung**
- Klick auf eine Person wählt wie bisher ihren Trupp. Ein weiterer Klick auf eine Person des schon gewählten Trupps wählt nur diese Person (ein Doppelklick führt damit zum selben Ergebnis). Ein Klick auf die schon einzeln gewählte Person, auf eine andere Stelle oder Esc hebt die Einzelauswahl auf.
- Klick auf das Porträt einer Person in der Truppkarte wählt diese Person einzeln (`_on_native_member_portrait_gui_input`, 5495); Doppelklick öffnet weiter die Charakterdetails.
- Bei Einzelauswahl schickt ein Rechtsklick auf den Boden nur diese Person sofort dorthin, ohne Menü und ohne GO, auch im Planmodus und auch während der Trupp einen Befehl ausführt.
- Rechtsklick auf einen sichtbaren Gegner: die Person bekämpft dessen Position (`engage_area` auf die Gegnerposition).
- Die Statuszeile nennt die Einzelsteuerung mit Namen („Einzelsteuerung: Anja“).

**Technik**
- `CTRL`: `_selected_unit_id: String`, `_detached_units: Dictionary` (unit_id → fireteam_id). Öffentliche Abfragen `get_selected_unit_id()`, `is_unit_detached(unit_id)`; Testzugänge nach dem Muster von `issue_right_click_command_for_test`.
- Abkoppeln: Die Person wird aus der laufenden Truppausführung herausgenommen, damit `_reissue_current_stage` sie nicht zurückholt (in `FMC` eine Ausschlussmenge, die `_build_member_records` und der Ausführungsumfang beachten). Abschlussprüfungen einer Truppetappe zählen abgekoppelte Personen nicht mit.
- Befehl: `SIM.enqueue_command` mit `move_to_position` (bzw. `engage_area`), `unit_id`, `team_id`, `target_position`, `source_command_type = "direct_control"`, eigenem `command_token`.
- Wiederanschluss: Sobald der Trupp seinen nächsten Befehl bekommt (Stelle: `_issue_waypoint_for_fireteam`, 34581, vor `start_execution`), werden alle abgekoppelten Personen dieses Trupps wieder Mitglieder. Fällt die Person aus, endet die Abkopplung.
- Ereignis für den Spielrunde-Strang: Signal `direct_unit_action_resolved(unit_id: String, action: String, success: bool, details: Dictionary)` an `CTRL`, dazu `get_direct_unit_action_events() -> Array` mit allen Einträgen des Einsatzes. `action` ist `move`, `engage`, später `take` und `use`. Bei `move` gilt die Ankunft am Ziel als gelungen, Abbruch oder Ausfall als misslungen.

**Prüfskript** `scripts/tests/playtest_direct_unit_control_verifier.gd`: Einzelauswahl per Klickfolge; Rechtsklick bewegt nur die gewählte Person, der Rest des Trupps bleibt bei seinem Befehl; die Person wird während eines laufenden Truppbefehls nicht zurückgeholt; nach dem nächsten Truppbefehl läuft sie wieder mit; Ereignis mit richtigen Feldern; Planmodus öffnet bei Einzelauswahl kein Menü. Nachbarn, die grün bleiben müssen: `bugfix_mission_right_click_order_flow`, `playtest_20261110_plan_mode_verifier`, `compact_team_actual_boarding_verifier`, `compact_fireteam_card_verifier`.

## Paket C2: Einzelsteuerung – nehmen und benutzen

Rechtsklick auf einen Interaktionspunkt oder Gegenstand lässt die einzeln gewählte Person dorthin gehen und ihn benutzen bzw. aufnehmen. Vorher klären, wie `_try_start_stationary_interaction` (32759) und `_is_interaction_arrival_receipt_valid` (32697) die Ankunft des Trupps prüfen und ob eine einzelne Person diese Prüfung erfüllen kann. Plan folgt nach C1.

## Offene Punkte

- Die Auswahlgeste (zweiter Klick wählt die Person) ist ein Vorschlag; Björn entscheidet nach dem Ausprobieren.
- Gezieltes Feuer auf eine bestimmte Person statt auf ihre Position gibt es im Regelwerk nicht; C1 nutzt die Position.
- Mehrspieler-Freigabe der Einzelsteuerung (Kategorie `unit_command` im Befehlsvertrag) kommt später.

## Ergebnis Paket A0 (15.11.2026)

Das Prüfskript `playtest_l03_boarding_repro_verifier.gd` spielt S1 bis S5 mit dem Zweiertrupp der Kampagne durch; auf `main` (`9fe0b659b`) sind alle fünf Szenen grün. Wird die Einstiegskorrektur `b5227ab21` probeweise zurückgenommen, kann die gelandete Besatzung gar nicht mehr aufsitzen. Der Hänger aus dem Playtest vom 14.11. war dieser Fehler und ist behoben; ein Paket A1 entfällt. Offen blieb nur die irreführende Meldung während des Absitzens (Paket B).

## Stand nach Paket B und C1 (15.11.2026)

- **Paket B** (`30db58a39`): Rechtsklick auf das eigene gelandete Schiff lässt den gewählten Trupp aufsitzen, mit und ohne Planmodus. Während des Absitzens meldet „Aufsitzen“ jetzt „Absitzen läuft noch“. Nach dem Absitzen ist der Trupp gewählt, wenn nichts anderes gewählt ist.
- **Paket C1** (`94cfc7a98`): Einzelauswahl über den zweiten Klick auf eine Person des gewählten Trupps oder über ihr Porträt; Esc, Lasso, Feldauswahl und Klick auf das Schiff heben sie auf. Rechtsklick bei Einzelauswahl: Gegner → `engage_area` auf dessen Position; liegende eigene Person → nur Meldung (Zielart für das spätere Tragen reserviert); eigenes Schiff → nur Meldung; Boden → sofortiger Marsch nur dieser Person. Die Person bleibt aus dem laufenden Truppbefehl heraus und läuft mit dem nächsten Truppbefehl wieder mit.
- **Für andere Stränge:** Signal `direct_unit_action_resolved(unit_id, action, success, details)` und `get_direct_unit_action_events()` am Missionscontroller; `get_selected_unit_id()`, `is_unit_detached(unit_id)`. In `fireteam_movement_controller.gd`: `set_unit_excluded`, `is_unit_excluded`, `enqueue_direct_unit_command`. `engage` meldet Erfolg schon bei angenommenem Befehl (`details.accepted_only`), weil es noch keine Trefferverfolgung gibt.
- **Prüfung:** `playtest_direct_unit_control_verifier` 96 / 0, `playtest_l03_right_click_boarding_verifier` 68 / 0, `playtest_l03_boarding_repro_verifier` 44 / 0; Nachbarn unverändert grün. Die Klicks gehen in den Prüfskripten als echte Mausereignisse in `_unhandled_input` des Controllers; die Verteilung durch das Godot-Fenster und ein echter Mausklick im laufenden Spiel sind nicht geprüft.
- **Bekannte Schwäche:** Ein Rechtsklick auf das Schiff in den ersten rund zwei Sekunden nach dem Absitzen kann mit `movement_controller_start_failed` abgelehnt werden, solange der Pilot noch vom Schiff wegläuft. Ob das auch den Knopf „Aufsitzen“ betrifft, ist nicht untersucht.
- **Nur Einzelspiel:** Ein verbundener Mehrspieler-Client bekommt die Meldung „Einzelsteuerung gibt es im Mehrspieler noch nicht“.
- **Offen:** Paket C2 (nehmen und benutzen), Freigabe im Mehrspieler, gezieltes Feuer auf eine bestimmte Person.


## Nachtrag: auf `main` gebracht (15.11.2026, 12:00)

- Vor dem Merge neu auf `main` `40ea8d106` aufgesetzt (Missionsansicht A5, schwere Rüstung R09 und R10 des Grafik-Strangs). Einzige gemeinsame Datei: der Missionscontroller; Git hat ohne Konflikt zusammengeführt.
- Auf dem zusammengeführten Stand gelaufen: `playtest_l03_right_click_boarding_verifier` 68 / 0, `playtest_l03_boarding_repro_verifier` 44 / 0, `bugfix_mission_right_click_order_flow` 21 / 0, `compact_fireteam_card_verifier` 41 / 0, `mission_a5_dichte_verifier` Exit 0, `playtest_hit_area_audit_verifier` 4395 Prüfungen und `failed=0`, `campaign_two_moon_roundtrips_real_verifier` 83 / 0.
- `playtest_direct_unit_control_verifier` meldete auf dem zusammengeführten Stand einmal 96 / 2 (Szene „DC-replace“). Ursache lag im Prüfskript: Der zweite Befehl kam nach einer festen Wartezeit von einer Spielsekunde, und genau dann erreichte die Person das erste Ziel. Je nach Abfragezeitpunkt war der erste Befehl schon erledigt (und wurde zu Recht gemeldet) statt ersetzt. Das Skript wartet jetzt, bis die Person unterwegs ist (mindestens ein Feld gelaufen, noch mehr als drei Felder vom ersten Ziel), und prüft das ausdrücklich. Danach dreimal hintereinander 97 / 0. Am Spielcode wurde dafür nichts geändert.
- Die Meldung „Absitzen läuft noch“ steht weiter in `A5BoardStatus`; der Knoten liegt seit A5 im Befehlsband unten.
